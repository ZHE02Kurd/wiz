-- Player Data Service (Server)
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Data.Config)
local Types = require(ReplicatedStorage.Shared.Types.GameTypes)
local SpellFusion = require(ReplicatedStorage.Shared.Systems.SpellFusion)

local PlayerDataService = {}
PlayerDataService.PlayerData = {}

local RemoteEvents = ReplicatedStorage:WaitForChild("RemoteEvents")
local DamagePlayer = RemoteEvents:WaitForChild("DamagePlayer")
local AddXP = RemoteEvents:WaitForChild("AddXP")
local LevelUpChoice = RemoteEvents:WaitForChild("LevelUpChoice")
local CastSpell = RemoteEvents:WaitForChild("CastSpell")

function PlayerDataService:InitializePlayer(player: Player)
	local data: Types.PlayerStats = {
		HP = Config.PLAYER.STARTING_HP,
		MaxHP = Config.PLAYER.STARTING_HP,
		Level = Config.PLAYER.STARTING_LEVEL,
		XP = 0,
		Kills = 0,
		CurrentSpell = {
			Element = "Basic",
			Damage = Config.SPELLS.Basic.Damage,
			Cooldown = Config.SPELLS.Basic.Cooldown,
			ProjectileSpeed = Config.SPELLS.Basic.ProjectileSpeed,
			Range = Config.SPELLS.Basic.Range,
			LastCastTime = 0,
		},
		Buffs = {},
	}

	self.PlayerData[player.UserId] = data
	print("✅ Initialized player data for", player.Name)
	return data
end

function PlayerDataService:GetPlayerData(player: Player): Types.PlayerStats?
	return self.PlayerData[player.UserId]
end

function PlayerDataService:AddXP(player: Player, amount: number)
	local data = self:GetPlayerData(player)
	if not data then
		return
	end

	data.XP += amount
	print(player.Name, "gained", amount, "XP. Total:", data.XP)

	-- Check for level up
	local LevelUpSystem = require(ReplicatedStorage.Shared.Systems.LevelUpSystem)
	if LevelUpSystem.CanLevelUp(data.Level, data.XP) then
		self:LevelUp(player)
	end

	-- Replicate XP to client
	AddXP:FireClient(player, data.XP, data.Level)
end

function PlayerDataService:LevelUp(player: Player)
	local data = self:GetPlayerData(player)
	if not data then
		return
	end

	data.Level += 1
	print("🎉", player.Name, "leveled up to", data.Level)

	-- Get choices for this level
	local LevelUpSystem = require(ReplicatedStorage.Shared.Systems.LevelUpSystem)
	local choices = LevelUpSystem.GetChoicesForLevel(data.Level)

	-- Send choices to client
	LevelUpChoice:FireClient(player, choices, data.Level)
end

function PlayerDataService:ApplyLevelUpChoice(player: Player, choiceType: string, choiceValue: string)
	local data = self:GetPlayerData(player)
	if not data then
		return
	end

	if choiceType == "Element" then
		-- Apply new element
		local currentElement = data.CurrentSpell.Element
		local newElement = SpellFusion.CombineSpell(currentElement, choiceValue)
		local spellStats = SpellFusion.GetSpellStats(newElement)

		data.CurrentSpell.Element = newElement
		data.CurrentSpell.Damage = spellStats.Damage
		data.CurrentSpell.Cooldown = spellStats.Cooldown
		data.CurrentSpell.ProjectileSpeed = spellStats.ProjectileSpeed
		data.CurrentSpell.Range = spellStats.Range

		-- Apply buffs to spell
		self:ApplyBuffsToSpell(data)

		print(player.Name, "upgraded spell to", newElement)
	elseif choiceType == "Buff" then
		-- Apply buff
		local buffType = choiceValue :: Types.BuffType
		data.Buffs[buffType] = (data.Buffs[buffType] or 0) + 1

		-- Apply buff effects
		if buffType == "MAX_HP" then
			local increase = Config.BUFFS.MAX_HP.Value
			data.MaxHP += increase
			data.HP += increase
		elseif buffType == "MOVE_SPEED" then
			local character = player.Character
			if character then
				local humanoid = character:FindFirstChild("Humanoid") :: Humanoid
				if humanoid then
					humanoid.WalkSpeed += Config.BUFFS.MOVE_SPEED.Value
				end
			end
		end

		-- Recalculate spell stats with buffs
		self:ApplyBuffsToSpell(data)

		print(player.Name, "gained buff", choiceValue)
	end
end

function PlayerDataService:ApplyBuffsToSpell(data: Types.PlayerStats)
	-- Apply projectile speed buff
	if data.Buffs.PROJECTILE_SPEED then
		local baseStats = SpellFusion.GetSpellStats(data.CurrentSpell.Element)
		data.CurrentSpell.ProjectileSpeed =
			baseStats.ProjectileSpeed + (data.Buffs.PROJECTILE_SPEED * Config.BUFFS.PROJECTILE_SPEED.Value)
	end

	-- Apply cooldown reduction
	if data.Buffs.COOLDOWN_REDUCTION then
		local baseStats = SpellFusion.GetSpellStats(data.CurrentSpell.Element)
		data.CurrentSpell.Cooldown =
			baseStats.Cooldown * (1 - data.Buffs.COOLDOWN_REDUCTION * Config.BUFFS.COOLDOWN_REDUCTION.Value)
	end

	-- Apply damage buff
	if data.Buffs.DAMAGE then
		local baseStats = SpellFusion.GetSpellStats(data.CurrentSpell.Element)
		data.CurrentSpell.Damage = baseStats.Damage + (data.Buffs.DAMAGE * Config.BUFFS.DAMAGE.Value)
	end
end

function PlayerDataService:DamagePlayer(player: Player, damage: number, attacker: Player?)
	local data = self:GetPlayerData(player)
	if not data then
		return
	end

	data.HP = math.max(0, data.HP - damage)
	DamagePlayer:FireClient(player, data.HP, data.MaxHP)

	if data.HP <= 0 then
		self:KillPlayer(player, attacker)
	end
end

function PlayerDataService:KillPlayer(player: Player, attacker: Player?)
	print("💀", player.Name, "was eliminated by", attacker and attacker.Name or "unknown")

	-- Give XP to attacker
	if attacker then
		self:AddXP(attacker, Config.LEVELING.KILL_XP)
		local attackerData = self:GetPlayerData(attacker)
		if attackerData then
			attackerData.Kills += 1
		end
	end

	-- Respawn or spectate logic would go here
	local character = player.Character
	if character then
		local humanoid = character:FindFirstChild("Humanoid") :: Humanoid
		if humanoid then
			humanoid.Health = 0
		end
	end
end

-- Initialize service
function PlayerDataService:Init()
	-- Connect events
	LevelUpChoice.OnServerEvent:Connect(function(player, choiceType, choiceValue)
		self:ApplyLevelUpChoice(player, choiceType, choiceValue)
	end)

	Players.PlayerAdded:Connect(function(player)
		player.CharacterAdded:Connect(function()
			self:InitializePlayer(player)
		end)
	end)

	Players.PlayerRemoving:Connect(function(player)
		self.PlayerData[player.UserId] = nil
	end)
end

return PlayerDataService
