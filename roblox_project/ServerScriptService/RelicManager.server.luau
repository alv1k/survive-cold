--[[
    RelicManager.server.luau
    Серверная система 7 Древних Реликвий, Мини-испытаний, 3D-моделей и баффов Алтаря:
    1. 🏆 Древняя Чаша Вечности (Огненный пазл: 3 чаши вокруг постамента)
    2. 🧊 Сердце Северной Бури (Заковано в вековой лед: отогрев факелом/костром)
    3. 🐺 Зуб Ледяного Хищника (Охраняется Белым Волком-Стражем)
    4. 🧭 Рунический Компас Геологов (Замерзший ящик экспедиции: требуется 2 детали Parts)
    5. 🔥 Кристалл Вечного Пламени (Ледяной пик: согревающий маяк на скале)
    6. 👑 Корона Ледяного Короля (Снежный завал: пробивание валунов)
    7. 🔮 Око Провидца (Маяк Бури: парящий рунический обелиск со световым лучом)
    
    Поэтапные командные баффы на Алтаре:
    - 1/7: Согревающая аура Алтаря (Зона тепла 30 studs)
    - 2/7: Костры и печи горят на +30 сек дольше
    - 3/7: +20% шанс удвоения добычи ресурсов
    - 4/7: Питомцы голодают на 50% медленнее
    - 5/7: +12% постоянная скорость бега всей команде
    - 6/7: +25% защита от холода и бури для всех
    - 7/7: Открытие Бункера Эвакуации, фейерверки и Перерождение!
--]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local TweenService = game:GetService("TweenService")

local TOTAL_RELICS = 7
workspace:SetAttribute("AltarPlacedRelics", 0)
workspace:SetAttribute("IsBunkerOpen", false)
workspace:SetAttribute("AltarWarmthZone", false)
workspace:SetAttribute("CampfireTimeBonus", 0)
workspace:SetAttribute("ResourceDropBonus", 0)
workspace:SetAttribute("PetStarveRateModifier", 1.0)
workspace:SetAttribute("TeamSpeedBonus", 0)
workspace:SetAttribute("TeamColdProtection", 0)

local RemotesFolder = ReplicatedStorage:FindFirstChild("Remotes") or Instance.new("Folder", ReplicatedStorage)
RemotesFolder.Name = "Remotes"

local ShowNotificationRemote = RemotesFolder:FindFirstChild("ShowNotification") or Instance.new("RemoteEvent", RemotesFolder)
ShowNotificationRemote.Name = "ShowNotification"

local RelicsFolder = workspace:FindFirstChild("Relics") or Instance.new("Folder", workspace)
RelicsFolder.Name = "Relics"
RelicsFolder:ClearAllChildren()

-- Создание вспомогательного светового луча маяка в небо
local function attachSkyBeacon(parentPart, beamColor)
	local attTop = Instance.new("Attachment")
	attTop.Name = "BeaconAttTop"
	attTop.Position = Vector3.new(0, 120, 0)
	attTop.Parent = parentPart

	local attBottom = Instance.new("Attachment")
	attBottom.Name = "BeaconAttBottom"
	attBottom.Position = Vector3.new(0, 0, 0)
	attBottom.Parent = parentPart

	local beam = Instance.new("Beam")
	beam.Name = "SkyBeam"
	beam.Attachment0 = attBottom
	beam.Attachment1 = attTop
	beam.Width0 = 3.5
	beam.Width1 = 0.5
	beam.Color = ColorSequence.new(beamColor)
	beam.Transparency = NumberSequence.new(0.3, 0.9)
	beam.LightEmission = 1
	beam.LightInfluence = 0
	beam.FaceCamera = true
	beam.Parent = parentPart

	local light = Instance.new("PointLight")
	light.Color = beamColor
	light.Range = 14
	light.Brightness = 0.6
	light.Parent = parentPart
end

-- 1. Создание Древнего Алтаря
local AltarPart = workspace:FindFirstChild("AncientAltar") or Instance.new("Part")
AltarPart.Name = "AncientAltar"
AltarPart.Size = Vector3.new(14, 2.5, 14)
AltarPart.Position = Vector3.new(-60, 1.25, 80)
AltarPart.Anchored = true
AltarPart.Material = Enum.Material.Slate
AltarPart.BrickColor = BrickColor.new("Dark stone grey")
AltarPart.Parent = workspace

local altarGlow = Instance.new("PointLight", AltarPart)
altarGlow.Name = "AltarGlow"
altarGlow.Color = Color3.fromRGB(56, 189, 248)
altarGlow.Range = 18
altarGlow.Brightness = 0.6

local AltarPrompt = AltarPart:FindFirstChildOfClass("ProximityPrompt") or Instance.new("ProximityPrompt", AltarPart)
AltarPrompt.ActionText = "Освятить реликвии на Алтаре"
AltarPrompt.ObjectText = "⛩️ Древний Алтарь (0/7) [Требуются реликвии]"
AltarPrompt.HoldDuration = 1.0
AltarPrompt.MaxActivationDistance = 14

-- 2. Создание Бункера Эвакуации
local BunkerPart = workspace:FindFirstChild("EvacuationBunker") or Instance.new("Part")
BunkerPart.Name = "EvacuationBunker"
BunkerPart.Size = Vector3.new(18, 9, 18)
BunkerPart.Position = Vector3.new(180, 4.5, 120)
BunkerPart.Anchored = true
BunkerPart.Material = Enum.Material.DiamondPlate
BunkerPart.BrickColor = BrickColor.new("Really red")
BunkerPart.Parent = workspace

local BunkerPrompt = BunkerPart:FindFirstChildOfClass("ProximityPrompt") or Instance.new("ProximityPrompt", BunkerPart)
BunkerPrompt.ActionText = "Войти в Бункер для Перерождения"
BunkerPrompt.ObjectText = "🚪 Бункер Эвакуации [🔒 Требуется 7 реликвий на Алтаре]"
BunkerPrompt.Enabled = false
BunkerPrompt.HoldDuration = 2.0
BunkerPrompt.MaxActivationDistance = 14

-- Список описаний бонусов Алтаря
local ALTAR_BUFF_DESC = {
	[1] = "🔥 Зона тепла вокруг Алтаря (30 studs)",
	[2] = "⏳ Костры горят на +30 сек дольше",
	[3] = "📦 +20% шанс удвоения добычи ресурсов",
	[4] = "🐾 Питомцы голодают в 2 раза медленнее",
	[5] = "⚡ +12% постоянная скорость бега всей команде",
	[6] = "🛡️ +25% стойкость к холоду и метели",
	[7] = "🚀 Бункер открыт! Доступно Перерождение!"
}

-- Применение командных баффов при сдаче реликвий
local function applyAltarBuffs(placedCount)
	if placedCount >= 1 then
		workspace:SetAttribute("AltarWarmthZone", true)
		altarGlow.Color = Color3.fromRGB(245, 158, 11)
		altarGlow.Range = 36
		altarGlow.Brightness = 4
	end
	if placedCount >= 2 then
		workspace:SetAttribute("CampfireTimeBonus", 30)
	end
	if placedCount >= 3 then
		workspace:SetAttribute("ResourceDropBonus", 0.20)
	end
	if placedCount >= 4 then
		workspace:SetAttribute("PetStarveRateModifier", 0.50)
	end
	if placedCount >= 5 then
		workspace:SetAttribute("TeamSpeedBonus", 0.12)
		for _, pl in ipairs(Players:GetPlayers()) do
			local hum = pl.Character and pl.Character:FindFirstChild("Humanoid")
			if hum then hum.WalkSpeed = 16 * 1.12 end
		end
	end
	if placedCount >= 6 then
		workspace:SetAttribute("TeamColdProtection", 0.25)
	end
	if placedCount >= 7 then
		workspace:SetAttribute("IsVictory", true)
		workspace:SetAttribute("IsBlizzard", false)
		workspace:SetAttribute("IsNight", false)
		workspace:SetAttribute("IsBunkerOpen", true)

		BunkerPart.BrickColor = BrickColor.new("Lime green")
		BunkerPrompt.Enabled = true
		BunkerPrompt.ObjectText = "🚪 Бункер Эвакуации [🟢 ДОСТУП РАЗРЕШЕН - ПЕРЕРОЖДЕНИЕ]"

		for _, pl in ipairs(Players:GetPlayers()) do
			ShowNotificationRemote:FireClient(pl, "🎉 ВСЕ 7 РЕЛИКВИЙ ОСВЯЩЕНЫ! БУНКЕР ЭВАКУАЦИИ ОТКРЫТ!")
		end
	end
end

-- Взаимодействие с Алтарем: Сдача реликвий
AltarPrompt.Triggered:Connect(function(player)
	local carried = player:GetAttribute("CarriedRelics") or 0
	if carried > 0 then
		local placed = workspace:GetAttribute("AltarPlacedRelics") or 0
		local toAdd = math.min(TOTAL_RELICS - placed, carried)
		placed = placed + toAdd
		player:SetAttribute("CarriedRelics", carried - toAdd)
		workspace:SetAttribute("AltarPlacedRelics", placed)

		applyAltarBuffs(placed)

		local nextBuff = ALTAR_BUFF_DESC[placed] or "Все реликвии собраны!"
		AltarPrompt.ObjectText = string.format("⛩️ Древний Алтарь (%d/%d) [%s]", placed, TOTAL_RELICS, nextBuff)

		for _, pl in ipairs(Players:GetPlayers()) do
			ShowNotificationRemote:FireClient(pl, string.format("⛩️ %s освятил реликвию! (%d/%d) Бафф: %s", player.DisplayName, placed, TOTAL_RELICS, nextBuff))
		end
		print(string.format("✨ %s освятил реликвии на Алтаре! (%d/%d) -> Бафф: %s", player.Name, placed, TOTAL_RELICS, nextBuff))
	else
		ShowNotificationRemote:FireClient(player, "⚠️ У вас нет реликвий в руках! Найдите древние артефакты в снегах.")
	end
end)

-- Взаимодействие с Бункером: Перерождение (Rebirth)
BunkerPrompt.Triggered:Connect(function(player)
	if workspace:GetAttribute("IsBunkerOpen") then
		local currentRebirths = player:GetAttribute("Rebirths") or 0
		local nextRebirth = currentRebirths + 1
		player:SetAttribute("Rebirths", nextRebirth)
		player:SetAttribute("CarriedRelics", 0)
		player:SetAttribute("ClothingLevel", 0)
		player:SetAttribute("ClothingProtection", 0)
		player:SetAttribute("Ammo_Slingshot", 0)
		player:SetAttribute("Ammo_Revolver", 0)

		local backpack = player:FindFirstChildOfClass("Backpack")
		if backpack then backpack:ClearAllChildren() end

		local char = player.Character
		local humanoid = char and char:FindFirstChild("Humanoid")
		if humanoid then
			humanoid.WalkSpeed = 16 * (1 + (nextRebirth * 0.05))
			humanoid.Health = humanoid.MaxHealth
		end
		player:SetAttribute("Warmth", 100)
		player:SetAttribute("Hunger", 100)
		player:SetAttribute("RebirthColdProtection", math.min(0.40, nextRebirth * 0.10))

		ShowNotificationRemote:FireClient(player, string.format("🚀 Вы успешно переродились! Цикл #%d (+%d%% скорости, +%d%% защиты от бури)", nextRebirth, nextRebirth * 5, nextRebirth * 10))
		print(string.format("🚀 %s успешно переродился! Новый цикл: #%d", player.Name, nextRebirth))
	end
end)

--------------------------------------------------------------------------------
-- 🏛️ СПАВН 7 УНИКАЛЬНЫХ РЕЛИКВИЙ С ИСПЫТАНИЯМИ
--------------------------------------------------------------------------------

-- Функция сбора реликвии игроком
local function awardRelicToPlayer(player, relicName)
	local carried = player:GetAttribute("CarriedRelics") or 0
	player:SetAttribute("CarriedRelics", carried + 1)
	ShowNotificationRemote:FireClient(player, string.format("💎 Вы получили реликвию: %s! Отнесите её на Древний Алтарь.", relicName))
	print(string.format("💎 %s подобрал реликвию %s! (В руках: %d)", player.Name, relicName, carried + 1))
end

-- 1. РЕЛИКВИЯ #1: 🏆 Древняя Чаша Вечности (Огненный пазл: 3 чаши)
task.spawn(function()
	local sitePos = Vector3.new(-180, 2, -120)

	local siteModel = Instance.new("Model", RelicsFolder)
	siteModel.Name = "RelicSite_1_Chalice"

	local altarPed = Instance.new("Part", siteModel)
	altarPed.Name = "Pedestal"
	altarPed.Size = Vector3.new(6, 2, 6)
	altarPed.Position = sitePos
	altarPed.Anchored = true
	altarPed.Material = Enum.Material.Marble
	altarPed.BrickColor = BrickColor.new("Sand blue")

	local chalice = Instance.new("Part", siteModel)
	chalice.Name = "Relic_1"
	chalice.Size = Vector3.new(1.8, 2.8, 1.8)
	chalice.Position = sitePos + Vector3.new(0, 2.4, 0)
	chalice.Anchored = true
	chalice.Material = Enum.Material.Neon
	chalice.BrickColor = BrickColor.new("Bright yellow")
	siteModel.PrimaryPart = chalice
	attachSkyBeacon(chalice, Color3.fromRGB(234, 179, 8))

	local chalicePrompt = Instance.new("ProximityPrompt", chalice)
	chalicePrompt.ActionText = "Взять Древнюю Чашу"
	chalicePrompt.ObjectText = "🔒 Чаша защищена магией [Зажгите 3 чаши с огнем]"
	chalicePrompt.HoldDuration = 1.0
	chalicePrompt.Enabled = false

	local litBraziers = 0
	local brazierOffsets = { Vector3.new(-4.5, 0, -4.5), Vector3.new(4.5, 0, -4.5), Vector3.new(0, 0, 5) }

	for idx, offset in ipairs(brazierOffsets) do
		local brazier = Instance.new("Part", siteModel)
		brazier.Name = "Brazier_" .. idx
		brazier.Size = Vector3.new(2, 2.5, 2)
		brazier.Position = sitePos + offset
		brazier.Anchored = true
		brazier.Material = Enum.Material.Cobblestone
		brazier.BrickColor = BrickColor.new("Dark stone grey")

		local bPrompt = Instance.new("ProximityPrompt", brazier)
		bPrompt.ActionText = "Зажечь чашу Факелом"
		bPrompt.ObjectText = string.format("🔥 Ритуальная чаша #%d", idx)
		bPrompt.HoldDuration = 0.8

		bPrompt.Triggered:Connect(function(player)
			local char = player.Character
			local equippedTool = char and char:FindFirstChildOfClass("Tool")
			local hasTorch = equippedTool and (equippedTool.Name:find("Факел") or equippedTool.Name:find("Torch"))

			if hasTorch then
				bPrompt.Enabled = false
				brazier.Material = Enum.Material.Neon
				brazier.BrickColor = BrickColor.new("Bright orange")

				local fire = Instance.new("Fire", brazier)
				fire.Size = 4

				litBraziers = litBraziers + 1
				ShowNotificationRemote:FireClient(player, string.format("🔥 Ритуальная чаша зажжена! (%d/3)", litBraziers))

				if litBraziers >= 3 then
					chalicePrompt.Enabled = true
					chalicePrompt.ObjectText = "🏆 Древняя Чаша Вечности [ГОТОВО]"
					ShowNotificationRemote:FireClient(player, "✨ Магический барьер пал! Древняя Чаша Вечности свободна!")
				end
			else
				ShowNotificationRemote:FireClient(player, "⚠️ Возьмите в руки горящий Факел, чтобы зажечь ритуальную чашу!")
			end
		end)
	end

	chalicePrompt.Triggered:Connect(function(player)
		awardRelicToPlayer(player, "🏆 Древняя Чаша Вечности")
		siteModel:Destroy()
	end)
end)

-- 2. РЕЛИКВИЯ #2: 🧊 Сердце Северной Бури (Отогрев векового льда)
task.spawn(function()
	local pos = Vector3.new(220, 2.5, -190)

	local siteModel = Instance.new("Model", RelicsFolder)
	siteModel.Name = "RelicSite_2_IceHeart"

	local relic = Instance.new("Part", siteModel)
	relic.Name = "Relic_2"
	relic.Size = Vector3.new(2.2, 3.2, 2.2)
	relic.Position = pos
	relic.Anchored = true
	relic.Material = Enum.Material.Neon
	relic.BrickColor = BrickColor.new("Cyan")
	siteModel.PrimaryPart = relic
	attachSkyBeacon(relic, Color3.fromRGB(6, 182, 212))

	local iceBlock = Instance.new("Part", siteModel)
	iceBlock.Name = "GlacialIce"
	iceBlock.Size = Vector3.new(5.5, 6.5, 5.5)
	iceBlock.Position = pos
	iceBlock.Anchored = true
	iceBlock.Material = Enum.Material.Ice
	iceBlock.BrickColor = BrickColor.new("Pastel light blue")
	iceBlock.Transparency = 0.35

	local icePrompt = Instance.new("ProximityPrompt", iceBlock)
	icePrompt.ActionText = "Растопить вековой лед Факелом"
	icePrompt.ObjectText = "🧊 Сердце Северной Бури (Заковано во льду)"
	icePrompt.HoldDuration = 3.0

	icePrompt.Triggered:Connect(function(player)
		local char = player.Character
		local equippedTool = char and char:FindFirstChildOfClass("Tool")
		local hasTorch = equippedTool and (equippedTool.Name:find("Факел") or equippedTool.Name:find("Torch"))

		if hasTorch then
			iceBlock:Destroy()
			local relicPrompt = Instance.new("ProximityPrompt", relic)
			relicPrompt.ActionText = "Взять Сердце Бури"
			relicPrompt.ObjectText = "🧊 Сердце Северной Бури"
			relicPrompt.HoldDuration = 0.8
			relicPrompt.Triggered:Connect(function(pl)
				awardRelicToPlayer(pl, "🧊 Сердце Северной Бури")
				siteModel:Destroy()
			end)
			ShowNotificationRemote:FireClient(player, "💧 Лёд растаял! Вы освободили Сердце Северной Бури.")
		else
			ShowNotificationRemote:FireClient(player, "⚠️ Возьмите в руки горящий Факел, чтобы растопить лед!")
		end
	end)
end)

-- 3. РЕЛИКВИЯ #3: 🐺 Зуб Ледяного Хищника (Охрана Белым Волком-Стражем)
task.spawn(function()
	local pos = Vector3.new(140, 2.5, 280)

	local siteModel = Instance.new("Model", RelicsFolder)
	siteModel.Name = "RelicSite_3_WolfFang"

	local ped = Instance.new("Part", siteModel)
	ped.Name = "AltarRock"
	ped.Size = Vector3.new(5, 3, 5)
	ped.Position = pos
	ped.Anchored = true
	ped.Material = Enum.Material.Rock
	ped.BrickColor = BrickColor.new("Dark stone grey")

	local relic = Instance.new("Part", siteModel)
	relic.Name = "Relic_3"
	relic.Size = Vector3.new(1.5, 3.5, 1.5)
	relic.Position = pos + Vector3.new(0, 3, 0)
	relic.Anchored = true
	relic.Material = Enum.Material.Neon
	relic.BrickColor = BrickColor.new("White")
	siteModel.PrimaryPart = relic
	attachSkyBeacon(relic, Color3.fromRGB(241, 245, 249))

	-- Спавн Элитного Волка-Стража
	local guard = Instance.new("Model", siteModel)
	guard.Name = "WhiteWolfGuardian"
	local gBody = Instance.new("Part", guard)
	gBody.Name = "HumanoidRootPart"
	gBody.Size = Vector3.new(3, 3, 5)
	gBody.Position = pos + Vector3.new(6, 2, 0)
	gBody.Material = Enum.Material.Fabric
	gBody.BrickColor = BrickColor.new("White")
	guard.PrimaryPart = gBody

	local hum = Instance.new("Humanoid", guard)
	hum.MaxHealth = 120
	hum.Health = 120

	local relicPrompt = Instance.new("ProximityPrompt", relic)
	relicPrompt.ActionText = "Взять Зуб Ледяного Хищника"
	relicPrompt.ObjectText = "🐺 Зуб Ледяного Хищника"
	relicPrompt.HoldDuration = 1.0
	relicPrompt.Triggered:Connect(function(player)
		awardRelicToPlayer(player, "🐺 Зуб Ледяного Хищника")
		siteModel:Destroy()
	end)
end)

-- 4. РЕЛИКВИЯ #4: 🧭 Рунический Компас Геологов (Замерзший ящик: требуется 2 детали)
task.spawn(function()
	local pos = Vector3.new(-260, 2.5, 160)

	local siteModel = Instance.new("Model", RelicsFolder)
	siteModel.Name = "RelicSite_4_Compass"

	local tent = Instance.new("Part", siteModel)
	tent.Name = "ExpeditionTent"
	tent.Size = Vector3.new(8, 5, 8)
	tent.Position = pos
	tent.Anchored = true
	tent.Material = Enum.Material.Fabric
	tent.BrickColor = BrickColor.new("Bright orange")

	local chest = Instance.new("Part", siteModel)
	chest.Name = "Relic_4"
	chest.Size = Vector3.new(2.5, 2, 2.5)
	chest.Position = pos + Vector3.new(0, -1, 0)
	chest.Anchored = true
	chest.Material = Enum.Material.DiamondPlate
	chest.BrickColor = BrickColor.new("Bright yellow")
	siteModel.PrimaryPart = chest
	attachSkyBeacon(chest, Color3.fromRGB(245, 158, 11))

	local chestPrompt = Instance.new("ProximityPrompt", chest)
	chestPrompt.ActionText = "Починить замок ящика (2 Детали)"
	chestPrompt.ObjectText = "🧭 Замерзший сейф с Компасом"
	chestPrompt.HoldDuration = 1.5

	chestPrompt.Triggered:Connect(function(player)
		local partsCount = player:GetAttribute("Parts") or 0
		if partsCount >= 2 then
			player:SetAttribute("Parts", partsCount - 2)
			awardRelicToPlayer(player, "🧭 Рунический Компас Геологов")
			siteModel:Destroy()
		else
			ShowNotificationRemote:FireClient(player, string.format("⚠️ Требуется 2 Детали (⚙️) для починки замка! (У вас: %d)", partsCount))
		end
	end)
end)

-- 5. РЕЛИКВИЯ #5: 🔥 Кристалл Вечного Пламени (Ледяной пик на скале)
task.spawn(function()
	local peakPos = Vector3.new(50, 32, -250)

	local siteModel = Instance.new("Model", RelicsFolder)
	siteModel.Name = "RelicSite_5_EternalFlame"

	local mountain = Instance.new("Part", siteModel)
	mountain.Name = "IcePeak"
	mountain.Size = Vector3.new(22, 32, 22)
	mountain.Position = Vector3.new(50, 16, -250)
	mountain.Anchored = true
	mountain.Material = Enum.Material.Ice
	mountain.BrickColor = BrickColor.new("Pastel light blue")

	local crystal = Instance.new("Part", siteModel)
	crystal.Name = "Relic_5"
	crystal.Size = Vector3.new(2.5, 4.5, 2.5)
	crystal.Position = peakPos + Vector3.new(0, 3, 0)
	crystal.Anchored = true
	crystal.Material = Enum.Material.Neon
	crystal.BrickColor = BrickColor.new("Bright red")
	siteModel.PrimaryPart = crystal
	attachSkyBeacon(crystal, Color3.fromRGB(239, 68, 68))

	local fire = Instance.new("Fire", crystal)
	fire.Size = 6
	fire.Color = Color3.fromRGB(255, 100, 0)

	-- Согревающая аура на вершине
	task.spawn(function()
		while siteModel.Parent do
			task.wait(1.0)
			for _, pl in ipairs(Players:GetPlayers()) do
				local char = pl.Character
				local hrp = char and char:FindFirstChild("HumanoidRootPart")
				if hrp and (hrp.Position - crystal.Position).Magnitude <= 18 then
					local curW = pl:GetAttribute("Warmth") or 100
					pl:SetAttribute("Warmth", math.min(100, curW + 8))
				end
			end
		end
	end)

	local prompt = Instance.new("ProximityPrompt", crystal)
	prompt.ActionText = "Взять Кристалл Вечного Пламени"
	prompt.ObjectText = "🔥 Кристалл Вечного Пламени"
	prompt.HoldDuration = 1.2
	prompt.Triggered:Connect(function(player)
		awardRelicToPlayer(player, "🔥 Кристалл Вечного Пламени")
		siteModel:Destroy()
	end)
end)

-- 6. РЕЛИКВИЯ #6: 👑 Корона Ледяного Короля (Разбивание валунов)
task.spawn(function()
	local pos = Vector3.new(-120, 2.5, 310)

	local siteModel = Instance.new("Model", RelicsFolder)
	siteModel.Name = "RelicSite_6_Crown"

	local crown = Instance.new("Part", siteModel)
	crown.Name = "Relic_6"
	crown.Size = Vector3.new(2.4, 2, 2.4)
	crown.Position = pos
	crown.Anchored = true
	crown.Material = Enum.Material.Neon
	crown.BrickColor = BrickColor.new("Bright violet")
	siteModel.PrimaryPart = crown
	attachSkyBeacon(crown, Color3.fromRGB(168, 85, 247))

	local rubble = Instance.new("Part", siteModel)
	rubble.Name = "GlacialRubble"
	rubble.Size = Vector3.new(6, 5, 6)
	rubble.Position = pos + Vector3.new(0, 1, 0)
	rubble.Anchored = true
	rubble.Material = Enum.Material.Slate
	rubble.BrickColor = BrickColor.new("Medium stone grey")

	local rubbleHits = 0
	local rPrompt = Instance.new("ProximityPrompt", rubble)
	rPrompt.ActionText = "Разбить снежный завал (3 удара)"
	rPrompt.ObjectText = "🪨 Древний снежный завал"
	rPrompt.HoldDuration = 1.0

	rPrompt.Triggered:Connect(function(player)
		rubbleHits = rubbleHits + 1
		rPrompt.ActionText = string.format("Разбить завал (%d/3)", rubbleHits)
		ShowNotificationRemote:FireClient(player, string.format("💥 Завал трескается! (%d/3)", rubbleHits))

		if rubbleHits >= 3 then
			rubble:Destroy()
			local cPrompt = Instance.new("ProximityPrompt", crown)
			cPrompt.ActionText = "Взять Корону Ледяного Короля"
			cPrompt.ObjectText = "👑 Корона Ледяного Короля"
			cPrompt.HoldDuration = 0.8
			cPrompt.Triggered:Connect(function(pl)
				awardRelicToPlayer(pl, "👑 Корона Ледяного Короля")
				siteModel:Destroy()
			end)
			ShowNotificationRemote:FireClient(player, "👑 Завал разрушен! Корона Ледяного Короля освобождена.")
		end
	end)
end)

-- 7. РЕЛИКВИЯ #7: 🔮 Око Провидца (Маяк в сердце метели)
task.spawn(function()
	local pos = Vector3.new(0, 4.5, -320)

	local siteModel = Instance.new("Model", RelicsFolder)
	siteModel.Name = "RelicSite_7_Eye"

	local pillar = Instance.new("Part", siteModel)
	pillar.Name = "RunePillar"
	pillar.Size = Vector3.new(4, 8, 4)
	pillar.Position = pos - Vector3.new(0, 2, 0)
	pillar.Anchored = true
	pillar.Material = Enum.Material.Obsidian
	pillar.BrickColor = BrickColor.new("Black")

	local eye = Instance.new("Part", siteModel)
	eye.Name = "Relic_7"
	eye.Shape = Enum.PartType.Ball
	eye.Size = Vector3.new(3, 3, 3)
	eye.Position = pos + Vector3.new(0, 5, 0)
	eye.Anchored = true
	eye.Material = Enum.Material.Neon
	eye.BrickColor = BrickColor.new("Magenta")
	siteModel.PrimaryPart = eye
	attachSkyBeacon(eye, Color3.fromRGB(236, 72, 153))

	local prompt = Instance.new("ProximityPrompt", eye)
	prompt.ActionText = "Взять Око Провидца"
	prompt.ObjectText = "🔮 Око Провидца (Древний Обелиск)"
	prompt.HoldDuration = 1.5
	prompt.Triggered:Connect(function(player)
		awardRelicToPlayer(player, "🔮 Око Провидца")
		siteModel:Destroy()
	end)
end)

print("🏛️ [RelicManager] 7 Уникальных Реликвий, интерактивные испытания и система баффов Алтаря успешно запущены!")
