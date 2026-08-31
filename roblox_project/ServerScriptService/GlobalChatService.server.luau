--[[
    GlobalChatService.server.luau
    Глобальный межсерверный чат выживших через MessagingService.
    Позволяет общаться игрокам со всех серверов игры в реальном времени!
--]]

local MessagingService = game:GetService("MessagingService")
local TextService = game:GetService("TextService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local GLOBAL_CHAT_TOPIC = "GlobalSurvivalRadio_v1"
local SPAM_COOLDOWN_SECONDS = 1.5

-- Папка Remotes
local RemotesFolder = ReplicatedStorage:FindFirstChild("Remotes") or Instance.new("Folder", ReplicatedStorage)
RemotesFolder.Name = "Remotes"

local GlobalChatEvent = RemotesFolder:FindFirstChild("GlobalChatMessage") or Instance.new("RemoteEvent", RemotesFolder)
GlobalChatEvent.Name = "GlobalChatMessage"

local playerCooldowns = {}

-- 1. Слушаем сообщения со ВСЕХ серверов Roblox по всему миру
local subscribeSuccess, subscribeConnection = pcall(function()
	return MessagingService:SubscribeAsync(GLOBAL_CHAT_TOPIC, function(message)
		local data = message.Data
		if type(data) == "table" and data.Sender and data.Text then
			-- Рассылаем всем игрокам на ТЕКУЩЕМ сервере
			GlobalChatEvent:FireAllClients(data)
			print(string.format("[🌐 Global Chat] [%s]: %s", data.Sender, data.Text))
		end
	end)
end)

if subscribeSuccess then
	print("📡 [GlobalChatService] Успешно подключен к межсерверному радио Roblox (MessagingService)!")
else
	warn("⚠️ [GlobalChatService] Не удалось подписаться на MessagingService (работает в опубликованном плейсе).")
end

-- 2. Обработка отправки глобального сообщения от игрока
GlobalChatEvent.OnServerEvent:Connect(function(player, rawMessage)
	if type(rawMessage) ~= "string" then return end
	
	local trimmed = string.sub(string.gsub(rawMessage, "^%s*(.-)%s*$", "%1"), 1, 120)
	if string.len(trimmed) == 0 then return end

	-- Проверка кулдауна анти-спама
	local now = os.clock()
	local lastTime = playerCooldowns[player.UserId] or 0
	if now - lastTime < SPAM_COOLDOWN_SECONDS then
		return
	end
	playerCooldowns[player.UserId] = now

	-- Обязательная фильтрация текста по правилам Roblox ToS
	local filteredText = trimmed
	pcall(function()
		local filterResult = TextService:FilterStringAsync(trimmed, player.UserId)
		filteredText = filterResult:GetNonChatStringForBroadcastAsync()
	end)

	local messagePayload = {
		Sender = player.Name,
		DisplayName = player.DisplayName,
		UserId = player.UserId,
		ServerJobId = string.sub(game.JobId, 1, 6),
		Text = filteredText,
		Timestamp = os.time(),
		Rebirths = player:GetAttribute("Rebirths") or 0
	}

	-- Публикуем в глобальную сеть всех серверов
	pcall(function()
		MessagingService:PublishAsync(GLOBAL_CHAT_TOPIC, messagePayload)
	end)

	-- Локальная доставка для мгновенного отклика
	GlobalChatEvent:FireAllClients(messagePayload)
end)

Players.PlayerRemoving:Connect(function(player)
	playerCooldowns[player.UserId] = nil
end)
