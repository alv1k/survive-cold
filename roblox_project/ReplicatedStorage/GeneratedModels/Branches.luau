--[[
    ReplicatedStorage/GeneratedModels/Branches.luau
    Процедурный 3D-генератор веток и хвороста («Survive the Cold»):
    
    1. 🌿 КУСТИК ХВОРОСТА ДЛЯ СБОРА В МИРЕ (World Node / Bush):
       - 8 круглых разветвленных сухих веток без листьев и хвои (~1.1 - 2.4 студа)
       - Боковые веточки-развилки для реалистичного силуэта сухостоя
       - Торчат веером вверх и в стороны из основания
       
    2. 🪵 ПУЧОК ХВОРОСТА ДЛЯ ДРОПА И ИНВЕНТАРЯ (Kindling Bundle):
       - 4 круглые сухие веточки (~1.9 студа), аккуратно уложенные в связку
       - Перевязаны посередине круглым джутовым жгутом с узелком (Twine Band)
--]]

local BranchesGenerator = {}

-- Создание пучка хвороста (4 круглые веточки с бечевкой)
function BranchesGenerator.createBundle(parent, targetCF)
	targetCF = targetCF or CFrame.identity
	local model = Instance.new("Model")
	model.Name = "BranchesBundle"

	-- Опорная центральная часть / Handle
	local handle = Instance.new("Part")
	handle.Name = "Handle"
	handle.Size = Vector3.new(0.38, 0.28, 0.38)
	handle.CFrame = targetCF * CFrame.new(0, 0.15, 0)
	handle.Transparency = 1
	handle.CanCollide = false
	handle.Anchored = true
	handle.Parent = model
	model.PrimaryPart = handle

	-- 4 Голые круглые веточки в пучке (ориентированы вдоль оси Y для естественного хвата в руке)
	local stickConfigs = {
		{ 
			Name = "Twig1", 
			Radius = 0.08, 
			Length = 1.95, 
			Offset = CFrame.new(-0.08, 0.0, -0.06) * CFrame.Angles(math.rad(2), 0, math.rad(2)), 
			Color = Color3.fromRGB(140, 69, 26) -- Cedar
		},
		{ 
			Name = "Twig2", 
			Radius = 0.09, 
			Length = 2.00, 
			Offset = CFrame.new(0.08, 0.0, -0.04) * CFrame.Angles(math.rad(-3), 0, math.rad(-2)), 
			Color = Color3.fromRGB(175, 115, 65) -- Pine
		},
		{ 
			Name = "Twig3", 
			Radius = 0.075, 
			Length = 1.85, 
			Offset = CFrame.new(-0.03, 0.0, 0.08) * CFrame.Angles(math.rad(1), 0, math.rad(1)), 
			Color = Color3.fromRGB(92, 46, 11) -- Walnut
		},
		{ 
			Name = "Twig4", 
			Radius = 0.08, 
			Length = 1.90, 
			Offset = CFrame.new(0.05, 0.0, 0.07) * CFrame.Angles(math.rad(-2), 0, math.rad(-1)), 
			Color = Color3.fromRGB(62, 30, 8) -- Bark
		},
	}

	for _, cfg in ipairs(stickConfigs) do
		local stick = Instance.new("Part")
		stick.Name = cfg.Name
		stick.Size = Vector3.new(cfg.Radius * 2, cfg.Length, cfg.Radius * 2)
		stick.CFrame = targetCF * cfg.Offset
		stick.Material = Enum.Material.Wood
		stick.Color = cfg.Color
		stick.Anchored = true
		stick.CanCollide = false
		stick.Parent = model

		-- Придание круглой цилиндрической формы
		local mesh = Instance.new("CylinderMesh")
		mesh.Parent = stick

		local w = Instance.new("WeldConstraint")
		w.Part0 = handle
		w.Part1 = stick
		w.Parent = stick
	end

	-- Перевязка бечевкой (Круглый джутовый жгут вокруг пучка)
	local twine = Instance.new("Part")
	twine.Name = "TwineBand"
	twine.Size = Vector3.new(0.42, 0.12, 0.38)
	twine.CFrame = targetCF * CFrame.new(0, 0, 0)
	twine.Material = Enum.Material.Fabric
	twine.Color = Color3.fromRGB(212, 163, 115) -- Джутовая бечевка
	twine.Anchored = true
	twine.CanCollide = false
	twine.Parent = model

	local twineMesh = Instance.new("CylinderMesh")
	twineMesh.Parent = twine

	local wTwine = Instance.new("WeldConstraint")
	wTwine.Part0 = handle
	wTwine.Part1 = twine
	wTwine.Parent = twine

	-- Узелок бечевки
	local knot = Instance.new("Part")
	knot.Name = "TwineKnot"
	knot.Shape = Enum.PartType.Ball
	knot.Size = Vector3.new(0.12, 0.12, 0.12)
	knot.CFrame = targetCF * CFrame.new(0, 0, 0.20)
	knot.Material = Enum.Material.Fabric
	knot.Color = Color3.fromRGB(254, 240, 138) -- Светлая солома
	knot.Anchored = true
	knot.CanCollide = false
	knot.Parent = model

	local wKnot = Instance.new("WeldConstraint")
	wKnot.Part0 = handle
	wKnot.Part1 = knot
	wKnot.Parent = knot

	if parent then
		model.Parent = parent
	end

	return model
end

-- Создание кустика хвороста (8 круглых разветвленных веток для сбора в мире)
function BranchesGenerator.createBush(parent, targetCF)
	targetCF = targetCF or CFrame.identity
	local model = Instance.new("Model")
	model.Name = "Branches"

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

	-- 8 Круглых веток, расходящихся веером вверх и в стороны
	local branchConfigs = {
		{ Name = "Branch_Center", Radius = 0.11, Length = 2.4, Offset = CFrame.new(0, 1.15, 0) * CFrame.Angles(math.rad(8), math.rad(15), math.rad(-5)), Color = Color3.fromRGB(62, 30, 8) },
		{ Name = "Branch_Right_Main", Radius = 0.10, Length = 2.1, Offset = CFrame.new(0.35, 1.0, 0.2) * CFrame.Angles(math.rad(-15), math.rad(45), math.rad(22)), Color = Color3.fromRGB(140, 69, 26) },
		{ Name = "Branch_Left_Main", Radius = 0.09, Length = 1.9, Offset = CFrame.new(-0.35, 0.9, 0.1) * CFrame.Angles(math.rad(14), math.rad(-40), math.rad(-24)), Color = Color3.fromRGB(92, 46, 11) },
		{ Name = "Branch_Back_Tall", Radius = 0.09, Length = 2.0, Offset = CFrame.new(-0.1, 0.95, -0.35) * CFrame.Angles(math.rad(-22), math.rad(-10), math.rad(12)), Color = Color3.fromRGB(175, 115, 65) },
		{ Name = "Branch_Front_Low", Radius = 0.08, Length = 1.5, Offset = CFrame.new(0.15, 0.70, 0.35) * CFrame.Angles(math.rad(28), math.rad(20), math.rad(-16)), Color = Color3.fromRGB(120, 113, 108) },
		{ Name = "Branch_Left_Low", Radius = 0.075, Length = 1.4, Offset = CFrame.new(-0.4, 0.65, -0.2) * CFrame.Angles(math.rad(-18), math.rad(-70), math.rad(-30)), Color = Color3.fromRGB(140, 69, 26) },
		{ Name = "Branch_Right_Low", Radius = 0.075, Length = 1.3, Offset = CFrame.new(0.4, 0.60, -0.15) * CFrame.Angles(math.rad(-10), math.rad(80), math.rad(26)), Color = Color3.fromRGB(92, 46, 11) },
		{ Name = "Branch_Front_Small", Radius = 0.065, Length = 1.1, Offset = CFrame.new(-0.15, 0.50, 0.25) * CFrame.Angles(math.rad(35), math.rad(-20), math.rad(18)), Color = Color3.fromRGB(175, 115, 65) },
	}

	for _, cfg in ipairs(branchConfigs) do
		local branch = Instance.new("Part")
		branch.Name = cfg.Name
		branch.Size = Vector3.new(cfg.Radius * 2, cfg.Length, cfg.Radius * 2)
		branch.CFrame = targetCF * cfg.Offset
		branch.Material = Enum.Material.Wood
		branch.Color = cfg.Color
		branch.Anchored = true
		branch.CanCollide = false
		branch.Parent = model

		-- Придание круглой цилиндрической формы
		local mesh = Instance.new("CylinderMesh")
		mesh.Parent = branch

		local w = Instance.new("WeldConstraint")
		w.Part0 = root
		w.Part1 = branch
		w.Parent = branch
	end

	-- Боковые сухие веточки-развилки (Sub-branches)
	local subBranches = {
		{ Name = "Twig_Fork1", Radius = 0.05, Length = 0.7, Offset = CFrame.new(0.25, 1.6, 0.15) * CFrame.Angles(math.rad(25), math.rad(40), math.rad(35)), Color = Color3.fromRGB(140, 69, 26) },
		{ Name = "Twig_Fork2", Radius = 0.045, Length = 0.6, Offset = CFrame.new(-0.20, 1.4, -0.15) * CFrame.Angles(math.rad(-30), math.rad(-35), math.rad(-25)), Color = Color3.fromRGB(92, 46, 11) },
		{ Name = "Twig_Fork3", Radius = 0.04, Length = 0.55, Offset = CFrame.new(0.45, 1.2, -0.10) * CFrame.Angles(math.rad(15), math.rad(65), math.rad(40)), Color = Color3.fromRGB(175, 115, 65) },
	}

	for _, cfg in ipairs(subBranches) do
		local twig = Instance.new("Part")
		twig.Name = cfg.Name
		twig.Size = Vector3.new(cfg.Radius * 2, cfg.Length, cfg.Radius * 2)
		twig.CFrame = targetCF * cfg.Offset
		twig.Material = Enum.Material.Wood
		twig.Color = cfg.Color
		twig.Anchored = true
		twig.CanCollide = false
		twig.Parent = model

		local mesh = Instance.new("CylinderMesh")
		mesh.Parent = twig

		local w = Instance.new("WeldConstraint")
		w.Part0 = root
		w.Part1 = twig
		w.Parent = twig
	end

	if parent then
		model.Parent = parent
	end

	return model
end

-- Универсальная функция create:
-- Если спавнится в мире для сбора (WorldResources / HomeSupplies) -> Кустик из 8 веток
-- Для дропа / инвентаря / инструментов -> Пучок из 4 веток с бечевкой
function BranchesGenerator.create(parent, targetCF, isBundle)
	if isBundle == true then
		return BranchesGenerator.createBundle(parent, targetCF)
	end
	if isBundle == false then
		return BranchesGenerator.createBush(parent, targetCF)
	end

	if parent and (parent.Name == "WorldResources" or parent.Name == "HomeSupplies") then
		return BranchesGenerator.createBush(parent, targetCF)
	end

	return BranchesGenerator.createBundle(parent, targetCF)
end

return BranchesGenerator
