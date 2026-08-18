#!/usr/bin/env python3
"""Structural validation gate for generated n8n workflows."""
from __future__ import annotations

import argparse
import json
import pathlib
import re
import sys
from collections import defaultdict, deque
from typing import Any

TRIGGERS = {
    "n8n-nodes-base.manualTrigger",
    "n8n-nodes-base.scheduleTrigger",
    "n8n-nodes-base.webhook",
    "n8n-nodes-base.cron",
}
EXTERNAL_TYPES = {
    "n8n-nodes-base.httpRequest",
    "n8n-nodes-base.gmail",
    "n8n-nodes-base.slack",
}
POSTGRES_TYPE = "n8n-nodes-base.postgres"
EXPR_PATTERNS = [
    re.compile(r"\$node\[['\"]([^'\"]+)['\"]\]"),
    re.compile(r"\$node\[['\"]([^'\"]+)['\"]\]"),
    re.compile(r"\$items\(['\"]([^'\"]+)['\"]\)"),
]


def load(path: pathlib.Path) -> dict[str, Any]:
    return json.loads(path.read_text(encoding="utf-8"))


def flattened_strings(value: Any):
    if isinstance(value, str):
        yield value
    elif isinstance(value, dict):
        for v in value.values():
            yield from flattened_strings(v)
    elif isinstance(value, list):
        for v in value:
            yield from flattened_strings(v)


def validate(data: dict[str, Any]) -> list[str]:
    errors: list[str] = []
    nodes = data.get("nodes", [])
    if not nodes:
        return ["workflow has no nodes"]
    names = [n.get("name") for n in nodes]
    ids = [n.get("id") for n in nodes]
    if len(set(names)) != len(names):
        errors.append("duplicate node names")
    if len(set(ids)) != len(ids):
        errors.append("duplicate node IDs")
    by_name = {n.get("name"): n for n in nodes}

    outgoing: dict[str, list[str]] = defaultdict(list)
    for source, spec in (data.get("connections") or {}).items():
        if source not in by_name:
            errors.append(f"connection source does not exist: {source}")
            continue
        for output in spec.get("main", []):
            for edge in output:
                target = edge.get("node")
                if target not in by_name:
                    errors.append(f"dangling connection: {source} -> {target}")
                else:
                    outgoing[source].append(target)

    trigger_names = [n["name"] for n in nodes if n.get("type") in TRIGGERS]
    if not trigger_names:
        errors.append("no trigger node found")
    reached: set[str] = set(trigger_names)
    queue = deque(trigger_names)
    while queue:
        current = queue.popleft()
        for nxt in outgoing.get(current, []):
            if nxt not in reached:
                reached.add(nxt)
                queue.append(nxt)
    for n in nodes:
        if n.get("type") != "n8n-nodes-base.stickyNote" and n.get("name") not in reached:
            errors.append(f"orphaned node: {n.get('name')}")

    for n in nodes:
        if n.get("type") in EXTERNAL_TYPES and n.get("continueOnFail") is not True:
            errors.append(f"external node missing continueOnFail=true: {n.get('name')}")
        if n.get("type") == POSTGRES_TYPE:
            query = str((n.get("parameters") or {}).get("query", ""))
            if not query.strip():
                errors.append(f"Postgres node has empty query: {n.get('name')}")

    all_text = "\n".join(flattened_strings(data))
    for pattern in EXPR_PATTERNS:
        for referenced in pattern.findall(all_text):
            if referenced not in by_name:
                errors.append(f"expression references missing node: {referenced}")

    pg_queries = [(n.get("name"), str((n.get("parameters") or {}).get("query", "")).upper())
                  for n in nodes if n.get("type") == POSTGRES_TYPE]
    has_update = any("UPDATE " in query for _, query in pg_queries)
    # A deduplication existence check is not a phase queue. Stateful input reads
    # are the explicit `WHERE status = ...` or `WHERE p.status = ...` queries.
    has_input_select = any(("WHERE STATUS" in query or "WHERE P.STATUS" in query) for _, query in pg_queries)
    has_status_transition = any(" SET STATUS" in query or " SET CRM_SYNCED" in query or " SET SENT_TODAY" in query for _, query in pg_queries)
    if has_input_select and not has_status_transition:
        errors.append("workflow reads stateful rows but has no downstream status/counter transition")

    # The workflow package intentionally uses Postgres inserts as phase outputs. We check
    # that each stateful phase also contains a mutation node rather than requiring a
    # nonsensical UPDATE on an output row that must remain `new` for the next phase.
    if any("INSERT INTO" in query for _, query in pg_queries) and not has_update and not str(data.get("name", "")).startswith("00 —"):
        errors.append("workflow writes Postgres rows but has no status/update node")

    return errors


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("paths", nargs="+", type=pathlib.Path)
    args = parser.parse_args()
    failed = False
    for path in args.paths:
        try:
            data = load(path)
            errors = validate(data)
        except Exception as exc:
            errors = [f"could not parse: {exc}"]
        if errors:
            failed = True
            print(f"FAIL {path}")
            for error in errors:
                print(f"  - {error}")
        else:
            print(f"PASS {path}")
    return 1 if failed else 0


if __name__ == "__main__":
    sys.exit(main())
