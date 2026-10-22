"""Public create, administrator-only read; never log bodies or exception details."""
import json
import os
from contacts import create_contact
from database import list_contacts
from validation import administrator


def response(status, **body):
    return {"statusCode": status, "headers": {
        "Content-Type": "application/json", "Cache-Control": "no-store"
    }, "body": json.dumps(body)}


def handler(event, context):
    try:
        method, path = event.get("httpMethod"), event.get("path", "")
        if method == "POST" and path == "/api/contact":
            return response(202, **create_contact(event))
        if method == "GET" and path == "/api/people":
            claims = event.get("requestContext", {}).get("authorizer", {}).get("claims", {})
            if not administrator(claims, os.environ["CLIENT_ID"]):
                return response(403, message="Administrator access required.")
            return response(200, **list_contacts(event.get("queryStringParameters") or {}))
        return response(404, message="Not found.")
    except ValueError as error:
        return response(400, message=str(error))
    except Exception:
        print("Contact operation failed", getattr(context, "aws_request_id", "unknown"))
        return response(503, message="Unable to complete your request. Please retry.")
