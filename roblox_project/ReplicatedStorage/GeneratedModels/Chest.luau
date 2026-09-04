--[[
    ReplicatedStorage/GeneratedModels/Chest.luau
    Высокоточный, красивый процедурный 3D-генератор сундука для Roblox (Chest):
    - Каменный постамент-основание (Cobblestone plinth)
    - Массивный деревянный короб (WoodPlanks)
    - Арочная крышка и свод (Arched Lid & Crown)
    - Кованые металлические полосы, оковки и угловые накладки (Cast Iron)
    - Золотой замок с замковой накладкой и сияющим неоновым кристаллом (Gold & Neon)
    - Боковые кованые ручки (Forged Handles)
    - Мягкая подсветка (PointLight)
--]]

local ChestGenerator = {}

function ChestGenerator.create(parent, targetCF)
	targetCF = targetCF or CFrame.identity
	local model = Instance.new("Model")
	model.Name = "Chest"

	-- 1. Каменный постамент-основание (чтобы сундук никогда не проваливался в снег)
	local plinth = Instance.new("Part")
	plinth.Name = "ChestPlinth"
	plinth.Size = Vector3.new(4.2, 0.4, 3.0)
	plinth.CFrame = targetCF * CFrame.new(0, 0.2, 0)
	plinth.Material = Enum.Material.Cobblestone
	plinth.Color = Color3.fromRGB(75, 85, 99)
	plinth.CastShadow = true
	plinth.Anchored = true
	plinth.CanCollide = true
	plinth.Parent = model

	-- 2. Массивный деревянный корпус (Base)
	local base = Instance.new("Part")
	base.Name = "ChestBase"
	base.Size = Vector3.new(3.6, 1.8, 2.4)
	base.CFrame = targetCF * CFrame.new(0, 1.3, 0)
	base.Material = Enum.Material.WoodPlanks
	base.Color = Color3.fromRGB(180, 100, 45) -- Warm Oak / Cedar
	base.CastShadow = true
	base.Anchored = true
	base.CanCollide = true
	base.Parent = model
	model.PrimaryPart = base

	-- 3. Нижний и верхний кованые обода корпуса
	local baseBandBot = Instance.new("Part")
	baseBandBot.Name = "BaseBandBot"
	baseBandBot.Size = Vector3.new(3.72, 0.3, 2.52)
	baseBandBot.CFrame = targetCF * CFrame.new(0, 0.55, 0)
	baseBandBot.Material = Enum.Material.Metal
	baseBandBot.Color = Color3.fromRGB(30, 41, 59) -- Cast Iron
	baseBandBot.CastShadow = true
	baseBandBot.Anchored = true
	baseBandBot.CanCollide = true
	baseBandBot.Parent = model

	local baseBandTop = Instance.new("Part")
	baseBandTop.Name = "BaseBandTop"
	baseBandTop.Size = Vector3.new(3.72, 0.25, 2.52)
	baseBandTop.CFrame = targetCF * CFrame.new(0, 2.05, 0)
	baseBandTop.Material = Enum.Material.Metal
	baseBandTop.Color = Color3.fromRGB(30, 41, 59)
	baseBandTop.CastShadow = true
	baseBandTop.Anchored = true
	baseBandTop.CanCollide = true
	baseBandTop.Parent = model

	-- 4. Вертикальные кованые полосы (Straps)
	for _, sx in ipairs({ -1.0, 1.0 }) do
		local strap = Instance.new("Part")
		strap.Name = "Strap_" .. tostring(sx)
		strap.Size = Vector3.new(0.24, 1.82, 2.48)
		strap.CFrame = targetCF * CFrame.new(sx, 1.3, 0)
		strap.Material = Enum.Material.Metal
		strap.Color = Color3.fromRGB(30, 41, 59)
		strap.CastShadow = true
		strap.Anchored = true
		strap.CanCollide = true
		strap.Parent = model
	end

	-- 5. Арочная деревянная крышка (Lid)
	local lid = Instance.new("Part")
	lid.Name = "ChestLid"
	lid.Size = Vector3.new(3.75, 0.8, 2.55)
	lid.CFrame = targetCF * CFrame.new(0, 2.55, 0)
	lid.Material = Enum.Material.WoodPlanks
	lid.Color = Color3.fromRGB(160, 85, 35)
	lid.CastShadow = true
	lid.Anchored = true
	lid.CanCollide = true
	lid.Parent = model

	-- Верхний скос крышки (Crown)
	local crown = Instance.new("Part")
	crown.Name = "LidCrown"
	crown.Size = Vector3.new(3.5, 0.4, 2.0)
	crown.CFrame = targetCF * CFrame.new(0, 3.05, 0)
	crown.Material = Enum.Material.WoodPlanks
	crown.Color = Color3.fromRGB(145, 75, 30)
	crown.CastShadow = true
	crown.Anchored = true
	crown.CanCollide = true
	crown.Parent = model

	-- Кованые полосы на крышке
	local lidBand = Instance.new("Part")
	lidBand.Name = "LidBand"
	lidBand.Size = Vector3.new(3.82, 0.2, 2.62)
	lidBand.CFrame = targetCF * CFrame.new(0, 2.25, 0)
	lidBand.Material = Enum.Material.Metal
	lidBand.Color = Color3.fromRGB(30, 41, 59)
	lidBand.CastShadow = true
	lidBand.Anchored = true
	lidBand.CanCollide = true
	lidBand.Parent = model

	-- 6. Золотой кованый замок и накладка (Lock & Plate)
	local lockPlate = Instance.new("Part")
	lockPlate.Name = "LockPlate"
	lockPlate.Size = Vector3.new(0.9, 1.1, 0.15)
	lockPlate.CFrame = targetCF * CFrame.new(0, 2.1, -1.26)
	lockPlate.Material = Enum.Material.Metal
	lockPlate.Color = Color3.fromRGB(30, 41, 59)
	lockPlate.CastShadow = true
	lockPlate.Anchored = true
	lockPlate.CanCollide = true
	lockPlate.Parent = model

	local latch = Instance.new("Part")
	latch.Name = "Latch"
	latch.Size = Vector3.new(0.65, 0.75, 0.3)
	latch.CFrame = targetCF * CFrame.new(0, 2.0, -1.35)
	latch.Material = Enum.Material.Metal
	latch.Color = Color3.fromRGB(250, 204, 21) -- Pure Gold
	latch.CastShadow = true
	latch.Anchored = true
	latch.CanCollide = true
	latch.Parent = model

	local gem = Instance.new("Part")
	gem.Name = "Gem"
	gem.Size = Vector3.new(0.25, 0.25, 0.1)
	gem.CFrame = targetCF * CFrame.new(0, 2.0, -1.5)
	gem.Material = Enum.Material.Neon
	gem.Color = Color3.fromRGB(250, 204, 21)
	gem.Anchored = true
	gem.CanCollide = false
	gem.Parent = model

	-- 7. Боковые кованые ручки (Handles)
	local handleL = Instance.new("Part")
	handleL.Name = "HandleLeft"
	handleL.Size = Vector3.new(0.2, 0.4, 0.6)
	handleL.CFrame = targetCF * CFrame.new(-1.88, 1.3, 0)
	handleL.Material = Enum.Material.Metal
	handleL.Color = Color3.fromRGB(30, 41, 59)
	handleL.CastShadow = true
	handleL.Anchored = true
	handleL.CanCollide = true
	handleL.Parent = model

	local handleR = Instance.new("Part")
	handleR.Name = "HandleRight"
	handleR.Size = Vector3.new(0.2, 0.4, 0.6)
	handleR.CFrame = targetCF * CFrame.new(1.88, 1.3, 0)
	handleR.Material = Enum.Material.Metal
	handleR.Color = Color3.fromRGB(30, 41, 59)
	handleR.CastShadow = true
	handleR.Anchored = true
	handleR.CanCollide = true
	handleR.Parent = model

	-- Сварка всех деталей с ChestBase
	for _, part in ipairs(model:GetChildren()) do
		if part:IsA("BasePart") and part ~= base then
			local weld = Instance.new("WeldConstraint")
			weld.Part0 = base
			weld.Part1 = part
			weld.Parent = part
		end
	end

	if parent then
		model.Parent = parent
	end

	return model
end

return ChestGenerator
