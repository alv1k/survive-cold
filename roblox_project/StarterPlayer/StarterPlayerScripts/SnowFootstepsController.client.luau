--[[
    SnowFootstepsController.client.luau
    Клиентская система следов на снегу:
    - 👣 Оставляет реалистичные отпечатки ног на снегу при ходьбе и беге
    - ❄️ Следы плавно заметаются снегом и исчезают через 20 секунд
--]]

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local FootprintsFolder = workspace:FindFirstChild("SnowFootprints") or Instance.new("Folder", workspace)
FootprintsFolder.Name = "SnowFootprints"

local lastStepTime = 0
local isLeftFoot = true

local function spawnFootprint(pos, cframe)
	local rayOrigin = pos + Vector3.new(0, 3, 0)
	local rayDir = Vector3.new(0, -6, 0)
	local raycastParams = RaycastParams.new()
	raycastParams.FilterType = Enum.RaycastFilterType.Include
	raycastParams.FilterDescendantsInstances = { workspace.Terrain }

	local result = workspace:Raycast(rayOrigin, rayDir, raycastParams)
	if not result then return end

	local footprint = Instance.new("Part")
	footprint.Name = "Footprint"
	footprint.Size = Vector3.new(0.65, 0.05, 1.1)
	footprint.CFrame = CFrame.new(result.Position + Vector3.new(0, 0.04, 0)) * CFrame.Angles(0, math.rad(cframe.Rotation.Y), 0)
	footprint.Anchored = true
	footprint.CanCollide = false
	footprint.CastShadow = false
	footprint.Material = Enum.Material.Slate
	footprint.BrickColor = BrickColor.new("Pastel light blue")
	footprint.Transparency = 0.35
	footprint.Parent = FootprintsFolder

	Instance.new("CylinderMesh", footprint)

	-- Плавное занесение снегом через 18 секунд
	task.delay(18, function()
		if footprint and footprint.Parent then
			local fade = TweenService:Create(footprint, TweenInfo.new(4), { Transparency = 1 })
			fade:Play()
			fade.Completed:Connect(function()
				footprint:Destroy()
			end)
		end
	end)
end

local function trackSteps(char)
	local hrp = char:WaitForChild("HumanoidRootPart", 10)
	local humanoid = char:WaitForChild("Humanoid", 10)
	if not hrp or not humanoid then return end

	humanoid.Running:Connect(function(speed)
		if speed > 2 then
			local now = os.clock()
			local stepInterval = (speed > 20) and 0.28 or 0.42
			if now - lastStepTime >= stepInterval then
				lastStepTime = now
				local footOffset = isLeftFoot and Vector3.new(-0.55, -2.8, 0) or Vector3.new(0.55, -2.8, 0)
				isLeftFoot = not isLeftFoot
				local stepWorldPos = (hrp.CFrame * CFrame.new(footOffset)).Position
				spawnFootprint(stepWorldPos, hrp.CFrame)
			end
		end
	end)
end

if player.Character then trackSteps(player.Character) end
player.CharacterAdded:Connect(trackSteps)

print("👣 [SnowFootsteps] Система следов на снегу активна!")
