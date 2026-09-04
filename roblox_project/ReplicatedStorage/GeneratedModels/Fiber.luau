--[[
    ReplicatedStorage/GeneratedModels/Fiber.luau
    Процедурный генератор 3D-модели пучка сухостоя / волокна (Fiber) - в размер дропа из сундука:
    - Основание-узел
    - 3 выразительных стебля золотой сухой травы (~2.0 студа)
    - Травяной нижний пучок
--]]

local FiberGenerator = {}

function FiberGenerator.create(parent, targetCF)
	targetCF = targetCF or CFrame.identity
	local model = Instance.new("Model")
	model.Name = "Fiber"

	-- 1. Основание / Узел (Base)
	local base = Instance.new("Part")
	base.Name = "Base"
	base.Size = Vector3.new(1.8, 0.45, 1.8)
	base.CFrame = targetCF * CFrame.new(0, 0.22, 0)
	base.Material = Enum.Material.Fabric
	base.Color = Color3.fromRGB(212, 163, 115) -- leather_tan
	base.Anchored = true
	base.CanCollide = false
	base.Parent = model
	model.PrimaryPart = base

	-- 2. Центральный высокий стебель
	local stalk1 = Instance.new("Part")
	stalk1.Name = "StalkCenter"
	stalk1.Size = Vector3.new(0.55, 2.8, 0.55)
	stalk1.CFrame = targetCF * CFrame.new(0.04, 1.4, 0.1) * CFrame.Angles(math.rad(10), 0, math.rad(-6))
	stalk1.Material = Enum.Material.Grass
	stalk1.Color = Color3.fromRGB(254, 240, 138) -- twine_straw
	stalk1.Anchored = true
	stalk1.CanCollide = false
	stalk1.Parent = model

	-- 3. Левый стебель
	local stalk2 = Instance.new("Part")
	stalk2.Name = "StalkLeft"
	stalk2.Size = Vector3.new(0.48, 2.4, 0.48)
	stalk2.CFrame = targetCF * CFrame.new(-0.45, 1.25, 0.2) * CFrame.Angles(math.rad(8), 0, math.rad(28))
	stalk2.Material = Enum.Material.Grass
	stalk2.Color = Color3.fromRGB(234, 179, 8) -- fiber_gold
	stalk2.Anchored = true
	stalk2.CanCollide = false
	stalk2.Parent = model

	-- 4. Правый стебель
	local stalk3 = Instance.new("Part")
	stalk3.Name = "StalkRight"
	stalk3.Size = Vector3.new(0.48, 2.5, 0.48)
	stalk3.CFrame = targetCF * CFrame.new(0.45, 1.3, -0.2) * CFrame.Angles(math.rad(-8), 0, math.rad(-26))
	stalk3.Material = Enum.Material.Grass
	stalk3.Color = Color3.fromRGB(234, 179, 8) -- fiber_gold
	stalk3.Anchored = true
	stalk3.CanCollide = false
	stalk3.Parent = model

	-- 5. Травяной нижний пучок (Tuft)
	local tuft = Instance.new("Part")
	tuft.Name = "Tuft"
	tuft.Size = Vector3.new(2.2, 0.8, 2.2)
	tuft.CFrame = targetCF * CFrame.new(0, 0.45, 0)
	tuft.Material = Enum.Material.Grass
	tuft.Color = Color3.fromRGB(202, 138, 4) -- amber grass
	tuft.Anchored = true
	tuft.CanCollide = false
	tuft.Parent = model

	-- 6. Перевязка жгутом (Twine Band)
	local band = Instance.new("Part")
	band.Name = "Band"
	band.Size = Vector3.new(1.5, 0.35, 1.5)
	band.CFrame = targetCF * CFrame.new(0, 0.9, 0)
	band.Material = Enum.Material.Fabric
	band.Color = Color3.fromRGB(180, 83, 9) -- dark twine
	band.Anchored = true
	band.CanCollide = false
	band.Parent = model

	-- Welds
	for _, st in ipairs({stalk1, stalk2, stalk3, tuft, band}) do
		local weld = Instance.new("WeldConstraint")
		weld.Part0 = base
		weld.Part1 = st
		weld.Parent = st
	end

	if parent then
		model.Parent = parent
	end

	return model
end

return FiberGenerator
