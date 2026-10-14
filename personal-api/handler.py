"""Save one personal-data record per authenticated Cognito user, using RDS Data API."""
import json
import os
import re

import boto3

client = boto3.client("rds-data")
schema_ready = False
SCHEMA = """CREATE TABLE IF NOT EXISTS people (
  owner_sub VARCHAR(64) PRIMARY KEY,
  full_name VARCHAR(120) NOT NULL,
  email VARCHAR(254) NOT NULL,
  phone VARCHAR(30) NOT NULL,
  address VARCHAR(500) NOT NULL,
  updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci"""
SAVE = """INSERT INTO people (owner_sub, full_name, email, phone, address)
VALUES (:owner_sub, :full_name, :email, :phone, :address)
ON DUPLICATE KEY UPDATE full_name = VALUES(full_name), email = VALUES(email),
phone = VALUES(phone), address = VALUES(address)"""


def response(status, message, **data):
    return {"statusCode": status, "headers": {
        "content-type": "application/json", "cache-control": "no-store"
    }, "body": json.dumps({"message": message, **data})}


def execute(sql, parameters=None):
    return client.execute_statement(
        resourceArn=os.environ["CLUSTER_ARN"], secretArn=os.environ["SECRET_ARN"],
        database=os.environ["DATABASE"], sql=sql, parameters=parameters or []
    )


def administrator(claims):
    groups = claims.get("cognito:groups", [])
    if isinstance(groups, str):
        try:
            groups = json.loads(groups)
        except ValueError:
            # HTTP API may stringify array claims as [group-a group-b].
            groups = [part for part in re.split(r'[\s,\[\]\"]+', groups) if part]
    return isinstance(groups, list) and "administrators" in groups


def read_people(event, claims, owner):
    global schema_ready
    path = event.get("rawPath", "/personal-data")
    columns = ["owner_sub", "full_name", "email", "phone", "address", "updated_at"]
    if path == "/people":
        if not administrator(claims):
            return response(403, "Administrator access is required to view all people.")
        cursor = (event.get("queryStringParameters") or {}).get("cursor", "")
        if not isinstance(cursor, str) or (cursor and not re.fullmatch(r"[A-Za-z0-9-]{1,64}", cursor)):
            return response(400, "Invalid page cursor.")
        sql = "SELECT " + ", ".join(columns) + " FROM people WHERE owner_sub > :cursor ORDER BY owner_sub LIMIT 51"
        parameters = [{"name": "cursor", "value": {"stringValue": cursor}}]
    elif path == "/personal-data":
        sql = "SELECT " + ", ".join(columns) + " FROM people WHERE owner_sub = :owner_sub"
        parameters = [{"name": "owner_sub", "value": {"stringValue": owner}}]
    else:
        return response(404, "Not found.")
    try:
        if not schema_ready:
            execute(SCHEMA)
            schema_ready = True
        result = execute(sql, parameters)
        people = [{column: field.get("stringValue", "") for column, field in zip(columns, row)}
                  for row in result.get("records", [])]
        next_cursor = people[49]["owner_sub"] if len(people) > 50 else ""
        return response(200, "Saved details loaded.", people=people[:50], next_cursor=next_cursor)
    except Exception:
        return response(503, "Could not load saved details. Please try again.")


def handler(event, context):
    global schema_ready
    claims = event.get("requestContext", {}).get("authorizer", {}).get("jwt", {}).get("claims", {})
    owner = claims.get("sub", "")
    if not isinstance(owner, str) or not re.fullmatch(r"[A-Za-z0-9-]{1,64}", owner):
        return response(401, "Sign in before saving your details.")
    method = event.get("requestContext", {}).get("http", {}).get("method")
    if method == "GET":
        return read_people(event, claims, owner)
    if method != "PUT":
        return response(405, "Method not allowed.")
    raw = event.get("body") or ""
    if event.get("isBase64Encoded") or not isinstance(raw, str) or len(raw.encode("utf-8")) > 8192:
        return response(400, "Invalid request body.")
    try:
        data = json.loads(raw)
        limits = {"full_name": 120, "email": 254, "phone": 30, "address": 500}
        if not isinstance(data, dict) or set(data) != set(limits):
            raise ValueError()
        for key, limit in limits.items():
            if not isinstance(data[key], str):
                raise ValueError()
            data[key] = data[key].strip()
            if len(data[key]) > limit or "\x00" in data[key]:
                raise ValueError()
        if not data["full_name"] or not re.fullmatch(r"[^\s@]+@[^\s@]+\.[^\s@]+", data["email"]):
            raise ValueError()
    except (ValueError, TypeError):
        return response(400, "Enter a name and valid email within the field limits.")
    try:
        if not schema_ready:
            execute(SCHEMA)
            schema_ready = True
        values = {"owner_sub": owner, **data}
        execute(SAVE, [{"name": key, "value": {"stringValue": value}} for key, value in values.items()])
    except Exception:
        # Do not log payloads, SQL parameters, tokens, or database exception text.
        print("Personal-data save failed; request ID:", getattr(context, "aws_request_id", "unknown"))
        return response(503, "Could not save your details. Please try again.")
    return response(200, "Your details have been saved.")
