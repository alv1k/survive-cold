--[[
    ReplicatedStorage/GeneratedModels/Stone.luau
    Процедурный 3D-генератор кубического/граненого камня («Survive the Cold»):
    
    1. ⚪ ГРАНЕНЫЙ КУБИЧЕСКИЙ ВАЛУН ДЛЯ СБОРА В МИРЕ (World Node / Blocky Boulder):
       - Стилизованный рубленый кубический монолит со ступенчатыми плитами и сколами
       - 100% Slate/SmoothPlastic без сферических форм (чистая блочная геометрия)
       - Основной блок, верхняя плита, боковой уступ и малый угловой осколок
       
    2. ⚪ КУБИЧЕСКИЙ КАМЕШЕК ДЛЯ ДРОПА И РУК (Pebble / Stone Item):
       - Аккуратный граненый мини-брусок/кристаллический камешек (~0.70 x 0.55 x 0.65 студа)
--]]

local StoneGenerator = {}

-- Создание рубленого граненого камешка в руку / для дропа
function StoneGenerator.createPebble(parent, targetCF)
	targetCF = targetCF or CFrame.identity
	local model = Instance.new("Model")
	model.Name = "Stone"

	local handle = Instance.new("Part")
	handle.Name = "Handle"
	handle.Size = Vector3.new(0.70, 0.55, 0.65)
	handle.CFrame = targetCF * CFrame.new(0, 0.28, 0)
	handle.Material = Enum.Material.Slate
	handle.Color = Color3.fromRGB(100, 116, 139) -- stone_slate
	handle.Anchored = true
	handle.CanCollide = false
	handle.CastShadow = true
	handle.TopSurface = Enum.SurfaceType.Smooth
	handle.BottomSurface = Enum.SurfaceType.Smooth
	handle.Parent = model

	local topFacet = Instance.new("Part")
	topFacet.Name = "TopFacet"
	topFacet.Size = Vector3.new(0.52, 0.20, 0.48)
	topFacet.CFrame = handle.CFrame * CFrame.new(0, 0.26, 0) * CFrame.Angles(0, math.rad(15), 0)
	topFacet.Material = Enum.Material.Slate
	topFacet.Color = Color3.fromRGB(148, 163, 184) -- steel_light
	topFacet.Anchored = true
	topFacet.CanCollide = false
	topFacet.CastShadow = true
	topFacet.TopSurface = Enum.SurfaceType.Smooth
	topFacet.BottomSurface = Enum.SurfaceType.Smooth
	topFacet.Parent = model

	local weld = Instance.new("WeldConstraint")
	weld.Part0 = handle
	weld.Part1 = topFacet
	weld.Parent = topFacet

	model.PrimaryPart = handle

	if parent then
		model.Parent = parent
	end

	return model
end

-- Создание большого рубленого кубического валуна для мира
function StoneGenerator.createBoulder(parent, targetCF)
	targetCF = targetCF or CFrame.identity
	local model = Instance.new("Model")
	model.Name = "Stone"

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

	local function makeBlock(name, size, cfOffset, color, material)
		local p = Instance.new("Part")
		p.Name = name
		p.Size = size
		p.CFrame = targetCF * cfOffset
		p.Material = material or Enum.Material.Slate
		p.Color = color or Color3.fromRGB(100, 116, 139)
		p.Anchored = true
		p.CanCollide = false
		p.CastShadow = true
		p.TopSurface = Enum.SurfaceType.Smooth
		p.BottomSurface = Enum.SurfaceType.Smooth
		p.Parent = model

		local weld = Instance.new("WeldConstraint")
		weld.Name = "Weld_" .. name
		weld.Part0 = root
		weld.Part1 = p
		weld.Parent = p
		return p
	end

	-- 1. Нижний темный цоколь в грунте (BaseFooting)
	makeBlock("BaseFooting", Vector3.new(2.7, 0.5, 2.5), CFrame.new(0, 0.25, 0), Color3.fromRGB(51, 65, 85), Enum.Material.Slate)

	-- 2. Основной кубический монолит (MainBlock)
	local mainBlock = makeBlock("MainBlock", Vector3.new(2.3, 1.4, 2.1), CFrame.new(0, 0.95, 0) * CFrame.Angles(0, math.rad(5), 0), Color3.fromRGB(100, 116, 139), Enum.Material.Slate)

	-- 3. Верхняя граненая плита (TopSlab)
	makeBlock("TopSlab", Vector3.new(1.6, 0.6, 1.5), CFrame.new(-0.1, 1.65, 0.05) * CFrame.Angles(0, math.rad(-12), 0), Color3.fromRGB(148, 163, 184), Enum.Material.Slate)

	-- 4. Верхний угловой гребень (TopPeak)
	makeBlock("TopPeak", Vector3.new(0.8, 0.4, 0.7), CFrame.new(-0.05, 2.05, 0.0) * CFrame.Angles(0, math.rad(25), math.rad(5)), Color3.fromRGB(226, 232, 240), Enum.Material.Slate)

	-- 5. Боковой ступенчатый блок справа (SideBlock_R)
	makeBlock("SideBlock_R", Vector3.new(1.1, 0.9, 1.3), CFrame.new(1.3, 0.6, -0.15) * CFrame.Angles(math.rad(-5), math.rad(18), math.rad(-8)), Color3.fromRGB(71, 85, 105), Enum.Material.Slate)

	-- 6. Боковой граненый осколок слева (SideBlock_L)
	makeBlock("SideBlock_L", Vector3.new(0.9, 0.65, 1.0), CFrame.new(-1.25, 0.45, 0.35) * CFrame.Angles(math.rad(8), math.rad(-22), math.rad(10)), Color3.fromRGB(71, 85, 105), Enum.Material.Slate)

	-- 7. Малый кубический осколок-камешек у подножия (PebbleChunk)
	makeBlock("PebbleChunk", Vector3.new(0.55, 0.35, 0.55), CFrame.new(1.2, 0.2, 0.9) * CFrame.Angles(0, math.rad(35), 0), Color3.fromRGB(148, 163, 184), Enum.Material.Slate)

	if parent then
		model.Parent = parent
	end

	return model
end

-- Универсальная функция create
function StoneGenerator.create(parent, targetCF, isPebble)
	if isPebble == true then
		return StoneGenerator.createPebble(parent, targetCF)
	end
	if isPebble == false then
		return StoneGenerator.createBoulder(parent, targetCF)
	end

	if parent and (parent.Name == "WorldResources" or parent.Name == "HomeSupplies") then
		return StoneGenerator.createBoulder(parent, targetCF)
	end

	return StoneGenerator.createPebble(parent, targetCF)
end

return StoneGenerator
