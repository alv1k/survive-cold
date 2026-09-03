--[[
    ShopService.server.luau
    Серверный скрипт магазина одежды и экипировки:
    - Манекен Lvl 1 (Легкая куртка): БЕСПЛАТНО (Стартовый паёк)
    - Манекен Lvl 2 (Теплый свитер): 3 Волокна + 2 Ветки
    - Манекен Lvl 3 (Зимнее пальто): 1 Шкура Волка + 4 Волокна
    - Манекен Lvl 4 (Меховая парка): 2 Шкуры Йети + 4 Волокна
    - Манекен Lvl 5 (VIP): 150 Robux
--]]

local Players = game:GetService("Players")
local MarketplaceService = game:GetService("MarketplaceService")

local ROBUX_GAMEPASS_ID = 123456789

local ClothingTiers = {
	[0] = { Name = "Джинсы и футболка", Protection = 0.00, Cost = {}, IsRobux = false, Desc = "Базовая одежда" },
	[1] = { Name = "Легкая куртка", Protection = 0.10, Cost = {}, IsRobux = false, Desc = "🎉 БЕСПЛАТНО (Старт)" },
	[2] = { Name = "Теплый свитер", Protection = 0.20, Cost = { Fiber = 3, Branches = 2 }, IsRobux = false, Desc = "3 Волокна + 2 Ветки" },
	[3] = { Name = "Зимнее пальто", Protection = 0.30, Cost = { WolfPelt = 1, Fiber = 4 }, IsRobux = false, Desc = "1 🐺 Шкура + 4 Волокна" },
	[4] = { Name = "Меховая парка", Protection = 0.40, Cost = { YetiPelt = 2, Fiber = 4 }, IsRobux = false, Desc = "2 ❄️ Шкуры + 4 Волокна" },
	[5] = { Name = "VIP Снаряжение", Protection = 0.55, RobuxPrice = 150, Cost = {}, IsRobux = true, Desc = "150 Robux" }
}

local ShopFolder = workspace:FindFirstChild("ClothingShop") or Instance.new("Folder", workspace)
ShopFolder.Name = "ClothingShop"

local SHOP_POSITION = Vector3.new(70, 2.5, 0)

local function setupBalancedShop()
	local shopBase = Instance.new("Part")
	shopBase.Name = "ShopBase"
	shopBase.Size = Vector3.new(30, 1, 25)
	shopBase.Position = SHOP_POSITION
	shopBase.Anchored = true
	shopBase.Material = Enum.Material.WoodPlanks
	shopBase.BrickColor = BrickColor.new("Lapis")
	shopBase.Parent = ShopFolder
	
	local fireplace = Instance.new("Part")
	fireplace.Name = "ShopFireplace"
	fireplace.Size = Vector3.new(4, 2, 4)
	fireplace.Position = SHOP_POSITION + Vector3.new(0, 1.5, -8)
	fireplace.Anchored = true
	fireplace.Material = Enum.Material.Neon
	fireplace.BrickColor = BrickColor.new("Bright orange")
	fireplace:SetAttribute("HeatRadius", 35)
	fireplace:SetAttribute("HeatPower", 12)
	fireplace.Parent = workspace:FindFirstChild("HeatSources") or workspace
	
	local mannequinConfig = {
		{ Id = 1, Tier = 1, IsRobux = false },
		{ Id = 2, Tier = 2, IsRobux = false },
		{ Id = 3, Tier = 3, IsRobux = false },
		{ Id = 4, Tier = 4, IsRobux = false },
		{ Id = 5, Tier = 5, IsRobux = true }
	}
	
	for _, m in ipairs(mannequinConfig) do
		local mannequinPart = Instance.new("Part")
		mannequinPart.Name = "Mannequin_" .. m.Id
		mannequinPart.Size = Vector3.new(2, 5, 2)
		mannequinPart.Position = SHOP_POSITION + Vector3.new(-10 + (m.Id * 4), 3, 0)
		mannequinPart.Anchored = true
		mannequinPart.Material = m.IsRobux and Enum.Material.Neon or Enum.Material.Wood
		mannequinPart.BrickColor = m.IsRobux and BrickColor.new("Lime green") or BrickColor.new("Dark stone grey")
		mannequinPart.Parent = ShopFolder
		
		local tierInfo = ClothingTiers[m.Tier]
		local prompt = Instance.new("ProximityPrompt", mannequinPart)
		
		if m.IsRobux then
			prompt.ActionText = string.format("💳 Купить VIP Костюм Lvl 5 (%d Robux)", tierInfo.RobuxPrice)
			prompt.ObjectText = "💎 Платный Манекен"
		elseif m.Tier == 1 then
			prompt.ActionText = string.format("Забрать БЕСПЛАТНО: %s (+%d%% защиты)", tierInfo.Name, tierInfo.Protection * 100)
			prompt.ObjectText = "🎉 Стартовый подарок"
		else
			prompt.ActionText = string.format("Сшить %s (%s)", tierInfo.Name, tierInfo.Desc)
			prompt.ObjectText = string.format("🧥 Костюм Lvl %d (+%d%% защиты)", m.Tier, tierInfo.Protection * 100)
		end
		prompt.HoldDuration = 0
		
		prompt.Triggered:Connect(function(player)
			if m.IsRobux then
				MarketplaceService:PromptGamePassPurchase(player, ROBUX_GAMEPASS_ID)
				return
			end

			local currentLevel = player:GetAttribute("ClothingLevel") or 0
			if currentLevel >= m.Tier then
				print(string.format("⚠️ У %s уже экипирован костюм уровня %d!", player.Name, currentLevel))
				return
			end

			-- Проверка и списание ресурсов
			local canCraft = true
			for resName, amount in pairs(tierInfo.Cost) do
				local currentRes = player:GetAttribute(resName) or 0
				if currentRes < amount then
					canCraft = false
					break
				end
			end

			if canCraft then
				for resName, amount in pairs(tierInfo.Cost) do
					local currentRes = player:GetAttribute(resName) or 0
					player:SetAttribute(resName, currentRes - amount)
				end

				player:SetAttribute("ClothingLevel", m.Tier)
				player:SetAttribute("ClothingProtection", tierInfo.Protection)
				print(string.format("🧥 %s изготовил и экипировал %s (Lvl %d, +%d%% защиты)!", player.Name, tierInfo.Name, m.Tier, tierInfo.Protection * 100))
			else
				print(string.format("⚠️ У %s недостаточно ресурсов! Требуется: %s", player.Name, tierInfo.Desc))
			end
		end)
	end
end

MarketplaceService.PromptGamePassPurchaseFinished:Connect(function(player, passId, wasPurchased)
	if wasPurchased and passId == ROBUX_GAMEPASS_ID then
		player:SetAttribute("ClothingLevel", 5)
		player:SetAttribute("ClothingProtection", ClothingTiers[5].Protection)
		print("💎 " .. player.Name .. " купил эксклюзивное VIP снаряжение за Робуксы!")
	end
end)

setupBalancedShop()
