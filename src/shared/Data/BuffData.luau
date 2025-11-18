--[[
    Name: BuffData.luau
    Author: Magica Development Team
    Date: 2025-11-18
    Location: ReplicatedStorage/Data/BuffData
    Affects: PlayerDataModule.luau, SpellModule.luau, all buff calculations
    
    Description: This module contains all the passive buff data. These are the
    bonuses players can choose at odd levels (3, 5, 7, 8, 9). Each buff makes
    the player stronger in a different way.
]]--

local BuffData = {}

-- ========================================
-- PASSIVE BUFFS (ODD LEVELS 3, 5, 7, 8, 9)
-- ========================================

BuffData.RapidCast = {
	name = "Rapid Cast",
	description = "Your spells cooldown faster",
	statType = "CooldownReduction",
	value = 0.05, -- Reduces cooldown by 5%
	stackable = true, -- You can get this buff multiple times
	maxStacks = 10, -- Can stack up to 10 times (50% total reduction)
	iconName = "RapidCastIcon" -- PLACEHOLDER: Need to create this icon
}

BuffData.SpellForce = {
	name = "Spell Force",
	description = "Your spells deal more damage",
	statType = "DamageBonus",
	value = 0.10, -- Increases damage by 10%
	stackable = true,
	maxStacks = 8,
	iconName = "SpellForceIcon" -- PLACEHOLDER
}

BuffData.Velocity = {
	name = "Velocity",
	description = "Your projectiles move faster",
	statType = "ProjectileSpeed",
	value = 0.10, -- Increases projectile speed by 10%
	stackable = true,
	maxStacks = 6,
	iconName = "VelocityIcon" -- PLACEHOLDER
}

BuffData.Magnitude = {
	name = "Magnitude",
	description = "Your area of effect spells are larger",
	statType = "AoERadius",
	value = 0.15, -- Increases AoE radius by 15%
	stackable = true,
	maxStacks = 5,
	iconName = "MagnitudeIcon" -- PLACEHOLDER
}

BuffData.CriticalMagic = {
	name = "Critical Magic",
	description = "Chance to deal double damage",
	statType = "CritChance",
	value = 0.05, -- 5% crit chance
	stackable = true,
	maxStacks = 8, -- Max 40% crit chance
	iconName = "CriticalMagicIcon" -- PLACEHOLDER
}

BuffData.Fortitude = {
	name = "Fortitude",
	description = "Increases your maximum health",
	statType = "MaxHealth",
	value = 0.10, -- Increases max HP by 10%
	stackable = true,
	maxStacks = 8,
	iconName = "FortitudeIcon" -- PLACEHOLDER
}

BuffData.FleetFoot = {
	name = "Fleet Foot",
	description = "Move faster across the arena",
	statType = "MovementSpeed",
	value = 0.05, -- Increases movement speed by 5%
	stackable = true,
	maxStacks = 6,
	iconName = "FleetFootIcon" -- PLACEHOLDER
}

BuffData.Regeneration = {
	name = "Regeneration",
	description = "Slowly heal over time",
	statType = "HealthRegen",
	value = 5, -- Heals 5 HP per second
	stackable = true,
	maxStacks = 5,
	iconName = "RegenerationIcon" -- PLACEHOLDER
}

BuffData.Bulwark = {
	name = "Bulwark",
	description = "Take less damage from all sources",
	statType = "DamageReduction",
	value = 0.05, -- Reduces damage taken by 5%
	stackable = true,
	maxStacks = 6,
	iconName = "BulwarkIcon" -- PLACEHOLDER
}

BuffData.ManaMagnet = {
	name = "Mana Magnet",
	description = "Collect pickups from farther away",
	statType = "PickupRange",
	value = 5, -- Increases pickup range by 5 studs
	stackable = true,
	maxStacks = 4,
	iconName = "ManaMagnetIcon" -- PLACEHOLDER
}

BuffData.Insight = {
	name = "Insight",
	description = "Gain more XP from all sources",
	statType = "XPBonus",
	value = 0.10, -- Increases XP gained by 10%
	stackable = true,
	maxStacks = 5,
	iconName = "InsightIcon" -- PLACEHOLDER
}

-- ========================================
-- LEVEL 10 ULTIMATE BUFFS
-- ========================================
-- These are super powerful buffs only available at max level

BuffData.MasterOfDestruction = {
	name = "Master of Destruction",
	description = "ALL damage increased by 25%",
	statType = "DamageBonus",
	value = 0.25,
	stackable = false, -- Can only get once
	maxStacks = 1,
	iconName = "MasterOfDestructionIcon", -- PLACEHOLDER
	tier = "Ultimate"
}

BuffData.SoulSiphon = {
	name = "Soul Siphon",
	description = "Heal 5% of max HP on kill",
	statType = "HealOnKill",
	value = 0.05,
	stackable = false,
	maxStacks = 1,
	iconName = "SoulSiphonIcon", -- PLACEHOLDER
	tier = "Ultimate"
}

BuffData.ChaosMaster = {
	name = "Chaos Master",
	description = "Reset all ability cooldowns on kill",
	statType = "ResetCooldownsOnKill",
	value = 1, -- Boolean: does it work or not
	stackable = false,
	maxStacks = 1,
	iconName = "ChaosMasterIcon", -- PLACEHOLDER
	tier = "Ultimate"
}

-- ========================================
-- HELPER FUNCTIONS
-- ========================================

--- Gets a list of random buffs for the player to choose from
--- @param playerLevel number The player's current level
--- @param existingBuffs table The buffs the player already has
--- @return table A list of 3 random buff options
function BuffData:GetRandomBuffChoices(playerLevel, existingBuffs)
	local availableBuffs = {}
	local choices = {}
	
	-- Level 10: Only show ultimate buffs
	if playerLevel == 10 then
		table.insert(availableBuffs, self.MasterOfDestruction)
		table.insert(availableBuffs, self.SoulSiphon)
		table.insert(availableBuffs, self.ChaosMaster)
		return availableBuffs -- Return all 3 ultimate choices
	end
	
	-- For other levels: Get all regular buffs that aren't maxed out
	local regularBuffs = {
		self.RapidCast,
		self.SpellForce,
		self.Velocity,
		self.Magnitude,
		self.CriticalMagic,
		self.Fortitude,
		self.FleetFoot,
		self.Regeneration,
		self.Bulwark,
		self.ManaMagnet,
		self.Insight
	}
	
	-- Check which buffs the player can still get
	for _, buff in ipairs(regularBuffs) do
		local currentStacks = existingBuffs[buff.name] or 0
		if currentStacks < buff.maxStacks then
			table.insert(availableBuffs, buff)
		end
	end
	
	-- If somehow all buffs are maxed (very unlikely), just return 3 random ones
	if #availableBuffs == 0 then
		availableBuffs = regularBuffs
	end
	
	-- Pick 3 random buffs from available
	-- Shuffle the list
	for i = #availableBuffs, 2, -1 do
		local j = math.random(i)
		availableBuffs[i], availableBuffs[j] = availableBuffs[j], availableBuffs[i]
	end
	
	-- Take the first 3
	for i = 1, math.min(3, #availableBuffs) do
		table.insert(choices, availableBuffs[i])
	end
	
	return choices
end

--- Calculates the total value of a buff stat for a player
--- @param buffList table The player's current buffs (e.g., {RapidCast = 2, SpellForce = 1})
--- @param statType string The stat to calculate (e.g., "DamageBonus")
--- @return number The total bonus for that stat
function BuffData:CalculateStatBonus(buffList, statType)
	local total = 0
	
	-- Loop through all possible buffs
	for buffName, stacks in pairs(buffList) do
		-- Find the buff data
		local buffData = self[buffName]
		if buffData and buffData.statType == statType then
			total = total + (buffData.value * stacks)
		end
	end
	
	return total
end

return BuffData
