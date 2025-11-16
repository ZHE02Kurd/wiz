-- Map Service (Server)
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Data.Config)

local MapService = {}

function MapService:CreateArena()
	-- Create arena folder
	local arena = Instance.new("Folder")
	arena.Name = "Arena"
	arena.Parent = Workspace

	-- Create ground
	local ground = Instance.new("Part")
	ground.Name = "Ground"
	ground.Size = Vector3.new(Config.MAP.SIZE, 1, Config.MAP.SIZE)
	ground.Position = Vector3.new(0, 0, 0)
	ground.Anchored = true
	ground.Material = Enum.Material.Grass
	ground.Color = Color3.fromRGB(100, 150, 80)
	ground.Parent = arena

	-- Create walls
	local wallHeight = 20
	local wallThickness = 2
	local walls = {
		{ Vector3.new(0, wallHeight / 2, Config.MAP.SIZE / 2 + wallThickness / 2), Vector3.new(Config.MAP.SIZE, wallHeight, wallThickness) },
		{ Vector3.new(0, wallHeight / 2, -Config.MAP.SIZE / 2 - wallThickness / 2), Vector3.new(Config.MAP.SIZE, wallHeight, wallThickness) },
		{ Vector3.new(Config.MAP.SIZE / 2 + wallThickness / 2, wallHeight / 2, 0), Vector3.new(wallThickness, wallHeight, Config.MAP.SIZE) },
		{ Vector3.new(-Config.MAP.SIZE / 2 - wallThickness / 2, wallHeight / 2, 0), Vector3.new(wallThickness, wallHeight, Config.MAP.SIZE) },
	}

	for i, wallData in walls do
		local wall = Instance.new("Part")
		wall.Name = "Wall" .. i
		wall.Size = wallData[2]
		wall.Position = wallData[1]
		wall.Anchored = true
		wall.Material = Enum.Material.Concrete
		wall.Color = Color3.fromRGB(80, 80, 80)
		wall.Parent = arena
	end

	print("✅ Arena created")
end

function MapService:SpawnChests()
	local chestsFolder = Instance.new("Folder")
	chestsFolder.Name = "Chests"
	chestsFolder.Parent = Workspace

	for i = 1, Config.MAP.CHEST_COUNT do
		local randomX = math.random(-Config.MAP.SIZE / 2 + 20, Config.MAP.SIZE / 2 - 20)
		local randomZ = math.random(-Config.MAP.SIZE / 2 + 20, Config.MAP.SIZE / 2 - 20)

		local chest = Instance.new("Part")
		chest.Name = "Chest"
		chest.Size = Vector3.new(4, 3, 3)
		chest.Position = Vector3.new(randomX, 2, randomZ)
		chest.Anchored = true
		chest.Material = Enum.Material.Wood
		chest.Color = Color3.fromRGB(139, 90, 43)
		chest.CanCollide = false
		chest.Parent = chestsFolder

		-- Add visual indicator
		local highlight = Instance.new("SelectionBox")
		highlight.LineThickness = 0.05
		highlight.Color3 = Color3.fromRGB(255, 215, 0)
		highlight.Adornee = chest
		highlight.Parent = chest
	end

	print("✅ Spawned", Config.MAP.CHEST_COUNT, "chests")
end

function MapService:SpawnCrystals()
	local crystalsFolder = Instance.new("Folder")
	crystalsFolder.Name = "Crystals"
	crystalsFolder.Parent = Workspace

	for i = 1, Config.MAP.CRYSTAL_COUNT do
		local randomX = math.random(-Config.MAP.SIZE / 2 + 10, Config.MAP.SIZE / 2 - 10)
		local randomZ = math.random(-Config.MAP.SIZE / 2 + 10, Config.MAP.SIZE / 2 - 10)

		local crystal = Instance.new("Part")
		crystal.Name = "Crystal"
		crystal.Size = Vector3.new(2, 3, 2)
		crystal.Position = Vector3.new(randomX, 2, randomZ)
		crystal.Anchored = true
		crystal.Material = Enum.Material.Neon
		crystal.Color = Color3.fromRGB(100, 200, 255)
		crystal.CanCollide = false
		crystal.Parent = crystalsFolder

		-- Make it bob
		task.spawn(function()
			local startY = crystal.Position.Y
			while crystal.Parent do
				crystal.CFrame = crystal.CFrame * CFrame.Angles(0, math.rad(2), 0)
				crystal.Position = Vector3.new(
					crystal.Position.X,
					startY + math.sin(tick() * 2) * 0.5,
					crystal.Position.Z
				)
				task.wait(0.03)
			end
		end)
	end

	print("✅ Spawned", Config.MAP.CRYSTAL_COUNT, "crystals")
end

function MapService:SetupChestInteraction()
	local chestsFolder = Workspace:WaitForChild("Chests")

	for _, chest in chestsFolder:GetChildren() do
		-- Touch detection for chests
		chest.Touched:Connect(function(hit)
			local character = hit.Parent
			if character and character:FindFirstChild("Humanoid") then
				local player = game.Players:GetPlayerFromCharacter(character)
				if player then
					self:OpenChest(chest, player)
				end
			end
		end)
	end
end

function MapService:OpenChest(chest: Part, player: Player)
	if chest:GetAttribute("Opened") then
		return
	end

	chest:SetAttribute("Opened", true)
	chest.Color = Color3.fromRGB(80, 50, 20)

	-- Remove highlight
	local highlight = chest:FindFirstChild("SelectionBox")
	if highlight then
		highlight:Destroy()
	end

	-- Spawn crystals around chest
	local numCrystals = math.random(5, 10)
	for i = 1, numCrystals do
		local angle = (i / numCrystals) * math.pi * 2
		local distance = 5
		local pos = chest.Position + Vector3.new(math.cos(angle) * distance, 3, math.sin(angle) * distance)

		local crystal = Instance.new("Part")
		crystal.Name = "ChestCrystal"
		crystal.Size = Vector3.new(1.5, 2, 1.5)
		crystal.Position = pos
		crystal.Anchored = true
		crystal.Material = Enum.Material.Neon
		crystal.Color = Color3.fromRGB(100, 200, 255)
		crystal.CanCollide = false
		crystal.Parent = Workspace

		-- Add bobbing animation
		task.spawn(function()
			local startY = crystal.Position.Y
			while crystal.Parent do
				crystal.CFrame = crystal.CFrame * CFrame.Angles(0, math.rad(3), 0)
				crystal.Position = Vector3.new(
					crystal.Position.X,
					startY + math.sin(tick() * 3) * 0.3,
					crystal.Position.Z
				)
				task.wait(0.03)
			end
		end)

		-- Touch detection
		crystal.Touched:Connect(function(hit)
			if not crystal.Parent then
				return
			end
			
			local character = hit.Parent
			if character and character:FindFirstChild("Humanoid") then
				local touchPlayer = game.Players:GetPlayerFromCharacter(character)
				if touchPlayer then
					local PlayerDataService = require(script.Parent.PlayerDataService)
					PlayerDataService:AddXP(touchPlayer, Config.LEVELING.CRYSTAL_XP_LARGE)
					crystal:Destroy()
				end
			end
		end)

		-- Auto-destroy after 30 seconds
		task.delay(30, function()
			if crystal.Parent then
				crystal:Destroy()
			end
		end)
	end

	print(player.Name, "opened a chest!")
end

function MapService:SetupCrystalCollection()
	local crystalsFolder = Workspace:WaitForChild("Crystals")

	for _, crystal in crystalsFolder:GetChildren() do
		crystal.Touched:Connect(function(hit)
			if not crystal.Parent then
				return
			end

			local character = hit.Parent
			if character and character:FindFirstChild("Humanoid") then
				local player = game.Players:GetPlayerFromCharacter(character)
				if player then
					local PlayerDataService = require(script.Parent.PlayerDataService)
					PlayerDataService:AddXP(player, Config.LEVELING.CRYSTAL_XP_SMALL)
					crystal:Destroy()
				end
			end
		end)
	end
end

function MapService:Init()
	self:CreateArena()
	self:SpawnChests()
	self:SpawnCrystals()

	task.wait(1)

	self:SetupChestInteraction()
	self:SetupCrystalCollection()

	print("🗺️ Map initialized")
end

return MapService
