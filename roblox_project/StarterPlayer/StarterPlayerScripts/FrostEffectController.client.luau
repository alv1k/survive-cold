--[[
    FrostEffectController.client.luau
    Клиентские визуальные эффекты замерзания:
    - ❄️ Ледяная морозная виньетка по краям экрана при падении тепла (< 50%)
    - 💨 Дрожь камеры и пульсация инея при критическом переохлаждении (< 20%)
    - 🌬️ Пар изо рта (морозное дыхание) каждые 3.5 секунды
--]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local camera = workspace.CurrentCamera

-- Создание полноэкранного оверлея
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "FrostScreenGui"
screenGui.ResetOnSpawn = false
screenGui.IgnoreGuiInset = true
screenGui.DisplayOrder = 5
screenGui.Parent = playerGui

-- Контейнер виньетки
local frostContainer = Instance.new("Frame")
frostContainer.Name = "FrostContainer"
frostContainer.Size = UDim2.new(1, 0, 1, 0)
frostContainer.BackgroundTransparency = 1
frostContainer.Parent = screenGui

-- 4 Градиентные ледяные рамки по самым краям экрана (Верх, Низ, Лево, Право)
local function createFrostBorder(name, size, pos, gradRotation)
	local border = Instance.new("Frame")
	border.Name = name
	border.Size = size
	border.Position = pos
	border.BackgroundColor3 = Color3.fromRGB(186, 230, 253)
	border.BackgroundTransparency = 1
	border.BorderSizePixel = 0
	border.Parent = frostContainer

	local grad = Instance.new("UIGradient", border)
	grad.Rotation = gradRotation
	grad.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0),
		NumberSequenceKeypoint.new(0.5, 0.6),
		NumberSequenceKeypoint.new(1, 1)
	})
	return border
end

local borderTop = createFrostBorder("Top", UDim2.new(1, 0, 0.14, 0), UDim2.new(0, 0, 0, 0), 90)
local borderBottom = createFrostBorder("Bottom", UDim2.new(1, 0, 0.14, 0), UDim2.new(0, 0, 0.86, 0), 270)
local borderLeft = createFrostBorder("Left", UDim2.new(0.14, 0, 1, 0), UDim2.new(0, 0, 0, 0), 0)
local borderRight = createFrostBorder("Right", UDim2.new(0.14, 0, 1, 0), UDim2.new(0.86, 0, 0, 0), 180)

local borders = { borderTop, borderBottom, borderLeft, borderRight }

-- Морозное дыхание (Cold Breath Particle)
local function setupColdBreath(char)
	local head = char:WaitForChild("Head", 10)
	if not head then return end

	local att = Instance.new("Attachment", head)
	att.Position = Vector3.new(0, -0.2, -0.6)

	local emitter = Instance.new("ParticleEmitter")
	emitter.Name = "ColdBreathEmitter"
	emitter.Rate = 0
	emitter.Lifetime = NumberRange.new(1.0, 1.6)
	emitter.Speed = NumberRange.new(1.2, 2.0)
	emitter.SpreadAngle = Vector2.new(15, 15)
	emitter.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.2),
		NumberSequenceKeypoint.new(0.4, 0.6),
		NumberSequenceKeypoint.new(1, 1.2)
	})
	emitter.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.5),
		NumberSequenceKeypoint.new(0.7, 0.7),
		NumberSequenceKeypoint.new(1, 1)
	})
	emitter.Color = ColorSequence.new(Color3.fromRGB(240, 248, 255))
	emitter.Parent = att

	task.spawn(function()
		while char and char.Parent do
			task.wait(math.random(30, 45) / 10)
			local warmth = player:GetAttribute("Warmth") or 100
			if warmth < 80 and emitter and emitter.Parent then
				emitter:Emit(math.random(4, 7))
			end
		end
	end)
end

if player.Character then setupColdBreath(player.Character) end
player.CharacterAdded:Connect(setupColdBreath)

-- Плавное обновление виньетки в каждом кадре
RunService.RenderStepped:Connect(function()
	local warmth = player:GetAttribute("Warmth") or 100
	local isBlizzard = workspace:GetAttribute("IsBlizzard") or false

	local targetTrans = 1.0

	if warmth < 50 then
		-- Мягкое появление инея по краям экрана (минимум 0.40 прозрачности, чтобы никогда не слепить)
		local frostFactor = 1 - (warmth / 50)
		targetTrans = math.clamp(1.0 - (frostFactor * 0.60), 0.40, 1.0)
	end

	-- В метель легкий дополнительный морозный оттенок по периметру
	if isBlizzard and targetTrans < 1.0 then
		targetTrans = math.max(0.35, targetTrans - 0.10)
	end

	for _, b in ipairs(borders) do
		b.BackgroundTransparency = b.BackgroundTransparency + (targetTrans - b.BackgroundTransparency) * 0.1
	end


	-- Микро-дрожь камеры при критическом замерзании
	if warmth <= 15 then
		local shake = Vector3.new(
			(math.random() - 0.5) * 0.04,
			(math.random() - 0.5) * 0.04,
			0
		)
		camera.CFrame = camera.CFrame * CFrame.new(shake)
	end
end)

print("❄️ [FrostEffect] Ледяной визуальный оверлей и морозное дыхание активны!")
