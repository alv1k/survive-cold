--[[
    ResourceSpawnerService.server.luau
    Серверная система спавна и 3D-моделей природных ресурсов:
    - 🌿 Ветки: Крупные скрещенные ветви с хвоей
    - ⚪ Камни: Большой граненый валун со снежной шапкой
    - 🌱 Волокно: Высокий пучок золотого сухостоя с узлом
    - 🌲 Доски: Крупный штабель дубовых и сосновых брусков
    - 🚫 4 такта добычи, защита от спама, CanCollide = false, приподнятая посадка над снегом
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

local ModelHelper = require(ReplicatedStorage:WaitForChild("ModelHelper", 10))

local function isInsideHouseZone(pos)
	-- Строгий запрет спавна в черте дома и прилегающего двора
	return (math.abs(pos.X) <= 38 and math.abs(pos.Z) <= 30) or ((pos.X^2 + pos.Z^2) <= 38^2)
end

local function getGroundHeight(pos)
	local rayOrigin = Vector3.new(pos.X, 150, pos.Z)
	local rayDirection = Vector3.new(0, -300, 0)
	local raycastParams = RaycastParams.new()
	raycastParams.FilterType = Enum.RaycastFilterType.Include
	raycastParams.FilterDescendantsInstances = { workspace.Terrain }

	local result = workspace:Raycast(rayOrigin, rayDirection, raycastParams)
	if result then
		return result.Position.Y
	end
	return 0
end

local function spawnResourceNode(resType, rawPos)
	if isInsideHouseZone(rawPos) then return end

	local groundY = getGroundHeight(rawPos)
	local exactPos = Vector3.new(rawPos.X, math.max(0.6, groundY + 0.4), rawPos.Z)
	local randYaw = math.rad(math.random(0, 360))
	local targetCF = CFrame.new(exactPos + Vector3.new(0, 0.35, 0)) * CFrame.Angles(0, randYaw, 0)

	local model = nil
	local genMod = ReplicatedStorage:FindFirstChild("GeneratedModels")
	if genMod and genMod:FindFirstChild(resType) then
		local success, mod = pcall(require, genMod[resType])
		if success and mod and type(mod.create) == "function" then
			model = mod.create(ResourcesFolder, targetCF)
		end
	end

	if not model then
		model = Instance.new("Model", ResourcesFolder)
		model:PivotTo(targetCF)
	end

	-- 2. Включаем видимость и атрибуты на всех деталях модели
	for _, part in ipairs(model:GetDescendants()) do
		if part:IsA("BasePart") then
			part.Anchored = true
			part.CanCollide = false
			part.Transparency = 0
			part:SetAttribute("ResourceType", resType)
			part:SetAttribute("IsHarvestable", true)
		end
	end

	-- 3. Хитбокс для клика мышью со всех сторон
	local hitBox = Instance.new("Part")
	hitBox.Name = "HitBox"
	hitBox.Size = Vector3.new(3.6, 2.4, 3.6)
	hitBox.CFrame = CFrame.new(exactPos + Vector3.new(0, 0.8, 0))
	hitBox.Transparency = 1
	hitBox.Anchored = true
	hitBox.CanCollide = false
	hitBox.Parent = model

	hitBox:SetAttribute("ResourceType", resType)
	hitBox:SetAttribute("HitsLeft", 4)
	hitBox:SetAttribute("MaxHits", 4)
	hitBox:SetAttribute("IsHarvestable", true)
	hitBox:SetAttribute("SpawnPos", exactPos)

	model:SetAttribute("ResourceType", resType)
	model:SetAttribute("HitsLeft", 4)
	model:SetAttribute("MaxHits", 4)
	model:SetAttribute("IsHarvestable", true)

	model.Parent = ResourcesFolder
end

-- РАВНОМЕРНОЕ ПРОСТРАНСТВЕННОЕ РАСПРЕДЕЛЕНИЕ РЕСУРСОВ ПО ВСЕЙ КАРТЕ
local function spawnWorldResources()
	ResourcesFolder:ClearAllChildren()

	local GRID_STEP = 52 -- Шаг сетки спавна в мире 3200x3200
	local MAP_MIN_X, MAP_MAX_X = -1450, 1450
	local MAP_MIN_Z, MAP_MAX_Z = -1450, 1450

	local totalSpawned = 0

	for x = MAP_MIN_X, MAP_MAX_X, GRID_STEP do
		for z = MAP_MIN_Z, MAP_MAX_Z, GRID_STEP do
			local jX = x + math.random(-14, 14)
			local jZ = z + math.random(-14, 14)
			local pos = Vector3.new(jX, 0, jZ)

			if not isInsideHouseZone(pos) then
				local distFromHouse = math.sqrt(pos.X^2 + pos.Z^2)

				-- Вероятность спавна ноды в ячейке (~52% заполненность сетки)
				if math.random() <= 0.52 then
					local chosenType = nil

					if distFromHouse < 80 then
						local nearTypes = { "Branches", "Branches", "Fiber", "Fiber", "Planks" }
						chosenType = nearTypes[math.random(1, #nearTypes)]
					else
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

	print(string.format("🌲 [Респавн] Равномерно распределено %d 3D-ресурсов по всей карте!", totalSpawned))
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
		else
			local giveBindable = ReplicatedStorage:FindFirstChild("GiveItem")
			if giveBindable and giveBindable:IsA("BindableFunction") then
				given = giveBindable:Invoke(player, resourceType, gain)
			end
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
