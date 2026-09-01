--[[
    CombatService.server.luau
    Серверный боевой сервис:
    - 🗡️ Копье (Spear): ближний бой, урон: 30, FireRate = 0.8с (радиус: 18)
    - 🏹 Праща (Slingshot): дальний бой, урон: 20, FireRate = 0.6с (радиус: 65, Ammo_Slingshot)
    - 🔫 Револьвер (Revolver): огнестрел, урон: 55, FireRate = 0.35с (радиус: 90, Ammo_Revolver)
    - 🐺 Бонус баффа волка (+25% к урону любым оружием)
    - ⚡ Жесткий контроль темпа стрельбы/ударов (FireRate) на сервере
--]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")

local RemotesFolder = ReplicatedStorage:FindFirstChild("Remotes") or Instance.new("Folder", ReplicatedStorage)
RemotesFolder.Name = "Remotes"

local AttackMeleeRemote = RemotesFolder:FindFirstChild("AttackMelee") or Instance.new("RemoteEvent", RemotesFolder)
AttackMeleeRemote.Name = "AttackMelee"

local ShootRangedRemote = RemotesFolder:FindFirstChild("ShootRanged") or Instance.new("RemoteEvent", RemotesFolder)
ShootRangedRemote.Name = "ShootRanged"

local ShowNotificationRemote = RemotesFolder:FindFirstChild("ShowNotification") or Instance.new("RemoteEvent", RemotesFolder)
ShowNotificationRemote.Name = "ShowNotification"

local MobsFolder = workspace:FindFirstChild("Mobs") or Instance.new("Folder", workspace)
MobsFolder.Name = "Mobs"

local WEAPON_CONFIGS = {
	Spear = {
		Name = "🗡️ Копье",
		Type = "Melee",
		Damage = 30,
		FireRate = 0.8,
		Range = 18
	},
	Slingshot = {
		Name = "🏹 Праща",
		Type = "Ranged",
		Damage = 20,
		FireRate = 0.6,
		Range = 65,
		AmmoType = "Ammo_Slingshot"
	},
	Revolver = {
		Name = "🔫 Револьвер",
		Type = "Ranged",
		Damage = 55,
		FireRate = 0.35,
		Range = 90,
		AmmoType = "Ammo_Revolver"
	}
}

local playerLastFireTimes = {}

-- Поиск лучшей цели-моба перед персонажем
local function findMobInFront(char, maxRange)
	local hrp = char:FindFirstChild("HumanoidRootPart")
	if not hrp then return nil end

	local bestMob = nil
	local bestDist = maxRange

	for _, mob in ipairs(MobsFolder:GetChildren()) do
		local mHrp = mob:FindFirstChild("HumanoidRootPart")
		local mHum = mob:FindFirstChild("Humanoid")
		if mHrp and mHum and mHum.Health > 0 then
			local dist = (mHrp.Position - hrp.Position).Magnitude
			if dist <= bestDist then
				-- Проверка направления взгляда (в секторе перед игроком)
				local toMob = (mHrp.Position - hrp.Position).Unit
				local look = hrp.CFrame.LookVector
				local dot = look:Dot(toMob)
				if dot > 0.15 or dist < 6 then
					bestDist = dist
					bestMob = mob
				end
			end
		end
	end

	return bestMob
end

-- Единая функция выполнения атаки оружием с проверкой FireRate
local function executeWeaponAttack(player, weaponType, targetMob)
	local cfg = WEAPON_CONFIGS[weaponType]
	if not cfg then return false end

	local char = player.Character
	if not char or not char:FindFirstChild("HumanoidRootPart") then return false end
	local hrp = char.HumanoidRootPart

	-- 1. Проверка FireRate (кулдаун атаки)
	local cdKey = tostring(player.UserId) .. "_" .. weaponType
	local now = os.clock()
	local lastFire = playerLastFireTimes[cdKey] or 0
	if now - lastFire < cfg.FireRate then
		return false -- Атака еще на перезарядке
	end
	playerLastFireTimes[cdKey] = now

	local wolfBuff = player:GetAttribute("WolfDamageBuff") or 1.0
	local finalDamage = math.floor(cfg.Damage * wolfBuff)

	-- 2. Обработка Ближнего боя (Копье)
	if cfg.Type == "Melee" then
		local mob = targetMob or findMobInFront(char, cfg.Range)
		if mob and mob:IsDescendantOf(MobsFolder) then
			local mHrp = mob:FindFirstChild("HumanoidRootPart")
			local mHum = mob:FindFirstChild("Humanoid")
			if mHrp and mHum and mHum.Health > 0 and (mHrp.Position - hrp.Position).Magnitude <= cfg.Range then
				mHum:TakeDamage(finalDamage)

				-- Визуальный эффект удара копьем
				local slash = Instance.new("Part")
				slash.Size = Vector3.new(1.8, 0.2, 1.8)
				slash.Position = mHrp.Position + Vector3.new(0, 0.5, 0)
				slash.Anchored = true
				slash.CanCollide = false
				slash.Material = Enum.Material.Neon
				slash.BrickColor = BrickColor.new("Bright yellow")
				slash.Parent = workspace
				task.delay(0.06, function() slash:Destroy() end)

				print(string.format("🗡️ %s нанес %d урона копьем по %s! (Темп: %.2fc)", player.Name, finalDamage, mob.Name, cfg.FireRate))
				return true
			end
		end
		return true
	end

	-- 3. Обработка Дальнего боя (Праща / Револьвер)
	if cfg.Type == "Ranged" then
		local ammo = player:GetAttribute(cfg.AmmoType) or 0
		if ammo <= 0 then
			local ammoName = (weaponType == "Slingshot") and "снарядов для пращи" or "патронов для револьвера"
			ShowNotificationRemote:FireClient(player, string.format("⚠️ Нет %s! Изготовьте их на верстаке.", ammoName))
			return false
		end

		player:SetAttribute(cfg.AmmoType, ammo - 1)

		local mob = targetMob or findMobInFront(char, cfg.Range)
		local endPos = hrp.Position + hrp.CFrame.LookVector * cfg.Range

		if mob and mob:IsDescendantOf(MobsFolder) then
			local mHrp = mob:FindFirstChild("HumanoidRootPart")
			local mHum = mob:FindFirstChild("Humanoid")
			if mHrp and mHum and mHum.Health > 0 then
				local dist = (mHrp.Position - hrp.Position).Magnitude
				if dist <= cfg.Range then
					endPos = mHrp.Position
					mHum:TakeDamage(finalDamage)
					print(string.format("🎯 %s выстрелил из %s по %s! Урон: %d (Темп: %.2fc, Осталось: %d)", player.Name, cfg.Name, mob.Name, finalDamage, cfg.FireRate, ammo - 1))
				end
			end
		end

		-- Визуальный трассер выстрела
		local startPos = hrp.Position + Vector3.new(0, 1.2, 0) + hrp.CFrame.LookVector * 1.5
		local tracer = Instance.new("Part")
		local length = (endPos - startPos).Magnitude
		tracer.Size = (weaponType == "Revolver") and Vector3.new(0.2, 0.2, length) or Vector3.new(0.35, 0.35, length)
		tracer.CFrame = CFrame.lookAt(startPos, endPos) * CFrame.new(0, 0, -length / 2)
		tracer.Anchored = true
		tracer.CanCollide = false
		tracer.Material = Enum.Material.Neon
		tracer.BrickColor = (weaponType == "Revolver") and BrickColor.new("Bright orange") or BrickColor.new("Medium stone grey")
		tracer.Parent = workspace
		task.delay(0.06, function() tracer:Destroy() end)

		return true
	end

	return false
end

_G.ExecuteWeaponAttack = executeWeaponAttack

-- Обработчики RemoteEvents от клиента
AttackMeleeRemote.OnServerEvent:Connect(function(player, targetMob)
	executeWeaponAttack(player, "Spear", targetMob)
end)

ShootRangedRemote.OnServerEvent:Connect(function(player, weaponType, targetMob)
	executeWeaponAttack(player, weaponType or "Slingshot", targetMob)
end)

print("🗡️ [CombatService] Боевая система оружия с FireRate (Копье: 0.8с, Праща: 0.6с, Револьвер: 0.35с) готова!")
