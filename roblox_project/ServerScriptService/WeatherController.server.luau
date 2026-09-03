--[[
    WeatherController.server.luau
    Серверный контроллер смены дня/ночи и динамических снежных бурь (Blizzards).
--]]

local Lighting = game:GetService("Lighting")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local DAY_DURATION = 240 -- 4 минуты ясного дня для сбора и исследований -- Длительность дня в секундах
local FOG_DURATION = 45   -- 45 секунд ледяного тумана перед бурей   -- Длительность тумана перед бурей
local BLIZZARD_DURATION = 90 -- 1.5 минуты свирепой ночной метели -- Длительность бури

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
			Density = 0.3,
			Haze = 0.5,
			Color = Color3.fromRGB(199, 219, 230),
			Glare = 0.2
		}):Play()
		TweenService:Create(Lighting, TweenInfo.new(5), {
			FogStart = 60,
			FogEnd = 800,
			OutdoorAmbient = Color3.fromRGB(128, 140, 155)
		}):Play()
		
	elseif state == "Fog" then
		workspace:SetAttribute("IsBlizzard", false)
		TweenService:Create(Atmosphere, TweenInfo.new(4), {
			Density = 0.5,
			Haze = 1.2,
			Color = Color3.fromRGB(150, 170, 185)
		}):Play()
		TweenService:Create(Lighting, TweenInfo.new(4), {
			FogStart = 15,
			FogEnd = 280,
			OutdoorAmbient = Color3.fromRGB(90, 100, 115)
		}):Play()
		
	elseif state == "Blizzard" then
		workspace:SetAttribute("IsBlizzard", true)
		TweenService:Create(Atmosphere, TweenInfo.new(3), {
			Density = 0.65,
			Haze = 2.0,
			Color = Color3.fromRGB(120, 135, 150),
			Glare = 0
		}):Play()
		TweenService:Create(Lighting, TweenInfo.new(3), {
			FogStart = 0,
			FogEnd = 140,
			OutdoorAmbient = Color3.fromRGB(50, 60, 75)
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
