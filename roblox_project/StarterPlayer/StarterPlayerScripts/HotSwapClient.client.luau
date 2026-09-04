--[[
    StarterPlayer/StarterPlayerScripts/HotSwapClient.client.luau
    Клиентский сервис мгновенной перезагрузки (HotSwap) в Roblox Studio:
    - При получении сигнала об изменении скрипта в StarterPlayerScripts:
      1. Находит запущенный LocalScript в PlayerScripts
      2. Удаляет старый запущенный скрипт
      3. Берет свежую копию из StarterPlayerScripts и запускает ее заново
      4. Новый интерфейс и логика применяются мгновенно без перезапуска игры!
--]]

local RunService = game:GetService("RunService")
if not RunService:IsStudio() then return end

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterPlayer = game:GetService("StarterPlayer")

local player = Players.LocalPlayer
local playerScripts = player:WaitForChild("PlayerScripts")
local playerGui = player:WaitForChild("PlayerGui")
local starterPlayerScripts = StarterPlayer:WaitForChild("StarterPlayerScripts")

local remotesFolder = ReplicatedStorage:WaitForChild("Remotes", 10)
local reloadRemote = remotesFolder and remotesFolder:WaitForChild("HotSwapReloadClientScript", 10)

if not reloadRemote then return end

-- Таблица соответствия скриптов и создаваемых ими ScreenGui для авто-очистки старого UI
local SCRIPT_TO_GUI = {
	["WelcomeGuide"] = "WelcomeGuideGui",
	["WorkbenchController"] = "WorkbenchScreenGui",
	["DeathReviveController"] = "DeathReviveGui",
	["WarmthHUD"] = "WarmthHUDGui",
	["MinimapController"] = "MinimapGui",
	["WaypointController"] = "WaypointGui",
	["FoxRadarController"] = "FoxRadarGui",
	["FrostEffectController"] = "FrostEffectGui",
}

local function reloadLocalScript(scriptName)
	if scriptName == "HotSwapClient" then return end

	print(string.format("🔥 [HotSwap Client] Перезагрузка скрипта: %s ...", scriptName))

	-- 1. Удаляем старый UI, если скрипт управлял интерфейсом
	local guiName = SCRIPT_TO_GUI[scriptName] or (scriptName .. "Gui")
	local oldGui = playerGui:FindFirstChild(guiName)
	if oldGui then
		oldGui:Destroy()
		print(string.format("🔥 [HotSwap Client] Очищен старый UI: %s", guiName))
	end

	-- 2. Находим старый запущенный скрипт в PlayerScripts
	local oldScript = playerScripts:FindFirstChild(scriptName)
	if oldScript then
		oldScript.Disabled = true
		oldScript:Destroy()
	end

	-- 3. Находим исходный обновленный скрипт в StarterPlayerScripts
	local template = starterPlayerScripts:FindFirstChild(scriptName)
	if template and template:IsA("LocalScript") then
		local newScript = template:Clone()
		newScript.Parent = playerScripts
		print(string.format("🔥 [HotSwap Client] ✅ Скрипт %s успешно перезапущен с обновленным кодом!", scriptName))
	else
		warn(string.format("⚠️ [HotSwap Client] Не найден шаблон в StarterPlayerScripts: %s", scriptName))
	end
end

reloadRemote.OnClientEvent:Connect(function(scriptName)
	task.defer(reloadLocalScript, scriptName)
end)

print("🔥 [HotSwap Client] Клиентский слушатель горячей перезагрузки активирован!")
