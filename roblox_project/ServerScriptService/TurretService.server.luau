--[[
    TurretService.server.luau
    Серверная система авто-прицеливания, вращения и стрельбы турелей по вражеским мобам.
--]]

local RunService = game:GetService("RunService")
local CollectionService = game:GetService("CollectionService")

local TurretsFolder = workspace:FindFirstChild("Turrets") or Instance.new("Folder", workspace)
TurretsFolder.Name = "Turrets"

local MobsFolder = workspace:FindFirstChild("Mobs") or Instance.new("Folder", workspace)
MobsFolder.Name = "Mobs"

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

-- Обработка стрельбы турелей
local function processTurret(turret)
	local head = turret:FindFirstChild("Head") or turret.PrimaryPart or turret:FindFirstChildWhichIsA("BasePart")
	if not head then return end
	
	local range = turret:GetAttribute("Range") or 30
	local damage = turret:GetAttribute("Damage") or 15
	local fireRate = turret:GetAttribute("FireRate") or 1.0 -- Пауза между выстрелами
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
			if targetHumanoid then
				targetHumanoid:TakeDamage(damage)
				
				-- Эффект выстрела (визуальный трассер)
				local tracer = Instance.new("Part")
				tracer.Size = Vector3.new(0.2, 0.2, (head.Position - targetHrp.Position).Magnitude)
				tracer.CFrame = CFrame.lookAt(head.Position, targetHrp.Position) * CFrame.new(0, 0, -tracer.Size.Z/2)
				tracer.Anchored = true
				tracer.CanCollide = false
				tracer.Material = Enum.Material.Neon
				tracer.BrickColor = BrickColor.new("Bright yellow")
				tracer.Parent = workspace
				
				task.delay(0.08, function()
					tracer:Destroy()
				end)
			end
		end
	end
end

-- Главный цикл обработки всех турелей каждые 0.1 секунды
task.spawn(function()
	while true do
		task.wait(0.1)
		for _, turret in ipairs(TurretsFolder:GetChildren()) do
			processTurret(turret)
		end
	end
end)
