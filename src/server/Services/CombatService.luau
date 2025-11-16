-- Combat Service (Server)
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local Debris = game:GetService("Debris")

local Config = require(ReplicatedStorage.Shared.Data.Config)

local CombatService = {}

local RemoteEvents = ReplicatedStorage:WaitForChild("RemoteEvents")
local CastSpell = RemoteEvents:WaitForChild("CastSpell")
local ProjectileHit = RemoteEvents:WaitForChild("ProjectileHit")

function CombatService:CreateProjectile(player: Player, spellData, direction: Vector3)
	local character = player.Character
	if not character then
		return
	end

	local rootPart = character:FindFirstChild("HumanoidRootPart") :: Part
	if not rootPart then
		return
	end

	-- Create projectile
	local projectile = Instance.new("Part")
	projectile.Name = "Projectile"
	projectile.Size = Vector3.new(1, 1, 2)
	projectile.CFrame = CFrame.new(rootPart.Position + direction * 3, rootPart.Position + direction * 100)
	projectile.Anchored = true -- Changed to true for performance
	projectile.CanCollide = false
	projectile.Material = Enum.Material.Neon

	-- Color based on element
	local colors = {
		Fire = Color3.fromRGB(255, 85, 0),
		Water = Color3.fromRGB(0, 170, 255),
		Earth = Color3.fromRGB(139, 90, 43),
		Lightning = Color3.fromRGB(255, 255, 0),
		Lava = Color3.fromRGB(200, 0, 0),
		Nature = Color3.fromRGB(0, 200, 0),
		Basic = Color3.fromRGB(200, 200, 200),
	}
	projectile.Color = colors[spellData.Element] or colors.Basic

	-- Add light effect
	local light = Instance.new("PointLight")
	light.Brightness = 2
	light.Range = 10
	light.Color = projectile.Color
	light.Parent = projectile

	projectile.Parent = Workspace

	-- Store projectile data
	projectile:SetAttribute("Damage", spellData.Damage)
	projectile:SetAttribute("Owner", player.Name)
	projectile:SetAttribute("StartTime", tick())

	-- Movement using TweenService-like manual updates (more efficient)
	local velocity = direction * spellData.ProjectileSpeed
	local maxDistance = spellData.Range
	local startPos = projectile.Position
	local startTime = tick()
	
	-- Create hit detection region
	local hitPlayers = {}
	
	-- Update projectile position
	local connection
	connection = game:GetService("RunService").Heartbeat:Connect(function(dt)
		if not projectile.Parent then
			connection:Disconnect()
			return
		end
		
		-- Move projectile
		local newPos = projectile.Position + velocity * dt
		projectile.Position = newPos
		
		-- Check distance
		if (newPos - startPos).Magnitude > maxDistance then
			projectile:Destroy()
			connection:Disconnect()
			return
		end
		
		-- Check for hits with region3
		local region = Region3.new(newPos - Vector3.new(2, 2, 2), newPos + Vector3.new(2, 2, 2))
		region = region:ExpandToGrid(4)
		
		for _, part in workspace:FindPartsInRegion3(region, character, 100) do
			local hitCharacter = part.Parent
			if hitCharacter and hitCharacter:FindFirstChild("Humanoid") then
				local hitPlayer = game.Players:GetPlayerFromCharacter(hitCharacter)
				if hitPlayer and hitPlayer ~= player and not hitPlayers[hitPlayer] then
					hitPlayers[hitPlayer] = true
					self:OnProjectileHit(projectile, part, player, spellData)
					projectile:Destroy()
					connection:Disconnect()
					return
				end
			end
		end
	end)

	-- Auto-destroy after max time
	Debris:AddItem(projectile, maxDistance / spellData.ProjectileSpeed)

	return projectile
end

function CombatService:OnProjectileHit(projectile: Part, hit: BasePart, attacker: Player, spellData)
	if not projectile.Parent then
		return
	end

	-- Check if hit a player
	local character = hit.Parent
	if character and character:FindFirstChild("Humanoid") then
		local hitPlayer = game.Players:GetPlayerFromCharacter(character)
		if hitPlayer and hitPlayer ~= attacker then
			-- Deal damage
			local PlayerDataService = require(script.Parent.PlayerDataService)
			PlayerDataService:DamagePlayer(hitPlayer, spellData.Damage, attacker)

			-- Visual feedback
			ProjectileHit:FireAllClients(projectile.Position, spellData.Element)
		end
	end
end

function CombatService:Init()
	-- Listen for spell casts
	CastSpell.OnServerEvent:Connect(function(player, direction)
		print("🎯 Spell cast requested by", player.Name, "Direction:", direction)
		
		local PlayerDataService = require(script.Parent.PlayerDataService)
		local data = PlayerDataService:GetPlayerData(player)

		if not data then
			print("❌ No player data found for", player.Name)
			return
		end

		-- Check cooldown
		local currentTime = tick()
		if data.CurrentSpell.LastCastTime then
			local timeSinceLastCast = currentTime - data.CurrentSpell.LastCastTime
			if timeSinceLastCast < data.CurrentSpell.Cooldown then
				print("⏳ Spell on cooldown for", player.Name, "Wait:", data.CurrentSpell.Cooldown - timeSinceLastCast)
				return
			end
		end

		-- Cast spell
		data.CurrentSpell.LastCastTime = currentTime
		print("✅ Creating projectile for", player.Name)
		self:CreateProjectile(player, data.CurrentSpell, direction)
	end)
	
	print("⚔️ Combat service initialized")
end

return CombatService
