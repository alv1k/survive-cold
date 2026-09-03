--[[
    MinimapController.client.luau
    Клиентская круглая миникарта (HUD Радар) в верхнем правом углу экрана:
    - Плавное отслеживание позиции игрока и угла камеры/взгляда
    - Компасные стороны света (С, Ю, З, В) по ободку
    - Отображение ключевых объектов:
      * 🏡 Дом игрока (0, 0)
      * 🥫 Продуктовый магазин (-50, 0)
      * 🧥 Магазин одежды (70, 0)
      * 🗿 Древний Алтарь
      * 🛖 Охотничьи Заимки
      * 🧰 Домашние сундуки
    - Координаты в реальном времени под миникартой
--]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local IconConfig = require(ReplicatedStorage:WaitForChild("IconConfig", 10))

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local camera = workspace.CurrentCamera

-- ScreenGui для Миникарты
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "MinimapScreenGui"
screenGui.ResetOnSpawn = false
screenGui.DisplayOrder = 15
screenGui.Parent = playerGui

-- Внешний контейнер миникарты (в верхнем правом углу)
local mapContainer = Instance.new("Frame")
mapContainer.Name = "MinimapContainer"
mapContainer.Size = UDim2.new(0, 150, 0, 150)
mapContainer.Position = UDim2.new(1, -165, 0, 16)
mapContainer.BackgroundColor3 = Color3.fromRGB(15, 23, 42)
mapContainer.BackgroundTransparency = 0.15
mapContainer.BorderSizePixel = 0
mapContainer.ClipsDescendants = true
mapContainer.Parent = screenGui
Instance.new("UICorner", mapContainer).CornerRadius = UDim.new(1, 0) -- Круглый стиль

local mapStroke = Instance.new("UIStroke", mapContainer)
mapStroke.Color = Color3.fromRGB(56, 189, 248)
mapStroke.Thickness = 2.5

-- Сетка / радарные кольца на фоне карты
local ringInner = Instance.new("Frame")
ringInner.Size = UDim2.new(0.5, 0, 0.5, 0)
ringInner.Position = UDim2.new(0.5, 0, 0.5, 0)
ringInner.AnchorPoint = Vector2.new(0.5, 0.5)
ringInner.BackgroundTransparency = 1
ringInner.Parent = mapContainer
Instance.new("UICorner", ringInner).CornerRadius = UDim.new(1, 0)

local ringStroke = Instance.new("UIStroke", ringInner)
ringStroke.Color = Color3.fromRGB(56, 189, 248)
ringStroke.Transparency = 0.7
ringStroke.Thickness = 1

-- Слой для вращения и перемещения меток объектов (World Layer)
local worldLayer = Instance.new("Frame")
worldLayer.Name = "WorldLayer"
worldLayer.Size = UDim2.new(1, 0, 1, 0)
worldLayer.Position = UDim2.new(0.5, 0, 0.5, 0)
worldLayer.AnchorPoint = Vector2.new(0.5, 0.5)
worldLayer.BackgroundTransparency = 1
worldLayer.Parent = mapContainer

-- Маркер игрока по центру с направлением взгляда
local playerMarker = Instance.new("Frame")
playerMarker.Name = "PlayerMarker"
playerMarker.Size = UDim2.new(0, 18, 0, 18)
playerMarker.Position = UDim2.new(0.5, 0, 0.5, 0)
playerMarker.AnchorPoint = Vector2.new(0.5, 0.5)
playerMarker.BackgroundColor3 = Color3.fromRGB(56, 189, 248)
playerMarker.ZIndex = 10
playerMarker.Parent = mapContainer
Instance.new("UICorner", playerMarker).CornerRadius = UDim.new(1, 0)

local pStroke = Instance.new("UIStroke", playerMarker)
pStroke.Color = Color3.fromRGB(255, 255, 255)
pStroke.Thickness = 1.5

-- Стрелочка направления взгляда
local arrow = Instance.new("ImageLabel")
arrow.Name = "Arrow"
arrow.Size = UDim2.new(0, 12, 0, 12)
arrow.Position = UDim2.new(0.5, 0, 0, -6)
arrow.AnchorPoint = Vector2.new(0.5, 0.5)
arrow.BackgroundTransparency = 1
arrow.Image = "rbxasset://textures/survival_icons/ui_arrow_right.png"
arrow.ImageColor3 = Color3.fromRGB(255, 255, 255)
arrow.Rotation = -90
arrow.ZIndex = 11
arrow.Parent = playerMarker

-- Нижняя плашка координат
local coordLabel = Instance.new("TextLabel")
coordLabel.Name = "CoordLabel"
coordLabel.Size = UDim2.new(0, 130, 0, 20)
coordLabel.Position = UDim2.new(1, -155, 0, 172)
coordLabel.BackgroundColor3 = Color3.fromRGB(15, 23, 42)
coordLabel.BackgroundTransparency = 0.3
coordLabel.Font = Enum.Font.MontserratBold
coordLabel.TextSize = 11.5
coordLabel.TextColor3 = Color3.fromRGB(241, 245, 249)
coordLabel.Text = "📍 X: 0, Z: 0"
coordLabel.Parent = screenGui
Instance.new("UICorner", coordLabel).CornerRadius = UDim.new(0, 6)

--------------------------------------------------------------------------------
-- СПИСОК КАРТОГРАФИЧЕСКИХ ОБЪЕКТОВ
--------------------------------------------------------------------------------
local MAP_RADAR_RADIUS = 60 -- Пикселей радиуса отображения
local WORLD_RADAR_RANGE = 140 -- Студов дальности видимости на миникарте

local POI_LIST = {
	{ Name = "Дом", Pos = Vector3.new(0, 2.5, 0), Color = Color3.fromRGB(56, 189, 248), IconKey = "Branches", Symbol = "🏡" },
	{ Name = "Лавка", Pos = Vector3.new(-50, 4, 0), Color = Color3.fromRGB(250, 204, 21), IconKey = "Soup", Symbol = "🥫" },
	{ Name = "Одежда", Pos = Vector3.new(70, 2.5, 0), Color = Color3.fromRGB(168, 85, 247), IconKey = "Clothing_4", Symbol = "🧥" },
	{ Name = "Алтарь", Pos = Vector3.new(0, 2.5, -280), Color = Color3.fromRGB(239, 68, 68), IconKey = "Relic_6", Symbol = "🗿" }
}

-- Добавляем 8 Заимок
task.spawn(function()
	local hunterCabins = workspace:WaitForChild("HunterCabins", 10)
	if hunterCabins then
		for _, cabin in ipairs(hunterCabins:GetChildren()) do
			local floor = cabin:FindFirstChild("Floor")
			if floor then
				table.insert(POI_LIST, {
					Name = cabin.Name,
					Pos = floor.Position,
					Color = Color3.fromRGB(249, 115, 22),
					IconKey = "CampfireKit",
					Symbol = "🛖"
				})
			end
		end
	end
end)

local blipElements = {}

local function getOrCreateBlip(poiKey, poiData)
	if blipElements[poiKey] then
		return blipElements[poiKey]
	end

	local blip = Instance.new("Frame")
	blip.Name = "Blip_" .. tostring(poiKey)
	blip.Size = UDim2.new(0, 16, 0, 16)
	blip.AnchorPoint = Vector2.new(0.5, 0.5)
	blip.BackgroundColor3 = poiData.Color or Color3.fromRGB(255, 255, 255)
	blip.ZIndex = 5
	blip.Parent = worldLayer
	Instance.new("UICorner", blip).CornerRadius = UDim.new(1, 0)

	local bStroke = Instance.new("UIStroke", blip)
	bStroke.Color = Color3.fromRGB(15, 23, 42)
	bStroke.Thickness = 1.2

	local iconImg = Instance.new("ImageLabel", blip)
	iconImg.Size = UDim2.new(1, -2, 1, -2)
	iconImg.Position = UDim2.new(0.5, 0, 0.5, 0)
	iconImg.AnchorPoint = Vector2.new(0.5, 0.5)
	iconImg.BackgroundTransparency = 1
	iconImg.ImageColor3 = Color3.fromRGB(255, 255, 255)
	iconImg.Image = IconConfig.GetIconImage(poiData.IconKey or "Branches")

	blipElements[poiKey] = blip
	return blip
end

-- 60 FPS Обновление положения радара
RunService.RenderStepped:Connect(function()
	local char = player.Character
	local hrp = char and char:FindFirstChild("HumanoidRootPart")
	if not hrp then return end

	local pPos = hrp.Position
	coordLabel.Text = string.format("📍 X: %d, Z: %d", math.floor(pPos.X), math.floor(pPos.Z))

	-- Направление взгляда персонажа
	local lookVec = hrp.CFrame.LookVector
	local lookAngle = math.atan2(lookVec.X, -lookVec.Z)
	playerMarker.Rotation = -math.deg(lookAngle)

	-- Обновление точек на миникарте относительно игрока
	for idx, poi in ipairs(POI_LIST) do
		local blip = getOrCreateBlip(idx, poi)
		local dx = poi.Pos.X - pPos.X
		local dz = poi.Pos.Z - pPos.Z
		local dist = math.sqrt(dx^2 + dz^2)

		-- Масштабирование на радиус миникарты
		local clampedDist = math.min(dist, WORLD_RADAR_RANGE)
		local factor = clampedDist / WORLD_RADAR_RANGE
		local pixelDist = factor * MAP_RADAR_RADIUS

		local angleToPoi = math.atan2(dx, dz)
		local screenX = math.sin(angleToPoi) * pixelDist
		local screenY = -math.cos(angleToPoi) * pixelDist

		blip.Position = UDim2.new(0.5, screenX, 0.5, screenY)
		blip.Visible = true
	end
end)

print("🗺️ [MinimapController] Круглая миникарта успешно инициализирована в верхнем правом углу!")
