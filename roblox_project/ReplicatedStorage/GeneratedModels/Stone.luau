--[[
    ReplicatedStorage/GeneratedModels/Stone.luau
    Процедурный генератор 3D-модели валуна со снегом (Stone) - в размер дропа из сундука:
    - Основной валун 2.0x1.4x1.8 студа
    - Снежная шапка на вершине
    - Малый боковой сколотый камень
--]]

local StoneGenerator = {}

function StoneGenerator.create(parent, targetCF)
	targetCF = targetCF or CFrame.identity
	local model = Instance.new("Model")
	model.Name = "Stone"

	-- 1. Основной валун (Boulder)
	local boulder = Instance.new("Part")
	boulder.Name = "Boulder"
	boulder.Size = Vector3.new(3.2, 2.2, 2.8)
	boulder.CFrame = targetCF * CFrame.new(0, 1.1, 0)
	boulder.Material = Enum.Material.Slate
	boulder.Color = Color3.fromRGB(100, 116, 139) -- stone_slate
	boulder.Anchored = true
	boulder.CanCollide = false
	boulder.Parent = model
	model.PrimaryPart = boulder

	-- 2. Снежная шапка (SnowCap)
	local snow = Instance.new("Part")
	snow.Name = "SnowCap"
	snow.Size = Vector3.new(2.7, 0.55, 2.3)
	snow.CFrame = targetCF * CFrame.new(0, 2.2, 0)
	snow.Material = Enum.Material.Snow
	snow.Color = Color3.fromRGB(255, 255, 255) -- snow_pure
	snow.Anchored = true
	snow.CanCollide = false
	snow.Parent = model

	-- 3. Боковой малый камень
	local sideRock = Instance.new("Part")
	sideRock.Name = "SideRock"
	sideRock.Size = Vector3.new(1.6, 1.1, 1.4)
	sideRock.CFrame = targetCF * CFrame.new(1.4, 0.55, -0.4) * CFrame.Angles(math.rad(-10), math.rad(65), math.rad(15))
	sideRock.Material = Enum.Material.Slate
	sideRock.Color = Color3.fromRGB(71, 85, 105) -- stone_dark
	sideRock.Anchored = true
	sideRock.CanCollide = false
	sideRock.Parent = model

	local w1 = Instance.new("WeldConstraint")
	w1.Part0 = boulder
	w1.Part1 = snow
	w1.Parent = snow

	local w2 = Instance.new("WeldConstraint")
	w2.Part0 = boulder
	w2.Part1 = sideRock
	w2.Parent = sideRock

	if parent then
		model.Parent = parent
	end

	return model
end

return StoneGenerator
