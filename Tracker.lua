local addonName, ns = ...

-- Always-on-screen list of your top quests by XP with their objectives,
-- styled like the default quest tracker. Uses the same filters as the window. Click the header to collapse, drag it to move. Shown state,
-- position, collapsed state and entry count live in the DB.

local WIDTH = 260
local HEADER_HEIGHT = 22
local ENTRY_MIN_HEIGHT = 32
local EMPTY_HEIGHT = 18
local DEFAULT_MAX = 10
local MAX_LIMIT = 25

local tracker
local entries = {}
local isDragging = false

-- Position -----------------------------------------------------------------

-- Saved as the top-left corner so the list grows downwards.
local function SavePosition()
    ns.db.trackerPosition = { tracker:GetLeft(), tracker:GetTop() }
end

local function ApplyPosition()
    tracker:ClearAllPoints()
    local p = ns.db.trackerPosition
    if p then
        tracker:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", p[1], p[2])
    else
        tracker:SetPoint("TOPLEFT", UIParent, "TOPLEFT", 20, -220)
    end
end

-- Entries ------------------------------------------------------------------

local function OnEntryClick(entry)
    if entry.data then ns.OpenQuestDetails(entry.data.questID) end
end

local function OnEntryEnter(entry)
    if entry.data then ns.ShowQuestTooltip(entry, entry.data) end
end

-- Returns a list of { text, finished } lines to show under the quest.
local function GetObjectiveLines(questID)
    local lines = {}
    if C_QuestLog.IsComplete then
        local ok, complete = pcall(C_QuestLog.IsComplete, questID)
        if ok and complete == true then
            lines[1] = { text = "Ready to turn in", ready = true }
            return lines
        end
    end
    if not C_QuestLog.GetQuestObjectives then return lines end
    local ok, objectives = pcall(C_QuestLog.GetQuestObjectives, questID)
    if not ok or type(objectives) ~= "table" then return lines end
    for _, objective in ipairs(objectives) do
        local text = objective.text
        if type(text) == "string" and not ns.IsSecret(text) and text ~= "" then
            lines[#lines + 1] = { text = text, finished = objective.finished == true }
        end
    end
    return lines
end

-- Entries are chained top to bottom because their heights vary.
local function CreateEntry(index)
    local entry = CreateFrame("Button", nil, tracker)
    entry:SetSize(WIDTH, ENTRY_MIN_HEIGHT)
    if index == 1 then
        entry:SetPoint("TOPLEFT", tracker, "TOPLEFT", 0, -HEADER_HEIGHT)
    else
        entry:SetPoint("TOPLEFT", entries[index - 1], "BOTTOMLEFT", 0, 0)
    end
    entry.lines = {}
    entry:SetHighlightTexture("Interface\\QuestFrame\\UI-QuestTitleHighlight", "ADD")
    entry:GetHighlightTexture():SetAlpha(0.5)
    entry:RegisterForClicks("LeftButtonUp")
    entry:SetScript("OnClick", OnEntryClick)
    entry:SetScript("OnEnter", OnEntryEnter)
    entry:SetScript("OnLeave", function() GameTooltip:Hide() end)

    entry.xp = entry:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    entry.xp:SetPoint("TOPRIGHT", -4, -3)
    entry.xp:SetWidth(80)
    entry.xp:SetJustifyH("RIGHT")

    entry.title = entry:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
    entry.title:SetPoint("TOPLEFT", 8, -3)
    entry.title:SetPoint("RIGHT", entry.xp, "LEFT", -6, 0)
    entry.title:SetJustifyH("LEFT")
    entry.title:SetWordWrap(false)

    entry.detail = entry:CreateFontString(nil, "ARTWORK", "GameFontDisableSmall")
    entry.detail:SetPoint("TOPLEFT", entry.title, "BOTTOMLEFT", 6, -2)
    entry.detail:SetPoint("RIGHT", entry, "RIGHT", -4, 0)
    entry.detail:SetJustifyH("LEFT")
    entry.detail:SetWordWrap(false)

    return entry
end

local function FillEntry(entry, data)
    entry.data = data
    entry.title:SetText(data.title)
    if type(GetQuestDifficultyColor) == "function" then
        local color = GetQuestDifficultyColor(data.difficultyLevel)
        entry.title:SetTextColor(color.r, color.g, color.b)
    end
    entry.xp:SetText(ns.FormatXP(data) .. " XP")

    local parts = {}
    if data.level > 0 then parts[#parts + 1] = "Lvl " .. data.level end
    if data.zone ~= "" then parts[#parts + 1] = data.zone end
    if data.questType ~= "normal" then parts[#parts + 1] = ns.GetQuestTypeLabel(data.questType, true) end
    entry.detail:SetText(table.concat(parts, "  -  "))

    -- Objectives, one line each, wrapping if long.
    local y = 3 + entry.title:GetStringHeight() + 2 + entry.detail:GetStringHeight() + 4
    local objectives = GetObjectiveLines(data.questID)
    for i, objective in ipairs(objectives) do
        local line = entry.lines[i]
        if not line then
            line = entry:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
            line:SetJustifyH("LEFT")
            line:SetWordWrap(true)
            line:SetWidth(WIDTH - 26)
            entry.lines[i] = line
        end
        line:ClearAllPoints()
        line:SetPoint("TOPLEFT", entry, "TOPLEFT", 16, -y)
        line:SetText("- " .. objective.text)
        if objective.ready then
            line:SetTextColor(0.3, 1, 0.3)
        elseif objective.finished then
            line:SetTextColor(0.5, 0.5, 0.5)
        else
            line:SetTextColor(0.85, 0.85, 0.85)
        end
        line:Show()
        y = y + line:GetStringHeight() + 2
    end
    for i = #objectives + 1, #entry.lines do entry.lines[i]:Hide() end

    local height = math.max(ENTRY_MIN_HEIGHT, y + 4)
    entry:SetHeight(height)
    return height
end

-- Frame --------------------------------------------------------------------

local function CreateTracker()
    tracker = CreateFrame("Frame", nil, UIParent)
    tracker:SetSize(WIDTH, HEADER_HEIGHT)
    tracker:SetFrameStrata("LOW")
    tracker:SetClampedToScreen(true)
    tracker:SetMovable(true)
    ApplyPosition()

    local header = CreateFrame("Button", nil, tracker)
    header:SetSize(WIDTH, HEADER_HEIGHT)
    header:SetPoint("TOPLEFT")
    header:RegisterForClicks("LeftButtonUp")
    header:RegisterForDrag("LeftButton")

    header.text = header:CreateFontString(nil, "ARTWORK")
    header.text:SetFontObject(GameFontNormalMed2 or GameFontNormal)
    header.text:SetPoint("LEFT", 4, 0)
    header.text:SetText("Quests by XP")

    header.toggle = header:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    header.toggle:SetPoint("RIGHT", -6, 0)

    local line = header:CreateTexture(nil, "ARTWORK")
    line:SetColorTexture(1, 0.82, 0, 0.35)
    line:SetHeight(1)
    line:SetPoint("BOTTOMLEFT", 2, 0)
    line:SetPoint("BOTTOMRIGHT", -2, 0)

    header:SetScript("OnClick", function()
        if isDragging then return end
        ns.db.trackerCollapsed = not ns.db.trackerCollapsed
        ns.RefreshTracker()
    end)
    header:SetScript("OnDragStart", function()
        isDragging = true
        tracker:StartMoving()
    end)
    header:SetScript("OnDragStop", function()
        tracker:StopMovingOrSizing()
        SavePosition()
        ApplyPosition()
        -- OnClick fires right after OnDragStop; ignore that one.
        C_Timer.After(0, function() isDragging = false end)
    end)
    header:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetText("Quests by XP")
        GameTooltip:AddLine("Click to collapse or expand. Drag to move.", 1, 1, 1)
        GameTooltip:AddLine("/ordq tracker hides it, /ordq tracker <number> sets how many quests to show.", 0.5, 0.5, 0.5, true)
        GameTooltip:Show()
    end)
    header:SetScript("OnLeave", function() GameTooltip:Hide() end)

    local emptyText = tracker:CreateFontString(nil, "ARTWORK", "GameFontDisableSmall")
    emptyText:SetPoint("TOPLEFT", 8, -(HEADER_HEIGHT + 3))
    emptyText:SetText("No quests to show.")

    tracker.header = header
    tracker.emptyText = emptyText
    tracker:Hide()
end

-- Public -------------------------------------------------------------------

function ns.IsTrackerShown()
    return tracker ~= nil and tracker:IsShown()
end

-- quests: optional, an already collected list (see ns.RefreshAll)
function ns.RefreshTracker(quests)
    if not ns.IsTrackerShown() then return end

    local collapsed = ns.db.trackerCollapsed
    local max = ns.db.trackerMax or DEFAULT_MAX
    local count, height = 0, HEADER_HEIGHT

    if not collapsed then
        quests = quests or ns.CollectQuests()
        for _, quest in ipairs(quests) do
            if count >= max then break end
            if ns.PassesFilters(quest) then
                count = count + 1
                local entry = entries[count]
                if not entry then
                    entry = CreateEntry(count)
                    entries[count] = entry
                end
                height = height + FillEntry(entry, quest)
                entry:Show()
            end
        end
    end
    for i = count + 1, #entries do entries[i]:Hide() end

    local isEmpty = not collapsed and count == 0
    tracker.emptyText:SetShown(isEmpty)
    tracker.header.toggle:SetText(collapsed and "+" or "-")
    tracker:SetHeight(height + (isEmpty and EMPTY_HEIGHT or 0))
end

function ns.SetTrackerShown(shown)
    ns.db.trackerShown = shown and true or false
    if shown then
        if not tracker then CreateTracker() end
        tracker:Show()
        ns.RefreshTracker()
    elseif tracker then
        tracker:Hide()
    end
    -- Keep the window's "Show on screen" checkbox in sync.
    ns.RefreshWindow()
end

function ns.ToggleTracker()
    ns.SetTrackerShown(not ns.IsTrackerShown())
end

function ns.SetTrackerMax(value)
    local n = tonumber(value)
    if not n or n < 1 then
        ns.Print(("usage: /ordq tracker <1-%d>"):format(MAX_LIMIT))
        return
    end
    n = math.min(math.floor(n), MAX_LIMIT)
    ns.db.trackerMax = n
    ns.Print(("the on-screen list now shows up to %d quests."):format(n))
    ns.RefreshTracker()
end

function ns.ResetTrackerPosition()
    ns.db.trackerPosition = nil
    if tracker then ApplyPosition() end
end

-- Called on login: show the tracker again if it was on last session.
function ns.InitTracker()
    if ns.db.trackerShown then ns.SetTrackerShown(true) end
end
