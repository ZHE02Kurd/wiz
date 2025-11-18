--[[
    Name: SpellData.luau
    Author: Magica Development Team
    Date: 2025-11-18
    Location: ReplicatedStorage/Data/SpellData
    Affects: SpellModule.luau, CombatClient.luau, all spell casting and damage systems
    
    Description: This module contains ALL the data for every spell in the game.
    Each spell has damage, cooldown, speed, special effects, and more.
    When you change a spell here, it changes everywhere in the game.
]]--

local SpellData = {}

-- ========================================
-- LEVEL 1: STARTING SPELL
-- ========================================
-- This is the spell everyone starts with before they choose an element
SpellData.MagicMissile = {
	name = "Magic Missile",
	level = 1,
	damage = 50,
	cooldown = 2.0,
	projectileSpeed = 80,
	range = 100,
	aoeRadius = 0, -- No area of effect, just hits one target
	pierce = false, -- Doesn't go through enemies
	homing = false, -- Doesn't track enemies
	specialEffect = nil,
	description = "A basic magical projectile. Simple but effective.",
	elements = {} -- No elements yet
}

-- ========================================
-- LEVEL 2: SINGLE ELEMENT SPELLS
-- ========================================

-- FIRE ELEMENT
SpellData.FireBall = {
	name = "Fire Ball",
	level = 2,
	damage = 100,
	cooldown = 1.8,
	projectileSpeed = 70,
	range = 120,
	aoeRadius = 0,
	pierce = false,
	homing = false,
	specialEffect = {
		type = "Burn",
		damagePerSecond = 25, -- Burns for 25 damage per second
		duration = 3 -- Burns for 3 seconds total (75 damage total)
	},
	description = "A ball of fire. Deals damage on impact and sets the target on fire.",
	elements = {"Fire"}
}

-- WATER ELEMENT
SpellData.BlobOfWater = {
	name = "Blob of Water",
	level = 2,
	damage = 90,
	cooldown = 1.5,
	projectileSpeed = 75,
	range = 110,
	aoeRadius = 0,
	pierce = false,
	homing = false,
	specialEffect = {
		type = "Siphon",
		healPercent = 0.30 -- Heals 30% of damage dealt (about 27 HP)
	},
	description = "A blob of water that deals damage and heals you.",
	elements = {"Water"}
}

-- EARTH ELEMENT
SpellData.LumpOfDirt = {
	name = "Lump of Dirt",
	level = 2,
	damage = 75,
	cooldown = 2.2,
	projectileSpeed = 65,
	range = 100,
	aoeRadius = 0,
	pierce = false,
	homing = false,
	specialEffect = {
		type = "Slow",
		slowPercent = 0.25, -- Slows enemy by 25%
		duration = 2 -- Slow lasts 2 seconds
	},
	description = "A magically enhanced lump of dirt. Damages and slows enemies.",
	elements = {"Earth"}
}

-- ========================================
-- LEVEL 4: DOUBLE ELEMENT SPELLS
-- ========================================

-- FIRE + FIRE
SpellData.ExplosiveSalvo = {
	name = "Explosive Salvo",
	level = 4,
	damage = 150,
	cooldown = 2.5,
	projectileSpeed = 65,
	range = 130,
	aoeRadius = 15, -- Explodes in a 15-stud radius
	pierce = false,
	homing = false,
	specialEffect = {
		type = "Burn",
		damagePerSecond = 30,
		duration = 3,
		aoe = true -- Burns all enemies in the explosion radius
	},
	description = "A large fireball that explodes on impact, burning all nearby enemies.",
	elements = {"Fire", "Fire"}
}

-- WATER + WATER
SpellData.Spray = {
	name = "Spray",
	level = 4,
	damage = 120, -- Total damage if all droplets hit
	cooldown = 1.8,
	projectileSpeed = 70,
	range = 90,
	aoeRadius = 20, -- Cone spreads to 20 studs wide
	pierce = false,
	homing = false,
	projectileCount = 5, -- Shoots 5 droplets in a cone
	specialEffect = {
		type = "Siphon",
		healPercent = 0.30
	},
	description = "Shoots dense water droplets in a cone. Heals you for damage dealt.",
	elements = {"Water", "Water"}
}

-- EARTH + EARTH
SpellData.Boulder = {
	name = "Boulder",
	level = 4,
	damage = 175,
	cooldown = 3.0,
	projectileSpeed = 55,
	range = 110,
	aoeRadius = 0,
	pierce = false,
	homing = false,
	specialEffect = {
		type = "Stun",
		duration = 1.0 -- Stuns enemy for 1 second
	},
	description = "A massive boulder that stuns your opponent.",
	elements = {"Earth", "Earth"}
}

-- FIRE + WATER
SpellData.LightningBall = {
	name = "Lightning Ball",
	level = 4,
	damage = 120,
	cooldown = 1.7,
	projectileSpeed = 85,
	range = 140,
	aoeRadius = 0,
	pierce = true, -- Goes through enemies!
	homing = true, -- Tracks the nearest enemy
	specialEffect = nil,
	description = "An electrical orb that homes onto enemies and pierces through them.",
	elements = {"Fire", "Water"}
}

-- WATER + EARTH
SpellData.IceLance = {
	name = "Ice Lance",
	level = 4,
	damage = 140,
	cooldown = 2.0,
	projectileSpeed = 90,
	range = 150,
	aoeRadius = 0,
	pierce = true, -- Goes through all enemies
	homing = false,
	specialEffect = {
		type = "Slow",
		slowPercent = 0.35,
		duration = 3
	},
	description = "A razor-sharp icicle that pierces through enemies and slows them.",
	elements = {"Water", "Earth"}
}

-- FIRE + EARTH
SpellData.Meteor = {
	name = "Meteor",
	level = 4,
	damage = 160,
	cooldown = 2.8,
	projectileSpeed = 60,
	range = 120,
	aoeRadius = 12,
	pierce = false,
	homing = false,
	specialEffect = {
		type = "BurningOil",
		damagePerSecond = 20,
		duration = 4,
		slowPercent = 0.20,
		groundRadius = 15 -- Creates a 15-stud pool of burning oil
	},
	description = "A flaming meteorite that creates burning oil on the ground.",
	elements = {"Fire", "Earth"}
}

-- ========================================
-- LEVEL 6: TRIPLE ELEMENT SPELLS (ULTIMATE FORMS)
-- ========================================

-- FIRE + FIRE + FIRE
SpellData.Supernova = {
	name = "Supernova",
	level = 6,
	damage = 400, -- Massive damage if touched directly
	cooldown = 4.5,
	projectileSpeed = 25, -- Moves very slowly
	range = 80,
	aoeRadius = 30, -- Burns everything within 30 studs
	pierce = false,
	homing = false,
	specialEffect = {
		type = "SupernovaBurn",
		damagePerSecond = 50, -- Burns nearby enemies
		explosionRadius = 40, -- Final explosion is even bigger
		explosionDamage = 250
	},
	description = "Summons a mini sun that burns everything nearby, then explodes.",
	elements = {"Fire", "Fire", "Fire"}
}

-- WATER + WATER + WATER
SpellData.Tsunami = {
	name = "Tsunami",
	level = 6,
	damage = 350, -- Damage grows as the wave grows
	cooldown = 4.0,
	projectileSpeed = 50, -- Starts slow, gets faster
	range = 150,
	aoeRadius = 25, -- Wave is 25 studs wide and grows
	pierce = true,
	homing = false,
	specialEffect = {
		type = "Tsunami",
		knockback = 50, -- Knocks enemies back
		healPercent = 0.30,
		damageGrowth = 1.5 -- Damage multiplies as it travels
	},
	description = "A giant wave that grows in size and knocks down enemies.",
	elements = {"Water", "Water", "Water"}
}

-- EARTH + EARTH + EARTH
SpellData.StoneRam = {
	name = "Stone Ram",
	level = 6,
	damage = 300,
	cooldown = 3.8,
	projectileSpeed = 0, -- Not a projectile, YOU become the projectile
	range = 60, -- You dash 60 studs
	aoeRadius = 8, -- Damages enemies in a small radius around you
	pierce = true,
	homing = false,
	specialEffect = {
		type = "StoneRam",
		dashSpeed = 120, -- You fly forward very fast
		damageReduction = 0.50, -- Take 50% less damage during dash
		stunDuration = 1.5,
		fragmentCount = 6, -- Stone breaks into 6 fragments at the end
		fragmentDamage = 50
	},
	description = "You turn to stone and dash forward, stunning enemies. Stone breaks into fragments.",
	elements = {"Earth", "Earth", "Earth"}
}

-- FIRE + FIRE + WATER
SpellData.StormFront = {
	name = "Storm Front",
	level = 6,
	damage = 280, -- Total damage if enemy stays in the storm
	cooldown = 3.5,
	projectileSpeed = 40,
	range = 120,
	aoeRadius = 25, -- Storm is 25 studs wide
	pierce = false,
	homing = false,
	specialEffect = {
		type = "LightningStorm",
		damagePerSecond = 70, -- Lightning strikes every second
		duration = 4 -- Storm lasts 4 seconds
	},
	description = "Creates an area of unstable electricity that strikes nearby enemies.",
	elements = {"Fire", "Fire", "Water"}
}

-- FIRE + FIRE + EARTH
SpellData.ClusterBomb = {
	name = "Cluster Bomb",
	level = 6,
	damage = 180, -- Initial explosion
	cooldown = 3.2,
	projectileSpeed = 70,
	range = 130,
	aoeRadius = 18,
	pierce = false,
	homing = false,
	specialEffect = {
		type = "ClusterBomb",
		fragmentCount = 8, -- Creates 8 patches of burning oil
		fragmentDamage = 20,
		oilDamagePerSecond = 25,
		oilDuration = 5,
		oilSlowPercent = 0.25
	},
	description = "Explodes into fragments that create burning oil patches.",
	elements = {"Fire", "Fire", "Earth"}
}

-- WATER + WATER + FIRE
SpellData.Thunderbolt = {
	name = "Thunderbolt",
	level = 6,
	damage = 320,
	cooldown = 3.0,
	projectileSpeed = 200, -- Extremely fast, almost instant
	range = 180,
	aoeRadius = 0,
	pierce = true, -- Goes through everything
	homing = false,
	specialEffect = nil,
	description = "Lightning that reaches its target instantly, piercing all enemies.",
	elements = {"Water", "Water", "Fire"}
}

-- WATER + WATER + EARTH
SpellData.Avalanche = {
	name = "Avalanche",
	level = 6,
	damage = 200, -- Starts at 200, grows to 400
	cooldown = 3.6,
	projectileSpeed = 45, -- Starts slow
	range = 140,
	aoeRadius = 12, -- Snowball size starts at 12, grows to 24
	pierce = false,
	homing = false,
	specialEffect = {
		type = "Avalanche",
		damageGrowth = 2.0, -- Damage doubles as it rolls
		sizeGrowth = 2.0, -- Size doubles
		stunDuration = 1.5,
		healPercent = 0.30
	},
	description = "A snowball that grows in size and damage as it rolls. Stuns on hit.",
	elements = {"Water", "Water", "Earth"}
}

-- EARTH + EARTH + FIRE
SpellData.Eruption = {
	name = "Eruption",
	level = 6,
	damage = 340,
	cooldown = 4.0,
	projectileSpeed = 50,
	range = 130,
	aoeRadius = 15,
	pierce = false,
	homing = false,
	specialEffect = {
		type = "Eruption",
		trailDamagePerSecond = 30,
		trailWidth = 10, -- Leaves a 10-stud wide trail of fire
		trailDuration = 5,
		trailSlowPercent = 0.30,
		stunDuration = 1.0
	},
	description = "A giant boulder that leaves a trail of fire and stuns on impact.",
	elements = {"Earth", "Earth", "Fire"}
}

-- EARTH + EARTH + WATER
SpellData.IceCrystal = {
	name = "Ice Crystal",
	level = 6,
	damage = 270, -- Main crystal damage
	cooldown = 3.4,
	projectileSpeed = 75,
	range = 125,
	aoeRadius = 14,
	pierce = false,
	homing = false,
	specialEffect = {
		type = "IceCrystal",
		shardCount = 4, -- Explodes into 4 shards
		shardDamage = 80,
		shardSlowPercent = 0.40,
		shardSlowDuration = 2,
		stunDuration = 1.0
	},
	description = "Ice crystal that explodes on impact, stunning and shooting shards.",
	elements = {"Earth", "Earth", "Water"}
}

-- FIRE + WATER + EARTH (THE ULTIMATE SPELL)
SpellData.ElementalStorm = {
	name = "Elemental Storm",
	level = 6,
	damage = 400, -- Total damage over duration
	cooldown = 5.0,
	projectileSpeed = 35,
	range = 100,
	aoeRadius = 30, -- Vortex is 30 studs wide
	pierce = false,
	homing = false,
	specialEffect = {
		type = "ElementalStorm",
		suckRadius = 35, -- Pulls enemies from 35 studs away
		suckSpeed = 20, -- How fast enemies are pulled in
		damagePerSecond = 80,
		duration = 5,
		disableAttacks = true -- Enemies caught can't attack
	},
	description = "Unites all elements into a whirlwind that sucks in and damages enemies.",
	elements = {"Fire", "Water", "Earth"}
}

-- ========================================
-- HELPER FUNCTION: Get Spell By Element Combo
-- ========================================
--- This function takes a list of elements (like {"Fire", "Fire", "Water"})
--- and returns the correct spell data
--- @param elementList table A list of elements like {"Fire", "Water"}
--- @return table The spell data for that combination
function SpellData:GetSpellByElements(elementList)
	-- If no elements, return Magic Missile
	if #elementList == 0 then
		return self.MagicMissile
	end
	
	-- Level 2: Single element
	if #elementList == 1 then
		if elementList[1] == "Fire" then
			return self.FireBall
		elseif elementList[1] == "Water" then
			return self.BlobOfWater
		elseif elementList[1] == "Earth" then
			return self.LumpOfDirt
		end
	end
	
	-- Level 4: Two elements
	if #elementList == 2 then
		local combo = table.concat(elementList, "+")
		if combo == "Fire+Fire" then return self.ExplosiveSalvo
		elseif combo == "Water+Water" then return self.Spray
		elseif combo == "Earth+Earth" then return self.Boulder
		elseif combo == "Fire+Water" or combo == "Water+Fire" then return self.LightningBall
		elseif combo == "Water+Earth" or combo == "Earth+Water" then return self.IceLance
		elseif combo == "Fire+Earth" or combo == "Earth+Fire" then return self.Meteor
		end
	end
	
	-- Level 6: Three elements
	if #elementList == 3 then
		local combo = table.concat(elementList, "+")
		if combo == "Fire+Fire+Fire" then return self.Supernova
		elseif combo == "Water+Water+Water" then return self.Tsunami
		elseif combo == "Earth+Earth+Earth" then return self.StoneRam
		elseif combo == "Fire+Fire+Water" or combo == "Fire+Water+Fire" or combo == "Water+Fire+Fire" then 
			return self.StormFront
		elseif combo == "Fire+Fire+Earth" or combo == "Fire+Earth+Fire" or combo == "Earth+Fire+Fire" then 
			return self.ClusterBomb
		elseif combo == "Water+Water+Fire" or combo == "Water+Fire+Water" or combo == "Fire+Water+Water" then 
			return self.Thunderbolt
		elseif combo == "Water+Water+Earth" or combo == "Water+Earth+Water" or combo == "Earth+Water+Water" then 
			return self.Avalanche
		elseif combo == "Earth+Earth+Fire" or combo == "Earth+Fire+Earth" or combo == "Fire+Earth+Earth" then 
			return self.Eruption
		elseif combo == "Earth+Earth+Water" or combo == "Earth+Water+Earth" or combo == "Water+Earth+Earth" then 
			return self.IceCrystal
		elseif combo == "Fire+Water+Earth" or combo == "Fire+Earth+Water" or 
		       combo == "Water+Fire+Earth" or combo == "Water+Earth+Fire" or 
		       combo == "Earth+Fire+Water" or combo == "Earth+Water+Fire" then 
			return self.ElementalStorm
		end
	end
	
	-- Fallback: Return Magic Missile if something went wrong
	return self.MagicMissile
end

return SpellData
