--[[
    ReplicatedStorage/GeneratedModels/Wolf.luau
    Высокоточный, стилизованный 3D-генератор Полярного Волка (~300 полигонов / Low-Poly Predator):
    - Мускулистый корпус с пышным загривком (Mane Ruff), светлым подбрюшьем и хребтом
    - Голова с клыкастой пастью (Fangs & Jaws), открытой алой пастью и черным носом
    - Светящиеся хищные красные глаза (Neon Red Eyes)
    - Остроконечные уши с розовой внутренней частью
    - 4 атлетичные лапы с когтями и суставами
    - Пушистый изогнутый хвост с белоснежным кончиком
--]]

local WolfGenerator = {}

function WolfGenerator.create(parent, targetCF)
	targetCF = targetCF or CFrame.new(0, 1.2, 0)
	local model = Instance.new("Model")
	model.Name = "Wolf"

	local function makePart(name, size, cfOffset, material, color, canCollide)
		local p = Instance.new("Part")
		p.Name = name
		p.Size = size
		p.CFrame = targetCF * cfOffset
		p.Material = material or Enum.Material.SmoothPlastic
		p.Color = color or Color3.fromRGB(71, 85, 105)
		p.Anchored = true
		p.CanCollide = (canCollide == true)
		p.CastShadow = true
		p.TopSurface = Enum.SurfaceType.Smooth
		p.BottomSurface = Enum.SurfaceType.Smooth
		p.Parent = model
		return p
	end

	local function makeWedge(name, size, cfOffset, material, color)
		local p = Instance.new("WedgePart")
		p.Name = name
		p.Size = size
		p.CFrame = targetCF * cfOffset
		p.Material = material or Enum.Material.SmoothPlastic
		p.Color = color or Color3.fromRGB(71, 85, 105)
		p.Anchored = true
		p.CanCollide = false
		p.CastShadow = true
		p.TopSurface = Enum.SurfaceType.Smooth
		p.BottomSurface = Enum.SurfaceType.Smooth
		p.Parent = model
		return p
	end

	-- Цветовая палитра полярного волка
	local c_dark = Color3.fromRGB(71, 85, 105)    -- stone_dark (#475569) - основной серый
	local c_light = Color3.fromRGB(148, 163, 184) -- slate_light (#94A3B8) - светло-серый
	local c_spine = Color3.fromRGB(30, 41, 59)    -- cast_iron (#1E293B) - темный хребет
	local c_belly = Color3.fromRGB(241, 245, 249) -- snow_pure (#F1F5F9) - светлое брюхо
	local c_black = Color3.fromRGB(9, 9, 11)      -- pitch_black (#09090B) - нос и когти
	local c_fangs = Color3.fromRGB(255, 255, 255) -- bone_ivory (#FFFFFF) - клыки
	local c_mouth = Color3.fromRGB(127, 29, 29)   -- crimson_dark (#7F1D1D) - пасть
	local c_pink = Color3.fromRGB(244, 114, 182)  -- pink_soft (#F472B6) - ушки внутри
	local c_eye = Color3.fromRGB(255, 0, 85)      -- neon_red_glow (#FF0055) - глаза

	-- =========================================================================
	-- 1. КОРПУС, ЗАГРИВОК И ХРЕБЕТ (Body, Mane, Underbelly)
	-- =========================================================================
	-- Основная грудная клетка (Chest)
	local body = makePart("Body", Vector3.new(0.72, 0.72, 0.65), CFrame.new(0, 0.94, 0.32), Enum.Material.SmoothPlastic, c_dark, true)
	model.PrimaryPart = body

	-- Загривок / воротник (Mane Ruff)
	makePart("ManeRuff", Vector3.new(0.60, 0.50, 0.48), CFrame.new(0, 1.20, 0.48), Enum.Material.SmoothPlastic, c_dark)

	-- Боковые пучки шерсти на груди (Ruff Flares)
	makeWedge("RuffL", Vector3.new(0.24, 0.45, 0.45), CFrame.new(-0.46, 1.05, 0.35) * CFrame.Angles(0, math.rad(25), math.rad(-15)), Enum.Material.SmoothPlastic, c_light)
	makeWedge("RuffR", Vector3.new(0.24, 0.45, 0.45), CFrame.new(0.46, 1.05, 0.35) * CFrame.Angles(0, math.rad(-25), math.rad(15)), Enum.Material.SmoothPlastic, c_light)

	-- Светлое подбрюшье и манишка (Underbelly Bib)
	makePart("Underbelly", Vector3.new(0.48, 0.34, 0.50), CFrame.new(0, 0.64, 0.35), Enum.Material.SmoothPlastic, c_belly)

	-- Задняя часть торса / таз (Pelvis / Flanks)
	makePart("Pelvis", Vector3.new(0.56, 0.62, 0.75), CFrame.new(0, 0.88, -0.38), Enum.Material.SmoothPlastic, c_dark)

	-- Темный шерстяной гребень на спине (Dorsal Spine Ridge)
	makePart("SpineRidge", Vector3.new(0.18, 0.16, 1.20), CFrame.new(0, 1.34, -0.05), Enum.Material.SmoothPlastic, c_spine)

	-- =========================================================================
	-- 2. ГОЛОВА, КЛЫКАСТАЯ ПАСТЬ И НОС (Head, Jaws, Fangs)
	-- =========================================================================
	-- Череп (Cranium)
	local head = makePart("Head", Vector3.new(0.50, 0.52, 0.45), CFrame.new(0, 1.14, 0.88), Enum.Material.SmoothPlastic, c_dark)

	-- Щечные очесы (Cheek Tufts)
	makeWedge("CheekL", Vector3.new(0.20, 0.32, 0.34), CFrame.new(-0.32, 1.05, 0.85) * CFrame.Angles(0, math.rad(15), math.rad(-10)), Enum.Material.SmoothPlastic, c_light)
	makeWedge("CheekR", Vector3.new(0.20, 0.32, 0.34), CFrame.new(0.32, 1.05, 0.85) * CFrame.Angles(0, math.rad(-15), math.rad(10)), Enum.Material.SmoothPlastic, c_light)

	-- Верхняя морда (Upper Snout / Muzzle)
	makePart("Snout", Vector3.new(0.30, 0.22, 0.48), CFrame.new(0, 1.01, 1.32), Enum.Material.SmoothPlastic, c_dark)
	makePart("SnoutBridge", Vector3.new(0.14, 0.08, 0.46), CFrame.new(0, 1.14, 1.32), Enum.Material.SmoothPlastic, c_spine)

	-- Черный нос (Black Nose)
	makePart("Nose", Vector3.new(0.14, 0.14, 0.10), CFrame.new(0, 1.05, 1.58), Enum.Material.SmoothPlastic, c_black)

	-- Нижняя челюсть (Lower Mandible)
	makePart("LowerJaw", Vector3.new(0.26, 0.16, 0.44), CFrame.new(0, 0.78, 1.28), Enum.Material.SmoothPlastic, c_light)

	-- Открытая пасть (Mouth Cavity)
	makePart("MouthCavity", Vector3.new(0.22, 0.08, 0.36), CFrame.new(0, 0.88, 1.28), Enum.Material.SmoothPlastic, c_mouth)

	-- 4 Острых белых клыка (Sharp White Canines)
	-- Верхние клыки
	makeWedge("Fang_UpperL", Vector3.new(0.06, 0.14, 0.06), CFrame.new(-0.11, 0.84, 1.45) * CFrame.Angles(math.rad(180), 0, 0), Enum.Material.SmoothPlastic, c_fangs)
	makeWedge("Fang_UpperR", Vector3.new(0.06, 0.14, 0.06), CFrame.new(0.11, 0.84, 1.45) * CFrame.Angles(math.rad(180), 0, 0), Enum.Material.SmoothPlastic, c_fangs)
	-- Нижние клыки
	makeWedge("Fang_LowerL", Vector3.new(0.06, 0.14, 0.06), CFrame.new(-0.09, 0.92, 1.41), Enum.Material.SmoothPlastic, c_fangs)
	makeWedge("Fang_LowerR", Vector3.new(0.06, 0.14, 0.06), CFrame.new(0.09, 0.92, 1.41), Enum.Material.SmoothPlastic, c_fangs)

	-- =========================================================================
	-- 3. СВЕТЯЩИЕСЯ ГЛАЗА И УШИ (Eyes & Ears)
	-- =========================================================================
	-- Светящиеся хищные глаза
	local eyeL = makePart("EyeL", Vector3.new(0.12, 0.08, 0.12), CFrame.new(-0.16, 1.18, 1.08) * CFrame.Angles(0, math.rad(-15), math.rad(-10)), Enum.Material.Neon, c_eye)
	local eyeR = makePart("EyeR", Vector3.new(0.12, 0.08, 0.12), CFrame.new(0.16, 1.18, 1.08) * CFrame.Angles(0, math.rad(15), math.rad(10)), Enum.Material.Neon, c_eye)

	local eyeLight = Instance.new("PointLight")
	eyeLight.Name = "WolfEyeGlow"
	eyeLight.Color = c_eye
	eyeLight.Range = 6
	eyeLight.Brightness = 0.75
	eyeLight.Parent = head

	-- Острые стоячие уши
	makeWedge("Ear_L", Vector3.new(0.14, 0.36, 0.22), CFrame.new(-0.16, 1.58, 0.82) * CFrame.Angles(0, math.rad(-10), math.rad(5)), Enum.Material.SmoothPlastic, c_dark)
	makePart("EarInner_L", Vector3.new(0.08, 0.22, 0.06), CFrame.new(-0.15, 1.54, 0.86) * CFrame.Angles(0, math.rad(-10), math.rad(5)), Enum.Material.SmoothPlastic, c_pink)

	makeWedge("Ear_R", Vector3.new(0.14, 0.36, 0.22), CFrame.new(0.16, 1.58, 0.82) * CFrame.Angles(0, math.rad(10), math.rad(-5)), Enum.Material.SmoothPlastic, c_dark)
	makePart("EarInner_R", Vector3.new(0.08, 0.22, 0.06), CFrame.new(0.15, 1.54, 0.86) * CFrame.Angles(0, math.rad(10), math.rad(-5)), Enum.Material.SmoothPlastic, c_pink)

	-- =========================================================================
	-- 4. 4 ЛАПЫ С КОГТЯМИ И СУСТАВАМИ (Legs & Paws)
	-- =========================================================================
	local legConfigs = {
		{ name = "Leg_FL", pos = Vector3.new(-0.26, 0.38, 0.40), isFront = true, isLeft = true },
		{ name = "Leg_FR", pos = Vector3.new(0.26, 0.38, 0.40), isFront = true, isLeft = false },
		{ name = "Leg_BL", pos = Vector3.new(-0.24, 0.38, -0.55), isFront = false, isLeft = true },
		{ name = "Leg_BR", pos = Vector3.new(0.24, 0.38, -0.55), isFront = false, isLeft = false },
	}

	for _, cfg in ipairs(legConfigs) do
		-- Верхняя часть / бедро
		makePart(cfg.name .. "_Upper", Vector3.new(0.18, 0.55, 0.22), CFrame.new(cfg.pos), Enum.Material.SmoothPlastic, c_dark)
		-- Лапа / подушечка с когтями
		local pawZ = cfg.pos.Z + (cfg.isFront and 0.08 or -0.04)
		makePart(cfg.name .. "_Paw", Vector3.new(0.20, 0.12, 0.26), CFrame.new(cfg.pos.X, 0.06, pawZ), Enum.Material.SmoothPlastic, c_spine)
	end

	-- =========================================================================
	-- 5. ПУШИСТЫЙ ХВОСТ С БЕЛЫМ КОНЧИКОМ (Tail & Tip)
	-- =========================================================================
	-- Основание хвоста
	makePart("TailBase", Vector3.new(0.22, 0.24, 0.36), CFrame.new(0, 0.88, -0.85) * CFrame.Angles(math.rad(-25), 0, 0), Enum.Material.SmoothPlastic, c_dark)
	-- Средняя часть хвоста
	makePart("TailMid", Vector3.new(0.24, 0.26, 0.42), CFrame.new(0, 0.72, -1.16) * CFrame.Angles(math.rad(-15), 0, 0), Enum.Material.SmoothPlastic, c_light)
	-- Белый кончик хвоста (Snow Tip)
	makePart("TailTip", Vector3.new(0.18, 0.20, 0.28), CFrame.new(0, 0.62, -1.45) * CFrame.Angles(math.rad(-5), 0, 0), Enum.Material.SmoothPlastic, c_belly)

	-- =========================================================================
	-- 6. СВАРКА ВСЕХ ЧАСТЕЙ К КОРПУСУ (WeldConstraint)
	-- =========================================================================
	for _, part in ipairs(model:GetDescendants()) do
		if part:IsA("BasePart") and part ~= body then
			local weld = Instance.new("WeldConstraint")
			weld.Name = "Weld_" .. part.Name
			weld.Part0 = body
			weld.Part1 = part
			weld.Parent = part
		end
	end

	if parent then
		model.Parent = parent
	end

	return model
end

return WolfGenerator
