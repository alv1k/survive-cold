--[[
    WeaponCombatController.client.luau
    Клиентское управление боем и оружием:
    - 🗡️ Копье (Spear): 0.8с темп удара, нативная дефолтная анимация Roblox (Tool Slash)
    - 🏹 Праща (Slingshot): 0.6с темп стрельбы
    - 🔫 Револьвер (Revolver): 0.35с темп стрельбы
    - 100% официальные встроенные анимации персонажа Roblox без сторонних ассетов
--]]

local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local player = Players.LocalPlayer
local mouse = player:GetMouse()

local RemotesFolder = ReplicatedStorage:WaitForChild("Remotes", 10)
if not RemotesFolder then return end

local AttackMeleeRemote = RemotesFolder:WaitForChild("AttackMelee", 10)
local ShootRangedRemote = RemotesFolder:WaitForChild("ShootRanged", 10)

local WEAPON_FIRERATES = {
	Spear = 0.8,
	Slingshot = 0.6,
	Revolver = 0.35
}

local lastAttackTimes = {}

-- Определение экипированного оружия
local function getEquippedWeapon()
	local char = player.Character
	if not char then return nil, nil end

	local tool = char:FindFirstChildOfClass("Tool")
	if tool then
		local itemKey = tool:GetAttribute("ItemKey") or tool.Name
		if WEAPON_FIRERATES[itemKey] then
			return itemKey, tool
		end
		local lowerName = string.lower(tool.Name)
		if string.find(lowerName, "копье") or string.find(lowerName, "копьё") or string.find(lowerName, "spear") then
			return "Spear", tool
		elseif string.find(lowerName, "праща") or string.find(lowerName, "рогатка") or string.find(lowerName, "slingshot") then
			return "Slingshot", tool
		elseif string.find(lowerName, "револьвер") or string.find(lowerName, "revolver") then
			return "Revolver", tool
		end
	end

	local attrWeapon = player:GetAttribute("EquippedItem")
	if attrWeapon and WEAPON_FIRERATES[attrWeapon] then
		return attrWeapon, tool
	end

	return nil, nil
end

-- Поиск модели моба под курсором мыши
local function getMobUnderMouse()
	local target = mouse.Target
	if not target then return nil end

	local mobsFolder = workspace:FindFirstChild("Mobs")
	if not mobsFolder then return nil end

	local model = target:FindFirstAncestorOfClass("Model")
	if model and model:IsDescendantOf(mobsFolder) then
		return model
	end

	return nil
end

-- Нативная дефолтная анимация атаки оружием Roblox (Tool Slash)
local function playDefaultWeaponAnimation(tool)
	local char = player.Character
	if not char then return end

	local humanoid = char:FindFirstChildOfClass("Humanoid")
	local animator = humanoid and (humanoid:FindFirstChildOfClass("Animator") or Instance.new("Animator", humanoid))
	local animateScript = char:FindFirstChild("Animate")

	-- 1. Воспроизводим официальную встроенную анимацию из скрипта Animate персонажа
	if animator and animateScript then
		local slashFolder = animateScript:FindFirstChild("toolslash") or animateScript:FindFirstChild("toollunge") or animateScript:FindFirstChild("slash")
		local animObj = slashFolder and slashFolder:FindFirstChildOfClass("Animation")
		if animObj then
			local success, track = pcall(function()
				return animator:LoadAnimation(animObj)
			end)
			if success and track then
				track.Priority = Enum.AnimationPriority.Action
				track:Play(0.05, 1, 1.6)
			end
		end
	end

	-- 2. Нативный классический триггер Roblox toolanim
	if tool and tool:IsA("Tool") then
		local animVal = Instance.new("StringValue")
		animVal.Name = "toolanim"
		animVal.Value = "Slash"
		animVal.Parent = tool
	end

	-- 3. Звуковой эффект рассекающего удара (Whoosh)
	local hrp = char:FindFirstChild("HumanoidRootPart")
	if hrp then
		local sound = Instance.new("Sound")
		sound.SoundId = "rbxasset://sounds/action_swipe.mp3"
		sound.Volume = 0.9
		sound.PlaybackSpeed = 1.25
		sound.Parent = hrp
		sound:Play()
		sound.Ended:Connect(function() sound:Destroy() end)
	end
end

-- Единая функция запуска атаки оружием
local function onAttackTrigger()
	local weaponType, tool = getEquippedWeapon()
	if not weaponType then return end

	local fireRate = WEAPON_FIRERATES[weaponType] or 0.8
	local now = os.clock()
	local lastTime = lastAttackTimes[weaponType] or 0

	if now - lastTime < (fireRate * 0.75) then
		return -- Еще идет кулдаун
	end
	lastAttackTimes[weaponType] = now

	local targetMob = getMobUnderMouse()

	if weaponType == "Spear" then
		playDefaultWeaponAnimation(tool)
		if AttackMeleeRemote then
			AttackMeleeRemote:FireServer(targetMob)
		end
	else
		if ShootRangedRemote then
			ShootRangedRemote:FireServer(weaponType, targetMob)
		end
	end
end

-- 1. Подписка на клик мыши и экранный тап
UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		local weaponType = getEquippedWeapon()
		if weaponType then
			onAttackTrigger()
		end
	end
end)

-- 2. Подписка на нативный Tool.Activated
local function bindTool(tool)
	if tool:IsA("Tool") then
		tool.Activated:Connect(function()
			onAttackTrigger()
		end)
	end
end

local function onCharacterAdded(char)
	char.ChildAdded:Connect(function(child)
		if child:IsA("Tool") then
			bindTool(child)
		end
	end)
	for _, child in ipairs(char:GetChildren()) do
		if child:IsA("Tool") then
			bindTool(child)
		end
	end
end

if player.Character then
	onCharacterAdded(player.Character)
end
player.CharacterAdded:Connect(onCharacterAdded)

print("🗡️ [WeaponCombatController] Нативная дефолтная система боя Roblox активна!")
