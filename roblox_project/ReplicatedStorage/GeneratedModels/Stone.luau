--[[
    ReplicatedStorage/GeneratedModels/Stone.luau
    Процедурный 3D-генератор камня («Survive the Cold»):
    
    1. ⚪ ВАЛУН ДЛЯ СБОРА В МИРЕ (World Node / Boulder):
       - Овальной формы сланцевая сфера/валун без снежной шапки
       - Малый боковой осколок камня
       
    2. ⚪ КРУГЛЫЙ КАМЕНЬ ДЛЯ ДРОПА И РУК (Pebble / Stone Item):
       - Аккуратная овальная сфера-камешек, удобно лежащая в ладони (~0.75 x 0.55 x 0.65 студа)
--]]

local StoneGenerator = {}

-- Создание круглого камня в руку / для дропа
function StoneGenerator.createPebble(parent, targetCF)
	targetCF = targetCF or CFrame.identity
	local model = Instance.new("Model")
	model.Name = "Stone"

	local handle = Instance.new("Part")
	handle.Name = "Handle"
	handle.Size = Vector3.new(0.75, 0.55, 0.65)
	handle.CFrame = targetCF * CFrame.new(0, 0.28, 0)
	handle.Material = Enum.Material.Slate
	handle.Color = Color3.fromRGB(100, 116, 139) -- stone_slate
	handle.Anchored = true
	handle.CanCollide = false
	handle.Parent = model

	local mesh = Instance.new("SpecialMesh")
	mesh.MeshType = Enum.MeshType.Sphere
	mesh.Parent = handle

	model.PrimaryPart = handle

	if parent then
		model.Parent = parent
	end

	return model
end

-- Создание большого овального валуна для мира
function StoneGenerator.createBoulder(parent, targetCF)
	targetCF = targetCF or CFrame.identity
	local model = Instance.new("Model")
	model.Name = "Stone"

	-- Опорное основание
	local root = Instance.new("Part")
	root.Name = "Root"
	root.Size = Vector3.new(0.2, 0.2, 0.2)
	root.CFrame = targetCF
	root.Transparency = 1
	root.CanCollide = false
	root.Anchored = true
	root.Parent = model
	model.PrimaryPart = root

	-- 1. Основной овальный валун
	local boulder = Instance.new("Part")
	boulder.Name = "Boulder"
	boulder.Size = Vector3.new(2.4, 1.8, 2.1)
	boulder.CFrame = targetCF * CFrame.new(0, 0.9, 0)
	boulder.Material = Enum.Material.Slate
	boulder.Color = Color3.fromRGB(100, 116, 139) -- stone_slate
	boulder.Anchored = true
	boulder.CanCollide = false
	boulder.Parent = model

	local meshB = Instance.new("SpecialMesh")
	meshB.MeshType = Enum.MeshType.Sphere
	meshB.Parent = boulder

	local w1 = Instance.new("WeldConstraint")
	w1.Part0 = root
	w1.Part1 = boulder
	w1.Parent = boulder

	-- 2. Малый боковой осколок камня
	local sideRock = Instance.new("Part")
	sideRock.Name = "SideRock"
	sideRock.Size = Vector3.new(0.95, 0.65, 0.85)
	sideRock.CFrame = targetCF * CFrame.new(1.15, 0.35, -0.3) * CFrame.Angles(math.rad(-10), math.rad(45), math.rad(15))
	sideRock.Material = Enum.Material.Slate
	sideRock.Color = Color3.fromRGB(71, 85, 105) -- stone_dark
	sideRock.Anchored = true
	sideRock.CanCollide = false
	sideRock.Parent = model

	local meshS = Instance.new("SpecialMesh")
	meshS.MeshType = Enum.MeshType.Sphere
	meshS.Parent = sideRock

	local w2 = Instance.new("WeldConstraint")
	w2.Part0 = root
	w2.Part1 = sideRock
	w2.Parent = sideRock

	if parent then
		model.Parent = parent
	end

	return model
end

-- Универсальная функция create
function StoneGenerator.create(parent, targetCF, isPebble)
	if isPebble == true then
		return StoneGenerator.createPebble(parent, targetCF)
	end
	if isPebble == false then
		return StoneGenerator.createBoulder(parent, targetCF)
	end

	if parent and (parent.Name == "WorldResources" or parent.Name == "HomeSupplies") then
		return StoneGenerator.createBoulder(parent, targetCF)
	end

	return StoneGenerator.createPebble(parent, targetCF)
end

return StoneGenerator
