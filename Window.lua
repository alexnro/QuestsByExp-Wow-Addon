local addonName, ns = ...

-- The quest list window: search + filter bar, header row, scrolling list
-- of quests with share / abandon buttons, and a "showing X of Y" footer.

local WINDOW_NAME = "OrderQuestsByExpWindow"
local ROW_HEIGHT = 22
local COLUMN_GAP = 4
local ACTIONS_WIDTH = 44
local COLUMNS = {
    { key = "title", label = "Quest", width = 220, justify = "LEFT" },
    { key = "zone",  label = "Zone",  width = 130, justify = "LEFT" },
    { key = "type",  label = "Type",  width = 70,  justify = "LEFT" },
    { key = "level", label = "Lvl",   width = 35,  justify = "CENTER" },
    { key = "xp",    label = "XP",    width = 70,  justify = "RIGHT" },
}

local LIST_WIDTH = ACTIONS_WIDTH
for _, col in ipairs(COLUMNS) do LIST_WIDTH = LIST_WIDTH + col.width + COLUMN_GAP end

local WIDTH = LIST_WIDTH + 12 + 30 -- left inset + scrollbar gutter
local HEIGHT = 420

local SHARE_TEXTURE = "Interface\\GossipFrame\\AvailableQuestIcon"
local ABANDON_TEXTURE = "Interface\\Buttons\\UI-GroupLoot-Pass-Up"

local window

local function CreateCells(parent, fontObject)
    local cells, x = {}, 0
    for _, col in ipairs(COLUMNS) do
        local fs = parent:CreateFontString(nil, "ARTWORK", fontObject)
        fs:SetPoint("LEFT", parent, "LEFT", x, 0)
        fs:SetWidth(col.width)
        fs:SetJustifyH(col.justify)
        fs:SetWordWrap(false)
        cells[col.key] = fs
        x = x + col.width + COLUMN_GAP
    end
    return cells
end

local function FormatXP(data)
    if data.xp then return BreakUpLargeNumbers(data.xp) end
    if data.pending then return "..." end
    return "?"
end
ns.FormatXP = FormatXP

-- Quest name with a green tick in front when it's ready to turn in.
local READY_ICON = "|TInterface\\RaidFrame\\ReadyCheck-Ready:0|t "
function ns.FormatQuestTitle(data)
    if data.complete then return READY_ICON .. data.title end
    return data.title
end

-- Quest tooltip shared by the window rows and the on-screen tracker.
function ns.ShowQuestTooltip(owner, data)
    GameTooltip:SetOwner(owner, "ANCHOR_RIGHT")
    GameTooltip:SetText(data.title, 1, 0.82, 0)
    if data.zone ~= "" then GameTooltip:AddLine(data.zone, 1, 1, 1) end
    GameTooltip:AddLine("Type: " .. ns.GetQuestTypeLabel(data.questType), 1, 1, 1)
    GameTooltip:AddLine("Level " .. data.level, 1, 1, 1)
    GameTooltip:AddLine("XP: " .. FormatXP(data), 1, 1, 1)
    if data.complete then GameTooltip:AddLine("Ready to turn in", 0.3, 1, 0.3) end
    GameTooltip:AddLine("Click to open in the quest log", 0.5, 0.5, 0.5)
    GameTooltip:Show()
end

local function HideTooltip()
    GameTooltip:Hide()
end

-- Row ----------------------------------------------------------------------

local function OnRowClick(row)
    if row.data then ns.OpenQuestDetails(row.data.questID) end
end

local function OnRowEnter(row)
    if row.data then ns.ShowQuestTooltip(row, row.data) end
end

local function OnShareClick(button)
    local data = button:GetParent().data
    if data then ns.ShareQuest(data.questID) end
end

local function OnShareEnter(button)
    local data = button:GetParent().data
    if not data then return end
    local canShare, reason = ns.CanShareQuest(data.questID)
    GameTooltip:SetOwner(button, "ANCHOR_RIGHT")
    GameTooltip:SetText("Share quest")
    if canShare then
        GameTooltip:AddLine("Offer this quest to your group.", 1, 1, 1)
    else
        GameTooltip:AddLine(reason, 1, 0.3, 0.3)
    end
    GameTooltip:Show()
end

local function OnAbandonClick(button)
    local data = button:GetParent().data
    if data then ns.AbandonQuest(data.questID, data.title) end
end

local function OnAbandonEnter(button)
    GameTooltip:SetOwner(button, "ANCHOR_RIGHT")
    GameTooltip:SetText("Abandon quest")
    GameTooltip:AddLine("Asks for confirmation first.", 1, 1, 1)
    GameTooltip:Show()
end

local function CreateActionButton(row, texture, onClick, onEnter)
    local button = CreateFrame("Button", nil, row)
    button:SetSize(16, 16)
    button:SetNormalTexture(texture)
    button:SetHighlightTexture("Interface\\Buttons\\ButtonHilight-Square", "ADD")
    button:SetScript("OnClick", onClick)
    button:SetScript("OnEnter", onEnter)
    button:SetScript("OnLeave", HideTooltip)
    return button
end

local function InitRow(row, data)
    if not row.cells then
        row.cells = CreateCells(row, "GameFontHighlight")
        row:SetHighlightTexture("Interface\\QuestFrame\\UI-QuestTitleHighlight", "ADD")
        row:RegisterForClicks("LeftButtonUp")
        row:SetScript("OnClick", OnRowClick)
        row:SetScript("OnEnter", OnRowEnter)
        row:SetScript("OnLeave", HideTooltip)

        row.abandonButton = CreateActionButton(row, ABANDON_TEXTURE, OnAbandonClick, OnAbandonEnter)
        row.abandonButton:SetPoint("RIGHT", row, "RIGHT", -4, 0)
        row.shareButton = CreateActionButton(row, SHARE_TEXTURE, OnShareClick, OnShareEnter)
        row.shareButton:SetPoint("RIGHT", row.abandonButton, "LEFT", -6, 0)
    end
    row.data = data

    local cells = row.cells
    cells.title:SetText(ns.FormatQuestTitle(data))
    if type(GetQuestDifficultyColor) == "function" then
        local color = GetQuestDifficultyColor(data.difficultyLevel)
        cells.title:SetTextColor(color.r, color.g, color.b)
    end
    cells.zone:SetText(data.zone)
    cells.type:SetText(ns.GetQuestTypeLabel(data.questType, true))
    cells.level:SetText(data.level > 0 and data.level or "")
    cells.xp:SetText(FormatXP(data))

    -- Dim the share button when sharing isn't possible right now.
    local canShare = ns.CanShareQuest(data.questID)
    local shareTexture = row.shareButton:GetNormalTexture()
    shareTexture:SetDesaturated(not canShare)
    row.shareButton:SetAlpha(canShare and 1 or 0.4)
end

-- Position -----------------------------------------------------------------

local function SavePosition(frame)
    local point, _, relPoint, x, y = frame:GetPoint(1)
    ns.db.position = { point, relPoint, x, y }
end

local function ApplyPosition(frame)
    frame:ClearAllPoints()
    local p = ns.db.position
    if p then
        frame:SetPoint(p[1], UIParent, p[2], p[3], p[4])
    else
        frame:SetPoint("CENTER")
    end
end

-- Window -------------------------------------------------------------------

local function UpdateFilterButton()
    local active = ns.CountActiveFilters()
    window.filterButton:SetText(active > 0 and ("Filters (%d)"):format(active) or "Filters")
end

local function CreateWindow()
    -- Named only so it can join UISpecialFrames, which closes it on Esc.
    local frame = CreateFrame("Frame", WINDOW_NAME, UIParent, "BasicFrameTemplateWithInset")
    tinsert(UISpecialFrames, WINDOW_NAME)
    frame:SetSize(WIDTH, HEIGHT)
    frame:SetFrameStrata("MEDIUM")
    frame:SetToplevel(true)
    frame:SetClampedToScreen(true)
    frame:SetMovable(true)
    frame:EnableMouse(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", frame.StartMoving)
    frame:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
        SavePosition(self)
    end)
    ApplyPosition(frame)

    local title = frame.TitleText
    if not title then
        title = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
        title:SetPoint("TOP", 0, -5)
    end
    title:SetText("Quests by XP")


    -- Search box + filter button
    local searchBox = CreateFrame("EditBox", nil, frame, "SearchBoxTemplate")
    searchBox:SetSize(220, 20)
    searchBox:SetPoint("TOPLEFT", 20, -32)
    searchBox:HookScript("OnTextChanged", function(self)
        ns.SetSearchText(self:GetText())
        ns.RefreshAll()
    end)

    local filterButton = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
    filterButton:SetSize(120, 22)
    filterButton:SetPoint("TOPRIGHT", -30, -31)
    filterButton:SetText("Filters")
    filterButton:SetScript("OnClick", function(self)
        ns.OpenFilterMenu(self, frame.counts or {})
    end)

    -- Toggles the always-visible on-screen tracker.
    local pinCheck = CreateFrame("CheckButton", nil, frame, "UICheckButtonTemplate")
    pinCheck:SetSize(24, 24)
    pinCheck:SetPoint("RIGHT", filterButton, "LEFT", -110, 0)
    local pinLabel = pinCheck.Text or pinCheck.text
    if not pinLabel then
        pinLabel = pinCheck:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
        pinLabel:SetPoint("LEFT", pinCheck, "RIGHT", 2, 0)
    end
    pinLabel:SetText("Show on screen")
    pinCheck:SetScript("OnClick", function(self)
        ns.SetTrackerShown(self:GetChecked())
    end)
    pinCheck:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetText("Show on screen")
        GameTooltip:AddLine("Keep a compact list of your top quests by XP on screen, like the quest tracker.", 1, 1, 1, true)
        GameTooltip:Show()
    end)
    pinCheck:SetScript("OnLeave", HideTooltip)

    -- Column header
    local header = CreateFrame("Frame", nil, frame)
    header:SetPoint("TOPLEFT", 12, -60)
    header:SetSize(LIST_WIDTH, ROW_HEIGHT)
    local headerCells = CreateCells(header, "GameFontNormal")
    for _, col in ipairs(COLUMNS) do
        headerCells[col.key]:SetText(col.label)
    end

    -- Quest list
    local scrollBox = CreateFrame("Frame", nil, frame, "WowScrollBoxList")
    scrollBox:SetPoint("TOPLEFT", header, "BOTTOMLEFT", 0, -2)
    scrollBox:SetPoint("BOTTOMRIGHT", -30, 30)

    local scrollBar = CreateFrame("EventFrame", nil, frame, "MinimalScrollBar")
    scrollBar:SetPoint("TOPLEFT", scrollBox, "TOPRIGHT", 8, 0)
    scrollBar:SetPoint("BOTTOMLEFT", scrollBox, "BOTTOMRIGHT", 8, 0)

    local view = CreateScrollBoxListLinearView()
    view:SetElementExtent(ROW_HEIGHT)
    view:SetElementInitializer("Button", InitRow)
    ScrollUtil.InitScrollBoxListWithScrollBar(scrollBox, scrollBar, view)

    local emptyText = frame:CreateFontString(nil, "OVERLAY", "GameFontDisable")
    emptyText:SetPoint("CENTER", scrollBox, "CENTER")
    emptyText:Hide()

    local footer = frame:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    footer:SetPoint("BOTTOMLEFT", 14, 11)

    frame.scrollBox = scrollBox
    frame.emptyText = emptyText
    frame.footer = footer
    frame.filterButton = filterButton
    frame.pinCheck = pinCheck
    frame:SetScript("OnShow", function() ns.RefreshWindow() end)
    -- Closed by the X, Esc or /ordq. Hiding the whole UI (Alt+Z) also fires
    -- OnHide, but then the window itself is still marked shown.
    frame:SetScript("OnHide", function(self)
        if not self:IsShown() then ns.db.shown = false end
    end)

    -- Start hidden so the first Show() fires OnShow and fills the list.
    frame:Hide()
    return frame
end

local function GetWindow()
    if not window then window = CreateWindow() end
    return window
end

function ns.IsWindowShown()
    return window ~= nil and window:IsShown()
end

-- quests: optional, an already collected list (see ns.RefreshAll)
function ns.RefreshWindow(quests)
    if not ns.IsWindowShown() then return end

    local all = quests or ns.CollectQuests()
    local shown, counts = {}, {}
    for _, quest in ipairs(all) do
        counts[quest.questType] = (counts[quest.questType] or 0) + 1
        if quest.complete then counts.ready = (counts.ready or 0) + 1 end
        if ns.PassesFilters(quest) then shown[#shown + 1] = quest end
    end
    window.counts = counts

    local retain = ScrollBoxConstants and ScrollBoxConstants.RetainScrollPosition
    window.scrollBox:SetDataProvider(CreateDataProvider(shown), retain)

    if #all == 0 then
        window.emptyText:SetText("No quests in your quest log.")
    else
        window.emptyText:SetText("No quests match the search or filters.")
    end
    window.emptyText:SetShown(#shown == 0)
    window.footer:SetText(("Showing %d of %d quests"):format(#shown, #all))
    UpdateFilterButton()
    window.pinCheck:SetChecked(ns.IsTrackerShown())
end

function ns.ToggleWindow()
    local frame = GetWindow()
    ns.db.shown = not frame:IsShown()
    frame:SetShown(ns.db.shown)
end

function ns.ResetWindowPosition()
    ns.db.position = nil
    if window then ApplyPosition(window) end
end

-- Called on login: reopen the window if it was open last session.
function ns.RestoreWindow()
    if ns.db.shown then GetWindow():Show() end
end
