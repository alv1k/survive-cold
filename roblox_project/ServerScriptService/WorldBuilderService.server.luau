--[[
    WorldBuilderService.server.luau
    Генератор масштабного открытого 3D мира выживания (3200 x 3200 studs):
    1. Огромный снежный ландшафт (Smooth Terrain Snow & Ice)
    2. Скалистый восточный хребет и горное кольцо по периметру
    3. Заснеженная тайга (280+ высоких елей)
    4. Жилой дом игрока с очагом и верстаком
    5. 8 Охотничьих Заимок-убежищ с горящими печами для дальних экспедиций
    6. Кинематографичная морозная атмосфера и освещение
--]]

local Lighting = game:GetService("Lighting")
local Terrain = workspace.Terrain

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SurfaceUtil = require(ReplicatedStorage:WaitForChild("SurfaceUtil"))
local BuildingGenerator = require(ReplicatedStorage:WaitForChild("GeneratedModels"):WaitForChild("BuildingGenerator"))

local WorldFolder = workspace:FindFirstChild("WorldStructures") or Instance.new("Folder", workspace)
WorldFolder.Name = "WorldStructures"

-- 1. НАСТРОЙКА КИНЕМАТОГРАФИЧНОЙ ЗИМНЕЙ АТМОСФЕРЫ
local function setupWinterLighting()
	Lighting.ClockTime = 14.5
	Lighting.GeographicLatitude = 65
	Lighting.Brightness = 2.2
	Lighting.OutdoorAmbient = Color3.fromRGB(140, 165, 195)
	Lighting.FogColor = Color3.fromRGB(180, 210, 240)
	Lighting.FogStart = 90
	Lighting.FogEnd = 900
	Lighting.GlobalShadows = true

	local atmosphere = Lighting:FindFirstChildOfClass("Atmosphere") or Instance.new("Atmosphere", Lighting)
	atmosphere.Density = 0.32
	atmosphere.Offset = 0.25
	atmosphere.Color = Color3.fromRGB(190, 220, 250)
	atmosphere.Decay = Color3.fromRGB(110, 150, 190)
	atmosphere.Glare = 0.2
	atmosphere.Haze = 1.5

	local colorCorrection = Lighting:FindFirstChildOfClass("ColorCorrectionEffect") or Instance.new("ColorCorrectionEffect", Lighting)
	colorCorrection.TintColor = Color3.fromRGB(235, 245, 255)
	colorCorrection.Contrast = 0.15
	colorCorrection.Saturation = -0.1

	local bloom = Lighting:FindFirstChildOfClass("BloomEffect") or Instance.new("BloomEffect", Lighting)
	bloom.Intensity = 0.6
	bloom.Size = 24
	bloom.Threshold = 0.8
end

-- 2. ГЕНЕРАЦИЯ СНЕЖНОГО РЕЛЬЕФА (3200 x 3200 studs)
local function generateSnowTerrain()
	-- Заливка основной карты снегом 3400x3400 studs
	Terrain:FillBlock(CFrame.new(0, -5, 0), Vector3.new(3400, 10, 3400), Enum.Material.Snow)

	-- 100% защита от падения в пустоту: Монолитный базовый слой (Bedrock Plate)
	local bedrock = Instance.new("Part")
	bedrock.Name = "WorldBedrockPlate"
	bedrock.Size = Vector3.new(3800, 10, 3800)
	bedrock.Position = Vector3.new(0, -5, 0)
	bedrock.Anchored = true
	bedrock.CanCollide = true
	bedrock.Transparency = 1
	bedrock.Material = Enum.Material.Slate
	bedrock.Parent = WorldFolder

	-- Большое замерзшее озеро на западе
	Terrain:FillBlock(CFrame.new(-650, -4.5, -350), Vector3.new(450, 9.5, 400), Enum.Material.Ice)

	-- Скалистый восточный хребет
	Terrain:FillBlock(CFrame.new(1050, 25, 0), Vector3.new(350, 70, 3200), Enum.Material.Rock)
	Terrain:FillBlock(CFrame.new(1050, 52, 0), Vector3.new(320, 16, 3160), Enum.Material.Snow)

	-- Горное кольцо по периметру (Север, Юг, Запад)
	Terrain:FillBlock(CFrame.new(0, 30, -1600), Vector3.new(3400, 80, 200), Enum.Material.Rock)
	Terrain:FillBlock(CFrame.new(0, 30, 1600), Vector3.new(3400, 80, 200), Enum.Material.Rock)
	Terrain:FillBlock(CFrame.new(-1600, 30, 0), Vector3.new(200, 80, 3400), Enum.Material.Rock)
end

-- 3. СОЗДАНИЕ ВЕЛИЧЕСТВЕННЫХ ВЫСОКИХ ЕЛЕЙ (СТВОЛ В 3 РАЗА ВЫШЕ: 114+ STUDS)
local function createPineTree(pos, scale)
	scale = scale or 1.0
	local treeModel = Instance.new("Model")
	treeModel.Name = "SnowPineTree"

	local trunkHeight = 114 * scale -- В 3 раза выше (было 38, стало 114)
	local trunkWidth = 4.6 * scale

	local trunk = Instance.new("Part")
	trunk.Name = "Trunk"
	trunk.Size = Vector3.new(trunkWidth, trunkHeight, trunkWidth)
	trunk.Position = pos + Vector3.new(0, trunkHeight / 2, 0)
	trunk.Anchored = true
	trunk.CanCollide = true
	trunk.Material = Enum.Material.Wood
	trunk.BrickColor = BrickColor.new("Reddish brown")
	trunk.Parent = treeModel

	-- 5 Ярусов пышной заснеженной кроны на большой высоте
	local tierConfigs = {
		{ Height = 48 * scale, Size = 28 * scale, FoliageH = 18 * scale },
		{ Height = 68 * scale, Size = 22 * scale, FoliageH = 16 * scale },
		{ Height = 86 * scale, Size = 17 * scale, FoliageH = 14 * scale },
		{ Height = 102 * scale, Size = 12 * scale, FoliageH = 12 * scale },
		{ Height = 116 * scale, Size = 6.5 * scale, FoliageH = 10 * scale }
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

		local snowCap = Instance.new("Part")
		snowCap.Name = "SnowCap_" .. i
		snowCap.Size = Vector3.new(tc.Size - 1.4 * scale, 2.0 * scale, tc.Size - 1.4 * scale)
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
	local HOUSE_POS = Vector3.new(0, 2.0, 0)
	local houseModel = BuildingGenerator.createBuilding("PlayerHouse", CFrame.new(HOUSE_POS), WorldFolder)
	houseModel.Name = "PlayerHouse"

	local houseSpawn = Instance.new("SpawnLocation")
	houseSpawn.Name = "HouseSpawnLocation"
	houseSpawn.Size = Vector3.new(8, 0.5, 8)
	houseSpawn.Position = HOUSE_POS + Vector3.new(0, 1.0, 0)
	houseSpawn.Anchored = true
	houseSpawn.CanCollide = true
	houseSpawn.Transparency = 1
	houseSpawn.Neutral = true
	houseSpawn.Duration = 0
	houseSpawn.Enabled = true
	houseSpawn.Parent = houseModel

	-- Печь-очаг под трубой (X = -7.5, Z = -5.0)
	local fireplace = Instance.new("Part")
	fireplace.Name = "HouseFireplace"
	fireplace.Size = Vector3.new(4.8, 4.0, 4.8)
	fireplace.Position = HOUSE_POS + Vector3.new(-7.5, 2.6, -5.0)
	fireplace.Anchored = true
	fireplace.Material = Enum.Material.Cobblestone
	fireplace.Color = Color3.fromHex("#475569")
	fireplace:SetAttribute("FuelSeconds", 0) -- Изначально потушен
	fireplace:SetAttribute("MaxFuel", 600)
	fireplace:SetAttribute("HeatRadius", 45)
	fireplace:SetAttribute("HeatPower", 15)
	fireplace.Parent = houseModel

	local fire = Instance.new("Fire", fireplace)
	fire.Size = 7
	fire.Heat = 15
	fire.Enabled = false

	local fireLight = Instance.new("PointLight", fireplace)
	fireLight.Color = Color3.fromRGB(255, 140, 40)
	fireLight.Brightness = 0.9
	fireLight.Range = 26
	fireLight.Enabled = false

	local prompt = Instance.new("ProximityPrompt", fireplace)
	prompt.Name = "FirePrompt"
	prompt.ActionText = "Зажечь костер (1 🌿 Ветка = +60с)"
	prompt.ObjectText = "🔥 Потухший камин"
	prompt.HoldDuration = 0
	prompt.MaxActivationDistance = 16
	prompt.RequiresLineOfSight = false

	local heatFolder = workspace:FindFirstChild("HeatSources") or Instance.new("Folder", workspace)
	heatFolder.Name = "HeatSources"
	fireplace.Parent = heatFolder

	-- Верстак выживальщика у боковой стены
	local workbench = Instance.new("Part")
	workbench.Name = "Workbench"
	workbench.Size = Vector3.new(5.5, 2.6, 3.4)
	workbench.Position = HOUSE_POS + Vector3.new(-8.2, 1.9, 3.5)
	workbench.Anchored = true
	workbench.Material = Enum.Material.WoodPlanks
	workbench.Color = Color3.fromHex("#8C451A")
	workbench.Parent = houseModel

	local tabletop = Instance.new("Part")
	tabletop.Name = "TableTop"
	tabletop.Size = Vector3.new(6.0, 0.4, 3.8)
	tabletop.Position = workbench.Position + Vector3.new(0, 1.4, 0)
	tabletop.Anchored = true
	tabletop.Material = Enum.Material.Wood
	tabletop.Color = Color3.fromHex("#C68B59")
	tabletop.Parent = houseModel

	local wbLight = Instance.new("PointLight")
	wbLight.Color = Color3.fromRGB(254, 240, 138)
	wbLight.Brightness = 0.7
	wbLight.Range = 16
	wbLight.Parent = tabletop

	local wbPrompt = Instance.new("ProximityPrompt")
	wbPrompt.Name = "WorkbenchPrompt"
	wbPrompt.ActionText = "Открыть Верстак [E]"
	wbPrompt.ObjectText = "🛠️ Верстак выживальщика"
	wbPrompt.HoldDuration = 0
	wbPrompt.MaxActivationDistance = 18
	wbPrompt.RequiresLineOfSight = false
	wbPrompt.KeyboardKeyCode = Enum.KeyCode.E
	wbPrompt:SetAttribute("IsWorkbench", true)
	wbPrompt.Parent = workbench

	-- Просторная лежанка питомцев (в правом углу)
	local petBed = Instance.new("Part")
	petBed.Name = "PetBed"
	petBed.Size = Vector3.new(6.8, 0.45, 6.0)
	petBed.Position = HOUSE_POS + Vector3.new(6.5, 0.85, 4.0)
	petBed.Anchored = true
	petBed.Material = Enum.Material.Fabric
	petBed.BrickColor = BrickColor.new("Pastel Blue")
	petBed.TopSurface = Enum.SurfaceType.Smooth
	petBed.BottomSurface = Enum.SurfaceType.Smooth
	petBed.Parent = houseModel

	local bedRim = Instance.new("Part")
	bedRim.Name = "PetBedRim"
	bedRim.Size = Vector3.new(7.4, 0.55, 6.6)
	bedRim.Position = HOUSE_POS + Vector3.new(6.5, 0.8, 4.0)
	bedRim.Anchored = true
	bedRim.Material = Enum.Material.Fabric
	bedRim.BrickColor = BrickColor.new("Lilac")
	bedRim.CanCollide = false
	bedRim.Parent = houseModel

	-- Уютный внутренний свет
	local ceilingLight = Instance.new("PointLight")
	ceilingLight.Name = "HouseInteriorLight"
	ceilingLight.Color = Color3.fromRGB(255, 235, 205)
	ceilingLight.Brightness = 0.6
	ceilingLight.Range = 28
	ceilingLight.Parent = houseSpawn
end

-- Зоны исключения для спавна деревьев (Дом игрока, Продуктовый магазин и Магазин одежды в радиусе 200, Заимки в радиусе 35)
local TREE_EXCLUSION_ZONES = {
	{ Pos = Vector3.new(0, 0, 0), Radius = 200, Name = "PlayerHouse" },     -- Дом игрока (R = 200)
	{ Pos = Vector3.new(-50, 0, 0), Radius = 200, Name = "FoodShop" },       -- Продуктовый магазин (R = 200)
	{ Pos = Vector3.new(70, 0, 0), Radius = 200, Name = "ClothingShop" },   -- Магазин одежды (R = 200)
	
	-- 8 Охотничьих Заимок (R = 35)
	{ Pos = Vector3.new(0, 0, -850), Radius = 35 },
	{ Pos = Vector3.new(200, 0, 900), Radius = 35 },
	{ Pos = Vector3.new(-950, 0, -150), Radius = 35 },
	{ Pos = Vector3.new(850, 0, -550), Radius = 35 },
	{ Pos = Vector3.new(-800, 0, -900), Radius = 35 },
	{ Pos = Vector3.new(900, 0, 850), Radius = 35 },
	{ Pos = Vector3.new(800, 0, -1150), Radius = 35 },
	{ Pos = Vector3.new(-850, 0, 950), Radius = 35 },
}

local function isTreeLocationAllowed(x, z)
	for _, zone in ipairs(TREE_EXCLUSION_ZONES) do
		local dx = x - zone.Pos.X
		local dz = z - zone.Pos.Z
		if (dx * dx + dz * dz) < (zone.Radius * zone.Radius) then
			return false
		end
	end
	return true
end

-- 5. РАССАДКА 280+ ЕЛЕЙ В ДИКОЙ ТАЙГЕ 3200x3200 (БЕЗ ДЕРЕВЬЕВ В ДОМЕ И В РАДИУСЕ 200 ОТ ДОМА И МАГАЗИНОВ)
local function populateForest()
	local forestFolder = workspace:FindFirstChild("Forest") or Instance.new("Folder", workspace)
	forestFolder.Name = "Forest"
	forestFolder:ClearAllChildren()

	local targetTreeCount = 280
	local spawnedCount = 0
	local maxAttempts = 2000
	local attempts = 0

	while spawnedCount < targetTreeCount and attempts < maxAttempts do
		attempts = attempts + 1
		local x = math.random(-1480, 1480)
		local z = math.random(-1480, 1480)

		if isTreeLocationAllowed(x, z) then
			local groundY = SurfaceUtil.getGroundHeight(x, z, 50)
			createPineTree(Vector3.new(x, groundY, z), math.random(80, 160) / 100)
			spawnedCount = spawnedCount + 1
		end
	end

	print(string.format("🌲 [Forest] Успешно высажено %d елей в тайге (строгий запрет в радиусе 200 от дома и магазинов)!", spawnedCount))
end

-- 6. ПОСТРОЙКА 8 ОХОТНИЧЬИХ ЗАИМОК ДЛЯ ДАЛЬНИХ ЭКСПЕДИЦИЙ
local function buildHunterCabins()
	local cabinsFolder = workspace:FindFirstChild("HunterCabins") or Instance.new("Folder", workspace)
	cabinsFolder.Name = "HunterCabins"
	cabinsFolder:ClearAllChildren()

	local CABIN_POSITIONS = {
		{ Name = "Северный Аванпост", Pos = Vector3.new(0, 0, -850) },
		{ Name = "Южная Заимка", Pos = Vector3.new(200, 0, 900) },
		{ Name = "Западное Убежище Озера", Pos = Vector3.new(-950, 0, -150) },
		{ Name = "Восточный Форпост Хребта", Pos = Vector3.new(850, 0, -550) },
		{ Name = "Северо-Западный Лагерь", Pos = Vector3.new(-800, 0, -900) },
		{ Name = "Юго-Восточная Стоянка", Pos = Vector3.new(900, 0, 850) },
		{ Name = "Северо-Восточный Дозор", Pos = Vector3.new(800, 0, -1150) },
		{ Name = "Юго-Западный Схрон", Pos = Vector3.new(-850, 0, 950) }
	}

	for i, c in ipairs(CABIN_POSITIONS) do
		local groundY = SurfaceUtil.getGroundHeight(c.Pos.X, c.Pos.Z, 50)
		local basePos = Vector3.new(c.Pos.X, groundY, c.Pos.Z)

		local cabin = BuildingGenerator.createBuilding("HunterCabin", CFrame.new(basePos), cabinsFolder)
		cabin.Name = c.Name

		-- Печь-очаг заимки под трубой (X = -7.5, Z = -5.0)
		local stove = Instance.new("Part")
		stove.Name = "CabinStove_" .. i
		stove.Size = Vector3.new(4.8, 4.0, 4.8)
		stove.Position = basePos + Vector3.new(-7.5, 2.6, -5.0)
		stove.Anchored = true
		stove.Material = Enum.Material.Cobblestone
		stove.Color = Color3.fromHex("#475569")
		stove:SetAttribute("FuelSeconds", 0) -- Изначально потушена
		stove:SetAttribute("MaxFuel", 600)
		stove:SetAttribute("HeatRadius", 40)
		stove:SetAttribute("HeatPower", 14)
		stove.Parent = cabin

		local stoveFire = Instance.new("Fire", stove)
		stoveFire.Size = 5
		stoveFire.Heat = 12
		stoveFire.Enabled = false

		local stoveLight = Instance.new("PointLight", stove)
		stoveLight.Color = Color3.fromRGB(255, 140, 40)
		stoveLight.Range = 20
		stoveLight.Brightness = 0.6
		stoveLight.Enabled = false

		local prompt = Instance.new("ProximityPrompt", stove)
		prompt.Name = "FirePrompt"
		prompt.ActionText = "Зажечь печь (1 🌿 Ветка = +60с)"
		prompt.ObjectText = string.format("🔥 %s [Потушено]", c.Name)
		prompt.HoldDuration = 0
		prompt.MaxActivationDistance = 14
		prompt.RequiresLineOfSight = false

		local heatFolder = workspace:FindFirstChild("HeatSources") or Instance.new("Folder", workspace)
		heatFolder.Name = "HeatSources"
		stove.Parent = heatFolder

		-- Мягкий свет внутри заимки
		local cabinLight = Instance.new("PointLight", stove)
		cabinLight.Color = Color3.fromRGB(255, 230, 180)
		cabinLight.Brightness = 0.4
		cabinLight.Range = 20
	end
end

-- Инициализация мира
setupWinterLighting()
generateSnowTerrain()
buildPlayerHouse()
populateForest()
buildHunterCabins()

print("❄️ [WorldBuilder] Карта 3200x3200 studs успешно сгенерирована: 280+ елей, горный пояс и 8 охотничьих заимок!")
