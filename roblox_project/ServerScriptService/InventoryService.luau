--!strict
--[[
    ServerScriptService/InventoryService.luau
    Централизованный модуль инвентаря и предметов:
    - Единая точка выдачи предметов (giveItem) и сброса на землю (dropItem)
    - Поедание еды (consumeFood)
    - Устраняет зависимость от ненадёжной глобальной таблицы _G
--]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Network = require(ReplicatedStorage:WaitForChild("Network"))
local ModelHelper = require(ReplicatedStorage:WaitForChild("ModelHelper", 10))
local IconConfig = require(ReplicatedStorage:WaitForChild("IconConfig", 10))
local SurfaceUtil = require(ReplicatedStorage:WaitForChild("SurfaceUtil"))

local InventoryService = {}

export type ItemConfig = {
	Name: string,
	MaxStack: number,
	HasFire: boolean?,
	IsFood: boolean?,
	Warmth: number?,
	Hunger: number?,
	Health: number?,
	IsPlaceable: boolean?,
	IsWeapon: boolean?,
	WeaponType: string?,
	AmmoType: string?,
	Damage: number?,
	FireRate: number?
}

InventoryService.ItemConfigs = {
	Torch = { Name = "🔥 Факел", MaxStack = 4, HasFire = true },
	Branches = { Name = "🌿 Ветки", MaxStack = 5 },
	Fiber = { Name = "🌱 Волокно", MaxStack = 5 },
	Stone = { Name = "⚪ Камень", MaxStack = 5 },
	Planks = { Name = "🌲 Доски", MaxStack = 3 },
	Parts = { Name = "⚙️ Детали", MaxStack = 4 },
	WolfPelt = { Name = "🐺 Шкура Волка", MaxStack = 5 },
	YetiPelt = { Name = "❄️ Шкура Йети", MaxStack = 5 },

	-- Еда
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

-- Создание объекта Tool для инвентаря
function InventoryService.createItemTool(itemKey: string, count: number): Tool?
	local cfg = InventoryService.ItemConfigs[itemKey]
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

	-- Сборка 3D-модели
	local handle = ModelHelper.assembleTool(itemKey, tool)
	if not handle then
		handle = Instance.new("Part")
		handle.Name = "Handle"
		handle.Size = Vector3.new(1, 1, 1)
		handle.CanCollide = false
		handle.Massless = true
		handle.Parent = tool
	end

	local gripCF = ModelHelper.ITEM_GRIPS and ModelHelper.ITEM_GRIPS[itemKey]
	if gripCF then
		tool.Grip = gripCF
	end

	tool.Equipped:Connect(function()
		local char = tool.Parent
		local player = char and Players:GetPlayerFromCharacter(char)
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

-- Публичная функция выдачи предметов
function InventoryService.giveItem(player: Player, itemKey: string, amount: number?): boolean
	local count = amount or 1
	local cfg = InventoryService.ItemConfigs[itemKey]
	if not cfg then
		warn(string.format("⚠️ [InventoryService] Неизвестный предмет: %s", tostring(itemKey)))
		return false
	end

	local backpack = player:FindFirstChildOfClass("Backpack")
	if not backpack then return false end

	local char = player.Character

	-- 1. Поиск неполных стаков
	local allTools: { Tool } = {}
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
				local toAdd = math.min(space, count)
				local newCount = curCount + toAdd
				tool:SetAttribute("Count", newCount)
				tool.Name = (newCount > 1) and string.format("%s (x%d)", cfg.Name, newCount) or cfg.Name
				player:SetAttribute(itemKey, (player:GetAttribute(itemKey) or 0) + toAdd)

				count = count - toAdd
				if count <= 0 then return true end
			end
		end
	end

	-- 2. Создание новых слотов
	local maxSlots = player:GetAttribute("MaxSlots") or 5
	local currentToolCount = #allTools
	if currentToolCount >= maxSlots then
		return false
	end

	while count > 0 and currentToolCount < maxSlots do
		local toAdd = math.min(cfg.MaxStack, count)
		local newTool = InventoryService.createItemTool(itemKey, toAdd)
		if newTool then
			newTool.Parent = backpack
			currentToolCount = currentToolCount + 1
			player:SetAttribute(itemKey, (player:GetAttribute(itemKey) or 0) + toAdd)
			count = count - toAdd
		else
			break
		end
	end

	return count <= 0
end

-- Поедание еды
function InventoryService.consumeFood(player: Player, targetTool: Tool?): boolean
	local char = player.Character
	if not char then return false end

	local tool = targetTool or char:FindFirstChildOfClass("Tool")
	if not tool then return false end

	local itemKey = tool:GetAttribute("ItemKey") or tool.Name
	local cfg = InventoryService.ItemConfigs[itemKey]
	if not cfg or not cfg.IsFood then return false end

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

	if curCount > 1 then
		tool:SetAttribute("Count", curCount - 1)
		tool.Name = string.format("%s (x%d)", cfg.Name, curCount - 1)
	else
		tool:Destroy()
	end

	return true
end

-- Сброс предмета на землю (DropItem)
function InventoryService.dropItem(player: Player, itemKey: string, count: number?, customPos: Vector3?): Model?
	local amount = count or 1
	local cfg = InventoryService.ItemConfigs[itemKey]
	if not cfg then return nil end

	local char = player and player.Character
	local spawnPos = customPos
	if not spawnPos and char and char:FindFirstChild("HumanoidRootPart") then
		local hrp = char.HumanoidRootPart
		spawnPos = hrp.Position + hrp.CFrame.LookVector * 3.5 + Vector3.new(0, 0.4, 0)
	end
	if not spawnPos then
		spawnPos = Vector3.new(0, 1.2, 0)
	end

	local droppedFolder = workspace:FindFirstChild("DroppedItems") or Instance.new("Folder", workspace)
	droppedFolder.Name = "DroppedItems"

	local dropModel = ModelHelper.assembleDropModel(itemKey, spawnPos)
	if not dropModel then
		local p = Instance.new("Part")
		p.Name = "Dropped_" .. itemKey
		p.Size = Vector3.new(1.2, 1.2, 1.2)
		p.Anchored = true
		p.CanCollide = true
		p.Parent = droppedFolder
		dropModel = p :: any
		SurfaceUtil.placeOnSurface(dropModel, spawnPos, 0.15)
	else
		dropModel.Parent = droppedFolder
		SurfaceUtil.placeOnSurface(dropModel, spawnPos, 0.05)
	end

	-- Гарантируем закрепление всех частей модели на земле
	for _, p in ipairs(dropModel:GetDescendants()) do
		if p:IsA("BasePart") then
			p.Anchored = true
			if p.Name == "Center" then
				p.Transparency = 1
				p.CanCollide = false
			else
				p.CanCollide = false
			end
			p.AssemblyLinearVelocity = Vector3.zero
		end
	end
	if dropModel:IsA("BasePart") then
		dropModel.Anchored = true
		dropModel.CanCollide = true
		dropModel.AssemblyLinearVelocity = Vector3.zero
	elseif dropModel:IsA("Model") and dropModel.PrimaryPart then
		dropModel.PrimaryPart.CanCollide = true
	end

	dropModel:SetAttribute("ItemKey", itemKey)
	dropModel:SetAttribute("Count", amount)

	-- ProximityPrompt для подбора
	local promptPart = if dropModel:IsA("Model") then (dropModel.PrimaryPart or dropModel:FindFirstChildWhichIsA("BasePart")) else dropModel
	if promptPart then
		local prompt = Instance.new("ProximityPrompt", promptPart)
		prompt.ActionText = string.format("Подобрать %s (x%d)", cfg.Name, amount)
		prompt.ObjectText = cfg.Name
		prompt.HoldDuration = 0
		prompt.MaxActivationDistance = 10
		prompt.RequiresLineOfSight = false

		prompt.Triggered:Connect(function(triggerPlayer)
			local given = InventoryService.giveItem(triggerPlayer, itemKey, amount)
			if given then
				dropModel:Destroy()
			else
				local notif = Network.getEvent("ShowNotification")
				notif:FireClient(triggerPlayer, "⚠️ Ваш рюкзак полон! Освободите место.")
			end
		end)
	end

	return dropModel :: any
end

-- Обратная совместимость для устаревших вызовов через _G
_G.GiveItemToPlayer = function(player, itemKey, amount)
	return InventoryService.giveItem(player, itemKey, amount)
end
_G.DropItemOnGround = function(player, itemKey, amount, pos)
	return InventoryService.dropItem(player, itemKey, amount, pos)
end
_G.ConsumeFoodItem = function(player, tool)
	return InventoryService.consumeFood(player, tool)
end

return InventoryService
