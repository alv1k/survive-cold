--[[
    HotSwap.server.luau
    Roblox Studio Plugin для мгновенной горячей перезагрузки кода при синхронизации через Rojo:
    1. Отслеживает изменения Source у всех ModuleScript, Script, LocalScript во время Play-теста (Play Solo).
    2. При изменении файла на диске (Rojo sync) или в Studio:
       - StarterPlayerScripts: мгновенно обновляет и перезапускает копии скриптов в PlayerScripts у всех игроков и обновляет UI!
       - ModuleScript: инвалидирует кэш require() через контролируемое клонирование и вызывает .reload() / .onHotReload()
       - ServerScriptService / Workspace: перезапускает скрипты
    3. Кнопка на панели инструментов Studio для быстрого включения / выключения (Toggle HotSwap ON/OFF).
--]]

local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

-- Создаем кнопку на панели инструментов Studio
local toolbar = plugin:CreateToolbar("🔥 HotSwap Live")
local toggleBtn = toolbar:CreateButton(
	"HotSwapToggle",
	"Включить / Выключить горячую перезагрузку кода (HotSwap)",
	"rbxassetid://10734898144"
)
toggleBtn.ClickableWhenViewportHidden = true

local isEnabled = true
toggleBtn:SetActive(isEnabled)

toggleBtn.Click:Connect(function()
	isEnabled = not isEnabled
	toggleBtn:SetActive(isEnabled)
	print(string.format("🔥 [HotSwap] Горячая перезагрузка: %s", isEnabled and "ВКЛЮЧЕНА ✅" or "ВЫКЛЮЧЕНА ❌"))
end)

-- Хранилище подключений к скриптам
local scriptConnections = {}
local reloadDebounce = {}

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

local function logHotSwap(msg)
	print(string.format("🔥 [HotSwap %s] %s", os.date("%H:%M:%S"), msg))
end

local function reloadClientScriptForPlayer(player, scriptTemplate)
	local pScripts = player:FindFirstChild("PlayerScripts")
	local pGui = player:FindFirstChild("PlayerGui")
	if not pScripts then return end

	local scriptName = scriptTemplate.Name
	local guiName = SCRIPT_TO_GUI[scriptName] or (scriptName .. "Gui")

	-- 1. Удаляем старый UI
	if pGui then
		local oldGui = pGui:FindFirstChild(guiName)
		if oldGui then
			oldGui:Destroy()
			logHotSwap(string.format("Очищен старый GUI '%s' у игрока %s", guiName, player.Name))
		end
	end

	-- 2. Удаляем старый скрипт в PlayerScripts
	local oldScript = pScripts:FindFirstChild(scriptName)
	if oldScript then
		oldScript.Disabled = true
		oldScript:Destroy()
	end

	-- 3. Клонируем свежую версию из StarterPlayerScripts
	task.defer(function()
		local newScript = scriptTemplate:Clone()
		newScript.Parent = pScripts
		logHotSwap(string.format("✅ Скрипт %s перезапущен у игрока %s!", scriptName, player.Name))
	end)
end

local function handleScriptModified(scriptInstance)
	if not isEnabled then return end
	if not RunService:IsRunning() then return end

	local path = scriptInstance:GetFullName()
	local now = os.clock()
	if reloadDebounce[path] and (now - reloadDebounce[path] < 0.25) then
		return
	end
	reloadDebounce[path] = now

	-- 1. Изменение в StarterPlayer / StarterPlayerScripts
	local starterPlayer = game:GetService("StarterPlayer")
	if scriptInstance:IsDescendantOf(starterPlayer) then
		logHotSwap(string.format("Обнаружено изменение в StarterPlayer: %s", scriptInstance.Name))
		for _, plr in ipairs(Players:GetPlayers()) do
			reloadClientScriptForPlayer(plr, scriptInstance)
		end
		return
	end

	-- 2. Изменение ModuleScript
	if scriptInstance:IsA("ModuleScript") then
		logHotSwap(string.format("Перезагрузка ModuleScript: %s ...", scriptInstance.Name))
		
		local success, newModule = pcall(function()
			local clone = scriptInstance:Clone()
			clone.Parent = scriptInstance.Parent
			local result = require(clone)
			clone:Destroy()
			return result
		end)

		if success then
			logHotSwap(string.format("✅ Успешно обновлен модуль: %s", scriptInstance.Name))
			if type(newModule) == "table" then
				if type(newModule.onHotReload) == "function" then
					pcall(newModule.onHotReload)
				elseif type(newModule.reload) == "function" then
					pcall(newModule.reload)
				end
			end
		else
			warn(string.format("⚠️ [HotSwap Ошибка] %s: %s", scriptInstance.Name, tostring(newModule)))
		end

	-- 3. Обычный скрипт в ServerScriptService / Workspace
	elseif scriptInstance:IsA("LocalScript") or scriptInstance:IsA("Script") then
		logHotSwap(string.format("Перезапуск скрипта: %s ...", scriptInstance.Name))
		local wasDisabled = scriptInstance.Disabled
		scriptInstance.Disabled = true
		task.defer(function()
			if scriptInstance and scriptInstance.Parent then
				scriptInstance.Disabled = wasDisabled
				logHotSwap(string.format("✅ Скрипт %s перезапущен с новым кодом!", scriptInstance.Name))
			end
		end)
	end
end

local function watchScript(inst)
	if not (inst:IsA("LuaSourceContainer")) then return end
	if scriptConnections[inst] then return end

	local conn = inst:GetPropertyChangedSignal("Source"):Connect(function()
		handleScriptModified(inst)
	end)
	scriptConnections[inst] = conn

	inst.AncestryChanged:Connect(function(_, parent)
		if not parent then
			if scriptConnections[inst] then
				scriptConnections[inst]:Disconnect()
				scriptConnections[inst] = nil
			end
		end
	end)
end

-- Сканируем все папки проекта
local function initWatchers()
	for _, root in ipairs({
		game:GetService("ReplicatedStorage"),
		game:GetService("ServerScriptService"),
		game:GetService("StarterPlayer"),
		game:GetService("StarterGui"),
		game:GetService("Workspace")
	}) do
		for _, desc in ipairs(root:GetDescendants()) do
			watchScript(desc)
		end
		root.DescendantAdded:Connect(watchScript)
	end
end

initWatchers()
logHotSwap("Плагин горячей перезагрузки активирован и готов к работе с Rojo!")
