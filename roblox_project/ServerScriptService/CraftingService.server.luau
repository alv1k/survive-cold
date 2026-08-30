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

-- 1. Функция проверки ресурсов у игрока
local function hasResources(player, requirements)
	for resourceName, amountRequired in pairs(requirements) do
		local currentVal = player:GetAttribute(resourceName) or 0
		if currentVal < amountRequired then
			return false
		end
	end
	return true
end

-- 2. Функция списания ресурсов
local function deductResources(player, requirements)
	for resourceName, amountRequired in pairs(requirements) do
		local currentVal = player:GetAttribute(resourceName) or 0
		player:SetAttribute(resourceName, math.max(0, currentVal - amountRequired))
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

-- 4. Обработка крафта предметов
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

		-- Б) Разблокировка оружия и выдача бонуса патронов
		if recipe.IsWeapon then
			player:SetAttribute("UnlockedWeapon_" .. recipeKey, true)
			if recipe.BonusAmmo then
				local currentAmmo = player:GetAttribute(recipe.BonusAmmo.AmmoType) or 0
				player:SetAttribute(recipe.BonusAmmo.AmmoType, currentAmmo + recipe.BonusAmmo.Count)
			end
			-- Выдача Tool в рюкзак игрока
			local backpack = player:FindFirstChildOfClass("Backpack")
			if backpack then
				local weaponTool = Instance.new("Tool")
				weaponTool.Name = recipe.DisplayName
				weaponTool:SetAttribute("IsWeapon", true)
				weaponTool:SetAttribute("WeaponType", recipe.WeaponType)
				weaponTool:SetAttribute("Damage", recipe.Damage)
				if recipe.AmmoType then
					weaponTool:SetAttribute("AmmoType", recipe.AmmoType)
				end
				weaponTool.Parent = backpack
			end
			print(string.format("⚔️ %s скрафтил оружие: %s!", player.Name, recipe.DisplayName))
			return
		end

		-- В) Расширение рюкзака (7 или 9 слотов)
		if recipe.SlotsUpgrade then
			local currentSlots = player:GetAttribute("MaxSlots") or 5
			if recipe.SlotsUpgrade > currentSlots then
				player:SetAttribute("MaxSlots", recipe.SlotsUpgrade)
				print(string.format("🎒 %s увеличил вместимость рюкзака до %d слотов!", player.Name, recipe.SlotsUpgrade))
			end
			return
		end

		-- Г) Меховая одежда
		if recipe.ClothingLevel then
			local currentCloth = player:GetAttribute("ClothingLevel") or 0
			if recipe.ClothingLevel > currentCloth then
				player:SetAttribute("ClothingLevel", recipe.ClothingLevel)
				player:SetAttribute("ClothingProtection", recipe.ClothingProtection)
				print(string.format("🧥 %s изготовил костюм Lvl %d (%s)!", player.Name, recipe.ClothingLevel, recipe.DisplayName))
			end
			return
		end

		-- Д) Постройка Турелей и Стен в мире
		local char = player.Character
		if not char or not char:FindFirstChild("HumanoidRootPart") then return end
		local spawnPos = targetPosition or (char.HumanoidRootPart.CFrame * CFrame.new(0, 0, -6)).Position

		if recipe.Category == "Turrets" or recipe.Category == "Structures" then
			local newModel = Instance.new("Model")
			newModel.Name = recipe.DisplayName

			local basePart = Instance.new("Part")
			basePart.Name = "PrimaryPart"
			basePart.Size = (recipe.Category == "Structures") and Vector3.new(12, 6, 2) or Vector3.new(4, 5, 4)
			basePart.Position = spawnPos
			basePart.Anchored = true
			basePart.Material = (recipe.Category == "Structures") and Enum.Material.WoodPlanks or Enum.Material.DiamondPlate
			basePart.BrickColor = recipe.IsHeavy and BrickColor.new("Bright orange") or BrickColor.new("Dark stone grey")
			basePart.Parent = newModel
			newModel.PrimaryPart = basePart

			if recipe.Category == "Turrets" then
				newModel:SetAttribute("Range", recipe.Range)
				newModel:SetAttribute("Damage", recipe.Damage)
				newModel:SetAttribute("FireRate", recipe.FireRate)
				newModel:SetAttribute("IsHeavy", recipe.IsHeavy or false)
				newModel.Parent = workspace:FindFirstChild("Turrets") or workspace
			else
				basePart:SetAttribute("Health", recipe.Health or 100)
				newModel.Parent = workspace:FindFirstChild("Walls") or workspace
			end
			print(string.format("🛠️ %s построил: %s!", player.Name, recipe.DisplayName))
		end
	end
end)

-- 5. Инициализация 16 Сундучков Деталей (Part Chests) по всей карте
local PartChestsFolder = workspace:FindFirstChild("PartChests") or Instance.new("Folder", workspace)
PartChestsFolder.Name = "PartChests"

local CHEST_LOCATIONS = {
	Vector3.new(-220, 2, -180), Vector3.new(-150, 2, 240), Vector3.new(-320, 2, 80), Vector3.new(-90, 2, -310),
	Vector3.new(180, 2, -260),  Vector3.new(280, 2, 190),  Vector3.new(350, 2, -120), Vector3.new(120, 2, 340),
	Vector3.new(-420, 2, -140), Vector3.new(-260, 2, -400), Vector3.new(-380, 2, 310), Vector3.new(420, 2, 280),
	Vector3.new(480, 2, -220),  Vector3.new(210, 2, -450), Vector3.new(-180, 2, 440), Vector3.new(360, 2, 420)
}

for i, loc in ipairs(CHEST_LOCATIONS) do
	local chestPart = Instance.new("Part")
	chestPart.Name = "PartChest_" .. i
	chestPart.Size = Vector3.new(3, 2.5, 2.5)
	chestPart.Position = loc
	chestPart.Anchored = true
	chestPart.Material = Enum.Material.Metal
	chestPart.BrickColor = BrickColor.new("Cyan")
	chestPart.Parent = PartChestsFolder

	local prompt = Instance.new("ProximityPrompt", chestPart)
	prompt.ActionText = "Взломать кованый замок и открыть"
	prompt.ObjectText = "📦 [⚙️ Сундук Деталей]"
	prompt.HoldDuration = 0.8

	prompt.Triggered:Connect(function(player)
		local partsCount = math.random(1, 2)
		local currentParts = player:GetAttribute("Parts") or 0
		player:SetAttribute("Parts", currentParts + partsCount)
		print(string.format("📦 %s открыл сундучок и нашел %dx ⚙️ Деталей! (Всего: %d)", player.Name, partsCount, currentParts + partsCount))
		
		prompt.Enabled = false
		chestPart.Transparency = 0.6
		chestPart.BrickColor = BrickColor.new("Dark stone grey")
		
		-- Респавн сундука через 3 минуты
		task.delay(180, function()
			chestPart.Transparency = 0
			chestPart.BrickColor = BrickColor.new("Cyan")
			prompt.Enabled = true
		end)
	end)
end

