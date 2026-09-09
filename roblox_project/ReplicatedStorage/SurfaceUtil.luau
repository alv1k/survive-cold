--!strict
--[[
    ReplicatedStorage/SurfaceUtil.luau
    Быстрая и надежная координатная система высот мира («Survive the Cold»):
    - 🏠 Внутри дома игрока: Y = 1.2 (деревянный пол)
    - 🧊 Замерзшее ледяное озеро (Запад): Y = 0.8 (гладкий зеркальный лед)
    - 🏔️ Восточный хребет (Горы): Y = 53.0 (скалистая вершина)
    - ❄️ Снежная равнина карты (3200x3200): Y = 2.0 (чистый уровень над сугробами)
    - 🚀 100% стабильность, без тяжелых физических лучей Raycast, лагов и осечек.
--]]

local SurfaceUtil = {}

-- 1. Зона дома игрока (PlayerHouse)
function SurfaceUtil.isInsidePlayerHouse(pos: Vector3): boolean
	return math.abs(pos.X) <= 13.5 and math.abs(pos.Z) <= 12.5 and pos.Y <= 17
end

-- 2. Зона замерзшего озера (IceLake: центр -650, -350, размер 450x400)
function SurfaceUtil.isInsideIceLake(pos: Vector3): boolean
	return pos.X >= -875 and pos.X <= -425 and pos.Z >= -550 and pos.Z <= -150
end

-- 3. Зона восточного скалистого хребта (EastRidge: центр 1050, 0, размер 350x3200)
function SurfaceUtil.isInsideEastRidge(pos: Vector3): boolean
	return pos.X >= 890 and pos.X <= 1210
end

-- 4. Получить точную высоту поверхности Y по координатам X, Z
function SurfaceUtil.getGroundHeight(x: number, z: number, _startY: number?, _customIgnoreList: { Instance }?): number
	-- 1. Дом игрока
	if math.abs(x) <= 13.5 and math.abs(z) <= 12.5 then
		return 2.6
	end

	-- 2. Замерзшее озеро
	if x >= -875 and x <= -425 and z >= -550 and z <= -150 then
		return 0.8
	end

	-- 3. Восточный хребет
	if x >= 890 and x <= 1210 then
		return 53.0
	end

	-- 4. Основная снежная равнина карты
	return 2.0
end

-- 5. Найти точку контакта с поверхностью (Vector3, Normal, Material)
function SurfaceUtil.getSurfacePosition(targetPos: Vector3, _customIgnoreList: { Instance }?): (Vector3, Vector3, Enum.Material)
	local x = targetPos.X
	local z = targetPos.Z

	-- 1. Дом игрока
	if SurfaceUtil.isInsidePlayerHouse(targetPos) then
		return Vector3.new(x, 2.6, z), Vector3.new(0, 1, 0), Enum.Material.WoodPlanks
	end

	-- 2. Замерзшее озеро
	if SurfaceUtil.isInsideIceLake(targetPos) then
		return Vector3.new(x, 0.8, z), Vector3.new(0, 1, 0), Enum.Material.Ice
	end

	-- 3. Восточный хребет
	if SurfaceUtil.isInsideEastRidge(targetPos) then
		return Vector3.new(x, 53.0, z), Vector3.new(0, 1, 0), Enum.Material.Snow
	end

	-- 4. Основная снежная равнина
	return Vector3.new(x, 2.0, z), Vector3.new(0, 1, 0), Enum.Material.Snow
end

-- 6. Вычислить CFrame идеальной посадки объекта на поверхность (по нижней границе меша/модели)
function SurfaceUtil.getSurfaceCFrame(modelOrPart: Instance?, targetPos: Vector3, extraYOffset: number?, _alignWithNormal: boolean?): CFrame
	local hitPos, _, _ = SurfaceUtil.getSurfacePosition(targetPos)
	local yOffset = extraYOffset or 0.05
	local targetBottomY = hitPos.Y + yOffset

	if not modelOrPart then
		return CFrame.new(hitPos.X, targetBottomY, hitPos.Z)
	end

	local currentRotation = CFrame.identity
	local currentBottomOffset = 0

	if modelOrPart:IsA("Model") then
		currentRotation = modelOrPart:GetPivot().Rotation
		local pivotPos = modelOrPart:GetPivot().Position
		local bbCF, bbSize = modelOrPart:GetBoundingBox()
		local bbBottomY = bbCF.Position.Y - (bbSize.Y / 2)
		currentBottomOffset = pivotPos.Y - bbBottomY
	elseif modelOrPart:IsA("BasePart") then
		currentRotation = modelOrPart.CFrame.Rotation
		currentBottomOffset = modelOrPart.Size.Y / 2
	end

	local finalPivotY = targetBottomY + currentBottomOffset
	return CFrame.new(Vector3.new(hitPos.X, finalPivotY, hitPos.Z)) * currentRotation
end

-- 7. Установить модель/деталь на поверхность
function SurfaceUtil.placeOnSurface(modelOrPart: Instance, targetPos: Vector3, extraYOffset: number?, alignWithNormal: boolean?): CFrame
	local targetCF = SurfaceUtil.getSurfaceCFrame(modelOrPart, targetPos, extraYOffset, alignWithNormal)

	if modelOrPart:IsA("Model") then
		modelOrPart:PivotTo(targetCF)
	elseif modelOrPart:IsA("BasePart") then
		modelOrPart.CFrame = targetCF
	end

	return targetCF
end

return SurfaceUtil
