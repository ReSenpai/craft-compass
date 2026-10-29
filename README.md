# Craft Compass

**What is this item for, and what does it take to make that? A tooltip and pinned windows for World of Warcraft
Classic.**

**English** · [Русский](README.ru.md)

Hover a herb, an ore or a piece of cloth and see every recipe and quest that uses it. Pin that list into a window,
follow a potion into what *it* is used for, and see for any craftable item which profession makes it, which
reagents it needs and how many of them you already carry, and where its recipe comes from — so you know what to
gather before you ask a crafter.

[![WoW Classic Era](https://img.shields.io/badge/WoW-Classic%20Era%201.15-c79c6e)](#compatibility)
[![License: GPL v3](https://img.shields.io/badge/License-GPLv3-blue.svg)](LICENSE)

## What does it do?

- **Uses in the tooltip.** Hold **Shift** (or Ctrl) over an item: the recipes it goes into, by profession and skill
  with how many of it each takes, and the quests that ask for it, the completed ones marked.
- **Pinned windows.** Hold **Alt** over an item to pin that list into a window that stays on screen. Hover a row for
  its tooltip, click it for the item window, **Shift-click** to link it in chat. Alt over a row (or a right click)
  opens a nested window beside it, as deep as you like. Long lists scroll; Escape closes them all.
- **What a craft takes.** Hover a craftable item in a pinned window, click it, or hold Shift over it anywhere: the
  profession and skill that make it, every reagent with how many you have (bags and bank) against how many it needs,
  and its recipe — taught by the trainer, or the recipe item and who sells it, which creatures drop it, where it is
  found and which quest rewards it.
- **Quests in chat.** Shift-click a quest in a pinned window to link it in chat, in the `[Name (id)]` form Questie
  turns into a clickable quest link.
- **Any client language.** Everything is looked up by id, and item, quest, profession and zone names come in the
  client's language. The addon's own text is in English and Russian.

## Requirements

| Addon | | What it gives |
| --- | --- | --- |
| [AtlasLoot Classic](https://www.curseforge.com/wow/addons/atlaslootclassic) | required | Recipes, reagents and recipe items |
| [Questie](https://www.curseforge.com/wow/addons/questie) (QuestieDB) | optional | Quests, and where a recipe comes from |

Craft Compass carries no item data of its own: it reads them from these addons while the game runs, so it stays as
up to date as they are. Without Questie there are no quests and a recipe is shown without its sources.

## Installation

Download the zip of a release and unpack it into `World of Warcraft\_classic_era_\Interface\AddOns`, so that you get
`Interface\AddOns\CraftCompass\CraftCompass_Vanilla.toc`.

To run it straight from a clone of this repository, link the clone into the AddOns folder under the addon's name
(from a Command Prompt):

```bat
mklink /J "C:\Program Files (x86)\World of Warcraft\_classic_era_\Interface\AddOns\CraftCompass" "C:\path\to\craft-compass"
```

Settings: `/craftcompass` or `/ccompass`, or the AddOns tab of the game options.

## Compatibility

- **Classic Era** (1.15): `CraftCompass_Vanilla.toc`.
- **Burning Crusade Anniversary**: `CraftCompass_TBC.toc`.
- **Classic Forever**: `CraftCompass.toc`, as far as AtlasLoot and Questie support it.

Recipes are what AtlasLoot Classic knows about; Season of Discovery's own recipes aren't in it.

## How it works

- `Sources/AtlasLoot.lua` — after login, goes through AtlasLoot's crafts once in the background and indexes them by
  reagent and by created item.
- `Sources/Questie.lua` — the same for QuestieDB's quests, indexed by the items they ask for; quest, NPC and zone
  names.
- `Core/Lines.lua` — builds the lines for "what is this for" and "what does this craft take".
- `UI/Tooltip.lua` — the tooltip hooks; `UI/PinWindow.lua` — the pinned windows; `Core/Options.lua` — the settings.
- `Libs/` — the Ace3 libraries behind the options panel.

Checks: `powershell -File tools/test.ps1` parses the Lua files, runs a smoke test against stubbed game and addon
APIs in English and Russian, and builds the craft index over an installed AtlasLoot Classic (needs Python with
`lupa` and `luaparser`, e.g. `pip install --target .tools/pylib lupa luaparser`).

Releases: raise `## Version` in the three TOC files and add a section for it to `CHANGELOG.md`; once that is on
`main`, `.github/workflows/release.yml` tags it and the [BigWigs packager](https://github.com/BigWigsMods/packager)
builds the zip and publishes it on GitHub (and on CurseForge). Pull requests are checked by
`.github/workflows/checks.yml`.

## License

Craft Compass is free software under the [GNU General Public License v3.0](LICENSE) or later; see [NOTICE](NOTICE)
for what it covers and the libraries it ships. Contributions are welcome, see [CONTRIBUTING](CONTRIBUTING.md).

Craft Compass is an unofficial fan project, not affiliated with or endorsed by Blizzard Entertainment.
