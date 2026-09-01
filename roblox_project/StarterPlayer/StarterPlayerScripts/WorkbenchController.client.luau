--[[
    WorkbenchController.client.luau
    Клиентский интерфейс Верстака с четкой иерархией:
    - 🟢 СЕКЦИЯ 1: «✅ ДОСТУПНО ДЛЯ КРАФТА» (Сортировка по Уровням 1 -> 5)
    - 🔒 СЕКЦИЯ 2: «🔒 ТРЕБУЮТСЯ РЕСУРСЫ ИЛИ УЛУЧШЕНИЕ» (Сортировка по Уровням 1 -> 5)
    - Четкие бейджи уровней [УРОВЕНЬ 1..5], иконки ресурсов и понятные статусы
--]]

local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local RemotesFolder = ReplicatedStorage:WaitForChild("Remotes", 10)
local CraftItemRemote = RemotesFolder and RemotesFolder:WaitForChild("CraftItem", 10)
local UpgradeWorkbenchRemote = RemotesFolder and RemotesFolder:WaitForChild("UpgradeWorkbench", 10)
local CraftingRecipes = require(ReplicatedStorage:WaitForChild("CraftingRecipes", 10))

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "WorkbenchScreenGui"
screenGui.ResetOnSpawn = false
screenGui.DisplayOrder = 10
screenGui.Enabled = false
screenGui.Parent = playerGui

local mainFrame = Instance.new("Frame")
mainFrame.Name = "MainFrame"
mainFrame.Size = UDim2.new(0, 780, 0, 560)
mainFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
mainFrame.AnchorPoint = Vector2.new(0.5, 0.5)
mainFrame.BackgroundColor3 = Color3.fromRGB(15, 23, 42)
mainFrame.BorderSizePixel = 0
mainFrame.Parent = screenGui
Instance.new("UICorner", mainFrame).CornerRadius = UDim.new(0, 16)

local mainStroke = Instance.new("UIStroke", mainFrame)
mainStroke.Color = Color3.fromRGB(56, 189, 248)
mainStroke.Thickness = 2

-- 1. Шапка верстака
local header = Instance.new("Frame")
header.Size = UDim2.new(1, 0, 0, 56)
header.BackgroundColor3 = Color3.fromRGB(30, 41, 59)
header.BorderSizePixel = 0
header.Parent = mainFrame
Instance.new("UICorner", header).CornerRadius = UDim.new(0, 16)

local titleLabel = Instance.new("TextLabel")
titleLabel.Name = "Title"
titleLabel.Size = UDim2.new(0.6, 0, 1, 0)
titleLabel.Position = UDim2.new(0, 20, 0, 0)
titleLabel.BackgroundTransparency = 1
titleLabel.Font = Enum.Font.GothamBlack
titleLabel.TextSize = 17
titleLabel.TextColor3 = Color3.fromRGB(241, 245, 249)
titleLabel.TextXAlignment = Enum.TextXAlignment.Left
titleLabel.Text = "🛠️ ВЕРСТАК ВЫЖИВАЛЬЩИКА"
titleLabel.Parent = header

local upgradeBtn = Instance.new("TextButton")
upgradeBtn.Name = "UpgradeBtn"
upgradeBtn.Size = UDim2.new(0, 230, 0, 36)
upgradeBtn.Position = UDim2.new(1, -90, 0.5, 0)
upgradeBtn.AnchorPoint = Vector2.new(1, 0.5)
upgradeBtn.BackgroundColor3 = Color3.fromRGB(245, 158, 11)
upgradeBtn.Font = Enum.Font.GothamBold
upgradeBtn.TextSize = 12
upgradeBtn.TextColor3 = Color3.fromRGB(15, 23, 42)
upgradeBtn.Text = "⬆️ Улучшить верстак"
upgradeBtn.Parent = header
Instance.new("UICorner", upgradeBtn).CornerRadius = UDim.new(0, 8)

local closeBtn = Instance.new("TextButton")
closeBtn.Size = UDim2.new(0, 36, 0, 36)
closeBtn.Position = UDim2.new(1, -46, 0.5, 0)
closeBtn.AnchorPoint = Vector2.new(0, 0.5)
closeBtn.BackgroundColor3 = Color3.fromRGB(239, 68, 68)
closeBtn.Font = Enum.Font.GothamBold
closeBtn.TextSize = 15
closeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
closeBtn.Text = "✕"
closeBtn.Parent = header
Instance.new("UICorner", closeBtn).CornerRadius = UDim.new(0, 10)

-- 2. Вкладки категорий
local catBar = Instance.new("Frame")
catBar.Size = UDim2.new(1, -36, 0, 34)
catBar.Position = UDim2.new(0, 18, 0, 64)
catBar.BackgroundTransparency = 1
catBar.Parent = mainFrame

local catLayout = Instance.new("UIListLayout", catBar)
catLayout.FillDirection = Enum.FillDirection.Horizontal
catLayout.Padding = UDim.new(0, 8)

local CATEGORIES = {
	{ Id = "All", Name = "📋 Все рецепты" },
	{ Id = "Weapons", Name = "🗡️ Оружие" },
	{ Id = "Gear", Name = "⛺ Снаряжение" },
	{ Id = "Structures", Name = "🛡️ Оборона & Ловушки" }
}

local selectedCategory = "All"
local catButtons = {}

-- 3. Скролл-список рецептов с иерархией
local scrollFrame = Instance.new("ScrollingFrame")
scrollFrame.Name = "RecipesScroll"
scrollFrame.Size = UDim2.new(1, -36, 1, -114)
scrollFrame.Position = UDim2.new(0, 18, 0, 104)
scrollFrame.BackgroundColor3 = Color3.fromRGB(20, 29, 47)
scrollFrame.BackgroundTransparency = 0.5
scrollFrame.BorderSizePixel = 0
scrollFrame.ScrollBarThickness = 6
scrollFrame.ScrollBarImageColor3 = Color3.fromRGB(56, 189, 248)
scrollFrame.Parent = mainFrame
Instance.new("UICorner", scrollFrame).CornerRadius = UDim.new(0, 12)

local listLayout = Instance.new("UIListLayout", scrollFrame)
listLayout.FillDirection = Enum.FillDirection.Vertical
listLayout.Padding = UDim.new(0, 8)
listLayout.SortOrder = Enum.SortOrder.LayoutOrder

local ICON_MAP = {
	Branches = "🌿",
	Stone = "⚪",
	Fiber = "🌱",
	Planks = "🌲",
	WolfPelt = "🐺",
	YetiPelt = "❄️",
	Parts = "⚙️"
}

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

	local availableList = {}
	local lockedList = {}

	for rKey, rData in pairs(CraftingRecipes.Recipes) do
		local matchCat = (selectedCategory == "All") or (rData.Category == selectedCategory)
		if selectedCategory == "Structures" and (rData.Category == "Turrets" or rData.Category == "Structures") then
			matchCat = true
		end

		if matchCat then
			local canCraft = (curWbLvl >= rData.Tier)
			for ingKey, ingAmount in pairs(rData.Ingredients) do
				local cur = player:GetAttribute(ingKey) or 0
				if cur < ingAmount then
					canCraft = false
				end
			end

			local itemObj = { Key = rKey, Data = rData, CanCraft = canCraft }
			if canCraft then
				table.insert(availableList, itemObj)
			else
				table.insert(lockedList, itemObj)
			end
		end
	end

	-- Сортировка внутри каждой группы: по возрастанию уровней (1 -> 2 -> 3 -> 4 -> 5)
	local function sortItems(a, b)
		if a.Data.Tier ~= b.Data.Tier then
			return a.Data.Tier < b.Data.Tier
		end
		return a.Data.DisplayName < b.Data.DisplayName
	end
	table.sort(availableList, sortItems)
	table.sort(lockedList, sortItems)

	local layoutIndex = 1

	-- Вспомогательная функция создания разделителя секции
	local function createSectionHeader(titleText, color, icon)
		local secFrame = Instance.new("Frame")
		secFrame.Name = "Section_" .. layoutIndex
		secFrame.Size = UDim2.new(1, -12, 0, 32)
		secFrame.BackgroundColor3 = Color3.fromRGB(30, 41, 59)
		secFrame.BorderSizePixel = 0
		secFrame.LayoutOrder = layoutIndex
		layoutIndex = layoutIndex + 1
		secFrame.Parent = scrollFrame
		Instance.new("UICorner", secFrame).CornerRadius = UDim.new(0, 8)

		local secStroke = Instance.new("UIStroke", secFrame)
		secStroke.Color = color
		secStroke.Thickness = 1.2

		local secLabel = Instance.new("TextLabel")
		secLabel.Size = UDim2.new(1, -20, 1, 0)
		secLabel.Position = UDim2.new(0, 12, 0, 0)
		secLabel.BackgroundTransparency = 1
		secLabel.Font = Enum.Font.GothamBlack
		secLabel.TextSize = 13
		secLabel.TextColor3 = color
		secLabel.TextXAlignment = Enum.TextXAlignment.Left
		secLabel.Text = string.format("%s  %s", icon, titleText)
		secLabel.Parent = secFrame
	end

	-- Вспомогательная функция создания карточки рецепта
	local function createRecipeCard(item, isAvailable)
		local rKey = item.Key
		local rData = item.Data

		local card = Instance.new("Frame")
		card.Name = "Card_" .. rKey
		card.Size = UDim2.new(1, -12, 0, 68)
		card.BackgroundColor3 = isAvailable and Color3.fromRGB(15, 23, 42) or Color3.fromRGB(11, 17, 32)
		card.BackgroundTransparency = 0.2
		card.BorderSizePixel = 0
		card.LayoutOrder = layoutIndex
		layoutIndex = layoutIndex + 1
		card.Parent = scrollFrame
		Instance.new("UICorner", card).CornerRadius = UDim.new(0, 10)

		local cardStroke = Instance.new("UIStroke", card)
		cardStroke.Color = isAvailable and Color3.fromRGB(74, 222, 128) or (curWbLvl >= rData.Tier and Color3.fromRGB(71, 85, 105) or Color3.fromRGB(185, 28, 28))
		cardStroke.Thickness = isAvailable and 1.5 or 1.0

		-- Бейдж уровня (Tier Badge)
		local tierBadge = Instance.new("Frame")
		tierBadge.Size = UDim2.new(0, 62, 0, 22)
		tierBadge.Position = UDim2.new(0, 10, 0, 8)
		tierBadge.BackgroundColor3 = (curWbLvl >= rData.Tier) and Color3.fromRGB(2, 132, 199) or Color3.fromRGB(71, 85, 105)
		tierBadge.BorderSizePixel = 0
		tierBadge.Parent = card
		Instance.new("UICorner", tierBadge).CornerRadius = UDim.new(0, 6)

		local tierLabel = Instance.new("TextLabel")
		tierLabel.Size = UDim2.new(1, 0, 1, 0)
		tierLabel.BackgroundTransparency = 1
		tierLabel.Font = Enum.Font.GothamBlack
		tierLabel.TextSize = 10.5
		tierLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
		tierLabel.Text = string.format("УР. %d", rData.Tier)
		tierLabel.Parent = tierBadge

		-- Название предмета
		local nameLbl = Instance.new("TextLabel")
		nameLbl.Size = UDim2.new(0.5, 0, 0, 22)
		nameLbl.Position = UDim2.new(0, 80, 0, 8)
		nameLbl.BackgroundTransparency = 1
		nameLbl.Font = Enum.Font.GothamBold
		nameLbl.TextSize = 13.5
		nameLbl.TextColor3 = isAvailable and Color3.fromRGB(241, 245, 249) or Color3.fromRGB(148, 163, 184)
		nameLbl.TextXAlignment = Enum.TextXAlignment.Left
		nameLbl.Text = rData.DisplayName
		nameLbl.Parent = card

		-- Иконочный список ресурсов
		local ingText = ""
		for ingKey, ingAmount in pairs(rData.Ingredients) do
			local cur = player:GetAttribute(ingKey) or 0
			local icon = ICON_MAP[ingKey] or "📦"
			ingText = ingText .. string.format("%s %d/%d   ", icon, cur, ingAmount)
		end

		local ingLbl = Instance.new("TextLabel")
		ingLbl.Size = UDim2.new(0.65, 0, 0, 24)
		ingLbl.Position = UDim2.new(0, 12, 0, 36)
		ingLbl.BackgroundTransparency = 1
		ingLbl.Font = Enum.Font.GothamBold
		ingLbl.TextSize = 12
		ingLbl.TextColor3 = isAvailable and Color3.fromRGB(74, 222, 128) or Color3.fromRGB(248, 113, 113)
		ingLbl.TextXAlignment = Enum.TextXAlignment.Left
		ingLbl.Text = ingText
		ingLbl.Parent = card

		-- Кнопка Крафта
		local craftBtn = Instance.new("TextButton")
		craftBtn.Size = UDim2.new(0, 110, 0, 36)
		craftBtn.Position = UDim2.new(1, -122, 0.5, 0)
		craftBtn.AnchorPoint = Vector2.new(0, 0.5)
		craftBtn.BackgroundColor3 = isAvailable and Color3.fromRGB(34, 197, 94) or Color3.fromRGB(51, 65, 85)
		craftBtn.Font = Enum.Font.GothamBlack
		craftBtn.TextSize = 11.5
		craftBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
		craftBtn.Text = isAvailable and "🛠️ Создать" or (curWbLvl < rData.Tier and string.format("🔒 Нужен Ур. %d", rData.Tier) or "❌ Мало ресурсов")
		craftBtn.Parent = card
		Instance.new("UICorner", craftBtn).CornerRadius = UDim.new(0, 8)

		if isAvailable then
			craftBtn.MouseButton1Click:Connect(function()
				if CraftItemRemote then
					CraftItemRemote:FireServer(rKey)
					task.wait(0.25)
					renderRecipes()
				end
			end)
		end
	end

	-- 1. СЕКЦИЯ: ДОСТУПНО ДЛЯ КРАФТА
	if #availableList > 0 then
		createSectionHeader(string.format("ГОТОВО К СОЗДАНИЮ (%d)", #availableList), Color3.fromRGB(74, 222, 128), "✅")
		for _, item in ipairs(availableList) do
			createRecipeCard(item, true)
		end
	end

	-- 2. СЕКЦИЯ: ТРЕБУЕТСЯ УЛУЧШЕНИЕ ИЛИ РЕСУРСЫ
	if #lockedList > 0 then
		createSectionHeader(string.format("НЕДОСТУПНО (%d)", #lockedList), Color3.fromRGB(148, 163, 184), "🔒")
		for _, item in ipairs(lockedList) do
			createRecipeCard(item, false)
		end
	end

	scrollFrame.CanvasSize = UDim2.new(0, 0, 0, layoutIndex * 78 + 20)
end

-- Кнопки категорий
for _, cat in ipairs(CATEGORIES) do
	local btn = Instance.new("TextButton")
	btn.Size = UDim2.new(0, 160, 1, 0)
	btn.BackgroundColor3 = (cat.Id == selectedCategory) and Color3.fromRGB(2, 132, 199) or Color3.fromRGB(15, 23, 42)
	btn.Font = Enum.Font.GothamBold
	btn.TextSize = 12
	btn.TextColor3 = Color3.fromRGB(255, 255, 255)
	btn.Text = cat.Name
	btn.Parent = catBar
	Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 8)

	btn.MouseButton1Click:Connect(function()
		selectedCategory = cat.Id
		for cId, b in pairs(catButtons) do
			b.BackgroundColor3 = (cId == selectedCategory) and Color3.fromRGB(2, 132, 199) or Color3.fromRGB(15, 23, 42)
		end
		renderRecipes()
	end)
	catButtons[cat.Id] = btn
end

upgradeBtn.MouseButton1Click:Connect(function()
	if UpgradeWorkbenchRemote then
		UpgradeWorkbenchRemote:FireServer()
		task.wait(0.3)
		renderRecipes()
	end
end)

closeBtn.MouseButton1Click:Connect(function()
	screenGui.Enabled = false
end)

local function openWorkbench()
	screenGui.Enabled = true
	renderRecipes()
end

local function bindWorkbenchPrompt()
	local house = workspace:FindFirstChild("WorldStructures") and workspace.WorldStructures:FindFirstChild("PlayerHouse")
	local wb = house and house:FindFirstChild("Workbench")
	if wb then
		local prompt = wb:FindFirstChildOfClass("ProximityPrompt")
		if prompt and not prompt:GetAttribute("Bound") then
			prompt:SetAttribute("Bound", true)
			prompt.Triggered:Connect(function(triggerPlayer)
				if triggerPlayer == player then
					openWorkbench()
				end
			end)
		end
	end
end

workspace.DescendantAdded:Connect(function(desc)
	if desc.Name == "Workbench" then
		task.wait(0.2)
		bindWorkbenchPrompt()
	end
end)
bindWorkbenchPrompt()

player.AttributeChanged:Connect(function()
	if screenGui.Enabled then
		renderRecipes()
	end
end)

UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then return end
	if input.KeyCode == Enum.KeyCode.E and screenGui.Enabled then
		-- screenGui.Enabled = false
	end
end)

print("🛠️ [WorkbenchController] Интерфейс верстака с четкой секционной иерархией активен!")
