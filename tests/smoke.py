"""Loads Craft Compass's files in TOC order against stubbed WoW, AtlasLoot and QuestieDB APIs and exercises them.

Usage: python tests/smoke.py [enUS|ruRU]
"""
import pathlib
import sys

import lupa

ROOT = pathlib.Path(__file__).resolve().parent.parent
lua = lupa.LuaRuntime(unpack_returned_tuples=True)

STUBS = r"""
unpack = table.unpack
EVENTS = {}
local function NewFrame(kind, name)
    local f = {shown = true, scripts = {}, points = 0, w = 0, h = 0}
    local mt = {}
    mt.__index = function(t, k)
        if not k:match('^%u') then return nil end
        return function(self, ...)
            if k == "RegisterEvent" then EVENTS[#EVENTS+1] = {self, (...)}
            elseif k == "SetScript" then local s, fn = ...; self.scripts[s] = fn
            elseif k == "GetScript" then return self.scripts[(...)]
            elseif k == "Show" then self.shown = true
            elseif k == "Hide" then
                if self.shown and self.scripts.OnHide then self.shown = false; self.scripts.OnHide(self) end
                self.shown = false
            elseif k == "IsShown" then return self.shown
            elseif k == "SetShown" then self.shown = (...)
            elseif k == "CreateFontString" or k == "CreateTexture" then
                local fs = NewFrame("FontString"); fs.text = "";
                return fs
            elseif k == "SetText" then self.text = (...)
            elseif k == "GetText" then return self.text
            elseif k == "GetStringWidth" then return #(self.text or "") * 6
            elseif k == "SetHeight" then self.h = (...)
            elseif k == "GetHeight" then return self.h
            elseif k == "SetSize" then self.w, self.h = ...
            elseif k == "SetWidth" then self.w = (...)
            elseif k == "GetWidth" then return self.w
            elseif k == "GetVerticalScrollRange" then return 0
            elseif k == "GetVerticalScroll" then return 0
            elseif k == "GetRight" then return 500
            elseif k == "HasScript" then return true
            elseif k == "HookScript" then local s, fn = ...; self.scripts[s] = fn
            elseif k == "GetName" then return self.name
            end
        end
    end
    setmetatable(f, mt)
    f.name = name
    return f
end
CreateFrame = function(kind, name) local f = NewFrame(kind, name); if name then _G[name] = f end; return f end
UIParent = NewFrame("Frame"); UIParent.GetHeight = function() return 1000 end; UIParent.GetRight = function() return 1900 end
UISpecialFrames = {}
BackdropTemplateMixin = {}
C_Timer = {NewTicker = function(_, fn) return {Cancel = function() end} end, After = function(_, fn) fn() end}
geterrorhandler = function() return function(e) error(e) end end
GetLocale = function() return LOCALE end
UnitRace = function() return "Human", "Human", 1 end
UnitClass = function() return "Warrior", "WARRIOR", 1 end
UnitFactionGroup = function() return "Alliance" end
GetNumSkillLines = function() return 1 end
GetSkillLineInfo = function() return "Leatherworking" end
local names = {[2318] = "Light Leather", [2320] = "Coarse Thread", [2302] = "Handstitched Leather Boots", [9999] = "Pattern: Boots"}
GetItemInfo = function(id) if names[id] then return names[id], "|cffffffff|Hitem:" .. id .. "::::|h[" .. names[id] .. "]|h|r" end end
GetItemIcon = function(id) return 134000 + id end
GetItemCount = function(id) return id == 2318 and 5 or 0 end
GetSpellInfo = function(id) return ({[2108] = "Leatherworking", [2259] = "Alchemy"})[id] or ("Spell" .. id) end
GetSpellTexture = function(id) return 1000 + id end
GetSpellLink = function(id) return "|cff71d5ff|Hspell:" .. id .. "|h[Spell" .. id .. "]|h|r" end
C_QuestLog = {IsQuestFlaggedCompleted = function(id) return id == 101 end}
C_Map = {GetAreaInfo = function(id) return "Zone" .. id end}
IsAltKeyDown = function() return ALT end
IsShiftKeyDown = function() return SHIFT end
IsControlKeyDown = function() return false end
IsModifiedClick = function() return true end
ChatEdit_InsertLink = function(t) INSERTED = t; return true end
SetItemRef = function(link) ITEMREF = link end
hooksecurefunc = function(name, hook)
    local original = _G[name]
    _G[name] = function(...) local r = {original(...)}; hook(...); return unpack(r) end
end
LibStub = setmetatable({}, {__call = function(_, name)
    return {RegisterOptionsTable = function() end, AddToBlizOptions = function() end, Open = function() OPENED = true end}
end})
SlashCmdList = {}
GameTooltip = NewFrame("GameTooltip", "GameTooltip")
ItemRefTooltip = NewFrame("GameTooltip", "ItemRefTooltip")
TOOLTIP_LINES = {}
for _, tt in ipairs({GameTooltip, ItemRefTooltip}) do
    tt.AddLine = function(self, t) table.insert(TOOLTIP_LINES, t) end
    tt.AddDoubleLine = function(self, l, r) table.insert(TOOLTIP_LINES, l .. " || " .. r) end
    tt.SetOwner = function(self, owner) self.owner = owner end
    tt.GetOwner = function(self) return self.owner end
    tt.GetItem = function(self) return self.itemName, self.itemLink end
    tt.SetHyperlink = function(self, data) end
end

-- AtlasLoot: two crafts using Light Leather
AtlasLoot = {Data = {
    Profession = {GetProfessionData = function(id)
        if id == 2149 then return {2302, 3, 1, 40, 70, {2318, 2320}, {2, 1}} end
        if id == 2152 then return {nil, 3, 30, 30, 60, {2318}, {3}} end
    end},
    Recipe = {GetRecipeForSpell = function(id) if id == 2149 then return 9999 end end}
}}
-- QuestieDB
local quests = {
    [100] = {name = "Leather for the Smith", questLevel = 12, objectives = {nil, nil, {{2318, nil, 10}}}, zoneOrSort = 12},
    [101] = {name = "Old Leather Quest", questLevel = 8, objectives = {nil, nil, {{2318, nil, 4}}}},
    [102] = {name = "Horde Only", questLevel = 10, requiredRaces = 2, objectives = {nil, nil, {{2318}}}},
}
LibQuestieDB = {
    Quest = {GetAllIds = function() return {100, 101, 102} end, Get = function(id, f) return quests[id] and quests[id][f] end},
    Item = {Get = function(id, f) if id == 9999 and f == "vendors" then return {1, 2} end if id == 9999 and f == "npcDrops" then return {3, 4, 5} end end},
    Npc = {Get = function(id, f) if f == "name" then return "Npc" .. id end if f == "zoneID" then return 40 end if f == "friendlyToFaction" then return id == 1 and "H" or "A" end end},
    Object = {Get = function() end},
}
"""
lua.execute(f"LOCALE = '{sys.argv[1] if len(sys.argv) > 1 else 'enUS'}'")
lua.execute(STUBS)

toc = (ROOT / "CraftCompass_Vanilla.toc").read_text(encoding="utf-8").splitlines()
files = [line.strip() for line in toc if line.strip() and not line.startswith("#") and line.endswith(".lua")]
lua.execute("NS = {}")
for f in files:
    code = (ROOT / f.replace("\\", "/")).read_text(encoding="utf-8")
    chunk = lua.eval("function(code, name) return assert(load(code, '@' .. name)) end")(code, f)
    lua.eval("function(chunk) chunk('CraftCompass', NS) end")(chunk)
    print("loaded", f)

lua.execute(r"""
function FIRE(event, arg)
    for _, entry in ipairs(EVENTS) do
        if entry[2] == event and entry[1].scripts.OnEvent then
            entry[1].scripts.OnEvent(entry[1], event, arg)
        end
    end
end
""")
result = lua.execute(r"""
local ns = NS
local out = {}
local function p(s) out[#out + 1] = tostring(s) end
local function dump(title) p("--- " .. title); for _, l in ipairs(TOOLTIP_LINES) do p(l) end; TOOLTIP_LINES = {} end

FIRE("ADDON_LOADED", "CraftCompass")
FIRE("PLAYER_LOGIN")
p("settings.showNotUsed=" .. tostring(ns.settings.showNotUsed) .. " db=" .. tostring(CraftCompassDB ~= nil))
p("slash=" .. tostring(SLASH_CRAFTCOMPASS1)); SlashCmdList.CRAFTCOMPASS(""); p("opened=" .. tostring(OPENED))

p("ForReagent(2318) = " .. #ns.Crafts.ForReagent(2318) .. " ForCreatedItem(2302) = " .. tostring(ns.Crafts.ForCreatedItem(2302)))
p("ForItem(2318) = " .. #ns.Quests.ForItem(2318))

-- Shift over Light Leather in a bag
GameTooltip.owner = UIParent
GameTooltip.itemName, GameTooltip.itemLink = GetItemInfo(2318)
SHIFT, ALT = true, false
GameTooltip.scripts.OnTooltipSetItem(GameTooltip)
dump("shift over Light Leather")

-- Shift over the boots: craft info and uses
GameTooltip.itemName, GameTooltip.itemLink = GetItemInfo(2302)
GameTooltip.scripts.OnTooltipSetItem(GameTooltip)
dump("shift over boots")

-- Alt over Light Leather pins a window
SHIFT, ALT = false, true
GameTooltip.itemName, GameTooltip.itemLink = GetItemInfo(2318)
GameTooltip.scripts.OnTooltipSetItem(GameTooltip)
local w = CraftCompassWindow1; if not w then p("NO WINDOW"); return table.concat(out, string.char(10)) end
p("window1 shown=" .. tostring(w and w.shown) .. " rows=" .. #w.rows)
for i, row in ipairs(w.rows) do p(string.format("  row %d: %s | %s link=%s quest=%s", i, row.text.text, row.right.text, tostring(row.link ~= nil), tostring(row.quest))) end

-- hover a recipe row, right click it for a nested window, shift-click a quest row
local recipeRow
for _, row in ipairs(w.rows) do if row.link and row.link:find("item:2302") then recipeRow = row end end
GameTooltip.itemName, GameTooltip.itemLink = GetItemInfo(2302)
recipeRow.scripts.OnEnter(recipeRow)
GameTooltip.scripts.OnTooltipSetItem(GameTooltip)
dump("alt-hover recipe row (opens nested)")
p("window2 shown=" .. tostring(CraftCompassWindow2 and CraftCompassWindow2.shown))
local enchantRow
for _, row in ipairs(w.rows) do if row.link and row.link:find("spell:2152") then enchantRow = row end end
ALT = false
enchantRow.scripts.OnEnter(enchantRow)
dump("hover enchant/spell row")
for _, row in ipairs(w.rows) do if row.quest then row.scripts.OnClick(row, "LeftButton"); break end end
p("chat=" .. tostring(INSERTED))
w:Hide()
p("after close: window2 shown=" .. tostring(CraftCompassWindow2.shown))

-- item window always shows craft info
ItemRefTooltip.itemName, ItemRefTooltip.itemLink = GetItemInfo(2302)
ItemRefTooltip.scripts.OnTooltipSetItem(ItemRefTooltip)
dump("item window for boots")

-- Alt-click on an item link in chat pins it instead of opening the item window
SHIFT, ALT = false, true
ItemRefTooltip.shown = true
local _, bootsLink = GetItemInfo(2302)
SetItemRef("item:2302::::", bootsLink, "LeftButton")
p("chat alt-click: window1 shown=" .. tostring(CraftCompassWindow1.shown) .. " title=" .. tostring(CraftCompassWindow1.title.text.text) .. " itemref shown=" .. tostring(ItemRefTooltip.shown))
-- a plain click still opens the item window
ALT = false
ItemRefTooltip.shown = true
SetItemRef("item:2318::::", (select(2, GetItemInfo(2318))), "LeftButton")
p("chat click: window1 title=" .. tostring(CraftCompassWindow1.title.text.text) .. " itemref shown=" .. tostring(ItemRefTooltip.shown))
-- Alt-click on a row of a window opens it nested, not as a new first window
SHIFT, ALT = false, true
CraftCompassWindow1:Hide()
GameTooltip.owner = UIParent
GameTooltip.itemName, GameTooltip.itemLink = GetItemInfo(2318)
GameTooltip.scripts.OnTooltipSetItem(GameTooltip)
for _, row in ipairs(CraftCompassWindow1.rows) do if row.link and row.link:find("item:2302") then row.scripts.OnClick(row, "LeftButton") end end
p("row alt-click: window1 title=" .. tostring(CraftCompassWindow1.title.text.text) .. " window2 shown=" .. tostring(CraftCompassWindow2.shown))
ALT = false

FIRE("GET_ITEM_INFO_RECEIVED")
FIRE("MODIFIER_STATE_CHANGED")
return table.concat(out, "\n")
""")
print(result)
