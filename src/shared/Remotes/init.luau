--!strict
-- ================================================================
-- REMOTES MODULE
-- ================================================================
-- Initializes all RemoteEvents and RemoteFunctions for client-server communication
-- Provides organized access to networking events
-- 
-- DEBUG: All remotes created on server startup
-- ================================================================

print("[DEBUG] Remotes module initializing...")

local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Get or create Remotes folder in ReplicatedStorage
local remotesFolder = ReplicatedStorage:FindFirstChild("Remotes")
if not remotesFolder then
	remotesFolder = Instance.new("Folder")
	remotesFolder.Name = "Remotes"
	remotesFolder.Parent = ReplicatedStorage
	print("[DEBUG] Created Remotes folder in ReplicatedStorage")
end

-- ================================================================
-- REMOTE EVENT CREATION
-- ================================================================

local function createRemoteEvent(name: string): RemoteEvent
	local remote = remotesFolder:FindFirstChild(name)
	if not remote then
		remote = Instance.new("RemoteEvent")
		remote.Name = name
		remote.Parent = remotesFolder
		print("[DEBUG] Created RemoteEvent:", name)
	else
		print("[DEBUG] RemoteEvent already exists:", name)
	end
	return remote :: RemoteEvent
end

local function createRemoteFunction(name: string): RemoteFunction
	local remote = remotesFolder:FindFirstChild(name)
	if not remote then
		remote = Instance.new("RemoteFunction")
		remote.Name = name
		remote.Parent = remotesFolder
		print("[DEBUG] Created RemoteFunction:", name)
	else
		print("[DEBUG] RemoteFunction already exists:", name)
	end
	return remote :: RemoteFunction
end

-- ================================================================
-- LEVEL-UP SYSTEM REMOTES
-- ================================================================
-- LevelUpChoiceSC: Server → Client when player levels up
-- Sends: {level: number, isElement: boolean, choices: {string}}
createRemoteEvent("LevelUpChoiceSC")

-- LevelUpChoiceCS: Client → Server when player selects choice
-- Sends: {choice: string}
createRemoteEvent("LevelUpChoiceCS")

-- PlayerLeveledUpSC: Server → All Clients to show level-up VFX
-- Sends: {player: Player, newLevel: number}
createRemoteEvent("PlayerLeveledUpSC")

-- ================================================================
-- COMBAT SYSTEM REMOTES
-- ================================================================
-- CastSpellCS: Client → Server when player taps shoot button
-- Sends: {direction: Vector3}
createRemoteEvent("CastSpellCS")

-- SpellHitSC: Server → Client for hit feedback VFX
-- Sends: {hitPosition: Vector3, spellType: string}
createRemoteEvent("SpellHitSC")

-- PlayerDamagedSC: Server → Client for damage numbers
-- Sends: {damageAmount: number, isCrit: boolean}
createRemoteEvent("PlayerDamagedSC")

-- ================================================================
-- MATCH SYSTEM REMOTES
-- ================================================================
-- MatchStateChangedSC: Server → All Clients for UI updates
-- Sends: {state: string, timeRemaining: number}
createRemoteEvent("MatchStateChangedSC")

-- PlayerEliminatedSC: Server → All Clients for kill feed
-- Sends: {eliminated: Player, eliminator: Player?}
createRemoteEvent("PlayerEliminatedSC")

print("[DEBUG] All RemoteEvents created successfully")

-- ================================================================
-- EXPORTS
-- ================================================================
local Remotes = {
	-- Level-Up
	LevelUpChoiceSC = remotesFolder:WaitForChild("LevelUpChoiceSC") :: RemoteEvent,
	LevelUpChoiceCS = remotesFolder:WaitForChild("LevelUpChoiceCS") :: RemoteEvent,
	PlayerLeveledUpSC = remotesFolder:WaitForChild("PlayerLeveledUpSC") :: RemoteEvent,
	
	-- Combat
	CastSpellCS = remotesFolder:WaitForChild("CastSpellCS") :: RemoteEvent,
	SpellHitSC = remotesFolder:WaitForChild("SpellHitSC") :: RemoteEvent,
	PlayerDamagedSC = remotesFolder:WaitForChild("PlayerDamagedSC") :: RemoteEvent,
	
	-- Match
	MatchStateChangedSC = remotesFolder:WaitForChild("MatchStateChangedSC") :: RemoteEvent,
	PlayerEliminatedSC = remotesFolder:WaitForChild("PlayerEliminatedSC") :: RemoteEvent,
}

print("[DEBUG] Remotes module ready")

return Remotes
