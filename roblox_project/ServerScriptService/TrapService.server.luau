--[[
    TrapService.server.luau
    Серверная система Охотничьих Капканов (RabbitTrap) и Шипастого Пола (SpikeTrap):
    - 🪤 RabbitTrap: авто-ловля зайцев и удержание мобов.
    - 📌 SpikeTrap: прочность на 10 срабатываний / ударов мобов, поломка при 0, починка за 3 ⚙️ Детали.
    - 🛠️ Установка из рук по клику ЛКМ на снег.
--]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local TrapsFolder = workspace:FindFirstChild("PlacedTraps") or Instance.new("Folder", workspace)
TrapsFolder.Name = "PlacedTraps"

local RemotesFolder = ReplicatedStorage:FindFirstChild("Remotes") or Instance.new("Folder", ReplicatedStorage)
local ShowNotificationRemote = RemotesFolder:FindFirstChild("ShowNotification") or Instance.new("RemoteEvent", RemotesFolder)
ShowNotificationRemote.Name = "ShowNotification"

-- 1. Создание 3D модели Капкана (RabbitTrap)
local function spawnPlacedRabbitTrap(ownerPlayer, spawnPos)
	local trapModel = Instance.new("Model")
	trapModel.Name = "ActiveHunterTrap"
	trapModel:SetAttribute("TrapType", "RabbitTrap")

	-- Основание капкана (металлическая пластина)
	local base = Instance.new("Part")
	base.Name = "Base"
	base.Size = Vector3.new(2.4, 0.25, 2.4)
	base.Position = spawnPos + Vector3.new(0, 0.15, 0)
	base.Anchored = true
	base.CanCollide = false
	base.Material = Enum.Material.Metal
	base.BrickColor = BrickColor.new("Dark stone grey")
	base.Parent = trapModel

	-- Челюсти капкана
	local jaw1 = Instance.new("Part")
	jaw1.Name = "Jaw1"
	jaw1.Size = Vector3.new(2.2, 0.4, 0.3)
	jaw1.Position = base.Position + Vector3.new(0, 0.2, 0.9)
	jaw1.Anchored = true
	jaw1.CanCollide = false
	jaw1.Material = Enum.Material.Metal
	jaw1.BrickColor = BrickColor.new("Black")
	jaw1.Parent = trapModel

	local jaw2 = Instance.new("Part")
	jaw2.Name = "Jaw2"
	jaw2.Size = Vector3.new(2.2, 0.4, 0.3)
	jaw2.Position = base.Position + Vector3.new(0, 0.2, -0.9)
	jaw2.Anchored = true
	jaw2.CanCollide = false
	jaw2.Material = Enum.Material.Metal
	jaw2.BrickColor = BrickColor.new("Black")
	jaw2.Parent = trapModel

	-- Неоновый индикатор
	local statusLight = Instance.new("Part")
	statusLight.Name = "StatusLight"
	statusLight.Size = Vector3.new(0.4, 0.4, 0.4)
	statusLight.Position = base.Position + Vector3.new(0, 0.3, 0)
	statusLight.Anchored = true
	statusLight.CanCollide = false
	statusLight.Material = Enum.Material.Neon
	statusLight.BrickColor = BrickColor.new("Bright green")
	statusLight.Parent = trapModel

	trapModel.PrimaryPart = base
	trapModel:SetAttribute("IsArmed", true)
	trapModel:SetAttribute("HasPrey", false)
	trapModel:SetAttribute("OwnerUserId", ownerPlayer and ownerPlayer.UserId or 0)
	trapModel.Parent = TrapsFolder

	local prompt = Instance.new("ProximityPrompt", base)
	prompt.ActionText = "Взведен (Ожидание дичи...)"
	prompt.ObjectText = "🪤 Охотничий капкан"
	prompt.HoldDuration = 0
	prompt.MaxActivationDistance = 10
	prompt.RequiresLineOfSight = false

	-- Взаимодействие с игроком
	prompt.Triggered:Connect(function(triggerPlayer)
		local hasPrey = trapModel:GetAttribute("HasPrey")
		local isArmed = trapModel:GetAttribute("IsArmed")

		if hasPrey then
			local given = false
			if _G.GiveItemToPlayer then
				given = _G.GiveItemToPlayer(triggerPlayer, "Steak", 1)
			else
				local giveBindable = ReplicatedStorage:FindFirstChild("GiveItem")
				if giveBindable and giveBindable:IsA("BindableFunction") then
					given = giveBindable:Invoke(triggerPlayer, "Steak", 1)
				end
			end
			trapModel:SetAttribute("HasPrey", false)
			trapModel:SetAttribute("IsArmed", true)
			statusLight.BrickColor = BrickColor.new("Bright green")
			prompt.ActionText = "Взведен (Ожидание дичи...)"
			prompt.ObjectText = "🪤 Охотничий капкан"

			ShowNotificationRemote:FireClient(triggerPlayer, "🐇 Добыча собрана! (+1 🥩 Сочный стейк)")
			print(string.format("🐇 %s забрал пойманную дичь из капкана!", triggerPlayer.Name))

		elseif not isArmed then
			trapModel:SetAttribute("IsArmed", true)
			statusLight.BrickColor = BrickColor.new("Bright green")
			prompt.ActionText = "Взведен (Ожидание дичи...)"
			ShowNotificationRemote:FireClient(triggerPlayer, "⚙️ Капкан снова взведен и готов к охоте!")
		else
			local picked = false
			if _G.GiveItemToPlayer then
				picked = _G.GiveItemToPlayer(triggerPlayer, "RabbitTrap", 1)
			else
				local giveBindable = ReplicatedStorage:FindFirstChild("GiveItem")
				if giveBindable and giveBindable:IsA("BindableFunction") then
					picked = giveBindable:Invoke(triggerPlayer, "RabbitTrap", 1)
				end
			end
			if picked then
				trapModel:Destroy()
				ShowNotificationRemote:FireClient(triggerPlayer, "🪤 Капкан убран в рюкзак.")
			else
				ShowNotificationRemote:FireClient(triggerPlayer, "⚠️ Рюкзак полон! Освободите место.")
			end
		end

	end)

	-- Автономный цикл охоты на дичь в лесу
	task.spawn(function()
		while trapModel and trapModel.Parent do
			local waitTime = math.random(45, 60)
			task.wait(waitTime)

			if trapModel and trapModel.Parent and trapModel:GetAttribute("IsArmed") and not trapModel:GetAttribute("HasPrey") then
				trapModel:SetAttribute("HasPrey", true)
				trapModel:SetAttribute("IsArmed", false)
				statusLight.BrickColor = BrickColor.new("Bright yellow")
				prompt.ActionText = "Забрать дичь (+1 🥩 Стейк)"
				prompt.ObjectText = "🐇 [ПОЙМАН ЗАЯЦ!]"
			end
		end
	end)
end

-- 2. Создание 3D модели Шипастого Пола (SpikeTrap) с прочностью 10 и починкой за 3 детали
local function spawnPlacedSpikeTrap(ownerPlayer, spawnPos)
	local trapModel = Instance.new("Model")
	trapModel.Name = "ActiveSpikeTrap"
	trapModel:SetAttribute("TrapType", "SpikeTrap")
	trapModel:SetAttribute("Durability", 10)
	trapModel:SetAttribute("MaxDurability", 10)
	trapModel:SetAttribute("IsBroken", false)
	trapModel:SetAttribute("Damage", 25)
	trapModel:SetAttribute("OwnerUserId", ownerPlayer and ownerPlayer.UserId or 0)

	-- Деревянная платформа основания
	local base = Instance.new("Part")
	base.Name = "Base"
	base.Size = Vector3.new(6.0, 0.4, 6.0)
	base.Position = spawnPos + Vector3.new(0, 0.2, 0)
	base.Anchored = true
	base.CanCollide = false
	base.Material = Enum.Material.WoodPlanks
	base.BrickColor = BrickColor.new("Dark orange")
	base.Parent = trapModel
	trapModel.PrimaryPart = base

	-- Металлические шипы
	local spikesFolder = Instance.new("Folder")
	spikesFolder.Name = "Spikes"
	spikesFolder.Parent = trapModel

	for x = -2, 2, 2 do
		for z = -2, 2, 2 do
			local spike = Instance.new("Part")
			spike.Name = "Spike"
			spike.Size = Vector3.new(0.35, 1.6, 0.35)
			spike.Position = base.Position + Vector3.new(x, 0.9, z)
			spike.Anchored = true
			spike.CanCollide = false
			spike.Material = Enum.Material.Metal
			spike.BrickColor = BrickColor.new("Medium stone grey")
			spike.Parent = spikesFolder
		end
	end

	-- Индикатор состояния
	local statusLight = Instance.new("Part")
	statusLight.Name = "StatusLight"
	statusLight.Size = Vector3.new(0.5, 0.5, 0.5)
	statusLight.Position = base.Position + Vector3.new(0, 0.4, 0)
	statusLight.Anchored = true
	statusLight.CanCollide = false
	statusLight.Material = Enum.Material.Neon
	statusLight.BrickColor = BrickColor.new("Bright green")
	statusLight.Parent = trapModel

	-- Дым поломки
	local smoke = Instance.new("Smoke", statusLight)
	smoke.Name = "BrokenSmoke"
	smoke.Size = 2
	smoke.Color = Color3.fromRGB(80, 80, 80)
	smoke.Opacity = 0.5
	smoke.Enabled = false

	trapModel.Parent = TrapsFolder

	local prompt = Instance.new("ProximityPrompt", base)
	prompt.ActionText = "Прочность: 10/10"
	prompt.ObjectText = "📌 Шипастый Пол"
	prompt.HoldDuration = 0.5
	prompt.MaxActivationDistance = 10
	prompt.RequiresLineOfSight = false

	local function updatePrompt()
		local isBroken = trapModel:GetAttribute("IsBroken")
		local curDur = trapModel:GetAttribute("Durability") or 10

		if isBroken then
			prompt.ObjectText = "🛠️ Сломанный шипастый пол"
			prompt.ActionText = "Починить (Требуется: 3 ⚙️ Детали)"
			statusLight.BrickColor = BrickColor.new("Bright red")
			smoke.Enabled = true
			for _, sp in ipairs(spikesFolder:GetChildren()) do
				sp.BrickColor = BrickColor.new("Black")
			end
		else
			prompt.ObjectText = "📌 Шипастый Пол"
			prompt.ActionText = string.format("Прочность: %d/10", curDur)
			statusLight.BrickColor = (curDur <= 3) and BrickColor.new("Bright yellow") or BrickColor.new("Bright green")
			smoke.Enabled = false
			for _, sp in ipairs(spikesFolder:GetChildren()) do
				sp.BrickColor = BrickColor.new("Medium stone grey")
			end
		end
	end

	-- Взаимодействие (Починка)
	prompt.Triggered:Connect(function(triggerPlayer)
		local isBroken = trapModel:GetAttribute("IsBroken")
		local curDur = trapModel:GetAttribute("Durability") or 10

		if isBroken or curDur < 10 then
			local parts = triggerPlayer:GetAttribute("Parts") or 0
			if parts >= 3 then
				triggerPlayer:SetAttribute("Parts", parts - 3)
				trapModel:SetAttribute("Durability", 10)
				trapModel:SetAttribute("IsBroken", false)
				updatePrompt()
				ShowNotificationRemote:FireClient(triggerPlayer, "🔧 Шипастый пол починен! (10/10 прочности, -3 ⚙️)")
				print(string.format("🔧 %s починил шипастый пол (-3 ⚙️)!", triggerPlayer.Name))
			else
				ShowNotificationRemote:FireClient(triggerPlayer, string.format("❌ Недостаточно деталей! Нужно 3 ⚙️ (у вас: %d)", parts))
			end
		else
			ShowNotificationRemote:FireClient(triggerPlayer, "📌 Шипастый пол полностью исправен (10/10).")
		end
	end)

	trapModel:SetAttribute("UpdateVisuals", updatePrompt)
	return trapModel
end

-- Обработка установки капкана или шипов из рук
_G.PlaceTrapFromHand = function(player, itemKey, toolInstance)
	local char = player.Character
	if not char or not char:FindFirstChild("HumanoidRootPart") then return end

	local hrp = char.HumanoidRootPart
	local placePos = (hrp.CFrame * CFrame.new(0, -2.5, -5)).Position

	-- Проверка высоты рельефа
	local ray = workspace:Raycast(placePos + Vector3.new(0, 10, 0), Vector3.new(0, -20, 0))
	if ray then
		placePos = ray.Position
	end

	if itemKey == "RabbitTrap" then
		spawnPlacedRabbitTrap(player, placePos)
		ShowNotificationRemote:FireClient(player, "🪤 Капкан установлен на снег! (Ожидайте дичь или заманивайте волков)")
	elseif itemKey == "SpikeTrap" then
		spawnPlacedSpikeTrap(player, placePos)
		ShowNotificationRemote:FireClient(player, "📌 Шипастый пол установлен! (10 ударов прочности, ремонт: 3 ⚙️)")
	end

	-- Уменьшаем количество в руках
	local count = toolInstance:GetAttribute("Count") or 1
	if count > 1 then
		toolInstance:SetAttribute("Count", count - 1)
		toolInstance.Name = string.format("%s (x%d)", itemKey == "SpikeTrap" and "📌 Шипы" or "🪤 Капкан", count - 1)
	else
		toolInstance:Destroy()
	end
end

-- Кулдаун ударов для каждого моба по шипам
local mobHitCooldowns = {}

-- Мониторинг мобов для Капканов и Шипов (каждые 0.3с)
task.spawn(function()
	while true do
		task.wait(0.3)
		local mobsFolder = workspace:FindFirstChild("Mobs")
		if mobsFolder then
			for _, trap in ipairs(TrapsFolder:GetChildren()) do
				local trapType = trap:GetAttribute("TrapType")
				local primaryPart = trap.PrimaryPart

				if primaryPart and trap.Parent then
					local trapPos = primaryPart.Position

					-- А) Обработка Капкана (RabbitTrap)
					if trapType == "RabbitTrap" and trap:GetAttribute("IsArmed") and not trap:GetAttribute("HasPrey") then
						for _, mob in ipairs(mobsFolder:GetChildren()) do
							local mHrp = mob:FindFirstChild("HumanoidRootPart")
							local mHum = mob:FindFirstChild("Humanoid")
							if mHrp and mHum and mHum.Health > 0 then
								local dist = (mHrp.Position - trapPos).Magnitude
								if dist <= 3.2 then
									trap:SetAttribute("IsArmed", false)
									local statusLight = trap:FindFirstChild("StatusLight")
									if statusLight then statusLight.BrickColor = BrickColor.new("Bright red") end

									mHum:TakeDamage(40)
									mHrp.Anchored = true
									task.delay(3.0, function()
										if mHrp and mHrp.Parent then mHrp.Anchored = false end
									end)

									local prompt = primaryPart:FindFirstChildOfClass("ProximityPrompt")
									if prompt then
										prompt.ActionText = "Взвести капкан заново"
										prompt.ObjectText = "🪤 [Сработал на зверя]"
									end
									print(string.format("💥 Моб %s наступил в капкан и получил 40 урона!", mob.Name))
									break
								end
							end
						end

					-- Б) Обработка Шипастого Пола (SpikeTrap)
					elseif trapType == "SpikeTrap" and not trap:GetAttribute("IsBroken") then
						local curDur = trap:GetAttribute("Durability") or 10

						if curDur > 0 then
							for _, mob in ipairs(mobsFolder:GetChildren()) do
								local mHrp = mob:FindFirstChild("HumanoidRootPart")
								local mHum = mob:FindFirstChild("Humanoid")
								if mHrp and mHum and mHum.Health > 0 then
									local dist = (mHrp.Position - trapPos).Magnitude
									if dist <= 4.2 then
										local cdKey = tostring(trap) .. "_" .. tostring(mob)
										local now = os.clock()
										if not mobHitCooldowns[cdKey] or (now - mobHitCooldowns[cdKey] >= 1.0) then
											mobHitCooldowns[cdKey] = now

											-- Наносим 25 урона мобу и замедляем
											mHum:TakeDamage(25)
											local origSpeed = mHum.WalkSpeed
											mHum.WalkSpeed = math.max(1, origSpeed * 0.4)
											task.delay(1.5, function()
												if mHum and mHum.Parent then
													mHum.WalkSpeed = origSpeed
												end
											end)

											-- Снижаем прочность шипов на 1
											curDur = math.max(0, curDur - 1)
											trap:SetAttribute("Durability", curDur)

											local prompt = primaryPart:FindFirstChildOfClass("ProximityPrompt")
											local statusLight = trap:FindFirstChild("StatusLight")
											local smoke = statusLight and statusLight:FindFirstChild("BrokenSmoke")

											if curDur <= 0 then
												trap:SetAttribute("IsBroken", true)
												if prompt then
													prompt.ObjectText = "🛠️ Сломанный шипастый пол"
													prompt.ActionText = "Починить (Требуется: 3 ⚙️ Детали)"
												end
												if statusLight then statusLight.BrickColor = BrickColor.new("Bright red") end
												if smoke then smoke.Enabled = true end
												local spikesFolder = trap:FindFirstChild("Spikes")
												if spikesFolder then
													for _, sp in ipairs(spikesFolder:GetChildren()) do
														sp.BrickColor = BrickColor.new("Black")
													end
												end
												print("💥 Шипастый пол полностью сломался от износа (10/10 срабатываний)!")
												break
											else
												if prompt then
													prompt.ActionText = string.format("Прочность: %d/10", curDur)
												end
												if statusLight then
													statusLight.BrickColor = (curDur <= 3) and BrickColor.new("Bright yellow") or BrickColor.new("Bright green")
												end
												print(string.format("📌 Шипы задели моба %s! (Осталось прочности: %d/10)", mob.Name, curDur))
											end
										end
									end
								end
							end
						end
					end
				end
			end
		end
	end
end)

print("🪤 [TrapService] Система охотничьих капканов и шипастых полов готова!")
