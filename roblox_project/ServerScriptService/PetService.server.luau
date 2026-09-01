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

			-- Создание спутника
			local petModel = Instance.new("Model")
			petModel.Name = "Pet_" .. petId
			petModel:SetAttribute("PetId", petId)
			petModel:SetAttribute("OwnerUserId", player.UserId)
			petModel:SetAttribute("Satiety", 100)
			petModel:SetAttribute("Mode", "follow")
			petModel:SetAttribute("StarveTimer", 0)

			local body = Instance.new("Part")
			body.Name = "PrimaryPart"
			body.Size = Vector3.new(2, 2, 3)
			body.Position = cfg.IceLocation
			body.Anchored = false
			body.Material = Enum.Material.Fabric
			body.BrickColor = (petId == "Fox") and BrickColor.new("Bright orange") or ((petId == "Wolf") and BrickColor.new("Medium stone grey") or BrickColor.new("White"))
			body.Parent = petModel
			petModel.PrimaryPart = body
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
