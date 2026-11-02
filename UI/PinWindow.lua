--[[
Pinned windows: what an item is used for, and for a crafted item what its craft takes, kept on
screen; reagents are rows like the rest, so they open in turn. Alt over an item opens one; Alt over a
row of a window (or a right click on it) opens a nested window beside it, one level deeper.
Rows are buttons: hover shows the row's tooltip, a click opens the item window, Shift-click
links the item or quest in chat. Alt-click on an item link in chat opens a window too. A source
row (zones, sold by, quest reward) opens the whole list in a nested window on a click. The
last row offers the item's Wowhead page to copy.
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
-- Long rows (sources) wrap at this width unless the other rows make the window wider anyway.
local WRAP_WIDTH = 320
-- The tallest a window gets before its list scrolls, as a share of the screen.
local MAX_HEIGHT_SHARE = 0.6

-- Windows by nesting level, 1 being the one opened from an ordinary tooltip.
local windows = {}

-- A dialog with a web page's address selected for copying: addons can't open a browser.
StaticPopupDialogs.CRAFTCOMPASS_COPY_URL = {
    text = L.CopyUrlHint,
    button1 = CLOSE,
    hasEditBox = true,
    editBoxWidth = 360,
    OnShow = function (dialog, url)
        local editBox = dialog.editBox or dialog.EditBox
        editBox:SetText(url)
        editBox:HighlightText()
        editBox:SetFocus()
    end,
    -- The address is there to be copied, not edited.
    EditBoxOnTextChanged = function (editBox, url)
        if editBox:GetText() ~= url then
            editBox:SetText(url)
            editBox:HighlightText()
        end
    end,
    EditBoxOnEnterPressed = function (editBox)
        editBox:GetParent():Hide()
    end,
    EditBoxOnEscapePressed = function (editBox)
        editBox:GetParent():Hide()
    end,
    timeout = 0,
    whileDead = true,
    hideOnEscape = true,
    preferredIndex = 3
}

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
    elseif row.open then
        GameTooltip:AddLine(row.open.label, 1, 0.82, 0)
        GameTooltip:AddLine(L.OpenListHint, 0.65, 0.65, 0.65)
        GameTooltip:Show()
    elseif row.url then
        GameTooltip:AddLine(L.WowheadPage, 1, 0.82, 0)
        GameTooltip:AddLine(row.url, 1, 1, 1)
        GameTooltip:AddLine(L.CopyUrlClickHint, 0.65, 0.65, 0.65)
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
    if row.open then
        PinWindow.OpenList(row)
    elseif row.url then
        StaticPopup_Show("CRAFTCOMPASS_COPY_URL", nil, nil, row.url)
    elseif row.quest then
        if IsModifiedClick("CHATLINK") then
            InsertChatLink(Quests.GetChatLink(row.quest))
        end
    elseif row.link then
        -- With Alt the row is opened nested, not as a new first window by the chat link hook.
        if button == "RightButton" or IsAltKeyDown() then
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
    -- Long rows show their text here instead, wrapped at the window's width.
    row.wrapText = row:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    row.wrapText:SetPoint("TOPLEFT", 0, -1)
    row.wrapText:SetJustifyH("LEFT")
    row.wrapText:SetJustifyV("TOP")
    row.wrapText:SetWordWrap(true)
    row.wrapText:Hide()
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
    -- The template closes through HideUIPanel, which is blocked in combat; this window isn't a
    -- panel and can always be hidden directly.
    close:SetScript("OnClick", function ()
        window:Hide()
    end)

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

--- The width of a text on one line, even when the font string is narrower and wraps it.
local function NaturalWidth(fontString)
    local width = fontString.GetUnboundedStringWidth and fontString:GetUnboundedStringWidth()
    return width or fontString:GetStringWidth()
end

local function Fill(window, lines)
    local width = window.title.text:GetStringWidth() + 30
    local wrapWidth = 0
    local previous
    for i, line in ipairs(lines) do
        local row = GetRow(window, i)
        row.link = line.link
        row.quest = line.quest
        row.open = line.open
        row.url = line.url
        row.wraps = line.wrap and not line.spacer
        local text = row.wraps and row.wrapText or row.text
        row.text:SetShown(not row.wraps)
        row.wrapText:SetShown(row.wraps)
        text:SetText(line.spacer and "" or line.text)
        text:SetTextColor(unpack(line.color or {1, 1, 1}))
        row.right:SetText(line.right or "")
        row.right:SetTextColor(unpack(line.rightColor or {1, 1, 1}))
        row:EnableMouse(line.link ~= nil or line.quest ~= nil or line.open ~= nil or line.url ~= nil)
        row:ClearAllPoints()
        if previous then
            row:SetPoint("TOPLEFT", previous, "BOTTOMLEFT")
        else
            row:SetPoint("TOPLEFT")
        end
        row:Show()
        if row.wraps then
            wrapWidth = math.max(wrapWidth, NaturalWidth(row.wrapText))
        else
            local rowWidth = row.text:GetStringWidth()
            if line.right then
                rowWidth = rowWidth + RIGHT_TEXT_GAP + row.right:GetStringWidth()
            end
            width = math.max(width, rowWidth)
        end
        previous = row
    end
    for i = #lines + 1, #window.rows do
        window.rows[i]:Hide()
    end
    -- Long rows get the width the rest needs, or up to WRAP_WIDTH, and wrap past it.
    width = math.max(width, math.min(wrapWidth, WRAP_WIDTH))
    window.title:SetWidth(width)

    local contentHeight = 0
    for i, line in ipairs(lines) do
        local row = window.rows[i]
        row:SetWidth(width)
        if row.wraps then
            row.wrapText:SetWidth(width)
            row:SetHeight(math.max(ROW_HEIGHT, math.ceil((row.wrapText:GetStringHeight() or 0) + 2)))
        else
            row:SetHeight(line.spacer and SPACER_HEIGHT or ROW_HEIGHT)
        end
        contentHeight = contentHeight + row:GetHeight()
    end
    return width, contentHeight
end

--[[
Shows content in the window at a level: {key, title, titleLink, build}, where title is a function
returning the title text and build returns the lines and whether some names are still pending.
The same content again keeps the window as it is. A refresh redraws the window in place (names
that have arrived since), keeping its position, scroll and nested windows.
]]
local function ShowContent(level, content, isRefresh)
    local window = windows[level] or CreateWindow(level)
    if window:IsShown() and window.view and window.view.key == content.key and not isRefresh then
        return
    end
    if not isRefresh and windows[level + 1] then
        windows[level + 1]:Hide()
    end

    local lines, pending = content.build()
    window.view = content
    window.pending = pending
    window.title.link = content.titleLink
    window.title.text:SetText(content.title())

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

--- Shows what the item behind a link takes, where it comes from and what it is used for.
function PinWindow.Show(level, link, isRefresh)
    local itemId = Util.ItemIdFromLink(link)
    if not itemId then
        return
    end
    ShowContent(level, {
        key = link,
        titleLink = link,
        title = function ()
            return link
        end,
        build = function ()
            return Lines.ForWindow(itemId)
        end
    }, isRefresh)
end

--- Opens the whole list a source row stands for (all zones, vendors, quests) one level deeper.
function PinWindow.OpenList(row)
    local open = row.open
    local _, link = Util.GetItemInfo(open.itemId)
    ShowContent(row.craftCompassLevel + 1, {
        key = open.kind .. ":" .. open.itemId,
        titleLink = link,
        title = function ()
            local _, itemLink = Util.GetItemInfo(open.itemId)
            return open.label .. ": " .. (itemLink or ("#" .. open.itemId))
        end,
        build = function ()
            local lines, pending = Lines.ForList(open)
            return lines, pending or link == nil
        end
    })
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
            ShowContent(level, window.view, true)
        end
    end
end

-- Alt-click on an item link (chat, quest log and anything else that goes through SetItemRef)
-- pins the item instead of opening the item window.
hooksecurefunc("SetItemRef", function (link, text)
    if IsAltKeyDown() and type(link) == "string" and link:match("^item:") and text then
        PinWindow.Show(1, text)
        ItemRefTooltip:Hide()
    end
end)
