--[[
    ReplicatedStorage/GeneratedModels/Parts.luau
    Высокоточный, стилизованный 3D-генератор механических деталей (Шестерёнки / Cogwheels & Gears):
    
    1. ⚙️ Большая бронзовая шестерня (Large Bronze Gear):
       - Центральная цилиндрическая ступица (Hub)
       - 8 массивных радиальных зубьев (Cogs)
       - 4 внутренние спицы крестом (Spokes)
       - Благородный металлический оттенок античной бронзы (#CA8A04)

    2. ⚙️ Средняя стальная шестерня (Medium Steel Gear):
       - Сцеплена зубьями с большой шестерней (Interlocking Mesh)
       - 6 массивных зубьев
       - 3 внутренние спицы
       - Шлифованная оружейная сталь (#94A3B8)

    3. ⚙️ Малая верхняя шестерня привода (Small Pinion Gear):
       - Наложена сверху ступицы для объемной многослойной композиции
       - 6 зубьев из вороненой стали (#475569)

    4. 🔩 Центральные оси, втулки и медные шайбы (Axle Pins & Copper Bushings):
       - Стальные штифты с шестигранными шляпками
       - Медные уплотнительные кольца (#D97706)
--]]

local PartsGenerator = {}

function PartsGenerator.create(parent, targetCF)
	targetCF = targetCF or CFrame.new(0, 2.0, 0)
	local model = Instance.new("Model")
	model.Name = "Parts"

	-- Невидимый базовый опорный элемент (Center / Root)
	local center = Instance.new("Part")
	center.Name = "Center"
	center.Size = Vector3.new(2.4, 0.4, 2.4)
	center.CFrame = targetCF * CFrame.new(0, 0.18, 0)
	center.Transparency = 1
	center.CanCollide = false
	center.Anchored = true
	center.CastShadow = false
	center.Parent = model
	model.PrimaryPart = center

	local function makePart(name, size, cfOffset, material, color)
		local p = Instance.new("Part")
		p.Name = name
		p.Size = size
		p.CFrame = targetCF * cfOffset
		p.Material = material or Enum.Material.Metal
		p.Color = color or Color3.fromRGB(180, 180, 180)
		p.Anchored = true
		p.CanCollide = false
		p.CastShadow = true
		p.TopSurface = Enum.SurfaceType.Smooth
		p.BottomSurface = Enum.SurfaceType.Smooth
		p.Parent = model
		return p
	end

	local function makeCylinder(name, radius, height, cfOffset, material, color)
		local p = Instance.new("Part")
		p.Name = name
		p.Size = Vector3.new(height, radius * 2, radius * 2)
		p.CFrame = targetCF * cfOffset * CFrame.Angles(0, 0, math.rad(90))
		p.Material = material or Enum.Material.Metal
		p.Color = color or Color3.fromRGB(180, 180, 180)
		p.Anchored = true
		p.CanCollide = false
		p.CastShadow = true
		p.TopSurface = Enum.SurfaceType.Smooth
		p.BottomSurface = Enum.SurfaceType.Smooth

		local mesh = Instance.new("SpecialMesh", p)
		mesh.MeshType = Enum.MeshType.Cylinder
		p.Parent = model
		return p
	end

	-- =========================================================================
	-- 1. ⚙️ БОЛЬШАЯ БРОНЗОВАЯ ШЕСТЕРНЯ (Large Gear, 8 Зубьев, R = 0.94)
	-- =========================================================================
	local g1_pos = Vector3.new(-0.35, 0.16, -0.20)
	local g1_color = Color3.fromRGB(202, 138, 4) -- Antique Bronze / Brass
	local g1_rim_color = Color3.fromRGB(180, 115, 6)

	-- Центральная ступица (Hub) большой шестерни
	makeCylinder("Gear1_Hub", 0.92, 0.22, CFrame.new(g1_pos), Enum.Material.Metal, g1_color)

	-- Внутренний обод (Inner Rim)
	makeCylinder("Gear1_InnerRim", 0.60, 0.24, CFrame.new(g1_pos), Enum.Material.Metal, g1_rim_color)

	-- 8 Зубьев большой шестерни (Cogs)
	local nTeeth1 = 8
	local radius1 = 0.94
	for i = 0, nTeeth1 - 1 do
		local angle = (i / nTeeth1) * (math.pi * 2)
		local toothCF = CFrame.new(g1_pos) 
			* CFrame.Angles(0, angle, 0) 
			* CFrame.new(0, 0, radius1)
		makePart(
			"Gear1_Tooth_" .. i,
			Vector3.new(0.32, 0.22, 0.36),
			toothCF,
			Enum.Material.Metal,
			g1_color
		)
	end

	-- 4 Спицы большой шестерни (Spokes)
	makePart("Gear1_Spoke1", Vector3.new(1.70, 0.18, 0.18), CFrame.new(g1_pos), Enum.Material.Metal, g1_rim_color)
	makePart("Gear1_Spoke2", Vector3.new(0.18, 0.18, 1.70), CFrame.new(g1_pos), Enum.Material.Metal, g1_rim_color)

	-- Центральный стальной штифт / ось (Axle Pin 1)
	makeCylinder("Gear1_AxlePin", 0.24, 0.38, CFrame.new(g1_pos + Vector3.new(0, 0.06, 0)), Enum.Material.Metal, Color3.fromRGB(71, 85, 105))
	makeCylinder("Gear1_CopperWasher", 0.36, 0.08, CFrame.new(g1_pos + Vector3.new(0, 0.12, 0)), Enum.Material.Metal, Color3.fromRGB(217, 119, 6))

	-- =========================================================================
	-- 2. ⚙️ СРЕДНЯЯ СТАЛЬНАЯ ШЕСТЕРНЯ (Medium Gear, 6 Зубьев, R = 0.66)
	-- =========================================================================
	local g2_pos = Vector3.new(1.05, 0.14, 0.42)
	local g2_color = Color3.fromRGB(148, 163, 184) -- Machined Steel
	local g2_dark = Color3.fromRGB(100, 116, 139)

	-- Ступица средней шестерни
	makeCylinder("Gear2_Hub", 0.64, 0.20, CFrame.new(g2_pos), Enum.Material.Metal, g2_color)

	-- 6 Зубьев средней шестерни (смещение по фазе на 28° для зацепления)
	local nTeeth2 = 6
	local radius2 = 0.66
	local phase2 = math.rad(28)
	for i = 0, nTeeth2 - 1 do
		local angle = (i / nTeeth2) * (math.pi * 2) + phase2
		local toothCF = CFrame.new(g2_pos) 
			* CFrame.Angles(0, angle, 0) 
			* CFrame.new(0, 0, radius2)
		makePart(
			"Gear2_Tooth_" .. i,
			Vector3.new(0.26, 0.20, 0.30),
			toothCF,
			Enum.Material.Metal,
			g2_color
		)
	end

	-- 3 Спицы средней шестерни
	for i = 0, 2 do
		local spAngle = (i / 3) * math.pi
		makePart(
			"Gear2_Spoke_" .. i,
			Vector3.new(1.20, 0.16, 0.14),
			CFrame.new(g2_pos) * CFrame.Angles(0, spAngle, 0),
			Enum.Material.Metal,
			g2_dark
		)
	end

	-- Центральная ось средней шестерни (Axle Pin 2)
	makeCylinder("Gear2_AxlePin", 0.20, 0.34, CFrame.new(g2_pos + Vector3.new(0, 0.05, 0)), Enum.Material.Metal, Color3.fromRGB(51, 65, 85))
	makeCylinder("Gear2_CopperWasher", 0.28, 0.06, CFrame.new(g2_pos + Vector3.new(0, 0.11, 0)), Enum.Material.Metal, Color3.fromRGB(217, 119, 6))

	-- =========================================================================
	-- 3. ⚙️ МАЛАЯ ВЕРХНЯЯ ШЕСТЕРНЯ ПРИВОДА (Small Pinion Gear, 6 Зубьев, R = 0.40)
	-- =========================================================================
	local g3_pos = g1_pos + Vector3.new(-0.25, 0.18, -0.22)
	local g3_color = Color3.fromRGB(71, 85, 105) -- Gunmetal / Cast Iron

	makeCylinder("Gear3_Hub", 0.38, 0.16, CFrame.new(g3_pos), Enum.Material.Metal, g3_color)

	local nTeeth3 = 6
	local radius3 = 0.40
	local phase3 = math.rad(15)
	for i = 0, nTeeth3 - 1 do
		local angle = (i / nTeeth3) * (math.pi * 2) + phase3
		local toothCF = CFrame.new(g3_pos) 
			* CFrame.Angles(0, angle, 0) 
			* CFrame.new(0, 0, radius3)
		makePart(
			"Gear3_Tooth_" .. i,
			Vector3.new(0.18, 0.16, 0.20),
			toothCF,
			Enum.Material.Metal,
			g3_color
		)
	end

	-- Верхняя фиксирующая гайка (Lock Nut)
	makePart("Gear3_Nut", Vector3.new(0.24, 0.14, 0.24), CFrame.new(g3_pos + Vector3.new(0, 0.12, 0)), Enum.Material.Metal, Color3.fromRGB(203, 213, 225))

	-- =========================================================================
	-- 4. СВАРКА ВСЕХ ДЕТАЛЕЙ К ЦЕНТРАЛЬНОМУ ОПОРНОМУ ЭЛЕМЕНТУ (WeldConstraint)
	-- =========================================================================
	for _, p in ipairs(model:GetChildren()) do
		if p:IsA("BasePart") and p ~= center then
			local weld = Instance.new("WeldConstraint")
			weld.Name = "Weld_" .. p.Name
			weld.Part0 = center
			weld.Part1 = p
			weld.Parent = p
		end
	end

	if parent then
		model.Parent = parent
	end

	return model
end

return PartsGenerator
