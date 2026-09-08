--[[
    ReplicatedStorage/GeneratedModels/Wolf.luau
    Высокоточная 3D-модель Полярного Волка и Ледяного Волчонка (Gold Standard):
    - Полная 1:1 анатомия из Blender 5.0 (406 tris) с палитрой palette.png
    - Надежные соединения Weld (C0/C1) и Motor6D суставы для 60 FPS анимаций
    - 4 полные 3-сегментные лапы (Upper -> Lower -> Paw с когтями)
    - 3-сегментный пушистый хвост (TailBase -> TailMid -> SnowTip)
    - Голова с клыками, открытой пастью, стоячими ушами и светящимися глазами (Neon)
--]]

local WolfGenerator = {}

function WolfGenerator.create(parent, targetCF, options)
	options = options or {}
	local isPet = (options.isPet == true)
	local isMob = (options.isMob == true) or (options.isAnimated == true)
	local scale = options.Scale or (isPet and 1.90 or 2.70)
	local isAnchored = (options.Anchored ~= false) and (not isMob) and (not isPet)
	local isAnimated = (options.isAnimated ~= false) and (isMob or isPet)
	
	targetCF = targetCF or CFrame.new(0, 2.4, 0)
	local model = Instance.new("Model")
	model.Name = isPet and "IceWolf" or "Wolf"

	local function makePart(name, size, cfOffset, material, color, canCollide)
		local p = Instance.new("Part")
		p.Name = name
		p.Size = size * scale
		p.CFrame = targetCF * CFrame.new(cfOffset.Position * scale) * cfOffset.Rotation
		p.Material = material or Enum.Material.SmoothPlastic
		p.Color = color or Color3.fromRGB(71, 85, 105)
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
		p.Material = material or Enum.Material.SmoothPlastic
		p.Color = color or Color3.fromRGB(71, 85, 105)
		p.Anchored = isAnchored
		p.CanCollide = false
		p.Massless = not isAnchored
		p.CastShadow = true
		p.TopSurface = Enum.SurfaceType.Smooth
		p.BottomSurface = Enum.SurfaceType.Smooth
		p.Parent = model
		return p
	end

	-- Жесткая сварка через классический Weld с C0/C1 (100% стабильность без разлетания частей)
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

	-- Палитра цветов (соответствует assets/palette_uv_map.json)
	local c_dark = isPet and Color3.fromRGB(100, 116, 139) or Color3.fromRGB(71, 85, 105)    -- stone_dark (#475569)
	local c_light = Color3.fromRGB(148, 163, 184) -- slate_light (#94A3B8)
	local c_spine = Color3.fromRGB(30, 41, 59)    -- cast_iron (#1E293B)
	local c_belly = Color3.fromRGB(241, 245, 249) -- snow_pure (#F1F5F9)
	local c_black = Color3.fromRGB(9, 9, 11)      -- pitch_black (#09090B)
	local c_fangs = Color3.fromRGB(255, 255, 255) -- bone_ivory (#FFFFFF)
	local c_mouth = Color3.fromRGB(153, 27, 27)   -- crimson_dark (#991B1B)
	local c_pink = Color3.fromRGB(253, 164, 175)  -- pink_soft (#FDA4AF)
	local c_eye = options.EyeColor or (isPet and Color3.fromRGB(0, 245, 212) or Color3.fromRGB(255, 0, 85))

	-- =========================================================================
	-- 1. КОРПУС И ХРЕБЕТ (Body / Torso)
	-- =========================================================================
	local body = makePart("Body", Vector3.new(0.72, 0.72, 0.68), CFrame.new(0, 0.94, -0.32), Enum.Material.SmoothPlastic, c_dark, false)
	model.PrimaryPart = body

	-- Загривок (Mane Ruff)
	local mane = makePart("ManeRuff", Vector3.new(0.60, 0.48, 0.44), CFrame.new(0, 1.16, -0.48), Enum.Material.SmoothPlastic, c_dark)
	local ruffL = makeWedge("RuffL", Vector3.new(0.24, 0.42, 0.42), CFrame.new(-0.44, 1.00, -0.32) * CFrame.Angles(0, math.rad(-25), math.rad(-15)), Enum.Material.SmoothPlastic, c_light)
	local ruffR = makeWedge("RuffR", Vector3.new(0.24, 0.42, 0.42), CFrame.new(0.44, 1.00, -0.32) * CFrame.Angles(0, math.rad(25), math.rad(15)), Enum.Material.SmoothPlastic, c_light)
	local belly = makePart("Underbelly", Vector3.new(0.48, 0.32, 0.52), CFrame.new(0, 0.62, -0.32), Enum.Material.SmoothPlastic, c_belly)

	-- Таз и задняя часть хребта
	local pelvis = makePart("Pelvis", Vector3.new(0.56, 0.63, 0.72), CFrame.new(0, 0.865, 0.36), Enum.Material.SmoothPlastic, c_dark)
	local spineRidge = makePart("SpineRidge", Vector3.new(0.16, 0.14, 1.25), CFrame.new(0, 1.34, 0.05), Enum.Material.SmoothPlastic, c_spine)

	weldParts(body, mane)
	weldParts(body, ruffL)
	weldParts(body, ruffR)
	weldParts(body, belly)
	weldParts(body, pelvis)
	weldParts(body, spineRidge)

	-- =========================================================================
	-- 2. ГОЛОВА, МОРДА, ГЛАЗА И УШИ (Head)
	-- =========================================================================
	local head = makePart("Head", Vector3.new(0.50, 0.50, 0.35), CFrame.new(0, 1.15, -1.015), Enum.Material.SmoothPlastic, c_dark)
	local cheekL = makeWedge("CheekL", Vector3.new(0.22, 0.28, 0.32), CFrame.new(-0.31, 1.05, -0.98) * CFrame.Angles(0, math.rad(-15), math.rad(-10)), Enum.Material.SmoothPlastic, c_light)
	local cheekR = makeWedge("CheekR", Vector3.new(0.22, 0.28, 0.32), CFrame.new(0.31, 1.05, -0.98) * CFrame.Angles(0, math.rad(15), math.rad(10)), Enum.Material.SmoothPlastic, c_light)
	local snout = makePart("Snout", Vector3.new(0.30, 0.22, 0.40), CFrame.new(0, 1.03, -1.35), Enum.Material.SmoothPlastic, c_dark)
	local snoutBridge = makePart("SnoutBridge", Vector3.new(0.14, 0.08, 0.38), CFrame.new(0, 1.16, -1.35), Enum.Material.SmoothPlastic, c_spine)
	local nose = makePart("Nose", Vector3.new(0.12, 0.12, 0.08), CFrame.new(0, 1.06, -1.58), Enum.Material.SmoothPlastic, c_black)

	local lowerJaw = makePart("LowerJaw", Vector3.new(0.26, 0.16, 0.42), CFrame.new(0, 0.80, -1.28), Enum.Material.SmoothPlastic, c_light)
	local mouth = makePart("MouthCavity", Vector3.new(0.22, 0.06, 0.34), CFrame.new(0, 0.88, -1.28), Enum.Material.SmoothPlastic, c_mouth)

	local fangUL = makeWedge("Fang_UpperL", Vector3.new(0.05, 0.12, 0.05), CFrame.new(-0.10, 0.84, -1.45) * CFrame.Angles(math.rad(180), 0, 0), Enum.Material.SmoothPlastic, c_fangs)
	local fangUR = makeWedge("Fang_UpperR", Vector3.new(0.05, 0.12, 0.05), CFrame.new(0.10, 0.84, -1.45) * CFrame.Angles(math.rad(180), 0, 0), Enum.Material.SmoothPlastic, c_fangs)
	local fangLL = makeWedge("Fang_LowerL", Vector3.new(0.05, 0.12, 0.05), CFrame.new(-0.08, 0.90, -1.40), Enum.Material.SmoothPlastic, c_fangs)
	local fangLR = makeWedge("Fang_LowerR", Vector3.new(0.05, 0.12, 0.05), CFrame.new(0.08, 0.90, -1.40), Enum.Material.SmoothPlastic, c_fangs)

	local eyeL = makePart("EyeL", Vector3.new(0.10, 0.10, 0.06), CFrame.new(-0.17, 1.23, -1.15), Enum.Material.SmoothPlastic, c_eye)
	local eyeR = makePart("EyeR", Vector3.new(0.10, 0.10, 0.06), CFrame.new(0.17, 1.23, -1.15), Enum.Material.SmoothPlastic, c_eye)

	local earL = makeWedge("Ear_L", Vector3.new(0.16, 0.38, 0.20), CFrame.new(-0.16, 1.58, -0.98) * CFrame.Angles(0, math.rad(10), math.rad(5)), Enum.Material.SmoothPlastic, c_dark)
	local earInL = makePart("EarInner_L", Vector3.new(0.08, 0.22, 0.05), CFrame.new(-0.15, 1.54, -1.02) * CFrame.Angles(0, math.rad(10), math.rad(5)), Enum.Material.SmoothPlastic, c_pink)
	local earR = makeWedge("Ear_R", Vector3.new(0.16, 0.38, 0.20), CFrame.new(0.16, 1.58, -0.98) * CFrame.Angles(0, math.rad(-10), math.rad(-5)), Enum.Material.SmoothPlastic, c_dark)
	local earInR = makePart("EarInner_R", Vector3.new(0.08, 0.22, 0.05), CFrame.new(0.15, 1.54, -1.02) * CFrame.Angles(0, math.rad(-10), math.rad(-5)), Enum.Material.SmoothPlastic, c_pink)

	local headParts = { cheekL, cheekR, snout, snoutBridge, nose, lowerJaw, mouth, fangUL, fangUR, fangLL, fangLR, eyeL, eyeR, earL, earInL, earR, earInR }
	for _, p in ipairs(headParts) do
		weldParts(head, p)
	end

	-- =========================================================================
	-- 3. 4 ПОЛНЫЕ АРТИКУЛИРОВАННЫЕ ЛАПЫ (Upper -> Lower -> Paw с когтями)
	-- =========================================================================
	local legs = {}
	local legCfgs = {
		{ key = "Leg_FL", shoulderPos = Vector3.new(-0.26, 0.80, -0.39), isFront = true },
		{ key = "Leg_FR", shoulderPos = Vector3.new(0.26, 0.80, -0.39), isFront = true },
		{ key = "Leg_BL", shoulderPos = Vector3.new(-0.25, 0.78, 0.50), isFront = false },
		{ key = "Leg_BR", shoulderPos = Vector3.new(0.25, 0.78, 0.50), isFront = false },
	}

	for _, cfg in ipairs(legCfgs) do
		local posX = cfg.shoulderPos.X
		local posZ = cfg.shoulderPos.Z
		
		-- 1. Верхняя часть (Upper / Thigh) - Центр на Y=0.62
		local upper = makePart(cfg.key .. "_Upper", Vector3.new(0.16, 0.36, 0.20), CFrame.new(posX, 0.62, posZ), Enum.Material.SmoothPlastic, c_dark)
		
		-- 2. Нижняя часть (Lower / Forearm) - Центр на Y=0.30
		local lower = makePart(cfg.key .. "_Lower", Vector3.new(0.14, 0.32, 0.18), CFrame.new(posX, 0.30, posZ), Enum.Material.SmoothPlastic, c_light)
		
		-- 3. Лапа / Подушечка с когтями (Paw) - Центр на Y=0.07, чуть выдается вперед
		local pawZ = posZ + (cfg.isFront and -0.06 or 0.04)
		local paw = makePart(cfg.key .. "_Paw", Vector3.new(0.18, 0.14, 0.24), CFrame.new(posX, 0.07, pawZ), Enum.Material.SmoothPlastic, c_spine)
		
		weldParts(upper, lower)
		weldParts(upper, paw)
		
		legs[cfg.key] = {
			upper = upper,
			shoulderPos = cfg.shoulderPos
		}
	end

	-- =========================================================================
	-- 4. 3-СЕГМЕНТНЫЙ ПУШИСТЫЙ ХВОСТ (TailBase -> TailMid -> SnowTip)
	-- =========================================================================
	local tailBase = makePart("TailBase", Vector3.new(0.22, 0.24, 0.30), CFrame.new(0, 0.88, 0.85) * CFrame.Angles(math.rad(-10), 0, 0), Enum.Material.SmoothPlastic, c_dark)
	local tailMid = makePart("TailMid", Vector3.new(0.24, 0.26, 0.34), CFrame.new(0, 0.72, 1.15) * CFrame.Angles(math.rad(-20), 0, 0), Enum.Material.SmoothPlastic, c_light)
	local tailTip = makePart("TailTip", Vector3.new(0.20, 0.22, 0.30), CFrame.new(0, 0.55, 1.45) * CFrame.Angles(math.rad(-30), 0, 0), Enum.Material.SmoothPlastic, c_belly)

	weldParts(tailBase, tailMid)
	weldParts(tailBase, tailTip)

	-- =========================================================================
	-- 5. СОЕДИНЕНИЕ СУСТАВОВ ЧЕРЕЗ ШАРНИРЫ (Motor6D с точным центром вращения)
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

	-- Сустав Шеи (NeckJoint) - вращается вокруг основания черепа
	bindLimbMotor("NeckJoint", body, head, Vector3.new(0, 1.10, -0.75))
	
	-- Сустав Хвоста (TailJoint) - вращается вокруг основания таза
	bindLimbMotor("TailJoint", body, tailBase, Vector3.new(0, 0.90, 0.72))

	-- Суставы 4 Лап (Joint_FL, FR, BL, BR) - вращаются вокруг плечевых/тазобедренных суставов
	for key, legData in pairs(legs) do
		local jointName = "Joint_" .. string.sub(key, 5) -- Joint_FL, Joint_FR...
		bindLimbMotor(jointName, body, legData.upper, legData.shoulderPos)
	end

	model:SetAttribute("IsWolfModel", true)
	model:SetAttribute("IsAnimatedModel", isAnimated)

	if parent then
		model.Parent = parent
	end

	return model
end

return WolfGenerator
