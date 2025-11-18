--!strict
-- ================================================================
-- LEVEL UP CLIENT
-- ================================================================
-- Handles the level-up UI and choice selection
-- Listens for LevelUpChoiceSC from server, displays UI with 3 buttons,
-- sends player choice back via LevelUpChoiceCS
-- ================================================================

print("[DEBUG] LevelUpClient initializing...")

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- Modules
local Remotes = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Remotes"))

-- RemoteEvents
local LevelUpChoiceSC = Remotes.LevelUpChoiceSC -- Server → Client
local LevelUpChoiceCS = Remotes.LevelUpChoiceCS -- Client → Server

-- ================================================================
-- UI STATE
-- ================================================================
local levelUpFrame: ScreenGui? = nil
local isUIOpen = false

-- ================================================================
-- UI CREATION
-- ================================================================

local function createLevelUpUI(): ScreenGui
	print("[LevelUpClient] 🎨 Creating Level-Up UI...")
	
	-- Main ScreenGui
	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = "LevelUpUI"
	screenGui.DisplayOrder = 100 -- High priority
	screenGui.ResetOnSpawn = false
	screenGui.IgnoreGuiInset = true
	screenGui.Enabled = false -- Hidden by default
	
	-- Background blur/darkening
	local background = Instance.new("Frame")
	background.Name = "Background"
	background.Size = UDim2.new(1, 0, 1, 0)
	background.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	background.BackgroundTransparency = 0.5
	background.BorderSizePixel = 0
	background.Parent = screenGui
	
	-- Main container frame
	local container = Instance.new("Frame")
	container.Name = "Container"
	container.Size = UDim2.new(0, 600, 0, 400)
	container.AnchorPoint = Vector2.new(0.5, 0.5)
	container.Position = UDim2.new(0.5, 0, 0.5, 0)
	container.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
	container.BorderSizePixel = 0
	container.Parent = background
	
	-- Add rounded corners
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 16)
	corner.Parent = container
	
	-- Title
	local title = Instance.new("TextLabel")
	title.Name = "Title"
	title.Size = UDim2.new(1, -40, 0, 60)
	title.Position = UDim2.new(0, 20, 0, 20)
	title.BackgroundTransparency = 1
	title.Font = Enum.Font.GothamBold
	title.Text = "⭐ LEVEL UP! ⭐"
	title.TextColor3 = Color3.fromRGB(255, 220, 100)
	title.TextSize = 32
	title.Parent = container
	
	-- Subtitle
	local subtitle = Instance.new("TextLabel")
	subtitle.Name = "Subtitle"
	subtitle.Size = UDim2.new(1, -40, 0, 30)
	subtitle.Position = UDim2.new(0, 20, 0, 80)
	subtitle.BackgroundTransparency = 1
	subtitle.Font = Enum.Font.Gotham
	subtitle.Text = "Choose your power:"
	subtitle.TextColor3 = Color3.fromRGB(200, 200, 200)
	subtitle.TextSize = 18
	subtitle.Parent = container
	
	-- Choice buttons container
	local buttonsContainer = Instance.new("Frame")
	buttonsContainer.Name = "ButtonsContainer"
	buttonsContainer.Size = UDim2.new(1, -40, 0, 220)
	buttonsContainer.Position = UDim2.new(0, 20, 0, 130)
	buttonsContainer.BackgroundTransparency = 1
	buttonsContainer.Parent = container
	
	-- Create 3 choice buttons
	for i = 1, 3 do
		local button = Instance.new("TextButton")
		button.Name = "Choice" .. i
		button.Size = UDim2.new(1, 0, 0, 60)
		button.Position = UDim2.new(0, 0, 0, (i - 1) * 70)
		button.BackgroundColor3 = Color3.fromRGB(50, 50, 70)
		button.BorderSizePixel = 0
		button.Font = Enum.Font.GothamBold
		button.Text = "Choice " .. i
		button.TextColor3 = Color3.fromRGB(255, 255, 255)
		button.TextSize = 20
		button.AutoButtonColor = false
		button.Parent = buttonsContainer
		
		-- Button rounded corners
		local buttonCorner = Instance.new("UICorner")
		buttonCorner.CornerRadius = UDim.new(0, 8)
		buttonCorner.Parent = button
		
		-- Button hover effect
		button.MouseEnter:Connect(function()
			TweenService:Create(button, TweenInfo.new(0.2), {
				BackgroundColor3 = Color3.fromRGB(70, 70, 100)
			}):Play()
		end)
		
		button.MouseLeave:Connect(function()
			TweenService:Create(button, TweenInfo.new(0.2), {
				BackgroundColor3 = Color3.fromRGB(50, 50, 70)
			}):Play()
		end)
	end
	
	screenGui.Parent = playerGui
	print("[LevelUpClient] ✅ Level-Up UI created successfully")
	
	return screenGui
end

-- ================================================================
-- UI DISPLAY
-- ================================================================

local function showLevelUpUI(level: number, isElement: boolean, choices: {string})
	print("[LevelUpClient] 📺 Showing Level-Up UI...")
	print("[LevelUpClient] Level:", level)
	print("[LevelUpClient] Is Element Choice:", isElement)
	print("[LevelUpClient] Choices:", table.concat(choices, ", "))
	
	if isUIOpen then
		warn("[LevelUpClient] ⚠️ UI is already open, ignoring new request")
		return
	end
	
	-- Create UI if it doesn't exist
	if not levelUpFrame then
		levelUpFrame = createLevelUpUI()
	end
	
	local frame = levelUpFrame :: ScreenGui
	local container = frame.Background.Container
	local buttonsContainer = container.ButtonsContainer
	
	-- Update subtitle based on choice type
	local subtitle = container.Subtitle :: TextLabel
	if isElement then
		subtitle.Text = "Choose an element to evolve your spell:"
	else
		subtitle.Text = "Choose a buff to enhance your stats:"
	end
	
	-- Update button texts with choices
	for i, choiceName in ipairs(choices) do
		local button = buttonsContainer:FindFirstChild("Choice" .. i) :: TextButton
		if button then
			button.Text = "🔥 " .. choiceName
			
			-- Set button click handler
			button.Activated:Connect(function()
				print("[LevelUpClient] ✅ Player selected:", choiceName)
				hideLevelUpUI()
				LevelUpChoiceCS:FireServer(choiceName)
			end)
		end
	end
	
	-- Show the UI with animation
	frame.Enabled = true
	isUIOpen = true
	
	-- Animate container entrance
	container.Position = UDim2.new(0.5, 0, -0.5, 0)
	TweenService:Create(container, TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
		Position = UDim2.new(0.5, 0, 0.5, 0)
	}):Play()
	
	print("[LevelUpClient] ✅ UI displayed successfully")
end

local function hideLevelUpUI()
	print("[LevelUpClient] 📴 Hiding Level-Up UI...")
	
	if not levelUpFrame then
		return
	end
	
	local frame = levelUpFrame :: ScreenGui
	local container = frame.Background.Container
	
	-- Animate container exit
	TweenService:Create(container, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.In), {
		Position = UDim2.new(0.5, 0, 1.5, 0)
	}):Play()
	
	task.wait(0.3)
	frame.Enabled = false
	isUIOpen = false
	
	print("[LevelUpClient] ✅ UI hidden successfully")
end

-- ================================================================
-- REMOTE EVENT LISTENERS
-- ================================================================

LevelUpChoiceSC.OnClientEvent:Connect(function(choiceData: {level: number, isElement: boolean, choices: {string}})
	print("[LevelUpClient] 📨 Received LevelUpChoiceSC from server")
	print("[LevelUpClient] Data:", choiceData)
	
	if not choiceData or not choiceData.choices then
		warn("[LevelUpClient] ❌ Invalid choice data received")
		return
	end
	
	showLevelUpUI(choiceData.level, choiceData.isElement, choiceData.choices)
end)

print("[LevelUpClient] ✅ Ready and listening for level-up events")

-- Return empty module (required for ModuleScript)
return {}
