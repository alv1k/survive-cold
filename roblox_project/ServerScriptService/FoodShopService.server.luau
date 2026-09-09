--[[
    FoodShopService.server.luau
    Серверный сервис Продуктового Домика-Магазина:
    - Полноценное уютное здание с открытым входом для игроков
    - Стеллажи полок как в магазине (по 4 штуки 3D-модели каждого вида еды)
    - ВСЯ ЕДА ПОЛНОСТЬЮ БЕСПЛАТНАЯ (бери свободно с полок)
    - Без костров/печей внутри
    - Единые характеристики: +60 Сытости, +50% Тепла, +25 Здоровья
--]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local GameConfig = require(ReplicatedStorage:WaitForChild("GameConfig"))
local Network = require(ReplicatedStorage:WaitForChild("Network"))
local InventoryService = require(script.Parent:WaitForChild("InventoryService"))

local FoodGenerator = require(ReplicatedStorage:WaitForChild("GeneratedModels"):WaitForChild("Food"))
local BuildingGenerator = require(ReplicatedStorage:WaitForChild("GeneratedModels"):WaitForChild("BuildingGenerator"))

local BuyFoodRemote = Network.getFunction("BuyFood")
local ShowNotificationRemote = Network.getEvent("ShowNotification")

local FOOD_SHOP_POSITION = GameConfig.Locations.FoodShop.Position

local FoodShopFolder = workspace:FindFirstChild("FoodShop") or Instance.new("Folder", workspace)
FoodShopFolder.Name = "FoodShop"

-- ВСЯ ЕДА БЕСПЛАТНАЯ (+60 Сытости, +50% Тепла, +25 Здоровья)
local FOOD_CATALOG = {
	Bar = { Key = "Bar", Name = "🍫 Батончик", Cost = {}, Desc = "Бесплатно", Warmth = 50, Hunger = 60, Health = 25 },
	Bread = { Key = "Bread", Name = "🍞 Хлеб", Cost = {}, Desc = "Бесплатно", Warmth = 50, Hunger = 60, Health = 25 },
	Chips = { Key = "Chips", Name = "🥔 Чипсы", Cost = {}, Desc = "Бесплатно", Warmth = 50, Hunger = 60, Health = 25 },
	Soup = { Key = "Soup", Name = "🥫 Суп", Cost = {}, Desc = "Бесплатно", Warmth = 50, Hunger = 60, Health = 25 },
	Pepper = { Key = "Pepper", Name = "🌶️ Перец", Cost = {}, Desc = "Бесплатно", Warmth = 50, Hunger = 60, Health = 25 },
	Coffee = { Key = "Coffee", Name = "☕ Кофе", Cost = {}, Desc = "Бесплатно", Warmth = 50, Hunger = 60, Health = 25 },
	Steak = { Key = "Steak", Name = "🥩 Стейк", Cost = {}, Desc = "Бесплатно", Warmth = 50, Hunger = 60, Health = 25 }
}

-- Данные о наличии товаров на полках
local ShelfStocks = {}

local function updateShelfStatus(foodKey)
	local shelfData = ShelfStocks[foodKey]
	if not shelfData then return end
	local cfg = FOOD_CATALOG[foodKey]
	if not cfg then return end

	local count = 0
	for _, itemObj in pairs(shelfData.Items) do
		if itemObj and itemObj.Parent then
			count = count + 1
		end
	end

	if count > 0 then
		shelfData.Label.Text = string.format("%s (%d/4)\n🍗+60 🔥+50%%", cfg.Name, count)
		shelfData.Stroke.Color = Color3.fromRGB(74, 222, 128)
	else
		shelfData.Label.Text = string.format("🔒 %s (0/4)", cfg.Name)
		shelfData.Stroke.Color = Color3.fromRGB(239, 68, 68)
	end
end

local function spawnShelfItem(foodKey, slotIndex)
	local shelfData = ShelfStocks[foodKey]
	if not shelfData then return end
	local cfg = FOOD_CATALOG[foodKey]
	if not cfg then return end

	local itemCF = shelfData.SlotCFrames[slotIndex]
	if not itemCF then return end

	-- Создание детализированной 3D-модели товара через FoodGenerator
	local foodModel = FoodGenerator.createFood(foodKey, FoodShopFolder, itemCF)
	if not foodModel then return end

	foodModel.Name = string.format("Display_%s_%d", foodKey, slotIndex)
	local targetPart = foodModel.PrimaryPart or foodModel:FindFirstChildWhichIsA("BasePart")
	if not targetPart then return end

	-- Интерактивный ProximityPrompt на каждом конкретном товаре
	local prompt = Instance.new("ProximityPrompt", targetPart)
	prompt.ObjectText = cfg.Name
	prompt.ActionText = "Взять"
	prompt.HoldDuration = 0
	prompt.MaxActivationDistance = 9
	prompt.RequiresLineOfSight = false

	local isClaiming = false
	prompt.Triggered:Connect(function(player)
		if isClaiming then return end
		isClaiming = true

		local given = InventoryService.giveItem(player, foodKey, 1)

		if given then
			shelfData.Items[slotIndex] = nil
			foodModel:Destroy()
			updateShelfStatus(foodKey)
			ShowNotificationRemote:FireClient(player, string.format("🛒 Взято: %s", cfg.Name))
			print(string.format("🛒 %s взял с полки %s (слот %d)!", player.Name, cfg.Name, slotIndex))

			-- Респавн товара через 180 секунд (3 минуты)
			task.delay(180, function()
				if FoodShopFolder and FoodShopFolder.Parent then
					spawnShelfItem(foodKey, slotIndex)
				end
			end)
		else
			isClaiming = false
			ShowNotificationRemote:FireClient(player, "⚠️ Рюкзак полон! Освободите место.")
		end
	end)

	shelfData.Items[slotIndex] = foodModel
	updateShelfStatus(foodKey)
end

-- Обработка бесплатного взятия еды через меню/каталог
local function handleBuyFood(player, foodKey)
	local item = FOOD_CATALOG[foodKey]
	if not item then
		return { Success = false, Message = "Неизвестный продукт!" }
	end

	local shelfData = ShelfStocks[foodKey]
	if not shelfData then
		return { Success = false, Message = "Полка с товаром не найдена!" }
	end

	-- Поиск доступного предмета на полке
	local availableSlot = nil
	local availableItemPart = nil
	for slotIdx, itemPart in pairs(shelfData.Items) do
		if itemPart and itemPart.Parent then
			availableSlot = slotIdx
			availableItemPart = itemPart
			break
		end
	end

	if not availableSlot or not availableItemPart then
		return { Success = false, Message = "Товар закончился на полках магазина!" }
	end

	local given = InventoryService.giveItem(player, foodKey, 1)

	if given then
		shelfData.Items[availableSlot] = nil
		availableItemPart:Destroy()
		updateShelfStatus(foodKey)

		-- Респавн через 180 сек
		task.delay(180, function()
			if FoodShopFolder and FoodShopFolder.Parent then
				spawnShelfItem(foodKey, availableSlot)
			end
		end)

		ShowNotificationRemote:FireClient(player, string.format("🛒 Вы взяли: %s (+60 Сытости, +50%% Тепла)!", item.Name))
		return { Success = true, Message = "Продукт добавлен в рюкзак!" }
	else
		return { Success = false, Message = "Рюкзак полон! Освободите место." }
	end
end

BuyFoodRemote.OnServerInvoke = function(player, foodKey)
	return handleBuyFood(player, foodKey)
end

--------------------------------------------------------------------------------
-- 🏪 ПОСТРОЙКА ДОМИКА-МАГАЗИНА С ПОЛКАМИ И 3D-ЕДОЙ ПО 4 ШТ
--------------------------------------------------------------------------------

-- Создание секции полок с 4 индивидуальными товарами и интерактивным ценником
local function createRetailShelfSection(foodKey, shelfCenterPos, shelfRotationY)
	local cfg = FOOD_CATALOG[foodKey]
	if not cfg then return end

	-- Деревянная полка-подставка
	local shelfPart = Instance.new("Part")
	shelfPart.Name = "Shelf_" .. foodKey
	shelfPart.Size = Vector3.new(4.5, 0.4, 1.4)
	shelfPart.Position = shelfCenterPos
	shelfPart.Orientation = Vector3.new(0, shelfRotationY, 0)
	shelfPart.Anchored = true
	shelfPart.Material = Enum.Material.WoodPlanks
	shelfPart.Color = Color3.fromHex("#8C451A")
	shelfPart.Parent = FoodShopFolder

	-- Информационный ценник над полкой
	local bb = Instance.new("BillboardGui", shelfPart)
	bb.Size = UDim2.new(0, 160, 0, 36)
	bb.StudsOffset = Vector3.new(0, 1.4, 0)
	bb.AlwaysOnTop = false
	bb.MaxDistance = 24

	local lbl = Instance.new("TextLabel", bb)
	lbl.Size = UDim2.new(1, 0, 1, 0)
	lbl.BackgroundColor3 = Color3.fromRGB(15, 23, 42)
	lbl.BackgroundTransparency = 0.5
	lbl.Font = Enum.Font.MontserratBold
	lbl.TextSize = 11.5
	lbl.TextColor3 = Color3.fromRGB(241, 245, 249)
	Instance.new("UICorner", lbl).CornerRadius = UDim.new(0, 6)

	local stroke = Instance.new("UIStroke", lbl)
	stroke.Color = Color3.fromRGB(74, 222, 128)
	stroke.Thickness = 1.0
	stroke.Transparency = 0.5

	local shelfData = {
		SectionPart = shelfPart,
		Label = lbl,
		Stroke = stroke,
		Items = {},
		SlotCFrames = {}
	}
	ShelfStocks[foodKey] = shelfData

	-- Расставляем 4 штуки еды на полке
	local offsets = { -1.5, -0.5, 0.5, 1.5 }
	for idx, xOff in ipairs(offsets) do
		shelfData.SlotCFrames[idx] = shelfPart.CFrame * CFrame.new(xOff, 0.35, 0)
		spawnShelfItem(foodKey, idx)
	end
end

local function buildFoodShopBuilding()
	ShelfStocks = {}
	FoodShopFolder:ClearAllChildren()

	-- 1. Стилизованный 3D-сруб продуктовой лавки с торговым прилавком и навесом
	local buildingModel = BuildingGenerator.createBuilding("FoodShop", CFrame.new(FOOD_SHOP_POSITION), FoodShopFolder)
	buildingModel.Name = "FoodShopBuilding"

	-- 2. Потолочное теплое освещение
	local ceilingLightPart = Instance.new("Part", FoodShopFolder)
	ceilingLightPart.Name = "CeilingLight"
	ceilingLightPart.Size = Vector3.new(3, 0.4, 3)
	ceilingLightPart.Position = FOOD_SHOP_POSITION + Vector3.new(0, 9.5, 0)
	ceilingLightPart.Anchored = true
	ceilingLightPart.Material = Enum.Material.Neon
	ceilingLightPart.Color = Color3.fromRGB(254, 240, 138)

	local shopLight = Instance.new("PointLight", ceilingLightPart)
	shopLight.Color = Color3.fromRGB(255, 220, 150)
	shopLight.Range = 28
	shopLight.Brightness = 0.9

	----------------------------------------------------------------------------
	-- 🛒 РАССТАНОВКА СТЕЛЛАЖЕЙ И ПОЛОК С ЕДОЙ (ПО 4 ШТ КАЖДАЯ)
	----------------------------------------------------------------------------

	-- Стеллаж 1: Вдоль левой стены (3 полки)
	createRetailShelfSection("Bar", FOOD_SHOP_POSITION + Vector3.new(-8.5, 1.4, -4.5), 0)    -- 4x Батончики
	createRetailShelfSection("Bread", FOOD_SHOP_POSITION + Vector3.new(-8.5, 1.4, 0.0), 0)   -- 4x Хлеб
	createRetailShelfSection("Chips", FOOD_SHOP_POSITION + Vector3.new(-8.5, 1.4, 4.5), 0)   -- 4x Чипсы

	-- Стеллаж 2: Вдоль правой стены (3 полки)
	createRetailShelfSection("Soup", FOOD_SHOP_POSITION + Vector3.new(8.5, 1.4, -4.5), 0)    -- 4x Суп
	createRetailShelfSection("Pepper", FOOD_SHOP_POSITION + Vector3.new(8.5, 1.4, 0.0), 0)   -- 4x Перец
	createRetailShelfSection("Coffee", FOOD_SHOP_POSITION + Vector3.new(8.5, 1.4, 4.5), 0)   -- 4x Кофе

	-- Стеллаж 3: Центральный островной прилавок (Стейки)
	local centerCounter = Instance.new("Part", FoodShopFolder)
	centerCounter.Name = "CenterDisplay_Steak"
	centerCounter.Size = Vector3.new(7.0, 1.2, 3.2)
	centerCounter.Position = FOOD_SHOP_POSITION + Vector3.new(0, 1.2, 0.0)
	centerCounter.Anchored = true
	centerCounter.Material = Enum.Material.WoodPlanks
	centerCounter.Color = Color3.fromHex("#5C2E0B")

	createRetailShelfSection("Steak", FOOD_SHOP_POSITION + Vector3.new(0, 1.8, 0.0), 0)      -- 4x Стейк

	print("🏪 [FoodShopService] 3D Продуктовая лавка с торговым прилавком и полками успешно создана!")
end

buildFoodShopBuilding()
