--[[
    PetService.server.luau
    Серверная система Питомцев (Снежный Лис, Ледяной Волчонок, Полярный Медвежонок):
    - Отогрев ледяных глыб факелом (с наглядной 3D-моделью замерзшего зверька внутри)
    - Голод и кормление (любимые блюда дают +65% сытости)
    - Уход в лес через 60 сек голода (Starvation Runaway)
    - Режимы: В походе (follow) / Отдых дома на лежанке (stay_home)
    - Уникальные баффы хозяину (Лис: стамина + радар, Волк: урон + скорость, Медведь: тепло)
    - Полная физическая стабильность (HumanoidRootPart, CanCollide, HipHeight, Motor6D)
    - Плавное 60 FPS следование за игроком через нативный Humanoid:MoveTo
--]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local PhysicsService = game:GetService("PhysicsService")

local SurfaceUtil = require(ReplicatedStorage:WaitForChild("SurfaceUtil"))
local GeneratedModels = ReplicatedStorage:WaitForChild("GeneratedModels")
local FoxGenerator = require(GeneratedModels:WaitForChild("Fox"))
local WolfPupGenerator = require(GeneratedModels:WaitForChild("WolfPup"))
local BearCubGenerator = require(GeneratedModels:WaitForChild("BearCub"))

local Network = require(ReplicatedStorage:WaitForChild("Network"))
local FeedPetRemote = Network.getEvent("FeedPet")
local TogglePetModeRemote = Network.getEvent("TogglePetMode")
local OpenPetMenuRemote = Network.getEvent("OpenPetMenu")
local UpdatePetDataRemote = Network.getEvent("UpdatePetData")
local ShowNotificationRemote = Network.getEvent("ShowNotification")

-- =============================================================================
-- НАСТРОЙКА ГРУПП КОЛЛИЗИЙ ДЛЯ ПИТОМЦЕВ
-- =============================================================================
local function safeRegisterCollisionGroup(groupName)
	pcall(function()
		PhysicsService:RegisterCollisionGroup(groupName)
	end)
end

safeRegisterCollisionGroup("Players")
safeRegisterCollisionGroup("Mobs")
safeRegisterCollisionGroup("Pets")

pcall(function()
	PhysicsService:CollisionGroupSetCollidable("Players", "Pets", false)
	PhysicsService:CollisionGroupSetCollidable("Mobs", "Pets", false)
	PhysicsService:CollisionGroupSetCollidable("Pets", "Pets", false)
	PhysicsService:CollisionGroupSetCollidable("Pets", "Default", true)
end)

local function setModelCollisionGroup(model, groupName)
	for _, desc in ipairs(model:GetDescendants()) do
		if desc:IsA("BasePart") then
			pcall(function()
				desc.CollisionGroup = groupName
			end)
		end
	end
	model.DescendantAdded:Connect(function(desc)
		if desc:IsA("BasePart") then
			pcall(function()
				desc.CollisionGroup = groupName
			end)
		end
	end)
end

local PET_CONFIG = {
	Fox = {
		Name = "🦊 Снежный Лис",
		IceLocation = Vector3.new(-16.5, 2.5, 14.0), -- 🏡 Слева от крыльца дома
		FavoriteFoods = { Bar = true, Chips = true },
		Desc = "+35% реген выносливости & Радар реликвий"
	},
	Wolf = {
		Name = "🐺 Ледяной Волчонок",
		IceLocation = Vector3.new(16.5, 2.5, 14.0), -- 🏡 Справа от крыльца дома (у факела)
		FavoriteFoods = { Steak = true, Soup = true },
		Desc = "+25% урон оружия & +10% скорость бега"
	},
	Bear = {
		Name = "🐻 Полярный Медвежонок",
		IceLocation = Vector3.new(0.0, 2.5, 22.0), -- 🏡 По центру переднего двора дома
		FavoriteFoods = { Bread = true, Steak = true },
		Desc = "+0.35 постоянное тепло & защита от бури"
	}
}

local PetsFolder = workspace:FindFirstChild("Pets") or Instance.new("Folder", workspace)
PetsFolder.Name = "Pets"

-- Спавн ледяных глыб с питомцами
for petId, cfg in pairs(PET_CONFIG) do
	local groundY = SurfaceUtil.getGroundHeight(cfg.IceLocation.X, cfg.IceLocation.Z)
	local exactIcePos = Vector3.new(cfg.IceLocation.X, groundY + 2.0, cfg.IceLocation.Z)

	local iceBlock = Instance.new("Part")
	iceBlock.Name = "FrozenPet_" .. petId
	iceBlock.Size = Vector3.new(4.2, 4.4, 4.2)
	iceBlock.Position = exactIcePos
	iceBlock.Anchored = true
	iceBlock.Material = Enum.Material.Ice
	iceBlock.BrickColor = BrickColor.new("Pastel light blue")
	iceBlock.Transparency = 0.35
	iceBlock.Parent = PetsFolder

	local iceLight = Instance.new("PointLight", iceBlock)
	iceLight.Color = Color3.fromRGB(165, 243, 252)
	iceLight.Range = 14
	iceLight.Brightness = 0.8

	-- Внутренняя замерзшая 3D-модель (для наглядности игроку)
	local frozenModel = nil
	if petId == "Wolf" then
		frozenModel = WolfPupGenerator.create(iceBlock, CFrame.new(exactIcePos - Vector3.new(0, 1.2, 0)), {
			Scale = 1.35,
			Anchored = true,
			isAnimated = false
		})
	elseif petId == "Fox" then
		frozenModel = FoxGenerator.create(iceBlock, CFrame.new(exactIcePos - Vector3.new(0, 1.1, 0)), {
			Scale = 1.30,
			Anchored = true,
			isAnimated = false
		})
	elseif petId == "Bear" then
		frozenModel = BearCubGenerator.create(iceBlock, CFrame.new(exactIcePos - Vector3.new(0, 1.3, 0)), {
			Scale = 1.35,
			Anchored = true,
			isAnimated = false
		})
	end

	if frozenModel then
		for _, part in ipairs(frozenModel:GetDescendants()) do
			if part:IsA("BasePart") then
				part.Material = Enum.Material.Ice
				part.Transparency = 0.25
				part.CanCollide = false
				part.Anchored = true
			end
		end
	end

	local prompt = Instance.new("ProximityPrompt", iceBlock)
	prompt.ActionText = "Отогреть Факелом"
	prompt.ObjectText = cfg.Name .. " (Закован во льду)"
	prompt.HoldDuration = 1.2
	prompt.MaxActivationDistance = 14
	prompt.RequiresLineOfSight = false

	prompt.Triggered:Connect(function(player)
		local char = player.Character
		if not char then return end
		local equippedTool = char:FindFirstChildOfClass("Tool")
		local hasTorch = equippedTool and (equippedTool.Name:find("Факел") or equippedTool.Name:find("Torch") or equippedTool:GetAttribute("ItemKey") == "Torch")

		if hasTorch then
			iceBlock:Destroy()

			local petModel = Instance.new("Model")
			petModel.Name = cfg.Name
			petModel:SetAttribute("PetId", petId)
			petModel:SetAttribute("OwnerUserId", player.UserId)
			petModel:SetAttribute("Hunger", 100)
			petModel:SetAttribute("Mode", "follow")
			petModel:SetAttribute("IsSleeping", false)

			-- Основной физический корень (HumanoidRootPart)
			local hrp = Instance.new("Part")
			hrp.Name = "HumanoidRootPart"
			hrp.Size = Vector3.new(1.4, 1.2, 1.8)
			hrp.Position = exactIcePos + Vector3.new(0, 1.2, 0)
			hrp.Transparency = 1
			hrp.Anchored = false
			hrp.CanCollide = true
			hrp.CustomPhysicalProperties = PhysicalProperties.new(0.7, 0.3, 0.5, 1, 1)
			hrp.Parent = petModel
			petModel.PrimaryPart = hrp

			local petHum = Instance.new("Humanoid")
			petHum.MaxHealth = 100
			petHum.Health = 100
			petHum.WalkSpeed = 16
			petHum.HipHeight = 0.9
			petHum.AutoRotate = true
			petHum.AutomaticScalingEnabled = false
			petHum:SetStateEnabled(Enum.HumanoidStateType.Climbing, false)
			petHum:SetStateEnabled(Enum.HumanoidStateType.Seated, false)
			petHum.MaxSlopeAngle = 45
			petHum.Parent = petModel

			local function attachPetVisuals()
				local halfHrpY = hrp.Size.Y / 2
				local hipHeight = petHum.HipHeight
				local offsetCF = CFrame.new(0, -(halfHrpY + hipHeight) + 0.12, 0)
				local visualModel = nil

				if petId == "Fox" then
					visualModel = FoxGenerator.create(petModel, hrp.CFrame * offsetCF, {
						isPet = true,
						Scale = 1.50,
						isAnimated = true,
						Anchored = false
					})
				elseif petId == "Wolf" then
					visualModel = WolfPupGenerator.create(petModel, hrp.CFrame * offsetCF, {
						isPet = true,
						Scale = 1.60,
						isAnimated = true,
						Anchored = false
					})
				elseif petId == "Bear" then
					visualModel = BearCubGenerator.create(petModel, hrp.CFrame * offsetCF, {
						isPet = true,
						Scale = 1.60,
						isAnimated = true,
						Anchored = false
					})
				end

				if visualModel and visualModel.PrimaryPart then
					visualModel.Name = "Visual_" .. petId
					local primary = visualModel.PrimaryPart

					local rootJoint = Instance.new("Motor6D")
					rootJoint.Name = "RootJoint"
					rootJoint.Part0 = hrp
					rootJoint.Part1 = primary
					rootJoint.C0 = hrp.CFrame:ToObjectSpace(primary.CFrame)
					rootJoint.C1 = CFrame.identity
					rootJoint:SetAttribute("RestC0", rootJoint.C0)
					rootJoint.Parent = hrp
				end
			end

			attachPetVisuals()

			-- Хелпер получения актуальных данных питомца для UI
			local function getPetDataLocal()
				return {
					PetId = petId,
					Name = cfg.Name,
					Desc = cfg.Desc,
					Satiety = petModel:GetAttribute("Satiety") or 100,
					Mode = petModel:GetAttribute("Mode") or "follow",
					IsSleeping = petModel:GetAttribute("IsSleeping") or false,
					FavoriteFoods = cfg.FavoriteFoods,
				}
			end

			-- Интерактивный ProximityPrompt и ClickDetector для открытия меню управления питомцем
			local petPrompt = Instance.new("ProximityPrompt")
			petPrompt.Name = "PetMenuPrompt"
			petPrompt.ActionText = "Меню питомца [E]"
			petPrompt.ObjectText = cfg.Name
			petPrompt.HoldDuration = 0
			petPrompt.MaxActivationDistance = 12
			petPrompt.RequiresLineOfSight = false
			petPrompt.Parent = hrp

			petPrompt.Triggered:Connect(function(triggerPlayer)
				if triggerPlayer.UserId ~= player.UserId then
					ShowNotificationRemote:FireClient(triggerPlayer, "Это питомец другого игрока!")
					return
				end
				OpenPetMenuRemote:FireClient(triggerPlayer, getPetDataLocal())
			end)

			local clickDetector = Instance.new("ClickDetector")
			clickDetector.MaxActivationDistance = 14
			clickDetector.Parent = hrp

			clickDetector.MouseClick:Connect(function(triggerPlayer)
				if triggerPlayer.UserId == player.UserId then
					OpenPetMenuRemote:FireClient(triggerPlayer, getPetDataLocal())
				end
			end)

			setModelCollisionGroup(petModel, "Pets")
			petModel.Parent = PetsFolder

			print(string.format("🎉 %s отогрел и спас питомца: %s!", player.Name, cfg.Name))
			ShowNotificationRemote:FireClient(player, string.format("🎉 Вы спасли питомца: %s! Он бежит за вами!", cfg.Name))

		else
			print(string.format("⚠️ %s должен взять в руки зажженный Факел, чтобы отогреть лед!", player.Name))
		end
	end)
end

-- Ссылки на слоты лежанки в доме
local PET_BED_SLOTS = {
	Wolf = Vector3.new(4.8, 3.1, 4.0),
	Fox = Vector3.new(8.2, 3.1, 4.0),
	Bear = Vector3.new(6.5, 3.1, 5.5)
}

local function getPetData(pet, petId)
	local cfg = PET_CONFIG[petId]
	if not cfg then return nil end
	local satiety = pet:GetAttribute("Satiety") or 100
	local mode = pet:GetAttribute("Mode") or "follow"
	local isSleeping = pet:GetAttribute("IsSleeping") or (mode == "stay_home")

	return {
		PetId = petId,
		Name = cfg.Name,
		Desc = cfg.Desc,
		Satiety = satiety,
		Mode = mode,
		IsSleeping = isSleeping,
		FavoriteFoods = cfg.FavoriteFoods,
	}
end

local function sendPetToBed(pet, pId)
	local hrp = pet:FindFirstChild("HumanoidRootPart") or pet.PrimaryPart
	local hum = pet:FindFirstChildOfClass("Humanoid")
	local slotPos = PET_BED_SLOTS[pId] or Vector3.new(11.0, 1.4, 8.0)
	if hrp then
		hrp.CFrame = CFrame.new(slotPos) * CFrame.Angles(0, math.rad(180), 0)
		hrp.AssemblyLinearVelocity = Vector3.zero
		hrp.AssemblyAngularVelocity = Vector3.zero
	end
	if hum then
		hum:MoveTo(slotPos)
	end
	pet:SetAttribute("Mode", "stay_home")
	pet:SetAttribute("IsSleeping", true)
end

local function wakePetUp(pet, _pId)
	pet:SetAttribute("Mode", "follow")
	pet:SetAttribute("IsSleeping", false)
end

-- Кормление питомца из инвентаря
FeedPetRemote.OnServerEvent:Connect(function(player, petId, foodId)
	local pet = nil
	for _, p in ipairs(PetsFolder:GetChildren()) do
		if p:GetAttribute("OwnerUserId") == player.UserId and p:GetAttribute("PetId") == petId then
			pet = p
			break
		end
	end
	if not pet then return end

	local backpack = player:FindFirstChildOfClass("Backpack")
	local char = player.Character
	local foundTool = nil

	if backpack then
		for _, t in ipairs(backpack:GetChildren()) do
			if t:IsA("Tool") and (t:GetAttribute("ItemKey") == foodId or t.Name:find(foodId)) then
				foundTool = t
				break
			end
		end
	end
	if not foundTool and char then
		for _, t in ipairs(char:GetChildren()) do
			if t:IsA("Tool") and (t:GetAttribute("ItemKey") == foodId or t.Name:find(foodId)) then
				foundTool = t
				break
			end
		end
	end

	local curAttr = player:GetAttribute(foodId) or player:GetAttribute("Food_" .. foodId) or 0
	if not foundTool and curAttr <= 0 then
		ShowNotificationRemote:FireClient(player, "У вас нет этой еды в рюкзаке!")
		return
	end

	-- Списание предмета из рюкзака / атрибута
	if foundTool then
		local curCount = foundTool:GetAttribute("Count") or 1
		if curCount > 1 then
			foundTool:SetAttribute("Count", curCount - 1)
			local cleanName = foundTool.Name:match("^[^%(]+") or foundTool.Name
			foundTool.Name = string.format("%s (x%d)", cleanName:gsub("%s+$", ""), curCount - 1)
		else
			foundTool:Destroy()
		end
	end
	if curAttr > 0 then
		player:SetAttribute(foodId, curAttr - 1)
		player:SetAttribute("Food_" .. foodId, math.max(0, curAttr - 1))
	end

	local cfg = PET_CONFIG[petId]
	local isFav = cfg.FavoriteFoods[foodId] or false
	local gain = isFav and 65 or 30
	local currentSat = pet:GetAttribute("Satiety") or 0
	local newSat = math.min(100, currentSat + gain)

	pet:SetAttribute("Satiety", newSat)
	pet:SetAttribute("StarveTimer", 0)

	local updatedData = getPetData(pet, petId)
	if updatedData then
		UpdatePetDataRemote:FireClient(player, updatedData)
	end

	if isFav then
		ShowNotificationRemote:FireClient(player, string.format("❤️ %s в восторге от любимого лакомства! (+%d%% сытости)", cfg.Name, gain))
	else
		ShowNotificationRemote:FireClient(player, string.format("🍖 %s с аппетитом подкрепился! (+%d%% сытости)", cfg.Name, gain))
	end
end)

-- Переключение режима питомца (Follow / Stay Home)
TogglePetModeRemote.OnServerEvent:Connect(function(player, petId)
	for _, pet in ipairs(PetsFolder:GetChildren()) do
		if pet:GetAttribute("OwnerUserId") == player.UserId and pet:GetAttribute("PetId") == petId then
			local currentMode = pet:GetAttribute("Mode") or "follow"
			if currentMode == "follow" then
				sendPetToBed(pet, petId)
				ShowNotificationRemote:FireClient(player, string.format("💤 %s уютно устроился отдыхать на лежанке!", pet.Name))
			else
				wakePetUp(pet, petId)
				ShowNotificationRemote:FireClient(player, string.format("🐾 %s радостно бежит за вами!", pet.Name))
			end
			local updatedData = getPetData(pet, petId)
			if updatedData then
				UpdatePetDataRemote:FireClient(player, updatedData)
			end
			break
		end
	end
end)

-- Управление всеми питомцами через лежанку в доме
_G.TogglePlayerPetsBed = function(player)
	local playerPets = {}
	local anyFollowing = false
	for _, pet in ipairs(PetsFolder:GetChildren()) do
		if pet:GetAttribute("OwnerUserId") == player.UserId then
			table.insert(playerPets, pet)
			if pet:GetAttribute("Mode") == "follow" then
				anyFollowing = true
			end
		end
	end

	if #playerPets == 0 then
		ShowNotificationRemote:FireClient(player, "У вас пока нет отогретых питомцев у дома!")
		return
	end

	if anyFollowing then
		for _, pet in ipairs(playerPets) do
			local pId = pet:GetAttribute("PetId")
			sendPetToBed(pet, pId)
		end
		ShowNotificationRemote:FireClient(player, "💤 Все питомцы уютно устроились отдыхать на лежанке!")
	else
		for _, pet in ipairs(playerPets) do
			local pId = pet:GetAttribute("PetId")
			wakePetUp(pet, pId)
		end
		ShowNotificationRemote:FireClient(player, "🐾 Все питомцы проснулись и следуют за вами в строю!")
	end
end

-- Сохранение и перемещение питомца к хозяину при воскрешении союзником или за Robux
_G.PreservePlayerPetOnRevive = function(player, targetPos)
	for _, pet in ipairs(PetsFolder:GetChildren()) do
		if pet:GetAttribute("OwnerUserId") == player.UserId then
			local petId = pet:GetAttribute("PetId")
			local hrp = pet:FindFirstChild("HumanoidRootPart") or pet.PrimaryPart
			if hrp and targetPos then
				local groundY = SurfaceUtil.getGroundHeight(targetPos.X + 3, targetPos.Z + 3)
				hrp.CFrame = CFrame.new(targetPos.X + 3, groundY + 1.2, targetPos.Z + 3)
				hrp.AssemblyLinearVelocity = Vector3.zero
			end
			wakePetUp(pet, petId)
			pet:SetAttribute("StarveTimer", 0)
			pet:SetAttribute("Satiety", math.max(60, pet:GetAttribute("Satiety") or 60))
			print(string.format("🐾 Питомец %s сохранен и следует за воскресшим хозяином %s!", pet.Name, player.Name))
		end
	end
end

-- Отправка питомцев домой на лежанку при обычном возрождении в доме
_G.SendPlayerPetHome = function(player)
	for _, pet in ipairs(PetsFolder:GetChildren()) do
		if pet:GetAttribute("OwnerUserId") == player.UserId then
			local petId = pet:GetAttribute("PetId")
			sendPetToBed(pet, petId)
		end
	end
	print(string.format("🐾 Питомцы игрока %s отправлены отдыхать на лежанку в дом!", player.Name))
end

-- Цикл обновления состояния сытости и баффов питомцев (каждую 1 сек)
task.spawn(function()
	while true do
		task.wait(1.0)
		for _, pet in ipairs(PetsFolder:GetChildren()) do
			if pet:IsA("Model") and pet:GetAttribute("OwnerUserId") then
				local ownerId = pet:GetAttribute("OwnerUserId")
				local owner = Players:GetPlayerByUserId(ownerId)
				local petId = pet:GetAttribute("PetId")
				local mode = pet:GetAttribute("Mode") or "follow"
				local satiety = pet:GetAttribute("Satiety") or 100
				local starveTimer = pet:GetAttribute("StarveTimer") or 0

				-- Уменьшение сытости (на лежанке дома сытость почти не тратится)
				local decay = (mode == "stay_home") and 0.10 or 0.50
				satiety = math.max(0, satiety - decay)
				pet:SetAttribute("Satiety", math.floor(satiety))

				if satiety <= 0 then
					starveTimer = starveTimer + 1
					pet:SetAttribute("StarveTimer", starveTimer)
					if starveTimer >= 90 then
						print(string.format("⚠️ Питомец %s ушел в дикий лес из-за голода!", pet.Name))
						pet:Destroy()
					end
				else
					pet:SetAttribute("StarveTimer", 0)
				end

				-- Наложение баффов на владельца
				if owner and owner.Character and satiety > 0 and mode == "follow" then
					if petId == "Fox" then
						owner:SetAttribute("FoxStaminaBuff", 1.35)
					elseif petId == "Wolf" then
						owner:SetAttribute("WolfDamageBuff", 1.25)
						owner:SetAttribute("WolfSpeedBuff", 1.10)
					elseif petId == "Bear" then
						owner:SetAttribute("BearWarmthBuff", 3.5)
					end
				elseif owner then
					if petId == "Fox" then owner:SetAttribute("FoxStaminaBuff", 1.0) end
					if petId == "Wolf" then owner:SetAttribute("WolfDamageBuff", 1.0); owner:SetAttribute("WolfSpeedBuff", 1.0) end
					if petId == "Bear" then owner:SetAttribute("BearWarmthBuff", 0) end
				end
			end
		end
	end
end)

-- Плавное мульти-построение питомцев за игроками (без наложений, стакания и толкания в 60 FPS)
local lastFollowUpdate = 0
RunService.Heartbeat:Connect(function()
	local now = os.clock()
	if now - lastFollowUpdate < 0.12 then return end
	lastFollowUpdate = now

	-- Группируем питомцев в режиме follow по владельцам
	local petsByOwner = {}
	for _, pet in ipairs(PetsFolder:GetChildren()) do
		if pet:IsA("Model") and pet:GetAttribute("OwnerUserId") then
			local ownerId = pet:GetAttribute("OwnerUserId")
			local mode = pet:GetAttribute("Mode") or "follow"
			local hum = pet:FindFirstChildOfClass("Humanoid")
			local hrp = pet:FindFirstChild("HumanoidRootPart") or pet.PrimaryPart

			if mode == "follow" and hum and hum.Health > 0 and hrp then
				if not petsByOwner[ownerId] then
					petsByOwner[ownerId] = {}
				end
				table.insert(petsByOwner[ownerId], pet)
			end
		end
	end

	for ownerId, petsList in pairs(petsByOwner) do
		local owner = Players:GetPlayerByUserId(ownerId)
		local char = owner and owner.Character
		local ownerHrp = char and char:FindFirstChild("HumanoidRootPart")
		local ownerHum = char and char:FindFirstChildOfClass("Humanoid")

		if ownerHrp and ownerHum and ownerHum.Health > 0 then
			local ownerPos = ownerHrp.Position
			local speed = ownerHrp.AssemblyLinearVelocity.Magnitude

			-- Сортируем для стабильного закрепления слота построения
			table.sort(petsList, function(a, b)
				return (a:GetAttribute("PetId") or "") < (b:GetAttribute("PetId") or "")
			end)

			local numPets = #petsList
			local formationOffsets = {}
			if numPets == 1 then
				formationOffsets = { Vector3.new(3.2, 0, 3.0) }
			elseif numPets == 2 then
				formationOffsets = { Vector3.new(-3.4, 0, 3.2), Vector3.new(3.4, 0, 3.2) }
			else
				formationOffsets = { Vector3.new(-3.8, 0, 2.8), Vector3.new(3.8, 0, 2.8), Vector3.new(0, 0, 5.2) }
			end

			for i, pet in ipairs(petsList) do
				local hum = pet:FindFirstChildOfClass("Humanoid")
				local hrp = pet:FindFirstChild("HumanoidRootPart") or pet.PrimaryPart
				if hum and hrp then
					local petPos = hrp.Position
					local slot = formationOffsets[i] or Vector3.new((i - 2) * 3.4, 0, 4.2)
					local targetPos = ownerHrp.CFrame:PointToWorldSpace(slot)
					local groundY = SurfaceUtil.getGroundHeight(targetPos.X, targetPos.Z)
					local goalPos = Vector3.new(targetPos.X, groundY, targetPos.Z)

					local distToGoal = (petPos - goalPos).Magnitude
					local distToOwner = (petPos - ownerPos).Magnitude

					-- Если питомец упал под карту или игрок телепортировался (> 80 studs)
					if petPos.Y < -50 or distToOwner > 80 then
						local safeGroundY = SurfaceUtil.getGroundHeight(goalPos.X, goalPos.Z)
						local safePos = Vector3.new(goalPos.X, safeGroundY + 1.2, goalPos.Z)
						hrp.CFrame = CFrame.new(safePos, ownerPos)
						hrp.AssemblyLinearVelocity = Vector3.zero
						hrp.AssemblyAngularVelocity = Vector3.zero
					elseif distToGoal > 2.0 then
						-- Динамическая скорость: питомец комфортно успевает за шагом, бегом и спринтом хозяина
						if speed > 18 then
							hum.WalkSpeed = 24
						elseif speed > 7 then
							hum.WalkSpeed = 18
						else
							hum.WalkSpeed = 15
						end
						hum:MoveTo(goalPos)
					else
						-- Питомец находится в своей позиции построения — спокойно стоит
						hum:MoveTo(petPos)
					end
				end
			end
		end
	end
end)
