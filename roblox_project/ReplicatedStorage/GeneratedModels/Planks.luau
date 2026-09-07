--[[
    ReplicatedStorage/GeneratedModels/Planks.luau
    Процедурный генератор 3D-модели штабеля досок (Planks):
    - 6 досок, положенных друг на друга горизонтально в одном направлении
    - Различие углов между слоями: 4-15 градусов
    - Разные натуральные древесные оттенки коричневого цвета
    - Базовая высота установки: Y = 2.0 (поверхность снежной равнины)
--]]

local PlanksGenerator = {}

function PlanksGenerator.create(parent, targetCF)
	targetCF = targetCF or CFrame.new(0, 2.0, 0)
	local model = Instance.new("Model")
	model.Name = "Planks"

	-- Конфигурация 6 горизонтальных досок в штабеле:
	-- Поворот вокруг Y (в градусах), смещение (X, Y, Z), размеры (X, Y, Z), цвет дерева
	local plankConfigs = {
		{
			name = "Plank_1",
			offset = Vector3.new(0.00, 0.09, 0.00),
			angleDeg = -2.0,
			size = Vector3.new(2.60, 0.18, 0.65),
			color = Color3.fromRGB(92, 46, 11), -- wood_walnut (глубокий темный орех)
		},
		{
			name = "Plank_2",
			offset = Vector3.new(0.04, 0.27, 0.03),
			angleDeg = 6.0, -- Разница с Plank_1: 8°
			size = Vector3.new(2.55, 0.18, 0.62),
			color = Color3.fromRGB(140, 69, 26), -- wood_cedar (теплый кедр)
		},
		{
			name = "Plank_3",
			offset = Vector3.new(-0.03, 0.45, -0.04),
			angleDeg = -3.0, -- Разница с Plank_2: 9°
			size = Vector3.new(2.65, 0.18, 0.66),
			color = Color3.fromRGB(198, 139, 89), -- wood_honey_oak (медовый дуб)
		},
		{
			name = "Plank_4",
			offset = Vector3.new(0.05, 0.63, 0.02),
			angleDeg = 7.0, -- Разница с Plank_3: 10°
			size = Vector3.new(2.52, 0.18, 0.63),
			color = Color3.fromRGB(229, 195, 158), -- wood_pine (светлая сосна)
		},
		{
			name = "Plank_5",
			offset = Vector3.new(-0.04, 0.81, 0.04),
			angleDeg = -4.0, -- Разница с Plank_4: 11°
			size = Vector3.new(2.58, 0.18, 0.62),
			color = Color3.fromRGB(161, 98, 7), -- leather_warm (янтарное дерево)
		},
		{
			name = "Plank_6",
			offset = Vector3.new(0.02, 0.99, -0.03),
			angleDeg = 3.0, -- Разница с Plank_5: 7°
			size = Vector3.new(2.56, 0.18, 0.65),
			color = Color3.fromRGB(180, 130, 85), -- wood_oak (натуральный дуб)
		},
	}

	local parts = {}
	local primaryPart = nil

	for i, cfg in ipairs(plankConfigs) do
		local p = Instance.new("Part")
		p.Name = cfg.name
		p.Size = cfg.size
		p.CFrame = targetCF * CFrame.new(cfg.offset) * CFrame.Angles(0, math.rad(cfg.angleDeg), 0)
		p.Material = Enum.Material.Wood
		p.Color = cfg.color
		p.Anchored = true
		p.CanCollide = false
		p.Transparency = 0
		p.CastShadow = true
		p.TopSurface = Enum.SurfaceType.Smooth
		p.BottomSurface = Enum.SurfaceType.Smooth
		p.Parent = model

		if i == 1 then
			primaryPart = p
			model.PrimaryPart = p
		else
			table.insert(parts, p)
		end
	end

	-- Welds для единой сборки
	for _, p in ipairs(parts) do
		local weld = Instance.new("WeldConstraint")
		weld.Name = "Weld_" .. p.Name
		weld.Part0 = primaryPart
		weld.Part1 = p
		weld.Parent = p
	end

	if parent then
		model.Parent = parent
	end

	return model
end

return PlanksGenerator
