--[[
    FoodShopController.client.luau
    Клиентский интерфейс Продуктовой Лавки с чистой ИКОНОЧНОЙ версткой:
    - Цены и баффы в иконках: 🌿 2, 🍗 +50 🔥 +15 ❤️ +25
    - Автоматическое отключение (disabled) кнопок при нехватке ресурсов или исчерпании лимита
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
	{ Key = "Bar", Name = "🍫 Батончик", Cost = {}, CostText = "🎉 БЕСПЛАТНО", Warmth = 50, Hunger = 60, Health = 25 },
	{ Key = "Bread", Name = "🍞 Хлеб", Cost = {}, CostText = "🎉 БЕСПЛАТНО", Warmth = 50, Hunger = 60, Health = 25 },
	{ Key = "Chips", Name = "🥔 Чипсы", Cost = {}, CostText = "🎉 БЕСПЛАТНО", Warmth = 50, Hunger = 60, Health = 25 },
	{ Key = "Soup", Name = "🥫 Суп", Cost = {}, CostText = "🎉 БЕСПЛАТНО", Warmth = 50, Hunger = 60, Health = 25 },
	{ Key = "Pepper", Name = "🌶️ Перец", Cost = {}, CostText = "🎉 БЕСПЛАТНО", Warmth = 50, Hunger = 60, Health = 25 },
	{ Key = "Coffee", Name = "☕ Кофе", Cost = {}, CostText = "🎉 БЕСПЛАТНО", Warmth = 50, Hunger = 60, Health = 25 },
	{ Key = "Steak", Name = "🥩 Стейк", Cost = {}, CostText = "🎉 БЕСПЛАТНО", Warmth = 50, Hunger = 60, Health = 25 }
}

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "FoodShopGui"
screenGui.ResetOnSpawn = false
screenGui.DisplayOrder = 90
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
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
		-- Проверка доступности товара
		local isAvailable = true
		local disabledReason = ""

		if item.IsFreeBar then
			local claimed = player:GetAttribute("FreeBarsClaimed") or 0
			local resetTime = player:GetAttribute("FreeBarResetTime") or 0
			local now = os.time()
			if claimed >= 3 and (resetTime == 0 or now < resetTime) then
				isAvailable = false
				disabledReason = "Лимит (0/3)"
			end
		else
			for resKey, amt in pairs(item.Cost or {}) do
				local cur = player:GetAttribute(resKey) or 0
				if cur < amt then
					isAvailable = false
					disabledReason = "Мало ресурсов"
					break
				end
			end
		end

		local card = Instance.new("Frame")
		card.Name = "Food_" .. item.Key
		card.BackgroundColor3 = isAvailable and Color3.fromRGB(15, 23, 42) or Color3.fromRGB(11, 17, 32)
		card.BackgroundTransparency = 0.3
		card.BorderSizePixel = 0
		card.Parent = scroll
		Instance.new("UICorner", card).CornerRadius = UDim.new(0, 10)

		local cardStroke = Instance.new("UIStroke", card)
		cardStroke.Color = isAvailable and Color3.fromRGB(71, 85, 105) or Color3.fromRGB(51, 65, 85)
		cardStroke.Thickness = 1.2

		local nameLbl = Instance.new("TextLabel")
		nameLbl.Size = UDim2.new(1, -105, 0, 20)
		nameLbl.Position = UDim2.new(0, 10, 0, 6)
		nameLbl.BackgroundTransparency = 1
		nameLbl.Font = Enum.Font.GothamBold
		nameLbl.TextSize = 12.5
		nameLbl.TextColor3 = isAvailable and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(148, 163, 184)
		nameLbl.TextXAlignment = Enum.TextXAlignment.Left
		nameLbl.Text = item.Name
		nameLbl.Parent = card

		local statsLbl = Instance.new("TextLabel")
		statsLbl.Size = UDim2.new(1, -105, 0, 18)
		statsLbl.Position = UDim2.new(0, 10, 0, 26)
		statsLbl.BackgroundTransparency = 1
		statsLbl.Font = Enum.Font.GothamBold
		statsLbl.TextSize = 11.5
		statsLbl.TextColor3 = isAvailable and Color3.fromRGB(74, 222, 128) or Color3.fromRGB(100, 116, 139)
		statsLbl.TextXAlignment = Enum.TextXAlignment.Left
		statsLbl.Text = string.format("🍗 +%d   🔥 +%d   ❤️ +%d", item.Hunger, item.Warmth, item.Health)
		statsLbl.Parent = card

		local costLbl = Instance.new("TextLabel")
		costLbl.Size = UDim2.new(1, -105, 0, 18)
		costLbl.Position = UDim2.new(0, 10, 0, 48)
		costLbl.BackgroundTransparency = 1
		costLbl.Font = Enum.Font.GothamBold
		costLbl.TextSize = 12
		costLbl.TextColor3 = isAvailable and Color3.fromRGB(250, 204, 21) or Color3.fromRGB(148, 163, 184)
		costLbl.TextXAlignment = Enum.TextXAlignment.Left
		costLbl.Text = item.CostText
		costLbl.Parent = card

		local buyBtn = Instance.new("TextButton")
		buyBtn.Size = UDim2.new(0, 95, 0, 32)
		buyBtn.Position = UDim2.new(1, -102, 0.5, 0)
		buyBtn.AnchorPoint = Vector2.new(0, 0.5)
		buyBtn.Font = Enum.Font.GothamBold
		buyBtn.TextSize = 11
		buyBtn.Parent = card
		Instance.new("UICorner", buyBtn).CornerRadius = UDim.new(0, 8)

		if isAvailable then
			buyBtn.Active = true
			buyBtn.AutoButtonColor = true
			buyBtn.BackgroundColor3 = item.IsFreeBar and Color3.fromRGB(22, 163, 74) or Color3.fromRGB(202, 138, 4)
			buyBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
			buyBtn.Text = item.IsFreeBar and "🎁 Забрать" or "🛒 Купить"

			buyBtn.MouseButton1Click:Connect(function()
				if BuyFoodRemote then
					local res = BuyFoodRemote:InvokeServer(item.Key)
					if res and res.Success then
						buyBtn.Text = "✅ Готово"
						buyBtn.BackgroundColor3 = Color3.fromRGB(22, 163, 74)
						task.delay(0.8, function()
							if mainFrame.Visible then
								renderFoodItems()
							end
						end)
					else
						if ShowNotificationRemote and res and res.Message then
							ShowNotificationRemote:FireServer(res.Message)
						end
						renderFoodItems()
					end
				end
			end)
		else
			buyBtn.Active = false
			buyBtn.AutoButtonColor = false
			buyBtn.BackgroundColor3 = Color3.fromRGB(51, 65, 85)
			buyBtn.TextColor3 = Color3.fromRGB(148, 163, 184)
			buyBtn.Text = "❌ " .. disabledReason
		end
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
		if prompt.ObjectText == "🛒 Касса магазина" or (prompt.Parent and prompt.Parent.Name == "CheckoutCounter") or prompt.ObjectText == "🥫 Лавка Еды" then
			openShop()
		end
	end
end)
