--[[
    FoodEatController.client.luau
    Клиентский скрипт безопасного поедания еды:
    - Предотвращает случайное поедание от кликов по экрану
    - Поедание срабатывает ТОЛЬКО при клике непосредственно по персонажу игрока
    - Отображает подсказку над персонажем при экипировке еды
--]]

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local camera = workspace.CurrentCamera

local RemotesFolder = ReplicatedStorage:WaitForChild("Remotes", 10)
local EatFoodRemote = RemotesFolder and RemotesFolder:WaitForChild("EatFood", 10)
local ShowNotificationRemote = RemotesFolder and RemotesFolder:WaitForChild("ShowNotification", 10)

local FOOD_KEYS = {
	Bar = true, Bread = true, Chips = true, Soup = true, Pepper = true, Coffee = true, Steak = true
}

-- Плавающий индикатор-подсказка над головой персонажа
local playerGui = player:WaitForChild("PlayerGui")
local hintGui = Instance.new("BillboardGui")
hintGui.Name = "FoodEatHintGui"
hintGui.Size = UDim2.new(0, 220, 0, 36)
hintGui.StudsOffset = Vector3.new(0, 3.2, 0)
hintGui.AlwaysOnTop = true
hintGui.Enabled = false
hintGui.Parent = playerGui

local hintLabel = Instance.new("TextLabel", hintGui)
hintLabel.Size = UDim2.new(1, 0, 1, 0)
hintLabel.BackgroundColor3 = Color3.fromRGB(15, 23, 42)
hintLabel.BackgroundTransparency = 0.2
hintLabel.Font = Enum.Font.GothamBold
hintLabel.TextSize = 12
hintLabel.TextColor3 = Color3.fromRGB(74, 222, 128)
hintLabel.Text = "🍖 Кликните по себе, чтобы съесть"
Instance.new("UICorner", hintLabel).CornerRadius = UDim.new(0, 8)
local hintStroke = Instance.new("UIStroke", hintLabel)
hintStroke.Color = Color3.fromRGB(34, 197, 94)
hintStroke.Thickness = 1.2

local function isHoldingFood()
	local char = player.Character
	if not char then return false, nil end
	local tool = char:FindFirstChildOfClass("Tool")
	if not tool then return false, nil end

	local isFood = tool:GetAttribute("IsFood")
	local itemKey = tool:GetAttribute("ItemKey") or tool.Name
	if isFood == true or FOOD_KEYS[itemKey] then
		return true, tool
	end
	return false, nil
end

-- Обновление подсказки над головой
RunService.RenderStepped:Connect(function()
	local holding, tool = isHoldingFood()
	local char = player.Character
	local hrp = char and char:FindFirstChild("HumanoidRootPart")

	if holding and hrp then
		hintGui.Adornee = hrp
		hintGui.Enabled = true
	else
		hintGui.Enabled = false
	end
end)

-- Обработка клика ЛКМ / тапа по экрану
UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then return end
	if input.UserInputType ~= Enum.UserInputType.MouseButton1 and input.UserInputType ~= Enum.UserInputType.Touch then
		return
	end

	local holding, tool = isHoldingFood()
	if not holding then return end

	local char = player.Character
	if not char then return end

	-- Луч от камеры к позиции курсора мыши
	local mousePos = UserInputService:GetMouseLocation()
	local unitRay = camera:ViewportPointToRay(mousePos.X, mousePos.Y)

	local rayParams = RaycastParams.new()
	rayParams.FilterType = Enum.RaycastFilterType.Include
	rayParams.FilterDescendantsInstances = { char }

	local result = workspace:Raycast(unitRay.Origin, unitRay.Direction * 500, rayParams)

	if result and result.Instance and result.Instance:IsDescendantOf(char) then
		-- Игрок кликнул строго по своему персонажу!
		if EatFoodRemote then
			EatFoodRemote:FireServer()
		end
	end
end)

print("🍖 [FoodEatController] Защита от случайного поедания активна (клик по персонажу для съедания)!")
