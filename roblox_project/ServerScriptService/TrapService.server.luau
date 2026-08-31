--[[
    TrapService.server.luau
    Серверная система Охотничьих Капканов (RabbitTrap):
    - 🛠️ Установка из рук по клику ЛКМ на снег
    - 🐇 Авто-ловля зайцев: каждые 45-60 секунд капкан ловит дичь (+1 🥩 Стейк / +1 🌱 Волокно)
    - 🐺 Ловушка для мобов: наносит 40 урона наступившему волку/йети и обездвиживает
    - 📦 Забор капкана обратно в рюкзак
--]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local TrapsFolder = workspace:FindFirstChild("PlacedTraps") or Instance.new("Folder", workspace)
TrapsFolder.Name = "PlacedTraps"

local RemotesFolder = ReplicatedStorage:FindFirstChild("Remotes") or Instance.new("Folder", ReplicatedStorage)
local ShowNotificationRemote = RemotesFolder:FindFirstChild("ShowNotification") or Instance.new("RemoteEvent", RemotesFolder)
ShowNotificationRemote.Name = "ShowNotification"

-- Функция создания 3D модели капкана в мире
local function spawnPlacedTrap(ownerPlayer, spawnPos)
	local trapModel = Instance.new("Model")
	trapModel.Name = "ActiveHunterTrap"

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

	-- Челюсти капкана (зубья)
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

	-- Неоновый индикатор взвода (Зеленый = взведен, Желтый = поймана дичь, Красный = сработал на монстра)
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
			-- Забираем пойманную дичь
			if _G.GiveItemToPlayer then
				_G.GiveItemToPlayer(triggerPlayer, "Steak", 1)
			end
			trapModel:SetAttribute("HasPrey", false)
			trapModel:SetAttribute("IsArmed", true)
			statusLight.BrickColor = BrickColor.new("Bright green")
			prompt.ActionText = "Взведен (Ожидание дичи...)"
			prompt.ObjectText = "🪤 Охотничий капкан"

			ShowNotificationRemote:FireClient(triggerPlayer, "🐇 Добыча собрана! (+1 🥩 Сочный стейк)")
			print(string.format("🐇 %s забрал пойманную дичь из капкана!", triggerPlayer.Name))

		elseif not isArmed then
			-- Повторно взводим сработавший капкан
			trapModel:SetAttribute("IsArmed", true)
			statusLight.BrickColor = BrickColor.new("Bright green")
			prompt.ActionText = "Взведен (Ожидание дичи...)"
			ShowNotificationRemote:FireClient(triggerPlayer, "⚙️ Капкан снова взведен и готов к охоте!")
		else
			-- Если капкан пуст и взведен -> подбираем сам капкан в рюкзак
			if _G.GiveItemToPlayer then
				local picked = _G.GiveItemToPlayer(triggerPlayer, "RabbitTrap", 1)
				if picked then
					trapModel:Destroy()
					ShowNotificationRemote:FireClient(triggerPlayer, "🪤 Капкан убран в рюкзак.")
				end
			end
		end
	end)

	-- Автономный цикл охоты на дичь в лесу (каждые 45-60 секунд)
	task.spawn(function()
		while trapModel and trapModel.Parent do
			local waitTime = math.random(45, 60)
			task.wait(waitTime)

			if trapModel and trapModel.Parent and trapModel:GetAttribute("IsArmed") and not trapModel:GetAttribute("HasPrey") then
				-- Успешная поимка дичи!
				trapModel:SetAttribute("HasPrey", true)
				trapModel:SetAttribute("IsArmed", false)
				statusLight.BrickColor = BrickColor.new("Bright yellow")
				prompt.ActionText = "Забрать дичь (+1 🥩 Стейк)"
				prompt.ObjectText = "🐇 [ПОЙМАН ЗАЯЦ!]"
			end
		end
	end)
end

-- Обработка установки капкана из рук
_G.PlaceTrapFromHand = function(player, itemKey, toolInstance)
	local char = player.Character
	if not char or not char:FindFirstChild("HumanoidRootPart") then return end

	local hrp = char.HumanoidRootPart
	local placePos = (hrp.CFrame * CFrame.new(0, -2.5, -4)).Position

	-- Проверка высоты рельефа
	local ray = workspace:Raycast(placePos + Vector3.new(0, 10, 0), Vector3.new(0, -20, 0))
	if ray then
		placePos = ray.Position
	end

	spawnPlacedTrap(player, placePos)

	-- Уменьшаем количество в руках
	local count = toolInstance:GetAttribute("Count") or 1
	if count > 1 then
		toolInstance:SetAttribute("Count", count - 1)
		toolInstance.Name = string.format("🪤 Капкан (x%d)", count - 1)
	else
		toolInstance:Destroy()
	end

	ShowNotificationRemote:FireClient(player, "🪤 Капкан установлен на снег! (Ожидайте дичь или заманивайте волков)")
end

-- Мониторинг мобов, наступающих на капкан (каждые 0.5с)
task.spawn(function()
	while true do
		task.wait(0.5)
		local mobsFolder = workspace:FindFirstChild("Mobs")
		if mobsFolder then
			for _, trap in ipairs(TrapsFolder:GetChildren()) do
				if trap:GetAttribute("IsArmed") and not trap:GetAttribute("HasPrey") and trap.PrimaryPart then
					local trapPos = trap.PrimaryPart.Position
					for _, mob in ipairs(mobsFolder:GetChildren()) do
						local mHrp = mob:FindFirstChild("HumanoidRootPart")
						local mHum = mob:FindFirstChild("Humanoid")
						if mHrp and mHum and mHum.Health > 0 then
							local dist = (mHrp.Position - trapPos).Magnitude
							if dist <= 3.2 then
								-- Моб попался в капкан!
								trap:SetAttribute("IsArmed", false)
								local statusLight = trap:FindFirstChild("StatusLight")
								if statusLight then statusLight.BrickColor = BrickColor.new("Bright red") end

								mHum:TakeDamage(40)
								mHrp.Anchored = true
								task.delay(3.0, function()
									if mHrp and mHrp.Parent then mHrp.Anchored = false end
								end)

								local prompt = trap.PrimaryPart:FindFirstChildOfClass("ProximityPrompt")
								if prompt then
									prompt.ActionText = "Взвести капкан заново"
									prompt.ObjectText = "🪤 [Сработал на зверя]"
								end
								print(string.format("💥 Моб %s наступил в капкан и получил 40 урона!", mob.Name))
								break
							end
						end
					end
				end
			end
		end
	end
end)

print("🪤 [TrapService] Система охотничьих капканов готова!")
