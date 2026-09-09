--[[
    ReplicatedStorage/GeneratedModels/Fox.luau
    Высокоточная процедурная 3D-модель Снежного Лиса (Chibi Snow Fox Pet):
    - Очаровательные чиби-пропорции: грациозное золотисто-рыжее тело, пышная белая манишка и животик
    - Крупная выразительная голова, пушистые белые щёчки, чуткие ушки с тёмными кончиками и розовой подкладкой
    - Большие изумрудные светящиеся глазки с бликами и черный носик-кнопка
    - Уютный лесной ошейник с изумрудным кулоном
    - 4 стройные лапки в белоснежных носочках
    - Огромный, роскошный пушистый лисий хвост с белым снежным кончиком
    - Полная поддержка Motor6D шарниров для плавной 60 FPS анимации бега, виляния хвостом и сна
--]]

local FoxGenerator = {}

function FoxGenerator.create(parent, targetCF, options)
	options = options or {}
	local scale = options.Scale or 1.50
	local isAnchored = (options.Anchored == true)
	local isAnimated = (options.isAnimated ~= false)
	targetCF = targetCF or CFrame.new(0, 1.8, 0)

	local model = Instance.new("Model")
	model.Name = "Fox"

	local function makePart(name, size, cfOffset, material, color, canCollide)
		local p = Instance.new("Part")
		p.Name = name
		p.Size = size * scale
		p.CFrame = targetCF * CFrame.new(cfOffset.Position * scale) * cfOffset.Rotation
		p.Material = material or Enum.Material.SmoothPlastic
		p.Color = color or Color3.fromRGB(249, 115, 22) -- Bright amber-orange (#F97316)
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
		p.Color = color or Color3.fromRGB(249, 115, 22)
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

	-- Цветовая палитра лиса
	local c_fur_main = Color3.fromRGB(249, 115, 22)  -- amber_orange (#F97316)
	local c_fur_dark = Color3.fromRGB(71, 85, 105)   -- stone_dark (#475569)
	local c_fur_white = Color3.fromRGB(255, 255, 255) -- snow_pure (#FFFFFF)
	local c_pink = Color3.fromRGB(253, 164, 175)       -- pink_soft (#FDA4AF)
	local c_black = Color3.fromRGB(15, 23, 42)        -- pitch_black (#0F172A)
	local c_eye = options.EyeColor or Color3.fromRGB(16, 185, 129) -- emerald_gem (#10B981)
	local c_collar = Color3.fromRGB(22, 101, 52)      -- forest_dark (#166534)
	local c_gem = Color3.fromRGB(52, 211, 153)        -- emerald_bright (#34D399)

	-- =========================================================================
	-- 1. КОРПУС И БЕЛЫЙ ЖИВОТИК (Torso / Body)
	-- =========================================================================
	local body = makePart("Body", Vector3.new(0.62, 0.58, 0.76), CFrame.new(0, 0.62, -0.06), Enum.Material.SmoothPlastic, c_fur_main, false)
	model.PrimaryPart = body

	local belly = makePart("Underbelly", Vector3.new(0.46, 0.26, 0.68), CFrame.new(0, 0.42, -0.06), Enum.Material.SmoothPlastic, c_fur_white)
	local chestFluff = makePart("ChestFluff", Vector3.new(0.52, 0.44, 0.38), CFrame.new(0, 0.72, -0.38) * CFrame.Angles(math.rad(28), 0, 0), Enum.Material.SmoothPlastic, c_fur_white)
	
	-- Ошейник и изумрудный медальон
	local collar = makePart("Collar", Vector3.new(0.56, 0.12, 0.56), CFrame.new(0, 0.86, -0.38) * CFrame.Angles(math.rad(22), 0, 0), Enum.Material.SmoothPlastic, c_collar)
	local gem = makePart("Gem", Vector3.new(0.16, 0.16, 0.16), CFrame.new(0, 0.74, -0.58), Enum.Material.Neon, c_gem)

	weldParts(body, belly)
	weldParts(body, chestFluff)
	weldParts(body, collar)
	weldParts(body, gem)

	-- =========================================================================
	-- 2. КРУПНАЯ ЧИБИ-ГОЛОВА, ПУШИСТЫЕ ЩЕЧКИ, МОРДОЧКА, ГЛАЗКИ И УШКИ (Head)
	-- =========================================================================
	local head = makePart("Head", Vector3.new(0.72, 0.64, 0.66), CFrame.new(0, 1.08, -0.58), Enum.Material.SmoothPlastic, c_fur_main)
	
	-- Пушистые белые лисьи щёчки
	local cheekL = makeWedge("CheekL", Vector3.new(0.24, 0.36, 0.34), CFrame.new(-0.42, 0.98, -0.56) * CFrame.Angles(0, math.rad(-30), math.rad(-22)), Enum.Material.SmoothPlastic, c_fur_white)
	local cheekR = makeWedge("CheekR", Vector3.new(0.24, 0.36, 0.34), CFrame.new(0.42, 0.98, -0.56) * CFrame.Angles(0, math.rad(30), math.rad(22)), Enum.Material.SmoothPlastic, c_fur_white)

	-- Аккуратная коническая мордочка и кнопка-носик
	local snout = makePart("Snout", Vector3.new(0.34, 0.28, 0.36), CFrame.new(0, 0.94, -0.92), Enum.Material.SmoothPlastic, c_fur_white)
	local nose = makePart("Nose", Vector3.new(0.14, 0.10, 0.10), CFrame.new(0, 1.02, -1.10), Enum.Material.SmoothPlastic, c_black)

	-- Высокие заостренные лисьи ушки с темными кончиками и розовой подкладкой
	local earL = makePart("EarL", Vector3.new(0.22, 0.52, 0.20), CFrame.new(-0.28, 1.52, -0.48) * CFrame.Angles(math.rad(-10), math.rad(-14), math.rad(-18)), Enum.Material.SmoothPlastic, c_fur_main)
	local earTipL = makePart("EarTipL", Vector3.new(0.16, 0.20, 0.16), CFrame.new(-0.35, 1.74, -0.44) * CFrame.Angles(math.rad(-10), math.rad(-14), math.rad(-18)), Enum.Material.SmoothPlastic, c_fur_dark)
	local earInnerL = makePart("EarInnerL", Vector3.new(0.12, 0.34, 0.04), CFrame.new(-0.27, 1.48, -0.54) * CFrame.Angles(math.rad(-10), math.rad(-14), math.rad(-18)), Enum.Material.SmoothPlastic, c_pink)

	local earR = makePart("EarR", Vector3.new(0.22, 0.52, 0.20), CFrame.new(0.28, 1.52, -0.48) * CFrame.Angles(math.rad(-10), math.rad(14), math.rad(18)), Enum.Material.SmoothPlastic, c_fur_main)
	local earTipR = makePart("EarTipR", Vector3.new(0.16, 0.20, 0.16), CFrame.new(0.35, 1.74, -0.44) * CFrame.Angles(math.rad(-10), math.rad(14), math.rad(18)), Enum.Material.SmoothPlastic, c_fur_dark)
	local earInnerR = makePart("EarInnerR", Vector3.new(0.12, 0.34, 0.04), CFrame.new(0.27, 1.48, -0.54) * CFrame.Angles(math.rad(-10), math.rad(14), math.rad(18)), Enum.Material.SmoothPlastic, c_pink)

	-- Большие изумрудные глаза с неоновым свечением, зрачками и искрами
	local eyeL = makePart("EyeL", Vector3.new(0.15, 0.18, 0.06), CFrame.new(-0.20, 1.12, -0.88), Enum.Material.Neon, c_eye)
	local pupilL = makePart("PupilL", Vector3.new(0.09, 0.12, 0.04), CFrame.new(-0.19, 1.12, -0.90), Enum.Material.SmoothPlastic, c_black)
	local glintL = makePart("GlintL", Vector3.new(0.05, 0.05, 0.03), CFrame.new(-0.16, 1.16, -0.91), Enum.Material.SmoothPlastic, c_fur_white)

	local eyeR = makePart("EyeR", Vector3.new(0.15, 0.18, 0.06), CFrame.new(0.20, 1.12, -0.88), Enum.Material.Neon, c_eye)
	local pupilR = makePart("PupilR", Vector3.new(0.09, 0.12, 0.04), CFrame.new(0.19, 1.12, -0.90), Enum.Material.SmoothPlastic, c_black)
	local glintR = makePart("GlintR", Vector3.new(0.05, 0.05, 0.03), CFrame.new(0.16, 1.16, -0.91), Enum.Material.SmoothPlastic, c_fur_white)

	weldParts(head, cheekL)
	weldParts(head, cheekR)
	weldParts(head, snout)
	weldParts(head, nose)
	weldParts(head, earL)
	weldParts(head, earTipL)
	weldParts(head, earInnerL)
	weldParts(head, earR)
	weldParts(head, earTipR)
	weldParts(head, earInnerR)
	weldParts(head, eyeL)
	weldParts(head, pupilL)
	weldParts(head, glintL)
	weldParts(head, eyeR)
	weldParts(head, pupilR)
	weldParts(head, glintR)

	-- =========================================================================
	-- 3. 4 СТРОЙНЫЕ ЛАПКИ С БЕЛЫМИ НОСОЧКАМИ (Legs & Paws)
	-- =========================================================================
	local legs = {}
	local function createFoxLeg(sideName, posX, posZ, isFront)
		local upper = makePart("Leg_" .. sideName, Vector3.new(0.22, 0.36, 0.22), CFrame.new(posX, 0.38, posZ), Enum.Material.SmoothPlastic, c_fur_main)
		local paw = makePart("Paw_" .. sideName, Vector3.new(0.24, 0.18, 0.28), CFrame.new(posX, 0.14, posZ - (isFront and 0.03 or -0.02)), Enum.Material.SmoothPlastic, c_fur_white)
		weldParts(upper, paw)
		legs[sideName] = { upper = upper, shoulderPos = Vector3.new(posX, 0.50, posZ) }
	end

	createFoxLeg("FL", -0.26, -0.24, true)
	createFoxLeg("FR",  0.26, -0.24, true)
	createFoxLeg("BL", -0.26,  0.24, false)
	createFoxLeg("BR",  0.26,  0.24, false)

	-- =========================================================================
	-- 4. ОГРОМНЫЙ РОСКОШНЫЙ ПУШИСТЫЙ ЛИСИЙ ХВОСТ С БЕЛЫМ КОНЧИКОМ (Tail)
	-- =========================================================================
	local tailBase = makePart("TailBase", Vector3.new(0.24, 0.34, 0.24), CFrame.new(0, 0.70, 0.36) * CFrame.Angles(math.rad(42), 0, 0), Enum.Material.SmoothPlastic, c_fur_main)
	local tailMid = makePart("TailMid", Vector3.new(0.32, 0.40, 0.32), CFrame.new(0, 0.94, 0.56) * CFrame.Angles(math.rad(68), 0, 0), Enum.Material.SmoothPlastic, c_fur_main)
	local tailTip = makePart("TailTip", Vector3.new(0.28, 0.38, 0.28), CFrame.new(0, 1.18, 0.72) * CFrame.Angles(math.rad(88), 0, 0), Enum.Material.SmoothPlastic, c_fur_white)

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
	bindLimbMotor("NeckJoint", body, head, Vector3.new(0, 0.82, -0.38))
	
	-- Сустав Хвоста (TailJoint)
	bindLimbMotor("TailJoint", body, tailBase, Vector3.new(0, 0.65, 0.26))

	-- Суставы 4 Лапок (Joint_FL, Joint_FR, Joint_BL, Joint_BR)
	for key, legData in pairs(legs) do
		local jointName = "Joint_" .. key
		bindLimbMotor(jointName, body, legData.upper, legData.shoulderPos)
	end

	model:SetAttribute("IsFoxModel", true)
	model:SetAttribute("IsFoxPet", true)
	model:SetAttribute("IsAnimatedModel", isAnimated)

	if parent then
		model.Parent = parent
	end

	return model
end

return FoxGenerator
