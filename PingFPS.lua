local ADDON_NAME, ADDON_VERSION, ADDON_AUTHOR = "PingFPS", "1.1.0", "YourName"

PingFPSDB = PingFPSDB or {}

local DEFAULTS = {
    point = "CENTER",
    x = 0,
    y = 0,
    locked = false,
    useColor = true,
}

local function ApplyDefaults()
    for k, v in pairs(DEFAULTS) do
        if PingFPSDB[k] == nil then
            PingFPSDB[k] = v
        end
    end
end

local UIParent = UIParent
local CreateFrame = CreateFrame
local GetNetStats = GetNetStats
local GetFramerate = GetFramerate
local IsShiftKeyDown = IsShiftKeyDown
local floor = math.floor
local format = string.format

local frame = CreateFrame("Frame", "PingFPSFrame", UIParent, "BackdropTemplate")
frame:SetSize(130, 28)
frame:SetMovable(true)
frame:EnableMouse(true)
frame:RegisterForDrag("LeftButton")
frame:SetBackdrop({
    bgFile = "Interface/Tooltips/UI-Tooltip-Background",
    edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
    tile = true,
    tileSize = 16,
    edgeSize = 12,
    insets = { left = 3, right = 3, top = 3, bottom = 3 }
})
frame:SetBackdropColor(0, 0, 0, 0.6)

local text = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
text:SetPoint("CENTER")

frame:SetScript("OnDragStart", function(self)
    if IsShiftKeyDown() and not PingFPSDB.locked then
        self:StartMoving()
    end
end)

frame:SetScript("OnDragStop", function(self)
    self:StopMovingOrSizing()
    local point, _, _, x, y = self:GetPoint()
    PingFPSDB.point = point
    PingFPSDB.x = x
    PingFPSDB.y = y
end)

local function GetColor(ping, fps)
    if ping < 100 and fps > 50 then
        return 0, 1, 0
    elseif ping < 200 and fps > 30 then
        return 1, 0.8, 0
    else
        return 1, 0, 0
    end
end

local lastPing, lastFPS

local function UpdateDisplay()
    local _, _, homePing, worldPing = GetNetStats()
    local ping = worldPing or homePing
    local fps = floor(GetFramerate() + 0.5)
    if ping == lastPing and fps == lastFPS then return end
    lastPing = ping
    lastFPS = fps
    if PingFPSDB.useColor then
        text:SetTextColor(GetColor(ping, fps))
    else
        text:SetTextColor(1, 1, 1)
    end
    text:SetText(format("Ping: %d ms | FPS: %d", ping, fps))
end

frame:RegisterEvent("ADDON_LOADED")
frame:SetScript("OnEvent", function(_, _, addon)
    if addon ~= ADDON_NAME then return end
    ApplyDefaults()
    frame:ClearAllPoints()
    frame:SetPoint(PingFPSDB.point, UIParent, PingFPSDB.point, PingFPSDB.x, PingFPSDB.y)
    UpdateDisplay()
    C_Timer.NewTicker(1, UpdateDisplay)
end)

frame:SetScript("OnEnter", function()
    GameTooltip:SetOwner(frame, "ANCHOR_TOP")
    GameTooltip:AddLine(ADDON_NAME)
    GameTooltip:AddLine("Version: "..ADDON_VERSION, 1, 1, 1)
    GameTooltip:AddLine("Author: "..ADDON_AUTHOR, 0.8, 0.8, 0.8)
    GameTooltip:Show()
end)

frame:SetScript("OnLeave", function()
    GameTooltip:Hide()
end)

local panel = CreateFrame("Frame", "PingFPSOptionsPanel", InterfaceOptionsFramePanelContainer)
panel.name = ADDON_NAME

local title = panel:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
title:SetPoint("TOPLEFT", 16, -16)
title:SetText(ADDON_NAME)

local subtitle = panel:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
subtitle:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -6)
subtitle:SetText("Lightweight Ping & FPS display\nAuthor: "..ADDON_AUTHOR)

local lock = CreateFrame("CheckButton", nil, panel, "InterfaceOptionsCheckButtonTemplate")
lock:SetPoint("TOPLEFT", subtitle, "BOTTOMLEFT", 0, -16)
lock.Text:SetText("Lock frame")
lock:SetScript("OnClick", function(self)
    PingFPSDB.locked = self:GetChecked()
end)

local color = CreateFrame("CheckButton", nil, panel, "InterfaceOptionsCheckButtonTemplate")
color:SetPoint("TOPLEFT", lock, "BOTTOMLEFT", 0, -8)
color.Text:SetText("Enable color based on performance")
color:SetScript("OnClick", function(self)
    PingFPSDB.useColor = self:GetChecked()
    UpdateDisplay()
end)

local reset = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
reset:SetSize(120, 22)
reset:SetPoint("TOPLEFT", color, "BOTTOMLEFT", 0, -14)
reset:SetText("Reset Position")
reset:SetScript("OnClick", function()
    PingFPSDB.point = "CENTER"
    PingFPSDB.x = 0
    PingFPSDB.y = 0
    frame:ClearAllPoints()
    frame:SetPoint("CENTER")
end)

panel:SetScript("OnShow", function()
    lock:SetChecked(PingFPSDB.locked)
    color:SetChecked(PingFPSDB.useColor)
end)

InterfaceOptions_AddCategory(panel)
