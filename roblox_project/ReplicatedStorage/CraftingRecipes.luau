--[[
    CraftingRecipes.luau
    Конфигурация Верстака (5 Уровней), Оружия, Боеприпасов, Защиты и Рецептов для Roblox.
--]]

local CraftingRecipes = {}

-- Лимиты стаков в инвентаре
CraftingRecipes.StackLimits = {
	Branches = 5,
	Fiber = 5,
	Stone = 5,
	Planks = 3,
	Torch = 4,
	Parts = 4,      -- ⚙️ Детали (стак 4)
	WolfPelt = 5,   -- 🐺 Шкура волка
	YetiPelt = 5,   -- ❄️ Шкура йети
	Bar = 3,
	Bread = 3,
	Chips = 3,
	Soup = 3,
	Pepper = 3,
	Coffee = 3,
	Steak = 3,
	RawMeat = 5,
	RabbitFur = 5,
	CampfireKit = 2,
	RabbitTrap = 3,
	SpikeTrap = 5
}

-- Конфигурация 5 уровней верстака
CraftingRecipes.WorkbenchTiers = {
	[1] = {
		Name = "Уровень 1: Базовый",
		Desc = "Базовые инструменты выживания: Факел, Копье, Походный костер, Капкан",
		UpgradeCost = { Parts = 2, Planks = 3 },
		UpgradeCostText = "2 ⚙️ + 3 🌲"
	},
	[2] = {
		Name = "Уровень 2: Продвинутый",
		Desc = "Дальний бой и расширение инвентаря: Рогатка, 7 Слотов",
		UpgradeCost = { Parts = 3, WolfPelt = 2, Planks = 4 },
		UpgradeCostText = "3 ⚙️ + 2 🐺 + 4 🌲"
	},
	[3] = {
		Name = "Уровень 3: Инженерный",
		Desc = "Оборона и турели: Авто-Турель, Шипастые полы, Стена, Волчья жилетка",
		UpgradeCost = { Parts = 4, YetiPelt = 2, Planks = 5 },
		UpgradeCostText = "4 ⚙️ + 2 ❄️ + 5 🌲"
	},
	[4] = {
		Name = "Уровень 4: Оружейный",
		Desc = "Огнестрельное оружие: Револьвер, Патроны, 9 Слотов",
		UpgradeCost = { Parts = 5, YetiPelt = 3, Stone = 6 },
		UpgradeCostText = "5 ⚙️ + 3 ❄️ + 6 ⚪"
	},
	[5] = {
		Name = "Уровень 5: Мастерский",
		Desc = "Тяжелая сдвоенная турель и элитная парка выживальщика",
		UpgradeCost = nil,
		UpgradeCostText = "👑 МАКСИМАЛЬНЫЙ УРОВЕНЬ"
	}
}

-- Чертежи крафта
CraftingRecipes.Recipes = {
	-- Уровень 1
	CampfireKit = {
		Tier = 1,
		Category = "Gear",
		DisplayName = "🔥 Походный костер",
		Ingredients = { Branches = 3, Stone = 2 },
		ResultItem = "CampfireKit",
		ResultCount = 1,
		Desc = "3 Ветки + 2 Камня (Согрев в поле на 90с + жарка мяса)"
	},
	RabbitTrap = {
		Tier = 1,
		Category = "Gear",
		DisplayName = "🪤 Охотничий капкан",
		Ingredients = { Branches = 3, Fiber = 2 },
		ResultItem = "RabbitTrap",
		ResultCount = 1,
		Desc = "3 Ветки + 2 Волокна (Авто-ловля зайцев в лесу)"
	},
	Spear = {
		Tier = 1,
		Category = "Weapons",
		DisplayName = "🗡️ Пика (Копье)",
		Ingredients = { Branches = 3, Stone = 2 },
		ResultItem = "Spear",
		ResultCount = 1,
		IsWeapon = true,
		WeaponType = "Melee",
		Damage = 30,
		Desc = "3 Ветки + 2 Камня (Ближний бой, урон: 30)"
	},
	Torch = {
		Tier = 1,
		Category = "Gear",
		DisplayName = "🔥 Факел",
		Ingredients = { Branches = 5, Fiber = 5 },
		ResultItem = "Torch",
		ResultCount = 1,
		Desc = "5 Веток + 5 Волокна (Согревает в руке +0.25)"
	},

	-- Уровень 2
	Slingshot = {
		Tier = 2,
		Category = "Weapons",
		DisplayName = "🏹 Рогатка (Праща)",
		Ingredients = { Branches = 4, Fiber = 4 },
		RequiredWeapon = "Spear",
		ResultItem = "Slingshot",
		ResultCount = 1,
		BonusAmmo = { AmmoType = "Ammo_Slingshot", Count = 50 },
		IsWeapon = true,
		WeaponType = "Ranged",
		AmmoType = "Ammo_Slingshot",
		Damage = 20,
		Desc = "4 Ветки + 4 Волокна (+50 снарядов в сумку боеприпасов)"
	},
	StoneAmmo = {
		Tier = 2,
		Category = "Ammo",
		DisplayName = "⚪ 50x Снарядов",
		Ingredients = { Stone = 2 },
		RequiredWeapon = "Slingshot",
		IsDirectAmmo = true,
		AmmoType = "Ammo_Slingshot",
		AmmoAmount = 50,
		Desc = "2 Камня ➔ +50 снарядов (НЕ занимает слот инвентаря)"
	},
	Backpack7 = {
		Tier = 2,
		Category = "Gear",
		DisplayName = "🎒 Рюкзак (7 Слотов)",
		Ingredients = { Planks = 3, Fiber = 5, WolfPelt = 1 },
		ResultItem = "Backpack7",
		SlotsUpgrade = 7,
		Desc = "3 Доски + 5 Волокна + 1 🐺 Шкура (+2 слота)"
	},

	-- Уровень 3
	SpikeTrap = {
		Tier = 3,
		Category = "Structures",
		DisplayName = "📌 Шипастый Пол",
		Ingredients = { Planks = 2, Stone = 2 },
		ResultItem = "SpikeTrap",
		ResultCount = 1,
		Damage = 25,
		Desc = "2 Доски + 2 Камня (Наносит урон и замедляет мобов)"
	},
	Wall = {
		Tier = 3,
		Category = "Structures",
		DisplayName = "🛡️ Защитная Стена",
		Ingredients = { Planks = 3 },
		ResultItem = "Wall",
		Health = 100,
		Desc = "3 Доски (100 HP прочности)"
	},
	Turret = {
		Tier = 3,
		Category = "Turrets",
		DisplayName = "🏹 Авто-Турель",
		Ingredients = { Planks = 3, Stone = 5, Parts = 1 },
		ResultItem = "Turret",
		Range = 40,
		Damage = 20,
		FireRate = 1.0,
		IsHeavy = false,
		Desc = "3 Доски + 5 Камней + 1 ⚙️ Деталь (Авто-стрельба, урон: 20)"
	},
	WolfVest = {
		Tier = 3,
		Category = "Gear",
		DisplayName = "🦺 Волчья жилетка",
		Ingredients = { WolfPelt = 2, Fiber = 3 },
		ClothingLevel = 2,
		ClothingProtection = 0.20,
		Desc = "2 🐺 Шкуры + 3 Волокна (Костюм Lvl 2, +20% защиты)"
	},

	-- Уровень 4
	Revolver = {
		Tier = 4,
		Category = "Weapons",
		DisplayName = "🔫 Револьвер",
		Ingredients = { Planks = 4, Stone = 6, Fiber = 4, Parts = 2 },
		RequiredWeapon = "Slingshot",
		ResultItem = "Revolver",
		ResultCount = 1,
		BonusAmmo = { AmmoType = "Ammo_Revolver", Count = 20 },
		IsWeapon = true,
		WeaponType = "Ranged",
		AmmoType = "Ammo_Revolver",
		Damage = 55,
		Desc = "4 Доски + 6 Камней + 4 Волокна + 2 ⚙️ Детали (+20 пуль в патронташ)"
	},
	RevolverAmmo = {
		Tier = 4,
		Category = "Ammo",
		DisplayName = "💥 20x Пуль револьвера",
		Ingredients = { Stone = 2, Branches = 2 },
		RequiredWeapon = "Revolver",
		IsDirectAmmo = true,
		AmmoType = "Ammo_Revolver",
		AmmoAmount = 20,
		Desc = "2 Камня + 2 Ветки ➔ +20 пуль (НЕ занимает слот инвентаря)"
	},
	Backpack9 = {
		Tier = 4,
		Category = "Gear",
		DisplayName = "🎒 Рюкзак (9 Слотов)",
		Ingredients = { Planks = 5, Fiber = 5, YetiPelt = 2 },
		ResultItem = "Backpack9",
		SlotsUpgrade = 9,
		Desc = "5 Досок + 5 Волокна + 2 ❄️ Шкуры Йети (+4 слота)"
	},

	-- Уровень 5
	HeavyTurret = {
		Tier = 5,
		Category = "Turrets",
		DisplayName = "⚡ Тяжелая Сдвоенная Турель",
		Ingredients = { Planks = 4, Stone = 6, Parts = 2, YetiPelt = 1 },
		ResultItem = "HeavyTurret",
		Range = 50,
		Damage = 35,
		FireRate = 0.5, -- Двойная скорострельность!
		IsHeavy = true,
		Desc = "4 Доски + 6 Камней + 2 ⚙️ Детали + 1 ❄️ Шкура (⚡ 2X скорострельность, урон: 35)"
	},
	YetiParka = {
		Tier = 5,
		Category = "Gear",
		DisplayName = "🐻 Парка выживальщика",
		Ingredients = { YetiPelt = 3, WolfPelt = 3, Fiber = 5 },
		ClothingLevel = 4,
		ClothingProtection = 0.40,
		Desc = "3 ❄️ Шкуры + 3 🐺 Шкуры + 5 Волокна (Костюм Lvl 4, +40% защиты)"
	}
}

return CraftingRecipes
