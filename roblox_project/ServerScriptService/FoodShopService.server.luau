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

local RemotesFolder = ReplicatedStorage:FindFirstChild("Remotes") or Instance.new("Folder", ReplicatedStorage)
RemotesFolder.Name = "Remotes"

local BuyFoodRemote = RemotesFolder:FindFirstChild("BuyFood") or Instance.new("RemoteFunction", RemotesFolder)
BuyFoodRemote.Name = "BuyFood"

local ShowNotificationRemote = RemotesFolder:FindFirstChild("ShowNotification") or Instance.new("RemoteEvent", RemotesFolder)
ShowNotificationRemote.Name = "ShowNotification"

local FOOD_SHOP_POSITION = Vector3.new(-50, 4.0, 0)

local FoodShopFolder = workspace:FindFirstChild("FoodShop") or Instance.new("Folder", workspace)
FoodShopFolder.Name = "FoodShop"

-- ВСЯ ЕДА БЕСПЛАТНАЯ (+60 Сытости, +50% Тепла, +25 Здоровья)
local FOOD_CATALOG = {
	Bar = { Key = "Bar", Name = "🍫 Энергетический батончик", Cost = {}, Desc = "🎉 БЕСПЛАТНО", Warmth = 50, Hunger = 60, Health = 25 },
	Bread = { Key = "Bread", Name = "🍞 Питательный хлеб", Cost = {}, Desc = "🎉 БЕСПЛАТНО", Warmth = 50, Hunger = 60, Health = 25 },
	Chips = { Key = "Chips", Name = "🥔 Хрустящие чипсы", Cost = {}, Desc = "🎉 БЕСПЛАТНО", Warmth = 50, Hunger = 60, Health = 25 },
	Soup = { Key = "Soup", Name = "🥫 Горячий мясной суп", Cost = {}, Desc = "🎉 БЕСПЛАТНО", Warmth = 50, Hunger = 60, Health = 25 },
	Pepper = { Key = "Pepper", Name = "🌶️ Огненный перец", Cost = {}, Desc = "🎉 БЕСПЛАТНО", Warmth = 50, Hunger = 60, Health = 25 },
	Coffee = { Key = "Coffee", Name = "☕ Горячий кофе", Cost = {}, Desc = "🎉 БЕСПЛАТНО", Warmth = 50, Hunger = 60, Health = 25 },
	Steak = { Key = "Steak", Name = "🥩 Сочный стейк на гриле", Cost = {}, Desc = "🎉 БЕСПЛАТНО", Warmth = 50, Hunger = 60, Health = 25 }
}

-- Данные о наличии товаров на полках
local ShelfStocks = {}

local function updateShelfStatus(foodKey)
	local shelfData = ShelfStocks[foodKey]
	if not shelfData then return end
	local cfg = FOOD_CATALOG[foodKey]
	if not cfg then return end

	local count = 0
	for _, itemPart in pairs(shelfData.Items) do
		if itemPart and itemPart.Parent then
			count = count + 1
		end
	end

	if count > 0 then
		shelfData.Label.Text = string.format("%s\nВ наличии: %d/4\n🍗 +60 | 🔥 +50%%\n🎉 БЕСПЛАТНО", cfg.Name, count)
		shelfData.Stroke.Color = Color3.fromRGB(74, 222, 128)
	else
		shelfData.Label.Text = string.format("🔒 %s\nНЕТ В НАЛИЧИИ (Поставка...)\n🎉 БЕСПЛАТНО", cfg.Name)
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

	-- Создание 3D-модели товара
	local itemPart = Instance.new("Part")
	itemPart.Name = string.format("Display_%s_%d", foodKey, slotIndex)
	itemPart.Anchored = true
	itemPart.CanCollide = false

	if foodKey == "Bar" then
		itemPart.Size = Vector3.new(0.6, 0.25, 1.2)
		itemPart.Material = Enum.Material.SmoothPlastic
		itemPart.BrickColor = BrickColor.new("Dark orange")
	elseif foodKey == "Bread" then
		itemPart.Size = Vector3.new(0.9, 0.6, 1.4)
		itemPart.Material = Enum.Material.WoodPlanks
		itemPart.BrickColor = BrickColor.new("Nougat")
	elseif foodKey == "Chips" then
		itemPart.Size = Vector3.new(0.7, 0.9, 0.4)
		itemPart.Material = Enum.Material.Fabric
		itemPart.BrickColor = BrickColor.new("Bright yellow")
	elseif foodKey == "Soup" then
		itemPart.Size = Vector3.new(0.8, 0.9, 0.8)
		itemPart.Shape = Enum.PartType.Cylinder
		itemPart.Material = Enum.Material.Metal
		itemPart.BrickColor = BrickColor.new("Bright red")
	elseif foodKey == "Pepper" then
		itemPart.Size = Vector3.new(0.4, 0.4, 1.1)
		itemPart.Material = Enum.Material.SmoothPlastic
		itemPart.BrickColor = BrickColor.new("Really red")
	elseif foodKey == "Coffee" then
		itemPart.Size = Vector3.new(0.7, 0.8, 0.7)
		itemPart.Shape = Enum.PartType.Cylinder
		itemPart.Material = Enum.Material.Plastic
		itemPart.BrickColor = BrickColor.new("White")
	elseif foodKey == "Steak" then
		itemPart.Size = Vector3.new(1.1, 0.35, 1.3)
		itemPart.Material = Enum.Material.Slate
		itemPart.BrickColor = BrickColor.new("Maroon")
	end

	itemPart.CFrame = itemCF
	itemPart.Parent = FoodShopFolder

	-- Интерактивный ProximityPrompt на каждом конкретном товаре
	local prompt = Instance.new("ProximityPrompt", itemPart)
	prompt.ObjectText = string.format("%s [🍗 +60 | 🔥 +50%%]", cfg.Name)
	prompt.ActionText = "Взять с полки (Бесплатно)"
	prompt.HoldDuration = 0
	prompt.MaxActivationDistance = 9
	prompt.RequiresLineOfSight = false

	local isClaiming = false
	prompt.Triggered:Connect(function(player)
		if isClaiming then return end
		isClaiming = true

		local given = false
		if _G.GiveItemToPlayer then
			given = _G.GiveItemToPlayer(player, foodKey, 1)
		else
			local giveBindable = ReplicatedStorage:FindFirstChild("GiveItem")
			if giveBindable and giveBindable:IsA("BindableFunction") then
				given = giveBindable:Invoke(player, foodKey, 1)
			end
		end

		if given then
			shelfData.Items[slotIndex] = nil
			itemPart:Destroy()
			updateShelfStatus(foodKey)
			ShowNotificationRemote:FireClient(player, string.format("🛒 Вы взяли с полки: %s (+60 Сытости, +50%% Тепла)!", cfg.Name))
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

	shelfData.Items[slotIndex] = itemPart
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

	local given = false
	if _G.GiveItemToPlayer then
		given = _G.GiveItemToPlayer(player, foodKey, 1)
	else
		local giveBindable = ReplicatedStorage:FindFirstChild("GiveItem")
		if giveBindable and giveBindable:IsA("BindableFunction") then
			given = giveBindable:Invoke(player, foodKey, 1)
		end
	end

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
	shelfPart.Size = Vector3.new(6.0, 0.5, 2.2)
	shelfPart.Position = shelfCenterPos
	shelfPart.Orientation = Vector3.new(0, shelfRotationY, 0)
	shelfPart.Anchored = true
	shelfPart.Material = Enum.Material.WoodPlanks
	shelfPart.BrickColor = BrickColor.new("Brown")
	shelfPart.Parent = FoodShopFolder

	-- Информационный ценник над полкой
	local bb = Instance.new("BillboardGui", shelfPart)
	bb.Size = UDim2.new(0, 205, 0, 48)
	bb.StudsOffset = Vector3.new(0, 1.5, 0)
	bb.AlwaysOnTop = false
	bb.MaxDistance = 28

	local lbl = Instance.new("TextLabel", bb)
	lbl.Size = UDim2.new(1, 0, 1, 0)
	lbl.BackgroundColor3 = Color3.fromRGB(15, 23, 42)
	lbl.BackgroundTransparency = 0.2
	lbl.Font = Enum.Font.MontserratBold
	lbl.TextSize = 13
	lbl.TextColor3 = Color3.fromRGB(241, 245, 249)
	Instance.new("UICorner", lbl).CornerRadius = UDim.new(0, 8)

	local stroke = Instance.new("UIStroke", lbl)
	stroke.Color = Color3.fromRGB(74, 222, 128)
	stroke.Thickness = 1.5

	local shelfData = {
		SectionPart = shelfPart,
		Label = lbl,
		Stroke = stroke,
		Items = {},
		SlotCFrames = {}
	}
	ShelfStocks[foodKey] = shelfData

	-- Расставляем 4 штуки еды на полке
	local offsets = { -2.0, -0.65, 0.65, 2.0 }
	for idx, xOff in ipairs(offsets) do
		shelfData.SlotCFrames[idx] = shelfPart.CFrame * CFrame.new(xOff, 0.4, 0)
		spawnShelfItem(foodKey, idx)
	end
end


local function buildFoodShopBuilding()
	ShelfStocks = {}
	FoodShopFolder:ClearAllChildren()

	-- 1. Пол магазина (32 x 26 studs)
	local floor = Instance.new("Part")
	floor.Name = "Floor"
	floor.Size = Vector3.new(32, 1.2, 26)
	floor.Position = FOOD_SHOP_POSITION
	floor.Anchored = true
	floor.Material = Enum.Material.WoodPlanks
	floor.BrickColor = BrickColor.new("Dark orange")
	floor.Parent = FoodShopFolder

	-- 2. Задняя стена
	local wallBack = Instance.new("Part")
	wallBack.Name = "WallBack"
	wallBack.Size = Vector3.new(32, 10, 1.5)
	wallBack.Position = FOOD_SHOP_POSITION + Vector3.new(0, 5, -12.25)
	wallBack.Anchored = true
	wallBack.Material = Enum.Material.Wood
	wallBack.BrickColor = BrickColor.new("Brown")
	wallBack.Parent = FoodShopFolder

	-- 3. Левая стена
	local wallLeft = Instance.new("Part")
	wallLeft.Name = "WallLeft"
	wallLeft.Size = Vector3.new(1.5, 10, 26)
	wallLeft.Position = FOOD_SHOP_POSITION + Vector3.new(-15.25, 5, 0)
	wallLeft.Anchored = true
	wallLeft.Material = Enum.Material.Wood
	wallLeft.BrickColor = BrickColor.new("Brown")
	wallLeft.Parent = FoodShopFolder

	-- 4. Правая стена
	local wallRight = Instance.new("Part")
	wallRight.Name = "WallRight"
	wallRight.Size = Vector3.new(1.5, 10, 26)
	wallRight.Position = FOOD_SHOP_POSITION + Vector3.new(15.25, 5, 0)
	wallRight.Anchored = true
	wallRight.Material = Enum.Material.Wood
	wallRight.BrickColor = BrickColor.new("Brown")
	wallRight.Parent = FoodShopFolder

	-- 5. Фасадная стена С ОТКРЫТЫМ ДВЕРНЫМ ВХОДОМ (Проход 8 studs)
	local frontLeft = Instance.new("Part")
	frontLeft.Name = "FrontWallLeft"
	frontLeft.Size = Vector3.new(11.5, 10, 1.5)
	frontLeft.Position = FOOD_SHOP_POSITION + Vector3.new(-10.25, 5, 12.25)
	frontLeft.Anchored = true
	frontLeft.Material = Enum.Material.Wood
	frontLeft.BrickColor = BrickColor.new("Brown")
	frontLeft.Parent = FoodShopFolder

	local frontRight = Instance.new("Part")
	frontRight.Name = "FrontWallRight"
	frontRight.Size = Vector3.new(11.5, 10, 1.5)
	frontRight.Position = FOOD_SHOP_POSITION + Vector3.new(10.25, 5, 12.25)
	frontRight.Anchored = true
	frontRight.Material = Enum.Material.Wood
	frontRight.BrickColor = BrickColor.new("Brown")
	frontRight.Parent = FoodShopFolder

	local frontTopLintel = Instance.new("Part")
	frontTopLintel.Name = "DoorLintel"
	frontTopLintel.Size = Vector3.new(9, 2.5, 1.5)
	frontTopLintel.Position = FOOD_SHOP_POSITION + Vector3.new(0, 8.75, 12.25)
	frontTopLintel.Anchored = true
	frontTopLintel.Material = Enum.Material.Wood
	frontTopLintel.BrickColor = BrickColor.new("Brown")
	frontTopLintel.Parent = FoodShopFolder

	-- 6. Крыша со снегом
	local roof = Instance.new("Part")
	roof.Name = "Roof"
	roof.Size = Vector3.new(35, 1.5, 29)
	roof.Position = FOOD_SHOP_POSITION + Vector3.new(0, 10.5, 0)
	roof.Anchored = true
	roof.Material = Enum.Material.Snow
	roof.BrickColor = BrickColor.new("White")
	roof.Parent = FoodShopFolder

	-- 7. Потолочное теплое освещение (Без костров и дыма)
	local ceilingLightPart = Instance.new("Part", FoodShopFolder)
	ceilingLightPart.Name = "CeilingLight"
	ceilingLightPart.Size = Vector3.new(3, 0.5, 3)
	ceilingLightPart.Position = FOOD_SHOP_POSITION + Vector3.new(0, 9.2, 0)
	ceilingLightPart.Anchored = true
	ceilingLightPart.Material = Enum.Material.Neon
	ceilingLightPart.BrickColor = BrickColor.new("Bright yellow")

	local shopLight = Instance.new("PointLight", ceilingLightPart)
	shopLight.Color = Color3.fromRGB(255, 220, 140)
	shopLight.Range = 36
	shopLight.Brightness = 2.5

	----------------------------------------------------------------------------
	-- 🛒 РАССТАНОВКА СТЕЛЛАЖЕЙ И ПОЛОК С ЕДОЙ (ПО 4 ШТ КАЖДАЯ)
	----------------------------------------------------------------------------


	-- Стеллаж 1: Вдоль левой стены (3 полки)
	local shelfLeftBackdrop = Instance.new("Part", FoodShopFolder)
	shelfLeftBackdrop.Name = "ShelfRack_Left"
	shelfLeftBackdrop.Size = Vector3.new(1.2, 7.5, 16)
	shelfLeftBackdrop.Position = FOOD_SHOP_POSITION + Vector3.new(-13.8, 4.25, -2)
	shelfLeftBackdrop.Anchored = true
	shelfLeftBackdrop.Material = Enum.Material.WoodPlanks
	shelfLeftBackdrop.BrickColor = BrickColor.new("Dark orange")

	createRetailShelfSection("Bar", FOOD_SHOP_POSITION + Vector3.new(-12.4, 2.0, -6.5), 0)    -- 4x Батончики
	createRetailShelfSection("Bread", FOOD_SHOP_POSITION + Vector3.new(-12.4, 2.0, 0.0), 0)   -- 4x Хлеб
	createRetailShelfSection("Chips", FOOD_SHOP_POSITION + Vector3.new(-12.4, 2.0, 6.5), 0)   -- 4x Чипсы

	-- Стеллаж 2: Вдоль правой стены (3 полки)
	local shelfRightBackdrop = Instance.new("Part", FoodShopFolder)
	shelfRightBackdrop.Name = "ShelfRack_Right"
	shelfRightBackdrop.Size = Vector3.new(1.2, 7.5, 14)
	shelfRightBackdrop.Position = FOOD_SHOP_POSITION + Vector3.new(13.8, 4.25, 2)
	shelfRightBackdrop.Anchored = true
	shelfRightBackdrop.Material = Enum.Material.WoodPlanks
	shelfRightBackdrop.BrickColor = BrickColor.new("Dark orange")

	createRetailShelfSection("Soup", FOOD_SHOP_POSITION + Vector3.new(12.4, 2.0, -1.5), 0)    -- 4x Суп
	createRetailShelfSection("Pepper", FOOD_SHOP_POSITION + Vector3.new(12.4, 2.0, 4.0), 0)   -- 4x Перец
	createRetailShelfSection("Coffee", FOOD_SHOP_POSITION + Vector3.new(12.4, 4.8, 1.2), 0)   -- 4x Кофе

	-- Стеллаж 3: Центральный островной прилавок
	local centerCounter = Instance.new("Part", FoodShopFolder)
	centerCounter.Name = "CenterDisplay_Steak"
	centerCounter.Size = Vector3.new(8, 2.2, 4)
	centerCounter.Position = FOOD_SHOP_POSITION + Vector3.new(0, 1.1, -2)
	centerCounter.Anchored = true
	centerCounter.Material = Enum.Material.WoodPlanks
	centerCounter.BrickColor = BrickColor.new("Dark orange")

	createRetailShelfSection("Steak", FOOD_SHOP_POSITION + Vector3.new(0, 2.3, -2), 0)        -- 4x Стейк

	print("🏪 [FoodShopService] Бесплатный продуктовый магазин с полками готов!")
end


buildFoodShopBuilding()
