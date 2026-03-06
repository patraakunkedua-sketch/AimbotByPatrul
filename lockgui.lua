-- AimbotByPatrul v3.0 - Fixed Sline + Player List Whitelist + Smooth Headlock
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local CoreGui = game:GetService("CoreGui")

local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

local Settings = {
    LockEnabled = false,
    LockPart = "Torso",
    SlineEnabled = false,
    MaxDistance = 500,
    LockSmoothing = 0.08,   -- torso: lebih ketat
    HeadSmoothing = 0.04,   -- head: smooth seperti free fire
    HeadOffset = 0.5,       -- offset agar tidak nempel banget (0=nempel, 1=jauh)
    TeamCheck = false,
}

local Whitelist = { [LocalPlayer.Name] = true }
local LockedTarget = nil

-- =====================
--     CLEAR OLD GUI
-- =====================
if CoreGui:FindFirstChild("LockGUI") then
    CoreGui:FindFirstChild("LockGUI"):Destroy()
end

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "LockGUI"
ScreenGui.ResetOnSpawn = false
ScreenGui.IgnoreGuiInset = true
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
pcall(function() ScreenGui.Parent = CoreGui end)
if not ScreenGui.Parent then
    ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")
end

-- =====================
--   SLINE CANVAS (FIXED)
-- =====================
-- Pakai SurfaceGui trick: Frame penuh layar utk drawing
local SlineFrame = Instance.new("Frame")
SlineFrame.Name = "SlineFrame"
SlineFrame.Size = UDim2.new(1, 0, 1, 0)
SlineFrame.Position = UDim2.new(0, 0, 0, 0)
SlineFrame.BackgroundTransparency = 1
SlineFrame.BorderSizePixel = 0
SlineFrame.ZIndex = 5
SlineFrame.ClipsDescendants = false
SlineFrame.Parent = ScreenGui

-- =====================
--      MAIN FRAME
-- =====================
local Frame = Instance.new("Frame")
Frame.Size = UDim2.new(0, 210, 0, 300)
Frame.Position = UDim2.new(0, 20, 0.5, -150)
Frame.BackgroundColor3 = Color3.fromRGB(13, 13, 13)
Frame.BorderSizePixel = 0
Frame.Active = true
Frame.Draggable = true
Frame.ZIndex = 20
Frame.Parent = ScreenGui
Instance.new("UICorner", Frame).CornerRadius = UDim.new(0, 10)
local MS = Instance.new("UIStroke", Frame)
MS.Color = Color3.fromRGB(50, 50, 50)
MS.Thickness = 1

-- Title
local TitleBar = Instance.new("Frame")
TitleBar.Size = UDim2.new(1, 0, 0, 38)
TitleBar.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
TitleBar.BorderSizePixel = 0
TitleBar.ZIndex = 21
TitleBar.Parent = Frame
local TBC = Instance.new("UICorner", TitleBar)
TBC.CornerRadius = UDim.new(0, 10)
local TBFix = Instance.new("Frame", TitleBar)
TBFix.Size = UDim2.new(1,0,0.5,0)
TBFix.Position = UDim2.new(0,0,0.5,0)
TBFix.BackgroundColor3 = Color3.fromRGB(20,20,20)
TBFix.BorderSizePixel = 0
TBFix.ZIndex = 21

local TLabel = Instance.new("TextLabel", TitleBar)
TLabel.Size = UDim2.new(1,0,1,0)
TLabel.BackgroundTransparency = 1
TLabel.Text = "🎯 AimbotByPatrul v3"
TLabel.TextColor3 = Color3.fromRGB(255,255,255)
TLabel.TextSize = 13
TLabel.Font = Enum.Font.GothamBold
TLabel.ZIndex = 22

local function makeDivider(yPos)
    local d = Instance.new("Frame", Frame)
    d.Size = UDim2.new(1,-20,0,1)
    d.Position = UDim2.new(0,10,0,yPos)
    d.BackgroundColor3 = Color3.fromRGB(40,40,40)
    d.BorderSizePixel = 0
    d.ZIndex = 21
end

makeDivider(38)

-- Fungsi buat tombol toggle
local function makeToggleBtn(yPos, icon, label)
    local Btn = Instance.new("TextButton", Frame)
    Btn.Size = UDim2.new(1,-20,0,32)
    Btn.Position = UDim2.new(0,10,0,yPos)
    Btn.BackgroundColor3 = Color3.fromRGB(25,25,25)
    Btn.BorderSizePixel = 0
    Btn.TextXAlignment = Enum.TextXAlignment.Left
    Btn.Text = "  "..icon.." "..label
    Btn.TextColor3 = Color3.fromRGB(160,160,160)
    Btn.TextSize = 12
    Btn.Font = Enum.Font.GothamSemibold
    Btn.ZIndex = 21
    Instance.new("UICorner", Btn).CornerRadius = UDim.new(0,6)

    local StatusDot = Instance.new("Frame", Btn)
    StatusDot.Size = UDim2.new(0,8,0,8)
    StatusDot.Position = UDim2.new(1,-16,0.5,-4)
    StatusDot.BackgroundColor3 = Color3.fromRGB(80,80,80)
    StatusDot.BorderSizePixel = 0
    StatusDot.ZIndex = 22
    Instance.new("UICorner", StatusDot).CornerRadius = UDim.new(1,0)

    return Btn, StatusDot
end

local TorsoBtn, TorsoDot = makeToggleBtn(48, "🎯", "Lock Torso")
local HeadBtn,  HeadDot  = makeToggleBtn(88, "💀", "Lock Head")
local SlineBtn, SlineDot = makeToggleBtn(128, "📡", "Sline ESP")

makeDivider(170)

-- =====================
--   WHITELIST SECTION
-- =====================
local WLLabel = Instance.new("TextLabel", Frame)
WLLabel.Size = UDim2.new(1,-20,0,18)
WLLabel.Position = UDim2.new(0,10,0,176)
WLLabel.BackgroundTransparency = 1
WLLabel.Text = "🛡️ Whitelist Players"
WLLabel.TextColor3 = Color3.fromRGB(200,200,200)
WLLabel.TextXAlignment = Enum.TextXAlignment.Left
WLLabel.TextSize = 11
WLLabel.Font = Enum.Font.GothamBold
WLLabel.ZIndex = 21

-- Scroll frame untuk list player
local ScrollFrame = Instance.new("ScrollingFrame", Frame)
ScrollFrame.Size = UDim2.new(1,-20,0,90)
ScrollFrame.Position = UDim2.new(0,10,0,198)
ScrollFrame.BackgroundColor3 = Color3.fromRGB(20,20,20)
ScrollFrame.BorderSizePixel = 0
ScrollFrame.ScrollBarThickness = 3
ScrollFrame.ScrollBarImageColor3 = Color3.fromRGB(80,80,80)
ScrollFrame.ZIndex = 21
Instance.new("UICorner", ScrollFrame).CornerRadius = UDim.new(0,6)

local UIList = Instance.new("UIListLayout", ScrollFrame)
UIList.SortOrder = Enum.SortOrder.Name
UIList.Padding = UDim.new(0,2)

-- Info target di bawah
makeDivider(295)
local InfoLabel = Instance.new("TextLabel", Frame)
InfoLabel.Size = UDim2.new(1,-20,0,18)
InfoLabel.Position = UDim2.new(0,10,0,300)
InfoLabel.BackgroundTransparency = 1
InfoLabel.Text = "Target: -"
InfoLabel.TextColor3 = Color3.fromRGB(100,100,100)
InfoLabel.TextXAlignment = Enum.TextXAlignment.Left
InfoLabel.TextSize = 10
InfoLabel.Font = Enum.Font.Gotham
InfoLabel.ZIndex = 21

-- Resize frame untuk info label
Frame.Size = UDim2.new(0,210,0,325)

-- =====================
--   FUNGSI PLAYER LIST
-- =====================
local PlayerButtons = {}

local function updatePlayerList()
    -- Bersihkan list lama
    for _, child in pairs(ScrollFrame:GetChildren()) do
        if child:IsA("TextButton") then child:Destroy() end
    end
    PlayerButtons = {}

    local allPlayers = Players:GetPlayers()
    local contentSize = 0

    for _, player in ipairs(allPlayers) do
        if player == LocalPlayer then continue end

        local isWL = Whitelist[player.Name] == true
        local Btn = Instance.new("TextButton", ScrollFrame)
        Btn.Size = UDim2.new(1,-6,0,24)
        Btn.BackgroundColor3 = isWL
            and Color3.fromRGB(30,60,30)
            or  Color3.fromRGB(28,28,28)
        Btn.BorderSizePixel = 0
        Btn.TextXAlignment = Enum.TextXAlignment.Left
        Btn.Text = (isWL and "  🛡️ " or "  👤 ") .. player.Name
        Btn.TextColor3 = isWL
            and Color3.fromRGB(100,220,100)
            or  Color3.fromRGB(180,180,180)
        Btn.TextSize = 11
        Btn.Font = Enum.Font.Gotham
        Btn.ZIndex = 22
        Instance.new("UICorner", Btn).CornerRadius = UDim.new(0,4)

        Btn.MouseButton1Click:Connect(function()
            if Whitelist[player.Name] then
                Whitelist[player.Name] = nil
            else
                Whitelist[player.Name] = true
                -- Batalkan lock kalau target di-whitelist
                if LockedTarget and LockedTarget.Name == player.Name then
                    LockedTarget = nil
                    Settings.LockEnabled = false
                end
            end
            updatePlayerList()
        end)

        PlayerButtons[player.Name] = Btn
        contentSize = contentSize + 26
    end

    ScrollFrame.CanvasSize = UDim2.new(0,0,0,contentSize)
end

-- Auto update list saat player join/leave
Players.PlayerAdded:Connect(function() updatePlayerList() end)
Players.PlayerRemoving:Connect(function() updatePlayerList() end)
updatePlayerList()

-- =====================
--    UPDATE TOMBOL GUI
-- =====================
local function setBtn(btn, dot, on, icon, label)
    if on then
        btn.Text = "  "..icon.." "..label.."  ✓"
        btn.TextColor3 = Color3.fromRGB(255,255,255)
        btn.BackgroundColor3 = Color3.fromRGB(18,18,18)
        dot.BackgroundColor3 = Color3.fromRGB(80,220,80)
    else
        btn.Text = "  "..icon.." "..label
        btn.TextColor3 = Color3.fromRGB(160,160,160)
        btn.BackgroundColor3 = Color3.fromRGB(25,25,25)
        dot.BackgroundColor3 = Color3.fromRGB(80,80,80)
    end
end

local function updateGUI()
    setBtn(TorsoBtn, TorsoDot, Settings.LockEnabled and Settings.LockPart=="Torso", "🎯", "Lock Torso")
    setBtn(HeadBtn,  HeadDot,  Settings.LockEnabled and Settings.LockPart=="Head",  "💀", "Lock Head")
    setBtn(SlineBtn, SlineDot, Settings.SlineEnabled, "📡", "Sline ESP")
end

-- =====================
--    SLINE ESP (FIXED)
-- =====================
local LinePool = {}

local function clearLines()
    for _, f in pairs(LinePool) do
        f.Visible = false
    end
end

local function getLine()
    for _, f in pairs(LinePool) do
        if not f.Visible then
            f.Visible = true
            return f
        end
    end
    -- Buat line baru kalau pool habis
    local f = Instance.new("Frame", SlineFrame)
    f.BackgroundColor3 = Color3.fromRGB(255,60,60)
    f.BorderSizePixel = 0
    f.AnchorPoint = Vector2.new(0.5, 0.5)
    f.ZIndex = 6
    Instance.new("UICorner", f).CornerRadius = UDim.new(1,0)
    table.insert(LinePool, f)
    return f
end

local function drawLine(x1, y1, x2, y2, color, thick)
    thick = thick or 2
    local dx = x2 - x1
    local dy = y2 - y1
    local len = math.sqrt(dx*dx + dy*dy)
    if len < 1 then return end

    local line = getLine()
    line.BackgroundColor3 = color
    line.Size = UDim2.new(0, len, 0, thick)
    line.Position = UDim2.new(0, (x1+x2)/2, 0, (y1+y2)/2)
    line.Rotation = math.deg(math.atan2(dy, dx))
end

local function updateSlines()
    clearLines()
    if not Settings.SlineEnabled then return end

    local myChar = LocalPlayer.Character
    if not myChar then return end
    local myRoot = myChar:FindFirstChild("HumanoidRootPart")
    if not myRoot then return end

    local vp = Camera.ViewportSize
    local sx = vp.X / 2
    local sy = vp.Y -- dari bawah tengah layar

    for _, player in ipairs(Players:GetPlayers()) do
        if player == LocalPlayer then continue end
        if Whitelist[player.Name] then continue end

        local char = player.Character
        if not char then continue end
        local hum = char:FindFirstChildOfClass("Humanoid")
        if not hum or hum.Health <= 0 then continue end

        local root = char:FindFirstChild("HumanoidRootPart")
            or char:FindFirstChild("UpperTorso")
            or char:FindFirstChild("Torso")
        if not root then continue end

        local dist = (root.Position - myRoot.Position).Magnitude
        if dist > Settings.MaxDistance then continue end

        local sp, onScreen = Camera:WorldToScreenPoint(root.Position)
        if not onScreen then continue end

        local color = (LockedTarget == player)
            and Color3.fromRGB(80, 255, 80)
            or  Color3.fromRGB(255, 60, 60)

        drawLine(sx, sy, sp.X, sp.Y, color, 2)
    end
end

-- =====================
--      LOCK LOGIC
-- =====================
local function isEnemy(player)
    if Whitelist[player.Name] then return false end
    if not Settings.TeamCheck then return true end
    if not player.Team or not LocalPlayer.Team then return true end
    return player.Team ~= LocalPlayer.Team
end

local function getLockPart(player)
    local char = player.Character
    if not char then return nil end
    if Settings.LockPart == "Head" then
        return char:FindFirstChild("Head")
    end
    return char:FindFirstChild("HumanoidRootPart")
        or char:FindFirstChild("UpperTorso")
        or char:FindFirstChild("Torso")
end

local function isAlive(player)
    local char = player.Character
    if not char then return false end
    local h = char:FindFirstChildOfClass("Humanoid")
    return h and h.Health > 0
end

local function getNearestTarget()
    local best, bestDist = nil, math.huge
    for _, player in ipairs(Players:GetPlayers()) do
        if player == LocalPlayer then continue end
        if not isEnemy(player) then continue end
        if not isAlive(player) then continue end

        local part = getLockPart(player)
        if not part then continue end

        local myChar = LocalPlayer.Character
        if not myChar then continue end
        local myRoot = myChar:FindFirstChild("HumanoidRootPart")
        if not myRoot then continue end

        if (part.Position - myRoot.Position).Magnitude > Settings.MaxDistance then continue end

        local sp, onScreen = Camera:WorldToScreenPoint(part.Position)
        if not onScreen then continue end

        local sc = Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y/2)
        local sd = (Vector2.new(sp.X, sp.Y) - sc).Magnitude

        if sd < bestDist then
            bestDist = sd
            best = player
        end
    end
    return best
end

-- =====================
--    SMOOTH HEAD LOCK
--    (style Free Fire)
-- =====================
local function lockToTarget()
    if not LockedTarget then return end
    if not isAlive(LockedTarget) then
        LockedTarget = nil
        Settings.LockEnabled = false
        updateGUI()
        InfoLabel.Text = "Target: -"
        return
    end

    local part = getLockPart(LockedTarget)
    if not part then return end

    local myRoot = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if myRoot then
        local dist = math.floor((part.Position - myRoot.Position).Magnitude)
        InfoLabel.Text = "🎯 "..LockedTarget.Name.." | "..dist.." studs"
    end

    local targetPos = part.Position

    -- Kalau Head: tambah offset ke atas agar tidak nempel
    if Settings.LockPart == "Head" then
        local char = LockedTarget.Character
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        local hipHeight = hum and hum.HipHeight or 0
        -- Offset sedikit di atas kepala (tidak nempel)
        targetPos = targetPos + Vector3.new(0, Settings.HeadOffset, 0)
    end

    local currentCFrame = Camera.CFrame
    local direction = (targetPos - currentCFrame.Position).Unit
    local targetCFrame = CFrame.lookAt(currentCFrame.Position, currentCFrame.Position + direction)

    -- Smoothing berbeda untuk head vs torso
    local smooth = Settings.LockPart == "Head"
        and Settings.HeadSmoothing
        or  Settings.LockSmoothing

    Camera.CFrame = currentCFrame:Lerp(targetCFrame, smooth)
end

-- =====================
--       TOGGLE
-- =====================
local function doToggle(part)
    if Settings.LockEnabled and Settings.LockPart == part then
        Settings.LockEnabled = false
        LockedTarget = nil
        InfoLabel.Text = "Target: -"
    else
        Settings.LockPart = part
        Settings.LockEnabled = true
        LockedTarget = getNearestTarget()
        if not LockedTarget then
            Settings.LockEnabled = false
            InfoLabel.Text = "Tidak ada target!"
        end
    end
    updateGUI()
end

TorsoBtn.MouseButton1Click:Connect(function() doToggle("Torso") end)
HeadBtn.MouseButton1Click:Connect(function() doToggle("Head") end)

SlineBtn.MouseButton1Click:Connect(function()
    Settings.SlineEnabled = not Settings.SlineEnabled
    if not Settings.SlineEnabled then clearLines() end
    updateGUI()
end)

UserInputService.InputBegan:Connect(function(input, gpe)
    if gpe then return end
    if input.KeyCode == Enum.KeyCode.E then doToggle("Torso")
    elseif input.KeyCode == Enum.KeyCode.R then doToggle("Head")
    elseif input.KeyCode == Enum.KeyCode.T then
        Settings.SlineEnabled = not Settings.SlineEnabled
        if not Settings.SlineEnabled then clearLines() end
        updateGUI()
    end
end)

-- =====================
--      MAIN LOOP
-- =====================
RunService.RenderStepped:Connect(function()
    if Settings.LockEnabled and LockedTarget then
        lockToTarget()
    end
    updateSlines()
end)

print("[AimbotByPatrul v3.0] E=Torso | R=Head | T=Sline")
