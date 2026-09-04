--[[
    WorkbenchController.client.luau
    Клиентский интерфейс Верстака с четкой иерархией и мгновенным пересчетом:
    - 🟢 СЕКЦИЯ 1: «✅ ГОТОВО К СОЗДАНИЮ» (Сортировка по Уровням 1 -> 5)
    - 🔒 СЕКЦИЯ 2: «🔒 ТРЕБУЮТСЯ РЕСУРСЫ ИЛИ УЛУЧШЕНИЕ» (Сортировка по Уровням 1 -> 5)
    - Динамический пересчет предметов в рюкзаке и руках в реальном времени
    - Моментальное обновление доступных рецептов сразу после крафта
--]]

local UserInputService = game:GetService("UserInputService")
local ProximityPromptService = game:GetService("ProximityPromptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local RemotesFolder = ReplicatedStorage:WaitForChild("Remotes", 10)
local CraftItemRemote = RemotesFolder and RemotesFolder:WaitForChild("CraftItem", 10)
local UpgradeWorkbenchRemote = RemotesFolder and RemotesFolder:WaitForChild("UpgradeWorkbench", 10)
local OpenWorkbenchRemote = RemotesFolder and RemotesFolder:WaitForChild("OpenWorkbench", 5)
local CraftingRecipes = require(ReplicatedStorage:WaitForChild("CraftingRecipes", 10))
local IconConfig = require(ReplicatedStorage:WaitForChild("IconConfig", 10))

local existingWorkbenchGui = playerGui:FindFirstChild("WorkbenchScreenGui")
if existingWorkbenchGui then
	existingWorkbenchGui:Destroy()
end

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
titleLabel.Size = UDim2.new(0.55, 0, 1, 0)
titleLabel.Position = UDim2.new(0, 20, 0, 0)
titleLabel.BackgroundTransparency = 1
titleLabel.Font = Enum.Font.MontserratBlack
titleLabel.TextSize = 19
titleLabel.TextColor3 = Color3.fromRGB(241, 245, 249)
titleLabel.TextXAlignment = Enum.TextXAlignment.Left
titleLabel.Text = "🛠️ ВЕРСТАК ВЫЖИВАЛЬЩИКА"
titleLabel.Parent = header

local upgradeBtn = Instance.new("TextButton")
upgradeBtn.Name = "UpgradeBtn"
upgradeBtn.Size = UDim2.new(0, 250, 0, 38)
upgradeBtn.Position = UDim2.new(1, -96, 0.5, 0)
upgradeBtn.AnchorPoint = Vector2.new(1, 0.5)
upgradeBtn.BackgroundColor3 = Color3.fromRGB(245, 158, 11)
upgradeBtn.Font = Enum.Font.MontserratBold
upgradeBtn.TextSize = 14
upgradeBtn.TextColor3 = Color3.fromRGB(15, 23, 42)
upgradeBtn.Text = "⬆️ Улучшить верстак"
upgradeBtn.Parent = header
Instance.new("UICorner", upgradeBtn).CornerRadius = UDim.new(0, 8)

local closeBtn = IconConfig.CreateIconButton(header, "UI_Close", UDim2.new(0, 36, 0, 36), Color3.fromRGB(220, 38, 38), Color3.fromRGB(254, 202, 202))
closeBtn.Name = "CloseButton"
closeBtn.Position = UDim2.new(1, -48, 0.5, 0)
closeBtn.AnchorPoint = Vector2.new(0, 0.5)
closeBtn.Modal = true -- Разблокирует мышь и курсор при открытии интерфейса

-- 2. Вкладки категорий
local catBar = Instance.new("Frame")
catBar.Size = UDim2.new(1, -36, 0, 36)
catBar.Position = UDim2.new(0, 18, 0, 64)
catBar.BackgroundTransparency = 1
catBar.Parent = mainFrame

local catLayout = Instance.new("UIListLayout", catBar)
catLayout.FillDirection = Enum.FillDirection.Horizontal
catLayout.Padding = UDim.new(0, 8)

local CATEGORIES = {
	{ Id = "All", Name = "Все рецепты", IconKey = "UI_Check" },
	{ Id = "Weapons", Name = "Оружие", IconKey = "UI_Swords" },
	{ Id = "Gear", Name = "Снаряжение", IconKey = "UI_Tent" },
	{ Id = "Structures", Name = "Оборона", IconKey = "UI_Shield" }
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

-- Функция подсчета реального количества ресурсов у игрока (из рюкзака, рук и атрибутов)
local function getPlayerResourceCount(resourceKey)
	local attrCount = player:GetAttribute(resourceKey) or 0
	local toolCount = 0

	local backpack = player:FindFirstChildOfClass("Backpack")
	if backpack then
		for _, t in ipairs(backpack:GetChildren()) do
			if t:IsA("Tool") and t:GetAttribute("ItemKey") == resourceKey then
				toolCount = toolCount + (t:GetAttribute("Count") or 1)
			end
		end
	end

	local char = player.Character
	if char then
		for _, t in ipairs(char:GetChildren()) do
			if t:IsA("Tool") and t:GetAttribute("ItemKey") == resourceKey then
				toolCount = toolCount + (t:GetAttribute("Count") or 1)
			end
		end
	end

	return math.max(attrCount, toolCount)
end

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
				local cur = getPlayerResourceCount(ingKey)
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

		-- Бейдж иконки предмета
		local itemBadge = IconConfig.CreateIconBadge(card, rKey, UDim2.new(0, 48, 0, 48), 0.25)
		itemBadge.Position = UDim2.new(0, 10, 0.5, 0)
		itemBadge.AnchorPoint = Vector2.new(0, 0.5)

		-- Бейдж уровня (Tier Badge)
		local tierBadge = Instance.new("Frame")
		tierBadge.Size = UDim2.new(0, 62, 0, 22)
		tierBadge.Position = UDim2.new(0, 68, 0, 8)
		tierBadge.BackgroundColor3 = (curWbLvl >= rData.Tier) and Color3.fromRGB(2, 132, 199) or Color3.fromRGB(71, 85, 105)
		tierBadge.BorderSizePixel = 0
		tierBadge.Parent = card
		Instance.new("UICorner", tierBadge).CornerRadius = UDim.new(0, 6)

		local tierLabel = Instance.new("TextLabel")
		tierLabel.Size = UDim2.new(1, 0, 1, 0)
		tierLabel.BackgroundTransparency = 1
		tierLabel.Font = Enum.Font.MontserratBlack
		tierLabel.TextSize = 12
		tierLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
		tierLabel.Text = string.format("УР. %d", rData.Tier)
		tierLabel.Parent = tierBadge

		-- Название предмета
		local nameLbl = Instance.new("TextLabel")
		nameLbl.Size = UDim2.new(0.5, 0, 0, 24)
		nameLbl.Position = UDim2.new(0, 138, 0, 6)
		nameLbl.BackgroundTransparency = 1
		nameLbl.Font = Enum.Font.MontserratBold
		nameLbl.TextSize = 15.5
		nameLbl.TextColor3 = isAvailable and Color3.fromRGB(241, 245, 249) or Color3.fromRGB(148, 163, 184)
		nameLbl.TextXAlignment = Enum.TextXAlignment.Left
		nameLbl.Text = rData.DisplayName
		nameLbl.Parent = card

		-- Иконочный список ресурсов с реальным количеством
		local ingText = ""
		for ingKey, ingAmount in pairs(rData.Ingredients) do
			local cur = getPlayerResourceCount(ingKey)
			local iconData = IconConfig.Icons[ingKey]
			local iconEmoji = iconData and iconData.FallbackEmoji or "📦"
			ingText = ingText .. string.format("%s %d/%d   ", iconEmoji, cur, ingAmount)
		end

		local ingLbl = Instance.new("TextLabel")
		ingLbl.Size = UDim2.new(0.65, 0, 0, 24)
		ingLbl.Position = UDim2.new(0, 68, 0, 36)
		ingLbl.BackgroundTransparency = 1
		ingLbl.Font = Enum.Font.MontserratBold
		ingLbl.TextSize = 13.5
		ingLbl.TextColor3 = isAvailable and Color3.fromRGB(74, 222, 128) or Color3.fromRGB(248, 113, 113)
		ingLbl.TextXAlignment = Enum.TextXAlignment.Left
		ingLbl.Text = ingText
		ingLbl.Parent = card

		-- Кнопка Крафта
		local craftBtn = Instance.new("TextButton")
		craftBtn.Size = UDim2.new(0, 125, 0, 38)
		craftBtn.Position = UDim2.new(1, -135, 0.5, 0)
		craftBtn.AnchorPoint = Vector2.new(0, 0.5)
		craftBtn.BackgroundColor3 = isAvailable and Color3.fromRGB(34, 197, 94) or Color3.fromRGB(51, 65, 85)
		craftBtn.Font = Enum.Font.MontserratBold
		craftBtn.TextSize = 13
		craftBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
		craftBtn.Text = isAvailable and "🛠️ Создать" or (curWbLvl < rData.Tier and string.format("🔒 Нужен Ур. %d", rData.Tier) or "❌ Мало ресурсов")
		craftBtn.Parent = card
		Instance.new("UICorner", craftBtn).CornerRadius = UDim.new(0, 8)

		if isAvailable then
			craftBtn.MouseButton1Click:Connect(function()
				if CraftItemRemote then
					craftBtn.Text = "⏳..."
					CraftItemRemote:FireServer(rKey)
					
					-- Мгновенный и повторный пересчет для гарантии синхронизации
					task.delay(0.12, function()
						if screenGui.Enabled then renderRecipes() end
					end)
					task.delay(0.35, function()
						if screenGui.Enabled then renderRecipes() end
					end)
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

-- Кнопки категорий с графическими иконками
for _, cat in ipairs(CATEGORIES) do
	local btn = Instance.new("TextButton")
	btn.Size = UDim2.new(0, 170, 1, 0)
	btn.BackgroundColor3 = (cat.Id == selectedCategory) and Color3.fromRGB(2, 132, 199) or Color3.fromRGB(15, 23, 42)
	btn.Text = "" -- Без текста кнопки, используем внутренние лейблы
	btn.AutoButtonColor = true
	btn.Parent = catBar
	Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 8)

	local iconBadge = IconConfig.CreateIconBadge(btn, cat.IconKey, UDim2.new(0, 24, 0, 24), 1)
	iconBadge.Position = UDim2.new(0, 8, 0.5, 0)
	iconBadge.AnchorPoint = Vector2.new(0, 0.5)

	local btnLbl = Instance.new("TextLabel")
	btnLbl.Size = UDim2.new(1, -38, 1, 0)
	btnLbl.Position = UDim2.new(0, 36, 0, 0)
	btnLbl.BackgroundTransparency = 1
	btnLbl.Font = Enum.Font.MontserratBold
	btnLbl.TextSize = 13
	btnLbl.TextColor3 = Color3.fromRGB(255, 255, 255)
	btnLbl.TextXAlignment = Enum.TextXAlignment.Left
	btnLbl.Text = cat.Name
	btnLbl.Parent = btn

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
		task.delay(0.2, function()
			if screenGui.Enabled then renderRecipes() end
		end)
	end
end)

local function closeWorkbench()
	screenGui.Enabled = false
	closeBtn.Modal = false
end

closeBtn.MouseButton1Click:Connect(closeWorkbench)

local function openWorkbench()
	screenGui.Enabled = true
	closeBtn.Modal = true
	UserInputService.MouseBehavior = Enum.MouseBehavior.Default
	UserInputService.MouseIconEnabled = true
	renderRecipes()
end

local function getWorkbenchDistance()
	local char = player.Character
	local hrp = char and char:FindFirstChild("HumanoidRootPart")
	if not hrp then return math.huge end

	local house = workspace:FindFirstChild("WorldStructures") and workspace.WorldStructures:FindFirstChild("PlayerHouse")
	local wb = house and house:FindFirstChild("Workbench")
	if wb and wb:IsA("BasePart") then
		return (hrp.Position - wb.Position).Magnitude
	end
	return (hrp.Position - Vector3.new(-12, 2.6, 8)).Magnitude
end

-- 1. Обработка клавиш [E], [Esc], [Tab]
UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if input.KeyCode == Enum.KeyCode.E then
		if screenGui.Enabled then
			closeWorkbench()
		else
			if not gameProcessed and getWorkbenchDistance() <= 18 then
				openWorkbench()
			end
		end
	elseif screenGui.Enabled and (input.KeyCode == Enum.KeyCode.Escape or input.KeyCode == Enum.KeyCode.Tab) then
		closeWorkbench()
	end
end)

-- 2. Глобальный слушатель ProximityPrompt на клиенте
ProximityPromptService.PromptTriggered:Connect(function(prompt, triggerPlayer)
	if triggerPlayer and triggerPlayer ~= player then return end
	local parent = prompt.Parent
	local promptName = prompt.Name
	local objText = prompt.ObjectText or ""
	local actText = prompt.ActionText or ""

	if promptName == "WorkbenchPrompt"
		or (parent and parent.Name == "Workbench")
		or prompt:GetAttribute("IsWorkbench")
		or string.find(string.lower(objText), "верстак")
		or string.find(string.lower(actText), "верстак") then
		openWorkbench()
	end
end)

-- 3. Слушатель удаленного вызова от сервера
if OpenWorkbenchRemote then
	OpenWorkbenchRemote.OnClientEvent:Connect(function()
		openWorkbench()
	end)
end

-- Автоматический пересчет рецептов при изменении любых атрибутов или инвентаря
player.AttributeChanged:Connect(function()
	if screenGui.Enabled then
		renderRecipes()
	end
end)

local function attachBackpackListeners()
	local backpack = player:FindFirstChildOfClass("Backpack")
	if backpack then
		backpack.ChildAdded:Connect(function()
			if screenGui.Enabled then renderRecipes() end
		end)
		backpack.ChildRemoved:Connect(function()
			if screenGui.Enabled then renderRecipes() end
		end)
	end
end

player.CharacterAdded:Connect(function(char)
	char.ChildAdded:Connect(function()
		if screenGui.Enabled then renderRecipes() end
	end)
	char.ChildRemoved:Connect(function()
		if screenGui.Enabled then renderRecipes() end
	end)
	attachBackpackListeners()
end)
attachBackpackListeners()

print("🛠️ [WorkbenchController] Интерфейс верстака с мгновенным пересчетом активен!")
