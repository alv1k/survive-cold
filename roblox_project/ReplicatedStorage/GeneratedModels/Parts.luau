--[[
    ReplicatedStorage/GeneratedModels/Parts.luau
    Процедурный генератор 3D-модели шестеренок и деталей (Parts) - в размер дропа из сундука:
    - Металлический корпус из титанового сплава
    - Две зубчатые шестеренки из закаленной стали
    - Светящийся энергетический кристалл/ядро в центре
--]]

local PartsGenerator = {}

function PartsGenerator.create(parent, targetCF)
	targetCF = targetCF or CFrame.identity
	local model = Instance.new("Model")
	model.Name = "Parts"

	-- 1. Базовый корпус из сплава (Main Housing)
	local housing = Instance.new("Part")
	housing.Name = "Housing"
	housing.Size = Vector3.new(1.6, 0.45, 1.6)
	housing.CFrame = targetCF * CFrame.new(0, 0.22, 0)
	housing.Material = Enum.Material.Metal
	housing.Color = Color3.fromRGB(51, 65, 85) -- dark alloy slate
	housing.Anchored = true
	housing.CanCollide = false
	housing.Parent = model
	model.PrimaryPart = housing

	-- 2. Первая большая шестеренка (Big Gear)
	local gear1 = Instance.new("Part")
	gear1.Name = "Gear_Main"
	gear1.Size = Vector3.new(1.4, 0.25, 1.4)
	gear1.CFrame = targetCF * CFrame.new(-0.2, 0.45, 0.1) * CFrame.Angles(0, math.rad(25), 0)
	gear1.Material = Enum.Material.DiamondPlate
	gear1.Color = Color3.fromRGB(148, 163, 184) -- steel
	gear1.Anchored = true
	gear1.CanCollide = false
	gear1.Parent = model

	-- 3. Вторая малая шестеренка (Small Gear)
	local gear2 = Instance.new("Part")
	gear2.Name = "Gear_Small"
	gear2.Size = Vector3.new(1.0, 0.22, 1.0)
	gear2.CFrame = targetCF * CFrame.new(0.4, 0.55, -0.2) * CFrame.Angles(0, math.rad(-45), 0)
	gear2.Material = Enum.Material.DiamondPlate
	gear2.Color = Color3.fromRGB(203, 213, 225) -- bright steel
	gear2.Anchored = true
	gear2.CanCollide = false
	gear2.Parent = model

	-- 4. Светящийся неоновый энергоблок (Energy Core)
	local core = Instance.new("Part")
	core.Name = "Core"
	core.Size = Vector3.new(0.7, 0.7, 0.7)
	core.CFrame = targetCF * CFrame.new(0, 0.65, 0)
	core.Material = Enum.Material.Neon
	core.Color = Color3.fromRGB(56, 189, 248) -- bright cyan
	core.Anchored = true
	core.CanCollide = false
	core.Parent = model

	-- 5. Медные контакты / шины (Copper Conduits)
	local copper1 = Instance.new("Part")
	copper1.Name = "Copper_1"
	copper1.Size = Vector3.new(0.25, 0.35, 1.3)
	copper1.CFrame = targetCF * CFrame.new(-0.45, 0.35, 0)
	copper1.Material = Enum.Material.Copper
	copper1.Color = Color3.fromRGB(234, 88, 12) -- copper rust
	copper1.Anchored = true
	copper1.CanCollide = false
	copper1.Parent = model

	-- Welds
	for _, part in ipairs({gear1, gear2, core, copper1}) do
		local weld = Instance.new("WeldConstraint")
		weld.Part0 = housing
		weld.Part1 = part
		weld.Parent = part
	end

	if parent then
		model.Parent = parent
	end

	return model
end

return PartsGenerator
