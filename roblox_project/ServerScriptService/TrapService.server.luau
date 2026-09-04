--[[
    TrapService.server.luau
    Серверная система Охотничьих Капканов (RabbitTrap) и Шипастого Пола (SpikeTrap):
    - В руках 1 шт:
      * Клик ЛКМ -> заряженный ставится на землю/снег.
      * Нажатие G -> выбрасывается просто так на землю как незаряженный дроп-предмет.
    - Стоит на земле заряжен:
      * ЕДИНСТВЕННАЯ опция взаимодействия по [E] -> "Взять в рюкзак" (убирается в рюкзак).
      * Если капкан поймал зайца -> по [E] забирается дичь (+1 Стейк) и капкан возвращается в рюкзак.
--]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local TweenService = game:GetService("TweenService")

local TrapsFolder = workspace:FindFirstChild("PlacedTraps") or Instance.new("Folder", workspace)
TrapsFolder.Name = "PlacedTraps"

local RemotesFolder = ReplicatedStorage:FindFirstChild("Remotes") or Instance.new("Folder", ReplicatedStorage)
local ShowNotificationRemote = RemotesFolder:FindFirstChild("ShowNotification") or Instance.new("RemoteEvent", RemotesFolder)
ShowNotificationRemote.Name = "ShowNotification"

local ModelHelper = require(ReplicatedStorage:WaitForChild("ModelHelper", 10))

-- 1. Создание 3D модели Капкана (RabbitTrap)
local function spawnPlacedRabbitTrap(ownerPlayer, spawnPos)
	local template = ModelHelper.findTemplate("rabbittrap")
	local trapModel = nil

	if template then
		trapModel = (template.Parent == nil) and template or template:Clone()
	else
		local genMod = ReplicatedStorage:FindFirstChild("GeneratedModels")
		if genMod and genMod:FindFirstChild("RabbitTrap") then
			trapModel = require(genMod.RabbitTrap).create(nil)
		end
	end

	if not trapModel then
		trapModel = Instance.new("Model")
	end

	trapModel.Name = "PlacedRabbitTrap"
	trapModel:SetAttribute("TrapType", "RabbitTrap")
	trapModel:SetAttribute("IsArmed", true)
	trapModel:SetAttribute("HasPrey", false)
	trapModel:SetAttribute("OwnerUserId", ownerPlayer and ownerPlayer.UserId or 0)

	-- Обеспечиваем PrimaryPart
	local primary = trapModel.PrimaryPart or trapModel:FindFirstChild("Crate") or trapModel:FindFirstChildWhichIsA("BasePart")
	if not primary then
		primary = Instance.new("Part")
		primary.Name = "RootPart"
		primary.Size = Vector3.new(1.6, 0.4, 1.4)
		primary.Transparency = 1
		primary.CanCollide = false
		primary.Parent = trapModel
	end
	trapModel.PrimaryPart = primary

	-- Позиционируем на снегу
	trapModel:PivotTo(CFrame.new(spawnPos + Vector3.new(0, 0.25, 0)))
	for _, desc in ipairs(trapModel:GetDescendants()) do
		if desc:IsA("BasePart") then
			desc.Anchored = true
			desc.CanCollide = false
		end
	end
	trapModel.Parent = TrapsFolder

	local crate = trapModel:FindFirstChild("Crate")
	local stick = trapModel:FindFirstChild("PropStick")
	local carrot = trapModel:FindFirstChild("Carrot")
	local greens = trapModel:FindFirstChild("CarrotGreens")

	local armedCrateCF = crate and crate.CFrame or primary.CFrame
	local disarmedCrateCF = armedCrateCF * CFrame.new(0, -0.28, 0) * CFrame.Angles(math.rad(22), 0, 0)

	local armedStickCF = stick and stick.CFrame or nil
	local disarmedStickCF = armedStickCF and (armedStickCF * CFrame.new(0, -0.25, 0.25) * CFrame.Angles(math.rad(75), 0, 0)) or nil

	-- Единственный ProximityPrompt взаимодействия: [E] Взять в рюкзак
	local prompt = Instance.new("ProximityPrompt", primary)
	prompt.Name = "PromptPickup"
	prompt.KeyboardKeyCode = Enum.KeyCode.E
	prompt.ActionText = "Взять в рюкзак"
	prompt.ObjectText = "🪤 Капкан (Заряжен)"
	prompt.HoldDuration = 0
	prompt.MaxActivationDistance = 10
	prompt.RequiresLineOfSight = false

	local function updateVisualState(animate)
		local isArmed = trapModel:GetAttribute("IsArmed")
		local hasPrey = trapModel:GetAttribute("HasPrey")

		if hasPrey then
			if crate then
				if animate then
					TweenService:Create(crate, TweenInfo.new(0.25, Enum.EasingStyle.Bounce, Enum.EasingDirection.Out), {CFrame = disarmedCrateCF}):Play()
				else
					crate.CFrame = disarmedCrateCF
				end
			end
			if stick and disarmedStickCF then
				if animate then
					TweenService:Create(stick, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {CFrame = disarmedStickCF}):Play()
				else
					stick.CFrame = disarmedStickCF
				end
			end
			if carrot then carrot.Transparency = 1 end
			if greens then greens.Transparency = 1 end

			prompt.ObjectText = "🐇 [ПОЙМАН ЗАЯЦ!]"
			prompt.ActionText = "Забрать дичь и капкан (+1 🥩)"
		elseif isArmed then
			if crate then
				if animate then
					TweenService:Create(crate, TweenInfo.new(0.35, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {CFrame = armedCrateCF}):Play()
				else
					crate.CFrame = armedCrateCF
				end
			end
			if stick and armedStickCF then
				if animate then
					TweenService:Create(stick, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {CFrame = armedStickCF}):Play()
				else
					stick.CFrame = armedStickCF
				end
				stick.Transparency = 0
			end
			if carrot then carrot.Transparency = 0 end
			if greens then greens.Transparency = 0 end

			prompt.ObjectText = "🪤 Капкан (Заряжен)"
			prompt.ActionText = "Взять в рюкзак"
		else
			if crate then
				if animate then
					TweenService:Create(crate, TweenInfo.new(0.2, Enum.EasingStyle.Bounce, Enum.EasingDirection.Out), {CFrame = disarmedCrateCF}):Play()
				else
					crate.CFrame = disarmedCrateCF
				end
			end
			if stick and disarmedStickCF then
				if animate then
					TweenService:Create(stick, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {CFrame = disarmedStickCF}):Play()
				else
					stick.CFrame = disarmedStickCF
				end
				stick.Transparency = 0.5
			end
			if carrot then carrot.Transparency = 1 end
			if greens then greens.Transparency = 1 end

			prompt.ObjectText = "🪤 Капкан (Сработал)"
			prompt.ActionText = "Взять в рюкзак"
		end
	end

	-- Взаимодействие [E]: забрать в рюкзак (и забрать стейк, если заяц внутри)
	prompt.Triggered:Connect(function(triggerPlayer)
		local hasPrey = trapModel:GetAttribute("HasPrey")

		if hasPrey then
			if _G.GiveItemToPlayer then
				_G.GiveItemToPlayer(triggerPlayer, "Steak", 1)
			else
				local giveBindable = ReplicatedStorage:FindFirstChild("GiveItem")
				if giveBindable and giveBindable:IsA("BindableFunction") then
					giveBindable:Invoke(triggerPlayer, "Steak", 1)
				end
			end
		end

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
			if hasPrey then
				ShowNotificationRemote:FireClient(triggerPlayer, "🐇 Добыча (+1 🥩 Стейк) и капкан убраны в рюкзак!")
			else
				ShowNotificationRemote:FireClient(triggerPlayer, "🪤 Капкан убран в рюкзак!")
			end
			print(string.format("🪤 %s забрал капкан в рюкзак.", triggerPlayer.Name))
		else
			ShowNotificationRemote:FireClient(triggerPlayer, "⚠️ Рюкзак полон! Освободите место, чтобы забрать капкан.")
		end
	end)

	-- Автономный цикл ловли зайцев в лесу (каждые 35-50 сек)
	task.spawn(function()
		while trapModel and trapModel.Parent do
			local waitTime = math.random(35, 50)
			task.wait(waitTime)

			if trapModel and trapModel.Parent and trapModel:GetAttribute("IsArmed") and not trapModel:GetAttribute("HasPrey") then
				trapModel:SetAttribute("HasPrey", true)
				trapModel:SetAttribute("IsArmed", false)
				updateVisualState(true)
			end
		end
	end)

	trapModel:SetAttribute("UpdateVisuals", updateVisualState)
	return trapModel
end

-- 2. Создание 3D модели Шипастого Пола (SpikeTrap)
local function spawnPlacedSpikeTrap(ownerPlayer, spawnPos)
	local template = ModelHelper.findTemplate("spiketrap")
	local trapModel = nil

	if template then
		trapModel = (template.Parent == nil) and template or template:Clone()
	else
		local genMod = ReplicatedStorage:FindFirstChild("GeneratedModels")
		if genMod and genMod:FindFirstChild("SpikeTrap") then
			trapModel = require(genMod.SpikeTrap).create(nil)
		end
	end

	if not trapModel then
		trapModel = Instance.new("Model")
	end

	trapModel.Name = "PlacedSpikeTrap"
	trapModel:SetAttribute("TrapType", "SpikeTrap")
	trapModel:SetAttribute("Durability", 10)
	trapModel:SetAttribute("MaxDurability", 10)
	trapModel:SetAttribute("IsBroken", false)
	trapModel:SetAttribute("Damage", 25)
	trapModel:SetAttribute("OwnerUserId", ownerPlayer and ownerPlayer.UserId or 0)

	local primary = trapModel.PrimaryPart or trapModel:FindFirstChild("BaseFrame") or trapModel:FindFirstChildWhichIsA("BasePart")
	if not primary then
		primary = Instance.new("Part")
		primary.Name = "Base"
		primary.Size = Vector3.new(3.0, 0.4, 3.0)
		primary.Transparency = 1
		primary.CanCollide = false
		primary.Parent = trapModel
	end
	trapModel.PrimaryPart = primary

	trapModel:PivotTo(CFrame.new(spawnPos + Vector3.new(0, 0.15, 0)))
	for _, desc in ipairs(trapModel:GetDescendants()) do
		if desc:IsA("BasePart") then
			desc.Anchored = true
			desc.CanCollide = false
		end
	end
	trapModel.Parent = TrapsFolder

	-- Единственный ProximityPrompt взаимодействия: [E] Взять в рюкзак
	local prompt = Instance.new("ProximityPrompt", primary)
	prompt.Name = "PromptPickup"
	prompt.KeyboardKeyCode = Enum.KeyCode.E
	prompt.ActionText = "Взять в рюкзак"
	prompt.ObjectText = "📌 Шипастый Пол (Заряжен)"
	prompt.HoldDuration = 0
	prompt.MaxActivationDistance = 10
	prompt.RequiresLineOfSight = false

	local function updatePrompt()
		local isBroken = trapModel:GetAttribute("IsBroken")
		local curDur = trapModel:GetAttribute("Durability") or 10

		if isBroken then
			prompt.ObjectText = "📌 Сломанный шипастый пол (0/10)"
			prompt.ActionText = "Взять в рюкзак"
		else
			prompt.ObjectText = string.format("📌 Шипастый Пол (Заряжен: %d/10)", curDur)
			prompt.ActionText = "Взять в рюкзак"
		end
	end

	-- Взаимодействие [E]: забрать шипы в рюкзак
	prompt.Triggered:Connect(function(triggerPlayer)
		local picked = false
		if _G.GiveItemToPlayer then
			picked = _G.GiveItemToPlayer(triggerPlayer, "SpikeTrap", 1)
		else
			local giveBindable = ReplicatedStorage:FindFirstChild("GiveItem")
			if giveBindable and giveBindable:IsA("BindableFunction") then
				picked = giveBindable:Invoke(triggerPlayer, "SpikeTrap", 1)
			end
		end

		if picked then
			trapModel:Destroy()
			ShowNotificationRemote:FireClient(triggerPlayer, "📌 Шипастый пол убран в рюкзак!")
			print(string.format("📌 %s забрал шипастый пол в рюкзак.", triggerPlayer.Name))
		else
			ShowNotificationRemote:FireClient(triggerPlayer, "⚠️ Рюкзак полон! Освободите место.")
		end
	end)

	trapModel:SetAttribute("UpdateVisuals", updatePrompt)
	return trapModel
end

-- 3. Создание 3D модели Походного костра (CampfireKit)
local function spawnPlacedCampfire(ownerPlayer, spawnPos)
	local template = ModelHelper.findTemplate("campfire")
	local campfireModel = nil

	if template then
		campfireModel = (template.Parent == nil) and template or template:Clone()
	else
		local genMod = ReplicatedStorage:FindFirstChild("GeneratedModels")
		if genMod and genMod:FindFirstChild("Campfire") then
			campfireModel = require(genMod.Campfire).create(nil)
		end
	end

	if not campfireModel then
		campfireModel = Instance.new("Model")
	end

	campfireModel.Name = "Campfire"
	campfireModel:SetAttribute("FuelSeconds", 120) -- 2 минуты стартового горения
	campfireModel:SetAttribute("MaxFuel", 600)
	campfireModel:SetAttribute("HeatRadius", 35)
	campfireModel:SetAttribute("IsBurning", true)
	campfireModel:SetAttribute("OwnerUserId", ownerPlayer and ownerPlayer.UserId or 0)

	local primary = campfireModel.PrimaryPart or campfireModel:FindFirstChild("Embers") or campfireModel:FindFirstChildWhichIsA("BasePart")
	if not primary then
		primary = Instance.new("Part")
		primary.Name = "Base"
		primary.Size = Vector3.new(2.0, 0.4, 2.0)
		primary.Transparency = 1
		primary.CanCollide = false
		primary.Parent = campfireModel
	end
	campfireModel.PrimaryPart = primary

	campfireModel:PivotTo(CFrame.new(spawnPos + Vector3.new(0, 0.1, 0)))
	for _, desc in ipairs(campfireModel:GetDescendants()) do
		if desc:IsA("BasePart") then
			desc.Anchored = true
			desc.CanCollide = false
		end
	end

	local HeatSourcesFolder = workspace:FindFirstChild("HeatSources") or Instance.new("Folder", workspace)
	HeatSourcesFolder.Name = "HeatSources"
	campfireModel.Parent = HeatSourcesFolder

	-- Light & Flame
	local light = primary:FindFirstChildOfClass("PointLight") or Instance.new("PointLight", primary)
	light.Color = Color3.fromRGB(255, 150, 50)
	light.Range = 16
	light.Brightness = 0.6

	local fire = primary:FindFirstChildOfClass("Fire") or Instance.new("Fire", primary)
	fire.Size = 4
	fire.Heat = 9

	-- Prompt [E] Добавить ветку (+60 сек)
	local promptAction = Instance.new("ProximityPrompt", primary)
	promptAction.Name = "PromptAction"
	promptAction.KeyboardKeyCode = Enum.KeyCode.E
	promptAction.ActionText = "Подкинуть ветку (+60 сек)"
	promptAction.ObjectText = "🔥 Походный костер"
	promptAction.HoldDuration = 0
	promptAction.MaxActivationDistance = 10
	promptAction.RequiresLineOfSight = false
	promptAction:SetAttribute("Bound", true)

	-- Prompt [F] Забрать костер в рюкзак
	local promptPickup = Instance.new("ProximityPrompt", primary)
	promptPickup.Name = "PromptPickup"
	promptPickup.KeyboardKeyCode = Enum.KeyCode.F
	promptPickup.ActionText = "Забрать костер в рюкзак"
	promptPickup.ObjectText = "🎒 Снять костер"
	promptPickup.HoldDuration = 0.3
	promptPickup.MaxActivationDistance = 10
	promptPickup.RequiresLineOfSight = false

	promptAction.Triggered:Connect(function(triggerPlayer)
		local char = triggerPlayer.Character
		local equippedTool = nil

		if char then
			for _, child in ipairs(char:GetChildren()) do
				if child:IsA("Tool") and (child:GetAttribute("ItemKey") == "Branches" or string.find(string.lower(child.Name), "ветк") or string.find(string.lower(child.Name), "branch")) then
					equippedTool = child
					break
				end
			end
		end

		if not equippedTool then
			ShowNotificationRemote:FireClient(triggerPlayer, "⚠️ Возьмите 🌿 Ветки в руки, чтобы подбросить в огонь!")
			return
		end

		local curCount = equippedTool:GetAttribute("Count") or 1
		if curCount > 1 then
			equippedTool:SetAttribute("Count", curCount - 1)
			equippedTool.Name = string.format("🌿 Ветки (x%d)", curCount - 1)
		else
			equippedTool:Destroy()
		end

		local totalBranches = triggerPlayer:GetAttribute("Branches") or 0
		triggerPlayer:SetAttribute("Branches", math.max(0, totalBranches - 1))

		local curFuel = campfireModel:GetAttribute("FuelSeconds") or 0
		local maxFuel = campfireModel:GetAttribute("MaxFuel") or 600
		local bonusFuel = workspace:GetAttribute("CampfireTimeBonus") or 0
		local newFuel = math.min(maxFuel, curFuel + 60 + bonusFuel)

		campfireModel:SetAttribute("FuelSeconds", newFuel)
		campfireModel:SetAttribute("IsBurning", true)
		fire.Enabled = true
		light.Enabled = true

		ShowNotificationRemote:FireClient(triggerPlayer, string.format("🪵 Ветка из рук брошена в огонь! (+%dс горения | Всего: %02d:%02d)", 60 + bonusFuel, math.floor(newFuel / 60), newFuel % 60))
	end)

	promptPickup.Triggered:Connect(function(triggerPlayer)
		local picked = false
		if _G.GiveItemToPlayer then
			picked = _G.GiveItemToPlayer(triggerPlayer, "CampfireKit", 1)
		else
			local giveBindable = ReplicatedStorage:FindFirstChild("GiveItem")
			if giveBindable and giveBindable:IsA("BindableFunction") then
				picked = giveBindable:Invoke(triggerPlayer, "CampfireKit", 1)
			end
		end

		if picked then
			campfireModel:Destroy()
			ShowNotificationRemote:FireClient(triggerPlayer, "🔥 Походный костер убран в рюкзак!")
		else
			ShowNotificationRemote:FireClient(triggerPlayer, "⚠️ Рюкзак полон! Освободите место.")
		end
	end)

	return campfireModel
end

-- Обработка установки капкана, шипов или костра из рук (ЛКМ)
_G.PlaceTrapFromHand = function(player, itemKey, toolInstance)
	if not player or not toolInstance or not toolInstance.Parent then return end
	if toolInstance:GetAttribute("IsPlacing") then return end

	local char = player.Character
	if not char or not char:FindFirstChild("HumanoidRootPart") then return end

	toolInstance:SetAttribute("IsPlacing", true)

	local hrp = char.HumanoidRootPart
	local placePos = (hrp.CFrame * CFrame.new(0, -2.5, -5)).Position

	local ray = workspace:Raycast(placePos + Vector3.new(0, 10, 0), Vector3.new(0, -20, 0))
	if ray then
		placePos = ray.Position
	end

	if itemKey == "RabbitTrap" then
		spawnPlacedRabbitTrap(player, placePos)
		ShowNotificationRemote:FireClient(player, "🪤 Капкан установлен и заряжен! (Нажмите [E], чтобы убрать в рюкзак)")
	elseif itemKey == "SpikeTrap" then
		spawnPlacedSpikeTrap(player, placePos)
		ShowNotificationRemote:FireClient(player, "📌 Шипастый пол установлен и заряжен! (Нажмите [E], чтобы убрать в рюкзак)")
	elseif itemKey == "CampfireKit" then
		spawnPlacedCampfire(player, placePos)
		ShowNotificationRemote:FireClient(player, "🔥 Походный костер разбит! (Положите 🌿 Ветки для горения)")
	end

	-- 1. Уменьшаем числовой атрибут у игрока
	local totalAttr = player:GetAttribute(itemKey) or 0
	if totalAttr > 0 then
		player:SetAttribute(itemKey, math.max(0, totalAttr - 1))
	end

	-- 2. Уменьшаем количество в руках или удаляем Tool
	local count = toolInstance:GetAttribute("Count") or 1
	if count > 1 then
		local newCount = count - 1
		toolInstance:SetAttribute("Count", newCount)
		toolInstance:SetAttribute("IsPlacing", false)
		local displayName = (itemKey == "SpikeTrap" and "📌 Шипастый Пол") or (itemKey == "CampfireKit" and "🔥 Походный костер") or "🪤 Капкан"
		toolInstance.Name = (newCount > 1) and string.format("%s (x%d)", displayName, newCount) or displayName
	else
		local humanoid = char:FindFirstChildOfClass("Humanoid")
		if humanoid then
			humanoid:UnequipTools()
		end
		toolInstance.Parent = nil
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
									mHum:TakeDamage(40)
									mHrp.Anchored = true
									task.delay(3.0, function()
										if mHrp and mHrp.Parent then mHrp.Anchored = false end
									end)

									local crate = trap:FindFirstChild("Crate")
									local stick = trap:FindFirstChild("PropStick")
									local carrot = trap:FindFirstChild("Carrot")
									local greens = trap:FindFirstChild("CarrotGreens")
									if stick then stick.Transparency = 0.8 end
									if carrot then carrot.Transparency = 1 end
									if greens then greens.Transparency = 1 end

									local prompt = primaryPart:FindFirstChildOfClass("ProximityPrompt")
									if prompt then
										prompt.ActionText = "Взять в рюкзак"
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

											mHum:TakeDamage(25)
											local origSpeed = mHum.WalkSpeed
											mHum.WalkSpeed = math.max(1, origSpeed * 0.4)
											task.delay(1.5, function()
												if mHum and mHum.Parent then
													mHum.WalkSpeed = origSpeed
												end
											end)

											curDur = math.max(0, curDur - 1)
											trap:SetAttribute("Durability", curDur)

											local prompt = primaryPart:FindFirstChildOfClass("ProximityPrompt")
											local statusLight = trap:FindFirstChild("StatusLight")
											local smoke = statusLight and statusLight:FindFirstChild("BrokenSmoke")

											if curDur <= 0 then
												trap:SetAttribute("IsBroken", true)
												if prompt then
													prompt.ObjectText = "📌 Сломанный шипастый пол (0/10)"
													prompt.ActionText = "Взять в рюкзак"
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
													prompt.ObjectText = string.format("📌 Шипастый Пол (Заряжен: %d/10)", curDur)
													prompt.ActionText = "Взять в рюкзак"
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

print("🪤 [TrapService] Система охотничьих капканов и шипастых полов готова (ЛКМ - поставить заряженным, [E] - взять в рюкзак, [G] - бросить на снег)!")
