-- services
local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

-- constants
local REMOTES = ReplicatedStorage:WaitForChild("Remotes")

-- variables
local inits = {}

-- functions
local function Init(player, item)
	-- This is the fix: store the Start time
	inits[player] = {Item = item; Start = tick()}
end

-- events
REMOTES.Booster.OnServerEvent:connect(function(player, action, item)
	local character = player.Character
	if character then
		local equipped = character.Equipped.Value

		if item == equipped then
			if action == "Init" then
				Init(player, item)

			elseif action == "Use" then
				-- Check that init data and the Start time exist
				if inits[player] and inits[player].Start then 
					if inits[player].Item == item then
						local elapsed = tick() - inits[player].Start
						local config = require(item.Config)
						local dif = math.abs(elapsed - config.UseTime)

						-- Check if client and server use-times match
						if dif <= 0.5 then 
							local humanoid = character.Humanoid

							--
							-- THIS IS THE LOGIC THAT FIXES ARMOR
							--
							if config.Boost == "Armor" then
								-- Instant full armor
								humanoid.Armor.Value = 100
								REMOTES.Effect:FireAllClients("Booster", character, "Heal")
								print("[ARMOR] Restored armor for " .. player.Name)

							elseif config.Boost == "Health" then
								-- Heal over time
								print("[HEALTH] Starting heal for " .. player.Name)
								spawn(function()
									local totalHealed = 0
									local tickRate = config.TickRate or 1
									local healPerTick = config.Potency or 10
									local maxHeal = config.MaxHeal or 100

									-- Loop until max heal, player is dead, or player is at full health
									while totalHealed < maxHeal and humanoid.Health > 0 and humanoid.Health < humanoid.MaxHealth do
										humanoid.Health = math.min(humanoid.Health + healPerTick, humanoid.MaxHealth)
										totalHealed = totalHealed + healPerTick
										REMOTES.Effect:FireAllClients("Booster", character, "Heal")
										print("[HEALTH] Healed " .. player.Name .. " for " .. healPerTick .. " (Total: " .. totalHealed .. ")")

										if humanoid.Health >= humanoid.MaxHealth then
											print("[HEALTH] " .. player.Name .. " at full health.")
											break
										end
										wait(tickRate)
									end
									print("[HEALTH] Healing complete for " .. player.Name)
								end)
							end

							-- Consume item from stack
							item.Stack.Value = item.Stack.Value - 1
							if item.Stack.Value == 0 then
								item:Destroy()
							end
						else
							warn("[BOOSTER] Time mismatch for " .. player.Name .. ": expected " .. config.UseTime .. ", got " .. elapsed)
						end
					end
				else
					warn("[BOOSTER] No init data for " .. player.Name .. " on 'Use' action.")
				end
			end
		end
	end
end)

Players.PlayerRemoving:connect(function(player)
	-- Clear data when player leaves
	if inits[player] then
		inits[player] = nil
	end
end)