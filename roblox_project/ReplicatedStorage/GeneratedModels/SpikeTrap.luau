--[[
    ReplicatedStorage/GeneratedModels/SpikeTrap.luau
    Процедурный генератор 3D-модели напольных защитных шипов (Spike Trap).
--]]

local SpikeTrapGenerator = {}

function SpikeTrapGenerator.create(parent)
	local model = Instance.new("Model")
	model.Name = "SpikeTrap"

	-- 1. Деревянная платформа (BaseFrame)
	local baseFrame = Instance.new("Part")
	baseFrame.Name = "BaseFrame"
	baseFrame.Size = Vector3.new(2.3, 0.16, 2.3)
	baseFrame.Position = Vector3.new(0, 0.08, 0)
	baseFrame.Material = Enum.Material.Wood
	baseFrame.Color = Color3.fromRGB(140, 69, 26) -- Cedar
	baseFrame.Anchored = false
	baseFrame.CanCollide = false
	baseFrame.Parent = model
	model.PrimaryPart = baseFrame

	-- 2. 5 Заостренных шипов
	local spikes = {}
	local spikeDefs = {
		{ Pos = Vector3.new(0, 0.75, 0), Rot = Vector3.new(0, 0, 0), H = 1.4 },
		{ Pos = Vector3.new(-0.55, 0.60, -0.55), Rot = Vector3.new(-25, 0, 25), H = 1.2 },
		{ Pos = Vector3.new(0.55, 0.60, -0.55), Rot = Vector3.new(-25, 0, -25), H = 1.2 },
		{ Pos = Vector3.new(-0.55, 0.60, 0.55), Rot = Vector3.new(25, 0, 25), H = 1.2 },
		{ Pos = Vector3.new(0.55, 0.60, 0.55), Rot = Vector3.new(25, 0, -25), H = 1.2 },
	}

	for i, sDef in ipairs(spikeDefs) do
		local sp = Instance.new("Part")
		sp.Name = "Spike_" .. i
		sp.Size = Vector3.new(0.22, sDef.H, 0.22)
		sp.CFrame = CFrame.new(sDef.Pos) * CFrame.Angles(math.rad(sDef.Rot.X), math.rad(sDef.Rot.Y), math.rad(sDef.Rot.Z))
		sp.Material = Enum.Material.Wood
		sp.Color = Color3.fromRGB(198, 139, 89) -- Honey Oak
		sp.Anchored = false
		sp.CanCollide = false
		sp.Parent = model
		table.insert(spikes, sp)
	end

	-- Сварка
	for _, sp in ipairs(spikes) do
		local weld = Instance.new("WeldConstraint")
		weld.Part0 = baseFrame
		weld.Part1 = sp
		weld.Parent = sp
	end

	if parent then
		model.Parent = parent
	end
	return model
end

return SpikeTrapGenerator
