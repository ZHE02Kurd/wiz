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
	local CONFIG	= require(MODULES:WaitForChild("Config"))
	local MOUSE		= require(MODULES:WaitForChild("Mouse"))
	local EFFECTS	= require(MODULES:WaitForChild("Effects"))
	local DAMAGE	= require(MODULES:WaitForChild("Damage"))
	local INPUT		= require(MODULES:WaitForChild("Input"))
	
local EQUIP_COOLDOWN	= 0.2

-- functions

local function Raycast(position, direction, ignore)
	local ray		= Ray.new(position, direction)
	local success	= false
	local h, p, n, humanoid
	
	table.insert(ignore, Workspace.Effects)
	
	repeat
		h, p, n	= Workspace:FindPartOnRayWithIgnoreList(ray, ignore)
		
		if h then
			humanoid	= h.Parent:FindFirstChildOfClass("Humanoid")
			if humanoid and humanoid.Health <= 0 then
				humanoid	= nil
			end
			if humanoid then
				success	= true
			else
				if h.CanCollide and h.Transparency < 1 then
					success	= true
				else
					table.insert(ignore, h)
					success	= false
				end
			end
		else
			success	= true
		end
	until success
	
	return h, p, n, humanoid
end

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
	
	local config		= CONFIG:GetConfig(item)
	local canShoot		= true
	local clicking		= false
	local reloading		= false
	local rCancelled	= false
	local equipTime		= 0
	
	local ammo	= item:WaitForChild("Ammo").Value
	
	local aiming	= false
	
	-- functions
	
	local function CanShoot()
		return itemModule.Equipped and canShoot and ammo > 0
	end
	
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
	
	local function Shoot()
		ammo	= ammo - 1
		
		local direction		= (MOUSE.WorldPosition - muzzle.WorldPosition).Unit
		
		if config.AimCorrection then
			direction	= (direction + Vector3.new(0, config.AimCorrection / 100, 0)).Unit
		end
		
		local projectileID	= EVENTS.GetProjectileID:Invoke()
		
		EVENTS.Projectile:Fire(PLAYER, item, projectileID, muzzle.WorldPosition, direction)
		REMOTES.RocketLauncher:FireServer(item, "Fire", projectileID, muzzle.WorldPosition, direction)
		
		if aiming then
			animations.AimShoot:Play(0, math.random(5, 10) / 10, 1)
		else
			animations.Shoot:Play(0, math.random(5, 10) / 10, 1)
		end
		
		EFFECTS:Effect("RocketLauncher", item, "Fire", ammo > 0)
		EVENTS.Gun:Fire("Update", ammo)
		EVENTS.Recoil:Fire(Vector3.new(math.random(-config.Recoil, config.Recoil) / 4, 0, math.random(config.Recoil / 2, config.Recoil)))
		
		if ammo > 0 then
			animations.Reload:Play(0.1, 1, 1 / config.Cooldown)
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
			if self.Equipped then
				EVENTS.Zoom:Fire(config.Zoom)
				EVENTS.Scope:Fire(config.Scope)
			end
		end))
		
		table.insert(self.Connections, item.Attachments.ChildRemoved:connect(function()
			config	= CONFIG:GetConfig(item)
			if self.Equipped then
				EVENTS.Zoom:Fire(config.Zoom)
				EVENTS.Scope:Fire(config.Scope)
			end
		end))
		
		table.insert(self.Connections, EVENTS.Aim.Event:connect(function(a)
			aiming	= a
			
			if self.Equipped then
				if aiming then
					animations.Idle:Stop()
					animations.Aim:Play()
				else
					animations.Aim:Stop()
					animations.Idle:Play()
				end
			end
		end))
	end
	
	function itemModule.Disconnect(self)
		for _, connection in pairs(self.Connections) do
			connection:Disconnect()
		end
		self.Connections	= {}
	end
	
	function itemModule.Equip(self)
		EVENTS.Zoom:Fire(config.Zoom)
		EVENTS.Scope:Fire(config.Scope)
		MOUSE.Reticle	= config.Reticle or "Gun"
		if aiming then
			animations.Aim:Play()
		else
			animations.Idle:Play()
		end
		animations.Equip:Play(0, 1, 1)
		
		ammo	= item.Ammo.Value
		
		EVENTS.Gun:Fire("Enable", config.Size, ammo)
		
		self.Equipped	= true
		equipTime		= tick()
		
		if ammo == 0 then
			spawn(function()
				Reload()
			end)
		end
	end
	
	function itemModule.Unequip(self)
		EVENTS.Zoom:Fire()
		EVENTS.Scope:Fire(false)
		MOUSE.Reticle	= "Default"
		
		for _, animation in pairs(animations) do
			animation:Stop()
		end
		
		EVENTS.Gun:Fire("Disable", config.Size, ammo)
		
		self.Equipped	= false
	end
	
	function itemModule.Activate(self)
		clicking	= true
		
		if CanShoot() then
			rCancelled	= true
			canShoot	= false
			Shoot()
			wait(config.Cooldown)
			canShoot	= true
		end
	end
	
	function itemModule.Deactivate(self)
		clicking	= false
	end
	
	return itemModule
end

return module