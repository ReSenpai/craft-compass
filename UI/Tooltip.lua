--[[
Item tooltips. Shift (or Ctrl) adds what the item is used for, Alt pins that into a window
instead. A craftable item also gets what its craft takes: with Shift, on rows of pinned windows,
and always in the item window a click on a link opens.
]]
local _, ns = ...
local L, Util, Lines, Crafts, PinWindow = ns.L, ns.Util, ns.Lines, ns.Crafts, ns.PinWindow

local Tooltip = {}
ns.Tooltip = Tooltip

-- Tooltips showing names that weren't cached yet, drawn again once the item info arrives.
local pending = {}

--- The pinned window row a tooltip belongs to, if it belongs to one.
local function GetPinnedRow(tooltip)
    local owner = tooltip:GetOwner()
    if owner and owner.craftCompassLevel then
        return owner
    end
    return nil
end

local function AddCraft(tooltip, spellId)
    local lines, isPending = Lines.ForCraft(spellId)
    if lines then
        Lines.AddToTooltip(tooltip, lines)
    end
    return isPending
end

--- Adds what a craft takes to the tooltip of an enchant or spell link, which the item hook doesn't see.
function Tooltip.AddCraftToSpellTooltip(tooltip, link)
    local spellId = tonumber(link:match("|Henchant:(%d+)") or link:match("|Hspell:(%d+)") or "")
    if spellId and AddCraft(tooltip, spellId) then
        pending[tooltip] = true
    end
end

local function OnTooltipSetItem(tooltip)
    local isItemWindow = tooltip == ItemRefTooltip
    -- Comparison and other tooltips are left alone.
    if tooltip ~= GameTooltip and not isItemWindow then
        return
    end
    local _, link = tooltip:GetItem()
    local itemId = Util.ItemIdFromLink(link)
    if not itemId then
        return
    end

    local row = not isItemWindow and GetPinnedRow(tooltip)
    local alt = IsAltKeyDown()
    local shift = (IsShiftKeyDown() or IsControlKeyDown()) and not alt
    local added, isPending = false, false

    if isItemWindow or row or shift then
        local spellId = Crafts.ForCreatedItem(itemId)
        if spellId then
            isPending = AddCraft(tooltip, spellId)
            added = true
            -- Reagents can't be clicked in the item window; a pinned window lets them be opened.
            if isItemWindow then
                tooltip:AddLine(L.PinLinkHint, 0.65, 0.65, 0.65, true)
            end
        end
    end

    if alt and not isItemWindow then
        -- Alt over a pinned row opens a window one level deeper; the title is that window's own item.
        if not (row and row.isTitle) then
            PinWindow.Show(row and row.craftCompassLevel + 1 or 1, link)
        end
    elseif shift then
        local lines, linesPending = Lines.ForItemUses(itemId)
        Lines.AddToTooltip(tooltip, lines)
        isPending = isPending or linesPending
        added = true
    end

    pending[tooltip] = isPending or nil
    if added then
        tooltip:Show()
    end
end

--- Draws the hovered tooltip again by entering the frame it belongs to once more.
local function RefreshHovered()
    if not GameTooltip:IsShown() then
        return
    end
    local owner = GameTooltip:GetOwner()
    local onEnter = owner and owner.IsMouseOver and owner:IsMouseOver() and owner:GetScript("OnEnter")
    if onEnter then
        onEnter(owner)
    end
end

local function RefreshItemWindow()
    if ItemRefTooltip:IsShown() then
        local _, link = ItemRefTooltip:GetItem()
        if link then
            ItemRefTooltip:SetHyperlink(Util.LinkData(link))
        end
    end
end

-- Shift, Ctrl and Alt change what an item tooltip shows, so it is drawn again when they change.
local modifierFrame = CreateFrame("Frame")
modifierFrame:RegisterEvent("MODIFIER_STATE_CHANGED")
modifierFrame:SetScript("OnEvent", function ()
    if GameTooltip:IsShown() and GameTooltip:GetItem() then
        RefreshHovered()
    end
end)

-- Item names arrive from the server in bursts; one redraw after a short pause covers a burst.
local refreshQueued = false
local itemInfoFrame = CreateFrame("Frame")
itemInfoFrame:RegisterEvent("GET_ITEM_INFO_RECEIVED")
itemInfoFrame:SetScript("OnEvent", function ()
    if refreshQueued then
        return
    end
    refreshQueued = true
    C_Timer.After(0.2, function ()
        refreshQueued = false
        PinWindow.RefreshPending()
        if pending[GameTooltip] then
            RefreshHovered()
        end
        if pending[ItemRefTooltip] then
            RefreshItemWindow()
        end
    end)
end)

ns.OnLogin(function ()
    for _, tooltip in ipairs({GameTooltip, ItemRefTooltip}) do
        if tooltip:HasScript("OnTooltipSetItem") then
            tooltip:HookScript("OnTooltipSetItem", OnTooltipSetItem)
        end
        if tooltip:HasScript("OnTooltipCleared") then
            tooltip:HookScript("OnTooltipCleared", function (cleared)
                pending[cleared] = nil
            end)
        end
    end
    -- Newer clients dropped OnTooltipSetItem for this. Classic clients have both but only
    -- call OnTooltipSetItem, so this is used only where the script is gone.
    if not GameTooltip:HasScript("OnTooltipSetItem") and TooltipDataProcessor then
        TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.Item, OnTooltipSetItem)
    end
end)
