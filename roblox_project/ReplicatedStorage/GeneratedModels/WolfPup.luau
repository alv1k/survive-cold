--[[
    ReplicatedStorage/GeneratedModels/WolfPup.luau
    Высокоточная процедурная 3D-модель Дружелюбного Волчонка-Питомца (Pet Wolf Pup):
    - Очаровательные пропорции щенка (Chibi puppy): крупная голова, пушистые щёчки, мягкие ушки с розовой подкладкой
    - Большие добрые глаза с голубой радужкой и бликами, кнопка-носик и розовый язычок
    - Уютный ошейник с золотым колокольчиком / медальоном
    - Пушистая манишка на груди, мягкий животик, белые лапки-носочки
    - Задорно приподнятый пушистый хвост с белоснежным кончиком
    - Полная поддержка Motor6D шарниров для плавной 60 FPS анимации бега, виляния хвостом и сна
--]]

local WolfPupGenerator = {}

function WolfPupGenerator.create(parent, targetCF, options)
	options = options or {}
	local scale = options.Scale or 1.60
	local isAnchored = (options.Anchored == true)
	local isAnimated = (options.isAnimated ~= false)
	targetCF = targetCF or CFrame.new(0, 1.8, 0)

	local model = Instance.new("Model")
	model.Name = "WolfPup"

	local function makePart(name, size, cfOffset, material, color, canCollide)
		local p = Instance.new("Part")
		p.Name = name
		p.Size = size * scale
		p.CFrame = targetCF * CFrame.new(cfOffset.Position * scale) * cfOffset.Rotation
		p.Material = material or Enum.Material.SmoothPlastic
		p.Color = color or Color3.fromRGB(226, 232, 240) -- slate_light
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
		p.Color = color or Color3.fromRGB(226, 232, 240)
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

	-- Цветовая палитра питомца (Мягкие теплые и чистые цвета)
	local c_fur_main = Color3.fromRGB(226, 232, 240)  -- slate_light (#E2E8F0)
	local c_fur_dark = Color3.fromRGB(100, 116, 139)  -- stone_slate (#64748B)
	local c_fur_white = Color3.fromRGB(255, 255, 255) -- snow_pure (#FFFFFF)
	local c_pink = Color3.fromRGB(253, 164, 175)       -- pink_soft (#FDA4AF)
	local c_black = Color3.fromRGB(15, 23, 42)        -- pitch_black (#0F172A)
	local c_eye = options.EyeColor or Color3.fromRGB(34, 211, 238) -- aqua_bright (#22D3EE)
	local c_collar = Color3.fromRGB(239, 68, 68)      -- meat_steak (#EF4444)
	local c_bell = Color3.fromRGB(250, 204, 21)       -- gold_pure (#FACC15)

	-- =========================================================================
	-- 1. КОРПУС И ЖИВОТИК (Torso / Body)
	-- =========================================================================
	local body = makePart("Body", Vector3.new(0.68, 0.60, 0.72), CFrame.new(0, 0.65, -0.08), Enum.Material.SmoothPlastic, c_fur_main, false)
	model.PrimaryPart = body

	local belly = makePart("Underbelly", Vector3.new(0.50, 0.28, 0.64), CFrame.new(0, 0.44, -0.08), Enum.Material.SmoothPlastic, c_fur_white)
	local chestFluff = makePart("ChestFluff", Vector3.new(0.56, 0.46, 0.38), CFrame.new(0, 0.74, -0.40) * CFrame.Angles(math.rad(25), 0, 0), Enum.Material.SmoothPlastic, c_fur_white)
	
	-- Ошейник и колокольчик
	local collar = makePart("Collar", Vector3.new(0.60, 0.12, 0.60), CFrame.new(0, 0.88, -0.42) * CFrame.Angles(math.rad(20), 0, 0), Enum.Material.SmoothPlastic, c_collar)
	local bell = makePart("Bell", Vector3.new(0.18, 0.18, 0.18), CFrame.new(0, 0.74, -0.64), Enum.Material.Metal, c_bell)

	weldParts(body, belly)
	weldParts(body, chestFluff)
	weldParts(body, collar)
	weldParts(body, bell)

	-- =========================================================================
	-- 2. КРУПНАЯ ЧИБИ-ГОЛОВА, ЩЕЧКИ, МОРДОЧКА, ГЛАЗКИ И УШКИ (Head)
	-- =========================================================================
	local head = makePart("Head", Vector3.new(0.76, 0.68, 0.68), CFrame.new(0, 1.10, -0.62), Enum.Material.SmoothPlastic, c_fur_main)
	
	-- Пушистые белые щёчки
	local cheekL = makeWedge("CheekL", Vector3.new(0.24, 0.34, 0.32), CFrame.new(-0.42, 0.98, -0.60) * CFrame.Angles(0, math.rad(-25), math.rad(-20)), Enum.Material.SmoothPlastic, c_fur_white)
	local cheekR = makeWedge("CheekR", Vector3.new(0.24, 0.34, 0.32), CFrame.new(0.42, 0.98, -0.60) * CFrame.Angles(0, math.rad(25), math.rad(20)), Enum.Material.SmoothPlastic, c_fur_white)

	-- Короткая закругленная мордочка
	local snout = makePart("Snout", Vector3.new(0.38, 0.30, 0.34), CFrame.new(0, 0.96, -0.96), Enum.Material.SmoothPlastic, c_fur_white)
	local nose = makePart("Nose", Vector3.new(0.16, 0.12, 0.12), CFrame.new(0, 1.05, -1.14), Enum.Material.SmoothPlastic, c_black)
	local tongue = makePart("Tongue", Vector3.new(0.14, 0.05, 0.18), CFrame.new(0, 0.86, -1.04) * CFrame.Angles(math.rad(15), 0, 0), Enum.Material.SmoothPlastic, c_pink)

	-- Мягкие ушки с розовой подкладкой
	local earL = makePart("EarL", Vector3.new(0.22, 0.44, 0.22), CFrame.new(-0.30, 1.48, -0.52) * CFrame.Angles(math.rad(-10), math.rad(-12), math.rad(-15)), Enum.Material.SmoothPlastic, c_fur_main)
	local earInnerL = makePart("EarInnerL", Vector3.new(0.12, 0.28, 0.04), CFrame.new(-0.29, 1.45, -0.58) * CFrame.Angles(math.rad(-10), math.rad(-12), math.rad(-15)), Enum.Material.SmoothPlastic, c_pink)

	local earR = makePart("EarR", Vector3.new(0.22, 0.44, 0.22), CFrame.new(0.30, 1.48, -0.52) * CFrame.Angles(math.rad(-10), math.rad(12), math.rad(15)), Enum.Material.SmoothPlastic, c_fur_main)
	local earInnerR = makePart("EarInnerR", Vector3.new(0.12, 0.28, 0.04), CFrame.new(0.29, 1.45, -0.58) * CFrame.Angles(math.rad(-10), math.rad(12), math.rad(15)), Enum.Material.SmoothPlastic, c_pink)

	-- Большие выразительные глаза со светящейся аква-радужкой, зрачком и бликом
	local eyeL = makePart("EyeL", Vector3.new(0.16, 0.18, 0.06), CFrame.new(-0.21, 1.14, -0.94), Enum.Material.Neon, c_eye)
	local pupilL = makePart("PupilL", Vector3.new(0.10, 0.12, 0.04), CFrame.new(-0.20, 1.14, -0.96), Enum.Material.SmoothPlastic, c_black)
	local glintL = makePart("GlintL", Vector3.new(0.05, 0.05, 0.03), CFrame.new(-0.17, 1.18, -0.97), Enum.Material.SmoothPlastic, c_fur_white)

	local eyeR = makePart("EyeR", Vector3.new(0.16, 0.18, 0.06), CFrame.new(0.21, 1.14, -0.94), Enum.Material.Neon, c_eye)
	local pupilR = makePart("PupilR", Vector3.new(0.10, 0.12, 0.04), CFrame.new(0.20, 1.14, -0.96), Enum.Material.SmoothPlastic, c_black)
	local glintR = makePart("GlintR", Vector3.new(0.05, 0.05, 0.03), CFrame.new(0.17, 1.18, -0.97), Enum.Material.SmoothPlastic, c_fur_white)

	weldParts(head, cheekL)
	weldParts(head, cheekR)
	weldParts(head, snout)
	weldParts(head, nose)
	weldParts(head, tongue)
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
	-- 3. 4 ПУХЛЫЕ ЛАПКИ С БЕЛЫМИ НОСОЧКАМИ (Legs & Paws)
	-- =========================================================================
	local legs = {}
	local function createPuppyLeg(sideName, posX, posZ, isFront)
		local upper = makePart("Leg_" .. sideName, Vector3.new(0.26, 0.34, 0.26), CFrame.new(posX, 0.40, posZ), Enum.Material.SmoothPlastic, c_fur_main)
		local paw = makePart("Paw_" .. sideName, Vector3.new(0.28, 0.20, 0.32), CFrame.new(posX, 0.16, posZ - (isFront and 0.04 or -0.02)), Enum.Material.SmoothPlastic, c_fur_white)
		weldParts(upper, paw)
		legs[sideName] = { upper = upper, shoulderPos = Vector3.new(posX, 0.52, posZ) }
	end

	createPuppyLeg("FL", -0.30, -0.28, true)
	createPuppyLeg("FR", 0.30, -0.28, true)
	createPuppyLeg("BL", -0.30, 0.24, false)
	createPuppyLeg("BR", 0.30, 0.24, false)

	-- =========================================================================
	-- 4. ЗАДОРНО ПРИПОДНЯТЫЙ ХВОСТИК С БЕЛЫМ КОНЧИКОМ (Tail)
	-- =========================================================================
	local tailBase = makePart("TailBase", Vector3.new(0.22, 0.30, 0.22), CFrame.new(0, 0.72, 0.36) * CFrame.Angles(math.rad(45), 0, 0), Enum.Material.SmoothPlastic, c_fur_main)
	local tailMid = makePart("TailMid", Vector3.new(0.24, 0.28, 0.24), CFrame.new(0, 0.90, 0.52) * CFrame.Angles(math.rad(70), 0, 0), Enum.Material.SmoothPlastic, c_fur_main)
	local tailTip = makePart("TailTip", Vector3.new(0.20, 0.28, 0.20), CFrame.new(0, 1.04, 0.60) * CFrame.Angles(math.rad(85), 0, 0), Enum.Material.SmoothPlastic, c_fur_white)

	weldParts(tailBase, tailMid)
	weldParts(tailBase, tailTip)

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
	bindLimbMotor("NeckJoint", body, head, Vector3.new(0, 0.85, -0.42))
	
	-- Сустав Хвоста (TailJoint)
	bindLimbMotor("TailJoint", body, tailBase, Vector3.new(0, 0.68, 0.28))

	-- Суставы 4 Лапок (Joint_FL, Joint_FR, Joint_BL, Joint_BR)
	for key, legData in pairs(legs) do
		local jointName = "Joint_" .. key
		bindLimbMotor(jointName, body, legData.upper, legData.shoulderPos)
	end

	model:SetAttribute("IsWolfModel", true)
	model:SetAttribute("IsWolfPup", true)
	model:SetAttribute("IsAnimatedModel", isAnimated)

	if parent then
		model.Parent = parent
	end

	return model
end

return WolfPupGenerator
