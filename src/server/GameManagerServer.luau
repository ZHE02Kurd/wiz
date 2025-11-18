--[[
    Name: GameManagerServer.luau
    Author: Magica Development Team
    Date: 2025-11-18
    Location: ServerScriptService/GameManagerServer
    Affects: ALL server scripts - this controls the entire game flow
    
    Description: This is the MASTER script that controls the entire game loop.
    It manages the two game states (Intermission and Match), handles the timers,
    teleports players between Lobby and Arena, and coordinates everything.
    When this script runs, the game starts. When it stops, the game stops.
]]--

-- Services
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local Workspace = game:GetService("Workspace")

-- Modules
local GameConstants = require(ReplicatedStorage.Shared.Data.GameConstants)
local PlayerDataModule = require(ReplicatedStorage.Shared.Modules.PlayerDataModule)

-- Server Modules
local ServerFolder = script.Parent
local ManaCrystalServer = require(ServerFolder:WaitForChild("ManaCrystalServer"))
local StormServer = require(ServerFolder:WaitForChild("StormServer"))

-- Remotes
local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local UpdateGameStateRemote = Remotes:WaitForChild("UpdateGameStateSC") -- Server to Client
local QueuePlayerRemote = Remotes:WaitForChild("QueuePlayerCS") -- Client to Server
local LeaveQueueRemote = Remotes:WaitForChild("LeaveQueueCS") -- Client to Server

local GameManagerServer = {}

-- ========================================
-- GAME STATE
-- ========================================
local GameState = {
	INTERMISSION = "Intermission",
	MATCH_IN_PROGRESS = "MatchInProgress"
}

-- Current state
local currentState = GameState.INTERMISSION
local stateTimer = 0 -- Time remaining in current state (seconds)

-- Queue system
local queuedPlayers = {} -- List of players waiting for next match
local playersInMatch = {} -- List of players currently in the arena

-- Map references (PLACEHOLDER - these need to be created in Roblox Studio)
local LobbySpawnLocation = nil -- Where players spawn in the lobby
local ArenaFolder = nil -- The arena map
local ArenaSpawnFolder = nil -- Folder containing spawn points in arena

-- ========================================
-- INITIALIZATION
-- ========================================
function GameManagerServer:Initialize()
	print("🎮 GameManager: Initializing...")
	
	-- Find map locations (PLACEHOLDER - create these in Studio)
	LobbySpawnLocation = Workspace:FindFirstChild("LobbySpawn")
	ArenaFolder = Workspace:FindFirstChild("Arena")
	ArenaSpawnFolder = ArenaFolder and ArenaFolder:FindFirstChild("SpawnPoints")
	
	if not LobbySpawnLocation then
		warn("⚠️ LobbySpawn not found! Create a SpawnLocation named 'LobbySpawn' in Workspace")
	end
	
	if not ArenaFolder then
		warn("⚠️ Arena folder not found! Create a folder named 'Arena' in Workspace")
	end
	
	-- Connect remote events
	QueuePlayerRemote.OnServerEvent:Connect(function(player)
		self:AddPlayerToQueue(player)
	end)
	
	LeaveQueueRemote.OnServerEvent:Connect(function(player)
		self:RemovePlayerFromQueue(player)
	end)
	
	-- Start the game loop
	self:StartGameLoop()
	
	print("✅ GameManager: Ready!")
end

-- ========================================
-- QUEUE MANAGEMENT
-- ========================================
--- Adds a player to the queue for the next match
--- @param player Player The player who wants to queue
function GameManagerServer:AddPlayerToQueue(player)
	print("[GameManager] 🎮 AddPlayerToQueue called for " .. player.DisplayName .. " (UserId: " .. player.UserId .. ")")
	
	-- Check if already queued
	for _, queuedPlayer in ipairs(queuedPlayers) do
		if queuedPlayer == player then
			warn("[GameManager] ⚠️ " .. player.DisplayName .. " is ALREADY in queue - ignoring request")
			print("[GameManager] 📊 Current queue size: " .. #queuedPlayers)
			return
		end
	end
	
	-- Check if already in a match
	for _, matchPlayer in ipairs(playersInMatch) do
		if matchPlayer == player then
			warn("[GameManager] ⚠️ " .. player.DisplayName .. " is ALREADY in a match - cannot queue")
			return
		end
	end
	
	-- Add to queue
	table.insert(queuedPlayers, player)
	
	-- Update player data
	local data = PlayerDataModule:GetPlayerData(player)
	if data then
		data.isInQueue = true
		print("[GameManager] ✅ Set isInQueue = true for " .. player.DisplayName)
	end
	
	print("[GameManager] ➕ " .. player.DisplayName .. " added to queue")
	print("[GameManager] 📊 Queue size: " .. #queuedPlayers .. " / " .. GameConstants.MIN_PLAYERS_TO_START .. " (min required)")
	
	-- List all queued players
	if #queuedPlayers <= 5 then
		print("[GameManager] 👥 Players in queue:")
		for i, p in ipairs(queuedPlayers) do
			print("  " .. i .. ". " .. p.DisplayName)
		end
	end
end

--- Removes a player from the queue
--- @param player Player The player leaving the queue
function GameManagerServer:RemovePlayerFromQueue(player)
	for i, queuedPlayer in ipairs(queuedPlayers) do
		if queuedPlayer == player then
			table.remove(queuedPlayers, i)
			
			-- Update player data
			local data = PlayerDataModule:GetPlayerData(player)
			if data then
				data.isInQueue = false
			end
			
			print("➖ " .. player.DisplayName .. " left the queue (" .. #queuedPlayers .. " in queue)")
			return
		end
	end
end

-- ========================================
-- PLAYER SPAWNING
-- ========================================
--- Spawns a player in the lobby
--- @param player Player The player to spawn
function GameManagerServer:SpawnPlayerInLobby(player)
	if not player.Character then
		warn("⚠️ Cannot spawn " .. player.DisplayName .. " - no character")
		return
	end
	
	local humanoidRootPart = player.Character:FindFirstChild("HumanoidRootPart")
	if not humanoidRootPart then
		warn("⚠️ Cannot spawn " .. player.DisplayName .. " - no HumanoidRootPart")
		return
	end
	
	-- Teleport to lobby
	if LobbySpawnLocation then
		humanoidRootPart.CFrame = LobbySpawnLocation.CFrame + Vector3.new(0, 5, 0)
		print("🏠 " .. player.DisplayName .. " spawned in lobby")
	else
		-- Fallback: Spawn at world origin
		humanoidRootPart.CFrame = CFrame.new(0, 10, 0)
		warn("⚠️ " .. player.DisplayName .. " spawned at origin (LobbySpawn not found)")
	end
end

--- Spawns players in the arena at the start of a match
--- @param players table List of players to spawn
function GameManagerServer:SpawnPlayersInArena(players)
	if not ArenaSpawnFolder then
		warn("⚠️ Cannot spawn players - ArenaSpawnFolder not found")
		return
	end
	
	-- Get all spawn points
	local spawnPoints = ArenaSpawnFolder:GetChildren()
	if #spawnPoints == 0 then
		warn("⚠️ No spawn points found in Arena/SpawnPoints folder")
		return
	end
	
	-- Spawn each player at a random spawn point
	for _, player in ipairs(players) do
		if player.Character then
			local humanoidRootPart = player.Character:FindFirstChild("HumanoidRootPart")
			if humanoidRootPart then
				-- Pick a random spawn point
				local spawnPoint = spawnPoints[math.random(1, #spawnPoints)]
				humanoidRootPart.CFrame = spawnPoint.CFrame + Vector3.new(0, 5, 0)
				print("🎯 " .. player.DisplayName .. " spawned in arena")
			end
		end
	end
end

-- ========================================
-- MATCH FLOW
-- ========================================
--- Starts a new match
function GameManagerServer:StartMatch()
	print("[GameManager] 🚀 ========================================")
	print("[GameManager] 🚀 START MATCH CALLED")
	print("[GameManager] 🚀 ========================================")
	
	if currentState == GameState.MATCH_IN_PROGRESS then
		warn("[GameManager] ❌ Match already in progress - cannot start new match")
		return
	end
	
	local queueSize = #queuedPlayers
	print("[GameManager] 📊 Queue size: " .. queueSize .. " | Min required: " .. GameConstants.MIN_PLAYERS_TO_START)
	
	-- Check if we have players
	if queueSize < GameConstants.MIN_PLAYERS_TO_START then
		warn("[GameManager] ❌ Not enough players to start match")
		print("[GameManager] ℹ️ Need " .. GameConstants.MIN_PLAYERS_TO_START .. " players, have " .. queueSize)
		-- Skip to next intermission
		self:StartIntermission()
		return
	end
	
	print("[GameManager] ✅ Sufficient players - proceeding with match start")
	
	-- Move queued players to active match
	print("[GameManager] 🔄 Moving players from queue to match...")
	playersInMatch = {}
	local playerCount = 0
	for _, player in ipairs(queuedPlayers) do
		table.insert(playersInMatch, player)
		playerCount = playerCount + 1
		
		print("[GameManager] 🔄 Preparing player " .. playerCount .. ": " .. player.DisplayName)
		
		-- Update player data
		local data = PlayerDataModule:GetPlayerData(player)
		if data then
			data.isInQueue = false
			data.isInMatch = true
			print("[GameManager] ✅ Set isInMatch = true for " .. player.DisplayName)
			PlayerDataModule:ResetMatchData(player) -- Reset stats for new match
		else
			warn("[GameManager] ⚠️ No player data found for " .. player.DisplayName)
		end
	end
	
	-- Clear the queue
	queuedPlayers = {}
	print("[GameManager] ✅ Queue cleared")
	
	print("[GameManager] 👥 Total players in match: " .. playerCount)
	
	-- Spawn all players in the arena
	print("[GameManager] 📍 Spawning players in arena...")
	self:SpawnPlayersInArena(playersInMatch)
	
	-- Change game state
	local oldState = currentState
	currentState = GameState.MATCH_IN_PROGRESS
	stateTimer = GameConstants.MATCH_DURATION
	print("[GameManager] 🎮 Game state changed: " .. oldState .. " → " .. currentState)
	print("[GameManager] ⏱️ Match duration: " .. stateTimer .. " seconds")
	
	-- Notify all clients
	self:BroadcastGameState()
	
	-- Spawn Mana Crystals around the arena
	print("[GameManager] 💎 Spawning Mana Crystals...")
	local arenaCenter = Vector3.new(0, 5, 0) -- PLACEHOLDER: Get actual arena center
	ManaCrystalServer:SpawnCrystals(arenaCenter, 50)
	print("[GameManager] ✅ Mana Crystals spawned")
	
	-- Start storm system (runs in background)
	print("[GameManager] 🌪️ Starting Storm System...")
	task.spawn(function()
		StormServer:StartStorm()
	end)
	
	print("[GameManager] 🎮 =========================================")
	print("[GameManager] 🎮 MATCH STARTED SUCCESSFULLY!")
	print("[GameManager] 🎮 =========================================")
end

--- Ends the current match
function GameManagerServer:EndMatch()
	print("[GameManager] 🏁 ========================================")
	print("[GameManager] 🏁 ENDING MATCH")
	print("[GameManager] 🏁 ========================================")
	
	-- Clean up match environment
	print("[GameManager] 🧹 Cleaning up match environment...")
	StormServer:StopStorm()
	ManaCrystalServer:ClearCrystals()
	print("[GameManager] ✅ Match cleanup complete")
	
	-- Calculate placements for remaining players
	local remainingPlayers = {}
	for _, player in ipairs(playersInMatch) do
		if player and player.Parent then -- Check if player is still in game
			table.insert(remainingPlayers, player)
		end
	end
	
	print("[GameManager] 📊 Remaining players at match end: " .. #remainingPlayers)
	
	-- Give placement to remaining players (they all "tied" for whatever place they are)
	local finalPlacement = #remainingPlayers
	for _, player in ipairs(remainingPlayers) do
		local data = PlayerDataModule:GetPlayerData(player)
		if data then
			data.placement = finalPlacement
		end
	end
	
	-- Teleport all remaining players back to lobby
	for _, player in ipairs(remainingPlayers) do
		self:SpawnPlayerInLobby(player)
		
		-- Update player data
		local data = PlayerDataModule:GetPlayerData(player)
		if data then
			data.isInMatch = false
		end
		
		-- TODO: Show post-match summary UI
		-- TODO: Calculate and award coins
		-- TODO: Bank gems
	end
	
	-- Clear match player list
	playersInMatch = {}
	
	-- Start intermission
	self:StartIntermission()
end

--- Starts the intermission phase
function GameManagerServer:StartIntermission()
	print("⏸️ ===== INTERMISSION STARTING =====")
	
	currentState = GameState.INTERMISSION
	stateTimer = GameConstants.INTERMISSION_DURATION
	
	-- Notify all clients
	self:BroadcastGameState()
end

--- Handles a player being eliminated during a match
--- @param player Player The player who died
--- @param killer Player|nil The player who killed them
function GameManagerServer:PlayerEliminated(player, killer)
	print("[GameManager] 💀 ========================================")
	print("[GameManager] 💀 PLAYER ELIMINATION")
	print("[GameManager] 💀 Player: " .. player.DisplayName)
	if killer then
		print("[GameManager] 💀 Killer: " .. killer.DisplayName)
	else
		print("[GameManager] 💀 Killer: Unknown/Environment")
	end
	print("[GameManager] 💀 ========================================")
	
	-- Remove from match player list FIRST (before calculating placement)
	local removed = false
	for i, matchPlayer in ipairs(playersInMatch) do
		if matchPlayer == player then
			table.remove(playersInMatch, i)
			removed = true
			print("[GameManager] ✅ Removed " .. player.DisplayName .. " from match player list")
			break
		end
	end
	if not removed then
		warn("[GameManager] ⚠️ Player was not in playersInMatch list")
	end
	
	-- NOW calculate placement (how many players are left alive + 1)
	-- This gives correct placement: if 1 player left, you're #2. If 0 left, you won (#1)
	local data = PlayerDataModule:GetPlayerData(player)
	if data then
		local playersAlive = 0
		for _, matchPlayer in ipairs(playersInMatch) do
			local matchData = PlayerDataModule:GetPlayerData(matchPlayer)
			if matchData and matchData.health > 0 then
				playersAlive = playersAlive + 1
			end
		end
		data.placement = playersAlive + 1
		data.isInMatch = false
		
		print("[GameManager] 📊 Placement: #" .. data.placement .. " (" .. playersAlive .. " players still alive)")
		print("[GameManager] ✅ Set isInMatch = false for " .. player.DisplayName)
	else
		warn("[GameManager] ⚠️ No player data found for " .. player.DisplayName)
	end
	
	-- Teleport back to lobby
	print("[GameManager] ⏳ Waiting 2 seconds before respawn...")
	task.wait(2) -- Wait 2 seconds so they can see the death
	print("[GameManager] 🏠 Teleporting " .. player.DisplayName .. " to lobby...")
	self:SpawnPlayerInLobby(player)
	
	local remainingCount = #playersInMatch
	print("[GameManager] 👥 Players remaining in match: " .. remainingCount)
	
	-- TODO: Show elimination screen
	-- TODO: Drop loot (gems, health orbs)
	-- TODO: Give XP to killer
	
	-- Check if match is over (only 1 player left)
	local playersAlive = 0
	for _, matchPlayer in ipairs(playersInMatch) do
		local matchData = PlayerDataModule:GetPlayerData(matchPlayer)
		if matchData and matchData.health > 0 then
			playersAlive = playersAlive + 1
		end
	end
	
	print("[GameManager] 👥 Players still alive: " .. playersAlive)
	
	if playersAlive <= 1 then
		print("[GameManager] 🏆 Only " .. playersAlive .. " player(s) remaining - match over!")
		self:EndMatch()
	else
		print("[GameManager] ℹ️ Match continues with " .. playersAlive .. " players alive")
	end
	
	print("[GameManager] 💀 ========================================")
end

-- ========================================
-- GAME LOOP
-- ========================================
--- Starts the main game loop (runs forever)
function GameManagerServer:StartGameLoop()
	print("[GameManager] 🔄 ========================================")
	print("[GameManager] 🔄 GAME LOOP STARTING")
	print("[GameManager] 🔄 ========================================")
	
	-- Start with intermission
	self:StartIntermission()
	
	-- Main loop (runs every second)
	task.spawn(function()
		local lastDebugTime = 0
		while true do
			task.wait(1) -- Wait 1 second
			
			-- Decrease timer
			stateTimer = stateTimer - 1
			
			local currentTime = tick()
			local shouldDebug = (currentTime - lastDebugTime) > 10
			
			if currentState == GameState.INTERMISSION then
				if shouldDebug or stateTimer % 30 == 0 then
					print("[GameManager] ⏱️ INTERMISSION - Time: " .. stateTimer .. "s | Queue: " .. #queuedPlayers .. " players")
					lastDebugTime = currentTime
				end
				
				if stateTimer == 30 then
					print("[GameManager] ⚠️ 30 SECONDS until match attempt")
				elseif stateTimer == 10 then
					print("[GameManager] ⚠️ 10 SECONDS until match attempt")
				end
				
			elseif currentState == GameState.MATCH_IN_PROGRESS then
				if shouldDebug or stateTimer % 30 == 0 then
					print("[GameManager] ⏱️ MATCH - Time: " .. stateTimer .. "s | Players: " .. #playersInMatch)
					lastDebugTime = currentTime
				end
				
				if stateTimer == 60 then
					print("[GameManager] ⚠️ 1 MINUTE REMAINING!")
				elseif stateTimer == 30 then
					print("[GameManager] ⚠️ 30 SECONDS REMAINING!")
				elseif stateTimer == 10 then
					print("[GameManager] ⚠️ 10 SECONDS REMAINING!")
				end
			end
			
			-- Broadcast updated timer to all clients
			self:BroadcastGameState()
			
			-- Check if timer expired
			if stateTimer <= 0 then
				if currentState == GameState.INTERMISSION then
					print("[GameManager] ⏰ Intermission timer expired - attempting to start match")
					-- Intermission over, start match
					self:StartMatch()
				elseif currentState == GameState.MATCH_IN_PROGRESS then
					print("[GameManager] ⏰ Match timer expired - ending match")
					-- Match time expired, end match
					self:EndMatch()
				end
			end
		end
	end)
end

--- Sends the current game state to all players
function GameManagerServer:BroadcastGameState()
	-- Send to all players
	for _, player in ipairs(Players:GetPlayers()) do
		UpdateGameStateRemote:FireClient(player, {
			state = currentState,
			timeRemaining = stateTimer,
			playersInQueue = #queuedPlayers,
			playersInMatch = #playersInMatch
		})
	end
end

-- ========================================
-- PLAYER LIFECYCLE
-- ========================================
-- Handle player joining
Players.PlayerAdded:Connect(function(player)
	print("[GameManager] 👋 ========================================")
	print("[GameManager] 👋 PLAYER JOINED")
	print("[GameManager] 👋 Player: " .. player.DisplayName .. " (UserId: " .. player.UserId .. ")")
	print("[GameManager] 👋 ========================================")
	
	-- Create player data
	PlayerDataModule:CreatePlayerData(player)
	
	-- Wait for character to load
	player.CharacterAdded:Connect(function(character)
		print("[GameManager] 👤 Character loaded for " .. player.DisplayName)
		-- Spawn in lobby
		GameManagerServer:SpawnPlayerInLobby(player)
		
		-- Auto-add to queue (for testing - later this should be a button click)
		task.wait(1) -- Wait for character to fully load
		GameManagerServer:AddPlayerToQueue(player)
		
		-- Listen for death
		local humanoid = character:WaitForChild("Humanoid")
		humanoid.Died:Connect(function()
			print("[GameManager] 💀 " .. player.DisplayName .. "'s character died")
			-- Check if they were in a match
			local data = PlayerDataModule:GetPlayerData(player)
			if data and data.isInMatch then
				print("[GameManager] ℹ️ Player was in match - handling elimination")
				GameManagerServer:PlayerEliminated(player, nil) -- TODO: Track who killed them
			else
				print("[GameManager] ℹ️ Player was not in match - ignoring death")
			end
		end)
	end)
	
	-- If they already have a character, spawn them
	if player.Character then
		print("[GameManager] ✅ Character already exists - spawning immediately")
		GameManagerServer:SpawnPlayerInLobby(player)
	end
end)

-- Handle player leaving
Players.PlayerRemoving:Connect(function(player)
	print("[GameManager] 👋 ========================================")
	print("[GameManager] 👋 PLAYER LEAVING")
	print("[GameManager] 👋 Player: " .. player.DisplayName .. " (UserId: " .. player.UserId .. ")")
	print("[GameManager] 👋 ========================================")
	
	-- Remove from queue
	print("[GameManager] 🔄 Removing from queue...")
	GameManagerServer:RemovePlayerFromQueue(player)
	
	-- Remove from match
	local wasInMatch = false
	for i, matchPlayer in ipairs(playersInMatch) do
		if matchPlayer == player then
			table.remove(playersInMatch, i)
			wasInMatch = true
			print("[GameManager] ✅ Removed from match (" .. #playersInMatch .. " players remaining)")
			break
		end
	end
	if not wasInMatch then
		print("[GameManager] ℹ️ Player was not in a match")
	end
	
	-- Remove player data
	PlayerDataModule:RemovePlayerData(player)
	print("[GameManager] ✅ Player cleanup complete")
end)

-- ========================================
-- RETURN MODULE
-- ========================================
-- Note: Initialize() is called by init.server.luau, not here
return GameManagerServer

