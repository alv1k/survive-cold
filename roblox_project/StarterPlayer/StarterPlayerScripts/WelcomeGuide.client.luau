--[[
    WelcomeGuide.client.luau
    Клиентский интерфейс Ознакомления и Обучения (Welcome & Onboarding Guide):
    - ✖ Заметная кнопка закрытия (крестик) в правом верхнем углу
    - ➡️ Кнопка "Далее ➔" с иконками для пошагового обучения
    - 5 Интерактивных Вкладок: Цель, Управление, Тепло/Сытость, Верстак/Дом, Питомцы
    - Автоматический показ при первом входе игрока (сохраняет 100% показатели до старта)
--]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local player = Players.LocalPlayer

local RemotesFolder = ReplicatedStorage:WaitForChild("Remotes", 10)
local StartGameRemote = RemotesFolder and RemotesFolder:WaitForChild("StartGame", 10)
local playerGui = player:WaitForChild("PlayerGui")

local guideGui = Instance.new("ScreenGui")
guideGui.Name = "WelcomeGuideGui"
guideGui.ResetOnSpawn = false
guideGui.Parent = playerGui

local mainFrame = Instance.new("Frame")
mainFrame.Name = "MainFrame"
mainFrame.Size = UDim2.new(0, 700, 0, 460)
mainFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
mainFrame.AnchorPoint = Vector2.new(0.5, 0.5)
mainFrame.BackgroundColor3 = Color3.fromRGB(15, 23, 42)
mainFrame.BackgroundTransparency = 0.05
mainFrame.BorderSizePixel = 0
mainFrame.Visible = true -- Автоматически открывается при входе
mainFrame.Parent = guideGui
Instance.new("UICorner", mainFrame).CornerRadius = UDim.new(0, 16)

local mfStroke = Instance.new("UIStroke", mainFrame)
mfStroke.Color = Color3.fromRGB(56, 189, 248)
mfStroke.Thickness = 2

-- 1. Шапка с заголовком и КРЕСТИКОМ ЗАКРЫТИЯ
local header = Instance.new("Frame")
header.Size = UDim2.new(1, 0, 0, 54)
header.BackgroundColor3 = Color3.fromRGB(30, 58, 138)
header.BackgroundTransparency = 0.4
header.BorderSizePixel = 0
header.Parent = mainFrame
Instance.new("UICorner", header).CornerRadius = UDim.new(0, 16)

local titleLabel = Instance.new("TextLabel")
titleLabel.Size = UDim2.new(1, -90, 1, 0)
titleLabel.Position = UDim2.new(0, 20, 0, 0)
titleLabel.BackgroundTransparency = 1
titleLabel.Font = Enum.Font.GothamBlack
titleLabel.TextSize = 15
titleLabel.TextColor3 = Color3.fromRGB(56, 189, 248)
titleLabel.TextXAlignment = Enum.TextXAlignment.Left
titleLabel.Text = "❄️ ВЫЖИТЬ В ХОЛОДЕ: 7 РЕЛИКВИЙ (ГИД ВЫЖИВАЮЩЕГО)"
titleLabel.Parent = header

-- ✖ ИКОНКА КРЕСТИКА ЗАКРЫТИЯ (Красный акцент)
local closeBtn = Instance.new("TextButton")
closeBtn.Name = "CloseButton"
closeBtn.Size = UDim2.new(0, 36, 0, 36)
closeBtn.Position = UDim2.new(1, -48, 0.5, 0)
closeBtn.AnchorPoint = Vector2.new(0, 0.5)
closeBtn.BackgroundColor3 = Color3.fromRGB(220, 38, 38)
closeBtn.Font = Enum.Font.GothamBold
closeBtn.TextSize = 18
closeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
closeBtn.Text = "✕"
closeBtn.Parent = header
Instance.new("UICorner", closeBtn).CornerRadius = UDim.new(0, 10)

local closeStroke = Instance.new("UIStroke", closeBtn)
closeStroke.Color = Color3.fromRGB(254, 202, 202)
closeStroke.Thickness = 1.5

-- 2. Панель переключения вкладок
local tabsBar = Instance.new("Frame")
tabsBar.Size = UDim2.new(1, -40, 0, 38)
tabsBar.Position = UDim2.new(0, 20, 0, 66)
tabsBar.BackgroundTransparency = 1
tabsBar.Parent = mainFrame

local tabsLayout = Instance.new("UIListLayout", tabsBar)
tabsLayout.FillDirection = Enum.FillDirection.Horizontal
tabsLayout.Padding = UDim.new(0, 8)

-- 3. Контейнер для текста вкладок
local contentFrame = Instance.new("Frame")
contentFrame.Size = UDim2.new(1, -40, 1, -185)
contentFrame.Position = UDim2.new(0, 20, 0, 114)
contentFrame.BackgroundColor3 = Color3.fromRGB(30, 41, 59)
contentFrame.BackgroundTransparency = 0.5
contentFrame.BorderSizePixel = 0
contentFrame.Parent = mainFrame
Instance.new("UICorner", contentFrame).CornerRadius = UDim.new(0, 12)

local contentText = Instance.new("TextLabel")
contentText.Size = UDim2.new(1, -28, 1, -28)
contentText.Position = UDim2.new(0, 14, 0, 14)
contentText.BackgroundTransparency = 1
contentText.Font = Enum.Font.Gotham
contentText.TextSize = 13
contentText.TextColor3 = Color3.fromRGB(226, 232, 240)
contentText.TextXAlignment = Enum.TextXAlignment.Left
contentText.TextYAlignment = Enum.TextYAlignment.Top
contentText.TextWrapped = true
contentText.Parent = contentFrame

-- Данные вкладок
local TABS_DATA = {
	{
		Title = "🎯 1. Цель",
		Body = "🗺️ Исследуйте бескрайний заснеженный мир.

" ..
		       "💎 1. Найдите 7 Реликвий, разбросанных в опасных уголках карты. Снежный Лис поможет компасом-радаром!

" ..
		       "⛩️ 2. Освятите их на Древнем Алтаре (X: -60, Z: 80). Каждая реликвия продлевает день и согревает округу!

" ..
		       "🚪 3. Эвакуируйтесь через Бункер Перерождения (X: 180, Z: 120), чтобы получить очки вечных талантов (до 15 уровней)!"
	},
	{
		Title = "🎮 2. Управление",
		Body = "🏃 ПЕРЕДВИЖЕНИЕ:
" ..
		       "• W, A, S, D / Стрелочки — Ходьба
" ..
		       "• Shift — Спринт (тратит ⚡ Стамину)

" ..
		       "✋ ВЗАИМОДЕЙСТВИЕ И БОЙ:
" ..
		       "• [ЛКМ (4 клика)] — Рубка деревьев, камней, кустов и веток для сбора ресурсов!
" ..
		       "• [1..9] — Выбор слота в хотбаре по центру снизу | [G] — Выбросить 1 предмет
" ..
		       "• [F] — Быстро покормить питомца | [T] — Переключить режим (Поход / Дом)
" ..
		       "• [E] — Открыть верстак, сундуки деталей, магазины одежды и продуктов"
	},
	{
		Title = "🍗 3. Тепло и Сытость",
		Body = "🔥 ТЕПЛО (WARMTH):
" ..
		       "• На морозе шкала падает. Грейтесь у костров, в жилом доме, магазинах и носите теплую одежду.
" ..
		       "• Держите в руках 🔥 Факел (+1.5 тепла) или берите 🐻 Медвежонка (+3.5 тепла).

" ..
		       "🍗 СЫТОСТЬ (HUNGER):
" ..
		       "• Полной шкалы 100% хватает на 5-6 минут. При сытости > 65% и тепле > 60% идет авто-регенерация HP!
" ..
		       "• В Продуктовом магазине (на западе) всегда доступен 🎉 Бесплатный паёк 🍫!"
	},
	{
		Title = "🛠️ 4. Верстак и Дом",
		Body = "🏡 ЖИЛОЙ ДОМ:
" ..
		       "• Спавн происходит внутри дома. При смерти рюкзак теряется, но ВСЁ ВНУТРИ ДОМА СОХРАНЯЕТСЯ НАВСЕГДА!

" ..
		       "⚙️ СУНДУКИ ДЕТАЛЕЙ (16 шт на карте):
" ..
		       "• Дают 1–2 детали для прокачки верстака и авто-турелей!

" ..
		       "🏹 СУМКА БОЕПРИПАСОВ (AMMO POUCH):
" ..
		       "• Снаряды для рогатки (🪨) и патроны револьвера (💥) НЕ занимают слоты инвентаря!"
	},
	{
		Title = "🦊 5. Питомцы",
		Body = "🧊 СПАСЕНИЕ ИЗ ЛЬДА: Отогрейте закованное животное горящим Факелом!

" ..
		       "🦊 СНЕЖНЫЙ ЛИС: +35% стамины + Радар-компас к ближайшей реликвии!
" ..
		       "🐺 ЛЕДЯНОЙ ВОЛК: +25% урона оружием + 10% скорости бега!
" ..
		       "🐻 ПОЛЯРНЫЙ МЕДВЕДЬ: +3.5 постоянного тепла даже в бурю!

" ..
		       "⚠️ КОРМЛЕНИЕ [F]: При 0% сытости питомец голодает. Клавишей [T] отправляйте его на лежанку в дом."
	}
}

local tabButtons = {}
local currentTabIdx = 1
local totalTabs = #TABS_DATA

local function selectTab(idx)
	currentTabIdx = math.clamp(idx, 1, totalTabs)
	for i, btn in ipairs(tabButtons) do
		if i == currentTabIdx then
			btn.BackgroundColor3 = Color3.fromRGB(2, 132, 199)
			btn.TextColor3 = Color3.fromRGB(255, 255, 255)
		else
			btn.BackgroundColor3 = Color3.fromRGB(15, 23, 42)
			btn.TextColor3 = Color3.fromRGB(148, 163, 184)
		end
	end
	contentText.Text = TABS_DATA[currentTabIdx].Body
end

for i, tData in ipairs(TABS_DATA) do
	local tBtn = Instance.new("TextButton")
	tBtn.Size = UDim2.new(0, 120, 1, 0)
	tBtn.BackgroundColor3 = Color3.fromRGB(15, 23, 42)
	tBtn.Font = Enum.Font.GothamBold
	tBtn.TextSize = 11.5
	tBtn.TextColor3 = Color3.fromRGB(148, 163, 184)
	tBtn.Text = tData.Title
	tBtn.Parent = tabsBar
	Instance.new("UICorner", tBtn).CornerRadius = UDim.new(0, 8)

	tBtn.MouseButton1Click:Connect(function()
		selectTab(i)
	end)
	table.insert(tabButtons, tBtn)
end

-- 4. НИЖНЯЯ ПАНЕЛЬ С КНОПКОЙ "➡️ ДАЛЕЕ"
local stepLabel = Instance.new("TextLabel")
stepLabel.Size = UDim2.new(0, 200, 0, 40)
stepLabel.Position = UDim2.new(0, 20, 1, -54)
stepLabel.BackgroundTransparency = 1
stepLabel.Font = Enum.Font.GothamBold
stepLabel.TextSize = 12
stepLabel.TextColor3 = Color3.fromRGB(148, 163, 184)
stepLabel.TextXAlignment = Enum.TextXAlignment.Left
stepLabel.Text = "💡 Совет 1 из 5"
stepLabel.Parent = mainFrame

local prevBtn = Instance.new("TextButton")
prevBtn.Name = "PrevButton"
prevBtn.Size = UDim2.new(0, 110, 0, 40)
prevBtn.Position = UDim2.new(1, -280, 1, -54)
prevBtn.BackgroundColor3 = Color3.fromRGB(51, 65, 85)
prevBtn.Font = Enum.Font.GothamBold
prevBtn.TextSize = 12
prevBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
prevBtn.Text = "◀ Назад"
prevBtn.Visible = false
prevBtn.Parent = mainFrame
Instance.new("UICorner", prevBtn).CornerRadius = UDim.new(0, 10)

-- ➡️ ИКОНКА КНОПКИ ДАЛЕЕ
local nextBtn = Instance.new("TextButton")
nextBtn.Name = "NextButton"
nextBtn.Size = UDim2.new(0, 145, 0, 40)
nextBtn.Position = UDim2.new(1, -165, 1, -54)
nextBtn.BackgroundColor3 = Color3.fromRGB(2, 132, 199)
nextBtn.Font = Enum.Font.GothamBlack
nextBtn.TextSize = 13
nextBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
nextBtn.Text = "➡️ Далее ➔"
nextBtn.Parent = mainFrame
Instance.new("UICorner", nextBtn).CornerRadius = UDim.new(0, 10)

local nextStroke = Instance.new("UIStroke", nextBtn)
nextStroke.Color = Color3.fromRGB(56, 189, 248)
nextStroke.Thickness = 1.5

local function updateNav()
	stepLabel.Text = string.format("💡 Совет %d из %d", currentTabIdx, totalTabs)
	prevBtn.Visible = (currentTabIdx > 1)
	if currentTabIdx == totalTabs then
		nextBtn.Text = "🚀 Начать!"
		nextBtn.BackgroundColor3 = Color3.fromRGB(22, 163, 74)
		nextStroke.Color = Color3.fromRGB(74, 222, 128)
	else
		nextBtn.Text = "➡️ Далее ➔"
		nextBtn.BackgroundColor3 = Color3.fromRGB(2, 132, 199)
		nextStroke.Color = Color3.fromRGB(56, 189, 248)
	end
end

local origSelect = selectTab
selectTab = function(idx)
	origSelect(idx)
	updateNav()
end
selectTab(1)

local function closeAndStartGame()
	mainFrame.Visible = false
	player:SetAttribute("IsGameStarted", true)
	if StartGameRemote then
		pcall(function()
			StartGameRemote:FireServer()
		end)
	end
end

nextBtn.MouseButton1Click:Connect(function()
	if currentTabIdx < totalTabs then
		selectTab(currentTabIdx + 1)
	else
		closeAndStartGame()
	end
end)

prevBtn.MouseButton1Click:Connect(function()
	if currentTabIdx > 1 then
		selectTab(currentTabIdx - 1)
	end
end)

closeBtn.MouseButton1Click:Connect(function()
	closeAndStartGame()
end)
