-- Input Controller (Client) - Cross-platform support
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local ContextActionService = game:GetService("ContextActionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local humanoid = character:WaitForChild("Humanoid") :: Humanoid
local rootPart = character:WaitForChild("HumanoidRootPart") :: Part
local camera = workspace.CurrentCamera

local RemoteEvents = ReplicatedStorage:WaitForChild("RemoteEvents")
local CastSpell = RemoteEvents:WaitForChild("CastSpell")

local InputController = {}
InputController.MoveDirection = Vector2.zero
InputController.IsShooting = false
InputController.IsMobile = false

-- Setup camera
function InputController:SetupCamera()
	camera.CameraType = Enum.CameraType.Scriptable
	
	local function updateCamera()
		if rootPart and rootPart.Parent then
			local offset = Vector3.new(0, 40, 24) -- Closer to character (was 50, 30)
			local cameraPosition = rootPart.Position + offset
			camera.CFrame = CFrame.new(cameraPosition, rootPart.Position)
		end
	end
	
	RunService.RenderStepped:Connect(updateCamera)
end

-- Create mobile UI
function InputController:CreateMobileUI()
	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = "MobileControls"
	screenGui.ResetOnSpawn = false
	screenGui.Parent = player:WaitForChild("PlayerGui")

	-- Movement Joystick
	local joystickFrame = Instance.new("Frame")
	joystickFrame.Name = "Joystick"
	joystickFrame.Size = UDim2.new(0, 150, 0, 150)
	joystickFrame.Position = UDim2.new(0, 50, 1, -200)
	joystickFrame.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
	joystickFrame.BackgroundTransparency = 0.5
	joystickFrame.Parent = screenGui

	local joystickCorner = Instance.new("UICorner")
	joystickCorner.CornerRadius = UDim.new(1, 0)
	joystickCorner.Parent = joystickFrame

	local joystickStick = Instance.new("Frame")
	joystickStick.Name = "Stick"
	joystickStick.Size = UDim2.new(0, 60, 0, 60)
	joystickStick.Position = UDim2.new(0.5, -30, 0.5, -30)
	joystickStick.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	joystickStick.BackgroundTransparency = 0.3
	joystickStick.Parent = joystickFrame

	local stickCorner = Instance.new("UICorner")
	stickCorner.CornerRadius = UDim.new(1, 0)
	stickCorner.Parent = joystickStick

	-- Shoot Button
	local shootButton = Instance.new("TextButton")
	shootButton.Name = "ShootButton"
	shootButton.Size = UDim2.new(0, 120, 0, 120)
	shootButton.Position = UDim2.new(1, -170, 1, -170)
	shootButton.BackgroundColor3 = Color3.fromRGB(255, 85, 0)
	shootButton.BackgroundTransparency = 0.3
	shootButton.Text = "🔥"
	shootButton.TextSize = 48
	shootButton.Parent = screenGui

	local shootCorner = Instance.new("UICorner")
	shootCorner.CornerRadius = UDim.new(1, 0)
	shootCorner.Parent = shootButton

	return screenGui, joystickFrame, joystickStick, shootButton
end

function InputController:SetupMobileJoystick(joystickFrame: Frame, joystickStick: Frame)
	local dragging = false

	local function updateJoystick(input: InputObject)
		if not dragging then
			return
		end

		local frameCenter = joystickFrame.AbsolutePosition + joystickFrame.AbsoluteSize / 2
		local delta = Vector2.new(input.Position.X, input.Position.Y) - frameCenter
		local maxRadius = joystickFrame.AbsoluteSize.X / 2 - 30

		if delta.Magnitude > maxRadius then
			delta = delta.Unit * maxRadius
		end

		joystickStick.Position = UDim2.new(0.5, delta.X, 0.5, delta.Y)

		-- Update move direction (normalized)
		self.MoveDirection = delta / maxRadius
	end

	joystickFrame.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
			dragging = true
			updateJoystick(input)
		end
	end)

	joystickFrame.InputChanged:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseMovement then
			updateJoystick(input)
		end
	end)

	joystickFrame.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
			dragging = false
			joystickStick.Position = UDim2.new(0.5, -30, 0.5, -30)
			self.MoveDirection = Vector2.zero
		end
	end)
end

function InputController:SetupMobileShootButton(shootButton: TextButton)
	shootButton.MouseButton1Down:Connect(function()
		self.IsShooting = true
	end)

	shootButton.MouseButton1Up:Connect(function()
		self.IsShooting = false
	end)
end

-- Desktop/Console Controls
function InputController:SetupDesktopControls()
	-- WASD Movement
	local moveVector = Vector2.zero
	
	UserInputService.InputBegan:Connect(function(input, gameProcessed)
		if gameProcessed then return end
		
		if input.KeyCode == Enum.KeyCode.W then
			moveVector = Vector2.new(moveVector.X, -1)
		elseif input.KeyCode == Enum.KeyCode.S then
			moveVector = Vector2.new(moveVector.X, 1)
		elseif input.KeyCode == Enum.KeyCode.A then
			moveVector = Vector2.new(-1, moveVector.Y)
		elseif input.KeyCode == Enum.KeyCode.D then
			moveVector = Vector2.new(1, moveVector.Y)
		elseif input.KeyCode == Enum.KeyCode.E or input.KeyCode == Enum.KeyCode.Space then
			self.IsShooting = true
		end
		
		self.MoveDirection = moveVector
	end)
	
	UserInputService.InputEnded:Connect(function(input, gameProcessed)
		if input.KeyCode == Enum.KeyCode.W then
			moveVector = Vector2.new(moveVector.X, moveVector.Y == -1 and 0 or moveVector.Y)
		elseif input.KeyCode == Enum.KeyCode.S then
			moveVector = Vector2.new(moveVector.X, moveVector.Y == 1 and 0 or moveVector.Y)
		elseif input.KeyCode == Enum.KeyCode.A then
			moveVector = Vector2.new(moveVector.X == -1 and 0 or moveVector.X, moveVector.Y)
		elseif input.KeyCode == Enum.KeyCode.D then
			moveVector = Vector2.new(moveVector.X == 1 and 0 or moveVector.X, moveVector.Y)
		elseif input.KeyCode == Enum.KeyCode.E or input.KeyCode == Enum.KeyCode.Space then
			self.IsShooting = false
		end
		
		self.MoveDirection = moveVector
	end)
end

function InputController:UpdateMovement()
	if self.MoveDirection.Magnitude > 0 then
		-- Convert screen space to world space based on camera
		local cameraCFrame = camera.CFrame
		local flatCameraCFrame = CFrame.new(
			cameraCFrame.Position,
			cameraCFrame.Position + Vector3.new(cameraCFrame.LookVector.X, 0, cameraCFrame.LookVector.Z)
		)
		
		-- Create movement vector
		local moveVector = Vector3.new(self.MoveDirection.X, 0, self.MoveDirection.Y)
		local worldMoveVector = flatCameraCFrame:VectorToWorldSpace(moveVector)
		
		-- Move character
		humanoid:Move(worldMoveVector)
		
		-- Rotate character to face movement direction
		if worldMoveVector.Magnitude > 0.1 then
			local lookAtPosition = rootPart.Position + worldMoveVector
			rootPart.CFrame = CFrame.new(rootPart.Position, lookAtPosition)
		end
	end
end

function InputController:TryCastSpell()
	if self.IsShooting and rootPart and rootPart.Parent then
		-- Get direction character is facing
		local lookVector = rootPart.CFrame.LookVector
		local direction = Vector3.new(lookVector.X, 0, lookVector.Z).Unit
		
		-- Make sure we have a valid direction
		if direction.Magnitude > 0 then
			CastSpell:FireServer(direction)
			print("🔥 Casting spell in direction:", direction)
		end
		
		self.IsShooting = false -- Single shot per press
	end
end

function InputController:Init()
	-- Setup camera first
	self:SetupCamera()
	
	-- Detect platform and setup appropriate controls
	self.IsMobile = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled
	
	if self.IsMobile then
		local screenGui, joystickFrame, joystickStick, shootButton = self:CreateMobileUI()
		self:SetupMobileJoystick(joystickFrame, joystickStick)
		self:SetupMobileShootButton(shootButton)
		print("✅ Mobile controls initialized")
	else
		self:SetupDesktopControls()
		print("✅ Desktop/Console controls initialized (WASD + E/SPACE)")
	end
	
	-- Update loop
	RunService.Heartbeat:Connect(function()
		self:UpdateMovement()
		self:TryCastSpell()
	end)
	
	print("✅ Input controller initialized")
end

return InputController
