--[[
Pinned windows: what an item is used for, kept on screen. Alt over an item opens one; Alt over a
row of a window (or a right click on it) opens a nested window beside it, one level deeper.
Rows are buttons: hover shows the row's tooltip, a click opens the item window, Shift-click
links the item or quest in chat.
]]
local _, ns = ...
local L, Util, Lines, Quests = ns.L, ns.Util, ns.Lines, ns.Quests

local PinWindow = {}
ns.PinWindow = PinWindow

local ROW_HEIGHT = 16
local SPACER_HEIGHT = 6
local PADDING = 12
local SCROLLBAR_WIDTH = 16
local RIGHT_TEXT_GAP = 16
local MIN_WIDTH = 220
-- The tallest a window gets before its list scrolls, as a share of the screen.
local MAX_HEIGHT_SHARE = 0.6

-- Windows by nesting level, 1 being the one opened from an ordinary tooltip.
local windows = {}

--- Puts a link into the chat input like Shift-clicking one does, opening the input when it's closed.
local function InsertChatLink(text)
    if not ChatEdit_InsertLink(text) then
        ChatFrame_OpenChat(text)
    end
end

local function Row_OnEnter(row)
    GameTooltip:SetOwner(row, "ANCHOR_RIGHT")
    if row.quest then
        GameTooltip:AddLine(Quests.GetName(row.quest), 1, 0.82, 0)
        local level = Quests.GetLevel(row.quest)
        if level then
            GameTooltip:AddLine(string.format(L.QuestLevel, level), 1, 1, 1)
        end
        local zone = Quests.GetZone(row.quest)
        if zone then
            GameTooltip:AddLine(zone, 1, 1, 1)
        end
        GameTooltip:AddLine(L.QuestLinkHint, 0.65, 0.65, 0.65)
        GameTooltip:Show()
    elseif row.link then
        -- Items get their extra lines from the tooltip hook; ns.Tooltip adds them to enchants.
        GameTooltip:SetHyperlink(Util.LinkData(row.link))
        ns.Tooltip.AddCraftToSpellTooltip(GameTooltip, row.link)
        GameTooltip:Show()
    end
end

local function Row_OnLeave()
    GameTooltip:Hide()
end

local function Row_OnClick(row, button)
    if row.quest then
        if IsModifiedClick("CHATLINK") then
            InsertChatLink(Quests.GetChatLink(row.quest))
        end
    elseif row.link then
        if button == "RightButton" then
            PinWindow.OpenNested(row)
        elseif IsModifiedClick("CHATLINK") then
            InsertChatLink(row.link)
        else
            SetItemRef(Util.LinkData(row.link), row.link, button)
        end
    end
end

local function CreateRow(window, parent)
    local row = CreateFrame("Button", nil, parent)
    row:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    row:SetHighlightTexture("Interface\\QuestFrame\\UI-QuestTitleHighlight", "ADD")
    row.text = row:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    row.text:SetPoint("LEFT")
    row.text:SetJustifyH("LEFT")
    row.right = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    row.right:SetPoint("RIGHT")
    row.right:SetJustifyH("RIGHT")
    -- Read by the tooltip hook to tell pinned rows from everything else.
    row.craftCompassLevel = window.level
    row:SetScript("OnEnter", Row_OnEnter)
    row:SetScript("OnLeave", Row_OnLeave)
    row:SetScript("OnClick", Row_OnClick)
    return row
end

local function SetScroll(window, value)
    value = math.max(0, math.min(value, window.scroll:GetVerticalScrollRange()))
    window.scroll:SetVerticalScroll(value)
    window.scrollBar:SetValue(value)
end

local function CreateWindow(level)
    local name = "CraftCompassWindow" .. level
    local window = CreateFrame("Frame", name, UIParent, BackdropTemplateMixin and "BackdropTemplate")
    window.level = level
    window.rows = {}
    window:SetBackdrop({
        bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true,
        tileSize = 16,
        edgeSize = 16,
        insets = {left = 4, right = 4, top = 4, bottom = 4}
    })
    window:SetBackdropColor(0, 0, 0, 0.9)
    window:SetFrameStrata("DIALOG")
    window:SetToplevel(true)
    window:SetClampedToScreen(true)
    window:EnableMouse(true)
    window:SetMovable(true)
    window:RegisterForDrag("LeftButton")
    window:SetScript("OnDragStart", window.StartMoving)
    window:SetScript("OnDragStop", window.StopMovingOrSizing)
    -- Nested windows belong to this one and close with it.
    window:SetScript("OnHide", function ()
        if windows[level + 1] then
            windows[level + 1]:Hide()
        end
    end)
    -- Escape closes the windows.
    table.insert(UISpecialFrames, name)

    local close = CreateFrame("Button", nil, window, "UIPanelCloseButton")
    close:SetPoint("TOPRIGHT", -2, -2)

    -- The title is the item itself; it can be hovered, clicked and dragged like the window.
    window.title = CreateRow(window, window)
    window.title.isTitle = true
    window.title.text:SetFontObject("GameFontNormalLarge")
    window.title:SetHeight(ROW_HEIGHT + 6)
    window.title:SetPoint("TOPLEFT", PADDING, -PADDING)
    window.title:RegisterForDrag("LeftButton")
    window.title:SetScript("OnDragStart", function () window:StartMoving() end)
    window.title:SetScript("OnDragStop", function () window:StopMovingOrSizing() end)

    window.scroll = CreateFrame("ScrollFrame", nil, window)
    window.scroll:SetPoint("TOPLEFT", window.title, "BOTTOMLEFT")
    window.content = CreateFrame("Frame", nil, window.scroll)
    window.content:SetSize(1, 1)
    window.scroll:SetScrollChild(window.content)
    window.scroll:EnableMouseWheel(true)
    window.scroll:SetScript("OnMouseWheel", function (scroll, delta)
        SetScroll(window, scroll:GetVerticalScroll() - delta * ROW_HEIGHT * 3)
    end)

    window.scrollBar = CreateFrame("Slider", nil, window)
    window.scrollBar:SetOrientation("VERTICAL")
    window.scrollBar:SetWidth(SCROLLBAR_WIDTH)
    window.scrollBar:SetPoint("TOPLEFT", window.scroll, "TOPRIGHT", 4, 0)
    window.scrollBar:SetPoint("BOTTOMLEFT", window.scroll, "BOTTOMRIGHT", 4, 0)
    window.scrollBar:SetThumbTexture("Interface\\Buttons\\UI-ScrollBar-Knob")
    local track = window.scrollBar:CreateTexture(nil, "BACKGROUND")
    track:SetAllPoints()
    track:SetColorTexture(1, 1, 1, 0.08)
    window.scrollBar:SetScript("OnValueChanged", function (_, value)
        window.scroll:SetVerticalScroll(value)
    end)

    -- Frames start out shown; this one waits for its content and position.
    window:Hide()
    windows[level] = window
    return window
end

local function GetRow(window, index)
    if not window.rows[index] then
        window.rows[index] = CreateRow(window, window.content)
    end
    return window.rows[index]
end

--- Puts a nested window beside its parent, on the side with room for it.
local function Place(window)
    window:ClearAllPoints()
    if window.level == 1 then
        window:SetPoint("CENTER")
        return
    end
    local parent = windows[window.level - 1]
    if (parent:GetRight() or 0) + window:GetWidth() > UIParent:GetRight() then
        window:SetPoint("TOPRIGHT", parent, "TOPLEFT", 2, 0)
    else
        window:SetPoint("TOPLEFT", parent, "TOPRIGHT", -2, 0)
    end
end

local function Fill(window, lines)
    local width = window.title.text:GetStringWidth() + 30
    local contentHeight = 0
    local previous
    for i, line in ipairs(lines) do
        local row = GetRow(window, i)
        row.link = line.link
        row.quest = line.quest
        row.text:SetText(line.spacer and "" or line.text)
        row.text:SetTextColor(unpack(line.color or {1, 1, 1}))
        row.right:SetText(line.right or "")
        row.right:SetTextColor(unpack(line.rightColor or {1, 1, 1}))
        row:SetHeight(line.spacer and SPACER_HEIGHT or ROW_HEIGHT)
        row:EnableMouse(line.link ~= nil or line.quest ~= nil)
        row:ClearAllPoints()
        if previous then
            row:SetPoint("TOPLEFT", previous, "BOTTOMLEFT")
        else
            row:SetPoint("TOPLEFT")
        end
        row:Show()
        local rowWidth = row.text:GetStringWidth()
        if line.right then
            rowWidth = rowWidth + RIGHT_TEXT_GAP + row.right:GetStringWidth()
        end
        width = math.max(width, rowWidth)
        contentHeight = contentHeight + row:GetHeight()
        previous = row
    end
    for i = #lines + 1, #window.rows do
        window.rows[i]:Hide()
    end
    window.title:SetWidth(width)
    for i = 1, #lines do
        window.rows[i]:SetWidth(width)
    end
    return width, contentHeight
end

--[[
Shows what the item behind a link is used for in the window at a level. A refresh redraws the
window in place (names that have arrived since), keeping its position, scroll and nested windows.
]]
function PinWindow.Show(level, link, isRefresh)
    local itemId = Util.ItemIdFromLink(link)
    if not itemId then
        return
    end
    local window = windows[level] or CreateWindow(level)
    -- Alt over the same item again: keep the window as it is.
    if window:IsShown() and window.link == link and not isRefresh then
        return
    end
    if not isRefresh and windows[level + 1] then
        windows[level + 1]:Hide()
    end

    local lines, pending = Lines.ForItemUses(itemId)
    window.link = link
    window.pending = pending
    window.title.link = link
    window.title.text:SetText(link)

    local width, contentHeight = Fill(window, lines)
    local maxHeight = math.floor(UIParent:GetHeight() * MAX_HEIGHT_SHARE)
    local scrollHeight = math.min(contentHeight, maxHeight)
    local overflow = contentHeight > maxHeight
    window.content:SetSize(width, math.max(contentHeight, 1))
    window.scroll:SetSize(width, math.max(scrollHeight, 1))
    window.scrollBar:SetMinMaxValues(0, math.max(contentHeight - scrollHeight, 0))
    window.scrollBar:SetShown(overflow)
    window.scroll:UpdateScrollChildRect()
    SetScroll(window, isRefresh and window.scroll:GetVerticalScroll() or 0)

    local windowWidth = width + PADDING * 2 + (overflow and SCROLLBAR_WIDTH + 6 or 0)
    window:SetSize(math.max(windowWidth, MIN_WIDTH), PADDING * 2 + window.title:GetHeight() + scrollHeight)
    -- The first window stays where the player dragged it; nested ones follow their parent.
    if not isRefresh and (level > 1 or not window.placed) then
        Place(window)
        window.placed = true
    end
    window:Show()
    window:Raise()
end

--- Opens the item of a pinned row in a window one level deeper.
function PinWindow.OpenNested(row)
    if row.link and not row.isTitle then
        PinWindow.Show(row.craftCompassLevel + 1, row.link)
    end
end

--- Redraws the windows that were waiting for item names.
function PinWindow.RefreshPending()
    for level, window in ipairs(windows) do
        if window:IsShown() and window.pending then
            PinWindow.Show(level, window.link, true)
        end
    end
end
