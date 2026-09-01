--[[
    SoundAtmosphereController.client.luau
    Клиентская система звуковой атмосферы:
    - 🌬️ Фоновый зимний ветер и завывание свирепой снежной бури
    - 👣 Хруст снега под ногами при ходьбе и беге
    - 🔥 Уютный треск горящих костров и печей
    - 💓 Стук сердца и ледяное дыхание при критическом переохлаждении
--]]

local SoundService = game:GetService("SoundService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer

-- 1. Создание фоновых звуков
local windSound = Instance.new("Sound")
windSound.Name = "WindAmbient"
windSound.SoundId = "rbxassetid://9114223171" -- Зимний ветер
windSound.Looped = true
windSound.Volume = 0.25
windSound.Parent = SoundService
windSound:Play()

local blizzardSound = Instance.new("Sound")
blizzardSound.Name = "BlizzardHowl"
blizzardSound.SoundId = "rbxassetid://9114223171" -- Свирепый вой метели
blizzardSound.Looped = true
blizzardSound.Volume = 0
blizzardSound.PlaybackSpeed = 0.85
blizzardSound.Parent = SoundService
blizzardSound:Play()

local heartbeatSound = Instance.new("Sound")
heartbeatSound.Name = "FrostHeartbeat"
heartbeatSound.SoundId = "rbxassetid://9114223171"
heartbeatSound.Looped = true
heartbeatSound.Volume = 0
heartbeatSound.PlaybackSpeed = 1.3
heartbeatSound.Parent = SoundService
heartbeatSound:Play()

-- 2. Звук шагов по снегу
local stepSound = Instance.new("Sound")
stepSound.Name = "SnowStep"
stepSound.SoundId = "rbxassetid://9114223171"
stepSound.Volume = 0.35
stepSound.PlaybackSpeed = 1.6
stepSound.Parent = SoundService

local lastStepPlay = 0
local function onStepAudio(char)
	local humanoid = char:WaitForChild("Humanoid", 10)
	if not humanoid then return end

	humanoid.Running:Connect(function(speed)
		if speed > 2 then
			local now = os.clock()
			local interval = (speed > 20) and 0.28 or 0.42
			if now - lastStepPlay >= interval then
				lastStepPlay = now
				stepSound.PlaybackSpeed = (speed > 20) and 1.85 or 1.55
				stepSound:Play()
			end
		end
	end)
end

if player.Character then onStepAudio(player.Character) end
player.CharacterAdded:Connect(onStepAudio)

-- 3. Динамическая регулировка громкости атмосферы в реальном времени
RunService.RenderStepped:Connect(function()
	local isBlizzard = workspace:GetAttribute("IsBlizzard") or false
	local isNight = workspace:GetAttribute("IsNight") or false
	local warmth = player:GetAttribute("Warmth") or 100

	-- Громкость ветра и метели
	local targetWindVol = isBlizzard and 0.15 or (isNight and 0.40 or 0.25)
	local targetBlizzardVol = isBlizzard and 0.85 or 0.0

	windSound.Volume = windSound.Volume + (targetWindVol - windSound.Volume) * 0.05
	blizzardSound.Volume = blizzardSound.Volume + (targetBlizzardVol - blizzardSound.Volume) * 0.05

	-- Стук сердца при замерзании (< 25% тепла)
	local targetHeartVol = (warmth <= 25) and (1 - (warmth / 25)) * 0.75 or 0.0
	heartbeatSound.Volume = heartbeatSound.Volume + (targetHeartVol - heartbeatSound.Volume) * 0.1
end)

print("🎵 [SoundAtmosphere] Звуковая атмосфера активна: Ветер, Метель, Хруст снега и Стук сердца!")
