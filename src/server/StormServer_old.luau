--!strict
-- ================================================================
-- STORM SERVER
-- ================================================================
-- Manages the Battle Royale storm that closes in over the 6-minute match
-- The storm damages players outside the safe zone, forcing them together
-- 
-- Phase 1 (0:00-1:00): 600 stud radius - Safe
-- Phase 2 (1:00-2:45): 300 stud radius - 2.5% HP/s damage
-- Phase 3 (2:45-4:15): 100 stud radius - 5% HP/s damage
-- Phase 4 (4:15-5:45): 25 stud radius - 7.5% HP/s damage
-- ================================================================

print("[DEBUG] StormServer initializing...")

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

-- Modules
local PlayerDataModule = require(ReplicatedStorage.Shared.Modules.PlayerDataModule)
local GameConstants = require(ReplicatedStorage.Shared.Data.GameConstants)

-- Create Storm folder in ReplicatedStorage (like the example)
local stormFolder = ReplicatedStorage:FindFirstChild("Storm")
if not stormFolder then
	stormFolder = Instance.new("Folder")
	stormFolder.Name = "Storm"
	stormFolder.Parent = ReplicatedStorage
	print("[Storm] 📁 Created Storm folder in ReplicatedStorage")
end

-- Create storm values (client will listen to these)
local centerValue = stormFolder:FindFirstChild("Center") or Instance.new("Vector3Value")
centerValue.Name = "Center"
centerValue.Value = Vector3.new(0, 5, 0)
centerValue.Parent = stormFolder

local radiusValue = stormFolder:FindFirstChild("Radius") or Instance.new("NumberValue")
radiusValue.Name = "Radius"
radiusValue.Value = 600
radiusValue.Parent = stormFolder

local targetCenterValue = stormFolder:FindFirstChild("TargetCenter") or Instance.new("Vector3Value")
targetCenterValue.Name = "TargetCenter"
targetCenterValue.Value = Vector3.new(0, 5, 0)
targetCenterValue.Parent = stormFolder

local targetRadiusValue = stormFolder:FindFirstChild("TargetRadius") or Instance.new("NumberValue")
targetRadiusValue.Name = "TargetRadius"
targetRadiusValue.Value = 600
targetRadiusValue.Parent = stormFolder

-- ================================================================
-- STORM CONFIGURATION
-- ================================================================

local STORM_CONFIG = {
	-- Phase 1: Match start (safe period)
	{
		duration = 60, -- 1 minute
		waitTime = 60,
		shrinkTime = 0,
		radius = 600,
		damagePercent = 0, -- No damage
		name = "Phase 1 (Safe)"
	},
	-- Phase 2: Early game
	{
		duration = 105, -- 1:45
		waitTime = 30,
		shrinkTime = 75,
		radius = 300,
		damagePercent = 2.5, -- 25 HP/s at 1000 max HP
		name = "Phase 2 (Early)"
	},
	-- Phase 3: Mid game
	{
		duration = 90, -- 1:30
		waitTime = 15,
		shrinkTime = 75,
		radius = 100,
		damagePercent = 5, -- 50 HP/s
		name = "Phase 3 (Mid)"
	},
	-- Phase 4: End game
	{
		duration = 90, -- 1:30
		waitTime = 15,
		shrinkTime = 75,
		radius = 25,
		damagePercent = 7.5, -- 75 HP/s
		name = "Phase 4 (End)"
	}
}

-- ================================================================
-- STATE
-- ================================================================

local stormActive = false
local currentPhase = 1
local activeTweens = {} -- Track active tweens for cleanup

-- ================================================================
-- DAMAGE TICK
-- ================================================================

local function applyStormDamage()
	if not stormActive then return end
	
	local phase = STORM_CONFIG[currentPhase]
	if phase.damagePercent == 0 then return end
	
	-- Check all players in match
	for _, player in ipairs(Players:GetPlayers()) do
		local data = PlayerDataModule:GetPlayerData(player)
		if data and data.isInMatch then
			local character = player.Character
			if character then
				local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
				if humanoidRootPart then
					-- Calculate distance from storm center
					local position = humanoidRootPart.Position
					local distance = (Vector2.new(position.X, position.Z) - Vector2.new(stormCenter.X, stormCenter.Z)).Magnitude
					
					-- If player is outside the safe zone
					if distance > currentRadius then
						local damageAmount = data.maxHealth * (phase.damagePercent / 100)
						print("[Storm] ⚡ " .. player.DisplayName .. " taking " .. math.floor(damageAmount) .. " storm damage (outside radius: " .. math.floor(distance) .. " > " .. currentRadius .. ")")
						PlayerDataModule:ApplyDamage(player, damageAmount, nil, "Storm")
					end
				end
			end
		end
	end
end

-- Broadcast storm state to all clients
local function broadcastStormState()
	if not stormActive then return end
	
	local phase = STORM_CONFIG[currentPhase]
	Remotes.StormUpdateSC:FireAllClients({
		currentRadius = currentRadius,
		targetRadius = targetRadius,
		center = stormCenter,
		damagePercent = phase.damagePercent,
		phase = currentPhase,
		isActive = stormActive
	})
end

-- Start damage tick loop (every 1 second)
task.spawn(function()
	while true do
		task.wait(1) -- Damage every second
		applyStormDamage()
		broadcastStormState() -- Update clients
	end
end)

-- ================================================================
-- STORM PHASES
-- ================================================================

local function startPhase(phaseNumber: number)
	currentPhase = phaseNumber
	local phase = STORM_CONFIG[phaseNumber]
	
	print("[Storm] 🌀 ========================================")
	print("[Storm] 🌀 STARTING " .. phase.name)
	print("[Storm] 🌀 Wait: " .. phase.waitTime .. "s | Shrink: " .. phase.shrinkTime .. "s")
	print("[Storm] 🌀 Radius: " .. currentRadius .. " → " .. phase.radius .. " studs")
	print("[Storm] 🌀 Damage: " .. phase.damagePercent .. "% HP/sec")
	print("[Storm] 🌀 ========================================")
	
	targetRadius = phase.radius
	broadcastStormState() -- Show next circle to clients
	
	-- Wait period (show next circle)
	if phase.waitTime > 0 then
		print("[Storm] ⏱️ Waiting " .. phase.waitTime .. "s before storm closes...")
		task.wait(phase.waitTime)
	end
	
	-- Shrink period
	if phase.shrinkTime > 0 then
		print("[Storm] 🌪️ Storm closing from " .. currentRadius .. " to " .. phase.radius .. " over " .. phase.shrinkTime .. "s")
		
		local startRadius = currentRadius
		local startTime = tick()
		
		-- Gradually shrink the radius
		while tick() - startTime < phase.shrinkTime do
			local elapsed = tick() - startTime
			local progress = elapsed / phase.shrinkTime
			currentRadius = startRadius + (targetRadius - startRadius) * progress
			broadcastStormState() -- Update visual shrinking
			
			task.wait(0.1) -- Update 10 times per second
		end
		
		currentRadius = targetRadius
		print("[Storm] ✅ Storm reached radius: " .. currentRadius)
	else
		-- Instant change (Phase 1)
		currentRadius = phase.radius
		targetRadius = phase.radius
	end
end

-- ================================================================
-- PUBLIC FUNCTIONS
-- ================================================================

local StormServer = {}

--- Starts the storm system for a match
function StormServer:StartStorm()
	print("[Storm] 🌪️ Storm system starting...")
	stormActive = true
	currentPhase = 1
	currentRadius = STORM_CONFIG[1].radius
	targetRadius = STORM_CONFIG[1].radius
	
	-- Run through all 4 phases
	for i = 1, #STORM_CONFIG do
		startPhase(i)
	end
	
	print("[Storm] ☠️ Final phase complete - storm has closed completely!")
end

--- Stops the storm system (match ended)
function StormServer:StopStorm()
	print("[Storm] 🛑 Storm system stopping...")
	stormActive = false
	currentPhase = 1
	currentRadius = STORM_CONFIG[1].radius
end

--- Gets current storm state for UI/debugging
function StormServer:GetStormState()
	return {
		active = stormActive,
		phase = currentPhase,
		currentRadius = currentRadius,
		targetRadius = targetRadius,
		center = stormCenter,
		damagePercent = STORM_CONFIG[currentPhase].damagePercent
	}
end

print("[Storm] ✅ StormServer module loaded")

return StormServer
