--[[
    Name: CombatClient.luau
    Author: Magica Development Team
    Date: 2025-11-18
    Location: StarterPlayer/StarterPlayerScripts/CombatClient
    Affects: SpellModule.luau (server), all spell casting
    
    Description: This client-side script handles the player's combat controls.
    It creates the mobile joystick and shoot button, handles desktop controls
    (WASD, mouse, keyboard), and sends spell casting requests to the server.
    This is what makes the combat controls work.
]]--

-- Services
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local ContextActionService = game:GetService("ContextActionService")

-- Get local player
local player = Players.LocalPlayer
local camera = workspace.CurrentCamera

-- Character references (will be updated on respawn)
local character = player.Character or player.CharacterAdded:Wait()
local humanoid = character:WaitForChild("Humanoid")
local humanoidRootPart = character:WaitForChild("HumanoidRootPart")

-- Modules
local PlayerDataModule = require(ReplicatedStorage.Shared.Modules.PlayerDataModule)

-- Remotes (located in ReplicatedStorage.Remotes, not Shared.Remotes)
local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local CastSpellRemote = Remotes:WaitForChild("CastSpellCS")
local UseAbilityRemote = Remotes:WaitForChild("UseAbilityCS")

-- ========================================
-- UI SETUP
-- ========================================
local playerGui = player:WaitForChild("PlayerGui")
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "CombatUI"
screenGui.ResetOnSpawn = false
screenGui.Parent = playerGui

-- Movement Joystick (Left side - MOBILE)
local joystickFrame = Instance.new("Frame")
joystickFrame.Name = "Joystick"
joystickFrame.Size = UDim2.new(0, 150, 0, 150)
joystickFrame.Position = UDim2.new(0.05, 0, 0.7, 0) -- Bottom left
joystickFrame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
joystickFrame.BackgroundTransparency = 0.5
joystickFrame.BorderSizePixel = 0
joystickFrame.Visible = UserInputService.TouchEnabled -- Only show on mobile
joystickFrame.Parent = screenGui

-- Make joystick circular
local joystickCorner = Instance.new("UICorner")
joystickCorner.CornerRadius = UDim.new(1, 0)
joystickCorner.Parent = joystickFrame

-- Joystick knob
local joystickKnob = Instance.new("Frame")
joystickKnob.Name = "Knob"
joystickKnob.Size = UDim2.new(0, 60, 0, 60)
joystickKnob.Position = UDim2.new(0.5, -30, 0.5, -30)
joystickKnob.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
joystickKnob.BackgroundTransparency = 0.3
joystickKnob.BorderSizePixel = 0
joystickKnob.Parent = joystickFrame

local knobCorner = Instance.new("UICorner")
knobCorner.CornerRadius = UDim.new(1, 0)
knobCorner.Parent = joystickKnob

-- Shoot Button (Right side - BOTH MOBILE AND DESKTOP)
local shootButton = Instance.new("TextButton")
shootButton.Name = "ShootButton"
shootButton.Size = UDim2.new(0, 100, 0, 100)
shootButton.Position = UDim2.new(0.9, -100, 0.75, 0) -- Bottom right
shootButton.BackgroundColor3 = Color3.fromRGB(255, 100, 50)
shootButton.Text = "CAST"
shootButton.TextColor3 = Color3.fromRGB(255, 255, 255)
shootButton.Font = Enum.Font.GothamBold
shootButton.TextSize = 24
shootButton.BorderSizePixel = 0
shootButton.Parent = screenGui

local shootCorner = Instance.new("UICorner")
shootCorner.CornerRadius = UDim.new(1, 0)
shootCorner.Parent = shootButton

-- Ability Button (Q button - BOTH MOBILE AND DESKTOP)
local abilityButton = Instance.new("TextButton")
abilityButton.Name = "AbilityButton"
abilityButton.Size = UDim2.new(0, 70, 0, 70)
abilityButton.Position = UDim2.new(0.9, -100, 0.6, 0) -- Above shoot button
abilityButton.BackgroundColor3 = Color3.fromRGB(100, 100, 255)
abilityButton.Text = "Q"
abilityButton.TextColor3 = Color3.fromRGB(255, 255, 255)
abilityButton.Font = Enum.Font.GothamBold
abilityButton.TextSize = 32
abilityButton.BorderSizePixel = 0
abilityButton.Parent = screenGui

local abilityCorner = Instance.new("UICorner")
abilityCorner.CornerRadius = UDim.new(1, 0)
abilityCorner.Parent = abilityButton

-- ========================================
-- MOVEMENT VARIABLES
-- ========================================
local moveDirection = Vector3.new(0, 0, 0)
local joystickActive = false
local joystickTouchInput = nil

-- ========================================
-- MOBILE JOYSTICK LOGIC
-- ========================================
local function updateJoystick(input)
	if not joystickActive then return end
	
	-- Get touch position relative to joystick center
	local joystickCenter = joystickFrame.AbsolutePosition + joystickFrame.AbsoluteSize / 2
	local touchPosition = Vector2.new(input.Position.X, input.Position.Y)
	local offset = touchPosition - joystickCenter
	
	-- Limit offset to joystick radius
	local maxRadius = joystickFrame.AbsoluteSize.X / 2
	local distance = offset.Magnitude
	if distance > maxRadius then
		offset = offset.Unit * maxRadius
	end
	
	-- Update knob position
	joystickKnob.Position = UDim2.new(0.5, offset.X, 0.5, offset.Y)
	
	-- Calculate movement direction
	if distance > 5 then -- Deadzone
		local normalizedOffset = offset / maxRadius
		moveDirection = Vector3.new(normalizedOffset.X, 0, -normalizedOffset.Y)
	else
		moveDirection = Vector3.new(0, 0, 0)
	end
end

joystickFrame.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.Touch then
		joystickActive = true
		joystickTouchInput = input
		updateJoystick(input)
	end
end)

joystickFrame.InputChanged:Connect(function(input)
	if input == joystickTouchInput then
		updateJoystick(input)
	end
end)

joystickFrame.InputEnded:Connect(function(input)
	if input == joystickTouchInput then
		joystickActive = false
		joystickTouchInput = nil
		moveDirection = Vector3.new(0, 0, 0)
		-- Reset knob position
		joystickKnob.Position = UDim2.new(0.5, -30, 0.5, -30)
	end
end)

-- ========================================
-- DESKTOP KEYBOARD MOVEMENT
-- ========================================
local keysPressed = {
	W = false,
	A = false,
	S = false,
	D = false,
	Up = false,
	Down = false,
	Left = false,
	Right = false
}

UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then return end
	
	if input.KeyCode == Enum.KeyCode.W then keysPressed.W = true end
	if input.KeyCode == Enum.KeyCode.A then keysPressed.A = true end
	if input.KeyCode == Enum.KeyCode.S then keysPressed.S = true end
	if input.KeyCode == Enum.KeyCode.D then keysPressed.D = true end
	if input.KeyCode == Enum.KeyCode.Up then keysPressed.Up = true end
	if input.KeyCode == Enum.KeyCode.Down then keysPressed.Down = true end
	if input.KeyCode == Enum.KeyCode.Left then keysPressed.Left = true end
	if input.KeyCode == Enum.KeyCode.Right then keysPressed.Right = true end
end)

UserInputService.InputEnded:Connect(function(input, gameProcessed)
	if input.KeyCode == Enum.KeyCode.W then keysPressed.W = false end
	if input.KeyCode == Enum.KeyCode.A then keysPressed.A = false end
	if input.KeyCode == Enum.KeyCode.S then keysPressed.S = false end
	if input.KeyCode == Enum.KeyCode.D then keysPressed.D = false end
	if input.KeyCode == Enum.KeyCode.Up then keysPressed.Up = false end
	if input.KeyCode == Enum.KeyCode.Down then keysPressed.Down = false end
	if input.KeyCode == Enum.KeyCode.Left then keysPressed.Left = false end
	if input.KeyCode == Enum.KeyCode.Right then keysPressed.Right = false end
end)

-- Update move direction from keyboard
RunService.Heartbeat:Connect(function()
	if not UserInputService.TouchEnabled then -- Only on desktop
		local x = 0
		local z = 0
		
		-- WASD or Arrow keys
		if keysPressed.W or keysPressed.Up then z = z - 1 end
		if keysPressed.S or keysPressed.Down then z = z + 1 end
		if keysPressed.A or keysPressed.Left then x = x - 1 end
		if keysPressed.D or keysPressed.Right then x = x + 1 end
		
		if x ~= 0 or z ~= 0 then
			moveDirection = Vector3.new(x, 0, z).Unit
		else
			moveDirection = Vector3.new(0, 0, 0)
		end
	end
end)

-- ========================================
-- CHARACTER MOVEMENT AND ROTATION
-- ========================================
-- This handles the actual character movement based on the camera (MOBA-style controls)
-- The character moves relative to where the camera is looking, and smoothly rotates to face the movement direction

RunService.Heartbeat:Connect(function()
	if moveDirection.Magnitude > 0.1 then
		-- Get camera CFrame for camera-relative movement (like MOBA games)
		local cameraCFrame = camera.CFrame
		
		-- Calculate move direction relative to camera (W = forward from camera view, S = backward from camera view)
		-- This makes the controls feel like League of Legends / MOBA games
		local relativeDirection = (cameraCFrame * CFrame.new(moveDirection.X, 0, moveDirection.Z)).Position - cameraCFrame.Position
		relativeDirection = Vector3.new(relativeDirection.X, 0, relativeDirection.Z) -- Flatten to ground plane
		
		-- Only move if we have a valid direction
		if relativeDirection.Magnitude > 0.01 then
			-- Normalize the direction so diagonal movement isn't faster
			local normalizedDirection = relativeDirection.Unit
			
			-- Tell the humanoid to walk in this direction
			-- This uses Roblox's built-in movement system which respects WalkSpeed
			humanoid:Move(normalizedDirection)
			
			-- Smoothly rotate character to face movement direction (not instant snap)
			-- This makes the character look where they're going without feeling "stuck"
			local currentLookVector = humanoidRootPart.CFrame.LookVector
			local targetLookVector = normalizedDirection
			
			-- Lerp (smooth blend) between current and target rotation
			local newLookVector = currentLookVector:Lerp(targetLookVector, 0.25) -- 0.25 = rotation speed
			
			-- Apply the new rotation (only affects Y-axis rotation, keeps character upright)
			humanoidRootPart.CFrame = CFrame.new(humanoidRootPart.Position, humanoidRootPart.Position + newLookVector)
		end
	else
		-- No input - stop moving
		humanoid:Move(Vector3.zero)
	end
end)

-- ========================================
-- SPELL CASTING
-- ========================================
local function castSpell()
	-- Get where the player is aiming (in front of where they're facing)
	local aimPosition = humanoidRootPart.Position + (humanoidRootPart.CFrame.LookVector * 100)
	
	-- Tell server to cast spell
	CastSpellRemote:FireServer(aimPosition)
	
	print("🔮 Casting spell!")
end

-- Shoot button (mobile touch and desktop click)
shootButton.MouseButton1Click:Connect(castSpell)

-- Desktop keyboard shortcuts for casting
ContextActionService:BindAction("CastSpell", function(actionName, inputState, inputObject)
	if inputState == Enum.UserInputState.Begin then
		castSpell()
	end
end, false, Enum.KeyCode.E, Enum.KeyCode.Space)

-- Also allow left mouse click to cast
UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then return end
	
	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		castSpell()
	end
end)

-- ========================================
-- ABILITY USAGE (Q BUTTON)
-- ========================================
local function useAbility()
	-- Tell server to use ability
	UseAbilityRemote:FireServer()
	
	print("⚡ Using ability!")
end

-- Ability button (mobile and desktop)
abilityButton.MouseButton1Click:Connect(useAbility)

-- Desktop Q and G keys
ContextActionService:BindAction("UseAbility", function(actionName, inputState, inputObject)
	if inputState == Enum.UserInputState.Begin then
		useAbility()
	end
end, false, Enum.KeyCode.Q, Enum.KeyCode.G)

-- ========================================
-- CAMERA SETUP (ISOMETRIC VIEW)
-- ========================================
-- Set up the fixed-angle isometric camera like League of Legends
camera.CameraType = Enum.CameraType.Scriptable

RunService.RenderStepped:Connect(function()
	-- Get current character (handles respawns)
	local currentCharacter = player.Character
	if not currentCharacter then return end
	
	local currentHRP = currentCharacter:FindFirstChild("HumanoidRootPart")
	if not currentHRP then return end
	
	-- Position camera above and behind player at fixed angle
	local offset = Vector3.new(0, 30, 20) -- 30 studs up, 20 studs back
	local targetPosition = currentHRP.Position + offset
	
	camera.CFrame = CFrame.new(targetPosition, currentHRP.Position)
end)

-- ========================================
-- CHARACTER RESPAWN HANDLER
-- ========================================
-- Update character references when player respawns
player.CharacterAdded:Connect(function(newCharacter)
	print("[CombatClient] 🔄 Character respawned - updating references")
	character = newCharacter
	humanoid = character:WaitForChild("Humanoid")
	humanoidRootPart = character:WaitForChild("HumanoidRootPart")
	
	-- Reset camera to follow new character
	camera.CameraType = Enum.CameraType.Scriptable
	camera.CameraSubject = humanoid
	
	print("[CombatClient] ✅ Character references updated - camera should follow")
end)

print("✅ Combat controls initialized!")

-- Return empty table (this is an initializer script)
return {}
