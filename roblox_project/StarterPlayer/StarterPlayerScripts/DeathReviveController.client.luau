--[[
    DeathReviveController.client.luau
    Клиентский интерфейс окна смерти и воскрешения:
    1. 👥 Воскрешение союзниками: все предметы в рюкзаке и одежда сохраняются
    2. ⚡ Воскреснуть на месте (5 R$): мгновенно со 100% теплом/сытостью/HP, все предметы и одежда сохраняются
    3. 🏡 Возродиться в доме (Бесплатно) / Крестик [✕]: в безопасном доме со 100% теплом/сытостью, без предметов и одежды
--]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local RemotesFolder = ReplicatedStorage:WaitForChild("Remotes", 10)
local ShowDeathScreenRemote = RemotesFolder and RemotesFolder:WaitForChild("ShowDeathScreen", 10)
local HideDeathScreenRemote = RemotesFolder and RemotesFolder:WaitForChild("HideDeathScreen", 10)
local RespawnInHouseRemote = RemotesFolder and RemotesFolder:WaitForChild("RespawnInHouse", 10)
local ReviveWithRobuxRemote = RemotesFolder and RemotesFolder:WaitForChild("ReviveWithRobux", 10)

local IconConfig = require(ReplicatedStorage:WaitForChild("IconConfig", 10))

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "DeathReviveGui"
screenGui.ResetOnSpawn = false
screenGui.DisplayOrder = 200
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.Parent = playerGui

local mainFrame = Instance.new("Frame")
mainFrame.Name = "MainFrame"
mainFrame.Size = UDim2.new(0, 600, 0, 430)
mainFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
mainFrame.AnchorPoint = Vector2.new(0.5, 0.5)
mainFrame.BackgroundColor3 = Color3.fromRGB(15, 23, 42)
mainFrame.BackgroundTransparency = 0.05
mainFrame.BorderSizePixel = 0
mainFrame.Visible = false
mainFrame.Parent = screenGui
Instance.new("UICorner", mainFrame).CornerRadius = UDim.new(0, 16)

local stroke = Instance.new("UIStroke", mainFrame)
stroke.Color = Color3.fromRGB(239, 68, 68)
stroke.Thickness = 2.5

-- 1. Шапка окна смерти
local header = Instance.new("Frame")
header.Size = UDim2.new(1, 0, 0, 54)
header.BackgroundColor3 = Color3.fromRGB(127, 29, 29)
header.BackgroundTransparency = 0.35
header.BorderSizePixel = 0
header.Parent = mainFrame
Instance.new("UICorner", header).CornerRadius = UDim.new(0, 16)

local skullBadge = IconConfig.CreateIconBadge(header, "UI_Skull", UDim2.new(0, 32, 0, 32), 1)
skullBadge.Position = UDim2.new(0, 14, 0.5, 0)
skullBadge.AnchorPoint = Vector2.new(0, 0.5)

local titleLabel = Instance.new("TextLabel")
titleLabel.Size = UDim2.new(1, -110, 1, 0)
titleLabel.Position = UDim2.new(0, 54, 0, 0)
titleLabel.BackgroundTransparency = 1
titleLabel.Font = Enum.Font.MontserratBlack
titleLabel.TextSize = 17
titleLabel.TextColor3 = Color3.fromRGB(254, 202, 202)
titleLabel.TextXAlignment = Enum.TextXAlignment.Left
titleLabel.Text = "ВЫ ПОГИБЛИ"
titleLabel.Parent = header

-- ✖ Графический крестик закрытия (Возрождение в жилом доме)
local closeBtn = IconConfig.CreateIconButton(header, "UI_Close", UDim2.new(0, 36, 0, 36), Color3.fromRGB(185, 28, 28), Color3.fromRGB(254, 202, 202))
closeBtn.Name = "CloseButton"
closeBtn.Position = UDim2.new(1, -46, 0.5, 0)
closeBtn.AnchorPoint = Vector2.new(0, 0.5)


-- 2. Информационный блок о помощи союзников
local infoCard = Instance.new("Frame")
infoCard.Size = UDim2.new(1, -36, 0, 84)
infoCard.Position = UDim2.new(0, 18, 0, 66)
infoCard.BackgroundColor3 = Color3.fromRGB(30, 41, 59)
infoCard.BackgroundTransparency = 0.5
infoCard.BorderSizePixel = 0
infoCard.Parent = mainFrame
Instance.new("UICorner", infoCard).CornerRadius = UDim.new(0, 12)

local infoStroke = Instance.new("UIStroke", infoCard)
infoStroke.Color = Color3.fromRGB(244, 63, 94)
infoStroke.Thickness = 1.2

local infoText = Instance.new("TextLabel")
infoText.Size = UDim2.new(1, -24, 1, -12)
infoText.Position = UDim2.new(0, 12, 0, 6)
infoText.BackgroundTransparency = 1
infoText.Font = Enum.Font.Gotham
infoText.TextSize = 12
infoText.TextColor3 = Color3.fromRGB(254, 226, 226)
infoText.TextXAlignment = Enum.TextXAlignment.Center
infoText.TextYAlignment = Enum.TextYAlignment.Center
infoText.TextWrapped = true
infoText.Text = "👥 Вас могут воскресить другие игроки прямо на месте гибели!\n(подойдя к вашему телу и зажав клавишу [E])\n✨ Все предметы, одежда и ПИТОМЕЦ сохраняются!"
infoText.Parent = infoCard

-- 3. Кнопка 1: Воскреснуть на месте (5 Robux)
local robuxBtn = Instance.new("TextButton")
robuxBtn.Name = "RobuxReviveBtn"
robuxBtn.Size = UDim2.new(1, -36, 0, 96)
robuxBtn.Position = UDim2.new(0, 18, 0, 162)
robuxBtn.BackgroundColor3 = Color3.fromRGB(6, 95, 70)
robuxBtn.BorderSizePixel = 0
robuxBtn.Text = ""
robuxBtn.Parent = mainFrame
Instance.new("UICorner", robuxBtn).CornerRadius = UDim.new(0, 12)

local robuxStroke = Instance.new("UIStroke", robuxBtn)
robuxStroke.Color = Color3.fromRGB(52, 211, 153)
robuxStroke.Thickness = 1.8

local robuxTitle = Instance.new("TextLabel")
robuxTitle.Size = UDim2.new(1, -20, 0, 24)
robuxTitle.Position = UDim2.new(0, 10, 0, 8)
robuxTitle.BackgroundTransparency = 1
robuxTitle.Font = Enum.Font.GothamBlack
robuxTitle.TextSize = 14.5
robuxTitle.TextColor3 = Color3.fromRGB(209, 250, 229)
robuxTitle.Text = "⚡ Воскреснуть сейчас на месте (5 R$)"
robuxTitle.Parent = robuxBtn

local robuxSub = Instance.new("TextLabel")
robuxSub.Size = UDim2.new(1, -20, 0, 52)
robuxSub.Position = UDim2.new(0, 10, 0, 34)
robuxSub.BackgroundTransparency = 1
robuxSub.Font = Enum.Font.Gotham
robuxSub.TextSize = 11.5
robuxSub.TextColor3 = Color3.fromRGB(167, 243, 208)
robuxSub.TextWrapped = true
robuxSub.Text = "Мгновенно оживляет на точке падения со 100% Тепла, Сытости и Здоровья.\n✨ Все предметы, одежда и ПИТОМЕЦ СОХРАНЯЮТСЯ!"
robuxSub.Parent = robuxBtn

-- 4. Кнопка 2: Возродиться в жилом доме (Бесплатно / Крестик)
local houseBtn = Instance.new("TextButton")
houseBtn.Name = "HouseRespawnBtn"
houseBtn.Size = UDim2.new(1, -36, 0, 96)
houseBtn.Position = UDim2.new(0, 18, 0, 270)
houseBtn.BackgroundColor3 = Color3.fromRGB(30, 58, 138)
houseBtn.BorderSizePixel = 0
houseBtn.Text = ""
houseBtn.Parent = mainFrame
Instance.new("UICorner", houseBtn).CornerRadius = UDim.new(0, 12)

local houseStroke = Instance.new("UIStroke", houseBtn)
houseStroke.Color = Color3.fromRGB(56, 189, 248)
houseStroke.Thickness = 1.8

local houseTitle = Instance.new("TextLabel")
houseTitle.Size = UDim2.new(1, -20, 0, 24)
houseTitle.Position = UDim2.new(0, 10, 0, 8)
houseTitle.BackgroundTransparency = 1
houseTitle.Font = Enum.Font.GothamBlack
houseTitle.TextSize = 14.5
houseTitle.TextColor3 = Color3.fromRGB(224, 242, 254)
houseTitle.Text = "🏡 Возродиться в жилом доме (Бесплатно)"
houseTitle.Parent = houseBtn

local houseSub = Instance.new("TextLabel")
houseSub.Size = UDim2.new(1, -20, 0, 52)
houseSub.Position = UDim2.new(0, 10, 0, 34)
houseSub.BackgroundTransparency = 1
houseSub.Font = Enum.Font.Gotham
houseSub.TextSize = 11.5
houseSub.TextColor3 = Color3.fromRGB(186, 230, 253)
houseSub.TextWrapped = true
houseSub.Text = "Мгновенно телепортирует в дом со 100% Тепла и 100% Сытости.\n⚠️ Без вещей в рюкзаке и одежды. Питомец ждет на лежанке дома."
houseSub.Parent = houseBtn

-- Обработчики нажатий
local function doRespawnInHouse()
	mainFrame.Visible = false
	closeBtn.Modal = false
	if RespawnInHouseRemote then
		RespawnInHouseRemote:FireServer()
	end
end

local function doReviveWithRobux()
	mainFrame.Visible = false
	closeBtn.Modal = false
	if ReviveWithRobuxRemote then
		ReviveWithRobuxRemote:FireServer()
	end
end

closeBtn.MouseButton1Click:Connect(doRespawnInHouse)
houseBtn.MouseButton1Click:Connect(doRespawnInHouse)
robuxBtn.MouseButton1Click:Connect(doReviveWithRobux)

-- Слушатели событий сервера
if ShowDeathScreenRemote then
	ShowDeathScreenRemote.OnClientEvent:Connect(function()
		mainFrame.Visible = true
		closeBtn.Modal = true
	end)
end

if HideDeathScreenRemote then
	HideDeathScreenRemote.OnClientEvent:Connect(function()
		mainFrame.Visible = false
		closeBtn.Modal = false
	end)
end

print("💀 [DeathReviveController] Контроллер возрождения и воскрешения успешно инициализирован!")
