--[[
    ReplicatedStorage/GeneratedModels/RabbitTrap.luau
    Процедурный генератор 3D-модели капкана на кроликов (Rabbit Trap).
--]]

local RabbitTrapGenerator = {}

function RabbitTrapGenerator.create(parent)
	local model = Instance.new("Model")
	model.Name = "RabbitTrap"

	-- 1. Деревянный приподнятый ящик (Crate)
	local crate = Instance.new("Part")
	crate.Name = "Crate"
	crate.Size = Vector3.new(1.5, 0.75, 1.3)
	crate.CFrame = CFrame.new(0, 0.55, 0) * CFrame.Angles(math.rad(-22), 0, 0)
	crate.Material = Enum.Material.Wood
	crate.Color = Color3.fromRGB(198, 139, 89) -- Honey Oak
	crate.Anchored = false
	crate.CanCollide = false
	crate.Parent = model
	model.PrimaryPart = crate

	-- 2. Подпирающая веточка (PropStick)
	local stick = Instance.new("Part")
	stick.Name = "PropStick"
	stick.Size = Vector3.new(0.08, 0.7, 0.08)
	stick.Position = Vector3.new(0, 0.35, -0.6)
	stick.Material = Enum.Material.Wood
	stick.Color = Color3.fromRGB(247, 225, 215) -- Birch
	stick.Anchored = false
	stick.CanCollide = false
	stick.Parent = model

	-- 3. Морковка-приманка (Carrot)
	local carrot = Instance.new("Part")
	carrot.Name = "Carrot"
	carrot.Size = Vector3.new(0.18, 0.16, 0.55)
	carrot.Position = Vector3.new(0, 0.09, 0.05)
	carrot.Material = Enum.Material.SmoothPlastic
	carrot.Color = Color3.fromRGB(249, 115, 22) -- Carrot Orange
	carrot.Anchored = false
	carrot.CanCollide = false
	carrot.Parent = model

	-- 4. Ботва морковки (CarrotGreens)
	local greens = Instance.new("Part")
	greens.Name = "CarrotGreens"
	greens.Size = Vector3.new(0.16, 0.14, 0.2)
	greens.Position = Vector3.new(0, 0.12, 0.35)
	greens.Material = Enum.Material.Grass
	greens.Color = Color3.fromRGB(34, 197, 94) -- Leaf Green
	greens.Anchored = false
	greens.CanCollide = false
	greens.Parent = model

	-- Сварка
	local subParts = {stick, carrot, greens}
	for _, part in ipairs(subParts) do
		local weld = Instance.new("WeldConstraint")
		weld.Part0 = crate
		weld.Part1 = part
		weld.Parent = part
	end

	if parent then
		model.Parent = parent
	end
	return model
end

return RabbitTrapGenerator
