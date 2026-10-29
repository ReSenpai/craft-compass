--[[
Quests and places from QuestieDB (part of Questie): which quests ask for an item, quest and NPC
names in the client's language, and where an item can be bought, looted or found. QuestieDB
knows a quest's items but not an item's quests, so after login we index them once.
]]
local _, ns = ...
local Util = ns.Util

local Quests = {}
ns.Quests = Quests

local QUESTS_PER_STEP = 250
-- Positions in a quest's objectives where the items to bring are listed.
local OBJECTIVE_ITEMS = 3

local questsByItem = {}
local finishIndex

function Quests.IsAvailable()
    return LibQuestieDB ~= nil and LibQuestieDB.Quest ~= nil and type(LibQuestieDB.Quest.Get) == "function"
end

--- A field of a QuestieDB entity ("Quest", "Item", "Npc", "Object"), or nil.
function Quests.Get(entity, id, field)
    local db = LibQuestieDB and LibQuestieDB[entity]
    return db and Util.SafeCall(db.Get, id, field)
end

local function AddQuestForItem(itemId, questId)
    local quests = questsByItem[itemId]
    if not quests then
        quests = {}
        questsByItem[itemId] = quests
    end
    if quests[#quests] ~= questId then
        table.insert(quests, questId)
    end
end

local function BuildIndex()
    local questDb = LibQuestieDB.Quest
    local ids = Util.SafeCall(questDb.GetAllIds) or {}
    for i, questId in ipairs(ids) do
        local objectives = Util.SafeCall(questDb.Get, questId, "objectives")
        local items = type(objectives) == "table" and objectives[OBJECTIVE_ITEMS]
        for _, objective in ipairs(type(items) == "table" and items or {}) do
            AddQuestForItem(objective[1], questId)
        end
        -- Items the quest needs in the bags to be started or done.
        local sourceItems = Util.SafeCall(questDb.Get, questId, "requiredSourceItems")
        for _, itemId in ipairs(type(sourceItems) == "table" and sourceItems or {}) do
            AddQuestForItem(itemId, questId)
        end
        if i % QUESTS_PER_STEP == 0 then
            coroutine.yield()
        end
    end
end

--- Whether the character's race and class may take a quest.
function Quests.IsForPlayer(questId)
    local race = select(3, UnitRace("player"))
    local class = select(3, UnitClass("player"))
    return Util.MaskAllows(Quests.Get("Quest", questId, "requiredRaces"), race)
        and Util.MaskAllows(Quests.Get("Quest", questId, "requiredClasses"), class)
end

--- The quests that ask for an item, whoever may take them.
function Quests.ForItem(itemId)
    if finishIndex then
        finishIndex()
    end
    return questsByItem[itemId] or {}
end

function Quests.GetName(questId)
    return Quests.Get("Quest", questId, "name") or ("#" .. questId)
end

function Quests.GetLevel(questId)
    local level = Quests.Get("Quest", questId, "questLevel")
    if type(level) == "number" and level > 0 then
        return level
    end
    return Quests.Get("Quest", questId, "requiredLevel")
end

--- The zone a quest belongs to, when QuestieDB files it under one.
function Quests.GetZone(questId)
    local zoneOrSort = Quests.Get("Quest", questId, "zoneOrSort")
    if type(zoneOrSort) == "number" and zoneOrSort > 0 and C_Map and C_Map.GetAreaInfo then
        return C_Map.GetAreaInfo(zoneOrSort)
    end
    return nil
end

--[[
The text that links a quest in chat. The client has no quest links of its own here, so this is
the "[Name (id)]" text Questie turns into a clickable link; Questie's own formatting is used
when it is loaded.
]]
function Quests.GetChatLink(questId)
    local questLink = QuestieLoader and Util.SafeCall(QuestieLoader.ImportModule, QuestieLoader, "QuestieLink")
    local text = questLink and Util.SafeCall(questLink.GetQuestLinkStringById, questId)
    if type(text) == "string" then
        return text
    end
    return "[" .. Quests.GetName(questId) .. " (" .. questId .. ")]"
end

--- "Name (Zone)" for an NPC or object.
function Quests.GetPlaceName(entity, id)
    local name = Quests.Get(entity, id, "name")
    if not name then
        return nil
    end
    local zoneId = Quests.Get(entity, id, "zoneID")
    local zone = zoneId and C_Map and C_Map.GetAreaInfo and C_Map.GetAreaInfo(zoneId)
    if zone and zone ~= "" then
        return name .. " (" .. zone .. ")"
    end
    return name
end

ns.OnLogin(function ()
    if Quests.IsAvailable() then
        finishIndex = Util.RunInBackground(BuildIndex)
    end
end)
