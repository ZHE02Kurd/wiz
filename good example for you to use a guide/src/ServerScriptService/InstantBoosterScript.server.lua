-- InstantBoosterScript - Handles instant booster use without equipping
-- Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

-- Constants
local REMOTES = ReplicatedStorage:WaitForChild("Remotes")
local EVENTS = ReplicatedStorage:WaitForChild("Events")

-- Create the remote if it doesn't exist
if not REMOTES:FindFirstChild("InstantBooster") then
	local instantBoosterRemote = Instance.new("RemoteEvent")
	instantBoosterRemote.Name = "InstantBooster"
	instantBoosterRemote.Parent = REMOTES
end

-- Track players currently using instant boosters
local usingBooster = {}

-- Function to use booster instantly without equipping
local function UseInstantBooster(player, item)
	local character = player.Character
	if not character or usingBooster[player] then return end
	
	-- Verify the item exists in player's items
	local items = character:FindFirstChild("Items")
	if not items or not items:FindFirstChild(item.Name) then return end
	
	local humanoid = character:FindFirstChild("Humanoid")
	if not humanoid or humanoid.Health <= 0 then return end
	
	local config = require(item:WaitForChild("Config"))
	if config.Type ~= "Booster" then return end
	
	local stack = item:FindFirstChild("Stack")
	if not stack or stack.Value <= 0 then return end
	
	-- Check if player can use this booster
	local armor = humanoid:FindFirstChild("Armor")
	local down = humanoid:FindFirstChild("Down")
	
	if down and down.Value then return end
	
	if config.Boost ~= "Health" then return end
	if humanoid.Health >= humanoid.MaxHealth then return end
	
	-- Mark as using
	usingBooster[player] = true
	
	-- Play animation without unequipping current item
	local useAnim
	if item:FindFirstChild("UseAnimation") then
		useAnim = humanoid:LoadAnimation(item.UseAnimation)
		useAnim:Play(0.1, 1, 1 / config.UseTime)
	end
	
	-- Wait for animation
	task.wait(config.UseTime)
	
	-- Stop animation
	if useAnim then
		useAnim:Stop(0.1)
	end
	
	-- Check if still valid after wait
	if not character or not character.Parent or humanoid.Health <= 0 then
		usingBooster[player] = nil
		return
	end
	
	if stack.Value <= 0 then
		usingBooster[player] = nil
		return
	end
	
	-- Consume item from stack
	stack.Value = stack.Value - 1
	if stack.Value == 0 then
		item:Destroy()
	end
	
	-- Heal over time
	task.spawn(function()
		local totalHealed = 0
		local tickRate = config.TickRate or 1
		local healPerTick = config.Potency or 10
		local maxHeal = config.MaxHeal or 100
		
		while totalHealed < maxHeal and humanoid.Health > 0 and humanoid.Health < humanoid.MaxHealth do
			humanoid.Health = math.min(humanoid.Health + healPerTick, humanoid.MaxHealth)
			totalHealed = totalHealed + healPerTick
			REMOTES.Effect:FireAllClients("Booster", character, "Health")
			
			if humanoid.Health >= humanoid.MaxHealth then
				break
			end
			task.wait(tickRate)
		end
	end)
	
	-- Clean up
	usingBooster[player] = nil
end

-- Events
REMOTES.InstantBooster.OnServerEvent:Connect(function(player, item)
	if item and item:IsA("Model") then
		task.spawn(function()
			UseInstantBooster(player, item)
		end)
	end
end)

-- Cleanup on player leaving
Players.PlayerRemoving:Connect(function(player)
	if usingBooster[player] then
		usingBooster[player] = nil
	end
end)
