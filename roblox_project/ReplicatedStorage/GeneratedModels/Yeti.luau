--[[
    ReplicatedStorage/GeneratedModels/Yeti.luau
    Процедурный генератор 3D-модели Снежного Йети со светящимися бирюзовыми глазами и ледяными рожками (Yeti).
    Структура:
    Yeti (Model)
      ├── Torso (объемный белый пушистый шар-торс)
      ├── Head (голова с темной маской и клыками)
      ├── Horns (ледяные голубые рожки)
      ├── Arms (мощные лапы-руки с кулаками)
      ├── Legs (толстые короткие ноги)
      └── Eyes (светящиеся бирюзовые неоновые глаза)
--]]

local YetiGenerator = {}

function YetiGenerator.create(parent)
	local model = Instance.new("Model")
	model.Name = "Yeti"

	-- 1. Торс (Torso)
	local torso = Instance.new("Part")
	torso.Name = "Torso"
	torso.Size = Vector3.new(1.45, 1.25, 1.15)
	torso.Position = Vector3.new(0, 1.35, 0)
	torso.Material = Enum.Material.Snow
	torso.Color = Color3.fromRGB(255, 255, 255) -- snow_pure
	torso.Anchored = false
	torso.CanCollide = false
	torso.Parent = model
	model.PrimaryPart = torso

	-- 2. Голова (Head)
	local head = Instance.new("Part")
	head.Name = "Head"
	head.Size = Vector3.new(0.85, 0.70, 0.75)
	head.Position = Vector3.new(0, 2.30, 0.05)
	head.Material = Enum.Material.Snow
	head.Color = Color3.fromRGB(255, 255, 255)
	head.Anchored = false
	head.CanCollide = false
	head.Parent = model

	-- Лицевая темная маска
	local faceMask = Instance.new("Part")
	faceMask.Name = "FaceMask"
	faceMask.Size = Vector3.new(0.65, 0.45, 0.15)
	faceMask.Position = Vector3.new(0, 2.25, 0.42)
	faceMask.Material = Enum.Material.SmoothPlastic
	faceMask.Color = Color3.fromRGB(71, 85, 105) -- stone_dark
	faceMask.Anchored = false
	faceMask.CanCollide = false
	faceMask.Parent = model

	-- 3. Светящиеся бирюзовые глаза (Eyes)
	local eyeL = Instance.new("Part")
	eyeL.Name = "EyeLeft"
	eyeL.Size = Vector3.new(0.14, 0.12, 0.08)
	eyeL.Position = Vector3.new(-0.16, 2.36, 0.48)
	eyeL.Material = Enum.Material.Neon
	eyeL.Color = Color3.fromRGB(0, 245, 212) -- neon_cyan_glow
	eyeL.Anchored = false
	eyeL.CanCollide = false
	eyeL.Parent = model

	local eyeR = Instance.new("Part")
	eyeR.Name = "EyeRight"
	eyeR.Size = Vector3.new(0.14, 0.12, 0.08)
	eyeR.Position = Vector3.new(0.16, 2.36, 0.48)
	eyeR.Material = Enum.Material.Neon
	eyeR.Color = Color3.fromRGB(0, 245, 212) -- neon_cyan_glow
	eyeR.Anchored = false
	eyeR.CanCollide = false
	eyeR.Parent = model

	-- 4. Ледяные рожки (Horns)
	local hornL = Instance.new("Part")
	hornL.Name = "HornLeft"
	hornL.Size = Vector3.new(0.18, 0.38, 0.18)
	hornL.CFrame = CFrame.new(-0.45, 2.75, -0.05) * CFrame.Angles(math.rad(-15), 0, math.rad(-25))
	hornL.Material = Enum.Material.Ice
	hornL.Color = Color3.fromRGB(56, 189, 248) -- ice_glacier
	hornL.Anchored = false
	hornL.CanCollide = false
	hornL.Parent = model

	local hornR = Instance.new("Part")
	hornR.Name = "HornRight"
	hornR.Size = Vector3.new(0.18, 0.38, 0.18)
	hornR.CFrame = CFrame.new(0.45, 2.75, -0.05) * CFrame.Angles(math.rad(-15), 0, math.rad(25))
	hornR.Material = Enum.Material.Ice
	hornR.Color = Color3.fromRGB(56, 189, 248) -- ice_glacier
	hornR.Anchored = false
	hornR.CanCollide = false
	hornR.Parent = model

	-- 5. Руки-лапы (Arms)
	local armL = Instance.new("Part")
	armL.Name = "ArmLeft"
	armL.Size = Vector3.new(0.42, 1.45, 0.45)
	armL.Position = Vector3.new(-0.95, 1.25, 0.08)
	armL.Material = Enum.Material.Snow
	armL.Color = Color3.fromRGB(255, 255, 255)
	armL.Anchored = false
	armL.CanCollide = false
	armL.Parent = model

	local armR = Instance.new("Part")
	armR.Name = "ArmRight"
	armR.Size = Vector3.new(0.42, 1.45, 0.45)
	armR.Position = Vector3.new(0.95, 1.25, 0.08)
	armR.Material = Enum.Material.Snow
	armR.Color = Color3.fromRGB(255, 255, 255)
	armR.Anchored = false
	armR.CanCollide = false
	armR.Parent = model

	-- 6. Ноги (Legs)
	local legL = Instance.new("Part")
	legL.Name = "LegLeft"
	legL.Size = Vector3.new(0.45, 0.85, 0.55)
	legL.Position = Vector3.new(-0.42, 0.42, 0)
	legL.Material = Enum.Material.Snow
	legL.Color = Color3.fromRGB(240, 248, 255) -- snow_ambient
	legL.Anchored = false
	legL.CanCollide = false
	legL.Parent = model

	local legR = Instance.new("Part")
	legR.Name = "LegRight"
	legR.Size = Vector3.new(0.45, 0.85, 0.55)
	legR.Position = Vector3.new(0.42, 0.42, 0)
	legR.Material = Enum.Material.Snow
	legR.Color = Color3.fromRGB(240, 248, 255)
	legR.Anchored = false
	legR.CanCollide = false
	legR.Parent = model

	-- Welds
	for _, p in ipairs({head, faceMask, eyeL, eyeR, hornL, hornR, armL, armR, legL, legR}) do
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

return YetiGenerator
