--[[
    SprintController.client.luau
    Клиентский скрипт бега (спринта) при зажатии Левого Shift:
    - Увеличение WalkSpeed персонажа с 16 до 26 (+62%)
    - Расход и регенерация выносливости (Stamina)
    - Механика одышки (Exhaustion): при 0% стамины спринт мгновенно прекращается и восстанавливается только после 20% стамины
    - FOV эффект при спринте (динамическая камера)
--]]

local UserInputService = game:GetService(UserInputService)
local RunService = game:GetService(RunService)
local Players = game:GetService(Players)
local TweenService = game:GetService(TweenService)
local Camera = workspace.CurrentCamera

local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local humanoid = character:WaitForChild(Humanoid)

player.CharacterAdded:Connect(function(char)
	character = char
	humanoid = char:WaitForChild(Humanoid)
end)

local DEFAULT_WALK_SPEED = 16
local SPRINT_WALK_SPEED = 26
local DEFAULT_FOV = 70
local SPRINT_FOV = 78

local isShiftHeld = false
local isExhausted = false
local stamina = 100
local MAX_STAMINA = 100

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
	if not humanoid or humanoid.Health <= 0 then return end

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
		
		if stamina <= 0 then
			isExhausted = true
			humanoid.WalkSpeed = DEFAULT_WALK_SPEED
		end

		TweenService:Create(Camera, TweenInfo.new(0.2), { FieldOfView = SPRINT_FOV }):Play()
	else
		humanoid.WalkSpeed = DEFAULT_WALK_SPEED
		stamina = math.min(MAX_STAMINA, stamina + (22 * dt))
		
		TweenService:Create(Camera, TweenInfo.new(0.2), { FieldOfView = DEFAULT_FOV }):Play()
	end

	player:SetAttribute(Stamina, math.floor(stamina))
	player:SetAttribute(IsExhausted, isExhausted)
end)
