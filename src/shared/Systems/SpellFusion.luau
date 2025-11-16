-- Spell Fusion System
local Config = require(script.Parent.Parent.Data.Config)

local SpellFusion = {}

-- Fusion recipes
local FUSIONS = {
	["Fire_Water"] = "Lightning",
	["Water_Fire"] = "Lightning",
	["Fire_Earth"] = "Lava",
	["Earth_Fire"] = "Lava",
	["Water_Earth"] = "Nature",
	["Earth_Water"] = "Nature",
}

function SpellFusion.CanFuse(element1: string, element2: string): boolean
	local key = element1 .. "_" .. element2
	return FUSIONS[key] ~= nil
end

function SpellFusion.Fuse(element1: string, element2: string): string?
	local key = element1 .. "_" .. element2
	return FUSIONS[key]
end

function SpellFusion.CombineSpell(currentElement: string, newElement: string): string
	-- Check if already a fused element
	if currentElement == "Lightning" or currentElement == "Lava" or currentElement == "Nature" then
		-- Already fused, just upgrade to new element
		return newElement
	end

	-- Try to fuse
	local fused = SpellFusion.Fuse(currentElement, newElement)
	if fused then
		return fused
	end

	-- No fusion available, just replace
	return newElement
end

function SpellFusion.GetSpellStats(element: string)
	local spellData = Config.SPELLS[element]
	if not spellData then
		return Config.SPELLS.Basic
	end
	return spellData
end

return SpellFusion
