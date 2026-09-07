--[[
    ReplicatedStorage/GeneratedModels/Yeti.luau
    Высокоточный, стилизованный 3D-генератор Снежного Йети (Snow Yeti / Снежный Человек):
    - Мощный белоснежный пушистый торс (Torso) с объемным воротником и подбрюшьем
    - Голова с темной сланцевой маской (FaceMask), клыками и затылком
    - Ветвистые изогнутые ледяные рога (Ice Horns)
    - Светящиеся бирюзовые неоновые глаза (Neon Cyan Eyes) с PointLight
    - Массивные мускулистые лапы-руки с ледяными когтями и кулаками
    - Устойчивые толстые ноги с ледяными ступнями
    - Направлен строго вперед (в сторону -Z в Roblox)
--]]

local YetiGenerator = {}

function YetiGenerator.create(parent, targetCF, options)
	options = options or {}
	local scale = options.Scale or 1.0
	local isAnchored = (options.Anchored ~= false) and (options.isMob ~= true)

	targetCF = targetCF or CFrame.new(0, 0, 0)
	local model = Instance.new("Model")
	model.Name = "Yeti"

	local function makePart(name, size, cfOffset, material, color, canCollide)
		local p = Instance.new("Part")
		p.Name = name
		p.Size = size * scale
		local scaledPos = cfOffset.Position * scale
		local scaledRot = cfOffset - cfOffset.Position
		p.CFrame = targetCF * CFrame.new(scaledPos) * scaledRot
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
		local scaledPos = cfOffset.Position * scale
		local scaledRot = cfOffset - cfOffset.Position
		p.CFrame = targetCF * CFrame.new(scaledPos) * scaledRot
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

	-- Цветовая палитра Снежного Йети
	local c_snow = Color3.fromRGB(248, 250, 252)     -- snow_pure (#F8FAFC) - чистый белый снег
	local c_ambient = Color3.fromRGB(224, 242, 254)  -- snow_ambient (#E0F2FE) - ледяная тень
	local c_mask = Color3.fromRGB(51, 65, 85)        -- stone_dark (#334155) - темная маска лица
	local c_ice_base = Color3.fromRGB(56, 189, 248)  -- ice_glacier (#38BDF8) - ледяные рога
	local c_ice_light = Color3.fromRGB(186, 230, 253)-- ice_light (#BAE6FD) - кончики рогов
	local c_ice_deep = Color3.fromRGB(2, 132, 199)   -- ice_deep (#0284C7) - когти и копыта
	local c_eye = Color3.fromRGB(0, 245, 212)        -- neon_cyan_glow (#00F5D4) - бирюзовые глаза
	local c_fangs = Color3.fromRGB(255, 255, 255)    -- bone_ivory - клыки

	-- =========================================================================
	-- 1. ТОРС, ВОРОТНИК И ГРУДЬ (Torso, Chest, Mane) - Центр на Y=2.3
	-- =========================================================================
	local torso = makePart("Torso", Vector3.new(2.4, 2.0, 1.8), CFrame.new(0, 2.4, 0), Enum.Material.Fabric, c_snow, false)
	model.PrimaryPart = torso

	-- Нижняя часть живота
	makePart("LowerTorso", Vector3.new(2.1, 1.4, 1.6), CFrame.new(0, 1.3, 0.05), Enum.Material.Fabric, c_ambient)

	-- Пышный загривок/воротник вокруг шеи
	makePart("FurCollar", Vector3.new(2.6, 0.7, 2.0), CFrame.new(0, 3.15, -0.05), Enum.Material.Fabric, c_snow)

	-- Выступающая грудина
	makePart("ChestBulge", Vector3.new(1.8, 1.3, 0.6), CFrame.new(0, 2.5, -0.85), Enum.Material.Fabric, c_ambient)

	-- =========================================================================
	-- 2. ГОЛОВА, МАСКА И КЛЫКИ (Head & Face) - Впереди (-Z)
	-- =========================================================================
	local head = makePart("Head", Vector3.new(1.6, 1.4, 1.5), CFrame.new(0, 3.9, -0.25), Enum.Material.Fabric, c_snow)

	-- Лицевая темная сланцевая маска
	makePart("FaceMask", Vector3.new(1.2, 0.85, 0.5), CFrame.new(0, 3.75, -0.90), Enum.Material.SmoothPlastic, c_mask)

	-- Клыки (Fangs)
	makeWedge("FangL", Vector3.new(0.12, 0.28, 0.12), CFrame.new(-0.35, 3.48, -1.15) * CFrame.Angles(math.rad(180), 0, 0), Enum.Material.SmoothPlastic, c_fangs)
	makeWedge("FangR", Vector3.new(0.12, 0.28, 0.12), CFrame.new(0.35, 3.48, -1.15) * CFrame.Angles(math.rad(180), 0, 0), Enum.Material.SmoothPlastic, c_fangs)

	-- =========================================================================
	-- 3. СВЕТЯЩИЕСЯ БИРЮЗОВЫЕ ГЛАЗА (Glowing Cyan Eyes)
	-- =========================================================================
	makePart("EyeL", Vector3.new(0.24, 0.18, 0.14), CFrame.new(-0.35, 3.95, -1.12), Enum.Material.Neon, c_eye)
	makePart("EyeR", Vector3.new(0.24, 0.18, 0.14), CFrame.new(0.35, 3.95, -1.12), Enum.Material.Neon, c_eye)

	local eyeLight = Instance.new("PointLight")
	eyeLight.Name = "YetiEyeGlow"
	eyeLight.Color = c_eye
	eyeLight.Range = 12 * scale
	eyeLight.Brightness = 1.0
	eyeLight.Parent = head

	-- =========================================================================
	-- 4. ИЗОГНУТЫЕ ЛЕДЯНЫЕ РОГА (Curved Ice Horns)
	-- =========================================================================
	-- Левый рог
	makePart("HornBaseL", Vector3.new(0.35, 0.85, 0.35), CFrame.new(-0.85, 4.45, -0.20) * CFrame.Angles(math.rad(-15), 0, math.rad(-30)), Enum.Material.Ice, c_ice_base)
	makePart("HornTipL", Vector3.new(0.24, 0.70, 0.24), CFrame.new(-1.18, 4.95, 0.05) * CFrame.Angles(math.rad(-35), math.rad(15), math.rad(-45)), Enum.Material.Ice, c_ice_light)

	-- Правый рог
	makePart("HornBaseR", Vector3.new(0.35, 0.85, 0.35), CFrame.new(0.85, 4.45, -0.20) * CFrame.Angles(math.rad(-15), 0, math.rad(30)), Enum.Material.Ice, c_ice_base)
	makePart("HornTipR", Vector3.new(0.24, 0.70, 0.24), CFrame.new(1.18, 4.95, 0.05) * CFrame.Angles(math.rad(-35), math.rad(-15), math.rad(45)), Enum.Material.Ice, c_ice_light)

	-- =========================================================================
	-- 5. МУСКУЛИСТЫЕ РУКИ С ЛЕДЯНЫМИ КОГТЯМИ (Arms & Ice Claws)
	-- =========================================================================
	-- Левая рука
	makePart("ShoulderL", Vector3.new(1.1, 1.3, 1.1), CFrame.new(-1.65, 2.7, -0.05), Enum.Material.Fabric, c_snow)
	makePart("ArmL", Vector3.new(1.0, 1.6, 1.0), CFrame.new(-1.85, 1.5, -0.15), Enum.Material.Fabric, c_snow)
	makePart("ClawL", Vector3.new(1.1, 0.7, 1.2), CFrame.new(-1.85, 0.45, -0.25), Enum.Material.Ice, c_ice_deep)

	-- Правая рука
	makePart("ShoulderR", Vector3.new(1.1, 1.3, 1.1), CFrame.new(1.65, 2.7, -0.05), Enum.Material.Fabric, c_snow)
	makePart("ArmR", Vector3.new(1.0, 1.6, 1.0), CFrame.new(1.85, 1.5, -0.15), Enum.Material.Fabric, c_snow)
	makePart("ClawR", Vector3.new(1.1, 0.7, 1.2), CFrame.new(1.85, 0.45, -0.25), Enum.Material.Ice, c_ice_deep)

	-- =========================================================================
	-- 6. ТОЛСТЫЕ СНЕЖНЫЕ НОГИ (Sturdy Legs & Ice Feet)
	-- =========================================================================
	-- Левая нога
	makePart("LegL", Vector3.new(1.0, 1.4, 1.1), CFrame.new(-0.75, 0.85, 0.05), Enum.Material.Fabric, c_ambient)
	makePart("FootL", Vector3.new(1.1, 0.5, 1.5), CFrame.new(-0.75, 0.25, -0.15), Enum.Material.Ice, c_ice_base)

	-- Правая нога
	makePart("LegR", Vector3.new(1.0, 1.4, 1.1), CFrame.new(0.75, 0.85, 0.05), Enum.Material.Fabric, c_ambient)
	makePart("FootR", Vector3.new(1.1, 0.5, 1.5), CFrame.new(0.75, 0.25, -0.15), Enum.Material.Ice, c_ice_base)

	-- =========================================================================
	-- 7. СВАРКА ВСЕХ ЧАСТЕЙ К ТОРСУ (WeldConstraint)
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

return YetiGenerator
