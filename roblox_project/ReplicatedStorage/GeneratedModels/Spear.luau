--[[
    ReplicatedStorage/GeneratedModels/Spear.luau
    Автоматически генерируемая 3D-модель охотничьего копья (Spear).
    Стилизованный Low-Poly дизайн:
    - Деревянное древко из тёплого медового дуба с резным навершием-противовесом
    - Двойные кожаные накладки хватов (Основной Handle в (0,0,0) и верхний направляющий хват)
    - Обмотка из жил / сыромятной кожи в месте крепления наконечника
    - Массивный граненый кремниевый наконечник со скошенными режущими гранями
--]]

local SpearModel = {}

function SpearModel.create(parent, targetCF)
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
	-- 1. ОСНОВНАЯ РУКОЯТЬ ХВАТА (Handle) - Центрирована в (0, 0, 0)
	-- =========================================================================
	local handle = addBlock(
		"Handle",
		Vector3.new(0.32, 1.10, 0.38),
		CFrame.new(0, 0, 0),
		Enum.Material.Fabric,
		Color3.fromHex("#713F12") -- leather_dark
	)
	container.PrimaryPart = handle

	-- Кожаные фиксирующие ремешки основного хвата
	local handleBandBot = addBlock(
		"HandleBandBot",
		Vector3.new(0.36, 0.12, 0.42),
		CFrame.new(0, -0.50, 0),
		Enum.Material.Fabric,
		Color3.fromHex("#A16207") -- leather_warm
	)

	local handleBandTop = addBlock(
		"HandleBandTop",
		Vector3.new(0.36, 0.12, 0.42),
		CFrame.new(0, 0.50, 0),
		Enum.Material.Fabric,
		Color3.fromHex("#A16207") -- leather_warm
	)

	-- =========================================================================
	-- 2. НИЖНЯЯ ЧАСТЬ ДРЕВКА И РЕЗНОЕ НАВЕРШИЕ (Lower Shaft & Pommel)
	-- =========================================================================
	local lowerShaft = addBlock(
		"LowerShaft",
		Vector3.new(0.24, 0.35, 0.28),
		CFrame.new(0, -0.68, 0),
		Enum.Material.Wood,
		Color3.fromHex("#C68B59") -- wood_honey_oak
	)

	local pommelWrap = addBlock(
		"PommelWrap",
		Vector3.new(0.28, 0.16, 0.32),
		CFrame.new(0, -0.88, 0),
		Enum.Material.Fabric,
		Color3.fromHex("#713F12") -- leather_dark
	)

	local pommelCap = addBlock(
		"PommelCap",
		Vector3.new(0.24, 0.18, 0.28),
		CFrame.new(0, -1.00, 0),
		Enum.Material.Wood,
		Color3.fromHex("#C68B59") -- wood_honey_oak
	)

	-- =========================================================================
	-- 3. СРЕДНЯЯ ЧАСТЬ ДРЕВКА И ВТОРОЙ ХВАТ (Mid Shaft & Upper Grip Pad)
	-- =========================================================================
	local midShaft = addBlock(
		"MidShaft",
		Vector3.new(0.24, 0.80, 0.28),
		CFrame.new(0, 0.95, 0),
		Enum.Material.Wood,
		Color3.fromHex("#C68B59") -- wood_honey_oak
	)

	-- Верхняя кожаная накладка направляющего хвата
	local upperGrip = addBlock(
		"UpperGrip",
		Vector3.new(0.30, 0.60, 0.35),
		CFrame.new(0, 1.65, 0),
		Enum.Material.Fabric,
		Color3.fromHex("#713F12") -- leather_dark
	)

	local upperGripBandBot = addBlock(
		"UpperGripBandBot",
		Vector3.new(0.34, 0.08, 0.38),
		CFrame.new(0, 1.39, 0),
		Enum.Material.Fabric,
		Color3.fromHex("#A16207") -- leather_warm
	)

	local upperGripBandTop = addBlock(
		"UpperGripBandTop",
		Vector3.new(0.34, 0.08, 0.38),
		CFrame.new(0, 1.91, 0),
		Enum.Material.Fabric,
		Color3.fromHex("#A16207") -- leather_warm
	)

	-- =========================================================================
	-- 4. ВЕРХНЕЕ ДРЕВКО И ОБМОТКА КРЕПЛЕНИЯ ЖИЛАМИ (Upper Shaft & Sinew Wrap)
	-- =========================================================================
	local upperShaft = addBlock(
		"UpperShaft",
		Vector3.new(0.24, 1.50, 0.28),
		CFrame.new(0, 2.70, 0),
		Enum.Material.Wood,
		Color3.fromHex("#C68B59") -- wood_honey_oak
	)

	local neckSocket = addBlock(
		"NeckSocket",
		Vector3.new(0.26, 0.35, 0.30),
		CFrame.new(0, 3.52, 0),
		Enum.Material.Wood,
		Color3.fromHex("#C68B59") -- wood_honey_oak
	)

	-- Обмотка из сухожилий / жил
	local sinewBinding = addBlock(
		"SinewBinding",
		Vector3.new(0.30, 0.40, 0.36),
		CFrame.new(0, 3.58, 0),
		Enum.Material.Fabric,
		Color3.fromHex("#FEF08A") -- twine_straw
	)

	-- Перекрещенные шнуры стяжки
	local sinewCross1 = addBlock(
		"SinewCross1",
		Vector3.new(0.34, 0.08, 0.14),
		CFrame.new(0, 3.58, 0) * CFrame.Angles(0, 0, math.rad(45)),
		Enum.Material.Fabric,
		Color3.fromHex("#A16207") -- leather_warm
	)

	local sinewCross2 = addBlock(
		"SinewCross2",
		Vector3.new(0.34, 0.08, 0.14),
		CFrame.new(0, 3.58, 0) * CFrame.Angles(0, 0, math.rad(-45)),
		Enum.Material.Fabric,
		Color3.fromHex("#A16207") -- leather_warm
	)

	-- =========================================================================
	-- 5. КРЕМНИЕВЫЙ НАКОНЕЧНИК (Flint / Chert Knapped Spearhead)
	-- =========================================================================
	-- Основание наконечника (хвостовик в пазу)
	local flintTang = addBlock(
		"FlintTang",
		Vector3.new(0.24, 0.35, 0.12),
		CFrame.new(0, 3.70, 0),
		Enum.Material.Slate,
		Color3.fromHex("#334155") -- iron_band
	)

	-- Боковые скошенные плечики наконечника (Flaked Shoulders)
	local flintRicassoL = addWedge(
		"FlintRicassoL",
		Vector3.new(0.12, 0.40, 0.36),
		CFrame.new(-0.20, 3.90, 0) * CFrame.Angles(0, math.rad(90), 0),
		Enum.Material.Slate,
		Color3.fromHex("#64748B") -- stone_slate
	)

	local flintRicassoR = addWedge(
		"FlintRicassoR",
		Vector3.new(0.12, 0.40, 0.36),
		CFrame.new(0.20, 3.90, 0) * CFrame.Angles(0, math.rad(-90), 0),
		Enum.Material.Slate,
		Color3.fromHex("#475569") -- stone_dark
	)

	-- Центральное ребро жесткости кремниевого лезвия (Spine)
	local flintSpine = addBlock(
		"FlintSpine",
		Vector3.new(0.14, 1.20, 0.20),
		CFrame.new(0, 4.40, 0),
		Enum.Material.Slate,
		Color3.fromHex("#1E293B") -- cast_iron
	)

	-- Широкое сколотое брюшко кремниевого лезвия (Flint Belly)
	local flintBellyL = addBlock(
		"FlintBellyL",
		Vector3.new(0.38, 0.60, 0.12),
		CFrame.new(-0.22, 4.30, 0),
		Enum.Material.Slate,
		Color3.fromHex("#64748B") -- stone_slate
	)

	local flintBellyR = addBlock(
		"FlintBellyR",
		Vector3.new(0.38, 0.60, 0.12),
		CFrame.new(0.22, 4.30, 0),
		Enum.Material.Slate,
		Color3.fromHex("#475569") -- stone_dark
	)

	-- Острое острие кремния (Flint Point)
	local flintTipL = addWedge(
		"FlintTipL",
		Vector3.new(0.12, 0.70, 0.40),
		CFrame.new(-0.20, 4.85, 0) * CFrame.Angles(0, math.rad(-90), 0),
		Enum.Material.Slate,
		Color3.fromHex("#64748B") -- stone_slate
	)

	local flintTipR = addWedge(
		"FlintTipR",
		Vector3.new(0.12, 0.70, 0.40),
		CFrame.new(0.20, 4.85, 0) * CFrame.Angles(0, math.rad(90), 0),
		Enum.Material.Slate,
		Color3.fromHex("#475569") -- stone_dark
	)

	-- Завершающая игла острия
	local flintNeedle = addWedge(
		"FlintNeedle",
		Vector3.new(0.12, 0.35, 0.16),
		CFrame.new(0, 5.20, 0),
		Enum.Material.Slate,
		Color3.fromHex("#334155")
	)

	-- =========================================================================
	-- 6. ТОЧНАЯ СВАРКА ВСЕХ ДЕТАЛЕЙ К РУКОЯТИ (Handle)
	-- =========================================================================
	for _, p in ipairs(container:GetChildren()) do
		if p:IsA("BasePart") and p ~= handle then
			local weld = Instance.new("WeldConstraint")
			weld.Part0 = handle
			weld.Part1 = p
			weld.Parent = p
		end
	end

	if targetCF then
		container:PivotTo(targetCF)
	end

	if parent then
		container.Parent = parent
	end

	return container
end

return SpearModel
