#!/usr/bin/env python3
import json
import os
import re
import sys
import time
from datetime import datetime

config_dir = os.environ.get("CLAUDE_CONFIG_DIR") or os.path.join(os.path.expanduser("~"), ".claude")
root = os.path.join(config_dir, "projects")
since = float(sys.argv[1]) if len(sys.argv) > 1 else time.time() - 7 * 86400

timestamp_re = re.compile(r'"timestamp":"(\d{4}-\d\d-\d\dT\d\d:\d\d:\d\d(?:\.\d+)?Z?)"')
model_re = re.compile(r'"model":"([^"]+)"')
id_re = re.compile(r'"message":\{[^{}]*?"id":"([^"]+)"')
token_res = {
    "input": re.compile(r'"input_tokens":(\d+)'),
    "output": re.compile(r'"output_tokens":(\d+)'),
    "cacheWrite": re.compile(r'"cache_creation_input_tokens":(\d+)'),
    "cacheRead": re.compile(r'"cache_read_input_tokens":(\d+)'),
}


def parse_time(text):
    try:
        return datetime.fromisoformat(text.replace("Z", "+00:00")).timestamp()
    except ValueError:
        return None


seen = set()
models = {}
files = 0

for dirpath, _, names in os.walk(root):
    for name in names:
        if not name.endswith(".jsonl"):
            continue
        path = os.path.join(dirpath, name)
        try:
            if os.path.getmtime(path) < since:
                continue
            handle = open(path, "r", encoding="utf-8", errors="ignore")
        except OSError:
            continue
        files += 1
        with handle:
            for line in handle:
                if '"usage"' not in line or '"type":"assistant"' not in line:
                    continue
                stamps = timestamp_re.findall(line)
                when = parse_time(stamps[-1]) if stamps else None
                if when is None or when < since:
                    continue
                message_id = id_re.search(line)
                if message_id:
                    key = message_id.group(1)
                    if key in seen:
                        continue
                    seen.add(key)
                model = model_re.search(line)
                model = model.group(1) if model else "unknown"
                if model.startswith("<"):
                    continue
                entry = models.setdefault(model, {"input": 0, "output": 0, "cacheWrite": 0, "cacheRead": 0, "messages": 0})
                for field, regex in token_res.items():
                    match = regex.search(line)
                    if match:
                        entry[field] += int(match.group(1))
                entry["messages"] += 1

json.dump({"since": since, "files": files, "models": models}, sys.stdout)
