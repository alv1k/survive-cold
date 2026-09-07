--[[
    ReplicatedStorage/GeneratedModels/Fiber.luau
    Процедурный 3D-генератор волокна и камыша («Survive the Cold»):
    
    1. 🌾 КУСТИК КАМЫША ДЛЯ СБОРА В МИРЕ (World Node / Bush):
       - 5 стеблей камыша (рогоза) с коричневыми бархатистыми початками
       - 8 золотисто-зеленых изогнутых камышовых листьев, растущих из снега
       
    2. 🌾 ПУЧОК КАМЫШЕЙ ДЛЯ ДРОПА И ИНВЕНТАРЯ (Cattail Bundle):
       - 3 стебля камыша с початками и сухими листьями
       - Перевязаны посередине круглым джутовым жгутом с узелком (Twine Band)
--]]

local FiberGenerator = {}

-- Создание связки камышей (для дропа, инвентаря и рук)
function FiberGenerator.createBundle(parent, targetCF)
	targetCF = targetCF or CFrame.identity
	local model = Instance.new("Model")
	model.Name = "FiberBundle"

	-- Опорный центр / Handle
	local handle = Instance.new("Part")
	handle.Name = "Handle"
	handle.Size = Vector3.new(0.32, 0.28, 0.32)
	handle.CFrame = targetCF * CFrame.new(0, 0.15, 0)
	handle.Transparency = 1
	handle.CanCollide = false
	handle.Anchored = true
	handle.Parent = model
	model.PrimaryPart = handle

	-- 3 Стебля камыша с початками
	local cattails = {
		{
			StemName = "Stem_Center",
			StemSize = Vector3.new(0.08, 1.8, 0.08),
			StemCF = CFrame.new(0.00, 0.15, 0.00) * CFrame.Angles(math.rad(2), 0, math.rad(-1)),
			StemColor = Color3.fromRGB(254, 240, 138), -- twine_straw
			HeadName = "Head_Center",
			HeadSize = Vector3.new(0.16, 0.45, 0.16),
			HeadCF = CFrame.new(0.02, 0.82, 0.01) * CFrame.Angles(math.rad(2), 0, math.rad(-1)),
			HeadColor = Color3.fromRGB(92, 46, 11), -- wood_walnut
		},
		{
			StemName = "Stem_Right",
			StemSize = Vector3.new(0.07, 1.65, 0.07),
			StemCF = CFrame.new(0.06, 0.10, -0.04) * CFrame.Angles(math.rad(-3), 0, math.rad(-6)),
			StemColor = Color3.fromRGB(234, 179, 8), -- fiber_gold
			HeadName = "Head_Right",
			HeadSize = Vector3.new(0.15, 0.40, 0.15),
			HeadCF = CFrame.new(0.09, 0.72, -0.06) * CFrame.Angles(math.rad(-3), 0, math.rad(-6)),
			HeadColor = Color3.fromRGB(84, 51, 16), -- soil_rich
		},
		{
			StemName = "Stem_Left",
			StemSize = Vector3.new(0.07, 1.70, 0.07),
			StemCF = CFrame.new(-0.06, 0.12, 0.04) * CFrame.Angles(math.rad(4), 0, math.rad(6)),
			StemColor = Color3.fromRGB(234, 179, 8), -- fiber_gold
			HeadName = "Head_Left",
			HeadSize = Vector3.new(0.15, 0.42, 0.15),
			HeadCF = CFrame.new(-0.09, 0.76, 0.06) * CFrame.Angles(math.rad(4), 0, math.rad(6)),
			HeadColor = Color3.fromRGB(92, 46, 11), -- wood_walnut
		},
	}

	for _, cfg in ipairs(cattails) do
		-- Стебель
		local stem = Instance.new("Part")
		stem.Name = cfg.StemName
		stem.Size = cfg.StemSize
		stem.CFrame = targetCF * cfg.StemCF
		stem.Material = Enum.Material.Wood
		stem.Color = cfg.StemColor
		stem.Anchored = true
		stem.CanCollide = false
		stem.Parent = model

		local stemMesh = Instance.new("CylinderMesh", stem)

		local wStem = Instance.new("WeldConstraint")
		wStem.Part0 = handle
		wStem.Part1 = stem
		wStem.Parent = stem

		-- Початок камыша (Brown Cattail Head)
		local head = Instance.new("Part")
		head.Name = cfg.HeadName
		head.Size = cfg.HeadSize
		head.CFrame = targetCF * cfg.HeadCF
		head.Material = Enum.Material.Fabric
		head.Color = cfg.HeadColor
		head.Anchored = true
		head.CanCollide = false
		head.Parent = model

		local headMesh = Instance.new("CylinderMesh", head)

		local wHead = Instance.new("WeldConstraint")
		wHead.Part0 = handle
		wHead.Part1 = head
		wHead.Parent = head
	end

	-- Сухие камышовые листья в пучке
	local leaves = {
		{ Name = "Leaf1", Size = Vector3.new(0.12, 1.35, 0.03), CF = CFrame.new(0.08, 0.18, 0.06) * CFrame.Angles(math.rad(6), math.rad(25), math.rad(8)), Color = Color3.fromRGB(234, 179, 8) },
		{ Name = "Leaf2", Size = Vector3.new(0.11, 1.25, 0.03), CF = CFrame.new(-0.08, 0.15, -0.05) * CFrame.Angles(math.rad(-8), math.rad(-30), math.rad(-10)), Color = Color3.fromRGB(254, 240, 138) },
		{ Name = "Leaf3", Size = Vector3.new(0.10, 1.20, 0.03), CF = CFrame.new(0.02, 0.12, -0.08) * CFrame.Angles(math.rad(-12), 0, math.rad(5)), Color = Color3.fromRGB(190, 242, 100) },
	}

	for _, l in ipairs(leaves) do
		local leaf = Instance.new("Part")
		leaf.Name = l.Name
		leaf.Size = l.Size
		leaf.CFrame = targetCF * l.CF
		leaf.Material = Enum.Material.Grass
		leaf.Color = l.Color
		leaf.Anchored = true
		leaf.CanCollide = false
		leaf.Parent = model

		local wLeaf = Instance.new("WeldConstraint")
		wLeaf.Part0 = handle
		wLeaf.Part1 = leaf
		wLeaf.Parent = leaf
	end

	-- Перевязка бечевкой (Круглый джутовый жгут)
	local twine = Instance.new("Part")
	twine.Name = "TwineBand"
	twine.Size = Vector3.new(0.34, 0.10, 0.32)
	twine.CFrame = targetCF * CFrame.new(0, 0.15, 0)
	twine.Material = Enum.Material.Fabric
	twine.Color = Color3.fromRGB(212, 163, 115) -- leather_tan
	twine.Anchored = true
	twine.CanCollide = false
	twine.Parent = model

	local twineMesh = Instance.new("CylinderMesh", twine)

	local wTwine = Instance.new("WeldConstraint")
	wTwine.Part0 = handle
	wTwine.Part1 = twine
	wTwine.Parent = twine

	-- Узелок бечевки
	local knot = Instance.new("Part")
	knot.Name = "TwineKnot"
	knot.Shape = Enum.PartType.Ball
	knot.Size = Vector3.new(0.10, 0.10, 0.10)
	knot.CFrame = targetCF * CFrame.new(0, 0.15, 0.16)
	knot.Material = Enum.Material.Fabric
	knot.Color = Color3.fromRGB(254, 240, 138)
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

-- Создание кустика камыша (5 стеблей с початками + листья для сбора в мире)
function FiberGenerator.createBush(parent, targetCF)
	targetCF = targetCF or CFrame.identity
	local model = Instance.new("Model")
	model.Name = "Fiber"

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

	-- 5 Стеблей камыша с початками
	local bushCattails = {
		{
			Name = "Center",
			StemSize = Vector3.new(0.08, 1.85, 0.08),
			StemCF = CFrame.new(0.0, 0.90, 0.0) * CFrame.Angles(math.rad(3), 0, math.rad(-2)),
			HeadSize = Vector3.new(0.16, 0.46, 0.16),
			HeadCF = CFrame.new(0.02, 1.55, 0.01) * CFrame.Angles(math.rad(3), 0, math.rad(-2)),
			StemColor = Color3.fromRGB(254, 240, 138),
			HeadColor = Color3.fromRGB(92, 46, 11),
		},
		{
			Name = "Right",
			StemSize = Vector3.new(0.07, 1.55, 0.07),
			StemCF = CFrame.new(0.25, 0.75, 0.12) * CFrame.Angles(math.rad(-10), math.rad(25), math.rad(18)),
			HeadSize = Vector3.new(0.15, 0.40, 0.15),
			HeadCF = CFrame.new(0.38, 1.30, 0.18) * CFrame.Angles(math.rad(-10), math.rad(25), math.rad(18)),
			StemColor = Color3.fromRGB(234, 179, 8),
			HeadColor = Color3.fromRGB(84, 51, 16),
		},
		{
			Name = "Left",
			StemSize = Vector3.new(0.07, 1.60, 0.07),
			StemCF = CFrame.new(-0.22, 0.78, 0.15) * CFrame.Angles(math.rad(12), math.rad(-20), math.rad(-16)),
			HeadSize = Vector3.new(0.15, 0.42, 0.15),
			HeadCF = CFrame.new(-0.34, 1.35, 0.22) * CFrame.Angles(math.rad(12), math.rad(-20), math.rad(-16)),
			StemColor = Color3.fromRGB(234, 179, 8),
			HeadColor = Color3.fromRGB(92, 46, 11),
		},
		{
			Name = "BackLeft",
			StemSize = Vector3.new(0.065, 1.45, 0.065),
			StemCF = CFrame.new(-0.16, 0.70, -0.20) * CFrame.Angles(math.rad(-15), math.rad(-40), math.rad(-12)),
			HeadSize = Vector3.new(0.14, 0.38, 0.14),
			HeadCF = CFrame.new(-0.25, 1.20, -0.30) * CFrame.Angles(math.rad(-15), math.rad(-40), math.rad(-12)),
			StemColor = Color3.fromRGB(254, 240, 138),
			HeadColor = Color3.fromRGB(84, 51, 16),
		},
		{
			Name = "BackRight",
			StemSize = Vector3.new(0.07, 1.50, 0.07),
			StemCF = CFrame.new(0.18, 0.72, -0.18) * CFrame.Angles(math.rad(-12), math.rad(45), math.rad(15)),
			HeadSize = Vector3.new(0.15, 0.40, 0.15),
			HeadCF = CFrame.new(0.28, 1.25, -0.26) * CFrame.Angles(math.rad(-12), math.rad(45), math.rad(15)),
			StemColor = Color3.fromRGB(234, 179, 8),
			HeadColor = Color3.fromRGB(92, 46, 11),
		},
	}

	for _, cfg in ipairs(bushCattails) do
		local stem = Instance.new("Part")
		stem.Name = "Stem_" .. cfg.Name
		stem.Size = cfg.StemSize
		stem.CFrame = targetCF * cfg.StemCF
		stem.Material = Enum.Material.Wood
		stem.Color = cfg.StemColor
		stem.Anchored = true
		stem.CanCollide = false
		stem.Parent = model

		local stemMesh = Instance.new("CylinderMesh", stem)

		local wStem = Instance.new("WeldConstraint")
		wStem.Part0 = root
		wStem.Part1 = stem
		wStem.Parent = stem

		local head = Instance.new("Part")
		head.Name = "Head_" .. cfg.Name
		head.Size = cfg.HeadSize
		head.CFrame = targetCF * cfg.HeadCF
		head.Material = Enum.Material.Fabric
		head.Color = cfg.HeadColor
		head.Anchored = true
		head.CanCollide = false
		head.Parent = model

		local headMesh = Instance.new("CylinderMesh", head)

		local wHead = Instance.new("WeldConstraint")
		wHead.Part0 = root
		wHead.Part1 = head
		wHead.Parent = head
	end

	-- 6 Раскидистых сухих камышовых листьев у основания
	local bushLeaves = {
		{ Name = "Leaf_Front", Size = Vector3.new(0.14, 1.2, 0.04), CF = CFrame.new(0.05, 0.55, 0.35) * CFrame.Angles(math.rad(30), 0, math.rad(-5)), Color = Color3.fromRGB(234, 179, 8) },
		{ Name = "Leaf_FrontLeft", Size = Vector3.new(0.12, 1.1, 0.04), CF = CFrame.new(-0.25, 0.50, 0.28) * CFrame.Angles(math.rad(25), math.rad(-35), math.rad(-22)), Color = Color3.fromRGB(254, 240, 138) },
		{ Name = "Leaf_Right", Size = Vector3.new(0.13, 1.15, 0.04), CF = CFrame.new(0.38, 0.52, 0.08) * CFrame.Angles(math.rad(-5), math.rad(60), math.rad(28)), Color = Color3.fromRGB(190, 242, 100) },
		{ Name = "Leaf_Back", Size = Vector3.new(0.13, 1.2, 0.04), CF = CFrame.new(-0.06, 0.55, -0.38) * CFrame.Angles(math.rad(-32), 0, math.rad(8)), Color = Color3.fromRGB(234, 179, 8) },
		{ Name = "Leaf_BackRight", Size = Vector3.new(0.12, 1.05, 0.04), CF = CFrame.new(0.30, 0.48, -0.28) * CFrame.Angles(math.rad(-22), math.rad(45), math.rad(24)), Color = Color3.fromRGB(254, 240, 138) },
		{ Name = "Leaf_Left", Size = Vector3.new(0.13, 1.1, 0.04), CF = CFrame.new(-0.35, 0.50, -0.08) * CFrame.Angles(math.rad(-6), math.rad(-65), math.rad(-26)), Color = Color3.fromRGB(190, 242, 100) },
	}

	for _, l in ipairs(bushLeaves) do
		local leaf = Instance.new("Part")
		leaf.Name = l.Name
		leaf.Size = l.Size
		leaf.CFrame = targetCF * l.CF
		leaf.Material = Enum.Material.Grass
		leaf.Color = l.Color
		leaf.Anchored = true
		leaf.CanCollide = false
		leaf.Parent = model

		local wLeaf = Instance.new("WeldConstraint")
		wLeaf.Part0 = root
		wLeaf.Part1 = leaf
		wLeaf.Parent = leaf
	end

	if parent then
		model.Parent = parent
	end

	return model
end

-- Универсальная функция create
function FiberGenerator.create(parent, targetCF, isBundle)
	if isBundle == true then
		return FiberGenerator.createBundle(parent, targetCF)
	end
	if isBundle == false then
		return FiberGenerator.createBush(parent, targetCF)
	end

	if parent and (parent.Name == "WorldResources" or parent.Name == "HomeSupplies") then
		return FiberGenerator.createBush(parent, targetCF)
	end

	return FiberGenerator.createBundle(parent, targetCF)
end

return FiberGenerator
