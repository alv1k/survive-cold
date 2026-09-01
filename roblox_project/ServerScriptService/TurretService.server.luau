--[[
    TurretService.server.luau
    Серверная система авто-прицеливания, стрельбы, поломки и починки турелей:
    - 🎯 Стрельба по вражеским мобам в радиусе поражения.
    - 🛡️ Прочность: 10 ударов/касаний мобов. При 0 турель ломается (IsBroken = true).
    - 🔧 Починка за 3 ⚙️ Детали через ProximityPrompt.
--]]

local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local TurretsFolder = workspace:FindFirstChild("Turrets") or Instance.new("Folder", workspace)
TurretsFolder.Name = "Turrets"

local MobsFolder = workspace:FindFirstChild("Mobs") or Instance.new("Folder", workspace)
MobsFolder.Name = "Mobs"

local RemotesFolder = ReplicatedStorage:FindFirstChild("Remotes") or Instance.new("Folder", ReplicatedStorage)
local ShowNotificationRemote = RemotesFolder:FindFirstChild("ShowNotification") or Instance.new("RemoteEvent", RemotesFolder)
ShowNotificationRemote.Name = "ShowNotification"

-- Кулдаун ударов каждого моба по турели
local mobTurretHitCooldowns = {}

-- Алгоритм выбора лучшей цели на основе расстояния и угрозы
local function findBestTarget(turretPart, range)
	local bestTarget = nil
	local highestScore = -math.huge

	for _, mob in ipairs(MobsFolder:GetChildren()) do
		local mobHrp = mob:FindFirstChild("HumanoidRootPart")
		local mobHumanoid = mob:FindFirstChild("Humanoid")

		if mobHrp and mobHumanoid and mobHumanoid.Health > 0 then
			local dist = (turretPart.Position - mobHrp.Position).Magnitude
			if dist <= range then
				local threatLevel = mob:GetAttribute("ThreatLevel") or 1
				local isAttackingFire = mob:GetAttribute("AttackingFire") or false

				local score = (100 / dist) + (threatLevel * 10)
				if isAttackingFire then
					score = score + 50
				end

				if score > highestScore then
					highestScore = score
					bestTarget = mob
				end
			end
		end
	end
	return bestTarget
end

-- Обновление визуального состояния и промпта турели
local function updateTurretVisuals(turret)
	local isBroken = turret:GetAttribute("IsBroken")
	local curDur = turret:GetAttribute("Durability") or 10
	local base = turret:FindFirstChild("Base") or turret.PrimaryPart
	local head = turret:FindFirstChild("Head")
	local statusLight = turret:FindFirstChild("StatusLight")
	local smoke = statusLight and statusLight:FindFirstChild("BrokenSmoke")
	local prompt = base and base:FindFirstChildOfClass("ProximityPrompt")

	if isBroken or curDur <= 0 then
		if statusLight then statusLight.BrickColor = BrickColor.new("Bright red") end
		if smoke then smoke.Enabled = true end
		if prompt then
			prompt.ObjectText = "🛠️ Сломанная турель"
			prompt.ActionText = "Починить (Требуется: 3 ⚙️ Детали)"
		end
	else
		if statusLight then
			statusLight.BrickColor = (curDur <= 3) and BrickColor.new("Bright yellow") or BrickColor.new("Bright green")
		end
		if smoke then smoke.Enabled = false end
		if prompt then
			prompt.ObjectText = turret.Name
			prompt.ActionText = string.format("Прочность: %d/10", curDur)
		end
	end
end

-- Подключение ProximityPrompt для починки турели
local function setupTurretInteraction(turret)
	local base = turret:FindFirstChild("Base") or turret.PrimaryPart
	if not base then return end

	local prompt = base:FindFirstChildOfClass("ProximityPrompt")
	if not prompt then
		prompt = Instance.new("ProximityPrompt", base)
		prompt.ActionText = "Прочность: 10/10"
		prompt.ObjectText = turret.Name
		prompt.HoldDuration = 0.5
		prompt.MaxActivationDistance = 10
		prompt.RequiresLineOfSight = false
	end

	if not turret:GetAttribute("PromptConnected") then
		turret:SetAttribute("PromptConnected", true)

		prompt.Triggered:Connect(function(player)
			local isBroken = turret:GetAttribute("IsBroken")
			local curDur = turret:GetAttribute("Durability") or 10

			if isBroken or curDur < 10 then
				local parts = player:GetAttribute("Parts") or 0
				if parts >= 3 then
					player:SetAttribute("Parts", parts - 3)
					turret:SetAttribute("Durability", 10)
					turret:SetAttribute("IsBroken", false)
					updateTurretVisuals(turret)
					ShowNotificationRemote:FireClient(player, "🔧 Турель успешно починена! (10/10 прочности, -3 ⚙️)")
					print(string.format("🔧 %s починил турель %s (-3 ⚙️)!", player.Name, turret.Name))
				else
					ShowNotificationRemote:FireClient(player, string.format("❌ Недостаточно деталей! Нужно 3 ⚙️ (у вас: %d)", parts))
				end
			else
				ShowNotificationRemote:FireClient(player, "🛡️ Турель полностью исправна (10/10).")
			end
		end)
	end
end

-- Обработка стрельбы турелей
local function processTurret(turret)
	setupTurretInteraction(turret)

	local isBroken = turret:GetAttribute("IsBroken")
	local curDur = turret:GetAttribute("Durability") or 10
	if isBroken or curDur <= 0 then
		return
	end

	local head = turret:FindFirstChild("Head") or turret.PrimaryPart or turret:FindFirstChildWhichIsA("BasePart")
	if not head then return end

	local range = turret:GetAttribute("Range") or 40
	local damage = turret:GetAttribute("Damage") or 20
	local fireRate = turret:GetAttribute("FireRate") or 1.0
	local lastFire = turret:GetAttribute("LastFire") or 0

	local target = findBestTarget(head, range)
	if target and target:FindFirstChild("HumanoidRootPart") then
		local targetHrp = target.HumanoidRootPart

		-- Вращение головы турели к цели
		head.CFrame = CFrame.lookAt(head.Position, Vector3.new(targetHrp.Position.X, head.Position.Y, targetHrp.Position.Z))

		-- Проверка отката стрельбы
		if os.clock() - lastFire >= fireRate then
			turret:SetAttribute("LastFire", os.clock())

			-- Нанесение урона мобу
			local targetHumanoid = target:FindFirstChild("Humanoid")
			if targetHumanoid and targetHumanoid.Health > 0 then
				targetHumanoid:TakeDamage(damage)

				-- Визуальный трассер выстрела
				local tracer = Instance.new("Part")
				tracer.Size = Vector3.new(0.25, 0.25, (head.Position - targetHrp.Position).Magnitude)
				tracer.CFrame = CFrame.lookAt(head.Position, targetHrp.Position) * CFrame.new(0, 0, -tracer.Size.Z / 2)
				tracer.Anchored = true
				tracer.CanCollide = false
				tracer.Material = Enum.Material.Neon
				tracer.BrickColor = (damage >= 35) and BrickColor.new("Bright orange") or BrickColor.new("Bright yellow")
				tracer.Parent = workspace

				task.delay(0.08, function()
					tracer:Destroy()
				end)
			end
		end
	end
end

-- Проверка урона турелям от приблизившихся мобов
local function checkMobAttacksOnTurrets()
	for _, turret in ipairs(TurretsFolder:GetChildren()) do
		local isBroken = turret:GetAttribute("IsBroken")
		local curDur = turret:GetAttribute("Durability") or 10
		local base = turret:FindFirstChild("Base") or turret.PrimaryPart

		if base and not isBroken and curDur > 0 then
			local tPos = base.Position
			for _, mob in ipairs(MobsFolder:GetChildren()) do
				local mHrp = mob:FindFirstChild("HumanoidRootPart")
				local mHum = mob:FindFirstChild("Humanoid")
				if mHrp and mHum and mHum.Health > 0 then
					local dist = (mHrp.Position - tPos).Magnitude
					if dist <= 5.5 then
						local cdKey = tostring(turret) .. "_" .. tostring(mob)
						local now = os.clock()
						if not mobTurretHitCooldowns[cdKey] or (now - mobTurretHitCooldowns[cdKey] >= 1.0) then
							mobTurretHitCooldowns[cdKey] = now

							curDur = math.max(0, curDur - 1)
							turret:SetAttribute("Durability", curDur)

							-- Вспышка урона на турели
							local head = turret:FindFirstChild("Head")
							if head then
								local oldColor = head.BrickColor
								head.BrickColor = BrickColor.new("Bright red")
								task.delay(0.15, function()
									if head and head.Parent then
										head.BrickColor = oldColor
									end
								end)
							end

							if curDur <= 0 then
								turret:SetAttribute("IsBroken", true)
								updateTurretVisuals(turret)
								print(string.format("💥 Турель %s сломана врагом %s (10/10 ударов)!", turret.Name, mob.Name))
								break
							else
								updateTurretVisuals(turret)
								print(string.format("🛡️ Враг %s ударил турель %s! (Осталось прочности: %d/10)", mob.Name, turret.Name, curDur))
							end
						end
					end
				end
			end
		end
	end
end

-- Главный цикл обработки стрельбы и износа турелей каждые 0.1 секунды
task.spawn(function()
	while true do
		task.wait(0.1)
		for _, turret in ipairs(TurretsFolder:GetChildren()) do
			processTurret(turret)
		end
		checkMobAttacksOnTurrets()
	end
end)

print("🏹 [TurretService] Система авто-турелей с прочностью 10 ударов и починкой за 3 детали готова!")
