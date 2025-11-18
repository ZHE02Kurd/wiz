-- services

local UserInputService	= game:GetService("UserInputService")
local ReplicatedStorage	= game:GetService("ReplicatedStorage")
local RunService		= game:GetService("RunService")
local Workspace			= game:GetService("Workspace")
local Players			= game:GetService("Players")

-- constants

local PLAYER	= Players.LocalPlayer
local EVENTS	= ReplicatedStorage:WaitForChild("Events")
local REMOTES	= ReplicatedStorage:WaitForChild("Remotes")
local MODULES	= ReplicatedStorage:WaitForChild("Modules")
	local CONFIG		= require(MODULES:WaitForChild("Config"))
	local MOUSE			= require(MODULES:WaitForChild("Mouse"))
	local EFFECTS		= require(MODULES:WaitForChild("Effects"))
	local DAMAGE		= require(MODULES:WaitForChild("Damage"))
	
local EQUIP_COOLDOWN	= 0.2

-- functions

-- modules

local module	= {}

function module.Create(self, item)
	local itemModule	= {
		Item		= item;
		Equipped	= false;
		Connections	= {};
	}
	
	-- variables
	
	local animations	= {}
	
	local character	= item.Parent.Parent
	local handle	= item:WaitForChild("Handle")
	local stack		= item:WaitForChild("Stack")
	
	local config	= CONFIG:GetConfig(item)
	
	local canThrow	= true
	
	-- functions
	
	-- module functions
	
	function itemModule.Connect(self)
		local character		= PLAYER.Character
		local humanoid		= character:WaitForChild("Humanoid")
		
		for _, animation in pairs(self.Item:WaitForChild("Animations"):GetChildren()) do
			animations[animation.Name]	= humanoid:LoadAnimation(animation)
		end
	end
	
	function itemModule.Disconnect(self)
		for _, connection in pairs(self.Connections) do
			connection:Disconnect()
		end
		self.Connections	= {}
	end
	
	function itemModule.Equip(self)
		animations.Idle:Play(0.1, 0.7, 1)
		animations.Equip:Play(0, 1, 1)
		
		self.Equipped	= true
	end
	
	function itemModule.Unequip(self)
		for name, animation in pairs(animations) do
			if name ~= "Throw" then
				animation:Stop()
			end
		end
		
		self.Equipped	= false
	end
	
	function itemModule.Activate(self)
		if canThrow and stack.Value > 0 then
			canThrow	= false
			
			local direction		= (MOUSE.WorldPosition - handle.Position).Unit
			local projectileID	= EVENTS.GetProjectileID:Invoke()
			
			if config.AimCorrection then
				direction	= (direction + Vector3.new(0, config.AimCorrection / 100, 0)).Unit
			end
			
			animations.Throw:Play(0, 1, 1)
			EFFECTS:Effect("Throw", item)
			
			wait(0.01)
			
			EVENTS.Projectile:Fire(PLAYER, item, projectileID, handle.Position, direction)
			REMOTES.Throwable:FireServer(item, "Throw", projectileID, handle.Position, direction)
			
			wait(1 / config.ThrowRate)
			canThrow	= true
		end
	end
	
	function itemModule.Deactivate(self)
		
	end
	
	return itemModule
end

return module