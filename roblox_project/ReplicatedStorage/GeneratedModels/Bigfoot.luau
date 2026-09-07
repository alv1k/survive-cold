--[[
    ReplicatedStorage/GeneratedModels/Bigfoot.luau
    Высокоточный, стилизованный 3D-генератор Бигфута (Bigfoot / Снежный Человек / Sasquatch):
    - Огромный мускулистый торс (Torso) цвета темного ореха с рельефными грудными плитами
    - Массивная голова примата с тяжелым надбровным валиком и выступающей челюстью
    - Светящиеся янтарные неоновые глаза (Neon Amber Eyes) с PointLight
    - Длинные мощные руки-лапы с широкими кулаками
    - Ноги-колонны с устойчивыми ступнями
    - Направлен строго вперед (в сторону -Z в Roblox)
--]]

local BigfootGenerator = {}

function BigfootGenerator.create(parent, targetCF, options)
	options = options or {}
	local scale = options.Scale or 1.0
	local isAnchored = (options.Anchored ~= false) and (options.isMob ~= true)

	targetCF = targetCF or CFrame.new(0, 0, 0)
	local model = Instance.new("Model")
	model.Name = "Bigfoot"

	local function makePart(name, size, cfOffset, material, color, canCollide)
		local p = Instance.new("Part")
		p.Name = name
		p.Size = size * scale
		local scaledPos = cfOffset.Position * scale
		local scaledRot = cfOffset - cfOffset.Position
		p.CFrame = targetCF * CFrame.new(scaledPos) * scaledRot
		p.Material = material or Enum.Material.SmoothPlastic
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

	-- Цветовая палитра Бигфута
	local c_fur = Color3.fromRGB(92, 46, 11)       -- wood_walnut (#5C2E0B) - темно-коричневая шерсть
	local c_dark = Color3.fromRGB(62, 30, 8)       -- wood_bark (#3E1E08) - темные участки / рельеф
	local c_burnt = Color3.fromRGB(41, 37, 36)     -- wood_burnt (#292524) - надбровье / загривок
	local c_skin = Color3.fromRGB(120, 53, 15)     -- wood_mahogany (#78350F) - лицо и челюсть
	local c_eye = Color3.fromRGB(255, 183, 3)      -- neon_amber_glow (#FFB703) - янтарные глаза

	-- =========================================================================
	-- 1. ТОРС, ГРУДЬ И ЗАГРИВОК (Torso, Pectorals, Flanks) - Центр на Y=2.5
	-- =========================================================================
	local torso = makePart("Torso", Vector3.new(2.6, 2.2, 1.9), CFrame.new(0, 2.5, 0), Enum.Material.SmoothPlastic, c_fur, false)
	model.PrimaryPart = torso

	-- Грудные пластины (Pectorals) - Спереди (-Z)
	makePart("Pectorals", Vector3.new(2.3, 1.1, 0.5), CFrame.new(0, 2.7, -0.9), Enum.Material.SmoothPlastic, c_dark)

	-- Нижняя часть живота
	makePart("LowerTorso", Vector3.new(2.3, 1.5, 1.7), CFrame.new(0, 1.35, 0.05), Enum.Material.SmoothPlastic, c_fur)

	-- Мощный горб/загривок на спине
	makePart("BackHunch", Vector3.new(2.5, 1.2, 1.4), CFrame.new(0, 3.2, 0.4), Enum.Material.SmoothPlastic, c_burnt)

	-- =========================================================================
	-- 2. ГОЛОВА, НАДБРОВЬЕ И ЧЕЛЮСТЬ (Head, Brow, Jaw) - Впереди (-Z)
	-- =========================================================================
	local head = makePart("Head", Vector3.new(1.7, 1.5, 1.6), CFrame.new(0, 3.9, -0.25), Enum.Material.SmoothPlastic, c_fur)

	-- Тяжелый надбровный валик (Brow Ridge)
	makePart("BrowRidge", Vector3.new(1.5, 0.4, 0.6), CFrame.new(0, 4.15, -0.95), Enum.Material.SmoothPlastic, c_burnt)

	-- Массивная нижняя челюсть (Ape Jaw)
	makePart("Jaw", Vector3.new(1.3, 0.7, 0.8), CFrame.new(0, 3.55, -0.90), Enum.Material.SmoothPlastic, c_skin)

	-- =========================================================================
	-- 3. СВЕТЯЩИЕСЯ ЯНТАРНЫЕ ГЛАЗА (Glowing Amber Eyes)
	-- =========================================================================
	makePart("EyeL", Vector3.new(0.24, 0.18, 0.14), CFrame.new(-0.35, 4.05, -1.1), Enum.Material.Neon, c_eye)
	makePart("EyeR", Vector3.new(0.24, 0.18, 0.14), CFrame.new(0.35, 4.05, -1.1), Enum.Material.Neon, c_eye)

	local eyeLight = Instance.new("PointLight")
	eyeLight.Name = "BigfootEyeGlow"
	eyeLight.Color = c_eye
	eyeLight.Range = 12 * scale
	eyeLight.Brightness = 1.0
	eyeLight.Parent = head

	-- =========================================================================
	-- 4. ДЛИННЫЕ РУКИ ГОРИЛЛЫ (Long Ape Arms & Heavy Fists)
	-- =========================================================================
	-- Левая рука
	makePart("ShoulderL", Vector3.new(1.2, 1.4, 1.2), CFrame.new(-1.8, 2.8, -0.05), Enum.Material.SmoothPlastic, c_fur)
	makePart("ArmL", Vector3.new(1.1, 1.9, 1.1), CFrame.new(-2.0, 1.6, -0.15), Enum.Material.SmoothPlastic, c_fur)
	makePart("HandL", Vector3.new(1.2, 0.8, 1.3), CFrame.new(-2.0, 0.45, -0.25), Enum.Material.SmoothPlastic, c_dark)

	-- Правая рука
	makePart("ShoulderR", Vector3.new(1.2, 1.4, 1.2), CFrame.new(1.8, 2.8, -0.05), Enum.Material.SmoothPlastic, c_fur)
	makePart("ArmR", Vector3.new(1.1, 1.9, 1.1), CFrame.new(2.0, 1.6, -0.15), Enum.Material.SmoothPlastic, c_fur)
	makePart("HandR", Vector3.new(1.2, 0.8, 1.3), CFrame.new(2.0, 0.45, -0.25), Enum.Material.SmoothPlastic, c_dark)

	-- =========================================================================
	-- 5. МАССИВНЫЕ НОГИ-КОЛОННЫ (Sturdy Legs & Broad Feet)
	-- =========================================================================
	-- Левая нога
	makePart("LegL", Vector3.new(1.1, 1.5, 1.2), CFrame.new(-0.8, 0.9, 0.05), Enum.Material.SmoothPlastic, c_fur)
	makePart("FootL", Vector3.new(1.2, 0.6, 1.6), CFrame.new(-0.8, 0.25, -0.15), Enum.Material.SmoothPlastic, c_dark)

	-- Правая нога
	makePart("LegR", Vector3.new(1.1, 1.5, 1.2), CFrame.new(0.8, 0.9, 0.05), Enum.Material.SmoothPlastic, c_fur)
	makePart("FootR", Vector3.new(1.2, 0.6, 1.6), CFrame.new(0.8, 0.25, -0.15), Enum.Material.SmoothPlastic, c_dark)

	-- =========================================================================
	-- 6. СВАРКА ВСЕХ ЧАСТЕЙ К ТОРСУ (WeldConstraint)
	-- =========================================================================
	for _, part in ipairs(model:GetDescendants()) do
		if part:IsA("BasePart") and part ~= torso then
			local weld = Instance.new("WeldConstraint")
			weld.Name = "Weld_" .. part.Name
			weld.Part0 = torso
			weld.Part1 = part
			weld.Parent = part
		end
	end

	if parent then
		model.Parent = parent
	end

	return model
end

return BigfootGenerator
