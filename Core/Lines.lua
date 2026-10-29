--[[
The lines Craft Compass shows, built once and drawn either into a tooltip or into a pinned window.
A line is a table:
    text        the left text
    color       {r, g, b} of the left text, white by default
    right       text on the right side
    rightColor  {r, g, b} of the right text
    link        an item or spell link the line stands for (pinned windows make it clickable)
    quest       a quest id the line stands for
    wrap        let a long text wrap in tooltips
    spacer      an empty line between sections
Builders return the lines and whether some item names weren't cached yet, in which case the
caller draws them again once GET_ITEM_INFO_RECEIVED brings them.
]]
local _, ns = ...
local L, Util, Crafts, Quests = ns.L, ns.Util, ns.Crafts, ns.Quests

local Lines = {}
ns.Lines = Lines

local HEADER_COLOR = {0.31, 0.52, 0.83}
local MUTED_COLOR = {0.65, 0.65, 0.65}
local ENOUGH_COLOR = {0.1, 1, 0.1}
local QUEST_ICON = "Interface\\GossipFrame\\AvailableQuestIcon"
-- How many vendors, drops and so on a recipe source line names before "and N more".
local SOURCES_SHOWN = 2

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

--- What an item is used for: the recipes it goes into and the quests that ask for it.
function Lines.ForItemUses(itemId)
    local lines = {}
    local hasRecipes, pending = AddRecipeUses(lines, itemId)
    local hasQuests = AddQuestUses(lines, itemId)
    if not hasRecipes and not hasQuests and ns.settings.showNotUsed then
        table.insert(lines, {spacer = true})
        table.insert(lines, {text = L.NotUsed, color = MUTED_COLOR})
    end
    return lines, pending
end

local function JoinNames(names)
    local shown = {}
    for i = 1, math.min(#names, SOURCES_SHOWN) do
        shown[i] = names[i]
    end
    local text = table.concat(shown, ", ")
    if #names > SOURCES_SHOWN then
        text = text .. " " .. string.format(L.AndMore, #names - SOURCES_SHOWN)
    end
    return text
end

local function PlaceNames(entity, ids, filter)
    local names = {}
    for _, id in ipairs(type(ids) == "table" and ids or {}) do
        if not filter or filter(id) then
            local name = Quests.GetPlaceName(entity, id)
            if name then
                table.insert(names, name)
            end
        end
    end
    return names
end

--- Where a recipe item comes from: vendors, drops, containers and quest rewards.
local function AddRecipeSources(lines, recipeId)
    local factionLetter = UnitFactionGroup("player") == "Horde" and "H" or "A"
    local vendorIds = Quests.Get("Item", recipeId, "vendors")
    -- Vendors the character can buy from first; the others rather than nothing.
    local vendors = PlaceNames("Npc", vendorIds, function (npcId)
        local friendly = Quests.Get("Npc", npcId, "friendlyToFaction")
        return type(friendly) ~= "string" or friendly:find(factionLetter) ~= nil
    end)
    if #vendors == 0 then
        vendors = PlaceNames("Npc", vendorIds)
    end

    local questNames = {}
    local rewardIds = Quests.Get("Item", recipeId, "questRewards")
    for _, questId in ipairs(type(rewardIds) == "table" and rewardIds or {}) do
        table.insert(questNames, Quests.GetName(questId))
    end

    local sources = {
        {L.SoldBy, vendors},
        {L.DropsFrom, PlaceNames("Npc", Quests.Get("Item", recipeId, "npcDrops"))},
        {L.FoundIn, PlaceNames("Object", Quests.Get("Item", recipeId, "objectDrops"))},
        {L.QuestReward, questNames}
    }
    for _, source in ipairs(sources) do
        if #source[2] > 0 then
            table.insert(lines, {
                text = "   " .. source[1] .. ": |cffffffff" .. JoinNames(source[2]) .. "|r",
                color = MUTED_COLOR,
                wrap = true
            })
        end
    end
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
        local reagentName = Util.GetItemInfo(reagentId)
        pending = pending or reagentName == nil
        local have = Util.GetItemCount(reagentId, true) or 0
        table.insert(lines, {
            text = Util.Icon(Util.GetItemIcon(reagentId)) .. (reagentName or "..."),
            right = have .. "/" .. needed,
            rightColor = have >= needed and ENOUGH_COLOR or nil
        })
    end

    local recipeId = Crafts.GetRecipeItem(spellId)
    if recipeId then
        local _, recipeLink = Util.GetItemInfo(recipeId)
        pending = pending or recipeLink == nil
        table.insert(lines, {text = L.Recipe .. ": " .. (recipeLink or "..."), color = MUTED_COLOR, link = recipeLink})
        AddRecipeSources(lines, recipeId)
    else
        table.insert(lines, {text = L.Recipe .. ": |cffffffff" .. L.Trainer .. "|r", color = MUTED_COLOR})
    end
    return lines, pending
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
