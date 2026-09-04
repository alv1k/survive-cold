--[[
    ReplicatedStorage/GeneratedModels/Planks.luau
    Процедурный генератор 3D-модели штабеля досок (Planks) - в размер дропа из сундука:
    - 4 доски крест-накрест (длина 2.8 студа)
    - Металлическая кованая стяжка
--]]

local PlanksGenerator = {}

function PlanksGenerator.create(parent, targetCF)
	targetCF = targetCF or CFrame.identity
	local model = Instance.new("Model")
	model.Name = "Planks"

	-- Нижний слой (2 доски вдоль X)
	local p1 = Instance.new("Part")
	p1.Name = "Plank_Bottom_1"
	p1.Size = Vector3.new(3.4, 0.55, 1.0)
	p1.CFrame = targetCF * CFrame.new(0, 0.28, -0.6)
	p1.Material = Enum.Material.Wood
	p1.Color = Color3.fromRGB(198, 139, 89) -- wood_honey_oak
	p1.Anchored = true
	p1.CanCollide = false
	p1.Parent = model
	model.PrimaryPart = p1

	local p2 = Instance.new("Part")
	p2.Name = "Plank_Bottom_2"
	p2.Size = Vector3.new(3.4, 0.55, 1.0)
	p2.CFrame = targetCF * CFrame.new(0.08, 0.28, 0.6)
	p2.Material = Enum.Material.Wood
	p2.Color = Color3.fromRGB(140, 69, 26) -- wood_cedar
	p2.Anchored = true
	p2.CanCollide = false
	p2.Parent = model

	-- Верхний слой (2 доски поперек вдоль Z)
	local p3 = Instance.new("Part")
	p3.Name = "Plank_Top_1"
	p3.Size = Vector3.new(1.0, 0.55, 3.4)
	p3.CFrame = targetCF * CFrame.new(-0.6, 0.8, 0)
	p3.Material = Enum.Material.Wood
	p3.Color = Color3.fromRGB(229, 195, 158) -- wood_pine
	p3.Anchored = true
	p3.CanCollide = false
	p3.Parent = model

	local p4 = Instance.new("Part")
	p4.Name = "Plank_Top_2"
	p4.Size = Vector3.new(1.0, 0.55, 3.4)
	p4.CFrame = targetCF * CFrame.new(0.6, 0.8, -0.04)
	p4.Material = Enum.Material.Wood
	p4.Color = Color3.fromRGB(198, 139, 89) -- wood_honey_oak
	p4.Anchored = true
	p4.CanCollide = false
	p4.Parent = model

	-- Металлическая стяжка
	local bracket = Instance.new("Part")
	bracket.Name = "Bracket"
	bracket.Size = Vector3.new(2.4, 0.1, 0.45)
	bracket.CFrame = targetCF * CFrame.new(0, 1.1, 0)
	bracket.Material = Enum.Material.Metal
	bracket.Color = Color3.fromRGB(30, 41, 59) -- cast iron
	bracket.Anchored = true
	bracket.CanCollide = false
	bracket.Parent = model

	-- Welds
	for _, p in ipairs({p2, p3, p4, bracket}) do
		local weld = Instance.new("WeldConstraint")
		weld.Part0 = p1
		weld.Part1 = p
		weld.Parent = p
	end

	if parent then
		model.Parent = parent
	end

	return model
end

return PlanksGenerator
