--[[
    ReplicatedStorage/HotReloader.luau
    Внутриигровой модуль горячей перезагрузки для быстрой разработки в Roblox Studio:
    - Позволяет модулям подписываться на изменение собственного исходного кода
    - Автоматически инвалидирует кэш require() в Studio
    - Автоматически отключается в релизной игре (Production Safe)
--]]

local RunService = game:GetService("RunService")

local HotReloader = {}
local listeners = {}

function HotReloader.listen(moduleScript, onReloadCallback)
	if not RunService:IsStudio() then return end
	if not moduleScript or not moduleScript:IsA("ModuleScript") then return end

	if listeners[moduleScript] then
		listeners[moduleScript]:Disconnect()
	end

	local conn = moduleScript:GetPropertyChangedSignal("Source"):Connect(function()
		task.defer(function()
			if not moduleScript.Parent then return end
			local success, newResult = pcall(function()
				local clone = moduleScript:Clone()
				clone.Parent = moduleScript.Parent
				local res = require(clone)
				clone:Destroy()
				return res
			end)

			if success then
				print(string.format("🔥 [HotReloader] Модуль '%s' успешно обновлен на лету!", moduleScript.Name))
				if onReloadCallback then
					pcall(onReloadCallback, newResult)
				end
			else
				warn(string.format("⚠️ [HotReloader Ошибка] %s: %s", moduleScript.Name, tostring(newResult)))
			end
		end)
	end)

	listeners[moduleScript] = conn
end

function HotReloader.reload(moduleScript)
	if not moduleScript or not moduleScript:IsA("ModuleScript") then return nil end
	local clone = moduleScript:Clone()
	clone.Parent = moduleScript.Parent
	local res = require(clone)
	clone:Destroy()
	return res
end

return HotReloader
