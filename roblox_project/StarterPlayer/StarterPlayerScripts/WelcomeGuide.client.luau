--[[
    WelcomeGuide.client.luau
    Клиентский интерфейс Ознакомления и Обучения (Welcome & Onboarding Guide ScreenGui):
    - 5 Интерактивных Вкладок: Цель, Управление, Тепло/Сытость, Верстак/Дом, Питомцы
    - Автоматический показ при первом входе игрока
    - Кнопка закрытия "🚀 Начать выживание!"
--]]

local Players = game:GetService("Players")
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local guideGui = Instance.new("ScreenGui")
guideGui.Name = "WelcomeGuideGui"
guideGui.ResetOnSpawn = false
guideGui.Parent = playerGui

local mainFrame = Instance.new("Frame")
mainFrame.Name = "MainFrame"
mainFrame.Size = UDim2.new(0, 680, 0, 440)
mainFrame.Position = UDim2.new(0.5, -340, 0.5, -220)
mainFrame.BackgroundColor3 = Color3.fromRGB(15, 23, 42)
mainFrame.BackgroundTransparency = 0.05
mainFrame.BorderSizePixel = 2
mainFrame.BorderColor3 = Color3.fromRGB(56, 189, 248)
mainFrame.Visible = true -- Автоматически открывается при входе!
mainFrame.Parent = guideGui

local mfCorner = Instance.new("UICorner", mainFrame)
mfCorner.CornerRadius = UDim.new(0, 16)

-- Шапка
local header = Instance.new("Frame")
header.Size = UDim2.new(1, 0, 0, 50)
header.BackgroundColor3 = Color3.fromRGB(30, 58, 138)
header.BackgroundTransparency = 0.5
header.BorderSizePixel = 0
header.Parent = mainFrame
Instance.new("UICorner", header).CornerRadius = UDim.new(0, 16)

local titleLabel = Instance.new("TextLabel")
titleLabel.Size = UDim2.new(1, -60, 1, 0)
titleLabel.Position = UDim2.new(0, 20, 0, 0)
titleLabel.BackgroundTransparency = 1
titleLabel.Font = Enum.Font.GothamBlack
titleLabel.TextSize = 16
titleLabel.TextColor3 = Color3.fromRGB(56, 189, 248)
titleLabel.TextXAlignment = Enum.TextXAlignment.Left
titleLabel.Text = "❄️ ВЫЖИТЬ В ХОЛОДЕ: 7 РЕЛИКВИЙ (ГИД ВЫЖИВАЮЩЕГО)"
titleLabel.Parent = header

local closeBtn = Instance.new("TextButton")
closeBtn.Size = UDim2.new(0, 30, 0, 30)
closeBtn.Position = UDim2.new(1, -40, 0, 10)
closeBtn.BackgroundColor3 = Color3.fromRGB(51, 65, 85)
closeBtn.Font = Enum.Font.GothamBold
closeBtn.TextSize = 14
closeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
closeBtn.Text = "✕"
closeBtn.Parent = header
Instance.new("UICorner", closeBtn).CornerRadius = UDim.new(0, 6)

-- Панель переключения вкладок
local tabsBar = Instance.new("Frame")
tabsBar.Size = UDim2.new(1, -40, 0, 36)
tabsBar.Position = UDim2.new(0, 20, 0, 60)
tabsBar.BackgroundTransparency = 1
tabsBar.Parent = mainFrame

local tabsLayout = Instance.new("UIListLayout", tabsBar)
tabsLayout.FillDirection = Enum.FillDirection.Horizontal
tabsLayout.Padding = UDim.new(0, 8)

-- Контейнер для текста вкладок
local contentFrame = Instance.new("Frame")
contentFrame.Size = UDim2.new(1, -40, 1, -170)
contentFrame.Position = UDim2.new(0, 20, 0, 105)
contentFrame.BackgroundColor3 = Color3.fromRGB(30, 41, 59)
contentFrame.BackgroundTransparency = 0.5
contentFrame.BorderSizePixel = 0
contentFrame.Parent = mainFrame
Instance.new("UICorner", contentFrame).CornerRadius = UDim.new(0, 12)

local contentText = Instance.new("TextLabel")
contentText.Size = UDim2.new(1, -24, 1, -24)
contentText.Position = UDim2.new(0, 12, 0, 12)
contentText.BackgroundTransparency = 1
contentText.Font = Enum.Font.Gotham
contentText.TextSize = 12
contentText.TextColor3 = Color3.fromRGB(226, 232, 240)
contentText.TextXAlignment = Enum.TextXAlignment.Left
contentText.TextYAlignment = Enum.TextYAlignment.Top
contentText.TextWrapped = true
contentText.Parent = contentFrame

-- Данные вкладок
local TABS_DATA = {
	{
		Title = "🎯 1. Цель игры",
		Body = "🗺️ Исследуйте бескрайний заснеженный мир.\n\n" ..
		       "💎 1. Найдите 7 Реликвий, разбросанных в опасных уголках карты. Снежный Лис поможет компасом-радаром!\n\n" ..
		       "⛩️ 2. Освятите их на Древнем Алтаре (X: -60, Z: 80) на клавишу [E]. Каждая реликвия продлевает день и согревает округу!\n\n" ..
		       "🚪 3. Эвакуируйтесь через Бункер Перерождения (X: 180, Z: 120), чтобы получить вечную прибавку к скорости и новый титул!"
	},
	{
		Title = "🎮 2. Управление",
		Body = "🏃 ПЕРЕДВИЖЕНИЕ:\n" ..
		       "• W, A, S, D / Стрелочки — Ходьба\n" ..
		       "• Shift — Спринт (тратит ⚡ Стамину. При 0% наступает одышка до 20%)\n\n" ..
		       "✋ ВЗАИМОДЕЙСТВИЕ И БОЙ:\n" ..
		       "• [E] — Подобрать предмет, открыть сундук деталей, верстак, магазины, костер\n" ..
		       "• [ЛКМ] — Рубка деревьев, камней, атака оружием, кормление\n" ..
		       "• [1..9] — Выбор слота в хотбаре | [G] — Выбросить 1 предмет\n" ..
		       "• [F] — Быстро покормить питомца | [T] — Переключить режим (Поход / Дом)"
	},
	{
		Title = "🍗 3. Тепло и Сытость",
		Body = "🔥 ТЕПЛО (WARMTH):\n" ..
		       "• На морозе шкала падает. Грейтесь у костров, в жилом доме, магазинах и носите теплую одежду.\n" ..
		       "• Держите в руках 🔥 Факел (+1.5 тепла) или берите 🐻 Медвежонка (+3.5 тепла).\n\n" ..
		       "🍗 СЫТОСТЬ (HUNGER):\n" ..
		       "• Полной шкалы 100% хватает на 5-6 минут. При сытости > 65% и тепле > 60% идет авто-регенерация HP!\n" ..
		       "• В Продуктовом магазине (на западе) всегда доступен 🎉 Бесплатный паёк 🍫!"
	},
	{
		Title = "🛠️ 4. Верстак и Дом",
		Body = "🏡 ЖИЛОЙ ДОМ:\n" ..
		       "• Почините дом за 3 Доски. Главное правило: при смерти рюкзак теряется, но ВСЁ ВНУТРИ ДОМА СОХРАНЯЕТСЯ НАВСЕГДА!\n\n" ..
		       "⚙️ СУНДУКИ ДЕТАЛЕЙ (16 шт на карте):\n" ..
		       "• Дают 1–2 детали для прокачки верстака и авто-турелей!\n\n" ..
		       "🏹 СУМКА БОЕПРИПАСОВ (AMMO POUCH):\n" ..
		       "• Снаряды для рогатки (🪨) и пули (💥) НЕ занимают слоты инвентаря!"
	},
	{
		Title = "🦊 5. Питомцы",
		Body = "🧊 СПАСЕНИЕ ИЗ ЛЬДА: Отогрейте закованное животное горящим Факелом!\n\n" ..
		       "🦊 СНЕЖНЫЙ ЛИС: +35% стамины + Радар-компас к ближайшей реликвии!\n" ..
		       "🐺 ЛЕДЯНОЙ ВОЛК: +25% урона оружием + 10% скорости бега!\n" ..
		       "🐻 ПОЛЯРНЫЙ МЕДВЕДЬ: +3.5 постоянного тепла даже в бурю!\n\n" ..
		       "⚠️ КОРМЛЕНИЕ [F]: При 0% сытости питомец голодает и через 60 сек уйдёт в дикий лес! Клавишей [T] отправляйте его на лежанку в дом."
	}
}

local tabButtons = {}

local function selectTab(idx)
	for i, btn in ipairs(tabButtons) do
		if i == idx then
			btn.BackgroundColor3 = Color3.fromRGB(2, 132, 199)
			btn.TextColor3 = Color3.fromRGB(255, 255, 255)
		else
			btn.BackgroundColor3 = Color3.fromRGB(15, 23, 42)
			btn.TextColor3 = Color3.fromRGB(148, 163, 184)
		end
	end
	contentText.Text = TABS_DATA[idx].Body
end

for i, tData in ipairs(TABS_DATA) do
	local tBtn = Instance.new("TextButton")
	tBtn.Size = UDim2.new(0, 120, 1, 0)
	tBtn.BackgroundColor3 = Color3.fromRGB(15, 23, 42)
	tBtn.Font = Enum.Font.GothamBold
	tBtn.TextSize = 11
	tBtn.TextColor3 = Color3.fromRGB(148, 163, 184)
	tBtn.Text = tData.Title
	tBtn.Parent = tabsBar
	Instance.new("UICorner", tBtn).CornerRadius = UDim.new(0, 8)

	tBtn.MouseButton1Click:Connect(function()
		selectTab(i)
	end)
	table.insert(tabButtons, tBtn)
end

selectTab(1)

-- Нижняя кнопка старта
local startBtn = Instance.new("TextButton")
startBtn.Size = UDim2.new(0, 220, 0, 36)
startBtn.Position = UDim2.new(0.5, -110, 1, -50)
startBtn.BackgroundColor3 = Color3.fromRGB(22, 163, 74)
startBtn.Font = Enum.Font.GothamBlack
startBtn.TextSize = 13
startBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
startBtn.Text = "🚀 Начать выживание!"
startBtn.Parent = mainFrame
Instance.new("UICorner", startBtn).CornerRadius = UDim.new(0, 10)

startBtn.MouseButton1Click:Connect(function()
	mainFrame.Visible = false
end)

closeBtn.MouseButton1Click:Connect(function()
	mainFrame.Visible = false
end)
