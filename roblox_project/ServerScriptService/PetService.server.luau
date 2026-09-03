--[[
    PetService.server.luau
    Серверная система Питомцев (Снежный Лис, Ледяной Волк, Полярный Медведь):
    - Отогрев ледяных глыб факелом
    - Голод и кормление (любимые блюда дают +65% сытости)
    - Уход в лес через 60 сек голода (Starvation Runaway)
    - Режимы: В походе (follow) / Отдых дома на лежанке (stay_home)
    - Уникальные баффы хозяину (Лис: стамина + радар, Волк: урон + скорость, Медведь: тепло)
--]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

-- Папка Remotes
local RemotesFolder = ReplicatedStorage:FindFirstChild("Remotes") or Instance.new("Folder", ReplicatedStorage)
RemotesFolder.Name = "Remotes"

local FeedPetRemote = RemotesFolder:FindFirstChild("FeedPet") or Instance.new("RemoteEvent", RemotesFolder)
FeedPetRemote.Name = "FeedPet"

local TogglePetModeRemote = RemotesFolder:FindFirstChild("TogglePetMode") or Instance.new("RemoteEvent", RemotesFolder)
TogglePetModeRemote.Name = "TogglePetMode"

local PET_CONFIG = {
	Fox = {
		Name = "🦊 Снежный Лис",
		IceLocation = Vector3.new(-200, 3, -150),
		FavoriteFoods = { Bar = true, Chips = true },
		Desc = "+35% реген выносливости & Радар реликвий"
	},
	Wolf = {
		Name = "🐺 Ледяной Волчонок",
		IceLocation = Vector3.new(450, 3, 200),
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
	local iceBlock = Instance.new("Part")
	iceBlock.Name = "FrozenPet_" .. petId
	iceBlock.Size = Vector3.new(4, 5, 4)
	iceBlock.Position = cfg.IceLocation
	iceBlock.Anchored = true
	iceBlock.Material = Enum.Material.Ice
	iceBlock.BrickColor = BrickColor.new("Pastel light blue")
	iceBlock.Transparency = 0.4
	iceBlock.Parent = PetsFolder

	local prompt = Instance.new("ProximityPrompt", iceBlock)
	prompt.ActionText = "Отогреть Факелом"
	prompt.ObjectText = cfg.Name .. " (Закован во льду)"
	prompt.HoldDuration = 1.5

	prompt.Triggered:Connect(function(player)
		local char = player.Character
		if not char then return end
		local equippedTool = char:FindFirstChildOfClass("Tool")
		local hasTorch = equippedTool and (equippedTool.Name:find("Факел") or equippedTool.Name:find("Torch"))

		if hasTorch then
			iceBlock:Destroy()

			local function addSubPart(name, size, cfOffset, material, color, isNeon)
				local sub = Instance.new("Part")
				sub.Name = name
				sub.Size = size
				sub.CFrame = body.CFrame * cfOffset
				sub.Material = material or Enum.Material.Fabric
				sub.BrickColor = color or BrickColor.new("White")
				sub.CanCollide = false
				sub.Massless = true
				sub.Parent = petModel

				local weld = Instance.new("WeldConstraint")
				weld.Part0 = body
				weld.Part1 = sub
				weld.Parent = sub
				return sub
			end

			local function attachPetVisuals()
				if petId == "Fox" then
					-- 🦊 СНЕЖНЫЙ ЛИС: Оранжевый корпус, белая грудка, ушки, изумрудные глазки и пушистый хвост
					body.Size = Vector3.new(1.4, 1.2, 2.2)
					body.Material = Enum.Material.Fabric
					body.BrickColor = BrickColor.new("Bright orange")

					-- Белая манишка на груди
					addSubPart("Chest", Vector3.new(1.1, 0.9, 1.1), CFrame.new(0, 0.1, -0.7), Enum.Material.Fabric, BrickColor.new("White"))

					-- Голова и носик
					addSubPart("Head", Vector3.new(1.1, 1.0, 1.2), CFrame.new(0, 0.6, -1.4), Enum.Material.Fabric, BrickColor.new("Bright orange"))
					addSubPart("Snout", Vector3.new(0.6, 0.45, 0.8), CFrame.new(0, 0.35, -2.0), Enum.Material.Fabric, BrickColor.new("White"))
					addSubPart("Nose", Vector3.new(0.2, 0.2, 0.2), CFrame.new(0, 0.45, -2.45), Enum.Material.SmoothPlastic, BrickColor.new("Really black"))

					-- Ушки
					addSubPart("EarL", Vector3.new(0.25, 0.6, 0.3), CFrame.new(-0.4, 1.2, -1.3) * CFrame.Angles(0, 0, math.rad(-15)), Enum.Material.Fabric, BrickColor.new("Bright orange"))
					addSubPart("EarR", Vector3.new(0.25, 0.6, 0.3), CFrame.new(0.4, 1.2, -1.3) * CFrame.Angles(0, 0, math.rad(15)), Enum.Material.Fabric, BrickColor.new("Bright orange"))

					-- Изумрудные глазки
					addSubPart("EyeL", Vector3.new(0.18, 0.18, 0.18), CFrame.new(-0.28, 0.65, -1.9), Enum.Material.Neon, BrickColor.new("Lime green"))
					addSubPart("EyeR", Vector3.new(0.18, 0.18, 0.18), CFrame.new(0.28, 0.65, -1.9), Enum.Material.Neon, BrickColor.new("Lime green"))

					-- 4 Лапки
					addSubPart("LegFL", Vector3.new(0.35, 0.9, 0.35), CFrame.new(-0.5, -0.7, -0.7), Enum.Material.Fabric, BrickColor.new("Dark stone grey"))
					addSubPart("LegFR", Vector3.new(0.35, 0.9, 0.35), CFrame.new(0.5, -0.7, -0.7), Enum.Material.Fabric, BrickColor.new("Dark stone grey"))
					addSubPart("LegBL", Vector3.new(0.4, 0.9, 0.4), CFrame.new(-0.5, -0.7, 0.7), Enum.Material.Fabric, BrickColor.new("Dark stone grey"))
					addSubPart("LegBR", Vector3.new(0.4, 0.9, 0.4), CFrame.new(0.5, -0.7, 0.7), Enum.Material.Fabric, BrickColor.new("Dark stone grey"))

					-- Большой хвост с белым кончиком
					addSubPart("TailMain", Vector3.new(0.5, 0.5, 1.4), CFrame.new(0, 0.4, 1.6) * CFrame.Angles(math.rad(25), 0, 0), Enum.Material.Fabric, BrickColor.new("Bright orange"))
					addSubPart("TailTip", Vector3.new(0.4, 0.4, 0.6), CFrame.new(0, 0.7, 2.2) * CFrame.Angles(math.rad(30), 0, 0), Enum.Material.Fabric, BrickColor.new("White"))

				elseif petId == "Wolf" then
					-- 🐺 ЛЕДЯНОЙ ВОЛЧОНОК: Серебристый мех, небесно-голубые глазки
					body.Size = Vector3.new(1.5, 1.3, 2.4)
					body.Material = Enum.Material.Fabric
					body.BrickColor = BrickColor.new("Medium stone grey")

					addSubPart("Head", Vector3.new(1.2, 1.1, 1.3), CFrame.new(0, 0.6, -1.5), Enum.Material.Fabric, BrickColor.new("Medium stone grey"))
					addSubPart("Snout", Vector3.new(0.7, 0.5, 0.9), CFrame.new(0, 0.4, -2.1), Enum.Material.Fabric, BrickColor.new("Dark stone grey"))
					addSubPart("Nose", Vector3.new(0.2, 0.2, 0.2), CFrame.new(0, 0.55, -2.6), Enum.Material.SmoothPlastic, BrickColor.new("Really black"))

					addSubPart("EarL", Vector3.new(0.25, 0.6, 0.3), CFrame.new(-0.45, 1.25, -1.4) * CFrame.Angles(0, 0, math.rad(-12)), Enum.Material.Fabric, BrickColor.new("Dark stone grey"))
					addSubPart("EarR", Vector3.new(0.25, 0.6, 0.3), CFrame.new(0.45, 1.25, -1.4) * CFrame.Angles(0, 0, math.rad(12)), Enum.Material.Fabric, BrickColor.new("Dark stone grey"))

					addSubPart("EyeL", Vector3.new(0.2, 0.2, 0.2), CFrame.new(-0.3, 0.7, -2.0), Enum.Material.Neon, BrickColor.new("Pastel light blue"))
					addSubPart("EyeR", Vector3.new(0.2, 0.2, 0.2), CFrame.new(0.3, 0.7, -2.0), Enum.Material.Neon, BrickColor.new("Pastel light blue"))

					addSubPart("LegFL", Vector3.new(0.4, 1.0, 0.4), CFrame.new(-0.55, -0.8, -0.8), Enum.Material.Fabric, BrickColor.new("Dark stone grey"))
					addSubPart("LegFR", Vector3.new(0.4, 1.0, 0.4), CFrame.new(0.55, -0.8, -0.8), Enum.Material.Fabric, BrickColor.new("Dark stone grey"))
					addSubPart("LegBL", Vector3.new(0.45, 1.0, 0.45), CFrame.new(-0.55, -0.8, 0.8), Enum.Material.Fabric, BrickColor.new("Dark stone grey"))
					addSubPart("LegBR", Vector3.new(0.45, 1.0, 0.45), CFrame.new(0.55, -0.8, 0.8), Enum.Material.Fabric, BrickColor.new("Dark stone grey"))

					addSubPart("Tail", Vector3.new(0.45, 0.45, 1.6), CFrame.new(0, 0.35, 1.7) * CFrame.Angles(math.rad(-20), 0, 0), Enum.Material.Fabric, BrickColor.new("Medium stone grey"))

				elseif petId == "Bear" then
					-- 🐻 ПОЛЯРНЫЙ МЕДВЕЖОНОК: Толстенький белый мишка, круглые ушки и носик-пуговка
					body.Size = Vector3.new(2.2, 1.8, 2.8)
					body.Material = Enum.Material.Fabric
					body.BrickColor = BrickColor.new("White")

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
			local primary = pet.PrimaryPart or pet:FindFirstChildWhichIsA("BasePart")
			if primary and targetPos then
				primary.CFrame = CFrame.new(targetPos + Vector3.new(3, 1, 3))
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
			local primary = pet.PrimaryPart or pet:FindFirstChildWhichIsA("BasePart")
			if primary then
				primary.CFrame = CFrame.new(Vector3.new(8, 2, 8))
			end
			pet:SetAttribute("Mode", "stay_home")
			pet:SetAttribute("StarveTimer", 0)
			print(string.format("🐾 Питомец %s отправлен отдыхать на лежанку в дом хозяина %s!", pet.Name, player.Name))
			break
		end
	end
end

-- Цикл обновления состояния, следования и баффов питомцев (каждую 1 сек)
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

				-- Следование за хозяином в режиме "follow"
				if owner and owner.Character and mode == "follow" then
					local hrp = owner.Character:FindFirstChild("HumanoidRootPart")
					local primary = pet.PrimaryPart or pet:FindFirstChildWhichIsA("BasePart")
					if hrp and primary then
						local dist = (primary.Position - hrp.Position).Magnitude
						if dist > 8 then
							local targetPos = hrp.Position - hrp.CFrame.LookVector * 5 + Vector3.new(2, 0, 0)
							primary.CFrame = primary.CFrame:Lerp(CFrame.new(targetPos, hrp.Position), 0.35)
						end
					end
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
