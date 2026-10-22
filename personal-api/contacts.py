import json
import os
from datetime import datetime, timezone
import boto3
from database import execute, SCHEMA, SAVE
from validation import validate

queue = boto3.client("sqs")


def create_contact(event):
    data = validate(event)
    execute(SCHEMA)
    execute(SAVE, {"request_id": data["requestId"], **{
        k: data[k] for k in ["name", "email", "phone", "interest"]}})
    # Retry with the same request ID never creates a second customer record.
    # Only non-personal metadata leaves the database.
    metadata = {"requestId": data["requestId"], "interest": data["interest"],
                "date": datetime.now(timezone.utc).date().isoformat()}
    queue.send_message(QueueUrl=os.environ["OUTBOX_QUEUE"], MessageBody=json.dumps(metadata))
    return {"message": "Our agent will call you.", "requestId": data["requestId"]}
