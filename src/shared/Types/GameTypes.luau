-- Type definitions for the game
export type SpellElement = "Fire" | "Water" | "Earth" | "Lightning" | "Lava" | "Nature" | "Basic"

export type SpellData = {
	Element: SpellElement,
	Damage: number,
	Cooldown: number,
	ProjectileSpeed: number,
	Range: number,
	LastCastTime: number?,
}

export type BuffType = "PROJECTILE_SPEED" | "COOLDOWN_REDUCTION" | "MAX_HP" | "DAMAGE" | "MOVE_SPEED"

export type PlayerStats = {
	HP: number,
	MaxHP: number,
	Level: number,
	XP: number,
	Kills: number,
	CurrentSpell: SpellData,
	Buffs: { [BuffType]: number },
}

export type LevelUpChoice = {
	Type: "Element" | "Buff",
	Value: SpellElement | BuffType,
	DisplayName: string,
}

export type MatchState = "Waiting" | "Starting" | "InProgress" | "Ending"

export type PlayerState = "Alive" | "Dead" | "Spectating"

return {}
