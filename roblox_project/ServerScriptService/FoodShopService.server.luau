--[[
    FoodShopService.server.luau
    Серверный сервис Продуктовой Лавки выживальщика:
    - Теплая хижина с печью и прилавком
    - Обработка покупки еды через RemoteFunction/RemoteEvent
    - Выдача реальных Tool в Backpack игрока с нативными эффектами
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

local FOOD_SHOP_POSITION = Vector3.new(-380, 4.0, -450)

local FoodShopFolder = workspace:FindFirstChild("FoodShop") or Instance.new("Folder", workspace)
FoodShopFolder.Name = "FoodShop"

local FOOD_CATALOG = {
	Bar = { Key = "Bar", Name = "🍫 Энергетический батончик", Cost = {}, Desc = "🎉 БЕСПЛАТНЫЙ ПАЁК", Warmth = 10, Hunger = 30, Health = 15 },
	Bread = { Key = "Bread", Name = "🍞 Питательный хлеб", Cost = { Branches = 2 }, Desc = "2 Ветки", Warmth = 15, Hunger = 50, Health = 25 },
	Chips = { Key = "Chips", Name = "🥔 Хрустящие чипсы", Cost = { Fiber = 2 }, Desc = "2 Волокна", Warmth = 8, Hunger = 25, Health = 15 },
	Soup = { Key = "Soup", Name = "🥫 Горячий мясной суп", Cost = { Branches = 3, Fiber = 2 }, Desc = "3 Ветки + 2 Волокна", Warmth = 30, Hunger = 70, Health = 35 },
	Pepper = { Key = "Pepper", Name = "🌶️ Огненный перец", Cost = { Stone = 2, Branches = 2 }, Desc = "2 Камня + 2 Ветки", Warmth = 50, Hunger = 15, Health = 5 },
	Coffee = { Key = "Coffee", Name = "☕ Горячий кофе", Cost = { Branches = 3, Fiber = 2 }, Desc = "3 Ветки + 2 Волокна", Warmth = 40, Hunger = 20, Health = 20 },
	Steak = { Key = "Steak", Name = "🥩 Сочный стейк на гриле", Cost = { Planks = 1, Branches = 2 }, Desc = "1 Доска + 2 Ветки", Warmth = 35, Hunger = 90, Health = 60 }
}

-- Постройка здания продуктовой лавки
local function buildFoodShopBuilding()
	FoodShopFolder:ClearAllChildren()

	-- Пол
	local floor = Instance.new("Part")
	floor.Name = "Floor"
	floor.Size = Vector3.new(28, 1.2, 22)
	floor.Position = FOOD_SHOP_POSITION
	floor.Anchored = true
	floor.Material = Enum.Material.WoodPlanks
	floor.BrickColor = BrickColor.new("Dark orange")
	floor.Parent = FoodShopFolder

	-- Стены
	local wallBack = Instance.new("Part")
	wallBack.Size = Vector3.new(28, 9, 1.5)
	wallBack.Position = FOOD_SHOP_POSITION + Vector3.new(0, 4.5, -10.5)
	wallBack.Anchored = true
	wallBack.Material = Enum.Material.Wood
	wallBack.BrickColor = BrickColor.new("Brown")
	wallBack.Parent = FoodShopFolder

	local wallLeft = Instance.new("Part")
	wallLeft.Size = Vector3.new(1.5, 9, 22)
	wallLeft.Position = FOOD_SHOP_POSITION + Vector3.new(-13.5, 4.5, 0)
	wallLeft.Anchored = true
	wallLeft.Material = Enum.Material.Wood
	wallLeft.BrickColor = BrickColor.new("Brown")
	wallLeft.Parent = FoodShopFolder

	local wallRight = Instance.new("Part")
	wallRight.Size = Vector3.new(1.5, 9, 22)
	wallRight.Position = FOOD_SHOP_POSITION + Vector3.new(13.5, 4.5, 0)
	wallRight.Anchored = true
	wallRight.Material = Enum.Material.Wood
	wallRight.BrickColor = BrickColor.new("Brown")
	wallRight.Parent = FoodShopFolder

	-- Крыша
	local roof = Instance.new("Part")
	roof.Size = Vector3.new(31, 1.5, 25)
	roof.Position = FOOD_SHOP_POSITION + Vector3.new(0, 9.5, 0)
	roof.Anchored = true
	roof.Material = Enum.Material.Snow
	roof.BrickColor = BrickColor.new("White")
	roof.Parent = FoodShopFolder

	-- Печь-очаг
	local oven = Instance.new("Part")
	oven.Name = "Oven"
	oven.Size = Vector3.new(5, 5, 4)
	oven.Position = FOOD_SHOP_POSITION + Vector3.new(9, 2.5, -7)
	oven.Anchored = true
	oven.Material = Enum.Material.Brick
	oven.BrickColor = BrickColor.new("Bright red")
	oven.Parent = FoodShopFolder

	local ovenFire = Instance.new("Fire", oven)
	ovenFire.Size = 4
	ovenFire.Heat = 12

	local ovenLight = Instance.new("PointLight", oven)
	ovenLight.Color = Color3.fromRGB(255, 140, 40)
	ovenLight.Range = 28
	ovenLight.Brightness = 2.5

	-- Торговый прилавок
	local counter = Instance.new("Part")
	counter.Name = "FoodCounter"
	counter.Size = Vector3.new(14, 3.2, 3.5)
	counter.Position = FOOD_SHOP_POSITION + Vector3.new(0, 1.6, 2)
	counter.Anchored = true
	counter.Material = Enum.Material.WoodPlanks
	counter.BrickColor = BrickColor.new("Dark orange")
	counter.Parent = FoodShopFolder

	-- Вывеска
	local sign = Instance.new("Part")
	sign.Size = Vector3.new(16, 2.5, 0.8)
	sign.Position = FOOD_SHOP_POSITION + Vector3.new(0, 7.5, 11)
	sign.Anchored = true
	sign.Material = Enum.Material.Wood
	sign.BrickColor = BrickColor.new("Brown")
	sign.Parent = FoodShopFolder

	local bbSign = Instance.new("BillboardGui", sign)
	bbSign.Size = UDim2.new(0, 260, 0, 40)
	bbSign.StudsOffset = Vector3.new(0, 0, 0.6)
	bbSign.AlwaysOnTop = true

	local signLbl = Instance.new("TextLabel", bbSign)
	signLbl.Size = UDim2.new(1, 0, 1, 0)
	signLbl.BackgroundTransparency = 1
	signLbl.Font = Enum.Font.GothamBlack
	signLbl.TextSize = 16
	signLbl.TextColor3 = Color3.fromRGB(250, 204, 21)
	signLbl.Text = "🥫 ПРОДУКТОВАЯ ЛАВКА"

	-- ProximityPrompt для открытия меню магазина
	local prompt = Instance.new("ProximityPrompt", counter)
	prompt.ActionText = "Открыть меню продуктов"
	prompt.ObjectText = "🥫 Лавка Еды"
	prompt.HoldDuration = 0
	prompt.MaxActivationDistance = 14
	prompt.RequiresLineOfSight = false
end

buildFoodShopBuilding()

-- Обработка покупки еды через RemoteFunction
BuyFoodRemote.OnServerInvoke = function(player, foodKey)
	local item = FOOD_CATALOG[foodKey]
	if not item then
		return { Success = false, Message = "Товар не найден" }
	end

	-- Проверка лимита бесплатного пайка (Максимум 3 батончика в час)
	if foodKey == "Bar" then
		local now = os.time()
		local resetTime = player:GetAttribute("FreeBarResetTime") or 0
		local claimed = player:GetAttribute("FreeBarsClaimed") or 0

		if now >= resetTime then
			claimed = 0
			resetTime = now + 3600 -- 1 час (3600 секунд)
			player:SetAttribute("FreeBarResetTime", resetTime)
			player:SetAttribute("FreeBarsClaimed", 0)
		end

		if claimed >= 3 then
			local waitMinutes = math.max(1, math.ceil((resetTime - now) / 60))
			return { Success = false, Message = string.format("Лимит бесплатного пайка исчерпан (3/3 в час)! Доступно через %d мин.", waitMinutes) }
		end
	end

	-- 1. Проверка наличия ресурсов
	for resKey, amountReq in pairs(item.Cost) do
		local curRes = player:GetAttribute(resKey) or 0
		if curRes < amountReq then
			return { Success = false, Message = "Недостаточно ресурсов!" }
		end
	end

	-- 2. Проверка свободного места в рюкзаке
	local backpack = player:FindFirstChildOfClass("Backpack")
	local maxSlots = player:GetAttribute("MaxSlots") or 5
	local char = player.Character

	if backpack then
		-- Проверяем, есть ли уже неполный стак этого товара
		local hasSpaceInStack = false
		for _, t in ipairs(backpack:GetChildren()) do
			if t:IsA("Tool") and t:GetAttribute("ItemKey") == foodKey then
				local curC = t:GetAttribute("Count") or 1
				local maxS = t:GetAttribute("MaxStack") or 3
				if curC < maxS then
					hasSpaceInStack = true
					break
				end
			end
		end

		if not hasSpaceInStack then
			local currentTools = #backpack:GetChildren() + (char and char:FindFirstChildOfClass("Tool") and 1 or 0)
			if currentTools >= maxSlots then
				return { Success = false, Message = "⚠️ Рюкзак полон! Освободите место." }
			end
		end
	end

	-- 3. Списание ресурсов
	for resKey, amountReq in pairs(item.Cost) do
		local curRes = player:GetAttribute(resKey) or 0
		player:SetAttribute(resKey, curRes - amountReq)

		-- Уменьшаем количество в Tool рюкзака
		if backpack then
			for _, t in ipairs(backpack:GetChildren()) do
				if t:IsA("Tool") and t:GetAttribute("ItemKey") == resKey then
					local c = t:GetAttribute("Count") or 1
					if c > amountReq then
						t:SetAttribute("Count", c - amountReq)
						t.Name = string.format("%s (x%d)", t.Name:match("^[^%(]+") or t.Name, c - amountReq)
					else
						t:Destroy()
					end
					break
				end
			end
		end
	end

	-- 4. Выдача купленной еды в рюкзак
	if _G.GiveItemToPlayer then
		_G.GiveItemToPlayer(player, foodKey, 1)
	end

	if foodKey == "Bar" then
		local claimed = player:GetAttribute("FreeBarsClaimed") or 0
		player:SetAttribute("FreeBarsClaimed", claimed + 1)
	end

	print(string.format("🥫 %s успешно купил: %s!", player.Name, item.Name))
	return { Success = true, Message = "Успешно куплено!" }
end
