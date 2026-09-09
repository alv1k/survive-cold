--[[
    PetMenuController.client.luau
    Клиентский интерфейс управления питомцами (Pet Management Modal):
    - 🍗 Секция "Еда (Голод) * Множитель":
        - Наглядная анимированная шкала сытости (0 - 100%)
        - Множитель эффективности пассивных баффов (1.0x / 0.7x / 0.4x / 0.0x)
        - Быстрое кормление из рюкзака с подсветкой любимых лакомств (❤️ Любимое +65% / +30%)
    - ✨ Секция "Строка баффов":
        - Пассивные эффекты питомца хозяину (урон, скорость, тепло, стамина, радар)
        - Статус активности баффа (🟢 Активен / 💤 На паузе)
    - 🐾 Секция "Режим":
        - Единая главная кнопка переключения: "💤 Отправить спать на лежанку" <-> "🐾 Позвать с собой [Следовать]"
    - Управление через [E], [ESC], клик по питомцу, закрытие при отходе
--]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local camera = workspace.CurrentCamera

local Network = require(ReplicatedStorage:WaitForChild("Network"))
local OpenPetMenuRemote = Network.getEvent("OpenPetMenu")
local TogglePetModeRemote = Network.getEvent("TogglePetMode")
local FeedPetRemote = Network.getEvent("FeedPet")
local UpdatePetDataRemote = Network.getEvent("UpdatePetData")

-- Удаляем старый UI если есть
local oldGui = playerGui:FindFirstChild("PetMenuScreenGui")
if oldGui then oldGui:Destroy() end

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "PetMenuScreenGui"
screenGui.ResetOnSpawn = false
screenGui.DisplayOrder = 15
screenGui.Enabled = false
screenGui.Parent = playerGui

-- Затемняющий фон (клик по фону закрывает окно)
local overlay = Instance.new("TextButton")
overlay.Name = "Overlay"
overlay.Size = UDim2.new(1, 0, 1, 0)
overlay.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
overlay.BackgroundTransparency = 0.55
overlay.Text = ""
overlay.AutoButtonColor = false
overlay.Parent = screenGui

-- Главное модальное окно
local modalFrame = Instance.new("Frame")
modalFrame.Name = "ModalFrame"
modalFrame.Size = UDim2.new(0, 560, 0, 520)
modalFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
modalFrame.AnchorPoint = Vector2.new(0.5, 0.5)
modalFrame.BackgroundColor3 = Color3.fromRGB(15, 23, 42)
modalFrame.BorderSizePixel = 0
modalFrame.Parent = screenGui

local modalCorner = Instance.new("UICorner", modalFrame)
modalCorner.CornerRadius = UDim.new(0, 16)

local modalStroke = Instance.new("UIStroke", modalFrame)
modalStroke.Color = Color3.fromRGB(56, 189, 248)
modalStroke.Thickness = 2

-- Градиент для модалки
local modalGrad = Instance.new("UIGradient", modalFrame)
modalGrad.Color = ColorSequence.new({
	ColorSequenceKeypoint.new(0, Color3.fromRGB(24, 34, 53)),
	ColorSequenceKeypoint.new(1, Color3.fromRGB(15, 23, 42))
})
modalGrad.Rotation = 45

-- 1. ШАПКА ОКНА (Header)
local header = Instance.new("Frame")
header.Name = "Header"
header.Size = UDim2.new(1, 0, 0, 58)
header.BackgroundColor3 = Color3.fromRGB(30, 41, 59)
header.BorderSizePixel = 0
header.Parent = modalFrame
Instance.new("UICorner", header).CornerRadius = UDim.new(0, 16)

local headerTitle = Instance.new("TextLabel")
headerTitle.Name = "PetTitle"
headerTitle.Size = UDim2.new(0.65, 0, 1, 0)
headerTitle.Position = UDim2.new(0, 20, 0, 0)
headerTitle.BackgroundTransparency = 1
headerTitle.Font = Enum.Font.MontserratBlack
headerTitle.TextSize = 18
headerTitle.TextColor3 = Color3.fromRGB(241, 245, 249)
headerTitle.TextXAlignment = Enum.TextXAlignment.Left
headerTitle.Text = "🐺 Ледяной Волчонок"
headerTitle.Parent = header

-- Бейдж статуса питомца
local statusBadge = Instance.new("Frame")
statusBadge.Name = "StatusBadge"
statusBadge.Size = UDim2.new(0, 130, 0, 28)
statusBadge.Position = UDim2.new(1, -78, 0.5, 0)
statusBadge.AnchorPoint = Vector2.new(1, 0.5)
statusBadge.BackgroundColor3 = Color3.fromRGB(34, 197, 94)
statusBadge.BackgroundTransparency = 0.8
statusBadge.Parent = header
Instance.new("UICorner", statusBadge).CornerRadius = UDim.new(0, 14)

local statusBadgeStroke = Instance.new("UIStroke", statusBadge)
statusBadgeStroke.Color = Color3.fromRGB(34, 197, 94)
statusBadgeStroke.Thickness = 1.2

local statusBadgeText = Instance.new("TextLabel", statusBadge)
statusBadgeText.Name = "StatusText"
statusBadgeText.Size = UDim2.new(1, 0, 1, 0)
statusBadgeText.BackgroundTransparency = 1
statusBadgeText.Font = Enum.Font.GothamBold
statusBadgeText.TextSize = 11
statusBadgeText.TextColor3 = Color3.fromRGB(74, 222, 128)
statusBadgeText.Text = "🟢 В походе"

-- Кнопка закрытия [✕]
local closeBtn = Instance.new("TextButton")
closeBtn.Name = "CloseBtn"
closeBtn.Size = UDim2.new(0, 36, 0, 36)
closeBtn.Position = UDim2.new(1, -44, 0.5, 0)
closeBtn.AnchorPoint = Vector2.new(0, 0.5)
closeBtn.BackgroundColor3 = Color3.fromRGB(220, 38, 38)
closeBtn.Font = Enum.Font.GothamBold
closeBtn.TextSize = 16
closeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
closeBtn.Text = "✕"
closeBtn.Parent = header
Instance.new("UICorner", closeBtn).CornerRadius = UDim.new(0, 8)

-- 2. ТЕЛО ОКНА (Content Container)
local contentList = Instance.new("Frame")
contentList.Name = "ContentList"
contentList.Size = UDim2.new(1, -32, 1, -74)
contentList.Position = UDim2.new(0, 16, 0, 66)
contentList.BackgroundTransparency = 1
contentList.Parent = modalFrame

local contentLayout = Instance.new("UIListLayout", contentList)
contentLayout.FillDirection = Enum.FillDirection.Vertical
contentLayout.Padding = UDim.new(0, 10)
contentLayout.SortOrder = Enum.SortOrder.LayoutOrder

-- -----------------------------------------------------------------------------
-- БЛОК 1: СЫТОСТЬ & МНОЖИТЕЛЬ БАФФА (Hunger & Multiplier)
-- -----------------------------------------------------------------------------
local satietyCard = Instance.new("Frame")
satietyCard.Name = "SatietyCard"
satietyCard.LayoutOrder = 1
satietyCard.Size = UDim2.new(1, 0, 0, 114)
satietyCard.BackgroundColor3 = Color3.fromRGB(30, 41, 59)
satietyCard.BorderSizePixel = 0
satietyCard.Parent = contentList
Instance.new("UICorner", satietyCard).CornerRadius = UDim.new(0, 12)
local satStroke = Instance.new("UIStroke", satietyCard)
satStroke.Color = Color3.fromRGB(51, 65, 85)
satStroke.Thickness = 1

local satHeader = Instance.new("Frame", satietyCard)
satHeader.Size = UDim2.new(1, -24, 0, 24)
satHeader.Position = UDim2.new(0, 12, 0, 10)
satHeader.BackgroundTransparency = 1

local satTitle = Instance.new("TextLabel", satHeader)
satTitle.Size = UDim2.new(0.6, 0, 1, 0)
satTitle.BackgroundTransparency = 1
satTitle.Font = Enum.Font.MontserratBold
satTitle.TextSize = 13
satTitle.TextColor3 = Color3.fromRGB(226, 232, 240)
satTitle.TextXAlignment = Enum.TextXAlignment.Left
satTitle.Text = "🍗 СЫТОСТЬ И МНОЖИТЕЛЬ СИЛЫ"

local satValLabel = Instance.new("TextLabel", satHeader)
satValLabel.Name = "SatValLabel"
satValLabel.Size = UDim2.new(0.4, 0, 1, 0)
satValLabel.Position = UDim2.new(0.6, 0, 0, 0)
satValLabel.BackgroundTransparency = 1
satValLabel.Font = Enum.Font.MontserratBlack
satValLabel.TextSize = 14
satValLabel.TextColor3 = Color3.fromRGB(74, 222, 128)
satValLabel.TextXAlignment = Enum.TextXAlignment.Right
satValLabel.Text = "85 / 100%"

-- Полоса сытости
local satBarBg = Instance.new("Frame", satietyCard)
satBarBg.Name = "SatBarBg"
satBarBg.Size = UDim2.new(1, -24, 0, 16)
satBarBg.Position = UDim2.new(0, 12, 0, 38)
satBarBg.BackgroundColor3 = Color3.fromRGB(15, 23, 42)
satBarBg.BorderSizePixel = 0
Instance.new("UICorner", satBarBg).CornerRadius = UDim.new(0, 8)

local satBarFill = Instance.new("Frame", satBarBg)
satBarFill.Name = "SatBarFill"
satBarFill.Size = UDim2.new(0.85, 0, 1, 0)
satBarFill.BackgroundColor3 = Color3.fromRGB(34, 197, 94)
satBarFill.BorderSizePixel = 0
Instance.new("UICorner", satBarFill).CornerRadius = UDim.new(0, 8)

-- Строка множителя
local multRow = Instance.new("Frame", satietyCard)
multRow.Size = UDim2.new(1, -24, 0, 22)
multRow.Position = UDim2.new(0, 12, 0, 60)
multRow.BackgroundTransparency = 1

local multTitle = Instance.new("TextLabel", multRow)
multTitle.Size = UDim2.new(0.5, 0, 1, 0)
multTitle.BackgroundTransparency = 1
multTitle.Font = Enum.Font.GothamMedium
multTitle.TextSize = 12
multTitle.TextColor3 = Color3.fromRGB(148, 163, 184)
multTitle.TextXAlignment = Enum.TextXAlignment.Left
multTitle.Text = "⚡ Множитель эффекта баффа:"

local multValLabel = Instance.new("TextLabel", multRow)
multValLabel.Name = "MultValLabel"
multValLabel.Size = UDim2.new(0.5, 0, 1, 0)
multValLabel.Position = UDim2.new(0.5, 0, 0, 0)
multValLabel.BackgroundTransparency = 1
multValLabel.Font = Enum.Font.MontserratBold
multValLabel.TextSize = 13
multValLabel.TextColor3 = Color3.fromRGB(250, 204, 21)
multValLabel.TextXAlignment = Enum.TextXAlignment.Right
multValLabel.Text = "1.0x (100% полная сила)"

local satHint = Instance.new("TextLabel", satietyCard)
satHint.Size = UDim2.new(1, -24, 0, 18)
satHint.Position = UDim2.new(0, 12, 0, 86)
satHint.BackgroundTransparency = 1
satHint.Font = Enum.Font.Gotham
satHint.TextSize = 10
satHint.TextColor3 = Color3.fromRGB(100, 116, 139)
satHint.TextXAlignment = Enum.TextXAlignment.Left
satHint.Text = "💡 На лежанке в доме сытость почти не тратится (0.1/сек vs 0.5/сек в походе)"

-- -----------------------------------------------------------------------------
-- БЛОК 2: СТРОКА БАФФОВ (Buff Status Row)
-- -----------------------------------------------------------------------------
local buffCard = Instance.new("Frame")
buffCard.Name = "BuffCard"
buffCard.LayoutOrder = 2
buffCard.Size = UDim2.new(1, 0, 0, 78)
buffCard.BackgroundColor3 = Color3.fromRGB(30, 41, 59)
buffCard.BorderSizePixel = 0
buffCard.Parent = contentList
Instance.new("UICorner", buffCard).CornerRadius = UDim.new(0, 12)
local buffStroke = Instance.new("UIStroke", buffCard)
buffStroke.Color = Color3.fromRGB(51, 65, 85)
buffStroke.Thickness = 1

local buffTitle = Instance.new("TextLabel", buffCard)
buffTitle.Size = UDim2.new(1, -24, 0, 20)
buffTitle.Position = UDim2.new(0, 12, 0, 8)
buffTitle.BackgroundTransparency = 1
buffTitle.Font = Enum.Font.MontserratBold
buffTitle.TextSize = 12
buffTitle.TextColor3 = Color3.fromRGB(226, 232, 240)
buffTitle.TextXAlignment = Enum.TextXAlignment.Left
buffTitle.Text = "✨ ПАССИВНЫЕ БАФФЫ ХОЗЯИНУ"

local buffDescLabel = Instance.new("TextLabel", buffCard)
buffDescLabel.Name = "BuffDescLabel"
buffDescLabel.Size = UDim2.new(1, -120, 0, 42)
buffDescLabel.Position = UDim2.new(0, 12, 0, 28)
buffDescLabel.BackgroundTransparency = 1
buffDescLabel.Font = Enum.Font.GothamMedium
buffDescLabel.TextSize = 12
buffDescLabel.TextColor3 = Color3.fromRGB(56, 189, 248)
buffDescLabel.TextXAlignment = Enum.TextXAlignment.Left
buffDescLabel.TextYAlignment = Enum.TextYAlignment.Center
buffDescLabel.TextWrapped = true
buffDescLabel.Text = "+25% урон оружия & +10% скорость бега"

local buffActiveTag = Instance.new("Frame", buffCard)
buffActiveTag.Name = "BuffActiveTag"
buffActiveTag.Size = UDim2.new(0, 95, 0, 26)
buffActiveTag.Position = UDim2.new(1, -12, 0.5, 6)
buffActiveTag.AnchorPoint = Vector2.new(1, 0.5)
buffActiveTag.BackgroundColor3 = Color3.fromRGB(34, 197, 94)
buffActiveTag.BackgroundTransparency = 0.8
Instance.new("UICorner", buffActiveTag).CornerRadius = UDim.new(0, 6)

local buffActiveStroke = Instance.new("UIStroke", buffActiveTag)
buffActiveStroke.Color = Color3.fromRGB(34, 197, 94)
buffActiveStroke.Thickness = 1

local buffActiveText = Instance.new("TextLabel", buffActiveTag)
buffActiveText.Name = "TagText"
buffActiveText.Size = UDim2.new(1, 0, 1, 0)
buffActiveText.BackgroundTransparency = 1
buffActiveText.Font = Enum.Font.GothamBold
buffActiveText.TextSize = 10
buffActiveText.TextColor3 = Color3.fromRGB(74, 222, 128)
buffActiveText.Text = "АКТИВЕН"

-- -----------------------------------------------------------------------------
-- БЛОК 3: БЫСТРОЕ КОРМЛЕНИЕ (Quick Feed Panel)
-- -----------------------------------------------------------------------------
local feedCard = Instance.new("Frame")
feedCard.Name = "FeedCard"
feedCard.LayoutOrder = 3
feedCard.Size = UDim2.new(1, 0, 0, 140)
feedCard.BackgroundColor3 = Color3.fromRGB(30, 41, 59)
feedCard.BorderSizePixel = 0
feedCard.Parent = contentList
Instance.new("UICorner", feedCard).CornerRadius = UDim.new(0, 12)
local feedStroke = Instance.new("UIStroke", feedCard)
feedStroke.Color = Color3.fromRGB(51, 65, 85)
feedStroke.Thickness = 1

local feedHeader = Instance.new("TextLabel", feedCard)
feedHeader.Size = UDim2.new(1, -24, 0, 20)
feedHeader.Position = UDim2.new(0, 12, 0, 8)
feedHeader.BackgroundTransparency = 1
feedHeader.Font = Enum.Font.MontserratBold
feedHeader.TextSize = 12
feedHeader.TextColor3 = Color3.fromRGB(226, 232, 240)
feedHeader.TextXAlignment = Enum.TextXAlignment.Left
feedHeader.Text = "🍲 ПОКОРМИТЬ ИЗ РЮКЗАКА (Кликните на еду):"

-- Горизонтальный скролл еды
local foodScroll = Instance.new("ScrollingFrame", feedCard)
foodScroll.Name = "FoodScroll"
foodScroll.Size = UDim2.new(1, -24, 0, 100)
foodScroll.Position = UDim2.new(0, 12, 0, 32)
foodScroll.BackgroundTransparency = 1
foodScroll.BorderSizePixel = 0
foodScroll.CanvasSize = UDim2.new(0, 540, 0, 0)
foodScroll.ScrollBarThickness = 4
foodScroll.ScrollBarImageColor3 = Color3.fromRGB(56, 189, 248)
foodScroll.HorizontalScrollBarInset = Enum.ScrollBarInset.None

local foodLayout = Instance.new("UIListLayout", foodScroll)
foodLayout.FillDirection = Enum.FillDirection.Horizontal
foodLayout.Padding = UDim.new(0, 8)
foodLayout.SortOrder = Enum.SortOrder.LayoutOrder

-- -----------------------------------------------------------------------------
-- БЛОК 4: ГЛАВНАЯ КНОПКА РЕЖИМА (Следовать / Спать)
-- -----------------------------------------------------------------------------
local modeActionBtn = Instance.new("TextButton")
modeActionBtn.Name = "ModeActionBtn"
modeActionBtn.LayoutOrder = 4
modeActionBtn.Size = UDim2.new(1, 0, 0, 52)
modeActionBtn.BackgroundColor3 = Color3.fromRGB(99, 102, 241)
modeActionBtn.BorderSizePixel = 0
modeActionBtn.AutoButtonColor = true
modeActionBtn.Text = ""
modeActionBtn.Parent = contentList
Instance.new("UICorner", modeActionBtn).CornerRadius = UDim.new(0, 12)

local modeBtnStroke = Instance.new("UIStroke", modeActionBtn)
modeBtnStroke.Color = Color3.fromRGB(165, 180, 252)
modeBtnStroke.Thickness = 1.5

local modeBtnMainText = Instance.new("TextLabel", modeActionBtn)
modeBtnMainText.Name = "MainText"
modeBtnMainText.Size = UDim2.new(1, 0, 0, 24)
modeBtnMainText.Position = UDim2.new(0, 0, 0, 6)
modeBtnMainText.BackgroundTransparency = 1
modeBtnMainText.Font = Enum.Font.MontserratBlack
modeBtnMainText.TextSize = 15
modeBtnMainText.TextColor3 = Color3.fromRGB(255, 255, 255)
modeBtnMainText.Text = "💤 ОТПРАВИТЬ СПАТЬ НА ЛЕЖАНКУ"

local modeBtnSubText = Instance.new("TextLabel", modeActionBtn)
modeBtnSubText.Name = "SubText"
modeBtnSubText.Size = UDim2.new(1, 0, 0, 18)
modeBtnSubText.Position = UDim2.new(0, 0, 0, 28)
modeBtnSubText.BackgroundTransparency = 1
modeBtnSubText.Font = Enum.Font.GothamMedium
modeBtnSubText.TextSize = 10
modeBtnSubText.TextColor3 = Color3.fromRGB(224, 231, 255)
modeBtnSubText.Text = "Питомец переместится на лежанку в доме и сохранит сытость"

-- =============================================================================
-- ЛОГИКА И ДАННЫЕ ПИТОМЦА
-- =============================================================================
local currentPetData = nil

local ALL_FOODS = {
	{ Key = "Steak", Name = "Стейк", Emoji = "🥩", BaseGain = 30 },
	{ Key = "Soup", Name = "Суп", Emoji = "🥫", BaseGain = 30 },
	{ Key = "Bread", Name = "Хлеб", Emoji = "🍞", BaseGain = 30 },
	{ Key = "Bar", Name = "Батончик", Emoji = "🍫", BaseGain = 30 },
	{ Key = "Chips", Name = "Чипсы", Emoji = "🥔", BaseGain = 30 },
	{ Key = "Pepper", Name = "Перец", Emoji = "🌶️", BaseGain = 30 },
	{ Key = "Coffee", Name = "Кофе", Emoji = "☕", BaseGain = 30 }
}

-- Подсчет количества еды в инвентаре/рюкзаке
local function getFoodCount(foodKey: string): number
	local count = 0
	local backpack = player:FindFirstChildOfClass("Backpack")
	local char = player.Character

	if backpack then
		for _, t in ipairs(backpack:GetChildren()) do
			if t:IsA("Tool") and (t:GetAttribute("ItemKey") == foodKey or t.Name:find(foodKey)) then
				count = count + (t:GetAttribute("Count") or 1)
			end
		end
	end
	if char then
		for _, t in ipairs(char:GetChildren()) do
			if t:IsA("Tool") and (t:GetAttribute("ItemKey") == foodKey or t.Name:find(foodKey)) then
				count = count + (t:GetAttribute("Count") or 1)
			end
		end
	end

	local attrCount = player:GetAttribute(foodKey) or player:GetAttribute("Food_" .. foodKey) or 0
	return math.max(count, attrCount)
end

-- Обновление UI
local function refreshPetUI()
	if not currentPetData then return end

	local pId = currentPetData.PetId
	local name = currentPetData.Name or "Питомец"
	local satiety = currentPetData.Satiety or 100
	local mode = currentPetData.Mode or "follow"
	local isSleeping = currentPetData.IsSleeping or (mode == "stay_home")
	local favs = currentPetData.FavoriteFoods or {}

	-- Шапка
	headerTitle.Text = name
	if mode == "follow" then
		statusBadge.BackgroundColor3 = Color3.fromRGB(34, 197, 94)
		statusBadgeStroke.Color = Color3.fromRGB(34, 197, 94)
		statusBadgeText.TextColor3 = Color3.fromRGB(74, 222, 128)
		statusBadgeText.Text = "🟢 В походе"
	else
		statusBadge.BackgroundColor3 = Color3.fromRGB(168, 85, 247)
		statusBadgeStroke.Color = Color3.fromRGB(168, 85, 247)
		statusBadgeText.TextColor3 = Color3.fromRGB(216, 180, 254)
		statusBadgeText.Text = "💤 На лежанке"
	end

	-- Сытость
	satValLabel.Text = string.format("%d / 100%%", satiety)
	local fillFrac = math.clamp(satiety / 100, 0, 1)

	TweenService:Create(satBarFill, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		Size = UDim2.new(fillFrac, 0, 1, 0)
	}):Play()

	if satiety >= 50 then
		satBarFill.BackgroundColor3 = Color3.fromRGB(34, 197, 94)
		satValLabel.TextColor3 = Color3.fromRGB(74, 222, 128)
		multValLabel.TextColor3 = Color3.fromRGB(74, 222, 128)
		multValLabel.Text = "1.0x (100% полная сила)"
	elseif satiety >= 25 then
		satBarFill.BackgroundColor3 = Color3.fromRGB(245, 158, 11)
		satValLabel.TextColor3 = Color3.fromRGB(251, 191, 36)
		multValLabel.TextColor3 = Color3.fromRGB(251, 191, 36)
		multValLabel.Text = "0.7x (70% ослабленный)"
	elseif satiety > 0 then
		satBarFill.BackgroundColor3 = Color3.fromRGB(239, 68, 68)
		satValLabel.TextColor3 = Color3.fromRGB(248, 113, 113)
		multValLabel.TextColor3 = Color3.fromRGB(248, 113, 113)
		multValLabel.Text = "0.4x (40% сильный голод)"
	else
		satBarFill.BackgroundColor3 = Color3.fromRGB(185, 28, 28)
		satValLabel.TextColor3 = Color3.fromRGB(248, 113, 113)
		multValLabel.TextColor3 = Color3.fromRGB(239, 68, 68)
		multValLabel.Text = "0.0x (Бафф выключен!)"
	end

	-- Баффы
	buffDescLabel.Text = currentPetData.Desc or "Пассивные баффы питомца"
	if mode == "follow" and satiety > 0 then
		buffActiveTag.BackgroundColor3 = Color3.fromRGB(34, 197, 94)
		buffActiveStroke.Color = Color3.fromRGB(34, 197, 94)
		buffActiveText.TextColor3 = Color3.fromRGB(74, 222, 128)
		buffActiveText.Text = "🟢 АКТИВЕН"
	elseif mode == "stay_home" then
		buffActiveTag.BackgroundColor3 = Color3.fromRGB(168, 85, 247)
		buffActiveStroke.Color = Color3.fromRGB(168, 85, 247)
		buffActiveText.TextColor3 = Color3.fromRGB(216, 180, 254)
		buffActiveText.Text = "💤 НА ПАУЗЕ"
	else
		buffActiveTag.BackgroundColor3 = Color3.fromRGB(239, 68, 68)
		buffActiveStroke.Color = Color3.fromRGB(239, 68, 68)
		buffActiveText.TextColor3 = Color3.fromRGB(252, 165, 165)
		buffActiveText.Text = "⚠️ ГОЛОДЕН"
	end

	-- Кнопка переключения режима (Следовать / Спать)
	if mode == "follow" then
		modeActionBtn.BackgroundColor3 = Color3.fromRGB(99, 102, 241)
		modeBtnStroke.Color = Color3.fromRGB(165, 180, 252)
		modeBtnMainText.Text = "💤 ОТПРАВИТЬ СПАТЬ НА ЛЕЖАНКУ"
		modeBtnSubText.Text = "Питомец пойдет на мягкую лежанку в доме и сохранит сытость"
	else
		modeActionBtn.BackgroundColor3 = Color3.fromRGB(16, 185, 129)
		modeBtnStroke.Color = Color3.fromRGB(110, 231, 183)
		modeBtnMainText.Text = "🐾 ПОЗВАТЬ С СОБОЙ В ПОХОД [СЛЕДОВАТЬ]"
		modeBtnSubText.Text = "Питомец побежит за вами и активирует свои полезные баффы"
	end

	-- Список еды для кормления (отображаются ТОЛЬКО те предметы, которые есть в рюкзаке)
	for _, child in ipairs(foodScroll:GetChildren()) do
		if child:IsA("GuiObject") and (child.Name:find("FoodItem_") or child.Name == "EmptyFoodLabel") then
			child:Destroy()
		end
	end

	local availableCount = 0
	local totalWidth = 0

	for _, item in ipairs(ALL_FOODS) do
		local count = getFoodCount(item.Key)
		if count > 0 then
			availableCount = availableCount + 1
			local isFav = favs[item.Key] or false

			local itemBtn = Instance.new("TextButton")
			itemBtn.Name = "FoodItem_" .. item.Key
			itemBtn.Size = UDim2.new(0, 116, 0, 92)
			itemBtn.BorderSizePixel = 0
			itemBtn.AutoButtonColor = true
			itemBtn.Text = ""
			itemBtn.Parent = foodScroll

			local itemCorner = Instance.new("UICorner", itemBtn)
			itemCorner.CornerRadius = UDim.new(0, 10)

			local itemStroke = Instance.new("UIStroke", itemBtn)
			itemStroke.Thickness = 1.4

			if isFav then
				itemBtn.BackgroundColor3 = Color3.fromRGB(45, 26, 52)
				itemStroke.Color = Color3.fromRGB(244, 114, 182)
			else
				itemBtn.BackgroundColor3 = Color3.fromRGB(24, 34, 53)
				itemStroke.Color = Color3.fromRGB(56, 189, 248)
			end

			-- Иконка еды
			local iconLbl = Instance.new("TextLabel", itemBtn)
			iconLbl.Size = UDim2.new(1, 0, 0, 28)
			iconLbl.Position = UDim2.new(0, 0, 0, 6)
			iconLbl.BackgroundTransparency = 1
			iconLbl.Font = Enum.Font.GothamBold
			iconLbl.TextSize = 22
			iconLbl.Text = item.Emoji

			-- Название еды и количество
			local nameLbl = Instance.new("TextLabel", itemBtn)
			nameLbl.Size = UDim2.new(1, -6, 0, 18)
			nameLbl.Position = UDim2.new(0, 3, 0, 36)
			nameLbl.BackgroundTransparency = 1
			nameLbl.Font = Enum.Font.GothamBold
			nameLbl.TextSize = 11
			nameLbl.TextColor3 = Color3.fromRGB(241, 245, 249)
			nameLbl.Text = string.format("%s (x%d)", item.Name, count)

			-- Бейдж сытости (+65% Любимое vs +30%)
			local gainBadge = Instance.new("TextLabel", itemBtn)
			gainBadge.Size = UDim2.new(1, -10, 0, 20)
			gainBadge.Position = UDim2.new(0, 5, 0, 58)
			gainBadge.BackgroundColor3 = isFav and Color3.fromRGB(244, 63, 94) or Color3.fromRGB(30, 41, 59)
			gainBadge.BackgroundTransparency = isFav and 0.2 or 0.5
			gainBadge.Font = Enum.Font.GothamBold
			gainBadge.TextSize = 9
			gainBadge.TextColor3 = isFav and Color3.fromRGB(255, 241, 242) or Color3.fromRGB(148, 163, 184)
			gainBadge.Text = isFav and "❤️ Любимое +65%" or "+30% сытости"
			Instance.new("UICorner", gainBadge).CornerRadius = UDim.new(0, 6)

			itemBtn.MouseButton1Click:Connect(function()
				FeedPetRemote:FireServer(pId, item.Key)
				-- Анимация клика
				TweenService:Create(itemBtn, TweenInfo.new(0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
					Size = UDim2.new(0, 110, 0, 86)
				}):Play()
				task.wait(0.1)
				TweenService:Create(itemBtn, TweenInfo.new(0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
					Size = UDim2.new(0, 116, 0, 92)
				}):Play()
				task.wait(0.15)
				refreshPetUI()
			end)

			totalWidth = totalWidth + 124
		end
	end

	if availableCount == 0 then
		local emptyLabel = Instance.new("TextLabel")
		emptyLabel.Name = "EmptyFoodLabel"
		emptyLabel.Size = UDim2.new(1, -10, 1, -10)
		emptyLabel.Position = UDim2.new(0, 5, 0, 5)
		emptyLabel.BackgroundTransparency = 1
		emptyLabel.Font = Enum.Font.GothamMedium
		emptyLabel.TextSize = 12
		emptyLabel.TextColor3 = Color3.fromRGB(148, 163, 184)
		emptyLabel.TextWrapped = true
		emptyLabel.Text = "🎒 В рюкзаке сейчас нет подходящей еды\n(Соберите стейк, суп, хлеб, чипсы, батончик или перец)"
		emptyLabel.Parent = foodScroll
		foodScroll.CanvasSize = UDim2.new(1, 0, 0, 0)
	else
		foodScroll.CanvasSize = UDim2.new(0, math.max(totalWidth + 10, 480), 0, 0)
	end
end

-- Открытие модального окна
local function openPetMenu(data)
	currentPetData = data
	refreshPetUI()
	screenGui.Enabled = true

	modalFrame.Position = UDim2.new(0.5, 0, 0.55, 0)
	modalFrame.BackgroundTransparency = 1
	modalStroke.Transparency = 1

	TweenService:Create(modalFrame, TweenInfo.new(0.25, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
		Position = UDim2.new(0.5, 0, 0.5, 0),
		BackgroundTransparency = 0
	}):Play()
	TweenService:Create(modalStroke, TweenInfo.new(0.25), { Transparency = 0 }):Play()
end

-- Закрытие модального окна
local function closePetMenu()
	if not screenGui.Enabled then return end
	TweenService:Create(modalFrame, TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
		Position = UDim2.new(0.5, 0, 0.55, 0),
		BackgroundTransparency = 1
	}):Play()
	task.wait(0.18)
	screenGui.Enabled = false
	currentPetData = nil
end

-- Обработка главной кнопки переключения режима
modeActionBtn.MouseButton1Click:Connect(function()
	if not currentPetData then return end
	TogglePetModeRemote:FireServer(currentPetData.PetId)
	
	-- Локальное мгновенное обновление
	currentPetData.Mode = (currentPetData.Mode == "follow") and "stay_home" or "follow"
	currentPetData.IsSleeping = (currentPetData.Mode == "stay_home")
	refreshPetUI()
end)

closeBtn.MouseButton1Click:Connect(closePetMenu)
overlay.MouseButton1Click:Connect(closePetMenu)

-- Слушатели сетевых событий
OpenPetMenuRemote.OnClientEvent:Connect(function(petData)
	openPetMenu(petData)
end)

UpdatePetDataRemote.OnClientEvent:Connect(function(updatedData)
	if currentPetData and currentPetData.PetId == updatedData.PetId then
		currentPetData = updatedData
		refreshPetUI()
	end
end)

-- Горячие клавиши (E, ESC закрывают меню)
UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if not screenGui.Enabled then return end
	if input.KeyCode == Enum.KeyCode.Escape or input.KeyCode == Enum.KeyCode.E then
		closePetMenu()
	end
end)

-- Закрытие окна при значительном отдалении от питомца
RunService.Heartbeat:Connect(function()
	if not screenGui.Enabled or not currentPetData then return end
	local char = player.Character
	local hrp = char and char:FindFirstChild("HumanoidRootPart")
	if not hrp then return end

	local petsFolder = workspace:FindFirstChild("Pets")
	if not petsFolder then return end

	local targetPet = nil
	for _, p in ipairs(petsFolder:GetChildren()) do
		if p:GetAttribute("OwnerUserId") == player.UserId and p:GetAttribute("PetId") == currentPetData.PetId then
			targetPet = p
			break
		end
	end

	if targetPet then
		local petHrp = targetPet:FindFirstChild("HumanoidRootPart") or targetPet.PrimaryPart
		if petHrp then
			local dist = (petHrp.Position - hrp.Position).Magnitude
			if dist > 22 then
				closePetMenu()
			end
		end
	end
end)

print("🐾 [PetMenuController] Меню управления питомцами (Еда*Множитель, Баффы, Режим) готово!")
