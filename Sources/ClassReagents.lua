--[[
Reagents of class spells: Fish Oil for a shaman's Water Walking, runes for a mage's teleports,
seeds for a druid's Rebirth. Neither AtlasLoot nor QuestieDB knows them, so they are kept here;
the names of classes and spells come from the client, in its language.
]]
local _, ns = ...
local Util = ns.Util

local ClassReagents = {}
ns.ClassReagents = ClassReagents

--[[
The spells each reagent is for: {class, spell id}, with rank where each rank takes its own
reagent, faction for a spell only one faction has, and tbc for one from Burning Crusade.
]]
local REAGENTS = {
    [17058] = {{"SHAMAN", 546}}, -- Fish Oil: Water Walking
    [17057] = {{"SHAMAN", 131}}, -- Shiny Fish Scales: Water Breathing
    [17030] = {{"SHAMAN", 20608}}, -- Ankh: Reincarnation

    [17056] = {{"MAGE", 130}, {"PRIEST", 1706}}, -- Light Feather: Slow Fall, Levitate
    [17020] = {{"MAGE", 23028}}, -- Arcane Powder: Arcane Brilliance
    [17031] = { -- Rune of Teleportation
        {"MAGE", 3561, faction = "Alliance"}, -- Stormwind
        {"MAGE", 3562, faction = "Alliance"}, -- Ironforge
        {"MAGE", 3565, faction = "Alliance"}, -- Darnassus
        {"MAGE", 32271, faction = "Alliance", tbc = true}, -- Exodar
        {"MAGE", 33690, faction = "Alliance", tbc = true}, -- Shattrath
        {"MAGE", 3567, faction = "Horde"}, -- Orgrimmar
        {"MAGE", 3563, faction = "Horde"}, -- Undercity
        {"MAGE", 3566, faction = "Horde"}, -- Thunder Bluff
        {"MAGE", 32272, faction = "Horde", tbc = true}, -- Silvermoon
        {"MAGE", 35715, faction = "Horde", tbc = true} -- Shattrath
    },
    [17032] = { -- Rune of Portals
        {"MAGE", 10059, faction = "Alliance"}, -- Stormwind
        {"MAGE", 11416, faction = "Alliance"}, -- Ironforge
        {"MAGE", 11419, faction = "Alliance"}, -- Darnassus
        {"MAGE", 32266, faction = "Alliance", tbc = true}, -- Exodar
        {"MAGE", 33691, faction = "Alliance", tbc = true}, -- Shattrath
        {"MAGE", 11417, faction = "Horde"}, -- Orgrimmar
        {"MAGE", 11418, faction = "Horde"}, -- Undercity
        {"MAGE", 11420, faction = "Horde"}, -- Thunder Bluff
        {"MAGE", 32267, faction = "Horde", tbc = true}, -- Silvermoon
        {"MAGE", 35717, faction = "Horde", tbc = true} -- Shattrath
    },

    [17028] = {{"PRIEST", 21562, rank = 1}}, -- Holy Candle: Prayer of Fortitude
    [17029] = { -- Sacred Candle
        {"PRIEST", 21564, rank = 2}, -- Prayer of Fortitude
        {"PRIEST", 25392, rank = 3, tbc = true},
        {"PRIEST", 27681}, -- Prayer of Spirit
        {"PRIEST", 27683} -- Prayer of Shadow Protection
    },

    [17034] = {{"DRUID", 20484, rank = 1}}, -- Maple Seed: Rebirth
    [17035] = {{"DRUID", 20739, rank = 2}}, -- Stranglethorn Seed
    [17036] = {{"DRUID", 20742, rank = 3}}, -- Ashwood Seed
    [17037] = {{"DRUID", 20747, rank = 4}}, -- Hornbeam Seed
    [17038] = {{"DRUID", 20748, rank = 5}}, -- Ironwood Seed
    [22147] = {{"DRUID", 26994, rank = 6, tbc = true}}, -- Flintweed Seed
    [17021] = {{"DRUID", 21849, rank = 1}}, -- Wild Berries: Gift of the Wild
    [17026] = {{"DRUID", 21850, rank = 2}}, -- Wild Thornroot
    [22148] = {{"DRUID", 26991, rank = 3, tbc = true}}, -- Wild Quillvine

    [17033] = {{"PALADIN", 19752}}, -- Symbol of Divinity: Divine Intervention
    [21177] = { -- Symbol of Kings: the greater blessings
        {"PALADIN", 25782}, -- Might
        {"PALADIN", 25894}, -- Wisdom
        {"PALADIN", 25898}, -- Kings
        {"PALADIN", 25895}, -- Salvation
        {"PALADIN", 25890}, -- Light
        {"PALADIN", 25899} -- Sanctuary
    },

    [5140] = {{"ROGUE", 1856}}, -- Flash Powder: Vanish
    [5530] = {{"ROGUE", 2094}}, -- Blinding Powder: Blind

    [6265] = { -- Soul Shard
        {"WARLOCK", 697}, -- Summon Voidwalker
        {"WARLOCK", 712}, -- Summon Succubus
        {"WARLOCK", 691}, -- Summon Felhunter
        {"WARLOCK", 30146, tbc = true}, -- Summon Felguard
        {"WARLOCK", 698}, -- Ritual of Summoning
        {"WARLOCK", 29893, tbc = true}, -- Ritual of Souls
        {"WARLOCK", 6201}, -- Create Healthstone
        {"WARLOCK", 693}, -- Create Soulstone
        {"WARLOCK", 2362}, -- Create Spellstone
        {"WARLOCK", 6366}, -- Create Firestone
        {"WARLOCK", 6353}, -- Soul Fire
        {"WARLOCK", 17877} -- Shadowburn
    },
    [5565] = {{"WARLOCK", 1122}}, -- Infernal Stone: Inferno
    [16583] = {{"WARLOCK", 18540}} -- Demonic Figurine: Ritual of Doom
}

--[[
The class spells an item is a reagent of, for this game version and the character's faction:
{class = "SHAMAN", spellId = 546, rank = nil}, in the order above.
]]
function ClassReagents.ForItem(itemId)
    local uses = {}
    local faction = UnitFactionGroup and UnitFactionGroup("player")
    local tbc = Util.IsTBC()
    for _, use in ipairs(REAGENTS[itemId] or {}) do
        if (tbc or not use.tbc) and (not use.faction or not faction or use.faction == faction) then
            table.insert(uses, {class = use[1], spellId = use[2], rank = use.rank})
        end
    end
    return uses
end

--- A class's name in the client's language and its colour, {r, g, b}.
function ClassReagents.GetClass(class)
    local name = LOCALIZED_CLASS_NAMES_MALE and LOCALIZED_CLASS_NAMES_MALE[class] or class
    local color = RAID_CLASS_COLORS and RAID_CLASS_COLORS[class]
    return name, color and {color.r, color.g, color.b}
end
