--[[
    ReplicatedStorage/GeneratedModels/FirTree.luau
    Процедурный генератор 3D-модели мультяшной конусной ели со снегом (FirTree).
    Структура:
    FirTree (Model)
      ├── Trunk (ствол дерева)
      ├── Tier1, Tier2, Tier3 (ярусы мультяшной хвои)
      └── SnowTrim (снежные шапки на ярусах)
--]]

local FirTreeGenerator = {}

function FirTreeGenerator.create(parent)
	local model = Instance.new("Model")
	model.Name = "FirTree"

	-- 1. Ствол (Trunk)
	local trunk = Instance.new("Part")
	trunk.Name = "Trunk"
	trunk.Size = Vector3.new(0.45, 1.6, 0.45)
	trunk.Position = Vector3.new(0, 0.8, 0)
	trunk.Material = Enum.Material.Wood
	trunk.Color = Color3.fromRGB(62, 30, 8) -- wood_bark
	trunk.Anchored = false
	trunk.CanCollide = false
	trunk.Parent = model
	model.PrimaryPart = trunk

	-- 2. Нижний ярус (Tier 1)
	local tier1 = Instance.new("Part")
	tier1.Name = "FoliageTier1"
	tier1.Size = Vector3.new(2.8, 1.3, 2.8)
	tier1.Position = Vector3.new(0, 1.45, 0)
	tier1.Material = Enum.Material.Grass
	tier1.Color = Color3.fromRGB(21, 128, 61) -- pine_dark
	tier1.Anchored = false
	tier1.CanCollide = false
	tier1.Parent = model

	-- 3. Средний ярус (Tier 2)
	local tier2 = Instance.new("Part")
	tier2.Name = "FoliageTier2"
	tier2.Size = Vector3.new(2.1, 1.2, 2.1)
	tier2.Position = Vector3.new(0, 2.45, 0)
	tier2.Material = Enum.Material.Grass
	tier2.Color = Color3.fromRGB(22, 163, 74) -- pine_green
	tier2.Anchored = false
	tier2.CanCollide = false
	tier2.Parent = model

	-- 4. Верхний ярус (Tier 3)
	local tier3 = Instance.new("Part")
	tier3.Name = "FoliageTier3"
	tier3.Size = Vector3.new(1.4, 1.4, 1.4)
	tier3.Position = Vector3.new(0, 3.45, 0)
	tier3.Material = Enum.Material.Grass
	tier3.Color = Color3.fromRGB(34, 197, 94) -- leaf_green
	tier3.Anchored = false
	tier3.CanCollide = false
	tier3.Parent = model

	-- 5. Снежная шапочка на верхушке
	local snow = Instance.new("Part")
	snow.Name = "SnowTrim"
	snow.Size = Vector3.new(0.8, 0.4, 0.8)
	snow.Position = Vector3.new(0, 4.05, 0)
	snow.Material = Enum.Material.Snow
	snow.Color = Color3.fromRGB(255, 255, 255) -- snow_pure
	snow.Anchored = false
	snow.CanCollide = false
	snow.Parent = model

	-- Welds
	for _, p in ipairs({tier1, tier2, tier3, snow}) do
		local weld = Instance.new("WeldConstraint")
		weld.Part0 = trunk
		weld.Part1 = p
		weld.Parent = p
	end

	if parent then
		model.Parent = parent
	end

	return model
end

return FirTreeGenerator
