--[[
    Name: SpellModule.luau
    Author: Magica Development Team
    Date: 2025-11-18
    Location: ReplicatedStorage/Modules/SpellModule
    Affects: CombatServer.luau, CombatClient.luau, all spell casting logic
    
    Description: This module handles ALL spell casting logic. When a player casts
    a spell, this module creates the projectile, calculates damage with buffs,
    applies special effects (burn, slow, siphon, etc.), and handles all spell behavior.
    This is the "spell engine" of the entire game.
]]--

-- Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Debris = game:GetService("Debris")

-- Modules
local SharedFolder = ReplicatedStorage:WaitForChild("Shared")
local DataFolder = SharedFolder:WaitForChild("Data")
local ModulesFolder = SharedFolder:WaitForChild("Modules")

-- Safely require SpellData: prefer FindFirstChild to avoid yielding, then pcall to catch require errors.
local _SpellData
local spellDataInstance = DataFolder:FindFirstChild("SpellData")
if spellDataInstance then
	local ok, module = pcall(require, spellDataInstance)
	if ok and module then
		_SpellData = module
	else
		warn("[SpellModule] ⚠️ Failed to require SpellData module; using fallback empty table.")
		_SpellData = {}
	end
else
	warn("[SpellModule] ⚠️ SpellData ModuleScript not found in ReplicatedStorage.Shared.Data; using fallback empty table.")
	_SpellData = {}
end

local BuffData = require(DataFolder:WaitForChild("BuffData"))
local PlayerDataModule = require(ModulesFolder:WaitForChild("PlayerDataModule"))

local SpellModule = {}

-- ========================================
-- PROJECTILE CREATION
-- ========================================
--- Creates a projectile for a spell
--- @param spellData table The spell's data from SpellData
--- @param startPosition Vector3 Where the projectile starts
--- @param direction Vector3 Which direction it travels
--- @param caster Player Who cast the spell
--- @return BasePart The projectile part
local function createProjectile(spellData, startPosition, direction, caster)
	-- Create the projectile part
	local projectile = Instance.new("Part")
	projectile.Name = spellData.name .. "_Projectile"
	projectile.Size = Vector3.new(2, 2, 2) -- PLACEHOLDER size
	projectile.Shape = Enum.PartType.Ball
	projectile.Material = Enum.Material.Neon
	projectile.CanCollide = false
	projectile.Anchored = true -- We'll move it manually for precise control
	projectile.Position = startPosition
	projectile.Parent = workspace
	
	-- Set color based on spell elements (PLACEHOLDER colors)
	if spellData.elements and #spellData.elements > 0 then
		if spellData.elements[1] == "Fire" then
			projectile.Color = Color3.fromRGB(255, 100, 50) -- Orange
		elseif spellData.elements[1] == "Water" then
			projectile.Color = Color3.fromRGB(50, 150, 255) -- Blue
		elseif spellData.elements[1] == "Earth" then
			projectile.Color = Color3.fromRGB(100, 200, 100) -- Green
		end
	else
		projectile.Color = Color3.fromRGB(200, 150, 255) -- Purple (Magic Missile)
	end
	
	-- Add light for visual effect
	local light = Instance.new("PointLight")
	light.Brightness = 2
	light.Range = 15
	light.Color = projectile.Color
	light.Parent = projectile
	
	-- PLACEHOLDER: Add particle effects here
	-- TODO: Create unique VFX for each spell
	
	-- Store data on the projectile
	projectile:SetAttribute("Damage", spellData.damage)
	projectile:SetAttribute("CasterUserId", caster.UserId)
	projectile:SetAttribute("SpellName", spellData.name)
	projectile:SetAttribute("Pierce", spellData.pierce)
	projectile:SetAttribute("AoERadius", spellData.aoeRadius)
	
	return projectile
end

-- ========================================
-- DAMAGE CALCULATION
-- ========================================
--- Calculates the final damage a spell will deal, including buffs
--- @param baseDamage number The spell's base damage
--- @param caster Player Who cast the spell
--- @return number The final damage amount
local function calculateDamage(baseDamage, caster)
	local data = PlayerDataModule:GetPlayerData(caster)
	if not data then return baseDamage end
	
	-- Apply damage bonus from buffs
	local damageBonus = BuffData:CalculateStatBonus(data.buffs, "DamageBonus")
	local finalDamage = baseDamage * (1 + damageBonus)
	
	-- Check for critical hit
	local critChance = BuffData:CalculateStatBonus(data.buffs, "CritChance")
	if math.random() < critChance then
		finalDamage = finalDamage * 2 -- Crit = double damage
		print("💥 CRITICAL HIT! " .. caster.DisplayName .. " dealt " .. math.floor(finalDamage) .. " damage!")
	end
	
	return finalDamage
end

-- ========================================
-- PROJECTILE MOVEMENT
-- ========================================
--- Moves a projectile and handles collisions
--- @param projectile BasePart The projectile to move
--- @param direction Vector3 Direction to move
--- @param speed number How fast to move
--- @param maxRange number Maximum distance to travel
--- @param caster Player Who cast the spell
--- @param spellData table The spell's data
local function moveProjectile(projectile, direction, speed, maxRange, caster, spellData)
	local distanceTraveled = 0
	local hitPlayers = {} -- Track who we've hit (for pierce logic)
	
	-- Movement loop
	local connection
	connection = RunService.Heartbeat:Connect(function(deltaTime)
		-- Check if projectile still exists
		if not projectile or not projectile.Parent then
			connection:Disconnect()
			return
		end
		
		-- Calculate movement
		local moveDistance = speed * deltaTime
		local moveVector = direction * moveDistance
		
		-- Raycast to check for hits
		local raycastParams = RaycastParams.new()
		raycastParams.FilterDescendantsInstances = {projectile, caster.Character}
		raycastParams.FilterType = Enum.RaycastFilterType.Exclude
		
		local rayResult = workspace:Raycast(projectile.Position, moveVector, raycastParams)
		
		if rayResult then
			-- We hit something!
			local hitPart = rayResult.Instance
			local hitCharacter = hitPart.Parent
			
			-- Check if we hit a player
			if hitCharacter and hitCharacter:FindFirstChild("Humanoid") then
				local hitPlayer = game.Players:GetPlayerFromCharacter(hitCharacter)
				
				if hitPlayer and hitPlayer ~= caster then
					-- Check if we've already hit this player (for pierce logic)
					if not table.find(hitPlayers, hitPlayer) then
						print("[SpellModule] 💥 ========================================")
						print("[SpellModule] 💥 HIT DETECTED!")
						print("[SpellModule] 💥 Caster: " .. caster.DisplayName)
						print("[SpellModule] 💥 Target: " .. hitPlayer.DisplayName)
						print("[SpellModule] 💥 Spell: " .. spellData.name)
						print("[SpellModule] 💥 Hit Position: " .. tostring(rayResult.Position))
						print("[SpellModule] 💥 ========================================")
						
						table.insert(hitPlayers, hitPlayer)
						
						-- Calculate and apply damage
						local damage = calculateDamage(spellData.damage, caster)
						print("[SpellModule] 📊 Calculated Damage: " .. damage)
						local died = PlayerDataModule:ApplyDamage(hitPlayer, damage, caster)
						
						if died then
							print("[SpellModule] 💀 TARGET KILLED: " .. hitPlayer.DisplayName)
						else
							print("[SpellModule] ✅ Damage applied to " .. hitPlayer.DisplayName)
						end
						
						-- Apply special effects
						if spellData.specialEffect then
							print("[SpellModule] ✨ Applying spell effect: " .. spellData.specialEffect.type)
							SpellModule:ApplySpellEffect(hitPlayer, spellData, caster)
						end
						
						-- TODO: Trigger hit VFX and sound
						-- TODO: Show damage numbers
						
						-- Check if we should destroy projectile
						if not spellData.pierce then
							print("[SpellModule] 💨 Non-piercing projectile - destroying")
							-- Non-piercing projectile, destroy on hit
							projectile:Destroy()
							connection:Disconnect()
							return
						else
							print("[SpellModule] 🎯 Piercing projectile - continuing (" .. #hitPlayers .. " hits so far)")
						end
					end
				end
			else
				print("[SpellModule] 💥 Hit terrain/object at " .. tostring(rayResult.Position) .. " - destroying projectile")
				-- Hit terrain or object, destroy projectile
				-- TODO: Trigger impact VFX
				projectile:Destroy()
				connection:Disconnect()
				return
			end
		end
		
		-- Move projectile
		projectile.Position = projectile.Position + moveVector
		distanceTraveled = distanceTraveled + moveDistance
		
		-- Check if we've traveled max range
		if distanceTraveled >= maxRange then
			projectile:Destroy()
			connection:Disconnect()
		end
	end)
end

-- ========================================
-- PUBLIC FUNCTIONS
-- ========================================

--- Casts a spell from a player
--- @param player Player The player casting the spell
--- @param targetPosition Vector3 Where the player is aiming
--- @return boolean Whether the spell was successfully cast
function SpellModule:CastSpell(player, targetPosition)
	print("[SpellModule] 🔮 ========================================")
	print("[SpellModule] 🔮 CAST SPELL")
	print("[SpellModule] 🔮 Caster: " .. player.DisplayName .. " (UserId: " .. player.UserId .. ")")
	print("[SpellModule] 🔮 Target Position: " .. tostring(targetPosition))
	print("[SpellModule] 🔮 ========================================")
	
	-- Get player data
	local data = PlayerDataModule:GetPlayerData(player)
	if not data then
		warn("[SpellModule] ❌ Cannot cast spell - no player data for " .. player.DisplayName)
		return false
	end
	print("[SpellModule] ✅ Player data found")
	
	-- Check if spell is on cooldown
	if not data.spellCooldownReady then
		local timeRemaining = (data.spellLastCastTime + 1) - tick() -- Approximate
		warn("[SpellModule] ⏱️ Spell on cooldown - Remaining: ~" .. string.format("%.2f", math.max(0, timeRemaining)) .. "s")
		return false
	end
	print("[SpellModule] ✅ Cooldown check passed")
	
	-- Get player's character
	local character = player.Character
	if not character then
		warn("[SpellModule] ❌ Cannot cast spell - " .. player.DisplayName .. " has no character")
		return false
	end
	
	local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
	if not humanoidRootPart then
		warn("[SpellModule] ❌ Cannot cast spell - no HumanoidRootPart")
		return false
	end
	print("[SpellModule] ✅ Character found")
	
	-- Get the spell data
	local spellData = data.currentSpell
	if not spellData then
		warn("[SpellModule] ❌ Cannot cast spell - no current spell")
		return false
	end
	print("[SpellModule] ✅ Spell: " .. spellData.name)
	print("[SpellModule] 📊 Spell stats:")
	print("  - Damage: " .. spellData.damage)
	print("  - Speed: " .. spellData.projectileSpeed)
	print("  - Range: " .. spellData.range)
	print("  - Cooldown: " .. spellData.cooldown .. "s")
	print("  - Pierce: " .. tostring(spellData.pierce))
	
	-- Calculate direction
	local startPosition = humanoidRootPart.Position + Vector3.new(0, 2, 0) -- Spawn above player
	local direction = (targetPosition - startPosition).Unit
	print("[SpellModule] 📍 Start Position: " .. tostring(startPosition))
	print("[SpellModule] 🎯 Direction: " .. tostring(direction))
	
	-- Apply projectile speed buff
	local speedBonus = BuffData:CalculateStatBonus(data.buffs, "ProjectileSpeed")
	local finalSpeed = spellData.projectileSpeed * (1 + speedBonus)
	print("[SpellModule] 🚀 Speed: " .. spellData.projectileSpeed .. " → " .. finalSpeed .. " (+" .. (speedBonus * 100) .. "%)")
	
	-- Apply range (no buff for range in this version)
	local finalRange = spellData.range
	
	-- Create projectile
	print("[SpellModule] 🎯 Creating projectile...")
	local projectile = createProjectile(spellData, startPosition, direction, player)
	print("[SpellModule] ✅ Projectile created")
	
	-- Start moving projectile
	print("[SpellModule] 🚀 Starting projectile movement...")
	moveProjectile(projectile, direction, finalSpeed, finalRange, player, spellData)
	
	-- Set cooldown
	data.spellCooldownReady = false
	data.spellLastCastTime = tick()
	
	-- Calculate cooldown with buffs
	local cooldownReduction = BuffData:CalculateStatBonus(data.buffs, "CooldownReduction")
	local finalCooldown = spellData.cooldown * (1 - cooldownReduction)
	print("[SpellModule] ⏱️ Cooldown: " .. spellData.cooldown .. "s → " .. string.format("%.2f", finalCooldown) .. "s (-" .. (cooldownReduction * 100) .. "%)")
	
	-- Reset cooldown after time
	task.delay(finalCooldown, function()
		if data then
			data.spellCooldownReady = true
			print("[SpellModule] ✅ " .. player.DisplayName .. "'s spell ready")
		end
	end)
	
	print("[SpellModule] ✅ Spell cast complete!")
	print("[SpellModule] ========================================")
	
	-- TODO: Play casting sound and VFX
	
	return true
end

--- Applies special effects from a spell (burn, slow, siphon, etc.)
--- @param target Player The player hit by the spell
--- @param spellData table The spell's data
--- @param caster Player Who cast the spell
function SpellModule:ApplySpellEffect(target, spellData, caster)
	if not spellData.specialEffect then return end
	
	local effect = spellData.specialEffect
	local targetData = PlayerDataModule:GetPlayerData(target)
	if not targetData then return end
	
	-- BURN EFFECT
	if effect.type == "Burn" then
		print("🔥 " .. target.DisplayName .. " is burning!")
		
		-- Create burn effect
		local burnDuration = effect.duration
		local burnDPS = effect.damagePerSecond
		local burnTicks = burnDuration -- Tick every second
		
		task.spawn(function()
			for i = 1, burnTicks do
				task.wait(1)
				-- Check if target still exists
				if target and target.Parent and targetData.health > 0 then
					PlayerDataModule:ApplyDamage(target, burnDPS, caster)
				else
					break
				end
			end
		end)
	end
	
	-- SIPHON EFFECT (Heal caster)
	if effect.type == "Siphon" then
		local healAmount = spellData.damage * effect.healPercent
		PlayerDataModule:Heal(caster, healAmount)
		print("💧 " .. caster.DisplayName .. " siphoned " .. math.floor(healAmount) .. " HP")
	end
	
	-- SLOW EFFECT
	if effect.type == "Slow" then
		print("🐌 " .. target.DisplayName .. " is slowed!")
		
		-- Apply slow
		targetData.isSlowed = true
		local originalSpeed = targetData.movementSpeed
		targetData.movementSpeed = originalSpeed * (1 - effect.slowPercent)
		
		-- TODO: Update character WalkSpeed
		
		-- Remove slow after duration
		task.delay(effect.duration, function()
			if targetData then
				targetData.isSlowed = false
				targetData.movementSpeed = originalSpeed
				-- TODO: Update character WalkSpeed
			end
		end)
	end
	
	-- STUN EFFECT
	if effect.type == "Stun" then
		print("😵 " .. target.DisplayName .. " is stunned!")
		
		targetData.isStunned = true
		
		-- TODO: Disable player movement and actions
		
		-- Remove stun after duration
		task.delay(effect.duration, function()
			if targetData then
				targetData.isStunned = false
				-- TODO: Re-enable player movement
			end
		end)
	end
	
	-- TODO: Implement other special effects (Burning Oil, Lightning Storm, etc.)
end

return SpellModule
