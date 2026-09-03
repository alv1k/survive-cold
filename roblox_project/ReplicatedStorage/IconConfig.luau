--[[
    IconConfig.luau
    Централизованный реестр графических иконок Game-icons (PNG/Decals)
    для Инвентаря, Верстака, HUD, Шкафов и Магазинов игры.
--]]

local IconConfig = {}

-- Таблица соответствия ключей предметов именам файлов и Roblox Asset ID
-- При загрузке в Roblox Studio через Asset Manager, укажите Asset ID в AssetId
IconConfig.Icons = {
	-- 🌿 Природные ресурсы
	Branches = { File = "branches.png", Color = Color3.fromRGB(134, 239, 172), Name = "Ветки", FallbackEmoji = "🌿" },
	Stone = { File = "stone.png", Color = Color3.fromRGB(203, 213, 225), Name = "Камень", FallbackEmoji = "⚪" },
	Fiber = { File = "fiber.png", Color = Color3.fromRGB(253, 224, 71), Name = "Волокно", FallbackEmoji = "🌱" },
	Planks = { File = "planks.png", Color = Color3.fromRGB(251, 146, 60), Name = "Доски", FallbackEmoji = "🌲" },
	Parts = { File = "parts.png", Color = Color3.fromRGB(56, 189, 248), Name = "Детали", FallbackEmoji = "⚙️" },
	WolfPelt = { File = "wolf_pelt.png", Color = Color3.fromRGB(203, 213, 225), Name = "Шкура волка", FallbackEmoji = "🐺" },
	YetiPelt = { File = "yeti_pelt.png", Color = Color3.fromRGB(186, 230, 253), Name = "Шкура Йети", FallbackEmoji = "❄️" },

	-- 🗡️ Оружие и Инструменты
	Torch = { File = "torch.png", Color = Color3.fromRGB(251, 146, 60), Name = "Факел", FallbackEmoji = "🔥" },
	Spear = { File = "spear.png", Color = Color3.fromRGB(226, 232, 240), Name = "Копьё", FallbackEmoji = "🗡️" },
	Slingshot = { File = "slingshot.png", Color = Color3.fromRGB(234, 179, 8), Name = "Праща", FallbackEmoji = "🏹" },
	Revolver = { File = "revolver.png", Color = Color3.fromRGB(248, 113, 113), Name = "Револьвер", FallbackEmoji = "🔫" },
	Ammo_Slingshot = { File = "ammo_slingshot.png", Color = Color3.fromRGB(203, 213, 225), Name = "Камни", FallbackEmoji = "⚪" },
	Ammo_Revolver = { File = "ammo_revolver.png", Color = Color3.fromRGB(250, 204, 21), Name = "Патроны", FallbackEmoji = "💥" },

	-- 🍖 Еда и Напитки
	Bar = { File = "bar.png", Color = Color3.fromRGB(245, 158, 11), Name = "Батончик", FallbackEmoji = "🍫" },
	Bread = { File = "bread.png", Color = Color3.fromRGB(253, 224, 71), Name = "Хлеб", FallbackEmoji = "🍞" },
	Chips = { File = "chips.png", Color = Color3.fromRGB(250, 204, 21), Name = "Чипсы", FallbackEmoji = "🥔" },
	Soup = { File = "soup.png", Color = Color3.fromRGB(239, 68, 68), Name = "Суп", FallbackEmoji = "🥫" },
	Pepper = { File = "pepper.png", Color = Color3.fromRGB(220, 38, 38), Name = "Перец", FallbackEmoji = "🌶️" },
	Coffee = { File = "coffee.png", Color = Color3.fromRGB(168, 85, 247), Name = "Кофе", FallbackEmoji = "☕" },
	Steak = { File = "steak.png", Color = Color3.fromRGB(244, 63, 94), Name = "Стейк", FallbackEmoji = "🥩" },

	-- 🪤 Ловушки, Оборона и Костры
	RabbitTrap = { File = "rabbit_trap.png", Color = Color3.fromRGB(148, 163, 184), Name = "Капкан", FallbackEmoji = "🪤" },
	SpikeTrap = { File = "spike_trap.png", Color = Color3.fromRGB(203, 213, 225), Name = "Шипастый пол", FallbackEmoji = "📌" },
	CampfireKit = { File = "campfire_kit.png", Color = Color3.fromRGB(249, 115, 22), Name = "Походный костер", FallbackEmoji = "🔥" },
	Wall = { File = "wall.png", Color = Color3.fromRGB(217, 119, 6), Name = "Защитная стена", FallbackEmoji = "🛡️" },
	Turret = { File = "turret.png", Color = Color3.fromRGB(56, 189, 248), Name = "Авто-Турель", FallbackEmoji = "🏹" },
	HeavyTurret = { File = "heavy_turret.png", Color = Color3.fromRGB(168, 85, 247), Name = "Тяжелая турель", FallbackEmoji = "⚡" },

	-- 🎒 Рюкзаки и Одежда
	Backpack7 = { File = "backpack7.png", Color = Color3.fromRGB(234, 179, 8), Name = "Рюкзак (7)", FallbackEmoji = "🎒" },
	Backpack9 = { File = "backpack9.png", Color = Color3.fromRGB(168, 85, 247), Name = "Рюкзак (9)", FallbackEmoji = "🎒" },
	Clothing_1 = { File = "clothing_sweater.png", Color = Color3.fromRGB(148, 163, 184), Name = "Легкая куртка", FallbackEmoji = "🧥" },
	Clothing_2 = { File = "clothing_sweater.png", Color = Color3.fromRGB(56, 189, 248), Name = "Теплый свитер", FallbackEmoji = "🧥" },
	Clothing_3 = { File = "clothing_parka.png", Color = Color3.fromRGB(203, 213, 225), Name = "Зимнее пальто", FallbackEmoji = "🧥" },
	Clothing_4 = { File = "clothing_parka.png", Color = Color3.fromRGB(186, 230, 253), Name = "Меховая парка", FallbackEmoji = "🧥" },
	WolfVest = { File = "clothing_sweater.png", Color = Color3.fromRGB(203, 213, 225), Name = "Волчья жилетка", FallbackEmoji = "🦺" },
	YetiParka = { File = "clothing_parka.png", Color = Color3.fromRGB(186, 230, 253), Name = "Парка выживальщика", FallbackEmoji = "🐻" },

	-- ⛩️ 7 Древних Реликвий
	Relic_1 = { File = "relic_chalice.png", Color = Color3.fromRGB(250, 204, 21), Name = "Чаша Вечности", FallbackEmoji = "🏆" },
	Relic_2 = { File = "relic_ice_heart.png", Color = Color3.fromRGB(56, 189, 248), Name = "Сердце Бури", FallbackEmoji = "🧊" },
	Relic_3 = { File = "relic_fang.png", Color = Color3.fromRGB(241, 245, 249), Name = "Зуб Хищника", FallbackEmoji = "🐺" },
	Relic_4 = { File = "relic_compass.png", Color = Color3.fromRGB(234, 179, 8), Name = "Компас Геологов", FallbackEmoji = "🧭" },
	Relic_5 = { File = "relic_fire_crystal.png", Color = Color3.fromRGB(239, 68, 68), Name = "Кристалл Пламени", FallbackEmoji = "🔥" },
	Relic_6 = { File = "relic_crown.png", Color = Color3.fromRGB(168, 85, 247), Name = "Корона Короля", FallbackEmoji = "👑" },
	Relic_7 = { File = "relic_seer_eye.png", Color = Color3.fromRGB(192, 132, 252), Name = "Око Провидца", FallbackEmoji = "🔮" },

	-- 🐾 Питомцы
	Pet_Fox = { File = "pet_fox.png", Color = Color3.fromRGB(251, 146, 60), Name = "Снежный Лис", FallbackEmoji = "🦊" },
	Pet_Wolf = { File = "pet_wolf.png", Color = Color3.fromRGB(56, 189, 248), Name = "Ледяной Волк", FallbackEmoji = "🐺" },
	Pet_Bear = { File = "pet_bear.png", Color = Color3.fromRGB(241, 245, 249), Name = "Белый Медведь", FallbackEmoji = "🐻" },

	-- 📊 HUD & Статусы
	HUD_Warmth = { File = "hud_warmth.png", Color = Color3.fromRGB(249, 115, 22), Name = "Тепло", FallbackEmoji = "🔥" },
	HUD_Hunger = { File = "steak.png", Color = Color3.fromRGB(234, 179, 8), Name = "Сытость", FallbackEmoji = "🍗" },
	HUD_Stamina = { File = "hud_stamina.png", Color = Color3.fromRGB(56, 189, 248), Name = "Бег", FallbackEmoji = "⚡" },
	HUD_Health = { File = "hud_health.png", Color = Color3.fromRGB(239, 68, 68), Name = "Здоровье", FallbackEmoji = "❤️" },
	HUD_Blizzard = { File = "hud_blizzard.png", Color = Color3.fromRGB(186, 230, 253), Name = "Буря", FallbackEmoji = "❄️" }
}

-- Создание компактного красивого бейджа иконки для UI
function IconConfig.CreateIconBadge(parent, iconKey, size, bgTransparency)
	local cfg = IconConfig.Icons[iconKey]
	size = size or UDim2.new(0, 32, 0, 32)

	local badge = Instance.new("Frame")
	badge.Name = "IconBadge_" .. tostring(iconKey)
	badge.Size = size
	badge.BackgroundColor3 = Color3.fromRGB(30, 41, 59)
	badge.BackgroundTransparency = bgTransparency or 0.2
	badge.BorderSizePixel = 0
	badge.Parent = parent
	Instance.new("UICorner", badge).CornerRadius = UDim.new(0, 8)

	local iconColor = cfg and cfg.Color or Color3.fromRGB(241, 245, 249)

	local stroke = Instance.new("UIStroke", badge)
	stroke.Color = iconColor
	stroke.Transparency = 0.4
	stroke.Thickness = 1.2

	local img = Instance.new("ImageLabel")
	img.Name = "Icon"
	img.Size = UDim2.new(1, -6, 1, -6)
	img.Position = UDim2.new(0.5, 0, 0.5, 0)
	img.AnchorPoint = Vector2.new(0.5, 0.5)
	img.BackgroundTransparency = 1
	img.ImageColor3 = iconColor
	img.ScaleType = Enum.ScaleType.Fit
	img.Parent = badge

	if cfg and cfg.AssetId then
		img.Image = cfg.AssetId
	end

	return badge, img
end

return IconConfig
