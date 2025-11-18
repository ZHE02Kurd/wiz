--[[
    Name: LevelUpServer.luau
    Author: Magica Development Team
    Date: 2025-11-18
    Location: ServerScriptService/LevelUpServer
    Affects: PlayerDataModule.luau, BuffData.luau, SpellData.luau
    
    Description: This server script handles the level-up choice system. When a player
    levels up, this script decides what choices to show them (elements for even levels,
    buffs for odd levels), sends the choices to the client, and processes their selection.
    This is the core of the spell evolution mechanic!
]]--

-- Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Modules
local PlayerDataModule = require(ReplicatedStorage.Shared.Modules.PlayerDataModule)
local BuffData = require(ReplicatedStorage.Shared.Data.BuffData)
local Remotes = require(ReplicatedStorage.Shared.Remotes)

-- RemoteEvents
local LevelUpChoiceSCRemote = Remotes.LevelUpChoiceSC -- Server to Client
local LevelUpChoiceCSRemote = Remotes.LevelUpChoiceCS -- Client to Server
local PlayerLeveledUpSCRemote = Remotes.PlayerLeveledUpSC -- Notify all clients

-- ========================================
-- LEVEL UP HANDLER
-- ========================================
--- Called when a player levels up
--- @param player Player The player who leveled up
function HandlePlayerLevelUp(player)
	print("[LevelUpServer] ⭐ ========================================")
	print("[LevelUpServer] ⭐ PLAYER LEVEL UP!")
	print("[LevelUpServer] ⭐ Player: " .. player.DisplayName)
	print("[LevelUpServer] ⭐ ========================================")
	
	local data = PlayerDataModule:GetPlayerData(player)
	if not data then 
		warn("[LevelUpServer] ❌ No player data found for " .. player.DisplayName)
		return 
	end
	
	local currentLevel = data.level
	print("[LevelUpServer] 📊 Current Level: " .. currentLevel)
	print("[LevelUpServer] 👋 Level " .. currentLevel .. " reached by " .. player.DisplayName .. "!")
	
	-- Determine what choices to offer based on level
	local choices = {}
	
	-- EVEN LEVELS (2, 4, 6): Choose an element
	if currentLevel == 2 or currentLevel == 4 or currentLevel == 6 then
		print("[LevelUpServer] 🔮 Even level - offering ELEMENT choices")
		-- Offer the three elements
		choices = {
			{type = "Element", name = "Fire", description = "Add Fire to your spell"},
			{type = "Element", name = "Water", description = "Add Water to your spell"},
			{type = "Element", name = "Earth", description = "Add Earth to your spell"}
		}
		
		print("[LevelUpServer] 🔮 " .. player.DisplayName .. " can choose an element")
	end
	
	-- ODD LEVELS (3, 5, 7, 8, 9): Choose a passive buff
	if currentLevel == 3 or currentLevel == 5 or currentLevel == 7 or currentLevel == 8 or currentLevel == 9 then
		-- Get 3 random buff choices
		local buffChoices = BuffData:GetRandomBuffChoices(currentLevel, data.buffs)
		
		for _, buff in ipairs(buffChoices) do
			table.insert(choices, {
				type = "Buff",
				name = buff.name,
				description = buff.description,
				statType = buff.statType,
				value = buff.value
			})
		end
		
		print("💪 " .. player.DisplayName .. " can choose a buff")
	end
	
	-- LEVEL 10: Choose an ultimate buff
	if currentLevel == 10 then
		-- This is handled by BuffData:GetRandomBuffChoices
		-- It automatically returns ultimate buffs for level 10
	end
	
	-- Send choices to client
	if #choices > 0 then
		-- Determine if this is an element choice or buff choice
		local isElementChoice = (choices[1].type == "Element")
		
		-- Extract just the choice names for the UI
		local choiceNames = {}
		for _, choice in ipairs(choices) do
			table.insert(choiceNames, choice.name)
		end
		
		-- Send to client with proper format
		local choiceData = {
			level = currentLevel,
			isElement = isElementChoice,
			choices = choiceNames
		}
		
		print("[LevelUpServer] 📤 Sending choices to client:", table.concat(choiceNames, ", "))
		LevelUpChoiceSCRemote:FireClient(player, choiceData)
		
		-- Also notify all clients that this player leveled up (for VFX)
		PlayerLeveledUpSCRemote:FireAllClients(player, currentLevel)
	else
		warn("⚠️ No level-up choices for level " .. currentLevel)
	end
end

-- ========================================
-- CHOICE SELECTION HANDLER
-- ========================================
LevelUpChoiceCSRemote.OnServerEvent:Connect(function(player, choiceName)
	print("[LevelUpServer] 🎯 ========================================")
	print("[LevelUpServer] 🎯 LEVEL-UP CHOICE RECEIVED")
	print("[LevelUpServer] 🎯 Player: " .. (player and player.DisplayName or "nil"))
	print("[LevelUpServer] 🎯 Choice: " .. tostring(choiceName))
	print("[LevelUpServer] 🎯 ========================================")
	
	-- SECURITY: Validate player
	if not player or not player.Parent then
		warn("[LevelUpServer] ❌ SECURITY: Invalid player object")
		return
	end
	print("[LevelUpServer] ✅ Player validation passed")
	
	-- SECURITY: Validate choice
	if not choiceName or type(choiceName) ~= "string" then
		warn("[LevelUpServer] ❌ SECURITY: Invalid choice data type: " .. type(choiceName))
		return
	end
	print("[LevelUpServer] ✅ Choice validation passed")
	
	local data = PlayerDataModule:GetPlayerData(player)
	if not data then
		warn("[LevelUpServer] ❌ No player data found")
		return
	end
	print("[LevelUpServer] ✅ Player data found")
	
	-- SECURITY: Check if player is in a match
	if not data.isInMatch then
		warn("[LevelUpServer] ❌ SECURITY: Player not in match - isInMatch = false")
		return
	end
	print("[LevelUpServer] ✅ Player is in match")
	
	-- Determine choice type based on player's current level
	local currentLevel = data.level
	local isElementChoice = (currentLevel == 2 or currentLevel == 4 or currentLevel == 6)
	
	-- Process the choice
	if isElementChoice then
		print("[LevelUpServer] 🔮 Processing ELEMENT choice...")
		
		-- SECURITY: Validate element
		if choiceName ~= "Fire" and choiceName ~= "Water" and choiceName ~= "Earth" then
			warn("[LevelUpServer] ❌ SECURITY: Invalid element: " .. tostring(choiceName))
			return
		end
		print("[LevelUpServer] ✅ Element validation passed: " .. choiceName)
		
		-- Add element to player's spell core
		PlayerDataModule:AddElement(player, choiceName)
		
		print("[LevelUpServer] ✅ Element added successfully!")
		print("[LevelUpServer] ✨ " .. player.DisplayName .. " chose " .. choiceName .. "! New spell: " .. data.currentSpell.name)
	
	else
		print("[LevelUpServer] 💪 Processing BUFF choice...")
		
		-- SECURITY: Validate buff exists
		if not BuffData[choiceName] then
			warn("[LevelUpServer] ❌ SECURITY: Invalid buff: " .. tostring(choiceName))
			return
		end
		print("[LevelUpServer] ✅ Buff validation passed: " .. choiceName)
		
		-- Add buff to player
		PlayerDataModule:AddBuff(player, choiceName)
		
		print("[LevelUpServer] ✅ Buff added successfully!")
		print("[LevelUpServer] 💪 " .. player.DisplayName .. " chose " .. choiceName .. "!")
	end
	
	-- Notify client that choice was processed
	print("[LevelUpServer] 📡 Notifying client of choice completion...")
	PlayerLeveledUpSCRemote:FireClient(player, {
		level = data.level,
		currentSpell = data.currentSpell.name,
		buffs = data.buffs
	})
	print("[LevelUpServer] ✅ Choice processing complete!")
	print("[LevelUpServer] ========================================")
end)

-- ========================================
-- LISTEN FOR XP GAINS
-- ========================================
-- This would normally be in a pickup system, but for now we'll export the function
return {
	HandlePlayerLevelUp = HandlePlayerLevelUp
}
