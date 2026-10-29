-- The addon's namespace, its saved settings and the login hook the other files start from.
local addonName, ns = ...

ns.name = addonName

-- Strings by key; a key without a translation shows as itself. Filled in by Locales/.
ns.L = setmetatable({}, {
    __index = function (_, key)
        return key
    end
})

local defaults = {
    -- Recipes only for the professions the character has.
    onlyMyProfessions = false,
    -- Quests the character has already completed.
    showCompletedQuests = true,
    -- A line saying the item isn't used anywhere.
    showNotUsed = true
}

-- Read through ns.settings.<name>: the table is replaced once the saved variables are loaded.
ns.settings = setmetatable({}, {__index = defaults})

local loginCallbacks = {}

--- Runs a function once the player has logged in, when every addon and saved variable is loaded.
function ns.OnLogin(callback)
    table.insert(loginCallbacks, callback)
end

local frame = CreateFrame("Frame")
frame:RegisterEvent("ADDON_LOADED")
frame:RegisterEvent("PLAYER_LOGIN")
frame:SetScript("OnEvent", function (_, event, loaded)
    if event == "ADDON_LOADED" and loaded == addonName then
        CraftCompassDB = CraftCompassDB or {}
        ns.settings = setmetatable(CraftCompassDB, {__index = defaults})
    elseif event == "PLAYER_LOGIN" then
        for _, callback in ipairs(loginCallbacks) do
            callback()
        end
    end
end)
