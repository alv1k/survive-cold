--[[
    PetService.server.luau
    Серверная система Питомцев (Снежный Лис, Ледяной Волк, Полярный Медведь):
    - Отогрев ледяных глыб факелом
    - Голод и кормление (любимые блюда дают +65% сытости)
    - Уход в лес через 60 сек голода (Starvation Runaway)
    - Режимы: В походе (follow) / Отдых дома на лежанке (stay_home)
    - Уникальные баффы хозяину (Лис: стамина + радар, Волк: урон + скорость, Медведь: тепло)
    - Полная физическая стабильность (HumanoidRootPart, CanCollide, HipHeight, Motor6D)
--]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local PhysicsService = game:GetService("PhysicsService")

local SurfaceUtil = require(ReplicatedStorage:WaitForChild("SurfaceUtil"))
local GeneratedModels = ReplicatedStorage:WaitForChild("GeneratedModels")
local WolfGenerator = require(GeneratedModels:WaitForChild("Wolf"))
local WolfPupGenerator = require(GeneratedModels:WaitForChild("WolfPup"))

-- Папка Remotes
local RemotesFolder = ReplicatedStorage:FindFirstChild("Remotes") or Instance.new("Folder", ReplicatedStorage)
RemotesFolder.Name = "Remotes"

local FeedPetRemote = RemotesFolder:FindFirstChild("FeedPet") or Instance.new("RemoteEvent", RemotesFolder)
FeedPetRemote.Name = "FeedPet"

local TogglePetModeRemote = RemotesFolder:FindFirstChild("TogglePetMode") or Instance.new("RemoteEvent", RemotesFolder)
TogglePetModeRemote.Name = "TogglePetMode"

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
		IceLocation = Vector3.new(-200, 3, -150),
		FavoriteFoods = { Bar = true, Chips = true },
		Desc = "+35% реген выносливости & Радар реликвий"
	},
	Wolf = {
		Name = "🐺 Ледяной Волчонок",
		IceLocation = Vector3.new(16.5, 2.5, 14.0), -- 🏡 Рядом с домом на заснеженном дворе у крыльца
		FavoriteFoods = { Steak = true, Soup = true },
		Desc = "+25% урон оружия & +10% скорость бега"
	},
	Bear = {
		Name = "🐻 Полярный Медвежонок",
		IceLocation = Vector3.new(100, 3, 450),
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
	local frozenPup = nil
	if petId == "Wolf" then
		frozenPup = WolfPupGenerator.create(iceBlock, CFrame.new(exactIcePos - Vector3.new(0, 1.2, 0)), {
			Scale = 1.35,
			Anchored = true,
			isAnimated = false
		})
		for _, part in ipairs(frozenPup:GetDescendants()) do
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

			local function addSubPart(name, size, cfOffset, material, color)
				local sub = Instance.new("Part")
				sub.Name = name
				sub.Size = size
				sub.CFrame = hrp.CFrame * cfOffset
				sub.Material = material or Enum.Material.Fabric
				sub.BrickColor = color or BrickColor.new("White")
				sub.CanCollide = false
				sub.Massless = true
				sub.Anchored = false
				sub.Parent = petModel

				local weld = Instance.new("WeldConstraint")
				weld.Name = "Weld_" .. name
				weld.Part0 = hrp
				weld.Part1 = sub
				weld.Parent = sub
				return sub
			end

			local function attachPetVisuals()
				if petId == "Fox" then
					-- 🦊 СНЕЖНЫЙ ЛИС: Оранжевый корпус, белая грудка, ушки, изумрудные глазки и пушистый хвост
					addSubPart("Body", Vector3.new(1.4, 1.2, 2.2), CFrame.new(0, 0, 0), Enum.Material.Fabric, BrickColor.new("Bright orange"))
					addSubPart("Chest", Vector3.new(1.1, 0.9, 1.1), CFrame.new(0, 0.1, -0.7), Enum.Material.Fabric, BrickColor.new("White"))
					addSubPart("Head", Vector3.new(1.1, 1.0, 1.2), CFrame.new(0, 0.6, -1.4), Enum.Material.Fabric, BrickColor.new("Bright orange"))
					addSubPart("Snout", Vector3.new(0.6, 0.45, 0.8), CFrame.new(0, 0.35, -2.0), Enum.Material.Fabric, BrickColor.new("White"))
					addSubPart("Nose", Vector3.new(0.2, 0.2, 0.2), CFrame.new(0, 0.45, -2.45), Enum.Material.SmoothPlastic, BrickColor.new("Really black"))
					addSubPart("EarL", Vector3.new(0.25, 0.6, 0.3), CFrame.new(-0.4, 1.2, -1.3) * CFrame.Angles(0, 0, math.rad(-15)), Enum.Material.Fabric, BrickColor.new("Bright orange"))
					addSubPart("EarR", Vector3.new(0.25, 0.6, 0.3), CFrame.new(0.4, 1.2, -1.3) * CFrame.Angles(0, 0, math.rad(15)), Enum.Material.Fabric, BrickColor.new("Bright orange"))
					addSubPart("EyeL", Vector3.new(0.18, 0.18, 0.18), CFrame.new(-0.28, 0.65, -1.9), Enum.Material.Neon, BrickColor.new("Lime green"))
					addSubPart("EyeR", Vector3.new(0.18, 0.18, 0.18), CFrame.new(0.28, 0.65, -1.9), Enum.Material.Neon, BrickColor.new("Lime green"))
					addSubPart("LegFL", Vector3.new(0.35, 0.9, 0.35), CFrame.new(-0.5, -0.7, -0.7), Enum.Material.Fabric, BrickColor.new("Dark stone grey"))
					addSubPart("LegFR", Vector3.new(0.35, 0.9, 0.35), CFrame.new(0.5, -0.7, -0.7), Enum.Material.Fabric, BrickColor.new("Dark stone grey"))
					addSubPart("LegBL", Vector3.new(0.4, 0.9, 0.4), CFrame.new(-0.5, -0.7, 0.7), Enum.Material.Fabric, BrickColor.new("Dark stone grey"))
					addSubPart("LegBR", Vector3.new(0.4, 0.9, 0.4), CFrame.new(0.5, -0.7, 0.7), Enum.Material.Fabric, BrickColor.new("Dark stone grey"))
					addSubPart("TailMain", Vector3.new(0.5, 0.5, 1.4), CFrame.new(0, 0.4, 1.6) * CFrame.Angles(math.rad(25), 0, 0), Enum.Material.Fabric, BrickColor.new("Bright orange"))
					addSubPart("TailTip", Vector3.new(0.4, 0.4, 0.6), CFrame.new(0, 0.7, 2.2) * CFrame.Angles(math.rad(30), 0, 0), Enum.Material.Fabric, BrickColor.new("White"))

				elseif petId == "Wolf" then
					-- 🐺 ЛЕДЯНОЙ ВОЛЧОНОК: Высокоточная очаровательная 3D Chibi модель, добрые аква-глазки, воротничок с колокольчиком и пушистый хвостик
					local halfHrpY = hrp.Size.Y / 2
					local hipHeight = petHum.HipHeight
					local offsetCF = CFrame.new(0, -(halfHrpY + hipHeight) + 0.12, 0)
					local wolfVisual = WolfPupGenerator.create(petModel, hrp.CFrame * offsetCF, {
						isPet = true,
						Scale = 1.60,
						isAnimated = true,
						EyeColor = Color3.fromRGB(34, 211, 238),
						Anchored = false
					})

					if wolfVisual and wolfVisual.PrimaryPart then
						wolfVisual.Name = "WolfPupVisual"
						local primary = wolfVisual.PrimaryPart

						local rootJoint = Instance.new("Motor6D")
						rootJoint.Name = "RootJoint"
						rootJoint.Part0 = hrp
						rootJoint.Part1 = primary
						rootJoint.C0 = hrp.CFrame:ToObjectSpace(primary.CFrame)
						rootJoint.C1 = CFrame.identity
						rootJoint:SetAttribute("RestC0", rootJoint.C0)
						rootJoint.Parent = hrp
					end

				elseif petId == "Bear" then
					-- 🐻 ПОЛЯРНЫЙ МЕДВЕЖОНОК: Толстенький белый мишка, круглые ушки и носик-пуговка
					addSubPart("Body", Vector3.new(2.2, 1.8, 2.8), CFrame.new(0, 0, 0), Enum.Material.Fabric, BrickColor.new("White"))
					addSubPart("Head", Vector3.new(1.6, 1.5, 1.6), CFrame.new(0, 0.8, -1.8), Enum.Material.Fabric, BrickColor.new("White"))
					addSubPart("Muzzle", Vector3.new(1.0, 0.8, 0.9), CFrame.new(0, 0.5, -2.5), Enum.Material.Fabric, BrickColor.new("White"))
					addSubPart("Nose", Vector3.new(0.35, 0.3, 0.3), CFrame.new(0, 0.7, -3.0), Enum.Material.SmoothPlastic, BrickColor.new("Really black"))
					addSubPart("EarL", Vector3.new(0.4, 0.4, 0.25), CFrame.new(-0.7, 1.6, -1.7), Enum.Material.Fabric, BrickColor.new("White"))
					addSubPart("EarR", Vector3.new(0.4, 0.4, 0.25), CFrame.new(0.7, 1.6, -1.7), Enum.Material.Fabric, BrickColor.new("White"))
					addSubPart("EyeL", Vector3.new(0.2, 0.2, 0.2), CFrame.new(-0.4, 0.95, -2.45), Enum.Material.SmoothPlastic, BrickColor.new("Really black"))
					addSubPart("EyeR", Vector3.new(0.2, 0.2, 0.2), CFrame.new(0.4, 0.95, -2.45), Enum.Material.SmoothPlastic, BrickColor.new("Really black"))
					addSubPart("LegFL", Vector3.new(0.65, 1.1, 0.65), CFrame.new(-0.85, -1.0, -0.9), Enum.Material.Fabric, BrickColor.new("White"))
					addSubPart("LegFR", Vector3.new(0.65, 1.1, 0.65), CFrame.new(0.85, -1.0, -0.9), Enum.Material.Fabric, BrickColor.new("White"))
					addSubPart("LegBL", Vector3.new(0.7, 1.1, 0.7), CFrame.new(-0.85, -1.0, 0.9), Enum.Material.Fabric, BrickColor.new("White"))
					addSubPart("LegBR", Vector3.new(0.7, 1.1, 0.7), CFrame.new(0.85, -1.0, 0.9), Enum.Material.Fabric, BrickColor.new("White"))
					addSubPart("Tail", Vector3.new(0.4, 0.4, 0.4), CFrame.new(0, 0.4, 1.5), Enum.Material.Fabric, BrickColor.new("White"))
				end
			end

			attachPetVisuals()
			setModelCollisionGroup(petModel, "Pets")
			petModel.Parent = PetsFolder

			print(string.format("🎉 %s отогрел и спас питомца: %s!", player.Name, cfg.Name))

		else
			print(string.format("⚠️ %s должен взять в руки зажженный Факел, чтобы отогреть лед!", player.Name))
		end
	end)
end

-- Кормление питомца
FeedPetRemote.OnServerEvent:Connect(function(player, petId, foodId)
	local pet = nil
	for _, p in ipairs(PetsFolder:GetChildren()) do
		if p:GetAttribute("OwnerUserId") == player.UserId and p:GetAttribute("PetId") == petId then
			pet = p
			break
		end
	end
	if not pet then return end

	local foodCount = player:GetAttribute("Food_" .. foodId) or 0
	if foodCount <= 0 then
		local altCount = player:GetAttribute(foodId) or 0
		if altCount <= 0 then return end
		player:SetAttribute(foodId, altCount - 1)
	else
		player:SetAttribute("Food_" .. foodId, foodCount - 1)
	end

	local cfg = PET_CONFIG[petId]
	local isFav = cfg.FavoriteFoods[foodId] or false
	local gain = isFav and 65 or 30
	local currentSat = pet:GetAttribute("Satiety") or 0
	local newSat = math.min(100, currentSat + gain)

	pet:SetAttribute("Satiety", newSat)
	pet:SetAttribute("StarveTimer", 0)
	print(string.format("🍖 %s покормил %s (%s). Сытость: %d%% %s", player.Name, cfg.Name, foodId, newSat, isFav and "❤️ Любимое лакомство!" or ""))
end)

-- Переключение режима питомца (Follow / Stay Home)
TogglePetModeRemote.OnServerEvent:Connect(function(player, petId)
	for _, pet in ipairs(PetsFolder:GetChildren()) do
		if pet:GetAttribute("OwnerUserId") == player.UserId and pet:GetAttribute("PetId") == petId then
			local currentMode = pet:GetAttribute("Mode") or "follow"
			local newMode = (currentMode == "follow") and "stay_home" or "follow"
			pet:SetAttribute("Mode", newMode)
			print(string.format("🐾 %s переключил режим %s на: %s", player.Name, petId, newMode))
			break
		end
	end
end)

-- Сохранение и перемещение питомца к хозяину при воскрешении союзником или за Robux
_G.PreservePlayerPetOnRevive = function(player, targetPos)
	for _, pet in ipairs(PetsFolder:GetChildren()) do
		if pet:GetAttribute("OwnerUserId") == player.UserId then
			local hrp = pet:FindFirstChild("HumanoidRootPart") or pet.PrimaryPart
			if hrp and targetPos then
				local groundY = SurfaceUtil.getGroundHeight(targetPos.X + 3, targetPos.Z + 3)
				hrp.CFrame = CFrame.new(targetPos.X + 3, groundY + 1.2, targetPos.Z + 3)
				hrp.AssemblyLinearVelocity = Vector3.zero
			end
			pet:SetAttribute("Mode", "follow")
			pet:SetAttribute("StarveTimer", 0)
			pet:SetAttribute("Satiety", math.max(60, pet:GetAttribute("Satiety") or 60))
			print(string.format("🐾 Питомец %s сохранен и телепортирован к воскресшему хозяину %s!", pet.Name, player.Name))
			break
		end
	end
end

-- Отправка питомца домой на лежанку при обычном возрождении в доме
_G.SendPlayerPetHome = function(player)
	for _, pet in ipairs(PetsFolder:GetChildren()) do
		if pet:GetAttribute("OwnerUserId") == player.UserId then
			local hrp = pet:FindFirstChild("HumanoidRootPart") or pet.PrimaryPart
			if hrp then
				local groundY = SurfaceUtil.getGroundHeight(8, 8)
				hrp.CFrame = CFrame.new(8, groundY + 1.2, 8)
				hrp.AssemblyLinearVelocity = Vector3.zero
			end
			pet:SetAttribute("Mode", "stay_home")
			pet:SetAttribute("StarveTimer", 0)
			print(string.format("🐾 Питомец %s отправлен отдыхать на лежанку в дом хозяина %s!", pet.Name, player.Name))
			break
		end
	end
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

				-- Уменьшение сытости
				local decay = (mode == "stay_home") and 0.20 or 0.50
				satiety = math.max(0, satiety - decay)
				pet:SetAttribute("Satiety", math.floor(satiety))

				if satiety <= 0 then
					starveTimer = starveTimer + 1
					pet:SetAttribute("StarveTimer", starveTimer)
					if starveTimer >= 60 then
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

-- Плавное и точное следование питомцев за игроками (через нативный Humanoid:MoveTo на полной скорости 60 FPS)
local lastFollowUpdate = 0
RunService.Heartbeat:Connect(function()
	local now = os.clock()
	if now - lastFollowUpdate < 0.15 then return end
	lastFollowUpdate = now

	for _, pet in ipairs(PetsFolder:GetChildren()) do
		if pet:IsA("Model") and pet:GetAttribute("OwnerUserId") then
			local mode = pet:GetAttribute("Mode") or "follow"
			local ownerId = pet:GetAttribute("OwnerUserId")
			local owner = Players:GetPlayerByUserId(ownerId)
			local hum = pet:FindFirstChildOfClass("Humanoid")
			local hrp = pet:FindFirstChild("HumanoidRootPart") or pet.PrimaryPart

			if owner and owner.Character and mode == "follow" and hum and hum.Health > 0 and hrp then
				local ownerHrp = owner.Character:FindFirstChild("HumanoidRootPart")
				local ownerHum = owner.Character:FindFirstChildOfClass("Humanoid")

				if ownerHrp and ownerHum and ownerHum.Health > 0 then
					local petPos = hrp.Position
					local ownerPos = ownerHrp.Position
					local dist = (petPos - ownerPos).Magnitude

					-- Если питомец провалился под карту или игрок очень далеко телепортировался (> 80 studs)
					if petPos.Y < -50 or dist > 80 then
						local safeGroundY = SurfaceUtil.getGroundHeight(ownerPos.X + 3.5, ownerPos.Z + 3.5)
						local safePos = Vector3.new(ownerPos.X + 3.5, safeGroundY + 1.5, ownerPos.Z + 3.5)
						hrp.CFrame = CFrame.new(safePos, ownerPos)
						hrp.AssemblyLinearVelocity = Vector3.zero
						hrp.AssemblyAngularVelocity = Vector3.zero
					elseif dist > 6.0 then
						-- Динамическая скорость: питомец комфортно успевает за шагом, бегом и спринтом хозяина
						local speed = ownerHrp.AssemblyLinearVelocity.Magnitude
						if speed > 18 then
							hum.WalkSpeed = 22
						elseif speed > 7 then
							hum.WalkSpeed = 17
						else
							hum.WalkSpeed = 14
						end

						-- Точка позади и справа от игрока
						local targetPos = ownerHrp.CFrame:PointToWorldSpace(Vector3.new(3.5, 0, 3.5))
						local groundY = SurfaceUtil.getGroundHeight(targetPos.X, targetPos.Z)
						hum:MoveTo(Vector3.new(targetPos.X, groundY, targetPos.Z))
					else
						-- Питомец рядом — останавливается без толкания хозяина
						hum:MoveTo(petPos)
					end
				end
			end
		end
	end
end)
