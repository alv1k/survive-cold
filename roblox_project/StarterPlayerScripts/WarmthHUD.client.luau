--[[
    WarmthHUD.client.luau
    Клиентский скрипт управления:
    - При нажатии клавиши G с сервера запрашивается выброс РО ВНО 1 предмета из выбранного слота.
--]]

local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local selectedSlot = nil

UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then return end
	
	local numberKeys = {
		[Enum.KeyCode.One]   = 1, [Enum.KeyCode.Two]   = 2, [Enum.KeyCode.Three] = 3,
		[Enum.KeyCode.Four]  = 4, [Enum.KeyCode.Five]  = 5, [Enum.KeyCode.Six]   = 6,
		[Enum.KeyCode.Seven] = 7, [Enum.KeyCode.Eight] = 8, [Enum.KeyCode.Nine]  = 9,
		[Enum.KeyCode.Zero]  = 10,
	}
	
	local slotNum = numberKeys[input.KeyCode]
	if slotNum then
		if selectedSlot == slotNum then
			selectedSlot = nil
			local character = player.Character
			if character then
				local humanoid = character:FindFirstChildOfClass("Humanoid")
				if humanoid then humanoid:UnequipTools() end
			end
		else
			selectedSlot = slotNum
			local equipEvent = ReplicatedStorage:FindFirstChild("EquipSlotEvent")
			if equipEvent then equipEvent:FireServer(selectedSlot) end
		end
	end
	
	-- КЛАВИША G — ВЫБРАСЫВАТЬ ПО 1 ШТУКЕ!
	if input.KeyCode == Enum.KeyCode.G then
		if selectedSlot then
			print("📦 Выброс РО ВНО 1 предмета из слота " .. selectedSlot)
			local dropEvent = ReplicatedStorage:FindFirstChild("DropItemEvent")
			if dropEvent then
				dropEvent:FireServer(selectedSlot, 1) -- ПАРАМЕТР 1 ШТУКА!
			end
		end
	end
end)
