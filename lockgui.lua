-- Lock To Torso/Head + Sline ESP (Fixed CoreGui)
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local CoreGui = game:GetService("CoreGui")

local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

local Settings = {
    LockEnabled = false,
    LockPart = "Torso",      -- "Torso" atau "Head"
    SlineEnabled = false,
    ToggleKey = Enum.KeyCode.E,
    MaxDistance = 500,
    LockSmoothing = 0.15,
    TeamCheck = true,
}

local LockedTarget = nil

-- =====================
--        GUI
-- =====================
if CoreGui:FindFirstChild("LockGUI") then
    CoreGui:FindFirstChild("LockGUI"):Destroy()
end

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "LockGUI"
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

local ok = pcall(function() ScreenGui.Parent = CoreGui end)
if not ok then ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui") end

-- Sline Canvas (gambar garis di atas semua UI)
local SlineCanvas = Instance.new("Frame")
SlineCanvas.Name = "SlineCanvas"
SlineCanvas.Size = UDim2.new(1, 0, 1, 0)
SlineCanvas.BackgroundTransparency = 1
SlineCanvas.ZIndex = 1
SlineCanvas.Parent = ScreenGui

-- Main Frame
local Frame = Instance.new("Frame")
Frame.Size = UDim2.new(0, 190, 0, 195)
Frame.Position = UDim2.new(0, 20, 0.5, -97)
Frame.BackgroundColor3 = Color3.fromRGB(18, 18, 18)
Frame.BorderSizePixel = 0
Frame.Active = true
Frame.Draggable = true
Frame.ZIndex = 2
Frame.Parent = ScreenGui

Instance.new("UICorner", Frame).CornerRadius = UDim.new(0, 8)
local Stroke = Instance.new("UIStroke", Frame)
Stroke.Color = Color3.fromRGB(60, 60, 60)
Stroke.Thickness = 1

-- Title
local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, 0, 0, 30)
Title.BackgroundTransparency = 1
Title.Text = "🎯 AimbotByPatrul"
Title.TextColor3 = Color3.fromRGB(255, 255, 255)
Title.TextSize = 13
Title.Font = Enum.Font.GothamBold
Title.ZIndex = 3
Title.Parent = Frame

-- Divider
local Divider = Instance.new("Frame")
Divider.Size = UDim2.new(1, -20, 0, 1)
Divider.Position = UDim2.new(0, 10, 0, 30)
Divider.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
Divider.BorderSizePixel = 0
Divider.ZIndex = 3
Divider.Parent = Frame

-- Fungsi buat tombol
local function makeButton(yPos, labelText)
    local Btn = Instance.new("TextButton")
    Btn.Size = UDim2.new(1, -20, 0, 32)
    Btn.Position = UDim2.new(0, 10, 0, yPos)
    Btn.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    Btn.BorderSizePixel = 0
    Btn.Text = labelText .. "  OFF"
    Btn.TextColor3 = Color3.fromRGB(180, 180, 180)
    Btn.TextSize = 12
    Btn.Font = Enum.Font.GothamSemibold
    Btn.ZIndex = 3
    Btn.Parent = Frame
    Instance.new("UICorner", Btn).CornerRadius = UDim.new(0, 6)

    local Dot = Instance.new("Frame")
    Dot.Size = UDim2.new(0, 8, 0, 8)
    Dot.Position = UDim2.new(0, 12, 0.5, -4)
    Dot.BackgroundColor3 = Color3.fromRGB(120, 120, 120)
    Dot.BorderSizePixel = 0
    Dot.ZIndex = 4
    Dot.Parent = Btn
    Instance.new("UICorner", Dot).CornerRadius = UDim.new(1, 0)

    return Btn, Dot
end

-- Tombol Lock Torso
local TorsoBtn, TorsoDot = makeButton(40, "🎯 Lock Torso")

-- Tombol Lock Head
local HeadBtn, HeadDot = makeButton(82, "💀 Lock Head")

-- Tombol Sline
local SlineBtn, SlineDot = makeButton(124, "📡 Sline ESP")

-- Label info target
local InfoLabel = Instance.new("TextLabel")
InfoLabel.Size = UDim2.new(1, -20, 0, 20)
InfoLabel.Position = UDim2.new(0, 10, 0, 168)
InfoLabel.BackgroundTransparency = 1
InfoLabel.Text = "Target: -"
InfoLabel.TextColor3 = Color3.fromRGB(130, 130, 130)
InfoLabel.TextSize = 11
InfoLabel.Font = Enum.Font.Gotham
InfoLabel.ZIndex = 3
InfoLabel.Parent = Frame

-- =====================
--    UPDATE GUI
-- =====================
local function updateBtn(btn, dot, state, label)
    if state then
        btn.Text = label .. "  ON"
        btn.TextColor3 = Color3.fromRGB(255, 255, 255)
        btn.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
        dot.BackgroundColor3 = Color3.fromRGB(100, 220, 100)
    else
        btn.Text = label .. "  OFF"
        btn.TextColor3 = Color3.fromRGB(180, 180, 180)
        btn.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
        dot.BackgroundColor3 = Color3.fromRGB(120, 120, 120)
    end
end

local function updateGUI()
    updateBtn(TorsoBtn, TorsoDot, Settings.LockEnabled and Settings.LockPart == "Torso", "🎯 Lock Torso")
    updateBtn(HeadBtn, HeadDot, Settings.LockEnabled and Settings.LockPart == "Head", "💀 Lock Head")
    updateBtn(SlineBtn, SlineDot, Settings.SlineEnabled, "📡 Sline ESP")
end

-- =====================
--    SLINE (GARIS ESP)
-- =====================
local SlineLines = {}

local function clearLines()
    for _, line in pairs(SlineLines) do
        line:Destroy()
    end
    SlineLines = {}
end

local function drawLine(from2D, to2D, color)
    local line = Instance.new("Frame")
    line.BackgroundColor3 = color or Color3.fromRGB(255, 50, 50)
    line.BorderSizePixel = 0
    line.ZIndex = 2
    line.Parent = SlineCanvas

    local dx = to2D.X - from2D.X
    local dy = to2D.Y - from2D.Y
    local length = math.sqrt(dx * dx + dy * dy)
    local angle = math.atan2(dy, dx)

    line.Size = UDim2.new(0, length, 0, 2)
    line.Position = UDim2.new(0, from2D.X, 0, from2D.Y - 1)
    line.Rotation = math.deg(angle)

    Instance.new("UICorner", line).CornerRadius = UDim.new(1, 0)

    table.insert(SlineLines, line)
end

local function updateSlines()
    clearLines()
    if not Settings.SlineEnabled then return end

    local myChar = LocalPlayer.Character
    if not myChar then return end
    local myRoot = myChar:FindFirstChild("HumanoidRootPart")
    if not myRoot then return end

    -- Titik awal = bawah tengah layar
    local screenCenter = Vector2.new(
        Camera.ViewportSize.X / 2,
        Camera.ViewportSize.Y  -- bawah layar
    )

    for _, player in ipairs(Players:GetPlayers()) do
        if player == LocalPlayer then continue end

        local char = player.Character
        if not char then continue end

        local hum = char:FindFirstChildOfClass("Humanoid")
        if not hum or hum.Health <= 0 then continue end

        local torso = char:FindFirstChild("HumanoidRootPart")
            or char:FindFirstChild("Torso")
            or char:FindFirstChild("UpperTorso")
        if not torso then continue end

        local dist = (torso.Position - myRoot.Position).Magnitude
        if dist > Settings.MaxDistance then continue end

        local screenPos, onScreen = Camera:WorldToScreenPoint(torso.Position)
        if not onScreen then continue end

        local targetPos2D = Vector2.new(screenPos.X, screenPos.Y)

        -- Warna: merah kalau locked, putih kalau tidak
        local color = Color3.fromRGB(200, 200, 200)
        if LockedTarget == player then
            color = Color3.fromRGB(100, 220, 100)
        end

        drawLine(screenCenter, targetPos2D, color)
    end
end

-- =====================
--      LOCK LOGIC
-- =====================
local function isEnemy(player)
    if not Settings.TeamCheck then return true end
    if player.Team == nil or LocalPlayer.Team == nil then return true end
    return player.Team ~= LocalPlayer.Team
end

local function getLockPart(player)
    local char = player.Character
    if not char then return nil end
    if Settings.LockPart == "Head" then
        return char:FindFirstChild("Head")
    else
        return char:FindFirstChild("HumanoidRootPart")
            or char:FindFirstChild("Torso")
            or char:FindFirstChild("UpperTorso")
    end
end

local function isAlive(player)
    local char = player.Character
    if not char then return false end
    local hum = char:FindFirstChildOfClass("Humanoid")
    return hum and hum.Health > 0
end

local function getNearestTarget()
    local closestPlayer = nil
    local closestDistance = math.huge

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

        local worldDist = (part.Position - myRoot.Position).Magnitude
        if worldDist > Settings.MaxDistance then continue end

        local screenPos, onScreen = Camera:WorldToScreenPoint(part.Position)
        if not onScreen then continue end

        local screenCenter = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
        local screenDist = (Vector2.new(screenPos.X, screenPos.Y) - screenCenter).Magnitude

        if screenDist < closestDistance then
            closestDistance = screenDist
            closestPlayer = player
        end
    end

    return closestPlayer
end

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
    if not part then
        LockedTarget = nil
        Settings.LockEnabled = false
        updateGUI()
        InfoLabel.Text = "Target: -"
        return
    end

    -- Update info label
    local myRoot = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if myRoot then
        local dist = math.floor((part.Position - myRoot.Position).Magnitude)
        InfoLabel.Text = "Target: " .. LockedTarget.Name .. " (" .. dist .. "m)"
    end

    local targetPos = part.Position
    local currentCFrame = Camera.CFrame
    local direction = (targetPos - currentCFrame.Position).Unit
    local targetCFrame = CFrame.lookAt(currentCFrame.Position, currentCFrame.Position + direction)
    Camera.CFrame = currentCFrame:Lerp(targetCFrame, 1 - Settings.LockSmoothing)
end

-- =====================
--      TOGGLE
-- =====================
local function doLockToggle(part)
    if Settings.LockEnabled and Settings.LockPart == part then
        -- Matikan lock
        Settings.LockEnabled = false
        LockedTarget = nil
        InfoLabel.Text = "Target: -"
    else
        -- Aktifkan lock dengan part yang dipilih
        Settings.LockPart = part
        Settings.LockEnabled = true
        LockedTarget = getNearestTarget()
        if not LockedTarget then
            Settings.LockEnabled = false
            InfoLabel.Text = "Target: -"
        end
    end
    updateGUI()
end

TorsoBtn.MouseButton1Click:Connect(function() doLockToggle("Torso") end)
HeadBtn.MouseButton1Click:Connect(function() doLockToggle("Head") end)

SlineBtn.MouseButton1Click:Connect(function()
    Settings.SlineEnabled = not Settings.SlineEnabled
    if not Settings.SlineEnabled then clearLines() end
    updateGUI()
end)

-- Keyboard toggle (E = Torso, R = Head, T = Sline)
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if input.KeyCode == Enum.KeyCode.E then
        doLockToggle("Torso")
    elseif input.KeyCode == Enum.KeyCode.R then
        doLockToggle("Head")
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

print("[AimbotByPatrul] Loaded! E=Torso | R=Head | T=Sline")
