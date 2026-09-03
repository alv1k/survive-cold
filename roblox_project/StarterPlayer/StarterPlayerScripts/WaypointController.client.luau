--[[
    WaypointController.client.luau
    Клиентская система 3D навигационных меток (Waypoints & Beacons):
    - 🏡 Дом игрока: Парящая иконка с АВАТАРКОЙ игрока и дистанцией [🏡 Ваш Дом]
    - 🥫 Продуктовая Лавка: Иконка [🥫 Продукты & Бесплатный Паёк]
    - 🧥 Магазин Одежды: Иконка [🧥 Меховая Одежда]
    - 🗿 Древний Алтарь: Иконка [🗿 Древний Алтарь Реликвий]
    - 🛖 8 Охотничьих Заимок: Иконки [🛖 Заимка · 🔥 Печь]
    - Всегда поверх геометрии (AlwaysOnTop) с динамическим расчетом дистанции в метрах
--]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local IconConfig = require(ReplicatedStorage:WaitForChild("IconConfig", 10))

local player = Players.LocalPlayer
local camera = workspace.CurrentCamera

-- Позиции ключевых объектов (50м и 70м от дома)
local LOCATIONS = {
	PlayerHouse = {
		Name = "Дом",
		Pos = Vector3.new(0, 14, 0),
		Color = Color3.fromRGB(56, 189, 248),
		BgColor = Color3.fromRGB(15, 23, 42),
		MaxDist = 3500,
		IsPlayerHouse = true
	},
	FoodShop = {
		Name = "Лавка",
		Pos = Vector3.new(-50, 12, 0),
		Color = Color3.fromRGB(250, 204, 21),
		BgColor = Color3.fromRGB(15, 23, 42),
		IconKey = "Soup",
		MaxDist = 3000
	},
	ClothingShop = {
		Name = "Одежда",
		Pos = Vector3.new(70, 12, 0),
		Color = Color3.fromRGB(168, 85, 247),
		BgColor = Color3.fromRGB(15, 23, 42),
		IconKey = "Clothing_4",
		MaxDist = 3000
	}
}

local activeWaypoints = {}

local function createWaypoint(key, cfg)
	local anchor = Instance.new("Part")
	anchor.Name = "WaypointAnchor_" .. key
	anchor.Size = Vector3.new(1, 1, 1)
	anchor.Position = cfg.Pos
	anchor.Anchored = true
	anchor.CanCollide = false
	anchor.Transparency = 1
	anchor.Parent = workspace.Terrain

	local bb = Instance.new("BillboardGui")
	bb.Name = "WaypointGui"
	bb.Size = UDim2.new(0, 56, 0, 72)
	bb.StudsOffset = Vector3.new(0, 2.5, 0)
	bb.AlwaysOnTop = true
	bb.MaxDistance = cfg.MaxDist or 3000
	bb.Parent = anchor

	-- Круглая плашка иконки (Минимализм)
	local iconContainer = Instance.new("Frame")
	iconContainer.Name = "IconContainer"
	iconContainer.Size = UDim2.new(0, 48, 0, 48)
	iconContainer.Position = UDim2.new(0.5, 0, 0, 0)
	iconContainer.AnchorPoint = Vector2.new(0.5, 0)
	iconContainer.BackgroundColor3 = cfg.BgColor or Color3.fromRGB(15, 23, 42)
	iconContainer.BackgroundTransparency = 0.1
	iconContainer.BorderSizePixel = 0
	iconContainer.Parent = bb
	Instance.new("UICorner", iconContainer).CornerRadius = UDim.new(1, 0)

	local stroke = Instance.new("UIStroke", iconContainer)
	stroke.Color = cfg.Color or Color3.fromRGB(56, 189, 248)
	stroke.Thickness = 2.0

	-- Аватарка игрока (для дома) или графическая иконка
	if cfg.IsPlayerHouse then
		local avatarImg = Instance.new("ImageLabel")
		avatarImg.Name = "Avatar"
		avatarImg.Size = UDim2.new(1, -6, 1, -6)
		avatarImg.Position = UDim2.new(0.5, 0, 0.5, 0)
		avatarImg.AnchorPoint = Vector2.new(0.5, 0.5)
		avatarImg.BackgroundColor3 = Color3.fromRGB(30, 41, 59)
		avatarImg.BackgroundTransparency = 1
		avatarImg.BorderSizePixel = 0
		avatarImg.Parent = iconContainer
		Instance.new("UICorner", avatarImg).CornerRadius = UDim.new(1, 0)

		task.spawn(function()
			local content, isReady = Players:GetUserThumbnailAsync(player.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size100x100)
			if avatarImg and avatarImg.Parent then
				avatarImg.Image = content
			end
		end)
	elseif cfg.IconKey then
		local _, img = IconConfig.CreateIconBadge(iconContainer, cfg.IconKey, UDim2.new(1, 0, 1, 0), 1)
		img.Size = UDim2.new(1, -12, 1, -12)
	else
		local iconLbl = Instance.new("TextLabel")
		iconLbl.Name = "Icon"
		iconLbl.Size = UDim2.new(1, 0, 1, 0)
		iconLbl.BackgroundTransparency = 1
		iconLbl.Font = Enum.Font.MontserratBlack
		iconLbl.TextSize = 22
		iconLbl.Text = cfg.Icon or "📍"
		iconLbl.Parent = iconContainer
	end

	-- Минималистичная метка дистанции снизу
	local distLbl = Instance.new("TextLabel")
	distLbl.Name = "Distance"
	distLbl.Size = UDim2.new(1, 40, 0, 18)
	distLbl.Position = UDim2.new(0.5, 0, 0, 52)
	distLbl.AnchorPoint = Vector2.new(0.5, 0)
	distLbl.BackgroundColor3 = Color3.fromRGB(15, 23, 42)
	distLbl.BackgroundTransparency = 0.35
	distLbl.Font = Enum.Font.MontserratBold
	distLbl.TextSize = 11.5
	distLbl.TextColor3 = cfg.Color or Color3.fromRGB(241, 245, 249)
	distLbl.Text = "0m"
	distLbl.Parent = bb
	Instance.new("UICorner", distLbl).CornerRadius = UDim.new(0, 6)

	table.insert(activeWaypoints, {
		Pos = cfg.Pos,
		DistLabel = distLbl,
		Container = iconContainer,
		MaxDist = cfg.MaxDist or 3000
	})
end


-- Инициализация основных меток
for key, cfg in pairs(LOCATIONS) do
	createWaypoint(key, cfg)
end

-- Подключение меток 8 Охотничьих Заимок
task.spawn(function()
	local hunterCabins = workspace:WaitForChild("HunterCabins", 15)
	if hunterCabins then
		for _, cabin in ipairs(hunterCabins:GetChildren()) do
			local floor = cabin:FindFirstChild("Floor")
			if floor then
				createWaypoint(cabin.Name, {
					Name = "🛖 " .. cabin.Name,
					Pos = floor.Position + Vector3.new(0, 14, 0),
					Color = Color3.fromRGB(249, 115, 22),
					BgColor = Color3.fromRGB(45, 20, 5),
					Icon = "🛖",
					MaxDist = 1800
				})
			end
		end
	end
end)

-- Обновление дистанции в каждом кадре
RunService.RenderStepped:Connect(function()
	local char = player.Character
	local hrp = char and char:FindFirstChild("HumanoidRootPart")
	if not hrp then return end

	local pPos = hrp.Position

	for _, wp in ipairs(activeWaypoints) do
		local dist = (wp.Pos - pPos).Magnitude
		local meters = math.floor(dist)

		if dist < wp.MaxDist then
			wp.DistLabel.Text = string.format("%d м", meters)
			wp.DistLabel.Visible = true
			wp.Container.Visible = true
		else
			wp.DistLabel.Visible = false
			wp.Container.Visible = false
		end
	end
end)

print("🧭 [WaypointController] 3D Навигационные метки активны: Дом с аватаркой, Магазины и Заимки!")
