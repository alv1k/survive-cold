--[[
    WorldChestService.server.luau
    Серверная система спавна сундуков по всему открытому миру:
    1. 50 Сундуков припасов (WorldChests) -> 4 случайных полезных предмета (БЕЗ ДЕТАЛЕЙ), золотая подсветка.
    2. 50 Сундуков деталей (WorldPartChests) -> 4 дропа ценных Деталей (Parts), высокотехнологичная синяя модель, неоновое циановое свечение.
    - Все сундуки приподняты на 10 пунктов (+1.0 студ), чтобы стоять идеально ровно на снегу / земле.
    - Медленное и плавное исчезновение при открытии (TweenService Fade Out 2.5 сек).
    - Автоматический респавн через 120 секунд с плавной анимацией появления (Fade In 2.0 сек).
--]]

local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Папки в Workspace для структурирования сундуков
local WorldChestsFolder = workspace:FindFirstChild("WorldChests") or Instance.new("Folder", workspace)
WorldChestsFolder.Name = "WorldChests"

local WorldPartChestsFolder = workspace:FindFirstChild("WorldPartChests") or Instance.new("Folder", workspace)
WorldPartChestsFolder.Name = "WorldPartChests"

local RemotesFolder = ReplicatedStorage:FindFirstChild("Remotes") or Instance.new("Folder", ReplicatedStorage)
RemotesFolder.Name = "Remotes"

local ShowNotificationRemote = RemotesFolder:FindFirstChild("ShowNotification") or Instance.new("RemoteEvent", RemotesFolder)
ShowNotificationRemote.Name = "ShowNotification"

local ModelHelper = require(ReplicatedStorage:WaitForChild("ModelHelper", 10))

-- Константы системы
local FADE_OUT_TIME = 2.5 -- Длительность медленного плавного исчезновения (сек)
local FADE_IN_TIME = 2.0  -- Длительность плавного появления при респавне (сек)
local RESPAWN_TIME = 120  -- Время до респавна сундука (сек)
local ITEMS_PER_CHEST = 4 -- Строго 4 случайных предмета в сундуке
local HEIGHT_OFFSET = 1.0 -- Подъем на 10 пунктов (+1.0 студ над землей) для идеальной посадки на снег

-- 50 Точек спавна сундуков ПРИПАСОВ по всей карте
local SUPPLY_CHEST_COORDS = {
	-- 0. Околодомовой сектор
	Vector3.new(-12, 0, 16),
	Vector3.new(14, 0, 16),
	Vector3.new(0, 0, -22),

	-- 1. Ближний пояс (R = 70..250)
	Vector3.new(85, 0, 75),
	Vector3.new(-90, 0, 110),
	Vector3.new(-120, 0, -80),
	Vector3.new(130, 0, -100),
	Vector3.new(160, 0, 80),
	Vector3.new(-180, 0, 140),
	Vector3.new(70, 0, 220),
	Vector3.new(-60, 0, -210),
	Vector3.new(220, 0, -180),
	Vector3.new(-210, 0, -170),
	Vector3.new(240, 0, 160),
	Vector3.new(-250, 0, 80),

	-- 2. Средний пояс (R = 300..700)
	Vector3.new(350, 0, 280),
	Vector3.new(-320, 0, 360),
	Vector3.new(-420, 0, -290),
	Vector3.new(410, 0, -350),
	Vector3.new(520, 0, 180),
	Vector3.new(-510, 0, 250),
	Vector3.new(280, 0, 540),
	Vector3.new(-340, 0, -520),
	Vector3.new(580, 0, -420),
	Vector3.new(-620, 0, 480),
	Vector3.new(-480, 0, 610),
	Vector3.new(650, 0, 320),
	Vector3.new(480, 0, -580),
	Vector3.new(-580, 0, -460),
	Vector3.new(380, 0, 680),
	Vector3.new(-690, 0, -280),

	-- 3. Дальний пояс (R = 750..1200)
	Vector3.new(820, 0, 450),
	Vector3.new(-850, 0, 520),
	Vector3.new(-780, 0, -680),
	Vector3.new(890, 0, -620),
	Vector3.new(980, 0, 280),
	Vector3.new(-940, 0, 380),
	Vector3.new(650, 0, 880),
	Vector3.new(-720, 0, -890),
	Vector3.new(1050, 0, -450),
	Vector3.new(-1080, 0, 590),
	Vector3.new(-890, 0, 920),
	Vector3.new(920, 0, 850),
	Vector3.new(1150, 0, 320),
	Vector3.new(-1120, 0, -480),
	Vector3.new(780, 0, -1050),
	Vector3.new(-650, 0, 1150),

	-- 4. Экстремальные границы (R = 1250..1500)
	Vector3.new(1350, 0, 650),
	Vector3.new(-1380, 0, 720),
	Vector3.new(-1280, 0, -980),
	Vector3.new(1420, 0, -850),
	Vector3.new(1250, 0, 1250),
	Vector3.new(-1450, 0, 450)
}

-- 50 Точек спавна сундуков ДЕТАЛЕЙ (Parts) по всей карте
local PART_CHEST_COORDS = {
	-- 0. Околодомовой сектор
	Vector3.new(14, 0, -16),
	Vector3.new(-14, 0, -16),
	Vector3.new(0, 0, 22),

	-- 1. Ближний пояс (R = 70..250)
	Vector3.new(-85, 0, -75),
	Vector3.new(90, 0, -110),
	Vector3.new(120, 0, 80),
	Vector3.new(-130, 0, 100),
	Vector3.new(-160, 0, -80),
	Vector3.new(180, 0, -140),
	Vector3.new(-70, 0, -220),
	Vector3.new(60, 0, 210),
	Vector3.new(-220, 0, 180),
	Vector3.new(210, 0, 170),
	Vector3.new(-240, 0, -160),
	Vector3.new(250, 0, -80),

	-- 2. Средний пояс (R = 300..700)
	Vector3.new(-350, 0, -280),
	Vector3.new(320, 0, -360),
	Vector3.new(420, 0, 290),
	Vector3.new(-410, 0, 350),
	Vector3.new(-520, 0, -180),
	Vector3.new(510, 0, -250),
	Vector3.new(-280, 0, -540),
	Vector3.new(340, 0, 520),
	Vector3.new(-580, 0, 420),
	Vector3.new(620, 0, -480),
	Vector3.new(480, 0, -610),
	Vector3.new(-650, 0, -320),
	Vector3.new(-480, 0, 580),
	Vector3.new(580, 0, 460),
	Vector3.new(-380, 0, -680),
	Vector3.new(690, 0, 280),

	-- 3. Дальний пояс (R = 750..1200)
	Vector3.new(-820, 0, -450),
	Vector3.new(850, 0, -520),
	Vector3.new(780, 0, 680),
	Vector3.new(-890, 0, 620),
	Vector3.new(-980, 0, -280),
	Vector3.new(940, 0, -380),
	Vector3.new(-650, 0, -880),
	Vector3.new(720, 0, 890),
	Vector3.new(-1050, 0, 450),
	Vector3.new(1080, 0, -590),
	Vector3.new(890, 0, -920),
	Vector3.new(-920, 0, -850),
	Vector3.new(-1150, 0, -320),

	-- 4. Экстремальные границы (R = 1250..1500)
	Vector3.new(1120, 0, 480),
	Vector3.new(-780, 0, 1050),
	Vector3.new(650, 0, -1150),
	Vector3.new(-1350, 0, -650),
	Vector3.new(1380, 0, -720),
	Vector3.new(1280, 0, 980)
}

-- Таблица случайного лута для сундуков припасов (СТРОГО БЕЗ ДЕТАЛЕЙ)
local SUPPLY_LOOT_POOL = {
	-- Ресурсы
	{ Item = "Branches", Min = 2, Max = 4, Weight = 20 },
	{ Item = "Fiber", Min = 2, Max = 4, Weight = 20 },
	{ Item = "Stone", Min = 2, Max = 4, Weight = 18 },
	{ Item = "Planks", Min = 2, Max = 3, Weight = 16 },

	-- Еда и напитки
	{ Item = "Bar", Min = 1, Max = 3, Weight = 15 },
	{ Item = "Bread", Min = 1, Max = 2, Weight = 15 },
	{ Item = "Chips", Min = 1, Max = 2, Weight = 14 },
	{ Item = "Soup", Min = 1, Max = 2, Weight = 12 },
	{ Item = "Pepper", Min = 1, Max = 2, Weight = 10 },
	{ Item = "Coffee", Min = 1, Max = 2, Weight = 10 },
	{ Item = "Steak", Min = 1, Max = 2, Weight = 8 },

	-- Снаряжение, ловушки и оружие
	{ Item = "Torch", Min = 1, Max = 1, Weight = 14 },
	{ Item = "Ammo_Slingshot", Min = 5, Max = 12, Weight = 15 },
	{ Item = "Slingshot", Min = 1, Max = 1, Weight = 6 },
	{ Item = "Spear", Min = 1, Max = 1, Weight = 5 },
	{ Item = "RabbitTrap", Min = 1, Max = 1, Weight = 7 },
	{ Item = "CampfireKit", Min = 1, Max = 1, Weight = 8 },
	{ Item = "SpikeTrap", Min = 1, Max = 1, Weight = 6 },
	{ Item = "WolfPelt", Min = 1, Max = 2, Weight = 6 },
}

local TOTAL_SUPPLY_WEIGHT = 0
for _, entry in ipairs(SUPPLY_LOOT_POOL) do
	TOTAL_SUPPLY_WEIGHT = TOTAL_SUPPLY_WEIGHT + entry.Weight
end

-- Функция случайного выбора 4 уникальных предметов припасов
local function getRandomSupplyLoot(targetCount)
	targetCount = targetCount or ITEMS_PER_CHEST
	local result = {}
	local chosenMap = {}
	local attempts = 0

	while #result < targetCount and #result < #SUPPLY_LOOT_POOL and attempts < 200 do
		attempts = attempts + 1
		local roll = math.random(1, TOTAL_SUPPLY_WEIGHT)
		local current = 0
		local picked = nil

		for _, entry in ipairs(SUPPLY_LOOT_POOL) do
			current = current + entry.Weight
			if roll <= current then
				picked = entry
				break
			end
		end

		if picked and not chosenMap[picked.Item] then
			chosenMap[picked.Item] = true
			table.insert(result, {
				Item = picked.Item,
				Count = math.random(picked.Min, picked.Max)
			})
		end
	end

	return result
end

-- Функция выбора 4 дропов деталей
local function getPartsLoot(targetCount)
	targetCount = targetCount or ITEMS_PER_CHEST
	local result = {}
	for _ = 1, targetCount do
		table.insert(result, {
			Item = "Parts",
			Count = math.random(1, 2)
		})
	end
	return result
end

local function getGroundHeight(x, z)
	local rayOrigin = Vector3.new(x, 150, z)
	local rayDirection = Vector3.new(0, -300, 0)
	local raycastParams = RaycastParams.new()
	raycastParams.FilterType = Enum.RaycastFilterType.Include
	raycastParams.FilterDescendantsInstances = { workspace.Terrain }

	local result = workspace:Raycast(rayOrigin, rayDirection, raycastParams)
	if result then
		return result.Position.Y
	end
	return 0
end

-- Плавная медленная анимация исчезновения сундука (Fade Out)
local function fadeChestOut(chestModel, light, duration)
	duration = duration or FADE_OUT_TIME
	local tweenInfo = TweenInfo.new(duration, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

	-- Плавно растворяем все детали модели
	for _, part in ipairs(chestModel:GetDescendants()) do
		if part:IsA("BasePart") then
			local tween = TweenService:Create(part, tweenInfo, { Transparency = 1 })
			tween:Play()
		end
	end

	-- Плавно гасим свет
	if light then
		local lightTween = TweenService:Create(light, tweenInfo, { Brightness = 0 })
		lightTween:Play()
	end

	-- Отключаем коллизию после исчезновения
	task.delay(duration, function()
		if chestModel and chestModel.Parent then
			for _, part in ipairs(chestModel:GetDescendants()) do
				if part:IsA("BasePart") then
					part.CanCollide = false
				end
			end
			if light then
				light.Enabled = false
			end
		end
	end)
end

-- Плавная анимация появления сундука (Fade In) при респавне
local function fadeChestIn(chestModel, light, defaultLightColor, duration)
	duration = duration or FADE_IN_TIME
	local tweenInfo = TweenInfo.new(duration, Enum.EasingStyle.Quad, Enum.EasingDirection.In)

	if light then
		light.Color = defaultLightColor or Color3.fromRGB(250, 204, 21)
		light.Enabled = true
		local lightTween = TweenService:Create(light, tweenInfo, { Brightness = 0.65 })
		lightTween:Play()
	end

	-- Включаем коллизию и плавно материализуем модель
	for _, part in ipairs(chestModel:GetDescendants()) do
		if part:IsA("BasePart") then
			if part.Name ~= "Gem" and not string.find(part.Name, "Circuit") and not string.find(part.Name, "Seam") then
				part.CanCollide = true
			end
			local tween = TweenService:Create(part, tweenInfo, { Transparency = 0 })
			tween:Play()
		end
	end
end

-- Создание интерактивного сундука
local function createInteractiveChest(index, loc, isPartsChest)
	local groundY = getGroundHeight(loc.X, loc.Z)
	-- Поднимаем на 10 пунктов (+1.0 студ над снежным покровом)
	local chestPos = Vector3.new(loc.X, math.max(1.2, groundY + HEIGHT_OFFSET), loc.Z)
	local randYaw = math.rad(math.random(0, 360))
	local chestCF = CFrame.new(chestPos) * CFrame.Angles(0, randYaw, 0)

	local targetFolder = isPartsChest and WorldPartChestsFolder or WorldChestsFolder
	local chestModel = nil

	if isPartsChest then
		local genChestParts = require(ReplicatedStorage.GeneratedModels.ChestParts)
		if genChestParts and type(genChestParts.create) == "function" then
			chestModel = genChestParts.create(targetFolder, chestCF)
		end
	else
		local genChest = require(ReplicatedStorage.GeneratedModels.Chest)
		if genChest and type(genChest.create) == "function" then
			chestModel = genChest.create(targetFolder, chestCF)
		end
	end

	if not chestModel then
		chestModel = Instance.new("Model", targetFolder)
		chestModel:PivotTo(chestCF)
	end

	chestModel.Name = isPartsChest and string.format("WorldPartChest_%d", index) or string.format("WorldChest_%d", index)

	-- Закрепление деталей
	for _, part in ipairs(chestModel:GetDescendants()) do
		if part:IsA("BasePart") then
			part.Anchored = true
			if part.Name ~= "Gem" and not string.find(part.Name, "Circuit") and not string.find(part.Name, "Seam") then
				part.CanCollide = true
			end
			part.Transparency = 0
		end
	end

	local base = chestModel.PrimaryPart or chestModel:FindFirstChild("ChestBase") or chestModel:FindFirstChildWhichIsA("BasePart")
	local lock = chestModel:FindFirstChild("Latch") or base

	local defaultLightColor = isPartsChest and Color3.fromRGB(6, 182, 212) or Color3.fromRGB(250, 204, 21)
	local light = lock:FindFirstChildOfClass("PointLight") or Instance.new("PointLight", lock)
	light.Color = defaultLightColor
	light.Range = 8
	light.Brightness = 0.65
	light.Enabled = true

	-- ProximityPrompt
	local prompt = Instance.new("ProximityPrompt", base)
	prompt.ActionText = isPartsChest and "Открыть сундук деталей" or "Открыть сундук"
	prompt.ObjectText = isPartsChest and string.format("⚙️ Сундук деталей #%d", index) or string.format("🧰 Древний сундук #%d", index)
	prompt.HoldDuration = 0.3
	prompt.MaxActivationDistance = 14
	prompt.RequiresLineOfSight = false

	local isOpening = false

	prompt.Triggered:Connect(function(player)
		if isOpening then return end
		local char = player.Character
		local hrp = char and char:FindFirstChild("HumanoidRootPart")
		if not hrp or (hrp.Position - chestPos).Magnitude > 22 then return end

		isOpening = true
		prompt.Enabled = false

		-- Генерация ровно 4 предметов
		local items = isPartsChest and getPartsLoot(ITEMS_PER_CHEST) or getRandomSupplyLoot(ITEMS_PER_CHEST)

		for i, dropData in ipairs(items) do
			local angle = (i / #items) * (math.pi * 2)
			local dropOffset = Vector3.new(math.cos(angle) * 2.4, 0, math.sin(angle) * 2.4)
			local dropPos = chestPos + dropOffset

			if _G.DropItemOnGround then
				_G.DropItemOnGround(player, dropData.Item, dropData.Count, dropPos)
			end
		end

		if isPartsChest then
			ShowNotificationRemote:FireClient(player, "⚙️ Вы открыли сундук деталей! Запчасти высыпались на снег.")
			print(string.format("⚙️ %s открыл WorldPartChest_%d! Выпало деталей: %d (плавное исчезновение)", player.Name, index, #items))
		else
			ShowNotificationRemote:FireClient(player, "📦 Вы открыли сундук! 4 ценных предмета высыпались на снег.")
			print(string.format("🧰 %s открыл WorldChest_%d! Выпало предметов: %d (плавное исчезновение)", player.Name, index, #items))
		end

		-- Плавное исчезновение сундука
		fadeChestOut(chestModel, light, FADE_OUT_TIME)

		-- Авто-респавн через 120 секунд с плавной анимацией появления
		task.delay(RESPAWN_TIME, function()
			if chestModel and chestModel.Parent and prompt and prompt.Parent then
				fadeChestIn(chestModel, light, defaultLightColor, FADE_IN_TIME)
				task.delay(FADE_IN_TIME, function()
					isOpening = false
					prompt.Enabled = true
				end)
			end
		end)
	end)

	chestModel.Parent = targetFolder
end

-- Инициализация 50 сундуков припасов
for i, coord in ipairs(SUPPLY_CHEST_COORDS) do
	createInteractiveChest(i, coord, false)
end

-- Инициализация 50 сундуков деталей
for i, coord in ipairs(PART_CHEST_COORDS) do
	createInteractiveChest(i, coord, true)
end

print(string.format("🗺️ [WorldChestService] Расставлено 50 сундуков припасов и 50 сундуков деталей (+10 пунктов над снегом, по 4 предмета, плавный fade-out/in)!", #SUPPLY_CHEST_COORDS, #PART_CHEST_COORDS))
