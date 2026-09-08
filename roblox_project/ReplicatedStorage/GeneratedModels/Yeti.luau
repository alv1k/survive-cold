--[[
    ReplicatedStorage/GeneratedModels/Yeti.luau
    Высокоточный процедурный 3D-генератор Снежного Йети (Snow Yeti Giant):
    - Увеличенный 4x масштаб (гигантский босс северных пустошей)
    - Полная система суставов Motor6D для 60 FPS анимаций ходьбы (Walk) и яростного бега (Run)
    - Матовая цветовая палитра без свечения (Non-glowing SmoothPlastic/Fabric)
    - Массивная мускулатура, загривок, сланцевая маска, 4 клыка, изогнутые ледяные рога и когти
--]]

local YetiGenerator = {}

function YetiGenerator.create(parent, targetCF, options)
	options = options or {}
	local scale = options.Scale or 4.0
	local isMob = (options.isMob == true) or (options.isAnimated == true)
	local isAnchored = (options.Anchored ~= false) and (not isMob)
	local isAnimated = (options.isAnimated ~= false) and isMob
	
	targetCF = targetCF or CFrame.new(0, 0, 0)
	local model = Instance.new("Model")
	model.Name = "Yeti"

	local function makePart(name, size, cfOffset, material, color, canCollide)
		local p = Instance.new("Part")
		p.Name = name
		p.Size = size * scale
		p.CFrame = targetCF * CFrame.new(cfOffset.Position * scale) * cfOffset.Rotation
		p.Material = material or Enum.Material.Fabric
		p.Color = color or Color3.fromRGB(241, 245, 249)
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
		p.Color = color or Color3.fromRGB(241, 245, 249)
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

	-- Цветовая палитра (palette.png - матовая, без свечения)
	local c_snow = Color3.fromRGB(248, 250, 252)      -- snow_pure (#F8FAFC)
	local c_ambient = Color3.fromRGB(224, 242, 254)   -- snow_ambient (#E0F2FE)
	local c_mask = Color3.fromRGB(51, 65, 85)         -- stone_dark (#334155)
	local c_brow = Color3.fromRGB(30, 41, 59)         -- cast_iron (#1E293B)
	local c_ice_base = Color3.fromRGB(56, 189, 248)   -- ice_glacier (#38BDF8)
	local c_ice_light = Color3.fromRGB(186, 230, 253) -- ice_light (#BAE6FD)
	local c_ice_deep = Color3.fromRGB(2, 132, 199)    -- ice_deep (#0284C7)
	local c_eye = Color3.fromRGB(56, 189, 248)         -- ice_glacier (матовый лед без Neon/Light)
	local c_fangs = Color3.fromRGB(255, 255, 255)     -- bone_ivory

	-- =========================================================================
	-- 1. ТОРС, ВОРОТНИК И ГРУДИНА (Torso)
	-- =========================================================================
	local torso = makePart("Torso", Vector3.new(2.4, 2.0, 1.8), CFrame.new(0, 2.4, 0), Enum.Material.Fabric, c_snow, false)
	model.PrimaryPart = torso

	local furCollar = makePart("FurCollar", Vector3.new(2.7, 0.8, 2.1), CFrame.new(0, 3.15, -0.05), Enum.Material.Fabric, c_snow)
	local chestBulge = makePart("ChestBulge", Vector3.new(1.8, 1.3, 0.6), CFrame.new(0, 2.5, -0.85), Enum.Material.Fabric, c_ambient)
	local backHump = makePart("BackHump", Vector3.new(1.8, 1.2, 0.6), CFrame.new(0, 2.6, 0.85), Enum.Material.Fabric, c_snow)
	local lowerTorso = makePart("LowerTorso", Vector3.new(2.1, 1.4, 1.6), CFrame.new(0, 1.3, 0.05), Enum.Material.Fabric, c_ambient)

	weldParts(torso, furCollar)
	weldParts(torso, chestBulge)
	weldParts(torso, backHump)

	-- =========================================================================
	-- 2. ГОЛОВА, МАСКА, КЛЫКИ И РОГА (Head)
	-- =========================================================================
	local head = makePart("Head", Vector3.new(1.6, 1.4, 1.5), CFrame.new(0, 3.9, -0.25), Enum.Material.Fabric, c_snow)
	local faceMask = makePart("FaceMask", Vector3.new(1.2, 0.85, 0.5), CFrame.new(0, 3.75, -0.90), Enum.Material.SmoothPlastic, c_mask)
	local browRidge = makePart("BrowRidge", Vector3.new(1.3, 0.25, 0.35), CFrame.new(0, 4.10, -0.95), Enum.Material.SmoothPlastic, c_brow)

	-- Матовые глаза (SmoothPlastic, без PointLight)
	local eyeL = makePart("EyeL", Vector3.new(0.24, 0.18, 0.14), CFrame.new(-0.35, 3.95, -1.12), Enum.Material.SmoothPlastic, c_eye)
	local eyeR = makePart("EyeR", Vector3.new(0.24, 0.18, 0.14), CFrame.new(0.35, 3.95, -1.12), Enum.Material.SmoothPlastic, c_eye)

	-- 4 Клыка (Верхние и Нижние)
	local fangUL = makeWedge("Fang_UpperL", Vector3.new(0.14, 0.32, 0.14), CFrame.new(-0.35, 3.48, -1.15) * CFrame.Angles(math.rad(180), 0, 0), Enum.Material.SmoothPlastic, c_fangs)
	local fangUR = makeWedge("Fang_UpperR", Vector3.new(0.14, 0.32, 0.14), CFrame.new(0.35, 3.48, -1.15) * CFrame.Angles(math.rad(180), 0, 0), Enum.Material.SmoothPlastic, c_fangs)
	local fangLL = makeWedge("Fang_LowerL", Vector3.new(0.12, 0.28, 0.12), CFrame.new(-0.25, 3.65, -1.12), Enum.Material.SmoothPlastic, c_fangs)
	local fangLR = makeWedge("Fang_LowerR", Vector3.new(0.12, 0.28, 0.12), CFrame.new(0.25, 3.65, -1.12), Enum.Material.SmoothPlastic, c_fangs)

	-- Изогнутые ледяные рога
	local hornBaseL = makePart("HornBaseL", Vector3.new(0.35, 0.85, 0.35), CFrame.new(-0.85, 4.45, -0.20) * CFrame.Angles(math.rad(-15), 0, math.rad(-30)), Enum.Material.Ice, c_ice_base)
	local hornTipL = makePart("HornTipL", Vector3.new(0.24, 0.70, 0.24), CFrame.new(-1.18, 4.95, 0.05) * CFrame.Angles(math.rad(-35), math.rad(15), math.rad(-45)), Enum.Material.Ice, c_ice_light)
	local hornBaseR = makePart("HornBaseR", Vector3.new(0.35, 0.85, 0.35), CFrame.new(0.85, 4.45, -0.20) * CFrame.Angles(math.rad(-15), 0, math.rad(30)), Enum.Material.Ice, c_ice_base)
	local hornTipR = makePart("HornTipR", Vector3.new(0.24, 0.70, 0.24), CFrame.new(1.18, 4.95, 0.05) * CFrame.Angles(math.rad(-35), math.rad(-15), math.rad(45)), Enum.Material.Ice, c_ice_light)

	local headParts = { faceMask, browRidge, eyeL, eyeR, fangUL, fangUR, fangLL, fangLR, hornBaseL, hornTipL, hornBaseR, hornTipR }
	for _, p in ipairs(headParts) do
		weldParts(head, p)
	end

	-- =========================================================================
	-- 3. МУСКУЛИСТЫЕ РУКИ С ЛЕДЯНЫМИ КОГТЯМИ (Arms & Claws)
	-- =========================================================================
	local shoulderL = makePart("ShoulderL", Vector3.new(1.1, 1.3, 1.1), CFrame.new(-1.65, 2.7, -0.05), Enum.Material.Fabric, c_snow)
	local armL = makePart("ArmL", Vector3.new(1.0, 1.6, 1.0), CFrame.new(-1.85, 1.5, -0.15), Enum.Material.Fabric, c_ambient)
	local clawL = makePart("ClawL", Vector3.new(1.1, 0.7, 1.2), CFrame.new(-1.85, 0.45, -0.25), Enum.Material.Ice, c_ice_deep)
	weldParts(shoulderL, armL)
	weldParts(armL, clawL)

	local shoulderR = makePart("ShoulderR", Vector3.new(1.1, 1.3, 1.1), CFrame.new(1.65, 2.7, -0.05), Enum.Material.Fabric, c_snow)
	local armR = makePart("ArmR", Vector3.new(1.0, 1.6, 1.0), CFrame.new(1.85, 1.5, -0.15), Enum.Material.Fabric, c_ambient)
	local clawR = makePart("ClawR", Vector3.new(1.1, 0.7, 1.2), CFrame.new(1.85, 0.45, -0.25), Enum.Material.Ice, c_ice_deep)
	weldParts(shoulderR, armR)
	weldParts(armR, clawR)

	-- =========================================================================
	-- 4. ТОЛСТЫЕ СНЕЖНЫЕ НОГИ И ЛЕДЯНЫЕ СТУПНИ (Legs & Feet)
	-- =========================================================================
	local legL = makePart("LegL", Vector3.new(1.0, 1.4, 1.1), CFrame.new(-0.75, 0.85, 0.05), Enum.Material.Fabric, c_ambient)
	local footL = makePart("FootL", Vector3.new(1.1, 0.5, 1.5), CFrame.new(-0.75, 0.25, -0.15), Enum.Material.Ice, c_ice_base)
	weldParts(legL, footL)

	local legR = makePart("LegR", Vector3.new(1.0, 1.4, 1.1), CFrame.new(0.75, 0.85, 0.05), Enum.Material.Fabric, c_ambient)
	local footR = makePart("FootR", Vector3.new(1.1, 0.5, 1.5), CFrame.new(0.75, 0.25, -0.15), Enum.Material.Ice, c_ice_base)
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
	bindLimbMotor("Joint_ArmL", torso, shoulderL, Vector3.new(-1.65, 3.1, -0.05))
	bindLimbMotor("Joint_ArmR", torso, shoulderR, Vector3.new(1.65, 3.1, -0.05))

	-- Тазобедренные суставы (Joint_LegL, Joint_LegR)
	bindLimbMotor("Joint_LegL", lowerTorso, legL, Vector3.new(-0.75, 1.3, 0.05))
	bindLimbMotor("Joint_LegR", lowerTorso, legR, Vector3.new(0.75, 1.3, 0.05))

	model:SetAttribute("IsYetiModel", true)
	model:SetAttribute("IsAnimatedModel", isAnimated)

	if parent then
		model.Parent = parent
	end

	return model
end

return YetiGenerator
