--!strict
--[[
    ReplicatedStorage/GeneratedModels/BuildingGenerator.luau
    Универсальный генератор стилизованных 3D-построек сруба для Roblox Studio (Масштаб 1.5x):
    - Фасад, крыльцо, витрины, вывески и двери смотрят ВПЕРЕД (+Z) навстречу игроку
    - Габариты увеличены в 1.5 раза: 24.0 x 22.0 studs, высота 14.0 / 10.5 studs
    - Односкатная крыша с идеальными широкими свесами со всех 4 сторон (без выпирающих стен)
    - 4 типа зданий: "PlayerHouse", "FoodShop", "ClothingShop", "HunterCabin"
--]]

local BuildingGenerator = {}

local PALETTE = {
	wood_honey_oak  = Color3.fromHex("#C68B59"),
	wood_pine       = Color3.fromHex("#E5C39E"),
	wood_cedar      = Color3.fromHex("#8C451A"),
	wood_walnut     = Color3.fromHex("#5C2E0B"),
	wood_bark       = Color3.fromHex("#3E1E08"),
	wood_weathered  = Color3.fromHex("#78716C"),
	wood_burnt      = Color3.fromHex("#292524"),
	wood_birch      = Color3.fromHex("#F7E1D7"),
	stone_dark      = Color3.fromHex("#475569"),
	stone_slate     = Color3.fromHex("#64748B"),
	slate_light     = Color3.fromHex("#E2E8F0"),
	steel_light     = Color3.fromHex("#94A3B8"),
	cast_iron       = Color3.fromHex("#1E293B"),
	gunmetal        = Color3.fromHex("#0F172A"),
	iron_band       = Color3.fromHex("#334155"),
	clay_brick      = Color3.fromHex("#9A3412"),
	twine_straw     = Color3.fromHex("#FEF08A"),
	spark_yellow    = Color3.fromHex("#FDE047"),
	fiber_gold      = Color3.fromHex("#EAB308"),
	crimson_dark    = Color3.fromHex("#991B1B"),
	denim_blue      = Color3.fromHex("#3B82F6"),
	midnight_blue   = Color3.fromHex("#1E1B4B"),
	aqua_bright     = Color3.fromHex("#22D3EE"),
	ice_light       = Color3.fromHex("#BAE6FD"),
	ice_glacier     = Color3.fromHex("#38BDF8"),
	ice_deep        = Color3.fromHex("#0284C7"),
	leather_tan     = Color3.fromHex("#D4A373"),
	leather_warm    = Color3.fromHex("#A16207"),
	meat_steak      = Color3.fromHex("#EF4444"),
	coral_meat      = Color3.fromHex("#FB7185"),
	snow_pure       = Color3.fromHex("#FFFFFF"),
	snow_ambient    = Color3.fromHex("#F0F8FF"),
	fire_core       = Color3.fromHex("#FEF9C3"),
}

local THEMES = {
	PlayerHouse = {
		FoundStone1 = PALETTE.stone_dark,
		FoundStone2 = PALETTE.stone_slate,
		FoundRim = PALETTE.wood_bark,
		FloorPlanks = { PALETTE.wood_pine, PALETTE.wood_honey_oak, PALETTE.wood_pine, PALETTE.wood_honey_oak, PALETTE.wood_birch },
		WallA = PALETTE.wood_honey_oak,
		WallB = PALETTE.wood_cedar,
		Trims = PALETTE.wood_cedar,
		Sill = PALETTE.wood_walnut,
		Crossbars = PALETTE.wood_pine,
		Glass = PALETTE.ice_light,
		Rafters = PALETTE.wood_cedar,
		RoofDeck = PALETTE.wood_walnut,
		RoofBattens = PALETTE.wood_cedar,
		ChimBase = PALETTE.stone_dark,
		ChimFlashing = PALETTE.stone_slate,
		ChimPipe = PALETTE.cast_iron,
		ChimBand = PALETTE.gunmetal,
	},
	FoodShop = {
		FoundStone1 = PALETTE.clay_brick,
		FoundStone2 = PALETTE.stone_dark,
		FoundRim = PALETTE.wood_bark,
		FloorPlanks = { PALETTE.wood_cedar, PALETTE.clay_brick, PALETTE.wood_walnut, PALETTE.wood_cedar, PALETTE.wood_pine },
		WallA = PALETTE.clay_brick,
		WallB = PALETTE.wood_cedar,
		Trims = PALETTE.crimson_dark,
		Sill = PALETTE.wood_walnut,
		Crossbars = PALETTE.wood_pine,
		Glass = PALETTE.ice_light,
		Rafters = PALETTE.crimson_dark,
		RoofDeck = PALETTE.twine_straw,
		RoofBattens = PALETTE.spark_yellow,
		ChimBase = PALETTE.clay_brick,
		ChimFlashing = PALETTE.stone_slate,
		ChimPipe = PALETTE.fiber_gold,
		ChimBand = PALETTE.cast_iron,
	},
	ClothingShop = {
		FoundStone1 = PALETTE.stone_slate,
		FoundStone2 = PALETTE.slate_light,
		FoundRim = PALETTE.wood_bark,
		FloorPlanks = { PALETTE.wood_birch, PALETTE.wood_pine, PALETTE.wood_birch, PALETTE.slate_light, PALETTE.wood_pine },
		WallA = PALETTE.wood_birch,
		WallB = PALETTE.slate_light,
		Trims = PALETTE.wood_bark,
		Sill = PALETTE.slate_light,
		Crossbars = PALETTE.wood_birch,
		Glass = PALETTE.aqua_bright,
		Rafters = PALETTE.midnight_blue,
		RoofDeck = PALETTE.midnight_blue,
		RoofBattens = PALETTE.denim_blue,
		ChimBase = PALETTE.slate_light,
		ChimFlashing = PALETTE.stone_slate,
		ChimPipe = PALETTE.gunmetal,
		ChimBand = PALETTE.steel_light,
	},
	HunterCabin = {
		FoundStone1 = PALETTE.stone_dark,
		FoundStone2 = PALETTE.iron_band,
		FoundRim = PALETTE.wood_burnt,
		FloorPlanks = { PALETTE.wood_weathered, PALETTE.wood_bark, PALETTE.wood_weathered, PALETTE.wood_burnt, PALETTE.wood_weathered },
		WallA = PALETTE.wood_weathered,
		WallB = PALETTE.wood_bark,
		Trims = PALETTE.wood_bark,
		Sill = PALETTE.wood_burnt,
		Crossbars = PALETTE.wood_weathered,
		Glass = PALETTE.ice_deep,
		Rafters = PALETTE.wood_burnt,
		RoofDeck = PALETTE.wood_burnt,
		RoofBattens = PALETTE.wood_bark,
		ChimBase = PALETTE.stone_dark,
		ChimFlashing = PALETTE.iron_band,
		ChimPipe = PALETTE.cast_iron,
		ChimBand = PALETTE.iron_band,
	}
}

-- Размеры сруба (Масштаб 1.5x)
local W_X = 24.0          -- Ширина по X
local D_Z = 22.0          -- Глубина по Z (От -11.0 сзади до +11.0 спереди)
local H_FRONT = 14.0      -- Высота фасада спереди (+Z)
local H_BACK = 10.5       -- Высота задней стены (-Z)
local FLOOR_Y = 0.6       -- Высота чистого пола над корнем модели
local BEAM_H = 0.70       -- Высота одного венца бруса
local BEAM_T = 0.85       -- Толщина стены

function BuildingGenerator.createBuilding(buildingType: string, rootCFrame: CFrame, parent: Instance?): Model
	local theme = THEMES[buildingType] or THEMES.PlayerHouse
	local model = Instance.new("Model")
	model.Name = buildingType

	local function addPart(name: string, size: Vector3, offsetCF: CFrame, color: Color3, material: Enum.Material?, canCollide: boolean?): Part
		local p = Instance.new("Part")
		p.Name = name
		p.Size = size
		p.CFrame = rootCFrame * offsetCF
		p.Color = color
		p.Material = material or Enum.Material.SmoothPlastic
		p.Anchored = true
		p.CanCollide = (canCollide ~= false)
		p.CastShadow = true
		p.Parent = model
		return p
	end

	local function addCylinder(name: string, radius: number, height: number, offsetCF: CFrame, color: Color3, material: Enum.Material?): Part
		local p = Instance.new("Part")
		p.Name = name
		p.Shape = Enum.PartType.Cylinder
		p.Size = Vector3.new(height, radius * 2, radius * 2)
		p.CFrame = rootCFrame * offsetCF * CFrame.Angles(0, 0, math.rad(90))
		p.Color = color
		p.Material = material or Enum.Material.SmoothPlastic
		p.Anchored = true
		p.CanCollide = false
		p.CastShadow = true
		p.Parent = model
		return p
	end

	local function addWedge(name: string, size: Vector3, offsetCF: CFrame, color: Color3, material: Enum.Material?): WedgePart
		local p = Instance.new("WedgePart")
		p.Name = name
		p.Size = size
		p.CFrame = rootCFrame * offsetCF
		p.Color = color
		p.Material = material or Enum.Material.SmoothPlastic
		p.Anchored = true
		p.CanCollide = true
		p.CastShadow = true
		p.Parent = model
		return p
	end

	-- =========================================================================
	-- 1. ФУНДАМЕНТ (6 Массивных каменных тумб и обвязочный брус)
	-- =========================================================================
	local halfX = W_X / 2.0  -- 12.0
	local halfZ = D_Z / 2.0  -- 11.0

	local corners = {
		Vector2.new(-halfX, -halfZ), Vector2.new(halfX, -halfZ),
		Vector2.new(-halfX, halfZ),  Vector2.new(halfX, halfZ),
		Vector2.new(0.0, -halfZ),    Vector2.new(0.0, halfZ)
	}
	for _, c in ipairs(corners) do
		addPart("FoundBlock", Vector3.new(2.6, 0.6, 2.6), CFrame.new(c.X, 0.3, c.Y), theme.FoundStone1, Enum.Material.Slate)
		addPart("FoundBase", Vector3.new(3.0, 0.25, 3.0), CFrame.new(c.X, 0.12, c.Y), theme.FoundStone2, Enum.Material.Slate)
	end

	-- Нижние обвязочные балки
	addPart("RimFront", Vector3.new(W_X + 2.0, 0.6, 1.1), CFrame.new(0, 0.45, halfZ), theme.FoundRim, Enum.Material.Wood)
	addPart("RimBack", Vector3.new(W_X + 2.0, 0.6, 1.1), CFrame.new(0, 0.45, -halfZ), theme.FoundRim, Enum.Material.Wood)
	addPart("RimLeft", Vector3.new(1.1, 0.6, D_Z), CFrame.new(-halfX, 0.45, 0), theme.FoundRim, Enum.Material.Wood)
	addPart("RimRight", Vector3.new(1.1, 0.6, D_Z), CFrame.new(halfX, 0.45, 0), theme.FoundRim, Enum.Material.Wood)

	-- =========================================================================
	-- 2. ДОЩАТЫЙ ПОЛ (18 Продольных массивных деревянных половиц)
	-- =========================================================================
	local numPlanks = 18
	local plankWidth = (W_X - 1.8) / numPlanks
	local floorLen = D_Z - 1.6
	local floorParts = {}
	for i = 1, numPlanks do
		local px = - (W_X - 1.8) / 2.0 + (i - 0.5) * plankWidth
		local col = theme.FloorPlanks[((i - 1) % #theme.FloorPlanks) + 1]
		local jitterZ = ((i - 1) % 3) * 0.015
		local plank = addPart("FloorPlank_" .. i, Vector3.new(plankWidth - 0.05, 0.18, floorLen), CFrame.new(px, FLOOR_Y - 0.05 + jitterZ, 0), col, Enum.Material.WoodPlanks)
		table.insert(floorParts, plank)
	end

	-- =========================================================================
	-- 3. ЗАДНЯЯ СТЕНА (at Z = -halfZ, сплошная, высота до H_BACK = 10.5)
	-- =========================================================================
	local zCur = FLOOR_Y + BEAM_H / 2.0
	local layer = 0
	while zCur < H_BACK do
		local col = (layer % 2 == 0) and theme.WallA or theme.WallB
		addPart("WallBackBeam", Vector3.new(W_X + 2.0, BEAM_H - 0.02, BEAM_T), CFrame.new(0, zCur, -halfZ), col, Enum.Material.Wood)
		zCur += BEAM_H
		layer += 1
	end

	-- =========================================================================
	-- 4. ПЕРЕДНИЙ ФАСАД (at Z = +halfZ, Дверной проем X in [-6.4, -1.2] и Окно 1 X in [3.6, 9.2])
	-- =========================================================================
	local doorX_Min, doorX_Max = -6.4, -1.2
	local win1_X_Min, win1_X_Max = 3.6, 9.2
	local win_Y_Bot, win_Y_Top = 3.6, 8.2
	local door_Y_Top = 9.4

	zCur = FLOOR_Y + BEAM_H / 2.0
	layer = 0
	while zCur < H_FRONT do
		local col = (layer % 2 == 0) and theme.WallA or theme.WallB

		if zCur < win_Y_Bot then
			-- Ниже подоконника: Стена слева, простенок между дверью и окном, стена справа
			-- Слева: [-12.0, -6.4] -> Center = -9.2, Width = 5.6
			addPart("WallFrontLeft", Vector3.new(5.6, BEAM_H - 0.02, BEAM_T), CFrame.new(-9.2, zCur, halfZ), col, Enum.Material.Wood)
			-- Справа (включая под окном): [-1.2, 12.0] -> Center = 5.4, Width = 13.2
			addPart("WallFrontRight", Vector3.new(13.2, BEAM_H - 0.02, BEAM_T), CFrame.new(5.4, zCur, halfZ), col, Enum.Material.Wood)

		elseif zCur < win_Y_Top then
			-- На уровне окна и двери:
			-- Слева от двери: [-12.0, -6.4] -> Center = -9.2, Width = 5.6
			addPart("WallFrontPillarL", Vector3.new(5.6, BEAM_H - 0.02, BEAM_T), CFrame.new(-9.2, zCur, halfZ), col, Enum.Material.Wood)
			-- Между дверью и окном: [-1.2, 3.6] -> Center = 1.2, Width = 4.8
			addPart("WallFrontPierMid", Vector3.new(4.8, BEAM_H - 0.02, BEAM_T), CFrame.new(1.2, zCur, halfZ), col, Enum.Material.Wood)
			-- Справа от окна: [9.2, 12.0] -> Center = 10.6, Width = 2.8
			addPart("WallFrontPierRight", Vector3.new(2.8, BEAM_H - 0.02, BEAM_T), CFrame.new(10.6, zCur, halfZ), col, Enum.Material.Wood)

		elseif zCur < door_Y_Top then
			-- Выше окна, но ниже верха двери:
			-- Слева от двери: [-12.0, -6.4] -> Center = -9.2, Width = 5.6
			addPart("WallFrontLeft", Vector3.new(5.6, BEAM_H - 0.02, BEAM_T), CFrame.new(-9.2, zCur, halfZ), col, Enum.Material.Wood)
			-- Справа от двери над окном: [-1.2, 12.0] -> Center = 5.4, Width = 13.2
			addPart("WallFrontRight", Vector3.new(13.2, BEAM_H - 0.02, BEAM_T), CFrame.new(5.4, zCur, halfZ), col, Enum.Material.Wood)

		else
			-- Сплошная перемычка над дверью и окном до самого карниза H_FRONT
			addPart("WallFrontTopLintel", Vector3.new(W_X + 2.0, BEAM_H - 0.02, BEAM_T), CFrame.new(0, zCur, halfZ), col, Enum.Material.Wood)
		end

		zCur += BEAM_H
		layer += 1
	end

	-- =========================================================================
	-- 5. БОКОВЫЕ СТЕНЫ (Левая с Окном 2 в Z in [-2.8, 2.8], Правая сплошная)
	-- =========================================================================
	zCur = FLOOR_Y + BEAM_H / 2.0
	layer = 0
	while zCur < H_BACK do
		local col = (layer % 2 == 0) and theme.WallA or theme.WallB
		if zCur >= win_Y_Bot and zCur <= win_Y_Top then
			-- Левая стена с окном: Часть сзади [-11.0, -2.8], Часть спереди [2.8, 11.0]
			-- Back section: Center = -6.9, Len = 8.2
			addPart("WallSideL_Back", Vector3.new(BEAM_T, BEAM_H - 0.02, 8.2), CFrame.new(-halfX, zCur, -6.9), col, Enum.Material.Wood)
			-- Front section: Center = 6.9, Len = 8.2
			addPart("WallSideL_Front", Vector3.new(BEAM_T, BEAM_H - 0.02, 8.2), CFrame.new(-halfX, zCur, 6.9), col, Enum.Material.Wood)
		else
			addPart("WallSideL", Vector3.new(BEAM_T, BEAM_H - 0.02, D_Z + 2.0), CFrame.new(-halfX, zCur, 0), col, Enum.Material.Wood)
		end
		addPart("WallSideR", Vector3.new(BEAM_T, BEAM_H - 0.02, D_Z + 2.0), CFrame.new(halfX, zCur, 0), col, Enum.Material.Wood)

		zCur += BEAM_H
		layer += 1
	end

	-- Скошенные фронтонные треугольники (Gables) для закрытия треугольного зазора под односкатной крышей
	local gableH = H_FRONT - H_BACK -- 3.5
	local gableL = D_Z             -- 22.0
	local gableMidY = H_BACK + gableH / 2.0 -- 12.25

	-- В Roblox WedgePart скос идет от -Z (низ) к +Z (верх). Центр (0,0,0) совпадает идеально!
	addWedge("GableL", Vector3.new(BEAM_T, gableH, gableL), CFrame.new(-halfX, gableMidY, 0), theme.WallB, Enum.Material.Wood)
	addWedge("GableR", Vector3.new(BEAM_T, gableH, gableL), CFrame.new(halfX, gableMidY, 0), theme.WallB, Enum.Material.Wood)

	-- =========================================================================
	-- 6. ДВЕРНОЙ ПРОЕМ И СТУПЕНИ СМОТРЯТ ВПЕРЕД (+Z)
	-- =========================================================================
	local doorCenter_X = (doorX_Min + doorX_Max) / 2.0  -- -3.8
	local doorWidth = doorX_Max - doorX_Min             -- 5.2
	local doorHeight = door_Y_Top                       -- 9.4

	-- Косяки и притолока двери
	addPart("DoorPostL", Vector3.new(0.55, doorHeight - FLOOR_Y, 1.2), CFrame.new(doorX_Min - 0.15, (FLOOR_Y + doorHeight) / 2.0, halfZ), theme.Trims, Enum.Material.Wood)
	addPart("DoorPostR", Vector3.new(0.55, doorHeight - FLOOR_Y, 1.2), CFrame.new(doorX_Max + 0.15, (FLOOR_Y + doorHeight) / 2.0, halfZ), theme.Trims, Enum.Material.Wood)
	addPart("DoorLintel", Vector3.new(doorWidth + 1.2, 0.6, 1.3), CFrame.new(doorCenter_X, doorHeight + 0.25, halfZ), theme.Trims, Enum.Material.Wood)

	-- Массивные деревянные ступени на улицу (+Z)
	addPart("DoorStep1", Vector3.new(doorWidth + 1.2, 0.35, 1.4), CFrame.new(doorCenter_X, FLOOR_Y - 0.15, halfZ + 0.8), theme.Sill, Enum.Material.Wood)
	addPart("DoorStep2", Vector3.new(doorWidth + 1.8, 0.32, 1.4), CFrame.new(doorCenter_X, FLOOR_Y - 0.42, halfZ + 1.9), theme.Trims, Enum.Material.Wood)

	-- =========================================================================
	-- 7. ДВА СТЕКЛЯННЫХ ОКНА С КРЕСТООБРАЗНОЙ РАСКЛАДКОЙ
	-- =========================================================================
	-- Окно 1: На главном фасаде (+Z)
	local w1_x = (win1_X_Min + win1_X_Max) / 2.0  -- 6.4
	local w1_y = (win_Y_Bot + win_Y_Top) / 2.0    -- 5.9
	local w1_w = win1_X_Max - win1_X_Min          -- 5.6
	local w1_h = win_Y_Top - win_Y_Bot            -- 4.6

	addPart("W1_Top", Vector3.new(w1_w + 0.8, 0.35, 1.2), CFrame.new(w1_x, w1_y + w1_h/2.0 + 0.15, halfZ), theme.Trims, Enum.Material.Wood)
	addPart("W1_Sill", Vector3.new(w1_w + 1.0, 0.45, 1.6), CFrame.new(w1_x, w1_y - w1_h/2.0 - 0.18, halfZ + 0.15), theme.Sill, Enum.Material.Wood)
	addPart("W1_PostL", Vector3.new(0.35, w1_h, 1.2), CFrame.new(w1_x - w1_w/2.0 - 0.15, w1_y, halfZ), theme.Trims, Enum.Material.Wood)
	addPart("W1_PostR", Vector3.new(0.35, w1_h, 1.2), CFrame.new(w1_x + w1_w/2.0 + 0.15, w1_y, halfZ), theme.Trims, Enum.Material.Wood)
	addPart("W1_CrossV", Vector3.new(0.22, w1_h, 0.9), CFrame.new(w1_x, w1_y, halfZ), theme.Crossbars, Enum.Material.Wood)
	addPart("W1_CrossH", Vector3.new(w1_w, 0.22, 0.9), CFrame.new(w1_x, w1_y, halfZ), theme.Crossbars, Enum.Material.Wood)
	local g1 = addPart("W1_Glass", Vector3.new(w1_w - 0.08, w1_h - 0.08, 0.12), CFrame.new(w1_x, w1_y, halfZ), theme.Glass, Enum.Material.Glass, false)
	g1.Transparency = 0.35

	-- Окно 2: На левой стене (X = -halfX)
	local w2_z = 0.0
	local w2_y = w1_y
	local w2_w = 5.6
	local w2_h = w1_h

	addPart("W2_Top", Vector3.new(1.2, 0.35, w2_w + 0.8), CFrame.new(-halfX, w2_y + w2_h/2.0 + 0.15, w2_z), theme.Trims, Enum.Material.Wood)
	addPart("W2_Sill", Vector3.new(1.6, 0.45, w2_w + 1.0), CFrame.new(-halfX - 0.15, w2_y - w2_h/2.0 - 0.18, w2_z), theme.Sill, Enum.Material.Wood)
	addPart("W2_PostF", Vector3.new(1.2, w2_h, 0.35), CFrame.new(-halfX, w2_y, w2_z - w2_w/2.0 - 0.15), theme.Trims, Enum.Material.Wood)
	addPart("W2_PostB", Vector3.new(1.2, w2_h, 0.35), CFrame.new(-halfX, w2_y, w2_z + w2_w/2.0 + 0.15), theme.Trims, Enum.Material.Wood)
	addPart("W2_CrossV", Vector3.new(0.9, w2_h, 0.22), CFrame.new(-halfX, w2_y, w2_z), theme.Crossbars, Enum.Material.Wood)
	addPart("W2_CrossH", Vector3.new(0.9, 0.22, w2_w), CFrame.new(-halfX, w2_y, w2_z), theme.Crossbars, Enum.Material.Wood)
	local g2 = addPart("W2_Glass", Vector3.new(0.12, w2_h - 0.08, w2_w - 0.08), CFrame.new(-halfX, w2_y, w2_z), theme.Glass, Enum.Material.Glass, false)
	g2.Transparency = 0.35

	-- =========================================================================
	-- 8. ОДНОСКАТНАЯ КРЫША С БОЛЬШИМИ СВЕСАМИ (Полностью закрывает все стены)
	-- =========================================================================
	-- Крыша имеет свес 2.0 studs по бокам, и 2.5 studs спереди (+Z) и сзади (-Z)
	local roofWidth = W_X + 4.0      -- 28.0 studs
	local roofDepthZ = D_Z + 5.0     -- 27.0 studs
	local roofMidY = (H_FRONT + H_BACK) / 2.0 + 0.45 -- 12.70
	local slopeAngle = - math.atan((H_FRONT - H_BACK) / D_Z) -- Около -9.04 градусов
	local slopeLength = math.sqrt(roofDepthZ * roofDepthZ + (H_FRONT - H_BACK) * (H_FRONT - H_BACK)) -- ~27.22 studs

	local roofSlopeCF = CFrame.new(0, roofMidY, 0) * CFrame.Angles(slopeAngle, 0, 0)

	-- 7 Стропильных массивных балок под настилом
	local rafterSpacing = roofWidth / 6.0
	for r = 0, 6 do
		local rx = - roofWidth / 2.0 + r * rafterSpacing
		addPart("Rafter_" .. r, Vector3.new(0.65, 0.6, slopeLength - 0.2), roofSlopeCF * CFrame.new(rx, -0.32, 0), theme.Rafters, Enum.Material.Wood)
	end

	-- Сплошной деревянный настил крыши
	local roofMain = addPart("RoofDeck", Vector3.new(roofWidth, 0.45, slopeLength), roofSlopeCF * CFrame.new(0, 0.22, 0), theme.RoofDeck, Enum.Material.WoodPlanks)
	roofMain.CanQuery = false

	-- 11 Продольных реек-нащельников
	for b = 1, 11 do
		local bx = - roofWidth / 2.0 + (b - 0.5) * (roofWidth / 11.0)
		addPart("RoofBatten_" .. b, Vector3.new(0.32, 0.22, slopeLength + 0.2), roofSlopeCF * CFrame.new(bx, 0.55, 0), theme.RoofBattens, Enum.Material.Wood)
	end

	-- Торцевые ветровые доски (Fascia) по левому и правому краю
	addPart("FasciaLeft", Vector3.new(0.38, 0.85, slopeLength + 0.4), roofSlopeCF * CFrame.new(-roofWidth/2.0 - 0.19, 0.12, 0), theme.Rafters, Enum.Material.Wood)
	addPart("FasciaRight", Vector3.new(0.38, 0.85, slopeLength + 0.4), roofSlopeCF * CFrame.new(roofWidth/2.0 + 0.19, 0.12, 0), theme.Rafters, Enum.Material.Wood)

	-- =========================================================================
	-- 9. ТРУБА ДЛЯ ПЕЧКИ (Masonry Base + Stovepipe with Spark Cap)
	-- =========================================================================
	local chimX = -7.5
	local chimZ = -5.0
	-- Высота крыши в точке трубы:
	local chimRoofY = roofMidY - chimZ * math.tan(-slopeAngle) -- ~11.90

	addPart("ChimBase", Vector3.new(2.4, 2.6, 2.4), CFrame.new(chimX, chimRoofY + 1.2, chimZ), theme.ChimBase, Enum.Material.Cobblestone)
	addPart("ChimFlashing", Vector3.new(2.8, 0.35, 2.8), CFrame.new(chimX, chimRoofY + 0.25, chimZ), theme.ChimFlashing, Enum.Material.Slate)
	addPart("ChimCrown", Vector3.new(2.6, 0.30, 2.6), CFrame.new(chimX, chimRoofY + 2.5, chimZ), theme.ChimFlashing, Enum.Material.Slate)
	addCylinder("ChimPipe", 0.65, 3.2, CFrame.new(chimX, chimRoofY + 4.1, chimZ), theme.ChimPipe, Enum.Material.Metal)
	addCylinder("ChimBand", 0.72, 0.28, CFrame.new(chimX, chimRoofY + 5.2, chimZ), theme.ChimBand, Enum.Material.Metal)
	addCylinder("ChimCap", 1.15, 0.22, CFrame.new(chimX, chimRoofY + 5.8, chimZ), theme.ChimPipe, Enum.Material.Metal)

	-- =========================================================================
	-- 10. УНИКАЛЬНЫЙ ДЕКОР И ПРИСТРОЙКИ ФАСАДА (+Z)
	-- =========================================================================
	if buildingType == "PlayerHouse" then
		-- 🏡 ДОМ ИГРОКА: Крытое крыльцо с фонарем, поленница дров, почтовый ящик
		local pX1, pX2 = doorX_Min - 0.6, doorX_Max + 0.6 -- [-7.0, -0.6]
		local pZ = halfZ + 3.8

		-- Опорные столбы крыльца
		addPart("PorchPost1", Vector3.new(0.6, 8.5, 0.6), CFrame.new(pX1, 4.25, pZ), PALETTE.wood_cedar, Enum.Material.Wood)
		addPart("PorchPost2", Vector3.new(0.6, 8.5, 0.6), CFrame.new(pX2, 4.25, pZ), PALETTE.wood_cedar, Enum.Material.Wood)
		addPart("PorchBeam", Vector3.new(pX2 - pX1 + 0.9, 0.55, 0.6), CFrame.new((pX1 + pX2)/2.0, 8.4, pZ), PALETTE.wood_cedar, Enum.Material.Wood)

		-- Перила крыльца
		addPart("PorchRailL1", Vector3.new(0.35, 0.22, 3.6), CFrame.new(pX1, 2.4, halfZ + 1.8), PALETTE.wood_pine, Enum.Material.Wood)
		addPart("PorchRailL2", Vector3.new(0.35, 0.22, 3.6), CFrame.new(pX1, 1.2, halfZ + 1.8), PALETTE.wood_pine, Enum.Material.Wood)
		addPart("PorchRailR1", Vector3.new(0.35, 0.22, 3.6), CFrame.new(pX2, 2.4, halfZ + 1.8), PALETTE.wood_pine, Enum.Material.Wood)
		addPart("PorchRailR2", Vector3.new(0.35, 0.22, 3.6), CFrame.new(pX2, 1.2, halfZ + 1.8), PALETTE.wood_pine, Enum.Material.Wood)

		-- Навес крыльца (скашивается вперед к +Z)
		local pCanopyLen = 4.2
		local pCanopyAng = math.rad(-14)
		local pCanopyCF = CFrame.new((pX1 + pX2)/2.0, 9.0, halfZ + 1.9) * CFrame.Angles(pCanopyAng, 0, 0)
		addPart("PorchCanopy", Vector3.new(pX2 - pX1 + 1.2, 0.35, pCanopyLen), pCanopyCF, PALETTE.wood_walnut, Enum.Material.WoodPlanks)

		-- Светящийся фонарь у входа
		local lanternGlow = addPart("LanternGlow", Vector3.new(0.55, 0.7, 0.55), CFrame.new(pX2 + 0.2, 6.8, pZ - 0.4), PALETTE.fire_core, Enum.Material.Neon, false)
		local pLight = Instance.new("PointLight", lanternGlow)
		pLight.Color = Color3.fromRGB(255, 200, 100)
		pLight.Brightness = 1.4
		pLight.Range = 24

		-- Дровяная поленница берёзовых поленьев справа от входа
		for r = 0, 2 do
			for c = 0, 6 do
				local wx = 3.8 + c * 0.95
				local wy = 0.5 + r * 0.7
				local col = ((r + c) % 2 == 0) and PALETTE.wood_birch or PALETTE.wood_pine
				addCylinder("FirewoodLog", 0.30, 1.4, CFrame.new(wx, wy, halfZ + 1.0) * CFrame.Angles(math.rad(90), 0, 0), col, Enum.Material.Wood)
			end
		end

		-- Почтовый ящик выжившего
		addPart("MailboxPost", Vector3.new(0.25, 3.2, 0.25), CFrame.new(-8.5, 1.6, halfZ + 4.2), PALETTE.wood_bark, Enum.Material.Wood)
		addPart("MailboxBox", Vector3.new(0.7, 0.7, 1.0), CFrame.new(-8.5, 3.2, halfZ + 4.2), PALETTE.wood_cedar, Enum.Material.Wood)

	elseif buildingType == "FoodShop" then
		-- 🍞 ПРОДУКТОВАЯ ЛАВКА: Торговый прилавок на фасаде (+Z), навес, ящики, бочки
		addPart("CounterTop", Vector3.new(6.0, 0.35, 1.8), CFrame.new(6.4, 2.8, halfZ + 1.4), PALETTE.wood_walnut, Enum.Material.Wood)
		addPart("CounterLegL", Vector3.new(0.45, 2.8, 1.5), CFrame.new(3.8, 1.4, halfZ + 1.4), PALETTE.wood_cedar, Enum.Material.Wood)
		addPart("CounterLegR", Vector3.new(0.45, 2.8, 1.5), CFrame.new(9.0, 1.4, halfZ + 1.4), PALETTE.wood_cedar, Enum.Material.Wood)

		-- Полосатый тканевый навес над прилавком
		local aSlopeCF = CFrame.new(6.4, 7.8, halfZ + 2.0) * CFrame.Angles(math.rad(-18), 0, 0)
		addPart("AwningDeck", Vector3.new(6.8, 0.22, 4.4), aSlopeCF, PALETTE.twine_straw, Enum.Material.Fabric)
		for _, sx in ipairs({ 3.8, 5.5, 7.3, 9.0 }) do
			addPart("AwningStripe", Vector3.new(0.75, 0.25, 4.45), aSlopeCF * CFrame.new(sx - 6.4, 0.02, 0), PALETTE.crimson_dark, Enum.Material.Fabric)
		end
		addPart("AwningPostL", Vector3.new(0.32, 6.5, 0.32), CFrame.new(3.3, 3.25, halfZ + 3.8), PALETTE.wood_bark, Enum.Material.Wood)
		addPart("AwningPostR", Vector3.new(0.32, 6.5, 0.32), CFrame.new(9.5, 3.25, halfZ + 3.8), PALETTE.wood_bark, Enum.Material.Wood)

		-- Ящики с припасами на прилавке
		addPart("FishCrate", Vector3.new(1.8, 0.6, 1.2), CFrame.new(4.8, 3.3, halfZ + 1.4), PALETTE.wood_pine, Enum.Material.Wood)
		addPart("FishItem", Vector3.new(1.4, 0.3, 0.9), CFrame.new(4.8, 3.5, halfZ + 1.4), PALETTE.ice_glacier, Enum.Material.Ice)
		addPart("BreadCrate", Vector3.new(1.8, 0.6, 1.2), CFrame.new(7.8, 3.3, halfZ + 1.4), PALETTE.wood_pine, Enum.Material.Wood)
		addPart("BreadItem", Vector3.new(1.4, 0.45, 0.9), CFrame.new(7.8, 3.6, halfZ + 1.4), PALETTE.spark_yellow, Enum.Material.SmoothPlastic)

		-- Дубовые бочки
		addCylinder("OakBarrel", 0.9, 2.6, CFrame.new(10.8, 1.4, halfZ + 1.2), PALETTE.wood_bark, Enum.Material.Wood)
		addCylinder("BarrelHoop1", 0.95, 0.18, CFrame.new(10.8, 2.2, halfZ + 1.2), PALETTE.iron_band, Enum.Material.Metal)
		addCylinder("BarrelHoop2", 0.95, 0.18, CFrame.new(10.8, 0.6, halfZ + 1.2), PALETTE.iron_band, Enum.Material.Metal)

		-- Мешки с зерном
		addPart("GrainSack1", Vector3.new(1.1, 1.6, 1.1), CFrame.new(9.5, 0.9, halfZ + 1.8) * CFrame.Angles(0, 0, math.rad(18)), PALETTE.leather_tan, Enum.Material.Fabric)

		-- Вывеска магазина
		addPart("ShopSignBracket", Vector3.new(0.18, 0.18, 1.4), CFrame.new(-3.8, 9.6, halfZ + 0.7), PALETTE.cast_iron, Enum.Material.Metal)
		addPart("ShopSignBoard", Vector3.new(0.15, 1.1, 2.0), CFrame.new(-3.8, 8.8, halfZ + 1.4), PALETTE.wood_walnut, Enum.Material.Wood)
		addPart("ShopSignEmblem", Vector3.new(0.20, 0.6, 1.2), CFrame.new(-3.8, 8.8, halfZ + 1.4), PALETTE.spark_yellow, Enum.Material.Neon, false)

	elseif buildingType == "ClothingShop" then
		-- 🧥 МАСТЕРСКАЯ ОДЕЖДЫ: Стойка сушки шкур на фасаде (+Z), манекен с паркой, рулоны ткани
		addPart("FramePostL", Vector3.new(0.32, 7.0, 0.32), CFrame.new(7.0, 3.5, halfZ + 1.4) * CFrame.Angles(0, 0, math.rad(-10)), PALETTE.wood_bark, Enum.Material.Wood)
		addPart("FramePostR", Vector3.new(0.32, 7.0, 0.32), CFrame.new(10.0, 3.5, halfZ + 1.4) * CFrame.Angles(0, 0, math.rad(10)), PALETTE.wood_bark, Enum.Material.Wood)
		addPart("FrameBarTop", Vector3.new(3.6, 0.28, 0.28), CFrame.new(8.5, 6.2, halfZ + 1.4), PALETTE.wood_bark, Enum.Material.Wood)
		addPart("FrameBarBot", Vector3.new(3.6, 0.28, 0.28), CFrame.new(8.5, 1.2, halfZ + 1.4), PALETTE.wood_bark, Enum.Material.Wood)
		addPart("StretchedPelt", Vector3.new(2.4, 4.0, 0.14), CFrame.new(8.5, 3.7, halfZ + 1.4), PALETTE.leather_tan, Enum.Material.Fabric)
		addPart("PeltFurInner", Vector3.new(1.6, 3.0, 0.16), CFrame.new(8.5, 3.7, halfZ + 1.4), PALETTE.snow_ambient, Enum.Material.Fabric)

		-- Манекен с теплой зимней паркой
		addPart("DummyBase", Vector3.new(1.6, 0.25, 1.6), CFrame.new(-8.5, 0.25, halfZ + 1.4), PALETTE.wood_bark, Enum.Material.Wood)
		addCylinder("DummyPole", 0.16, 4.5, CFrame.new(-8.5, 2.4, halfZ + 1.4), PALETTE.wood_cedar, Enum.Material.Wood)
		addPart("WinterCoatBody", Vector3.new(1.9, 2.4, 1.1), CFrame.new(-8.5, 3.6, halfZ + 1.4), PALETTE.midnight_blue, Enum.Material.Fabric)
		addPart("FurCollar", Vector3.new(1.4, 0.6, 1.2), CFrame.new(-8.5, 4.7, halfZ + 1.4), PALETTE.snow_pure, Enum.Material.Fabric)

		-- Рулоны шерсти и сукна
		addCylinder("ClothRoll1", 0.35, 2.0, CFrame.new(-1.2, 0.8, halfZ + 1.0), PALETTE.denim_blue, Enum.Material.Fabric)
		addCylinder("ClothRoll2", 0.35, 2.0, CFrame.new(-0.5, 0.8, halfZ + 1.0), PALETTE.slate_light, Enum.Material.Fabric)
		addCylinder("ClothRoll3", 0.30, 1.8, CFrame.new(-0.9, 2.1, halfZ + 1.0), PALETTE.midnight_blue, Enum.Material.Fabric)

		-- Вывеска
		addPart("ShopSignBracket", Vector3.new(0.18, 0.18, 1.4), CFrame.new(-3.8, 9.6, halfZ + 0.7), PALETTE.cast_iron, Enum.Material.Metal)
		addPart("ShopSignBoard", Vector3.new(0.15, 1.1, 2.0), CFrame.new(-3.8, 8.8, halfZ + 1.4), PALETTE.slate_light, Enum.Material.Wood)
		addPart("ShopSignEmblem", Vector3.new(0.20, 0.6, 1.2), CFrame.new(-3.8, 8.8, halfZ + 1.4), PALETTE.denim_blue, Enum.Material.Neon, false)

	elseif buildingType == "HunterCabin" then
		-- 🏹 ОХОТНИЧЬЯ ЗАИМКА: Рога оленя над входом (+Z), стойка вяления мяса, колода с топором
		addPart("AntlerShield", Vector3.new(0.8, 0.55, 0.35), CFrame.new(doorCenter_X, 10.2, halfZ + 0.6), PALETTE.wood_bark, Enum.Material.Wood)
		addPart("AntlerL1", Vector3.new(0.24, 1.4, 0.24), CFrame.new(doorCenter_X - 0.8, 11.0, halfZ + 0.7) * CFrame.Angles(0, 0, math.rad(30)), PALETTE.wood_birch, Enum.Material.Wood)
		addPart("AntlerL2", Vector3.new(0.18, 1.0, 0.18), CFrame.new(doorCenter_X - 1.4, 11.8, halfZ + 0.7) * CFrame.Angles(0, 0, math.rad(60)), PALETTE.wood_birch, Enum.Material.Wood)
		addPart("AntlerR1", Vector3.new(0.24, 1.4, 0.24), CFrame.new(doorCenter_X + 0.8, 11.0, halfZ + 0.7) * CFrame.Angles(0, 0, math.rad(-30)), PALETTE.wood_birch, Enum.Material.Wood)
		addPart("AntlerR2", Vector3.new(0.18, 1.0, 0.18), CFrame.new(doorCenter_X + 1.4, 11.8, halfZ + 0.7) * CFrame.Angles(0, 0, math.rad(-60)), PALETTE.wood_birch, Enum.Material.Wood)

		-- Стойка вяления мяса и рыбы на фасаде (+Z)
		addPart("SmokerPostL", Vector3.new(0.28, 5.2, 0.28), CFrame.new(5.0, 2.6, halfZ + 1.4) * CFrame.Angles(0, 0, math.rad(-8)), PALETTE.wood_burnt, Enum.Material.Wood)
		addPart("SmokerPostR", Vector3.new(0.28, 5.2, 0.28), CFrame.new(9.2, 2.6, halfZ + 1.4) * CFrame.Angles(0, 0, math.rad(8)), PALETTE.wood_burnt, Enum.Material.Wood)
		addPart("SmokerBarTop", Vector3.new(4.6, 0.24, 0.24), CFrame.new(7.1, 4.8, halfZ + 1.4), PALETTE.wood_burnt, Enum.Material.Wood)
		addPart("SmokerBarBot", Vector3.new(4.6, 0.24, 0.24), CFrame.new(7.1, 3.2, halfZ + 1.4), PALETTE.wood_burnt, Enum.Material.Wood)
		for _, mx in ipairs({ 5.8, 6.7, 7.6, 8.4 }) do
			addPart("SmokedMeat", Vector3.new(0.18, 1.2, 0.18), CFrame.new(mx, 3.9, halfZ + 1.4), PALETTE.meat_steak, Enum.Material.SmoothPlastic)
			addPart("SmokedFish", Vector3.new(0.20, 1.1, 0.20), CFrame.new(mx + 0.3, 2.3, halfZ + 1.4), PALETTE.coral_meat, Enum.Material.SmoothPlastic)
		end

		-- Колода с воткнутым топором
		addCylinder("WoodBlock", 0.9, 1.8, CFrame.new(-8.5, 0.9, halfZ + 1.4), PALETTE.wood_bark, Enum.Material.Wood)
		addPart("AxeHandle", Vector3.new(0.16, 1.8, 0.24), CFrame.new(-8.5, 2.4, halfZ + 1.4) * CFrame.Angles(0, 0, math.rad(-20)), PALETTE.wood_pine, Enum.Material.Wood)
		addPart("AxeHead", Vector3.new(0.18, 0.55, 0.7), CFrame.new(-8.4, 2.0, halfZ + 1.4) * CFrame.Angles(0, 0, math.rad(-20)), PALETTE.iron_band, Enum.Material.Metal)

		-- Охотничье копье у стены
		addCylinder("HunterSpearShaft", 0.09, 6.8, CFrame.new(-1.0, 3.5, halfZ + 0.6), PALETTE.wood_pine, Enum.Material.Wood)
		addPart("HunterSpearBlade", Vector3.new(0.08, 0.9, 0.26), CFrame.new(-1.0, 6.8, halfZ + 0.6), PALETTE.iron_band, Enum.Material.Metal)
	end

	-- Назначение PrimaryPart
	model.PrimaryPart = floorParts[1] or model:FindFirstChildWhichIsA("BasePart")
	if parent then
		model.Parent = parent
	end

	return model
end

return BuildingGenerator
