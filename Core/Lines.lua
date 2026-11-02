--[[
The lines Craft Compass shows, built once and drawn either into a tooltip or into a pinned window.
A line is a table:
    text        the left text
    color       {r, g, b} of the left text, white by default
    right       text on the right side
    rightColor  {r, g, b} of the right text
    link        an item or spell link the line stands for (pinned windows make it clickable)
    quest       a quest id the line stands for
    open        a list a click opens in a pinned window, {kind, itemId, label} (Lines.ForList)
    url         a web page a click offers to copy (pinned windows)
    wrap        let a long text wrap; pinned windows wrap it at a set width
    spacer      an empty line between sections
Builders return the lines and whether some item names weren't cached yet, in which case the
caller draws them again once GET_ITEM_INFO_RECEIVED brings them.
]]
local _, ns = ...
local L, Util, Crafts, Quests, Gathering = ns.L, ns.Util, ns.Crafts, ns.Quests, ns.Gathering

local Lines = {}
ns.Lines = Lines

local HEADER_COLOR = {0.31, 0.52, 0.83}
local MUTED_COLOR = {0.65, 0.65, 0.65}
local ENOUGH_COLOR = {0.1, 1, 0.1}
local QUEST_ICON = "Interface\\GossipFrame\\AvailableQuestIcon"
-- How many vendors or quests a source line names before "and N more".
local SOURCES_SHOWN = 2
local ZONES_SHOWN = 3

--- The link and icon of what a craft makes: its item, or the spell itself for enchants.
local function GetCraftResult(spellId, craft)
    if craft[1] then
        local _, link = Util.GetItemInfo(craft[1])
        return link, Util.GetItemIcon(craft[1])
    end
    return Util.GetSpellLink(spellId), Util.GetSpellIcon(spellId)
end

local function GetReagentCount(craft, itemId)
    for i, reagentId in ipairs(craft[6] or {}) do
        if reagentId == itemId then
            return craft[7] and craft[7][i] or 1
        end
    end
    return 1
end

--- The recipes an item goes into, grouped by profession.
local function AddRecipeUses(lines, itemId)
    local pending = false
    local professions = {}
    for _, spellId in ipairs(Crafts.ForReagent(itemId)) do
        local craft = Crafts.Get(spellId)
        local name, icon = Crafts.GetProfession(craft and craft[2])
        if craft and name and (not ns.settings.onlyMyProfessions or Util.HasSkill(name)) then
            local profession = professions[name]
            if not profession then
                profession = {name = name, icon = icon, recipes = {}}
                professions[name] = profession
            end
            local link, resultIcon = GetCraftResult(spellId, craft)
            pending = pending or link == nil
            table.insert(profession.recipes, {
                skill = (craft[3] and craft[3] > 0) and craft[3] or craft[4] or 0,
                link = link,
                icon = resultIcon,
                count = GetReagentCount(craft, itemId)
            })
        end
    end

    local sorted = {}
    for _, profession in pairs(professions) do
        table.insert(sorted, profession)
    end
    table.sort(sorted, function (a, b) return a.name < b.name end)

    for _, profession in ipairs(sorted) do
        table.sort(profession.recipes, function (a, b) return a.skill < b.skill end)
        table.insert(lines, {spacer = true})
        table.insert(lines, {text = Util.Icon(profession.icon) .. profession.name, color = HEADER_COLOR})
        for _, recipe in ipairs(profession.recipes) do
            table.insert(lines, {
                text = "[" .. recipe.skill .. "] " .. Util.Icon(recipe.icon) .. (recipe.link or "..."),
                right = "x" .. recipe.count,
                rightColor = MUTED_COLOR,
                link = recipe.link
            })
        end
    end
    return #sorted > 0, pending
end

--- The quests that ask for an item, for this character's race and class.
local function AddQuestUses(lines, itemId)
    local quests = {}
    for _, questId in ipairs(Quests.ForItem(itemId)) do
        local completed = Util.IsQuestCompleted(questId)
        if Quests.IsForPlayer(questId) and (ns.settings.showCompletedQuests or not completed) then
            table.insert(quests, {
                id = questId,
                name = Quests.GetName(questId),
                level = Quests.GetLevel(questId) or 0,
                completed = completed
            })
        end
    end
    if #quests == 0 then
        return false
    end
    table.sort(quests, function (a, b)
        if a.level ~= b.level then
            return a.level < b.level
        end
        return a.name < b.name
    end)

    table.insert(lines, {spacer = true})
    table.insert(lines, {text = Util.Icon(QUEST_ICON) .. L.Quests, color = HEADER_COLOR})
    for _, quest in ipairs(quests) do
        local text = "[" .. quest.level .. "] " .. quest.name
        if quest.completed then
            text = text .. " |cff808080(" .. L.Completed .. ")|r"
        end
        table.insert(lines, {text = text, quest = quest.id})
    end
    return true
end

--[[
What an item is used for: the recipes it goes into and the quests that ask for it. Nothing found
says nothing: the sources don't know every use, so "not used" would be a guess.
]]
function Lines.ForItemUses(itemId)
    local lines = {}
    local _, pending = AddRecipeUses(lines, itemId)
    AddQuestUses(lines, itemId)
    return lines, pending
end

--[[
The first few names out of a list of ids, and how many ids pass the filter in all. Names are
looked up only for the ones shown.
]]
local function FirstNames(ids, getName, filter, shown)
    local names, total = {}, 0
    for _, id in ipairs(type(ids) == "table" and ids or {}) do
        if not filter or filter(id) then
            total = total + 1
            if #names < (shown or SOURCES_SHOWN) then
                table.insert(names, getName(id))
            end
        end
    end
    return names, total
end

--[[
A label and "a, b and N more" in one line. The line opens the whole list in a pinned window:
open is {kind, itemId, label}, as Lines.ForList takes it.
]]
local function AddNamesLine(lines, open, names, total)
    if #names == 0 then
        return
    end
    local text = table.concat(names, ", ")
    if total > #names then
        text = text .. " " .. string.format(L.AndMore, total - #names)
    end
    table.insert(lines, {
        text = open.label .. ": |cffffffff" .. text .. "|r",
        color = MUTED_COLOR,
        wrap = true,
        open = open
    })
end

local function NpcName(npcId)
    return Quests.GetPlaceName("Npc", npcId) or ("#" .. npcId)
end

local function IsFriendlyNpc(npcId)
    local factionLetter = UnitFactionGroup("player") == "Horde" and "H" or "A"
    local friendly = Quests.Get("Npc", npcId, "friendlyToFaction")
    return type(friendly) ~= "string" or friendly:find(factionLetter) ~= nil
end

--[[
The lists a source line can open: the QuestieDB field each one reads and how its ids are named.
Drops (creatures, chests, containers) are left out on purpose: QuestieDB has them right only for
quest items, the rest come from an emulator's database and are often wrong. The window's Wowhead
row is there for those.
]]
local SOURCE_LISTS = {
    {kind = "vendors", label = "SoldBy", getName = NpcName},
    {kind = "questRewards", label = "QuestReward", getName = Quests.GetName}
}

--- The ids of one of an item's QuestieDB source lists.
local function SourceIds(itemId, list)
    local ids = Quests.Get("Item", itemId, list.kind)
    return type(ids) == "table" and ids or {}
end

--[[
Where an item comes from in QuestieDB: vendors and quest rewards. Returns whether it added
anything.
]]
local function AddSources(lines, itemId)
    local count = #lines
    for _, list in ipairs(SOURCE_LISTS) do
        local ids = SourceIds(itemId, list)
        local names, total = FirstNames(ids, list.getName)
        -- Vendors the character can buy from are named first; the others rather than nothing.
        if list.kind == "vendors" then
            local friendly, friendlyTotal = FirstNames(ids, NpcName, IsFriendlyNpc)
            if friendlyTotal > 0 then
                names = friendly
            end
        end
        AddNamesLine(lines, {kind = list.kind, itemId = itemId, label = L[list.label]}, names, total)
    end
    return #lines > count
end

local function ZoneName(zoneId)
    local name = C_Map and C_Map.GetAreaInfo and C_Map.GetAreaInfo(zoneId)
    if name and name ~= "" then
        return name
    end
    return "#" .. zoneId
end

--[[
Where an item comes from: the profession that gathers it with the skill it needs and the zones it
grows in, then vendors and quest rewards. Nil when nothing is known.
]]
function Lines.ForSources(itemId)
    local lines = {{spacer = true}, {text = L.WhereToGet, color = HEADER_COLOR}}
    local professionId, skill = Gathering.Get(itemId)
    local name, icon = Crafts.GetProfession(professionId)
    if name then
        local zonesOpen = {kind = "zones", itemId = itemId, label = L.Zones}
        local zones = Gathering.GetZones(itemId)
        table.insert(lines, {
            text = Util.Icon(icon) .. name .. " (" .. skill .. ")",
            open = #zones > 0 and zonesOpen or nil
        })
        AddNamesLine(lines, zonesOpen, FirstNames(zones, ZoneName, nil, ZONES_SHOWN))
    end
    if not AddSources(lines, itemId) and not name then
        return nil
    end
    return lines
end

local function NpcLevel(npcId)
    local low, high = Quests.Get("Npc", npcId, "minLevel"), Quests.Get("Npc", npcId, "maxLevel")
    if type(low) ~= "number" or low <= 0 then
        return nil
    end
    if type(high) == "number" and high > low then
        return low .. "-" .. high
    end
    return tostring(low)
end

--- Rows of NPCs: "[level] Name" on the left and its zones on the right, by zone and name.
local function AddNpcRows(lines, ids, color)
    local places = {}
    for _, id in ipairs(ids) do
        local level = NpcLevel(id)
        local zones, zoneCount = Quests.GetZoneNames("Npc", id, 2)
        local zone = table.concat(zones, ", ")
        if zoneCount > #zones then
            zone = zone .. " +" .. (zoneCount - #zones)
        end
        table.insert(places, {
            name = (level and "[" .. level .. "] " or "") .. (Quests.Get("Npc", id, "name") or ("#" .. id)),
            zone = zone
        })
    end
    table.sort(places, function (a, b)
        if a.zone ~= b.zone then
            return a.zone < b.zone
        end
        return a.name < b.name
    end)
    for _, place in ipairs(places) do
        table.insert(lines, {text = place.name, color = color, right = place.zone, rightColor = MUTED_COLOR})
    end
end

--[[
The whole list a source line stands for, for its own pinned window. open is the {kind, itemId,
label} of that line. Returns the lines and whether some item names weren't cached yet (never, as
these lists name NPCs, quests and zones).
]]
function Lines.ForList(open)
    local lines, pending = {}, false
    if open.kind == "zones" then
        local zones, counts = Gathering.GetZones(open.itemId)
        table.insert(lines, {text = L.NodesPerZone, color = MUTED_COLOR})
        for _, zoneId in ipairs(zones) do
            table.insert(lines, {text = ZoneName(zoneId), right = tostring(counts[zoneId]), rightColor = MUTED_COLOR})
        end
        return lines, pending
    end

    local ids = {}
    for _, list in ipairs(SOURCE_LISTS) do
        if list.kind == open.kind then
            ids = SourceIds(open.itemId, list)
        end
    end

    if open.kind == "vendors" then
        -- Vendors of the other faction last, greyed out.
        local friendly, hostile = {}, {}
        for _, npcId in ipairs(ids) do
            table.insert(IsFriendlyNpc(npcId) and friendly or hostile, npcId)
        end
        AddNpcRows(lines, friendly)
        AddNpcRows(lines, hostile, MUTED_COLOR)
    elseif open.kind == "questRewards" then
        local quests = {}
        for _, questId in ipairs(ids) do
            table.insert(quests, {id = questId, name = Quests.GetName(questId), level = Quests.GetLevel(questId) or 0})
        end
        table.sort(quests, function (a, b)
            if a.level ~= b.level then
                return a.level < b.level
            end
            return a.name < b.name
        end)
        for _, quest in ipairs(quests) do
            table.insert(lines, {text = "[" .. quest.level .. "] " .. quest.name, quest = quest.id})
        end
    end
    return lines, pending
end

--[[
What a craft takes: the profession and skill, each reagent with how many the character has
(bags and bank) against how many it needs, and where the recipe comes from.
]]
function Lines.ForCraft(spellId)
    local craft = Crafts.Get(spellId)
    if not craft then
        return nil, false
    end
    local lines = {{spacer = true}}
    local pending = false

    local name, icon = Crafts.GetProfession(craft[2])
    if name then
        local header = Util.Icon(icon) .. name
        if craft[3] and craft[3] > 0 then
            header = header .. " (" .. craft[3] .. ")"
        end
        table.insert(lines, {text = header, color = HEADER_COLOR})
    end

    for i, reagentId in ipairs(craft[6] or {}) do
        local needed = craft[7] and craft[7][i] or 1
        local reagentName, reagentLink = Util.GetItemInfo(reagentId)
        pending = pending or reagentName == nil
        local have = Util.GetItemCount(reagentId, true) or 0
        table.insert(lines, {
            text = Util.Icon(Util.GetItemIcon(reagentId)) .. (reagentName or "..."),
            right = have .. "/" .. needed,
            rightColor = have >= needed and ENOUGH_COLOR or nil,
            link = reagentLink
        })
    end

    local recipeId = Crafts.GetRecipeItem(spellId)
    if recipeId then
        local _, recipeLink = Util.GetItemInfo(recipeId)
        pending = pending or recipeLink == nil
        table.insert(lines, {text = L.Recipe .. ": " .. (recipeLink or "..."), color = MUTED_COLOR, link = recipeLink})
        AddSources(lines, recipeId)
    else
        table.insert(lines, {text = L.Recipe .. ": |cffffffff" .. L.Trainer .. "|r", color = MUTED_COLOR})
    end
    return lines, pending
end

--[[
What an item takes and where it comes from: its craft, if it is crafted, then its sources. Nil
when there is neither.
]]
function Lines.ForOrigin(itemId)
    local lines, pending = {}, false
    local spellId = Crafts.ForCreatedItem(itemId)
    if spellId then
        local craftLines, craftPending = Lines.ForCraft(spellId)
        for _, line in ipairs(craftLines or {}) do
            table.insert(lines, line)
        end
        pending = craftPending
    end
    for _, line in ipairs(Lines.ForSources(itemId) or {}) do
        table.insert(lines, line)
    end
    if #lines == 0 then
        return nil, false
    end
    return lines, pending
end

--[[
A pinned window's lines: what the item's craft takes and where the item comes from, so its
reagents can be opened in turn, then what the item is used for, and last a link to its Wowhead
page, where the drops the addon's sources lack can be checked.
]]
function Lines.ForWindow(itemId)
    local lines, pending = Lines.ForOrigin(itemId)
    local useLines, usePending = Lines.ForItemUses(itemId)
    lines = lines or {}
    for _, line in ipairs(useLines) do
        table.insert(lines, line)
    end
    table.insert(lines, {spacer = true})
    table.insert(lines, {text = L.WowheadPage, color = MUTED_COLOR, url = Util.WowheadItemUrl(itemId)})
    return lines, pending or usePending
end

--- Draws lines into a tooltip.
function Lines.AddToTooltip(tooltip, lines)
    for _, line in ipairs(lines) do
        local r, g, b = 1, 1, 1
        if line.color then
            r, g, b = unpack(line.color)
        end
        if line.spacer then
            tooltip:AddLine(" ")
        elseif line.right then
            local rr, rg, rb = 1, 1, 1
            if line.rightColor then
                rr, rg, rb = unpack(line.rightColor)
            end
            tooltip:AddDoubleLine(line.text, line.right, r, g, b, rr, rg, rb)
        else
            tooltip:AddLine(line.text, r, g, b, line.wrap)
        end
    end
end
