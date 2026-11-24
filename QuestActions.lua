local addonName, ns = ...

-- Share and abandon, using the same calls as the default quest log.

local function GetLogIndex(questID)
    if not C_QuestLog.GetLogIndexForQuestID then return nil end
    local ok, index = pcall(C_QuestLog.GetLogIndexForQuestID, questID)
    if ok and type(index) == "number" and index > 0 then return index end
    return nil
end

-- Returns canShare, reason
function ns.CanShareQuest(questID)
    if not IsInGroup() then
        return false, "You need to be in a group to share quests."
    end
    if not C_QuestLog.IsPushableQuest then
        return false, "Sharing isn't available on this client."
    end
    local ok, pushable = pcall(C_QuestLog.IsPushableQuest, questID)
    if not ok or pushable ~= true then
        return false, "This quest can't be shared."
    end
    return true
end

function ns.ShareQuest(questID)
    local canShare, reason = ns.CanShareQuest(questID)
    if not canShare then
        ns.Print(reason)
        return
    end
    if type(QuestLogPushQuest) ~= "function" then return end
    pcall(C_QuestLog.SetSelectedQuest, questID)
    pcall(QuestLogPushQuest, GetLogIndex(questID))
end

-- Opens the game's own "Abandon <quest>?" confirmation.
function ns.AbandonQuest(questID, title)
    if not GetLogIndex(questID) then return end
    if not (C_QuestLog.SetSelectedQuest and C_QuestLog.SetAbandonQuest and StaticPopup_Show) then
        ns.Print("abandoning isn't available on this client.")
        return
    end
    pcall(C_QuestLog.SetSelectedQuest, questID)
    pcall(C_QuestLog.SetAbandonQuest)

    local name = title
    if type(GetAbandonQuestName) == "function" then
        local ok, own = pcall(GetAbandonQuestName)
        if ok and type(own) == "string" and own ~= "" then name = own end
    end
    StaticPopup_Show("ABANDON_QUEST", name or "")
end
