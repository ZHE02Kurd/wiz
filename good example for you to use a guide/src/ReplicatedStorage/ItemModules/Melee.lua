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
	local EFFECTS	= require(MODULES:WaitForChild("Effects"))
	local DAMAGE	= require(MODULES:WaitForChild("Damage"))
	
local EQUIP_COOLDOWN	= 0.2
	
-- module

local module	= {}

function module.Create(self, item)
	local itemModule	= {
		Item		= item;
		Equipped	= false;
		Connections	= {};
	}
	
	local config	= require(item:WaitForChild("Config"))
	
	local canAttack		= true
	local animations	= {}
	local attackIndex	= 1
	local numAttacks	= 0
	
	local lastAttack	= 0
	local equipTime		= 0
	
	-- functions
	
	local function Raycast(ray, ignore)
		local success	= false
		local h, p, n, humanoid
		
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
					if h.CanCollide then
						success	= true
					else
						table.insert(ignore, h)
					end
				end
			else
				success	= true
			end
		until success
		
		return h, p, n, humanoid
	end
	
	local function Attack(self)
		if canAttack then
			canAttack	= false
			
			local character	= PLAYER.Character
			local rootPart	= character.HumanoidRootPart
			local handle	= self.Item.PrimaryPart
			local blade		= handle.Blade
			
			if tick() - lastAttack > 0.3 then
				attackIndex	= 1
			end
			
			local anim	= animations["Attack" .. tostring(attackIndex)]
			local t		= anim.Length
			local hits	= {}
			
			rootPart.Velocity	= rootPart.Velocity * 0.5 + rootPart.CFrame.lookVector * config.Dash
			
			anim:Play()
			REMOTES.Melee:FireServer("Init", item, attackIndex)
			EFFECTS:Effect("Swing", item, anim.Length)
			
			local start	= tick()
			repeat
				RunService.RenderStepped:wait()
				local alpha	= math.min((tick() - start) / t, 1)
				
				local ray	= Ray.new(rootPart.Position, blade.WorldPosition - rootPart.Position)
				local hit, pos, normal, humanoid	= Raycast(ray, {character})
				
				if humanoid then
					if DAMAGE:PlayerCanDamage(PLAYER, humanoid) then
						if not hits[humanoid] then
							hits[humanoid]	= true
							
							local armor		= (humanoid:FindFirstChild("Armor") and humanoid.Armor.Value > 0)
							EFFECTS:Effect("Damage", humanoid, pos, normal)
							EVENTS.Hitmarker:Fire(pos, config.Damage, armor)
							REMOTES.Melee:FireServer("Hit", item, humanoid)
						end
					end
				end
			until alpha == 1 or not self.Equipped
			
			attackIndex	= attackIndex + 1
			if attackIndex > numAttacks then
				attackIndex	= 1
			end
			
			lastAttack	= tick()
			canAttack	= true
		end
	end
	
	-- item functions
	
	function itemModule.Connect(self)
		local character	= PLAYER.Character
		local humanoid	= character:WaitForChild("Humanoid")
		
		for _, animation in pairs(self.Item:WaitForChild("Animations"):GetChildren()) do
			animations[animation.Name]	= humanoid:LoadAnimation(animation)
			
			if string.match(animation.Name, "^Attack") then
				numAttacks	= numAttacks + 1
			end
		end
	end
	
	function itemModule.Disconnect(self)
		-- called when the item leaves the client's control
		for _, connection in pairs(self.Connections) do
			connection:Disconnect()
		end
		self.Connections	= {}
		
		print("disconnect " .. item.Name)
	end
	
	function itemModule.Equip(self)
		-- called when the item is equipped
		self.Equipped	= true
		equipTime		= tick()
		
		animations.Idle:Play(0.1, 0.9)
		
		if animations.Equip then
			animations.Equip:Play(0, 1, 1)
		end
	end
	
	function itemModule.Unequip(self)
		-- called when the item is unequipped
		self.Equipped	= false
		
		for _, animation in pairs(animations) do
			animation:Stop()
		end
	end
	
	function itemModule.Activate(self)
		-- called when the item is activated
		if tick() - equipTime >= EQUIP_COOLDOWN then
			Attack(self)
		end
	end
	
	function itemModule.Deactivate(self)
		-- called when then item is deactivated
	end
	
	return itemModule
end

return module