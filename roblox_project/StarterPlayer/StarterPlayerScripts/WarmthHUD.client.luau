--[[
    WarmthHUD.client.luau
    Клиентский интерфейс (HUD):
    - Шкалы: 🔥 Тепло, 🍗 Сытость, ❤️ Здоровье, ⚡ Выносливость
    - Верхняя панель: Цикл перерождения, Уровень одежды, Вместимость рюкзака, 🏹 Сумка боеприпасов (🪨 X | 💥 Y)
    - Панель дистанций до ключевых точек (Дом, Продуктовый, Одежда, Алтарь, Бункер)
    - Горячие клавиши: G (выбросить предмет), F (покормить питомца), T (режим питомца), 1..9 (хотбар)
--]]

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- Создание ScreenGui
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "SurviveTheColdHUD"
screenGui.ResetOnSpawn = false
screenGui.Parent = playerGui

-- 1. Верхняя панель квеста и боеприпасов (Quest Bar)
local questBar = Instance.new("Frame")
questBar.Name = "QuestBar"
questBar.Size = UDim2.new(0, 680, 0, 36)
questBar.Position = UDim2.new(0.5, -340, 0, 16)
questBar.BackgroundColor3 = Color3.fromRGB(15, 23, 42)
questBar.BackgroundTransparency = 0.2
questBar.BorderSizePixel = 0
questBar.Parent = screenGui

local qbCorner = Instance.new("UICorner", questBar)
qbCorner.CornerRadius = UDim.new(0, 10)

local questLabel = Instance.new("TextLabel")
questLabel.Size = UDim2.new(1, -20, 1, 0)
questLabel.Position = UDim2.new(0, 10, 0, 0)
questLabel.BackgroundTransparency = 1
questLabel.Font = Enum.Font.GothamBold
questLabel.TextSize = 13
questLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
questLabel.Text = "👑 Цикл: #0 | 🎒 5 слотов | 🧥 Lvl 0 | 🏹 Боеприпасы: 🪨 0 | 💥 0 | 🗿 Алтарь: 0/7"
questLabel.Parent = questBar

-- 2. Нижняя панель статусов (Тепло, Сытость, Здоровье, Стамина)
local statusBar = Instance.new("Frame")
statusBar.Name = "StatusBar"
statusBar.Size = UDim2.new(0, 640, 0, 48)
statusBar.Position = UDim2.new(0.5, -320, 1, -64)
statusBar.BackgroundColor3 = Color3.fromRGB(15, 23, 42)
statusBar.BackgroundTransparency = 0.2
statusBar.BorderSizePixel = 0
statusBar.Parent = screenGui

local sbCorner = Instance.new("UICorner", statusBar)
sbCorner.CornerRadius = UDim.new(0, 12)

local statusLayout = Instance.new("UIListLayout", statusBar)
statusLayout.FillDirection = Enum.FillDirection.Horizontal
statusLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
statusLayout.VerticalAlignment = Enum.VerticalAlignment.Center
statusLayout.Padding = UDim.new(0, 16)

local function createBarGroup(name, labelText, color)
	local group = Instance.new("Frame")
	group.Name = name
	group.Size = UDim2.new(0, 135, 0, 32)
	group.BackgroundTransparency = 1
	group.Parent = statusBar

	local title = Instance.new("TextLabel")
	title.Size = UDim2.new(1, 0, 0, 14)
	title.BackgroundTransparency = 1
	title.Font = Enum.Font.GothamBold
	title.TextSize = 10
	title.TextColor3 = Color3.fromRGB(203, 213, 225)
	title.Text = labelText .. ": 100%"
	title.Parent = group

	local barBg = Instance.new("Frame")
	barBg.Size = UDim2.new(1, 0, 0, 8)
	barBg.Position = UDim2.new(0, 0, 0, 18)
	barBg.BackgroundColor3 = Color3.fromRGB(30, 41, 59)
	barBg.BorderSizePixel = 0
	barBg.Parent = group
	Instance.new("UICorner", barBg).CornerRadius = UDim.new(0, 4)

	local barFill = Instance.new("Frame")
	barFill.Name = "Fill"
	barFill.Size = UDim2.new(1, 0, 1, 0)
	barFill.BackgroundColor3 = color
	barFill.BorderSizePixel = 0
	barFill.Parent = barBg
	Instance.new("UICorner", barFill).CornerRadius = UDim.new(0, 4)

	return title, barFill
end

local warmthTitle, warmthFill = createBarGroup("WarmthGroup", "🔥 Тепло", Color3.fromRGB(249, 115, 22))
local hungerTitle, hungerFill = createBarGroup("HungerGroup", "🍗 Сытость", Color3.fromRGB(234, 179, 8))
local healthTitle, healthFill = createBarGroup("HealthGroup", "❤️ Здоровье", Color3.fromRGB(239, 68, 68))
local staminaTitle, staminaFill = createBarGroup("StaminaGroup", "⚡ Бег", Color3.fromRGB(56, 189, 248))

-- 3. Кнопка вызова Гайда (❓ Обучение & Гайд)
local guideBtn = Instance.new("TextButton")
guideBtn.Name = "GuideButton"
guideBtn.Size = UDim2.new(0, 150, 0, 32)
guideBtn.Position = UDim2.new(0, 20, 0, 20)
guideBtn.BackgroundColor3 = Color3.fromRGB(15, 23, 42)
guideBtn.BackgroundTransparency = 0.2
guideBtn.Font = Enum.Font.GothamBold
guideBtn.TextSize = 12
guideBtn.TextColor3 = Color3.fromRGB(56, 189, 248)
guideBtn.Text = "❓ Обучение & Гайд"
guideBtn.Parent = screenGui

local gbCorner = Instance.new("UICorner", guideBtn)
gbCorner.CornerRadius = UDim.new(0, 8)

guideBtn.MouseButton1Click:Connect(function()
	local guideGui = playerGui:FindFirstChild("WelcomeGuideGui")
	if guideGui then
		local frame = guideGui:FindFirstChild("MainFrame")
		if frame then frame.Visible = not frame.Visible end
	end
end)

-- 4. Панель дистанций (Waypoints HUD)
local waypointsFrame = Instance.new("Frame")
waypointsFrame.Name = "WaypointsFrame"
waypointsFrame.Size = UDim2.new(0, 180, 0, 130)
waypointsFrame.Position = UDim2.new(0, 20, 0, 60)
waypointsFrame.BackgroundColor3 = Color3.fromRGB(15, 23, 42)
waypointsFrame.BackgroundTransparency = 0.3
waypointsFrame.BorderSizePixel = 0
waypointsFrame.Parent = screenGui
Instance.new("UICorner", waypointsFrame).CornerRadius = UDim.new(0, 8)

local wpLayout = Instance.new("UIListLayout", waypointsFrame)
wpLayout.Padding = UDim.new(0, 4)
wpLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
wpLayout.VerticalAlignment = Enum.VerticalAlignment.Center

local function createWpLabel(text, color)
	local lbl = Instance.new("TextLabel")
	lbl.Size = UDim2.new(1, -16, 0, 18)
	lbl.BackgroundTransparency = 1
	lbl.Font = Enum.Font.GothamBold
	lbl.TextSize = 11
	lbl.TextColor3 = color
	lbl.TextXAlignment = Enum.TextXAlignment.Left
	lbl.Text = text
	lbl.Parent = waypointsFrame
	return lbl
end

local wpFood = createWpLabel("🥫 Продуктовый: 400 studs", Color3.fromRGB(74, 222, 128))
local wpShop = createWpLabel("🏪 Одежда: 700 studs", Color3.fromRGB(56, 189, 248))
local wpAltar = createWpLabel("⛩️ Алтарь: 320 studs", Color3.fromRGB(6, 182, 212))
local wpBunker = createWpLabel("🚪 Бункер: 700 studs", Color3.fromRGB(248, 113, 113))
local wpHouse = createWpLabel("🏡 Жилой дом: 100 studs", Color3.fromRGB(245, 158, 11))

-- 5. Обновление интерфейса каждый кадр
RunService.RenderStepped:Connect(function()
	local warmth = player:GetAttribute("Warmth") or 100
	local hunger = player:GetAttribute("Hunger") or 100
	local stamina = player:GetAttribute("Stamina") or 100
	local char = player.Character
	local humanoid = char and char:FindFirstChild("Humanoid")
	local health = humanoid and humanoid.Health or 100

	warmthTitle.Text = string.format("🔥 Тепло: %d%%", warmth)
	warmthFill.Size = UDim2.new(math.clamp(warmth / 100, 0, 1), 0, 1, 0)

	hungerTitle.Text = string.format("🍗 Сытость: %d%%", hunger)
	hungerFill.Size = UDim2.new(math.clamp(hunger / 100, 0, 1), 0, 1, 0)

	healthTitle.Text = string.format("❤️ Здоровье: %d%%", math.floor(health))
	healthFill.Size = UDim2.new(math.clamp(health / 100, 0, 1), 0, 1, 0)

	staminaTitle.Text = string.format("⚡ Бег: %d%%", stamina)
	staminaFill.Size = UDim2.new(math.clamp(stamina / 100, 0, 1), 0, 1, 0)

	-- Верхний статус
	local rebirths = player:GetAttribute("Rebirths") or 0
	local maxSlots = player:GetAttribute("MaxSlots") or 5
	local clothLvl = player:GetAttribute("ClothingLevel") or 0
	local ammoSling = player:GetAttribute("Ammo_Slingshot") or 0
	local ammoRev = player:GetAttribute("Ammo_Revolver") or 0
	local placedRelics = workspace:GetAttribute("AltarPlacedRelics") or 0
	local handRelics = player:GetAttribute("CarriedRelics") or 0

	questLabel.Text = string.format(
		"👑 Цикл: #%d | 🎒 %d слотов | 🧥 Lvl %d | 🏹 Боеприпасы: 🪨 %d | 💥 %d | 🗿 Алтарь: %d/7 (%d в руках)",
		rebirths, maxSlots, clothLvl, ammoSling, ammoRev, placedRelics, handRelics
	)

	-- Расчет дистанций
	if char and char:FindFirstChild("HumanoidRootPart") then
		local pPos = char.HumanoidRootPart.Position
		wpHouse.Text = string.format("🏡 Жилой дом: %d studs", math.floor((pPos - Vector3.new(0, 5, 0)).Magnitude))
		wpFood.Text = string.format("🥫 Продуктовый: %d studs", math.floor((pPos - Vector3.new(-180, 2.5, -220)).Magnitude))
		wpShop.Text = string.format("🏪 Одежда: %d studs", math.floor((pPos - Vector3.new(350, 2.5, -300)).Magnitude))
		wpAltar.Text = string.format("⛩️ Алтарь: %d studs (%d/7)", math.floor((pPos - Vector3.new(-60, 1, 80)).Magnitude), placedRelics)
		local isBunkerOpen = workspace:GetAttribute("IsBunkerOpen") or false
		wpBunker.Text = string.format("🚪 Бункер: %d studs [%s]", math.floor((pPos - Vector3.new(180, 4, 120)).Magnitude), isBunkerOpen and "🟢 Открыт" or "🔒 Закрыт")
	end
end)

-- 6. Обработка клавиш (F, T, G)
local selectedSlot = 1

UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then return end

	-- Кормление питомца клавишей F
	if input.KeyCode == Enum.KeyCode.F then
		local feedEvent = ReplicatedStorage:FindFirstChild("Remotes") and ReplicatedStorage.Remotes:FindFirstChild("FeedPet")
		if feedEvent then
			feedEvent:FireServer("Fox", "Bar")
			feedEvent:FireServer("Wolf", "Steak")
			feedEvent:FireServer("Bear", "Bread")
		end
	end

	-- Переключение режима питомца клавишей T
	if input.KeyCode == Enum.KeyCode.T then
		local toggleEvent = ReplicatedStorage:FindFirstChild("Remotes") and ReplicatedStorage.Remotes:FindFirstChild("TogglePetMode")
		if toggleEvent then
			toggleEvent:FireServer("Fox")
			toggleEvent:FireServer("Wolf")
			toggleEvent:FireServer("Bear")
		end
	end

	-- Выброс 1 предмета клавишей G
	if input.KeyCode == Enum.KeyCode.G then
		local dropEvent = ReplicatedStorage:FindFirstChild("DropItemEvent")
		if dropEvent then
			dropEvent:FireServer(selectedSlot, 1)
		end
	end
end)
