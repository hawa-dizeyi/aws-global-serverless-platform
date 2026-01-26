import base64
import json
import os
import time
import uuid
from typing import Any, Dict, Optional, Tuple

import boto3

TABLE_NAME = os.environ["TABLE_NAME"]
ddb = boto3.resource("dynamodb")
table = ddb.Table(TABLE_NAME)

SECURITY_HEADERS = {
    # API is always HTTPS via API Gateway custom domain / execute-api
    "strict-transport-security": "max-age=31536000; includeSubDomains; preload",
    "x-content-type-options": "nosniff",
    "referrer-policy": "no-referrer",
    # Minimal CSP for API responses (mostly irrelevant, but harmless and signals maturity)
    "content-security-policy": "default-src 'none'; frame-ancestors 'none'; base-uri 'none'",
    # Don't cache API responses (safer for demos)
    "cache-control": "no-store",
    "content-type": "application/json",
}

ALLOWED_PATHS = ["/health", "/write"]


def _header(event: Dict[str, Any], name: str) -> str:
    # API Gateway headers may be lower/upper/mixed
    headers = event.get("headers") or {}
    for k, v in headers.items():
        if k.lower() == name.lower():
            return v or ""
    return ""


def _apigw_request_id(event: Dict[str, Any]) -> str:
    # HTTP API v2
    rid = (event.get("requestContext") or {}).get("requestId")
    return rid or ""


def _correlation_id(event: Dict[str, Any]) -> str:
    incoming = _header(event, "x-correlation-id").strip()
    return incoming if incoming else str(uuid.uuid4())


def _resp(
    event: Dict[str, Any],
    status: int,
    body: Dict[str, Any],
    extra_headers: Optional[Dict[str, str]] = None,
):
    headers = dict(SECURITY_HEADERS)

    # Observability: correlation / tracing headers
    cid = _correlation_id(event)
    headers["x-correlation-id"] = cid

    rid = _apigw_request_id(event)
    if rid:
        headers["x-apigw-request-id"] = rid

    if extra_headers:
        headers.update(extra_headers)

    return {
        "statusCode": status,
        "headers": headers,
        "body": json.dumps(body),
    }


def _normalize_path(event: Dict[str, Any]) -> str:
    return (event.get("rawPath") or event.get("path") or "/").lower()


def _http_method(event: Dict[str, Any]) -> str:
    return (
        event.get("requestContext", {}).get("http", {}).get("method")
        or event.get("httpMethod")
        or "GET"
    ).upper()


def _parse_json_body(event: Dict[str, Any]) -> Tuple[Optional[Dict[str, Any]], Optional[str]]:
    """
    Returns (json_obj, error_message). If body is empty, returns ({}, None).
    Supports base64-encoded bodies.
    """
    body = event.get("body")
    if body is None or body == "":
        return {}, None

    if event.get("isBase64Encoded"):
        try:
            body = base64.b64decode(body).decode("utf-8", errors="replace")
        except Exception:
            return None, "Invalid base64 body."

    try:
        obj = json.loads(body)
    except Exception:
        return None, "Body must be valid JSON."

    if obj is None:
        return {}, None
    if not isinstance(obj, dict):
        return None, "JSON body must be an object."

    return obj, None


def handler(event, context):
    path = _normalize_path(event)
    method = _http_method(event)

    # Health endpoint
    if path.endswith("/health"):
        return _resp(
            event,
            200,
            {"ok": True, "region": os.environ.get("AWS_REGION"), "table": TABLE_NAME},
        )

    # Write endpoint: POST only
    if path.endswith("/write"):
        if method != "POST":
            return _resp(
                event,
                405,
                {"message": "method not allowed", "allowed": ["POST"]},
                extra_headers={"allow": "POST"},
            )

        content_type = _header(event, "content-type").lower()
        # Accept "application/json; charset=utf-8" etc.
        if "application/json" not in content_type:
            return _resp(
                event,
                415,
                {"message": "unsupported media type", "required": "application/json"},
            )

        # Step S3.2 — Payload size guard (prevents cheap abuse)
        raw_body = event.get("body") or ""
        if len(raw_body) > 4096:
            return _resp(
                event,
                413,
                {"message": "payload too large (max 4KB)"},
            )

        payload, err = _parse_json_body(event)
        if err:
            return _resp(event, 400, {"message": err})

        # Optional: accept pk from body, else default
        pk = payload.get("pk", "demo")
        if not isinstance(pk, str) or not pk.strip():
            return _resp(event, 400, {"message": "pk must be a non-empty string"})
        pk = pk.strip()
        if len(pk) > 64:
            return _resp(event, 400, {"message": "pk too long (max 64 chars)"})

        item_id = str(uuid.uuid4())
        now = int(time.time())
        item = {
            "pk": pk,
            "sk": item_id,
            "createdAt": now,
            "ttl": now + 3600,  # auto-expire in 1 hour
            "region": os.environ.get("AWS_REGION"),
        }

        table.put_item(Item=item)
        return _resp(event, 200, {"written": True, "item": item})

    # Default
    return _resp(event, 404, {"message": "not found", "paths": ALLOWED_PATHS})
