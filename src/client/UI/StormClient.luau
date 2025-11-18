--!strict
-- ================================================================
-- STORM CLIENT (NEW - Based on Example)
-- ================================================================
-- Renders the storm by listening to ReplicatedStorage.Storm values
-- Shows a visual sphere that closes in
-- ================================================================

print("[StormClient] Initializing...")

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")

-- Wait for Storm folder
local STORM = ReplicatedStorage:WaitForChild("Storm")
local CENTER = STORM:WaitForChild("Center") :: Vector3Value
local RADIUS = STORM:WaitForChild("Radius") :: NumberValue
local TARGET_CENTER = STORM:WaitForChild("TargetCenter") :: Vector3Value
local TARGET_RADIUS = STORM:WaitForChild("TargetRadius") :: NumberValue

local CAMERA = Workspace.CurrentCamera

-- Get or create effects folder
local effectsFolder = Workspace:FindFirstChild("Effects")
if not effectsFolder then
	effectsFolder = Instance.new("Folder")
	effectsFolder.Name = "Effects"
	effectsFolder.Parent = Workspace
end

-- ================================================================
-- STORM SPHERE (Current safe zone boundary)
-- ================================================================

local stormSphere = Instance.new("Part")
stormSphere.Name = "StormSphere"
stormSphere.Anchored = true
stormSphere.CanCollide = false
stormSphere.Material = Enum.Material.ForceField
stormSphere.Color = Color3.fromRGB(150, 50, 255) -- Purple storm
stormSphere.Transparency = 0.7
stormSphere.TopSurface = Enum.SurfaceType.Smooth
stormSphere.BottomSurface = Enum.SurfaceType.Smooth
stormSphere.Parent = effectsFolder

local sphereMesh = Instance.new("SpecialMesh")
sphereMesh.MeshType = Enum.MeshType.Sphere
sphereMesh.Parent = stormSphere

-- ================================================================
-- TARGET CIRCLE (White circle showing where storm will close to)
-- ================================================================

local function createCirclePart(): Part
	local part = Instance.new("Part")
	part.Anchored = true
	part.CanCollide = false
	part.Material = Enum.Material.Neon
	part.Color = Color3.fromRGB(255, 255, 255) -- White
	part.Transparency = 0.5
	part.TopSurface = Enum.SurfaceType.Smooth
	part.BottomSurface = Enum.SurfaceType.Smooth
	part.Size = Vector3.new(2, 0.3, 2)
	return part
end

local targetCircleParts: {Part} = {}
local CIRCLE_SEGMENTS = 64

local function clearTargetCircle()
	for _, part in ipairs(targetCircleParts) do
		part:Destroy()
	end
	table.clear(targetCircleParts)
end

local function createTargetCircle(radius: number, center: Vector3)
	clearTargetCircle()
	
	if radius >= 50000 then return end -- Don't show for huge radius
	
	local segmentAngle = (2 * math.pi) / CIRCLE_SEGMENTS
	
	for i = 0, CIRCLE_SEGMENTS - 1 do
		local angle1 = i * segmentAngle
		local angle2 = (i + 1) * segmentAngle
		
		local x1 = center.X + math.cos(angle1) * radius
		local z1 = center.Z + math.sin(angle1) * radius
		local x2 = center.X + math.cos(angle2) * radius
		local z2 = center.Z + math.sin(angle2) * radius
		
		local midX = (x1 + x2) / 2
		local midZ = (z1 + z2) / 2
		local midPoint = Vector3.new(midX, 0.5, midZ)
		
		local part = createCirclePart()
		part.Parent = effectsFolder
		
		local length = math.sqrt((x2 - x1)^2 + (z2 - z1)^2)
		part.Size = Vector3.new(length, 0.3, 1)
		
		local lookVector = Vector3.new(x2 - x1, 0, z2 - z1).Unit
		part.CFrame = CFrame.new(midPoint, midPoint + lookVector)
		
		table.insert(targetCircleParts, part)
	end
	
	print("[StormClient] 🔵 Created target circle at radius " .. radius)
end

-- ================================================================
-- UPDATE FUNCTION
-- ================================================================

local function update()
	-- Update storm sphere
	local currentRadius = RADIUS.Value
	local currentCenter = CENTER.Value
	
	sphereMesh.Scale = Vector3.new(currentRadius * 2, 500, currentRadius * 2)
	stormSphere.CFrame = CFrame.new(currentCenter + Vector3.new(0, 250, 0))
	
	-- Show/hide target circle
	local targetRadius = TARGET_RADIUS.Value
	local targetCenter = TARGET_CENTER.Value
	
	-- Only show target circle if it's different from current AND not huge
	if math.abs(targetRadius - currentRadius) > 10 and targetRadius < 50000 then
		if #targetCircleParts == 0 then
			createTargetCircle(targetRadius, targetCenter)
		end
	else
		-- Hide target circle when reached
		if #targetCircleParts > 0 then
			clearTargetCircle()
		end
	end
	
	-- Calculate player distance for effects (optional)
	if CAMERA.CFrame then
		local centerDistance = (Vector2.new(currentCenter.X, currentCenter.Z) - Vector2.new(CAMERA.CFrame.X, CAMERA.CFrame.Z)).Magnitude
		local edgeDistance = currentRadius - centerDistance
		
		-- Future: Could add visual effects based on edgeDistance
		-- If player is close to edge, add red vignette, screen shake, etc.
	end
end

-- ================================================================
-- EVENT LISTENERS
-- ================================================================

-- Update when values change
RADIUS.Changed:Connect(update)
CENTER.Changed:Connect(update)
TARGET_RADIUS.Changed:Connect(update)
TARGET_CENTER.Changed:Connect(update)

-- Update every frame for smooth camera-relative effects
RunService.RenderStepped:Connect(update)

-- Initial update
update()

print("[StormClient] ✅ Ready - listening to ReplicatedStorage.Storm values")

return {}
