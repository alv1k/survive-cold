--[[
    ItemDropService.server.luau
    Серверная система 3D сброса предметов в мир:
    - Стилизованные многосоставные 3D-модели
    - Физика броска вперед
    - Мгновенный подбор на E (HoldDuration = 0)
--]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local DroppedFolder = workspace:FindFirstChild("DroppedItems") or Instance.new("Folder", workspace)
DroppedFolder.Name = "DroppedItems"

local RemotesFolder = ReplicatedStorage:FindFirstChild("Remotes") or Instance.new("Folder", ReplicatedStorage)
RemotesFolder.Name = "Remotes"

local DropItemRemote = RemotesFolder:FindFirstChild("DropItem") or Instance.new("RemoteEvent", RemotesFolder)
DropItemRemote.Name = "DropItem"

local ShowNotificationRemote = RemotesFolder:FindFirstChild("ShowNotification") or Instance.new("RemoteEvent", RemotesFolder)
ShowNotificationRemote.Name = "ShowNotification"

local PLAYER_HOUSE = {
	Position = Vector3.new(0, 5, 0),
	Size = Vector3.new(45, 10, 30)
}

local function isInsideHouse(pos)
	local minB = PLAYER_HOUSE.Position - (PLAYER_HOUSE.Size / 2)
	local maxB = PLAYER_HOUSE.Position + (PLAYER_HOUSE.Size / 2)
	return pos.X >= minB.X and pos.X <= maxB.X and pos.Z >= minB.Z and pos.Z <= maxB.Z
end

local ITEM_NAMES = {
	Branches = "🌿 Ветки",
	Fiber = "🌱 Волокно",
	Stone = "⚪ Камень",
	Planks = "🌲 Доски",
	Parts = "⚙️ Детали",
	Torch = "🔥 Факел",
	WolfPelt = "🐺 Шкура Волка",
	YetiPelt = "❄️ Шкура Йети",
	Bar = "🍫 Батончик",
	Bread = "🍞 Хлеб",
	Chips = "🥔 Чипсы",
	Soup = "🥫 Суп",
	Pepper = "🌶️ Перец",
	Coffee = "☕ Кофе",
	Steak = "🥩 Стейк",
	CampfireKit = "🔥 Походный костер",
	RabbitTrap = "🪤 Капкан",
	SpikeTrap = "📌 Шипы",
	Spear = "🗡️ Копье",
	Slingshot = "🏹 Рогатка",
	Revolver = "🔫 Револьвер"
}

local ModelHelper = require(ReplicatedStorage:WaitForChild("ModelHelper", 10))

local function build3DDropObject(itemName, pos)
	local dropModel = ModelHelper.assembleDropModel(itemName, pos)
	if dropModel then
		return dropModel
	end

	local root = Instance.new("Part")
	root.Name = "Dropped_" .. itemName
	root.Position = pos
	root.Anchored = false
	root.CanCollide = true
	root.Massless = false

	local function addSubPart(name, size, cfOffset, material, color)
		local sub = Instance.new("Part")
		sub.Name = name
		sub.Size = size
		sub.CFrame = root.CFrame * cfOffset
		sub.Material = material
		sub.BrickColor = color
		sub.CanCollide = false
		sub.Massless = true
		sub.Parent = root

		local weld = Instance.new("WeldConstraint")
		weld.Part0 = root
		weld.Part1 = sub
		weld.Parent = sub
		return sub
	end

	if itemName == "Spear" then
		root.Size = Vector3.new(0.3, 0.3, 4.8)
		root.Material = Enum.Material.Wood
		root.BrickColor = BrickColor.new("Reddish brown")
		addSubPart("Blade", Vector3.new(0.5, 0.1, 1.2), CFrame.new(0, 0, 2.5), Enum.Material.Slate, BrickColor.new("Medium stone grey"))

	elseif itemName == "Slingshot" then
		root.Size = Vector3.new(0.4, 1.6, 0.4)
		root.Material = Enum.Material.WoodPlanks
		root.BrickColor = BrickColor.new("Dark orange")
		addSubPart("ForkL", Vector3.new(0.25, 0.8, 0.25), CFrame.new(-0.35, 0.8, 0) * CFrame.Angles(0, 0, math.rad(25)), Enum.Material.WoodPlanks, BrickColor.new("Dark orange"))
		addSubPart("ForkR", Vector3.new(0.25, 0.8, 0.25), CFrame.new(0.35, 0.8, 0) * CFrame.Angles(0, 0, math.rad(-25)), Enum.Material.WoodPlanks, BrickColor.new("Dark orange"))

	elseif itemName == "Revolver" then
		root.Size = Vector3.new(0.35, 0.9, 0.5)
		root.Material = Enum.Material.Wood
		root.BrickColor = BrickColor.new("Reddish brown")
		addSubPart("Barrel", Vector3.new(0.3, 0.35, 1.4), CFrame.new(0, 0.35, -0.8), Enum.Material.Metal, BrickColor.new("Dark stone grey"))

	elseif itemName == "Steak" then
		root.Size = Vector3.new(1.3, 0.35, 1.0)
		root.Material = Enum.Material.SmoothPlastic
		root.BrickColor = BrickColor.new("Dark red")
		addSubPart("Bone", Vector3.new(0.3, 0.3, 0.7), CFrame.new(0.7, 0, 0), Enum.Material.SmoothPlastic, BrickColor.new("White"))

	elseif itemName == "Bread" then
		root.Size = Vector3.new(1.2, 0.7, 1.5)
		root.Material = Enum.Material.SmoothPlastic
		root.BrickColor = BrickColor.new("Brick yellow")
		addSubPart("Crust", Vector3.new(1.1, 0.15, 1.3), CFrame.new(0, 0.4, 0), Enum.Material.SmoothPlastic, BrickColor.new("Dark orange"))

	elseif itemName == "Soup" then
		root.Size = Vector3.new(0.9, 1.1, 0.9)
		root.Material = Enum.Material.Metal
		root.BrickColor = BrickColor.new("Bright red")
		addSubPart("Lid", Vector3.new(0.85, 0.05, 0.85), CFrame.new(0, 0.56, 0), Enum.Material.Metal, BrickColor.new("Medium stone grey"))

	elseif itemName == "Stone" then
		root.Size = Vector3.new(3.2, 2.2, 2.8)
		root.Material = Enum.Material.Slate
		root.BrickColor = BrickColor.new("Medium stone grey")
		addSubPart("Snow", Vector3.new(2.7, 0.55, 2.3), CFrame.new(0, 1.1, 0), Enum.Material.Snow, BrickColor.new("White"))

	elseif itemName == "Planks" then
		root.Size = Vector3.new(3.4, 0.55, 1.0)
		root.Material = Enum.Material.WoodPlanks
		root.BrickColor = BrickColor.new("Dark orange")
		addSubPart("P2", Vector3.new(1.0, 0.55, 3.4), CFrame.new(0, 0.55, 0), Enum.Material.WoodPlanks, BrickColor.new("Medium orange"))

	elseif itemName == "Branches" then
		root.Size = Vector3.new(0.65, 0.65, 3.4)
		root.Material = Enum.Material.Wood
		root.BrickColor = BrickColor.new("Reddish brown")
		addSubPart("B2", Vector3.new(0.58, 0.58, 3.0), CFrame.new(0, 0.3, 0) * CFrame.Angles(0, math.rad(40), 0), Enum.Material.Wood, BrickColor.new("Dark orange"))

	elseif itemName == "Fiber" then
		root.Size = Vector3.new(1.8, 2.8, 1.8)
		root.Material = Enum.Material.Grass
		root.BrickColor = BrickColor.new("Bright green")

	elseif itemName == "Parts" then
		root.Size = Vector3.new(1.6, 0.45, 1.6)
		root.Material = Enum.Material.Metal
		root.BrickColor = BrickColor.new("Dark stone grey")
		addSubPart("Core", Vector3.new(0.7, 0.7, 0.7), CFrame.new(0, 0.3, 0), Enum.Material.Neon, BrickColor.new("Cyan"))

	elseif itemName == "RabbitTrap" then
		root.Size = Vector3.new(1.8, 0.2, 1.8)
		root.Material = Enum.Material.Metal
		root.BrickColor = BrickColor.new("Dark stone grey")
		addSubPart("Jaw1", Vector3.new(1.5, 0.3, 0.2), CFrame.new(0, 0.15, 0.6), Enum.Material.Metal, BrickColor.new("Black"))
		addSubPart("Jaw2", Vector3.new(1.5, 0.3, 0.2), CFrame.new(0, 0.15, -0.6), Enum.Material.Metal, BrickColor.new("Black"))

	elseif itemName == "SpikeTrap" then
		root.Size = Vector3.new(2.4, 0.2, 2.4)
		root.Material = Enum.Material.WoodPlanks
		root.BrickColor = BrickColor.new("Dark orange")
		for sx = -1, 1, 2 do
			for sz = -1, 1, 2 do
				addSubPart("Spike_" .. sx .. "_" .. sz, Vector3.new(0.2, 0.8, 0.2), CFrame.new(sx * 0.6, 0.45, sz * 0.6), Enum.Material.Metal, BrickColor.new("Dark stone grey"))
			end
		end
		addSubPart("CenterSpike", Vector3.new(0.25, 0.9, 0.25), CFrame.new(0, 0.5, 0), Enum.Material.Metal, BrickColor.new("Medium stone grey"))

	elseif itemName == "CampfireKit" then
		root.Size = Vector3.new(1.6, 0.4, 1.6)
		root.Material = Enum.Material.Wood
		root.BrickColor = BrickColor.new("Reddish brown")
		addSubPart("Log2", Vector3.new(1.6, 0.35, 0.4), CFrame.new(0, 0.15, 0) * CFrame.Angles(0, math.rad(90), 0), Enum.Material.Wood, BrickColor.new("Dark orange"))

	else
		root.Size = Vector3.new(1.2, 0.8, 1.2)
		root.Material = Enum.Material.Wood
		root.BrickColor = BrickColor.new("Dark orange")
	end

	return root
end

local function getGroundHeight(x, z)
	local rayOrigin = Vector3.new(x, 60, z)
	local rayDirection = Vector3.new(0, -120, 0)
	local raycastParams = RaycastParams.new()
	raycastParams.FilterType = Enum.RaycastFilterType.Include
	local structFolder = workspace:FindFirstChild("WorldStructures")
	if structFolder then
		raycastParams.FilterDescendantsInstances = { workspace.Terrain, structFolder }
	else
		raycastParams.FilterDescendantsInstances = { workspace.Terrain }
	end

	local result = workspace:Raycast(rayOrigin, rayDirection, raycastParams)
	if result then
		return result.Position.Y
	end
	return 0
end

local function spawnSingleDrop(player, itemName, spawnPos, isImpulse)
	local displayName = ITEM_NAMES[itemName] or itemName
	local inHouse = isInsideHouse(spawnPos)

	local groundY = getGroundHeight(spawnPos.X, spawnPos.Z)
	local lower = string.lower(itemName)
	local isElongated = (lower == "spear" or lower == "torch" or string.find(lower, "spear") or string.find(lower, "torch"))
	local restingHeight = isElongated and 0.16 or 0.35
	local safeRestingY = math.max(0.4, groundY + restingHeight)

	-- Для дропа из сундука спавним прямо на поверхности земли в зафиксированном виде
	local initialPos = isImpulse and Vector3.new(spawnPos.X, math.max(1.6, spawnPos.Y), spawnPos.Z) or Vector3.new(spawnPos.X, safeRestingY, spawnPos.Z)

	local dropObj = build3DDropObject(itemName, initialPos)
	if not dropObj then return end

	dropObj:SetAttribute("ItemName", itemName)
	dropObj:SetAttribute("Count", 1)
	dropObj:SetAttribute("InsideHouse", inHouse)

	local rootPart = (dropObj:IsA("BasePart") and dropObj) or dropObj.PrimaryPart or dropObj:FindFirstChildWhichIsA("BasePart", true)
	if not rootPart then
		dropObj:Destroy()
		return
	end

	local randYaw = CFrame.Angles(0, math.rad(math.random(0, 360)), 0)
	local flatTilt = isElongated and (randYaw * CFrame.Angles(math.rad(90), 0, 0)) or randYaw

	if isImpulse and player and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
		local hrp = player.Character.HumanoidRootPart
		rootPart.AssemblyLinearVelocity = hrp.CFrame.LookVector * (10 + math.random(1, 4)) + Vector3.new(math.random(-2, 2), 4, math.random(-2, 2))
		dropObj.Parent = DroppedFolder

		-- Мягкое приземление брошенного игроком предмета и фиксация плашмя над уровнем снега
		task.spawn(function()
			local elapsed = 0
			while elapsed < 0.6 and dropObj and dropObj.Parent and rootPart and not rootPart.Anchored do
				task.wait(0.05)
				elapsed = elapsed + 0.05
				local curGroundY = getGroundHeight(rootPart.Position.X, rootPart.Position.Z)
				if rootPart.Position.Y <= curGroundY + 0.4 then
					break
				end
			end
			if dropObj and dropObj.Parent and rootPart then
				local finalGroundY = getGroundHeight(rootPart.Position.X, rootPart.Position.Z)
				local finalY = math.max(0.4, finalGroundY + restingHeight)
				local landCF = CFrame.new(rootPart.Position.X, finalY, rootPart.Position.Z) * flatTilt

				if dropObj:IsA("Model") then
					dropObj:PivotTo(landCF)
				else
					dropObj.CFrame = landCF
				end
				for _, p in ipairs(dropObj:GetDescendants()) do
					if p:IsA("BasePart") then
						p.Anchored = true
						p.AssemblyLinearVelocity = Vector3.zero
					end
				end
				if dropObj:IsA("BasePart") then
					dropObj.Anchored = true
					dropObj.AssemblyLinearVelocity = Vector3.zero
				end
			end
		end)
	else
		-- Предмет из сундука: мгновенно фиксируем плашмя на снегу
		local landCF = CFrame.new(spawnPos.X, safeRestingY, spawnPos.Z) * flatTilt
		if dropObj:IsA("Model") then
			dropObj:PivotTo(landCF)
		else
			dropObj.CFrame = landCF
		end
		for _, p in ipairs(dropObj:GetDescendants()) do
			if p:IsA("BasePart") then
				p.Anchored = true
				p.CanCollide = false
				p.Transparency = 0
				p.AssemblyLinearVelocity = Vector3.zero
			end
		end
		if dropObj:IsA("BasePart") then
			dropObj.Anchored = true
			dropObj.CanCollide = false
			dropObj.Transparency = 0
			dropObj.AssemblyLinearVelocity = Vector3.zero
		end
		rootPart.CanCollide = true
		dropObj.Parent = DroppedFolder
	end

	-- Интерактивный ProximityPrompt для подбора ровно 1 штуки
	local prompt = Instance.new("ProximityPrompt", rootPart)
	prompt.ActionText = string.format("Подобрать %s (x1)", displayName)
	prompt.ObjectText = inHouse and "🏡 Склад на полу [СОХРАНЕНО]" or "📦 Предмет на земле"
	prompt.HoldDuration = 0
	prompt.MaxActivationDistance = 10
	prompt.RequiresLineOfSight = false

	local pickingUp = false

	prompt.Triggered:Connect(function(triggeringPlayer)
		if pickingUp then return end
		pickingUp = true
		prompt.Enabled = false

		local itName = dropObj:GetAttribute("ItemName") or itemName

		local given = false
		if _G.GiveItemToPlayer then
			given = _G.GiveItemToPlayer(triggeringPlayer, itName, 1)
		else
			local giveBindable = ReplicatedStorage:FindFirstChild("GiveItem")
			if giveBindable and giveBindable:IsA("BindableFunction") then
				given = giveBindable:Invoke(triggeringPlayer, itName, 1)
			end
		end

		if given then
			dropObj:Destroy()
			print(string.format("🎒 %s подобрал %s (x1) с земли!", triggeringPlayer.Name, displayName))
		else
			prompt.Enabled = true
			pickingUp = false
			ShowNotificationRemote:FireClient(triggeringPlayer, "⚠️ Рюкзак полон! Освободите место.")
		end
	end)
end

local function dropItemOnGround(player, itemName, count, customPos)
	count = count or 1
	local char = player and player.Character
	local hrp = char and char:FindFirstChild("HumanoidRootPart")
	if not hrp and not customPos then return end

	local basePos = customPos or (hrp.Position + hrp.CFrame.LookVector * 3.5 + Vector3.new(0, 1.0, 0))

	-- Создаем ровно `count` отдельных физических объектов по 1 штуке
	for i = 1, count do
		local offset = Vector3.new(0, 0, 0)
		if count > 1 or customPos then
			local angle = (i / count) * (math.pi * 2) + (math.random(-15, 15) / 100)
			local radius = 0.5 + (i * 0.4)
			offset = Vector3.new(math.cos(angle) * radius, 0.15 * (i - 1), math.sin(angle) * radius)
		end
		local spawnPos = basePos + offset
		spawnSingleDrop(player, itemName, spawnPos, not customPos)
	end
end

_G.DropItemOnGround = dropItemOnGround

-- Обработка сброса предмета игроком (клавиша G) со списанием из инвентаря
DropItemRemote.OnServerEvent:Connect(function(player, itemName, count)
	count = count or 1
	local char = player and player.Character
	local backpack = player and player:FindFirstChildOfClass("Backpack")
	if not char then return end

	-- Ищем предмет сначала в руках персонажа (Character), затем в рюкзаке (Backpack)
	local targetTool = nil
	local equippedTool = char:FindFirstChildOfClass("Tool")
	if equippedTool and (equippedTool:GetAttribute("ItemKey") == itemName or equippedTool.Name:find(itemName)) then
		targetTool = equippedTool
	elseif backpack then
		for _, t in ipairs(backpack:GetChildren()) do
			if t:IsA("Tool") and (t:GetAttribute("ItemKey") == itemName or t.Name:find(itemName)) then
				targetTool = t
				break
			end
		end
	end

	if not targetTool then
		print(string.format("⚠️ %s попытался выбросить %s, но предмета нет в руках/рюкзаке!", player.Name, tostring(itemName)))
		return
	end

	local actualKey = targetTool:GetAttribute("ItemKey") or itemName
	if actualKey == "Torch" then return end

	local curCount = targetTool:GetAttribute("Count") or 1
	local dropAmount = math.min(curCount, count)

	if curCount > dropAmount then
		targetTool:SetAttribute("Count", curCount - dropAmount)
		local baseName = targetTool.Name:match("^[^%(]+") or targetTool.Name
		baseName = baseName:gsub("%s+$", "")
		targetTool.Name = string.format("%s (x%d)", baseName, curCount - dropAmount)
	else
		targetTool:Destroy()
	end

	-- Синхронизируем числовой атрибут игрока, если это ресурс
	local curAttr = player:GetAttribute(actualKey)
	if curAttr and type(curAttr) == "number" then
		player:SetAttribute(actualKey, math.max(0, curAttr - dropAmount))
	end

	-- Создаем 3D-объект на земле
	dropItemOnGround(player, actualKey, dropAmount)
	print(string.format("📦 %s выбросил %s (x%d) на землю! Осталось в стаке: %d", player.Name, actualKey, dropAmount, math.max(0, curCount - dropAmount)))
end)
