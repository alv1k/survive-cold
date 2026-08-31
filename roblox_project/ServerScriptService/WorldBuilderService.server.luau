--[[
    WorldBuilderService.server.luau
    Генератор 3D мира выживания:
    1. Снежный ландшафт (Smooth Terrain Snow & Ice)
    2. Заснеженный хвойный лес (80+ елей с коллизиями)
    3. Жилой дом игрока (очаг, верстак, лежанка, крыша)
    4. Древний Алтарь и Бункер Эвакуации
    5. Магазины (Одежда и Продукты)
    6. 6 Охотничьих Заимок в тайге
    7. Зимняя кинематографичная атмосфера и освещение (Lighting)
--]]

local Lighting = game:GetService("Lighting")
local Terrain = workspace.Terrain

local WorldFolder = workspace:FindFirstChild("WorldStructures") or Instance.new("Folder", workspace)
WorldFolder.Name = "WorldStructures"

-- 1. НАСТРОЙКА КИНЕМАТОГРАФИЧНОЙ ЗИМНЕЙ АТМОСФЕРЫ
local function setupWinterLighting()
	Lighting.ClockTime = 14.5
	Lighting.GeographicLatitude = 65 -- Северные широты
	Lighting.Brightness = 2.2
	Lighting.OutdoorAmbient = Color3.fromRGB(140, 165, 195)
	Lighting.FogColor = Color3.fromRGB(180, 210, 240)
	Lighting.FogStart = 60
	Lighting.FogEnd = 500
	Lighting.GlobalShadows = true

	-- Атмосфера
	local atmosphere = Lighting:FindFirstChildOfClass("Atmosphere") or Instance.new("Atmosphere", Lighting)
	atmosphere.Density = 0.35
	atmosphere.Offset = 0.25
	atmosphere.Color = Color3.fromRGB(190, 220, 250)
	atmosphere.Decay = Color3.fromRGB(110, 150, 190)
	atmosphere.Glare = 0.2
	atmosphere.Haze = 1.5

	-- Цветокоррекция (Холодный кинематографичный зимний тон)
	local colorCorrection = Lighting:FindFirstChildOfClass("ColorCorrectionEffect") or Instance.new("ColorCorrectionEffect", Lighting)
	colorCorrection.TintColor = Color3.fromRGB(235, 245, 255)
	colorCorrection.Contrast = 0.15
	colorCorrection.Saturation = -0.1

	-- Блум (Мягкое свечение снега и костров)
	local bloom = Lighting:FindFirstChildOfClass("BloomEffect") or Instance.new("BloomEffect", Lighting)
	bloom.Intensity = 0.6
	bloom.Size = 24
	bloom.Threshold = 0.8
end

-- 2. ГЕНЕРАЦИЯ СНЕЖНОГО РЕЛЬЕФА (SMOOTH TERRAIN)
local function generateSnowTerrain()
	-- Заливка основной карты снегом 1200x1200 studs
	Terrain:FillBlock(CFrame.new(0, -5, 0), Vector3.new(1400, 10, 1400), Enum.Material.Snow)
	
	-- Замерзшее озеро у Запада
	Terrain:FillBlock(CFrame.new(-180, -4.5, -60), Vector3.new(160, 9.5, 120), Enum.Material.Ice)
	
	-- Скалистый восточный хребет (Опасная зона)
	Terrain:FillBlock(CFrame.new(380, 15, 0), Vector3.new(200, 50, 1200), Enum.Material.Rock)
	Terrain:FillBlock(CFrame.new(380, 38, 0), Vector3.new(180, 10, 1180), Enum.Material.Snow)
end

-- 3. СОЗДАНИЕ ВЫСОКОЙ ЗАСНЕЖЕННОЙ ЕЛИ (PINE TREE - ЧИСТОЕ ОКРУЖЕНИЕ/ДЕКОРАЦИЯ)
local function createPineTree(pos, scale)
	scale = scale or 1.0
	local treeModel = Instance.new("Model")
	treeModel.Name = "SnowPineTree"

	local trunkHeight = 36 * scale
	local trunkWidth = 3.2 * scale

	-- Высокий массивный ствол (С коллизией, НЕ добывается)
	local trunk = Instance.new("Part")
	trunk.Name = "Trunk"
	trunk.Size = Vector3.new(trunkWidth, trunkHeight, trunkWidth)
	trunk.Position = pos + Vector3.new(0, trunkHeight / 2, 0)
	trunk.Anchored = true
	trunk.CanCollide = true
	trunk.Material = Enum.Material.Wood
	trunk.BrickColor = BrickColor.new("Reddish brown")
	trunk.Parent = treeModel

	-- 5 Ярусов пышной заснеженной хвои (высота дерева до 48 studs)
	local tierConfigs = {
		{ Height = 16 * scale, Size = 20 * scale, FoliageH = 8 * scale },
		{ Height = 24 * scale, Size = 16 * scale, FoliageH = 7 * scale },
		{ Height = 31 * scale, Size = 12 * scale, FoliageH = 6 * scale },
		{ Height = 37 * scale, Size = 8 * scale, FoliageH = 5 * scale },
		{ Height = 42 * scale, Size = 4.5 * scale, FoliageH = 5 * scale }
	}

	for i, tc in ipairs(tierConfigs) do
		local foliage = Instance.new("Part")
		foliage.Name = "Foliage_" .. i
		foliage.Size = Vector3.new(tc.Size, tc.FoliageH, tc.Size)
		foliage.Position = pos + Vector3.new(0, tc.Height, 0)
		foliage.Anchored = true
		foliage.CanCollide = false
		foliage.Material = Enum.Material.Grass
		foliage.BrickColor = BrickColor.new("Dark green")
		foliage.Parent = treeModel

		-- Снежная шапка на каждом ярусе
		local snowCap = Instance.new("Part")
		snowCap.Name = "SnowCap_" .. i
		snowCap.Size = Vector3.new(tc.Size - 1.2 * scale, 1.4 * scale, tc.Size - 1.2 * scale)
		snowCap.Position = foliage.Position + Vector3.new(0, tc.FoliageH / 2, 0)
		snowCap.Anchored = true
		snowCap.CanCollide = false
		snowCap.Material = Enum.Material.Snow
		snowCap.BrickColor = BrickColor.new("White")
		snowCap.Parent = treeModel
	end

	treeModel.PrimaryPart = trunk
	treeModel.Parent = workspace:FindFirstChild("Forest") or Instance.new("Folder", workspace)
end

-- 4. ПОСТРОЙКА ЖИЛОГО ДОМА ИГРОКА (PLAYER HOUSE)
local function buildPlayerHouse()
	local houseModel = Instance.new("Model")
	houseModel.Name = "PlayerHouse"

	local HOUSE_POS = Vector3.new(0, 0, 0)

	-- Пол
	local floor = Instance.new("Part")
	floor.Name = "HouseFloor"
	floor.Size = Vector3.new(34, 1.2, 28)
	floor.Position = HOUSE_POS + Vector3.new(0, 0.6, 0)
	floor.Anchored = true
	floor.Material = Enum.Material.WoodPlanks
	floor.BrickColor = BrickColor.new("Brown")
	floor.Parent = houseModel

	-- Точка спавна (Рождение внутри дома!)
	local houseSpawn = Instance.new("SpawnLocation")
	houseSpawn.Name = "HouseSpawnLocation"
	houseSpawn.Size = Vector3.new(8, 0.5, 8)
	houseSpawn.Position = HOUSE_POS + Vector3.new(0, 1.2, 0)
	houseSpawn.Anchored = true
	houseSpawn.CanCollide = false
	houseSpawn.Transparency = 1
	houseSpawn.Neutral = true
	houseSpawn.Duration = 0
	houseSpawn.Parent = houseModel

	-- Стены
	local wallConfigs = {
		{ Size = Vector3.new(34, 12, 1.5), Pos = Vector3.new(0, 6.6, -13.5) }, -- Задняя
		{ Size = Vector3.new(1.5, 12, 28), Pos = Vector3.new(-16.5, 6.6, 0) }, -- Левая
		{ Size = Vector3.new(1.5, 12, 28), Pos = Vector3.new(16.5, 6.6, 0) },  -- Правая
		{ Size = Vector3.new(12, 12, 1.5), Pos = Vector3.new(-11, 6.6, 13.5) }, -- Передняя левая
		{ Size = Vector3.new(12, 12, 1.5), Pos = Vector3.new(11, 6.6, 13.5) }   -- Передняя правая (Дверной проем по центру)
	}

	for _, wc in ipairs(wallConfigs) do
		local wall = Instance.new("Part")
		wall.Size = wc.Size
		wall.Position = HOUSE_POS + wc.Pos
		wall.Anchored = true
		wall.Material = Enum.Material.WoodPlanks
		wall.BrickColor = BrickColor.new("Pine Orange")
		wall.Parent = houseModel
	end

	-- Крыша
	local roof = Instance.new("Part")
	roof.Name = "HouseRoof"
	roof.Size = Vector3.new(38, 2, 32)
	roof.Position = HOUSE_POS + Vector3.new(0, 13, 0)
	roof.Anchored = true
	roof.Material = Enum.Material.WoodPlanks
	roof.BrickColor = BrickColor.new("Dark stone grey")
	roof.Parent = houseModel

	-- Очаг / Камин (Тепловая зона)
	local fireplace = Instance.new("Part")
	fireplace.Name = "HouseFireplace"
	fireplace.Size = Vector3.new(6, 4, 6)
	fireplace.Position = HOUSE_POS + Vector3.new(0, 2.5, -9)
	fireplace.Anchored = true
	fireplace.Material = Enum.Material.Cobblestone
	fireplace.BrickColor = BrickColor.new("Dark stone grey")
	fireplace.Parent = houseModel

	local fire = Instance.new("Fire", fireplace)
	fire.Size = 8
	fire.Heat = 15

	local fireLight = Instance.new("PointLight", fireplace)
	fireLight.Color = Color3.fromRGB(255, 140, 40)
	fireLight.Brightness = 3.5
	fireLight.Range = 35

	fireplace:SetAttribute("HeatRadius", 40)
	fireplace:SetAttribute("HeatPower", 15)
	fireplace.Parent = workspace:FindFirstChild("HeatSources") or workspace

	-- Верстак (Workbench)
	local workbench = Instance.new("Part")
	workbench.Name = "Workbench"
	workbench.Size = Vector3.new(5, 3.5, 3.5)
	workbench.Position = HOUSE_POS + Vector3.new(-12, 2.2, 8)
	workbench.Anchored = true
	workbench.Material = Enum.Material.Wood
	workbench.BrickColor = BrickColor.new("Lapis")
	workbench.Parent = houseModel

	local wbPrompt = Instance.new("ProximityPrompt", workbench)
	wbPrompt.ActionText = "Открыть Верстак (Крафт)"
	wbPrompt.ObjectText = "🛠️ Верстак выживальщика"
	wbPrompt.HoldDuration = 0

	-- Лежанка для питомцев
	local petBed = Instance.new("Part")
	petBed.Name = "PetBed"
	petBed.Size = Vector3.new(6, 1, 4)
	petBed.Position = HOUSE_POS + Vector3.new(11, 1, 8)
	petBed.Anchored = true
	petBed.Material = Enum.Material.Fabric
	petBed.BrickColor = BrickColor.new("Lilac")
	petBed.Parent = houseModel

	houseModel.Parent = WorldFolder
end

-- 5. РАССАДКА 100+ ЕЛЕЙ В ТАЙГЕ
local function populateForest()
	local forestFolder = Instance.new("Folder", workspace)
	forestFolder.Name = "Forest"

	-- Ели вокруг дома (Плотная роща)
	for i = 1, 35 do
		local angle = math.random() * math.pi * 2
		local dist = math.random(35, 150)
		local x = math.cos(angle) * dist
		local z = math.sin(angle) * dist
		createPineTree(Vector3.new(x, 0, z), math.random(90, 140) / 100)
	end

	-- Ели в дикой тайге
	for i = 1, 65 do
		local x = math.random(-450, 450)
		local z = math.random(-450, 450)
		if math.abs(x) > 40 or math.abs(z) > 40 then
			createPineTree(Vector3.new(x, 0, z), math.random(80, 150) / 100)
		end
	end
end

-- 6. ПОСТРОЙКА ОХОТНИЧЬИХ ЗАИМОК (HUNTER CABINS)
local function buildHunterCabins()
	local CABIN_POSITIONS = {
		{ Name = "Северная Заимка", Pos = Vector3.new(-120, 0, -220) },
		{ Name = "Западное Убежище", Pos = Vector3.new(-280, 0, 40) },
		{ Name = "Южная Стоянка", Pos = Vector3.new(80, 0, 240) },
		{ Name = "Восточный Форпост", Pos = Vector3.new(220, 0, -140) },
		{ Name = "Озерный Домик", Pos = Vector3.new(-210, 0, -80) },
		{ Name = "Тайный Схрон", Pos = Vector3.new(140, 0, 320) }
	}

	for _, c in ipairs(CABIN_POSITIONS) do
		local cabin = Instance.new("Model")
		cabin.Name = c.Name

		local base = Instance.new("Part")
		base.Name = "Floor"
		base.Size = Vector3.new(16, 1, 16)
		base.Position = c.Pos + Vector3.new(0, 0.5, 0)
		base.Anchored = true
		base.Material = Enum.Material.WoodPlanks
		base.BrickColor = BrickColor.new("Reddish brown")
		base.Parent = cabin

		local stove = Instance.new("Part")
		stove.Name = "Stove"
		stove.Size = Vector3.new(3, 3, 3)
		stove.Position = c.Pos + Vector3.new(-4, 2, -4)
		stove.Anchored = true
		stove.Material = Enum.Material.Metal
		stove.BrickColor = BrickColor.new("Dark stone grey")
		stove.Parent = cabin

		local stoveFire = Instance.new("Fire", stove)
		stoveFire.Size = 4

		stove:SetAttribute("HeatRadius", 25)
		stove:SetAttribute("HeatPower", 10)
		stove.Parent = workspace:FindFirstChild("HeatSources") or workspace

		cabin.Parent = WorldFolder
	end
end

-- Инициализация мира
setupWinterLighting()
generateSnowTerrain()
buildPlayerHouse()
populateForest()
buildHunterCabins()

print("❄️ [WorldBuilder] Зимний 3D мир успешно сгенерирован: Рельеф, Тайга, Дом, Заимки и Освещение!")
