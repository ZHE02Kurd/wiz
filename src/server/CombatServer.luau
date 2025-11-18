--[[
    Name: CombatServer.luau
    Author: Magica Development Team
    Date: 2025-11-18
    Location: ServerScriptService/CombatServer
    Affects: SpellModule.luau, PlayerDataModule.luau, all combat systems
    
    Description: This server-side script handles all combat-related RemoteEvent
    requests from clients. When a client wants to cast a spell or use an ability,
    this script receives the request, validates it (SECURITY!), and then calls
    the appropriate module functions. This is the "gatekeeper" for all combat actions.
]]--

-- Services
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Modules
local PlayerDataModule = require(ReplicatedStorage.Shared.Modules.PlayerDataModule)
local SpellModule = require(ReplicatedStorage.Shared.Modules.SpellModule)

-- Remotes
local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local CastSpellRemote = Remotes:WaitForChild("CastSpellCS")
local UseAbilityRemote = Remotes:WaitForChild("UseAbilityCS")

-- ========================================
-- SPELL CASTING HANDLER
-- ========================================
CastSpellRemote.OnServerEvent:Connect(function(player, targetPosition)
	print("[CombatServer] 🎯 ========================================")
	print("[CombatServer] 🎯 CAST SPELL REQUEST")
	print("[CombatServer] 🎯 Player: " .. (player and player.DisplayName or "nil"))
	print("[CombatServer] 🎯 Target: " .. tostring(targetPosition))
	print("[CombatServer] 🎯 ========================================")
	
	-- SECURITY: Validate the player
	if not player or not player.Parent then
		warn("[CombatServer] ❌ SECURITY: Invalid player object")
		return
	end
	print("[CombatServer] ✅ Player validation passed")
	
	-- SECURITY: Validate target position
	if typeof(targetPosition) ~= "Vector3" then
		warn("[CombatServer] ❌ SECURITY: Invalid target position type: " .. typeof(targetPosition))
		return
	end
	print("[CombatServer] ✅ Target position validation passed")
	
	-- SECURITY: Check if player is in a match
	local data = PlayerDataModule:GetPlayerData(player)
	if not data then
		warn("[CombatServer] ❌ No player data found")
		return
	end
	print("[CombatServer] ✅ Player data found")
	
	if not data.isInMatch then
		warn("[CombatServer] ❌ SECURITY: Player not in match - isInMatch = false")
		return
	end
	print("[CombatServer] ✅ Player is in match")
	
	-- SECURITY: Check if player is alive
	if data.health <= 0 then
		warn("[CombatServer] ❌ SECURITY: Player is dead - Health: " .. data.health)
		return
	end
	print("[CombatServer] ✅ Player is alive - Health: " .. data.health .. " / " .. data.maxHealth)
	
	-- SECURITY: Check if player is stunned
	if data.isStunned then
		warn("[CombatServer] ❌ SECURITY: Player is stunned - cannot cast")
		return
	end
	print("[CombatServer] ✅ Player is not stunned")
	
	-- SECURITY: Anti-exploit - limit target distance
	local character = player.Character
	if character then
		local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
		if humanoidRootPart then
			local distance = (targetPosition - humanoidRootPart.Position).Magnitude
			print("[CombatServer] 📏 Distance check: " .. math.floor(distance) .. " studs (Max: 500)")
			if distance > 500 then -- Reasonable max aim distance
				warn("[CombatServer] ❌ SECURITY: Target too far! Distance: " .. math.floor(distance) .. " > 500 studs")
				warn("[CombatServer] ⚠️ POSSIBLE EXPLOIT ATTEMPT by " .. player.DisplayName)
				return
			end
			print("[CombatServer] ✅ Distance validation passed")
		end
	end
	
	-- All checks passed, cast the spell!
	print("[CombatServer] ✅ All validations passed - forwarding to SpellModule")
	SpellModule:CastSpell(player, targetPosition)
	print("[CombatServer] ========================================")
end)

-- ========================================
-- ABILITY USAGE HANDLER
-- ========================================
UseAbilityRemote.OnServerEvent:Connect(function(player)
	-- SECURITY: Validate the player
	if not player or not player.Parent then
		warn("⚠️ Invalid player tried to use ability")
		return
	end
	
	-- SECURITY: Check if player is in a match
	local data = PlayerDataModule:GetPlayerData(player)
	if not data or not data.isInMatch then
		warn("⚠️ " .. player.DisplayName .. " tried to use ability outside of match")
		return
	end
	
	-- SECURITY: Check if player is alive
	if data.health <= 0 then
		warn("⚠️ " .. player.DisplayName .. " tried to use ability while dead")
		return
	end
	
	-- SECURITY: Check if player is stunned
	if data.isStunned then
		warn("⚠️ " .. player.DisplayName .. " tried to use ability while stunned")
		return
	end
	
	-- SECURITY: Check if ability is on cooldown
	if not data.abilityCooldownReady then
		warn("⚠️ " .. player.DisplayName .. "'s ability is on cooldown")
		return
	end
	
	-- TODO: Implement hero abilities
	-- For now, just print a message
	print("⚡ " .. player.DisplayName .. " used their " .. data.selectedHero .. " ability!")
	
	-- Set cooldown (example: 20 seconds)
	data.abilityCooldownReady = false
	data.abilityLastCastTime = tick()
	
	task.delay(20, function()
		if data then
			data.abilityCooldownReady = true
		end
	end)
end)

print("✅ CombatServer initialized!")
