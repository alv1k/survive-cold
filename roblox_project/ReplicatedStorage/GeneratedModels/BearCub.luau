--[[
    ReplicatedStorage/GeneratedModels/BearCub.luau
    Высокоточная процедурная 3D-модель Полярного Медвежонка (Chibi Polar Bear Cub Pet):
    - Очаровательные пухлые чиби-пропорции: кругленькое мягкое тельце, теплый животик
    - Крупная округлая голова, пухлые щёчки, милые круглые ушки-помпоны с розовой подкладкой
    - Добрые сияющие сапфирово-ледяные глазки, кнопка-носик
    - Зимний ледниковый ошейник с золотым бубенчиком
    - 4 толстенькие устойчивые лапки с темными подушечками
    - Милый круглый хвостик-пуговка
    - Полная поддержка Motor6D шарниров для плавной 60 FPS анимации походки вперевалочку, сна и отдыха
--]]

local BearCubGenerator = {}

function BearCubGenerator.create(parent, targetCF, options)
	options = options or {}
	local scale = options.Scale or 1.60
	local isAnchored = (options.Anchored == true)
	local isAnimated = (options.isAnimated ~= false)
	targetCF = targetCF or CFrame.new(0, 1.8, 0)

	local model = Instance.new("Model")
	model.Name = "BearCub"

	local function makePart(name, size, cfOffset, material, color, canCollide)
		local p = Instance.new("Part")
		p.Name = name
		p.Size = size * scale
		p.CFrame = targetCF * CFrame.new(cfOffset.Position * scale) * cfOffset.Rotation
		p.Material = material or Enum.Material.SmoothPlastic
		p.Color = color or Color3.fromRGB(255, 255, 255) -- snow_pure
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
		p.Color = color or Color3.fromRGB(255, 255, 255)
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

	-- Цветовая палитра белого мишки
	local c_fur_main = Color3.fromRGB(255, 255, 255)  -- snow_pure (#FFFFFF)
	local c_fur_soft = Color3.fromRGB(241, 245, 249)  -- slate_soft (#F1F5F9)
	local c_fur_dark = Color3.fromRGB(71, 85, 105)   -- stone_dark (#475569)
	local c_pink = Color3.fromRGB(253, 164, 175)       -- pink_soft (#FDA4AF)
	local c_black = Color3.fromRGB(15, 23, 42)        -- pitch_black (#0F172A)
	local c_eye = options.EyeColor or Color3.fromRGB(56, 189, 248) -- ice_glacier (#38BDF8)
	local c_collar = Color3.fromRGB(14, 165, 233)     -- glacier_blue (#0EA5E9)
	local c_bell = Color3.fromRGB(250, 204, 21)       -- gold_pure (#FACC15)

	-- =========================================================================
	-- 1. КОРПУС И КРУГЛЫЙ ЖИВОТИК (Torso / Body)
	-- =========================================================================
	local body = makePart("Body", Vector3.new(0.80, 0.68, 0.88), CFrame.new(0, 0.68, -0.06), Enum.Material.SmoothPlastic, c_fur_main, false)
	model.PrimaryPart = body

	local belly = makePart("Underbelly", Vector3.new(0.64, 0.32, 0.76), CFrame.new(0, 0.44, -0.06), Enum.Material.SmoothPlastic, c_fur_soft)
	local chestFluff = makePart("ChestFluff", Vector3.new(0.66, 0.50, 0.42), CFrame.new(0, 0.78, -0.42) * CFrame.Angles(math.rad(22), 0, 0), Enum.Material.SmoothPlastic, c_fur_main)
	
	-- Зимний ошейник и золотой бубенчик
	local collar = makePart("Collar", Vector3.new(0.72, 0.14, 0.72), CFrame.new(0, 0.92, -0.42) * CFrame.Angles(math.rad(20), 0, 0), Enum.Material.SmoothPlastic, c_collar)
	local bell = makePart("Bell", Vector3.new(0.20, 0.20, 0.20), CFrame.new(0, 0.78, -0.66), Enum.Material.Metal, c_bell)

	weldParts(body, belly)
	weldParts(body, chestFluff)
	weldParts(body, collar)
	weldParts(body, bell)

	-- =========================================================================
	-- 2. КРУГЛАЯ ПЛЮШЕВАЯ ГОЛОВА, ЩЕЧКИ, МОРДОЧКА, ГЛАЗКИ И КРУГЛЫЕ УШКИ (Head)
	-- =========================================================================
	local head = makePart("Head", Vector3.new(0.84, 0.74, 0.74), CFrame.new(0, 1.14, -0.62), Enum.Material.SmoothPlastic, c_fur_main)
	
	-- Пухлые круглые щёчки
	local cheekL = makeWedge("CheekL", Vector3.new(0.26, 0.38, 0.36), CFrame.new(-0.46, 1.02, -0.60) * CFrame.Angles(0, math.rad(-20), math.rad(-15)), Enum.Material.SmoothPlastic, c_fur_main)
	local cheekR = makeWedge("CheekR", Vector3.new(0.26, 0.38, 0.36), CFrame.new(0.46, 1.02, -0.60) * CFrame.Angles(0, math.rad(20), math.rad(15)), Enum.Material.SmoothPlastic, c_fur_main)

	-- Круглая белая мордочка и кнопка-носик
	local snout = makePart("Snout", Vector3.new(0.44, 0.34, 0.36), CFrame.new(0, 0.98, -0.98), Enum.Material.SmoothPlastic, c_fur_soft)
	local nose = makePart("Nose", Vector3.new(0.18, 0.14, 0.14), CFrame.new(0, 1.08, -1.16), Enum.Material.SmoothPlastic, c_black)

	-- Круглые ушки плюшевого мишки с розовыми подушечками
	local earL = makePart("EarL", Vector3.new(0.28, 0.28, 0.18), CFrame.new(-0.36, 1.54, -0.52) * CFrame.Angles(0, 0, math.rad(-15)), Enum.Material.SmoothPlastic, c_fur_main)
	local earInnerL = makePart("EarInnerL", Vector3.new(0.18, 0.18, 0.04), CFrame.new(-0.35, 1.54, -0.58) * CFrame.Angles(0, 0, math.rad(-15)), Enum.Material.SmoothPlastic, c_pink)

	local earR = makePart("EarR", Vector3.new(0.28, 0.28, 0.18), CFrame.new(0.36, 1.54, -0.52) * CFrame.Angles(0, 0, math.rad(15)), Enum.Material.SmoothPlastic, c_fur_main)
	local earInnerR = makePart("EarInnerR", Vector3.new(0.18, 0.18, 0.04), CFrame.new(0.35, 1.54, -0.58) * CFrame.Angles(0, 0, math.rad(15)), Enum.Material.SmoothPlastic, c_pink)

	-- Добрые сапфирово-голубые глаза со светящейся радужкой, зрачком и искрами
	local eyeL = makePart("EyeL", Vector3.new(0.16, 0.18, 0.06), CFrame.new(-0.23, 1.18, -0.96), Enum.Material.Neon, c_eye)
	local pupilL = makePart("PupilL", Vector3.new(0.10, 0.12, 0.04), CFrame.new(-0.22, 1.18, -0.98), Enum.Material.SmoothPlastic, c_black)
	local glintL = makePart("GlintL", Vector3.new(0.05, 0.05, 0.03), CFrame.new(-0.19, 1.22, -0.99), Enum.Material.SmoothPlastic, c_fur_main)

	local eyeR = makePart("EyeR", Vector3.new(0.16, 0.18, 0.06), CFrame.new(0.23, 1.18, -0.96), Enum.Material.Neon, c_eye)
	local pupilR = makePart("PupilR", Vector3.new(0.10, 0.12, 0.04), CFrame.new(0.22, 1.18, -0.98), Enum.Material.SmoothPlastic, c_black)
	local glintR = makePart("GlintR", Vector3.new(0.05, 0.05, 0.03), CFrame.new(0.19, 1.22, -0.99), Enum.Material.SmoothPlastic, c_fur_main)

	weldParts(head, cheekL)
	weldParts(head, cheekR)
	weldParts(head, snout)
	weldParts(head, nose)
	weldParts(head, earL)
	weldParts(head, earInnerL)
	weldParts(head, earR)
	weldParts(head, earInnerR)
	weldParts(head, eyeL)
	weldParts(head, pupilL)
	weldParts(head, glintL)
	weldParts(head, eyeR)
	weldParts(head, pupilR)
	weldParts(head, glintR)

	-- =========================================================================
	-- 3. 4 ТОЛСТЕНЬКИЕ ЛАПКИ С ПОДУШЕЧКАМИ (Legs & Paws)
	-- =========================================================================
	local legs = {}
	local function createBearLeg(sideName, posX, posZ, isFront)
		local upper = makePart("Leg_" .. sideName, Vector3.new(0.32, 0.36, 0.32), CFrame.new(posX, 0.40, posZ), Enum.Material.SmoothPlastic, c_fur_main)
		local paw = makePart("Paw_" .. sideName, Vector3.new(0.34, 0.20, 0.38), CFrame.new(posX, 0.16, posZ - (isFront and 0.04 or -0.02)), Enum.Material.SmoothPlastic, c_fur_main)
		local pad = makePart("Pad_" .. sideName, Vector3.new(0.22, 0.03, 0.24), CFrame.new(posX, 0.07, posZ - (isFront and 0.04 or -0.02)), Enum.Material.SmoothPlastic, c_fur_dark)
		weldParts(upper, paw)
		weldParts(upper, pad)
		legs[sideName] = { upper = upper, shoulderPos = Vector3.new(posX, 0.52, posZ) }
	end

	createBearLeg("FL", -0.32, -0.28, true)
	createBearLeg("FR",  0.32, -0.28, true)
	createBearLeg("BL", -0.32,  0.26, false)
	createBearLeg("BR",  0.32,  0.26, false)

	-- =========================================================================
	-- 4. КРУГЛЫЙ ХВОСТИК-ПУГОВКА (Tail)
	-- =========================================================================
	local tail = makePart("Tail", Vector3.new(0.22, 0.22, 0.22), CFrame.new(0, 0.68, 0.42), Enum.Material.SmoothPlastic, c_fur_main)

	-- =========================================================================
	-- 5. MOTOR6D ШАРНИРЫ ДЛЯ АНИМАЦИИ (Neck, Tail, Legs)
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

	-- Сустав Шеи (NeckJoint)
	bindLimbMotor("NeckJoint", body, head, Vector3.new(0, 0.88, -0.42))
	
	-- Сустав Хвоста (TailJoint)
	bindLimbMotor("TailJoint", body, tail, Vector3.new(0, 0.66, 0.36))

	-- Суставы 4 Лапок (Joint_FL, Joint_FR, Joint_BL, Joint_BR)
	for key, legData in pairs(legs) do
		local jointName = "Joint_" .. key
		bindLimbMotor(jointName, body, legData.upper, legData.shoulderPos)
	end

	model:SetAttribute("IsBearModel", true)
	model:SetAttribute("IsBearCub", true)
	model:SetAttribute("IsAnimatedModel", isAnimated)

	if parent then
		model.Parent = parent
	end

	return model
end

return BearCubGenerator
