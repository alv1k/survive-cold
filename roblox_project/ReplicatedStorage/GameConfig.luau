--!strict
--[[
    ReplicatedStorage/GameConfig.luau
    Централизованный конфигурационный модуль мира, координат ключевых локаций и базового баланса.
--]]

local GameConfig = {}

-- 1. Координаты ключевых локаций мира
GameConfig.Locations = {
	PlayerHouse = {
		Name = "Дом Выживших",
		Position = Vector3.new(0, 2.0, 0),
		WaypointHeight = 14,
		Color = Color3.fromRGB(56, 189, 248),
		BgColor = Color3.fromRGB(15, 23, 42),
		MaxDist = 3500,
		IsPlayerHouse = true
	},
	FoodShop = {
		Name = "Продуктовая Лавка",
		Position = Vector3.new(-50, 2.0, 0),
		WaypointHeight = 14,
		Color = Color3.fromRGB(250, 204, 21),
		BgColor = Color3.fromRGB(15, 23, 42),
		IconKey = "Soup",
		MaxDist = 3000,
		-- Границы зоны укрытия от холода (размеры магазина)
		Bounds = {
			SizeX = 22,
			SizeZ = 20,
			MinY = 1.0,
			MaxY = 18.0
		}
	},
	ClothingShop = {
		Name = "Мастерская Одежды",
		Position = Vector3.new(70, 2.0, 0),
		WaypointHeight = 14,
		Color = Color3.fromRGB(168, 85, 247),
		BgColor = Color3.fromRGB(15, 23, 42),
		IconKey = "Clothing_4",
		MaxDist = 3000
	},
	AncientAltar = {
		Name = "Древний Алтарь",
		Position = Vector3.new(-60, 1.25, 80),
		WaypointHeight = 14,
		Color = Color3.fromRGB(244, 63, 94),
		BgColor = Color3.fromRGB(15, 23, 42),
		IconKey = "Altar",
		MaxDist = 4000
	}
}

-- 2. Баланс выживания
GameConfig.Survival = {
	BaseMaxHealth = 100,
	BaseMaxWarmth = 100,
	BaseMaxHunger = 100,
	BaseMaxStamina = 100,
	DefaultSlots = 5,
	DefaultWorkbenchLevel = 1,

	-- Скорость замерзания (в секунду)
	ClearColdRate = 1.0,
	NightColdRate = 2.6,
	BlizzardColdRate = 5.0,

	-- Скорость траты голода (в секунду)
	HungerDrainRate = 0.15,
	SprintHungerMultiplier = 1.5,
	BlizzardHungerMultiplier = 1.25,
	WarmShelterHungerMultiplier = 0.6,

	-- Скорость согревания
	FireplaceWarmthGain = 6.0,
	TorchWarmthGain = 4.0
}

return GameConfig
