--[[
    Name: GameConstants.luau
    Author: Magica Development Team
    Date: 2025-11-18
    Location: ReplicatedStorage/Data/GameConstants
    Affects: All game systems rely on these constants for balance and configuration
    
    Description: This module stores all the game's constant values for easy balancing.
    If you change a number here, it affects the entire game. This is the single source
    of truth for all game balance numbers like health, damage, XP, and timers.
]]--

local GameConstants = {}

-- ========================================
-- PLAYER BASE STATS
-- ========================================
-- These are the starting stats every player has when they spawn
GameConstants.BASE_HEALTH = 1000 -- How much HP a player starts with
GameConstants.BASE_MOVEMENT_SPEED = 16 -- How fast players walk (studs per second)
GameConstants.MAX_LEVEL = 10 -- The highest level a player can reach in a match

-- ========================================
-- XP AND LEVELING
-- ========================================
-- This table tells us how much XP is needed to reach each level
-- For example: To go from Level 1 to Level 2, you need 100 XP total
GameConstants.XP_THRESHOLDS = {
	[1] = 0,    -- Level 1 starts at 0 XP
	[2] = 100,  -- Level 2 needs 100 total XP
	[3] = 250,  -- Level 3 needs 250 total XP
	[4] = 500,  -- Level 4 needs 500 total XP
	[5] = 900,  -- Level 5 needs 900 total XP
	[6] = 1500, -- Level 6 needs 1500 total XP
	[7] = 2250, -- Level 7 needs 2250 total XP
	[8] = 3150, -- Level 8 needs 3150 total XP
	[9] = 4200, -- Level 9 needs 4200 total XP
	[10] = 5400 -- Level 10 needs 5400 total XP
}

-- How much XP you get from different sources
GameConstants.XP_FROM_MANA_CRYSTAL = 5   -- Small crystal on the ground gives 5 XP
GameConstants.XP_FROM_CHEST = 250        -- Opening a chest gives 250 XP
GameConstants.XP_FROM_ELIMINATION = 400  -- Killing a player gives 400 XP

-- ========================================
-- MATCH TIMING
-- ========================================
-- How long different parts of the game last
GameConstants.INTERMISSION_DURATION = 120 -- 2 minutes between matches (in seconds)
GameConstants.MATCH_DURATION = 345        -- 5 minutes 45 seconds for the match (in seconds)

-- ========================================
-- STORM CONFIGURATION
-- ========================================
-- The storm has 4 phases. Each phase makes the safe zone smaller and more dangerous
GameConstants.STORM_PHASES = {
	-- Phase 1: The match starts, everyone is safe for 60 seconds
	{
		waitTime = 60,      -- Wait 60 seconds before storm starts moving
		shrinkTime = 0,     -- Storm doesn't shrink yet
		damagePercent = 0.01, -- Storm damage (1% of max HP per second, basically safe)
		safeZoneRadius = 600 -- Safe zone is 600 studs radius (big circle)
	},
	-- Phase 2: Storm starts closing in, forcing players to move
	{
		waitTime = 30,       -- Wait 30 seconds before this phase starts shrinking
		shrinkTime = 90,     -- Takes 90 seconds to shrink to new size
		damagePercent = 0.025, -- 2.5% max HP per second (25 damage/sec)
		safeZoneRadius = 300 -- Safe zone shrinks to 300 studs radius
	},
	-- Phase 3: Storm gets more dangerous, forces combat
	{
		waitTime = 15,      -- Wait 15 seconds
		shrinkTime = 75,    -- Shrinks over 75 seconds
		damagePercent = 0.05, -- 5% max HP per second (50 damage/sec)
		safeZoneRadius = 100 -- Safe zone is now 100 studs radius (small)
	},
	-- Phase 4: Final phase, forces the last 1v1
	{
		waitTime = 15,       -- Wait 15 seconds
		shrinkTime = 75,     -- Shrinks over 75 seconds
		damagePercent = 0.075, -- 7.5% max HP per second (75 damage/sec - very lethal)
		safeZoneRadius = 25  -- Safe zone is tiny (25 studs radius)
	}
}

-- ========================================
-- PLAYER SPAWNING
-- ========================================
-- Rules for where players spawn in the arena
GameConstants.MIN_SPAWN_DISTANCE = 150 -- Players must spawn at least 150 studs apart
GameConstants.SPAWN_ZONE_RADIUS = 600 -- Players spawn inside the Phase 1 safe zone

-- ========================================
-- LOOT AND PICKUPS
-- ========================================
-- What you get from chests and pickups
GameConstants.CHEST_XP_REWARD = 250           -- Opening a chest gives 250 XP
GameConstants.CHEST_HEALTH_ORBS = 1           -- Chests always give 1 Health Orb
GameConstants.CHEST_GEM_CHANCE = 0.25         -- 25% chance to get Gems from a chest
GameConstants.CHEST_GEM_MIN = 1               -- Minimum Gems from chest (if you get any)
GameConstants.CHEST_GEM_MAX = 3               -- Maximum Gems from chest

GameConstants.HEALTH_ORB_HEAL_AMOUNT = 150    -- Health Orbs heal 150 HP

GameConstants.ELIMINATION_HEALTH_ORBS = 2     -- Dead players drop 2 Health Orbs
GameConstants.ELIMINATION_XP_REWARD = 400     -- Killing a player gives 400 XP

-- ========================================
-- ECONOMY (COINS AND GEMS)
-- ========================================
-- How many Coins you earn based on your placement in the match
GameConstants.PLACEMENT_REWARDS = {
	[1] = 100,  -- 1st place gets 100 Coins
	[2] = 75,   -- 2nd place gets 75 Coins
	[3] = 75,   -- 3rd place gets 75 Coins
	-- Positions 4-10 all get 50 Coins
	[4] = 50, [5] = 50, [6] = 50, [7] = 50, [8] = 50, [9] = 50, [10] = 50,
	-- Positions 11-20 all get 25 Coins
	[11] = 25, [12] = 25, [13] = 25, [14] = 25, [15] = 25,
	[16] = 25, [17] = 25, [18] = 25, [19] = 25, [20] = 25
}

GameConstants.COINS_PER_ELIMINATION = 10 -- You get 10 Coins for each player you eliminate

-- Shop prices
GameConstants.HERO_PRICE_COINS = 3000 -- Heroes cost 3000 Coins
GameConstants.HERO_PRICE_GEMS = 250   -- OR 250 Gems (shortcut)
GameConstants.BATTLE_PASS_GEMS = 400  -- Battle Pass costs 400 Gems
GameConstants.COSMETIC_CHEST_GEMS = 50 -- Cosmetic Chest costs 50 Gems

-- ========================================
-- MATCH CONFIGURATION
-- ========================================
GameConstants.MIN_PLAYERS_TO_START = 1  -- Match can start with just 1 player (for testing)
GameConstants.MAX_PLAYERS_PER_MATCH = 20 -- Maximum 20 players per match

-- ========================================
-- ARENA SIZE
-- ========================================
GameConstants.ARENA_SIZE = 1500 -- Arena is 1500 x 1500 studs

return GameConstants
