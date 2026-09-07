--[[
    MobSpawner.server.luau
    Серверная система спавна, ИИ, патруля и выпадения шкур врагов:
    - Западная Безопасная Зона (X < 180): Монстры не могут зайти за границу!
    - Восточная Опасная Зона (X >= 250): Спавн Волков, Йети и Бигфутов.
    - Дроп шкур при убийстве: Волк -> WolfPelt (85%), Йети -> YetiPelt (90%).
--]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local PhysicsService = game:GetService("PhysicsService")

local Network = require(ReplicatedStorage:WaitForChild("Network"))
local InventoryService = require(script.Parent:WaitForChild("InventoryService"))
local SurfaceUtil = require(ReplicatedStorage:WaitForChild("SurfaceUtil"))

local ShowNotificationRemote = Network.getEvent("ShowNotification")

local MobsFolder = workspace:FindFirstChild("Mobs") or Instance.new("Folder", workspace)
MobsFolder.Name = "Mobs"

-- =============================================================================
-- НАСТРОЙКА ГРУПП КОЛЛИЗИЙ (PhysicsService: Враги проходят насквозь игрока)
-- =============================================================================
local function safeRegisterCollisionGroup(groupName)
	pcall(function()
		PhysicsService:RegisterCollisionGroup(groupName)
	end)
end

safeRegisterCollisionGroup("Players")
safeRegisterCollisionGroup("Mobs")
safeRegisterCollisionGroup("Pets")

-- Отключаем коллизию между Игроками и Монстрами (не взбираются друг на друга, проходят насквозь)
pcall(function()
	PhysicsService:CollisionGroupSetCollidable("Players", "Mobs", false)
	PhysicsService:CollisionGroupSetCollidable("Players", "Pets", false)
	PhysicsService:CollisionGroupSetCollidable("Players", "Players", false)
	PhysicsService:CollisionGroupSetCollidable("Mobs", "Mobs", false)
	PhysicsService:CollisionGroupSetCollidable("Mobs", "Pets", false)
	PhysicsService:CollisionGroupSetCollidable("Pets", "Pets", false)
end)

local function setModelCollisionGroup(model, groupName)
	for _, desc in ipairs(model:GetDescendants()) do
		if desc:IsA("BasePart") then
			pcall(function()
				desc.CollisionGroup = groupName
			end)
		end
	end
	model.DescendantAdded:Connect(function(desc)
		if desc:IsA("BasePart") then
			pcall(function()
				desc.CollisionGroup = groupName
			end)
		end
	end)
end

-- Автоматическое назначение игроков в группу "Players"
local function setupPlayerCharacter(char)
	setModelCollisionGroup(char, "Players")
end

Players.PlayerAdded:Connect(function(player)
	if player.Character then
		setupPlayerCharacter(player.Character)
	end
	player.CharacterAdded:Connect(setupPlayerCharacter)
end)

for _, player in ipairs(Players:GetPlayers()) do
	if player.Character then
		setupPlayerCharacter(player.Character)
	end
	player.CharacterAdded:Connect(setupPlayerCharacter)
end

local mobConfigs = {
	Wolf = {
		Name = "🐺 Полярный Волк",
		Hp = 30,
		Damage = 12,
		Speed = 12.0,
		ThreatLevel = 2,
		AggroRadius = 45,
		PatrolRadius = 120,
		HipHeight = 0.95,
		HrpSize = Vector3.new(1.2, 1.0, 2.2),
		Loot = { Item = "WolfPelt", Chance = 0.85, Count = 1 }
	},
	Yeti = {
		Name = "❄️ Снежный Йети",
		Hp = 60,
		Damage = 25,
		Speed = 6.0,
		ThreatLevel = 4,
		AggroRadius = 40,
		PatrolRadius = 90,
		HipHeight = 1.8,
		HrpSize = Vector3.new(2.4, 2.6, 2.0),
		Loot = { Item = "YetiPelt", Chance = 0.90, Count = 1 }
	},
	Bigfoot = {
		Name = "🦍 Бигфут",
		Hp = 120,
		Damage = 40,
		Speed = 5.0,
		ThreatLevel = 6,
		AggroRadius = 50,
		PatrolRadius = 150,
		HipHeight = 2.2,
		HrpSize = Vector3.new(2.6, 3.0, 2.2),
		Loot = { Item = "YetiPelt", Chance = 1.00, Count = 2 }
	}
}

local SAFE_ZONE_BARRIER_X = 180 -- Западная граница: монстры не переходят X < 180!

local function attachEnemyVisuals(mobModel, mobType, hrp)
	local genMod = ReplicatedStorage:FindFirstChild("GeneratedModels")
	local modScript = genMod and genMod:FindFirstChild(mobType)
	local loaded = false

	if modScript then
		local success, Generator = pcall(require, modScript)
		if success and Generator and type(Generator.create) == "function" then
			local offsetCF = CFrame.identity
			if mobType == "Wolf" then
				offsetCF = CFrame.new(0, -0.9, 0)
			elseif mobType == "Yeti" then
				offsetCF = CFrame.new(0, -1.8, 0)
			elseif mobType == "Bigfoot" then
				offsetCF = CFrame.new(0, -2.2, 0)
			end

			local visualModel = Generator.create(nil, hrp.CFrame * offsetCF, {
				isMob = true,
				Scale = (mobType == "Wolf" and 1.35 or 1.0),
				Anchored = false
			})

			if visualModel and visualModel.PrimaryPart then
				local primary = visualModel.PrimaryPart
				-- Переносим все части визуальной модели в mobModel
				for _, desc in ipairs(visualModel:GetChildren()) do
					if desc:IsA("BasePart") then
						desc.Anchored = false
						desc.CanCollide = false
						desc.Massless = true
						desc.Parent = mobModel
					end
				end
				visualModel:Destroy()

				-- Привариваем PrimaryPart (Torso/Body) к hrp
				local rootWeld = Instance.new("WeldConstraint")
				rootWeld.Name = "Weld_Root_" .. mobType
				rootWeld.Part0 = hrp
				rootWeld.Part1 = primary
				rootWeld.Parent = hrp

				loaded = true
			end
		end
	end

	if not loaded then
		local function addSubPart(name, size, cfOffset, material, color)
			local sub = Instance.new("Part")
			sub.Name = name
			sub.Size = size
			sub.CFrame = hrp.CFrame * cfOffset
			sub.Material = material or Enum.Material.Fabric
			sub.BrickColor = color or BrickColor.new("Medium stone grey")
			sub.CanCollide = false
			sub.Massless = true
			sub.Anchored = false
			sub.Parent = mobModel

			local weld = Instance.new("WeldConstraint")
			weld.Name = "Weld_" .. name
			weld.Part0 = hrp
			weld.Part1 = sub
			weld.Parent = sub
			return sub
		end

		if mobType == "Wolf" then
			addSubPart("Body", Vector3.new(1.4, 1.2, 2.2), CFrame.new(0, 0, 0), Enum.Material.SmoothPlastic, BrickColor.new("Medium stone grey"))
			addSubPart("Head", Vector3.new(1.4, 1.3, 1.6), CFrame.new(0, 0.4, -1.2), Enum.Material.SmoothPlastic, BrickColor.new("Medium stone grey"))
			addSubPart("Snout", Vector3.new(0.8, 0.6, 1.1), CFrame.new(0, 0.2, -1.8), Enum.Material.SmoothPlastic, BrickColor.new("Dark stone grey"))
			addSubPart("Nose", Vector3.new(0.3, 0.3, 0.3), CFrame.new(0, 0.35, -2.25), Enum.Material.SmoothPlastic, BrickColor.new("Really black"))
			addSubPart("EarL", Vector3.new(0.3, 0.8, 0.4), CFrame.new(-0.5, 1.0, -1.1) * CFrame.Angles(0, 0, math.rad(-15)), Enum.Material.SmoothPlastic, BrickColor.new("Dark stone grey"))
			addSubPart("EarR", Vector3.new(0.3, 0.8, 0.4), CFrame.new(0.5, 1.0, -1.1) * CFrame.Angles(0, 0, math.rad(15)), Enum.Material.SmoothPlastic, BrickColor.new("Dark stone grey"))
			addSubPart("EyeL", Vector3.new(0.25, 0.25, 0.25), CFrame.new(-0.35, 0.55, -1.6), Enum.Material.Neon, BrickColor.new("Bright red"))
			addSubPart("EyeR", Vector3.new(0.25, 0.25, 0.25), CFrame.new(0.35, 0.55, -1.6), Enum.Material.Neon, BrickColor.new("Bright red"))
			addSubPart("LegFL", Vector3.new(0.4, 1.2, 0.4), CFrame.new(-0.5, -0.6, -0.7), Enum.Material.SmoothPlastic, BrickColor.new("Dark stone grey"))
			addSubPart("LegFR", Vector3.new(0.4, 1.2, 0.4), CFrame.new(0.5, -0.6, -0.7), Enum.Material.SmoothPlastic, BrickColor.new("Dark stone grey"))
			addSubPart("LegBL", Vector3.new(0.45, 1.2, 0.45), CFrame.new(-0.5, -0.6, 0.7), Enum.Material.SmoothPlastic, BrickColor.new("Dark stone grey"))
			addSubPart("LegBR", Vector3.new(0.45, 1.2, 0.45), CFrame.new(0.5, -0.6, 0.7), Enum.Material.SmoothPlastic, BrickColor.new("Dark stone grey"))
			addSubPart("Tail", Vector3.new(0.4, 0.4, 1.4), CFrame.new(0, 0.2, 1.4) * CFrame.Angles(math.rad(-25), 0, 0), Enum.Material.SmoothPlastic, BrickColor.new("Medium stone grey"))
		elseif mobType == "Yeti" then
			addSubPart("Torso", Vector3.new(3.8, 3.2, 2.6), CFrame.new(0, 0, 0), Enum.Material.Fabric, BrickColor.new("Pastel light blue"))
			addSubPart("LowerTorso", Vector3.new(3.2, 1.8, 2.4), CFrame.new(0, -1.2, 0), Enum.Material.Fabric, BrickColor.new("Pastel light blue"))
			addSubPart("FurCollar", Vector3.new(4.0, 1.2, 3.0), CFrame.new(0, 1.2, 0), Enum.Material.Fabric, BrickColor.new("White"))
			addSubPart("Head", Vector3.new(2.4, 2.2, 2.2), CFrame.new(0, 2.4, -0.4), Enum.Material.Fabric, BrickColor.new("White"))
			addSubPart("FaceMask", Vector3.new(1.8, 1.2, 0.6), CFrame.new(0, 2.2, -1.3), Enum.Material.SmoothPlastic, BrickColor.new("Dark stone grey"))
			addSubPart("HornL", Vector3.new(0.6, 1.4, 0.6), CFrame.new(-1.3, 3.4, -0.4) * CFrame.Angles(0, 0, math.rad(-25)), Enum.Material.Ice, BrickColor.new("Pastel light blue"))
			addSubPart("HornR", Vector3.new(0.6, 1.4, 0.6), CFrame.new(1.3, 3.4, -0.4) * CFrame.Angles(0, 0, math.rad(25)), Enum.Material.Ice, BrickColor.new("Pastel light blue"))
			addSubPart("EyeL", Vector3.new(0.4, 0.4, 0.4), CFrame.new(-0.55, 2.5, -1.5), Enum.Material.Neon, BrickColor.new("Cyan"))
			addSubPart("EyeR", Vector3.new(0.4, 0.4, 0.4), CFrame.new(0.55, 2.5, -1.5), Enum.Material.Neon, BrickColor.new("Cyan"))
			addSubPart("ArmL", Vector3.new(1.4, 3.6, 1.4), CFrame.new(-2.6, 0.2, 0), Enum.Material.Fabric, BrickColor.new("Pastel light blue"))
			addSubPart("ArmR", Vector3.new(1.4, 3.6, 1.4), CFrame.new(2.6, 0.2, 0), Enum.Material.Fabric, BrickColor.new("Pastel light blue"))
			addSubPart("LegL", Vector3.new(1.4, 2.4, 1.4), CFrame.new(-1.1, -2.0, 0), Enum.Material.Fabric, BrickColor.new("Pastel light blue"))
			addSubPart("LegR", Vector3.new(1.4, 2.4, 1.4), CFrame.new(1.1, -2.0, 0), Enum.Material.Fabric, BrickColor.new("Pastel light blue"))
		elseif mobType == "Bigfoot" then
			addSubPart("Torso", Vector3.new(4.0, 3.4, 2.8), CFrame.new(0, 0, 0), Enum.Material.Fabric, BrickColor.new("Reddish brown"))
			addSubPart("LowerTorso", Vector3.new(3.4, 1.8, 2.5), CFrame.new(0, -1.3, 0), Enum.Material.Fabric, BrickColor.new("Reddish brown"))
			addSubPart("BackHunch", Vector3.new(3.8, 1.6, 2.2), CFrame.new(0, 1.1, 0.4), Enum.Material.Fabric, BrickColor.new("Dark orange"))
			addSubPart("Head", Vector3.new(2.4, 2.2, 2.2), CFrame.new(0, 2.4, -0.4), Enum.Material.Fabric, BrickColor.new("Dark orange"))
			addSubPart("BrowRidge", Vector3.new(2.2, 0.6, 0.8), CFrame.new(0, 2.7, -1.3), Enum.Material.SmoothPlastic, BrickColor.new("Really black"))
			addSubPart("Jaw", Vector3.new(1.8, 0.9, 1.2), CFrame.new(0, 1.9, -1.2), Enum.Material.Fabric, BrickColor.new("Reddish brown"))
			addSubPart("EyeL", Vector3.new(0.4, 0.4, 0.4), CFrame.new(-0.55, 2.6, -1.5), Enum.Material.Neon, BrickColor.new("Deep orange"))
			addSubPart("EyeR", Vector3.new(0.4, 0.4, 0.4), CFrame.new(0.55, 2.6, -1.5), Enum.Material.Neon, BrickColor.new("Deep orange"))
			addSubPart("ArmL", Vector3.new(1.5, 4.2, 1.5), CFrame.new(-2.8, 0.0, 0), Enum.Material.Fabric, BrickColor.new("Reddish brown"))
			addSubPart("ArmR", Vector3.new(1.5, 4.2, 1.5), CFrame.new(2.8, 0.0, 0), Enum.Material.Fabric, BrickColor.new("Reddish brown"))
			addSubPart("LegL", Vector3.new(1.5, 2.6, 1.5), CFrame.new(-1.2, -2.2, 0), Enum.Material.Fabric, BrickColor.new("Dark orange"))
			addSubPart("LegR", Vector3.new(1.5, 2.6, 1.5), CFrame.new(1.2, -2.2, 0), Enum.Material.Fabric, BrickColor.new("Dark orange"))
		end
	end
end

local function spawnMob(mobType, spawnPos)
	local cfg = mobConfigs[mobType]
	if not cfg then return end

	local mobModel = Instance.new("Model")
	mobModel.Name = cfg.Name
	mobModel:SetAttribute("MobType", mobType)
	mobModel:SetAttribute("ThreatLevel", cfg.ThreatLevel)
	mobModel:SetAttribute("SpawnPos", spawnPos)

	local hrp = Instance.new("Part")
	hrp.Name = "HumanoidRootPart"
	hrp.Size = cfg.HrpSize or Vector3.new(1.4, 1.2, 2.2)
	hrp.Position = spawnPos
	hrp.Transparency = 1
	hrp.Anchored = false
	hrp.CanCollide = true
	hrp.Parent = mobModel
	mobModel.PrimaryPart = hrp

	attachEnemyVisuals(mobModel, mobType, hrp)
	setModelCollisionGroup(mobModel, "Mobs")

	local humanoid = Instance.new("Humanoid")
	humanoid.MaxHealth = cfg.Hp
	humanoid.Health = cfg.Hp
	humanoid.WalkSpeed = cfg.Speed
	humanoid.HipHeight = cfg.HipHeight or 1.0
	humanoid.AutomaticScalingEnabled = false
	humanoid:SetStateEnabled(Enum.HumanoidStateType.Climbing, false) -- Не карабкаться по игрокам и препятствиям
	humanoid:SetStateEnabled(Enum.HumanoidStateType.Seated, false)
	humanoid.MaxSlopeAngle = 45
	humanoid.Parent = mobModel


	-- Обработка гибели моба и выпадения шкуры
	humanoid.Died:Connect(function()
		if cfg.Loot and math.random() <= cfg.Loot.Chance then
			-- Создание лута на земле через SurfaceUtil
			local lootPart = Instance.new("Part")
			lootPart.Name = "Dropped_" .. cfg.Loot.Item
			lootPart.Size = Vector3.new(2, 0.4, 2)
			lootPart.Anchored = true
			lootPart.CanCollide = false
			lootPart.Material = Enum.Material.Fabric
			lootPart.BrickColor = (cfg.Loot.Item == "WolfPelt") and BrickColor.new("Dark stone grey") or BrickColor.new("White")
			lootPart.Parent = workspace:FindFirstChild("DroppedItems") or workspace
			SurfaceUtil.placeOnSurface(lootPart, hrp.Position, 0.15)

			local prompt = Instance.new("ProximityPrompt", lootPart)
			prompt.ActionText = string.format("Подобрать %s (x%d)", (cfg.Loot.Item == "WolfPelt" and "🐺 Шкуру волка" or "❄️ Шкуру Йети"), cfg.Loot.Count)
			prompt.ObjectText = "Трофей с монстра"
			prompt.HoldDuration = 0
			prompt.MaxActivationDistance = 14
			prompt.RequiresLineOfSight = false

			prompt.Triggered:Connect(function(player)
				local given = InventoryService.giveItem(player, cfg.Loot.Item, cfg.Loot.Count)
				if not given then
					ShowNotificationRemote:FireClient(player, "⚠️ Рюкзак полон! Освободите место, чтобы поднять шкуру.")
					return
				end

				lootPart:Destroy()
				ShowNotificationRemote:FireClient(player, string.format("🎒 Вы подобрали %s (x%d)!", (cfg.Loot.Item == "WolfPelt" and "🐺 Шкуру волка" or "❄️ Шкуру Йети"), cfg.Loot.Count))
				print(string.format("🎒 %s подобрал %dx %s!", player.Name, cfg.Loot.Count, cfg.Loot.Item))
			end)
		end

		task.delay(2, function()
			mobModel:Destroy()
		end)

		-- Респавн моба в опасной зоне через 60 секунд
		task.delay(60, function()
			spawnMob(mobType, spawnPos)
		end)
	end)


	mobModel.Parent = MobsFolder
	print(string.format("🐺 [MobSpawner] Заспавнен %s (%s) на позиции (%.1f, %.1f, %.1f), частей модели: %d", cfg.Name, mobType, spawnPos.X, spawnPos.Y, spawnPos.Z, #mobModel:GetChildren()))
end

local function getGroundHeight(x, z)
	return SurfaceUtil.getGroundHeight(x, z, 50)
end

-- Спавн по 1 штуке каждого типа врагов на расстоянии ровно 210 метров от дома
local MOB_SPAWN_POINTS = {
	{ Type = "Wolf", Pos = Vector3.new(210, 0, 0) },       -- 🐺 Волк: 210м к востоку
	{ Type = "Yeti", Pos = Vector3.new(148, 0, 148) },     -- ❄️ Йети: 210м к юго-востоку
	{ Type = "Bigfoot", Pos = Vector3.new(148, 0, -148) }  -- 🦍 Бигфут: 210м к северо-востоку
}

for _, sp in ipairs(MOB_SPAWN_POINTS) do
	local gy = getGroundHeight(sp.Pos.X, sp.Pos.Z)
	local exactPos = Vector3.new(sp.Pos.X, gy + 3, sp.Pos.Z)
	spawnMob(sp.Type, exactPos)
end

-- ИИ Патруля и Агро с защитой околодомовой зоны (радиус 80м вокруг дома)
task.spawn(function()
	while true do
		task.wait(0.5)
		for _, mob in ipairs(MobsFolder:GetChildren()) do
			local humanoid = mob:FindFirstChild("Humanoid")
			local hrp = mob:FindFirstChild("HumanoidRootPart")
			if humanoid and hrp and humanoid.Health > 0 then
				local mobType = mob:GetAttribute("MobType") or "Wolf"
				local cfg = mobConfigs[mobType]
				local spawnPos = mob:GetAttribute("SpawnPos") or hrp.Position

				-- Поиск ближайшего игрока или активной турели в радиусе агро
				local targetTarget = nil
				local targetIsPlayer = false
				local closestDist = cfg.AggroRadius

				for _, player in ipairs(Players:GetPlayers()) do
					local char = player.Character
					if char and char:FindFirstChild("HumanoidRootPart") then
						local pHrp = char.HumanoidRootPart
						local pDistToHouse = math.sqrt(pHrp.Position.X^2 + pHrp.Position.Z^2)

						-- Мобы агрятся на игрока, когда он выходит за пределы домашней зоны (> 80m)
						if pDistToHouse >= 80 then
							local dist = (pHrp.Position - hrp.Position).Magnitude
							if dist < closestDist then
								closestDist = dist
								targetTarget = pHrp
								targetIsPlayer = true
							end
						end
					end
				end

				if not targetTarget then
					local turretsFolder = workspace:FindFirstChild("Turrets")
					if turretsFolder then
						for _, turret in ipairs(turretsFolder:GetChildren()) do
							if not turret:GetAttribute("IsBroken") then
								local base = turret:FindFirstChild("Base") or turret.PrimaryPart
								if base then
									local tDist = (base.Position - hrp.Position).Magnitude
									if tDist < closestDist then
										closestDist = tDist
										targetTarget = base
										targetIsPlayer = false
									end
								end
							end
						end
					end
				end

				if targetTarget then
					-- Движение и атака цели
					humanoid:MoveTo(targetTarget.Position)
					if targetIsPlayer and closestDist < 6 then
						local pChar = targetTarget.Parent
						local pHumanoid = pChar and pChar:FindFirstChild("Humanoid")
						if pHumanoid then
							pHumanoid:TakeDamage(cfg.Damage)
						end
					end
				else
					-- Патруль в радиусе своей 210-метровой зоны обитания
					local distFromHouse = math.sqrt(hrp.Position.X^2 + hrp.Position.Z^2)
					if distFromHouse < 80 then
						-- Возврат на исходную позицию 210м при случайном приближении к дому
						humanoid:MoveTo(spawnPos)
					else
						local offset = Vector3.new(math.random(-cfg.PatrolRadius, cfg.PatrolRadius), 0, math.random(-cfg.PatrolRadius, cfg.PatrolRadius))
						local targetPos = spawnPos + offset
						local targetDistToHouse = math.sqrt(targetPos.X^2 + targetPos.Z^2)
						if targetDistToHouse < 80 then
							targetPos = spawnPos
						end
						humanoid:MoveTo(targetPos)
					end
				end
			end
		end
	end
end)


