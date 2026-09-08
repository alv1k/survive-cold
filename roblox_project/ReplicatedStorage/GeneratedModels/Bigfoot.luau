--[[
    ReplicatedStorage/GeneratedModels/Bigfoot.luau
    Высокоточный процедурный 3D-генератор Бигфута (Bigfoot / Sasquatch):
    - Увеличенный 4x масштаб (гигантский лесной босс-примат)
    - Богатая теплая коричневая цветовая палитра (wood_walnut, wood_cedar, wood_bark, leather_tan, leather_warm, soil_rich)
    - Полная система суставов Motor6D для 60 FPS анимаций ходьбы (Walk), яростного бега (Run) и дыхания (Idle)
    - Матовая цветовая палитра без свечения (Non-glowing SmoothPlastic/Fabric, без Neon и PointLight)
    - Мощный торс, загривок, сагиттальный гребень, уши, челюсть, 4 клыка, массивные лапы и ступни
--]]

local BigfootGenerator = {}

function BigfootGenerator.create(parent, targetCF, options)
	options = options or {}
	local scale = options.Scale or 4.0
	local isMob = (options.isMob == true) or (options.isAnimated == true)
	local isAnchored = (options.Anchored ~= false) and (not isMob)
	local isAnimated = (options.isAnimated ~= false) and isMob

	targetCF = targetCF or CFrame.new(0, 0, 0)
	local model = Instance.new("Model")
	model.Name = "Bigfoot"

	local function makePart(name, size, cfOffset, material, color, canCollide)
		local p = Instance.new("Part")
		p.Name = name
		p.Size = size * scale
		p.CFrame = targetCF * CFrame.new(cfOffset.Position * scale) * cfOffset.Rotation
		p.Material = material or Enum.Material.Fabric
		p.Color = color or Color3.fromRGB(92, 46, 11)
		p.Anchored = isAnchored
		p.CanCollide = (canCollide == true and isAnchored)
		p.Massless = not isAnchored
		p.CastShadow = true
		p.TopSurface = Enum.SurfaceType.Smooth
		p.BottomSurface = Enum.SurfaceType.Smooth
		p.Parent = model
		return p
	end

	local function makeWedge(name, size, cfOffset, material, color)
		local p = Instance.new("WedgePart")
		p.Name = name
		p.Size = size * scale
		p.CFrame = targetCF * CFrame.new(cfOffset.Position * scale) * cfOffset.Rotation
		p.Material = material or Enum.Material.Fabric
		p.Color = color or Color3.fromRGB(92, 46, 11)
		p.Anchored = isAnchored
		p.CanCollide = false
		p.Massless = not isAnchored
		p.CastShadow = true
		p.TopSurface = Enum.SurfaceType.Smooth
		p.BottomSurface = Enum.SurfaceType.Smooth
		p.Parent = model
		return p
	end

	local function weldParts(parentPart, childPart)
		local w = Instance.new("Weld")
		w.Name = "Weld_" .. childPart.Name
		w.Part0 = parentPart
		w.Part1 = childPart
		w.C0 = parentPart.CFrame:ToObjectSpace(childPart.CFrame)
		w.C1 = CFrame.identity
		w.Parent = childPart
		return w
	end

	-- Коричневая цветовая гамма Бигфута (матовая, без Neon/PointLight)
	local c_walnut = Color3.fromRGB(92, 46, 11)       -- wood_walnut (#5C2E0B) - основной темно-коричневый мех
	local c_cedar = Color3.fromRGB(140, 69, 26)       -- wood_cedar (#8C451A) - теплый коричневый мех
	local c_bark = Color3.fromRGB(62, 30, 8)          -- wood_bark (#3E1E08) - темная кора / когти / ступни
	local c_burnt = Color3.fromRGB(41, 37, 36)        -- wood_burnt (#292524) - надбровье
	local c_leather_tan = Color3.fromRGB(212, 163, 115) -- leather_tan (#D4A373) - кожа лица, уши
	local c_leather_warm = Color3.fromRGB(161, 98, 7) -- leather_warm (#A16207) - грудные пластины
	local c_soil = Color3.fromRGB(84, 51, 16)         -- soil_rich (#543310) - живот / бедра
	local c_eye = Color3.fromRGB(217, 119, 6)         -- copper_bronze (#D97706) - матовые янтарные глаза
	local c_teeth = Color3.fromRGB(255, 255, 255)     -- bone_ivory / snow_pure (#FFFFFF) - клыки

	-- =========================================================================
	-- 1. ТОРС, ВОРОТНИК, ГРУДЬ И ЗАГРИВОК (Torso)
	-- =========================================================================
	local torso = makePart("Torso", Vector3.new(2.6, 2.1, 1.9), CFrame.new(0, 2.4, 0), Enum.Material.Fabric, c_walnut, false)
	model.PrimaryPart = torso

	local furCollar = makePart("FurCollar", Vector3.new(2.9, 0.8, 2.2), CFrame.new(0, 3.15, -0.05), Enum.Material.Fabric, c_bark)
	local chestBulge = makePart("ChestBulge", Vector3.new(1.9, 1.4, 0.6), CFrame.new(0, 2.5, -0.90), Enum.Material.SmoothPlastic, c_leather_warm)
	local backHump = makePart("BackHump", Vector3.new(1.9, 1.3, 0.7), CFrame.new(0, 2.65, 0.90), Enum.Material.Fabric, c_walnut)
	local lowerTorso = makePart("LowerTorso", Vector3.new(2.2, 1.4, 1.7), CFrame.new(0, 1.3, 0.05), Enum.Material.Fabric, c_soil)

	weldParts(torso, furCollar)
	weldParts(torso, chestBulge)
	weldParts(torso, backHump)

	-- =========================================================================
	-- 2. ГОЛОВА, САГИТТАЛЬНЫЙ ГРЕБЕНЬ, МАСКА, КЛЫКИ И УШИ (Head)
	-- =========================================================================
	local head = makePart("Head", Vector3.new(1.7, 1.4, 1.6), CFrame.new(0, 3.9, -0.25), Enum.Material.Fabric, c_walnut)
	local sagittalCrest = makePart("SagittalCrest", Vector3.new(0.65, 0.55, 1.4), CFrame.new(0, 4.65, -0.2), Enum.Material.Fabric, c_cedar)
	local faceMask = makePart("FaceMask", Vector3.new(1.35, 0.95, 0.55), CFrame.new(0, 3.75, -0.95), Enum.Material.SmoothPlastic, c_leather_tan)
	local browRidge = makePart("BrowRidge", Vector3.new(1.4, 0.30, 0.40), CFrame.new(0, 4.15, -1.02), Enum.Material.SmoothPlastic, c_burnt)
	local apeNose = makePart("ApeNose", Vector3.new(0.55, 0.35, 0.25), CFrame.new(0, 3.82, -1.22), Enum.Material.SmoothPlastic, c_bark)

	-- Матовые янтарные глаза (SmoothPlastic, без Neon и PointLight)
	local eyeL = makePart("EyeL", Vector3.new(0.24, 0.18, 0.14), CFrame.new(-0.35, 4.0, -1.18), Enum.Material.SmoothPlastic, c_eye)
	local eyeR = makePart("EyeR", Vector3.new(0.24, 0.18, 0.14), CFrame.new(0.35, 4.0, -1.18), Enum.Material.SmoothPlastic, c_eye)

	-- 4 Клыка (Верхние и Нижние)
	local fangUL = makeWedge("Fang_UpperL", Vector3.new(0.14, 0.32, 0.14), CFrame.new(-0.35, 3.48, -1.22) * CFrame.Angles(math.rad(180), 0, 0), Enum.Material.SmoothPlastic, c_teeth)
	local fangUR = makeWedge("Fang_UpperR", Vector3.new(0.14, 0.32, 0.14), CFrame.new(0.35, 3.48, -1.22) * CFrame.Angles(math.rad(180), 0, 0), Enum.Material.SmoothPlastic, c_teeth)
	local fangLL = makeWedge("Fang_LowerL", Vector3.new(0.12, 0.28, 0.12), CFrame.new(-0.25, 3.65, -1.18), Enum.Material.SmoothPlastic, c_teeth)
	local fangLR = makeWedge("Fang_LowerR", Vector3.new(0.12, 0.28, 0.12), CFrame.new(0.25, 3.65, -1.18), Enum.Material.SmoothPlastic, c_teeth)

	-- Уши примата
	local earL = makePart("EarL", Vector3.new(0.25, 0.45, 0.35), CFrame.new(-0.95, 3.95, -0.2), Enum.Material.SmoothPlastic, c_leather_tan)
	local earR = makePart("EarR", Vector3.new(0.25, 0.45, 0.35), CFrame.new(0.95, 3.95, -0.2), Enum.Material.SmoothPlastic, c_leather_tan)

	local headParts = { sagittalCrest, faceMask, browRidge, apeNose, eyeL, eyeR, fangUL, fangUR, fangLL, fangLR, earL, earR }
	for _, p in ipairs(headParts) do
		weldParts(head, p)
	end

	-- =========================================================================
	-- 3. ДЛИННЫЕ МУСКУЛИСТЫЕ РУКИ И ТЯЖЕЛЫЕ ЛАПЫ-КУЛАКИ (Arms & Fists)
	-- =========================================================================
	local shoulderL = makePart("ShoulderL", Vector3.new(1.2, 1.4, 1.2), CFrame.new(-1.75, 2.7, -0.05), Enum.Material.Fabric, c_walnut)
	local tuftL = makePart("ShoulderTuftL", Vector3.new(0.8, 0.6, 0.8), CFrame.new(-2.0, 3.2, -0.05), Enum.Material.Fabric, c_cedar)
	local armL = makePart("ArmL", Vector3.new(1.1, 1.7, 1.1), CFrame.new(-1.95, 1.5, -0.15), Enum.Material.Fabric, c_soil)
	local forearmL = makePart("ForearmL", Vector3.new(1.15, 1.1, 1.15), CFrame.new(-1.95, 0.65, -0.20), Enum.Material.Fabric, c_cedar)
	local clawL = makePart("ClawL", Vector3.new(1.2, 0.8, 1.3), CFrame.new(-1.95, 0.15, -0.25), Enum.Material.SmoothPlastic, c_bark)
	weldParts(shoulderL, tuftL)
	weldParts(shoulderL, armL)
	weldParts(armL, forearmL)
	weldParts(forearmL, clawL)

	local shoulderR = makePart("ShoulderR", Vector3.new(1.2, 1.4, 1.2), CFrame.new(1.75, 2.7, -0.05), Enum.Material.Fabric, c_walnut)
	local tuftR = makePart("ShoulderTuftR", Vector3.new(0.8, 0.6, 0.8), CFrame.new(2.0, 3.2, -0.05), Enum.Material.Fabric, c_cedar)
	local armR = makePart("ArmR", Vector3.new(1.1, 1.7, 1.1), CFrame.new(1.95, 1.5, -0.15), Enum.Material.Fabric, c_soil)
	local forearmR = makePart("ForearmR", Vector3.new(1.15, 1.1, 1.15), CFrame.new(1.95, 0.65, -0.20), Enum.Material.Fabric, c_cedar)
	local clawR = makePart("ClawR", Vector3.new(1.2, 0.8, 1.3), CFrame.new(1.95, 0.15, -0.25), Enum.Material.SmoothPlastic, c_bark)
	weldParts(shoulderR, tuftR)
	weldParts(shoulderR, armR)
	weldParts(armR, forearmR)
	weldParts(forearmR, clawR)

	-- =========================================================================
	-- 4. МОЩНЫЕ НОГИ И ГИГАНТСКИЕ СТУПНИ БИГФУТА (Legs & Bigfoot Feet)
	-- =========================================================================
	local legL = makePart("LegL", Vector3.new(1.1, 1.4, 1.2), CFrame.new(-0.80, 0.85, 0.05), Enum.Material.Fabric, c_walnut)
	local footL = makePart("FootL", Vector3.new(1.2, 0.55, 1.6), CFrame.new(-0.80, 0.25, -0.18), Enum.Material.SmoothPlastic, c_bark)
	weldParts(legL, footL)

	local legR = makePart("LegR", Vector3.new(1.1, 1.4, 1.2), CFrame.new(0.80, 0.85, 0.05), Enum.Material.Fabric, c_walnut)
	local footR = makePart("FootR", Vector3.new(1.2, 0.55, 1.6), CFrame.new(0.80, 0.25, -0.18), Enum.Material.SmoothPlastic, c_bark)
	weldParts(legR, footR)

	-- =========================================================================
	-- 5. ШАРНИРНЫЕ СУСТАВЫ MOTOR6D (ДЛЯ 60 FPS АНИМАЦИИ WALK, RUN, IDLE)
	-- =========================================================================
	local function bindLimbMotor(jointName, part0, part1, pivotWorldPos)
		local pivotCF = targetCF * CFrame.new(pivotWorldPos * scale)
		if isAnimated then
			local motor = Instance.new("Motor6D")
			motor.Name = jointName
			motor.Part0 = part0
			motor.Part1 = part1
			motor.C0 = part0.CFrame:ToObjectSpace(pivotCF)
			motor.C1 = part1.CFrame:ToObjectSpace(pivotCF)
			motor:SetAttribute("RestC0", motor.C0)
			motor:SetAttribute("RestC1", motor.C1)
			motor.Parent = part0
			return motor
		else
			return weldParts(part0, part1)
		end
	end

	-- Поясной сустав (WaistJoint)
	bindLimbMotor("WaistJoint", torso, lowerTorso, Vector3.new(0, 1.8, 0))

	-- Шейный сустав (NeckJoint)
	bindLimbMotor("NeckJoint", torso, head, Vector3.new(0, 3.3, -0.1))

	-- Плечевые суставы (Shoulder_L, Shoulder_R)
	bindLimbMotor("Joint_ArmL", torso, shoulderL, Vector3.new(-1.75, 3.1, -0.05))
	bindLimbMotor("Joint_ArmR", torso, shoulderR, Vector3.new(1.75, 3.1, -0.05))

	-- Тазобедренные суставы (Joint_LegL, Joint_LegR)
	bindLimbMotor("Joint_LegL", lowerTorso, legL, Vector3.new(-0.80, 1.3, 0.05))
	bindLimbMotor("Joint_LegR", lowerTorso, legR, Vector3.new(0.80, 1.3, 0.05))

	model:SetAttribute("IsBigfootModel", true)
	model:SetAttribute("IsAnimatedModel", isAnimated)

	if parent then
		model.Parent = parent
	end

	return model
end

return BigfootGenerator
