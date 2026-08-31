--[[
    GlobalChatController.client.luau
    Клиентский контроллер глобального межсерверного чата:
    - Интеграция с TextChatService / каналом "Global"
    - Отображение глобальных сообщений со всех серверов
--]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterGui = game:GetService("StarterGui")
local Players = game:GetService("Players")

local RemotesFolder = ReplicatedStorage:WaitForChild("Remotes", 10)
if not RemotesFolder then return end

local GlobalChatEvent = RemotesFolder:WaitForChild("GlobalChatMessage", 10)
if not GlobalChatEvent then return end

-- Получение глобального сообщения со всех серверов мира
GlobalChatEvent.OnClientEvent:Connect(function(data)
	if not data or not data.Sender or not data.Text then return end

	local serverTag = data.ServerJobId and string.format("[#%s]", data.ServerJobId) or "[🌐 Глобал]"
	local rebirthTag = (data.Rebirths and data.Rebirths > 0) and string.format(" [👑 #%d]", data.Rebirths) or ""
	local formattedText = string.format("%s%s %s: %s", serverTag, rebirthTag, data.DisplayName or data.Sender, data.Text)

	-- Вывод в системный чат с голубой подсветкой
	pcall(function()
		StarterGui:SetCore("ChatMakeSystemMessage", {
			Text = formattedText,
			Color = Color3.fromRGB(56, 189, 248),
			Font = Enum.Font.SourceSansBold,
			FontSize = Enum.FontSize.Size18
		})
	end)
end)
