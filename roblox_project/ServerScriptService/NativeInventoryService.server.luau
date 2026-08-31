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

local GiveItemBindable = Instance.new("BindableFunction")
GiveItemBindable.Name = "GiveItem"
GiveItemBindable.Parent = ReplicatedStorage

local ITEM_CONFIGS = {
	Torch = { Name = "🔥 Факел", MaxStack = 4, HasFire = true },
	Branches = { Name = "🌿 Ветки", MaxStack = 5 },
	Fiber = { Name = "🌱 Волокно", MaxStack = 5 },
	Stone = { Name = "⚪ Камень", MaxStack = 5 },
	Planks = { Name = "🌲 Доски", MaxStack = 3 },
	Parts = { Name = "⚙️ Детали", MaxStack = 4 },
	WolfPelt = { Name = "🐺 Шкура Волка", MaxStack = 5 },
	YetiPelt = { Name = "❄️ Шкура Йети", MaxStack = 5 },
	
	-- Еда
	Bar = { Name = "🍫 Батончик", MaxStack = 3, IsFood = true, Warmth = 10, Hunger = 30, Health = 15 },
	Bread = { Name = "🍞 Хлеб", MaxStack = 3, IsFood = true, Warmth = 15, Hunger = 50, Health = 25 },
	Chips = { Name = "🥔 Чипсы", MaxStack = 3, IsFood = true, Warmth = 8, Hunger = 25, Health = 15 },
	Soup = { Name = "🥫 Суп", MaxStack = 3, IsFood = true, Warmth = 30, Hunger = 70, Health = 35 },
	Pepper = { Name = "🌶️ Перец", MaxStack = 3, IsFood = true, Warmth = 50, Hunger = 15, Health = 5 },
	Coffee = { Name = "☕ Кофе", MaxStack = 3, IsFood = true, Warmth = 40, Hunger = 20, Health = 20 },
	Steak = { Name = "🥩 Стейк", MaxStack = 2, IsFood = true, Warmth = 35, Hunger = 90, Health = 60 },

	-- Ловушки и постройки
	RabbitTrap = { Name = "🪤 Капкан", MaxStack = 3, IsPlaceable = true },
	CampfireKit = { Name = "🔥 Походный костер", MaxStack = 2, IsPlaceable = true },
	
	-- Оружие
	Spear = { Name = "🗡️ Копье", MaxStack = 1, IsWeapon = true, Damage = 30 },
	Slingshot = { Name = "🏹 Рогатка", MaxStack = 1, IsWeapon = true, Damage = 22 },
	Revolver = { Name = "🔫 Револьвер", MaxStack = 1, IsWeapon = true, Damage = 55 }
}

-- Функция сборки детализированной 3D-модели для Handle инструмента
local function attachDetailed3DModel(tool, itemKey)
	local handle = Instance.new("Part")
	handle.Name = "Handle"
	handle.CanCollide = false
	handle.Massless = true
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
		handle.Size = Vector3.new(0.3, 5.2, 0.3)
		handle.Material = Enum.Material.Wood
		handle.BrickColor = BrickColor.new("Reddish brown")

		-- Наконечник копья из кремния/стали
		addSubPart("Blade", Vector3.new(0.5, 1.4, 0.1), CFrame.new(0, 2.7, 0), Enum.Material.Slate, BrickColor.new("Medium stone grey"))
		addSubPart("Rope", Vector3.new(0.42, 0.4, 0.42), CFrame.new(0, 1.9, 0), Enum.Material.Fabric, BrickColor.new("Dark orange"))

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

		addSubPart("Wrapper", Vector3.new(0.64, 0.32, 1.0), CFrame.new(0, 0, -0.2), Enum.Material.Metal, BrickColor.new("Bright yellow"))

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

	else
		-- Базовая модель по умолчанию
		handle.Size = Vector3.new(1.0, 1.0, 1.0)
		handle.Material = Enum.Material.Wood
		handle.BrickColor = BrickColor.new("Dark orange")
	end

	return handle
end

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

	if itemKey == "Torch" then
		tool:SetAttribute("TorchFuel", 120)
	end

	attachDetailed3DModel(tool, itemKey)

	-- Обработка клика ЛКМ
	tool.Activated:Connect(function()
		local char = tool.Parent
		local player = Players:GetPlayerFromCharacter(char)
		if not player then return end

		if cfg.IsFood then
			local curCount = tool:GetAttribute("Count") or 1
			local curWarmth = player:GetAttribute("Warmth") or 100
			local curHunger = player:GetAttribute("Hunger") or 100
			local humanoid = char:FindFirstChildOfClass("Humanoid")

			player:SetAttribute("Warmth", math.min(100, curWarmth + (cfg.Warmth or 10)))
			player:SetAttribute("Hunger", math.min(100, curHunger + (cfg.Hunger or 25)))
			if humanoid then
				humanoid.Health = math.min(humanoid.MaxHealth, humanoid.Health + (cfg.Health or 15))
			end

			local curAttr = player:GetAttribute(itemKey) or 0
			if curAttr > 0 then
				player:SetAttribute(itemKey, curAttr - 1)
			end

			print(string.format("🍖 %s съел %s! (+%d тепла, +%d сытости)", player.Name, cfg.Name, cfg.Warmth or 10, cfg.Hunger or 25))

			if curCount > 1 then
				tool:SetAttribute("Count", curCount - 1)
				tool.Name = string.format("%s (x%d)", cfg.Name, curCount - 1)
			else
				tool:Destroy()
			end
		elseif cfg.IsPlaceable then
			if _G.PlaceTrapFromHand then
				_G.PlaceTrapFromHand(player, itemKey, tool)
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
	if not cfg then return false end

	local backpack = player:FindFirstChildOfClass("Backpack")
	if not backpack then return false end

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

	-- 2. Если остались предметы -> проверяем лимит слотов
	local maxSlots = player:GetAttribute("MaxSlots") or 5
	local currentToolCount = #backpack:GetChildren() + (char and (char:FindFirstChildOfClass("Tool") and 1 or 0) or 0)
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
	end)
end)
