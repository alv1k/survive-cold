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

local Network = require(ReplicatedStorage:WaitForChild("Network"))
local InventoryService = require(script.Parent:WaitForChild("InventoryService"))

local ShowNotificationRemote = Network.getEvent("ShowNotification")

local ModelHelper = require(ReplicatedStorage:WaitForChild("ModelHelper", 10))
local SurfaceUtil = require(ReplicatedStorage:WaitForChild("SurfaceUtil"))

local function getGroundHeight(x, z)
	return SurfaceUtil.getGroundHeight(x, z)
end

local function givePlayerItem(player, itemKey, count)
	return InventoryService.giveItem(player, itemKey, count or 1)
end

--------------------------------------------------------------------------------
-- 🌲 ОКОЛОДОМОВЫЕ ПРИРОДНЫЕ РЕСУРСЫ (Ветки, Волокно, Камни, Доски, Детали)
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- 2. 🌲 10 ВЕТОК, 10 ВОЛОКОН, 10 КАМНЕЙ, 10 ДОСОК У ДОМА (С КРУПНЫМИ 3D-МОДЕЛЯМИ)
--------------------------------------------------------------------------------

local function createHomeResourceNode(resType, pos, index)
	local groundY = getGroundHeight(pos.X, pos.Z)
	local exactPos = Vector3.new(pos.X, groundY, pos.Z)
	local nodeCF = CFrame.new(exactPos) * CFrame.Angles(0, math.rad((index * 37) % 360), 0)

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
		nodeModel:PivotTo(nodeCF)
	end

	nodeModel.Name = string.format("HomeNode_%s_%d", resType, index)

	-- 1. Включаем видимость и закрепляем все физические детали
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
		local given = InventoryService.giveItem(player, resType, 2)
		if not given then
			InventoryService.dropItem(player, resType, 2, exactPos + Vector3.new(0, 1.0, 0))
		end

		prompt.Enabled = false
		for _, desc in ipairs(nodeModel:GetDescendants()) do
			if desc:IsA("BasePart") then
				desc.Transparency = 1
			end
		end

		-- Быстрый респавн 45 секунд
		task.delay(45, function()
			if nodeModel and nodeModel.Parent then
				for _, desc in ipairs(nodeModel:GetDescendants()) do
					if desc:IsA("BasePart") and desc.Name ~= "HitBox" then
						desc.Transparency = 0
					end
				end
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

-- 10 ДОСОК (4 на переднем крыльце у входа: X = 12..18, Z = 15..20; 6 на заднем дворе: X = 20..30, Z = -20..-30)
local plankPositions = {
	Vector3.new(14, 0, 16),  -- Прямо справа от входа
	Vector3.new(17, 0, 19),  -- Справа на полянке перед домом
	Vector3.new(-14, 0, 16), -- Прямо слева от входа
	Vector3.new(-17, 0, 19), -- Слева на полянке перед домом
	Vector3.new(22, 0, -18), -- Задний правый угол
	Vector3.new(26, 0, -22), -- Задний правый двор
	Vector3.new(28, 0, -26), -- Задний правый двор
	Vector3.new(24, 0, -28), -- Задний правый двор
	Vector3.new(20, 0, -24), -- Задний правый угол
	Vector3.new(25, 0, -31), -- Задний правый двор
}
for i, pos in ipairs(plankPositions) do
	createHomeResourceNode("Planks", pos, i)
end

-- 10 ДЕТАЛЕЙ (Правый фасад: X = 15 .. 28, Z = 5 .. 20)
for i = 1, 10 do
	local angle = (i / 10) * (math.pi * 1.5)
	local x = 22 + math.cos(angle) * 6
	local z = 10 + math.sin(angle) * 6
	createHomeResourceNode("Parts", Vector3.new(x, 0, z), i)
end

print("🏡 [HomeSuppliesService] 50 околодомовых 3D-ресурсов (Ветки, Волокно, Камни, Доски, Детали) успешно расставлены вокруг дома!")
