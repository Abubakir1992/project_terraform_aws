import json
import os
import sys
from unittest.mock import MagicMock
from pathlib import Path
sys.path.insert(0, str(Path(__file__).parent))
os.environ.update(CLUSTER_ARN="cluster", SECRET_ARN="secret", DATABASE="db",
                  CLIENT_ID="client", OUTBOX_QUEUE="queue", AWS_DEFAULT_REGION="us-east-1")
# All AWS calls are mocked before importing application modules.
sys.modules["boto3"] = MagicMock()
import handler
import contacts
import database
from validation import validate, administrator


def payload(**overrides):
    return {"name": "Example Rider", "email": "rider@example.com", "phone": "+1 555 010 9999",
            "interest": "Sport", "consent": True,
            "requestId": "550e8400-e29b-41d4-a716-446655440000", **overrides}


def event(**overrides):
    return {"httpMethod": "POST", "path": "/api/contact", "body": json.dumps(payload()), **overrides}


def claims(**overrides):
    return {"sub": "user", "aud": "client", "token_use": "id",
            "cognito:groups": "administrators", **overrides}
