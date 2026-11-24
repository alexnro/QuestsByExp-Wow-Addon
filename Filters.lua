local addonName, ns = ...

-- Name search and quest-type filter. Hidden types are saved in
-- OrderQuestsByExpDB.hiddenTypes; the search text lasts for the session only.

ns.QUEST_TYPES = {
    { key = "normal",  label = "Normal" },
    { key = "group",   label = "Group / elite" },
    { key = "dungeon", label = "Dungeon" },
    { key = "raid",    label = "Raid" },
    { key = "pvp",     label = "PvP" },
    { key = "class",   label = "Class" },
}

local searchText = ""

function ns.SetSearchText(text)
    searchText = strtrim(text or ""):lower()
end

local function HiddenTypes()
    ns.db.hiddenTypes = ns.db.hiddenTypes or {}
    return ns.db.hiddenTypes
end

function ns.CountHiddenTypes()
    local count = 0
    for _ in pairs(HiddenTypes()) do count = count + 1 end
    return count
end

function ns.PassesFilters(quest)
    if HiddenTypes()[quest.questType] then return false end
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
    ns.RefreshWindow()
    return MenuResponse and MenuResponse.Refresh
end

-- counts: questType -> number of quests of that type in the log
function ns.OpenFilterMenu(owner, counts)
    if not (MenuUtil and MenuUtil.CreateContextMenu) then
        ns.Print("the filter menu isn't available on this client.")
        return
    end
    MenuUtil.CreateContextMenu(owner, function(_, root)
        root:CreateTitle("Show quest types")
        for _, questType in ipairs(ns.QUEST_TYPES) do
            local label = ("%s (%d)"):format(questType.label, counts[questType.key] or 0)
            root:CreateCheckbox(label, IsTypeShown, ToggleType, questType.key)
        end
        root:CreateDivider()
        root:CreateButton("Show all types", function()
            wipe(HiddenTypes())
            ns.RefreshWindow()
        end)
    end)
end
