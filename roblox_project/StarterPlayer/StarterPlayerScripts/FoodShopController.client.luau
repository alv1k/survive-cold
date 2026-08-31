--[[
    FoodShopController.client.luau
    Клиентский интерфейс Продуктовой Лавки с чистой ИКОНОЧНОЙ версткой:
    - Цены и баффы в иконках: 🌿 2, 🍗 +50 🔥 +15 ❤️ +25
--]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ProximityPromptService = game:GetService("ProximityPromptService")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local RemotesFolder = ReplicatedStorage:WaitForChild("Remotes", 10)
local BuyFoodRemote = RemotesFolder and RemotesFolder:WaitForChild("BuyFood", 10)
local ShowNotificationRemote = RemotesFolder and RemotesFolder:WaitForChild("ShowNotification", 10)

local FOOD_ITEMS = {
	{ Key = "Bar", Name = "🍫 Батончик", CostText = "🎉 0 [Лимит: 3/час]", Warmth = 10, Hunger = 30, Health = 15 },
	{ Key = "Bread", Name = "🍞 Хлеб", CostText = "🌿 2", Warmth = 15, Hunger = 50, Health = 25 },
	{ Key = "Chips", Name = "🥔 Чипсы", CostText = "🌱 2", Warmth = 8, Hunger = 25, Health = 15 },
	{ Key = "Soup", Name = "🥫 Суп", CostText = "🌿 3  🌱 2", Warmth = 30, Hunger = 70, Health = 35 },
	{ Key = "Pepper", Name = "🌶️ Перец", CostText = "⚪ 2  🌿 2", Warmth = 50, Hunger = 15, Health = 5 },
	{ Key = "Coffee", Name = "☕ Кофе", CostText = "🌿 3  🌱 2", Warmth = 40, Hunger = 20, Health = 20 },
	{ Key = "Steak", Name = "🥩 Стейк", CostText = "🌲 1  🌿 2", Warmth = 35, Hunger = 90, Health = 60 }
}

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "FoodShopGui"
screenGui.ResetOnSpawn = false
screenGui.Parent = playerGui

local mainFrame = Instance.new("Frame")
mainFrame.Name = "MainFrame"
mainFrame.Size = UDim2.new(0, 680, 0, 460)
mainFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
mainFrame.AnchorPoint = Vector2.new(0.5, 0.5)
mainFrame.BackgroundColor3 = Color3.fromRGB(15, 23, 42)
mainFrame.BackgroundTransparency = 0.05
mainFrame.BorderSizePixel = 0
mainFrame.Visible = false
mainFrame.Parent = screenGui
Instance.new("UICorner", mainFrame).CornerRadius = UDim.new(0, 16)

local stroke = Instance.new("UIStroke", mainFrame)
stroke.Color = Color3.fromRGB(234, 179, 8)
stroke.Thickness = 2

local header = Instance.new("Frame")
header.Size = UDim2.new(1, 0, 0, 50)
header.BackgroundColor3 = Color3.fromRGB(113, 63, 18)
header.BackgroundTransparency = 0.4
header.BorderSizePixel = 0
header.Parent = mainFrame
Instance.new("UICorner", header).CornerRadius = UDim.new(0, 16)

local titleLabel = Instance.new("TextLabel")
titleLabel.Size = UDim2.new(1, -60, 1, 0)
titleLabel.Position = UDim2.new(0, 20, 0, 0)
titleLabel.BackgroundTransparency = 1
titleLabel.Font = Enum.Font.GothamBlack
titleLabel.TextSize = 16
titleLabel.TextColor3 = Color3.fromRGB(250, 204, 21)
titleLabel.TextXAlignment = Enum.TextXAlignment.Left
titleLabel.Text = "🥫 ПРОДУКТОВАЯ ЛАВКА"
titleLabel.Parent = header

local closeBtn = Instance.new("TextButton")
closeBtn.Size = UDim2.new(0, 34, 0, 34)
closeBtn.Position = UDim2.new(1, -42, 0.5, 0)
closeBtn.AnchorPoint = Vector2.new(0, 0.5)
closeBtn.BackgroundColor3 = Color3.fromRGB(220, 38, 38)
closeBtn.Font = Enum.Font.GothamBold
closeBtn.TextSize = 17
closeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
closeBtn.Text = "✕"
closeBtn.Parent = header
Instance.new("UICorner", closeBtn).CornerRadius = UDim.new(0, 10)

local scroll = Instance.new("ScrollingFrame")
scroll.Size = UDim2.new(1, -36, 1, -68)
scroll.Position = UDim2.new(0, 18, 0, 58)
scroll.BackgroundColor3 = Color3.fromRGB(30, 41, 59)
scroll.BackgroundTransparency = 0.5
scroll.BorderSizePixel = 0
scroll.ScrollBarThickness = 6
scroll.ScrollBarImageColor3 = Color3.fromRGB(234, 179, 8)
scroll.Parent = mainFrame
Instance.new("UICorner", scroll).CornerRadius = UDim.new(0, 12)

local layout = Instance.new("UIGridLayout", scroll)
layout.CellSize = UDim2.new(0, 305, 0, 88)
layout.CellPadding = UDim2.new(0, 10, 0, 10)

local function renderFoodItems()
	for _, child in ipairs(scroll:GetChildren()) do
		if child:IsA("Frame") then child:Destroy() end
	end

	for _, item in ipairs(FOOD_ITEMS) do
		local card = Instance.new("Frame")
		card.Name = "Food_" .. item.Key
		card.BackgroundColor3 = Color3.fromRGB(15, 23, 42)
		card.BackgroundTransparency = 0.3
		card.BorderSizePixel = 0
		card.Parent = scroll
		Instance.new("UICorner", card).CornerRadius = UDim.new(0, 10)

		local cardStroke = Instance.new("UIStroke", card)
		cardStroke.Color = Color3.fromRGB(71, 85, 105)
		cardStroke.Thickness = 1.2

		local nameLbl = Instance.new("TextLabel")
		nameLbl.Size = UDim2.new(1, -95, 0, 20)
		nameLbl.Position = UDim2.new(0, 10, 0, 6)
		nameLbl.BackgroundTransparency = 1
		nameLbl.Font = Enum.Font.GothamBold
		nameLbl.TextSize = 12.5
		nameLbl.TextColor3 = Color3.fromRGB(255, 255, 255)
		nameLbl.TextXAlignment = Enum.TextXAlignment.Left
		nameLbl.Text = item.Name
		nameLbl.Parent = card

		local statsLbl = Instance.new("TextLabel")
		statsLbl.Size = UDim2.new(1, -95, 0, 18)
		statsLbl.Position = UDim2.new(0, 10, 0, 26)
		statsLbl.BackgroundTransparency = 1
		statsLbl.Font = Enum.Font.GothamBold
		statsLbl.TextSize = 11.5
		statsLbl.TextColor3 = Color3.fromRGB(74, 222, 128)
		statsLbl.TextXAlignment = Enum.TextXAlignment.Left
		statsLbl.Text = string.format("🍗 +%d   🔥 +%d   ❤️ +%d", item.Hunger, item.Warmth, item.Health)
		statsLbl.Parent = card

		local costLbl = Instance.new("TextLabel")
		costLbl.Size = UDim2.new(1, -95, 0, 18)
		costLbl.Position = UDim2.new(0, 10, 0, 48)
		costLbl.BackgroundTransparency = 1
		costLbl.Font = Enum.Font.GothamBold
		costLbl.TextSize = 12
		costLbl.TextColor3 = Color3.fromRGB(250, 204, 21)
		costLbl.TextXAlignment = Enum.TextXAlignment.Left
		costLbl.Text = item.CostText
		costLbl.Parent = card

		local buyBtn = Instance.new("TextButton")
		buyBtn.Size = UDim2.new(0, 80, 0, 32)
		buyBtn.Position = UDim2.new(1, -90, 0.5, 0)
		buyBtn.AnchorPoint = Vector2.new(0, 0.5)
		buyBtn.BackgroundColor3 = Color3.fromRGB(202, 138, 4)
		buyBtn.Font = Enum.Font.GothamBold
		buyBtn.TextSize = 11.5
		buyBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
		buyBtn.Text = "🛒 Купить"
		buyBtn.Parent = card
		Instance.new("UICorner", buyBtn).CornerRadius = UDim.new(0, 8)

		buyBtn.MouseButton1Click:Connect(function()
			if BuyFoodRemote then
				local res = BuyFoodRemote:InvokeServer(item.Key)
				if res and res.Success then
					buyBtn.Text = "✅"
					buyBtn.BackgroundColor3 = Color3.fromRGB(22, 163, 74)
					task.delay(1.0, function()
						if buyBtn and buyBtn.Parent then
							buyBtn.Text = "🛒 Купить"
							buyBtn.BackgroundColor3 = Color3.fromRGB(202, 138, 4)
						end
					end)
				else
					if ShowNotificationRemote and res and res.Message then
						ShowNotificationRemote:FireServer(res.Message)
					end
				end
			end
		end)
	end

	local count = #FOOD_ITEMS
	local rows = math.ceil(count / 2)
	scroll.CanvasSize = UDim2.new(0, 0, 0, rows * 98 + 16)
end

local function openShop()
	renderFoodItems()
	mainFrame.Visible = true
end

local function closeShop()
	mainFrame.Visible = false
end

closeBtn.MouseButton1Click:Connect(closeShop)

ProximityPromptService.PromptTriggered:Connect(function(prompt, triggeringPlayer)
	if triggeringPlayer == player then
		if prompt.ObjectText == "🥫 Лавка Еды" or (prompt.Parent and prompt.Parent.Name == "FoodCounter") then
			openShop()
		end
	end
end)

UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then return end
	if input.KeyCode == Enum.KeyCode.Escape and mainFrame.Visible then
		closeShop()
	end
end)
