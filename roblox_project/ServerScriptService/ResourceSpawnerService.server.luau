--[[
    ResourceSpawnerService.server.luau
    Серверная система спавна и 3D-моделей природных ресурсов:
    - 🌿 Ветки: 3 перекрещенные деревянные веточки с сосновой хвоей
    - ⚪ Камни: Валун из 3 сланцевых камней с шапкой свежего снега
    - 🌱 Волокно: Пышный кустик зимнего сухостоя из 4 стеблей
    - 🌲 Доски: Аккуратно сложенная стопка пиломатериалов с железными скобами
    - 🚫 4 такта добычи, защита от спама, CanCollide = false
--]]

local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ResourcesFolder = workspace:FindFirstChild("WorldResources") or Instance.new("Folder", workspace)
ResourcesFolder.Name = "WorldResources"

local RemotesFolder = ReplicatedStorage:FindFirstChild("Remotes") or Instance.new("Folder", ReplicatedStorage)
RemotesFolder.Name = "Remotes"

local HarvestResourceRemote = RemotesFolder:FindFirstChild("HarvestResource") or Instance.new("RemoteEvent", RemotesFolder)
HarvestResourceRemote.Name = "HarvestResource"

local function isInsideHouseZone(pos)
	-- Строгий запрет спавна в черте дома и прилегающего двора
	return (math.abs(pos.X) <= 38 and math.abs(pos.Z) <= 30) or ((pos.X^2 + pos.Z^2) <= 38^2)
end

local function getGroundHeight(pos)
	local rayOrigin = Vector3.new(pos.X, 120, pos.Z)
	local rayDirection = Vector3.new(0, -200, 0)
	local raycastParams = RaycastParams.new()
	raycastParams.FilterType = Enum.RaycastFilterType.Include
	raycastParams.FilterDescendantsInstances = { workspace.Terrain }

	local result = workspace:Raycast(rayOrigin, rayDirection, raycastParams)
	if result then
		return result.Position.Y
	end
	-- Точная базовая высота снежного покрова Smooth Terrain
	return 0
end

-- 1. Создание красивой 3D-модели ВЕТОК (🌿 Скрещенные ветви сосны)
local function buildBranchesModel(pos)
	local model = Instance.new("Model")
	model.Name = "Resource_Branches"

	local hitBox = Instance.new("Part")
	hitBox.Name = "HitBox"
	hitBox.Size = Vector3.new(3.6, 1.4, 3.6)
	hitBox.Position = pos + Vector3.new(0, 0.7, 0)
	hitBox.Transparency = 1
	hitBox.Anchored = true
	hitBox.CanCollide = false
	hitBox.Parent = model

	local stick1 = Instance.new("Part")
	stick1.Name = "Stick1"
	stick1.Size = Vector3.new(0.4, 0.4, 3.8)
	stick1.CFrame = CFrame.new(pos + Vector3.new(0, 0.25, 0)) * CFrame.Angles(0, math.rad(25), math.rad(4))
	stick1.Anchored = true
	stick1.CanCollide = false
	stick1.Material = Enum.Material.Wood
	stick1.BrickColor = BrickColor.new("Reddish brown")
	stick1.Parent = model

	local stick2 = Instance.new("Part")
	stick2.Name = "Stick2"
	stick2.Size = Vector3.new(0.35, 0.35, 3.4)
	stick2.CFrame = CFrame.new(pos + Vector3.new(0, 0.35, 0)) * CFrame.Angles(0, math.rad(-50), math.rad(-3))
	stick2.Anchored = true
	stick2.CanCollide = false
	stick2.Material = Enum.Material.Wood
	stick2.BrickColor = BrickColor.new("Dark orange")
	stick2.Parent = model

	local stick3 = Instance.new("Part")
	stick3.Name = "Stick3"
	stick3.Size = Vector3.new(0.3, 0.3, 2.6)
	stick3.CFrame = CFrame.new(pos + Vector3.new(0.4, 0.4, -0.2)) * CFrame.Angles(0, math.rad(80), math.rad(8))
	stick3.Anchored = true
	stick3.CanCollide = false
	stick3.Material = Enum.Material.Wood
	stick3.BrickColor = BrickColor.new("Brown")
	stick3.Parent = model

	local needles = Instance.new("Part")
	needles.Name = "Needles"
	needles.Size = Vector3.new(0.8, 0.3, 0.8)
	needles.CFrame = CFrame.new(pos + Vector3.new(1.2, 0.3, 1.2)) * CFrame.Angles(0, math.rad(45), 0)
	needles.Anchored = true
	needles.CanCollide = false
	needles.Material = Enum.Material.Grass
	needles.BrickColor = BrickColor.new("Dark green")
	needles.Parent = model

	model.PrimaryPart = hitBox
	return model
end

-- 2. Создание красивой 3D-модели КАМНЯ (⚪ Сланцевый валун с шапкой снега)
local function buildStoneModel(pos)
	local model = Instance.new("Model")
	model.Name = "Resource_Stone"

	local hitBox = Instance.new("Part")
	hitBox.Name = "HitBox"
	hitBox.Size = Vector3.new(3.8, 2.2, 3.8)
	hitBox.Position = pos + Vector3.new(0, 1.1, 0)
	hitBox.Transparency = 1
	hitBox.Anchored = true
	hitBox.CanCollide = false
	hitBox.Parent = model

	local mainRock = Instance.new("Part")
	mainRock.Name = "MainRock"
	mainRock.Size = Vector3.new(3.2, 1.8, 2.8)
	mainRock.CFrame = CFrame.new(pos + Vector3.new(0, 0.8, 0)) * CFrame.Angles(math.rad(6), math.rad(30), math.rad(-4))
	mainRock.Anchored = true
	mainRock.CanCollide = false
	mainRock.Material = Enum.Material.Slate
	mainRock.BrickColor = BrickColor.new("Medium stone grey")
	mainRock.Parent = model

	local snowCap = Instance.new("Part")
	snowCap.Name = "SnowCap"
	snowCap.Size = Vector3.new(2.8, 0.4, 2.4)
	snowCap.CFrame = CFrame.new(pos + Vector3.new(0, 1.75, 0)) * CFrame.Angles(0, math.rad(30), 0)
	snowCap.Anchored = true
	snowCap.CanCollide = false
	snowCap.Material = Enum.Material.Snow
	snowCap.BrickColor = BrickColor.new("White")
	snowCap.Parent = model

	local sideRock = Instance.new("Part")
	sideRock.Name = "SideRock"
	sideRock.Size = Vector3.new(1.4, 0.9, 1.3)
	sideRock.CFrame = CFrame.new(pos + Vector3.new(1.6, 0.4, -0.4)) * CFrame.Angles(math.rad(-10), math.rad(70), math.rad(15))
	sideRock.Anchored = true
	sideRock.CanCollide = false
	sideRock.Material = Enum.Material.Slate
	sideRock.BrickColor = BrickColor.new("Dark stone grey")
	sideRock.Parent = model

	model.PrimaryPart = hitBox
	return model
end

-- 3. Создание красивой 3D-модели ВОЛОКНА (🌱 Пучок сухостоя и камыша)
local function buildFiberModel(pos)
	local model = Instance.new("Model")
	model.Name = "Resource_Fiber"

	local hitBox = Instance.new("Part")
	hitBox.Name = "HitBox"
	hitBox.Size = Vector3.new(3.2, 2.4, 3.2)
	hitBox.Position = pos + Vector3.new(0, 1.2, 0)
	hitBox.Transparency = 1
	hitBox.Anchored = true
	hitBox.CanCollide = false
	hitBox.Parent = model

	local stem1 = Instance.new("Part")
	stem1.Name = "Stem1"
	stem1.Size = Vector3.new(0.3, 2.2, 0.3)
	stem1.CFrame = CFrame.new(pos + Vector3.new(-0.3, 1.0, 0.2)) * CFrame.Angles(math.rad(12), 0, math.rad(-15))
	stem1.Anchored = true
	stem1.CanCollide = false
	stem1.Material = Enum.Material.Grass
	stem1.BrickColor = BrickColor.new("Bright green")
	stem1.Parent = model

	local stem2 = Instance.new("Part")
	stem2.Name = "Stem2"
	stem2.Size = Vector3.new(0.35, 2.5, 0.35)
	stem2.CFrame = CFrame.new(pos + Vector3.new(0.2, 1.15, -0.2)) * CFrame.Angles(math.rad(-8), math.rad(45), math.rad(12))
	stem2.Anchored = true
	stem2.CanCollide = false
	stem2.Material = Enum.Material.Grass
	stem2.BrickColor = BrickColor.new("Lime green")
	stem2.Parent = model

	local stem3 = Instance.new("Part")
	stem3.Name = "Stem3"
	stem3.Size = Vector3.new(0.25, 1.9, 0.25)
	stem3.CFrame = CFrame.new(pos + Vector3.new(0.3, 0.9, 0.3)) * CFrame.Angles(math.rad(16), math.rad(90), math.rad(8))
	stem3.Anchored = true
	stem3.CanCollide = false
	stem3.Material = Enum.Material.Grass
	stem3.BrickColor = BrickColor.new("Pastel green")
	stem3.Parent = model

	local baseTuft = Instance.new("Part")
	baseTuft.Name = "BaseTuft"
	baseTuft.Size = Vector3.new(1.2, 0.5, 1.2)
	baseTuft.CFrame = CFrame.new(pos + Vector3.new(0, 0.25, 0))
	baseTuft.Anchored = true
	baseTuft.CanCollide = false
	baseTuft.Material = Enum.Material.Grass
	baseTuft.BrickColor = BrickColor.new("Dark green")
	baseTuft.Parent = model

	model.PrimaryPart = hitBox
	return model
end

-- 4. Создание красивой 3D-модели ДОСОК (🌲 Стопка пиломатериалов)
local function buildPlanksModel(pos)
	local model = Instance.new("Model")
	model.Name = "Resource_Planks"

	local hitBox = Instance.new("Part")
	hitBox.Name = "HitBox"
	hitBox.Size = Vector3.new(3.6, 1.6, 3.6)
	hitBox.Position = pos + Vector3.new(0, 0.8, 0)
	hitBox.Transparency = 1
	hitBox.Anchored = true
	hitBox.CanCollide = false
	hitBox.Parent = model

	local p1 = Instance.new("Part")
	p1.Name = "Plank1"
	p1.Size = Vector3.new(1.1, 0.4, 3.6)
	p1.CFrame = CFrame.new(pos + Vector3.new(-0.6, 0.2, 0)) * CFrame.Angles(0, math.rad(15), 0)
	p1.Anchored = true
	p1.CanCollide = false
	p1.Material = Enum.Material.WoodPlanks
	p1.BrickColor = BrickColor.new("Dark orange")
	p1.Parent = model

	local p2 = Instance.new("Part")
	p2.Name = "Plank2"
	p2.Size = Vector3.new(1.1, 0.4, 3.6)
	p2.CFrame = CFrame.new(pos + Vector3.new(0.6, 0.2, 0)) * CFrame.Angles(0, math.rad(15), 0)
	p2.Anchored = true
	p2.CanCollide = false
	p2.Material = Enum.Material.WoodPlanks
	p2.BrickColor = BrickColor.new("Dark orange")
	p2.Parent = model

	local p3 = Instance.new("Part")
	p3.Name = "Plank3"
	p3.Size = Vector3.new(1.1, 0.4, 3.4)
	p3.CFrame = CFrame.new(pos + Vector3.new(0, 0.6, 0)) * CFrame.Angles(0, math.rad(105), 0)
	p3.Anchored = true
	p3.CanCollide = false
	p3.Material = Enum.Material.WoodPlanks
	p3.BrickColor = BrickColor.new("Medium orange")
	p3.Parent = model

	local bracket = Instance.new("Part")
	bracket.Name = "Bracket"
	bracket.Size = Vector3.new(1.3, 0.05, 0.3)
	bracket.CFrame = CFrame.new(pos + Vector3.new(0, 0.82, 0)) * CFrame.Angles(0, math.rad(105), 0)
	bracket.Anchored = true
	bracket.CanCollide = false
	bracket.Material = Enum.Material.Metal
	bracket.BrickColor = BrickColor.new("Dark stone grey")
	bracket.Parent = model

	model.PrimaryPart = hitBox
	return model
end

local function spawnResourceNode(resType, rawPos)
	if isInsideHouseZone(rawPos) then return end

	local groundY = getGroundHeight(rawPos)
	-- Приподнимаем точку спавна на +0.65 studs над снежной коркой, чтобы модели никогда не тонули в вокселях
	local pos = Vector3.new(rawPos.X, groundY + 2, rawPos.Z)

	local model = nil
	if resType == "Branches" then model = buildBranchesModel(pos)
	elseif resType == "Stone" then model = buildStoneModel(pos)
	elseif resType == "Fiber" then model = buildFiberModel(pos)
	elseif resType == "Planks" then model = buildPlanksModel(pos)
	end

	if not model then return end

	local hitBox = model.PrimaryPart
	hitBox:SetAttribute("ResourceType", resType)
	hitBox:SetAttribute("HitsLeft", 4)
	hitBox:SetAttribute("MaxHits", 4)
	hitBox:SetAttribute("IsHarvestable", true)
	hitBox:SetAttribute("SpawnPos", pos)

	model:SetAttribute("ResourceType", resType)
	model:SetAttribute("HitsLeft", 4)
	model:SetAttribute("MaxHits", 4)
	model:SetAttribute("IsHarvestable", true)

	model.Parent = ResourcesFolder
end
-- РАВНОМЕРНОЕ ПРОСТРАНСТВЕННОЕ РАСПРЕДЕЛЕНИЕ РЕСУРСОВ ПО ВСЕЙ КАРТЕ
local function spawnWorldResources()
	ResourcesFolder:ClearAllChildren()

	local GRID_STEP = 52 -- Шаг сетки спавна в мире 3200x3200 -- Шаг сетки (studs)
	local MAP_MIN_X, MAP_MAX_X = -1450, 1450
	local MAP_MIN_Z, MAP_MAX_Z = -1450, 1450

	local totalSpawned = 0

	for x = MAP_MIN_X, MAP_MAX_X, GRID_STEP do
		for z = MAP_MIN_Z, MAP_MAX_Z, GRID_STEP do
			-- Добавляем естественное случайное смещение (Jitter) внутри сектора сетки
			local jX = x + math.random(-14, 14)
			local jZ = z + math.random(-14, 14)
			local pos = Vector3.new(jX, 0, jZ)

			if not isInsideHouseZone(pos) then
				local distFromHouse = math.sqrt(pos.X^2 + pos.Z^2)

				-- Вероятность спавна ноды в ячейке (~50% заполненность сетки для сбалансированной плотности)
				if math.random() <= 0.52 then
					local chosenType = nil

					if distFromHouse < 80 then
						-- Околодомовая зона (40..80 studs): Ветки, Волокно, Доски (КАМНЕЙ НЕТ ВБЛИЗИ ДОМА!)
						local nearTypes = { "Branches", "Branches", "Fiber", "Fiber", "Planks" }
						chosenType = nearTypes[math.random(1, #nearTypes)]
					else
						-- Удаленная зона (80..420 studs): Все ресурсы, включая Камни в каменистых предгорьях
						local farTypes = { "Branches", "Fiber", "Planks", "Stone", "Stone" }
						chosenType = farTypes[math.random(1, #farTypes)]
					end

					if chosenType then
						spawnResourceNode(chosenType, pos)
						totalSpawned = totalSpawned + 1
					end
				end
			end
		end
	end

	print(string.format("🌲 [Респавн] Равномерно распределено %d 3D-ресурсов по всей карте (камни спавнятся от 80 studs)!", totalSpawned))
end

spawnWorldResources()

task.spawn(function()
	while true do
		task.wait(600)
		spawnWorldResources()
	end
end)

-- Обработка клика ЛКМ по ресурсу (4 удара)
HarvestResourceRemote.OnServerEvent:Connect(function(player, target)
	if not target or not target.Parent then return end

	local model = target:IsA("Model") and target or target:FindFirstAncestorOfClass("Model") or target
	local hitBox = (model:IsA("Model") and (model.PrimaryPart or model:FindFirstChildWhichIsA("BasePart"))) or target

	if model:GetAttribute("IsHarvestable") ~= true then return end

	local char = player.Character
	if not char or not char:FindFirstChild("HumanoidRootPart") then return end

	local nodePos = (hitBox and hitBox:IsA("BasePart")) and hitBox.Position or char.HumanoidRootPart.Position
	local dist = (char.HumanoidRootPart.Position - nodePos).Magnitude
	if dist > 26 then return end

	local resourceType = model:GetAttribute("ResourceType") or (hitBox and hitBox:GetAttribute("ResourceType"))
	if not resourceType then return end

	local hitsLeft = model:GetAttribute("HitsLeft") or 4
	hitsLeft = hitsLeft - 1
	model:SetAttribute("HitsLeft", hitsLeft)

	if hitsLeft <= 0 then
		model:SetAttribute("IsHarvestable", false)

		-- Скрываем все видимые детали 3D-модели
		if model:IsA("Model") then
			for _, part in ipairs(model:GetDescendants()) do
				if part:IsA("BasePart") then
					part.Transparency = 1
				end
			end
		elseif model:IsA("BasePart") then
			model.Transparency = 1
		end

		-- Выдача случайного количества ресурсов от 1 до 3 шт.
		local gain = math.random(1, 3)

		local lumberRank = player:GetAttribute("Perk_Lumberjack") or 0
		if lumberRank == 1 and math.random() < 0.25 then gain = gain + 1
		elseif lumberRank == 2 and math.random() < 0.35 then gain = gain + 1
		elseif lumberRank >= 3 and math.random() < 0.50 then gain = gain + 1 end

		-- Командный бонус с Алтаря (+20% шанс на дополнительный ресурс)
		local dropBonus = workspace:GetAttribute("ResourceDropBonus") or 0
		if dropBonus > 0 and math.random() < dropBonus then
			gain = gain + 1
		end

		local given = false
		if _G.GiveItemToPlayer then
			given = _G.GiveItemToPlayer(player, resourceType, gain)
		end

		if not given then
			if _G.DropItemOnGround then
				_G.DropItemOnGround(player, resourceType, gain)
			end
		end

		print(string.format("⛏️ %s добыл %s (x%d)! Нода истощена.", player.Name, resourceType, gain))

		-- Респавн через 10 минут
		task.delay(600, function()
			if model and model.Parent then
				if model:IsA("Model") then
					for _, part in ipairs(model:GetDescendants()) do
						if part:IsA("BasePart") and part.Name ~= "HitBox" then
							part.Transparency = 0
						end
					end
				elseif model:IsA("BasePart") then
					model.Transparency = 0
				end
				model:SetAttribute("HitsLeft", 4)
				model:SetAttribute("IsHarvestable", true)
			end
		end)
	end
end)
