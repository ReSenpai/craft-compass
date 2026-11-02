-- Small helpers over the game client's API, shared by the other files.
local _, ns = ...

local Util = {}
ns.Util = Util

-- The namespaced item functions replaced the global ones on newer clients.
Util.GetItemInfo = C_Item and C_Item.GetItemInfo or GetItemInfo
Util.GetItemIcon = C_Item and C_Item.GetItemIconByID or GetItemIcon
Util.GetItemCount = C_Item and C_Item.GetItemCount or GetItemCount

--- Calls a function from another addon, returning nil instead of raising when it fails.
function Util.SafeCall(func, ...)
    if type(func) ~= "function" then
        return nil
    end
    local ok, result = pcall(func, ...)
    if ok then
        return result
    end
    return nil
end

function Util.GetSpellName(spellId)
    if GetSpellInfo then
        return (GetSpellInfo(spellId))
    end
    local info = C_Spell and C_Spell.GetSpellInfo and C_Spell.GetSpellInfo(spellId)
    return info and info.name
end

function Util.GetSpellIcon(spellId)
    if GetSpellTexture then
        return GetSpellTexture(spellId)
    end
    return C_Spell and C_Spell.GetSpellTexture and C_Spell.GetSpellTexture(spellId)
end

function Util.GetSpellLink(spellId)
    if GetSpellLink then
        return GetSpellLink(spellId)
    end
    return C_Spell and C_Spell.GetSpellLink and C_Spell.GetSpellLink(spellId)
end

--- An inline texture for the start of a line, or nothing without a texture.
function Util.Icon(texture)
    if not texture then
        return ""
    end
    return "|T" .. texture .. ":0|t "
end

--- The hyperlink part of a link ("item:2589:..."), as SetHyperlink and SetItemRef take it.
function Util.LinkData(link)
    return link and link:match("|H(.-)|h")
end

function Util.ItemIdFromLink(link)
    return link and tonumber(link:match("|Hitem:(%d+)"))
end

--- The spell of a spell or enchant link, as crafts without an item (enchants) are linked.
function Util.SpellIdFromLink(link)
    return link and tonumber(link:match("|Henchant:(%d+)") or link:match("|Hspell:(%d+)"))
end

--- What a spell does, as its tooltip says; empty until the client has the spell's data.
function Util.GetSpellDescription(spellId)
    if GetSpellDescription then
        return GetSpellDescription(spellId)
    end
    return C_Spell and C_Spell.GetSpellDescription and C_Spell.GetSpellDescription(spellId)
end

--[[
Asks the client for a spell's data it doesn't have yet and calls back once it arrives. Returns
whether it asked: false when the data is already there (or the client can't say).
]]
function Util.LoadSpell(spellId, callback)
    local spell = Spell and Spell.CreateFromSpellID and Spell:CreateFromSpellID(spellId)
    if not spell or spell:IsSpellDataCached() then
        return false
    end
    spell:ContinueOnSpellLoad(callback)
    return true
end

-- Wowhead's language folders by client locale; English and languages it lacks have none.
local WOWHEAD_LANGUAGES = {
    deDE = "de", esES = "es", esMX = "es", frFR = "fr", itIT = "it", ptBR = "pt", ruRU = "ru", koKR = "ko", zhCN = "cn"
}

--- An item's or spell's page on Wowhead (kind "item" or "spell"), for the client's game version and language.
function Util.WowheadUrl(kind, id)
    local interface = select(4, GetBuildInfo())
    local site = (interface >= 20000 and interface < 30000) and "tbc" or "classic"
    local language = WOWHEAD_LANGUAGES[GetLocale()]
    return "https://www.wowhead.com/" .. site .. (language and "/" .. language or "") .. "/" .. kind .. "=" .. id
end

--- Whether the character has a skill line with this (localized) name.
function Util.HasSkill(name)
    for i = 1, GetNumSkillLines() do
        if GetSkillLineInfo(i) == name then
            return true
        end
    end
    return false
end

function Util.IsQuestCompleted(questId)
    if C_QuestLog and C_QuestLog.IsQuestFlaggedCompleted then
        return C_QuestLog.IsQuestFlaggedCompleted(questId)
    end
    return IsQuestFlaggedCompleted and IsQuestFlaggedCompleted(questId) or false
end

--- Tests a 1-based flag in a race or class mask; an empty mask allows everyone.
function Util.MaskAllows(mask, index)
    if not mask or mask == 0 or not index then
        return true
    end
    local flag = 2 ^ (index - 1)
    -- Arithmetic rather than bit.band, which stops at 32 bits.
    return mask % (flag * 2) >= flag
end

--[[
Runs work spread over frames so it doesn't freeze the game. The work function calls
coroutine.yield() now and then. Returns a function that finishes the rest right away,
for when the result is needed before it's done.
]]
function Util.RunInBackground(work)
    local routine = coroutine.create(work)
    local ticker

    local function resume()
        local ok, err = coroutine.resume(routine)
        if not ok then
            geterrorhandler()(err)
        end
    end

    ticker = C_Timer.NewTicker(0, function ()
        resume()
        if coroutine.status(routine) == "dead" then
            ticker:Cancel()
        end
    end)

    return function ()
        while coroutine.status(routine) ~= "dead" do
            resume()
        end
        ticker:Cancel()
    end
end
