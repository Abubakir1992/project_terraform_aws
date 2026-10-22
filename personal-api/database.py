import os
import re
import boto3

client = boto3.client("rds-data")
SCHEMA = """CREATE TABLE IF NOT EXISTS contact_requests (
request_id CHAR(36) PRIMARY KEY, name VARCHAR(120) NOT NULL,
email VARCHAR(254) NOT NULL, phone VARCHAR(30) NOT NULL,
interest VARCHAR(40) NOT NULL, created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci"""
SAVE = """INSERT IGNORE INTO contact_requests
(request_id, name, email, phone, interest) VALUES
(:request_id, :name, :email, :phone, :interest)"""


def execute(sql, values=None):
    return client.execute_statement(
        resourceArn=os.environ["CLUSTER_ARN"], secretArn=os.environ["SECRET_ARN"],
        database=os.environ["DATABASE"], sql=sql,
        parameters=[{"name": k, "value": {"stringValue": v}}
                    for k, v in (values or {}).items()])


def list_contacts(query):
    cursor = query.get("cursor", "")
    if not isinstance(cursor, str) or (cursor and not re.fullmatch(r"[a-f0-9-]{36}", cursor)):
        raise ValueError("Invalid cursor.")
    execute(SCHEMA)
    result = execute("SELECT request_id,name,email,phone,interest,created_at "
                     "FROM contact_requests WHERE request_id > :cursor "
                     "ORDER BY request_id LIMIT 51", {"cursor": cursor})
    columns = ["request_id", "name", "email", "phone", "interest", "created_at"]
    rows = [{k: v.get("stringValue", "") for k, v in zip(columns, row)}
            for row in result.get("records", [])]
    return {"people": rows[:50], "next_cursor": rows[49]["request_id"] if len(rows) > 50 else ""}
