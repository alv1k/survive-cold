--[[
    WarmthManager.server.luau
    Серверный сервис выживания и управления всеми кострами и печами мира:
    - 🔥 Любой костер / печь в мире зажигается и топится 🌿 Ветками (1 Ветка = +60 сек горения)
    - ⏱️ Авто-затухание огня при окончании дров
    - 🌡️ Нагрев персонажей в радиусе любого горящего источника (+6.0 тепла/сек)
--]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local RemotesFolder = ReplicatedStorage:FindFirstChild("Remotes") or Instance.new("Folder", ReplicatedStorage)
RemotesFolder.Name = "Remotes"

local StartGameRemote = RemotesFolder:FindFirstChild("StartGame") or Instance.new("RemoteEvent", RemotesFolder)
StartGameRemote.Name = "StartGame"

local ShowNotificationRemote = RemotesFolder:FindFirstChild("ShowNotification") or Instance.new("RemoteEvent", RemotesFolder)
ShowNotificationRemote.Name = "ShowNotification"

local ShowDeathScreenRemote = RemotesFolder:FindFirstChild("ShowDeathScreen") or Instance.new("RemoteEvent", RemotesFolder)
ShowDeathScreenRemote.Name = "ShowDeathScreen"

local HideDeathScreenRemote = RemotesFolder:FindFirstChild("HideDeathScreen") or Instance.new("RemoteEvent", RemotesFolder)
HideDeathScreenRemote.Name = "HideDeathScreen"

local RespawnInHouseRemote = RemotesFolder:FindFirstChild("RespawnInHouse") or Instance.new("RemoteEvent", RemotesFolder)
RespawnInHouseRemote.Name = "RespawnInHouse"

local ReviveWithRobuxRemote = RemotesFolder:FindFirstChild("ReviveWithRobux") or Instance.new("RemoteEvent", RemotesFolder)
ReviveWithRobuxRemote.Name = "ReviveWithRobux"

-- Увеличиваем время авто-спавна, чтобы игрок мог выбрать возрождение или быть воскрешен
Players.RespawnTime = 999999

local HeatSourcesFolder = workspace:FindFirstChild("HeatSources") or Instance.new("Folder", workspace)
HeatSourcesFolder.Name = "HeatSources"

local DownedPlayersFolder = workspace:FindFirstChild("DownedPlayers") or Instance.new("Folder", workspace)
DownedPlayersFolder.Name = "DownedPlayers"

local SavedInventoriesOnDeath = {}

local function removeDownedMarker(player)
	local marker = DownedPlayersFolder:FindFirstChild("Downed_" .. player.UserId)
	if marker then marker:Destroy() end
end

local function restoreSavedInventory(player)
	local saved = SavedInventoriesOnDeath[player.UserId]
	if saved then
		player:SetAttribute("ClothingLevel", saved.ClothingLevel or 0)
		player:SetAttribute("ClothingProtection", saved.ClothingProtection or 0)
		player:SetAttribute("Ammo_Slingshot", saved.Ammo_Slingshot or 0)
		player:SetAttribute("Ammo_Revolver", saved.Ammo_Revolver or 0)

		if saved.Items and #saved.Items > 0 then
			for _, itemData in ipairs(saved.Items) do
				if _G.GiveItemToPlayer then
					local tool = _G.GiveItemToPlayer(player, itemData.Key, itemData.Count)
					if tool and itemData.TorchFuel then
						tool:SetAttribute("TorchFuel", itemData.TorchFuel)
					end
				end
			end
		end
		SavedInventoriesOnDeath[player.UserId] = nil
	end
end

local function createDownedMarker(player, pos)
	removeDownedMarker(player)

	local marker = Instance.new("Model")
	marker.Name = "Downed_" .. player.UserId

	local tomb = Instance.new("Part")
	tomb.Name = "Tombstone"
	tomb.Size = Vector3.new(2.4, 3.0, 1.2)
	tomb.Position = pos + Vector3.new(0, 1.5, 0)
	tomb.Anchored = true
	tomb.CanCollide = false
	tomb.Material = Enum.Material.Slate
	tomb.BrickColor = BrickColor.new("Dark stone grey")
	tomb.Parent = marker
	marker.PrimaryPart = tomb

	local heart = Instance.new("Part")
	heart.Name = "HeartGlow"
	heart.Size = Vector3.new(1.0, 1.0, 1.0)
	heart.Position = tomb.Position + Vector3.new(0, 1.8, 0)
	heart.Anchored = true
	heart.CanCollide = false
	heart.Material = Enum.Material.Neon
	heart.BrickColor = BrickColor.new("Bright red")
	heart.Parent = marker

	local prompt = Instance.new("ProximityPrompt", tomb)
	prompt.ObjectText = string.format("❤️ %s (Павший союзник)", player.DisplayName)
	prompt.ActionText = "Воскресить союзника"
	prompt.HoldDuration = 2.0
	prompt.MaxActivationDistance = 12
	prompt.RequiresLineOfSight = false

	prompt.Triggered:Connect(function(allyPlayer)
		if allyPlayer ~= player and allyPlayer.Character and allyPlayer.Character:FindFirstChild("Humanoid") and allyPlayer.Character.Humanoid.Health > 0 then
			removeDownedMarker(player)
			player:SetAttribute("IsDead", false)
			player:LoadCharacter()

			task.wait(0.15)
			if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
				player.Character.HumanoidRootPart.CFrame = CFrame.new(pos + Vector3.new(0, 3, 0))
				local hum = player.Character:FindFirstChild("Humanoid")
				if hum then hum.Health = 60 end
			end

			player:SetAttribute("Warmth", 60)
			player:SetAttribute("Hunger", 60)

			-- Восстанавливаем рюкзак и одежду при воскрешении союзником
			restoreSavedInventory(player)

			-- Сохраняем и телепортируем питомца к воскресшему хозяину
			if _G.PreservePlayerPetOnRevive then
				_G.PreservePlayerPetOnRevive(player, pos)
			end

			HideDeathScreenRemote:FireClient(player)
			ShowNotificationRemote:FireClient(player, string.format("❤️ Вас воскресил союзник %s! (Рюкзак, одежда и питомец сохранены)", allyPlayer.DisplayName))
			ShowNotificationRemote:FireClient(allyPlayer, string.format("❤️ Вы воскресили союзника %s!", player.DisplayName))
			print(string.format("❤️ %s воскресил %s на месте гибели! Рюкзак и питомец сохранены.", allyPlayer.Name, player.Name))
		end
	end)

	marker.Parent = DownedPlayersFolder
end

-- Функция зажигания / подкидывания веток в любой костер или печь
local function tryFeedFireplace(player, firePart)
	local branches = player:GetAttribute("Branches") or 0
	local backpack = player:FindFirstChildOfClass("Backpack")
	local char = player.Character

	-- Проверяем наличие ветки в инвентаре
	local hasBranch = (branches >= 1)
	if not hasBranch and backpack then
		for _, t in ipairs(backpack:GetChildren()) do
			if t:IsA("Tool") and t:GetAttribute("ItemKey") == "Branches" then
				hasBranch = true
				break
			end
		end
	end
	if not hasBranch and char then
		for _, t in ipairs(char:GetChildren()) do
			if t:IsA("Tool") and t:GetAttribute("ItemKey") == "Branches" then
				hasBranch = true
				break
			end
		end
	end

	if not hasBranch then
		ShowNotificationRemote:FireClient(player, "⚠️ Нужна 🌿 Ветка, чтобы зажечь огонь!")
		return false
	end

	-- Списываем 1 ветку
	player:SetAttribute("Branches", math.max(0, branches - 1))

	local deducted = false
	if backpack then
		for _, t in ipairs(backpack:GetChildren()) do
			if t:IsA("Tool") and t:GetAttribute("ItemKey") == "Branches" then
				local count = t:GetAttribute("Count") or 1
				if count > 1 then
					t:SetAttribute("Count", count - 1)
					t.Name = string.format("🌿 Ветки (x%d)", count - 1)
				else
					t:Destroy()
				end
				deducted = true
				break
			end
		end
	end
	if not deducted and char then
		for _, t in ipairs(char:GetChildren()) do
			if t:IsA("Tool") and t:GetAttribute("ItemKey") == "Branches" then
				local count = t:GetAttribute("Count") or 1
				if count > 1 then
					t:SetAttribute("Count", count - 1)
					t.Name = string.format("🌿 Ветки (x%d)", count - 1)
				else
					t:Destroy()
				end
				break
			end
		end
	end

	-- Добавляем +60 секунд горения (+ бонус с Алтаря)
	local curFuel = firePart:GetAttribute("FuelSeconds") or 0
	local maxFuel = firePart:GetAttribute("MaxFuel") or 600
	local bonusFuel = workspace:GetAttribute("CampfireTimeBonus") or 0
	local newFuel = math.min(maxFuel, curFuel + 60 + bonusFuel)
	firePart:SetAttribute("FuelSeconds", newFuel)

	-- Включаем огонь и свет
	local fire = firePart:FindFirstChildOfClass("Fire")
	if fire then fire.Enabled = true end

	local light = firePart:FindFirstChildOfClass("PointLight")
	if light then light.Enabled = true end

	ShowNotificationRemote:FireClient(player, string.format("🪵 Ветка брошена в огонь! (+%dс тепла | Всего: %02d:%02d)", 60 + bonusFuel, math.floor(newFuel/60), newFuel%60))
	print(string.format("🔥 %s подбросил 🌿 Ветку в %s! (Осталось: %d сек)", player.Name, firePart.Name, newFuel))
	return true
end

-- Подключение ProximityPrompt для всех источников тепла
local function bindHeatSourcePrompts()
	for _, source in ipairs(HeatSourcesFolder:GetChildren()) do
		local prompt = source:FindFirstChildOfClass("ProximityPrompt")
		if prompt and not prompt:GetAttribute("Bound") then
			prompt:SetAttribute("Bound", true)
			prompt.Triggered:Connect(function(triggerPlayer)
				tryFeedFireplace(triggerPlayer, source)
			end)
		end
	end
end

HeatSourcesFolder.ChildAdded:Connect(function()
	task.wait(0.1)
	bindHeatSourcePrompts()
end)
bindHeatSourcePrompts()

-- 1. Инициализация характеристик игрока
local function onPlayerSpawn(player, character)
	player:SetAttribute("IsGameStarted", true)
	if not player:GetAttribute("StartGameTimestamp") or player:GetAttribute("StartGameTimestamp") == 0 then
		player:SetAttribute("StartGameTimestamp", os.clock())
	end
	player:SetAttribute("SurvivalTimeSeconds", player:GetAttribute("SurvivalTimeSeconds") or 0)
	player:SetAttribute("Warmth", player:GetAttribute("Warmth") or 100)
	player:SetAttribute("Hunger", player:GetAttribute("Hunger") or 100)
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
		local hrp = character:FindFirstChild("HumanoidRootPart")
		local deathPos = hrp and hrp.Position or Vector3.new(0, 4, 0)
		player:SetAttribute("LastDeathPos", deathPos)
		player:SetAttribute("IsDead", true)

		-- Сохраняем слепок рюкзака и экипировки перед очисткой
		local savedItems = {}
		local backpack = player:FindFirstChildOfClass("Backpack")

		local function saveToolsFrom(container)
			if container then
				for _, t in ipairs(container:GetChildren()) do
					if t:IsA("Tool") and t:GetAttribute("ItemKey") then
						table.insert(savedItems, {
							Key = t:GetAttribute("ItemKey"),
							Count = t:GetAttribute("Count") or 1,
							TorchFuel = t:GetAttribute("TorchFuel")
						})
					end
				end
			end
		end

		saveToolsFrom(backpack)
		saveToolsFrom(character)

		SavedInventoriesOnDeath[player.UserId] = {
			Items = savedItems,
			ClothingLevel = player:GetAttribute("ClothingLevel") or 0,
			ClothingProtection = player:GetAttribute("ClothingProtection") or 0,
			Ammo_Slingshot = player:GetAttribute("Ammo_Slingshot") or 0,
			Ammo_Revolver = player:GetAttribute("Ammo_Revolver") or 0
		}

		player:SetAttribute("CarriedRelics", 0)

		-- Создание маркера павшего союзника для воскрешения другими игроками
		createDownedMarker(player, deathPos)

		-- Открытие окна смерти на клиенте
		ShowDeathScreenRemote:FireClient(player)
		print(string.format("💀 %s погиб на позиции %s! Слепок рюкзака сохранен в ожидании выбора.", player.Name, tostring(deathPos)))
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

Players.PlayerRemoving:Connect(function(player)
	removeDownedMarker(player)
	SavedInventoriesOnDeath[player.UserId] = nil
end)

StartGameRemote.OnServerEvent:Connect(function(player)
	player:SetAttribute("IsGameStarted", true)
	player:SetAttribute("StartGameTimestamp", os.clock())
	print(string.format("🚀 %s подтвердил старт игры!", player.Name))
end)

-- Возрождение в доме (100% сытость и 100% тепло БЕЗ вещей и БЕЗ одежды)
RespawnInHouseRemote.OnServerEvent:Connect(function(player)
	removeDownedMarker(player)
	SavedInventoriesOnDeath[player.UserId] = nil -- очищаем сохраненные вещи
	player:SetAttribute("IsDead", false)
	player:SetAttribute("ClothingLevel", 0)
	player:SetAttribute("ClothingProtection", 0)
	player:SetAttribute("Ammo_Slingshot", 0)
	player:SetAttribute("Ammo_Revolver", 0)

	player:LoadCharacter()

	task.wait(0.15)
	if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
		player.Character.HumanoidRootPart.CFrame = CFrame.new(0, 3.5, 0)
		local hum = player.Character:FindFirstChild("Humanoid")
		if hum then hum.Health = 100 end
	end

	local bp = player:FindFirstChildOfClass("Backpack")
	if bp then bp:ClearAllChildren() end

	player:SetAttribute("Warmth", 100)
	player:SetAttribute("Hunger", 100)

	-- Отправляем питомца отдыхать на лежанку в доме
	if _G.SendPlayerPetHome then
		_G.SendPlayerPetHome(player)
	end

	HideDeathScreenRemote:FireClient(player)
	ShowNotificationRemote:FireClient(player, "🏡 Вы возродились в жилом доме (100% Тепло и Сытость | Рюкзак и одежда сброшены | Питомец дома)")
	print(string.format("🏡 %s возродился в доме (100%% тепло, 100%% сытость, без вещей, питомец ждет дома)!", player.Name))
end)

-- Мгновенное воскрешение на месте за 5 Robux (ВСЕ вещи, одежда и ПИТОМЕЦ СОХРАНЯЮТСЯ)
ReviveWithRobuxRemote.OnServerEvent:Connect(function(player)
	local deathPos = player:GetAttribute("LastDeathPos") or Vector3.new(0, 3.5, 0)
	removeDownedMarker(player)
	player:SetAttribute("IsDead", false)
	player:LoadCharacter()

	task.wait(0.15)
	if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
		player.Character.HumanoidRootPart.CFrame = CFrame.new(deathPos + Vector3.new(0, 3, 0))
		local hum = player.Character:FindFirstChild("Humanoid")
		if hum then hum.Health = 100 end
	end

	player:SetAttribute("Warmth", 100)
	player:SetAttribute("Hunger", 100)

	-- Восстанавливаем сохраненный рюкзак и одежду
	restoreSavedInventory(player)

	-- Сохраняем и телепортируем питомца к хозяину
	if _G.PreservePlayerPetOnRevive then
		_G.PreservePlayerPetOnRevive(player, deathPos)
	end

	HideDeathScreenRemote:FireClient(player)
	ShowNotificationRemote:FireClient(player, "⚡ Вы воскресли на месте гибели со всеми вещами, одеждой и питомцем!")
	print(string.format("⚡ %s воскрес за Robux на месте гибели! Рюкзак, одежда и питомец сохранены.", player.Name))
end)

-- 2. ГЛАВНЫЙ СЕРВЕРНЫЙ ЦИКЛ (Сгорание дров во всем мире и симуляция выживания)
task.spawn(function()
	while true do
		task.wait(1.0)

		-- А) Обновление всех костров и печей на карте
		for _, source in ipairs(HeatSourcesFolder:GetChildren()) do
			local fuel = source:GetAttribute("FuelSeconds") or 0
			local prompt = source:FindFirstChildOfClass("ProximityPrompt")
			local fire = source:FindFirstChildOfClass("Fire")
			local light = source:FindFirstChildOfClass("PointLight")

			if fuel > 0 then
				fuel = fuel - 1
				source:SetAttribute("FuelSeconds", fuel)

				if prompt then
					prompt.ActionText = string.format("Подбросить ветку [🔥 %02d:%02d]", math.floor(fuel / 60), fuel % 60)
					prompt.ObjectText = "🔥 Горящий очаг (+6 тепла/сек)"
				end

				if fuel == 0 then
					if fire then fire.Enabled = false end
					if light then light.Enabled = false end
					if prompt then
						prompt.ActionText = "Зажечь костер (1 🌿 Ветка = +60с)"
						prompt.ObjectText = "🔥 Потухший очаг"
					end
					print(string.format("💨 Огонь в %s полностью погас!", source.Name))
				end
			end
		end

		local isBlizzard = workspace:GetAttribute("IsBlizzard") or false
		local isNight = workspace:GetAttribute("IsNight") or false

		-- Б) Симуляция тепла, голода и здоровья игроков
		for _, player in ipairs(Players:GetPlayers()) do
			local char = player.Character
			if char and char:FindFirstChild("HumanoidRootPart") and char:FindFirstChild("Humanoid") then
				local hrp = char.HumanoidRootPart
				local humanoid = char.Humanoid
				if humanoid.Health > 0 then
					local survSecs = (player:GetAttribute("SurvivalTimeSeconds") or 0) + 1
					player:SetAttribute("SurvivalTimeSeconds", survSecs)

					local pPos = hrp.Position

					-- Поиск ближайшего горящего источника тепла
					local nearBurningFire = false
					for _, source in ipairs(HeatSourcesFolder:GetChildren()) do
						local fuel = source:GetAttribute("FuelSeconds") or 0
						if fuel > 0 then
							local radius = source:GetAttribute("HeatRadius") or 35
							if (source.Position - pPos).Magnitude <= radius then
								nearBurningFire = true
								break
							end
						end
					end

					-- Зона тепла вокруг Древнего Алтаря (Бафф 1/7)
					if workspace:GetAttribute("AltarWarmthZone") == true then
						if (Vector3.new(-60, 1.25, 80) - pPos).Magnitude <= 30 then
							nearBurningFire = true
						end
					end

					-- Проверка наличия зажженного факела в руках персонажа
					local equippedTool = char:FindFirstChildOfClass("Tool")
					local isHoldingTorch = (player:GetAttribute("HasTorchInHand") == true)
						or (equippedTool and (equippedTool:GetAttribute("ItemKey") == "Torch" or equippedTool.Name:find("Факел") or equippedTool.Name:find("Torch")))

					-- Расчет Тепла с учетом командного бонуса с Алтаря и Факела
					local warmth = player:GetAttribute("Warmth") or 100
					local clothingProt = player:GetAttribute("ClothingProtection") or 0
					local teamColdProt = workspace:GetAttribute("TeamColdProtection") or 0
					local totalColdProt = math.min(0.90, clothingProt + teamColdProt)

					local baseColdRate = isBlizzard and 5.0 or (isNight and 2.6 or 1.0)
					local effectiveColdRate = baseColdRate * (1 - totalColdProt)

					local heatSourcesGain = 0
					if nearBurningFire then
						heatSourcesGain = heatSourcesGain + 6.0
					end
					if isHoldingTorch then
						-- Факел в руке активно согревает (+4.0 тепла в сек)
						heatSourcesGain = heatSourcesGain + 4.0
					end
					local bearBuff = player:GetAttribute("BearWarmthBuff") or 0
					heatSourcesGain = heatSourcesGain + bearBuff

					-- Проверка нахождения внутри здания Магазина Продуктов (Тепло стоит на месте)
					local dx = math.abs(pPos.X - (-380))
					local dz = math.abs(pPos.Z - (-450))
					local inFoodShop = (dx <= 16 and dz <= 13 and pPos.Y >= 2 and pPos.Y <= 16)

					if inFoodShop then
						-- В магазине тепло не расходуется и стоит на месте (без костра)
						if isHoldingTorch then
							warmth = math.min(100, warmth + 4.0)
						else
							warmth = warmth -- не меняется
						end
					elseif nearBurningFire or isHoldingTorch then
						-- Около огня или с горящим факелом в руках игрок всегда гарантированно согревается!
						local netGain = math.max(1.5, heatSourcesGain - (isBlizzard and 1.5 or 0))
						warmth = math.min(100, warmth + netGain)
					else
						warmth = math.max(0, math.min(100, warmth + (heatSourcesGain - effectiveColdRate)))
					end
					player:SetAttribute("Warmth", math.floor(warmth))

					-- Расчет Голода (Замедлен ровно в 2 раза: 0.15 вместо 0.30)
					local startTs = player:GetAttribute("StartGameTimestamp") or os.clock()
					local elapsed = os.clock() - startTs

					if elapsed >= 60 then
						local hunger = player:GetAttribute("Hunger") or 100
						local hungerDrain = 0.15 -- В 2 раза медленнее
						if player:GetAttribute("IsSprinting") then
							hungerDrain = hungerDrain * 1.50
						end
						if isBlizzard then
							hungerDrain = hungerDrain * 1.25
						end
						if nearBurningFire or isHoldingTorch or inFoodShop then
							hungerDrain = hungerDrain * 0.60
						end
						hunger = math.max(0, hunger - hungerDrain)
						player:SetAttribute("Hunger", math.floor(hunger))
					else
						player:SetAttribute("Hunger", 100)
					end

					-- Урон и Пассивная регенерация
					local curHunger = player:GetAttribute("Hunger") or 100
					if warmth <= 0 then
						humanoid:TakeDamage(8)
					end
					if curHunger <= 0 then
						humanoid:TakeDamage(6)
					elseif curHunger > 65 and warmth > 60 and humanoid.Health < humanoid.MaxHealth then
						humanoid.Health = math.min(humanoid.MaxHealth, humanoid.Health + 1.5)
					end
				end
			end
		end
	end
end)
