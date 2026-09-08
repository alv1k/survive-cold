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

	local walkT = state.walkPhase
	local breathe = math.sin(timeNow * 2.0) * 0.025
	local sleepBreathe = math.sin(timeNow * 1.5) * 0.04

	for _, motor in ipairs(state.motors) do
		if not motor or not motor.Parent then continue end
		local mName = motor.Name

		if targetMode == "Walk" then
			-- =========================================================
			-- АНИМАЦИЯ ХОДЬБЫ / РЫСИ (Wolf_Walk)
			-- =========================================================
			if mName == "Joint_FL" then
				local rotX = math.sin(walkT) * 0.52
				motor.Transform = motor.Transform:Lerp(CFrame.Angles(rotX, 0, 0), 0.35)
			elseif mName == "Joint_FR" then
				local rotX = -math.sin(walkT) * 0.52
				motor.Transform = motor.Transform:Lerp(CFrame.Angles(rotX, 0, 0), 0.35)
			elseif mName == "Joint_BL" then
				local rotX = -math.sin(walkT) * 0.48
				motor.Transform = motor.Transform:Lerp(CFrame.Angles(rotX, 0, 0), 0.35)
			elseif mName == "Joint_BR" then
				local rotX = math.sin(walkT) * 0.48
				motor.Transform = motor.Transform:Lerp(CFrame.Angles(rotX, 0, 0), 0.35)
			elseif mName == "TailJoint" then
				local swayY = math.sin(walkT * 0.8) * 0.42
				motor.Transform = motor.Transform:Lerp(CFrame.Angles(math.rad(-5), swayY, 0), 0.3)
			elseif mName == "NeckJoint" then
				local bobX = math.abs(math.sin(walkT)) * 0.10 - 0.05
				motor.Transform = motor.Transform:Lerp(CFrame.Angles(bobX, 0, 0), 0.3)
			elseif mName == "RootJoint" then
				local bounceY = -math.abs(math.sin(walkT)) * 0.08
				motor.Transform = motor.Transform:Lerp(CFrame.new(0, bounceY, 0), 0.3)
			end

		elseif targetMode == "Sleep" then
			-- =========================================================
			-- АНИМАЦИЯ СНА (Wolf_Sleep)
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
				motor.Transform = motor.Transform:Lerp(CFrame.new(0, -0.48 + sleepBreathe, 0) * CFrame.Angles(math.rad(-5), math.rad(-8), math.rad(12)), 0.2)
			end

		else
			-- =========================================================
			-- АНИМАЦИЯ ПОКОЯ (Idle)
			-- =========================================================
			if mName == "NeckJoint" then
				motor.Transform = motor.Transform:Lerp(CFrame.Angles(breathe * 0.5, 0, 0), 0.25)
			elseif mName == "TailJoint" then
				motor.Transform = motor.Transform:Lerp(CFrame.Angles(math.rad(-5), math.sin(timeNow * 1.2) * 0.15, 0), 0.25)
			else
				motor.Transform = motor.Transform:Lerp(CFrame.identity, 0.25)
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
					end
				end
			end
		end
	end

	-- 2. Анимация питомцев в PetsFolder
	if PetsFolder then
		for _, pet in ipairs(PetsFolder:GetChildren()) do
			if pet:IsA("Model") then
				local hrp = pet.PrimaryPart or pet:FindFirstChild("Body") or pet:FindFirstChild("HumanoidRootPart")
				local humanoid = pet:FindFirstChildOfClass("Humanoid")
				local petId = pet:GetAttribute("PetId")

				if hrp and humanoid and humanoid.Health > 0 then
					if petId == "Wolf" or pet.Name:find("Волк") or pet.Name:find("Wolf") then
						animateWolf(pet, hrp, humanoid, dt)
					end
				end
			end
		end
	end
end)
