-- services
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")
local Teams = game:GetService("Teams")
local TeleportService = game:GetService("TeleportService")

-- constants
local ITEMS = ReplicatedStorage.Items
local REMOTES = ReplicatedStorage.Remotes
local PLAYER_DATA_FOLDER = ReplicatedStorage:WaitForChild("PlayerData")
local STORM_SCRIPT = script.Parent.StormScript

-- GAME SETTINGS
local MAX_ROUNDS = 5
local ROUNDS_TO_WIN = 5
local ROUND_PREP_TIME = 10
local ROUND_END_TIME = 8
local STORM_START_DELAY = 60
local HUB_PLACE_ID = 84984343682815

-- Get spawn points
local TEAM_A_SPAWNS = Workspace:WaitForChild("TeamASpawns"):GetChildren()
local TEAM_B_SPAWNS = Workspace:WaitForChild("TeamBSpawns"):GetChildren()

print("--- ROUND SCRIPT LOADED ---")
print("Spawns loaded: Team A [" .. #TEAM_A_SPAWNS .. "], Team B [" .. #TEAM_B_SPAWNS .. "]")

-- Team definitions
local teamA = Teams:FindFirstChild("Team A") or Instance.new("Team", Teams)
teamA.Name = "Team A"
teamA.TeamColor = BrickColor.new("Bright blue")
teamA.AutoAssignable = false

local teamB = Teams:FindFirstChild("Team B") or Instance.new("Team", Teams)
teamB.Name = "Team B"
teamB.TeamColor = BrickColor.new("Bright red")
teamB.AutoAssignable = false

Players.CharacterAutoLoads = false

-- Match state variables
local teamAScore = 0
local teamBScore = 0
local currentRound = 0
local playersInRound = {}
local roundConnections = {}
local isRoundInProgress = false
local teamAssignmentsLocked = false
local playerSpawnPoints = {}


-- FUNCTIONS --

local function ClearInventory(character)
	if character:FindFirstChild("Items") then
		character.Items:ClearAllChildren()
	end
	if character:FindFirstChild("Ammo") then
		for _, ammo in pairs(character.Ammo:GetChildren()) do
			ammo.Value = 0
		end
	end
end

local function GiveLoadout(player)
	local character = player.Character
	if not character then
		warn("[LOADOUT] No character for " .. player.Name)
		return
	end

	local playerData = PLAYER_DATA_FOLDER:FindFirstChild(player.Name)
	if not playerData then
		warn("[LOADOUT] No PlayerData folder for " .. player.Name)
		return
	end

	local equipped = playerData:WaitForChild("Equipped")
	-- Wait up to 5 seconds for these folders to be added to the character
	local ammo = character:WaitForChild("Ammo", 5)
	local itemsFolder = character:WaitForChild("Items", 5)

	if not ammo or not itemsFolder then
		warn("[LOADOUT] Missing Ammo or Items folder for " .. player.Name)
		return
	end

	ClearInventory(character)

	local function GiveItem(itemName, defaultItem)
		local finalItemName = itemName
		if not itemName or itemName == "" or not ITEMS:FindFirstChild(itemName) then
			finalItemName = defaultItem
		end

		local itemToGive = ITEMS:FindFirstChild(finalItemName)
		if itemToGive then
			local clonedItem = itemToGive:Clone()
			clonedItem.Parent = itemsFolder
			print("[LOADOUT DEBUG] Gave " .. finalItemName .. " to " .. player.Name)

			-- Give Ammo
			if finalItemName == "Beagle" and ammo:FindFirstChild("Light") then
				ammo.Light.Value = 60
			elseif finalItemName == "AR-18" and ammo:FindFirstChild("Medium") then
				ammo.Medium.Value = 180
			elseif finalItemName == "Pump Shotgun" and ammo:FindFirstChild("Shells") then
				ammo.Shells.Value = 48
			end
		end
	end

	-- Give Weapons
	GiveItem(equipped.Automatic.Value, "AR-18")
	GiveItem(equipped.Pistol.Value, "Beagle")
	GiveItem(equipped.Melee.Value, "Katana")

	-- Give Consumables
	if ITEMS:FindFirstChild("Armor") then
		ITEMS.Armor:Clone().Parent = itemsFolder
		print("[LOADOUT DEBUG] Gave Armor to " .. player.Name)
	end
	if ITEMS:FindFirstChild("Health Pack") then
		ITEMS["Health Pack"]:Clone().Parent = itemsFolder
		print("[LOADOUT DEBUG] Gave Health Pack to " .. player.Name)
	end

	print("[LOADOUT] ✓ Complete for " .. player.Name)
end

local function SpawnPlayer(player)
	print("[SPAWN ATTEMPT] Player: " .. player.Name .. ", UserId: " .. tostring(player.UserId))

	-- DEBUG: Show what's in the table right now
	print("[DEBUG] Current playerSpawnPoints (at spawn attempt):")
	for userId, spawnPart in pairs(playerSpawnPoints) do
		print("  " .. tostring(userId) .. " → " .. spawnPart.Name)
	end
	local character = player.Character
	if not character then
		warn("[SPAWN] No character for " .. player.Name)
		return
	end

	-- Use the player's assigned spawn point (lookup by UserId)
	local spawnPart = playerSpawnPoints[player.UserId]

	if not spawnPart then
		warn("[CRITICAL] No spawn point assigned for " .. player.Name .. " (UserId: " .. player.UserId .. ") - Team: " .. tostring(player.Team))
		return
	end

	print("[SPAWN START] " .. player.Name .. " → " .. spawnPart.Name .. " (Team: " .. player.Team.Name .. ")")

	-- Wait for HumanoidRootPart to exist
	local rootPart = character:WaitForChild("HumanoidRootPart", 10)
	if not rootPart then
		warn("[SPAWN] No HumanoidRootPart for " .. player.Name)
		return
	end

	-- Small random offset so players don't overlap (within 3 studs radius)
	local randomOffset = Vector3.new(
		math.random(-3, 3),
		0,
		math.random(-3, 3)
	)

	-- FORCE teleport multiple times to ensure it sticks
	local targetCFrame = spawnPart.CFrame * CFrame.new(0, 3, 0) * CFrame.new(randomOffset)

	-- Teleport 3 times with small delays to override Roblox's default spawn
	for i = 1, 3 do
		rootPart.CFrame = targetCFrame
		wait(0.05)
	end

	print("[SPAWN POS] " .. player.Name .. " teleported to: " .. tostring(rootPart.Position))

	-- Reset Status AFTER teleporting
	local humanoid = character:WaitForChild("Humanoid")
	humanoid.Health = humanoid.MaxHealth
	if humanoid:FindFirstChild("Armor") then
		humanoid.Armor.Value = 100
	end

	-- Wait for physics to settle
	wait(0.2)

	-- Loadout
	GiveLoadout(player)

	-- Mark as alive
	playersInRound[player] = true
	print("[SPAWN] ✓ " .. player.Name .. " spawned at " .. spawnPart.Name .. " (Team: " .. player.Team.Name .. ")")
end

local function CleanUpRound()
	playersInRound = {}
	-- Disconnect specifically tracked connections if you add any later
	-- Stop the storm
	STORM_SCRIPT.StopSequence:Fire()
end

local function CheckForRoundWinner()
	local teamAlive = nil
	local playersAliveCount = 0

	for player, _ in pairs(playersInRound) do
		if player.Team then
			if teamAlive == nil then
				teamAlive = player.Team
			elseif teamAlive ~= player.Team then
				return nil -- Both teams still have players
			end
			playersAliveCount = playersAliveCount + 1
		end
	end

	if playersAliveCount == 0 then
		return "draw"
	end

	return teamAlive -- Only one team remains
end

function OnPlayerDied(player)
	if not isRoundInProgress then return end
	if not playersInRound[player] then return end

	print("[DEATH] " .. player.Name .. " eliminated.")
	playersInRound[player] = nil -- Mark as dead

	REMOTES.RoundInfo:FireAllClients("Message", player.Name .. " has been eliminated.")

	-- Spectator Mode
	REMOTES.Camera:FireClient(player, "Mode", "Spectate")

	-- Check Win Condition
	local winningTeam = CheckForRoundWinner()
	if winningTeam then
		EndRound(winningTeam)
	end
end

function EndRound(winningTeam)
	isRoundInProgress = false
	CleanUpRound()

	if winningTeam == "draw" then
		REMOTES.RoundInfo:FireAllClients("Message", "Round Draw!")
		print("[ROUND END] Draw")
	elseif winningTeam then
		if winningTeam == teamA then
			teamAScore = teamAScore + 1
		else
			teamBScore = teamBScore + 1
		end
		REMOTES.RoundInfo:FireAllClients("Message", winningTeam.Name .. " wins the round!")
		print("[ROUND END] Winner: " .. winningTeam.Name)
	end

	REMOTES.RoundInfo:FireAllClients("Message", "Score: " .. teamAScore .. " - " .. teamBScore)

	if teamAScore >= ROUNDS_TO_WIN or teamBScore >= ROUNDS_TO_WIN or currentRound == MAX_ROUNDS then
		EndMatch()
	else
		wait(ROUND_END_TIME)
		StartRound()
	end
end

function EndMatch()
	local winner = "Draw"
	if teamAScore > teamBScore then
		winner = teamA.Name .. " Wins"
	elseif teamBScore > teamAScore then
		winner = teamB.Name .. " Wins"
	end

	REMOTES.RoundInfo:FireAllClients("Message", "GAME OVER: " .. winner)
	print("[MATCH END] Final Score: " .. teamAScore .. " - " .. teamBScore)

	wait(15)

	if HUB_PLACE_ID ~= 0 then
		local playersToTeleport = Players:GetPlayers()
		if #playersToTeleport > 0 then
			-- Wrap in pcall to prevent script breaking if teleport fails
			pcall(function()
				TeleportService:TeleportPartyAsync(HUB_PLACE_ID, playersToTeleport)
			end)
		end
	else
		warn("[TELEPORT] HUB_PLACE_ID is 0. Not teleporting.")
	end
end


local function AssignTeams()
	if teamAssignmentsLocked then
		print("--- TEAMS ALREADY ASSIGNED - SKIPPING ---")
		return
	end

	print("--- ASSIGNING TEAMS (PERMANENT) ---")
	local players = Players:GetPlayers()
	local squads = {}

	-- 1. Group players by Squad Name
	for _, player in pairs(players) do
		local squadName = player:GetAttribute("SquadName") or "NoSquad"

		if not squads[squadName] then
			squads[squadName] = {}
		end
		table.insert(squads[squadName], player)
	end

	-- 2. Convert to list
	local squadList = {}
	for squadName, squadPlayers in pairs(squads) do
		table.insert(squadList, {Name = squadName, Players = squadPlayers})
	end

	-- 3. Sort Alphabetically (A-Z)
	table.sort(squadList, function(a, b)
		return a.Name < b.Name
	end)

	-- 4. Assign Teams PERMANENTLY with spawn points
	if squadList[1] then
		print("Team A assigned to Squad: " .. squadList[1].Name .. " (" .. #squadList[1].Players .. " players)")
		local teamASpawn = TEAM_A_SPAWNS[1] -- Use first spawn (e.g., BlueSpawn1)

		for _, player in pairs(squadList[1].Players) do
			player.Team = teamA
			playerSpawnPoints[player.UserId] = teamASpawn -- USE USERID AS KEY
			print("  - " .. player.Name .. " assigned to Team A at " .. teamASpawn.Name)
		end
	end

	if squadList[2] then
		print("Team B assigned to Squad: " .. squadList[2].Name .. " (" .. #squadList[2].Players .. " players)")
		local teamBSpawn = TEAM_B_SPAWNS[1] -- Use first spawn (e.g., RedSpawn1)

		for _, player in pairs(squadList[2].Players) do
			player.Team = teamB
			playerSpawnPoints[player.UserId] = teamBSpawn -- USE USERID AS KEY
			print("  - " .. player.Name .. " assigned to Team B at " .. teamBSpawn.Name)
		end
	end

	-- Handle extra squads (Spectators or overflow) if necessary
	if #squadList > 2 then
		warn("More than 2 squads detected! Extra players not assigned a team.")
	end

	teamAssignmentsLocked = true
	print("--- TEAMS LOCKED - NO FURTHER CHANGES ALLOWED ---")
	-- DEBUG: Print what's in the spawn points table
	print("[DEBUG] playerSpawnPoints table contents (after assignment):")
	for userId, spawnPart in pairs(playerSpawnPoints) do
		print("  UserId: " .. tostring(userId) .. " → " .. spawnPart.Name)
	end
end


-- This function handles players who join AFTER teams have been locked
local function AssignPlayerTeam(player)
	if teamAssignmentsLocked then
		warn("[LATE JOIN] " .. player.Name .. " joined after teams locked - assigning to smallest team.")

		-- Count team sizes
		local teamACount = 0
		local teamBCount = 0
		for _, p in pairs(Players:GetPlayers()) do
			if p.Team == teamA then
				teamACount = teamACount + 1
			elseif p.Team == teamB then
				teamBCount = teamBCount + 1
			end
		end

		-- Assign to smaller team
		if teamACount <= teamBCount then
			player.Team = teamA
			playerSpawnPoints[player] = TEAM_A_SPAWNS[math.random(1, #TEAM_A_SPAWNS)]
			print(player.Name .. " assigned to Team A (LATE JOIN)")
		else
			player.Team = teamB
			playerSpawnPoints[player] = TEAM_B_SPAWNS[math.random(1, #TEAM_B_SPAWNS)]
			print(player.Name .. " assigned to Team B (LATE JOIN)")
		end
	end
end



function StartRound()
	isRoundInProgress = true
	currentRound = currentRound + 1
	print("--- STARTING ROUND " .. currentRound .. " ---")
	-- ... (rest of round start logic) ...

	REMOTES.RoundInfo:FireAllClients("Message", "Round " .. currentRound .. " - Fight!")

	-- Spawn all players ONE BY ONE to ensure proper loading
	for _, player in pairs(Players:GetPlayers()) do
		spawn(function()
			-- [FIX] Reset camera mode so they stop spectating
			REMOTES.Camera:FireClient(player, "Mode", "Default")

			if player.Character then
				player.Character:Destroy()
			end

			-- Load character and wait for it
			player:LoadCharacter()
			local character = player.Character or player.CharacterAdded:Wait()

			-- Wait for character to fully load
			character:WaitForChild("HumanoidRootPart", 5)

			-- Now spawn them
			SpawnPlayer(player)
		end)
	end

	-- Wait for all spawns to complete
	wait(2)

	wait(STORM_START_DELAY)
	if isRoundInProgress then
		STORM_SCRIPT.RunSequence:Fire()
	end
end

--- MAIN GAME LOOP START ---

-- Replace your ENTIRE Players.PlayerAdded function
Players.PlayerAdded:Connect(function(player)
	print("[JOIN] " .. player.Name .. " connected.")

	-- Handle Teleport Data vs Studio Testing
	local joinData = player:GetJoinData()
	local squadName = joinData.TeleportData

	if RunService:IsStudio() and not squadName then
		squadName = "StudioSquad_" .. (player.UserId % 2) 
		print("[DEBUG] Assigned Fake Studio Squad: " .. squadName)
	end

	player:SetAttribute("SquadName", squadName)

	-- We do NOT call AssignPlayerTeam here anymore, 
	-- let the initial AssignTeams handle everyone.

	player.CharacterAdded:Connect(function(character)
		local humanoid = character:WaitForChild("Humanoid")

		-- Connect Death Event for Round Logic
		humanoid.Died:Connect(function()
			if isRoundInProgress and playersInRound[player] then
				OnPlayerDied(player)
			end
		end)

		-- Don't auto-spawn here - let StartRound() handle it
	end)
end)

-- Wait loop
while #Players:GetPlayers() < 2 do
	REMOTES.RoundInfo:FireAllClients("Message", "Waiting for players to load...")
	wait(0.5)
end

print("Players found. Waiting 2 seconds to stabilize...")
wait(2)

-- Assign teams BEFORE loading characters
AssignTeams()

-- Now start the round (which will load characters and spawn them)
StartRound()