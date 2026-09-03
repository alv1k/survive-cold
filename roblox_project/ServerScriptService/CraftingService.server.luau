--[[
    CraftingService.server.luau
    Серверный сервис для Верстака (5 Уровней), Крафта Оружия, Боеприпасов и Сундучков Деталей.
--]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local CraftingRecipes = require(ReplicatedStorage:WaitForChild("CraftingRecipes"))

-- Папка RemoteEvents
local RemotesFolder = ReplicatedStorage:FindFirstChild("Remotes") or Instance.new("Folder", ReplicatedStorage)
RemotesFolder.Name = "Remotes"

local CraftItemRemote = RemotesFolder:FindFirstChild("CraftItem") or Instance.new("RemoteEvent", RemotesFolder)
CraftItemRemote.Name = "CraftItem"

local UpgradeWorkbenchRemote = RemotesFolder:FindFirstChild("UpgradeWorkbench") or Instance.new("RemoteEvent", RemotesFolder)
UpgradeWorkbenchRemote.Name = "UpgradeWorkbench"

-- 1. Функция точного подсчета ресурсов у игрока (в атрибутах и в рюкзаке)
local function countPlayerResource(player, resourceName)
	local attrCount = player:GetAttribute(resourceName) or 0
	local toolCount = 0
	local backpack = player:FindFirstChildOfClass("Backpack")
	local char = player.Character

	if backpack then
		for _, t in ipairs(backpack:GetChildren()) do
			if t:IsA("Tool") and t:GetAttribute("ItemKey") == resourceName then
				toolCount = toolCount + (t:GetAttribute("Count") or 1)
			end
		end
	end
	if char then
		for _, t in ipairs(char:GetChildren()) do
			if t:IsA("Tool") and t:GetAttribute("ItemKey") == resourceName then
				toolCount = toolCount + (t:GetAttribute("Count") or 1)
			end
		end
	end

	local total = math.max(attrCount, toolCount)
	player:SetAttribute(resourceName, total)
	return total
end

local function hasResources(player, requirements)
	for resourceName, amountRequired in pairs(requirements) do
		local currentVal = countPlayerResource(player, resourceName)
		if currentVal < amountRequired then
			return false
		end
	end
	return true
end

-- 2. Функция списания ресурсов из рюкзака и атрибутов
local function deductResources(player, requirements)
	local backpack = player:FindFirstChildOfClass("Backpack")
	local char = player.Character

	for resourceName, amountRequired in pairs(requirements) do
		local currentVal = countPlayerResource(player, resourceName)
		local remainingToDeduct = amountRequired

		local function deductFromContainer(container)
			if not container or remainingToDeduct <= 0 then return end
			for _, t in ipairs(container:GetChildren()) do
				if t:IsA("Tool") and t:GetAttribute("ItemKey") == resourceName then
					local curC = t:GetAttribute("Count") or 1
					if curC > remainingToDeduct then
						t:SetAttribute("Count", curC - remainingToDeduct)
						t.Name = string.format("%s (x%d)", t.Name:match("^[^%(]+") or t.Name, curC - remainingToDeduct)
						remainingToDeduct = 0
						break
					else
						remainingToDeduct = remainingToDeduct - curC
						t:Destroy()
					end
				end
			end
		end

		deductFromContainer(backpack)
		deductFromContainer(char)

		local finalCount = math.max(0, currentVal - amountRequired)
		player:SetAttribute(resourceName, finalCount)
	end
end

-- 3. Обработка улучшения Верстака
UpgradeWorkbenchRemote.OnServerEvent:Connect(function(player)
	local currentLvl = player:GetAttribute("WorkbenchLevel") or 1
	if currentLvl >= 5 then return end

	local tierConfig = CraftingRecipes.WorkbenchTiers[currentLvl]
	if not tierConfig or not tierConfig.UpgradeCost then return end

	if hasResources(player, tierConfig.UpgradeCost) then
		deductResources(player, tierConfig.UpgradeCost)
		local newLvl = currentLvl + 1
		player:SetAttribute("WorkbenchLevel", newLvl)
		print(string.format("🎉 %s улучшил Верстак до Уровня %d!", player.Name, newLvl))
	end
end)

-- 4. Обработка крафта предметов на верстаке
CraftItemRemote.OnServerEvent:Connect(function(player, recipeKey, targetPosition)
	local recipe = CraftingRecipes.Recipes[recipeKey]
	if not recipe then return end

	local playerWbLvl = player:GetAttribute("WorkbenchLevel") or 1
	if playerWbLvl < recipe.Tier then
		print(string.format("🔒 У %s недостаточный уровень верстака для %s (требуется Ур. %d)", player.Name, recipeKey, recipe.Tier))
		return
	end

	-- Проверка наличия предшествующего оружия
	if recipe.RequiredWeapon then
		local hasReq = player:GetAttribute("UnlockedWeapon_" .. recipe.RequiredWeapon)
		if not hasReq then
			print(string.format("🔒 У %s не разблокировано оружие %s для крафта %s", player.Name, recipe.RequiredWeapon, recipeKey))
			return
		end
	end

	if hasResources(player, recipe.Ingredients) then
		deductResources(player, recipe.Ingredients)

		-- А) Крафт патронов напрямую в карман боеприпасов (Ammo Pouch - НЕ занимает слот)
		if recipe.IsDirectAmmo and recipe.AmmoType then
			local currentAmmo = player:GetAttribute(recipe.AmmoType) or 0
			player:SetAttribute(recipe.AmmoType, currentAmmo + recipe.AmmoAmount)
			print(string.format("🏹 %s скрафтил +%d боеприпасов %s (Всего в сумке: %d)!", player.Name, recipe.AmmoAmount, recipe.AmmoType, currentAmmo + recipe.AmmoAmount))
			return
		end

		-- Б) Расширение рюкзака (7 или 9 слотов)
		if recipe.SlotsUpgrade then
			local currentSlots = player:GetAttribute("MaxSlots") or 5
			if recipe.SlotsUpgrade > currentSlots then
				player:SetAttribute("MaxSlots", recipe.SlotsUpgrade)
				print(string.format("🎒 %s увеличил вместимость рюкзака до %d слотов!", player.Name, recipe.SlotsUpgrade))
			end
			return
		end

		-- В) Меховая одежда
		if recipe.ClothingLevel then
			local currentCloth = player:GetAttribute("ClothingLevel") or 0
			if recipe.ClothingLevel > currentCloth then
				player:SetAttribute("ClothingLevel", recipe.ClothingLevel)
				player:SetAttribute("ClothingProtection", recipe.ClothingProtection)
				print(string.format("🧥 %s изготовил костюм Lvl %d (%s)!", player.Name, recipe.ClothingLevel, recipe.DisplayName))
			end
			return
		end

		-- Г) Постройка Турелей и Стен в мире
		if recipe.Category == "Turrets" or (recipe.Category == "Structures" and recipe.ResultItem ~= "SpikeTrap") then
			local char = player.Character
			if not char or not char:FindFirstChild("HumanoidRootPart") then return end
			local spawnPos = targetPosition or (char.HumanoidRootPart.CFrame * CFrame.new(0, 0, -6)).Position

			local newModel = Instance.new("Model")
			newModel.Name = recipe.DisplayName

			if recipe.Category == "Turrets" then
				local basePart = Instance.new("Part")
				basePart.Name = "Base"
				basePart.Size = Vector3.new(4, 0.8, 4)
				basePart.Position = spawnPos + Vector3.new(0, 0.4, 0)
				basePart.Anchored = true
				basePart.Material = Enum.Material.DiamondPlate
				basePart.BrickColor = recipe.IsHeavy and BrickColor.new("Bright orange") or BrickColor.new("Dark stone grey")
				basePart.Parent = newModel
				newModel.PrimaryPart = basePart

				local pillar = Instance.new("Part")
				pillar.Name = "Pillar"
				pillar.Size = Vector3.new(1.2, 2.2, 1.2)
				pillar.Position = basePart.Position + Vector3.new(0, 1.5, 0)
				pillar.Anchored = true
				pillar.Material = Enum.Material.Metal
				pillar.BrickColor = BrickColor.new("Black")
				pillar.Parent = newModel

				local head = Instance.new("Part")
				head.Name = "Head"
				head.Size = Vector3.new(2.2, 1.4, 3.0)
				head.Position = pillar.Position + Vector3.new(0, 1.6, 0)
				head.Anchored = true
				head.Material = Enum.Material.DiamondPlate
				head.BrickColor = recipe.IsHeavy and BrickColor.new("Bright orange") or BrickColor.new("Medium stone grey")
				head.Parent = newModel

				local statusLight = Instance.new("Part")
				statusLight.Name = "StatusLight"
				statusLight.Size = Vector3.new(0.5, 0.5, 0.5)
				statusLight.Position = head.Position + Vector3.new(0, 0.9, 0)
				statusLight.Anchored = true
				statusLight.Material = Enum.Material.Neon
				statusLight.BrickColor = BrickColor.new("Bright green")
				statusLight.Parent = newModel

				local smoke = Instance.new("Smoke", statusLight)
				smoke.Name = "BrokenSmoke"
				smoke.Size = 2.5
				smoke.Color = Color3.fromRGB(70, 70, 70)
				smoke.Opacity = 0.6
				smoke.Enabled = false

				newModel:SetAttribute("Range", recipe.Range)
				newModel:SetAttribute("Damage", recipe.Damage)
				newModel:SetAttribute("FireRate", recipe.FireRate)
				newModel:SetAttribute("IsHeavy", recipe.IsHeavy or false)
				newModel:SetAttribute("Durability", 10)
				newModel:SetAttribute("MaxDurability", 10)
				newModel:SetAttribute("IsBroken", false)

				local prompt = Instance.new("ProximityPrompt", basePart)
				prompt.ActionText = "Прочность: 10/10"
				prompt.ObjectText = recipe.DisplayName
				prompt.HoldDuration = 0.5
				prompt.MaxActivationDistance = 10
				prompt.RequiresLineOfSight = false

				newModel.Parent = workspace:FindFirstChild("Turrets") or workspace
			else
				local basePart = Instance.new("Part")
				basePart.Name = "PrimaryPart"
				basePart.Size = Vector3.new(12, 6, 2)
				basePart.Position = spawnPos + Vector3.new(0, 3, 0)
				basePart.Anchored = true
				basePart.Material = Enum.Material.WoodPlanks
				basePart.BrickColor = BrickColor.new("Dark orange")
				basePart.Parent = newModel
				newModel.PrimaryPart = basePart
				basePart:SetAttribute("Health", recipe.Health or 100)
				newModel.Parent = workspace:FindFirstChild("Walls") or workspace
			end

			print(string.format("🛠️ %s построил: %s!", player.Name, recipe.DisplayName))
			return
		end

		-- Д) Выдача любых предметов, инструментов, капканов и оружия в рюкзак (RabbitTrap, Torch, Spear, Slingshot, etc.)
		local resultKey = recipe.ResultItem or recipeKey
		local resultCount = recipe.ResultCount or 1

		if recipe.IsWeapon then
			player:SetAttribute("UnlockedWeapon_" .. recipeKey, true)
			if recipe.BonusAmmo then
				local currentAmmo = player:GetAttribute(recipe.BonusAmmo.AmmoType) or 0
				player:SetAttribute(recipe.BonusAmmo.AmmoType, currentAmmo + recipe.BonusAmmo.Count)
			end
		end

		local given = false
		if _G.GiveItemToPlayer then
			given = _G.GiveItemToPlayer(player, resultKey, resultCount)
		else
			local giveBindable = ReplicatedStorage:FindFirstChild("GiveItem")
			if giveBindable and giveBindable:IsA("BindableFunction") then
				given = giveBindable:Invoke(player, resultKey, resultCount)
			end
		end

		if not given then
			if _G.DropItemOnGround then
				_G.DropItemOnGround(player, resultKey, resultCount)
			end
			local ShowNotificationRemote = RemotesFolder:FindFirstChild("ShowNotification")
			if ShowNotificationRemote then
				ShowNotificationRemote:FireClient(player, string.format("⚠️ Рюкзак полон! %s упал на землю.", recipe.DisplayName))
			end
		end

		print(string.format("🛠️ %s успешно скрафтил: %s (x%d)!", player.Name, recipe.DisplayName, resultCount))
	end
end)

-- 5. Инициализация 16 Сундучков Деталей (Part Chests) с точной посадкой на рельеф
local PartChestsFolder = workspace:FindFirstChild("PartChests") or Instance.new("Folder", workspace)
PartChestsFolder.Name = "PartChests"

local CHEST_LOCATIONS = {
	Vector3.new(-450, 20, -480), Vector3.new(-380, 20, 620),  Vector3.new(-750, 20, 220),  Vector3.new(-240, 20, -850),
	Vector3.new(480, 20, -680),  Vector3.new(680, 20, 520),   Vector3.new(950, 20, -350),  Vector3.new(320, 20, 850),
	Vector3.new(-1150, 20, -450), Vector3.new(-650, 20, -1200), Vector3.new(-980, 20, 850),  Vector3.new(1150, 20, 750),
	Vector3.new(1250, 20, -650), Vector3.new(550, 20, -1350), Vector3.new(-520, 20, 1250), Vector3.new(980, 20, 1150)
}

local function getGroundHeight(pos)
	local rayOrigin = Vector3.new(pos.X, 100, pos.Z)
	local rayDirection = Vector3.new(0, -200, 0)
	local raycastParams = RaycastParams.new()
	raycastParams.FilterType = Enum.RaycastFilterType.Include
	raycastParams.FilterDescendantsInstances = { workspace.Terrain }

	local result = workspace:Raycast(rayOrigin, rayDirection, raycastParams)
	if result then
		return result.Position.Y
	end
	return 3.0
end

local function buildPartChest(index, loc)
	local groundY = getGroundHeight(loc)
	local chestPos = Vector3.new(loc.X, groundY + 1.2, loc.Z)

	local chestModel = Instance.new("Model")
	chestModel.Name = "PartChest_" .. index

	-- 1. Корпус сундука (Ровный деревянный короб)
	local base = Instance.new("Part")
	base.Name = "Base"
	base.Size = Vector3.new(3.8, 2.2, 2.6)
	base.Position = chestPos
	base.Anchored = true
	base.CanCollide = true
	base.Material = Enum.Material.WoodPlanks
	base.BrickColor = BrickColor.new("Dark orange")
	base.Parent = chestModel

	-- 2. Крышка с металлической кованой отделкой
	local lid = Instance.new("Part")
	lid.Name = "Lid"
	lid.Size = Vector3.new(4.0, 0.7, 2.8)
	lid.Position = chestPos + Vector3.new(0, 1.35, 0)
	lid.Anchored = true
	lid.CanCollide = true
	lid.Material = Enum.Material.Metal
	lid.BrickColor = BrickColor.new("Dark stone grey")
	lid.Parent = chestModel

	-- 3. Светящийся неоновый замок деталей (Cyan)
	local lock = Instance.new("Part")
	lock.Name = "Lock"
	lock.Size = Vector3.new(0.8, 0.8, 0.4)
	lock.Position = chestPos + Vector3.new(0, 0.3, 1.35)
	lock.Anchored = true
	lock.CanCollide = false
	lock.Material = Enum.Material.Neon
	lock.BrickColor = BrickColor.new("Cyan")
	lock.Parent = chestModel

	local light = Instance.new("PointLight", lock)
	light.Color = Color3.fromRGB(56, 189, 248)
	light.Range = 12
	light.Brightness = 1.5

	-- 4. Стабильный ProximityPrompt (Всегда виден, без сбоев видимости)
	local prompt = Instance.new("ProximityPrompt", base)
	prompt.ActionText = "Открыть сундук деталей"
	prompt.ObjectText = "⚙️ Кованый сундук"
	prompt.HoldDuration = 0 -- Моментальное открытие
	prompt.MaxActivationDistance = 14
	prompt.RequiresLineOfSight = false -- 100% стабильность показа подсказки!

	prompt.Triggered:Connect(function(player)
		local partsCount = math.random(1, 2)
		local given = false

		if _G.GiveItemToPlayer then
			given = _G.GiveItemToPlayer(player, "Parts", partsCount)
		else
			local giveBindable = ReplicatedStorage:FindFirstChild("GiveItem")
			if giveBindable and giveBindable:IsA("BindableFunction") then
				given = giveBindable:Invoke(player, "Parts", partsCount)
			end
		end

		if not given then
			-- Рюкзак полон! Сбрасываем найденные детали на землю прямо у сундука
			if _G.DropItemOnGround then
				_G.DropItemOnGround(player, "Parts", partsCount, chestPos + Vector3.new(0, 0.5, 2.5))
			end
			local ShowNotificationRemote = RemotesFolder:FindFirstChild("ShowNotification")
			if ShowNotificationRemote then
				ShowNotificationRemote:FireClient(player, string.format("⚠️ Рюкзак полон! ⚙️ Детали (x%d) упали на землю у сундука.", partsCount))
			end
			print(string.format("📦 %s открыл сундук (рюкзак полон), детали (x%d) упали на землю!", player.Name, partsCount))
		else
			print(string.format("📦 %s открыл сундучок и нашел %dx ⚙️ Деталей в рюкзак!", player.Name, partsCount))
		end

		prompt.Enabled = false
		base.Transparency = 0.5
		lid.Transparency = 0.5
		lock.Transparency = 0.8
		light.Enabled = false

		-- Респавн сундука через 3 минуты
		task.delay(180, function()
			if base and base.Parent then
				base.Transparency = 0
				lid.Transparency = 0
				lock.Transparency = 0
				light.Enabled = true
				prompt.Enabled = true
			end
		end)
	end)

	chestModel.PrimaryPart = base
	chestModel.Parent = PartChestsFolder
end

for i, loc in ipairs(CHEST_LOCATIONS) do
	buildPartChest(i, loc)
end
