--[[
    ShopService.server.luau
    Серверный скрипт магазина одежды (30 секунд от спавна).
    Манекены 1-4 100% БЕСПЛАТНЫЕ (0 дров, берутся без ресурсов).
    Только 1 манекен платный за Robux!
--]]

local Players = game:GetService("Players")
local MarketplaceService = game:GetService("MarketplaceService")

local ROBUX_GAMEPASS_ID = 123456789

local ClothingTiers = {
	[0] = { Name = "Джинсы и футболка", Protection = 0.00, CostWood = 0, IsRobux = false },
	[1] = { Name = "Легкая куртка", Protection = 0.10, CostWood = 0, IsRobux = false },  -- 100% БЕСПЛАТНО
	[2] = { Name = "Теплый свитер", Protection = 0.20, CostWood = 0, IsRobux = false },  -- 100% БЕСПЛАТНО
	[3] = { Name = "Зимнее пальто", Protection = 0.30, CostWood = 0, IsRobux = false },   -- 100% БЕСПЛАТНО
	[4] = { Name = "Меховая парка", Protection = 0.40, CostWood = 0, IsRobux = false },   -- 100% БЕСПЛАТНО
	[5] = { Name = "VIP Снаряжение", Protection = 0.55, RobuxPrice = 150, IsRobux = true } -- ПЛАТНЫЙ ЗА ROBUX
}

local ShopFolder = workspace:FindFirstChild("ClothingShop") or Instance.new("Folder", workspace)
ShopFolder.Name = "ClothingShop"

local SHOP_POSITION = Vector3.new(350, 2.5, -300)

local function setupTrulyFreeShop()
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
		{ Id = 2, Tier = 1, IsRobux = false },
		{ Id = 3, Tier = 1, IsRobux = false },
		{ Id = 4, Tier = math.random(2, 3), IsRobux = false },
		{ Id = 5, Tier = 5, IsRobux = true } -- Единственный платный!
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
		else
			prompt.ActionText = string.format("Забрать БЕСПЛАТНО: %s Lvl %d (+%d%% защиты)", tierInfo.Name, m.Tier, tierInfo.Protection * 100)
			prompt.ObjectText = "🎉 Бесплатный манекен (0 дров)"
		end
		prompt.HoldDuration = 0.5
		
		prompt.Triggered:Connect(function(player)
			if m.IsRobux then
				MarketplaceService:PromptGamePassPurchase(player, ROBUX_GAMEPASS_ID)
			else
				-- 100% БЕСПЛАТНО — БЕЗ ПРОВЕРКИ И СПИСАНИЯ ДРОВ!
				local currentLevel = player:GetAttribute("ClothingLevel") or 0
				if currentLevel < m.Tier then
					player:SetAttribute("ClothingLevel", m.Tier)
					player:SetAttribute("ClothingProtection", tierInfo.Protection)
					print(string.format("🎉 %s бесплатно забрал костюм %d уровня (%s)!", player.Name, m.Tier, tierInfo.Name))
				end
			end
		end)
	end
end

MarketplaceService.PromptGamePassPurchaseFinished:Connect(function(player, passId, wasPurchased)
	if wasPurchased and passId == ROBUX_GAMEPASS_ID then
		player:SetAttribute("ClothingLevel", 5)
		player:SetAttribute("ClothingProtection", ClothingTiers[5].Protection)
		print("💎 " .. player.Name .. " купил единственное платное VIP снаряжение за Робуксы!")
	end
end)

setupTrulyFreeShop()
