-- Level Up System
local Config = require(script.Parent.Parent.Data.Config)
local Types = require(script.Parent.Parent.Types.GameTypes)

local LevelUpSystem = {}

function LevelUpSystem.GetXPForLevel(level: number): number
	return Config.LEVELING.XP_PER_LEVEL[level] or 9999
end

function LevelUpSystem.CanLevelUp(currentLevel: number, currentXP: number): boolean
	if currentLevel >= Config.PLAYER.MAX_LEVEL then
		return false
	end
	return currentXP >= LevelUpSystem.GetXPForLevel(currentLevel + 1)
end

function LevelUpSystem.GetChoicesForLevel(level: number): { Types.LevelUpChoice }
	local choices = {}

	if level % 2 == 0 then
		-- Even levels: Element choices
		table.insert(choices, {
			Type = "Element",
			Value = "Fire",
			DisplayName = "🔥 Fire",
		})
		table.insert(choices, {
			Type = "Element",
			Value = "Water",
			DisplayName = "💧 Water",
		})
		table.insert(choices, {
			Type = "Element",
			Value = "Earth",
			DisplayName = "🪨 Earth",
		})
	else
		-- Odd levels: Buff choices
		local buffOptions = {
			"PROJECTILE_SPEED",
			"COOLDOWN_REDUCTION",
			"MAX_HP",
			"DAMAGE",
			"MOVE_SPEED",
		}

		-- Randomly select 3 buffs
		local shuffled = table.clone(buffOptions)
		for i = #shuffled, 2, -1 do
			local j = math.random(i)
			shuffled[i], shuffled[j] = shuffled[j], shuffled[i]
		end

		for i = 1, 3 do
			local buffType = shuffled[i]
			local buffData = Config.BUFFS[buffType]
			table.insert(choices, {
				Type = "Buff",
				Value = buffType,
				DisplayName = buffData.Name,
			})
		end
	end

	return choices
end

return LevelUpSystem
