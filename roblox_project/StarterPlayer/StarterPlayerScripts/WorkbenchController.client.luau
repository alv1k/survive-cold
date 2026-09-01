--[[
    WorkbenchController.client.luau
    Клиентский интерфейс Верстака (5 Уровней Крафта) с чистой ИКОНОЧНОЙ версткой:
    - Без лишних слов: только иконки и числа (🌿 3/3  ⚪ 2/2  🌱 2/2  🌲 1/1)
    - Камень = серый кружочек (⚪)
    - Сортировка строго по уровню 1 -> 5
--]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ProximityPromptService = game:GetService("ProximityPromptService")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local CraftingRecipes = require(ReplicatedStorage:WaitForChild("CraftingRecipes"))

local RemotesFolder = ReplicatedStorage:WaitForChild("Remotes", 10)
local CraftItemRemote = RemotesFolder and RemotesFolder:WaitForChild("CraftItem", 10)
local UpgradeWorkbenchRemote = RemotesFolder and RemotesFolder:WaitForChild("UpgradeWorkbench", 10)

local ICON_MAP = {
	Branches = "🌿",
	Fiber = "🌱",
	Stone = "⚪",
	Planks = "🌲",
	Parts = "⚙️",
	WolfPelt = "🐺",
	YetiPelt = "❄️",
	Torch = "🔥"
}

-- Создание ScreenGui
local wbGui = Instance.new("ScreenGui")
wbGui.Name = "WorkbenchGui"
wbGui.ResetOnSpawn = false
wbGui.Parent = playerGui

local mainFrame = Instance.new("Frame")
mainFrame.Name = "WorkbenchFrame"
mainFrame.Size = UDim2.new(0, 740, 0, 480)
mainFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
mainFrame.AnchorPoint = Vector2.new(0.5, 0.5)
mainFrame.BackgroundColor3 = Color3.fromRGB(15, 23, 42)
mainFrame.BackgroundTransparency = 0.05
mainFrame.BorderSizePixel = 0
mainFrame.Visible = false
mainFrame.Parent = wbGui
Instance.new("UICorner", mainFrame).CornerRadius = UDim.new(0, 16)

local mfStroke = Instance.new("UIStroke", mainFrame)
mfStroke.Color = Color3.fromRGB(56, 189, 248)
mfStroke.Thickness = 2

-- 1. Шапка
local header = Instance.new("Frame")
header.Size = UDim2.new(1, 0, 0, 52)
header.BackgroundColor3 = Color3.fromRGB(30, 58, 138)
header.BackgroundTransparency = 0.4
header.BorderSizePixel = 0
header.Parent = mainFrame
Instance.new("UICorner", header).CornerRadius = UDim.new(0, 16)

local titleLabel = Instance.new("TextLabel")
titleLabel.Name = "Title"
titleLabel.Size = UDim2.new(1, -260, 1, 0)
titleLabel.Position = UDim2.new(0, 20, 0, 0)
titleLabel.BackgroundTransparency = 1
titleLabel.Font = Enum.Font.GothamBlack
titleLabel.TextSize = 15
titleLabel.TextColor3 = Color3.fromRGB(56, 189, 248)
titleLabel.TextXAlignment = Enum.TextXAlignment.Left
titleLabel.Text = "🛠️ ВЕРСТАК (УРОВЕНЬ 1/5)"
titleLabel.Parent = header

-- Кнопка улучшения верстака
local upgradeBtn = Instance.new("TextButton")
upgradeBtn.Name = "UpgradeBtn"
upgradeBtn.Size = UDim2.new(0, 175, 0, 34)
upgradeBtn.Position = UDim2.new(1, -225, 0.5, 0)
upgradeBtn.AnchorPoint = Vector2.new(0, 0.5)
upgradeBtn.BackgroundColor3 = Color3.fromRGB(16, 185, 129)
upgradeBtn.Font = Enum.Font.GothamBold
upgradeBtn.TextSize = 12
upgradeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
upgradeBtn.Text = "⬆️ 2 ⚙️ + 3 🌲"
upgradeBtn.Parent = header
Instance.new("UICorner", upgradeBtn).CornerRadius = UDim.new(0, 8)

-- Крестик закрытия
local closeBtn = Instance.new("TextButton")
closeBtn.Name = "CloseBtn"
closeBtn.Size = UDim2.new(0, 34, 0, 34)
closeBtn.Position = UDim2.new(1, -42, 0.5, 0)
closeBtn.AnchorPoint = Vector2.new(0, 0.5)
closeBtn.BackgroundColor3 = Color3.fromRGB(220, 38, 38)
closeBtn.Font = Enum.Font.GothamBold
closeBtn.TextSize = 17
closeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
closeBtn.Text = "✕"
closeBtn.Parent = header
Instance.new("UICorner", closeBtn).CornerRadius = UDim.new(0, 10)

-- 2. Вкладки категорий
local catBar = Instance.new("Frame")
catBar.Size = UDim2.new(1, -36, 0, 34)
catBar.Position = UDim2.new(0, 18, 0, 62)
catBar.BackgroundTransparency = 1
catBar.Parent = mainFrame

local catLayout = Instance.new("UIListLayout", catBar)
catLayout.FillDirection = Enum.FillDirection.Horizontal
catLayout.Padding = UDim.new(0, 8)

local CATEGORIES = {
	{ Id = "All", Name = "📋 Все" },
	{ Id = "Weapons", Name = "🗡️ Оружие" },
	{ Id = "Gear", Name = "⛺ Выживание" },
	{ Id = "Structures", Name = "🛡️ Оборона" }
}

local selectedCategory = "All"
local catButtons = {}

-- 3. Скролл-список рецептов
local scrollFrame = Instance.new("ScrollingFrame")
scrollFrame.Name = "RecipesScroll"
scrollFrame.Size = UDim2.new(1, -36, 1, -112)
scrollFrame.Position = UDim2.new(0, 18, 0, 102)
scrollFrame.BackgroundColor3 = Color3.fromRGB(30, 41, 59)
scrollFrame.BackgroundTransparency = 0.5
scrollFrame.BorderSizePixel = 0
scrollFrame.ScrollBarThickness = 6
scrollFrame.ScrollBarImageColor3 = Color3.fromRGB(56, 189, 248)
scrollFrame.Parent = mainFrame
Instance.new("UICorner", scrollFrame).CornerRadius = UDim.new(0, 12)

local gridLayout = Instance.new("UIGridLayout", scrollFrame)
gridLayout.CellSize = UDim2.new(0, 335, 0, 88)
gridLayout.CellPadding = UDim2.new(0, 10, 0, 10)

local function renderRecipes()
	for _, child in ipairs(scrollFrame:GetChildren()) do
		if child:IsA("Frame") then child:Destroy() end
	end

	local curWbLvl = player:GetAttribute("WorkbenchLevel") or 1
	titleLabel.Text = string.format("🛠️ ВЕРСТАК (УРОВЕНЬ %d/5)", curWbLvl)

	local tierCfg = CraftingRecipes.WorkbenchTiers[curWbLvl]
	if tierCfg and tierCfg.UpgradeCostText and tierCfg.UpgradeCost then
		upgradeBtn.Visible = true
		upgradeBtn.Text = "⬆️ " .. tierCfg.UpgradeCostText
	else
		upgradeBtn.Visible = false
	end

	local sortedList = {}
	for rKey, rData in pairs(CraftingRecipes.Recipes) do
		-- Проверяем, доступен ли крафт прямо сейчас (хватает уровня верстака и ингредиентов)
		local canCraft = (curWbLvl >= rData.Tier)
		for ingKey, ingAmount in pairs(rData.Ingredients) do
			local cur = player:GetAttribute(ingKey) or 0
			if cur < ingAmount then
				canCraft = false
			end
		end

		table.insert(sortedList, {
			Key = rKey,
			Data = rData,
			CanCraft = canCraft
		})
	end

	-- СОРТИРОВКА: Сначала все ДОСТУПНЫЕ крафты (по уровням 1..5), затем недоступные (по уровням 1..5)
	table.sort(sortedList, function(a, b)
		if a.CanCraft ~= b.CanCraft then
			return a.CanCraft == true -- Доступные первыми!
		end
		if a.Data.Tier ~= b.Data.Tier then
			return a.Data.Tier < b.Data.Tier -- Начиная от 1 уровня
		end
		return a.Data.DisplayName < b.Data.DisplayName
	end)
	for _, item in ipairs(sortedList) do
		local rKey = item.Key
		local rData = item.Data

		local matchCat = (selectedCategory == "All") or (rData.Category == selectedCategory)
		if selectedCategory == "Structures" and (rData.Category == "Turrets" or rData.Category == "Structures") then
			matchCat = true
		end

		if matchCat then
			local card = Instance.new("Frame")
			card.Name = "Card_" .. rKey
			card.BackgroundColor3 = Color3.fromRGB(15, 23, 42)
			card.BackgroundTransparency = 0.3
			card.BorderSizePixel = 0
			card.Parent = scrollFrame
			Instance.new("UICorner", card).CornerRadius = UDim.new(0, 10)

			local stroke = Instance.new("UIStroke", card)
			stroke.Color = (curWbLvl >= rData.Tier) and Color3.fromRGB(56, 189, 248) or Color3.fromRGB(71, 85, 105)
			stroke.Thickness = 1.2

			-- Название и уровень
			local nameLbl = Instance.new("TextLabel")
			nameLbl.Size = UDim2.new(1, -100, 0, 20)
			nameLbl.Position = UDim2.new(0, 10, 0, 6)
			nameLbl.BackgroundTransparency = 1
			nameLbl.Font = Enum.Font.GothamBold
			nameLbl.TextSize = 12.5
			nameLbl.TextColor3 = (curWbLvl >= rData.Tier) and Color3.fromRGB(241, 245, 249) or Color3.fromRGB(148, 163, 184)
			nameLbl.TextXAlignment = Enum.TextXAlignment.Left
			nameLbl.Text = string.format("%s [Ур. %d]", rData.DisplayName, rData.Tier)
			nameLbl.Parent = card

			-- ЧИСТАЯ ИКОНОЧНАЯ СТРОКА РЕСУРСОВ (Без лишних слов)
			local canCraft = (curWbLvl >= rData.Tier)
			local ingText = ""
			for ingKey, ingAmount in pairs(rData.Ingredients) do
				local cur = player:GetAttribute(ingKey) or 0
				local icon = ICON_MAP[ingKey] or "📦"
				ingText = ingText .. string.format("%s %d/%d   ", icon, cur, ingAmount)
				if cur < ingAmount then canCraft = false end
			end

			local ingLbl = Instance.new("TextLabel")
			ingLbl.Size = UDim2.new(1, -100, 0, 24)
			ingLbl.Position = UDim2.new(0, 10, 0, 30)
			ingLbl.BackgroundTransparency = 1
			ingLbl.Font = Enum.Font.GothamBold
			ingLbl.TextSize = 12.5
			ingLbl.TextColor3 = canCraft and Color3.fromRGB(74, 222, 128) or Color3.fromRGB(248, 113, 113)
			ingLbl.TextXAlignment = Enum.TextXAlignment.Left
			ingLbl.Text = ingText
			ingLbl.Parent = card

			-- Кнопка Крафта
			local craftBtn = Instance.new("TextButton")
			craftBtn.Size = UDim2.new(0, 85, 0, 32)
			craftBtn.Position = UDim2.new(1, -95, 0.5, 0)
			craftBtn.AnchorPoint = Vector2.new(0, 0.5)
			craftBtn.BackgroundColor3 = canCraft and Color3.fromRGB(2, 132, 199) or Color3.fromRGB(51, 65, 85)
			craftBtn.Font = Enum.Font.GothamBold
			craftBtn.TextSize = 11.5
			craftBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
			craftBtn.Text = canCraft and "🛠️ Скрафтить" or (curWbLvl < rData.Tier and "🔒 Ур. " .. rData.Tier or "❌ Мало")
			craftBtn.Parent = card
			Instance.new("UICorner", craftBtn).CornerRadius = UDim.new(0, 8)

			if canCraft then
				craftBtn.MouseButton1Click:Connect(function()
					if CraftItemRemote then
						CraftItemRemote:FireServer(rKey)
						task.wait(0.25)
						renderRecipes()
					end
				end)
			end
		end
	end

	local totalCells = #scrollFrame:GetChildren() - 1
	local rows = math.ceil(totalCells / 2)
	scrollFrame.CanvasSize = UDim2.new(0, 0, 0, rows * 98 + 16)
end

-- Кнопки категорий
for _, cat in ipairs(CATEGORIES) do
	local btn = Instance.new("TextButton")
	btn.Size = UDim2.new(0, 140, 1, 0)
	btn.BackgroundColor3 = (cat.Id == selectedCategory) and Color3.fromRGB(2, 132, 199) or Color3.fromRGB(15, 23, 42)
	btn.Font = Enum.Font.GothamBold
	btn.TextSize = 11.5
	btn.TextColor3 = (cat.Id == selectedCategory) and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(148, 163, 184)
	btn.Text = cat.Name
	btn.Parent = catBar
	Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 8)

	btn.MouseButton1Click:Connect(function()
		selectedCategory = cat.Id
		for _, b in ipairs(catButtons) do
			b.btn.BackgroundColor3 = (b.id == selectedCategory) and Color3.fromRGB(2, 132, 199) or Color3.fromRGB(15, 23, 42)
			b.btn.TextColor3 = (b.id == selectedCategory) and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(148, 163, 184)
		end
		renderRecipes()
	end)
	table.insert(catButtons, { id = cat.Id, btn = btn })
end

upgradeBtn.MouseButton1Click:Connect(function()
	if UpgradeWorkbenchRemote then
		UpgradeWorkbenchRemote:FireServer()
		task.wait(0.3)
		renderRecipes()
	end
end)

local function openWorkbench()
	renderRecipes()
	mainFrame.Visible = true
end

local function closeWorkbench()
	mainFrame.Visible = false
end

closeBtn.MouseButton1Click:Connect(closeWorkbench)

ProximityPromptService.PromptTriggered:Connect(function(prompt, triggeringPlayer)
	if triggeringPlayer == player then
		if prompt.ObjectText == "🛠️ Верстак выживальщика" or (prompt.Parent and prompt.Parent.Name == "Workbench") then
			openWorkbench()
		end
	end
end)

UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then return end
	if input.KeyCode == Enum.KeyCode.B or input.KeyCode == Enum.KeyCode.C then
		if mainFrame.Visible then closeWorkbench() else openWorkbench() end
	elseif input.KeyCode == Enum.KeyCode.Escape and mainFrame.Visible then
		closeWorkbench()
	end
end)
