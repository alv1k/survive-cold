--[[
    ReplicatedStorage/GeneratedModels/Food.luau
    3D-генератор моделей продуктов для магазина («Survive the Cold»):
    - Bar (🍫 Шоколадный энерджи-батончик)
    - Bread (🍞 Ремесленный хлеб с надрезами)
    - Chips (🥔 Пакет хрустящих чипсов)
    - Soup (🥫 Консервная банка с супом)
    - Pepper (🌶️ Острый согревающий перец)
    - Coffee (☕ Стаканчик горячего кофе с манжетой)
    - Steak (🥩 Аппетитный стейк с прожаркой)
--]]

local FoodGenerator = {}

-- Вспомогательная функция сборки детали
local function makePart(parent, name, size, cf, color, material, shape)
	local p = Instance.new("Part")
	p.Name = name
	p.Size = size
	p.CFrame = cf
	p.Color = color
	p.Material = material or Enum.Material.SmoothPlastic
	if shape then
		p.Shape = shape
	end
	p.Anchored = true
	p.CanCollide = false
	p.CastShadow = true
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.Parent = parent
	return p
end

local function weldParts(root, part)
	local weld = Instance.new("WeldConstraint")
	weld.Part0 = root
	weld.Part1 = part
	weld.Parent = part
	return weld
end

-- 1. 🍫 Шоколадный Батончик (Energy Bar)
function FoodGenerator.createBar(parent, targetCF)
	targetCF = targetCF or CFrame.identity
	local model = Instance.new("Model")
	model.Name = "Food_Bar"

	local root = makePart(model, "Handle", Vector3.new(0.62, 0.22, 1.22), targetCF * CFrame.new(0, 0.11, 0), Color3.fromRGB(185, 28, 28), Enum.Material.SmoothPlastic)
	model.PrimaryPart = root

	-- Фольгированный край обертки
	local foil = makePart(model, "FoilSeal", Vector3.new(0.64, 0.08, 0.22), targetCF * CFrame.new(0, 0.11, 0.58), Color3.fromRGB(203, 213, 225), Enum.Material.SmoothPlastic)
	weldParts(root, foil)

	-- Открытый шоколадный кончик
	local choc = makePart(model, "Chocolate", Vector3.new(0.52, 0.18, 0.42), targetCF * CFrame.new(0, 0.11, -0.46), Color3.fromRGB(78, 42, 30), Enum.Material.SmoothPlastic)
	weldParts(root, choc)

	-- Дольки шоколада
	local ridge = makePart(model, "Ridge", Vector3.new(0.44, 0.06, 0.08), targetCF * CFrame.new(0, 0.20, -0.46), Color3.fromRGB(55, 25, 18), Enum.Material.SmoothPlastic)
	weldParts(root, ridge)

	if parent then model.Parent = parent end
	return model
end

-- 2. 🍞 Буханка Хлеба (Artisan Bread)
function FoodGenerator.createBread(parent, targetCF)
	targetCF = targetCF or CFrame.identity
	local model = Instance.new("Model")
	model.Name = "Food_Bread"

	local root = makePart(model, "Handle", Vector3.new(0.85, 0.52, 1.35), targetCF * CFrame.new(0, 0.26, 0), Color3.fromRGB(180, 115, 60), Enum.Material.WoodPlanks)
	model.PrimaryPart = root

	-- Нижняя темная корочка
	local bottom = makePart(model, "BottomCrust", Vector3.new(0.80, 0.10, 1.30), targetCF * CFrame.new(0, 0.05, 0), Color3.fromRGB(120, 70, 35), Enum.Material.WoodPlanks)
	weldParts(root, bottom)

	-- Верхние надрезы / посыпка мукой
	local score1 = makePart(model, "Score1", Vector3.new(0.60, 0.06, 0.12), targetCF * CFrame.new(0, 0.52, -0.32) * CFrame.Angles(0, math.rad(18), 0), Color3.fromRGB(245, 230, 200), Enum.Material.SmoothPlastic)
	weldParts(root, score1)

	local score2 = makePart(model, "Score2", Vector3.new(0.60, 0.06, 0.12), targetCF * CFrame.new(0, 0.52, 0.32) * CFrame.Angles(0, math.rad(-18), 0), Color3.fromRGB(245, 230, 200), Enum.Material.SmoothPlastic)
	weldParts(root, score2)

	if parent then model.Parent = parent end
	return model
end

-- 3. 🥔 Пакет Чипсов (Snack Chips)
function FoodGenerator.createChips(parent, targetCF)
	targetCF = targetCF or CFrame.identity
	local model = Instance.new("Model")
	model.Name = "Food_Chips"

	local root = makePart(model, "Handle", Vector3.new(0.72, 0.95, 0.36), targetCF * CFrame.new(0, 0.48, 0), Color3.fromRGB(245, 158, 11), Enum.Material.SmoothPlastic)
	model.PrimaryPart = root

	-- Верхний и нижний запаянный шов
	local topSeal = makePart(model, "TopSeal", Vector3.new(0.76, 0.08, 0.10), targetCF * CFrame.new(0, 0.94, 0), Color3.fromRGB(217, 119, 6), Enum.Material.SmoothPlastic)
	weldParts(root, topSeal)

	local botSeal = makePart(model, "BotSeal", Vector3.new(0.76, 0.08, 0.10), targetCF * CFrame.new(0, 0.04, 0), Color3.fromRGB(217, 119, 6), Enum.Material.SmoothPlastic)
	weldParts(root, botSeal)

	-- Яркая эмблема вкуса
	local badge = makePart(model, "Badge", Vector3.new(0.56, 0.32, 0.38), targetCF * CFrame.new(0, 0.48, 0), Color3.fromRGB(220, 38, 38), Enum.Material.SmoothPlastic)
	weldParts(root, badge)

	if parent then model.Parent = parent end
	return model
end

-- 4. 🥫 Банка Супа (Soup Tin Can)
function FoodGenerator.createSoup(parent, targetCF)
	targetCF = targetCF or CFrame.identity
	local model = Instance.new("Model")
	model.Name = "Food_Soup"

	-- Цилиндры ориентированы по оси X в Roblox, вращаем на 90 градусов
	local canCF = targetCF * CFrame.new(0, 0.44, 0) * CFrame.Angles(0, 0, math.rad(90))
	local root = makePart(model, "Handle", Vector3.new(0.86, 0.78, 0.78), canCF, Color3.fromRGB(148, 163, 184), Enum.Material.Metal, Enum.PartType.Cylinder)
	model.PrimaryPart = root

	-- Красная этикетка
	local label = makePart(model, "Label", Vector3.new(0.64, 0.80, 0.80), canCF, Color3.fromRGB(220, 38, 38), Enum.Material.SmoothPlastic, Enum.PartType.Cylinder)
	weldParts(root, label)

	-- Верхнее кольцо/крышка
	local lid = makePart(model, "Lid", Vector3.new(0.04, 0.72, 0.72), targetCF * CFrame.new(0, 0.86, 0) * CFrame.Angles(0, 0, math.rad(90)), Color3.fromRGB(226, 232, 240), Enum.Material.Metal, Enum.PartType.Cylinder)
	weldParts(root, lid)

	-- Колечко открывания
	local tab = makePart(model, "PullTab", Vector3.new(0.18, 0.04, 0.22), targetCF * CFrame.new(0.12, 0.89, 0), Color3.fromRGB(203, 213, 225), Enum.Material.Metal)
	weldParts(root, tab)

	if parent then model.Parent = parent end
	return model
end

-- 5. 🌶️ Острый Перец (Chili Pepper)
function FoodGenerator.createPepper(parent, targetCF)
	targetCF = targetCF or CFrame.identity
	local model = Instance.new("Model")
	model.Name = "Food_Pepper"

	local root = makePart(model, "Handle", Vector3.new(0.38, 0.38, 1.15), targetCF * CFrame.new(0, 0.20, 0), Color3.fromRGB(220, 38, 38), Enum.Material.SmoothPlastic)
	model.PrimaryPart = root

	-- Изогнутый носик перца
	local tip = makePart(model, "Tip", Vector3.new(0.26, 0.26, 0.40), targetCF * CFrame.new(0, 0.16, -0.65) * CFrame.Angles(math.rad(15), 0, 0), Color3.fromRGB(185, 28, 28), Enum.Material.SmoothPlastic)
	weldParts(root, tip)

	-- Зеленая чашечка и стебелек
	local calyx = makePart(model, "Calyx", Vector3.new(0.30, 0.30, 0.18), targetCF * CFrame.new(0, 0.20, 0.60), Color3.fromRGB(22, 101, 52), Enum.Material.SmoothPlastic)
	weldParts(root, calyx)

	local stem = makePart(model, "Stem", Vector3.new(0.10, 0.24, 0.10), targetCF * CFrame.new(0, 0.30, 0.70) * CFrame.Angles(math.rad(-25), 0, 0), Color3.fromRGB(34, 197, 94), Enum.Material.SmoothPlastic)
	weldParts(root, stem)

	if parent then model.Parent = parent end
	return model
end

-- 6. ☕ Горячий Кофе (Coffee Cup)
function FoodGenerator.createCoffee(parent, targetCF)
	targetCF = targetCF or CFrame.identity
	local model = Instance.new("Model")
	model.Name = "Food_Coffee"

	local cupCF = targetCF * CFrame.new(0, 0.42, 0) * CFrame.Angles(0, 0, math.rad(90))
	local root = makePart(model, "Handle", Vector3.new(0.82, 0.70, 0.70), cupCF, Color3.fromRGB(248, 250, 252), Enum.Material.SmoothPlastic, Enum.PartType.Cylinder)
	model.PrimaryPart = root

	-- Крафтовая картонная манжета
	local sleeve = makePart(model, "Sleeve", Vector3.new(0.40, 0.73, 0.73), cupCF, Color3.fromRGB(180, 115, 60), Enum.Material.WoodPlanks, Enum.PartType.Cylinder)
	weldParts(root, sleeve)

	-- Темная крышка стаканчика
	local lid = makePart(model, "Lid", Vector3.new(0.08, 0.74, 0.74), targetCF * CFrame.new(0, 0.82, 0) * CFrame.Angles(0, 0, math.rad(90)), Color3.fromRGB(30, 41, 59), Enum.Material.SmoothPlastic, Enum.PartType.Cylinder)
	weldParts(root, lid)

	if parent then model.Parent = parent end
	return model
end

-- 7. 🥩 Стейк на гриле (Ribeye Steak)
function FoodGenerator.createSteak(parent, targetCF)
	targetCF = targetCF or CFrame.identity
	local model = Instance.new("Model")
	model.Name = "Food_Steak"

	local root = makePart(model, "Handle", Vector3.new(1.10, 0.30, 1.35), targetCF * CFrame.new(0, 0.15, 0), Color3.fromRGB(153, 27, 27), Enum.Material.SmoothPlastic)
	model.PrimaryPart = root

	-- Жировая прослойка по краю
	local fat = makePart(model, "FatEdge", Vector3.new(0.20, 0.28, 1.25), targetCF * CFrame.new(-0.50, 0.15, 0), Color3.fromRGB(254, 243, 199), Enum.Material.SmoothPlastic)
	weldParts(root, fat)

	-- Полосы прожарки гриля
	local mark1 = makePart(model, "Grill1", Vector3.new(0.08, 0.32, 1.10), targetCF * CFrame.new(-0.15, 0.15, 0) * CFrame.Angles(0, math.rad(25), 0), Color3.fromRGB(45, 20, 20), Enum.Material.SmoothPlastic)
	weldParts(root, mark1)

	local mark2 = makePart(model, "Grill2", Vector3.new(0.08, 0.32, 1.00), targetCF * CFrame.new(0.22, 0.15, 0) * CFrame.Angles(0, math.rad(25), 0), Color3.fromRGB(45, 20, 20), Enum.Material.SmoothPlastic)
	weldParts(root, mark2)

	-- Косточка
	local bone = makePart(model, "Bone", Vector3.new(0.18, 0.32, 0.30), targetCF * CFrame.new(0.48, 0.15, -0.40), Color3.fromRGB(241, 245, 249), Enum.Material.SmoothPlastic)
	weldParts(root, bone)

	if parent then model.Parent = parent end
	return model
end

-- Фабричный метод создания по ключу
function FoodGenerator.createFood(foodKey, parent, targetCF)
	if not foodKey then return nil end
	local key = string.lower(foodKey)

	if key == "bar" or string.find(key, "батончик") then
		return FoodGenerator.createBar(parent, targetCF)
	elseif key == "bread" or string.find(key, "хлеб") then
		return FoodGenerator.createBread(parent, targetCF)
	elseif key == "chips" or string.find(key, "чипс") then
		return FoodGenerator.createChips(parent, targetCF)
	elseif key == "soup" or string.find(key, "суп") then
		return FoodGenerator.createSoup(parent, targetCF)
	elseif key == "pepper" or string.find(key, "перец") then
		return FoodGenerator.createPepper(parent, targetCF)
	elseif key == "coffee" or string.find(key, "кофе") then
		return FoodGenerator.createCoffee(parent, targetCF)
	elseif key == "steak" or string.find(key, "стейк") then
		return FoodGenerator.createSteak(parent, targetCF)
	end
	return nil
end

function FoodGenerator.create(parent, foodKey)
	return FoodGenerator.createFood(foodKey or "Bread", parent)
end

return FoodGenerator

