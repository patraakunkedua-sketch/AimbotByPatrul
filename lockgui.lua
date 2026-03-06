-- Lock To Torso + Simple GUI
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

-- Settings
local Settings = {
    LockEnabled = false,
    ToggleKey = Enum.KeyCode.E,
    MaxDistance = 500,
    LockSmoothing = 0.15,
    TeamCheck = true,
}

local LockedTarget = nil

-- =====================
--        GUI
-- =====================
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "LockGUI"
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")

-- Main Frame
local Frame = Instance.new("Frame")
Frame.Size = UDim2.new(0, 180, 0, 90)
Frame.Position = UDim2.new(0, 20, 0.5, -45)
Frame.BackgroundColor3 = Color3.fromRGB(18, 18, 18)
Frame.BorderSizePixel = 0
Frame.Active = true
Frame.Draggable = true
Frame.Parent = ScreenGui

-- Corner
local Corner = Instance.new("UICorner")
Corner.CornerRadius = UDim.new(0, 8)
Corner.Parent = Frame

-- Stroke border tipis
local Stroke = Instance.new("UIStroke")
Stroke.Color = Color3.fromRGB(60, 60, 60)
Stroke.Thickness = 1
Stroke.Parent = Frame

-- Title
local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, 0, 0, 30)
Title.Position = UDim2.new(0, 0, 0, 0)
Title.BackgroundTransparency = 1
Title.Text = "🎯 AimBot"
Title.TextColor3 = Color3.fromRGB(255, 255, 255)
Title.TextSize = 13
Title.Font = Enum.Font.GothamBold
Title.Parent = Frame

-- Divider
local Divider = Instance.new("Frame")
Divider.Size = UDim2.new(1, -20, 0, 1)
Divider.Position = UDim2.new(0, 10, 0, 30)
Divider.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
Divider.BorderSizePixel = 0
Divider.Parent = Frame

-- Toggle Button
local ToggleBtn = Instance.new("TextButton")
ToggleBtn.Size = UDim2.new(1, -20, 0, 32)
ToggleBtn.Position = UDim2.new(0, 10, 0, 40)
ToggleBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
ToggleBtn.BorderSizePixel = 0
ToggleBtn.Text = "Lock  OFF"
ToggleBtn.TextColor3 = Color3.fromRGB(180, 180, 180)
ToggleBtn.TextSize = 13
ToggleBtn.Font = Enum.Font.GothamSemibold
ToggleBtn.Parent = Frame

local BtnCorner = Instance.new("UICorner")
BtnCorner.CornerRadius = UDim.new(0, 6)
BtnCorner.Parent = ToggleBtn

-- Status dot (bulat kecil di kiri button)
local Dot = Instance.new("Frame")
Dot.Size = UDim2.new(0, 8, 0, 8)
Dot.Position = UDim2.new(0, 12, 0.5, -4)
Dot.BackgroundColor3 = Color3.fromRGB(120, 120, 120)
Dot.BorderSizePixel = 0
Dot.Parent = ToggleBtn

local DotCorner = Instance.new("UICorner")
DotCorner.CornerRadius = UDim.new(1, 0)
DotCorner.Parent = Dot

-- =====================
--    UPDATE GUI STATE
-- =====================
local function updateGUI()
    if Settings.LockEnabled then
        ToggleBtn.Text = "Lock  ON"
        ToggleBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
        ToggleBtn.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
        Dot.BackgroundColor3 = Color3.fromRGB(100, 220, 100) -- hijau
    else
        ToggleBtn.Text = "Lock  OFF"
        ToggleBtn.TextColor3 = Color3.fromRGB(180, 180, 180)
        ToggleBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
        Dot.BackgroundColor3 = Color3.fromRGB(120, 120, 120) -- abu
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

local function getTorso(player)
    local char = player.Character
    if not char then return nil end
    return char:FindFirstChild("HumanoidRootPart")
        or char:FindFirstChild("Torso")
        or char:FindFirstChild("UpperTorso")
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

        local torso = getTorso(player)
        if not torso then continue end

        local myChar = LocalPlayer.Character
        if not myChar then continue end
        local myRoot = myChar:FindFirstChild("HumanoidRootPart")
        if not myRoot then continue end

        local worldDist = (torso.Position - myRoot.Position).Magnitude
        if worldDist > Settings.MaxDistance then continue end

        local screenPos, onScreen = Camera:WorldToScreenPoint(torso.Position)
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
        return
    end

    local torso = getTorso(LockedTarget)
    if not torso then
        LockedTarget = nil
        Settings.LockEnabled = false
        updateGUI()
        return
    end

    local targetPos = torso.Position
    local currentCFrame = Camera.CFrame
    local direction = (targetPos - currentCFrame.Position).Unit
    local targetCFrame = CFrame.lookAt(currentCFrame.Position, currentCFrame.Position + direction)
    Camera.CFrame = currentCFrame:Lerp(targetCFrame, 1 - Settings.LockSmoothing)
end

-- =====================
--      TOGGLE AKSI
-- =====================
local function doToggle()
    Settings.LockEnabled = not Settings.LockEnabled

    if Settings.LockEnabled then
        LockedTarget = getNearestTarget()
        if not LockedTarget then
            Settings.LockEnabled = false
        end
    else
        LockedTarget = nil
    end

    updateGUI()
end

-- Klik tombol GUI
ToggleBtn.MouseButton1Click:Connect(doToggle)

-- Tekan keyboard (E)
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if input.KeyCode == Settings.ToggleKey then
        doToggle()
    end
end)

-- Loop utama
RunService.RenderStepped:Connect(function()
    if Settings.LockEnabled and LockedTarget then
        lockToTarget()
    end
end)

print("[Lock GUI] Aktif | Klik tombol atau tekan E")
```

---

## 🖥️ Tampilan GUI
```
┌──────────────────────┐
│  🎯 Lock To Torso    │
│ ──────────────────── │
│  ● Lock  OFF         │
└──────────────────────┘

