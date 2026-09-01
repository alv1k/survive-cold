--[[
    FoxRadarController.client.luau
    Клиентский скрипт радара Снежного Лиса:
    - Когда Лис активен, рисует 3D луч/направление к ближайшей реликвии на карте
--]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local RelicsFolder = workspace:WaitForChild("Relics", 10)

local radarBeam = Instance.new("Beam")
radarBeam.Color = ColorSequence.new(Color3.fromRGB(6, 182, 212))
radarBeam.Width0 = 0.5
radarBeam.Width1 = 1.2
radarBeam.Texture = "rbxassetid://446111271"
radarBeam.TextureSpeed = 2
radarBeam.Enabled = false
radarBeam.Parent = workspace.CurrentCamera

local att0 = Instance.new("Attachment", workspace.Terrain)
local att1 = Instance.new("Attachment", workspace.Terrain)
radarBeam.Attachment0 = att0
radarBeam.Attachment1 = att1

RunService.RenderStepped:Connect(function()
	local char = player.Character
	local hrp = char and char:FindFirstChild("HumanoidRootPart")
	local foxBuff = player:GetAttribute("FoxStaminaBuff") or 1.0

	if hrp and foxBuff > 1.0 and RelicsFolder then
		local closestRelic = nil
		local minDistance = math.huge

		for _, site in ipairs(RelicsFolder:GetChildren()) do
			local targetPart = nil
			if site:IsA("Model") then
				targetPart = site.PrimaryPart or site:FindFirstChildWhichIsA("BasePart")
			elseif site:IsA("BasePart") then
				targetPart = site
			end

			if targetPart then
				local dist = (targetPart.Position - hrp.Position).Magnitude
				if dist < minDistance then
					minDistance = dist
					closestRelic = targetPart
				end
			end
		end

		if closestRelic then
			att0.WorldPosition = hrp.Position + Vector3.new(0, 1, 0)
			att1.WorldPosition = closestRelic.Position + Vector3.new(0, 1, 0)
			radarBeam.Enabled = true
		else
			radarBeam.Enabled = false
		end
	else
		radarBeam.Enabled = false
	end
end)
