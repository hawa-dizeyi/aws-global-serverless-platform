import json
import os
import time
import uuid

import boto3

TABLE_NAME = os.environ["TABLE_NAME"]
ddb = boto3.resource("dynamodb")
table = ddb.Table(TABLE_NAME)


def _resp(status: int, body: dict):
    return {
        "statusCode": status,
        "headers": {"content-type": "application/json"},
        "body": json.dumps(body),
    }


def handler(event, context):
    path = (event.get("rawPath") or event.get("path") or "/").lower()
    method = (
        event.get("requestContext", {}).get("http", {}).get("method")
        or event.get("httpMethod")
        or "GET"
    ).upper()

    if path.endswith("/health"):
        return _resp(200, {"ok": True, "region": os.environ.get("AWS_REGION"), "table": TABLE_NAME})

    if path.endswith("/write") and method in ("POST", "GET"):
        item_id = str(uuid.uuid4())
        now = int(time.time())
        item = {
            "pk": "demo",
            "sk": item_id,
            "createdAt": now,
            "ttl": now + 3600,  # auto-expire in 1 hour
            "region": os.environ.get("AWS_REGION"),
        }
        table.put_item(Item=item)
        return _resp(200, {"written": True, "item": item})

    return _resp(404, {"message": "not found", "paths": ["/health", "/write"]})
