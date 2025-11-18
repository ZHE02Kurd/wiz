--[[
    Name: init.client.luau
    Author: Magica Development Team
    Date: 2025-11-18
    Location: StarterPlayer/StarterPlayerScripts/Client/init.client.luau
    Affects: Client-side game initialization
    
    Description: This is the MAIN client script that starts when a player joins.
    It sets up the client-side systems like UI, controls, and spell casting.
]]--

print("[🎨 CLIENT] ========================================")
print("[🎨 CLIENT] 🚀 MAGICA CLIENT STARTING...")
print("[🎨 CLIENT] ========================================")

-- Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

-- Get the player
local player = Players.LocalPlayer

-- Remotes
local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local UpdateGameStateRemote = Remotes:WaitForChild("UpdateGameStateSC")
local QueuePlayerRemote = Remotes:WaitForChild("QueuePlayerCS")

-- Load client modules
-- With init.client.luau structure, sibling files become children of this script
local combatClientModule = script:FindFirstChild("CombatClient")

if combatClientModule then
	require(combatClientModule)
	print("[🎨 CLIENT] ⚔️ CombatClient loaded!")
else
	warn("[🎨 CLIENT] ❌ CombatClient not found! Spell casting will not work.")
	warn("[🎨 CLIENT] Script location:", script:GetFullName())
	warn("[🎨 CLIENT] Available children in script:")
	for _, child in ipairs(script:GetChildren()) do
		warn("  -", child.Name, child.ClassName)
	end
end

print("[🎨 CLIENT] 👤 Player:", player.Name)
print("[🎨 CLIENT] ========================================")
print("[🎨 CLIENT] ✅ CLIENT READY!")
print("[🎨 CLIENT] 📡 Waiting for game to start...")
print("[🎨 CLIENT] ========================================")

-- ========================================
-- GAME STATE LISTENER
-- ========================================
UpdateGameStateRemote.OnClientEvent:Connect(function(gameState)
	-- Update client with current game state
	-- gameState contains: state, timeRemaining, playersInQueue, playersInMatch
	
	-- TODO: Update UI with game state information
	-- For now, just log it (commented out to reduce spam)
	-- print("[🎨 CLIENT] 📊 Game State:", gameState.state, "| Time:", math.floor(gameState.timeRemaining), "s")
end)

-- ========================================
-- AUTO-JOIN QUEUE
-- ========================================
-- Auto-join queue when character loads (for testing/development)
local function autoJoinQueue()
	print("[🎨 CLIENT] 🎮 Auto-joining queue...")
	QueuePlayerRemote:FireServer()
	print("[🎨 CLIENT] ✅ Joined queue!")
end

-- Join queue when character loads
player.CharacterAdded:Connect(function(character)
	print("[🎨 CLIENT] 👤 Character loaded - waiting 1 second before joining queue...")
	task.wait(1) -- Wait a moment for everything to initialize
	autoJoinQueue()
end)

-- If character already exists, join immediately
if player.Character then
	print("[🎨 CLIENT] 👤 Character already exists - joining queue...")
	task.wait(1)
	autoJoinQueue()
end
