--[[
    ReplicatedStorage/ModelHelper.luau
    Универсальный менеджер и фабрика 3D-моделей для Survive the Cold:
    1. Автоматический поиск импортированных MeshPart моделей (ReplicatedStorage.Models / Workspace / ServerStorage).
    2. Автоматический fallback на сгенерированные модули (ReplicatedStorage.GeneratedModels).
    3. Автоматическая подготовка: Unanchor, CanCollide = false, Massless = true, точный Weld с C0/C1.
    4. Автоматическая сборка в Tool для рук и Dropped Model для земли.
--]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local ModelHelper = {}

-- Поиск мастер-модели предмета
function ModelHelper.findTemplate(itemKey)
	local lowerKey = string.lower(itemKey)

	local function isMatch(name)
		local l = string.lower(name)
		if l == lowerKey then return true end
		if string.find(l, lowerKey, 1, true) ~= nil then return true end
		if lowerKey == "spear" then
			if string.find(l, "spear", 1, true) or string.find(l, "копье", 1, true) or string.find(l, "копьё", 1, true) then
				return true
			end
		end
		return false
	end

	-- 1. ReplicatedStorage.Models (импортированные сетки MeshPart)
	local modelsFolder = ReplicatedStorage:FindFirstChild("Models")
	if modelsFolder then
		for _, child in ipairs(modelsFolder:GetChildren()) do
			if isMatch(child.Name) and (child:IsA("Model") or child:IsA("Folder") or child:IsA("BasePart")) then
				-- Убедимся, что это не пустая папка или StringValue
				if child:IsA("BasePart") or #child:GetDescendants() > 0 then
					print(string.format("🔍 [ModelHelper] Найдена 3D-модель '%s' в ReplicatedStorage.Models: '%s'", itemKey, child.Name))
					return child
				end
			end
		end
	end

	-- 2. Workspace (импортированные меши в сцене)
	for _, child in ipairs(Workspace:GetChildren()) do
		if isMatch(child.Name) and not child:FindFirstChildOfClass("Humanoid") and (child:IsA("Model") or child:IsA("Folder") or child:IsA("BasePart")) then
			if child:IsA("BasePart") or #child:GetDescendants() > 0 then
				print(string.format("🔍 [ModelHelper] Найдена 3D-модель '%s' в Workspace: '%s'", itemKey, child.Name))
				return child
			end
		end
	end

	-- 3. ReplicatedStorage.GeneratedModels (автоматически скомпилированные 3D-модули)
	local genFolder = ReplicatedStorage:FindFirstChild("GeneratedModels")
	if genFolder then
		local modScript = genFolder:FindFirstChild(itemKey)
		if not modScript then
			for _, ch in ipairs(genFolder:GetChildren()) do
				if isMatch(ch.Name) and ch:IsA("ModuleScript") then
					modScript = ch
					break
				end
			end
		end
		if modScript and modScript:IsA("ModuleScript") then
			local success, genModule = pcall(require, modScript)
			if success and genModule and type(genModule.create) == "function" then
				local generated = genModule.create(nil)
				if generated then
					print(string.format("⚡ [ModelHelper] Сгенерирована высокоточная 3D-модель '%s' из GeneratedModels", itemKey))
					return generated
				end
			end
		end
	end

	-- 4. ServerStorage
	local serverStorage = game:GetService("ServerStorage")
	if serverStorage then
		for _, child in ipairs(serverStorage:GetChildren()) do
			if isMatch(child.Name) and (child:IsA("Model") or child:IsA("Folder") or child:IsA("BasePart")) then
				if child:IsA("BasePart") or #child:GetDescendants() > 0 then
					print(string.format("🔍 [ModelHelper] Найдена модель '%s' в ServerStorage: '%s'", itemKey, child.Name))
					return child
				end
			end
		end
	end

	return nil
end

-- Сборка объекта Tool из 3D-модели
function ModelHelper.assembleTool(itemKey, parentTool)
	local template = ModelHelper.findTemplate(itemKey)
	if not template then 
		print(string.format("⚠️ [ModelHelper] Шаблон 3D-модели для '%s' не найден", itemKey))
		return nil 
	end

	-- Если template уже был создан через GeneratedModels, используем его, иначе клонируем
	local clone = (template.Parent == nil) and template or template:Clone()
	local handle = nil

	if clone:IsA("BasePart") then
		handle = clone
		handle.Name = "Handle"
		handle.Anchored = false
		handle.CanCollide = false
		handle.Massless = true
		handle.Parent = parentTool
		return handle
	elseif clone:IsA("Model") or clone:IsA("Folder") then
		local allParts = {}
		for _, desc in ipairs(clone:GetDescendants()) do
			if desc:IsA("BasePart") then
				table.insert(allParts, desc)
			end
		end

		if #allParts == 0 then
			clone:Destroy()
			return nil
		end

		-- Ищем деталь Handle или Grip
		for _, p in ipairs(allParts) do
			local pName = string.lower(p.Name)
			if pName == "handle" or pName == "grip" or string.find(pName, "handle") or string.find(pName, "grip") then
				handle = p
				break
			end
		end
		if not handle then
			handle = clone.PrimaryPart or allParts[1]
		end

		handle.Name = "Handle"
		handle.Anchored = false
		handle.CanCollide = false
		handle.Massless = true
		handle.Parent = parentTool

		-- Переносим остальные части и свариваем через математический Weld (C0/C1)
		for _, otherPart in ipairs(allParts) do
			if otherPart ~= handle then
				otherPart.Anchored = false
				otherPart.CanCollide = false
				otherPart.Massless = true
				
				local relCF = handle.CFrame:ToObjectSpace(otherPart.CFrame)
				otherPart.Parent = parentTool

				-- Удаляем старые Weld
				for _, w in ipairs(otherPart:GetChildren()) do
					if w:IsA("Weld") or w:IsA("WeldConstraint") then
						w:Destroy()
					end
				end

				local weld = Instance.new("Weld")
				weld.Name = "Weld_" .. otherPart.Name
				weld.Part0 = handle
				weld.Part1 = otherPart
				weld.C0 = relCF
				weld.C1 = CFrame.identity
				weld.Parent = handle
			end
		end

		clone:Destroy()
		print(string.format("✅ [ModelHelper] Tool '%s' успешно собран из %d мешей модели!", itemKey, #allParts))
		return handle
	end

	return nil
end

-- Сборка Dropped Model для выпадающих предметов на земле
function ModelHelper.assembleDropModel(itemName, pos)
	local template = ModelHelper.findTemplate(itemName)
	if not template then return nil end

	local clone = (template.Parent == nil) and template or template:Clone()
	local root = nil
	local randYaw = CFrame.Angles(0, math.rad(math.random(0, 360)), 0)

	-- Для длинных предметов (копье, факел) укладываем их горизонтально на землю
	local lower = string.lower(itemName)
	local isElongated = (lower == "spear" or lower == "torch" or string.find(lower, "spear") or string.find(lower, "torch"))
	local flatTilt = isElongated and CFrame.Angles(0, 0, math.rad(90)) or CFrame.identity
	local targetCF = CFrame.new(pos) * randYaw * flatTilt

	if clone:IsA("BasePart") then
		root = clone
		root.Name = "Dropped_" .. itemName
		root.CFrame = targetCF
		root.Anchored = false
		root.CanCollide = true
		root.Massless = false
		return root
	else
		local allParts = {}
		for _, desc in ipairs(clone:GetDescendants()) do
			if desc:IsA("BasePart") then
				table.insert(allParts, desc)
			end
		end

		if #allParts == 0 then
			clone:Destroy()
			return nil
		end

		local primary = clone:FindFirstChild("Handle") or clone.PrimaryPart or allParts[1]
		local primaryOriginCF = primary.CFrame

		root = Instance.new("Part")
		root.Name = "Dropped_" .. itemName
		root.Size = Vector3.new(0.6, 0.6, 0.6)
		root.Transparency = 1
		root.CFrame = targetCF
		root.Anchored = false
		root.CanCollide = true
		root.Massless = false

		for _, p in ipairs(allParts) do
			local relCF = primaryOriginCF:ToObjectSpace(p.CFrame)
			p.CFrame = root.CFrame * relCF
			p.Anchored = false
			p.CanCollide = false
			p.Massless = true
			p.Parent = root

			for _, w in ipairs(p:GetChildren()) do
				if w:IsA("Weld") or w:IsA("WeldConstraint") then
					w:Destroy()
				end
			end

			local weld = Instance.new("Weld")
			weld.Name = "Weld_" .. p.Name
			weld.Part0 = root
			weld.Part1 = p
			weld.C0 = relCF
			weld.C1 = CFrame.identity
			weld.Parent = root
		end

		clone:Destroy()
		return root
	end
end

return ModelHelper
