--[[
    HomeSuppliesService.server.luau
    Сервис околодомовых ресурсов и сундуков:
    - 10 Сундуков припасов вдоль веранды и двора дома (сбалансированный лут и ресток 90 сек)
    - 10 Веток (Branches)
    - 10 Волокон (Fiber)
    - 10 Камней (Stone)
    - 10 Досок (Planks)
    - Индивидуальные ProximityPrompt для быстрого и удобного сбора ресурсов около дома
--]]

local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local HomeSuppliesFolder = workspace:FindFirstChild("HomeSupplies") or Instance.new("Folder", workspace)
HomeSuppliesFolder.Name = "HomeSupplies"

local RemotesFolder = ReplicatedStorage:FindFirstChild("Remotes") or Instance.new("Folder", ReplicatedStorage)
RemotesFolder.Name = "Remotes"

local ShowNotificationRemote = RemotesFolder:FindFirstChild("ShowNotification") or Instance.new("RemoteEvent", RemotesFolder)
ShowNotificationRemote.Name = "ShowNotification"

local function getGroundHeight(x, z)
	local rayOrigin = Vector3.new(x, 100, z)
	local rayDirection = Vector3.new(0, -150, 0)
	local raycastParams = RaycastParams.new()
	raycastParams.FilterType = Enum.RaycastFilterType.Include
	raycastParams.FilterDescendantsInstances = { workspace.Terrain }

	local result = workspace:Raycast(rayOrigin, rayDirection, raycastParams)
	if result then
		return result.Position.Y
	end
	return 2.5
end

local function givePlayerItem(player, itemKey, count)
	count = count or 1
	if _G.GiveItemToPlayer then
		return _G.GiveItemToPlayer(player, itemKey, count)
	else
		local giveBindable = ReplicatedStorage:FindFirstChild("GiveItem")
		if giveBindable and giveBindable:IsA("BindableFunction") then
			return giveBindable:Invoke(player, itemKey, count)
		end
	end
	return false
end

--------------------------------------------------------------------------------
-- 1. 🧰 10 СУНДУКОВ ПРИПАСОВ У ДОМА (Вдоль крыльца и веранды)
--------------------------------------------------------------------------------
local CHEST_OFFSETS = {
	-- Слева от крыльца (5 шт)
	Vector3.new(-14, 0, -10),
	Vector3.new(-14, 0, -6),
	Vector3.new(-14, 0, -2),
	Vector3.new(-14, 0, 2),
	Vector3.new(-14, 0, 6),
	-- Справа от крыльца (5 шт)
	Vector3.new(14, 0, -10),
	Vector3.new(14, 0, -6),
	Vector3.new(14, 0, -2),
	Vector3.new(14, 0, 2),
	Vector3.new(14, 0, 6)
}

local CHEST_LOOT_TABLES = {
	{ { Item = "Branches", Min = 3, Max = 5 }, { Item = "Fiber", Min = 2, Max = 4 } },
	{ { Item = "Stone", Min = 2, Max = 4 }, { Item = "Planks", Min = 2, Max = 3 } },
	{ { Item = "Torch", Min = 1, Max = 1 }, { Item = "Bread", Min = 1, Max = 2 } },
	{ { Item = "Parts", Min = 1, Max = 2 }, { Item = "Ammo_Slingshot", Min = 5, Max = 10 } },
	{ { Item = "Bar", Min = 2, Max = 3 }, { Item = "Soup", Min = 1, Max = 2 } },
	{ { Item = "Planks", Min = 3, Max = 5 }, { Item = "Branches", Min = 3, Max = 4 } },
	{ { Item = "Stone", Min = 3, Max = 5 }, { Item = "Fiber", Min = 3, Max = 5 } },
	{ { Item = "Spear", Min = 1, Max = 1 }, { Item = "Steak", Min = 1, Max = 2 } },
	{ { Item = "Parts", Min = 2, Max = 3 }, { Item = "Coffee", Min = 1, Max = 2 } },
	{ { Item = "RabbitTrap", Min = 1, Max = 1 }, { Item = "CampfireKit", Min = 1, Max = 1 } }
}

local function createHomeChest(index, offset)
	local groundY = getGroundHeight(offset.X, offset.Z)
	local chestPos = Vector3.new(offset.X, groundY + 1.2, offset.Z)

	local chestModel = Instance.new("Model")
	chestModel.Name = "HomeChest_" .. index

	local base = Instance.new("Part")
	base.Name = "Base"
	base.Size = Vector3.new(3.4, 2.0, 2.4)
	base.Position = chestPos
	base.Anchored = true
	base.CanCollide = true
	base.Material = Enum.Material.WoodPlanks
	base.BrickColor = BrickColor.new("Dark orange")
	base.Parent = chestModel

	local lid = Instance.new("Part")
	lid.Name = "Lid"
	lid.Size = Vector3.new(3.6, 0.6, 2.6)
	lid.Position = chestPos + Vector3.new(0, 1.25, 0)
	lid.Anchored = true
	lid.CanCollide = true
	lid.Material = Enum.Material.Metal
	lid.BrickColor = BrickColor.new("Dark stone grey")
	lid.Parent = chestModel

	local lock = Instance.new("Part")
	lock.Name = "Lock"
	lock.Size = Vector3.new(0.7, 0.7, 0.3)
	lock.Position = chestPos + Vector3.new(0, 0.25, 1.25)
	lock.Anchored = true
	lock.CanCollide = false
	lock.Material = Enum.Material.Neon
	lock.BrickColor = BrickColor.new("Bright yellow")
	lock.Parent = chestModel

	local light = Instance.new("PointLight", lock)
	light.Color = Color3.fromRGB(250, 204, 21)
	light.Range = 10
	light.Brightness = 1.2

	local prompt = Instance.new("ProximityPrompt", base)
	prompt.ActionText = "Открыть сундук припасов"
	prompt.ObjectText = string.format("🧰 Домашний сундук #%d", index)
	prompt.HoldDuration = 0
	prompt.MaxActivationDistance = 12
	prompt.RequiresLineOfSight = false

	local lootPool = CHEST_LOOT_TABLES[index] or CHEST_LOOT_TABLES[1]

	prompt.Triggered:Connect(function(player)
		local lootedText = {}
		for _, loot in ipairs(lootPool) do
			local qty = math.random(loot.Min, loot.Max)
			local given = givePlayerItem(player, loot.Item, qty)
			if not given and _G.DropItemOnGround then
				_G.DropItemOnGround(player, loot.Item, qty, chestPos + Vector3.new(0, 0.5, 2))
			end
			table.insert(lootedText, string.format("%s (x%d)", loot.Item, qty))
		end

		ShowNotificationRemote:FireClient(player, "📦 Вы открыли сундук и получили припасы!")
		prompt.Enabled = false
		lock.BrickColor = BrickColor.new("Really red")
		light.Color = Color3.fromRGB(239, 68, 68)

		-- Восполнение сундука через 90 секунд
		task.delay(90, function()
			if prompt and prompt.Parent then
				prompt.Enabled = true
				lock.BrickColor = BrickColor.new("Bright yellow")
				light.Color = Color3.fromRGB(250, 204, 21)
			end
		end)
	end)

	chestModel.PrimaryPart = base
	chestModel.Parent = HomeSuppliesFolder
end

for i, offset in ipairs(CHEST_OFFSETS) do
	createHomeChest(i, offset)
end

--------------------------------------------------------------------------------
-- 2. 🌲 10 ВЕТОК, 10 ВОЛОКОН, 10 КАМНЕЙ, 10 ДОСОК У ДОМА
--------------------------------------------------------------------------------

local function createHomeResourceNode(resType, pos, index)
	local groundY = getGroundHeight(pos.X, pos.Z)
	local exactPos = Vector3.new(pos.X, groundY, pos.Z)

	local nodeModel = Instance.new("Model")
	nodeModel.Name = string.format("HomeNode_%s_%d", resType, index)

	local basePart = Instance.new("Part")
	basePart.Name = "HitBox"
	basePart.Size = Vector3.new(2.4, 2.0, 2.4)
	basePart.Position = exactPos + Vector3.new(0, 1.0, 0)
	basePart.Transparency = 1
	basePart.Anchored = true
	basePart.CanCollide = false
	basePart.Parent = nodeModel

	-- Визуальная 3D геометрия ноды
	local visual = Instance.new("Part")
	visual.Name = "Visual"
	visual.Anchored = true
	visual.CanCollide = false
	visual.Parent = nodeModel

	local actionTitle = ""
	local promptName = ""

	if resType == "Branches" then
		visual.Size = Vector3.new(1.8, 0.6, 2.6)
		visual.Position = exactPos + Vector3.new(0, 0.3, 0)
		visual.Material = Enum.Material.Wood
		visual.BrickColor = BrickColor.new("Reddish brown")
		actionTitle = "Взять ветки (x2)"
		promptName = "🌿 Ветки"
	elseif resType == "Fiber" then
		visual.Size = Vector3.new(1.4, 1.8, 1.4)
		visual.Position = exactPos + Vector3.new(0, 0.9, 0)
		visual.Material = Enum.Material.Grass
		visual.BrickColor = BrickColor.new("Bright green")
		actionTitle = "Собрать волокно (x2)"
		promptName = "🌱 Волокно"
	elseif resType == "Stone" then
		visual.Size = Vector3.new(2.2, 1.4, 2.0)
		visual.Position = exactPos + Vector3.new(0, 0.7, 0)
		visual.Material = Enum.Material.Slate
		visual.BrickColor = BrickColor.new("Medium stone grey")
		actionTitle = "Взять камень (x2)"
		promptName = "⚪ Камень"
	elseif resType == "Planks" then
		visual.Size = Vector3.new(1.6, 0.8, 2.8)
		visual.Position = exactPos + Vector3.new(0, 0.4, 0)
		visual.Material = Enum.Material.WoodPlanks
		visual.BrickColor = BrickColor.new("Dark orange")
		actionTitle = "Взять доски (x2)"
		promptName = "🌲 Доски"
	end

	local prompt = Instance.new("ProximityPrompt", basePart)
	prompt.ActionText = actionTitle
	prompt.ObjectText = promptName
	prompt.HoldDuration = 0
	prompt.MaxActivationDistance = 12
	prompt.RequiresLineOfSight = false

	prompt.Triggered:Connect(function(player)
		local given = givePlayerItem(player, resType, 2)
		if not given and _G.DropItemOnGround then
			_G.DropItemOnGround(player, resType, 2, exactPos + Vector3.new(0, 0.5, 0))
		end

		prompt.Enabled = false
		visual.Transparency = 1

		-- Быстрый респавн 45 секунд
		task.delay(45, function()
			if visual and visual.Parent then
				visual.Transparency = 0
				prompt.Enabled = true
			end
		end)
	end)

	nodeModel.PrimaryPart = basePart
	nodeModel.Parent = HomeSuppliesFolder
end

-- 10 ВЕТОК (Передний левый двор: X = -22..-8, Z = -24..-12)
for i = 1, 10 do
	local angle = (i / 10) * math.pi
	local x = -16 + math.cos(angle) * 7
	local z = -18 + math.sin(angle) * 6
	createHomeResourceNode("Branches", Vector3.new(x, 0, z), i)
end

-- 10 ВОЛОКОН (Передний правый двор: X = 8..22, Z = -24..-12)
for i = 1, 10 do
	local angle = (i / 10) * math.pi
	local x = 16 + math.cos(angle) * 7
	local z = -18 + math.sin(angle) * 6
	createHomeResourceNode("Fiber", Vector3.new(x, 0, z), i)
end

-- 10 КАМНЕЙ (Задний левый двор: X = -22..-8, Z = 12..24)
for i = 1, 10 do
	local angle = (i / 10) * math.pi
	local x = -16 + math.cos(angle) * 7
	local z = 18 + math.sin(angle) * 6
	createHomeResourceNode("Stone", Vector3.new(x, 0, z), i)
end

-- 10 ДОСОК (Задний правый двор: X = 8..22, Z = 12..24)
for i = 1, 10 do
	local angle = (i / 10) * math.pi
	local x = 16 + math.cos(angle) * 7
	local z = 18 + math.sin(angle) * 6
	createHomeResourceNode("Planks", Vector3.new(x, 0, z), i)
end

print("🏡 [HomeSuppliesService] 10 сундуков и 40 ресурсов (10 веток, 10 волокон, 10 камней, 10 досок) установлены вокруг дома!")
