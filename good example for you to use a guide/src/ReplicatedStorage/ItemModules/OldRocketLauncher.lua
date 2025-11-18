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
	local INPUT			= require(MODULES:WaitForChild("Input"))
	
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
	local muzzle	= handle:WaitForChild("Muzzle")
	
	local config	= CONFIG:GetConfig(item)
	
	local ammo			= item:WaitForChild("Ammo").Value
	local reloading		= false
	local rCancelled	= false
	
	-- functions
	
	local function Reload()
		if (not reloading) and itemModule.Equipped and ammo < config.Magazine then
			reloading	= true
			rCancelled	= false
			
			local storedAmmo	= character.Ammo[config.Size].Value
			if storedAmmo > 0 then
				MOUSE.Reticle	= "Reloading"
				REMOTES.Reload:FireServer(item)
				EFFECTS:Effect("Reload", item)
				animations.Reload:Play(0.1, 1, 1/config.ReloadTime)
				
				local start		= tick()
				local elapsed	= 0
				repeat
					elapsed	= tick() - start
					RunService.Stepped:wait()
				until elapsed >= config.ReloadTime or rCancelled or (not itemModule.Equipped)
				
				animations.Reload:Stop()
				
				if itemModule.Equipped then
					if elapsed >= config.ReloadTime then
						local magazine	= config.Magazine
						local needed	= magazine - ammo
						
						if storedAmmo >= needed then
							ammo	= ammo + needed
						else
							ammo	= ammo + storedAmmo
						end
					end
					
					MOUSE.Reticle	= config.Reticle or "Gun"
					EVENTS.Gun:Fire("Update", ammo)
				end
			end
			reloading	= false
		end
	end
	
	-- module functions
	
	function itemModule.Connect(self)
		local character		= PLAYER.Character
		local humanoid		= character:WaitForChild("Humanoid")
		
		for _, animation in pairs(self.Item:WaitForChild("Animations"):GetChildren()) do
			animations[animation.Name]	= humanoid:LoadAnimation(animation)
		end
		
		table.insert(self.Connections, INPUT.ActionBegan:connect(function(action, processed)
			if self.Equipped and (not processed) then
				if action == "Reload" then
					Reload()
				end
			end
		end))
		
		table.insert(self.Connections, item.Attachments.ChildAdded:connect(function()
			config	= CONFIG:GetConfig(item)
			EVENTS.Zoom:Fire(config.Zoom)
			EVENTS.Scope:Fire(config.Scope)
		end))
		
		table.insert(self.Connections, item.Attachments.ChildRemoved:connect(function()
			config	= CONFIG:GetConfig(item)
			EVENTS.Zoom:Fire(config.Zoom)
			EVENTS.Scope:Fire(config.Scope)
		end))
	end
	
	function itemModule.Disconnect(self)
		for _, connection in pairs(self.Connections) do
			connection:Disconnect()
		end
		self.Connections	= {}
	end
	
	function itemModule.Equip(self)
		self.Equipped	= true
		EVENTS.Zoom:Fire(config.Zoom)
		EVENTS.Scope:Fire(config.Scope)
		MOUSE.Reticle	= config.Reticle or "Gun"
		animations.Idle:Play()
		animations.Equip:Play(0, 1, 1)
		
		ammo	= item.Ammo.Value
		
		EVENTS.Gun:Fire("Enable", config.Size, ammo)
		
		if ammo == 0 then
			spawn(function()
				Reload()
			end)
		end
	end
	
	function itemModule.Unequip(self)
		self.Equipped	= false
		
		EVENTS.Zoom:Fire()
		EVENTS.Scope:Fire(false)
		MOUSE.Reticle	= "Default"
		
		for _, animation in pairs(animations) do
			animation:Stop()
		end
		
		EVENTS.Gun:Fire("Disable")
	end
	
	function itemModule.Activate(self)
		if ammo > 0 then
			ammo	= ammo - 1
			
			local direction		= (MOUSE.WorldPosition - muzzle.WorldPosition).Unit
			local projectileID	= EVENTS.GetProjectileID:Invoke()
			
			EVENTS.Projectile:Fire(PLAYER, item, projectileID, muzzle.WorldPosition, direction)
			REMOTES.RocketLauncher:FireServer(item, "Fire", projectileID, muzzle.WorldPosition, direction)
			
			animations.Shoot:Play(0, 1, 1)
			EVENTS.Recoil:Fire(Vector3.new(math.random(-config.Recoil, config.Recoil) / 4, 0, math.random(config.Recoil / 2, config.Recoil)))
			EFFECTS:Effect("RocketLauncher", item, "Fire")
			
			EVENTS.Gun:Fire("Update", ammo)
			
			wait(0.4)
			
			Reload()
		end
	end
	
	function itemModule.Deactivate(self)
		
	end
	
	return itemModule
end

return module