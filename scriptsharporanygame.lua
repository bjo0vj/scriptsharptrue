-- =========================================================
-- PHATHUB PRO ULTIMATE - ESP + TOGGLE AIM + AUTO TP (ULTRA OPTIMIZED)
-- [FIXED] Highlight ESP Bug
-- [REMOVED] Target HUD & Weapon Scanner for Maximum FPS
-- =========================================================

-- [1] SERVICES
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

-- XÓA GUI & FOLDER CŨ NẾU CÓ ĐỂ TRÁNH TRÙNG LẶP
pcall(function() 
    if PlayerGui:FindFirstChild("PhatHub_Pro_UI") then PlayerGui.PhatHub_Pro_UI:Destroy() end
    if PlayerGui:FindFirstChild("PhatHub_ESP_Container") then PlayerGui.PhatHub_ESP_Container:Destroy() end
    if PlayerGui:FindFirstChild("PhatHub_TopRightUI") then PlayerGui.PhatHub_TopRightUI:Destroy() end
    if game:GetService("CoreGui"):FindFirstChild("PhatHub_HL_Folder") then game:GetService("CoreGui").PhatHub_HL_Folder:Destroy() end
    if workspace:FindFirstChild("PhatHub_HL_Folder") then workspace.PhatHub_HL_Folder:Destroy() end
end)

local ESP_Container = Instance.new("ScreenGui")
ESP_Container.Name = "PhatHub_ESP_Container"
ESP_Container.ResetOnSpawn = false
ESP_Container.Parent = PlayerGui

-- TẠO FOLDER CHỨA HIGHLIGHT RIÊNG (FIX LỖI HIGHLIGHT)
local HL_Folder = Instance.new("Folder")
HL_Folder.Name = "PhatHub_HL_Folder"
local success = pcall(function() HL_Folder.Parent = game:GetService("CoreGui") end)
if not success then HL_Folder.Parent = workspace end

-- [2] SETTINGS & TOGGLES
local Settings = {
    FOV = 50,
    Smoothness = 3,
    AimPart = "Head",
    
    IsAiming = false,
    ScriptEnabled = true,
    CurrentTarget = nil,

    ESP_Enabled = true,
    TeamCheck = false,
    NameESP = true,
    ShowDistance = false,
    Highlight = true,
    Tracer = false,
    
    AimRightClick = true,
    WallCheck = false,
    AutoClearMem = false,

    -- Cấu hình Teleport
    LoopTP_Enabled = false,
    TP_PositionMode = "Above" -- "Above" (10 stud) hoặc "Behind" (2 stud)
}

local ESP_Cache = {}

-- Tối ưu Raycast (Tạo 1 lần)
local GlobalRayParams = RaycastParams.new()
GlobalRayParams.FilterType = Enum.RaycastFilterType.Exclude
GlobalRayParams.IgnoreWater = true

-- Tối ưu Noclip (Cache Parts)
local MyCharacterParts = {}
local function UpdateCharacterParts(character)
    table.clear(MyCharacterParts)
    for _, part in ipairs(character:GetDescendants()) do
        if part:IsA("BasePart") then table.insert(MyCharacterParts, part) end
    end
    character.DescendantAdded:Connect(function(part)
        if part:IsA("BasePart") then table.insert(MyCharacterParts, part) end
    end)
end

if LocalPlayer.Character then UpdateCharacterParts(LocalPlayer.Character) end
LocalPlayer.CharacterAdded:Connect(function(char)
    UpdateCharacterParts(char)
    if Settings.AutoClearMem then task.wait(1); collectgarbage("collect") end
end)

-- =========================================================
-- [3] LOGIC FUNCTIONS
-- =========================================================
local function OptimizeMemory() collectgarbage("collect") end

local function IsEnemy(targetPlayer)
    if targetPlayer == LocalPlayer then return false end
    if targetPlayer.Team and LocalPlayer.Team then 
        return targetPlayer.Team ~= LocalPlayer.Team 
    end
    local myChar = LocalPlayer.Character
    local targetChar = targetPlayer.Character
    if myChar and targetChar and myChar.Parent and targetChar.Parent then 
        return myChar.Parent.Name ~= targetChar.Parent.Name 
    end
    return true
end

local function IsAlive(model)
    if not model or not model.Parent then return false end
    local humanoid = model.Parent:FindFirstChildOfClass("Humanoid")
    if not humanoid or humanoid.Health <= 0 then return false end
    
    if Settings.TeamCheck then
        local ply = Players:GetPlayerFromCharacter(model.Parent)
        if ply and not IsEnemy(ply) then return false end
    end
    return true
end

-- =========================================================
-- [4] FOV SETUP
-- =========================================================
local FOV_Circle = Drawing.new("Circle")
FOV_Circle.Radius = Settings.FOV
FOV_Circle.Thickness = 2
FOV_Circle.Color = Color3.fromRGB(255, 0, 0)
FOV_Circle.Filled = false
FOV_Circle.Visible = true

local CenterPoint = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
local BottomCenter = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y)

local function UpdateFOVPosition()
    CenterPoint = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
    BottomCenter = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y)
    FOV_Circle.Position = CenterPoint
end

UpdateFOVPosition()
Camera:GetPropertyChangedSignal("ViewportSize"):Connect(UpdateFOVPosition)

-- =========================================================
-- [5] GUI SETUP (PLAYERGUI)
-- =========================================================
-- 5.1 TOP RIGHT GUI
local TopRightGui = Instance.new("ScreenGui")
TopRightGui.Name = "PhatHub_TopRightUI"
TopRightGui.ResetOnSpawn = false
TopRightGui.Parent = PlayerGui

local SmoothLabel = Instance.new("TextLabel", TopRightGui)
SmoothLabel.Size = UDim2.new(0, 140, 0, 30)
SmoothLabel.Position = UDim2.new(1, -150, 0, 20)
SmoothLabel.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
SmoothLabel.TextColor3 = Color3.fromRGB(0, 255, 255)
SmoothLabel.Font = Enum.Font.GothamBold
SmoothLabel.TextSize = 14
SmoothLabel.Text = "Smooth: " .. Settings.Smoothness
Instance.new("UICorner", SmoothLabel).CornerRadius = UDim.new(0, 8)
local SmoothStroke = Instance.new("UIStroke", SmoothLabel)
SmoothStroke.Color = Color3.fromRGB(255, 255, 255)
SmoothStroke.Thickness = 1.2
SmoothStroke.Transparency = 0.5

local EspResetNotif = Instance.new("TextLabel", TopRightGui)
EspResetNotif.Size = UDim2.new(0, 220, 0, 35)
EspResetNotif.Position = UDim2.new(1, -230, 0, 60)
EspResetNotif.BackgroundColor3 = Color3.fromRGB(220, 50, 50)
EspResetNotif.TextColor3 = Color3.new(1, 1, 1)
EspResetNotif.Font = Enum.Font.GothamBold
EspResetNotif.TextSize = 14
EspResetNotif.Text = "Đang reset danh sách ESP..."
EspResetNotif.Visible = false
Instance.new("UICorner", EspResetNotif).CornerRadius = UDim.new(0, 8)
local NotifStroke = Instance.new("UIStroke", EspResetNotif)
NotifStroke.Color = Color3.new(1, 1, 1)
NotifStroke.Thickness = 1.5

-- 5.2 MAIN MENU UI
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "PhatHub_Pro_UI"
ScreenGui.IgnoreGuiInset = true
ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = PlayerGui

local MainFrame = Instance.new("Frame", ScreenGui)
MainFrame.Size = UDim2.new(0, 480, 0, 430) 
MainFrame.Position = UDim2.new(0.5, -240, 0.5, -215)
MainFrame.BackgroundColor3 = Color3.fromRGB(25, 28, 38)
MainFrame.BorderSizePixel = 0
MainFrame.Active = true
MainFrame.Draggable = true

Instance.new("UICorner", MainFrame).CornerRadius = UDim.new(0, 12)
local MainStroke = Instance.new("UIStroke", MainFrame)
MainStroke.Color = Color3.fromRGB(0, 180, 255)
MainStroke.Thickness = 1.5; MainStroke.Transparency = 0.2

local TitleBar = Instance.new("TextLabel", MainFrame)
TitleBar.Size = UDim2.new(1, -70, 0, 35)
TitleBar.Position = UDim2.new(0, 15, 0, 0)
TitleBar.BackgroundTransparency = 1; TitleBar.Text = "PhatHub Ultimate (Press 'P' to Hide)"
TitleBar.TextColor3 = Color3.fromRGB(240, 240, 245)
TitleBar.Font = Enum.Font.GothamBold; TitleBar.TextSize = 16
TitleBar.TextXAlignment = Enum.TextXAlignment.Left

local CloseBtn = Instance.new("TextButton", MainFrame)
CloseBtn.Size = UDim2.new(0, 30, 0, 30)
CloseBtn.Position = UDim2.new(1, -35, 0, 5)
CloseBtn.BackgroundColor3 = Color3.fromRGB(220, 60, 60); CloseBtn.Text = "X"
CloseBtn.TextColor3 = Color3.new(1,1,1); CloseBtn.Font = Enum.Font.GothamBold; CloseBtn.TextSize = 14
Instance.new("UICorner", CloseBtn).CornerRadius = UDim.new(0, 8)

local MinimizeBtn = Instance.new("TextButton", MainFrame)
MinimizeBtn.Size = UDim2.new(0, 30, 0, 30)
MinimizeBtn.Position = UDim2.new(1, -70, 0, 5)
MinimizeBtn.BackgroundColor3 = Color3.fromRGB(60, 65, 80); MinimizeBtn.Text = "-"
MinimizeBtn.TextColor3 = Color3.new(1,1,1); MinimizeBtn.Font = Enum.Font.GothamBold; MinimizeBtn.TextSize = 14
Instance.new("UICorner", MinimizeBtn).CornerRadius = UDim.new(0, 8)

local TabContainer = Instance.new("Frame", MainFrame)
TabContainer.Size = UDim2.new(1, -30, 0, 40)
TabContainer.Position = UDim2.new(0, 15, 0, 45)
TabContainer.BackgroundColor3 = Color3.fromRGB(35, 40, 55)
Instance.new("UICorner", TabContainer).CornerRadius = UDim.new(0, 10)

local CombatTabBtn = Instance.new("TextButton", TabContainer)
CombatTabBtn.Size = UDim2.new(0.5, 0, 1, 0)
CombatTabBtn.BackgroundColor3 = Color3.fromRGB(0, 180, 100)
CombatTabBtn.Text = "COMBAT"; CombatTabBtn.TextColor3 = Color3.new(1,1,1)
CombatTabBtn.Font = Enum.Font.GothamBold; CombatTabBtn.TextSize = 15
Instance.new("UICorner", CombatTabBtn).CornerRadius = UDim.new(0, 10)

local VisualTabBtn = Instance.new("TextButton", TabContainer)
VisualTabBtn.Size = UDim2.new(0.5, 0, 1, 0)
VisualTabBtn.Position = UDim2.new(0.5, 0, 0, 0)
VisualTabBtn.BackgroundColor3 = Color3.fromRGB(35, 40, 55); VisualTabBtn.Text = "VISUAL"
VisualTabBtn.TextColor3 = Color3.new(1,1,1); VisualTabBtn.Font = Enum.Font.GothamBold; VisualTabBtn.TextSize = 15
Instance.new("UICorner", VisualTabBtn).CornerRadius = UDim.new(0, 10)

local CombatFrame = Instance.new("Frame", MainFrame)
CombatFrame.Size = UDim2.new(1, 0, 1, -95)
CombatFrame.Position = UDim2.new(0, 0, 0, 95)
CombatFrame.BackgroundTransparency = 1; CombatFrame.Visible = true

local VisualFrame = Instance.new("Frame", MainFrame)
VisualFrame.Size = UDim2.new(1, 0, 1, -95)
VisualFrame.Position = UDim2.new(0, 0, 0, 95)
VisualFrame.BackgroundTransparency = 1; VisualFrame.Visible = false

local function SetupGridLayout(parent)
    local grid = Instance.new("UIGridLayout", parent)
    grid.CellSize = UDim2.new(0.47, 0, 0, 36)
    grid.CellPadding = UDim2.new(0.04, 0, 0, 12)
    grid.HorizontalAlignment = Enum.HorizontalAlignment.Center
    grid.SortOrder = Enum.SortOrder.LayoutOrder
    local padding = Instance.new("UIPadding", parent)
    padding.PaddingTop = UDim.new(0, 10)
    padding.PaddingLeft = UDim.new(0, 15); padding.PaddingRight = UDim.new(0, 15)
end
SetupGridLayout(CombatFrame); SetupGridLayout(VisualFrame)

CombatTabBtn.MouseButton1Click:Connect(function()
    CombatFrame.Visible = true; VisualFrame.Visible = false
    CombatTabBtn.BackgroundColor3 = Color3.fromRGB(0, 180, 100); VisualTabBtn.BackgroundColor3 = Color3.fromRGB(35, 40, 55)
end)

VisualTabBtn.MouseButton1Click:Connect(function()
    CombatFrame.Visible = false; VisualFrame.Visible = true
    CombatTabBtn.BackgroundColor3 = Color3.fromRGB(35, 40, 55); VisualTabBtn.BackgroundColor3 = Color3.fromRGB(0, 180, 100)
end)

local function CreateButton(parent, text, isTextBox, order)
    local btn = Instance.new(isTextBox and "TextBox" or "TextButton", parent)
    btn.Text = text
    btn.LayoutOrder = order; btn.BackgroundColor3 = Color3.fromRGB(45, 52, 70)
    btn.TextColor3 = Color3.new(1,1,1); btn.Font = Enum.Font.GothamSemibold; btn.TextSize = 14
    btn.BorderSizePixel = 0
    if isTextBox then btn.ClearTextOnFocus = true end
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 8)
    local stroke = Instance.new("UIStroke", btn)
    stroke.Color = Color3.fromRGB(80, 90, 120); stroke.Thickness = 1.2; stroke.Transparency = 0.4
    return btn
end

-- COMBAT TAB
local AimStatusLabel = Instance.new("TextLabel", CombatFrame)
AimStatusLabel.Text = "AIM : MANUAL (OFF)"
AimStatusLabel.LayoutOrder = 1
AimStatusLabel.BackgroundTransparency = 1
AimStatusLabel.TextColor3 = Color3.fromRGB(255, 80, 80); AimStatusLabel.Font = Enum.Font.GothamBold
AimStatusLabel.TextSize = 18

local FovBox = CreateButton(CombatFrame, "FOV: " .. Settings.FOV, true, 2)
local SmoothBox = CreateButton(CombatFrame, "Smooth: " .. Settings.Smoothness, true, 3)
local AimPartBtn = CreateButton(CombatFrame, "Aim Part: HEAD", false, 4)
AimPartBtn.TextColor3 = Color3.fromRGB(100, 255, 255)

local TeamCheckBtn = CreateButton(CombatFrame, "Team Check: OFF", false, 5)
local AimRCBtn = CreateButton(CombatFrame, "Aim Right Click: ON", false, 6)
local WallCheckBtn = CreateButton(CombatFrame, "Wall Check: OFF", false, 7)
local RecenterFovBtn = CreateButton(CombatFrame, "Recenter FOV", false, 8)
RecenterFovBtn.BackgroundColor3 = Color3.fromRGB(100, 80, 200)

local TPPosBtn = CreateButton(CombatFrame, "TP Pos: TRÊN ĐẦU 10 STUD", false, 9)
TPPosBtn.BackgroundColor3 = Color3.fromRGB(0, 150, 100)
TPPosBtn.Font = Enum.Font.GothamBold

if Settings.TP_PositionMode == "Behind" then
    TPPosBtn.Text = "TP Pos: SAU LƯNG 2 STUD"
    TPPosBtn.BackgroundColor3 = Color3.fromRGB(200, 100, 0)
end

TeamCheckBtn.TextColor3 = Color3.fromRGB(255, 150, 150)
AimRCBtn.TextColor3 = Color3.fromRGB(0, 255, 100)
WallCheckBtn.TextColor3 = Color3.fromRGB(255, 150, 150)

-- VISUAL TAB
local EspMainBtn = CreateButton(VisualFrame, "ESP : ON", false, 1)
EspMainBtn.TextColor3 = Color3.fromRGB(100, 255, 255)
local HighlightBtn = CreateButton(VisualFrame, "Highlight: ON", false, 2)
local NameEspBtn = CreateButton(VisualFrame, "Name ESP: ON", false, 3)
local TracerBtn = CreateButton(VisualFrame, "Tracer: OFF", false, 4)
TracerBtn.TextColor3 = Color3.fromRGB(255, 150, 150)
local ClearMemBtn = CreateButton(VisualFrame, "Clear Memory", false, 5)
ClearMemBtn.BackgroundColor3 = Color3.fromRGB(150, 60, 60)
local AutoClearBtn = CreateButton(VisualFrame, "Auto Clear Mem: OFF", false, 6)
AutoClearBtn.TextColor3 = Color3.fromRGB(255, 150, 150)
local DistanceEspBtn = CreateButton(VisualFrame, "Distance ESP: OFF", false, 7)
DistanceEspBtn.TextColor3 = Color3.fromRGB(255, 150, 150)

-- =========================================================
-- [6] UI INTERACTIONS
-- =========================================================
local function UpdateSmoothGUI()
    SmoothLabel.Text = "Smooth: " .. Settings.Smoothness
    SmoothBox.Text = "Smooth: " .. Settings.Smoothness
end

local isMinimized = false
MinimizeBtn.MouseButton1Click:Connect(function()
    isMinimized = not isMinimized
    if isMinimized then
        MinimizeBtn.Text = "+"
        TabContainer.Visible = false; CombatFrame.Visible = false; VisualFrame.Visible = false
        MainFrame.Size = UDim2.new(0, 480, 0, 40)
    else
        MinimizeBtn.Text = "-"
        TabContainer.Visible = true
        if CombatTabBtn.BackgroundColor3 == Color3.fromRGB(0, 180, 100) then CombatFrame.Visible = true else VisualFrame.Visible = true end
        MainFrame.Size = UDim2.new(0, 480, 0, 430)
    end
end)

CloseBtn.MouseButton1Click:Connect(function()
    Settings.ScriptEnabled = false
    Settings.LoopTP_Enabled = false
    for _, objects in pairs(ESP_Cache) do
        if objects.Highlight then objects.Highlight:Destroy() end
        if objects.Billboard then objects.Billboard:Destroy() end
        if objects.Tracer then objects.Tracer:Remove() end
        if objects.Connection then objects.Connection:Disconnect() end
    end
    table.clear(ESP_Cache)
    FOV_Circle:Remove()
    ESP_Container:Destroy()
    ScreenGui:Destroy()
    TopRightGui:Destroy()
    HL_Folder:Destroy()
end)

FovBox.FocusLost:Connect(function()
    local val = tonumber(FovBox.Text)
    if val and val > 0 then Settings.FOV = val; FOV_Circle.Radius = val end
    FovBox.Text = "FOV: " .. Settings.FOV
end)

SmoothBox.FocusLost:Connect(function()
    local val = tonumber(SmoothBox.Text)
    if val then Settings.Smoothness = math.max(val, 1) end
    UpdateSmoothGUI()
end)

AimPartBtn.MouseButton1Click:Connect(function()
    if Settings.AimPart == "Head" then
        Settings.AimPart = "HumanoidRootPart"; AimPartBtn.Text = "Aim Part: BODY"
    else
        Settings.AimPart = "Head"; AimPartBtn.Text = "Aim Part: HEAD"
    end
end)

TPPosBtn.MouseButton1Click:Connect(function()
    if Settings.TP_PositionMode == "Above" then
        Settings.TP_PositionMode = "Behind"
        TPPosBtn.Text = "TP Pos: SAU LƯNG 2 STUD"
        TPPosBtn.BackgroundColor3 = Color3.fromRGB(200, 100, 0)
    else
        Settings.TP_PositionMode = "Above"
        TPPosBtn.Text = "TP Pos: TRÊN ĐẦU 10 STUD"
        TPPosBtn.BackgroundColor3 = Color3.fromRGB(0, 150, 100)
    end
end)

local function ToggleBtn(btn, settingKey, textPrefix)
    Settings[settingKey] = not Settings[settingKey]
    btn.Text = textPrefix .. (Settings[settingKey] and "ON" or "OFF")
    btn.TextColor3 = Settings[settingKey] and Color3.fromRGB(0, 255, 100) or Color3.fromRGB(255, 150, 150)
end

RecenterFovBtn.MouseButton1Click:Connect(function()
    UpdateFOVPosition()
    RecenterFovBtn.Text = "Reset OK!"
    task.delay(1, function() RecenterFovBtn.Text = "Recenter FOV" end)
end)

EspMainBtn.MouseButton1Click:Connect(function() ToggleBtn(EspMainBtn, "ESP_Enabled", "ESP : ") end)
TeamCheckBtn.MouseButton1Click:Connect(function() ToggleBtn(TeamCheckBtn, "TeamCheck", "Team Check: ") end)
AimRCBtn.MouseButton1Click:Connect(function() ToggleBtn(AimRCBtn, "AimRightClick", "Aim Right Click: ") end)
WallCheckBtn.MouseButton1Click:Connect(function() ToggleBtn(WallCheckBtn, "WallCheck", "Wall Check: ") end)
HighlightBtn.MouseButton1Click:Connect(function() ToggleBtn(HighlightBtn, "Highlight", "Highlight: ") end)
NameEspBtn.MouseButton1Click:Connect(function() ToggleBtn(NameEspBtn, "NameESP", "Name ESP: ") end)
DistanceEspBtn.MouseButton1Click:Connect(function() ToggleBtn(DistanceEspBtn, "ShowDistance", "Distance ESP: ") end)
TracerBtn.MouseButton1Click:Connect(function() ToggleBtn(TracerBtn, "Tracer", "Tracer: ") end)
AutoClearBtn.MouseButton1Click:Connect(function() ToggleBtn(AutoClearBtn, "AutoClearMem", "Auto Clear Mem: ") end)
ClearMemBtn.MouseButton1Click:Connect(OptimizeMemory)

-- =========================================================
-- [7] ESP ENGINE (OPTIMIZED & FIXED HIGHLIGHT)
-- =========================================================
local function InitPlayerESP(player)
    if player == LocalPlayer then return end
    
    local objects = {}

    local highlight = Instance.new("Highlight")
    highlight.Name = player.Name .. "_Highlight"
    highlight.FillColor = Color3.fromRGB(0, 255, 0)
    highlight.OutlineColor = Color3.new(1, 1, 1)
    highlight.FillTransparency = 0.5
    highlight.OutlineTransparency = 0.1
    highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    highlight.Parent = HL_Folder -- Đưa ra ngoài ScreenGui
    objects.Highlight = highlight

    local billboard = Instance.new("BillboardGui")
    billboard.Name = player.Name .. "_Billboard"
    billboard.Size = UDim2.new(0, 200, 0, 50)
    billboard.StudsOffset = Vector3.new(0, 3.5, 0)
    billboard.AlwaysOnTop = true
    billboard.Enabled = false
    billboard.Parent = ESP_Container
    objects.Billboard = billboard

    local textLabel = Instance.new("TextLabel")
    textLabel.Size = UDim2.new(1, 0, 1, 0)
    textLabel.BackgroundTransparency = 1
    textLabel.TextColor3 = Color3.fromRGB(0, 255, 0)
    textLabel.TextStrokeTransparency = 0
    textLabel.TextSize = 14
    textLabel.Font = Enum.Font.SourceSansBold
    textLabel.Parent = billboard
    objects.Text = textLabel

    local tracer = Drawing.new("Line")
    tracer.Visible = false
    tracer.Color = Color3.fromRGB(0, 255, 0)
    tracer.Thickness = 1.5
    tracer.Transparency = 1
    objects.Tracer = tracer

    local function UpdateAdornee(char)
        -- Setup lại Adornee an toàn
        if Settings.Highlight and Settings.ESP_Enabled then
            highlight.Adornee = char
        else
            highlight.Adornee = nil
        end
        local head = char:WaitForChild("Head", 5)
        if head then billboard.Adornee = head end
    end
    
    if player.Character then UpdateAdornee(player.Character) end
    objects.Connection = player.CharacterAdded:Connect(UpdateAdornee)

    ESP_Cache[player] = objects
end

local function RemovePlayerESP(player)
    if ESP_Cache[player] then
        if ESP_Cache[player].Highlight then ESP_Cache[player].Highlight:Destroy() end
        if ESP_Cache[player].Billboard then ESP_Cache[player].Billboard:Destroy() end
        if ESP_Cache[player].Tracer then ESP_Cache[player].Tracer:Remove() end
        if ESP_Cache[player].Connection then ESP_Cache[player].Connection:Disconnect() end
        ESP_Cache[player] = nil
    end
end

for _, ply in ipairs(Players:GetPlayers()) do InitPlayerESP(ply) end
Players.PlayerAdded:Connect(InitPlayerESP)
Players.PlayerRemoving:Connect(RemovePlayerESP)

-- =========================================================
-- [8] TARGET ACQUISITION & INPUT (AIM + TP LOGIC)
-- =========================================================
local function GetClosestTarget()
    local bestTarget = nil
    local bestDist = Settings.FOV 

    for _, player in pairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then
            if Settings.TeamCheck and not IsEnemy(player) then continue end
            
            local char = player.Character
            if char and char.Parent and char:IsDescendantOf(workspace) then
                local humanoid = char:FindFirstChildOfClass("Humanoid")
                local targetPart = char:FindFirstChild(Settings.AimPart)
    
                if humanoid and targetPart and humanoid.Health > 0 then
                    if Settings.WallCheck then
                        GlobalRayParams.FilterDescendantsInstances = {LocalPlayer.Character, Camera}
                        local dir = (targetPart.Position - Camera.CFrame.Position)
                        local ray = workspace:Raycast(Camera.CFrame.Position, dir, GlobalRayParams)
                        
                        if ray and ray.Instance and not ray.Instance:IsDescendantOf(char) and ray.Instance.Transparency < 0.8 then
                            continue 
                        end
                    end

                    local screenPos, onScreen = Camera:WorldToViewportPoint(targetPart.Position)
                    if onScreen then
                        local distToCenter = (Vector2.new(screenPos.X, screenPos.Y) - CenterPoint).Magnitude
                        if distToCenter < bestDist then
                            bestDist = distToCenter
                            bestTarget = targetPart
                        end
                    end
                end
            end
        end
    end
    return bestTarget
end

local isLockedByE = false

UserInputService.InputBegan:Connect(function(input, processed)
    if processed then return end
    if input.KeyCode == Enum.KeyCode.P then
        ScreenGui.Enabled = not ScreenGui.Enabled
        return
    end

    if input.KeyCode == Enum.KeyCode.Eight then
        Settings.Smoothness = math.max(1, Settings.Smoothness - 1)
        UpdateSmoothGUI()
    elseif input.KeyCode == Enum.KeyCode.Nine then
        Settings.Smoothness = Settings.Smoothness + 1
        UpdateSmoothGUI()
    elseif input.KeyCode == Enum.KeyCode.O then
        if Settings.TP_PositionMode == "Above" then
            Settings.TP_PositionMode = "Behind"
            TPPosBtn.Text = "TP Pos: SAU LƯNG 2 STUD"
            TPPosBtn.BackgroundColor3 = Color3.fromRGB(200, 100, 0)
        else
            Settings.TP_PositionMode = "Above"
            TPPosBtn.Text = "TP Pos: TRÊN ĐẦU 10 STUD"
            TPPosBtn.BackgroundColor3 = Color3.fromRGB(0, 150, 100)
        end
    elseif input.KeyCode == Enum.KeyCode.Zero then
        for ply, objects in pairs(ESP_Cache) do
            if objects.Highlight then objects.Highlight:Destroy() end
            if objects.Billboard then objects.Billboard:Destroy() end
            if objects.Tracer then objects.Tracer:Remove() end
            if objects.Connection then objects.Connection:Disconnect() end
        end
        table.clear(ESP_Cache)
        
        EspResetNotif.Visible = true
        task.delay(2, function() EspResetNotif.Visible = false end)

        for _, ply in ipairs(Players:GetPlayers()) do InitPlayerESP(ply) end

    elseif input.KeyCode == Enum.KeyCode.G then
        Settings.LoopTP_Enabled = not Settings.LoopTP_Enabled
        
        if Settings.LoopTP_Enabled then
            if not Settings.CurrentTarget then Settings.CurrentTarget = GetClosestTarget() end
            if Settings.CurrentTarget then
                Settings.IsAiming = true
                isLockedByE = true
            else
                Settings.LoopTP_Enabled = false
            end
        else
            isLockedByE = false
            Settings.IsAiming = false
            Settings.CurrentTarget = nil
        end

    elseif input.KeyCode == Enum.KeyCode.E then
        if Settings.LoopTP_Enabled then return end 

        isLockedByE = not isLockedByE
        if isLockedByE then
            Settings.IsAiming = true
            Settings.CurrentTarget = GetClosestTarget()
            if not Settings.CurrentTarget then
                isLockedByE = false
                Settings.IsAiming = false
            end
        else
            Settings.IsAiming = false
            Settings.CurrentTarget = nil
        end

    elseif Settings.AimRightClick and input.UserInputType == Enum.UserInputType.MouseButton2 then
        if not isLockedByE and not Settings.LoopTP_Enabled then
            Settings.IsAiming = true
        end
    elseif input.KeyCode == Enum.KeyCode.LeftAlt or input.KeyCode == Enum.KeyCode.RightAlt then
        if Settings.AimPart == "Head" then
            Settings.AimPart = "HumanoidRootPart"
            AimPartBtn.Text = "Aim Part: BODY"
        else
            Settings.AimPart = "Head"
            AimPartBtn.Text = "Aim Part: HEAD"
        end
    end
end)

UserInputService.InputEnded:Connect(function(input)
    if Settings.AimRightClick and input.UserInputType == Enum.UserInputType.MouseButton2 then
        if not isLockedByE and not Settings.LoopTP_Enabled then
            Settings.IsAiming = false
            Settings.CurrentTarget = nil 
        end
    end
end)

-- =========================================================
-- [9] TELEPORT & NOCLIP ENGINE
-- =========================================================
RunService.Stepped:Connect(function()
    if Settings.ScriptEnabled and Settings.LoopTP_Enabled and Settings.CurrentTarget then
        for _, part in ipairs(MyCharacterParts) do
            part.CanCollide = false
        end
    end
end)

-- =========================================================
-- [10] HEARTBEAT LOOP (LOGIC NẶNG & CẬP NHẬT HIGHLIGHT)
-- =========================================================
RunService.Heartbeat:Connect(function()
    if not Settings.ScriptEnabled then return end

    -- [1] KIỂM TRA MỤC TIÊU CÒN SỐNG
    if Settings.IsAiming then
        if not Settings.CurrentTarget or not IsAlive(Settings.CurrentTarget) then 
            if isLockedByE or Settings.LoopTP_Enabled then
                isLockedByE = false
                Settings.LoopTP_Enabled = false
                Settings.IsAiming = false
                Settings.CurrentTarget = nil
            else
                Settings.CurrentTarget = GetClosestTarget() 
            end
        end
    else
        Settings.CurrentTarget = nil
    end

    -- [2] XỬ LÝ TELEPORT VÀO VỊ TRÍ
    if Settings.LoopTP_Enabled and Settings.CurrentTarget then
        local myChar = LocalPlayer.Character
        local targetChar = Settings.CurrentTarget.Parent

        if myChar and myChar:FindFirstChild("HumanoidRootPart") and targetChar and targetChar:FindFirstChild("HumanoidRootPart") then
            local myHRP = myChar.HumanoidRootPart
            local targetHRP = targetChar.HumanoidRootPart
            
            myHRP.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
            myHRP.AssemblyAngularVelocity = Vector3.new(0, 0, 0)
            
            if Settings.TP_PositionMode == "Above" then
                myHRP.CFrame = targetHRP.CFrame * CFrame.new(0, 10, 0)
            elseif Settings.TP_PositionMode == "Behind" then
                myHRP.CFrame = targetHRP.CFrame * CFrame.new(0, 0, 2)
            end
        end
    end

    -- [3] XỬ LÝ ESP PROPERTIES (DÙNG ADORNEE = NIL ĐỂ ẨN)
    for player, objects in pairs(ESP_Cache) do
        if not Settings.ESP_Enabled or not player.Character or not player.Character:FindFirstChild("HumanoidRootPart") or not player.Character:FindFirstChild("Humanoid") or player.Character.Humanoid.Health <= 0 then
            objects.Highlight.Adornee = nil
            objects.Billboard.Enabled = false
            continue
        end

        if Settings.TeamCheck and not IsEnemy(player) then
            objects.Highlight.Adornee = nil
            objects.Billboard.Enabled = false
            continue
        end

        local isTargeted = (Settings.CurrentTarget and player == Players:GetPlayerFromCharacter(Settings.CurrentTarget.Parent))
        local currentColor = isTargeted and Color3.fromRGB(255, 0, 0) or Color3.fromRGB(0, 255, 0)

        if Settings.Highlight then
            objects.Highlight.Adornee = player.Character
            objects.Highlight.FillColor = currentColor
        else
            objects.Highlight.Adornee = nil
        end

        if Settings.NameESP then
            objects.Billboard.Enabled = true
            objects.Text.TextColor3 = currentColor
            if Settings.ShowDistance then
                local dist = math.floor((Camera.CFrame.Position - player.Character.HumanoidRootPart.Position).Magnitude)
                objects.Text.Text = player.Name .. "\n[" .. tostring(dist) .. "m]"
            else
                objects.Text.Text = player.Name
            end
        else
            objects.Billboard.Enabled = false
        end
    end
end)

-- =========================================================
-- [11] RENDER LOOP (MƯỢT MÀN HÌNH)
-- =========================================================
RunService.RenderStepped:Connect(function()
    if not Settings.ScriptEnabled then return end

    -- [AIM EXECUTION]
    if Settings.IsAiming and Settings.CurrentTarget then
        local targetPos, onScreen = Camera:WorldToViewportPoint(Settings.CurrentTarget.Position)
        if onScreen then
            local moveX = (targetPos.X - CenterPoint.X) / Settings.Smoothness
            local moveY = (targetPos.Y - CenterPoint.Y) / Settings.Smoothness
            if mousemoverel then mousemoverel(moveX, moveY) end
        end

        if Settings.LoopTP_Enabled then
            AimStatusLabel.Text = "AIM + TP : LOCKED (KEY G)"
        elseif isLockedByE then
            AimStatusLabel.Text = "AIM : LOCKED (KEY E)"
        else
            AimStatusLabel.Text = "AIM : MANUAL (HOLDING)"
        end
        
        AimStatusLabel.TextColor3 = Color3.fromRGB(0, 255, 0)
        FOV_Circle.Color = Color3.fromRGB(0, 255, 0)
    else
        if AimStatusLabel.Text ~= "AIM : MANUAL (OFF)" then
            AimStatusLabel.Text = "AIM : MANUAL (OFF)"
            AimStatusLabel.TextColor3 = Color3.fromRGB(255, 80, 80)
        end
        FOV_Circle.Color = Color3.fromRGB(255, 0, 0)
    end

    -- [TRACER EXECUTION]
    for player, objects in pairs(ESP_Cache) do
        if Settings.Tracer and Settings.ESP_Enabled and player.Character and player.Character:FindFirstChild("HumanoidRootPart") and player.Character:FindFirstChild("Humanoid") and player.Character.Humanoid.Health > 0 and (not Settings.TeamCheck or IsEnemy(player)) then
            local vector, onScreen = Camera:WorldToViewportPoint(player.Character.HumanoidRootPart.Position)
            if onScreen then
                local isTargeted = (Settings.CurrentTarget and player == Players:GetPlayerFromCharacter(Settings.CurrentTarget.Parent))
                objects.Tracer.From = BottomCenter
                objects.Tracer.To = Vector2.new(vector.X, vector.Y)
                objects.Tracer.Color = isTargeted and Color3.fromRGB(255, 0, 0) or Color3.fromRGB(0, 255, 0)
                objects.Tracer.Visible = true
            else
                objects.Tracer.Visible = false
            end
        else
            objects.Tracer.Visible = false
        end
    end
end)
