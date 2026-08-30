--[[
    FoodShopService.server.luau
    Серверный скрипт Продуктового Магазина и Поварни:
    - Теплая зона и очаг/печь для согрева покупателей
    - Витрины с едой (батончики, суп, чипсы, перец, кофе, стейк, хлеб)
    - Покупка за собранные природные ресурсы (ветки, волокно, камень, доски)
--]]

local Players = game:GetService(Players)

local FOOD_SHOP_POSITION = Vector3.new(-180, 2.5, -220)

local FoodShopFolder = workspace:FindFirstChild(FoodShop) or Instance.new(Folder, workspace)
FoodShopFolder.Name = FoodShop

local FoodCatalog = {
	{ Id = bar, Name = 🍫 Энергетический батончик, Cost = {}, Desc = 🎉 БЕСПЛАТНЫЙ ПАЁК (0 🪵), Hp = 15, Warmth = 10 },
	{ Id = bread, Name = 🍞 Питательный хлеб, Cost = { Branches = 2 }, Desc = 2 Ветки, Hp = 25, Warmth = 15 },
	{ Id = chips, Name = 🥔 Хрустящие чипсы, Cost = { Fiber = 2 }, Desc = 2 Волокна, Hp = 15, Warmth = 8 },
	{ Id = soup, Name = 🥫 Горячий мясной суп, Cost = { Branches = 3, Fiber = 2 }, Desc = 3 Ветки + 2 Волокна, Hp = 35, Warmth = 30 },
	{ Id = pepper, Name = 🌶️ Огненный перец, Cost = { Stone = 2, Branches = 2 }, Desc = 2 Камня + 2 Ветки, Hp = 5, Warmth = 50 },
	{ Id = coffee, Name = ☕ Горячий кофе (Термос), Cost = { Branches = 3, Fiber = 2 }, Desc = 3 Ветки + 2 Волокна (+Скорость), Hp = 20, Warmth = 40, SpeedBoost = true },
	{ Id = steak, Name = 🥩 Жареный стейк на гриле, Cost = { Planks = 1, Branches = 2 }, Desc = 1 Доска + 2 Ветки (+60 HP), Hp = 60, Warmth = 35 }
}

local function setupFoodShop()
	local shopBase = Instance.new(Part)
	shopBase.Name = FoodShopBase
	shopBase.Size = Vector3.new(28, 1, 22)
	shopBase.Position = FOOD_SHOP_POSITION
	shopBase.Anchored = true
	shopBase.Material = Enum.Material.WoodPlanks
	shopBase.BrickColor = BrickColor.new(Forest green)
	shopBase.Parent = FoodShopFolder

	local oven = Instance.new(Part)
	oven.Name = FoodShopOven
	oven.Size = Vector3.new(4, 4, 4)
	oven.Position = FOOD_SHOP_POSITION + Vector3.new(10, 2, -6)
	oven.Anchored = true
	oven.Material = Enum.Material.Brick
	oven.BrickColor = BrickColor.new(Bright orange)
	oven:SetAttribute(HeatRadius, 35)
	oven:SetAttribute(HeatPower, 15)
	oven.Parent = workspace:FindFirstChild(HeatSources) or FoodShopFolder

	for i, item in ipairs(FoodCatalog) do
		local stallPart = Instance.new(Part)
		stallPart.Name = Stall_ .. item.Id
		stallPart.Size = Vector3.new(2.5, 3, 2.5)
		stallPart.Position = FOOD_SHOP_POSITION + Vector3.new(-10 + ((i - 1) * 3.3), 2, 0)
		stallPart.Anchored = true
		stallPart.Material = Enum.Material.SmoothPlastic
		stallPart.BrickColor = BrickColor.new(Bright yellow)
		stallPart.Parent = FoodShopFolder

		local prompt = Instance.new(ProximityPrompt, stallPart)
		prompt.ActionText = string.format(Купить: %s (%s), item.Name, item.Desc)
		prompt.ObjectText = string.format(🥫 Продукт (+%d HP, +%d🔥), item.Hp, item.Warmth)
		prompt.HoldDuration = 0.4

		prompt.Triggered:Connect(function(player)
			local canBuy = true
			for resourceName, amount in pairs(item.Cost) do
				local currentRes = player:GetAttribute(resourceName) or 0
				if currentRes < amount then
					canBuy = false
					break
				end
			end

			if canBuy then
				for resourceName, amount in pairs(item.Cost) do
					local currentRes = player:GetAttribute(resourceName) or 0
					player:SetAttribute(resourceName, currentRes - amount)
				end

				local currentFoodCount = player:GetAttribute(Food_ .. item.Id) or 0
				player:SetAttribute(Food_ .. item.Id, currentFoodCount + 1)
				print(string.format(🥫 %s купил %s!, player.Name, item.Name))
			else
				print(string.format(⚠️ У %s недостаточно ресурсов для покупки %s!, player.Name, item.Name))
			end
		end)
	end
end

setupFoodShop()
