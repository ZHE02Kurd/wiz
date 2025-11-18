# 🐛 DEBUG OUTPUT REQUIREMENTS FOR MAGICA

This document specifies the **comprehensive debug output** that must be added to **EVERY module** to make the game "debug friendly" and easy to troubleshoot.

---

## 📋 DEBUG OUTPUT PRINCIPLES

Every function MUST follow these rules:

### 1. **Function Entry Logging**
```luau
print("[ModuleName] 🔧 FunctionName called - Param1: value1 | Param2: value2")
```

### 2. **State Change Logging**
```luau
print("[ModuleName] OldValue → NewValue")
```

### 3. **Success/Failure Logging**
```luau
print("[ModuleName] ✅ Operation completed successfully")
warn("[ModuleName] ❌ Operation failed - Reason: XYZ")
```

### 4. **Data Structure Logging**
```luau
print("[ModuleName] 📊 Current data state:")
print("  - Field1: value1")
print("  - Field2: value2")
```

### 5. **Error Validation Logging**
```luau
if not valid then
	warn("[ModuleName] ⚠️ Validation failed - Expected X, got Y")
	return
end
print("[ModuleName] ✅ Validation passed")
```

---

## 🗂️ MODULE-BY-MODULE DEBUG REQUIREMENTS

### **PlayerDataModule.luau** ✅ PARTIALLY COMPLETE

**Status:** Basic debug added, needs completion

**Still Needs:**
- `Heal()` function - log old/new health, healing amount, overheal protection
- `ResetMatchData()` - log all fields being reset
- `GetPlayerData()` - log whether data found or not
- `RemovePlayerData()` - confirm removal

**Example for Heal():**
```luau
function PlayerDataModule:Heal(player, healAmount)
	print("[PlayerData] ⚕️ Heal called - Player: " .. player.DisplayName .. " | Amount: " .. healAmount)
	local data = self:GetPlayerData(player)
	if not data then 
		warn("[PlayerData] ❌ No player data found")
		return 
	end
	
	local oldHealth = data.health
	data.health = math.min(data.health + healAmount, data.maxHealth)
	local actualHealing = data.health - oldHealth
	
	print("[PlayerData] ❤️ Health changed: " .. math.floor(oldHealth) .. " → " .. math.floor(data.health))
	print("[PlayerData] ⚕️ Healed " .. math.floor(actualHealing) .. " HP (requested " .. healAmount .. ")")
	
	if actualHealing < healAmount then
		print("[PlayerData] ℹ️ Overhealing prevented - capped at max health " .. data.maxHealth)
	end
end
```

---

### **GameManagerServer.luau** ⚠️ NEEDS COMPLETE OVERHAUL

**Current Status:** Minimal debug output

**Required Debug Output:**

#### `Initialize()`
```luau
function GameManagerServer:Initialize()
	print("[GameManager] 🚀 ========================================")
	print("[GameManager] 🚀 INITIALIZING GAME MANAGER")
	print("[GameManager] 🚀 ========================================")
	
	-- Map loading
	print("[GameManager] 🗺️ Loading map references...")
	LobbySpawnLocation = Workspace:FindFirstChild("LobbySpawn")
	if LobbySpawnLocation then
		print("[GameManager] ✅ LobbySpawn found at position: " .. tostring(LobbySpawnLocation.Position))
	else
		warn("[GameManager] ❌ LobbySpawn NOT FOUND in Workspace!")
	end
	
	ArenaFolder = Workspace:FindFirstChild("Arena")
	if ArenaFolder then
		print("[GameManager] ✅ Arena folder found")
	else
		warn("[GameManager] ❌ Arena folder NOT FOUND in Workspace!")
	end
	
	-- ... continue for all map references
end
```

#### `AddPlayerToQueue()`
```luau
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
	local data = PlayerDataModule:GetPlayerData(player)
	if data then
		data.isInQueue = true
		print("[GameManager] ✅ Set isInQueue = true for " .. player.DisplayName)
	end
	
	print("[GameManager] ➕ " .. player.DisplayName .. " added to queue")
	print("[GameManager] 📊 Queue size: " .. #queuedPlayers .. " / " .. GameConstants.MIN_PLAYERS .. " (min required)")
	
	-- List all queued players
	print("[GameManager] 👥 Players in queue:")
	for i, p in ipairs(queuedPlayers) do
		print("  " .. i .. ". " .. p.DisplayName)
	end
end
```

#### `StartMatch()`
```luau
function GameManagerServer:StartMatch()
	print("[GameManager] 🚀 ========================================")
	print("[GameManager] 🚀 START MATCH CALLED")
	print("[GameManager] 🚀 ========================================")
	
	if currentState == GameState.MATCH_IN_PROGRESS then
		warn("[GameManager] ❌ Match already in progress - cannot start new match")
		return
	end
	
	local queueSize = #queuedPlayers
	print("[GameManager] 📊 Queue size: " .. queueSize .. " | Min required: " .. GameConstants.MIN_PLAYERS)
	
	if queueSize < GameConstants.MIN_PLAYERS then
		warn("[GameManager] ❌ Not enough players to start match")
		print("[GameManager] ℹ️ Need " .. GameConstants.MIN_PLAYERS .. " players, have " .. queueSize)
		return
	end
	
	print("[GameManager] ✅ Sufficient players - proceeding with match start")
	
	-- Change game state
	local oldState = currentState
	currentState = GameState.MATCH_IN_PROGRESS
	stateTimer = GameConstants.MATCH_DURATION
	print("[GameManager] 🎮 Game state changed: " .. oldState .. " → " .. currentState)
	print("[GameManager] ⏱️ Match duration: " .. stateTimer .. " seconds")
	
	-- Move players from queue to match
	print("[GameManager] 🔄 Moving players from queue to match...")
	playersInMatch = {}
	local playerCount = 0
	for _, player in ipairs(queuedPlayers) do
		table.insert(playersInMatch, player)
		playerCount = playerCount + 1
		
		-- Reset player data for match
		print("[GameManager] 🔄 Preparing player: " .. player.DisplayName)
		PlayerDataModule:ResetMatchData(player)
		
		local data = PlayerDataModule:GetPlayerData(player)
		if data then
			data.isInQueue = false
			data.isInMatch = true
			print("[GameManager] ✅ Set isInMatch = true for " .. player.DisplayName)
		end
	end
	print("[GameManager] 👥 Total players in match: " .. playerCount)
	
	-- Spawn players
	print("[GameManager] 📍 Spawning players in arena...")
	self:SpawnPlayersInArena(playersInMatch)
	
	-- Clear queue
	queuedPlayers = {}
	print("[GameManager] ✅ Queue cleared")
	
	print("[GameManager] 🎮 ========================================")
	print("[GameManager] 🎮 MATCH STARTED SUCCESSFULLY!")
	print("[GameManager] 🎮 ========================================")
end
```

#### `PlayerEliminated()`
```luau
function GameManagerServer:PlayerEliminated(player)
	print("[GameManager] 💀 ========================================")
	print("[GameManager] 💀 PLAYER ELIMINATION")
	print("[GameManager] 💀 Player: " .. player.DisplayName)
	print("[GameManager] 💀 ========================================")
	
	-- Find player in match
	local playerIndex = nil
	for i, matchPlayer in ipairs(playersInMatch) do
		if matchPlayer == player then
			playerIndex = i
			break
		end
	end
	
	if not playerIndex then
		warn("[GameManager] ⚠️ Player " .. player.DisplayName .. " not found in active match - ignoring elimination")
		return
	end
	
	-- Calculate placement
	local placement = #playersInMatch
	print("[GameManager] 📊 Placement: #" .. placement .. " out of " .. placement)
	
	-- Update player data
	local data = PlayerDataModule:GetPlayerData(player)
	if data then
		data.isInMatch = false
		data.placement = placement
		print("[GameManager] ✅ Updated player data - isInMatch = false, placement = " .. placement)
	else
		warn("[GameManager] ⚠️ No player data found for " .. player.DisplayName)
	end
	
	-- Remove from match
	table.remove(playersInMatch, playerIndex)
	local remainingCount = #playersInMatch
	print("[GameManager] 👥 Players removed from match - Remaining: " .. remainingCount)
	
	-- Teleport to lobby
	print("[GameManager] 🏠 Teleporting " .. player.DisplayName .. " to lobby...")
	self:SpawnPlayerInLobby(player)
	
	-- Check for match end
	if remainingCount <= 1 then
		print("[GameManager] 🏆 Only " .. remainingCount .. " player(s) remaining - ending match")
		self:EndMatch()
	else
		print("[GameManager] ℹ️ Match continues with " .. remainingCount .. " players")
	end
	
	print("[GameManager] 💀 ========================================")
end
```

#### `Game Loop (every tick)`
```luau
-- In the while true loop:
while true do
	task.wait(1)
	
	if currentState == GameState.INTERMISSION then
		stateTimer = stateTimer - 1
		
		-- Log every 10 seconds
		if stateTimer % 10 == 0 then
			print("[GameManager] ⏱️ INTERMISSION - Time: " .. stateTimer .. "s | Queue: " .. #queuedPlayers .. " players")
		end
		
		if stateTimer <= 0 then
			print("[GameManager] ⏰ Intermission timer expired - attempting to start match")
			self:StartMatch()
		else
			if #queuedPlayers >= GameConstants.MIN_PLAYERS and stateTimer > 10 then
				print("[GameManager] ⚡ Fast-start triggered - queue full (" .. #queuedPlayers .. " players)")
				stateTimer = 10
			end
		end
		
	elseif currentState == GameState.MATCH_IN_PROGRESS then
		stateTimer = stateTimer - 1
		
		-- Log every 30 seconds
		if stateTimer % 30 == 0 then
			print("[GameManager] ⏱️ MATCH - Time: " .. stateTimer .. "s | Players: " .. #playersInMatch)
		end
		
		-- Warnings at specific times
		if stateTimer == 60 then
			print("[GameManager] ⚠️ 1 MINUTE REMAINING!")
		elseif stateTimer == 30 then
			print("[GameManager] ⚠️ 30 SECONDS REMAINING!")
		elseif stateTimer == 10 then
			print("[GameManager] ⚠️ 10 SECONDS REMAINING!")
		end
		
		if stateTimer <= 0 then
			print("[GameManager] ⏰ Match timer expired - ending match")
			self:EndMatch()
		end
	end
end
```

---

### **SpellModule.luau** ⚠️ NEEDS COMPREHENSIVE DEBUG

**Required Debug Output:**

#### `CastSpell()`
```luau
function SpellModule.CastSpell(caster, spellName, targetPosition)
	print("[SpellModule] 🔮 ========================================")
	print("[SpellModule] 🔮 CAST SPELL")
	print("[SpellModule] 🔮 Caster: " .. caster.DisplayName .. " (UserId: " .. caster.UserId .. ")")
	print("[SpellModule] 🔮 Spell: " .. spellName)
	print("[SpellModule] 🔮 Target Position: " .. tostring(targetPosition))
	print("[SpellModule] 🔮 ========================================")
	
	-- Cooldown check
	local currentTime = tick()
	if spellCooldowns[caster.UserId] and spellCooldowns[caster.UserId] > currentTime then
		local cooldownRemaining = spellCooldowns[caster.UserId] - currentTime
		warn("[SpellModule] ⏱️ Spell on cooldown - Remaining: " .. string.format("%.2f", cooldownRemaining) .. "s")
		return
	end
	print("[SpellModule] ✅ Cooldown check passed")
	
	-- Spell data lookup
	local spell = SpellData.Spells[spellName]
	if not spell then
		warn("[SpellModule] ❌ Spell not found in SpellData: " .. spellName)
		return
	end
	print("[SpellModule] ✅ Spell found in database")
	print("[SpellModule] 📊 Spell stats:")
	print("  - Damage: " .. spell.damage)
	print("  - Speed: " .. spell.projectileSpeed)
	print("  - Cooldown: " .. spell.cooldown .. "s")
	print("  - Pierce: " .. spell.pierce)
	
	-- Character check
	local character = caster.Character
	if not character or not character:FindFirstChild("HumanoidRootPart") then
		warn("[SpellModule] ❌ Character or HumanoidRootPart not found")
		return
	end
	print("[SpellModule] ✅ Character found")
	
	-- Create projectile
	local startPosition = character.HumanoidRootPart.Position + Vector3.new(0, 2, 0)
	print("[SpellModule] 🎯 Creating projectile at: " .. tostring(startPosition))
	
	local projectile = createProjectile(spell, startPosition, targetPosition, caster)
	projectile.Parent = workspace
	print("[SpellModule] ✅ Projectile created and added to workspace")
	
	-- Start movement
	print("[SpellModule] 🚀 Starting projectile movement...")
	moveProjectile(projectile, spell, caster, targetPosition)
	
	-- Set cooldown
	spellCooldowns[caster.UserId] = currentTime + spell.cooldown
	print("[SpellModule] ⏱️ Cooldown set - Ready at: " .. string.format("%.2f", spellCooldowns[caster.UserId]))
	
	print("[SpellModule] ✅ Spell cast complete")
end
```

#### `moveProjectile()` - Collision Detection
```luau
-- Inside the Heartbeat loop:
if hit and hitHumanoid then
	local hitPlayer = game.Players:GetPlayerFromCharacter(hit.Parent)
	if hitPlayer and hitPlayer ~= caster then
		print("[SpellModule] 💥 ========================================")
		print("[SpellModule] 💥 HIT DETECTED!")
		print("[SpellModule] 💥 Caster: " .. caster.DisplayName)
		print("[SpellModule] 💥 Target: " .. hitPlayer.DisplayName)
		print("[SpellModule] 💥 Spell: " .. spell.name)
		print("[SpellModule] 💥 Hit Position: " .. tostring(hitResult.Position))
		print("[SpellModule] 💥 ========================================")
		
		-- Calculate damage
		local damage = calculateDamage(caster, spell)
		print("[SpellModule] 📊 Calculated Damage: " .. damage)
		
		-- Apply damage
		local isDead = PlayerDataModule.ApplyDamage(hitPlayer, damage, caster)
		if isDead then
			print("[SpellModule] 💀 TARGET KILLED: " .. hitPlayer.DisplayName)
		else
			print("[SpellModule] ✅ Damage applied to " .. hitPlayer.DisplayName)
		end
		
		-- Apply effects
		if spell.effects then
			print("[SpellModule] ✨ Applying spell effects...")
			ApplySpellEffect(spell, hitPlayer)
		end
		
		-- Pierce handling
		hitsRemaining = hitsRemaining - 1
		print("[SpellModule] 🎯 Hits remaining: " .. hitsRemaining .. " / " .. spell.pierce)
		
		if hitsRemaining <= 0 then
			print("[SpellModule] 💨 Projectile exhausted - destroying")
			projectile:Destroy()
			connection:Disconnect()
			return
		end
	end
end
```

---

### **CombatServer.luau** ⚠️ NEEDS COMPREHENSIVE DEBUG

**Required Debug Output:**

#### `CastSpellCS RemoteEvent Handler`
```luau
CastSpellRemote.OnServerEvent:Connect(function(player, targetPosition)
	print("[CombatServer] 🎯 ========================================")
	print("[CombatServer] 🎯 CAST SPELL REQUEST")
	print("[CombatServer] 🎯 Player: " .. player.DisplayName)
	print("[CombatServer] 🎯 Target: " .. tostring(targetPosition))
	print("[CombatServer] 🎯 ========================================")
	
	-- Validate player
	if not player or not player.Parent then
		warn("[CombatServer] ❌ Invalid player object")
		return
	end
	print("[CombatServer] ✅ Player validation passed")
	
	-- Validate target position
	if typeof(targetPosition) ~= "Vector3" then
		warn("[CombatServer] ❌ Invalid target position type: " .. typeof(targetPosition))
		return
	end
	print("[CombatServer] ✅ Target position validation passed")
	
	-- Get player data
	local data = PlayerDataModule:GetPlayerData(player)
	if not data then
		warn("[CombatServer] ❌ No player data found")
		return
	end
	print("[CombatServer] ✅ Player data found")
	
	-- Check if in match
	if not data.isInMatch then
		warn("[CombatServer] ❌ Player not in match - isInMatch = false")
		return
	end
	print("[CombatServer] ✅ Player is in match")
	
	-- Check if alive
	if data.health <= 0 then
		warn("[CombatServer] ❌ Player is dead - Health: " .. data.health)
		return
	end
	print("[CombatServer] ✅ Player is alive - Health: " .. data.health .. " / " .. data.maxHealth)
	
	-- Check if stunned
	if data.isStunned then
		warn("[CombatServer] ❌ Player is stunned - cannot cast")
		return
	end
	print("[CombatServer] ✅ Player is not stunned")
	
	-- Distance check (anti-exploit)
	local character = player.Character
	if character and character:FindFirstChild("HumanoidRootPart") then
		local distance = (character.HumanoidRootPart.Position - targetPosition).Magnitude
		print("[CombatServer] 📏 Distance check: " .. math.floor(distance) .. " studs (Max: 500)")
		if distance > 500 then
			warn("[CombatServer] ❌ TARGET TOO FAR! Distance: " .. math.floor(distance) .. " > 500 studs")
			warn("[CombatServer] ⚠️ POSSIBLE EXPLOIT ATTEMPT by " .. player.DisplayName)
			return
		end
		print("[CombatServer] ✅ Distance validation passed")
	end
	
	print("[CombatServer] ✅ All validations passed - forwarding to SpellModule")
	SpellModule.CastSpell(player, data.currentSpell, targetPosition)
	print("[CombatServer] ========================================")
end)
```

---

### **LevelUpServer.luau** ⚠️ NEEDS COMPREHENSIVE DEBUG

**Required Debug Output:**

#### `HandlePlayerLevelUp()`
```luau
function HandlePlayerLevelUp(player)
	print("[LevelUpServer] ⭐ ========================================")
	print("[LevelUpServer] ⭐ PLAYER LEVEL UP!")
	print("[LevelUpServer] ⭐ Player: " .. player.DisplayName)
	print("[LevelUpServer] ⭐ ========================================")
	
	local data = PlayerDataModule:GetPlayerData(player)
	if not data then 
		warn("[LevelUpServer] ❌ No player data found")
		return 
	end
	
	local currentLevel = data.level
	print("[LevelUpServer] 📊 Current Level: " .. currentLevel)
	
	local choices = {}
	
	-- Determine choice type
	if currentLevel % 2 == 0 then
		print("[LevelUpServer] 🔮 Even level - offering ELEMENT choices")
		choices = {
			{type = "Element", name = "Fire", description = "Add Fire to your spell"},
			{type = "Element", name = "Water", description = "Add Water to your spell"},
			{type = "Element", name = "Earth", description = "Add Earth to your spell"}
		}
	else
		if currentLevel == 10 then
			print("[LevelUpServer] 👑 Level 10 - offering ULTIMATE BUFF choices")
			local buffChoices = BuffData:GetRandomBuffChoices(true)
			-- Convert to full format...
		else
			print("[LevelUpServer] 💪 Odd level - offering REGULAR BUFF choices")
			local buffChoices = BuffData:GetRandomBuffChoices(false)
			-- Convert to full format...
		end
	end
	
	print("[LevelUpServer] 📋 Choices offered:")
	for i, choice in ipairs(choices) do
		print("  " .. i .. ". [" .. choice.type .. "] " .. choice.name)
	end
	
	-- Send to client
	print("[LevelUpServer] 📡 Sending choices to client...")
	LevelUpChoiceSCRemote:FireClient(player, choices)
	print("[LevelUpServer] ✅ Level-up handling complete")
	print("[LevelUpServer] ========================================")
end
```

#### `LevelUpChoiceCS RemoteEvent Handler`
```luau
LevelUpChoiceCSRemote.OnServerEvent:Connect(function(player, choiceType, choice)
	print("[LevelUpServer] 🎯 ========================================")
	print("[LevelUpServer] 🎯 LEVEL-UP CHOICE RECEIVED")
	print("[LevelUpServer] 🎯 Player: " .. player.DisplayName)
	print("[LevelUpServer] 🎯 Choice Type: " .. choiceType)
	print("[LevelUpServer] 🎯 Choice: " .. choice)
	print("[LevelUpServer] 🎯 ========================================")
	
	-- Validate player
	local data = PlayerDataModule:GetPlayerData(player)
	if not data then
		warn("[LevelUpServer] ❌ No player data found")
		return
	end
	
	if not data.isInMatch then
		warn("[LevelUpServer] ❌ Player not in match")
		return
	end
	
	-- Process choice
	if choiceType == "Element" then
		print("[LevelUpServer] 🔮 Processing ELEMENT choice: " .. choice)
		if choice == "Fire" or choice == "Water" or choice == "Earth" then
			PlayerDataModule:AddElement(player, choice)
			print("[LevelUpServer] ✅ Element added successfully")
		else
			warn("[LevelUpServer] ❌ Invalid element: " .. choice)
		end
		
	elseif choiceType == "Buff" then
		print("[LevelUpServer] 💪 Processing BUFF choice: " .. choice)
		local buffInfo = BuffData[choice]
		if buffInfo then
			PlayerDataModule:AddBuff(player, choice)
			print("[LevelUpServer] ✅ Buff added successfully")
		else
			warn("[LevelUpServer] ❌ Invalid buff: " .. choice)
		end
		
	else
		warn("[LevelUpServer] ❌ Invalid choice type: " .. choiceType)
	end
	
	print("[LevelUpServer] ========================================")
end)
```

---

### **CombatClient.luau** ⚠️ NEEDS DEBUG OUTPUT

**Required Debug Output:**

#### `castSpell()`
```luau
local function castSpell()
	print("[CombatClient] 🔮 castSpell function called")
	local character = player.Character
	if not character then
		warn("[CombatClient] ❌ No character found - cannot cast spell")
		return
	end
	
	-- Get target position
	local mouseLocation = UserInputService:GetMouseLocation()
	local ray = camera:ViewportPointToRay(mouseLocation.X, mouseLocation.Y)
	local targetPosition = ray.Origin + ray.Direction * 100
	print("[CombatClient] 🎯 Spell target calculated: " .. tostring(targetPosition))
	
	print("[CombatClient] 📡 Firing CastSpellCS to server...")
	CastSpellRemote:FireServer("CurrentSpell", targetPosition)
	print("[CombatClient] ✅ Request sent")
end
```

#### `Joystick Touch Handler`
```luau
joystickKnob.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.Touch then
		print("[CombatClient] 📱 Joystick touch began at " .. tostring(input.Position))
		isTouchingJoystick = true
		touchStartPosition = input.Position
	end
end)

joystickKnob.InputEnded:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.Touch then
		print("[CombatClient] 📱 Joystick touch ended")
		isTouchingJoystick = false
		-- Reset joystick visual
	end
end)
```

#### `Movement Loop (every 2 seconds)`
```luau
local lastDebugTime = 0
RunService.RenderStepped:Connect(function()
	local currentTime = tick()
	local shouldDebug = (currentTime - lastDebugTime) > 2
	
	-- ... movement calculation code ...
	
	if moveDirection.Magnitude > 0 and shouldDebug then
		print("[CombatClient] 🏃 Moving - Direction: " .. tostring(worldMoveDirection))
		print("[CombatClient] 📊 Keys pressed: W=" .. tostring(keysPressed.W) .. " A=" .. tostring(keysPressed.A) .. " S=" .. tostring(keysPressed.S) .. " D=" .. tostring(keysPressed.D))
		lastDebugTime = currentTime
	end
end)
```

---

## 🎯 IMPLEMENTATION CHECKLIST

Apply debug output to these files in this order:

- [x] **PlayerDataModule.luau** - PARTIALLY DONE (Complete remaining functions)
- [ ] **GameManagerServer.luau** - CRITICAL (Add all debug as specified above)
- [ ] **SpellModule.luau** - HIGH PRIORITY (Collision detection needs detailed logs)
- [ ] **CombatServer.luau** - HIGH PRIORITY (Security validation needs logs)
- [ ] **LevelUpServer.luau** - MEDIUM PRIORITY
- [ ] **CombatClient.luau** - LOW PRIORITY (Client-side is less critical)

---

## 💡 TESTING THE DEBUG OUTPUT

Once implemented, you should see output like this in Roblox Studio Output window:

```
[GameManager] 🚀 ========================================
[GameManager] 🚀 INITIALIZING GAME MANAGER
[GameManager] 🚀 ========================================
[GameManager] 🗺️ Loading map references...
[GameManager] ✅ LobbySpawn found at position: 0, 10, 0
[GameManager] ✅ Arena folder found
[GameManager] ✅ Arena/SpawnPoints found with 20 spawn points
[PlayerData] 🔧 CreatePlayerData called for Player1 (UserId: 123456)
[PlayerData] ✅ Created player data for Player1
[PlayerData] 📊 Initial data structure:
  - Health: 1000 / 1000
  - Level: 1 | XP: 0
  - SpellCore:  (empty if new)
  - CurrentSpell: MagicMissile
  - Movement Speed: 16
[GameManager] 🎮 AddPlayerToQueue called for Player1 (UserId: 123456)
[GameManager] ✅ Set isInQueue = true for Player1
[GameManager] ➕ Player1 added to queue
[GameManager] 📊 Queue size: 1 / 4 (min required)
```

This makes debugging **incredibly easy** because you can see:
- **What function was called**
- **With what parameters**
- **What the result was**
- **Where it failed (if it failed)**

---

## 🚨 CRITICAL AREAS FOR DEBUG OUTPUT

These areas cause the most bugs and MUST have detailed logging:

1. **Player State Transitions** (joining, queueing, in match, dead)
2. **Spell Casting & Collision** (every hit/miss needs a log)
3. **Level-Up Choices** (what was offered, what was chosen)
4. **Game State Changes** (Intermission → Match, timer updates)
5. **Data Validation** (every security check, every nil check)

---

🎯 **GOAL:** Every time something doesn't work, you can look at the Output window and immediately see EXACTLY where and why it failed, with NO guesswork!
