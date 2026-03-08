-- ======================================================
--   JAWA HUB - AUTO MARSHMALLOW
--   Letakkan di: StarterPlayer > StarterPlayerScripts
--   Tipe: LocalScript
--   UPDATE: Ambil Marshmallow pakai Tas Kosong
-- ======================================================

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local VIM = game:GetService("VirtualInputManager")
local UIS = game:GetService("UserInputService")

local player = Players.LocalPlayer
local playerGui = player.PlayerGui
local character = player.Character or player.CharacterAdded:Wait()
local hrp = character:WaitForChild("HumanoidRootPart")

-- ========================
-- KONFIGURASI
-- ========================
local CONFIG = {
	WATER_WAIT = 20,
	COOK_WAIT  = 46,
}

local ITEM_WATER = "Water"
local ITEM_SUGAR = "Sugar Block Bag"
local ITEM_GEL   = "Gelatin"
local ITEM_EMPTY = "Empty Bag"

-- ========================
-- STATE
-- ========================
local isRunning = false
local isCooking = false
local stats = { totalMS = 0, small = 0, medium = 0, large = 0 }

-- ========================
-- SIMULASI TEKAN E
-- ========================
local function pressE()

	local ok1 = pcall(function()
		VIM:SendKeyEvent(true,Enum.KeyCode.E,false,game)
		task.wait(0.1)
		VIM:SendKeyEvent(false,Enum.KeyCode.E,false,game)
	end)

	if not ok1 then
		for _, obj in ipairs(workspace:GetDescendants()) do
			if obj:IsA("ProximityPrompt") then
				local part = obj.Parent
				if part and part:IsA("BasePart") then
					local dist = (hrp.Position - part.Position).Magnitude
					if dist <= (obj.MaxActivationDistance or 10) then
						pcall(function()
							fireproximityprompt(obj)
						end)
					end
				end
			end
		end
	end

end

-- ========================
-- HELPER INVENTORY
-- ========================
local function countItem(name)

	local n = 0

	for _, t in ipairs(player.Backpack:GetChildren()) do
		if t.Name == name then
			n += 1
		end
	end

	local char = player.Character

	if char then
		for _, t in ipairs(char:GetChildren()) do
			if t:IsA("Tool") and t.Name == name then
				n += 1
			end
		end
	end

	return n

end

local function equipTool(name)

	local char = player.Character
	if not char then return false end

	local hum = char:FindFirstChildOfClass("Humanoid")
	local t = player.Backpack:FindFirstChild(name)

	if hum and t then
		hum:EquipTool(t)
		task.wait(0.3)
		return true
	end

	return false

end

local function unequipAll()

	local char = player.Character
	if not char then return end

	local hum = char:FindFirstChildOfClass("Humanoid")

	if hum then
		hum:UnequipTools()
	end

end

local function hasAllIngredients()

	return countItem(ITEM_WATER) >= 1
		and countItem(ITEM_SUGAR) >= 1
		and countItem(ITEM_GEL)   >= 1

end

-- ========================
-- TUNGGU TAS KOSONG
-- ========================
local function waitForEmptyBag(timeout)

	local t = 0

	while t < timeout do

		if player.Backpack:FindFirstChild(ITEM_EMPTY) then
			return true
		end

		task.wait(0.5)
		t += 0.5

	end

	return false

end

-- ========================
-- GUI
-- ========================
if playerGui:FindFirstChild("JawaHubGUI") then
	playerGui.JawaHubGUI:Destroy()
end

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "JawaHubGUI"
screenGui.ResetOnSpawn = false
screenGui.IgnoreGuiInset = true
screenGui.Parent = playerGui

local panel = Instance.new("Frame")
panel.Size = UDim2.new(0, 230, 0, 310)
panel.Position = UDim2.new(0, 14, 0.5, -155)
panel.BackgroundColor3 = Color3.fromRGB(24, 24, 36)
panel.BorderSizePixel = 0
panel.Parent = screenGui
Instance.new("UICorner", panel).CornerRadius = UDim.new(0, 14)

Instance.new("UIStroke", panel).Color = Color3.fromRGB(60, 60, 90)

local header = Instance.new("Frame")
header.Size = UDim2.new(1, 0, 0, 44)
header.BackgroundColor3 = Color3.fromRGB(30, 30, 46)
header.BorderSizePixel = 0
header.Parent = panel
Instance.new("UICorner", header).CornerRadius = UDim.new(0, 14)

local headerLabel = Instance.new("TextLabel")
headerLabel.Size = UDim2.new(1, 0, 1, 0)
headerLabel.BackgroundTransparency = 1
headerLabel.Text = "DSR Auto Marshmallow"
headerLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
headerLabel.TextScaled = true
headerLabel.Font = Enum.Font.GothamBold
headerLabel.Parent = header

local sisaMS = Instance.new("TextLabel")
sisaMS.Size = UDim2.new(1, 0, 0, 26)
sisaMS.Position = UDim2.new(0, 0, 0, 48)
sisaMS.BackgroundTransparency = 1
sisaMS.Text = "MS SELESAI: 0"
sisaMS.TextColor3 = Color3.fromRGB(80, 220, 255)
sisaMS.TextScaled = true
sisaMS.Font = Enum.Font.GothamBold
sisaMS.Parent = panel

local function makeDivider(posY)
	local d = Instance.new("Frame")
	d.Size = UDim2.new(1, -20, 0, 1)
	d.Position = UDim2.new(0, 10, 0, posY)
	d.BackgroundColor3 = Color3.fromRGB(60, 60, 80)
	d.BorderSizePixel = 0
	d.Parent = panel
end

local function makeLabel(text, posY, color)
	local lbl = Instance.new("TextLabel")
	lbl.Size = UDim2.new(1, -20, 0, 22)
	lbl.Position = UDim2.new(0, 14, 0, posY)
	lbl.BackgroundTransparency = 1
	lbl.Text = text
	lbl.TextColor3 = color or Color3.fromRGB(200, 200, 200)
	lbl.TextXAlignment = Enum.TextXAlignment.Left
	lbl.TextScaled = true
	lbl.Font = Enum.Font.Gotham
	lbl.Parent = panel
	return lbl
end

makeDivider(78)
makeLabel("MS Sudah Jadi:", 82, Color3.fromRGB(200, 200, 200))
local lblSmall  = makeLabel("Small: 0",  104)
local lblMedium = makeLabel("Medium: 0", 126)
local lblLarge  = makeLabel("Large: 0",  148)
makeDivider(174)
local lblWater   = makeLabel("Water: 0",           180)
local lblSugar   = makeLabel("Sugar Block Bag: 0", 202)
local lblGelatin = makeLabel("Gelatin: 0",          224)

local lblStatus = Instance.new("TextLabel")
lblStatus.Size = UDim2.new(1, -10, 0, 20)
lblStatus.Position = UDim2.new(0, 5, 0, 248)
lblStatus.BackgroundTransparency = 1
lblStatus.Text = ""
lblStatus.TextColor3 = Color3.fromRGB(255, 210, 80)
lblStatus.TextScaled = true
lblStatus.Font = Enum.Font.Gotham
lblStatus.TextXAlignment = Enum.TextXAlignment.Center
lblStatus.Parent = panel

local btnFrame = Instance.new("Frame")
btnFrame.Size = UDim2.new(1, -20, 0, 44)
btnFrame.Position = UDim2.new(0, 10, 0, 258)
btnFrame.BackgroundColor3 = Color3.fromRGB(40, 185, 80)
btnFrame.BorderSizePixel = 0
btnFrame.Parent = panel
Instance.new("UICorner", btnFrame).CornerRadius = UDim.new(0, 10)

local btnButton = Instance.new("TextButton")
btnButton.Size = UDim2.new(1, 0, 1, 0)
btnButton.BackgroundTransparency = 1
btnButton.Text = "Start AutoMS"
btnButton.TextColor3 = Color3.fromRGB(255, 255, 255)
btnButton.TextScaled = true
btnButton.Font = Enum.Font.GothamBold
btnButton.Parent = btnFrame


-- ========================
-- DRAG GUI
-- ========================
local dragging = false
local dragInput
local dragStart
local startPos

local function update(input)
	local delta = input.Position - dragStart
	panel.Position = UDim2.new(
		startPos.X.Scale,
		startPos.X.Offset + delta.X,
		startPos.Y.Scale,
		startPos.Y.Offset + delta.Y
	)
end

header.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 
	or input.UserInputType == Enum.UserInputType.Touch then
		
		dragging = true
		dragStart = input.Position
		startPos = panel.Position
		
		input.Changed:Connect(function()
			if input.UserInputState == Enum.UserInputState.End then
				dragging = false
			end
		end)
	end
end)

header.InputChanged:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseMovement 
	or input.UserInputType == Enum.UserInputType.Touch then
		dragInput = input
	end
end)

UIS.InputChanged:Connect(function(input)
	if input == dragInput and dragging then
		update(input)
	end
end)

-- ========================
-- DISPLAY
-- ========================
local function updateDisplay()

	local w = countItem(ITEM_WATER)
	local s = countItem(ITEM_SUGAR)
	local g = countItem(ITEM_GEL)

	lblWater.Text = "Water: "..w
	lblSugar.Text = "Sugar Block Bag: "..s
	lblGelatin.Text = "Gelatin: "..g

	lblSmall.Text = "Small: "..stats.small
	lblMedium.Text = "Medium: "..stats.medium
	lblLarge.Text = "Large: "..stats.large

	sisaMS.Text = "Sisa MS: "..stats.totalMS

end

local function setStatus(msg,color)

	lblStatus.Text = msg
	lblStatus.TextColor3 = color or Color3.fromRGB(255,210,80)

end

local function countdown(secs,fmt,color)

	for i = secs,1,-1 do

		if not isRunning then
			return false
		end

		setStatus(string.format(fmt,i),color)

		task.wait(1)

	end

	return true

end

-- ========================
-- MASAK
-- ========================
local function doOneCook()
	isCooking = true

	-- STEP 1: Water
	setStatus("💧 Menggunakan Water...", Color3.fromRGB(100, 180, 255))
	equipTool(ITEM_WATER)
	task.wait(0.5)
	pressE()
	task.wait(0.7)

	local ok = countdown(CONFIG.WATER_WAIT, "💧 Air mendidih... ⏱ %ds", Color3.fromRGB(100, 180, 255))
	if not ok then isCooking = false return end


	-- STEP 2: Sugar
	setStatus("🧂 Menggunakan Sugar Block Bag...", Color3.fromRGB(255, 220, 100))
	equipTool(ITEM_SUGAR)
	task.wait(0.6)
	pressE()

	-- tunggu proses sugar selesai
	task.wait(2)


	-- STEP 3: Gelatin
	setStatus("🟡 Menggunakan Gelatin...", Color3.fromRGB(255, 200, 50))
	equipTool(ITEM_GEL)
	task.wait(0.6)
	pressE()

	task.wait(1)


	-- STEP 4: Masak
	ok = countdown(CONFIG.COOK_WAIT, "🔥 Memasak... ⏱ %ds", Color3.fromRGB(255, 130, 50))
	if not ok then isCooking = false return end


	-- STEP 5: Tunggu Empty Bag
	setStatus("🎒 Menunggu Tas Kosong...", Color3.fromRGB(180,255,180))

	local bag
	local timeout = 0

	repeat
		bag = player.Backpack:FindFirstChild("Empty Bag")
		task.wait(0.5)
		timeout += 0.5
	until bag or timeout > 10

	if bag then

		setStatus("🎒 Mengambil Marshmallow...", Color3.fromRGB(180,255,180))

		equipTool("Empty Bag")
		task.wait(0.6)

		pressE()
		task.wait(1)

		stats.totalMS += 1
		stats.small += 1

		setStatus("🎉 Marshmallow ke-"..stats.totalMS.." selesai!", Color3.fromRGB(100,255,130))

	else

		setStatus("❌ Tas kosong tidak ditemukan!", Color3.fromRGB(255,90,90))

	end

	task.wait(1.5)

	isCooking = false
end

-- ========================
-- LOOP
-- ========================
local function autoLoop()

	while isRunning do

		if not hasAllIngredients() then

			setStatus("❌ Bahan habis! Berhenti.",Color3.fromRGB(255,90,90))

			task.wait(1)

			isRunning = false

			break

		end

		doOneCook()

		if isRunning then
			task.wait(0.5)
		end

	end

	btnFrame.BackgroundColor3 = Color3.fromRGB(40,185,80)
	btnButton.Text = "Start AutoMS"

	setStatus("")

	isCooking = false

end

-- ========================
-- BUTTON
-- ========================
btnButton.MouseButton1Click:Connect(function()

	if isRunning then

		isRunning = false
		isCooking = false

		btnFrame.BackgroundColor3 = Color3.fromRGB(40,185,80)
		btnButton.Text = "Start AutoMS"

		setStatus("")

	else

		if not hasAllIngredients() then
			setStatus("❌ Bahan tidak lengkap!",Color3.fromRGB(255,90,90))
			task.wait(2)
			setStatus("")
			return
		end

		isRunning = true

		btnFrame.BackgroundColor3 = Color3.fromRGB(200,60,60)
		btnButton.Text = "Stop AutoMS"

		task.spawn(autoLoop)

	end

end)

RunService.Heartbeat:Connect(updateDisplay)

player.CharacterAdded:Connect(function(char)

	character = char
	hrp = char:WaitForChild("HumanoidRootPart")

end)

print("[JawaHub AutoMS] Aktif! Empty Bag Enabled")




PERBAIKI AGAR KETIKA DI INVENTORY MARSMELLOW YANG SUDAH JADINYA DAN KETIKA SUDAH TIDAK ADA DI INVENTORY MAKA DI MARSMELLOW SUDAH JADI ITU DIA JADI GADA , DAN JUGA BUATKAN AGAR LEBIH RAPIH LAGI GUI NYA TANPA MERUSAK ATAU MENJADI TIDAK BISA DI PAKAI
