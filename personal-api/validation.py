import json
import re
import uuid

CATEGORIES = {"All motorcycles", "Sport", "Heritage", "Adventure"}


def validate(event):
    raw = event.get("body") or ""
    if event.get("isBase64Encoded") or not isinstance(raw, str) or len(raw.encode()) > 4096:
        raise ValueError("Invalid request body.")
    try:
        data = json.loads(raw)
    except (ValueError, TypeError):
        raise ValueError("Invalid JSON.")
    limits = {"name": 120, "email": 254, "phone": 30, "interest": 40, "requestId": 36}
    if not isinstance(data, dict) or set(data) != set(limits) | {"consent"}:
        raise ValueError("Complete all required fields.")
    for key, limit in limits.items():
        value = data[key]
        if not isinstance(value, str) or not value.strip() or len(value) > limit:
            raise ValueError("Invalid field length.")
        if any(ord(c) < 32 for c in value):
            raise ValueError("Invalid characters.")
        data[key] = value.strip()
    if not re.fullmatch(r"[^\s@]+@[^\s@]+\.[^\s@]+", data["email"]):
        raise ValueError("Enter a valid email.")
    if not re.fullmatch(r"[+()\d .-]{7,30}", data["phone"]):
        raise ValueError("Enter a valid phone number.")
    if data["interest"] not in CATEGORIES or data["consent"] is not True:
        raise ValueError("Choose an interest and agree to a callback.")
    try:
        if str(uuid.UUID(data["requestId"])) != data["requestId"]:
            raise ValueError()
    except ValueError:
        raise ValueError("Invalid request ID.")
    return data


def administrator(claims, client_id):
    if claims.get("aud") != client_id or claims.get("token_use") != "id":
        return False
    groups = claims.get("cognito:groups", [])
    if isinstance(groups, str):
        groups = [x for x in re.split(r'[\s,\[\]\"]+', groups) if x]
    return isinstance(groups, list) and "administrators" in groups
