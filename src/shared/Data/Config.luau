-- Game Configuration
return {
	-- Match Settings
	MATCH = {
		MIN_PLAYERS = 2, -- Minimum players to start (low for testing)
		MAX_PLAYERS = 20,
		MATCH_DURATION = 300, -- 5 minutes max
		SHRINK_START_TIME = 30, -- When zone starts shrinking
		SHRINK_INTERVAL = 20, -- How often zone shrinks
		STORM_DAMAGE = 5, -- Damage per second outside zone
	},

	-- Player Settings
	PLAYER = {
		STARTING_HP = 100,
		STARTING_LEVEL = 1,
		MAX_LEVEL = 15,
		WALK_SPEED = 16,
		SPRINT_SPEED = 22,
	},

	-- Leveling & XP
	LEVELING = {
		XP_PER_LEVEL = {
			[1] = 0,
			[2] = 100,
			[3] = 250,
			[4] = 450,
			[5] = 700,
			[6] = 1000,
			[7] = 1350,
			[8] = 1750,
			[9] = 2200,
			[10] = 2700,
			[11] = 3250,
			[12] = 3850,
			[13] = 4500,
			[14] = 5200,
			[15] = 6000,
		},
		KILL_XP = 50,
		CRYSTAL_XP_SMALL = 5,
		CRYSTAL_XP_LARGE = 15,
		CHEST_XP_RANGE = { 40, 80 },
	},

	-- Spell Types
	SPELL_ELEMENTS = {
		FIRE = "Fire",
		WATER = "Water",
		EARTH = "Earth",
		LIGHTNING = "Lightning", -- Fire + Water
		LAVA = "Lava", -- Fire + Earth
		NATURE = "Nature", -- Water + Earth
	},

	-- Spell Stats
	SPELLS = {
		Basic = {
			Damage = 10,
			Cooldown = 0.5,
			ProjectileSpeed = 40,
			Range = 100,
		},
		Fire = {
			Damage = 25,
			Cooldown = 1.2,
			ProjectileSpeed = 45,
			Range = 120,
		},
		Water = {
			Damage = 20,
			Cooldown = 1.0,
			ProjectileSpeed = 42,
			Range = 110,
		},
		Earth = {
			Damage = 30,
			Cooldown = 1.5,
			ProjectileSpeed = 35,
			Range = 90,
		},
		Lightning = {
			Damage = 40,
			Cooldown = 2.0,
			ProjectileSpeed = 55,
			Range = 150,
		},
		Lava = {
			Damage = 45,
			Cooldown = 2.2,
			ProjectileSpeed = 38,
			Range = 100,
		},
		Nature = {
			Damage = 35,
			Cooldown = 1.8,
			ProjectileSpeed = 40,
			Range = 115,
		},
	},

	-- Buff Options (Odd Levels)
	BUFFS = {
		PROJECTILE_SPEED = { Name = "+Projectile Speed", Value = 10 },
		COOLDOWN_REDUCTION = { Name = "-Cooldown", Value = 0.1 },
		MAX_HP = { Name = "+Max HP", Value = 20 },
		DAMAGE = { Name = "+Damage", Value = 5 },
		MOVE_SPEED = { Name = "+Move Speed", Value = 2 },
	},

	-- Map Settings
	MAP = {
		SIZE = 500, -- studs
		CHEST_COUNT = 15,
		CRYSTAL_COUNT = 50,
	},

	-- Rewards
	REWARDS = {
		PLACEMENT_COINS = {
			[1] = 100,
			[2] = 75,
			[3] = 60,
			[4] = 50,
			[5] = 40,
		},
		KILL_COINS = 5,
		BASE_XP = 10,
	},
}
