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

local HeatSourcesFolder = workspace:FindFirstChild("HeatSources") or Instance.new("Folder", workspace)
HeatSourcesFolder.Name = "HeatSources"

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

	-- Добавляем +60 секунд горения
	local curFuel = firePart:GetAttribute("FuelSeconds") or 0
	local maxFuel = firePart:GetAttribute("MaxFuel") or 600
	local newFuel = math.min(maxFuel, curFuel + 60)
	firePart:SetAttribute("FuelSeconds", newFuel)

	-- Включаем огонь и свет
	local fire = firePart:FindFirstChildOfClass("Fire")
	if fire then fire.Enabled = true end

	local light = firePart:FindFirstChildOfClass("PointLight")
	if light then light.Enabled = true end

	ShowNotificationRemote:FireClient(player, string.format("🪵 Ветка брошена в огонь! (+60с тепла | Всего: %02d:%02d)", math.floor(newFuel/60), newFuel%60))
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
		if backpack then backpack:ClearAllChildren() end
		print(string.format("💀 %s погиб! Рюкзак очищен. Дом и верстак сохранены.", player.Name))
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

StartGameRemote.OnServerEvent:Connect(function(player)
	player:SetAttribute("IsGameStarted", true)
	player:SetAttribute("StartGameTimestamp", os.clock())
	print(string.format("🚀 %s нажал 'Начать!' — выживание запущено!", player.Name))
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
					if player:GetAttribute("IsGameStarted") ~= true then
						player:SetAttribute("Warmth", 100)
						player:SetAttribute("Hunger", 100)
						humanoid.Health = humanoid.MaxHealth
						continue
					end

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

					-- Расчет Тепла
					local warmth = player:GetAttribute("Warmth") or 100
					local clothingProt = player:GetAttribute("ClothingProtection") or 0
					local baseColdRate = isBlizzard and 5.0 or (isNight and 2.6 or 1.0)
					local effectiveColdRate = baseColdRate * (1 - clothingProt)

					local heatSourcesGain = 0
					if nearBurningFire then
						heatSourcesGain = heatSourcesGain + 6.0
					end
					if player:GetAttribute("HasTorchInHand") == true then
						heatSourcesGain = heatSourcesGain + 1.5
					end
					local bearBuff = player:GetAttribute("BearWarmthBuff") or 0
					heatSourcesGain = heatSourcesGain + bearBuff

					if nearBurningFire then
						warmth = math.min(100, warmth + heatSourcesGain)
					else
						warmth = math.max(0, math.min(100, warmth + (heatSourcesGain - effectiveColdRate)))
					end
					player:SetAttribute("Warmth", math.floor(warmth))

					-- Расчет Голода
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
						if nearBurningFire then
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
