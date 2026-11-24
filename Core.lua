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
        ns.RestoreWindow()
    end
end)

local function PrintHelp()
    ns.Print("commands:")
    ns.Print("  /ordq - show or hide the quest window")
    ns.Print("  /ordq reset - move the window back to the center")
    ns.Print("  /ordq help - show this help")
end

SLASH_ORDERQUESTSBYEXP1 = "/ordq"
SlashCmdList.ORDERQUESTSBYEXP = function(msg)
    msg = strtrim(msg or ""):lower()
    if msg == "" then
        ns.ToggleWindow()
    elseif msg == "reset" then
        ns.ResetWindowPosition()
        ns.Print("window position reset.")
    else
        PrintHelp()
    end
end
