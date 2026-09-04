--[[
    ReplicatedStorage/ModelHelper.luau
    Универсальный менеджер и фабрика 3D-моделей для Survive the Cold:
    1. Автоматическая генерация высокоточных 3D-моделей из ReplicatedStorage.GeneratedModels.
    2. Поиск импортированных MeshPart моделей (ReplicatedStorage.Models / ServerStorage).
    3. Автоматическая подготовка: Unanchor, CanCollide, Massless, точный Weld с C0/C1.
    4. Автоматическая сборка в Tool для рук и Dropped Model для земли.
--]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local ModelHelper = {}

local function isValid3DModel(inst)
	if not inst then return false end
	if inst:IsA("MeshPart") then
		return inst.MeshId ~= "" and inst.MeshId ~= "rbxassetid://0"
	end
	if inst:IsA("BasePart") then return true end
	if inst:IsA("Model") or inst:IsA("Folder") then
		for _, desc in ipairs(inst:GetDescendants()) do
			if desc:IsA("MeshPart") then
				if desc.MeshId ~= "" and desc.MeshId ~= "rbxassetid://0" then
					return true
				end
			elseif desc:IsA("BasePart") then
				return true
			end
		end
	end
	return false
end

-- Поиск мастер-модели предмета
function ModelHelper.findTemplate(itemKey)
	local lowerKey = string.lower(itemKey)

	local function isMatch(name)
		local l = string.lower(name)
		if l == lowerKey then return true end

		if lowerKey == "parts" or lowerKey == "part" or lowerKey == "детали" or lowerKey == "деталь" then
			if (l == "parts" or l == "part" or string.find(l, "детал", 1, true) or string.find(l, "шестерен", 1, true)) and not string.find(l, "chest", 1, true) then
				return true
			end
			return false
		end

		if string.find(l, lowerKey, 1, true) ~= nil then return true end
		if lowerKey == "spear" then
			if string.find(l, "spear", 1, true) or string.find(l, "копье", 1, true) or string.find(l, "копьё", 1, true) then
				return true
			end
		end
		if lowerKey == "torch" then
			if string.find(l, "torch", 1, true) or string.find(l, "факел", 1, true) then
				return true
			end
		end
		if lowerKey == "chest_parts" or lowerKey == "chestparts" or lowerKey == "partchest" or lowerKey == "homepartchest" then
			if string.find(l, "parts", 1, true) and string.find(l, "chest", 1, true) then
				return true
			end
		end
		if lowerKey == "campfire" or lowerKey == "campfirekit" or lowerKey == "костер" or lowerKey == "костёр" then
			if string.find(l, "campfire", 1, true) or string.find(l, "fire", 1, true) then
				return true
			end
		end
		if lowerKey == "rabbittrap" or lowerKey == "rabbit_trap" or lowerKey == "капкан" then
			if string.find(l, "rabbit", 1, true) or string.find(l, "trap", 1, true) then
				return true
			end
		end
		if lowerKey == "spiketrap" or lowerKey == "spike_trap" or lowerKey == "шипы" then
			if string.find(l, "spike", 1, true) then
				return true
			end
		end
		if lowerKey == "icecrystal" or lowerKey == "ice_crystal" or lowerKey == "iceblock" or lowerKey == "глыба" then
			if string.find(l, "crystal", 1, true) or string.find(l, "ice", 1, true) then
				return true
			end
		end
		if lowerKey == "branches" or lowerKey == "branch" or lowerKey == "ветки" or lowerKey == "ветка" or lowerKey == "палки" then
			if string.find(l, "branch", 1, true) or string.find(l, "stick", 1, true) or string.find(l, "ветк", 1, true) then
				return true
			end
		end
		if lowerKey == "stone" or lowerKey == "rock" or lowerKey == "boulder" or lowerKey == "камень" or lowerKey == "валун" then
			if string.find(l, "stone", 1, true) or string.find(l, "boulder", 1, true) or string.find(l, "rock", 1, true) or string.find(l, "камен", 1, true) then
				return true
			end
		end
		if lowerKey == "fiber" or lowerKey == "straw" or lowerKey == "волокно" or lowerKey == "трава" then
			if string.find(l, "fiber", 1, true) or string.find(l, "straw", 1, true) or string.find(l, "волокн", 1, true) then
				return true
			end
		end
		if lowerKey == "planks" or lowerKey == "plank" or lowerKey == "wood" or lowerKey == "доски" or lowerKey == "доска" then
			if string.find(l, "plank", 1, true) or string.find(l, "доск", 1, true) then
				return true
			end
		end
		if lowerKey == "firtree" or lowerKey == "fir_tree" or lowerKey == "tree" or lowerKey == "елка" or lowerKey == "ель" or lowerKey == "дерево" then
			if string.find(l, "fir", 1, true) or string.find(l, "tree", 1, true) or string.find(l, "ель", 1, true) or string.find(l, "елк", 1, true) then
				return true
			end
		end
		if lowerKey == "wolf" or lowerKey == "волк" then
			if string.find(l, "wolf", 1, true) or string.find(l, "волк", 1, true) then
				return true
			end
		end
		if lowerKey == "yeti" or lowerKey == "йети" then
			if string.find(l, "yeti", 1, true) or string.find(l, "йети", 1, true) then
				return true
			end
		end
		if lowerKey == "bigfoot" or lowerKey == "бигфут" or lowerKey == "sasquatch" then
			if string.find(l, "bigfoot", 1, true) or string.find(l, "бигфут", 1, true) or string.find(l, "sasquatch", 1, true) then
				return true
			end
		end
		return false
	end

	-- 1. ReplicatedStorage.GeneratedModels (высокоточные 3D-модели из процедурных модулей)
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
				if generated and isValid3DModel(generated) then
					return generated
				end
			end
		end
	end

	-- 2. ReplicatedStorage.Models (импортированные сетки MeshPart, если они импортированы в студии)
	local modelsFolder = ReplicatedStorage:FindFirstChild("Models")
	if modelsFolder then
		for _, child in ipairs(modelsFolder:GetDescendants()) do
			if isMatch(child.Name) and isValid3DModel(child) then
				return child
			end
		end
	end

	-- 3. ServerStorage
	local serverStorage = game:GetService("ServerStorage")
	if serverStorage then
		for _, child in ipairs(serverStorage:GetChildren()) do
			if isMatch(child.Name) and isValid3DModel(child) then
				return child
			end
		end
	end

	return nil
end

-- Сборка объекта Tool из 3D-модели
function ModelHelper.assembleTool(itemKey, parentTool)
	local template = ModelHelper.findTemplate(itemKey)
	if not template then 
		return nil 
	end

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

		-- Переносим остальные части и свариваем через современный WeldConstraint
		for _, otherPart in ipairs(allParts) do
			if otherPart ~= handle then
				otherPart.Anchored = false
				otherPart.CanCollide = false
				otherPart.Massless = true
				otherPart.Parent = parentTool

				for _, w in ipairs(otherPart:GetChildren()) do
					if w:IsA("Weld") or w:IsA("ManualWeld") or w:IsA("WeldConstraint") then
						w:Destroy()
					end
				end

				local weld = Instance.new("WeldConstraint")
				weld.Name = "Weld_" .. otherPart.Name
				weld.Part0 = handle
				weld.Part1 = otherPart
				weld.Parent = otherPart
			end
		end

		clone:Destroy()
		return handle
	end

	return nil
end

-- Сборка Dropped Model для выпадающих предметов на земле
function ModelHelper.assembleDropModel(itemName, pos)
	local template = ModelHelper.findTemplate(itemName)
	if not template then return nil end

	local clone = (template.Parent == nil) and template or template:Clone()
	local randYaw = CFrame.Angles(0, math.rad(math.random(0, 360)), 0)

	local lower = string.lower(itemName)
	local isElongated = (lower == "spear" or lower == "torch" or string.find(lower, "spear") or string.find(lower, "torch"))
	local flatTilt = isElongated and CFrame.Angles(math.rad(90), 0, 0) or CFrame.identity
	local targetCF = CFrame.new(pos) * randYaw * flatTilt

	if clone:IsA("BasePart") then
		clone.Name = "Dropped_" .. itemName
		clone.CFrame = targetCF
		clone.Anchored = false
		clone.CanCollide = true
		clone.Massless = false
		clone.Transparency = 0
		return clone
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
		clone.PrimaryPart = primary
		clone.Name = "Dropped_" .. itemName
		clone:PivotTo(targetCF)

		for _, p in ipairs(allParts) do
			p.Anchored = false
			p.Transparency = 0
			p.CastShadow = true

			for _, w in ipairs(p:GetChildren()) do
				if w:IsA("Weld") or w:IsA("ManualWeld") then
					w:Destroy()
				end
			end

			if p == primary then
				p.CanCollide = true
				p.Massless = false
			else
				p.CanCollide = false
				p.Massless = true
				local wc = p:FindFirstChildOfClass("WeldConstraint")
				if not wc then
					wc = Instance.new("WeldConstraint")
					wc.Name = "Weld_" .. p.Name
					wc.Part0 = primary
					wc.Part1 = p
					wc.Parent = p
				else
					wc.Part0 = primary
					wc.Part1 = p
				end
			end
		end

		return clone
	end
end

return ModelHelper
