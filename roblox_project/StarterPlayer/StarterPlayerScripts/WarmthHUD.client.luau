--[[
    WarmthHUD.client.luau
    Клиентский интерфейс (HUD) со ВСТРОЕННЫМ НАТИВНЫМ рюкзаком Roblox:
    - 🎒 Включен нативный хотбар Roblox (CoreGui Backpack)
    - 🔥 Шкалы внизу: Тепло, Сытость, Выносливость (Здоровье отображается нативно в правом верхнем углу Roblox)
    - 👑 Верхняя панель: Живой таймер выживания, Цикл перерождения, Уровень одежды, Боеприпасы, Реликвии
    - ❓ Кнопка Гайда и всплывающие предупреждения
--]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local StarterGui = game:GetService("StarterGui")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- 1. Включаем стандартный нативный рюкзак Roblox!
pcall(function()
	StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Backpack, true)
end)

-- Создание ScreenGui для шкал и верхней панели
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "SurviveTheColdHUD"
screenGui.ResetOnSpawn = false
screenGui.Parent = playerGui

-- 1. Верхняя панель
local questBar = Instance.new("Frame")
questBar.Name = "QuestBar"
questBar.Size = UDim2.new(0, 720, 0, 36)
questBar.Position = UDim2.new(0.5, 0, 0, 16)
questBar.AnchorPoint = Vector2.new(0.5, 0)
questBar.BackgroundColor3 = Color3.fromRGB(15, 23, 42)
questBar.BackgroundTransparency = 0.25
questBar.BorderSizePixel = 0
questBar.Parent = screenGui
Instance.new("UICorner", questBar).CornerRadius = UDim.new(0, 10)

local questLabel = Instance.new("TextLabel")
questLabel.Size = UDim2.new(1, -20, 1, 0)
questLabel.Position = UDim2.new(0, 10, 0, 0)
questLabel.BackgroundTransparency = 1
questLabel.Font = Enum.Font.GothamBold
questLabel.TextSize = 12.5
questLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
questLabel.Text = "⏱️ 00:00 | 👑 Цикл: #0 | 🎒 5 слотов | 🧥 Lvl 0 | 🏹 ⛏️ 0 💥 0 | 🗿 Алтарь: 0/7"
questLabel.Parent = questBar

-- 2. Нижняя панель статусов (3 группы: 🔥 Тепло, 🍗 Сытость, ⚡ Бег) - над хотбаром Roblox
local statusBar = Instance.new("Frame")
statusBar.Name = "StatusBar"
statusBar.Size = UDim2.new(0, 460, 0, 44)
statusBar.Position = UDim2.new(0.5, 0, 1, -76)
statusBar.AnchorPoint = Vector2.new(0.5, 1)
statusBar.BackgroundColor3 = Color3.fromRGB(15, 23, 42)
statusBar.BackgroundTransparency = 0.3
statusBar.BorderSizePixel = 0
statusBar.Parent = screenGui
Instance.new("UICorner", statusBar).CornerRadius = UDim.new(0, 10)

local statusLayout = Instance.new("UIListLayout", statusBar)
statusLayout.FillDirection = Enum.FillDirection.Horizontal
statusLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
statusLayout.VerticalAlignment = Enum.VerticalAlignment.Center
statusLayout.Padding = UDim.new(0, 14)

local function createBarGroup(name, labelText, color)
	local group = Instance.new("Frame")
	group.Name = name
	group.Size = UDim2.new(0, 130, 0, 30)
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
	barBg.Size = UDim2.new(1, 0, 0, 7)
	barBg.Position = UDim2.new(0, 0, 0, 17)
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
local staminaTitle, staminaFill = createBarGroup("StaminaGroup", "⚡ Бег", Color3.fromRGB(56, 189, 248))

-- 3. Кнопка вызова Гайда
local guideBtn = Instance.new("TextButton")
guideBtn.Name = "GuideButton"
guideBtn.Size = UDim2.new(0, 150, 0, 32)
guideBtn.Position = UDim2.new(0, 20, 0, 20)
guideBtn.BackgroundColor3 = Color3.fromRGB(15, 23, 42)
guideBtn.BackgroundTransparency = 0.25
guideBtn.Font = Enum.Font.GothamBold
guideBtn.TextSize = 12
guideBtn.TextColor3 = Color3.fromRGB(56, 189, 248)
guideBtn.Text = "❓ Обучение & Гайд"
guideBtn.Parent = screenGui
Instance.new("UICorner", guideBtn).CornerRadius = UDim.new(0, 8)

guideBtn.MouseButton1Click:Connect(function()
	local guideGui = playerGui:FindFirstChild("WelcomeGuideGui")
	if guideGui then
		local frame = guideGui:FindFirstChild("MainFrame")
		if frame then frame.Visible = not frame.Visible end
	end
end)

-- 4. Всплывающее предупреждение по центру экрана
local notifBanner = Instance.new("Frame")
notifBanner.Name = "NotificationBanner"
notifBanner.Size = UDim2.new(0, 480, 0, 38)
notifBanner.Position = UDim2.new(0.5, 0, 0, 64)
notifBanner.AnchorPoint = Vector2.new(0.5, 0)
notifBanner.BackgroundColor3 = Color3.fromRGB(220, 38, 38)
notifBanner.BackgroundTransparency = 0.15
notifBanner.BorderSizePixel = 0
notifBanner.Visible = false
notifBanner.Parent = screenGui
Instance.new("UICorner", notifBanner).CornerRadius = UDim.new(0, 8)

local notifText = Instance.new("TextLabel")
notifText.Size = UDim2.new(1, -20, 1, 0)
notifText.Position = UDim2.new(0, 10, 0, 0)
notifText.BackgroundTransparency = 1
notifText.Font = Enum.Font.GothamBold
notifText.TextSize = 13
notifText.TextColor3 = Color3.fromRGB(255, 255, 255)
notifText.Text = "⚠️ Предупреждение!"
notifText.Parent = notifBanner

local RemotesFolder = ReplicatedStorage:WaitForChild("Remotes", 10)
local ShowNotificationRemote = RemotesFolder and RemotesFolder:WaitForChild("ShowNotification", 10)
if ShowNotificationRemote then
	ShowNotificationRemote.OnClientEvent:Connect(function(msg)
		notifText.Text = msg
		notifBanner.Visible = true
		task.delay(3.0, function()
			if notifBanner then notifBanner.Visible = false end
		end)
	end)
end

-- 5. Обновление шкал каждый кадр
RunService.RenderStepped:Connect(function()
	local warmth = player:GetAttribute("Warmth") or 100
	local hunger = player:GetAttribute("Hunger") or 100
	local stamina = player:GetAttribute("Stamina") or 100

	warmthTitle.Text = string.format("🔥 Тепло: %d%%", warmth)
	warmthFill.Size = UDim2.new(math.clamp(warmth / 100, 0, 1), 0, 1, 0)

	hungerTitle.Text = string.format("🍗 Сытость: %d%%", hunger)
	hungerFill.Size = UDim2.new(math.clamp(hunger / 100, 0, 1), 0, 1, 0)

	staminaTitle.Text = string.format("⚡ Бег: %d%%", stamina)
	staminaFill.Size = UDim2.new(math.clamp(stamina / 100, 0, 1), 0, 1, 0)

	-- Верхняя панель
	local survSecs = player:GetAttribute("SurvivalTimeSeconds") or 0
	local mins = math.floor(survSecs / 60)
	local secs = survSecs % 60
	local timeFormatted = string.format("%02d:%02d", mins, secs)

	local rebirths = player:GetAttribute("Rebirths") or 0
	local maxSlots = player:GetAttribute("MaxSlots") or 5
	local clothLvl = player:GetAttribute("ClothingLevel") or 0
	local ammoSling = player:GetAttribute("Ammo_Slingshot") or 0
	local ammoRev = player:GetAttribute("Ammo_Revolver") or 0
	local placedRelics = workspace:GetAttribute("AltarPlacedRelics") or 0
	local handRelics = player:GetAttribute("CarriedRelics") or 0

	questLabel.Text = string.format(
		"⏱️ %s | 👑 Цикл: #%d | 🎒 %d слотов | 🧥 Lvl %d | 🏹 ⛏️ %d 💥 %d | 🗿 Алтарь: %d/7 (%d в руках)",
		timeFormatted, rebirths, maxSlots, clothLvl, ammoSling, ammoRev, placedRelics, handRelics
	)
end)
