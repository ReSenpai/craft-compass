-- The options panel (game options > AddOns, or /craftcompass) and the slash commands.
local addonName, ns = ...
local L = ns.L

local function Toggle(order, key, name, description)
    return {
        order = order,
        type = "toggle",
        width = "full",
        name = name,
        desc = description,
        get = function ()
            return ns.settings[key]
        end,
        set = function (_, value)
            ns.settings[key] = value
        end
    }
end

local options = {
    type = "group",
    name = L.OptionsTitle,
    args = {
        help = {order = 0, type = "description", fontSize = "medium", name = L.OptionsHelp .. "\n"},
        onlyMyProfessions = Toggle(1, "onlyMyProfessions", L.OnlyMyProfessions, L.OnlyMyProfessionsDesc),
        showCompletedQuests = Toggle(2, "showCompletedQuests", L.ShowCompletedQuests, L.ShowCompletedQuestsDesc),
        showNotUsed = Toggle(3, "showNotUsed", L.ShowNotUsed, L.ShowNotUsedDesc)
    }
}

ns.OnLogin(function ()
    local ConfigDialog = LibStub("AceConfigDialog-3.0")
    LibStub("AceConfigRegistry-3.0"):RegisterOptionsTable(addonName, options)
    ConfigDialog:AddToBlizOptions(addonName, L.OptionsTitle)

    SLASH_CRAFTCOMPASS1 = "/craftcompass"
    SLASH_CRAFTCOMPASS2 = "/ccompass"
    SlashCmdList.CRAFTCOMPASS = function ()
        ConfigDialog:Open(addonName)
    end
end)
