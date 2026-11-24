local addonName, ns = ...

-- Keeps the window and the on-screen tracker in sync with the quest log. Bursts of events are
-- collapsed into one refresh, and nothing runs while the window is hidden.

local REFRESH_DELAY = 0.2

local EVENTS = {
    "QUEST_LOG_UPDATE",
    "QUEST_ACCEPTED",
    "QUEST_REMOVED",
    "QUEST_TURNED_IN",
    "PLAYER_LEVEL_UP",
    "GROUP_ROSTER_UPDATE", -- share buttons depend on being in a group
    "QUEST_DATA_LOAD_RESULT",
}

local refreshQueued = false

local function AnythingShown()
    return ns.IsWindowShown() or ns.IsTrackerShown()
end

-- Reads the quest log once and updates both the window and the tracker.
function ns.RefreshAll()
    if not AnythingShown() then return end
    local quests = ns.CollectQuests()
    ns.RefreshWindow(quests)
    ns.RefreshTracker(quests)
end

local function RunRefresh()
    refreshQueued = false
    ns.RefreshAll()
end

local function QueueRefresh()
    if refreshQueued or not AnythingShown() then return end
    refreshQueued = true
    C_Timer.After(REFRESH_DELAY, RunRefresh)
end

local frame = CreateFrame("Frame")
for _, event in ipairs(EVENTS) do
    pcall(frame.RegisterEvent, frame, event)
end

frame:SetScript("OnEvent", function(_, event, arg1)
    if event == "QUEST_DATA_LOAD_RESULT" then
        -- Fires for every quest any addon loads; only refresh for ours.
        if not ns.OnQuestDataLoaded(arg1) then return end
    end
    QueueRefresh()
end)
