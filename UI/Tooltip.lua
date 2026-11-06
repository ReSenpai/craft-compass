--[[
Item tooltips. Shift (or Ctrl) adds what the item is used for, Alt pins that into a window
instead. What the item's craft takes and where the item comes from are added with Shift, on rows
of pinned windows, and always in the item window a click on a link opens.
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
    if owner and owner.craftCompassWindow then
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
    local spellId = Util.SpellIdFromLink(link)
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
        local lines, originPending = Lines.ForOrigin(itemId)
        if lines then
            Lines.AddToTooltip(tooltip, lines)
            isPending = originPending
            added = true
            -- Reagents can't be clicked in the item window; a pinned window lets them be opened.
            if isItemWindow and Crafts.ForCreatedItem(itemId) then
                tooltip:AddLine(L.PinLinkHint, 0.65, 0.65, 0.65, true)
            end
        end
    end

    if alt and not isItemWindow then
        -- Alt over a pinned row opens its window's nested one; the title is that window's own item.
        if not (row and row.isTitle) then
            PinWindow.Show(row and row.craftCompassWindow, link)
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

--[[
Draws the hovered tooltip again by entering the frame it belongs to once more. A secure frame,
such as an action button, is never entered: what its OnEnter writes into it would then come from
addon code, and the game would block the button's next click as the addon's. Its tooltip is set
again directly instead.
]]
local function RefreshHovered()
    if not GameTooltip:IsShown() then
        return
    end
    local owner = GameTooltip:GetOwner()
    if not (owner and owner.IsMouseOver and owner:IsMouseOver()) then
        return
    end
    if owner.IsProtected and owner:IsProtected() then
        local _, link = GameTooltip:GetItem()
        if type(owner.action) == "number" and GameTooltip.SetAction then
            GameTooltip:SetAction(owner.action)
        elseif link then
            GameTooltip:SetHyperlink(Util.LinkData(link))
        end
        return
    end
    local onEnter = owner:GetScript("OnEnter")
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

-- Shift, Ctrl and Alt change what an item tooltip shows, so it is drawn again when they change;
-- over an enchant row of a pinned window, Alt opens it.
local modifierFrame = CreateFrame("Frame")
modifierFrame:RegisterEvent("MODIFIER_STATE_CHANGED")
modifierFrame:SetScript("OnEvent", function ()
    if GameTooltip:IsShown() and (GameTooltip:GetItem() or GetPinnedRow(GameTooltip)) then
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
