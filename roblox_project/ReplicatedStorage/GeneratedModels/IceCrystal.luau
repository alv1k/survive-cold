--[[
    ReplicatedStorage/GeneratedModels/IceCrystal.luau
    Процедурный генератор 3D-модели ледяной глыбы с питомцем (Ice Crystal Block).
--]]

local IceCrystalGenerator = {}

function IceCrystalGenerator.create(parent)
	local model = Instance.new("Model")
	model.Name = "IceCrystal"

	-- 1. Снежная подложка (BaseFrost)
	local baseFrost = Instance.new("Part")
	baseFrost.Name = "BaseFrost"
	baseFrost.Size = Vector3.new(2.4, 0.2, 2.4)
	baseFrost.Position = Vector3.new(0, 0.1, 0)
	baseFrost.Material = Enum.Material.Snow
	baseFrost.Color = Color3.fromRGB(255, 255, 255)
	baseFrost.Anchored = false
	baseFrost.CanCollide = false
	baseFrost.Parent = model
	model.PrimaryPart = baseFrost

	-- 2. Главный кристаллический шпиль (MainSpire)
	local mainSpire = Instance.new("Part")
	mainSpire.Name = "MainSpire"
	mainSpire.Size = Vector3.new(1.1, 2.3, 1.1)
	mainSpire.CFrame = CFrame.new(0.1, 1.15, -0.1) * CFrame.Angles(math.rad(6), math.rad(15), math.rad(-5))
	mainSpire.Material = Enum.Material.Ice
	mainSpire.Transparency = 0.2
	mainSpire.Color = Color3.fromRGB(56, 189, 248) -- Glacier Blue
	mainSpire.Anchored = false
	mainSpire.CanCollide = false
	mainSpire.Parent = model

	-- 3. Левый осколок (ShardLeft)
	local shardLeft = Instance.new("Part")
	shardLeft.Name = "ShardLeft"
	shardLeft.Size = Vector3.new(0.7, 1.4, 0.7)
	shardLeft.CFrame = CFrame.new(-0.65, 0.7, 0.2) * CFrame.Angles(math.rad(-12), math.rad(-20), math.rad(10))
	shardLeft.Material = Enum.Material.Ice
	shardLeft.Transparency = 0.25
	shardLeft.Color = Color3.fromRGB(2, 132, 199) -- Deep Ice
	shardLeft.Anchored = false
	shardLeft.CanCollide = false
	shardLeft.Parent = model

	-- 4. Правый осколок (ShardRight)
	local shardRight = Instance.new("Part")
	shardRight.Name = "ShardRight"
	shardRight.Size = Vector3.new(0.6, 1.2, 0.6)
	shardRight.CFrame = CFrame.new(0.55, 0.6, -0.35) * CFrame.Angles(math.rad(10), math.rad(30), math.rad(-12))
	shardRight.Material = Enum.Material.Ice
	shardRight.Transparency = 0.15
	shardRight.Color = Color3.fromRGB(34, 211, 238) -- Aqua Bright
	shardRight.Anchored = false
	shardRight.CanCollide = false
	shardRight.Parent = model

	-- Сварка
	local subParts = {mainSpire, shardLeft, shardRight}
	for _, part in ipairs(subParts) do
		local weld = Instance.new("WeldConstraint")
		weld.Part0 = baseFrost
		weld.Part1 = part
		weld.Parent = part
	end

	if parent then
		model.Parent = parent
	end
	return model
end

return IceCrystalGenerator
