--[[
    WarmthManager.server.luau
    Серверный менеджер тепла и строений:
    1. ЖИЛОЙ ДОМ ИГРОКА (Player Residential House):
       - Размер 45x30 studs, содержит КОСТЕР (+60 сек за ветку) и Верстак.
       - Защищает от мороза и агро мобов. Выброс предметов = личный (OwnerUserId).
    2. 3 ОХОТНИЧЬИХ ДОМИКА (Hunter Cabins):
       - Компактный размер (22.5x15 studs).
       - БЕЗ костра, без починки. Защищают от агро мобов, спавнят 1 шт еды.
--]]

local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")

local playerHouse = {
	Position = Vector3.new(0, 5, 0),
	Size = Vector3.new(45, 10, 30),
	FireFuelSeconds = 120,
	MaxFuelSeconds = 360
}

local hunterCabins = {
	{ Position = Vector3.new(-300, 4, 300), Size = Vector3.new(22.5, 8, 15) },
	{ Position = Vector3.new(300, 4, -300), Size = Vector3.new(22.5, 8, 15) },
	{ Position = Vector3.new(0, 4, 350), Size = Vector3.new(22.5, 8, 15) }
}

print("🏡 Жилой дом игрока (с Костром) и 3 Охотничьих Домика активированы!")
