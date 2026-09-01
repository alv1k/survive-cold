--[[
    WeaponCombatController.client.luau
    Клиентское управление боем и стрельбой с соблюдением FireRate:
    - 🗡️ Копье (Spear): 0.8с темп удара
    - 🏹 Праща (Slingshot): 0.6с темп стрельбы
    - 🔫 Револьвер (Revolver): 0.35с темп стрельбы
    - Прицеливание мышью по монстрам в опасной зоне
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
	if not char then return nil end

	local tool = char:FindFirstChildOfClass("Tool")
	if tool then
		local itemKey = tool:GetAttribute("ItemKey") or tool.Name
		if WEAPON_FIRERATES[itemKey] then
			return itemKey
		end
	end

	local attrWeapon = player:GetAttribute("EquippedItem")
	if attrWeapon and WEAPON_FIRERATES[attrWeapon] then
		return attrWeapon
	end

	return nil
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

-- Обработка клика ЛКМ для атаки оружием
local function onAttackTrigger()
	local weaponType = getEquippedWeapon()
	if not weaponType then return end

	local fireRate = WEAPON_FIRERATES[weaponType] or 0.8
	local now = os.clock()
	local lastTime = lastAttackTimes[weaponType] or 0

	if now - lastTime < fireRate then
		return -- Еще идет кулдаун между выстрелами / ударами
	end
	lastAttackTimes[weaponType] = now

	local targetMob = getMobUnderMouse()

	if weaponType == "Spear" then
		if AttackMeleeRemote then
			AttackMeleeRemote:FireServer(targetMob)
		end
	else
		if ShootRangedRemote then
			ShootRangedRemote:FireServer(weaponType, targetMob)
		end
	end
end

UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then return end
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		onAttackTrigger()
	end
end)
