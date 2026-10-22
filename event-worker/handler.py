"""At-least-once notifications; analytics objects are idempotent by request ID."""
import json
import os
import boto3

events = boto3.client("events")
sns = boto3.client("sns")
s3 = boto3.client("s3")


def process(record):
    payload = json.loads(record["body"])
    if record["eventSourceARN"] == os.environ["OUTBOX_ARN"]:
        result = events.put_events(Entries=[{
            "Source": "moto.contacts", "DetailType": "ContactCreated",
            "EventBusName": os.environ["BUS_NAME"], "Detail": json.dumps(payload)}])
        if result.get("FailedEntryCount", 0):
            raise RuntimeError("Event delivery failed")
        return
    detail = payload["detail"]
    request_id = detail["requestId"]
    row = {"request_id": request_id, "event_date": detail["date"],
           "interest": detail["interest"], "requests": 1}
    s3.put_object(Bucket=os.environ["ANALYTICS_BUCKET"],
                  Key=f"contacts/{request_id}.json", Body=json.dumps(row) + "\n",
                  ContentType="application/json", ServerSideEncryption="AES256")
    sns.publish(TopicArn=os.environ["TOPIC_ARN"], Subject="New motorcycle enquiry",
                Message=f"Request {request_id} is ready. Open the administrator portal.")


def handler(event, context):
    failed = []
    for record in event.get("Records", []):
        try:
            process(record)
        except Exception:
            failed.append({"itemIdentifier": record["messageId"]})
    return {"batchItemFailures": failed}
