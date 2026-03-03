local ADDON_NAME = "PingFPS"
PingFPSDB = PingFPSDB or {}

-- Defaults
local DEFAULTS = { point = "CENTER", x = 0, y = 0, locked = false, useColor = true, showPing = true, showFPS = true, fontSize = 14, fontName = "Default" }
local FONT_MAP = { 
    ["Default"] = "Fonts\\FRIZQT__.TTF", 
    ["Quantico"] = "Interface\\AddOns\\PingFPS\\Fonts\\Quantico\\Quantico-Regular.ttf", 
    ["Offside"] = "Interface\\AddOns\\PingFPS\\Fonts\\Offside\\Offside-Regular.ttf" 
}
local fontOrder = {"Default", "Quantico", "Offside"}

local function ApplyDefaults()
    for k, v in pairs(DEFAULTS) do if PingFPSDB[k] == nil then PingFPSDB[k] = v end end
end

-- Main Display
local frame = CreateFrame("Frame", "PingFPS_MainFrame", UIParent, "BackdropTemplate")
frame:SetMovable(true); frame:EnableMouse(true); frame:RegisterForDrag("LeftButton")
frame:SetBackdrop({bgFile = "Interface/Buttons/WHITE8x8", edgeFile = "Interface/Buttons/WHITE8x8", tile = true, tileSize = 16, edgeSize = 1})
frame:SetBackdropColor(0, 0, 0, 0.7); frame:SetBackdropBorderColor(0.2, 0.2, 0.2, 1)

local text = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
text:SetPoint("CENTER")

-- NEW: Logic to make the frame hug the text
local function UpdateFrameSize()
    local w = text:GetStringWidth() + 20
    local h = text:GetStringHeight() + 10
    frame:SetSize(w, h)
end

local function RefreshFont()
    local path = FONT_MAP[PingFPSDB.fontName] or FONT_MAP["Default"]
    text:SetFont(path, PingFPSDB.fontSize, "OUTLINE")
    UpdateFrameSize() -- Resize when font changes
end

local function UpdateDisplay()
    local _, _, home, world = GetNetStats()
    local ping = world or home; local fps = math.floor(GetFramerate() + 0.5)
    local t = {}
    if PingFPSDB.showPing then table.insert(t, "Ping: " .. ping .. "ms") end
    if PingFPSDB.showFPS then table.insert(t, "FPS: " .. fps) end
    text:SetText(#t > 0 and table.concat(t, " | ") or "Hidden")
    text:SetTextColor(PingFPSDB.useColor and (ping < 100 and 0 or 1) or 1, PingFPSDB.useColor and 1 or 1, 0)
    UpdateFrameSize() -- Resize when text content changes
end

-- Custom Settings Overlay
local settingsFrame = CreateFrame("Frame", "PingFPS_SettingsOverlay", UIParent, "BackdropTemplate")
settingsFrame:SetSize(220, 200); settingsFrame:SetPoint("CENTER"); settingsFrame:Hide()
settingsFrame:SetBackdrop({bgFile = "Interface/Buttons/WHITE8x8", edgeFile = "Interface/Buttons/WHITE8x8", tile = true, tileSize = 16, edgeSize = 1})
settingsFrame:SetBackdropColor(0.1, 0.1, 0.1, 0.9); settingsFrame:SetBackdropBorderColor(0.4, 0.4, 0.4, 1)
settingsFrame:SetMovable(true); settingsFrame:EnableMouse(true); settingsFrame:RegisterForDrag("LeftButton")
settingsFrame:SetScript("OnDragStart", settingsFrame.StartMoving); settingsFrame:SetScript("OnDragStop", settingsFrame.StopMovingOrSizing)

local closeBtn = CreateFrame("Button", nil, settingsFrame, "UIPanelCloseButton"); closeBtn:SetPoint("TOPRIGHT", -2, -2)

local function CreateCheck(label, key, yOffset)
    local btnName = "PingFPS_CB_" .. key
    local btn = CreateFrame("CheckButton", btnName, settingsFrame, "UICheckButtonTemplate")
    btn:SetPoint("TOPLEFT", 20, yOffset)
    _G[btnName .. "Text"]:SetText(label)
    btn:SetScript("OnClick", function(s) PingFPSDB[key] = s:GetChecked(); UpdateDisplay() end)
    btn:SetScript("OnShow", function(s) s:SetChecked(PingFPSDB[key]) end)
    return btn
end

CreateCheck("Show Ping", "showPing", -40)
CreateCheck("Show FPS", "showFPS", -70)
CreateCheck("Use Colors", "useColor", -100)

local btn = CreateFrame("Button", nil, settingsFrame, "UIPanelButtonTemplate")
btn:SetSize(100, 25); btn:SetPoint("TOP", 0, -140); btn:SetText("Cycle Font")
btn:SetScript("OnClick", function()
    for i, name in ipairs(fontOrder) do
        if name == PingFPSDB.fontName then PingFPSDB.fontName = fontOrder[(i % #fontOrder) + 1]; break end
    end
    RefreshFont()
end)

-- Init
frame:RegisterEvent("ADDON_LOADED")
frame:SetScript("OnEvent", function(_, _, addon)
    if addon ~= ADDON_NAME then return end
    ApplyDefaults(); RefreshFont()
    frame:ClearAllPoints(); frame:SetPoint(PingFPSDB.point, UIParent, PingFPSDB.point, PingFPSDB.x, PingFPSDB.y)
    UpdateDisplay()
    C_Timer.NewTicker(1, UpdateDisplay)
end)

frame:SetScript("OnDragStart", function(s) if IsShiftKeyDown() and not PingFPSDB.locked then s:StartMoving() end end)
frame:SetScript("OnDragStop", function(s)
    s:StopMovingOrSizing(); local p, _, _, x, y = s:GetPoint()
    PingFPSDB.point, PingFPSDB.x, PingFPSDB.y = p, x, y
end)

SLASH_PINGFPS1 = "/pfs"
SlashCmdList["PINGFPS"] = function() 
    if settingsFrame:IsShown() then settingsFrame:Hide() else settingsFrame:Show() end 
end