"""Parses every Lua file of the addon (not Libs/) and reports syntax errors."""
import pathlib
import sys

from luaparser import ast

ROOT = pathlib.Path(__file__).resolve().parent.parent
failed = False
for path in sorted(ROOT.glob("*/*.lua")):
    if path.parts[-2] in ("Libs", "tests", "tools", ".tools"):
        continue
    try:
        ast.parse(path.read_text(encoding="utf-8"))
    except Exception as error:  # luaparser raises its own error types
        failed = True
        print(f"{path.relative_to(ROOT)}: {error}")
print("syntax: " + ("FAILED" if failed else "ok"))
sys.exit(1 if failed else 0)
