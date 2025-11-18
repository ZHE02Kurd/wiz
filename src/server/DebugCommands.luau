--!strict
-- ================================================================
-- DEBUG COMMANDS SERVER
-- ================================================================
-- Provides debug commands for testing game systems
-- Commands are chat-based and only work for specific players
-- ================================================================

print("[DEBUG] DebugCommands initializing...")

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Modules
local PlayerDataModule = require(ReplicatedStorage.Shared.Modules.PlayerDataModule)
local LevelUpServer = require(script.Parent.LevelUpServer)

-- ================================================================
-- CONFIGURATION
-- ================================================================
local ALLOWED_USERS = {
	"ZHE02Kurd", -- Add your username here
	"Player1",
	"Player2"
}

-- ================================================================
-- HELPER FUNCTIONS
-- ================================================================

local function isAllowed(player: Player): boolean
	for _, username in ipairs(ALLOWED_USERS) do
		if player.Name == username then
			return true
		end
	end
	return false
end

-- ================================================================
-- COMMAND: /xp <amount>
-- ================================================================
-- Gives XP to the player who typed the command
-- Example: /xp 100
local function commandGiveXP(player: Player, amount: number)
	print("[DebugCmd] 🎯 /xp command from", player.Name)
	
	if not isAllowed(player) then
		warn("[DebugCmd] ❌", player.Name, "not allowed to use commands")
		return
	end
	
	local data = PlayerDataModule:GetPlayerData(player)
	if not data then
		warn("[DebugCmd] ❌ No player data found for", player.Name)
		return
	end
	
	print("[DebugCmd] ⭐ Giving", amount, "XP to", player.Name)
	local leveledUp = PlayerDataModule:AddXP(player, amount)
	
	if leveledUp then
		print("[DebugCmd] 🎉 Player leveled up! Triggering level-up handler...")
		LevelUpServer.HandlePlayerLevelUp(player)
	end
	
	print("[DebugCmd] ✅ Command complete - New XP:", data.xp, "| Level:", data.level)
end

-- ================================================================
-- COMMAND: /levelup
-- ================================================================
-- Instantly levels up the player (gives exact XP needed for next level)
local function commandLevelUp(player: Player)
	print("[DebugCmd] 🎯 /levelup command from", player.Name)
	
	if not isAllowed(player) then
		warn("[DebugCmd] ❌", player.Name, "not allowed to use commands")
		return
	end
	
	local data = PlayerDataModule:GetPlayerData(player)
	if not data then
		warn("[DebugCmd] ❌ No player data found for", player.Name)
		return
	end
	
	-- Calculate XP needed for next level
	local currentLevel = data.level
	local nextLevelThreshold = PlayerDataModule.XP_THRESHOLDS[currentLevel + 1]
	
	if not nextLevelThreshold then
		warn("[DebugCmd] ⚠️", player.Name, "is already max level!")
		return
	end
	
	local xpNeeded = nextLevelThreshold - data.xp
	print("[DebugCmd] ⭐ Giving", xpNeeded, "XP to", player.Name, "(", data.xp, "→", nextLevelThreshold, ")")
	
	local leveledUp = PlayerDataModule:AddXP(player, xpNeeded)
	
	if leveledUp then
		print("[DebugCmd] 🎉 Player leveled up! Triggering level-up handler...")
		LevelUpServer.HandlePlayerLevelUp(player)
	end
	
	print("[DebugCmd] ✅ Command complete - New Level:", data.level)
end

-- ================================================================
-- COMMAND: /stats
-- ================================================================
-- Shows current player stats (HP, XP, Level, Spell)
local function commandStats(player: Player)
	print("[DebugCmd] 🎯 /stats command from", player.Name)
	
	if not isAllowed(player) then
		warn("[DebugCmd] ❌", player.Name, "not allowed to use commands")
		return
	end
	
	local data = PlayerDataModule:GetPlayerData(player)
	if not data then
		warn("[DebugCmd] ❌ No player data found for", player.Name)
		return
	end
	
	print("[DebugCmd] 📊 ========================================")
	print("[DebugCmd] 📊 STATS FOR", player.Name)
	print("[DebugCmd] 📊 Level:", data.level)
	print("[DebugCmd] 📊 XP:", data.xp)
	print("[DebugCmd] 📊 Health:", data.health, "/", data.maxHealth)
	print("[DebugCmd] 📊 Spell:", data.currentSpell.name)
	print("[DebugCmd] 📊 SpellCore:", table.concat(data.spellCore, ", "))
	print("[DebugCmd] 📊 InMatch:", data.isInMatch)
	print("[DebugCmd] 📊 ========================================")
end

-- ================================================================
-- COMMAND: /reset
-- ================================================================
-- Resets player's level and XP back to 1
local function commandReset(player: Player)
	print("[DebugCmd] 🎯 /reset command from", player.Name)
	
	if not isAllowed(player) then
		warn("[DebugCmd] ❌", player.Name, "not allowed to use commands")
		return
	end
	
	local data = PlayerDataModule:GetPlayerData(player)
	if not data then
		warn("[DebugCmd] ❌ No player data found for", player.Name)
		return
	end
	
	print("[DebugCmd] 🔄 Resetting", player.Name, "to level 1")
	PlayerDataModule:ResetMatchData(player)
	
	print("[DebugCmd] ✅ Reset complete - Level:", data.level, "| XP:", data.xp)
end

-- ================================================================
-- CHAT LISTENER
-- ================================================================

Players.PlayerAdded:Connect(function(player)
	player.Chatted:Connect(function(message)
		local lowerMessage = string.lower(message)
		
		-- /xp <amount>
		if string.match(lowerMessage, "^/xp%s+(%d+)") then
			local amount = tonumber(string.match(lowerMessage, "^/xp%s+(%d+)"))
			if amount then
				commandGiveXP(player, amount)
			end
		
		-- /levelup
		elseif lowerMessage == "/levelup" then
			commandLevelUp(player)
		
		-- /stats
		elseif lowerMessage == "/stats" then
			commandStats(player)
		
		-- /reset
		elseif lowerMessage == "/reset" then
			commandReset(player)
		end
	end)
end)

print("[DEBUG] DebugCommands ready!")
print("[DEBUG] Available commands:")
print("[DEBUG]   /xp <amount> - Give XP")
print("[DEBUG]   /levelup - Level up instantly")
print("[DEBUG]   /stats - Show your current stats")
print("[DEBUG]   /reset - Reset to level 1")

return {}
