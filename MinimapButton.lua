local addonName, ns = ...

-- Round button on the minimap edge: left-click toggles the window, drag to
-- move it around the minimap. Angle and hidden state live in the DB.

local DEFAULT_ANGLE = 200
local ICON = "Interface\\Icons\\INV_Misc_Note_01"

local button
local isDragging = false

local function UpdatePosition()
    local angle = math.rad(ns.db.minimapAngle or DEFAULT_ANGLE)
    local radius = math.max(Minimap:GetWidth(), Minimap:GetHeight()) / 2 + 5
    button:ClearAllPoints()
    button:SetPoint("CENTER", Minimap, "CENTER", math.cos(angle) * radius, math.sin(angle) * radius)
end

local function OnDragUpdate()
    local mx, my = Minimap:GetCenter()
    local scale = Minimap:GetEffectiveScale()
    local cx, cy = GetCursorPosition()
    cx, cy = cx / scale, cy / scale
    ns.db.minimapAngle = math.deg(math.atan2(cy - my, cx - mx))
    UpdatePosition()
end

local function CreateButton()
    button = CreateFrame("Button", nil, Minimap)
    button:SetSize(31, 31)
    button:SetFrameStrata("MEDIUM")
    button:SetFrameLevel(8)
    button:RegisterForClicks("LeftButtonUp")
    button:RegisterForDrag("LeftButton")
    button:SetHighlightTexture("Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight")

    local background = button:CreateTexture(nil, "BACKGROUND")
    background:SetSize(24, 24)
    background:SetTexture("Interface\\Minimap\\UI-Minimap-Background")
    background:SetPoint("CENTER")

    local icon = button:CreateTexture(nil, "ARTWORK")
    icon:SetSize(18, 18)
    icon:SetTexture(ICON)
    icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)
    icon:SetPoint("CENTER")

    local border = button:CreateTexture(nil, "OVERLAY")
    border:SetSize(50, 50)
    border:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")
    border:SetPoint("TOPLEFT")

    button:SetScript("OnClick", function()
        if not isDragging then ns.ToggleWindow() end
    end)
    button:SetScript("OnDragStart", function(self)
        isDragging = true
        self:SetScript("OnUpdate", OnDragUpdate)
    end)
    button:SetScript("OnDragStop", function(self)
        self:SetScript("OnUpdate", nil)
        -- OnClick fires right after OnDragStop; ignore that one.
        C_Timer.After(0, function() isDragging = false end)
    end)
    button:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_LEFT")
        GameTooltip:SetText("Order Quests By Exp")
        GameTooltip:AddLine("Click to show or hide your quests by XP.", 1, 1, 1)
        GameTooltip:AddLine("Drag to move. /ordq minimap hides this button.", 0.5, 0.5, 0.5)
        GameTooltip:Show()
    end)
    button:SetScript("OnLeave", function() GameTooltip:Hide() end)

    UpdatePosition()
end

-- Called on login.
function ns.InitMinimapButton()
    if not Minimap or ns.db.minimapHidden then return end
    if not button then CreateButton() end
    button:Show()
end

function ns.ToggleMinimapButton()
    ns.db.minimapHidden = not ns.db.minimapHidden
    if ns.db.minimapHidden then
        if button then button:Hide() end
        ns.Print("minimap button hidden. /ordq minimap shows it again.")
    else
        ns.InitMinimapButton()
        ns.Print("minimap button shown.")
    end
end
