--!strict
-- ================================================================
-- STORM CLIENT
-- ================================================================
-- Visualizes the Battle Royale storm on the client
-- Shows:
-- - Current safe zone (green circle on ground)
-- - Next safe zone (white circle outline)
-- - Storm wall (particle effects at radius edge)
-- - Storm damage visual feedback
-- ================================================================

print("[StormClient] Initializing...")

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

-- Modules
local Remotes = require(ReplicatedStorage.Shared.Remotes)

-- ================================================================
-- CONFIGURATION
-- ================================================================

local CIRCLE_SEGMENTS = 64 -- Smoothness of circles
local CIRCLE_HEIGHT = 0.5 -- Height above ground
local CIRCLE_THICKNESS = 0.3 -- Thickness of circle line

local CURRENT_CIRCLE_COLOR = Color3.fromRGB(50, 255, 50) -- Green for safe zone
local NEXT_CIRCLE_COLOR = Color3.fromRGB(255, 255, 255) -- White for next zone
local STORM_COLOR = Color3.fromRGB(150, 50, 255) -- Purple for storm wall

-- ================================================================
-- STATE
-- ================================================================

local stormState = {
	currentRadius = 600,
	targetRadius = 600,
	center = Vector3.new(0, 5, 0),
	damagePercent = 0,
	phase = 1,
	isActive = false
}

-- Visual parts
local currentCircleParts: {Part} = {}
local nextCircleParts: {Part} = {}
local stormWallParts: {Part} = {}

-- Container folder (recreate if needed)
local function getStormFolder(): Folder
	local folder = Workspace:FindFirstChild("StormVisuals")
	if not folder then
		folder = Instance.new("Folder")
		folder.Name = "StormVisuals"
		folder.Parent = Workspace
		print("[StormClient] 📁 Created StormVisuals folder")
	end
	return folder
end

-- ================================================================
-- CIRCLE RENDERING
-- ================================================================

local function createCirclePart(position: Vector3, color: Color3, transparency: number): Part
	local part = Instance.new("Part")
	part.Size = Vector3.new(2, CIRCLE_THICKNESS, 2)
	part.Position = position
	part.Anchored = true
	part.CanCollide = false
	part.Color = color
	part.Material = Enum.Material.Neon
	part.Transparency = transparency
	part.TopSurface = Enum.SurfaceType.Smooth
	part.BottomSurface = Enum.SurfaceType.Smooth
	part.Parent = getStormFolder() -- Use getter to ensure folder exists
	return part
end

local function createCircle(radius: number, center: Vector3, color: Color3, transparency: number): {Part}
	local parts = {}
	local segmentAngle = (2 * math.pi) / CIRCLE_SEGMENTS
	
	for i = 0, CIRCLE_SEGMENTS - 1 do
		local angle1 = i * segmentAngle
		local angle2 = (i + 1) * segmentAngle
		
		-- Calculate positions
		local x1 = center.X + math.cos(angle1) * radius
		local z1 = center.Z + math.sin(angle1) * radius
		local x2 = center.X + math.cos(angle2) * radius
		local z2 = center.Z + math.sin(angle2) * radius
		
		-- Mid point
		local midX = (x1 + x2) / 2
		local midZ = (z1 + z2) / 2
		local midPoint = Vector3.new(midX, CIRCLE_HEIGHT, midZ)
		
		-- Create part
		local part = createCirclePart(midPoint, color, transparency)
		
		-- Calculate length and rotation
		local length = math.sqrt((x2 - x1)^2 + (z2 - z1)^2)
		part.Size = Vector3.new(length, CIRCLE_THICKNESS, 1)
		
		-- Rotate to connect points
		local lookVector = Vector3.new(x2 - x1, 0, z2 - z1).Unit
		part.CFrame = CFrame.new(midPoint, midPoint + lookVector)
		
		table.insert(parts, part)
	end
	
	return parts
end

local function clearCircle(parts: {Part})
	for _, part in ipairs(parts) do
		part:Destroy()
	end
	table.clear(parts)
end

local function updateCircle(parts: {Part}, radius: number, center: Vector3)
	if #parts == 0 then return end
	
	-- Check if parts still exist (might have been destroyed)
	local allValid = true
	for _, part in ipairs(parts) do
		if not part.Parent then
			allValid = false
			break
		end
	end
	
	-- If parts were destroyed, clear the array so they can be recreated
	if not allValid then
		table.clear(parts)
		return
	end
	
	local segmentAngle = (2 * math.pi) / CIRCLE_SEGMENTS
	
	for i, part in ipairs(parts) do
		local angle1 = (i - 1) * segmentAngle
		local angle2 = i * segmentAngle
		
		-- Calculate positions
		local x1 = center.X + math.cos(angle1) * radius
		local z1 = center.Z + math.sin(angle1) * radius
		local x2 = center.X + math.cos(angle2) * radius
		local z2 = center.Z + math.sin(angle2) * radius
		
		-- Mid point
		local midX = (x1 + x2) / 2
		local midZ = (z1 + z2) / 2
		local midPoint = Vector3.new(midX, CIRCLE_HEIGHT, midZ)
		
		-- Calculate length and rotation
		local length = math.sqrt((x2 - x1)^2 + (z2 - z1)^2)
		
		-- Update part
		local lookVector = Vector3.new(x2 - x1, 0, z2 - z1).Unit
		part.Size = Vector3.new(length, CIRCLE_THICKNESS, 1)
		part.CFrame = CFrame.new(midPoint, midPoint + lookVector)
	end
end

-- ================================================================
-- STORM STATE UPDATES
-- ================================================================

local function onStormUpdate(data: {[string]: any})
	stormState.currentRadius = data.currentRadius
	stormState.targetRadius = data.targetRadius
	stormState.center = data.center
	stormState.damagePercent = data.damagePercent
	stormState.phase = data.phase
	stormState.isActive = data.isActive
	
	-- Update current circle (green safe zone)
	if #currentCircleParts == 0 then
		currentCircleParts = createCircle(stormState.currentRadius, stormState.center, CURRENT_CIRCLE_COLOR, 0.3)
	else
		updateCircle(currentCircleParts, stormState.currentRadius, stormState.center)
	end
	
	-- Update next circle (white preview)
	if stormState.currentRadius ~= stormState.targetRadius then
		if #nextCircleParts == 0 then
			nextCircleParts = createCircle(stormState.targetRadius, stormState.center, NEXT_CIRCLE_COLOR, 0.6)
		else
			updateCircle(nextCircleParts, stormState.targetRadius, stormState.center)
		end
	else
		-- Hide next circle when we've reached target
		if #nextCircleParts > 0 then
			clearCircle(nextCircleParts)
		end
	end
end

local function clearStormVisuals()
	clearCircle(currentCircleParts)
	clearCircle(nextCircleParts)
	clearCircle(stormWallParts)
	stormState.isActive = false
end

-- ================================================================
-- INITIALIZATION
-- ================================================================

-- Listen for storm updates from server
Remotes.StormUpdateSC.OnClientEvent:Connect(onStormUpdate)

print("[StormClient] ✅ Ready and listening for storm updates")

return {
	ClearVisuals = clearStormVisuals
}
