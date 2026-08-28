--[[
    WeatherController.server.luau
    Серверный контроллер смены дня/ночи и динамических снежных бурь (Blizzards).
--]]

local Lighting = game:GetService("Lighting")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local DAY_DURATION = 180 -- Длительность дня в секундах
local FOG_DURATION = 30   -- Длительность тумана перед бурей
local BLIZZARD_DURATION = 60 -- Длительность бури

-- Создание или получение эффекта атмосферы
local Atmosphere = Lighting:FindFirstChildOfClass("Atmosphere")
if not Atmosphere then
	Atmosphere = Instance.new("Atmosphere", Lighting)
	Atmosphere.Density = 0.3
	Atmosphere.Offset = 0.25
	Atmosphere.Color = Color3.fromRGB(199, 219, 230)
	Atmosphere.Decay = Color3.fromRGB(106, 122, 133)
end

local function setWeatherState(state)
	workspace:SetAttribute("WeatherState", state)
	
	if state == "Clear" then
		workspace:SetAttribute("IsBlizzard", false)
		TweenService:Create(Atmosphere, TweenInfo.new(5), {
			Density = 0.35,
			Color = Color3.fromRGB(199, 219, 230),
			Glare = 0.2
		}):Play()
		TweenService:Create(Lighting, TweenInfo.new(5), {
			FogEnd = 500,
			OutdoorAmbient = Color3.fromRGB(128, 140, 155)
		}):Play()
		
	elseif state == "Fog" then
		workspace:SetAttribute("IsBlizzard", false)
		TweenService:Create(Atmosphere, TweenInfo.new(4), {
			Density = 0.65,
			Color = Color3.fromRGB(150, 170, 185)
		}):Play()
		TweenService:Create(Lighting, TweenInfo.new(4), {
			FogEnd = 150,
			OutdoorAmbient = Color3.fromRGB(90, 100, 115)
		}):Play()
		
	elseif state == "Blizzard" then
		workspace:SetAttribute("IsBlizzard", true)
		TweenService:Create(Atmosphere, TweenInfo.new(3), {
			Density = 0.92,
			Color = Color3.fromRGB(120, 135, 150),
			Glare = 0
		}):Play()
		TweenService:Create(Lighting, TweenInfo.new(3), {
			FogEnd = 40,
			OutdoorAmbient = Color3.fromRGB(40, 50, 65)
		}):Play()
	end
end

-- Основной погодный цикл
task.spawn(function()
	while true do
		-- 1. Ясный день
		setWeatherState("Clear")
		workspace:SetAttribute("IsNight", false)
		Lighting.ClockTime = 12
		task.wait(DAY_DURATION)
		
		-- 2. Наступление ночи и тумана
		workspace:SetAttribute("IsNight", true)
		Lighting.ClockTime = 22
		setWeatherState("Fog")
		task.wait(FOG_DURATION)
		
		-- 3. Снежная буря (Близзард)
		setWeatherState("Blizzard")
		task.wait(BLIZZARD_DURATION)
	end
end)
