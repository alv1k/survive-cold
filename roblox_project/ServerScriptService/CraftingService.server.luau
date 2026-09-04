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

local OpenWorkbenchRemote = RemotesFolder:FindFirstChild("OpenWorkbench") or Instance.new("RemoteEvent", RemotesFolder)
OpenWorkbenchRemote.Name = "OpenWorkbench"

local ProximityPromptService = game:GetService("ProximityPromptService")
ProximityPromptService.PromptTriggered:Connect(function(prompt, triggerPlayer)
	if prompt.Name == "WorkbenchPrompt" or (prompt.Parent and prompt.Parent.Name == "Workbench") or prompt:GetAttribute("IsWorkbench") then
		OpenWorkbenchRemote:FireClient(triggerPlayer)
	end
end)

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


