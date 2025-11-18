--[[
    Name: ManaCrystalServer.luau
    Author: Magica Development Team
    Date: 2025-11-18
    Location: ServerScriptService/ManaCrystalServer
    Affects: PlayerDataModule.luau (calls AddXP), LevelUpServer.luau (triggers level-ups)
    
    Description: This server script spawns Mana Crystal pickups around the arena.
    When a player touches one, it gives them 5 XP and destroys itself.
    Mana Crystals are the main way players level up by exploring the map.
]]--

-- Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")

-- Modules
local SharedFolder = ReplicatedStorage:WaitForChild("Shared")
local ModulesFolder = SharedFolder:WaitForChild("Modules")
local DataFolder = SharedFolder:WaitForChild("Data")

local PlayerDataModule = require(ModulesFolder:WaitForChild("PlayerDataModule"))

-- Server Modules
local ServerFolder = script.Parent
local LevelUpServer = require(ServerFolder:WaitForChild("LevelUpServer"))

local ManaCrystalServer = {}

-- ========================================
-- CONFIGURATION
-- ========================================
local MANA_CRYSTAL_XP = 5 -- How much XP each crystal gives
local CRYSTALS_PER_SPAWN = 50 -- How many crystals to spawn
local SPAWN_RADIUS = 500 -- Spawn within this radius of center
local CRYSTAL_SIZE = Vector3.new(1.5, 1.5, 1.5) -- Crystal size
local CRYSTAL_COLOR = Color3.fromRGB(100, 200, 255) -- Blue/purple glow
local DEBOUNCE_TIME = 0.5 -- Prevent multiple pickups

-- ========================================
-- HELPER FUNCTIONS
-- ========================================

--- Creates a single Mana Crystal at a position
--- @param position Vector3 Where to spawn the crystal
--- @return Part The created crystal
local function createManaCrystal(position)
	print("[ManaCrystal] 💎 Creating Mana Crystal at " .. tostring(position))
	
	-- Create the crystal part
	local crystal = Instance.new("Part")
	crystal.Name = "ManaCrystal"
	crystal.Size = CRYSTAL_SIZE
	crystal.Position = position
	crystal.Shape = Enum.PartType.Ball
	crystal.Material = Enum.Material.Neon
	crystal.Color = CRYSTAL_COLOR
	crystal.CanCollide = false
	crystal.Anchored = true
	
	-- Add a light for visibility
	local light = Instance.new("PointLight")
	light.Brightness = 2
	light.Range = 20
	light.Color = CRYSTAL_COLOR
	light.Parent = crystal
	
	-- Add a hovering animation (simple up/down bobbing)
	-- PLACEHOLDER: Could be enhanced with TweenService for smooth animation
	local originalY = position.Y
	task.spawn(function()
		local time = 0
		while crystal.Parent do
			time = time + 0.05
			-- Bob up and down 0.5 studs
			crystal.Position = Vector3.new(position.X, originalY + math.sin(time * 2) * 0.5, position.Z)
			task.wait(0.05)
		end
	end)
	
	-- Add a debounce attribute to prevent double-pickup
	crystal:SetAttribute("PickupDebounce", false)
	
	return crystal
end

--- Handles when a player touches a Mana Crystal
--- @param crystal Part The crystal that was touched
--- @param player Player The player who touched it
local function onCrystalTouched(crystal, player)
	print("[ManaCrystal] 👆 ========================================")
	print("[ManaCrystal] 👆 Crystal touched by " .. player.DisplayName)
	
	-- Check debounce
	if crystal:GetAttribute("PickupDebounce") then
		print("[ManaCrystal] ⏱️ Debounce active - ignoring touch")
		print("[ManaCrystal] ========================================")
		return
	end
	
	-- Set debounce
	crystal:SetAttribute("PickupDebounce", true)
	
	print("[ManaCrystal] ✅ Pickup valid - giving " .. MANA_CRYSTAL_XP .. " XP to " .. player.DisplayName)
	
	-- Give XP to the player
	local leveledUp = PlayerDataModule:AddXP(player, MANA_CRYSTAL_XP)
	
	print("[ManaCrystal] 📊 AddXP returned: " .. tostring(leveledUp))
	
	if leveledUp then
		print("[ManaCrystal] ⭐ Player leveled up from this crystal!")
		-- Trigger level-up UI via LevelUpServer
		LevelUpServer.HandlePlayerLevelUp(player)
	else
		print("[ManaCrystal] ℹ️ No level up yet")
	end
	
	-- Play pickup effect (PLACEHOLDER - add sound/VFX here)
	-- TODO: Play "tink" sound
	-- TODO: Play particle effect
	
	-- Destroy the crystal
	print("[ManaCrystal] 💨 Destroying crystal")
	crystal:Destroy()
	print("[ManaCrystal] ========================================")
end

--- Sets up touch detection for a crystal
--- @param crystal Part The crystal part
local function setupCrystalTouchDetection(crystal)
	crystal.Touched:Connect(function(otherPart)
		-- Check if the thing that touched it is a player's character
		local character = otherPart.Parent
		if not character then return end
		
		local humanoid = character:FindFirstChild("Humanoid")
		if not humanoid or humanoid.Health <= 0 then return end
		
		-- Get the player from the character
		local player = Players:GetPlayerFromCharacter(character)
		if not player then return end
		
		-- Get player data to verify they're in a match
		local data = PlayerDataModule:GetPlayerData(player)
		if not data or not data.isInMatch then
			print("[ManaCrystal] ⚠️ Player " .. player.DisplayName .. " not in match - ignoring pickup")
			return
		end
		
		-- Handle pickup
		onCrystalTouched(crystal, player)
	end)
end

-- ========================================
-- PUBLIC FUNCTIONS
-- ========================================

--- Spawns Mana Crystals randomly around the arena
--- @param centerPosition Vector3 The center point to spawn around (usually arena center)
--- @param count number How many crystals to spawn (optional, defaults to CRYSTALS_PER_SPAWN)
function ManaCrystalServer:SpawnCrystals(centerPosition, count)
	count = count or CRYSTALS_PER_SPAWN
	
	print("[ManaCrystal] 🌟 ========================================")
	print("[ManaCrystal] 🌟 SPAWNING MANA CRYSTALS")
	print("[ManaCrystal] 🌟 Center: " .. tostring(centerPosition))
	print("[ManaCrystal] 🌟 Count: " .. count)
	print("[ManaCrystal] 🌟 Radius: " .. SPAWN_RADIUS)
	print("[ManaCrystal] 🌟 ========================================")
	
	-- Create a folder to hold all crystals (makes cleanup easy)
	local crystalFolder = Workspace:FindFirstChild("ManaCrystals")
	if not crystalFolder then
		crystalFolder = Instance.new("Folder")
		crystalFolder.Name = "ManaCrystals"
		crystalFolder.Parent = Workspace
	end
	
	-- Spawn crystals
	local successfulSpawns = 0
	local attempts = 0
	local maxAttempts = count * 3 -- Try up to 3x the desired count to handle failed raycasts
	
	while successfulSpawns < count and attempts < maxAttempts do
		attempts = attempts + 1
		
		-- Random position within radius
		local angle = math.random() * math.pi * 2 -- Random angle
		local distance = math.random(50, SPAWN_RADIUS) -- Random distance (not too close to center)
		
		local x = centerPosition.X + math.cos(angle) * distance
		local z = centerPosition.Z + math.sin(angle) * distance
		
		-- Raycast down to find ground level (cast from high up, go down far)
		local rayOrigin = Vector3.new(x, centerPosition.Y + 500, z)
		local rayDirection = Vector3.new(0, -1000, 0) -- Go down 1000 studs
		
		local raycastParams = RaycastParams.new()
		raycastParams.FilterType = Enum.RaycastFilterType.Exclude
		raycastParams.FilterDescendantsInstances = {crystalFolder} -- Don't hit other crystals
		
		local rayResult = Workspace:Raycast(rayOrigin, rayDirection, raycastParams)
		
		if rayResult then
			-- Spawn crystal 2 studs above ground
			local spawnPosition = rayResult.Position + Vector3.new(0, 2, 0)
			local crystal = createManaCrystal(spawnPosition)
			crystal.Parent = crystalFolder
			
			-- Setup touch detection
			setupCrystalTouchDetection(crystal)
			
			successfulSpawns = successfulSpawns + 1
			print("[ManaCrystal] ✅ Crystal " .. successfulSpawns .. "/" .. count .. " spawned at " .. tostring(spawnPosition))
		else
			print("[ManaCrystal] ⚠️ Raycast miss at (" .. math.floor(x) .. ", " .. math.floor(z) .. ") - retrying...")
		end
	end
	
	if successfulSpawns < count then
		warn("[ManaCrystal] ⚠️ Only spawned " .. successfulSpawns .. " out of " .. count .. " crystals after " .. attempts .. " attempts")
	else
		print("[ManaCrystal] ✅ All " .. successfulSpawns .. " crystals spawned successfully!")
	end
	
	print("[ManaCrystal] ✅ Finished spawning " .. count .. " Mana Crystals")
end

--- Clears all existing Mana Crystals from the map
function ManaCrystalServer:ClearCrystals()
	print("[ManaCrystal] 🧹 Clearing all Mana Crystals")
	
	local crystalFolder = Workspace:FindFirstChild("ManaCrystals")
	if crystalFolder then
		local count = #crystalFolder:GetChildren()
		crystalFolder:ClearAllChildren()
		print("[ManaCrystal] ✅ Cleared " .. count .. " crystals")
	else
		print("[ManaCrystal] ℹ️ No ManaCrystals folder found - nothing to clear")
	end
end

--- Spawns a single crystal at a specific position (useful for testing or chest drops)
--- @param position Vector3 Where to spawn the crystal
--- @return Part The created crystal
function ManaCrystalServer:SpawnSingleCrystal(position)
	print("[ManaCrystal] 💎 Spawning single crystal at " .. tostring(position))
	
	local crystalFolder = Workspace:FindFirstChild("ManaCrystals")
	if not crystalFolder then
		crystalFolder = Instance.new("Folder")
		crystalFolder.Name = "ManaCrystals"
		crystalFolder.Parent = Workspace
	end
	
	local crystal = createManaCrystal(position)
	crystal.Parent = crystalFolder
	setupCrystalTouchDetection(crystal)
	
	return crystal
end

print("[ManaCrystal] ✅ ManaCrystalServer module loaded")

return ManaCrystalServer
