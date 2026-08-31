--[[
    MouseHarvestController.client.luau
    Клиентская добыча ресурсов 4 кликами ЛКМ по 3D-моделям:
    - 100% кликабельность по любой части многосоставной 3D-модели
    - Всплывающий индикатор прогресса (1/4 -> 2/4 -> 3/4 -> 4/4)
    - Эффект вздрагивания и искр
--]]

local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local mouse = player:GetMouse()

local RemotesFolder = ReplicatedStorage:WaitForChild("Remotes", 10)
if not RemotesFolder then return end

local HarvestResourceRemote = RemotesFolder:WaitForChild("HarvestResource", 10)
if not HarvestResourceRemote then return end

local lastClickTime = 0
local CLICK_COOLDOWN = 0.18

-- Функция поиска валидного ресурса по клику мыши
local function getHarvestNodeFromTarget(target)
	if not target then return nil, nil end

	-- 1. Если кликнули по BasePart внутри Model ресурса
	local model = target:FindFirstAncestorOfClass("Model")
	if model and model:GetAttribute("ResourceType") and model:GetAttribute("IsHarvestable") == true then
		local mainPart = model.PrimaryPart or target
		return model, mainPart
	end

	-- 2. Если кликнули по одиночной части
	if target:IsA("BasePart") and target:GetAttribute("ResourceType") and target:GetAttribute("IsHarvestable") == true and target.Transparency < 1 then
		return target, target
	end

	return nil, nil
end

-- Всплывающий индикатор кликов над ресурсом
local function showHitProgressBillboard(anchorPart, hitsLeft, maxHits)
	if not anchorPart or not anchorPart:IsA("BasePart") then return end

	local existingBb = anchorPart:FindFirstChild("HarvestBillboard")
	if existingBb then existingBb:Destroy() end

	local bb = Instance.new("BillboardGui")
	bb.Name = "HarvestBillboard"
	bb.Size = UDim2.new(0, 115, 0, 38)
	bb.StudsOffset = Vector3.new(0, 2.2, 0)
	bb.AlwaysOnTop = true
	bb.Parent = anchorPart

	local frame = Instance.new("Frame")
	frame.Size = UDim2.new(1, 0, 1, 0)
	frame.BackgroundColor3 = Color3.fromRGB(15, 23, 42)
	frame.BackgroundTransparency = 0.15
	frame.BorderSizePixel = 0
	frame.Parent = bb
	Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 8)

	local stroke = Instance.new("UIStroke", frame)
	stroke.Color = Color3.fromRGB(56, 189, 248)
	stroke.Thickness = 1.5

	local currentHit = maxHits - hitsLeft
	local text = (hitsLeft <= 0) and "🎉 Добыто!" or string.format("⛏️ Удар: %d / %d", currentHit, maxHits)

	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(1, 0, 0.55, 0)
	label.Position = UDim2.new(0, 0, 0, 2)
	label.BackgroundTransparency = 1
	label.Font = Enum.Font.GothamBold
	label.TextSize = 11.5
	label.TextColor3 = (hitsLeft <= 0) and Color3.fromRGB(74, 222, 128) or Color3.fromRGB(250, 204, 21)
	label.Text = text
	label.Parent = frame

	local barBg = Instance.new("Frame")
	barBg.Size = UDim2.new(0.85, 0, 0, 5)
	barBg.Position = UDim2.new(0.075, 0, 0.65, 0)
	barBg.BackgroundColor3 = Color3.fromRGB(30, 41, 59)
	barBg.BorderSizePixel = 0
	barBg.Parent = frame
	Instance.new("UICorner", barBg).CornerRadius = UDim.new(0, 3)

	local barFill = Instance.new("Frame")
	barFill.Size = UDim2.new(math.clamp(currentHit / maxHits, 0, 1), 0, 1, 0)
	barFill.BackgroundColor3 = (hitsLeft <= 0) and Color3.fromRGB(74, 222, 128) or Color3.fromRGB(56, 189, 248)
	barFill.BorderSizePixel = 0
	barFill.Parent = barBg
	Instance.new("UICorner", barFill).CornerRadius = UDim.new(0, 3)

	task.delay(1.6, function()
		if bb and bb.Parent then bb:Destroy() end
	end)
end

local function onMouseClick()
	local now = os.clock()
	if now - lastClickTime < CLICK_COOLDOWN then return end
	lastClickTime = now

	local target = mouse.Target
	if not target then return end

	local char = player.Character
	if not char or not char:FindFirstChild("HumanoidRootPart") then return end

	local nodeModel, hitPart = getHarvestNodeFromTarget(target)
	if not nodeModel or not hitPart then return end

	local nodePos = hitPart.Position
	local dist = (char.HumanoidRootPart.Position - nodePos).Magnitude

	if dist <= 24 then
		local currentHitsLeft = nodeModel:GetAttribute("HitsLeft") or 4
		local maxHits = nodeModel:GetAttribute("MaxHits") or 4
		local newHitsLeft = math.max(0, currentHitsLeft - 1)
		nodeModel:SetAttribute("HitsLeft", newHitsLeft)

		if newHitsLeft <= 0 then
			nodeModel:SetAttribute("IsHarvestable", false)
		end

		showHitProgressBillboard(hitPart, newHitsLeft, maxHits)
		HarvestResourceRemote:FireServer(nodeModel)

		-- Анимация вздрагивания при ударе
		if hitPart and hitPart:IsA("BasePart") then
			local origCF = hitPart.CFrame
			local shakeTween = TweenService:Create(hitPart, TweenInfo.new(0.06, Enum.EasingStyle.Sine, Enum.EasingDirection.Out, 0, true), {
				CFrame = origCF * CFrame.Angles(0, 0, math.rad(math.random(-4, 4)))
			})
			shakeTween:Play()
		end
	end
end

UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then return end
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		onMouseClick()
	end
end)
