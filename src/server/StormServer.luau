--!strict
-- ================================================================
-- STORM SERVER
-- ================================================================
-- Manages the Battle Royale storm using ReplicatedStorage values
-- Client listens to these values changing and renders the storm
-- Based on the example game's approach
-- ================================================================

print("[DEBUG] StormServer initializing...")

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

-- Modules
local PlayerDataModule = require(ReplicatedStorage.Shared.Modules.PlayerDataModule)

-- Create Storm folder in ReplicatedStorage
local stormFolder = ReplicatedStorage:FindFirstChild("Storm")
if not stormFolder then
	stormFolder = Instance.new("Folder")
	stormFolder.Name = "Storm"
	stormFolder.Parent = ReplicatedStorage
	print("[Storm] 📁 Created Storm folder in ReplicatedStorage")
end

-- Create storm values (client will listen to these changing)
local function getOrCreateValue(name: string, valueType: string, defaultValue: any)
	local value = stormFolder:FindFirstChild(name)
	if not value then
		value = Instance.new(valueType)
		value.Name = name
		value.Value = defaultValue
		value.Parent = stormFolder
	end
	return value
end

local CENTER = getOrCreateValue("Center", "Vector3Value", Vector3.new(0, 5, 0))
local RADIUS = getOrCreateValue("Radius", "NumberValue", 100000) -- Start huge
local TARGET_CENTER = getOrCreateValue("TargetCenter", "Vector3Value", Vector3.new(0, 5, 0))
local TARGET_RADIUS = getOrCreateValue("TargetRadius", "NumberValue", 100000)

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
local activeTweens = {}

-- ================================================================
-- HELPER FUNCTIONS
-- ================================================================

local function setTarget(center: Vector3, radius: number)
	TARGET_CENTER.Value = center
	TARGET_RADIUS.Value = radius
	print("[Storm] 🎯 Set target: radius=" .. radius .. ", center=" .. tostring(center))
end

local function moveToTarget(duration: number)
	-- Cancel any existing tweens
	for _, tween in pairs(activeTweens) do
		if tween then
			tween:Cancel()
		end
	end
	activeTweens = {}
	
	-- Create new tweens
	local info = TweenInfo.new(duration, Enum.EasingStyle.Linear, Enum.EasingDirection.Out)
	local centerTween = TweenService:Create(CENTER, info, {Value = TARGET_CENTER.Value})
	local radiusTween = TweenService:Create(RADIUS, info, {Value = TARGET_RADIUS.Value})
	
	table.insert(activeTweens, centerTween)
	table.insert(activeTweens, radiusTween)
	
	centerTween:Play()
	radiusTween:Play()
	
	-- Wait for completion
	task.wait(duration)
	
	-- Cleanup
	activeTweens = {}
end

-- ================================================================
-- STORM DAMAGE LOOP
-- ================================================================

task.spawn(function()
	while true do
		task.wait(1) -- Check every second
		
		if stormActive then
			local phase = STORM_CONFIG[currentPhase]
			if phase.damagePercent > 0 then
				local center = Vector3.new(CENTER.Value.X, 0, CENTER.Value.Z)
				local radius = RADIUS.Value
				
				for _, player in pairs(Players:GetPlayers()) do
					local data = PlayerDataModule:GetPlayerData(player)
					if data and data.isInMatch then
						local character = player.Character
						if character then
							local hrp = character:FindFirstChild("HumanoidRootPart")
							if hrp then
								local playerPos = Vector3.new(hrp.Position.X, 0, hrp.Position.Z)
								local distance = (playerPos - center).Magnitude
								
								if distance > radius then
									local damageAmount = data.maxHealth * (phase.damagePercent / 100)
									print("[Storm] ⚡ " .. player.DisplayName .. " taking " .. math.floor(damageAmount) .. " damage (dist: " .. math.floor(distance) .. " > " .. radius .. ")")
									PlayerDataModule.ApplyDamage(player, damageAmount, nil, "Storm")
								end
							end
						end
					end
				end
			end
		end
	end
end)

-- ================================================================
-- STORM SEQUENCE
-- ================================================================

local function runSequence()
	if stormActive then return end
	stormActive = true
	
	print("[Storm] 🌪️ Storm sequence starting...")
	
	-- Reset to starting position
	CENTER.Value = Vector3.new(0, 5, 0)
	RADIUS.Value = STORM_CONFIG[1].radius
	TARGET_CENTER.Value = Vector3.new(0, 5, 0)
	TARGET_RADIUS.Value = STORM_CONFIG[1].radius
	
	-- Run all phases
	for i, phase in ipairs(STORM_CONFIG) do
		if not stormActive then break end
		
		currentPhase = i
		
		print("[Storm] 🌀 ========================================")
		print("[Storm] 🌀 STARTING " .. phase.name)
		print("[Storm] 🌀 Wait: " .. phase.waitTime .. "s | Shrink: " .. phase.shrinkTime .. "s")
		print("[Storm] 🌀 Target Radius: " .. phase.radius .. " studs")
		print("[Storm] 🌀 Damage: " .. phase.damagePercent .. "% HP/sec")
		print("[Storm] 🌀 ========================================")
		
		-- Set the target (client will see white circle)
		setTarget(Vector3.new(0, 5, 0), phase.radius)
		
		-- Wait period
		if phase.waitTime > 0 then
			print("[Storm] ⏱️ Waiting " .. phase.waitTime .. "s...")
			task.wait(phase.waitTime)
		end
		
		-- Shrink period
		if phase.shrinkTime > 0 then
			print("[Storm] 🌪️ Storm closing to " .. phase.radius .. " over " .. phase.shrinkTime .. "s")
			moveToTarget(phase.shrinkTime)
		end
		
		if not stormActive then break end
	end
	
	print("[Storm] ✅ Storm sequence complete")
end

local function stopSequence()
	print("[Storm] 🛑 Storm system stopping...")
	stormActive = false
	
	-- Cancel all tweens
	for _, tween in pairs(activeTweens) do
		if tween then
			tween:Cancel()
		end
	end
	activeTweens = {}
	
	-- Reset to huge safe zone
	CENTER.Value = Vector3.new(0, 5, 0)
	RADIUS.Value = 100000
	TARGET_CENTER.Value = Vector3.new(0, 5, 0)
	TARGET_RADIUS.Value = 100000
	currentPhase = 1
end

-- ================================================================
-- PUBLIC API
-- ================================================================

local StormServer = {}

function StormServer:StartStorm()
	print("[Storm] 🌪️ Storm system starting...")
	task.spawn(runSequence)
end

function StormServer:StopStorm()
	stopSequence()
end

function StormServer:GetStormRadius(): number
	return RADIUS.Value
end

function StormServer:GetStormCenter(): Vector3
	return CENTER.Value
end

print("[Storm] ✅ StormServer module loaded")

return StormServer
