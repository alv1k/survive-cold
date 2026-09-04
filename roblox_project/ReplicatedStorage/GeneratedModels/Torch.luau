--[[
    ReplicatedStorage/GeneratedModels/Torch.luau
    Автоматически генерируемая 3D-модель походного факела (Torch).
--]]

local TorchModel = {}

function TorchModel.create(parent)
	local container = Instance.new("Model")
	container.Name = "Torch"

	local handle = Instance.new("Part")
	handle.Name = "Handle"
	handle.Size = Vector3.new(0.18, 1.8, 0.18)
	handle.CFrame = CFrame.new(0, 0, 0)
	handle.Material = Enum.Material.Wood
	handle.Color = Color3.fromHex("#8C451A") -- wood_cedar
	handle.CanCollide = false
	handle.Massless = true
	handle.Anchored = false
	handle.Parent = container

	local handleMesh = Instance.new("SpecialMesh", handle)
	handleMesh.MeshType = Enum.MeshType.Cylinder

	container.PrimaryPart = handle

	-- Тряпичная промасленная обмотка на верхушке
	local head = Instance.new("Part")
	head.Name = "Head"
	head.Size = Vector3.new(0.32, 0.65, 0.32)
	head.CFrame = CFrame.new(0, 0.85, 0)
	head.Material = Enum.Material.Fabric
	head.Color = Color3.fromHex("#78716C") -- wood_weathered / cloth
	head.CanCollide = false
	head.Massless = true
	head.Anchored = false
	head.Parent = container

	local headMesh = Instance.new("SpecialMesh", head)
	headMesh.MeshType = Enum.MeshType.Cylinder

	-- Металлический хомут под обмоткой
	local clamp = Instance.new("Part")
	clamp.Name = "Clamp"
	clamp.Size = Vector3.new(0.24, 0.12, 0.24)
	clamp.CFrame = CFrame.new(0, 0.50, 0)
	clamp.Material = Enum.Material.Metal
	clamp.Color = Color3.fromHex("#334155") -- iron_band
	clamp.CanCollide = false
	clamp.Massless = true
	clamp.Anchored = false
	clamp.Parent = container

	local clampMesh = Instance.new("SpecialMesh", clamp)
	clampMesh.MeshType = Enum.MeshType.Cylinder

	-- Пламя и свет
	local fire = Instance.new("Fire", head)
	fire.Size = 3.5
	fire.Heat = 10
	fire.Color = Color3.fromRGB(255, 140, 30)
	fire.SecondaryColor = Color3.fromRGB(255, 60, 0)

	local light = Instance.new("PointLight", head)
	light.Color = Color3.fromRGB(255, 160, 50)
	light.Range = 28
	light.Brightness = 2.8
	light.Shadows = true

	-- Сварка
	for _, p in ipairs(container:GetChildren()) do
		if p:IsA("BasePart") and p ~= handle then
			local relCF = handle.CFrame:ToObjectSpace(p.CFrame)
			local weld = Instance.new("Weld")
			weld.Name = "Weld_" .. p.Name
			weld.Part0 = handle
			weld.Part1 = p
			weld.C0 = relCF
			weld.C1 = CFrame.identity
			weld.Parent = handle
		end
	end

	if parent then container.Parent = parent end
	return container
end

return TorchModel
