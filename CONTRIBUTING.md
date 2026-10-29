# Contributing to Craft Compass

Thanks for taking a look. Bug reports, translations and pull requests are welcome.

## Licensing of contributions

Craft Compass is licensed under the [GNU GPL v3.0 or later](LICENSE). By sending a pull request you agree that your
contribution is licensed under the same terms, and that you have the right to license it.

Sign your commits off with `git commit -s` (the [Developer Certificate of Origin](https://developercertificate.org/)),
which adds a `Signed-off-by` line to the commit message.

## How the repository is laid out

The repository root is the addon itself (the TOC files at the top), so it can be linked straight into the game:

```
mklink /J "C:\Program Files (x86)\World of Warcraft\_classic_era_\Interface\AddOns\CraftCompass" "<path>\craft-compass"
```

- `Core/` — start-up and settings, the lines shown in tooltips and windows, the options panel.
- `Sources/` — reading crafts from AtlasLoot Classic and quests from QuestieDB.
- `UI/` — the tooltip hooks and the pinned windows.
- `Locales/` — the addon's own text.
- `Libs/` — the Ace3 libraries behind the options panel.
- `tests/`, `tools/` — the checks below. Neither goes into the release zip.

## Data

Craft Compass ships no item, recipe or quest data: everything comes from AtlasLoot Classic and QuestieDB while the
game runs. A missing or wrong recipe or quest is usually best fixed in those addons. Please don't add data tables
copied from other addons or websites.

## Translations

A new language is one more file in `Locales/` (like `ruRU.lua`, with the same keys as `enUS.lua`), added to the three
TOC files after `Locales\ruRU.lua`. Item, quest, profession and zone names already come in the client's language.

## Working style

- Test in the game client (Classic Era 1.15); code changes need `/reload`.
- Run the checks before a pull request: `powershell -File tools/test.ps1` (Python with `lupa` and `luaparser`,
  e.g. `pip install --target .tools/pylib lupa luaparser`).
- Every string the player sees goes through `Locales/`.
- Text files use LF line endings and UTF-8 (`.gitattributes`, `.editorconfig`).
