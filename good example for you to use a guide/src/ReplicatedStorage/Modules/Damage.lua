-- services

local ServerScriptService	= game:GetService("ServerScriptService")
local ReplicatedStorage		= game:GetService("ReplicatedStorage")
local Players				= game:GetService("Players")
local Debris				= game:GetService("Debris")

-- constants

local PLAYER_DATA	= ReplicatedStorage:WaitForChild("PlayerData")
local EVENTS		= ReplicatedStorage:WaitForChild("Events")
local REMOTES		= ReplicatedStorage:WaitForChild("Remotes")
local SQUADS		= ReplicatedStorage:WaitForChild("Squads")
local MODULES		= ReplicatedStorage:WaitForChild("Modules")
	local CONFIG		= require(MODULES:WaitForChild("Config"))

local DOWN_INVUL_TIME	= 0.5
	
-- functions

local function GetSquad(player)
	for _, squad in pairs(SQUADS:GetChildren()) do
		if squad:FindFirstChild(player.Name) then
			return squad
		end
	end
end

local function Invulnerable(humanoid)
	local invul		= Instance.new("BoolValue")
		invul.Name		= "Invulnerable"
		invul.Value		= true
		invul.Parent	= humanoid
		
	Debris:AddItem(invul, DOWN_INVUL_TIME)
end

-- module

local DAMAGE	= {}

-- variables

local damageEnabled	= true

-- todo: implement damage functions etc

function DAMAGE.SetEnabled(self, enabled)
	damageEnabled	= enabled
end

function DAMAGE.Calculate(self, item, hit, origin)
	local config	= CONFIG:GetConfig(item)
	local damage	= config.Damage
	
	if hit.Name == "Head" then
		damage		= damage * 1.5
	end
	
	local humanoid	= hit.Parent:FindFirstChildOfClass("Humanoid")
	
	if humanoid and humanoid:FindFirstChild("Down") then
		if humanoid.Down.Value then
			damage	= damage * 2
		end
	end
	
	local distance	= (origin - hit.Position).Magnitude
	local falloff	= math.clamp(1 - (distance / config.Range)^3, 0, 1)
	local minDamage	= damage * 0.3
	damage			= math.max(damage * falloff, minDamage)
	
	return math.ceil(damage)
end



--function DAMAGE.PlayerCanDamage(self, player, humanoid)
--	local squad	= GetSquad(player)
--	if squad then
--		local otherPlayer	= Players:GetPlayerFromCharacter(humanoid.Parent)
--		if otherPlayer then
--			local otherSquad	= GetSquad(otherPlayer)
			
--			if otherSquad and otherSquad == squad then
--				return false
--			end
--		end
--	end
	
--	return true
--end
function DAMAGE.PlayerCanDamage(self, player, humanoid)
	if not player then return true end

	local otherPlayer = Players:GetPlayerFromCharacter(humanoid.Parent)

	-- If the target is a real player (not an NPC)
	if otherPlayer then
		-- Check teams
		if player.Team and otherPlayer.Team then
			if player.Team == otherPlayer.Team then
				return false -- SAME TEAM! No damage.
			end
		end
	end

	return true -- Different teams (or no teams), damage allowed.
end




function DAMAGE.Damage(self, humanoid, damage, player)
	local canDamage	= true
	
	if humanoid:FindFirstChild("Invulnerable") then
		canDamage	= false
	end
	
	--[[if player then
		canDamage	= DAMAGE:PlayerCanDamage(player, humanoid)
	end]]
	
	if damageEnabled and canDamage then
		if player then
			ServerScriptService.StatScript.Increment:Fire(player, "Damage", damage)
		end
		
		local armor	= humanoid:FindFirstChild("Armor")
		local down	= humanoid:FindFirstChild("Down")
		
		if player then
			local killTag	= humanoid:FindFirstChild("KillTag")
			
			if not killTag then
				killTag	= Instance.new("ObjectValue")
					killTag.Name	= "KillTag"
					killTag.Parent	= humanoid
			end
			
			killTag.Value	= player
		end
		
		if humanoid.Health > 0 then
			EVENTS.Damaged:Fire(humanoid)
			
			if armor then
				if armor.Value >= damage then
					armor.Value	= armor.Value - damage
				else
					local dif	= damage - armor.Value
					armor.Value	= 0
					if down and not down.Value then
						if humanoid.Health - dif <= 0 then
							humanoid.Health	= humanoid.MaxHealth
							Invulnerable(humanoid)
							
							if player then
								local downTag	= humanoid:FindFirstChild("DownTag")
								if not downTag then
									downTag		= Instance.new("ObjectValue")
										downTag.Name	= "DownTag"
										downTag.Parent	= humanoid
								end
								downTag.Value	= player
								REMOTES.Killed:FireClient(player, humanoid.Parent.Name, false)
							end
							
							down.Value		= true
						else
							humanoid:TakeDamage(dif)
							
							if humanoid.Health <= 0 then
								if player then
									REMOTES.Killed:FireClient(player, humanoid.Parent.Name, true)
								end
								local downTag	= humanoid:FindFirstChild("DownTag")
								if downTag and downTag.Value and downTag.Value ~= player then
									REMOTES.Killed:FireClient(downTag.Value, humanoid.Parent.Name, true)
								end
							end
						end
					else
						humanoid:TakeDamage(dif)
						
						if humanoid.Health <= 0 then
							if player then
								REMOTES.Killed:FireClient(player, humanoid.Parent.Name, true)
							end
							local downTag	= humanoid:FindFirstChild("DownTag")
							if downTag and downTag.Value and downTag.Value ~= player then
								REMOTES.Killed:FireClient(downTag.Value, humanoid.Parent.Name, true)
							end
						end
					end
				end
			else
				if down and not down.Value then
					if humanoid.Health - damage <= 0 then
						humanoid.Health	= humanoid.MaxHealth
						Invulnerable(humanoid)
						
						if player then
							local downTag	= humanoid:FindFirstChild("DownTag")
							if not downTag then
								downTag		= Instance.new("ObjectValue")
									downTag.Name	= "DownTag"
									downTag.Parent	= humanoid
							end
							downTag.Value	= player
							REMOTES.Killed:FireClient(player, humanoid.Parent.Name, false)
						end
						down.Value		= true
					end
				else
					humanoid:TakeDamage(damage)
					
					if humanoid.Health <= 0 then
						if player then
							REMOTES.Killed:FireClient(player, humanoid.Parent.Name, true)
						end
						local downTag	= humanoid:FindFirstChild("DownTag")
						if downTag and downTag.Value and downTag.Value ~= player then
							REMOTES.Killed:FireClient(downTag.Value, humanoid.Parent.Name, true)
						end
					end
				end
			end
			if humanoid.Health <= 0 then
				if player then
					local playerData	= PLAYER_DATA[player.Name]
					if playerData.Equipped.KillEffect.Value ~= "None" then
						REMOTES.Effect:FireAllClients("Death", humanoid.Parent, playerData.Equipped.KillEffect.Value)
					end
					if playerData.Equipped.Aura.Value ~= "None" then
						REMOTES.Effect:FireAllClients("Aura", player.Character, playerData.Equipped.Aura.Value)
					end
				end
			end
		end
	end
end

return DAMAGE