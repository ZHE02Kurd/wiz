-- services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

-- constants
local REMOTES = ReplicatedStorage:WaitForChild("Remotes")
local PLAYER = Players.LocalPlayer
local PLAYERGUI = PLAYER:WaitForChild("PlayerGui")

local module = {}

function module:Create(item)
	local itemModule = {
		Item = item,
		Equipped = false,
		Connections = {},
	}

	local character = PLAYER.Character
	local humanoid = character:WaitForChild("Humanoid")
	local config = require(item:WaitForChild("Config"))
	local useAnim = item:FindFirstChild("UseAnimation") and humanoid:LoadAnimation(item.UseAnimation) or nil
	local gui = PLAYERGUI:WaitForChild("MainGui")
	local boosterGui = gui:WaitForChild("Booster")

	local inUse = false
	-- 'used' variable removed

	function itemModule:Connect()
		-- called when the item is first initialized on the client
	end

	function itemModule:Disconnect()
		-- called when the item leaves the client's control
		for _, connection in pairs(self.Connections) do
			connection:Disconnect()
		end
		self.Connections = {}
	end

	function itemModule:Equip()
		-- called when the item is equipped
		self.Equipped = true
	end

	function itemModule:Unequip()
		-- called when the item is unequipped
		self.Equipped = false

		inUse = false
		boosterGui.Visible = false
	end

	function itemModule:Activate()
		print("[BOOSTER ACTIVATE] Called for item: " .. item.Name)
		print("[BOOSTER ACTIVATE] inUse=" .. tostring(inUse))

		-- called when the item is activated
		-- Check only for 'inUse', not 'used'
		if (not inUse) then 
			local character = PLAYER.Character
			local humanoid = character:WaitForChild("Humanoid")
			local rootPart = character:WaitForChild("HumanoidRootPart")

			print("[BOOSTER ACTIVATE] Boost type: " .. config.Boost)
			print("[BOOSTER ACTIVATE] Health: " .. humanoid.Health .. "/" .. humanoid.MaxHealth)
			print("[BOOSTER ACTIVATE] Armor: " .. humanoid.Armor.Value .. "/100")

			if (config.Boost == "Health" and humanoid.Health < humanoid.MaxHealth) or (config.Boost == "Armor" and humanoid.Armor.Value < 100) then
				print("[BOOSTER ACTIVATE] Condition passed! Starting use...")
				boosterGui.Visible = true

				inUse = true
				local health = humanoid.Health
				local start = tick()
				local alpha = 0

				REMOTES.Booster:FireServer("Init", item)
				if useAnim then
					useAnim:Play(0.1, 1, 1 / config.UseTime)
				end

				repeat
					local speed = rootPart.Velocity.Magnitude
					alpha = math.min((tick() - start) / config.UseTime, 1)
					boosterGui.Bar.Size = UDim2.new(alpha, 0, 1, 0)

					RunService.RenderStepped:wait()
				until alpha == 1 or (not self.Equipped) or humanoid.Health < health

				inUse = false
				boosterGui.Visible = false
				if useAnim then
					useAnim:Stop(0.1)
				end

				if alpha == 1 then
					-- 'used' line removed
					REMOTES.Booster:FireServer("Use", item)
				end
			else
				print("[BOOSTER ACTIVATE] Condition FAILED! Cannot use.")
			end
		else
			print("[BOOSTER ACTIVATE] Already in use!")
		end
	end

	function itemModule:Deactivate()
		-- called when then item is deactivated
	end

	return itemModule
end

return module