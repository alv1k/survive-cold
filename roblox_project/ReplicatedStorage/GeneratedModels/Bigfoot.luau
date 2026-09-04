--[[
    ReplicatedStorage/GeneratedModels/Bigfoot.luau
    Процедурный генератор 3D-модели Бигфута с янтарными глазами (Bigfoot).
    Структура:
    Bigfoot (Model)
      ├── Torso (мощный темно-коричневый торс с широкими плечами)
      ├── Head (голова гориллы с тяжелыми надбровными дугами)
      ├── Arms (длинные мускулистые руки до земли)
      ├── Legs (массивные устойчивые ноги)
      └── Eyes (светящиеся янтарные неоновые глаза)
--]]

local BigfootGenerator = {}

function BigfootGenerator.create(parent)
	local model = Instance.new("Model")
	model.Name = "Bigfoot"

	-- 1. Торс (Torso)
	local torso = Instance.new("Part")
	torso.Name = "Torso"
	torso.Size = Vector3.new(1.60, 1.35, 1.10)
	torso.Position = Vector3.new(0, 1.50, 0)
	torso.Material = Enum.Material.SmoothPlastic
	torso.Color = Color3.fromRGB(92, 46, 11) -- wood_walnut
	torso.Anchored = false
	torso.CanCollide = false
	torso.Parent = model
	model.PrimaryPart = torso

	-- Грудные плиты / Рельеф (Pectorals)
	local pecs = Instance.new("Part")
	pecs.Name = "Pectorals"
	pecs.Size = Vector3.new(1.45, 0.70, 0.35)
	pecs.Position = Vector3.new(0, 1.60, 0.48)
	pecs.Material = Enum.Material.SmoothPlastic
	pecs.Color = Color3.fromRGB(62, 30, 8) -- wood_bark
	pecs.Anchored = false
	pecs.CanCollide = false
	pecs.Parent = model

	-- 2. Голова (Head)
	local head = Instance.new("Part")
	head.Name = "Head"
	head.Size = Vector3.new(0.80, 0.70, 0.75)
	head.Position = Vector3.new(0, 2.40, 0.05)
	head.Material = Enum.Material.SmoothPlastic
	head.Color = Color3.fromRGB(92, 46, 11)
	head.Anchored = false
	head.CanCollide = false
	head.Parent = model

	-- Брови (Brow)
	local brow = Instance.new("Part")
	brow.Name = "BrowRidge"
	brow.Size = Vector3.new(0.75, 0.22, 0.25)
	brow.Position = Vector3.new(0, 2.50, 0.42)
	brow.Material = Enum.Material.SmoothPlastic
	brow.Color = Color3.fromRGB(41, 37, 36) -- wood_burnt
	brow.Anchored = false
	brow.CanCollide = false
	brow.Parent = model

	-- Челюсть (Jaw)
	local jaw = Instance.new("Part")
	jaw.Name = "Jaw"
	jaw.Size = Vector3.new(0.60, 0.32, 0.35)
	jaw.Position = Vector3.new(0, 2.20, 0.40)
	jaw.Material = Enum.Material.SmoothPlastic
	jaw.Color = Color3.fromRGB(56, 34, 15) -- soil_dark
	jaw.Anchored = false
	jaw.CanCollide = false
	jaw.Parent = model

	-- 3. Светящиеся янтарные глаза (Eyes)
	local eyeL = Instance.new("Part")
	eyeL.Name = "EyeLeft"
	eyeL.Size = Vector3.new(0.14, 0.10, 0.08)
	eyeL.Position = Vector3.new(-0.16, 2.46, 0.46)
	eyeL.Material = Enum.Material.Neon
	eyeL.Color = Color3.fromRGB(255, 183, 3) -- neon_amber_glow
	eyeL.Anchored = false
	eyeL.CanCollide = false
	eyeL.Parent = model

	local eyeR = Instance.new("Part")
	eyeR.Name = "EyeRight"
	eyeR.Size = Vector3.new(0.14, 0.10, 0.08)
	eyeR.Position = Vector3.new(0.16, 2.46, 0.46)
	eyeR.Material = Enum.Material.Neon
	eyeR.Color = Color3.fromRGB(255, 183, 3) -- neon_amber_glow
	eyeR.Anchored = false
	eyeR.CanCollide = false
	eyeR.Parent = model

	-- 4. Руки гориллы (Arms)
	local armL = Instance.new("Part")
	armL.Name = "ArmLeft"
	armL.Size = Vector3.new(0.45, 1.75, 0.45)
	armL.Position = Vector3.new(-1.05, 1.25, 0.08)
	armL.Material = Enum.Material.SmoothPlastic
	armL.Color = Color3.fromRGB(62, 30, 8) -- wood_bark
	armL.Anchored = false
	armL.CanCollide = false
	armL.Parent = model

	local armR = Instance.new("Part")
	armR.Name = "ArmRight"
	armR.Size = Vector3.new(0.45, 1.75, 0.45)
	armR.Position = Vector3.new(1.05, 1.25, 0.08)
	armR.Material = Enum.Material.SmoothPlastic
	armR.Color = Color3.fromRGB(62, 30, 8)
	armR.Anchored = false
	armR.CanCollide = false
	armR.Parent = model

	-- 5. Ноги (Legs)
	local legL = Instance.new("Part")
	legL.Name = "LegLeft"
	legL.Size = Vector3.new(0.48, 0.95, 0.65)
	legL.Position = Vector3.new(-0.46, 0.48, 0)
	legL.Material = Enum.Material.SmoothPlastic
	legL.Color = Color3.fromRGB(92, 46, 11)
	legL.Anchored = false
	legL.CanCollide = false
	legL.Parent = model

	local legR = Instance.new("Part")
	legR.Name = "LegRight"
	legR.Size = Vector3.new(0.48, 0.95, 0.65)
	legR.Position = Vector3.new(0.46, 0.48, 0)
	legR.Material = Enum.Material.SmoothPlastic
	legR.Color = Color3.fromRGB(92, 46, 11)
	legR.Anchored = false
	legR.CanCollide = false
	legR.Parent = model

	-- Welds
	for _, p in ipairs({pecs, head, brow, jaw, eyeL, eyeR, armL, armR, legL, legR}) do
		local weld = Instance.new("WeldConstraint")
		weld.Part0 = torso
		weld.Part1 = p
		weld.Parent = p
	end

	if parent then
		model.Parent = parent
	end

	return model
end

return BigfootGenerator
