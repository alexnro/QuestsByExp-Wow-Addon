local addonName, ns = ...

ns.name = addonName
ns.tag = "|cff33ff99Order Quests By Exp|r:"

function ns.Print(...)
    print(ns.tag, ...)
end

local eventFrame = CreateFrame("Frame")
ns.eventFrame = eventFrame

eventFrame:RegisterEvent("ADDON_LOADED")
eventFrame:RegisterEvent("PLAYER_LOGIN")

eventFrame:SetScript("OnEvent", function(_, event, arg1)
    if event == "ADDON_LOADED" then
        if arg1 ~= addonName then return end
        OrderQuestsByExpDB = OrderQuestsByExpDB or {}
        ns.db = OrderQuestsByExpDB
        eventFrame:UnregisterEvent("ADDON_LOADED")
    elseif event == "PLAYER_LOGIN" then
        ns.Print("loaded. Type /ordq to show your quests by XP.")
        ns.InitMinimapButton()
        ns.RestoreWindow()
        ns.InitTracker()
    end
end)

local function PrintHelp()
    ns.Print("commands:")
    ns.Print("  /ordq - show or hide the quest window")
    ns.Print("  /ordq tracker - show or hide the on-screen list")
    ns.Print("  /ordq tracker <number> - how many quests the on-screen list shows")
    ns.Print("  /ordq reset - move the window and on-screen list back to their default spots")
    ns.Print("  /ordq minimap - show or hide the minimap button")
    ns.Print("  /ordq help - show this help")
end

SLASH_ORDERQUESTSBYEXP1 = "/ordq"
SlashCmdList.ORDERQUESTSBYEXP = function(msg)
    msg = strtrim(msg or ""):lower()
    local command, arg = msg:match("^(%S*)%s*(.-)$")
    if command == "" then
        ns.ToggleWindow()
    elseif command == "tracker" then
        if arg ~= "" then ns.SetTrackerMax(arg) else ns.ToggleTracker() end
    elseif command == "reset" then
        ns.ResetWindowPosition()
        ns.ResetTrackerPosition()
        ns.Print("window and on-screen list positions reset.")
    elseif command == "minimap" then
        ns.ToggleMinimapButton()
    else
        PrintHelp()
    end
end
