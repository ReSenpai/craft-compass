--[[
Enchants an item can take: by the slot it is worn in, the enchanting spells made for that slot.
AtlasLoot knows what each enchant takes and the skill it needs, but not which slot it is for, so
the spells of each slot are kept here; their names come from the client, in its language.
]]
local _, ns = ...
local Util, Crafts = ns.Util, ns.Crafts

local Enchants = {}
ns.Enchants = Enchants

-- AtlasLoot's profession id of Enchanting.
Enchants.PROFESSION = 10

--[[
The enchanting spells of each slot, tbc marking those from Burning Crusade. Enchant Weapon fits
two-handed weapons too; a ring only takes the enchanter's own enchants.
]]
local SPELLS = {
    weapon = {
        {23804}, -- Enchant Weapon - Mighty Intellect
        {20034}, -- Enchant Weapon - Crusader
        {20032}, -- Enchant Weapon - Lifestealing
        {22749}, -- Enchant Weapon - Spell Power
        {22750}, -- Enchant Weapon - Healing Power
        {23803}, -- Enchant Weapon - Mighty Spirit
        {20031}, -- Enchant Weapon - Superior Striking
        {20033}, -- Enchant Weapon - Unholy Weapon
        {23799}, -- Enchant Weapon - Strength
        {23800}, -- Enchant Weapon - Agility
        {20029}, -- Enchant Weapon - Icy Chill
        {13898}, -- Enchant Weapon - Fiery Weapon
        {13943}, -- Enchant Weapon - Greater Striking
        {13915}, -- Enchant Weapon - Demonslaying
        {13693}, -- Enchant Weapon - Striking
        {21931}, -- Enchant Weapon - Winter
        {13653}, -- Enchant Weapon - Lesser Beastslayer
        {13655}, -- Enchant Weapon - Lesser Elemental Slayer
        {13503}, -- Enchant Weapon - Lesser Striking
        {7788}, -- Enchant Weapon - Minor Striking
        {7786}, -- Enchant Weapon - Minor Beastslayer
        {42974, tbc = true}, -- Enchant Weapon - Executioner
        {27982, tbc = true}, -- Enchant Weapon - Soulfrost
        {27981, tbc = true}, -- Enchant Weapon - Sunfire
        {27984, tbc = true}, -- Enchant Weapon - Mongoose
        {28003, tbc = true}, -- Enchant Weapon - Spellsurge
        {28004, tbc = true}, -- Enchant Weapon - Battlemaster
        {46578, tbc = true}, -- Enchant Weapon - Deathfrost
        {42620, tbc = true}, -- Enchant Weapon - Greater Agility
        {34010, tbc = true}, -- Enchant Weapon - Major Healing
        {27975, tbc = true}, -- Enchant Weapon - Major Spellpower
        {27972, tbc = true}, -- Enchant Weapon - Potency
        {27968, tbc = true}, -- Enchant Weapon - Major Intellect
        {27967, tbc = true}, -- Enchant Weapon - Major Striking
    },
    twoHand = {
        {20035}, -- Enchant 2H Weapon - Major Spirit
        {20036}, -- Enchant 2H Weapon - Major Intellect
        {20030}, -- Enchant 2H Weapon - Superior Impact
        {27837}, -- Enchant 2H Weapon - Agility
        {13937}, -- Enchant 2H Weapon - Greater Impact
        {13695}, -- Enchant 2H Weapon - Impact
        {13529}, -- Enchant 2H Weapon - Lesser Impact
        {13380}, -- Enchant 2H Weapon - Lesser Spirit
        {7745}, -- Enchant 2H Weapon - Minor Impact
        {7793}, -- Enchant 2H Weapon - Lesser Intellect
        {27977, tbc = true}, -- Enchant 2H Weapon - Major Agility
        {27971, tbc = true}, -- Enchant 2H Weapon - Savagery
    },
    cloak = {
        {25086}, -- Enchant Cloak - Dodge
        {25081}, -- Enchant Cloak - Greater Fire Resistance
        {25082}, -- Enchant Cloak - Greater Nature Resistance
        {25084}, -- Enchant Cloak - Subtlety
        {25083}, -- Enchant Cloak - Stealth
        {20015}, -- Enchant Cloak - Superior Defense
        {20014}, -- Enchant Cloak - Greater Resistance
        {13882}, -- Enchant Cloak - Lesser Agility
        {13794}, -- Enchant Cloak - Resistance
        {13746}, -- Enchant Cloak - Greater Defense
        {13657}, -- Enchant Cloak - Fire Resistance
        {13635}, -- Enchant Cloak - Defense
        {13522}, -- Enchant Cloak - Lesser Shadow Resistance
        {7861}, -- Enchant Cloak - Lesser Fire Resistance
        {13421}, -- Enchant Cloak - Lesser Protection
        {13419}, -- Enchant Cloak - Minor Agility
        {7771}, -- Enchant Cloak - Minor Protection
        {7454}, -- Enchant Cloak - Minor Resistance
        {47051, tbc = true}, -- Enchant Cloak - Steelweave
        {34006, tbc = true}, -- Enchant Cloak - Greater Shadow Resistance
        {34005, tbc = true}, -- Enchant Cloak - Greater Arcane Resistance
        {27962, tbc = true}, -- Enchant Cloak - Major Resistance
        {34003, tbc = true}, -- Enchant Cloak - Spell Penetration
        {34004, tbc = true}, -- Enchant Cloak - Greater Agility
        {27961, tbc = true}, -- Enchant Cloak - Major Armor
        {25086, tbc = true}, -- Enchant Cloak - Dodge
        {25081, tbc = true}, -- Enchant Cloak - Greater Fire Resistance
        {25082, tbc = true}, -- Enchant Cloak - Greater Nature Resistance
        {25084, tbc = true}, -- Enchant Cloak - Subtlety
        {25083, tbc = true}, -- Enchant Cloak - Stealth
    },
    chest = {
        {20025}, -- Enchant Chest - Greater Stats
        {20028}, -- Enchant Chest - Major Mana
        {20026}, -- Enchant Chest - Major Health
        {13941}, -- Enchant Chest - Stats
        {13917}, -- Enchant Chest - Superior Mana
        {13858}, -- Enchant Chest - Superior Health
        {13700}, -- Enchant Chest - Lesser Stats
        {13663}, -- Enchant Chest - Greater Mana
        {13640}, -- Enchant Chest - Greater Health
        {13626}, -- Enchant Chest - Minor Stats
        {13607}, -- Enchant Chest - Mana
        {13538}, -- Enchant Chest - Lesser Absorption
        {7857}, -- Enchant Chest - Health
        {7776}, -- Enchant Chest - Lesser Mana
        {7748}, -- Enchant Chest - Lesser Health
        {7426}, -- Enchant Chest - Minor Absorption
        {7443}, -- Enchant Chest - Minor Mana
        {7420}, -- Enchant Chest - Minor Health
        {46594, tbc = true}, -- Enchant Chest - Defense
        {33992, tbc = true}, -- Enchant Chest - Major Resilience
        {27960, tbc = true}, -- Enchant Chest - Exceptional Stats
        {33990, tbc = true}, -- Enchant Chest - Major Spirit
        {27957, tbc = true}, -- Enchant Chest - Exceptional Health
        {33991, tbc = true}, -- Enchant Chest - Restore Mana Prime
    },
    feet = {
        {20023}, -- Enchant Boots - Greater Agility
        {20024}, -- Enchant Boots - Spirit
        {20020}, -- Enchant Boots - Greater Stamina
        {13935}, -- Enchant Boots - Agility
        {13890}, -- Enchant Boots - Minor Speed
        {13836}, -- Enchant Boots - Stamina
        {13687}, -- Enchant Boots - Lesser Spirit
        {13644}, -- Enchant Boots - Lesser Stamina
        {13637}, -- Enchant Boots - Lesser Agility
        {7867}, -- Enchant Boots - Minor Agility
        {7863}, -- Enchant Boots - Minor Stamina
        {27954, tbc = true}, -- Enchant Boots - Surefooted
        {34008, tbc = true}, -- Enchant Boots - Boar's Speed
        {34007, tbc = true}, -- Enchant Boots - Cat's Swiftness
        {27951, tbc = true}, -- Enchant Boots - Dexterity
        {27950, tbc = true}, -- Enchant Boots - Fortitude
        {27948, tbc = true}, -- Enchant Boots - Vitality
    },
    hand = {
        {25080}, -- Enchant Gloves - Superior Agility
        {25073}, -- Enchant Gloves - Shadow Power
        {25074}, -- Enchant Gloves - Frost Power
        {25072}, -- Enchant Gloves - Threat
        {25079}, -- Enchant Gloves - Healing Power
        {25078}, -- Enchant Gloves - Fire Power
        {20013}, -- Enchant Gloves - Greater Strength
        {20012}, -- Enchant Gloves - Greater Agility
        {13948}, -- Enchant Gloves - Minor Haste
        {13947}, -- Enchant Gloves - Riding Skill
        {13868}, -- Enchant Gloves - Advanced Herbalism
        {13887}, -- Enchant Gloves - Strength
        {13841}, -- Enchant Gloves - Advanced Mining
        {13815}, -- Enchant Gloves - Agility
        {13698}, -- Enchant Gloves - Skinning
        {13617}, -- Enchant Gloves - Herbalism
        {13620}, -- Enchant Gloves - Fishing
        {13612}, -- Enchant Gloves - Mining
        {33997, tbc = true}, -- Enchant Gloves - Major Spellpower
        {33994, tbc = true}, -- Enchant Gloves - Spell Strike
        {33999, tbc = true}, -- Enchant Gloves - Major Healing
        {33995, tbc = true}, -- Enchant Gloves - Major Strength
        {33996, tbc = true}, -- Enchant Gloves - Assault
        {33993, tbc = true}, -- Enchant Gloves - Blasting
        {25080, tbc = true}, -- Enchant Gloves - Superior Agility
        {25072, tbc = true}, -- Enchant Gloves - Threat
    },
    shield = {
        {20016}, -- Enchant Shield - Superior Spirit
        {20017}, -- Enchant Shield - Greater Stamina
        {13933}, -- Enchant Shield - Frost Resistance
        {13905}, -- Enchant Shield - Greater Spirit
        {13817}, -- Enchant Shield - Stamina
        {13689}, -- Enchant Shield - Lesser Block
        {13659}, -- Enchant Shield - Spirit
        {13631}, -- Enchant Shield - Lesser Stamina
        {13485}, -- Enchant Shield - Lesser Spirit
        {13464}, -- Enchant Shield - Lesser Protection
        {13378}, -- Enchant Shield - Minor Stamina
        {27947, tbc = true}, -- Enchant Shield - Resistance
        {44383, tbc = true}, -- Enchant Shield - Resilience
        {27946, tbc = true}, -- Enchant Shield - Shield Block
        {34009, tbc = true}, -- Enchant Shield - Major Stamina
        {27945, tbc = true}, -- Enchant Shield - Intellect
        {27944, tbc = true}, -- Enchant Shield - Tough Shield
    },
    wrist = {
        {23802}, -- Enchant Bracer - Healing Power
        {20011}, -- Enchant Bracer - Superior Stamina
        {20010}, -- Enchant Bracer - Superior Strength
        {23801}, -- Enchant Bracer - Mana Regeneration
        {20009}, -- Enchant Bracer - Superior Spirit
        {20008}, -- Enchant Bracer - Greater Intellect
        {13945}, -- Enchant Bracer - Greater Stamina
        {13939}, -- Enchant Bracer - Greater Strength
        {13931}, -- Enchant Bracer - Deflection
        {13846}, -- Enchant Bracer - Greater Spirit
        {13822}, -- Enchant Bracer - Intellect
        {13661}, -- Enchant Bracer - Strength
        {13648}, -- Enchant Bracer - Stamina
        {13646}, -- Enchant Bracer - Lesser Deflection
        {13642}, -- Enchant Bracer - Spirit
        {13622}, -- Enchant Bracer - Lesser Intellect
        {13536}, -- Enchant Bracer - Lesser Strength
        {13501}, -- Enchant Bracer - Lesser Stamina
        {7859}, -- Enchant Bracer - Lesser Spirit
        {7779}, -- Enchant Bracer - Minor Agility
        {7782}, -- Enchant Bracer - Minor Strength
        {7766}, -- Enchant Bracer - Minor Spirit
        {7457}, -- Enchant Bracer - Minor Stamina
        {7428}, -- Enchant Bracer - Minor Deflect
        {7418}, -- Enchant Bracer - Minor Health
        {27917, tbc = true}, -- Enchant Bracer - Spellpower
        {27914, tbc = true}, -- Enchant Bracer - Fortitude
        {27913, tbc = true}, -- Enchant Bracer - Restore Mana Prime
        {27911, tbc = true}, -- Enchant Bracer - Superior Healing
        {27905, tbc = true}, -- Enchant Bracer - Stats
        {27906, tbc = true}, -- Enchant Bracer - Major Defense
        {34001, tbc = true}, -- Enchant Bracer - Major Intellect
        {27899, tbc = true}, -- Enchant Bracer - Brawn
        {34002, tbc = true}, -- Enchant Bracer - Assault
    },
    finger = {
        {27927, tbc = true}, -- Enchant Ring - Stats
        {27926, tbc = true}, -- Enchant Ring - Healing Power
        {27924, tbc = true}, -- Enchant Ring - Spellpower
        {27920, tbc = true}, -- Enchant Ring - Striking
    },
}

-- The slots of each equip location, with the order they are shown in.
local SLOTS = {
    INVTYPE_WEAPON = {"weapon"},
    INVTYPE_WEAPONMAINHAND = {"weapon"},
    INVTYPE_WEAPONOFFHAND = {"weapon"},
    INVTYPE_2HWEAPON = {"twoHand", "weapon"},
    INVTYPE_CLOAK = {"cloak"},
    INVTYPE_CHEST = {"chest"},
    INVTYPE_ROBE = {"chest"},
    INVTYPE_FEET = {"feet"},
    INVTYPE_HAND = {"hand"},
    INVTYPE_SHIELD = {"shield"},
    INVTYPE_WRIST = {"wrist"},
    INVTYPE_FINGER = {"finger"}
}

local GetItemInfoInstant = C_Item and C_Item.GetItemInfoInstant or GetItemInfoInstant

--[[
The enchants an item can take, by slot: {slot, crafts}, crafts being {spellId, skill}, the skill
the enchanter needs, lowest first. Slots whose enchants this game version lacks are left out.
]]
function Enchants.ForItem(itemId)
    local equipLoc = GetItemInfoInstant and select(4, GetItemInfoInstant(itemId))
    local tbc = Util.IsTBC()
    local groups = {}
    for _, slot in ipairs(equipLoc and SLOTS[equipLoc] or {}) do
        local crafts = {}
        for _, spell in ipairs(SPELLS[slot]) do
            local craft = (tbc or not spell.tbc) and Crafts.Get(spell[1])
            if craft then
                local skill = (craft[3] and craft[3] > 0) and craft[3] or craft[4] or 0
                table.insert(crafts, {spellId = spell[1], skill = skill})
            end
        end
        table.sort(crafts, function (a, b)
            if a.skill ~= b.skill then
                return a.skill < b.skill
            end
            return a.spellId < b.spellId
        end)
        if #crafts > 0 then
            table.insert(groups, {slot = slot, crafts = crafts})
        end
    end
    return groups
end
