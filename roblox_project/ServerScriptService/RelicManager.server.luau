--[[
    RelicManager.server.luau
    Серверный скрипт:
    1. 7 Древних Реликвий (спавнятся на карте, подбираются в инвентарь игрока)
    2. Древний Алтарь Реликвий (куда игрок относит реликвии, дает зону тепла)
    3. Защищенный Бункер Эвакуации и Перерождения (открывается после 7/7 на Алтаре)
--]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local TOTAL_RELICS = 7
workspace:SetAttribute("AltarPlacedRelics", 0)
workspace:SetAttribute("IsBunkerOpen", false)

local RelicsFolder = workspace:FindFirstChild("Relics") or Instance.new("Folder", workspace)
RelicsFolder.Name = "Relics"

-- Создание Древнего Алтаря
local AltarPart = Instance.new("Part")
AltarPart.Name = "AncientAltar"
AltarPart.Size = Vector3.new(12, 2, 12)
AltarPart.Position = Vector3.new(-60, 1, 80)
AltarPart.Anchored = true
AltarPart.Material = Enum.Material.Slate
AltarPart.BrickColor = BrickColor.new("Dark stone grey")
AltarPart.Parent = workspace

local AltarPrompt = Instance.new("ProximityPrompt", AltarPart)
AltarPrompt.ActionText = "Освятить реликвии на Алтаре"
AltarPrompt.ObjectText = "⛩️ Древний Алтарь (0/7)"
AltarPrompt.HoldDuration = 1.0

-- Создание Бункера
local BunkerPart = Instance.new("Part")
BunkerPart.Name = "EvacuationBunker"
BunkerPart.Size = Vector3.new(16, 8, 16)
BunkerPart.Position = Vector3.new(180, 4, 120)
BunkerPart.Anchored = true
BunkerPart.Material = Enum.Material.DiamondPlate
BunkerPart.BrickColor = BrickColor.new("Really red")
BunkerPart.Parent = workspace

local BunkerPrompt = Instance.new("ProximityPrompt", BunkerPart)
BunkerPrompt.ActionText = "Войти в Бункер для Перерождения"
BunkerPrompt.ObjectText = "🚪 Бункер Эвакуации [🔒 Требуется 7 реликвий на Алтаре]"
BunkerPrompt.Enabled = false
BunkerPrompt.HoldDuration = 2.5

-- Финал: Открытие Бункера
local function onAllRelicsPlaced()
	workspace:SetAttribute("IsVictory", true)
	workspace:SetAttribute("IsBlizzard", false)
	workspace:SetAttribute("IsNight", false)
	workspace:SetAttribute("IsBunkerOpen", true)
	
	BunkerPart.BrickColor = BrickColor.new("Lime green")
	BunkerPrompt.Enabled = true
	BunkerPrompt.ObjectText = "🚪 Бункер Эвакуации [🟢 ДОСТУП РАЗРЕШЕН]"
	
	print("🚨 ВСЕ 7 РЕЛИКВИЙ НА АЛТАРЕ! БУНКЕР ЭВАКУАЦИИ ОТКРЫТ!")
end

-- Взаимодействие с Алтарем
AltarPrompt.Triggered:Connect(function(player)
	local carried = player:GetAttribute("CarriedRelics") or 0
	if carried > 0 then
		local placed = workspace:GetAttribute("AltarPlacedRelics") or 0
		local toAdd = math.min(TOTAL_RELICS - placed, carried)
		placed = placed + toAdd
		player:SetAttribute("CarriedRelics", carried - toAdd)
		workspace:SetAttribute("AltarPlacedRelics", placed)
		
		AltarPrompt.ObjectText = string.format("⛩️ Древний Алтарь (%d/%d)", placed, TOTAL_RELICS)
		print(string.format("✨ %s освятил реликвии на Алтаре! (%d/%d)", player.Name, placed, TOTAL_RELICS))
		
		if placed >= TOTAL_RELICS then
			onAllRelicsPlaced()
		end
	else
		print(string.format("⚠️ У %s нет реликвий в руках для Алтаря!", player.Name))
	end
end)

-- Взаимодействие с Бункером: Перерождение (Rebirth)
BunkerPrompt.Triggered:Connect(function(player)
	if workspace:GetAttribute("IsBunkerOpen") then
		local currentRebirths = player:GetAttribute("Rebirths") or 0
		player:SetAttribute("Rebirths", currentRebirths + 1)
		player:SetAttribute("CarriedRelics", 0)
		
		print(string.format("🚀 %s успешно переродился! Уровень перерождения: #%d", player.Name, currentRebirths + 1))
	end
end)

-- Спавн 7 Реликвий на карте
for i = 1, TOTAL_RELICS do
	local relicPart = Instance.new("Part")
	relicPart.Name = "Relic_" .. i
	relicPart.Size = Vector3.new(2, 4, 2)
	relicPart.Position = Vector3.new(math.random(-250, 250), 3, math.random(-250, 250))
	relicPart.Anchored = true
	relicPart.Material = Enum.Material.Neon
	relicPart.BrickColor = BrickColor.new("Cyan")
	relicPart.Parent = RelicsFolder
	
	local prompt = Instance.new("ProximityPrompt", relicPart)
	prompt.ActionText = "Подобрать Реликвию #" .. i
	prompt.ObjectText = "💎 Древний Артефакт"
	prompt.HoldDuration = 1.0
	
	prompt.Triggered:Connect(function(player)
		relicPart:Destroy()
		local carried = player:GetAttribute("CarriedRelics") or 0
		player:SetAttribute("CarriedRelics", carried + 1)
		print(string.format("💎 %s подобрал Реликвию! (В руках: %d)", player.Name, carried + 1))
	end)
end
