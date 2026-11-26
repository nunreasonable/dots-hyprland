#!/usr/bin/env python3
import glob
import json
import os
import re
import sys

TAIL_BYTES = 2_000_000
HEAD_BYTES = 65_536
MAX_SESSIONS = 40


def claude_dir():
    return os.environ.get("CLAUDE_CONFIG_DIR") or os.path.expanduser("~/.claude")


def lines_of(path, start, length, skip_first):
    with open(path, "rb") as fh:
        fh.seek(start)
        data = fh.read(length).decode("utf-8", "replace")
    lines = data.split("\n")
    if skip_first:
        lines = lines[1:]
    return lines


def text_of(content):
    if isinstance(content, str):
        return content
    if isinstance(content, list):
        return " ".join(c.get("text", "") for c in content if isinstance(c, dict) and c.get("type") == "text")
    return ""


def head_info(path):
    cwd = ""
    prompt = ""
    for line in lines_of(path, 0, HEAD_BYTES, False):
        if '"cwd"' not in line and '"custom-title"' not in line:
            continue
        try:
            entry = json.loads(line)
        except ValueError:
            continue
        if not cwd and entry.get("cwd"):
            cwd = entry["cwd"]
        if entry.get("type") == "custom-title" and not prompt:
            prompt = entry.get("customTitle", "")
        elif entry.get("type") == "user" and not entry.get("isMeta") and not prompt:
            text = text_of(entry.get("message", {}).get("content")).strip()
            if text and not text.startswith("<"):
                prompt = text
        if cwd and prompt:
            break
    return cwd, prompt


def session(path):
    size = os.path.getsize(path)
    start = max(0, size - TAIL_BYTES)
    info = {
        "id": os.path.splitext(os.path.basename(path))[0],
        "file": path,
        "mtime": int(os.path.getmtime(path)),
        "cwd": "",
        "title": "",
        "lastPrompt": "",
        "model": "",
        "effort": "",
        "contextTokens": 0,
        "costUsd": 0,
        "tasks": [],
    }
    creates = {}
    tasks = {}
    order = []
    last_cwd = ""
    for line in lines_of(path, start, TAIL_BYTES, start > 0):
        if not line:
            continue
        try:
            entry = json.loads(line)
        except ValueError:
            continue
        kind = entry.get("type")
        if entry.get("cwd"):
            last_cwd = entry["cwd"]
        if kind == "custom-title":
            info["title"] = entry.get("customTitle", "")
        elif kind == "last-prompt":
            info["lastPrompt"] = entry.get("lastPrompt", "")
        elif kind == "cost-state":
            info["costUsd"] = entry.get("totalCostUSD") or 0
        elif kind == "assistant":
            message = entry.get("message", {})
            usage = message.get("usage")
            if usage and not entry.get("isSidechain"):
                info["model"] = message.get("model") or info["model"]
                info["effort"] = entry.get("effort") or info["effort"]
                info["contextTokens"] = sum(usage.get(k) or 0 for k in ("input_tokens", "cache_read_input_tokens", "cache_creation_input_tokens"))
            for block in message.get("content") or []:
                if not isinstance(block, dict) or block.get("type") != "tool_use":
                    continue
                if block.get("name") == "TaskCreate":
                    creates[block.get("id")] = block.get("input") or {}
                elif block.get("name") == "TaskUpdate":
                    data = block.get("input") or {}
                    task = tasks.get(str(data.get("taskId")))
                    if task and data.get("status"):
                        task["status"] = data["status"]
        elif kind == "user":
            result = entry.get("toolUseResult")
            if not isinstance(result, dict) or not isinstance(result.get("task"), dict):
                continue
            for block in entry.get("message", {}).get("content") or []:
                if isinstance(block, dict) and block.get("type") == "tool_result" and block.get("tool_use_id") in creates:
                    created = creates[block["tool_use_id"]]
                    task_id = str(result["task"].get("id"))
                    tasks[task_id] = {
                        "id": task_id,
                        "subject": result["task"].get("subject") or created.get("subject", ""),
                        "activeForm": created.get("activeForm", ""),
                        "status": "pending",
                    }
                    order.append(task_id)
    info["tasks"] = [tasks[t] for t in order if tasks[t]["status"] != "deleted"]
    info["cwd"], prompt = head_info(path)
    info["cwd"] = info["cwd"] or last_cwd
    if not info["title"]:
        info["title"] = prompt or info["lastPrompt"]
    info["title"] = re.sub(r"\s+", " ", info["title"]).strip()[:200]
    info["lastPrompt"] = re.sub(r"\s+", " ", info["lastPrompt"]).strip()[:400]
    return info


def main():
    files = glob.glob(os.path.join(claude_dir(), "projects", "*", "*.jsonl"))
    files.sort(key=os.path.getmtime, reverse=True)
    sessions = []
    for path in files[:MAX_SESSIONS]:
        try:
            sessions.append(session(path))
        except OSError:
            continue
    json.dump({"sessions": sessions}, sys.stdout, ensure_ascii=False)


if __name__ == "__main__":
    main()
