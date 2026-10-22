import json
import os
import sys
import unittest
from unittest.mock import MagicMock, patch
from pathlib import Path
sys.path.insert(0, str(Path(__file__).parent))
sys.modules["boto3"] = MagicMock()
os.environ.update(OUTBOX_ARN="outbox", BUS_NAME="bus", TOPIC_ARN="topic", ANALYTICS_BUCKET="analytics")
import handler

class WorkerTests(unittest.TestCase):
    def record(self, arn="contacts"):
        detail = {"requestId":"request-1", "interest":"Sport", "date":"2026-10-22"}
        return {"messageId":"message-1", "eventSourceARN":arn,
                "body":json.dumps(detail if arn=="outbox" else {"detail":detail})}

    def test_outbox_publishes_event(self):
        with patch("handler.events") as events:
            events.put_events.return_value = {"FailedEntryCount":0}
            result = handler.handler({"Records":[self.record("outbox")]}, None)
            self.assertEqual(result["batchItemFailures"],[])
            self.assertEqual(events.put_events.call_args.kwargs["Entries"][0]["Source"],"moto.contacts")

    def test_partial_event_failure_is_retried(self):
        with patch("handler.events") as events:
            events.put_events.return_value = {"FailedEntryCount":1}
            result = handler.handler({"Records":[self.record("outbox")]}, None)
        self.assertEqual(result["batchItemFailures"],[{"itemIdentifier":"message-1"}])

    def test_idempotent_analytics_key_and_no_pii_notification(self):
        with patch("handler.s3") as s3, patch("handler.sns") as sns:
            handler.process(self.record());handler.process(self.record())
            keys = [c.kwargs["Key"] for c in s3.put_object.call_args_list]
            self.assertEqual(keys,["contacts/request-1.json"]*2)
            self.assertEqual(sns.publish.call_args.kwargs["Message"],
                "Request request-1 is ready. Open the administrator portal.")

    def test_one_failure_does_not_retry_successful_record(self):
        good=self.record();good["messageId"]="good"
        bad=self.record();bad["messageId"]="bad";bad["body"]="not json"
        with patch("handler.s3"), patch("handler.sns"):
            result=handler.handler({"Records":[good,bad]},None)
        self.assertEqual(result["batchItemFailures"],[{"itemIdentifier":"bad"}])

if __name__=="__main__":unittest.main()
