--[[
    SprintController.client.luau
    Клиентский скрипт спринта на Left Shift:
    - Плавное ускорение без утечек памяти (FOV твины запускаются ТОЛЬКО при смене состояния)
    - Безопасное подключение персонажа без блокировок потока
--]]

local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local Camera = workspace.CurrentCamera

local player = Players.LocalPlayer
local character = player.Character
local humanoid = character and character:FindFirstChildOfClass("Humanoid")

local function onCharAdded(char)
	character = char
	humanoid = char:WaitForChild("Humanoid", 10)
end

if player.Character then
	onCharAdded(player.Character)
end
player.CharacterAdded:Connect(onCharAdded)

local DEFAULT_WALK_SPEED = 16
local SPRINT_WALK_SPEED = 26
local DEFAULT_FOV = 70
local SPRINT_FOV = 78

local isShiftHeld = false
local isExhausted = false
local stamina = 100
local MAX_STAMINA = 100
local isCurrentlySprinting = false

-- Функция плавного изменения FOV только при смене состояния спринта!
local function setSprintingFOV(sprinting)
	if isCurrentlySprinting == sprinting then return end
	isCurrentlySprinting = sprinting

	local targetFOV = sprinting and SPRINT_FOV or DEFAULT_FOV
	TweenService:Create(Camera, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		FieldOfView = targetFOV
	}):Play()
end

UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then return end
	if input.KeyCode == Enum.KeyCode.LeftShift or input.KeyCode == Enum.KeyCode.RightShift then
		isShiftHeld = true
	end
end)

UserInputService.InputEnded:Connect(function(input)
	if input.KeyCode == Enum.KeyCode.LeftShift or input.KeyCode == Enum.KeyCode.RightShift then
		isShiftHeld = false
	end
end)

RunService.RenderStepped:Connect(function(dt)
	if not humanoid or humanoid.Health <= 0 then
		setSprintingFOV(false)
		return
	end

	local isMoving = humanoid.MoveDirection.Magnitude > 0.1

	-- Проверка одышки
	if stamina <= 0 then
		isExhausted = true
	elseif isExhausted and stamina >= 20 then
		isExhausted = false
	end

	if isShiftHeld and isMoving and not isExhausted and stamina > 0 then
		humanoid.WalkSpeed = SPRINT_WALK_SPEED
		stamina = math.max(0, stamina - (30 * dt))
		setSprintingFOV(true)
		player:SetAttribute("IsSprinting", true)
		
		if stamina <= 0 then
			isExhausted = true
			humanoid.WalkSpeed = DEFAULT_WALK_SPEED
			setSprintingFOV(false)
			player:SetAttribute("IsSprinting", false)
		end
	else
		humanoid.WalkSpeed = DEFAULT_WALK_SPEED
		stamina = math.min(MAX_STAMINA, stamina + (22 * dt))
		setSprintingFOV(false)
		player:SetAttribute("IsSprinting", false)
	end

	player:SetAttribute("Stamina", math.floor(stamina))
	player:SetAttribute("IsExhausted", isExhausted)
end)
