#!/usr/bin/env python3
import json
import sys

MISSING = object()


def merge(base, ours, theirs, path, conflicts):
    if ours == theirs:
        return ours
    if ours == base:
        return theirs
    if theirs == base:
        return ours
    if isinstance(ours, dict) and isinstance(theirs, dict):
        base = base if isinstance(base, dict) else {}
        merged = {}
        for key in ordered_keys(ours, theirs):
            value = merge(base.get(key, MISSING), ours.get(key, MISSING), theirs.get(key, MISSING), path + [key], conflicts)
            if value is not MISSING:
                merged[key] = value
        return merged
    conflicts.append((path, ours, theirs))
    return ours


def ordered_keys(ours, theirs):
    keys = list(ours)
    previous = None
    for key in theirs:
        if key not in ours:
            position = keys.index(previous) + 1 if previous in keys else len(keys)
            keys.insert(position, key)
        previous = key
    return keys


def describe(value):
    if value is MISSING:
        return "removed"
    text = json.dumps(value, ensure_ascii=False)
    return text if len(text) <= 120 else text[:117] + "..."


def main():
    base_path, ours_path, theirs_path = sys.argv[1:4]
    documents = []
    for path in (base_path, ours_path, theirs_path):
        with open(path, encoding="utf-8") as file:
            text = file.read()
        documents.append(json.loads(text) if text.strip() else {})

    conflicts = []
    merged = merge(*documents, [], conflicts)

    with open(ours_path, "w", encoding="utf-8") as file:
        file.write(json.dumps(merged, indent=2, separators=(",", " : "), ensure_ascii=False))

    if conflicts:
        sys.stderr.write(f"xcstrings: {len(conflicts)} conflict(s), our side kept for each:\n")
        for path, ours, theirs in conflicts:
            sys.stderr.write(f"  {' > '.join(path)}\n    ours:   {describe(ours)}\n    theirs: {describe(theirs)}\n")
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())
