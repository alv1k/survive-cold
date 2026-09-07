--[[
    ReplicatedStorage/GeneratedModels/Parts.luau
    Высокоточный, стилизованный 3D-генератор механической шестерёнки (Drive Pinion Gear):
    - Одиночная компактная приводная шестерня песочного цвета (Warm Sand / Desert Gold)
    - Центральная ступица со спицами и медной шайбой
    - 6 массивных радиальных зубьев
    - Стальная центральная ось и верхняя фиксирующая шестигранная гайка
--]]

local PartsGenerator = {}

function PartsGenerator.create(parent, targetCF)
	targetCF = targetCF or CFrame.new(0, 2.0, 0)
	local model = Instance.new("Model")
	model.Name = "Parts"

	-- Невидимый базовый опорный элемент (Center / Root)
	local center = Instance.new("Part")
	center.Name = "Center"
	center.Size = Vector3.new(1.8, 0.4, 1.8)
	center.CFrame = targetCF * CFrame.new(0, 0.14, 0)
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
	-- ⚙️ ПРИВОДНАЯ ШЕСТЕРНЯ ПЕСОЧНОГО ЦВЕТА (Drive Pinion Gear, R = 0.72)
	-- =========================================================================
	local g_pos = Vector3.new(0, 0.14, 0)
	local sand_color = Color3.fromRGB(226, 194, 139)      -- Теплый песочный (#E2C28B)
	local sand_dark = Color3.fromRGB(195, 160, 105)       -- Глубокий песочный обод (#C3A069)
	local steel_dark = Color3.fromRGB(71, 85, 105)        -- Вороненый металл оси (#475569)
	local steel_light = Color3.fromRGB(203, 213, 225)     -- Шлифованная стальная гайка (#CBD5E1)
	local copper_color = Color3.fromRGB(217, 119, 6)      -- Медная шайба (#D97706)

	-- 1. Центральная ступица (Hub) и внутреннее кольцо
	makeCylinder("Gear_Hub", 0.65, 0.22, CFrame.new(g_pos), Enum.Material.Metal, sand_color)
	makeCylinder("Gear_InnerRim", 0.45, 0.24, CFrame.new(g_pos), Enum.Material.Metal, sand_dark)

	-- 2. 6 Массивных радиальных зубьев (Cogs, 60° шаг)
	local nTeeth = 6
	local radius = 0.72
	for i = 0, nTeeth - 1 do
		local angle = (i / nTeeth) * (math.pi * 2)
		local toothCF = CFrame.new(g_pos) 
			* CFrame.Angles(0, angle, 0) 
			* CFrame.new(0, 0, radius)
		makePart(
			"Gear_Tooth_" .. i,
			Vector3.new(0.26, 0.22, 0.32),
			toothCF,
			Enum.Material.Metal,
			sand_color
		)
	end

	-- 3. 3 Внутренние спицы (Spokes)
	for i = 0, 2 do
		local spAngle = (i / 3) * math.pi
		makePart(
			"Gear_Spoke_" .. i,
			Vector3.new(1.10, 0.18, 0.16),
			CFrame.new(g_pos) * CFrame.Angles(0, spAngle, 0),
			Enum.Material.Metal,
			sand_dark
		)
	end

	-- 4. Центральный стальной штифт / ось (Axle Pin)
	makeCylinder("Gear_AxlePin", 0.24, 0.34, CFrame.new(g_pos + Vector3.new(0, 0.04, 0)), Enum.Material.Metal, steel_dark)

	-- 5. Медная упорная шайба (Copper Washer)
	makeCylinder("Gear_CopperWasher", 0.34, 0.08, CFrame.new(g_pos + Vector3.new(0, 0.10, 0)), Enum.Material.Metal, copper_color)

	-- 6. Верхняя фиксирующая гайка (Lock Nut)
	makePart("Gear_Nut", Vector3.new(0.28, 0.14, 0.28), CFrame.new(g_pos + Vector3.new(0, 0.16, 0)), Enum.Material.Metal, steel_light)

	-- =========================================================================
	-- 7. СВАРКА ВСЕХ ДЕТАЛЕЙ К ЦЕНТРАЛЬНОМУ ОПОРНОМУ ЭЛЕМЕНТУ (WeldConstraint)
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
