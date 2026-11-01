--[[
Resources gathered with a profession: herbs, ore and stone, leather and hides, and the skill
each needs. Neither AtlasLoot nor QuestieDB knows these skills, so they are kept here. Where the
herbs and veins grow comes from QuestieDB, whose objects are matched to them by English name
after login.
]]
local _, ns = ...
local Util, Quests = ns.Util, ns.Quests

local Gathering = {}
ns.Gathering = Gathering

-- AtlasLoot's profession ids, as Crafts.GetProfession takes them.
local HERBALISM, MINING, SKINNING = 5, 7, 12
local OBJECTS_PER_STEP = 250

-- Herbs and veins by their English name in QuestieDB: the profession and the skill they need.
local NODES = {
    ["Peacebloom"] = {HERBALISM, 1},
    ["Silverleaf"] = {HERBALISM, 1},
    ["Earthroot"] = {HERBALISM, 15},
    ["Mageroyal"] = {HERBALISM, 50},
    ["Briarthorn"] = {HERBALISM, 70},
    ["Stranglekelp"] = {HERBALISM, 85},
    ["Bruiseweed"] = {HERBALISM, 100},
    ["Wild Steelbloom"] = {HERBALISM, 115},
    ["Grave Moss"] = {HERBALISM, 120},
    ["Kingsblood"] = {HERBALISM, 125},
    ["Liferoot"] = {HERBALISM, 150},
    ["Fadeleaf"] = {HERBALISM, 160},
    ["Goldthorn"] = {HERBALISM, 170},
    ["Khadgar's Whisker"] = {HERBALISM, 185},
    ["Wintersbite"] = {HERBALISM, 195},
    ["Firebloom"] = {HERBALISM, 205},
    ["Purple Lotus"] = {HERBALISM, 210},
    ["Arthas' Tears"] = {HERBALISM, 220},
    ["Sungrass"] = {HERBALISM, 230},
    ["Blindweed"] = {HERBALISM, 235},
    ["Ghost Mushroom"] = {HERBALISM, 245},
    ["Gromsblood"] = {HERBALISM, 250},
    ["Golden Sansam"] = {HERBALISM, 260},
    ["Dreamfoil"] = {HERBALISM, 270},
    ["Mountain Silversage"] = {HERBALISM, 280},
    ["Plaguebloom"] = {HERBALISM, 285},
    ["Icecap"] = {HERBALISM, 290},
    ["Black Lotus"] = {HERBALISM, 300},
    ["Felweed"] = {HERBALISM, 300},
    ["Dreaming Glory"] = {HERBALISM, 315},
    ["Ragveil"] = {HERBALISM, 325},
    ["Terocone"] = {HERBALISM, 325},
    ["Flame Cap"] = {HERBALISM, 335},
    ["Ancient Lichen"] = {HERBALISM, 340},
    ["Netherbloom"] = {HERBALISM, 350},
    ["Netherdust Bush"] = {HERBALISM, 350},
    ["Nightmare Vine"] = {HERBALISM, 365},
    ["Mana Thistle"] = {HERBALISM, 375},

    ["Copper Vein"] = {MINING, 1},
    ["Tin Vein"] = {MINING, 65},
    ["Incendicite Mineral Vein"] = {MINING, 65},
    ["Silver Vein"] = {MINING, 75},
    ["Ooze Covered Silver Vein"] = {MINING, 75},
    ["Lesser Bloodstone Deposit"] = {MINING, 75},
    ["Iron Deposit"] = {MINING, 125},
    ["Ooze Covered Iron Deposit"] = {MINING, 125},
    ["Indurium Mineral Vein"] = {MINING, 150},
    ["Gold Vein"] = {MINING, 155},
    ["Ooze Covered Gold Vein"] = {MINING, 155},
    ["Mithril Deposit"] = {MINING, 175},
    ["Ooze Covered Mithril Deposit"] = {MINING, 175},
    ["Truesilver Deposit"] = {MINING, 230},
    ["Ooze Covered Truesilver Deposit"] = {MINING, 230},
    ["Dark Iron Deposit"] = {MINING, 230},
    ["Small Thorium Vein"] = {MINING, 245},
    ["Ooze Covered Thorium Vein"] = {MINING, 245},
    ["Rich Thorium Vein"] = {MINING, 275},
    ["Ooze Covered Rich Thorium Vein"] = {MINING, 275},
    ["Fel Iron Deposit"] = {MINING, 300},
    ["Adamantite Deposit"] = {MINING, 325},
    ["Rich Adamantite Deposit"] = {MINING, 350},
    ["Khorium Vein"] = {MINING, 375}
}

local THORIUM = {"Small Thorium Vein", "Ooze Covered Thorium Vein", "Rich Thorium Vein", "Ooze Covered Rich Thorium Vein"}
local MITHRIL = {"Mithril Deposit", "Ooze Covered Mithril Deposit"}

-- The herbs and veins each resource comes from.
local ITEM_NODES = {
    [2447] = {"Peacebloom"},
    [765] = {"Silverleaf"},
    [2449] = {"Earthroot"},
    [785] = {"Mageroyal"},
    [2450] = {"Briarthorn"},
    [2452] = {"Mageroyal", "Briarthorn"}, -- Swiftthistle
    [3820] = {"Stranglekelp"},
    [2453] = {"Bruiseweed"},
    [3355] = {"Wild Steelbloom"},
    [3369] = {"Grave Moss"},
    [3356] = {"Kingsblood"},
    [3357] = {"Liferoot"},
    [3818] = {"Fadeleaf"},
    [3821] = {"Goldthorn"},
    [3358] = {"Khadgar's Whisker"},
    [3819] = {"Wintersbite"},
    [4625] = {"Firebloom"},
    [8831] = {"Purple Lotus"},
    [8153] = {"Purple Lotus"}, -- Wildvine
    [8836] = {"Arthas' Tears"},
    [8838] = {"Sungrass"},
    [8839] = {"Blindweed"},
    [8845] = {"Ghost Mushroom"},
    [8846] = {"Gromsblood"},
    [13464] = {"Golden Sansam"},
    [13463] = {"Dreamfoil"},
    [13465] = {"Mountain Silversage"},
    [13466] = {"Plaguebloom"},
    [13467] = {"Icecap"},
    [13468] = {"Black Lotus"},
    [22785] = {"Felweed"},
    [22786] = {"Dreaming Glory"},
    [22787] = {"Ragveil"},
    [22788] = {"Flame Cap"},
    [22789] = {"Terocone"},
    [22790] = {"Ancient Lichen"},
    [22791] = {"Netherbloom"},
    [22792] = {"Nightmare Vine"},
    [22793] = {"Mana Thistle"},
    [32468] = {"Netherdust Bush"}, -- Netherdust Pollen

    [2770] = {"Copper Vein"},
    [2835] = {"Copper Vein"}, -- Rough Stone
    [2771] = {"Tin Vein"},
    [2836] = {"Tin Vein"}, -- Coarse Stone
    [3340] = {"Incendicite Mineral Vein"},
    [2775] = {"Silver Vein", "Ooze Covered Silver Vein"},
    [4278] = {"Lesser Bloodstone Deposit"},
    [2772] = {"Iron Deposit", "Ooze Covered Iron Deposit"},
    [2838] = {"Iron Deposit", "Ooze Covered Iron Deposit"}, -- Heavy Stone
    [5833] = {"Indurium Mineral Vein"},
    [2776] = {"Gold Vein", "Ooze Covered Gold Vein"},
    [3858] = MITHRIL,
    [7912] = MITHRIL, -- Solid Stone
    [7911] = {"Truesilver Deposit", "Ooze Covered Truesilver Deposit"},
    [11370] = {"Dark Iron Deposit"},
    [10620] = THORIUM,
    [12365] = THORIUM, -- Dense Stone
    [23424] = {"Fel Iron Deposit"},
    [23425] = {"Adamantite Deposit", "Rich Adamantite Deposit"},
    [23426] = {"Khorium Vein"}
}

-- Leather and hides: the skill from which beasts start to give them.
local SKINNED = {
    [2934] = 1, -- Ruined Leather Scraps
    [2318] = 1, -- Light Leather
    [783] = 1, -- Light Hide
    [2319] = 100, -- Medium Leather
    [4232] = 100, -- Medium Hide
    [4234] = 150, -- Heavy Leather
    [4235] = 150, -- Heavy Hide
    [4304] = 200, -- Thick Leather
    [8169] = 200, -- Thick Hide
    [8170] = 250, -- Rugged Leather
    [8171] = 250, -- Rugged Hide
    [25649] = 300, -- Knothide Leather Scraps
    [21887] = 300 -- Knothide Leather
}

local objectsByNode = {}
local isNodeObject = {}
local zonesByItem = {}
local finishIndex

local function EnsureIndex()
    if finishIndex then
        finishIndex()
    end
end

local function BuildIndex()
    local objectDb = LibQuestieDB.Object
    -- Raw names are the English ones on every client language; Get is the fallback.
    local getName = objectDb.GetRaw or objectDb.Get
    local ids = Util.SafeCall(objectDb.GetAllIds) or {}
    for i, objectId in ipairs(ids) do
        local name = Util.SafeCall(getName, objectId, "name")
        if name and NODES[name] then
            objectsByNode[name] = objectsByNode[name] or {}
            table.insert(objectsByNode[name], objectId)
            isNodeObject[objectId] = true
        end
        if i % OBJECTS_PER_STEP == 0 then
            coroutine.yield()
        end
    end
end

--[[
How an item is gathered: the profession id (AtlasLoot's) and the skill it needs, or nil for
items that aren't gathered.
]]
function Gathering.Get(itemId)
    local skinSkill = SKINNED[itemId]
    if skinSkill then
        return SKINNING, skinSkill
    end
    local nodes = ITEM_NODES[itemId]
    if not nodes then
        return nil
    end
    local profession, skill
    for _, name in ipairs(nodes) do
        local node = NODES[name]
        profession = node[1]
        skill = math.min(skill or node[2], node[2])
    end
    return profession, skill
end

--[[
The zones where an item's herbs or veins grow, the ones with the most of them first, and how many
spawn points each zone has.
]]
function Gathering.GetZones(itemId)
    local nodes = ITEM_NODES[itemId]
    if not nodes or not Quests.IsAvailable() then
        return {}, {}
    end
    if zonesByItem[itemId] then
        return unpack(zonesByItem[itemId])
    end
    EnsureIndex()
    local counts = {}
    for _, name in ipairs(nodes) do
        for _, objectId in ipairs(objectsByNode[name] or {}) do
            local spawns = Quests.Get("Object", objectId, "spawns")
            for zoneId, points in pairs(type(spawns) == "table" and spawns or {}) do
                counts[zoneId] = (counts[zoneId] or 0) + (type(points) == "table" and #points or 1)
            end
        end
    end
    local zones = {}
    for zoneId in pairs(counts) do
        table.insert(zones, zoneId)
    end
    table.sort(zones, function (a, b)
        if counts[a] ~= counts[b] then
            return counts[a] > counts[b]
        end
        return a < b
    end)
    zonesByItem[itemId] = {zones, counts}
    return zones, counts
end

--- Whether a QuestieDB object is a herb or a vein, which the gathering line already covers.
function Gathering.IsNode(objectId)
    EnsureIndex()
    return isNodeObject[objectId] == true
end

ns.OnLogin(function ()
    if Quests.IsAvailable() and LibQuestieDB.Object then
        finishIndex = Util.RunInBackground(BuildIndex)
    end
end)
