--[[
    WarmthManager.server.luau
    Серверная система моделирования Тепла (Warmth), Голода (Hunger), Здоровья и Костра в жилом доме.
--]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Папка Remotes
local RemotesFolder = ReplicatedStorage:FindFirstChild("Remotes") or Instance.new("Folder", ReplicatedStorage)
RemotesFolder.Name = "Remotes"

local FeedFireRemote = RemotesFolder:FindFirstChild("FeedFire") or Instance.new("RemoteEvent", RemotesFolder)
FeedFireRemote.Name = "FeedFire"

local RepairHouseRemote = RemotesFolder:FindFirstChild("RepairHouse") or Instance.new("RemoteEvent", RemotesFolder)
RepairHouseRemote.Name = "RepairHouse"

-- Параметры Жилого Дома
local PLAYER_HOUSE = {
	Position = Vector3.new(0, 5, 0),
	Size = Vector3.new(45, 10, 30),
	IsRepaired = false,
	RepairCostPlanks = 3,
	FireFuelSeconds = 120,
	MaxFuelSeconds = 360
}

-- Параметры 3 Охотничьих Домиков
local HUNTER_CABINS = {
	{ Position = Vector3.new(-300, 4, 300), Size = Vector3.new(22.5, 8, 15) },
	{ Position = Vector3.new(300, 4, -300), Size = Vector3.new(22.5, 8, 15) },
	{ Position = Vector3.new(0, 4, 350), Size = Vector3.new(22.5, 8, 15) }
}

-- Проверка нахождения персонажа внутри дома
local function isInsidePlayerHouse(pos)
	local minBounds = PLAYER_HOUSE.Position - (PLAYER_HOUSE.Size / 2)
	local maxBounds = PLAYER_HOUSE.Position + (PLAYER_HOUSE.Size / 2)
	return pos.X >= minBounds.X and pos.X <= maxBounds.X and
	       pos.Z >= minBounds.Z and pos.Z <= maxBounds.Z
end

-- Проверка нахождения персонажа в любом укрытии
local function isInsideAnyStructure(pos)
	if isInsidePlayerHouse(pos) then return true end
	for _, cabin in ipairs(HUNTER_CABINS) do
		local minB = cabin.Position - (cabin.Size / 2)
		local maxB = cabin.Position + (cabin.Size / 2)
		if pos.X >= minB.X and pos.X <= maxB.X and pos.Z >= minB.Z and pos.Z <= maxB.Z then
			return true
		end
	end
	return false
end

-- 1. Инициализация характеристик игрока при входе/спавне
local function onPlayerSpawn(player, character)
	-- Всегда гарантированно 100% сытости, тепла и выносливости при старте!
	player:SetAttribute("Warmth", 100)
	player:SetAttribute("Hunger", 100)
	player:SetAttribute("Stamina", 100)
	player:SetAttribute("MaxSlots", player:GetAttribute("MaxSlots") or 5)
	player:SetAttribute("WorkbenchLevel", player:GetAttribute("WorkbenchLevel") or 1)
	player:SetAttribute("ClothingLevel", player:GetAttribute("ClothingLevel") or 0)
	player:SetAttribute("ClothingProtection", player:GetAttribute("ClothingProtection") or 0)
	player:SetAttribute("Ammo_Slingshot", player:GetAttribute("Ammo_Slingshot") or 0)
	player:SetAttribute("Ammo_Revolver", player:GetAttribute("Ammo_Revolver") or 0)

	local humanoid = character:WaitForChild("Humanoid")
	humanoid.MaxHealth = 100
	humanoid.Health = 100

	humanoid.Died:Connect(function()
		-- Правило гибели: потеря рюкзака и одежды, но дом и всё внутри сохраняется!
		player:SetAttribute("ClothingLevel", 0)
		player:SetAttribute("ClothingProtection", 0)
		player:SetAttribute("CarriedRelics", 0)
		player:SetAttribute("Ammo_Slingshot", 0)
		player:SetAttribute("Ammo_Revolver", 0)

		local backpack = player:FindFirstChildOfClass("Backpack")
		if backpack then
			backpack:ClearAllChildren()
		end
		print(string.format("💀 %s погиб! Рюкзак и одежда утеряны. Дом и питомцы на базе сохранены.", player.Name))
	end)
end

Players.PlayerAdded:Connect(function(player)
	player.CharacterAdded:Connect(function(char)
		onPlayerSpawn(player, char)
	end)
	if player.Character then
		onPlayerSpawn(player, player.Character)
	end
end)

-- 2. Обработка починки дома (3 Доски)
RepairHouseRemote.OnServerEvent:Connect(function(player)
	local planks = player:GetAttribute("Planks") or 0
	if planks >= PLAYER_HOUSE.RepairCostPlanks and not PLAYER_HOUSE.IsRepaired then
		player:SetAttribute("Planks", planks - PLAYER_HOUSE.RepairCostPlanks)
		PLAYER_HOUSE.IsRepaired = true
		PLAYER_HOUSE.FireFuelSeconds = 180
		workspace:SetAttribute("HouseRepaired", true)
		print(string.format("🏡 %s отремонтировал жилой дом!", player.Name))
	end
end)

-- 3. Обработка подкидывания дров в костер жилого дома (+60 сек за ветку)
FeedFireRemote.OnServerEvent:Connect(function(player)
	local branches = player:GetAttribute("Branches") or 0
	if branches >= 1 then
		player:SetAttribute("Branches", branches - 1)
		PLAYER_HOUSE.FireFuelSeconds = math.min(PLAYER_HOUSE.MaxFuelSeconds, PLAYER_HOUSE.FireFuelSeconds + 60)
		workspace:SetAttribute("HouseFireFuel", PLAYER_HOUSE.FireFuelSeconds)
		print(string.format("🪵 %s бросил ветку в костер! (Осталось горения: %d сек)", player.Name, PLAYER_HOUSE.FireFuelSeconds))
	end
end)

-- 4. Главный цикл симуляции тепла, голода и здоровья (каждую 1 сек)
task.spawn(function()
	while true do
		task.wait(1.0)

		-- Сгорание дров в костре
		if PLAYER_HOUSE.FireFuelSeconds > 0 then
			PLAYER_HOUSE.FireFuelSeconds = math.max(0, PLAYER_HOUSE.FireFuelSeconds - 1)
			workspace:SetAttribute("HouseFireFuel", PLAYER_HOUSE.FireFuelSeconds)
		end

		local isBlizzard = workspace:GetAttribute("IsBlizzard") or false
		local isNight = workspace:GetAttribute("IsNight") or false

		for _, player in ipairs(Players:GetPlayers()) do
			local char = player.Character
			if char and char:FindFirstChild("HumanoidRootPart") and char:FindFirstChild("Humanoid") then
				local hrp = char.HumanoidRootPart
				local humanoid = char.Humanoid
				if humanoid.Health > 0 then
					local pos = hrp.Position
					local insideHouse = isInsidePlayerHouse(pos)
					local insideStructure = isInsideAnyStructure(pos)

					-- А) Расчет Тепла (Warmth)
					local warmth = player:GetAttribute("Warmth") or 100
					local clothingProt = player:GetAttribute("ClothingProtection") or 0
					local baseColdRate = isBlizzard and 3.2 or (isNight and 1.8 or 0.9)
					local effectiveColdRate = baseColdRate * (1 - clothingProt)

					local heatSourcesGain = 0
					-- Очаг в доме
					if insideHouse and PLAYER_HOUSE.FireFuelSeconds > 0 then
						heatSourcesGain = heatSourcesGain + 6.0
					end
					-- Факел в руках
					local equippedTool = char:FindFirstChildOfClass("Tool")
					if equippedTool and equippedTool.Name:find("Факел") or equippedTool and equippedTool.Name:find("Torch") then
						heatSourcesGain = heatSourcesGain + 1.5
					end
					-- Бафф Медвежонка
					local bearBuff = player:GetAttribute("BearWarmthBuff") or 0
					heatSourcesGain = heatSourcesGain + bearBuff

					if insideStructure and heatSourcesGain > 0 then
						warmth = math.min(100, warmth + heatSourcesGain)
					else
						warmth = math.max(0, math.min(100, warmth + (heatSourcesGain - effectiveColdRate)))
					end
					player:SetAttribute("Warmth", math.floor(warmth))

					-- Б) Расчет Голода (Hunger - 100% хватает на 5-6 минут)
					local hunger = player:GetAttribute("Hunger") or 100
					local hungerDrain = 0.30
					if player:GetAttribute("IsSprinting") then
						hungerDrain = hungerDrain * 1.75
					end
					if isBlizzard then
						hungerDrain = hungerDrain * 1.30
					end
					if insideStructure then
						hungerDrain = hungerDrain * 0.60
					end
					hunger = math.max(0, hunger - hungerDrain)
					player:SetAttribute("Hunger", math.floor(hunger))

					-- В) Урон и Пассивная регенерация
					if warmth <= 0 then
						humanoid:TakeDamage(5) -- Замерзание
					end
					if hunger <= 0 then
						humanoid:TakeDamage(4) -- Голодание
					elseif hunger > 65 and warmth > 60 and humanoid.Health < humanoid.MaxHealth then
						humanoid.Health = math.min(humanoid.MaxHealth, humanoid.Health + 1) -- Сытое исцеление
					end
				end
			end
		end
	end
end)

