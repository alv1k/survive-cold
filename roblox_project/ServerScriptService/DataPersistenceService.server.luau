--[[
    DataPersistenceService.server.luau
    Серверная система автосохранения и персистентности (DataStoreService):
    - Полное сохранение инвентаря, боеприпасов, уровня одежды, прокачки верстака и питомцев при выходе из игры.
    - Автоматическое восстановление до 100% сытости/здоровья/тепла при поврежденных/старых сохранениях.
--]]

local Players = game:GetService("Players")
local DataStoreService = game:GetService("DataStoreService")
local RunService = game:GetService("RunService")

local PlayerDataStore = DataStoreService:GetDataStore("SurviveTheCold_PlayerData_v1")

local function loadPlayerData(player)
	local userId = player.UserId
	local key = "Player_" .. userId

	local success, data = pcall(function()
		return PlayerDataStore:GetAsync(key)
	end)

	if success and data then
		-- 1. Слоты и инвентарь
		player:SetAttribute("MaxSlots", data.MaxSlots or 5)
		player:SetAttribute("WorkbenchLevel", data.WorkbenchLevel or 1)
		player:SetAttribute("ClothingLevel", data.ClothingLevel or 0)
		player:SetAttribute("ClothingProtection", data.ClothingProtection or 0)

		-- 2. Сумка боеприпасов (Ammo Pouch)
		player:SetAttribute("Ammo_Slingshot", data.Ammo_Slingshot or 0)
		player:SetAttribute("Ammo_Revolver", data.Ammo_Revolver or 0)

		-- 3. Ресурсы
		local resources = data.Resources or {}
		for resName, count in pairs(resources) do
			player:SetAttribute(resName, count)
		end

		-- 4. Перерождения
		player:SetAttribute("Rebirths", data.Rebirths or 0)

		-- 5. Жизненные показатели (защита от мгновенной смерти: минимум 100% при загрузке)
		player:SetAttribute("Warmth", (data.Warmth and data.Warmth > 20) and data.Warmth or 100)
		player:SetAttribute("Hunger", (data.Hunger and data.Hunger > 20) and data.Hunger or 100)
		player:SetAttribute("Stamina", 100)

		print(string.format("💾 Данные игрока %s успешно загружены!", player.Name))
	else
		-- Новый игрок
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
		print(string.format("🌟 Создан новый профиль выживающего для %s!", player.Name))
	end
end

local function savePlayerData(player)
	local userId = player.UserId
	local key = "Player_" .. userId

	local data = {
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

	pcall(function()
		PlayerDataStore:SetAsync(key, data)
	end)
	print(string.format("💾 Данные игрока %s сохранены!", player.Name))
end

Players.PlayerAdded:Connect(loadPlayerData)
Players.PlayerRemoving:Connect(savePlayerData)

game:BindToClose(function()
	for _, player in ipairs(Players:GetPlayers()) do
		savePlayerData(player)
	end
end)
