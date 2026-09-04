--[[
    NativeInventoryService.server.luau
    Серверная система инвентаря с детализированными 3D-моделями всех предметов:
    - Нативное управление player.Backpack и Tool
    - Проработанные многосоставные 3D-модели в руках (оружие, еда, факелы, капканы)
    - 120-секундный таймер горения факелов в руках
    - Нативное поедание еды по клику ЛКМ
--]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local RemotesFolder = ReplicatedStorage:FindFirstChild("Remotes") or Instance.new("Folder", ReplicatedStorage)
RemotesFolder.Name = "Remotes"

local IconConfig = require(ReplicatedStorage:WaitForChild("IconConfig", 10))

local GiveItemBindable = ReplicatedStorage:FindFirstChild("GiveItem") or Instance.new("BindableFunction", ReplicatedStorage)
GiveItemBindable.Name = "GiveItem"

local ITEM_CONFIGS = {
	Torch = { Name = "🔥 Факел", MaxStack = 4, HasFire = true },
	Branches = { Name = "🌿 Ветки", MaxStack = 5 },
	Fiber = { Name = "🌱 Волокно", MaxStack = 5 },
	Stone = { Name = "⚪ Камень", MaxStack = 5 },
	Planks = { Name = "🌲 Доски", MaxStack = 3 },
	Parts = { Name = "⚙️ Детали", MaxStack = 4 },
	WolfPelt = { Name = "🐺 Шкура Волка", MaxStack = 5 },
	YetiPelt = { Name = "❄️ Шкура Йети", MaxStack = 5 },
	
	-- Еда (Единое линейное восстановление: +60 Сытости, +50 Тепла, +25 Здоровья)
	Bar = { Name = "🍫 Батончик", MaxStack = 3, IsFood = true, Warmth = 50, Hunger = 60, Health = 25 },
	Bread = { Name = "🍞 Хлеб", MaxStack = 3, IsFood = true, Warmth = 50, Hunger = 60, Health = 25 },
	Chips = { Name = "🥔 Чипсы", MaxStack = 3, IsFood = true, Warmth = 50, Hunger = 60, Health = 25 },
	Soup = { Name = "🥫 Суп", MaxStack = 3, IsFood = true, Warmth = 50, Hunger = 60, Health = 25 },
	Pepper = { Name = "🌶️ Перец", MaxStack = 3, IsFood = true, Warmth = 50, Hunger = 60, Health = 25 },
	Coffee = { Name = "☕ Кофе", MaxStack = 3, IsFood = true, Warmth = 50, Hunger = 60, Health = 25 },
	Steak = { Name = "🥩 Стейк", MaxStack = 2, IsFood = true, Warmth = 50, Hunger = 60, Health = 25 },

	-- Ловушки и постройки
	RabbitTrap = { Name = "🪤 Капкан", MaxStack = 3, IsPlaceable = true },
	SpikeTrap = { Name = "📌 Шипастый Пол", MaxStack = 3, IsPlaceable = true },
	CampfireKit = { Name = "🔥 Походный костер", MaxStack = 2, IsPlaceable = true },
	
	-- Оружие
	Spear = { Name = "🗡️ Копье", MaxStack = 1, IsWeapon = true, WeaponType = "Melee", Damage = 30, FireRate = 0.8 },
	Slingshot = { Name = "🏹 Праща", MaxStack = 1, IsWeapon = true, WeaponType = "Ranged", AmmoType = "Ammo_Slingshot", Damage = 20, FireRate = 0.6 },
	Revolver = { Name = "🔫 Револьвер", MaxStack = 1, IsWeapon = true, WeaponType = "Ranged", AmmoType = "Ammo_Revolver", Damage = 55, FireRate = 0.35 }
}

local ModelHelper = require(ReplicatedStorage:WaitForChild("ModelHelper", 10))

-- Функция сборки детализированной 3D-модели для Handle инструмента
local function attachDetailed3DModel(tool, itemKey)
	-- 1. Пробуем собрать Tool из найденной 3D-модели через универсальный ModelHelper
	local handle = ModelHelper.assembleTool(itemKey, tool)
	if handle then
		print(string.format("✅ [3D Tool] Успешно подгружена 3D-модель для '%s' через ModelHelper", itemKey))
		return handle
	end

	-- Процедурный сборщик (Стилизованная модульная модель в точном соответствии с spear-2)
	local handle = Instance.new("Part")
	handle.Name = "Handle"
	handle.CanCollide = false
	handle.Massless = true
	handle.Anchored = false
	handle.Parent = tool

	local function addSubPart(name, size, cfOffset, material, color)
		local sub = Instance.new("Part")
		sub.Name = name
		sub.Size = size
		sub.CFrame = handle.CFrame * cfOffset
		sub.Material = material
		sub.BrickColor = color
		sub.CanCollide = false
		sub.Massless = true
		sub.Parent = handle

		local weld = Instance.new("WeldConstraint")
		weld.Part0 = handle
		weld.Part1 = sub
		weld.Parent = sub
		return sub
	end

	if itemKey == "Torch" then
		handle.Size = Vector3.new(0.4, 2.6, 0.4)
		handle.Material = Enum.Material.Wood
		handle.BrickColor = BrickColor.new("Reddish brown")

		-- Тряпичная обмотка на кончике факела
		local head = addSubPart("Head", Vector3.new(0.65, 0.7, 0.65), CFrame.new(0, 1.1, 0), Enum.Material.Fabric, BrickColor.new("Dark orange"))
		
		local fire = Instance.new("Fire", head)
		fire.Size = 3.5
		fire.Heat = 10

		local light = Instance.new("PointLight", head)
		light.Color = Color3.fromRGB(255, 160, 50)
		light.Range = 25
		light.Brightness = 2.5

	elseif itemKey == "Spear" then
		-- Рукоять хвата (Handle) в точке (0,0,0) с кожаной обмоткой
		handle.Size = Vector3.new(0.35, 1.2, 0.35)
		handle.Material = Enum.Material.SmoothPlastic
		handle.BrickColor = BrickColor.new("Dark orange") -- leather_tan

		-- Кольца на рукояти
		addSubPart("GripRingTop", Vector3.new(0.38, 0.1, 0.38), CFrame.new(0, 0.6, 0), Enum.Material.Metal, BrickColor.new("Dark stone grey"))
		addSubPart("GripRingBot", Vector3.new(0.38, 0.1, 0.38), CFrame.new(0, -0.6, 0), Enum.Material.Metal, BrickColor.new("Dark stone grey"))

		-- Деревянное древко (Shaft)
		addSubPart("Shaft", Vector3.new(0.3, 3.4, 0.3), CFrame.new(0, 1.8, 0), Enum.Material.Wood, BrickColor.new("Reddish brown"))

		-- Нижний упор (Pommel)
		addSubPart("Pommel", Vector3.new(0.36, 0.35, 0.36), CFrame.new(0, -0.85, 0), Enum.Material.Metal, BrickColor.new("Dark stone grey"))

		-- Верхняя обмотка и обойма (NeckWrap & Collar)
		addSubPart("NeckWrap", Vector3.new(0.36, 0.6, 0.36), CFrame.new(0, 2.7, 0), Enum.Material.Fabric, BrickColor.new("Dark orange"))
		addSubPart("Collar", Vector3.new(0.42, 0.25, 0.42), CFrame.new(0, 3.1, 0), Enum.Material.Metal, BrickColor.new("Dark stone grey"))

		-- Широкое и плотное острие (Blade spear-2)
		addSubPart("Blade", Vector3.new(0.85, 1.35, 0.14), CFrame.new(0, 3.75, 0), Enum.Material.Metal, BrickColor.new("Medium stone grey"))
		addSubPart("BladeEdge", Vector3.new(0.7, 0.8, 0.18), CFrame.new(0, 3.75, 0), Enum.Material.Metal, BrickColor.new("White"))

	elseif itemKey == "Slingshot" then
		handle.Size = Vector3.new(0.4, 1.8, 0.4)
		handle.Material = Enum.Material.WoodPlanks
		handle.BrickColor = BrickColor.new("Dark orange")

		-- Рожки рогатки
		addSubPart("ForkLeft", Vector3.new(0.3, 0.9, 0.3), CFrame.new(-0.4, 0.9, 0) * CFrame.Angles(0, 0, math.rad(25)), Enum.Material.WoodPlanks, BrickColor.new("Dark orange"))
		addSubPart("ForkRight", Vector3.new(0.3, 0.9, 0.3), CFrame.new(0.4, 0.9, 0) * CFrame.Angles(0, 0, math.rad(-25)), Enum.Material.WoodPlanks, BrickColor.new("Dark orange"))
		addSubPart("Band", Vector3.new(0.8, 0.08, 0.08), CFrame.new(0, 1.2, 0), Enum.Material.SmoothPlastic, BrickColor.new("Crimson"))

	elseif itemKey == "Revolver" then
		handle.Size = Vector3.new(0.35, 1.0, 0.6)
		handle.Material = Enum.Material.Wood
		handle.BrickColor = BrickColor.new("Reddish brown") -- Деревянная рукоять

		-- Ствол и барабан
		addSubPart("Barrel", Vector3.new(0.3, 0.4, 1.6), CFrame.new(0, 0.4, -0.9), Enum.Material.Metal, BrickColor.new("Dark stone grey"))
		addSubPart("Cylinder", Vector3.new(0.55, 0.55, 0.6), CFrame.new(0, 0.35, -0.2), Enum.Material.Metal, BrickColor.new("Black"))

	elseif itemKey == "RabbitTrap" then
		handle.Size = Vector3.new(1.8, 0.2, 1.8)
		handle.Material = Enum.Material.Metal
		handle.BrickColor = BrickColor.new("Dark stone grey")

		addSubPart("Jaw1", Vector3.new(1.6, 0.35, 0.2), CFrame.new(0, 0.15, 0.7), Enum.Material.Metal, BrickColor.new("Black"))
		addSubPart("Jaw2", Vector3.new(1.6, 0.35, 0.2), CFrame.new(0, 0.15, -0.7), Enum.Material.Metal, BrickColor.new("Black"))
		addSubPart("Diode", Vector3.new(0.3, 0.3, 0.3), CFrame.new(0, 0.2, 0), Enum.Material.Neon, BrickColor.new("Bright green"))

	elseif itemKey == "SpikeTrap" then
		handle.Size = Vector3.new(2.4, 0.2, 2.4)
		handle.Material = Enum.Material.WoodPlanks
		handle.BrickColor = BrickColor.new("Dark orange")

		-- Шипы
		for sx = -1, 1, 2 do
			for sz = -1, 1, 2 do
				addSubPart("Spike_" .. sx .. "_" .. sz, Vector3.new(0.2, 0.8, 0.2), CFrame.new(sx * 0.6, 0.45, sz * 0.6), Enum.Material.Metal, BrickColor.new("Dark stone grey"))
			end
		end
		addSubPart("CenterSpike", Vector3.new(0.25, 0.9, 0.25), CFrame.new(0, 0.5, 0), Enum.Material.Metal, BrickColor.new("Medium stone grey"))

	elseif itemKey == "CampfireKit" then
		handle.Size = Vector3.new(1.6, 0.4, 1.6)
		handle.Material = Enum.Material.Wood
		handle.BrickColor = BrickColor.new("Reddish brown")
		addSubPart("Log2", Vector3.new(1.6, 0.35, 0.4), CFrame.new(0, 0.15, 0) * CFrame.Angles(0, math.rad(90), 0), Enum.Material.Wood, BrickColor.new("Dark orange"))
		addSubPart("Ember", Vector3.new(0.6, 0.2, 0.6), CFrame.new(0, 0.2, 0), Enum.Material.Neon, BrickColor.new("Deep orange"))

	elseif itemKey == "Steak" then
		handle.Size = Vector3.new(1.4, 0.4, 1.1)
		handle.Material = Enum.Material.SmoothPlastic
		handle.BrickColor = BrickColor.new("Dark red")

		addSubPart("Bone", Vector3.new(0.3, 0.35, 0.8), CFrame.new(0.8, 0, 0), Enum.Material.SmoothPlastic, BrickColor.new("White"))
		addSubPart("GrillMarks", Vector3.new(1.0, 0.05, 0.8), CFrame.new(0, 0.21, 0), Enum.Material.SmoothPlastic, BrickColor.new("Black"))

	elseif itemKey == "Bread" then
		handle.Size = Vector3.new(1.3, 0.8, 1.6)
		handle.Material = Enum.Material.SmoothPlastic
		handle.BrickColor = BrickColor.new("Brick yellow")

		addSubPart("Crust", Vector3.new(1.2, 0.2, 1.4), CFrame.new(0, 0.45, 0), Enum.Material.SmoothPlastic, BrickColor.new("Dark orange"))

	elseif itemKey == "Soup" then
		handle.Size = Vector3.new(1.0, 1.2, 1.0)
		handle.Material = Enum.Material.Metal
		handle.BrickColor = BrickColor.new("Bright red")

		addSubPart("Lid", Vector3.new(0.95, 0.05, 0.95), CFrame.new(0, 0.61, 0), Enum.Material.Metal, BrickColor.new("Medium stone grey"))

	elseif itemKey == "Bar" then
		handle.Size = Vector3.new(0.6, 0.3, 1.5)
		handle.Material = Enum.Material.SmoothPlastic
		handle.BrickColor = BrickColor.new("Brown")

		addSubPart("Wrapper", Vector3.new(0.64, 0.32, 1.0), CFrame.new(0, 0, -0.2), Enum.Material.SmoothPlastic, BrickColor.new("Bright yellow"))

	elseif itemKey == "Chips" then
		handle.Size = Vector3.new(0.8, 1.1, 0.4)
		handle.Material = Enum.Material.Fabric
		handle.BrickColor = BrickColor.new("Bright yellow")
		addSubPart("Strip", Vector3.new(0.82, 0.25, 0.42), CFrame.new(0, 0.1, 0), Enum.Material.SmoothPlastic, BrickColor.new("Bright red"))

	elseif itemKey == "Pepper" then
		handle.Size = Vector3.new(0.5, 0.5, 1.3)
		handle.Material = Enum.Material.SmoothPlastic
		handle.BrickColor = BrickColor.new("Really red")
		addSubPart("Stem", Vector3.new(0.2, 0.3, 0.2), CFrame.new(0, 0.2, 0.6) * CFrame.Angles(math.rad(20), 0, 0), Enum.Material.SmoothPlastic, BrickColor.new("Bright green"))

	elseif itemKey == "Coffee" then
		handle.Size = Vector3.new(0.8, 1.5, 0.8)
		handle.Material = Enum.Material.Metal
		handle.BrickColor = BrickColor.new("Dark stone grey")

		addSubPart("Cap", Vector3.new(0.7, 0.3, 0.7), CFrame.new(0, 0.8, 0), Enum.Material.SmoothPlastic, BrickColor.new("Black"))

	elseif itemKey == "Parts" then
		handle.Size = Vector3.new(0.8, 0.8, 0.8)
		handle.Material = Enum.Material.Metal
		handle.BrickColor = BrickColor.new("Cyan")

		addSubPart("Core", Vector3.new(0.5, 0.5, 0.5), CFrame.new(0, 0, 0), Enum.Material.Neon, BrickColor.new("Bright blue"))

	elseif itemKey == "Stone" then
		handle.Size = Vector3.new(1.2, 0.9, 1.1)
		handle.Material = Enum.Material.Slate
		handle.BrickColor = BrickColor.new("Medium stone grey")

		addSubPart("Snow", Vector3.new(0.9, 0.2, 0.8), CFrame.new(0, 0.5, 0), Enum.Material.Snow, BrickColor.new("White"))

	elseif itemKey == "Planks" then
		handle.Size = Vector3.new(0.8, 0.4, 2.2)
		handle.Material = Enum.Material.WoodPlanks
		handle.BrickColor = BrickColor.new("Dark orange")

		addSubPart("P2", Vector3.new(0.8, 0.4, 2.0), CFrame.new(0, 0.4, 0.1), Enum.Material.WoodPlanks, BrickColor.new("Medium orange"))

	elseif itemKey == "Branches" then
		handle.Size = Vector3.new(0.4, 0.4, 2.4)
		handle.Material = Enum.Material.Wood
		handle.BrickColor = BrickColor.new("Reddish brown")
		addSubPart("Twig2", Vector3.new(0.3, 0.3, 2.0), CFrame.new(0, 0.1, 0) * CFrame.Angles(0, math.rad(35), 0), Enum.Material.Wood, BrickColor.new("Dark orange"))

	elseif itemKey == "Fiber" then
		handle.Size = Vector3.new(0.6, 1.2, 0.6)
		handle.Material = Enum.Material.Grass
		handle.BrickColor = BrickColor.new("Sand green")
		addSubPart("Leaf2", Vector3.new(0.5, 1.0, 0.5), CFrame.new(0, 0.1, 0) * CFrame.Angles(0, math.rad(45), 0), Enum.Material.Grass, BrickColor.new("Bright yellow"))

	elseif itemKey == "WolfPelt" or itemKey == "YetiPelt" then
		handle.Size = Vector3.new(1.4, 0.3, 1.4)
		handle.Material = Enum.Material.Fabric
		handle.BrickColor = (itemKey == "WolfPelt") and BrickColor.new("Dark stone grey") or BrickColor.new("White")

	else
		-- Базовая модель по умолчанию
		handle.Size = Vector3.new(1.0, 1.0, 1.0)
		handle.Material = Enum.Material.Wood
		handle.BrickColor = BrickColor.new("Dark orange")
	end

	return handle
end

local EatFoodRemote = RemotesFolder:FindFirstChild("EatFood") or Instance.new("RemoteEvent", RemotesFolder)
EatFoodRemote.Name = "EatFood"

-- Функция поедания еды (только при подтвержденном клике по персонажу)
local function consumeFoodItem(player, targetTool)
	local char = player.Character
	if not char then return end

	local tool = targetTool or char:FindFirstChildOfClass("Tool")
	if not tool then return end

	local itemKey = tool:GetAttribute("ItemKey") or tool.Name
	local cfg = ITEM_CONFIGS[itemKey]
	if not cfg or not cfg.IsFood then return end

	local curCount = tool:GetAttribute("Count") or 1
	local curWarmth = player:GetAttribute("Warmth") or 100
	local curHunger = player:GetAttribute("Hunger") or 100
	local humanoid = char:FindFirstChildOfClass("Humanoid")

	player:SetAttribute("Warmth", math.min(100, curWarmth + (cfg.Warmth or 50)))
	player:SetAttribute("Hunger", math.min(100, curHunger + (cfg.Hunger or 60)))
	if humanoid then
		humanoid.Health = math.min(humanoid.MaxHealth, humanoid.Health + (cfg.Health or 25))
	end

	local curAttr = player:GetAttribute(itemKey) or 0
	if curAttr > 0 then
		player:SetAttribute(itemKey, curAttr - 1)
	end

	print(string.format("🍖 %s съел %s! (+%d тепла, +%d сытости, +%d HP)", player.Name, cfg.Name, cfg.Warmth or 50, cfg.Hunger or 60, cfg.Health or 25))

	if curCount > 1 then
		tool:SetAttribute("Count", curCount - 1)
		tool.Name = string.format("%s (x%d)", cfg.Name, curCount - 1)
	else
		tool:Destroy()
	end
end

_G.ConsumeFoodItem = consumeFoodItem

EatFoodRemote.OnServerEvent:Connect(function(player)
	consumeFoodItem(player)
end)

-- Функция создания нативного объекта Tool
local function createItemTool(itemKey, count)
	local cfg = ITEM_CONFIGS[itemKey]
	if not cfg then return nil end

	local tool = Instance.new("Tool")
	tool.Name = (count > 1) and string.format("%s (x%d)", cfg.Name, count) or cfg.Name
	tool.RequiresHandle = true
	tool.CanBeDropped = false
	tool:SetAttribute("ItemKey", itemKey)
	tool:SetAttribute("Count", count)
	tool:SetAttribute("MaxStack", cfg.MaxStack)
	tool:SetAttribute("IsFood", cfg.IsFood or false)

	if itemKey == "Torch" then
		tool:SetAttribute("TorchFuel", 120)
	end

	local iconData = IconConfig.Icons[itemKey]
	if iconData and iconData.AssetId then
		tool.TextureId = iconData.AssetId
	end

	attachDetailed3DModel(tool, itemKey)

	if itemKey == "Spear" then
		-- Наклон копья вперед в руке под естественным боевым углом 35 градусов
		tool.Grip = CFrame.new(0, 0, 0) * CFrame.Angles(math.rad(-35), 0, 0)
	end

	-- Обработка клика ЛКМ (Еда исключена от случайных нажатий по экрану)
	tool.Activated:Connect(function()
		local char = tool.Parent
		local player = Players:GetPlayerFromCharacter(char)
		if not player then return end

		if cfg.IsFood then
			-- Еда не съедается от любого клика по экрану!
			-- Съедание происходит ТОЛЬКО при клике по персонажу через FoodEatController
			return
		elseif cfg.IsPlaceable then
			if _G.PlaceTrapFromHand then
				_G.PlaceTrapFromHand(player, itemKey, tool)
			end
		elseif cfg.IsWeapon then
			local now = os.clock()
			local lastAttack = tool:GetAttribute("LastAttack") or 0
			local fireRate = cfg.FireRate or 0.8
			if now - lastAttack < fireRate then return end
			tool:SetAttribute("LastAttack", now)

			-- Нативный дефолтный триггер анимации удара Roblox (toolanim = Slash)
			local animVal = Instance.new("StringValue")
			animVal.Name = "toolanim"
			animVal.Value = "Slash"
			animVal.Parent = tool

			if _G.ExecuteWeaponAttack then
				_G.ExecuteWeaponAttack(player, itemKey)
			end
		end
	end)

	-- Подключение бонуса факела в руке
	tool.Equipped:Connect(function()
		local char = tool.Parent
		local player = Players:GetPlayerFromCharacter(char)
		if player and itemKey == "Torch" then
			player:SetAttribute("HasTorchInHand", true)
		end
	end)

	tool.Unequipped:Connect(function()
		local char = tool.Parent and tool.Parent.Parent
		local player = char and Players:GetPlayerFromCharacter(char)
		if player and itemKey == "Torch" then
			player:SetAttribute("HasTorchInHand", false)
		end
	end)

	return tool
end

-- 120-секундный цикл сгорания факела в руке
task.spawn(function()
	while true do
		task.wait(1.0)
		for _, player in ipairs(Players:GetPlayers()) do
			local char = player.Character
			if char then
				local equippedTool = char:FindFirstChildOfClass("Tool")
				if equippedTool and equippedTool:GetAttribute("ItemKey") == "Torch" then
					local fuel = equippedTool:GetAttribute("TorchFuel") or 120
					fuel = math.max(0, fuel - 1)
					equippedTool:SetAttribute("TorchFuel", fuel)

					if fuel <= 0 then
						local count = equippedTool:GetAttribute("Count") or 1
						local torchesTotal = player:GetAttribute("Torch") or 0
						if torchesTotal > 0 then
							player:SetAttribute("Torch", torchesTotal - 1)
						end

						if count > 1 then
							equippedTool:SetAttribute("Count", count - 1)
							equippedTool:SetAttribute("TorchFuel", 120)
							equippedTool.Name = string.format("🔥 Факел (x%d)", count - 1)
						else
							equippedTool:Destroy()
							player:SetAttribute("HasTorchInHand", false)
						end
						print(string.format("🔥 Факел у %s полностью прогорел (120 сек)!", player.Name))
					end
				end
			end
		end
	end
end)

-- Публичная функция выдачи предметов
local function giveItemToPlayer(player, itemKey, amount)
	amount = amount or 1
	local cfg = ITEM_CONFIGS[itemKey]
	if not cfg then
		warn(string.format("⚠️ [GiveItem] Неизвестный предмет: %s", tostring(itemKey)))
		return false
	end

	local backpack = player:FindFirstChildOfClass("Backpack")
	if not backpack then
		warn(string.format("⚠️ [GiveItem] Рюкзак игрока %s не найден!", player.Name))
		return false
	end

	local char = player.Character

	-- 1. Сначала пытаемся добавить в существующие неполные стаки
	local allTools = {}
	for _, t in ipairs(backpack:GetChildren()) do
		if t:IsA("Tool") then table.insert(allTools, t) end
	end
	if char then
		for _, t in ipairs(char:GetChildren()) do
			if t:IsA("Tool") then table.insert(allTools, t) end
		end
	end

	for _, tool in ipairs(allTools) do
		if tool:GetAttribute("ItemKey") == itemKey then
			local curCount = tool:GetAttribute("Count") or 1
			local maxStack = cfg.MaxStack
			if curCount < maxStack then
				local space = maxStack - curCount
				local toAdd = math.min(space, amount)
				local newCount = curCount + toAdd
				tool:SetAttribute("Count", newCount)
				tool.Name = (newCount > 1) and string.format("%s (x%d)", cfg.Name, newCount) or cfg.Name
				player:SetAttribute(itemKey, (player:GetAttribute(itemKey) or 0) + toAdd)
				
				amount = amount - toAdd
				if amount <= 0 then return true end
			end
		end
	end

	-- 2. Если остались предметы -> проверяем лимит слотов (считаем только Tool)
	local maxSlots = player:GetAttribute("MaxSlots") or 5
	local currentToolCount = #allTools
	if currentToolCount >= maxSlots then
		return false
	end

	while amount > 0 and currentToolCount < maxSlots do
		local toAdd = math.min(cfg.MaxStack, amount)
		local newTool = createItemTool(itemKey, toAdd)
		if newTool then
			newTool.Parent = backpack
			currentToolCount = currentToolCount + 1
			player:SetAttribute(itemKey, (player:GetAttribute(itemKey) or 0) + toAdd)
			amount = amount - toAdd
		else
			break
		end
	end

	return amount <= 0
end

GiveItemBindable.OnInvoke = giveItemToPlayer
_G.GiveItemToPlayer = giveItemToPlayer

Players.PlayerAdded:Connect(function(player)
	player.CharacterAdded:Connect(function(char)
		player:SetAttribute("Torch", player:GetAttribute("Torch") or 0)
		player:SetAttribute("HasTorchInHand", false)
		
		task.delay(0.5, function()
			if player.Parent then
				-- Выдаем стартовое Копье и Факел в Backpack игрока при спавне
				giveItemToPlayer(player, "Spear", 1)
				giveItemToPlayer(player, "Torch", 1)
			end
		end)
	end)
end)

