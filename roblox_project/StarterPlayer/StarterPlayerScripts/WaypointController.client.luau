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

local player = Players.LocalPlayer
local camera = workspace.CurrentCamera

-- Позиции ключевых объектов
local LOCATIONS = {
	PlayerHouse = {
		Name = "🏡 Ваш Дом",
		Pos = Vector3.new(0, 18, 0),
		Color = Color3.fromRGB(56, 189, 248),
		BgColor = Color3.fromRGB(15, 23, 42),
		MaxDist = 3500,
		IsPlayerHouse = true
	},
	FoodShop = {
		Name = "🥫 Продуктовая Лавка",
		Subtitle = "🍫 Бесплатный паёк · Еда",
		Pos = Vector3.new(-380, 18, -450),
		Color = Color3.fromRGB(250, 204, 21),
		BgColor = Color3.fromRGB(66, 32, 6),
		Icon = "🥫",
		MaxDist = 3000
	},
	ClothingShop = {
		Name = "🧥 Магазин Одежды",
		Subtitle = "❄️ Меховые костюмы",
		Pos = Vector3.new(350, 18, -300),
		Color = Color3.fromRGB(168, 85, 247),
		BgColor = Color3.fromRGB(59, 7, 100),
		Icon = "🧥",
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
	bb.Size = UDim2.new(0, 195, 0, 60)
	bb.StudsOffset = Vector3.new(0, 2.2, 0)
	bb.AlwaysOnTop = true
	bb.MaxDistance = cfg.MaxDist or 3000
	bb.Parent = anchor

	local container = Instance.new("Frame")
	container.Name = "Container"
	container.Size = UDim2.new(1, 0, 1, 0)
	container.BackgroundColor3 = cfg.BgColor or Color3.fromRGB(15, 23, 42)
	container.BackgroundTransparency = 0.15
	container.BorderSizePixel = 0
	container.Parent = bb
	Instance.new("UICorner", container).CornerRadius = UDim.new(0, 12)

	local stroke = Instance.new("UIStroke", container)
	stroke.Color = cfg.Color or Color3.fromRGB(56, 189, 248)
	stroke.Thickness = 2

	-- Аватарка игрока (для дома) или текстовая иконка
	if cfg.IsPlayerHouse then
		local avatarImg = Instance.new("ImageLabel")
		avatarImg.Name = "Avatar"
		avatarImg.Size = UDim2.new(0, 42, 0, 42)
		avatarImg.Position = UDim2.new(0, 8, 0.5, 0)
		avatarImg.AnchorPoint = Vector2.new(0, 0.5)
		avatarImg.BackgroundColor3 = Color3.fromRGB(30, 41, 59)
		avatarImg.BorderSizePixel = 0
		avatarImg.Parent = container
		Instance.new("UICorner", avatarImg).CornerRadius = UDim.new(1, 0)

		local avStroke = Instance.new("UIStroke", avatarImg)
		avStroke.Color = Color3.fromRGB(56, 189, 248)
		avStroke.Thickness = 1.5

		task.spawn(function()
			local content, isReady = Players:GetUserThumbnailAsync(player.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size100x100)
			if avatarImg and avatarImg.Parent then
				avatarImg.Image = content
			end
		end)
	else
		local iconLbl = Instance.new("TextLabel")
		iconLbl.Name = "Icon"
		iconLbl.Size = UDim2.new(0, 42, 0, 42)
		iconLbl.Position = UDim2.new(0, 8, 0.5, 0)
		iconLbl.AnchorPoint = Vector2.new(0, 0.5)
		iconLbl.BackgroundTransparency = 1
		iconLbl.Font = Enum.Font.MontserratBlack
		iconLbl.TextSize = 24
		iconLbl.Text = cfg.Icon or "📍"
		iconLbl.Parent = container
	end

	-- Название
	local titleLbl = Instance.new("TextLabel")
	titleLbl.Name = "Title"
	titleLbl.Size = UDim2.new(1, -58, 0, 22)
	titleLbl.Position = UDim2.new(0, 54, 0, 8)
	titleLbl.BackgroundTransparency = 1
	titleLbl.Font = Enum.Font.MontserratBlack
	titleLbl.TextSize = 14
	titleLbl.TextColor3 = Color3.fromRGB(255, 255, 255)
	titleLbl.TextXAlignment = Enum.TextXAlignment.Left
	titleLbl.Text = cfg.Name
	titleLbl.Parent = container

	-- Дистанция
	local distLbl = Instance.new("TextLabel")
	distLbl.Name = "Distance"
	distLbl.Size = UDim2.new(1, -58, 0, 20)
	distLbl.Position = UDim2.new(0, 54, 0, 30)
	distLbl.BackgroundTransparency = 1
	distLbl.Font = Enum.Font.MontserratBold
	distLbl.TextSize = 12.5
	distLbl.TextColor3 = cfg.Color or Color3.fromRGB(56, 189, 248)
	distLbl.TextXAlignment = Enum.TextXAlignment.Left
	distLbl.Text = "[ 0m ]"
	distLbl.Parent = container

	table.insert(activeWaypoints, {
		Pos = cfg.Pos,
		DistLabel = distLbl,
		Container = container,
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
		local meters = math.floor(dist / 3.57) -- 1 stud ~ 0.28m

		if dist < wp.MaxDist then
			wp.DistLabel.Text = string.format("📍 %d м", meters)
			wp.Container.Visible = true
		else
			wp.Container.Visible = false
		end
	end
end)

print("🧭 [WaypointController] 3D Навигационные метки активны: Дом с аватаркой, Магазины и Заимки!")
