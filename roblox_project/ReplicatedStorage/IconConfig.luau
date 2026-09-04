--[[
    IconConfig.luau
    Централизованный реестр игровых иконок и бейджей
    для Инвентаря, Верстака, HUD, Шкафов и Магазинов игры.
--]]

local IconConfig = {}

-- Таблица конфигураций предметов и UI компонентов
-- Если указан AssetId (например rbxassetid://...), используется графическая текстура
-- В противном случае используется чистый, стилизованный нативный UI бейдж с FallbackEmoji
IconConfig.Icons = {
	-- 🌿 Природные ресурсы
	Branches = { Color = Color3.fromRGB(134, 239, 172), Name = "Ветки", FallbackEmoji = "🌿" },
	Stone = { Color = Color3.fromRGB(203, 213, 225), Name = "Камень", FallbackEmoji = "⚪" },
	Fiber = { Color = Color3.fromRGB(253, 224, 71), Name = "Волокно", FallbackEmoji = "🌱" },
	Planks = { Color = Color3.fromRGB(251, 146, 60), Name = "Доски", FallbackEmoji = "🌲" },
	Parts = { Color = Color3.fromRGB(56, 189, 248), Name = "Детали", FallbackEmoji = "⚙️" },
	WolfPelt = { Color = Color3.fromRGB(203, 213, 225), Name = "Шкура волка", FallbackEmoji = "🐺" },
	YetiPelt = { Color = Color3.fromRGB(186, 230, 253), Name = "Шкура Йети", FallbackEmoji = "❄️" },

	-- 🗡️ Оружие и Инструменты
	Torch = { Color = Color3.fromRGB(251, 146, 60), Name = "Факел", FallbackEmoji = "🔥" },
	Spear = { Color = Color3.fromRGB(226, 232, 240), Name = "Копьё", FallbackEmoji = "🗡️" },
	Slingshot = { Color = Color3.fromRGB(234, 179, 8), Name = "Праща", FallbackEmoji = "🏹" },
	Revolver = { Color = Color3.fromRGB(248, 113, 113), Name = "Револьвер", FallbackEmoji = "🔫" },
	Ammo_Slingshot = { Color = Color3.fromRGB(203, 213, 225), Name = "Камни", FallbackEmoji = "⚪" },
	Ammo_Revolver = { Color = Color3.fromRGB(250, 204, 21), Name = "Патроны", FallbackEmoji = "💥" },

	-- 🍖 Еда и Напитки
	Bar = { Color = Color3.fromRGB(245, 158, 11), Name = "Батончик", FallbackEmoji = "🍫" },
	Bread = { Color = Color3.fromRGB(253, 224, 71), Name = "Хлеб", FallbackEmoji = "🍞" },
	Chips = { Color = Color3.fromRGB(250, 204, 21), Name = "Чипсы", FallbackEmoji = "🥔" },
	Soup = { Color = Color3.fromRGB(239, 68, 68), Name = "Суп", FallbackEmoji = "🥫" },
	Pepper = { Color = Color3.fromRGB(220, 38, 38), Name = "Перец", FallbackEmoji = "🌶️" },
	Coffee = { Color = Color3.fromRGB(168, 85, 247), Name = "Кофе", FallbackEmoji = "☕" },
	Steak = { Color = Color3.fromRGB(244, 63, 94), Name = "Стейк", FallbackEmoji = "🥩" },

	-- 🪤 Ловушки, Оборона и Костры
	RabbitTrap = { Color = Color3.fromRGB(148, 163, 184), Name = "Капкан", FallbackEmoji = "🪤" },
	SpikeTrap = { Color = Color3.fromRGB(203, 213, 225), Name = "Шипастый пол", FallbackEmoji = "📌" },
	CampfireKit = { Color = Color3.fromRGB(249, 115, 22), Name = "Походный костер", FallbackEmoji = "🔥" },
	Wall = { Color = Color3.fromRGB(217, 119, 6), Name = "Защитная стена", FallbackEmoji = "🛡️" },
	Turret = { Color = Color3.fromRGB(56, 189, 248), Name = "Авто-Турель", FallbackEmoji = "🏹" },
	HeavyTurret = { Color = Color3.fromRGB(168, 85, 247), Name = "Тяжелая турель", FallbackEmoji = "⚡" },

	-- 🎒 Рюкзаки и Одежда
	Backpack7 = { Color = Color3.fromRGB(234, 179, 8), Name = "Рюкзак (7)", FallbackEmoji = "🎒" },
	Backpack9 = { Color = Color3.fromRGB(168, 85, 247), Name = "Рюкзак (9)", FallbackEmoji = "🎒" },
	Clothing_1 = { Color = Color3.fromRGB(148, 163, 184), Name = "Легкая куртка", FallbackEmoji = "🧥" },
	Clothing_2 = { Color = Color3.fromRGB(56, 189, 248), Name = "Теплый свитер", FallbackEmoji = "🧥" },
	Clothing_3 = { Color = Color3.fromRGB(203, 213, 225), Name = "Зимнее пальто", FallbackEmoji = "🧥" },
	Clothing_4 = { Color = Color3.fromRGB(186, 230, 253), Name = "Меховая парка", FallbackEmoji = "🧥" },
	WolfVest = { Color = Color3.fromRGB(203, 213, 225), Name = "Волчья жилетка", FallbackEmoji = "🦺" },
	YetiParka = { Color = Color3.fromRGB(186, 230, 253), Name = "Парка выживальщика", FallbackEmoji = "🐻" },

	-- ⛩️ 7 Древних Реликвий
	Relic_1 = { Color = Color3.fromRGB(250, 204, 21), Name = "Чаша Вечности", FallbackEmoji = "🏆" },
	Relic_2 = { Color = Color3.fromRGB(56, 189, 248), Name = "Сердце Бури", FallbackEmoji = "🧊" },
	Relic_3 = { Color = Color3.fromRGB(241, 245, 249), Name = "Зуб Хищника", FallbackEmoji = "🐺" },
	Relic_4 = { Color = Color3.fromRGB(234, 179, 8), Name = "Компас Геологов", FallbackEmoji = "🧭" },
	Relic_5 = { Color = Color3.fromRGB(239, 68, 68), Name = "Кристалл Пламени", FallbackEmoji = "🔥" },
	Relic_6 = { Color = Color3.fromRGB(168, 85, 247), Name = "Корона Короля", FallbackEmoji = "👑" },
	Relic_7 = { Color = Color3.fromRGB(192, 132, 252), Name = "Око Провидца", FallbackEmoji = "🔮" },

	-- 🐾 Питомцы
	Pet_Fox = { Color = Color3.fromRGB(251, 146, 60), Name = "Снежный Лис", FallbackEmoji = "🦊" },
	Pet_Wolf = { Color = Color3.fromRGB(56, 189, 248), Name = "Ледяной Волк", FallbackEmoji = "🐺" },
	Pet_Bear = { Color = Color3.fromRGB(241, 245, 249), Name = "Белый Медведь", FallbackEmoji = "🐻" },

	-- 📊 HUD & Статусы
	HUD_Warmth = { Color = Color3.fromRGB(249, 115, 22), Name = "Тепло", FallbackEmoji = "🔥" },
	HUD_Hunger = { Color = Color3.fromRGB(234, 179, 8), Name = "Сытость", FallbackEmoji = "🍗" },
	HUD_Stamina = { Color = Color3.fromRGB(56, 189, 248), Name = "Бег", FallbackEmoji = "⚡" },
	HUD_Health = { Color = Color3.fromRGB(239, 68, 68), Name = "Здоровье", FallbackEmoji = "❤️" },
	HUD_Blizzard = { Color = Color3.fromRGB(186, 230, 253), Name = "Буря", FallbackEmoji = "❄️" },

	-- 🖥️ Системный UI и навигация
	UI_Close = { Color = Color3.fromRGB(255, 255, 255), Name = "Закрыть", FallbackEmoji = "✕" },
	UI_ArrowLeft = { Color = Color3.fromRGB(255, 255, 255), Name = "Назад", FallbackEmoji = "◀" },
	UI_ArrowRight = { Color = Color3.fromRGB(255, 255, 255), Name = "Вперед", FallbackEmoji = "▶" },
	UI_Guide = { Color = Color3.fromRGB(56, 189, 248), Name = "Гид", FallbackEmoji = "📖" },
	UI_Hammer = { Color = Color3.fromRGB(74, 222, 128), Name = "Создать", FallbackEmoji = "🔨" },
	UI_Anvil = { Color = Color3.fromRGB(250, 204, 21), Name = "Улучшить", FallbackEmoji = "⭐" },
	UI_Swords = { Color = Color3.fromRGB(248, 113, 113), Name = "Оружие", FallbackEmoji = "🗡️" },
	UI_Tent = { Color = Color3.fromRGB(251, 146, 60), Name = "Снаряжение", FallbackEmoji = "⛺" },
	UI_Shield = { Color = Color3.fromRGB(56, 189, 248), Name = "Оборона", FallbackEmoji = "🛡️" },
	UI_Check = { Color = Color3.fromRGB(34, 197, 94), Name = "Готово", FallbackEmoji = "✓" },
	UI_Skull = { Color = Color3.fromRGB(239, 68, 68), Name = "Смерть", FallbackEmoji = "💀" },
}

local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Получение реальной текстуры иконки (из AssetId)
function IconConfig.GetIconImage(iconKey)
	local cfg = IconConfig.Icons[iconKey]
	if not cfg then return "" end

	if cfg.AssetId and cfg.AssetId ~= "" then
		return cfg.AssetId
	end

	return ""
end

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

	local resolvedImage = IconConfig.GetIconImage(iconKey)
	if resolvedImage and resolvedImage ~= "" then
		local img = Instance.new("ImageLabel")
		img.Name = "Icon"
		img.Size = UDim2.new(1, -6, 1, -6)
		img.Position = UDim2.new(0.5, 0, 0.5, 0)
		img.AnchorPoint = Vector2.new(0.5, 0.5)
		img.BackgroundTransparency = 1
		img.ImageColor3 = iconColor
		img.ScaleType = Enum.ScaleType.Fit
		img.Image = resolvedImage
		img.Parent = badge
		return badge, img
	else
		local txt = Instance.new("TextLabel")
		txt.Name = "Icon"
		txt.Size = UDim2.new(1, -4, 1, -4)
		txt.Position = UDim2.new(0.5, 0, 0.5, 0)
		txt.AnchorPoint = Vector2.new(0.5, 0.5)
		txt.BackgroundTransparency = 1
		txt.TextColor3 = iconColor
		txt.Font = Enum.Font.GothamBold
		txt.TextScaled = true
		txt.Text = cfg and cfg.FallbackEmoji or "•"
		txt.Parent = badge
		return badge, txt
	end
end

-- Создание кнопки с графической или текстовой иконкой (например, крестик закрытия, стрелочки)
function IconConfig.CreateIconButton(parent, iconKey, size, bgCol, strokeCol)
	local cfg = IconConfig.Icons[iconKey]
	size = size or UDim2.new(0, 36, 0, 36)

	local btn = Instance.new("TextButton")
	btn.Name = "Btn_" .. tostring(iconKey)
	btn.Size = size
	btn.BackgroundColor3 = bgCol or Color3.fromRGB(220, 38, 38)
	btn.Text = ""
	btn.AutoButtonColor = true
	btn.Parent = parent
	Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 8)

	local stroke = Instance.new("UIStroke", btn)
	stroke.Color = strokeCol or Color3.fromRGB(254, 202, 202)
	stroke.Thickness = 1.5

	local resolved = IconConfig.GetIconImage(iconKey)
	if resolved and resolved ~= "" then
		local img = Instance.new("ImageLabel")
		img.Name = "IconImg"
		img.Size = UDim2.new(1, -8, 1, -8)
		img.Position = UDim2.new(0.5, 0, 0.5, 0)
		img.AnchorPoint = Vector2.new(0.5, 0.5)
		img.BackgroundTransparency = 1
		img.ImageColor3 = (cfg and cfg.Color) or Color3.fromRGB(255, 255, 255)
		img.ScaleType = Enum.ScaleType.Fit
		img.Image = resolved
		img.Parent = btn
		return btn, img
	else
		btn.Text = cfg and cfg.FallbackEmoji or "✕"
		btn.TextColor3 = (cfg and cfg.Color) or Color3.fromRGB(255, 255, 255)
		btn.Font = Enum.Font.GothamBold
		btn.TextSize = 18
		return btn, btn
	end
end

return IconConfig



