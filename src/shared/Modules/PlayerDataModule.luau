--[[
    Name: PlayerDataModule.luau
    Author: Magica Development Team
    Date: 2025-11-18
    Location: ReplicatedStorage/Modules/PlayerDataModule
    Affects: ALL game systems - this is the central player data storage
    
    Description: This module stores and manages ALL data for EVERY player.
    Every script that needs to know about a player (health, level, spells, etc.)
    will ask this module. This is the "brain" that remembers everything about players.
]]--

-- Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Modules (Data is in the Shared folder)
local SharedFolder = ReplicatedStorage:WaitForChild("Shared")
local SharedData = SharedFolder:WaitForChild("Data")

-- Safe require helper: verifies the ModuleScript exists and pcall-wraps require to avoid compile/runtime require errors
local function safeRequire(parent, name)
	local child = parent:FindFirstChild(name)
	if not child then
		warn("[PlayerData] ⚠️ Module '" .. name .. "' not found under " .. tostring(parent) .. "; returning empty table as fallback")
		return {}
	end

	local ok, result = pcall(require, child)
	if not ok then
		warn("[PlayerData] ⚠️ Failed to require '" .. name .. "': " .. tostring(result) .. " — returning empty table as fallback")
		return {}
	end

	return result
end

local GameConstants = safeRequire(SharedData, "GameConstants")
local SpellData = safeRequire(SharedData, "SpellData")
local BuffData = safeRequire(SharedData, "BuffData")

local PlayerDataModule = {}

-- This table stores data for every player currently in the game
-- Key = Player UserId, Value = Player's data table
local playerDataStore = {}

-- ========================================
-- DEFAULT PLAYER DATA STRUCTURE
-- ========================================
--- This function creates a fresh data table for a new player
--- @param player Player The Roblox player object
--- @return table The player's new data table
local function createDefaultPlayerData(player)
	return {
		-- Basic Info
		userId = player.UserId,
		displayName = player.DisplayName,
		
		-- Match Stats (resets every match)
		health = GameConstants.BASE_HEALTH, -- Current HP
		maxHealth = GameConstants.BASE_HEALTH, -- Maximum HP
		level = 1, -- Current level (1-10)
		xp = 0, -- Current XP
		
		-- Combat Stats
		spellCore = {}, -- List of chosen elements (e.g., {"Fire", "Water"})
		currentSpell = SpellData.MagicMissile, -- The spell they currently have
		buffs = {}, -- Table of buffs (e.g., {RapidCast = 2, Fortitude = 1})
		
		-- In-Match Economy
		gemsHeld = 0, -- Gems picked up this match (lost on death)
		eliminations = 0, -- How many players they've killed this match
		
		-- Persistent Economy (saved across matches)
		coins = 0, -- Soft currency (earned from matches)
		gemsBanked = 0, -- Hard currency (bought with Robux or earned)
		
		-- Hero & Cosmetics
		selectedHero = "Novice", -- Which hero they're playing as
		unlockedHeroes = {"Novice"}, -- List of heroes they own
		equippedSkin = nil, -- Which skin they have equipped
		equippedWand = nil, -- Which wand they have equipped
		equippedDeathEffect = nil, -- Which death effect they have equipped
		unlockedCosmetics = {}, -- List of all cosmetics they own
		
		-- Game State
		isInMatch = false, -- Are they currently in the arena?
		isInQueue = false, -- Are they queued for the next match?
		placement = nil, -- Their placement when they died (e.g., 7 out of 18)
		
		-- Cooldowns
		spellCooldownReady = true, -- Can they cast their spell right now?
		spellLastCastTime = 0, -- When did they last cast (for cooldown calculation)
		abilityCooldownReady = true, -- Can they use their Q ability?
		abilityLastCastTime = 0,
		
		-- Movement
		movementSpeed = GameConstants.BASE_MOVEMENT_SPEED,
		isSlowed = false,
		isStunned = false,
		
		-- Effects
		activeEffects = {}, -- List of active effects (burns, slows, etc.)
	}
end

-- ========================================
-- PUBLIC FUNCTIONS
-- ========================================

--- Creates a new player data entry when a player joins the game
--- @param player Player The Roblox player object
function PlayerDataModule:CreatePlayerData(player)
	print("[PlayerData] 🔧 CreatePlayerData called for " .. player.DisplayName .. " (UserId: " .. player.UserId .. ")")
	
	-- Check if player data already exists (shouldn't happen, but just in case)
	if playerDataStore[player.UserId] then
		warn("[PlayerData] ⚠️ Player data already exists for " .. player.DisplayName .. " - returning existing data")
		print("[PlayerData] 📊 Existing data:", playerDataStore[player.UserId])
		return
	end
	
	-- Create new data
	playerDataStore[player.UserId] = createDefaultPlayerData(player)
	local data = playerDataStore[player.UserId]
	print("[PlayerData] ✅ Created player data for " .. player.DisplayName)
	print("[PlayerData] 📊 Initial data structure:")
	print("  - Health: " .. data.health .. " / " .. data.maxHealth)
	print("  - Level: " .. data.level .. " | XP: " .. data.xp)
	print("  - SpellCore: " .. (#data.spellCore > 0 and table.concat(data.spellCore, ", ") or "(empty)"))
	print("  - CurrentSpell: " .. data.currentSpell)
	print("  - Movement Speed: " .. data.movementSpeed)
end

--- Removes a player's data when they leave the game
--- @param player Player The Roblox player object
function PlayerDataModule:RemovePlayerData(player)
	print("[PlayerData] 🗑️ RemovePlayerData called for " .. player.DisplayName .. " (UserId: " .. player.UserId .. ")")
	if not playerDataStore[player.UserId] then
		warn("[PlayerData] ⚠️ Tried to remove data for player that doesn't exist: " .. player.DisplayName)
		return
	end
	
	playerDataStore[player.UserId] = nil
	print("[PlayerData] ✅ Removed player data for " .. player.DisplayName)
end

--- Gets a player's data table
--- @param player Player The Roblox player object
--- @return table|nil The player's data, or nil if not found
function PlayerDataModule:GetPlayerData(player)
	local data = playerDataStore[player.UserId]
	
	if not data then
		warn("[PlayerData] ⚠️ No data found for player: " .. player.DisplayName .. " (UserId: " .. player.UserId .. ")")
	end
	
	return data
end

--- Adds XP to a player and checks if they level up
--- @param player Player The Roblox player object
--- @param xpAmount number How much XP to add
--- @return boolean Whether the player leveled up
function PlayerDataModule:AddXP(player, xpAmount)
	print("[PlayerData] 📈 AddXP called - Player: " .. player.DisplayName .. " | Amount: " .. xpAmount)
	local data = self:GetPlayerData(player)
	if not data then 
		warn("[PlayerData] ❌ No player data found for " .. player.DisplayName)
		return false 
	end
	
	-- Apply XP bonus buff if they have it
	local xpBonus = BuffData:CalculateStatBonus(data.buffs, "XPBonus")
	local finalXP = xpAmount * (1 + xpBonus)
	
	local oldXP = data.xp
	-- Add XP
	data.xp = data.xp + finalXP
	print("[PlayerData] XP changed: " .. oldXP .. " → " .. data.xp .. " (+" .. math.floor(finalXP) .. " with " .. (xpBonus * 100) .. "% bonus)")
	
	-- Check if player leveled up
	local nextLevel = data.level + 1
	if nextLevel <= GameConstants.MAX_LEVEL then
		local xpNeeded = GameConstants.XP_THRESHOLDS[nextLevel]
		print("[PlayerData] 🔍 Checking level up - Current Level: " .. data.level .. " | Current XP: " .. data.xp .. " | Required for Level " .. nextLevel .. ": " .. xpNeeded)
		if data.xp >= xpNeeded then
			local oldLevel = data.level
			data.level = nextLevel
			print("[PlayerData] ⭐ LEVEL UP! " .. player.DisplayName .. " → Level " .. data.level .. " (was " .. oldLevel .. ")")
			return true -- LEVEL UP!
		else
			print("[PlayerData] ❌ Not enough XP for level up. Need " .. (xpNeeded - data.xp) .. " more XP")
		end
	else
		print("[PlayerData] ℹ️ Player is already at MAX_LEVEL (" .. GameConstants.MAX_LEVEL .. ")")
	end
	
	return false -- No level up
end

--- Updates a player's spell based on their current spell core
--- @param player Player The Roblox player object
function PlayerDataModule:UpdateSpell(player)
	local data = self:GetPlayerData(player)
	if not data then return end
	
	-- Get the correct spell for their element combination
	data.currentSpell = SpellData:GetSpellByElements(data.spellCore)
	print("🔮 " .. player.DisplayName .. "'s spell updated to: " .. data.currentSpell.name)
end

--- Adds an element to a player's spell core and updates their spell
--- @param player Player The Roblox player object
--- @param element string The element to add ("Fire", "Water", or "Earth")
function PlayerDataModule:AddElement(player, element)
	print("[PlayerData] 🔮 AddElement called - Player: " .. player.DisplayName .. " | Element: " .. element)
	local data = self:GetPlayerData(player)
	if not data then 
		warn("[PlayerData] ❌ No player data found for " .. player.DisplayName)
		return 
	end
	
	local oldSpellCore = {}
	for _, e in ipairs(data.spellCore) do
		table.insert(oldSpellCore, e)
	end
	
	-- Add the element to their core
	table.insert(data.spellCore, element)
	print("[PlayerData] SpellCore updated: [" .. table.concat(oldSpellCore, ", ") .. "] → [" .. table.concat(data.spellCore, ", ") .. "]")
	
	-- Update their spell
	local oldSpell = data.currentSpell
	self:UpdateSpell(player)
	print("[PlayerData] ✨ Spell evolved: " .. oldSpell .. " → " .. data.currentSpell)
	print("[PlayerData] 📊 New spell stats - Damage: " .. SpellData.Spells[data.currentSpell].damage .. " | Cooldown: " .. SpellData.Spells[data.currentSpell].cooldown .. "s")
end

--- Adds a buff to a player
--- @param player Player The Roblox player object
--- @param buffName string The name of the buff (e.g., "RapidCast")
function PlayerDataModule:AddBuff(player, buffName)
	print("[PlayerData] 💪 AddBuff called - Player: " .. player.DisplayName .. " | Buff: " .. buffName)
	local data = self:GetPlayerData(player)
	if not data then 
		warn("[PlayerData] ❌ No player data found for " .. player.DisplayName)
		return 
	end
	
	-- Initialize buff stack count if it doesn't exist
	if not data.buffs[buffName] then
		data.buffs[buffName] = 0
	end
	
	local oldStack = data.buffs[buffName]
	
	-- Get the buff data
	local buffData = BuffData[buffName]
	if not buffData then
		warn("[PlayerData] ⚠️ Tried to add unknown buff: " .. buffName)
		return
	end
	
	-- Check if we can add more stacks
	if data.buffs[buffName] < buffData.maxStacks then
		data.buffs[buffName] = data.buffs[buffName] + 1
		print("[PlayerData] Buff stacked: " .. buffName .. " | Stack: " .. oldStack .. " → " .. data.buffs[buffName] .. " (Max: " .. buffData.maxStacks .. ")")
		
		-- Apply the buff immediately
		self:RecalculateStats(player)
		print("[PlayerData] ✅ Buff applied and stats recalculated")
	else
		warn("[PlayerData] ⚠️ Buff " .. buffName .. " is already at max stacks (" .. buffData.maxStacks .. ")")
	end
end

--- Recalculates all of a player's stats based on their buffs
--- @param player Player The Roblox player object
function PlayerDataModule:RecalculateStats(player)
	print("[PlayerData] 📊 RecalculateStats called for " .. player.DisplayName)
	local data = self:GetPlayerData(player)
	if not data then 
		warn("[PlayerData] ❌ No player data found for " .. player.DisplayName)
		return 
	end
	
	local oldMaxHealth = data.maxHealth
	local oldMovementSpeed = data.movementSpeed
	
	-- Reset to base stats
	local baseMaxHealth = GameConstants.BASE_HEALTH
	local baseMovementSpeed = GameConstants.BASE_MOVEMENT_SPEED
	
	-- Calculate bonuses from buffs
	local healthBonus = BuffData:CalculateStatBonus(data.buffs, "MaxHealth")
	local speedBonus = BuffData:CalculateStatBonus(data.buffs, "MovementSpeed")
	
	-- Apply bonuses
	data.maxHealth = baseMaxHealth * (1 + healthBonus)
	data.movementSpeed = baseMovementSpeed * (1 + speedBonus)
	
	print("[PlayerData] ❤️ MaxHealth recalculated: " .. oldMaxHealth .. " → " .. data.maxHealth .. " (+" .. (healthBonus * 100) .. "%)")
	print("[PlayerData] 🏃 MovementSpeed recalculated: " .. oldMovementSpeed .. " → " .. data.movementSpeed .. " (+" .. (speedBonus * 100) .. "%)")
	
	-- Make sure current health doesn't exceed new max
	if data.health > data.maxHealth then
		local oldHealth = data.health
		data.health = data.maxHealth
		print("[PlayerData] ⚕️ Current health capped: " .. oldHealth .. " → " .. data.maxHealth)
	end
	
	print("[PlayerData] ✅ Stats recalculation complete")
end

--- Applies damage to a player
--- @param player Player The player taking damage
--- @param damageAmount number How much damage to apply
--- @param damageSource Player|nil The player who dealt the damage (for kill credit)
--- @return boolean Whether the player died
function PlayerDataModule:ApplyDamage(player, damageAmount, damageSource)
	print("[PlayerData] 💥 ApplyDamage called - Target: " .. player.DisplayName .. " | Raw Damage: " .. damageAmount .. " | Source: " .. (damageSource and damageSource.DisplayName or "Environment"))
	local data = self:GetPlayerData(player)
	if not data then 
		warn("[PlayerData] ❌ No player data found for " .. player.DisplayName)
		return false 
	end
	
	-- Calculate damage reduction from buffs
	local damageReduction = BuffData:CalculateStatBonus(data.buffs, "DamageReduction")
	local finalDamage = damageAmount * (1 - damageReduction)
	print("[PlayerData] 🛡️ Damage calculation - Reduction: " .. (damageReduction * 100) .. "% | Actual Damage: " .. finalDamage)
	
	local oldHealth = data.health
	-- Apply damage
	data.health = data.health - finalDamage
	print("[PlayerData] ❤️ Health changed: " .. math.floor(oldHealth) .. " → " .. math.floor(data.health) .. " (" .. math.floor(data.health) .. " / " .. data.maxHealth .. ")")
	
	-- Check if player died
	if data.health <= 0 then
		data.health = 0
		print("[PlayerData] 💀 PLAYER DIED - " .. player.DisplayName .. " | Final Health: 0")
		
		-- Give kill credit if there was a damage source
		if damageSource then
			local killerData = self:GetPlayerData(damageSource)
			if killerData then
				local oldElims = killerData.eliminations
				killerData.eliminations = killerData.eliminations + 1
				print("[PlayerData] 🏆 Kill credited to " .. damageSource.DisplayName .. " | Eliminations: " .. oldElims .. " → " .. killerData.eliminations)
			end
		end
		
		return true -- Player died
	else
		print("[PlayerData] ✅ Player survived - Remaining: " .. math.floor(data.health) .. " / " .. data.maxHealth)
	end
	
	return false -- Player survived
end

--- Heals a player
--- @param player Player The player to heal
--- @param healAmount number How much HP to restore
function PlayerDataModule:Heal(player, healAmount)
	print("[PlayerData] ⚕️ Heal called - Player: " .. player.DisplayName .. " | Amount: " .. healAmount)
	local data = self:GetPlayerData(player)
	if not data then 
		warn("[PlayerData] ❌ No player data found for " .. player.DisplayName)
		return 
	end
	
	local oldHealth = data.health
	-- Add health
	data.health = math.min(data.health + healAmount, data.maxHealth)
	local actualHealing = data.health - oldHealth
	
	print("[PlayerData] ❤️ Health changed: " .. math.floor(oldHealth) .. " → " .. math.floor(data.health))
	print("[PlayerData] ⚕️ Healed " .. math.floor(actualHealing) .. " HP (requested " .. healAmount .. ")")
	
	if actualHealing < healAmount then
		print("[PlayerData] ℹ️ Overhealing prevented - capped at max health " .. data.maxHealth)
	end
end

--- Resets a player's match data (called when a new match starts)
--- @param player Player The Roblox player object
function PlayerDataModule:ResetMatchData(player)
	print("[PlayerData] 🔄 ResetMatchData called for " .. player.DisplayName)
	local data = self:GetPlayerData(player)
	if not data then 
		warn("[PlayerData] ❌ No player data found for " .. player.DisplayName)
		return 
	end
	
	print("[PlayerData] 📊 Before reset:")
	print("  - Health: " .. data.health .. " / " .. data.maxHealth)
	print("  - Level: " .. data.level .. " | XP: " .. data.xp)
	print("  - SpellCore: [" .. table.concat(data.spellCore, ", ") .. "]")
	print("  - Buffs: " .. (next(data.buffs) and "present" or "none"))
	print("  - Eliminations: " .. data.eliminations)
	
	-- Reset all match-specific data
	data.health = data.maxHealth
	data.level = 1
	data.xp = 0
	data.spellCore = {}
	data.currentSpell = SpellData.MagicMissile
	data.buffs = {}
	data.gemsHeld = 0
	data.eliminations = 0
	data.placement = nil
	data.spellCooldownReady = true
	data.spellLastCastTime = 0
	data.abilityCooldownReady = true
	data.abilityLastCastTime = 0
	data.activeEffects = {}
	
	-- Recalculate stats
	self:RecalculateStats(player)
	
	print("[PlayerData] ✅ Match data reset complete")
	print("[PlayerData] 📊 After reset:")
	print("  - Health: " .. data.health .. " / " .. data.maxHealth)
	print("  - Level: " .. data.level)
	print("  - Spell: " .. data.currentSpell)
end

return PlayerDataModule
