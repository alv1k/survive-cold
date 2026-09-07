--!strict
--[[
    ServerScriptService/DataPersistenceService.server.luau
    Надежная серверная система сохранения данных игроков (DataStoreService):
    - Retry Logic с повторными попытками при сетевых сбоях
    - Защита от вайпа: данные НЕ перезаписываются, если загрузка завершилась ошибкой
    - Использование UpdateAsync для предотвращения конфликтов сессий
    - Корректная обработка PlayerAdded для уже находящихся на сервере игроков
    - Безопасное завершение сервера в BindToClose
--]]

local Players = game:GetService("Players")
local DataStoreService = game:GetService("DataStoreService")

local DATA_STORE_NAME = "SurviveTheCold_PlayerData_v1"
local MAX_RETRIES = 3
local RETRY_DELAY = 1.5

local PlayerDataStore = DataStoreService:GetDataStore(DATA_STORE_NAME)

local pendingSaves: { [number]: boolean } = {}

local function applyDefaultData(player: Player)
	player:SetAttribute("MaxSlots", 5)
	player:SetAttribute("WorkbenchLevel", 1)
	player:SetAttribute("ClothingLevel", 0)
	player:SetAttribute("ClothingProtection", 0)
	player:SetAttribute("Ammo_Slingshot", 0)
	player:SetAttribute("Ammo_Revolver", 0)
	player:SetAttribute("Warmth", 100)
	player:SetAttribute("Hunger", 100)
	player:SetAttribute("Stamina", 100)
	player:SetAttribute("Rebirths", 0)
	player:SetAttribute("DataLoaded", true)
	player:SetAttribute("DataLoadFailed", false)
	print(string.format("🌟 [DataStore] Создан новый профиль выживающего для %s (%d)!", player.Name, player.UserId))
end

local function loadPlayerData(player: Player)
	local userId = player.UserId
	local key = "Player_" .. userId

	local data = nil
	local success = false
	local attempts = 0

	while attempts < MAX_RETRIES and not success do
		attempts = attempts + 1
		local ok, result = pcall(function()
			return PlayerDataStore:GetAsync(key)
		end)

		if ok then
			success = true
			data = result
		else
			warn(string.format("⚠️ [DataStore] Ошибка загрузки данных для %s (Попытка %d/%d): %s", player.Name, attempts, MAX_RETRIES, tostring(result)))
			if attempts < MAX_RETRIES then
				task.wait(RETRY_DELAY * attempts)
			end
		end
	end

	-- Если загрузка упала после всех попыток -> ЗАЩИТА ОТ ВАЙПА
	if not success then
		player:SetAttribute("DataLoadFailed", true)
		player:SetAttribute("DataLoaded", false)
		warn(string.format("❌ [DataStore] КРИТИЧЕСКАЯ ОШИБКА: Не удалось загрузить данные %s! Сохранение для этой сессии заблокировано во избежание вайпа.", player.Name))
		-- Применяем временные дефолты для игры, но не сохраняем
		applyDefaultData(player)
		player:SetAttribute("DataLoadFailed", true)
		return
	end

	if data and type(data) == "table" then
		-- 1. Слоты и инвентарь
		player:SetAttribute("MaxSlots", data.MaxSlots or 5)
		player:SetAttribute("WorkbenchLevel", data.WorkbenchLevel or 1)
		player:SetAttribute("ClothingLevel", data.ClothingLevel or 0)
		player:SetAttribute("ClothingProtection", data.ClothingProtection or 0)

		-- 2. Сумка боеприпасов
		player:SetAttribute("Ammo_Slingshot", data.Ammo_Slingshot or 0)
		player:SetAttribute("Ammo_Revolver", data.Ammo_Revolver or 0)

		-- 3. Ресурсы
		local resources = data.Resources or {}
		for resName, count in pairs(resources) do
			player:SetAttribute(resName, count)
		end

		-- 4. Перерождения
		player:SetAttribute("Rebirths", data.Rebirths or 0)

		-- 5. Жизненные показатели
		player:SetAttribute("Warmth", (data.Warmth and data.Warmth > 20) and data.Warmth or 100)
		player:SetAttribute("Hunger", (data.Hunger and data.Hunger > 20) and data.Hunger or 100)
		player:SetAttribute("Stamina", 100)

		player:SetAttribute("DataLoaded", true)
		player:SetAttribute("DataLoadFailed", false)
		print(string.format("💾 [DataStore] Данные игрока %s успешно загружены!", player.Name))
	else
		-- Игрок действительно впервые в игре
		applyDefaultData(player)
	end
end

local function savePlayerData(player: Player): boolean
	local userId = player.UserId
	if player:GetAttribute("DataLoadFailed") == true then
		warn(string.format("⚠️ [DataStore] Сохранение данных %s пропущено из-за ошибки при начальной загрузке (защита от вайпа).", player.Name))
		return false
	end

	if not player:GetAttribute("DataLoaded") then
		return false
	end

	pendingSaves[userId] = true
	local key = "Player_" .. userId

	local dataToSave = {
		MaxSlots = player:GetAttribute("MaxSlots") or 5,
		WorkbenchLevel = player:GetAttribute("WorkbenchLevel") or 1,
		ClothingLevel = player:GetAttribute("ClothingLevel") or 0,
		ClothingProtection = player:GetAttribute("ClothingProtection") or 0,
		Ammo_Slingshot = player:GetAttribute("Ammo_Slingshot") or 0,
		Ammo_Revolver = player:GetAttribute("Ammo_Revolver") or 0,
		Warmth = player:GetAttribute("Warmth") or 100,
		Hunger = player:GetAttribute("Hunger") or 100,
		Rebirths = player:GetAttribute("Rebirths") or 0,
		Resources = {
			Branches = player:GetAttribute("Branches") or 0,
			Fiber = player:GetAttribute("Fiber") or 0,
			Stone = player:GetAttribute("Stone") or 0,
			Planks = player:GetAttribute("Planks") or 0,
			Parts = player:GetAttribute("Parts") or 0,
			WolfPelt = player:GetAttribute("WolfPelt") or 0,
			YetiPelt = player:GetAttribute("YetiPelt") or 0,
			Torch = player:GetAttribute("Torch") or 0
		}
	}

	local saveSuccess = false
	local attempts = 0

	while attempts < MAX_RETRIES and not saveSuccess do
		attempts = attempts + 1
		local ok, err = pcall(function()
			PlayerDataStore:UpdateAsync(key, function(_oldValue)
				return dataToSave
			end)
		end)

		if ok then
			saveSuccess = true
		else
			warn(string.format("⚠️ [DataStore] Ошибка сохранения данных для %s (Попытка %d/%d): %s", player.Name, attempts, MAX_RETRIES, tostring(err)))
			if attempts < MAX_RETRIES then
				task.wait(RETRY_DELAY * attempts)
			end
		end
	end

	pendingSaves[userId] = nil

	if saveSuccess then
		print(string.format("💾 [DataStore] Данные игрока %s успешно сохранены!", player.Name))
	else
		warn(string.format("❌ [DataStore] Не удалось сохранить данные игрока %s!", player.Name))
	end

	return saveSuccess
end

Players.PlayerAdded:Connect(loadPlayerData)
Players.PlayerRemoving:Connect(savePlayerData)

-- Обработка игроков, которые уже зашли до старта скрипта
for _, player in ipairs(Players:GetPlayers()) do
	task.spawn(loadPlayerData, player)
end

-- Безопасное сохранение при закрытии сервера
game:BindToClose(function()
	local players = Players:GetPlayers()
	for _, player in ipairs(players) do
		task.spawn(savePlayerData, player)
	end

	-- Ожидаем завершения сохранения
	local maxWait = 5.0
	local waited = 0
	while next(pendingSaves) ~= nil and waited < maxWait do
		task.wait(0.2)
		waited = waited + 0.2
	end
end)
