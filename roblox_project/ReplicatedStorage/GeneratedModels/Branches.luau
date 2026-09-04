--[[
    ReplicatedStorage/GeneratedModels/Branches.luau
    Процедурный генератор 3D-модели веток (Branches) - сбалансированный масштаб (в размер дропа из сундука):
    - 3 скрещенных стволика кедра, сосны и дуба (~2.8 студа)
    - 4 пучка изумрудной хвои
    - Зимняя снежная шапочка на пересечении
--]]

local BranchesGenerator = {}

function BranchesGenerator.create(parent, targetCF)
	targetCF = targetCF or CFrame.identity
	local model = Instance.new("Model")
	model.Name = "Branches"

	-- 1. Основная кедровая ветка (нижний опорный ствол)
	local stick1 = Instance.new("Part")
	stick1.Name = "Stick1"
	stick1.Size = Vector3.new(0.65, 0.65, 3.4)
	stick1.CFrame = targetCF * CFrame.new(0, 0.4, 0) * CFrame.Angles(0, math.rad(35), math.rad(4))
	stick1.Material = Enum.Material.Wood
	stick1.Color = Color3.fromRGB(140, 69, 26) -- wood_cedar
	stick1.Anchored = true
	stick1.CanCollide = false
	stick1.Parent = model
	model.PrimaryPart = stick1

	-- 2. Вторая скрещенная сосновая ветка (средний ярус)
	local stick2 = Instance.new("Part")
	stick2.Name = "Stick2"
	stick2.Size = Vector3.new(0.58, 0.58, 3.0)
	stick2.CFrame = targetCF * CFrame.new(0, 0.7, 0) * CFrame.Angles(0, math.rad(-50), math.rad(-4))
	stick2.Material = Enum.Material.Wood
	stick2.Color = Color3.fromRGB(210, 160, 110) -- wood_pine
	stick2.Anchored = true
	stick2.CanCollide = false
	stick2.Parent = model

	-- 3. Верхняя скрепляющая ветка (верхний ярус)
	local stick3 = Instance.new("Part")
	stick3.Name = "Stick3"
	stick3.Size = Vector3.new(0.50, 0.50, 2.6)
	stick3.CFrame = targetCF * CFrame.new(-0.25, 0.95, -0.1) * CFrame.Angles(0, math.rad(75), math.rad(10))
	stick3.Material = Enum.Material.Wood
	stick3.Color = Color3.fromRGB(175, 115, 65) -- wood_oak
	stick3.Anchored = true
	stick3.CanCollide = false
	stick3.Parent = model

	-- 4. Пучки хвои на концах веток
	local needlePositions = {
		Vector3.new(1.3, 0.55, 0.9),
		Vector3.new(-1.3, 0.55, -0.9),
		Vector3.new(0.9, 0.8, -1.1),
		Vector3.new(-1.0, 0.9, 0.8),
	}
	for i, pos in ipairs(needlePositions) do
		local needle = Instance.new("Part")
		needle.Name = "Needle_" .. i
		needle.Size = Vector3.new(1.1, 0.45, 1.1)
		needle.CFrame = targetCF * CFrame.new(pos) * CFrame.Angles(0, math.rad(i * 45), 0)
		needle.Material = Enum.Material.Grass
		needle.Color = (i % 2 == 0) and Color3.fromRGB(22, 163, 74) or Color3.fromRGB(16, 185, 129)
		needle.Anchored = true
		needle.CanCollide = false
		needle.Parent = model

		local w = Instance.new("WeldConstraint")
		w.Part0 = stick1
		w.Part1 = needle
		w.Parent = needle
	end

	-- 5. Снежная шапочка на пересечении веток
	local snowCap = Instance.new("Part")
	snowCap.Name = "SnowCap"
	snowCap.Size = Vector3.new(1.1, 0.35, 1.1)
	snowCap.CFrame = targetCF * CFrame.new(-0.05, 1.2, 0)
	snowCap.Material = Enum.Material.Snow
	snowCap.Color = Color3.fromRGB(248, 250, 252)
	snowCap.Anchored = true
	snowCap.CanCollide = false
	snowCap.Parent = model

	local wSnow = Instance.new("WeldConstraint")
	wSnow.Part0 = stick1
	wSnow.Part1 = snowCap
	wSnow.Parent = snowCap

	local w2 = Instance.new("WeldConstraint")
	w2.Part0 = stick1
	w2.Part1 = stick2
	w2.Parent = stick2

	local w3 = Instance.new("WeldConstraint")
	w3.Part0 = stick1
	w3.Part1 = stick3
	w3.Parent = stick3

	if parent then
		model.Parent = parent
	end

	return model
end

return BranchesGenerator
