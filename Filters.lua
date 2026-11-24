local addonName, ns = ...

-- Name search, "only ready to turn in" and quest-type filters, shared by the
-- window and the on-screen tracker. Hidden types (OrderQuestsByExpDB.hiddenTypes)
-- and onlyReady are saved; the search text lasts for the session only.

-- label: shown in the filter menu; short: shown in the window's Type column
ns.QUEST_TYPES = {
    { key = "normal",  label = "Normal",        short = "Normal" },
    { key = "group",   label = "Group / elite", short = "Group" },
    { key = "dungeon", label = "Dungeon",       short = "Dungeon" },
    { key = "raid",    label = "Raid",          short = "Raid" },
    { key = "pvp",     label = "PvP",           short = "PvP" },
    { key = "class",   label = "Class",         short = "Class" },
}

local typeByKey = {}
for _, questType in ipairs(ns.QUEST_TYPES) do typeByKey[questType.key] = questType end

function ns.GetQuestTypeLabel(key, short)
    local questType = typeByKey[key]
    if not questType then return "" end
    return short and questType.short or questType.label
end

local searchText = ""

function ns.SetSearchText(text)
    searchText = strtrim(text or ""):lower()
end

local function HiddenTypes()
    ns.db.hiddenTypes = ns.db.hiddenTypes or {}
    return ns.db.hiddenTypes
end

-- Number of saved filters in use (hidden types + "only ready to turn in").
function ns.CountActiveFilters()
    local count = 0
    for _ in pairs(HiddenTypes()) do count = count + 1 end
    if ns.db.onlyReady then count = count + 1 end
    return count
end

-- Used by both the window and the on-screen tracker.
function ns.PassesFilters(quest)
    if HiddenTypes()[quest.questType] then return false end
    if ns.db.onlyReady and not quest.complete then return false end
    if searchText ~= "" and not quest.title:lower():find(searchText, 1, true) then
        return false
    end
    return true
end

local function IsTypeShown(key)
    return not HiddenTypes()[key]
end

local function ToggleType(key)
    local hidden = HiddenTypes()
    if hidden[key] then hidden[key] = nil else hidden[key] = true end
    ns.RefreshAll()
    return MenuResponse and MenuResponse.Refresh
end

local function IsOnlyReady()
    return ns.db.onlyReady == true
end

local function ToggleOnlyReady()
    ns.db.onlyReady = not ns.db.onlyReady or nil
    ns.RefreshAll()
    return MenuResponse and MenuResponse.Refresh
end

-- counts: questType -> number of quests of that type in the log,
-- plus counts.ready = number of quests ready to turn in
function ns.OpenFilterMenu(owner, counts)
    if not (MenuUtil and MenuUtil.CreateContextMenu) then
        ns.Print("the filter menu isn't available on this client.")
        return
    end
    MenuUtil.CreateContextMenu(owner, function(_, root)
        root:CreateTitle("Status")
        local readyLabel = ("Only ready to turn in (%d)"):format(counts.ready or 0)
        root:CreateCheckbox(readyLabel, IsOnlyReady, ToggleOnlyReady)
        root:CreateDivider()
        root:CreateTitle("Show quest types")
        for _, questType in ipairs(ns.QUEST_TYPES) do
            local label = ("%s (%d)"):format(questType.label, counts[questType.key] or 0)
            root:CreateCheckbox(label, IsTypeShown, ToggleType, questType.key)
        end
        root:CreateDivider()
        root:CreateButton("Clear all filters", function()
            wipe(HiddenTypes())
            ns.db.onlyReady = nil
            ns.RefreshAll()
        end)
    end)
end
