--[[
    EquipService.server.luau
    Серверная система экипировки предметов в руки персонажа при нажатии 1..9:
    - Факел (с огнем и светом), Оружие, Еда, Ресурсы
    - Аттач к RightHand (R15) или Right Arm (R6)
--]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local RemotesFolder = ReplicatedStorage:FindFirstChild("Remotes") or Instance.new("Folder", ReplicatedStorage)
RemotesFolder.Name = "Remotes"

local EquipItemRemote = RemotesFolder:FindFirstChild("EquipItem") or Instance.new("RemoteEvent", RemotesFolder)
EquipItemRemote.Name = "EquipItem"

-- Конфигурация 3D моделей предметов в руке
local HAND_MODELS = {
	Torch = {
		Size = Vector3.new(0.6, 2.4, 0.6),
		Color = BrickColor.new("Reddish brown"),
		Material = Enum.Material.Wood,
		HasFire = true
	},
	Branches = {
		Size = Vector3.new(0.5, 2.0, 0.5),
		Color = BrickColor.new("Reddish brown"),
		Material = Enum.Material.Wood
	},
	Fiber = {
		Size = Vector3.new(1.2, 1.2, 1.2),
		Color = BrickColor.new("Bright green"),
		Material = Enum.Material.Grass
	},
	Stone = {
		Size = Vector3.new(1.2, 1.2, 1.2),
		Color = BrickColor.new("Medium stone grey"),
		Material = Enum.Material.Slate
	},
	Planks = {
		Size = Vector3.new(0.8, 2.6, 1.2),
		Color = BrickColor.new("Dark orange"),
		Material = Enum.Material.WoodPlanks
	},
	Parts = {
		Size = Vector3.new(0.8, 0.8, 0.8),
		Color = BrickColor.new("Cyan"),
		Material = Enum.Material.Metal
	},
	Bar = {
		Size = Vector3.new(0.6, 1.4, 0.4),
		Color = BrickColor.new("Brown"),
		Material = Enum.Material.Plastic
	},
	Bread = {
		Size = Vector3.new(1.0, 1.2, 0.8),
		Color = BrickColor.new("Brick yellow"),
		Material = Enum.Material.SmoothPlastic
	},
	Soup = {
		Size = Vector3.new(0.9, 1.2, 0.9),
		Color = BrickColor.new("Bright red"),
		Material = Enum.Material.Metal
	},
	Steak = {
		Size = Vector3.new(1.2, 0.6, 1.0),
		Color = BrickColor.new("Dark red"),
		Material = Enum.Material.SmoothPlastic
	},
	Pepper = {
		Size = Vector3.new(0.5, 1.2, 0.5),
		Color = BrickColor.new("Bright red"),
		Material = Enum.Material.SmoothPlastic
	},
	Coffee = {
		Size = Vector3.new(0.8, 1.1, 0.8),
		Color = BrickColor.new("Dark stone grey"),
		Material = Enum.Material.Plastic
	},
	Spear = {
		Size = Vector3.new(0.4, 5.2, 0.4),
		Color = BrickColor.new("Reddish brown"),
		Material = Enum.Material.Wood
	},
	Slingshot = {
		Size = Vector3.new(0.6, 2.0, 1.2),
		Color = BrickColor.new("Dark orange"),
		Material = Enum.Material.Wood
	},
	Revolver = {
		Size = Vector3.new(0.5, 1.4, 2.2),
		Color = BrickColor.new("Black"),
		Material = Enum.Material.Metal
	}
}

local function removeCurrentEquipped(char)
	local existing = char:FindFirstChild("EquippedHandItem")
	if existing then existing:Destroy() end
end

EquipItemRemote.OnServerEvent:Connect(function(player, itemKey)
	local char = player.Character
	if not char or not char:FindFirstChild("HumanoidRootPart") then return end

	removeCurrentEquipped(char)
	player:SetAttribute("EquippedItem", itemKey or "")

	if not itemKey or not HAND_MODELS[itemKey] then return end

	local hand = char:FindFirstChild("RightHand") or char:FindFirstChild("Right Arm")
	if not hand then return end

	local cfg = HAND_MODELS[itemKey]
	local itemPart = Instance.new("Part")
	itemPart.Name = "EquippedHandItem"
	itemPart.Size = cfg.Size
	itemPart.Material = cfg.Material
	itemPart.BrickColor = cfg.Color
	itemPart.CanCollide = false
	itemPart.Massless = true

	local weld = Instance.new("WeldConstraint")
	itemPart.CFrame = hand.CFrame * CFrame.new(0, -0.6, 0)
	weld.Part0 = hand
	weld.Part1 = itemPart
	weld.Parent = itemPart

	if cfg.HasFire then
		local fire = Instance.new("Fire", itemPart)
		fire.Size = 4
		fire.Heat = 10

		local light = Instance.new("PointLight", itemPart)
		light.Color = Color3.fromRGB(255, 160, 50)
		light.Range = 25
		light.Brightness = 2.5
	end

	itemPart.Parent = char
	print(string.format("✋ %s взял в руки: %s", player.Name, itemKey))
end)

Players.PlayerRemoving:Connect(function(player)
	if player.Character then removeCurrentEquipped(player.Character) end
end)
