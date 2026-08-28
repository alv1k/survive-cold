--[[
    CraftingService.server.luau
    Обработка запросов игроков на крафтинг предметов, костров и турелей.
--]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local CraftingRecipes = require(ReplicatedStorage:WaitForChild("CraftingRecipes"))

-- RemoteEvent для крафта
local RemotesFolder = ReplicatedStorage:FindFirstChild("Remotes") or Instance.new("Folder", ReplicatedStorage)
RemotesFolder.Name = "Remotes"

local CraftItemRemote = RemotesFolder:FindFirstChild("CraftItem") or Instance.new("RemoteEvent", RemotesFolder)
CraftItemRemote.Name = "CraftItem"

-- Проверка инвентаря игрока
local function hasResources(player, requirements)
	local leaderstats = player:FindFirstChild("leaderstats")
	if not leaderstats then return false end
	
	for resourceName, amountRequired in pairs(requirements) do
		local valObj = leaderstats:FindFirstChild(resourceName)
		if not valObj or valObj.Value < amountRequired then
			return false
		end
	end
	return true
end

-- Списание ресурсов
local function deductResources(player, requirements)
	local leaderstats = player:FindFirstChild("leaderstats")
	for resourceName, amountRequired in pairs(requirements) do
		local valObj = leaderstats:FindFirstChild(resourceName)
		if valObj then
			valObj.Value = valObj.Value - amountRequired
		end
	end
end

-- Обработка вызова крафта от клиента
CraftItemRemote.OnServerEvent:Connect(function(player, recipeKey, targetPosition)
	local recipe = CraftingRecipes[recipeKey]
	if not recipe then return end
	
	if hasResources(player, recipe.Requirements) then
		deductResources(player, recipe.Requirements)
		
		local char = player.Character
		if not char or not char:FindFirstChild("HumanoidRootPart") then return end
		
		local spawnPos = targetPosition or (char.HumanoidRootPart.CFrame * CFrame.new(0, 0, -6)).Position
		
		-- Постройка костра или турели
		if recipe.Category == "Structures" or recipe.Category == "Turrets" then
			local newModel = Instance.new("Model")
			newModel.Name = recipe.DisplayName
			
			local basePart = Instance.new("Part")
			basePart.Name = "PrimaryPart"
			basePart.Size = Vector3.new(4, 4, 4)
			basePart.Position = spawnPos
			basePart.Anchored = true
			basePart.Material = Enum.Material.Wood
			basePart.BrickColor = recipe.Category == "Turrets" and BrickColor.new("Dark stone grey") or BrickColor.new("Reddish brown")
			basePart.Parent = newModel
			newModel.PrimaryPart = basePart
			
			if recipe.HeatRadius then
				basePart:SetAttribute("HeatRadius", recipe.HeatRadius)
				basePart:SetAttribute("HeatPower", recipe.HeatPower)
				newModel.Parent = workspace:FindFirstChild("HeatSources") or workspace
			end
			
			if recipe.Category == "Turrets" then
				newModel:SetAttribute("Range", recipe.Range)
				newModel:SetAttribute("Damage", recipe.Damage)
				newModel:SetAttribute("FireRate", recipe.FireRate)
				newModel.Parent = workspace:FindFirstChild("Turrets") or workspace
			end
		end
	end
end)
