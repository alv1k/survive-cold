--[[
    WarmthManager.server.luau
    Серверная система выживания, тепла, голода и восстановления дома:
    - 🔒 До нажатия "Начать" счетчики заблокированы (новичок читает гайд).
    - 🚀 После нажатия "Начать" запускается таймер выживания и шкала тепла.
    - 🍗 Шкала сытости начинает тикать СТРОГО СПУСТЯ 60 СЕКУНД после нажатия "Начать".
    - 🔥 Очаг в жилом доме: согревает (+6 тепла/сек) и требует дрова (1 ветка = +60 сек).
--]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local RemotesFolder = ReplicatedStorage:FindFirstChild("Remotes") or Instance.new("Folder", ReplicatedStorage)
RemotesFolder.Name = "Remotes"

local StartGameRemote = RemotesFolder:FindFirstChild("StartGame") or Instance.new("RemoteEvent", RemotesFolder)
StartGameRemote.Name = "StartGame"

local RepairHouseRemote = RemotesFolder:FindFirstChild("RepairHouse") or Instance.new("RemoteEvent", RemotesFolder)
RepairHouseRemote.Name = "RepairHouse"

local FeedFireRemote = RemotesFolder:FindFirstChild("FeedFire") or Instance.new("RemoteEvent", RemotesFolder)
FeedFireRemote.Name = "FeedFire"

local ShowNotificationRemote = RemotesFolder:FindFirstChild("ShowNotification") or Instance.new("RemoteEvent", RemotesFolder)
ShowNotificationRemote.Name = "ShowNotification"

-- Конфигурация жилого дома игрока
local PLAYER_HOUSE = {
	Position = Vector3.new(0, 5, 0),
	Size = Vector3.new(45, 10, 30),
	FirePosition = Vector3.new(0, 2, 0),
	FireRadius = 18,
	IsRepaired = false,
	RepairCostPlanks = 3,
	FireFuelSeconds = 180,
	MaxFuelSeconds = 600
}

local function isInsidePlayerHouse(pos)
	local minB = PLAYER_HOUSE.Position - (PLAYER_HOUSE.Size / 2)
	local maxB = PLAYER_HOUSE.Position + (PLAYER_HOUSE.Size / 2)
	return pos.X >= minB.X and pos.X <= maxB.X and pos.Z >= minB.Z and pos.Z <= maxB.Z and pos.Y >= (PLAYER_HOUSE.Position.Y - 2) and pos.Y <= (PLAYER_HOUSE.Position.Y + PLAYER_HOUSE.Size.Y + 2)
end

local function isInsideAnyStructure(pos)
	if isInsidePlayerHouse(pos) then return true end
	local cabins = workspace:FindFirstChild("HunterCabins")
	if cabins then
		for _, cabin in ipairs(cabins:GetChildren()) do
			local cPart = cabin:FindFirstChild("Floor") or cabin.PrimaryPart
			if cPart and (cPart.Position - pos).Magnitude < 18 then
				return true
			end
		end
	end
	return false
end

-- 1. Инициализация характеристик игрока при спавне
local function onPlayerSpawn(player, character)
	player:SetAttribute("IsGameStarted", false)
	player:SetAttribute("StartGameTimestamp", 0)
	player:SetAttribute("SurvivalTimeSeconds", 0)
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
		player:SetAttribute("ClothingLevel", 0)
		player:SetAttribute("ClothingProtection", 0)
		player:SetAttribute("CarriedRelics", 0)
		player:SetAttribute("Ammo_Slingshot", 0)
		player:SetAttribute("Ammo_Revolver", 0)

		local backpack = player:FindFirstChildOfClass("Backpack")
		if backpack then
			backpack:ClearAllChildren()
		end
		print(string.format("💀 %s погиб! Рюкзак и одежда утеряны. Дом и верстак сохранены.", player.Name))
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

-- 1.5. Обработка старта игры (нажатие кнопки "Начать!" в туториале)
StartGameRemote.OnServerEvent:Connect(function(player)
	player:SetAttribute("IsGameStarted", true)
	player:SetAttribute("StartGameTimestamp", os.clock())
	print(string.format("🚀 %s нажал 'Начать!' — выживание запущено (льгота сытости 60с)!", player.Name))
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
					-- Защита игрока ДО нажатия "Начать!"
					if player:GetAttribute("IsGameStarted") ~= true then
						player:SetAttribute("Warmth", 100)
						player:SetAttribute("Hunger", 100)
						humanoid.Health = humanoid.MaxHealth
						continue
					end

					-- Тикаем живой таймер выживания
					local survSecs = (player:GetAttribute("SurvivalTimeSeconds") or 0) + 1
					player:SetAttribute("SurvivalTimeSeconds", survSecs)

					local pos = hrp.Position
					local insideHouse = isInsidePlayerHouse(pos)
					local insideStructure = isInsideAnyStructure(pos)

					-- А) Расчет Тепла (Warmth)
					local warmth = player:GetAttribute("Warmth") or 100
					local clothingProt = player:GetAttribute("ClothingProtection") or 0
					local baseColdRate = isBlizzard and 3.2 or (isNight and 1.8 or 0.9)
					local effectiveColdRate = baseColdRate * (1 - clothingProt)

					local heatSourcesGain = 0
					if insideHouse and PLAYER_HOUSE.FireFuelSeconds > 0 then
						heatSourcesGain = heatSourcesGain + 6.0
					end
					if player:GetAttribute("HasTorchInHand") == true then
						heatSourcesGain = heatSourcesGain + 1.5
					end
					local bearBuff = player:GetAttribute("BearWarmthBuff") or 0
					heatSourcesGain = heatSourcesGain + bearBuff

					if insideStructure and heatSourcesGain > 0 then
						warmth = math.min(100, warmth + heatSourcesGain)
					else
						warmth = math.max(0, math.min(100, warmth + (heatSourcesGain - effectiveColdRate)))
					end
					player:SetAttribute("Warmth", math.floor(warmth))

					-- Б) Расчет Сытости (Hunger): НАЧИНАЕТ ТИКАТЬ СТРОГО ЧЕРЕЗ 60 СЕКУНД ПОСЛЕ СТАРТА
					local startTs = player:GetAttribute("StartGameTimestamp") or os.clock()
					local elapsed = os.clock() - startTs

					if elapsed >= 60 then
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
					else
						player:SetAttribute("Hunger", 100)
					end

					-- В) Урон и Пассивная регенерация
					local curHunger = player:GetAttribute("Hunger") or 100
					if warmth <= 0 then
						humanoid:TakeDamage(5) -- Замерзание
					end
					if curHunger <= 0 then
						humanoid:TakeDamage(4) -- Голодание
					elseif curHunger > 65 and warmth > 60 and humanoid.Health < humanoid.MaxHealth then
						humanoid.Health = math.min(humanoid.MaxHealth, humanoid.Health + 1) -- Сытое исцеление
					end
				end
			end
		end
	end
end)
