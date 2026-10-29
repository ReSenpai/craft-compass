# Runs the checks: Lua syntax, the smoke test in enUS and ruRU, and the craft index over the
# installed AtlasLoot Classic. Python libraries (lupa, luaparser) are looked up in .tools/pylib,
# then in the usual places: pip install --target .tools/pylib lupa luaparser
$ErrorActionPreference = "Stop"
$root = Split-Path -Parent $PSScriptRoot
$env:PYTHONPATH = Join-Path $root ".tools\pylib"
$env:PYTHONIOENCODING = "utf-8"

python (Join-Path $root "tests\check_syntax.py")
if ($LASTEXITCODE -ne 0) { exit 1 }
foreach ($locale in "enUS", "ruRU") {
    python (Join-Path $root "tests\smoke.py") $locale
    if ($LASTEXITCODE -ne 0) { exit 1 }
}
python (Join-Path $root "tests\atlasloot_index.py") @args
if ($LASTEXITCODE -ne 0) { exit 1 }
