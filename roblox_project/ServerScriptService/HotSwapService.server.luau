--[[
    ServerScriptService/HotSwapService.server.luau
    Серверный сервис для поддержки мгновенной горячей перезагрузки (HotSwap) в Roblox Studio:
    - Работает только в Studio (RunService:IsStudio())
    - Отслеживает изменения исходного кода (Source) скриптов в StarterPlayerScripts и ServerScriptService
    - При синхронизации через Rojo или редактировании в Studio мгновенно уведомляет клиенты для перезапуска
--]]

local RunService = game:GetService("RunService")
if not RunService:IsStudio() then return end

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterPlayer = game:GetService("StarterPlayer")
local Players = game:GetService("Players")

local starterPlayerScripts = StarterPlayer:WaitForChild("StarterPlayerScripts")

-- Создаем RemoteEvent для HotSwap, если его еще нет
local remotesFolder = ReplicatedStorage:FindFirstChild("Remotes")
if not remotesFolder then
	remotesFolder = Instance.new("Folder")
	remotesFolder.Name = "Remotes"
	remotesFolder.Parent = ReplicatedStorage
end

local reloadRemote = remotesFolder:FindFirstChild("HotSwapReloadClientScript")
if not reloadRemote then
	reloadRemote = Instance.new("RemoteEvent")
	reloadRemote.Name = "HotSwapReloadClientScript"
	reloadRemote.Parent = remotesFolder
end

local debounce = {}

local function notifyClientReload(scriptName)
	print(string.format("🔥 [HotSwap Service] Обнаружено изменение: %s. Отправка сигнала клиенту на перезапуск...", scriptName))
	reloadRemote:FireAllClients(scriptName)
end

local function watchStarterScript(scriptInst)
	if not scriptInst:IsA("LocalScript") and not scriptInst:IsA("Script") then return end
	
	scriptInst:GetPropertyChangedSignal("Source"):Connect(function()
		local now = os.clock()
		if debounce[scriptInst.Name] and (now - debounce[scriptInst.Name] < 0.2) then return end
		debounce[scriptInst.Name] = now
		notifyClientReload(scriptInst.Name)
	end)
end

for _, child in ipairs(starterPlayerScripts:GetDescendants()) do
	watchStarterScript(child)
end
starterPlayerScripts.DescendantAdded:Connect(watchStarterScript)

print("🔥 [HotSwap Service] Сервис горячей перезагрузки активирован в Studio!")
