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

local Network = require(ReplicatedStorage:WaitForChild("Network"))
local SurfaceUtil = require(ReplicatedStorage:WaitForChild("SurfaceUtil"))

local DropItemRemote = Network.getEvent("DropItem")
local ShowNotificationRemote = Network.getEvent("ShowNotification")

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
	local surfPos, _, _ = SurfaceUtil.getSurfacePosition(pos)
	root.Position = surfPos + Vector3.new(0, 0.4, 0)
	root.Anchored = true
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
		sub.Anchored = true
		sub.Parent = root

		local weld = Instance.new("WeldConstraint")
		weld.Part0 = root
		weld.Part1 = sub
		weld.Parent = sub
		return sub
	end

	if itemName == "Spear" then
		root.Size = Vector3.new(0.32, 1.10, 0.38)
		root.Material = Enum.Material.Fabric
		root.Color = Color3.fromHex("#713F12")
		addSubPart("LowerShaft", Vector3.new(0.24, 0.35, 0.28), CFrame.new(0, -0.68, 0), Enum.Material.Wood, Color3.fromHex("#C68B59"))
		addSubPart("PommelCap", Vector3.new(0.24, 0.18, 0.28), CFrame.new(0, -1.00, 0), Enum.Material.Wood, Color3.fromHex("#C68B59"))
		addSubPart("MidShaft", Vector3.new(0.24, 0.80, 0.28), CFrame.new(0, 0.95, 0), Enum.Material.Wood, Color3.fromHex("#C68B59"))
		addSubPart("UpperGrip", Vector3.new(0.30, 0.60, 0.35), CFrame.new(0, 1.65, 0), Enum.Material.Fabric, Color3.fromHex("#713F12"))
		addSubPart("UpperShaft", Vector3.new(0.24, 1.50, 0.28), CFrame.new(0, 2.70, 0), Enum.Material.Wood, Color3.fromHex("#C68B59"))
		addSubPart("SinewBinding", Vector3.new(0.30, 0.40, 0.36), CFrame.new(0, 3.58, 0), Enum.Material.Fabric, Color3.fromHex("#FEF08A"))
		addSubPart("FlintBlade", Vector3.new(0.82, 1.57, 0.22), CFrame.new(0, 4.40, 0), Enum.Material.Slate, Color3.fromHex("#64748B"))

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
		root.Size = Vector3.new(0.75, 0.55, 0.65)
		root.Material = Enum.Material.Slate
		root.BrickColor = BrickColor.new("Medium stone grey")
		local mesh = Instance.new("SpecialMesh")
		mesh.MeshType = Enum.MeshType.Sphere
		mesh.Parent = root

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
		root.Size = Vector3.new(0.6, 0.6, 2.2)
		root.Material = Enum.Material.Grass
		root.BrickColor = BrickColor.new("Sand yellow")

	elseif itemName == "Parts" then
		root.Size = Vector3.new(1.6, 0.45, 1.6)
		root.Material = Enum.Material.Metal
		root.BrickColor = BrickColor.new("Dark stone grey")
		addSubPart("Core", Vector3.new(0.7, 0.7, 0.7), CFrame.new(0, 0.3, 0), Enum.Material.SmoothPlastic, BrickColor.new("Cyan"))

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
	return SurfaceUtil.getGroundHeight(x, z, 5)
end

local function spawnSingleDrop(player, itemName, spawnPos, isImpulse)
	local displayName = ITEM_NAMES[itemName] or itemName
	local inHouse = isInsideHouse(spawnPos)

	local lower = string.lower(itemName)
	local isElongated = (lower == "spear" or lower == "torch" or string.find(lower, "spear") or string.find(lower, "torch"))
	local restingHeight = isElongated and 0.22 or 0.42

	-- Находим точную точку посадки на верхней границе поверхности
	local surfacePos, _, _ = SurfaceUtil.getSurfacePosition(spawnPos)
	local safeRestingPos = surfacePos + Vector3.new(0, restingHeight, 0)

	local dropObj = build3DDropObject(itemName, spawnPos)
	if not dropObj then return end

	dropObj:SetAttribute("ItemName", itemName)
	dropObj:SetAttribute("Count", 1)
	dropObj:SetAttribute("InsideHouse", inHouse)

	local rootPart = (dropObj:IsA("BasePart") and dropObj) or dropObj.PrimaryPart or dropObj:FindFirstChildWhichIsA("BasePart", true)
	if not rootPart then
		dropObj:Destroy()
		return
	end

	-- Точный CFrame посадки на снег
	local landCF = dropObj:IsA("Model") and dropObj:GetPivot() or dropObj.CFrame
	local landPos = landCF.Position

	-- Гарантируем закрепление всех частей модели
	for _, p in ipairs(dropObj:GetDescendants()) do
		if p:IsA("BasePart") then
			p.Anchored = true
			p.CanCollide = false
			p.Transparency = 0
			p.AssemblyLinearVelocity = Vector3.zero
			p.AssemblyAngularVelocity = Vector3.zero
		end
	end
	if dropObj:IsA("BasePart") then
		dropObj.Anchored = true
		dropObj.CanCollide = true
		dropObj.Transparency = 0
		dropObj.AssemblyLinearVelocity = Vector3.zero
		dropObj.AssemblyAngularVelocity = Vector3.zero
	end
	rootPart.CanCollide = true

	if isImpulse and player and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
		local hrp = player.Character.HumanoidRootPart
		local startPos = hrp.Position + hrp.CFrame.LookVector * 1.5 + Vector3.new(0, 0.4, 0)
		local startCF = CFrame.new(startPos) * landCF.Rotation

		if dropObj:IsA("Model") then
			dropObj:PivotTo(startCF)
		else
			dropObj.CFrame = startCF
		end

		dropObj.Parent = DroppedFolder

		-- Плавная дуговая CFrame-анимация броска в зафиксированном состоянии (без провала под землю)
		task.spawn(function()
			local steps = 8
			for s = 1, steps do
				task.wait(0.03)
				if not dropObj or not dropObj.Parent then break end
				local t = s / steps
				local currentPos = startPos:Lerp(landPos, t) + Vector3.new(0, math.sin(t * math.pi) * 1.0, 0)
				local currentCF = CFrame.new(currentPos) * landCF.Rotation
				if dropObj:IsA("Model") then
					dropObj:PivotTo(currentCF)
				else
					dropObj.CFrame = currentCF
				end
			end
			if dropObj and dropObj.Parent then
				SurfaceUtil.placeOnSurface(dropObj, spawnPos, 0.05)
			end
		end)
	else
		-- Мгновенная фиксация на поверхности (из сундуков/контейнеров)
		SurfaceUtil.placeOnSurface(dropObj, spawnPos, 0.05)
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
