"""Checks that a version can be released: the three TOC files carry the same ## Version, and
CHANGELOG.md has a section for it.

Usage:
  python tools/release_check.py                          check
  python tools/release_check.py --print-version          print the version
  python tools/release_check.py --require-new-version origin/main
      also fail when the addon's files changed since that commit but the version did not
"""
import argparse
import pathlib
import re
import subprocess
import sys

ROOT = pathlib.Path(__file__).resolve().parent.parent
TOCS = ("CraftCompass_Vanilla.toc", "CraftCompass_TBC.toc", "CraftCompass.toc")
# What goes into the zip and so needs a new version when it changes
ADDON_PATHS = ("Core/", "Libs/", "Locales/", "Sources/", "UI/", *TOCS)
VERSION_LINE = re.compile(r"^## Version:\s*(\S+)\s*$", re.MULTILINE)


def toc_version(text):
    match = VERSION_LINE.search(text)
    return match.group(1) if match else None


def git(*args):
    return subprocess.run(["git", *args], cwd=ROOT, capture_output=True, text=True, encoding="utf-8", check=True).stdout


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--print-version", action="store_true")
    parser.add_argument("--require-new-version", metavar="BASE")
    args = parser.parse_args()

    errors = []
    versions = {toc: toc_version((ROOT / toc).read_text(encoding="utf-8")) for toc in TOCS}
    version = versions[TOCS[0]]
    if not version or not re.fullmatch(r"\d+\.\d+\.\d+", version):
        errors.append(f"{TOCS[0]}: no ## Version: X.Y.Z line")
    for toc, other in versions.items():
        if other != version:
            errors.append(f"{toc}: version {other}, {TOCS[0]} has {version}")

    changelog = (ROOT / "CHANGELOG.md").read_text(encoding="utf-8")
    if version and not re.search(rf"^## {re.escape(version)}\b", changelog, re.MULTILINE):
        errors.append(f"CHANGELOG.md: no section '## {version}'")

    if args.require_new_version and version:
        base = args.require_new_version
        changed = [path for path in git("diff", "--name-only", f"{base}...HEAD").splitlines()
                   if path.startswith(ADDON_PATHS)]
        base_version = toc_version(git("show", f"{base}:{TOCS[0]}"))
        if changed and base_version == version:
            errors.append(f"the addon changed ({', '.join(changed[:5])}) but the version is still {version}:"
                          " raise ## Version in the TOC files and add a CHANGELOG.md section")

    if errors:
        for error in errors:
            print("release: " + error, file=sys.stderr)
        sys.exit(1)
    print(version if args.print_version else f"release: ok ({version})")


if __name__ == "__main__":
    main()
