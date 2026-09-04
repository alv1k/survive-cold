--[[
    ReplicatedStorage/GeneratedModels/Wolf.luau
    Процедурный генератор 3D-модели лесного волка со светящимися красными глазами (Wolf).
    Структура:
    Wolf (Model)
      ├── Body (торс и брюхо)
      ├── Head (голова с мордой и носом)
      ├── Ears (треугольные ушки)
      ├── Legs (4 мультяшные лапы)
      ├── Tail (пушистый хвост)
      └── Eyes (светящиеся красные неоновые глаза)
--]]

local WolfGenerator = {}

function WolfGenerator.create(parent)
	local model = Instance.new("Model")
	model.Name = "Wolf"

	-- 1. Торс (Body)
	local body = Instance.new("Part")
	body.Name = "Body"
	body.Size = Vector3.new(0.68, 0.75, 1.4)
	body.Position = Vector3.new(0, 0.85, 0)
	body.Material = Enum.Material.SmoothPlastic
	body.Color = Color3.fromRGB(71, 85, 105) -- stone_dark
	body.Anchored = false
	body.CanCollide = false
	body.Parent = model
	model.PrimaryPart = body

	-- 2. Голова (Head)
	local head = Instance.new("Part")
	head.Name = "Head"
	head.Size = Vector3.new(0.55, 0.55, 0.55)
	head.Position = Vector3.new(0, 1.15, 0.75)
	head.Material = Enum.Material.SmoothPlastic
	head.Color = Color3.fromRGB(71, 85, 105) -- stone_dark
	head.Anchored = false
	head.CanCollide = false
	head.Parent = model

	-- Морда (Snout)
	local snout = Instance.new("Part")
	snout.Name = "Snout"
	snout.Size = Vector3.new(0.32, 0.28, 0.45)
	snout.Position = Vector3.new(0, 0.98, 1.15)
	snout.Material = Enum.Material.SmoothPlastic
	snout.Color = Color3.fromRGB(100, 116, 139) -- stone_slate
	snout.Anchored = false
	snout.CanCollide = false
	snout.Parent = model

	-- Черный нос
	local nose = Instance.new("Part")
	nose.Name = "Nose"
	nose.Size = Vector3.new(0.12, 0.10, 0.08)
	nose.Position = Vector3.new(0, 1.05, 1.38)
	nose.Material = Enum.Material.SmoothPlastic
	nose.Color = Color3.fromRGB(9, 9, 11) -- pitch_black
	nose.Anchored = false
	nose.CanCollide = false
	nose.Parent = model

	-- 3. Светящиеся красные глаза (Eyes)
	local eyeLeft = Instance.new("Part")
	eyeLeft.Name = "EyeLeft"
	eyeLeft.Size = Vector3.new(0.10, 0.08, 0.06)
	eyeLeft.Position = Vector3.new(-0.16, 1.18, 1.02)
	eyeLeft.Material = Enum.Material.Neon
	eyeLeft.Color = Color3.fromRGB(255, 0, 85) -- neon_red_glow
	eyeLeft.Anchored = false
	eyeLeft.CanCollide = false
	eyeLeft.Parent = model

	local eyeRight = Instance.new("Part")
	eyeRight.Name = "EyeRight"
	eyeRight.Size = Vector3.new(0.10, 0.08, 0.06)
	eyeRight.Position = Vector3.new(0.16, 1.18, 1.02)
	eyeRight.Material = Enum.Material.Neon
	eyeRight.Color = Color3.fromRGB(255, 0, 85) -- neon_red_glow
	eyeRight.Anchored = false
	eyeRight.CanCollide = false
	eyeRight.Parent = model

	-- 4. Ушки (Ears)
	local earL = Instance.new("Part")
	earL.Name = "EarLeft"
	earL.Size = Vector3.new(0.16, 0.32, 0.16)
	earL.Position = Vector3.new(-0.18, 1.52, 0.68)
	earL.Material = Enum.Material.SmoothPlastic
	earL.Color = Color3.fromRGB(71, 85, 105)
	earL.Anchored = false
	earL.CanCollide = false
	earL.Parent = model

	local earR = Instance.new("Part")
	earR.Name = "EarRight"
	earR.Size = Vector3.new(0.16, 0.32, 0.16)
	earR.Position = Vector3.new(0.18, 1.52, 0.68)
	earR.Material = Enum.Material.SmoothPlastic
	earR.Color = Color3.fromRGB(71, 85, 105)
	earR.Anchored = false
	earR.CanCollide = false
	earR.Parent = model

	-- 5. Лапы (Legs)
	local legPositions = {
		Vector3.new(-0.24, 0.32, 0.45),
		Vector3.new(0.24, 0.32, 0.45),
		Vector3.new(-0.22, 0.32, -0.50),
		Vector3.new(0.22, 0.32, -0.50),
	}
	for i, pos in ipairs(legPositions) do
		local leg = Instance.new("Part")
		leg.Name = "Leg_" .. i
		leg.Size = Vector3.new(0.20, 0.65, 0.22)
		leg.Position = pos
		leg.Material = Enum.Material.SmoothPlastic
		leg.Color = Color3.fromRGB(71, 85, 105)
		leg.Anchored = false
		leg.CanCollide = false
		leg.Parent = model

		local w = Instance.new("WeldConstraint")
		w.Part0 = body
		w.Part1 = leg
		w.Parent = leg
	end

	-- 6. Хвост (Tail)
	local tail = Instance.new("Part")
	tail.Name = "Tail"
	tail.Size = Vector3.new(0.22, 0.25, 0.65)
	tail.CFrame = CFrame.new(0, 0.95, -0.95) * CFrame.Angles(math.rad(25), 0, 0)
	tail.Material = Enum.Material.SmoothPlastic
	tail.Color = Color3.fromRGB(71, 85, 105)
	tail.Anchored = false
	tail.CanCollide = false
	tail.Parent = model

	-- Welds для остальных деталей к Body
	for _, p in ipairs({head, snout, nose, eyeLeft, eyeRight, earL, earR, tail}) do
		local weld = Instance.new("WeldConstraint")
		weld.Part0 = body
		weld.Part1 = p
		weld.Parent = p
	end

	if parent then
		model.Parent = parent
	end

	return model
end

return WolfGenerator
