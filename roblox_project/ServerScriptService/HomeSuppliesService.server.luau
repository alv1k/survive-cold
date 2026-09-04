--[[
    HomeSuppliesService.server.luau
    Сервис околодомовых природных ресурсов:
    - 10 Крупных 3D-моделей Веток (Branches)
    - 10 Крупных 3D-моделей Волокон (Fiber)
    - 10 Крупных 3D-моделей Камней (Stone)
    - 10 Крупных 3D-моделей Досок (Planks)
    - 10 Крупных 3D-моделей Деталей (Parts)
    - Приподнятая посадка над снегом (Y-offset), мягкая подсветка и ProximityPrompt
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

local ModelHelper = require(ReplicatedStorage:WaitForChild("ModelHelper", 10))

local function getGroundHeight(x, z)
	local rayOrigin = Vector3.new(x, 100, z)
	local rayDirection = Vector3.new(0, -200, 0)
	local raycastParams = RaycastParams.new()
	raycastParams.FilterType = Enum.RaycastFilterType.Include
	raycastParams.FilterDescendantsInstances = { workspace.Terrain }

	local result = workspace:Raycast(rayOrigin, rayDirection, raycastParams)
	if result then
		return result.Position.Y
	end
	return 0
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
-- 🌲 ОКОЛОДОМОВЫЕ ПРИРОДНЫЕ РЕСУРСЫ (Ветки, Волокно, Камни, Доски, Детали)
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- 2. 🌲 10 ВЕТОК, 10 ВОЛОКОН, 10 КАМНЕЙ, 10 ДОСОК У ДОМА (С КРУПНЫМИ 3D-МОДЕЛЯМИ)
--------------------------------------------------------------------------------

local function createHomeResourceNode(resType, pos, index)
	local groundY = getGroundHeight(pos.X, pos.Z)
	local exactPos = Vector3.new(pos.X, math.max(0.6, groundY + 0.4), pos.Z)
	local nodeCF = CFrame.new(exactPos + Vector3.new(0, 0.35, 0)) * CFrame.Angles(0, math.rad((index * 37) % 360), 0)

	local nodeModel = nil
	local genMod = ReplicatedStorage:FindFirstChild("GeneratedModels")
	if genMod and genMod:FindFirstChild(resType) then
		local success, mod = pcall(require, genMod[resType])
		if success and mod and type(mod.create) == "function" then
			nodeModel = mod.create(HomeSuppliesFolder, nodeCF)
		end
	end

	if not nodeModel then
		nodeModel = Instance.new("Model", HomeSuppliesFolder)
	end

	nodeModel.Name = string.format("HomeNode_%s_%d", resType, index)

	-- 1. Позиционируем 3D-модель на поверхности снега (приподнято над сугробами)
	nodeModel:PivotTo(CFrame.new(exactPos + Vector3.new(0, 0.35, 0)) * CFrame.Angles(0, math.rad((index * 37) % 360), 0))

	-- 2. Включаем видимость и закрепляем все физические детали
	for _, part in ipairs(nodeModel:GetDescendants()) do
		if part:IsA("BasePart") then
			part.Anchored = true
			part.CanCollide = false
			part.Transparency = 0
		end
	end

	-- 3. Прозрачный хитбокс для взаимодействия
	local hitBox = Instance.new("Part")
	hitBox.Name = "HitBox"
	hitBox.Size = Vector3.new(3.6, 2.4, 3.6)
	hitBox.CFrame = CFrame.new(exactPos + Vector3.new(0, 0.8, 0))
	hitBox.Transparency = 1
	hitBox.CanCollide = false
	hitBox.Anchored = true
	hitBox.Parent = nodeModel

	-- Мягкая подсветка ноды
	local glowLight = Instance.new("PointLight", hitBox)
	glowLight.Range = 9
	glowLight.Brightness = 0.7
	if resType == "Branches" then glowLight.Color = Color3.fromRGB(245, 158, 11)
	elseif resType == "Fiber" then glowLight.Color = Color3.fromRGB(250, 204, 21)
	elseif resType == "Stone" then glowLight.Color = Color3.fromRGB(186, 230, 253)
	elseif resType == "Planks" then glowLight.Color = Color3.fromRGB(251, 191, 36)
	elseif resType == "Parts" then glowLight.Color = Color3.fromRGB(56, 189, 248)
	end

	local actionTitle = (resType == "Branches" and "Взять ветки (x2)")
		or (resType == "Fiber" and "Собрать волокно (x2)")
		or (resType == "Stone" and "Взять камень (x2)")
		or (resType == "Planks" and "Взять доски (x2)")
		or (resType == "Parts" and "Взять детали (x2)")
		or "Взять ресурс (x2)"

	local promptName = (resType == "Branches" and "🌿 Ветки")
		or (resType == "Fiber" and "🌱 Волокно")
		or (resType == "Stone" and "⚪ Камень")
		or (resType == "Planks" and "🌲 Доски")
		or (resType == "Parts" and "⚙️ Детали")
		or "📦 Ресурс"

	local prompt = Instance.new("ProximityPrompt", hitBox)
	prompt.ActionText = actionTitle
	prompt.ObjectText = promptName
	prompt.HoldDuration = 0
	prompt.MaxActivationDistance = 12
	prompt.RequiresLineOfSight = false

	prompt.Triggered:Connect(function(player)
		local given = givePlayerItem(player, resType, 2)
		if not given and _G.DropItemOnGround then
			_G.DropItemOnGround(player, resType, 2, exactPos + Vector3.new(0, 1.0, 0))
		end

		prompt.Enabled = false
		for _, desc in ipairs(nodeModel:GetDescendants()) do
			if desc:IsA("BasePart") then
				desc.Transparency = 1
			end
		end
		glowLight.Enabled = false

		-- Быстрый респавн 45 секунд
		task.delay(45, function()
			if nodeModel and nodeModel.Parent then
				for _, desc in ipairs(nodeModel:GetDescendants()) do
					if desc:IsA("BasePart") and desc.Name ~= "HitBox" then
						desc.Transparency = 0
					end
				end
				glowLight.Enabled = true
				prompt.Enabled = true
			end
		end)
	end)

	nodeModel.Parent = HomeSuppliesFolder
end

-- 10 ВЕТОК (Левый передний двор: X = -22 .. -34, Z = 5 .. 25)
for i = 1, 10 do
	local angle = (i / 10) * (math.pi * 1.5)
	local x = -26 + math.cos(angle) * 7
	local z = 15 + math.sin(angle) * 8
	createHomeResourceNode("Branches", Vector3.new(x, 0, z), i)
end

-- 10 ВОЛОКОН (Правый передний двор: X = 22 .. 34, Z = 5 .. 25)
for i = 1, 10 do
	local angle = (i / 10) * (math.pi * 1.5)
	local x = 26 + math.cos(angle) * 7
	local z = 15 + math.sin(angle) * 8
	createHomeResourceNode("Fiber", Vector3.new(x, 0, z), i)
end

-- 10 КАМНЕЙ (Задний левый двор: X = -18 .. -32, Z = -18 .. -32)
for i = 1, 10 do
	local angle = (i / 10) * (math.pi * 1.5)
	local x = -24 + math.cos(angle) * 7
	local z = -24 + math.sin(angle) * 7
	createHomeResourceNode("Stone", Vector3.new(x, 0, z), i)
end

-- 10 ДОСОК (Задний правый двор: X = 18 .. 32, Z = -18 .. -32)
for i = 1, 10 do
	local angle = (i / 10) * (math.pi * 1.5)
	local x = 24 + math.cos(angle) * 7
	local z = -24 + math.sin(angle) * 7
	createHomeResourceNode("Planks", Vector3.new(x, 0, z), i)
end

-- 10 ДЕТАЛЕЙ (Правый фасад: X = 15 .. 28, Z = 5 .. 20)
for i = 1, 10 do
	local angle = (i / 10) * (math.pi * 1.5)
	local x = 22 + math.cos(angle) * 6
	local z = 10 + math.sin(angle) * 6
	createHomeResourceNode("Parts", Vector3.new(x, 0, z), i)
end

print("🏡 [HomeSuppliesService] 50 околодомовых 3D-ресурсов (Ветки, Волокно, Камни, Доски, Детали) успешно расставлены вокруг дома!")
