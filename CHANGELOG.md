# Changelog

All notable changes to Craft Compass. The text of this file goes into each release's notes.

## 0.5.4 — 2026-11-05

- On World of Warcraft: Forever, the Wowhead row now leads to Wowhead's Forever pages (`wowhead.com/forever/...`)
  instead of the Classic ones.

## 0.5.3 — 2026-11-04

- With AtlasLoot Classic and AtlasLoot Continued both enabled, Craft Compass says at login, in chat, that they break
  each other and one of them should be disabled. On CurseForge, AtlasLoot Continued is now the dependency that the
  CurseForge app installs along with Craft Compass.

## 0.5.2 — 2026-11-04

- Works with AtlasLoot Continued, the most up to date AtlasLoot for Classic: it installs into its own folder, and
  Craft Compass used to require the folder of AtlasLoot Classic. AtlasLoot Classic and its maintained fork still work;
  the original hasn't been updated since 2023. Without any AtlasLoot, Craft Compass now loads anyway, shows quests and
  says in chat that recipes need AtlasLoot.
- Season of Discovery recipes on Season of Discovery realms, with AtlasLoot Continued or the AtlasLoot Classic fork.
  Their spells have ids the craft index didn't reach; on other realms they stay out, though AtlasLoot lists them with
  Classic Era's.

## 0.5.1 — 2026-11-04

- The items a quest's window says to bring no longer show "0/0" marked as done: Questie mostly doesn't know how many
  a quest asks for (it's in the quest's text), so the window now shows how many you have.

## 0.5.0 — 2026-11-03

- A click on a quest (or Alt over it, or a right click) opens its window: level and zone, whether it's done or in your
  log, what it says to do, who gives it and who takes it back, the items to bring with how many you have, the quests
  before and after it in the chain (they open too) and its Wowhead page. Shift-click still links it in chat.
- With Questie itself loaded, hovering a quest shows Questie's tooltip of it, and the quest's window has an "Open in
  Questie" row for Questie's own window of the quest.
- The Wowhead address dialog keeps its size: it used to grow wider each time it was opened, until it ran off the
  screen, and a long address stuck out of its box.

## 0.4.0 — 2026-11-03

- Drag a nested window away and it stays on its own: closing the window it came from no longer closes it, and that
  window opens its rows in a new nested one.
- No more "Drops from", "Found in" and "Contained in" lines. Outside quest items, the data behind them comes from
  private-server databases and was too often wrong (rogue quest mobs "dropping" herbs). Where to get an item now
  shows the gathering profession and zones, vendors and quest rewards.
- No more "Not used in any recipe or quest" line and its setting: the sources don't know every use, so it was a
  guess.
- Instead of drops, the last row of a pinned window is the item's Wowhead page: click it and press Ctrl+C to copy
  the address, on the site of your game version and in your client's language. The dialog closes by itself.
- Enchants open in pinned windows too: Alt over an enchant row (or Alt-click, or a right click) shows what it does,
  what it takes, where its formula comes from and its Wowhead page. Hovering an enchant row shows its tooltip.
- Herbs and ores show every zone they grow in. Questie clears the spawn points of the most common herbs and veins
  (Peacebloom, Briarthorn, copper, tin, iron...), so only a zone or two used to show.
- The list of zones no longer shows how many spawn points each has: the numbers come from private-server data and
  don't match the live realms. The richest zones still come first.

## 0.3.0 — 2026-11-01

- Where an item comes from, with Shift, in pinned windows and in the item window: herbs, ore, stone, leather and
  hides show the gathering profession and the skill they need, and herbs and ore the zones they grow in. Any item
  shows who sells it, which creatures drop it, what it is found or contained in and which quest rewards it.
- In a pinned window every source line opens the whole list in a nested window: all vendors (the other
  faction's greyed out), all creatures with their level and zones, all objects, containers and quests, and every
  zone with how many spawn points it has.
- Long source lines wrap in pinned windows instead of making them wider and wider.
- NPCs and objects show every zone they appear in, so the Darkmoon Faire's vendors show both of theirs.
- Long drop lists no longer slow tooltips down: only the names shown are looked up.
- The source lines of a recipe are no longer indented, which pushed them to the right.

## 0.2.0 — 2026-10-31

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
