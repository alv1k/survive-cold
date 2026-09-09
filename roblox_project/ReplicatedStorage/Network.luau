--!strict
--[[
    ReplicatedStorage/Network.luau
    Централизованный сетевой менеджер (RemoteEvents & RemoteFunctions):
    - Создает и кэширует все сетевые события один раз при старте
    - Устраняет дублирование создания папок Remotes и таймаутов WaitForChild
--]]

local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Network = {}

local REMOTES_FOLDER_NAME = "Remotes"

local REMOTE_EVENTS = {
	"AttackMelee",
	"ShootRanged",
	"ShowNotification",
	"ShowDeathScreen",
	"HideDeathScreen",
	"RespawnInHouse",
	"ReviveWithRobux",
	"StartGame",
	"CraftItem",
	"UpgradeWorkbench",
	"OpenWorkbench",
	"HarvestResource",
	"DropItem",
	"GlobalChatMessage",
	"EatFood",
	"PlayCustomSound",
	"ToggleFoxRadar",
	"PromptRebirth",
	"OpenPetMenu",
	"TogglePetMode",
	"FeedPet",
	"UpdatePetData"
}

local REMOTE_FUNCTIONS = {
	"BuyFood"
}

local function getRemotesFolder(): Folder
	if RunService:IsServer() then
		local folder = ReplicatedStorage:FindFirstChild(REMOTES_FOLDER_NAME)
		if not folder then
			folder = Instance.new("Folder")
			folder.Name = REMOTES_FOLDER_NAME
			folder.Parent = ReplicatedStorage
		end
		return folder :: Folder
	else
		local folder = ReplicatedStorage:WaitForChild(REMOTES_FOLDER_NAME, 15)
		if not folder then
			error("⚠️ [Network] Папка Remotes не была создана сервером вовремя!")
		end
		return folder :: Folder
	end
end

local remotesFolder = getRemotesFolder()

-- Инициализация всех событий на сервере при первом вызове
if RunService:IsServer() then
	for _, eventName in ipairs(REMOTE_EVENTS) do
		if not remotesFolder:FindFirstChild(eventName) then
			local re = Instance.new("RemoteEvent")
			re.Name = eventName
			re.Parent = remotesFolder
		end
	end

	for _, funcName in ipairs(REMOTE_FUNCTIONS) do
		if not remotesFolder:FindFirstChild(funcName) then
			local rf = Instance.new("RemoteFunction")
			rf.Name = funcName
			rf.Parent = remotesFolder
		end
	end
end

-- Получить RemoteEvent
function Network.getEvent(eventName: string): RemoteEvent
	local event = remotesFolder:FindFirstChild(eventName)
	if not event then
		if RunService:IsServer() then
			local re = Instance.new("RemoteEvent")
			re.Name = eventName
			re.Parent = remotesFolder
			return re
		else
			event = remotesFolder:WaitForChild(eventName, 10)
		end
	end

	if not event or not event:IsA("RemoteEvent") then
		error(string.format("⚠️ [Network] RemoteEvent '%s' не найден!", eventName))
	end
	return event :: RemoteEvent
end

-- Получить RemoteFunction
function Network.getFunction(funcName: string): RemoteFunction
	local func = remotesFolder:FindFirstChild(funcName)
	if not func then
		if RunService:IsServer() then
			local rf = Instance.new("RemoteFunction")
			rf.Name = funcName
			rf.Parent = remotesFolder
			return rf
		else
			func = remotesFolder:WaitForChild(funcName, 10)
		end
	end

	if not func or not func:IsA("RemoteFunction") then
		error(string.format("⚠️ [Network] RemoteFunction '%s' не найдена!", funcName))
	end
	return func :: RemoteFunction
end

return Network
