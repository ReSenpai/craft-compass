# Changelog

All notable changes to Craft Compass. The text of this file goes into each release's notes.

## Unreleased

- Alt-click on an item link in chat (or anywhere else a link opens the item window) pins it into a window.
  Alt-click on a row of a pinned window opens it nested, like a right click.
- A pinned window of a crafted item starts with what its craft takes, and the reagents are rows like the rest:
  hover one for its tooltip, Alt or right click it for its own window — where it comes from and how it is made.
  The item window a link opens says so.
- The close button of a pinned window works in combat too.

## 0.1.0 — 2026-10-29

First version.

- Shift (or Ctrl) over an item: the recipes it goes into, by profession and skill with how many each takes, and the
  quests that ask for it, filtered to the character's race and class, completed ones marked.
- Alt pins that into a window: rows with tooltips, click for the item window, Shift-click to link items and quests
  in chat, Alt or a right click for a nested window beside it. Long lists scroll; Escape closes the windows.
- What a craft takes, on pinned rows, in the item window and with Shift anywhere: profession and skill, reagents
  with how many you have against how many it needs, and the recipe — trainer, or the recipe item with its vendors,
  drops, containers and quest rewards.
- Data from AtlasLoot Classic (required) and QuestieDB (optional), indexed in the background after login; names in
  the client's language, the addon's own text in English and Russian.
- Settings: only my professions, completed quests, the "not used" line. `/craftcompass`, `/ccompass`.
