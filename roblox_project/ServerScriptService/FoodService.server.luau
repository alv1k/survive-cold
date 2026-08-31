--[[
    FoodService.server.luau
    Серверная система потребления еды (съедание из инвентаря):
    - Восстановление Здоровья (HP), Тепла (Warmth) и Сытости (Hunger)
    - Ускорение от горячего кофе (+35% скорости бега на 15 секунд)
--]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local RemotesFolder = ReplicatedStorage:FindFirstChild("Remotes") or Instance.new("Folder", ReplicatedStorage)
RemotesFolder.Name = "Remotes"

local ConsumeFoodRemote = RemotesFolder:FindFirstChild("ConsumeFood") or Instance.new("RemoteEvent", RemotesFolder)
ConsumeFoodRemote.Name = "ConsumeFood"

local FOOD_STATS = {
	bar = { Name = "🍫 Батончик", Hp = 15, Warmth = 10, Hunger = 30, SpeedBoost = 1.0, Duration = 0 },
	bread = { Name = "🍞 Хлеб", Hp = 25, Warmth = 15, Hunger = 50, SpeedBoost = 1.0, Duration = 0 },
	chips = { Name = "🥔 Чипсы", Hp = 15, Warmth = 8, Hunger = 25, SpeedBoost = 1.0, Duration = 0 },
	soup = { Name = "🥫 Мясной суп", Hp = 35, Warmth = 30, Hunger = 70, SpeedBoost = 1.0, Duration = 0 },
	pepper = { Name = "🌶️ Перец", Hp = 5, Warmth = 50, Hunger = 15, SpeedBoost = 1.0, Duration = 0 },
	coffee = { Name = "☕ Горячий кофе", Hp = 20, Warmth = 40, Hunger = 20, SpeedBoost = 1.35, Duration = 15 },
	steak = { Name = "🥩 Жареный стейк", Hp = 60, Warmth = 35, Hunger = 90, SpeedBoost = 1.0, Duration = 0 }
}

ConsumeFoodRemote.OnServerEvent:Connect(function(player, foodId)
	local cfg = FOOD_STATS[foodId]
	if not cfg then return end

	local currentCount = player:GetAttribute("Food_" .. foodId) or player:GetAttribute(foodId) or 0
	if currentCount <= 0 then return end

	-- Списание 1 порции
	if player:GetAttribute("Food_" .. foodId) then
		player:SetAttribute("Food_" .. foodId, currentCount - 1)
	else
		player:SetAttribute(foodId, currentCount - 1)
	end

	-- Восстановление показателей
	local currentWarmth = player:GetAttribute("Warmth") or 100
	local currentHunger = player:GetAttribute("Hunger") or 100
	player:SetAttribute("Warmth", math.min(100, currentWarmth + cfg.Warmth))
	player:SetAttribute("Hunger", math.min(100, currentHunger + cfg.Hunger))

	local char = player.Character
	local humanoid = char and char:FindFirstChild("Humanoid")
	if humanoid and humanoid.Health > 0 then
		humanoid.Health = math.min(humanoid.MaxHealth, humanoid.Health + cfg.Hp)
	end

	-- Бафф кофе
	if cfg.Duration > 0 and cfg.SpeedBoost > 1.0 then
		player:SetAttribute("CoffeeSpeedBuff", cfg.SpeedBoost)
		task.delay(cfg.Duration, function()
			player:SetAttribute("CoffeeSpeedBuff", 1.0)
		end)
	end

	print(string.format("🍗 %s съел %s! (+%d HP, +%d🔥, +%d🍗)", player.Name, cfg.Name, cfg.Hp, cfg.Warmth, cfg.Hunger))
end)
