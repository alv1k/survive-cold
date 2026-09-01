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
	local houseModel = Instance.new("Model")
	houseModel.Name = "PlayerHouse"

	local HOUSE_POS = Vector3.new(0, 0, 0)

	local floor = Instance.new("Part")
	floor.Name = "HouseFloor"
	floor.Size = Vector3.new(34, 1.2, 28)
	floor.Position = HOUSE_POS + Vector3.new(0, 0.6, 0)
	floor.Anchored = true
	floor.Material = Enum.Material.WoodPlanks
	floor.BrickColor = BrickColor.new("Brown")
	floor.Parent = houseModel

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

	local wallConfigs = {
		{ Size = Vector3.new(34, 12, 1.5), Pos = Vector3.new(0, 6.6, -13.5) },
		{ Size = Vector3.new(1.5, 12, 28), Pos = Vector3.new(-16.5, 6.6, 0) },
		{ Size = Vector3.new(1.5, 12, 28), Pos = Vector3.new(16.5, 6.6, 0) },
		{ Size = Vector3.new(12, 12, 1.5), Pos = Vector3.new(-11, 6.6, 13.5) },
		{ Size = Vector3.new(12, 12, 1.5), Pos = Vector3.new(11, 6.6, 13.5) }
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

	local roof = Instance.new("Part")
	roof.Name = "HouseRoof"
	roof.Size = Vector3.new(38, 2, 32)
	roof.Position = HOUSE_POS + Vector3.new(0, 13, 0)
	roof.Anchored = true
	roof.Material = Enum.Material.WoodPlanks
	roof.BrickColor = BrickColor.new("Dark stone grey")
	roof.Parent = houseModel

	local fireplace = Instance.new("Part")
	fireplace.Name = "HouseFireplace"
	fireplace.Size = Vector3.new(6, 4, 6)
	fireplace.Position = HOUSE_POS + Vector3.new(0, 2.5, -9)
	fireplace.Anchored = true
	fireplace.Material = Enum.Material.Cobblestone
	fireplace.BrickColor = BrickColor.new("Dark stone grey")
	fireplace:SetAttribute("FuelSeconds", 0) -- Изначально потушен
	fireplace:SetAttribute("MaxFuel", 600)
	fireplace:SetAttribute("HeatRadius", 40)
	fireplace:SetAttribute("HeatPower", 15)
	fireplace.Parent = houseModel

	local fire = Instance.new("Fire", fireplace)
	fire.Size = 8
	fire.Heat = 15
	fire.Enabled = false

	local fireLight = Instance.new("PointLight", fireplace)
	fireLight.Color = Color3.fromRGB(255, 140, 40)
	fireLight.Brightness = 3.5
	fireLight.Range = 35
	fireLight.Enabled = false

	local prompt = Instance.new("ProximityPrompt", fireplace)
	prompt.Name = "FirePrompt"
	prompt.ActionText = "Зажечь костер (1 🌿 Ветка = +60с)"
	prompt.ObjectText = "🔥 Потухший камин"
	prompt.HoldDuration = 0
	prompt.MaxActivationDistance = 14
	prompt.RequiresLineOfSight = false

	local heatFolder = workspace:FindFirstChild("HeatSources") or Instance.new("Folder", workspace)
	heatFolder.Name = "HeatSources"
	fireplace.Parent = heatFolder

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

-- 5. РАССАДКА 280+ ЕЛЕЙ В ТАЙГЕ 3200x3200
local function populateForest()
	local forestFolder = workspace:FindFirstChild("Forest") or Instance.new("Folder", workspace)
	forestFolder.Name = "Forest"
	forestFolder:ClearAllChildren()

	-- Роща вокруг дома (40..180 studs)
	for i = 1, 45 do
		local angle = math.random() * math.pi * 2
		local dist = math.random(42, 180)
		local x = math.cos(angle) * dist
		local z = math.sin(angle) * dist
		createPineTree(Vector3.new(x, 0, z), math.random(90, 140) / 100)
	end

	-- Дикая тайга по всей карте 3200x3200
	for i = 1, 240 do
		local x = math.random(-1480, 1480)
		local z = math.random(-1480, 1480)
		if math.abs(x) > 45 or math.abs(z) > 45 then
			createPineTree(Vector3.new(x, 0, z), math.random(80, 160) / 100)
		end
	end
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

	for _, c in ipairs(CABIN_POSITIONS) do
		local cabin = Instance.new("Model")
		cabin.Name = c.Name

		local base = Instance.new("Part")
		base.Name = "Floor"
		base.Size = Vector3.new(20, 1.2, 20)
		base.Position = c.Pos + Vector3.new(0, 0.6, 0)
		base.Anchored = true
		base.Material = Enum.Material.WoodPlanks
		base.BrickColor = BrickColor.new("Reddish brown")
		base.Parent = cabin

		-- Крыша
		local roof = Instance.new("Part")
		roof.Size = Vector3.new(22, 1.2, 22)
		roof.Position = c.Pos + Vector3.new(0, 10, 0)
		roof.Anchored = true
		roof.Material = Enum.Material.Wood
		roof.BrickColor = BrickColor.new("Dark stone grey")
		roof.Parent = cabin

		-- Печь-очаг
		local stove = Instance.new("Part")
		stove.Name = "CabinStove_" .. i
		stove.Size = Vector3.new(4, 4, 4)
		stove.Position = c.Pos + Vector3.new(-5, 2.5, -5)
		stove.Anchored = true
		stove.Material = Enum.Material.Brick
		stove.BrickColor = BrickColor.new("Dark stone grey")
		stove:SetAttribute("FuelSeconds", 0) -- Изначально потушена
		stove:SetAttribute("MaxFuel", 600)
		stove:SetAttribute("HeatRadius", 35)
		stove:SetAttribute("HeatPower", 12)
		stove.Parent = cabin

		local stoveFire = Instance.new("Fire", stove)
		stoveFire.Size = 5
		stoveFire.Heat = 12
		stoveFire.Enabled = false

		local stoveLight = Instance.new("PointLight", stove)
		stoveLight.Color = Color3.fromRGB(255, 140, 40)
		stoveLight.Range = 30
		stoveLight.Brightness = 3
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

		cabin.PrimaryPart = base
		cabin.Parent = cabinsFolder
	end
end

-- Инициализация мира
setupWinterLighting()
generateSnowTerrain()
buildPlayerHouse()
populateForest()
buildHunterCabins()

print("❄️ [WorldBuilder] Карта 3200x3200 studs успешно сгенерирована: 280+ елей, горный пояс и 8 охотничьих заимок!")
