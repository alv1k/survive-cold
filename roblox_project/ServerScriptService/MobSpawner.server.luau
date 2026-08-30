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
	hrp.Size = (mobType == "Wolf") and Vector3.new(2, 2, 4) or Vector3.new(4, 7, 4)
	hrp.Position = spawnPos
	hrp.Anchored = false
	hrp.CanCollide = true
	hrp.Material = Enum.Material.Fabric
	hrp.BrickColor = (mobType == "Wolf") and BrickColor.new("Medium stone grey") or ((mobType == "Yeti") and BrickColor.new("Pastel light blue") or BrickColor.new("Reddish brown"))
	hrp.Parent = mobModel
	mobModel.PrimaryPart = hrp

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
			lootPart.Material = Enum.Material.Fabric
			lootPart.BrickColor = (cfg.Loot.Item == "WolfPelt") and BrickColor.new("Dark stone grey") or BrickColor.new("White")
			lootPart.Parent = workspace:FindFirstChild("DroppedItems") or workspace

			local prompt = Instance.new("ProximityPrompt", lootPart)
			prompt.ActionText = string.format("Подобрать %s (x%d)", (cfg.Loot.Item == "WolfPelt" and "🐺 Шкуру волка" or "❄️ Шкуру Йети"), cfg.Loot.Count)
			prompt.ObjectText = "Трофей с монстра"
			prompt.HoldDuration = 0.3

			prompt.Triggered:Connect(function(player)
				local currentCount = player:GetAttribute(cfg.Loot.Item) or 0
				player:SetAttribute(cfg.Loot.Item, currentCount + cfg.Loot.Count)
				lootPart:Destroy()
				print(string.format("🎒 %s подобрал %dx %s!", player.Name, cfg.Loot.Count, cfg.Loot.Item))
			end)
		end

		task.delay(2, function()
			mobModel:Destroy()
		end)

		-- Респавн моба в восточной опасной зоне через 60 секунд
		task.delay(60, function()
			spawnMob(mobType, spawnPos)
		end)
	end)

	mobModel.Parent = MobsFolder
end

-- Спавн популяций мобов исключительно в Восточной Опасной Зоне (X >= 250)
local MOB_SPAWN_POINTS = {
	{ Type = "Wolf", Pos = Vector3.new(280, 4, -120) },
	{ Type = "Wolf", Pos = Vector3.new(340, 4, 180) },
	{ Type = "Wolf", Pos = Vector3.new(420, 4, -280) },
	{ Type = "Yeti", Pos = Vector3.new(320, 5, 290) },
	{ Type = "Yeti", Pos = Vector3.new(460, 5, -80) },
	{ Type = "Bigfoot", Pos = Vector3.new(500, 6, 150) }
}

for _, sp in ipairs(MOB_SPAWN_POINTS) do
	spawnMob(sp.Type, sp.Pos)
end

-- ИИ Патруля и Агро с жестким барьером безопасной зоны
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

				-- Поиск ближайшего игрока в радиусе агро (только если игрок зашел в восточную зону X >= 170)
				local targetPlayer = nil
				local closestDist = cfg.AggroRadius

				for _, player in ipairs(Players:GetPlayers()) do
					local char = player.Character
					if char and char:FindFirstChild("HumanoidRootPart") then
						local pHrp = char.HumanoidRootPart
						if pHrp.Position.X >= 170 then -- Игрок в опасной зоне!
							local dist = (pHrp.Position - hrp.Position).Magnitude
							if dist < closestDist then
								closestDist = dist
								targetPlayer = pHrp
							end
						end
					end
				end

				if targetPlayer then
					-- Атака игрока
					humanoid:MoveTo(targetPlayer.Position)
					if closestDist < 5 then
						local pChar = targetPlayer.Parent
						local pHumanoid = pChar and pChar:FindFirstChild("Humanoid")
						if pHumanoid then
							pHumanoid:TakeDamage(cfg.Damage)
						end
					end
				else
					-- Патруль вокруг точки спавна в восточном лесу
					if hrp.Position.X < SAFE_ZONE_BARRIER_X then
						-- Авто-разворот при приближении к границе безопасной зоны!
						humanoid:MoveTo(spawnPos)
					else
						local offset = Vector3.new(math.random(-cfg.PatrolRadius, cfg.PatrolRadius), 0, math.random(-cfg.PatrolRadius, cfg.PatrolRadius))
						local targetPos = spawnPos + offset
						if targetPos.X < SAFE_ZONE_BARRIER_X then
							targetPos = Vector3.new(SAFE_ZONE_BARRIER_X + 20, targetPos.Y, targetPos.Z)
						end
						humanoid:MoveTo(targetPos)
					end
				end
			end
		end
	end
end)

