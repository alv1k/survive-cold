--[[
    ItemDropController.client.luau
    Клиентская обработка выброса предметов на клавишу G:
    - Выбросить можно ТОЛЬКО предмет, который находится В РУКАХ персонажа!
    - Если в руках ничего нет -> ничего не выбрасывается.
    - Факел выбросить нельзя (он должен прогореть в руках).
--]]

local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local RemotesFolder = ReplicatedStorage:WaitForChild("Remotes", 10)
local DropItemRemote = RemotesFolder and RemotesFolder:WaitForChild("DropItem", 10)
local ShowNotificationRemote = RemotesFolder and RemotesFolder:WaitForChild("ShowNotification", 10)

UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then return end
	if input.KeyCode == Enum.KeyCode.G then
		local char = player.Character
		if not char then return end

		-- Проверяем предмет СТРОГО В РУКАХ (Character)
		local equippedTool = char:FindFirstChildOfClass("Tool")
		if not equippedTool then
			-- В руках ничего нет -> ничего не выбрасываем
			return
		end

		local itemKey = equippedTool:GetAttribute("ItemKey") or equippedTool.Name

		-- Факел нельзя выбросить
		if itemKey == "Torch" or equippedTool.Name:find("Факел") then
			if ShowNotificationRemote then
				ShowNotificationRemote:FireServer("🔥 Факел нельзя выбросить! Он горит в руках 120 секунд.")
			end
			return
		end

		-- Отправляем запрос на выброс 1 шт предмета из рук
		if DropItemRemote then
			DropItemRemote:FireServer(itemKey, 1)
		end
	end
end)
