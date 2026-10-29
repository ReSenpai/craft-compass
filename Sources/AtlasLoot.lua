--[[
Crafts from AtlasLoot Classic: what each profession spell makes, from which reagents, and its
recipe item. AtlasLoot looks crafts up by spell id only, so after login we go through the spell
ids once to index them by reagent and by the item they create.
]]
local _, ns = ...
local Util = ns.Util

local Crafts = {}
ns.Crafts = Crafts

-- Craft spells go up to about 30000 in Classic Era and 51000 in TBC, but the Anniversary
-- client added a few around 351000. A lookup is cheap, so the whole range is searched.
local MAX_CRAFT_SPELL_ID = 400000
local SPELLS_PER_STEP = 10000

-- The spell each of AtlasLoot's profession ids is named after, for the localized name and icon.
local PROFESSION_SPELLS = {
    [1] = 3273, -- First Aid
    [2] = 2018, -- Blacksmithing
    [3] = 2108, -- Leatherworking
    [4] = 2259, -- Alchemy
    [5] = 2366, -- Herbalism
    [6] = 2550, -- Cooking
    [7] = 2575, -- Mining
    [8] = 3908, -- Tailoring
    [9] = 4036, -- Engineering
    [10] = 7411, -- Enchanting
    [11] = 7620, -- Fishing
    [12] = 8618, -- Skinning
    [13] = 2842, -- Poisons
    [14] = 25229 -- Jewelcrafting
}

local spellsByReagent = {}
local spellByCreatedItem = {}
local finishIndex

local function GetDataModule(name)
    local data = AtlasLoot and AtlasLoot.Data
    return data and data[name]
end

function Crafts.IsAvailable()
    local profession = GetDataModule("Profession")
    return profession ~= nil and type(profession.GetProfessionData) == "function"
end

--[[
A craft as AtlasLoot stores it, or nil:
{ createdItemId, professionId, minSkill, lowSkill, highSkill, reagentIds, reagentCounts, numCreated }
]]
function Crafts.Get(spellId)
    local profession = GetDataModule("Profession")
    return profession and Util.SafeCall(profession.GetProfessionData, spellId)
end

local function BuildIndex()
    local getCraft = GetDataModule("Profession").GetProfessionData
    for spellId = 1, MAX_CRAFT_SPELL_ID do
        local craft = getCraft(spellId)
        if craft then
            if craft[1] and not spellByCreatedItem[craft[1]] then
                spellByCreatedItem[craft[1]] = spellId
            end
            for _, reagentId in ipairs(craft[6] or {}) do
                spellsByReagent[reagentId] = spellsByReagent[reagentId] or {}
                table.insert(spellsByReagent[reagentId], spellId)
            end
        end
        if spellId % SPELLS_PER_STEP == 0 then
            coroutine.yield()
        end
    end
end

local function EnsureIndex()
    if finishIndex then
        finishIndex()
    end
end

--- The craft spells that use an item as a reagent.
function Crafts.ForReagent(itemId)
    EnsureIndex()
    return spellsByReagent[itemId] or {}
end

--- The craft spell that creates an item, if any.
function Crafts.ForCreatedItem(itemId)
    EnsureIndex()
    return spellByCreatedItem[itemId]
end

--- The recipe item that teaches a craft spell; nil for crafts learned from a trainer.
function Crafts.GetRecipeItem(spellId)
    local recipe = GetDataModule("Recipe")
    return recipe and Util.SafeCall(recipe.GetRecipeForSpell, spellId)
end

--- The localized name and icon of one of AtlasLoot's profession ids.
function Crafts.GetProfession(professionId)
    local spellId = PROFESSION_SPELLS[professionId]
    if not spellId then
        return nil
    end
    return Util.GetSpellName(spellId), Util.GetSpellIcon(spellId)
end

ns.OnLogin(function ()
    if Crafts.IsAvailable() then
        finishIndex = Util.RunInBackground(BuildIndex)
    end
end)
