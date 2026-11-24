local addonName, ns = ...

-- The quest list window: header row + scrolling list of quests.

local WIDTH, HEIGHT = 480, 340
local ROW_HEIGHT = 18
local COLUMN_GAP = 4
local COLUMNS = {
    { key = "title", label = "Quest", width = 210, justify = "LEFT" },
    { key = "zone",  label = "Zone",  width = 120, justify = "LEFT" },
    { key = "level", label = "Lvl",   width = 35,  justify = "CENTER" },
    { key = "xp",    label = "XP",    width = 60,  justify = "RIGHT" },
}

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

local function OnRowClick(row)
    local questID = row.data and row.data.questID
    if not questID then return end
    if InCombatLockdown() then
        ns.Print("can't open the quest log during combat.")
        return
    end
    if type(QuestMapFrame_OpenToQuestDetails) == "function" then
        QuestMapFrame_OpenToQuestDetails(questID)
    elseif type(ToggleQuestLog) == "function" then
        ToggleQuestLog()
    end
end

local function OnRowEnter(row)
    local data = row.data
    if not data then return end
    GameTooltip:SetOwner(row, "ANCHOR_RIGHT")
    GameTooltip:SetText(data.title, 1, 0.82, 0)
    if data.zone ~= "" then GameTooltip:AddLine(data.zone, 1, 1, 1) end
    GameTooltip:AddLine("Level " .. data.level, 1, 1, 1)
    GameTooltip:AddLine("XP: " .. FormatXP(data), 1, 1, 1)
    GameTooltip:AddLine("Click to open in the quest log", 0.5, 0.5, 0.5)
    GameTooltip:Show()
end

local function OnRowLeave()
    GameTooltip:Hide()
end

local function InitRow(row, data)
    if not row.cells then
        row.cells = CreateCells(row, "GameFontHighlightSmall")
        row:SetHighlightTexture("Interface\\QuestFrame\\UI-QuestTitleHighlight", "ADD")
        row:RegisterForClicks("LeftButtonUp")
        row:SetScript("OnClick", OnRowClick)
        row:SetScript("OnEnter", OnRowEnter)
        row:SetScript("OnLeave", OnRowLeave)
    end
    row.data = data

    local cells = row.cells
    cells.title:SetText(data.title)
    if type(GetQuestDifficultyColor) == "function" then
        local color = GetQuestDifficultyColor(data.difficultyLevel)
        cells.title:SetTextColor(color.r, color.g, color.b)
    end
    cells.zone:SetText(data.zone)
    cells.level:SetText(data.level > 0 and data.level or "")
    cells.xp:SetText(FormatXP(data))
end

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

local function CreateWindow()
    local frame = CreateFrame("Frame", nil, UIParent, "BasicFrameTemplateWithInset")
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

    if frame.CloseButton then
        frame.CloseButton:HookScript("OnClick", function() ns.db.shown = false end)
    end

    local header = CreateFrame("Frame", nil, frame)
    header:SetPoint("TOPLEFT", 12, -30)
    header:SetPoint("TOPRIGHT", -30, -30)
    header:SetHeight(ROW_HEIGHT)
    local headerCells = CreateCells(header, "GameFontNormalSmall")
    for _, col in ipairs(COLUMNS) do
        headerCells[col.key]:SetText(col.label)
    end

    local scrollBox = CreateFrame("Frame", nil, frame, "WowScrollBoxList")
    scrollBox:SetPoint("TOPLEFT", header, "BOTTOMLEFT", 0, -2)
    scrollBox:SetPoint("BOTTOMRIGHT", -30, 10)

    local scrollBar = CreateFrame("EventFrame", nil, frame, "MinimalScrollBar")
    scrollBar:SetPoint("TOPLEFT", scrollBox, "TOPRIGHT", 8, 0)
    scrollBar:SetPoint("BOTTOMLEFT", scrollBox, "BOTTOMRIGHT", 8, 0)

    local view = CreateScrollBoxListLinearView()
    view:SetElementExtent(ROW_HEIGHT)
    view:SetElementInitializer("Button", InitRow)
    ScrollUtil.InitScrollBoxListWithScrollBar(scrollBox, scrollBar, view)

    local emptyText = frame:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    emptyText:SetPoint("CENTER", scrollBox, "CENTER")
    emptyText:SetText("No quests in your quest log.")
    emptyText:Hide()

    frame.scrollBox = scrollBox
    frame.emptyText = emptyText
    frame:SetScript("OnShow", function() ns.RefreshWindow() end)

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

function ns.RefreshWindow()
    if not ns.IsWindowShown() then return end
    local quests = ns.CollectQuests()
    local retain = ScrollBoxConstants and ScrollBoxConstants.RetainScrollPosition
    window.scrollBox:SetDataProvider(CreateDataProvider(quests), retain)
    window.emptyText:SetShown(#quests == 0)
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
