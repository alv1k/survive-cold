--[[
    MobSpawner.server.luau
    Серверная система спавна, ИИ, патруля и выпадения шкур врагов:
    - Западная Безопасная Зона (X < 180): Монстры не могут зайти за границу!
    - Восточная Опасная Зона (X >= 250): Спавн Волков, Йети и Бигфутов.
    - Дроп шкур при убийстве: Волк -> WolfPelt (85%), Йети -> YetiPelt (90%).
--]]

local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local MobsFolder = workspace:FindFirstChild("Mobs") or Instance.new("Folder", workspace)
MobsFolder.Name = "Mobs"

local mobConfigs = {
	Wolf = {
		Name = "🐺 Лесной Волк",
		Hp = 30,
		Damage = 12,
		Speed = 8.0,
		ThreatLevel = 2,
		AggroRadius = 45,
		PatrolRadius = 120,
		Loot = { Item = "WolfPelt", Chance = 0.85, Count = 1 }
	},
	Yeti = {
		Name = "❄️ Снежный Йети",
		Hp = 60,
		Damage = 25,
		Speed = 1.2,
		ThreatLevel = 4,
		AggroRadius = 40,
		PatrolRadius = 90,
		Loot = { Item = "YetiPelt", Chance = 0.90, Count = 1 }
	},
	Bigfoot = {
		Name = "🦍 Бигфут",
		Hp = 120,
		Damage = 40,
		Speed = 1.0,
		ThreatLevel = 6,
		AggroRadius = 50,
		PatrolRadius = 150,
		Loot = { Item = "YetiPelt", Chance = 1.00, Count = 2 }
	}
}

local SAFE_ZONE_BARRIER_X = 180 -- Западная граница: монстры не переходят X < 180!

local function attachEnemyVisuals(mobModel, mobType, hrp)
	local function addSubPart(name, size, cfOffset, material, color, isNeon)
		local sub = Instance.new("Part")
		sub.Name = name
		sub.Size = size
		sub.CFrame = hrp.CFrame * cfOffset
		sub.Material = material or Enum.Material.Fabric
		sub.BrickColor = color or BrickColor.new("Medium stone grey")
		sub.CanCollide = false
		sub.Massless = true
		sub.Parent = mobModel

		local weld = Instance.new("WeldConstraint")
		weld.Part0 = hrp
		weld.Part1 = sub
		weld.Parent = sub
		return sub
	end

	if mobType == "Wolf" then
		-- 🐺 ВОЛК: Морда, уши, светящиеся красные глаза, 4 лапы и хвост
		hrp.Size = Vector3.new(1.8, 1.8, 3.6)
		hrp.Material = Enum.Material.Fabric
		hrp.BrickColor = BrickColor.new("Medium stone grey")

		-- Голова и мордочка
		addSubPart("Head", Vector3.new(1.4, 1.3, 1.6), CFrame.new(0, 0.6, -2.2), Enum.Material.Fabric, BrickColor.new("Medium stone grey"))
		addSubPart("Snout", Vector3.new(0.8, 0.6, 1.1), CFrame.new(0, 0.3, -3.0), Enum.Material.Fabric, BrickColor.new("Dark stone grey"))
		addSubPart("Nose", Vector3.new(0.3, 0.3, 0.3), CFrame.new(0, 0.5, -3.55), Enum.Material.SmoothPlastic, BrickColor.new("Really black"))

		-- Острые стоячие уши
		addSubPart("EarL", Vector3.new(0.3, 0.8, 0.4), CFrame.new(-0.5, 1.4, -2.0) * CFrame.Angles(0, 0, math.rad(-15)), Enum.Material.Fabric, BrickColor.new("Dark stone grey"))
		addSubPart("EarR", Vector3.new(0.3, 0.8, 0.4), CFrame.new(0.5, 1.4, -2.0) * CFrame.Angles(0, 0, math.rad(15)), Enum.Material.Fabric, BrickColor.new("Dark stone grey"))

		-- Светящиеся красные глаза хищника
		local eyeL = addSubPart("EyeL", Vector3.new(0.25, 0.25, 0.25), CFrame.new(-0.35, 0.75, -2.8), Enum.Material.Neon, BrickColor.new("Bright red"))
		local eyeR = addSubPart("EyeR", Vector3.new(0.25, 0.25, 0.25), CFrame.new(0.35, 0.75, -2.8), Enum.Material.Neon, BrickColor.new("Bright red"))

		-- 4 Лапы
		addSubPart("LegFL", Vector3.new(0.5, 1.6, 0.5), CFrame.new(-0.7, -1.0, -1.2), Enum.Material.Fabric, BrickColor.new("Dark stone grey"))
		addSubPart("LegFR", Vector3.new(0.5, 1.6, 0.5), CFrame.new(0.7, -1.0, -1.2), Enum.Material.Fabric, BrickColor.new("Dark stone grey"))
		addSubPart("LegBL", Vector3.new(0.55, 1.6, 0.55), CFrame.new(-0.7, -1.0, 1.2), Enum.Material.Fabric, BrickColor.new("Dark stone grey"))
		addSubPart("LegBR", Vector3.new(0.55, 1.6, 0.55), CFrame.new(0.7, -1.0, 1.2), Enum.Material.Fabric, BrickColor.new("Dark stone grey"))

		-- Пушистый хвост
		addSubPart("Tail", Vector3.new(0.6, 0.6, 2.0), CFrame.new(0, 0.4, 2.4) * CFrame.Angles(math.rad(-25), 0, 0), Enum.Material.Fabric, BrickColor.new("Medium stone grey"))

	elseif mobType == "Yeti" then
		-- ❄️ СНЕЖНЫЙ ЙЕТИ: Мощный ледяной торс, рога, ледяные лапы и бирюзовые глаза
		hrp.Size = Vector3.new(3.8, 4.5, 3.0)
		hrp.Material = Enum.Material.Fabric
		hrp.BrickColor = BrickColor.new("Pastel light blue")

		-- Голова
		addSubPart("Head", Vector3.new(2.4, 2.2, 2.2), CFrame.new(0, 3.2, -0.4), Enum.Material.Fabric, BrickColor.new("White"))
		
		-- Ледяные рога
		addSubPart("HornL", Vector3.new(0.6, 1.4, 0.6), CFrame.new(-1.3, 4.3, -0.4) * CFrame.Angles(0, 0, math.rad(-25)), Enum.Material.Ice, BrickColor.new("Pastel light blue"))
		addSubPart("HornR", Vector3.new(0.6, 1.4, 0.6), CFrame.new(1.3, 4.3, -0.4) * CFrame.Angles(0, 0, math.rad(25)), Enum.Material.Ice, BrickColor.new("Pastel light blue"))

		-- Светящиеся ледяные глаза
		addSubPart("EyeL", Vector3.new(0.4, 0.4, 0.4), CFrame.new(-0.6, 3.4, -1.4), Enum.Material.Neon, BrickColor.new("Cyan"))
		addSubPart("EyeR", Vector3.new(0.4, 0.4, 0.4), CFrame.new(0.6, 3.4, -1.4), Enum.Material.Neon, BrickColor.new("Cyan"))

		-- Мощные руки с ледяными когтями
		addSubPart("ArmL", Vector3.new(1.4, 4.4, 1.4), CFrame.new(-2.6, 0.4, 0), Enum.Material.Fabric, BrickColor.new("Pastel light blue"))
		addSubPart("ArmR", Vector3.new(1.4, 4.4, 1.4), CFrame.new(2.6, 0.4, 0), Enum.Material.Fabric, BrickColor.new("Pastel light blue"))

		-- 2 Массивные ноги
		addSubPart("LegL", Vector3.new(1.6, 3.0, 1.6), CFrame.new(-1.2, -2.8, 0), Enum.Material.Fabric, BrickColor.new("Pastel light blue"))
		addSubPart("LegR", Vector3.new(1.6, 3.0, 1.6), CFrame.new(1.2, -2.8, 0), Enum.Material.Fabric, BrickColor.new("Pastel light blue"))

	elseif mobType == "Bigfoot" then
		-- 🦍 БИГФУТ: Огромный темно-бурый торс, массивная челюсть и янтарные глаза
		hrp.Size = Vector3.new(4.2, 5.0, 3.2)
		hrp.Material = Enum.Material.Fabric
		hrp.BrickColor = BrickColor.new("Reddish brown")

		-- Голова с тяжелым лбом
		addSubPart("Head", Vector3.new(2.6, 2.4, 2.4), CFrame.new(0, 3.5, -0.5), Enum.Material.Fabric, BrickColor.new("Dark orange"))
		addSubPart("Jaw", Vector3.new(1.8, 0.9, 1.2), CFrame.new(0, 2.7, -1.4), Enum.Material.Fabric, BrickColor.new("Reddish brown"))

		-- Светящиеся янтарные глаза
		addSubPart("EyeL", Vector3.new(0.4, 0.4, 0.4), CFrame.new(-0.65, 3.7, -1.6), Enum.Material.Neon, BrickColor.new("Deep orange"))
		addSubPart("EyeR", Vector3.new(0.4, 0.4, 0.4), CFrame.new(0.65, 3.7, -1.6), Enum.Material.Neon, BrickColor.new("Deep orange"))

		-- Длинные лапы-руки
		addSubPart("ArmL", Vector3.new(1.6, 5.0, 1.6), CFrame.new(-2.9, 0.5, 0), Enum.Material.Fabric, BrickColor.new("Reddish brown"))
		addSubPart("ArmR", Vector3.new(1.6, 5.0, 1.6), CFrame.new(2.9, 0.5, 0), Enum.Material.Fabric, BrickColor.new("Reddish brown"))

		-- 2 Ноги-колонны
		addSubPart("LegL", Vector3.new(1.8, 3.2, 1.8), CFrame.new(-1.3, -3.0, 0), Enum.Material.Fabric, BrickColor.new("Dark orange"))
		addSubPart("LegR", Vector3.new(1.8, 3.2, 1.8), CFrame.new(1.3, -3.0, 0), Enum.Material.Fabric, BrickColor.new("Dark orange"))
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
	hrp.Position = spawnPos
	hrp.Anchored = false
	hrp.CanCollide = true
	hrp.Parent = mobModel
	mobModel.PrimaryPart = hrp

	attachEnemyVisuals(mobModel, mobType, hrp)

	local humanoid = Instance.new("Humanoid")
	humanoid.MaxHealth = cfg.Hp
	humanoid.Health = cfg.Hp
	humanoid.WalkSpeed = cfg.Speed
	humanoid.Parent = mobModel


	-- Обработка гибели моба и выпадения шкуры
	humanoid.Died:Connect(function()
		if cfg.Loot and math.random() <= cfg.Loot.Chance then
			-- Создание лута на земле
			local lootPart = Instance.new("Part")
			lootPart.Name = "Dropped_" .. cfg.Loot.Item
			lootPart.Size = Vector3.new(2, 1, 2)
			lootPart.Position = hrp.Position + Vector3.new(0, 1, 0)
			lootPart.Anchored = true
			lootPart.CanCollide = false
			lootPart.Material = Enum.Material.Fabric
			lootPart.BrickColor = (cfg.Loot.Item == "WolfPelt") and BrickColor.new("Dark stone grey") or BrickColor.new("White")
			lootPart.Parent = workspace:FindFirstChild("DroppedItems") or workspace

			local prompt = Instance.new("ProximityPrompt", lootPart)
			prompt.ActionText = string.format("Подобрать %s (x%d)", (cfg.Loot.Item == "WolfPelt" and "🐺 Шкуру волка" or "❄️ Шкуру Йети"), cfg.Loot.Count)
			prompt.ObjectText = "Трофей с монстра"
			prompt.HoldDuration = 0
			prompt.MaxActivationDistance = 14
			prompt.RequiresLineOfSight = false

			prompt.Triggered:Connect(function(player)
				local given = false
				if _G.GiveItemToPlayer then
					given = _G.GiveItemToPlayer(player, cfg.Loot.Item, cfg.Loot.Count)
				else
					local giveBindable = ReplicatedStorage:FindFirstChild("GiveItem")
					if giveBindable and giveBindable:IsA("BindableFunction") then
						given = giveBindable:Invoke(player, cfg.Loot.Item, cfg.Loot.Count)
					end
				end

				if not given then
					local ShowNotificationRemote = RemotesFolder:FindFirstChild("ShowNotification")
					if ShowNotificationRemote then
						ShowNotificationRemote:FireClient(player, "⚠️ Рюкзак полон! Освободите место, чтобы поднять шкуру.")
					end
					return
				end

				lootPart:Destroy()
				local ShowNotificationRemote = RemotesFolder:FindFirstChild("ShowNotification")
				if ShowNotificationRemote then
					ShowNotificationRemote:FireClient(player, string.format("🎒 Вы подобрали %s (x%d)!", (cfg.Loot.Item == "WolfPelt" and "🐺 Шкуру волка" or "❄️ Шкуру Йети"), cfg.Loot.Count))
				end
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
end

local function getGroundHeight(x, z)
	local rayOrigin = Vector3.new(x, 120, z)
	local rayDirection = Vector3.new(0, -180, 0)
	local raycastParams = RaycastParams.new()
	raycastParams.FilterType = Enum.RaycastFilterType.Include
	raycastParams.FilterDescendantsInstances = { workspace.Terrain }

	local result = workspace:Raycast(rayOrigin, rayDirection, raycastParams)
	if result then
		return result.Position.Y
	end
	return 2.5
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


