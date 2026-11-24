local addonName, ns = ...

-- Reads the quest log and returns the quests sorted by XP reward.

local pcall, type, tostring, sort = pcall, type, tostring, table.sort

-- questID -> "pending" (load requested) | "loaded" (client has the quest data)
local loadState = {}

function ns.IsSecret(value)
    return type(issecretvalue) == "function" and issecretvalue(value) or false
end

-- Returns xp, isPending. xp is nil when the value is unknown.
local function ReadXP(questID)
    if type(GetQuestLogRewardXP) ~= "function" then return nil, false end
    local ok, xp = pcall(GetQuestLogRewardXP, questID)
    if not ok or ns.IsSecret(xp) or type(xp) ~= "number" then return nil, false end
    if xp > 0 then return xp, false end

    -- A 0 can mean "the client has not cached this quest yet".
    if loadState[questID] == "loaded" then return 0, false end
    if type(C_QuestLog.RequestLoadQuestByID) ~= "function" then return 0, false end
    if not loadState[questID] then
        loadState[questID] = "pending"
        pcall(C_QuestLog.RequestLoadQuestByID, questID)
    end
    return nil, true
end

-- Called from QUEST_DATA_LOAD_RESULT. Returns true if we were waiting on it.
function ns.OnQuestDataLoaded(questID)
    if loadState[questID] == "pending" then
        loadState[questID] = "loaded"
        return true
    end
    return false
end

-- Quest type detection -----------------------------------------------------

-- Enum.QuestTag values, with the numeric fallbacks used by the client.
local QuestTag = (Enum and Enum.QuestTag) or {}
local TAG_TO_TYPE = {
    [QuestTag.Group or 1] = "group",
    [QuestTag.PvP or 41] = "pvp",
    [QuestTag.Raid or 62] = "raid",
    [QuestTag.Dungeon or 81] = "dungeon",
    [QuestTag.Heroic or 85] = "dungeon",
    [QuestTag.Raid10 or 88] = "raid",
    [QuestTag.Raid25 or 89] = "raid",
}

-- Class quests sit under a quest-log header named after the class.
local classHeaders
local function IsClassHeader(zone)
    if not classHeaders then
        classHeaders = {}
        for _, names in ipairs({ LOCALIZED_CLASS_NAMES_MALE, LOCALIZED_CLASS_NAMES_FEMALE }) do
            if type(names) == "table" then
                for _, name in pairs(names) do classHeaders[name] = true end
            end
        end
    end
    return classHeaders[zone] == true
end

local function GetQuestType(info, zone)
    if IsClassHeader(zone) then return "class" end
    if C_QuestLog.GetQuestTagInfo then
        local ok, tag = pcall(C_QuestLog.GetQuestTagInfo, info.questID)
        if ok and type(tag) == "table" and not ns.IsSecret(tag.tagID) then
            local questType = TAG_TO_TYPE[tag.tagID]
            if questType then return questType end
        end
    end
    local suggested = info.suggestedGroup
    if not ns.IsSecret(suggested) and type(suggested) == "number" and suggested > 1 then
        return "group"
    end
    return "normal"
end

-- Highest XP first; unknown XP last; ties go to the lower level, then by name.
local function Compare(a, b)
    local ax, bx = a.xp or -1, b.xp or -1
    if ax ~= bx then return ax > bx end
    if a.level ~= b.level then return a.level < b.level end
    return a.title < b.title
end

local function SafeNumber(value)
    if ns.IsSecret(value) or type(value) ~= "number" then return 0 end
    return value
end

local function SafeString(value, fallback)
    if ns.IsSecret(value) or value == nil then return fallback end
    return tostring(value)
end

function ns.CollectQuests()
    local quests = {}
    if not (C_QuestLog and C_QuestLog.GetNumQuestLogEntries and C_QuestLog.GetInfo) then
        return quests
    end

    local ok, numEntries = pcall(C_QuestLog.GetNumQuestLogEntries)
    if not ok or ns.IsSecret(numEntries) or type(numEntries) ~= "number" then
        return quests
    end

    local zone = ""
    for i = 1, numEntries do
        local okInfo, info = pcall(C_QuestLog.GetInfo, i)
        if okInfo and type(info) == "table" then
            if info.isHeader then
                zone = SafeString(info.title, "")
            elseif not info.isHidden and not info.isTask and not info.isBounty and info.questID then
                local xp, pending = ReadXP(info.questID)
                local level = SafeNumber(info.level)
                quests[#quests + 1] = {
                    questID = info.questID,
                    title = SafeString(info.title, "?"),
                    zone = zone,
                    level = level,
                    difficultyLevel = SafeNumber(info.difficultyLevel) > 0 and info.difficultyLevel or level,
                    xp = xp,
                    pending = pending,
                    questType = GetQuestType(info, zone),
                }
            end
        end
    end

    sort(quests, Compare)
    return quests
end
