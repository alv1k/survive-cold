--[[
    StarterPlayer/StarterPlayerScripts/MobAnimationController.client.luau
    Клиентский контроллер процедурной анимации для монстров и питомцев (60 FPS):
    - Полная поддержка 3D Волка (Полярный Волк и Ледяной Волчонок)
    - Цикл Ходьбы (Wolf_Walk): 4-ногая диагональная рысь, кивок головы, виляние хвоста
    - Цикл Сна (Wolf_Sleep): сворачивание клубочком на снегу, поджатые лапки, плавное дыхание
    - Цикл Покоя (Idle): настороженная стойка и мягкое дыхание
    - Управление через нативный Motor6D.Transform (чистые вращения вокруг плечевых суставов без сдвигов)
--]]

local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local MobsFolder = Workspace:WaitForChild("Mobs", 10)
local PetsFolder = Workspace:WaitForChild("Pets", 10)

-- Хранилище состояния анимации
local animStates = {}

local function getAnimState(model)
	if not animStates[model] then
		animStates[model] = {
			walkPhase = math.random() * math.pi * 2,
			motors = {}
		}

		model.AncestryChanged:Connect(function(_, parent)
			if not parent then
				animStates[model] = nil
			end
		end)
	end
	return animStates[model]
end

local function cacheMotors(model, state)
	if #state.motors > 0 then return end

	for _, desc in ipairs(model:GetDescendants()) do
		if desc:IsA("Motor6D") then
			table.insert(state.motors, desc)
		end
	end
end

local function animateWolf(model, hrp, humanoid, dt)
	local state = getAnimState(model)
	cacheMotors(model, state)

	local speed = hrp.AssemblyLinearVelocity.Magnitude
	local isMoving = (speed > 0.5) or (humanoid and humanoid.MoveDirection.Magnitude > 0.1)
	local isSleeping = (model:GetAttribute("IsSleeping") == true) or (model:GetAttribute("Mode") == "stay_home")

	local targetMode = isSleeping and "Sleep" or (isMoving and "Walk" or "Idle")
	local timeNow = os.clock()

	-- Обновление фазы походки
	if isMoving then
		local stepRate = math.clamp(speed * 0.95, 4.0, 14.0)
		state.walkPhase = (state.walkPhase + dt * stepRate) % (math.pi * 2)
	end

	local isPup = (model:GetAttribute("IsWolfPup") == true) or (model:GetAttribute("PetId") == "Wolf")
	local walkT = state.walkPhase
	local breathe = math.sin(timeNow * 2.0) * 0.025
	local sleepBreathe = math.sin(timeNow * 1.5) * 0.04

	for _, motor in ipairs(state.motors) do
		if not motor or not motor.Parent then continue end
		local mName = motor.Name

		if targetMode == "Walk" then
			-- =========================================================
			-- АНИМАЦИЯ ХОДЬБЫ / РЫСИ (Wolf_Walk / Puppy_Trot)
			-- =========================================================
			local legStride = isPup and 0.60 or 0.52
			if mName == "Joint_FL" then
				local rotX = math.sin(walkT) * legStride
				motor.Transform = motor.Transform:Lerp(CFrame.Angles(rotX, 0, 0), 0.35)
			elseif mName == "Joint_FR" then
				local rotX = -math.sin(walkT) * legStride
				motor.Transform = motor.Transform:Lerp(CFrame.Angles(rotX, 0, 0), 0.35)
			elseif mName == "Joint_BL" then
				local rotX = -math.sin(walkT) * (legStride * 0.9)
				motor.Transform = motor.Transform:Lerp(CFrame.Angles(rotX, 0, 0), 0.35)
			elseif mName == "Joint_BR" then
				local rotX = math.sin(walkT) * (legStride * 0.9)
				motor.Transform = motor.Transform:Lerp(CFrame.Angles(rotX, 0, 0), 0.35)
			elseif mName == "TailJoint" then
				-- У щенка хвостик задорно и быстро виляет при беге
				local tailWag = isPup and (math.sin(timeNow * 8.0) * 0.55) or (math.sin(walkT * 0.8) * 0.42)
				motor.Transform = motor.Transform:Lerp(CFrame.Angles(math.rad(isPup and 15 or -5), tailWag, 0), 0.35)
			elseif mName == "NeckJoint" then
				local bobX = math.abs(math.sin(walkT)) * (isPup and 0.14 or 0.10) - 0.05
				local tiltZ = isPup and (math.sin(walkT * 0.5) * 0.08) or 0
				motor.Transform = motor.Transform:Lerp(CFrame.Angles(bobX, 0, tiltZ), 0.3)
			elseif mName == "RootJoint" then
				local bounceY = math.abs(math.sin(walkT)) * (isPup and 0.08 or 0.05)
				motor.Transform = motor.Transform:Lerp(CFrame.new(0, bounceY, 0), 0.3)
			end

		elseif targetMode == "Sleep" then
			-- =========================================================
			-- АНИМАЦИЯ СНА (Wolf_Sleep / Puppy_Cuddle)
			-- =========================================================
			if mName == "Joint_FL" then
				motor.Transform = motor.Transform:Lerp(CFrame.Angles(math.rad(68), math.rad(-15), math.rad(10)), 0.2)
			elseif mName == "Joint_FR" then
				motor.Transform = motor.Transform:Lerp(CFrame.Angles(math.rad(62), math.rad(18), math.rad(-12)), 0.2)
			elseif mName == "Joint_BL" then
				motor.Transform = motor.Transform:Lerp(CFrame.Angles(math.rad(78), math.rad(-22), math.rad(15)), 0.2)
			elseif mName == "Joint_BR" then
				motor.Transform = motor.Transform:Lerp(CFrame.Angles(math.rad(72), math.rad(20), math.rad(-15)), 0.2)
			elseif mName == "TailJoint" then
				motor.Transform = motor.Transform:Lerp(CFrame.Angles(math.rad(-25), 0, math.rad(-45)), 0.2)
			elseif mName == "NeckJoint" then
				motor.Transform = motor.Transform:Lerp(CFrame.Angles(math.rad(-18 + sleepBreathe * 15), 0, math.rad(-22)), 0.2)
			elseif mName == "RootJoint" then
				motor.Transform = motor.Transform:Lerp(CFrame.new(0, -0.18 + sleepBreathe * 0.5, 0) * CFrame.Angles(math.rad(-5), math.rad(-8), math.rad(12)), 0.2)
			end

		else
			-- =========================================================
			-- АНИМАЦИЯ ПОКОЯ (Idle / Happy Pup Wag)
			-- =========================================================
			if mName == "NeckJoint" then
				local headTilt = isPup and (math.sin(timeNow * 1.5) * 0.10) or 0
				motor.Transform = motor.Transform:Lerp(CFrame.Angles(breathe * 0.5, 0, headTilt), 0.25)
			elseif mName == "TailJoint" then
				-- В покое щенок радостно помахивает хвостиком
				local wag = isPup and (math.sin(timeNow * 4.5) * 0.40) or (math.sin(timeNow * 1.2) * 0.15)
				motor.Transform = motor.Transform:Lerp(CFrame.Angles(math.rad(isPup and 12 or -5), wag, 0), 0.25)
			else
				motor.Transform = motor.Transform:Lerp(CFrame.identity, 0.25)
			end
		end
	end
end

local function animateYeti(model, hrp, humanoid, dt)
	local state = getAnimState(model)
	cacheMotors(model, state)

	local speed = hrp.AssemblyLinearVelocity.Magnitude
	local isMoving = (speed > 0.5) or (humanoid and humanoid.MoveDirection.Magnitude > 0.1)
	local isRunning = isMoving and (speed > 5.5 or (humanoid and humanoid.WalkSpeed > 6.0))
	local targetMode = isRunning and "Run" or (isMoving and "Walk" or "Idle")
	local timeNow = os.clock()

	if isMoving then
		local stepRate = isRunning and math.clamp(speed * 0.85, 5.0, 11.0) or math.clamp(speed * 1.05, 2.5, 6.5)
		state.walkPhase = (state.walkPhase + dt * stepRate) % (math.pi * 2)
	end

	local walkT = state.walkPhase
	local breathe = math.sin(timeNow * 1.4) * 0.035

	for _, motor in ipairs(state.motors) do
		if not motor or not motor.Parent then continue end
		local mName = motor.Name

		if targetMode == "Run" then
			-- =========================================================
			-- АНИМАЦИЯ ЯРОСТНОГО БЕГА / ПОГОНИ (Yeti_Run)
			-- =========================================================
			if mName == "Joint_LegL" then
				local rotX = math.sin(walkT) * 0.72
				motor.Transform = motor.Transform:Lerp(CFrame.Angles(rotX, 0, 0), 0.35)
			elseif mName == "Joint_LegR" then
				local rotX = -math.sin(walkT) * 0.72
				motor.Transform = motor.Transform:Lerp(CFrame.Angles(rotX, 0, 0), 0.35)
			elseif mName == "Joint_ArmL" then
				local rotX = -math.sin(walkT) * 0.95 + math.rad(28)
				motor.Transform = motor.Transform:Lerp(CFrame.Angles(rotX, 0, math.rad(-14)), 0.35)
			elseif mName == "Joint_ArmR" then
				local rotX = math.sin(walkT) * 0.95 + math.rad(28)
				motor.Transform = motor.Transform:Lerp(CFrame.Angles(rotX, 0, math.rad(14)), 0.35)
			elseif mName == "WaistJoint" then
				local swayY = math.sin(walkT) * 0.18
				motor.Transform = motor.Transform:Lerp(CFrame.Angles(math.rad(22), swayY, 0), 0.3)
			elseif mName == "NeckJoint" then
				local headBob = math.sin(walkT * 2) * 0.08 - math.rad(15)
				motor.Transform = motor.Transform:Lerp(CFrame.Angles(headBob, 0, 0), 0.3)
			elseif mName == "RootJoint" then
				local bounceY = -math.abs(math.sin(walkT)) * 0.28
				motor.Transform = motor.Transform:Lerp(CFrame.new(0, bounceY, 0), 0.3)
			end

		elseif targetMode == "Walk" then
			-- =========================================================
			-- АНИМАЦИЯ ПАТРУЛЬНОЙ ХОДЬБЫ ГИГАНТА (Yeti_Walk)
			-- =========================================================
			if mName == "Joint_LegL" then
				local rotX = math.sin(walkT) * 0.45
				motor.Transform = motor.Transform:Lerp(CFrame.Angles(rotX, 0, 0), 0.3)
			elseif mName == "Joint_LegR" then
				local rotX = -math.sin(walkT) * 0.45
				motor.Transform = motor.Transform:Lerp(CFrame.Angles(rotX, 0, 0), 0.3)
			elseif mName == "Joint_ArmL" then
				local rotX = -math.sin(walkT) * 0.55
				motor.Transform = motor.Transform:Lerp(CFrame.Angles(rotX, 0, math.rad(-8)), 0.3)
			elseif mName == "Joint_ArmR" then
				local rotX = math.sin(walkT) * 0.55
				motor.Transform = motor.Transform:Lerp(CFrame.Angles(rotX, 0, math.rad(8)), 0.3)
			elseif mName == "WaistJoint" then
				local swayY = math.sin(walkT) * 0.12
				local tiltZ = -math.sin(walkT) * 0.08
				motor.Transform = motor.Transform:Lerp(CFrame.Angles(math.rad(6), swayY, tiltZ), 0.25)
			elseif mName == "NeckJoint" then
				local bobX = math.abs(math.sin(walkT)) * 0.08 - 0.04
				motor.Transform = motor.Transform:Lerp(CFrame.Angles(bobX, 0, 0), 0.25)
			elseif mName == "RootJoint" then
				local bounceY = -math.abs(math.sin(walkT)) * 0.14
				motor.Transform = motor.Transform:Lerp(CFrame.new(0, bounceY, 0), 0.25)
			end

		else
			-- =========================================================
			-- АНИМАЦИЯ ПОКОЯ ГИГАНТА (Idle)
			-- =========================================================
			if mName == "WaistJoint" then
				motor.Transform = motor.Transform:Lerp(CFrame.Angles(breathe * 0.6, 0, 0), 0.2)
			elseif mName == "NeckJoint" then
				motor.Transform = motor.Transform:Lerp(CFrame.Angles(breathe * 0.4, math.sin(timeNow * 0.8) * 0.06, 0), 0.2)
			elseif mName == "Joint_ArmL" then
				motor.Transform = motor.Transform:Lerp(CFrame.Angles(0, 0, math.rad(-6) + breathe * 0.2), 0.2)
			elseif mName == "Joint_ArmR" then
				motor.Transform = motor.Transform:Lerp(CFrame.Angles(0, 0, math.rad(6) - breathe * 0.2), 0.2)
			else
				motor.Transform = motor.Transform:Lerp(CFrame.identity, 0.2)
			end
		end
	end
end

local function animateFox(model, hrp, humanoid, dt)
	local state = getAnimState(model)
	cacheMotors(model, state)

	local speed = hrp.AssemblyLinearVelocity.Magnitude
	local isMoving = (speed > 0.5) or (humanoid and humanoid.MoveDirection.Magnitude > 0.1)
	local isSleeping = (model:GetAttribute("IsSleeping") == true) or (model:GetAttribute("Mode") == "stay_home")

	local targetMode = isSleeping and "Sleep" or (isMoving and "Walk" or "Idle")
	local timeNow = os.clock()

	if isMoving then
		local stepRate = math.clamp(speed * 1.05, 4.5, 15.0)
		state.walkPhase = (state.walkPhase + dt * stepRate) % (math.pi * 2)
	end

	local walkT = state.walkPhase
	local breathe = math.sin(timeNow * 2.2) * 0.025
	local sleepBreathe = math.sin(timeNow * 1.4) * 0.035

	for _, motor in ipairs(state.motors) do
		if not motor or not motor.Parent then continue end
		local mName = motor.Name

		if targetMode == "Walk" then
			-- 🦊 Грациозная быстрая рысь лисички
			local legStride = 0.58
			if mName == "Joint_FL" then
				local rotX = math.sin(walkT) * legStride
				motor.Transform = motor.Transform:Lerp(CFrame.Angles(rotX, 0, 0), 0.35)
			elseif mName == "Joint_FR" then
				local rotX = -math.sin(walkT) * legStride
				motor.Transform = motor.Transform:Lerp(CFrame.Angles(rotX, 0, 0), 0.35)
			elseif mName == "Joint_BL" then
				local rotX = -math.sin(walkT) * (legStride * 0.9)
				motor.Transform = motor.Transform:Lerp(CFrame.Angles(rotX, 0, 0), 0.35)
			elseif mName == "Joint_BR" then
				local rotX = math.sin(walkT) * (legStride * 0.9)
				motor.Transform = motor.Transform:Lerp(CFrame.Angles(rotX, 0, 0), 0.35)
			elseif mName == "TailJoint" then
				-- Большой лисий хвост плавно и красиво раскачивается
				local tailWag = math.sin(walkT * 0.9) * 0.55
				motor.Transform = motor.Transform:Lerp(CFrame.Angles(math.rad(18), tailWag, 0), 0.3)
			elseif mName == "NeckJoint" then
				local bobX = math.abs(math.sin(walkT)) * 0.12 - 0.04
				local tiltZ = math.sin(walkT * 0.5) * 0.10
				motor.Transform = motor.Transform:Lerp(CFrame.Angles(bobX, 0, tiltZ), 0.3)
			elseif mName == "RootJoint" then
				local bounceY = math.abs(math.sin(walkT)) * 0.08
				motor.Transform = motor.Transform:Lerp(CFrame.new(0, bounceY, 0), 0.3)
			end

		elseif targetMode == "Sleep" then
			-- 🦊 Лисичка сворачивается в уютный клубочек и укрывается пышным хвостом
			if mName == "Joint_FL" then
				motor.Transform = motor.Transform:Lerp(CFrame.Angles(math.rad(70), math.rad(-18), math.rad(12)), 0.2)
			elseif mName == "Joint_FR" then
				motor.Transform = motor.Transform:Lerp(CFrame.Angles(math.rad(65), math.rad(20), math.rad(-14)), 0.2)
			elseif mName == "Joint_BL" then
				motor.Transform = motor.Transform:Lerp(CFrame.Angles(math.rad(80), math.rad(-25), math.rad(18)), 0.2)
			elseif mName == "Joint_BR" then
				motor.Transform = motor.Transform:Lerp(CFrame.Angles(math.rad(75), math.rad(22), math.rad(-16)), 0.2)
			elseif mName == "TailJoint" then
				motor.Transform = motor.Transform:Lerp(CFrame.Angles(math.rad(-15), math.rad(60), math.rad(-30)), 0.2)
			elseif mName == "NeckJoint" then
				motor.Transform = motor.Transform:Lerp(CFrame.Angles(math.rad(-22 + sleepBreathe * 15), math.rad(-15), math.rad(-25)), 0.2)
			elseif mName == "RootJoint" then
				motor.Transform = motor.Transform:Lerp(CFrame.new(0, -0.16 + sleepBreathe * 0.5, 0) * CFrame.Angles(math.rad(-6), math.rad(-10), math.rad(14)), 0.2)
			end

		else
			-- 🦊 Покой: любопытные наклоны головы и взмахи хвостом
			if mName == "NeckJoint" then
				local headTilt = math.sin(timeNow * 1.6) * 0.14
				motor.Transform = motor.Transform:Lerp(CFrame.Angles(breathe * 0.6, 0, headTilt), 0.25)
			elseif mName == "TailJoint" then
				local wag = math.sin(timeNow * 2.8) * 0.38
				motor.Transform = motor.Transform:Lerp(CFrame.Angles(math.rad(16), wag, 0), 0.25)
			else
				motor.Transform = motor.Transform:Lerp(CFrame.identity, 0.25)
			end
		end
	end
end

local function animateBearCub(model, hrp, humanoid, dt)
	local state = getAnimState(model)
	cacheMotors(model, state)

	local speed = hrp.AssemblyLinearVelocity.Magnitude
	local isMoving = (speed > 0.5) or (humanoid and humanoid.MoveDirection.Magnitude > 0.1)
	local isSleeping = (model:GetAttribute("IsSleeping") == true) or (model:GetAttribute("Mode") == "stay_home")

	local targetMode = isSleeping and "Sleep" or (isMoving and "Walk" or "Idle")
	local timeNow = os.clock()

	if isMoving then
		local stepRate = math.clamp(speed * 0.85, 3.5, 11.0)
		state.walkPhase = (state.walkPhase + dt * stepRate) % (math.pi * 2)
	end

	local walkT = state.walkPhase
	local breathe = math.sin(timeNow * 1.8) * 0.02
	local sleepBreathe = math.sin(timeNow * 1.2) * 0.035

	for _, motor in ipairs(state.motors) do
		if not motor or not motor.Parent then continue end
		local mName = motor.Name

		if targetMode == "Walk" then
			-- 🐻 Походка медвежонка вперевалочку (милый waddle)
			local legStride = 0.48
			if mName == "Joint_FL" then
				local rotX = math.sin(walkT) * legStride
				motor.Transform = motor.Transform:Lerp(CFrame.Angles(rotX, 0, math.rad(-4)), 0.3)
			elseif mName == "Joint_FR" then
				local rotX = -math.sin(walkT) * legStride
				motor.Transform = motor.Transform:Lerp(CFrame.Angles(rotX, 0, math.rad(4)), 0.3)
			elseif mName == "Joint_BL" then
				local rotX = -math.sin(walkT) * (legStride * 0.85)
				motor.Transform = motor.Transform:Lerp(CFrame.Angles(rotX, 0, math.rad(-4)), 0.3)
			elseif mName == "Joint_BR" then
				local rotX = math.sin(walkT) * (legStride * 0.85)
				motor.Transform = motor.Transform:Lerp(CFrame.Angles(rotX, 0, math.rad(4)), 0.3)
			elseif mName == "TailJoint" then
				local tailWag = math.sin(walkT * 1.5) * 0.25
				motor.Transform = motor.Transform:Lerp(CFrame.Angles(0, tailWag, 0), 0.3)
			elseif mName == "NeckJoint" then
				local bobX = math.abs(math.sin(walkT)) * 0.08 - 0.03
				local tiltZ = -math.sin(walkT) * 0.08
				motor.Transform = motor.Transform:Lerp(CFrame.Angles(bobX, 0, tiltZ), 0.25)
			elseif mName == "RootJoint" then
				local rollZ = math.sin(walkT) * 0.06 -- покачивание боками при шаге
				local bounceY = math.abs(math.sin(walkT)) * 0.06
				motor.Transform = motor.Transform:Lerp(CFrame.new(0, bounceY, 0) * CFrame.Angles(0, 0, rollZ), 0.25)
			end

		elseif targetMode == "Sleep" then
			-- 🐻 Медвежонок лежит клубочком, поджав толстенькие лапки
			if mName == "Joint_FL" then
				motor.Transform = motor.Transform:Lerp(CFrame.Angles(math.rad(60), math.rad(-12), math.rad(8)), 0.2)
			elseif mName == "Joint_FR" then
				motor.Transform = motor.Transform:Lerp(CFrame.Angles(math.rad(55), math.rad(15), math.rad(-10)), 0.2)
			elseif mName == "Joint_BL" then
				motor.Transform = motor.Transform:Lerp(CFrame.Angles(math.rad(68), math.rad(-16), math.rad(12)), 0.2)
			elseif mName == "Joint_BR" then
				motor.Transform = motor.Transform:Lerp(CFrame.Angles(math.rad(64), math.rad(16), math.rad(-12)), 0.2)
			elseif mName == "TailJoint" then
				motor.Transform = motor.Transform:Lerp(CFrame.Angles(math.rad(-10), 0, 0), 0.2)
			elseif mName == "NeckJoint" then
				motor.Transform = motor.Transform:Lerp(CFrame.Angles(math.rad(-14 + sleepBreathe * 12), 0, math.rad(-10)), 0.2)
			elseif mName == "RootJoint" then
				motor.Transform = motor.Transform:Lerp(CFrame.new(0, -0.16 + sleepBreathe * 0.5, 0) * CFrame.Angles(math.rad(-3), 0, math.rad(6)), 0.2)
			end

		else
			-- 🐻 Покой: спокойное глубокое дыхание и мягкие повороты головы
			if mName == "NeckJoint" then
				local headTurn = math.sin(timeNow * 1.0) * 0.08
				motor.Transform = motor.Transform:Lerp(CFrame.Angles(breathe * 0.5, headTurn, 0), 0.2)
			elseif mName == "TailJoint" then
				local wag = math.sin(timeNow * 1.5) * 0.15
				motor.Transform = motor.Transform:Lerp(CFrame.Angles(0, wag, 0), 0.2)
			else
				motor.Transform = motor.Transform:Lerp(CFrame.identity, 0.2)
			end
		end
	end
end

-- Главный цикл обновления кадров (60 FPS)
RunService.RenderStepped:Connect(function(dt)
	-- 1. Анимация монстров в MobsFolder
	if MobsFolder then
		for _, mob in ipairs(MobsFolder:GetChildren()) do
			if mob:IsA("Model") then
				local hrp = mob:FindFirstChild("HumanoidRootPart")
				local humanoid = mob:FindFirstChildOfClass("Humanoid")
				local mobType = mob:GetAttribute("MobType")

				if hrp and humanoid and humanoid.Health > 0 then
					if mobType == "Wolf" or mob.Name:find("Волк") or mob.Name:find("Wolf") then
						animateWolf(mob, hrp, humanoid, dt)
					elseif mobType == "Yeti" or mob.Name:find("Йети") or mob.Name:find("Yeti") or mobType == "Bigfoot" or mob.Name:find("Бигфут") or mob.Name:find("Bigfoot") then
						animateYeti(mob, hrp, humanoid, dt)
					end
				end
			end
		end
	end

	-- 2. Анимация питомцев в PetsFolder
	if PetsFolder then
		for _, pet in ipairs(PetsFolder:GetChildren()) do
			if pet:IsA("Model") then
				local hrp = pet.PrimaryPart or pet:FindFirstChild("HumanoidRootPart") or pet:FindFirstChild("Body")
				local humanoid = pet:FindFirstChildOfClass("Humanoid")
				local petId = pet:GetAttribute("PetId")

				if hrp and humanoid and humanoid.Health > 0 then
					if petId == "Wolf" or pet.Name:find("Волк") or pet.Name:find("Wolf") then
						animateWolf(pet, hrp, humanoid, dt)
					elseif petId == "Fox" or pet.Name:find("Лис") or pet.Name:find("Fox") then
						animateFox(pet, hrp, humanoid, dt)
					elseif petId == "Bear" or petId == "BearCub" or pet.Name:find("Медвед") or pet.Name:find("Bear") then
						animateBearCub(pet, hrp, humanoid, dt)
					end
				end
			end
		end
	end
end)
