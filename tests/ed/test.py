#!/usr/bin/env python3
import sys

packages = ["requests"]
failed = []

for pkg in packages:
    try:
        __import__(pkg)
    except ImportError:
        failed.append(pkg)

if failed:
    sys.stderr.write(f"FAIL: {', '.join(failed)}\n")
    sys.exit(1)

print("PASS: all packages loaded")
