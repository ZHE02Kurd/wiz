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
InputController.IsShooting = false
InputController.IsMobile = false

-- Setup camera
function InputController:SetupCamera()
	camera.CameraType = Enum.CameraType.Scriptable

	local function updateCamera()
		if rootPart and rootPart.Parent then
			local offset = Vector3.new(20, 35, 20) -- Slightly angled camera
			local cameraPosition = rootPart.Position + offset
			-- Look at a point slightly in front of the character for better angle
			local lookAtPoint = rootPart.Position + Vector3.new(0, -5, 0)
			camera.CFrame = CFrame.new(cameraPosition, lookAtPoint)
		end
	end

	RunService.RenderStepped:Connect(updateCamera)
end

-- Setup Mobile Controls (Using default Roblox movement + custom buttons)
function InputController:SetupMobileControls()
	-- Disable jumping
	humanoid:SetStateEnabled(Enum.HumanoidStateType.Jumping, false)

	-- Replace jump button with shoot button
	ContextActionService:BindAction(
		"ShootSpell",
		function(actionName, inputState, inputObject)
			if inputState == Enum.UserInputState.Begin then
				self.IsShooting = true
			elseif inputState == Enum.UserInputState.End then
				self.IsShooting = false
			end
			return Enum.ContextActionResult.Pass
		end,
		true, -- Create touch button
		Enum.KeyCode.ButtonR2 -- Fallback for controllers
	)

	-- Customize the button appearance
	ContextActionService:SetPosition("ShootSpell", UDim2.new(1, -70, 0.5, -70))
	ContextActionService:SetTitle("ShootSpell", "🔥")
	ContextActionService:SetImage("ShootSpell", "") -- Remove default image

	-- Optional: Add more custom buttons
	-- Example: Special ability button
	ContextActionService:BindAction("SpecialAbility", function(actionName, inputState, inputObject)
		if inputState == Enum.UserInputState.Begin then
			print("🌟 Special ability activated!")
			-- Add your special ability logic here
		end
		return Enum.ContextActionResult.Pass
	end, true, Enum.KeyCode.ButtonL2)

	ContextActionService:SetPosition("SpecialAbility", UDim2.new(1, -70, 0.5, 30))
	ContextActionService:SetTitle("SpecialAbility", "⚡")
	ContextActionService:SetImage("SpecialAbility", "")

	print("✅ Mobile controls initialized with default movement + custom buttons")
end

-- Desktop/Console Controls
function InputController:SetupDesktopControls()
	UserInputService.InputBegan:Connect(function(input, gameProcessed)
		if input.KeyCode == Enum.KeyCode.E or input.KeyCode == Enum.KeyCode.Space then
			self.IsShooting = true
		elseif input.UserInputType == Enum.UserInputType.MouseButton1 then
			self.IsShooting = true
		end
	end)

	UserInputService.InputEnded:Connect(function(input)
		if input.KeyCode == Enum.KeyCode.E or input.KeyCode == Enum.KeyCode.Space then
			self.IsShooting = false
		elseif input.UserInputType == Enum.UserInputType.MouseButton1 then
			self.IsShooting = false
		end
	end)
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
	self:SetupCamera()

	-- Detect platform
	self.IsMobile = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled

	if self.IsMobile then
		self:SetupMobileControls()
	else
		self:SetupDesktopControls()
		print("✅ Desktop/Console controls initialized (WASD + E/SPACE + Mouse)")
	end

	-- Update loop
	RunService.Heartbeat:Connect(function()
		self:TryCastSpell()
	end)

	print("✅ Input controller initialized")
end

return InputController
