--[[
    ReplicatedStorage/GeneratedModels/Spear.luau
    Автоматически генерируемая 3D-модель изящного охотничьего копья (Spear).
    Стилизованный Low-Poly дизайн: четкие грани, правильные пропорции, 100% надежная геометрия Roblox.
--]]

local SpearModel = {}

function SpearModel.create(parent)
	local container = Instance.new("Model")
	container.Name = "Spear"

	local function addBlock(name, size, cfOffset, material, color)
		local p = Instance.new("Part")
		p.Name = name
		p.Size = size
		p.CFrame = cfOffset
		p.Material = material or Enum.Material.SmoothPlastic
		p.Color = color or Color3.fromRGB(200, 200, 200)
		p.CanCollide = false
		p.Massless = true
		p.Anchored = false
		p.CastShadow = true
		p.Parent = container
		return p
	end

	local function addWedge(name, size, cfOffset, material, color)
		local p = Instance.new("WedgePart")
		p.Name = name
		p.Size = size
		p.CFrame = cfOffset
		p.Material = material or Enum.Material.SmoothPlastic
		p.Color = color or Color3.fromRGB(200, 200, 200)
		p.CanCollide = false
		p.Massless = true
		p.Anchored = false
		p.CastShadow = true
		p.Parent = container
		return p
	end

	-- =========================================================================
	-- 1. РУКОЯТЬ ХВАТА (Handle) - Центрирована в (0, 0, 0)
	-- =========================================================================
	local handle = addBlock(
		"Handle",
		Vector3.new(0.32, 1.10, 0.32),
		CFrame.new(0, 0, 0),
		Enum.Material.Fabric,
		Color3.fromHex("#713F12") -- leather_dark
	)
	container.PrimaryPart = handle

	-- Кольца-ограничители хвата (бронза)
	local gripRingTop = addBlock(
		"GripRingTop",
		Vector3.new(0.38, 0.12, 0.38),
		CFrame.new(0, 0.55, 0),
		Enum.Material.Metal,
		Color3.fromHex("#D97706") -- copper_bronze
	)

	local gripRingBot = addBlock(
		"GripRingBot",
		Vector3.new(0.38, 0.12, 0.38),
		CFrame.new(0, -0.55, 0),
		Enum.Material.Metal,
		Color3.fromHex("#D97706") -- copper_bronze
	)

	-- =========================================================================
	-- 2. ОСНОВНОЕ ДЕРЕВЯННОЕ ДРЕВКО (Shaft)
	-- =========================================================================
	-- Прочное деревянное древко из тёплого дуба (чётко выражено и отлично видно!)
	local shaft = addBlock(
		"Shaft",
		Vector3.new(0.28, 2.50, 0.28),
		CFrame.new(0, 1.80, 0),
		Enum.Material.Wood,
		Color3.fromHex("#C68B59") -- wood_honey_oak
	)

	-- =========================================================================
	-- 3. НИЖНЯЯ ЧАСТЬ И СТАЛЬНОЙ НАВЕРШИЕ-ПРОТИВОВЕС (Pommel & Butt Spike)
	-- =========================================================================
	local lowerShaft = addBlock(
		"LowerShaft",
		Vector3.new(0.28, 0.35, 0.28),
		CFrame.new(0, -0.75, 0),
		Enum.Material.Wood,
		Color3.fromHex("#C68B59")
	)

	local buttCollar = addBlock(
		"ButtCollar",
		Vector3.new(0.36, 0.14, 0.36),
		CFrame.new(0, -0.96, 0),
		Enum.Material.Metal,
		Color3.fromHex("#334155") -- iron_band
	)

	-- Заострённый подток (Butt Spike)
	local buttSpike1 = addWedge(
		"ButtSpike1",
		Vector3.new(0.26, 0.45, 0.13),
		CFrame.new(0, -1.22, 0.065) * CFrame.Angles(math.rad(180), 0, 0),
		Enum.Material.Metal,
		Color3.fromHex("#E2E8F0") -- slate_light
	)

	local buttSpike2 = addWedge(
		"ButtSpike2",
		Vector3.new(0.26, 0.45, 0.13),
		CFrame.new(0, -1.22, -0.065) * CFrame.Angles(math.rad(180), math.rad(180), 0),
		Enum.Material.Metal,
		Color3.fromHex("#94A3B8") -- steel_light
	)

	-- =========================================================================
	-- 4. ШЕЙНАЯ ОБМОТКА И СТАЛЬНАЯ ВТУЛКА (Neck Wrap & Collar)
	-- =========================================================================
	local neckWrap = addBlock(
		"NeckWrap",
		Vector3.new(0.34, 0.45, 0.34),
		CFrame.new(0, 3.20, 0),
		Enum.Material.Fabric,
		Color3.fromHex("#FEF08A") -- twine_straw
	)

	local collar = addBlock(
		"Collar",
		Vector3.new(0.38, 0.30, 0.38),
		CFrame.new(0, 3.55, 0),
		Enum.Material.Metal,
		Color3.fromHex("#334155") -- iron_band
	)

	-- Бронзовые боковые крылья-упоры (Winged Hunting Spear Lugs)
	local lugLeft = addWedge(
		"LugLeft",
		Vector3.new(0.12, 0.32, 0.28),
		CFrame.new(-0.28, 3.55, 0) * CFrame.Angles(0, math.rad(-90), math.rad(-35)),
		Enum.Material.Metal,
		Color3.fromHex("#D97706") -- copper_bronze
	)

	local lugRight = addWedge(
		"LugRight",
		Vector3.new(0.12, 0.32, 0.28),
		CFrame.new(0.28, 3.55, 0) * CFrame.Angles(0, math.rad(90), math.rad(35)),
		Enum.Material.Metal,
		Color3.fromHex("#D97706") -- copper_bronze
	)

	-- =========================================================================
	-- 5. СКУЛЬПТУРНЫЙ ЛИСТОВИДНЫЙ НАКОНЕЧНИК (Leaf-Diamond Spearhead)
	-- =========================================================================
	-- Рикассо / основание лезвия (расширение от втулки к брюшку)
	local ricassoL = addWedge(
		"RicassoL",
		Vector3.new(0.10, 0.45, 0.35),
		CFrame.new(-0.16, 3.90, 0) * CFrame.Angles(0, math.rad(90), 0),
		Enum.Material.Metal,
		Color3.fromHex("#E2E8F0") -- slate_light (светлая грань)
	)

	local ricassoR = addWedge(
		"RicassoR",
		Vector3.new(0.10, 0.45, 0.35),
		CFrame.new(0.16, 3.90, 0) * CFrame.Angles(0, math.rad(-90), 0),
		Enum.Material.Metal,
		Color3.fromHex("#94A3B8") -- steel_light (теневая грань)
	)

	-- Центральное ребро жёсткости лезвия (Spine)
	local bladeSpine = addBlock(
		"BladeSpine",
		Vector3.new(0.12, 1.40, 0.16),
		CFrame.new(0, 4.45, 0),
		Enum.Material.Metal,
		Color3.fromHex("#64748B") -- stone_slate
	)

	-- Широкое брюшко лезвия (Leaf Belly)
	local bladeBellyL = addBlock(
		"BladeBellyL",
		Vector3.new(0.28, 0.65, 0.08),
		CFrame.new(-0.20, 4.35, 0),
		Enum.Material.Metal,
		Color3.fromHex("#E2E8F0")
	)

	local bladeBellyR = addBlock(
		"BladeBellyR",
		Vector3.new(0.28, 0.65, 0.08),
		CFrame.new(0.20, 4.35, 0),
		Enum.Material.Metal,
		Color3.fromHex("#94A3B8")
	)

	-- Игловидное острие (Needle Tip)
	local tipL = addWedge(
		"TipL",
		Vector3.new(0.08, 0.75, 0.32),
		CFrame.new(-0.16, 4.95, 0) * CFrame.Angles(0, math.rad(-90), 0),
		Enum.Material.Metal,
		Color3.fromHex("#E2E8F0")
	)

	local tipR = addWedge(
		"TipR",
		Vector3.new(0.08, 0.75, 0.32),
		CFrame.new(0.16, 4.95, 0) * CFrame.Angles(0, math.rad(90), 0),
		Enum.Material.Metal,
		Color3.fromHex("#94A3B8")
	)

	-- =========================================================================
	-- 6. ТОЧНАЯ СВАРКА ВСЕХ ДЕТАЛЕЙ К HANDLE
	-- =========================================================================
	for _, p in ipairs(container:GetChildren()) do
		if p:IsA("BasePart") and p ~= handle then
			local weld = Instance.new("WeldConstraint")
			weld.Part0 = handle
			weld.Part1 = p
			weld.Parent = p
		end
	end

	if parent then
		container.Parent = parent
	end

	return container
end

return SpearModel
