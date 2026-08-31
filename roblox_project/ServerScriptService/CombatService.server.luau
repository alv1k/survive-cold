--[[
    CombatService.server.luau
    Серверный боевой сервис:
    - Ближний бой копьем (Spear)
    - Дальний бой рогаткой (Slingshot) со списанием камней из Ammo Pouch (Ammo_Slingshot)
    - Огнестрел револьвером (Revolver) со списанием пуль из Ammo Pouch (Ammo_Revolver)
    - Бонус баффа волка (+25% урона оружием)
--]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local RemotesFolder = ReplicatedStorage:FindFirstChild("Remotes") or Instance.new("Folder", ReplicatedStorage)
RemotesFolder.Name = "Remotes"

local AttackMeleeRemote = RemotesFolder:FindFirstChild("AttackMelee") or Instance.new("RemoteEvent", RemotesFolder)
AttackMeleeRemote.Name = "AttackMelee"

local ShootRangedRemote = RemotesFolder:FindFirstChild("ShootRanged") or Instance.new("RemoteEvent", RemotesFolder)
ShootRangedRemote.Name = "ShootRanged"

local MobsFolder = workspace:FindFirstChild("Mobs") or Instance.new("Folder", workspace)

-- Ближний бой копьем
AttackMeleeRemote.OnServerEvent:Connect(function(player, targetMob)
	local char = player.Character
	if not char or not char:FindFirstChild("HumanoidRootPart") then return end

	local wolfBuff = player:GetAttribute("WolfDamageBuff") or 1.0
	local damage = math.floor(30 * wolfBuff)

	if targetMob and targetMob:IsDescendantOf(MobsFolder) then
		local mobHrp = targetMob:FindFirstChild("HumanoidRootPart")
		local mobHumanoid = targetMob:FindFirstChild("Humanoid")
		if mobHrp and mobHumanoid and (mobHrp.Position - char.HumanoidRootPart.Position).Magnitude <= 18 then
			mobHumanoid:TakeDamage(damage)
			print(string.format("🗡️ %s нанес %d урона копьем по %s!", player.Name, damage, targetMob.Name))
		end
	end
end)

-- Дальний бой (Рогатка / Револьвер)
ShootRangedRemote.OnServerEvent:Connect(function(player, weaponType, targetMob)
	local char = player.Character
	if not char or not char:FindFirstChild("HumanoidRootPart") then return end

	local wolfBuff = player:GetAttribute("WolfDamageBuff") or 1.0

	if weaponType == "Slingshot" then
		local ammo = player:GetAttribute("Ammo_Slingshot") or 0
		if ammo <= 0 then return end
		player:SetAttribute("Ammo_Slingshot", ammo - 1)

		local damage = math.floor(22 * wolfBuff)
		if targetMob and targetMob:IsDescendantOf(MobsFolder) then
			local mobHumanoid = targetMob:FindFirstChild("Humanoid")
			if mobHumanoid then
				mobHumanoid:TakeDamage(damage)
				print(string.format("🏹 %s выстрелил из рогатки по %s (Урон: %d, Осталось камней: %d)", player.Name, targetMob.Name, damage, ammo - 1))
			end
		end

	elseif weaponType == "Revolver" then
		local ammo = player:GetAttribute("Ammo_Revolver") or 0
		if ammo <= 0 then return end
		player:SetAttribute("Ammo_Revolver", ammo - 1)

		local damage = math.floor(55 * wolfBuff)
		if targetMob and targetMob:IsDescendantOf(MobsFolder) then
			local mobHumanoid = targetMob:FindFirstChild("Humanoid")
			if mobHumanoid then
				mobHumanoid:TakeDamage(damage)
				print(string.format("💥 %s выстрелил из револьвера по %s (Урон: %d, Осталось пуль: %d)", player.Name, targetMob.Name, damage, ammo - 1))
			end
		end
	end
end)
