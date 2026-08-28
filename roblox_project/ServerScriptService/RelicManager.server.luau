--[[
    RelicManager.server.luau
    Серверный скрипт квеста 7 Древних Реликвий и победного финала.
--]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local TOTAL_RELICS = 7
workspace:SetAttribute("CollectedRelics", 0)

local RelicsFolder = workspace:FindFirstChild("Relics") or Instance.new("Folder", workspace)
RelicsFolder.Name = "Relics"

-- Финал: Наступление постоянного тепла и победа
local function triggerSunDawn()
	workspace:SetAttribute("IsVictory", true)
	workspace:SetAttribute("IsBlizzard", false)
	workspace:SetAttribute("IsNight", false)
	
	game:GetService("Lighting").ClockTime = 12
	print("🏆 ПОБЕДА! Все 7 Реликвий найдены! Вечная зима окончена!")
end

-- Регистрация нахождения реликвии
for i = 1, TOTAL_RELICS do
	local relicPart = Instance.new("Part")
	relicPart.Name = "Relic_" .. i
	relicPart.Size = Vector3.new(2, 4, 2)
	relicPart.Position = Vector3.new(math.random(-200, 200), 5, math.random(-200, 200))
	relicPart.Anchored = true
	relicPart.Material = Enum.Material.Neon
	relicPart.BrickColor = BrickColor.new("Cyan")
	relicPart.Parent = RelicsFolder
	
	local prompt = Instance.new("ProximityPrompt", relicPart)
	prompt.ActionText = "Активировать Реликвию " .. i
	prompt.ObjectText = "Древний Артефакт"
	prompt.HoldDuration = 2.0
	
	prompt.Triggered:Connect(function(player)
		relicPart:Destroy()
		local current = workspace:GetAttribute("CollectedRelics") or 0
		current = current + 1
		workspace:SetAttribute("CollectedRelics", current)
		
		print("🗿 " .. player.Name .. " активировал Реликвию " .. current .. "/" .. TOTAL_RELICS)
		
		if current >= TOTAL_RELICS then
			triggerSunDawn()
		end
	end)
end
