--[[
    ReplicatedStorage/GeneratedModels/Campfire.luau
    Процедурный генератор 3D-модели походного костра (Campfire).
    Структура:
    Campfire (Model)
      ├── FireRing (каменное кольцо)
      ├── FireLogs (перекрещенные поленья)
      ├── Embers (тлеющие угли)
      └── Flame (стилизованное пламя)
--]]

local CampfireGenerator = {}

function CampfireGenerator.create(parent)
	local model = Instance.new("Model")
	model.Name = "Campfire"

	-- 1. Тлеющие угли (Embers)
	local embers = Instance.new("Part")
	embers.Name = "Embers"
	embers.Size = Vector3.new(1.2, 0.2, 1.2)
	embers.Position = Vector3.new(0, 0.1, 0)
	embers.Material = Enum.Material.Neon
	embers.Color = Color3.fromRGB(239, 68, 68) -- Ember Red
	embers.Anchored = false
	embers.CanCollide = false
	embers.Parent = model
	model.PrimaryPart = embers

	-- 2. Каменное кольцо (FireRing)
	local stones = {}
	for i = 1, 6 do
		local ang = (i - 1) * (math.pi / 3)
		local st = Instance.new("Part")
		st.Name = "Stone_" .. i
		st.Size = Vector3.new(0.5, 0.35, 0.45)
		st.Position = Vector3.new(math.cos(ang) * 1.05, 0.18, math.sin(ang) * 1.05)
		st.Material = Enum.Material.Slate
		st.Color = (i % 2 == 0) and Color3.fromRGB(100, 116, 139) or Color3.fromRGB(71, 85, 105)
		st.Anchored = false
		st.CanCollide = false
		st.Parent = model
		table.insert(stones, st)
	end

	-- 3. Перекрещенные бревна (FireLogs)
	local logs = {}
	for i = 1, 4 do
		local ang = (i - 1) * (math.pi / 2) + 0.4
		local log = Instance.new("Part")
		log.Name = "Log_" .. i
		log.Size = Vector3.new(0.25, 0.25, 1.1)
		local midPos = Vector3.new(math.cos(ang) * 0.45, 0.35, math.sin(ang) * 0.45)
		log.CFrame = CFrame.lookAt(midPos, Vector3.new(0, 0.6, 0))
		log.Material = Enum.Material.Wood
		log.Color = Color3.fromRGB(140, 69, 26) -- Cedar
		log.Anchored = false
		log.CanCollide = false
		log.Parent = model
		table.insert(logs, log)
	end

	-- 4. Стилизованное пламя (Flame)
	local flame = Instance.new("Part")
	flame.Name = "Flame"
	flame.Size = Vector3.new(0.6, 1.1, 0.6)
	flame.Position = Vector3.new(0, 0.85, 0)
	flame.Material = Enum.Material.Neon
	flame.Color = Color3.fromRGB(249, 115, 22) -- Bright Orange
	flame.Anchored = false
	flame.CanCollide = false
	flame.Parent = model

	local light = Instance.new("PointLight", flame)
	light.Color = Color3.fromRGB(251, 146, 60)
	light.Range = 12
	light.Brightness = 0.6

	-- Сварка всех деталей с PrimaryPart (Embers)
	local allSubParts = {flame}
	for _, s in ipairs(stones) do table.insert(allSubParts, s) end
	for _, l in ipairs(logs) do table.insert(allSubParts, l) end

	for _, part in ipairs(allSubParts) do
		local weld = Instance.new("WeldConstraint")
		weld.Part0 = embers
		weld.Part1 = part
		weld.Parent = part
	end

	if parent then
		model.Parent = parent
	end
	return model
end

return CampfireGenerator
