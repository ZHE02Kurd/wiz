-- UI Controller (Client)
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local RemoteEvents = ReplicatedStorage:WaitForChild("RemoteEvents")
local DamagePlayer = RemoteEvents:WaitForChild("DamagePlayer")
local AddXP = RemoteEvents:WaitForChild("AddXP")
local LevelUpChoice = RemoteEvents:WaitForChild("LevelUpChoice")

local UIController = {}

function UIController:CreateHUD()
	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = "GameHUD"
	screenGui.ResetOnSpawn = false
	screenGui.Parent = player:WaitForChild("PlayerGui")

	-- HP Bar
	local hpFrame = Instance.new("Frame")
	hpFrame.Name = "HPBar"
	hpFrame.Size = UDim2.new(0, 300, 0, 30)
	hpFrame.Position = UDim2.new(0.5, -150, 0, 20)
	hpFrame.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
	hpFrame.Parent = screenGui

	local hpCorner = Instance.new("UICorner")
	hpCorner.CornerRadius = UDim.new(0, 8)
	hpCorner.Parent = hpFrame

	local hpFill = Instance.new("Frame")
	hpFill.Name = "Fill"
	hpFill.Size = UDim2.new(1, 0, 1, 0)
	hpFill.BackgroundColor3 = Color3.fromRGB(0, 200, 0)
	hpFill.BorderSizePixel = 0
	hpFill.Parent = hpFrame

	local hpFillCorner = Instance.new("UICorner")
	hpFillCorner.CornerRadius = UDim.new(0, 8)
	hpFillCorner.Parent = hpFill

	local hpLabel = Instance.new("TextLabel")
	hpLabel.Size = UDim2.new(1, 0, 1, 0)
	hpLabel.BackgroundTransparency = 1
	hpLabel.Text = "100 / 100"
	hpLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	hpLabel.TextSize = 20
	hpLabel.Font = Enum.Font.GothamBold
	hpLabel.Parent = hpFrame

	-- XP Bar
	local xpFrame = Instance.new("Frame")
	xpFrame.Name = "XPBar"
	xpFrame.Size = UDim2.new(0, 300, 0, 20)
	xpFrame.Position = UDim2.new(0.5, -150, 0, 60)
	xpFrame.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
	xpFrame.Parent = screenGui

	local xpCorner = Instance.new("UICorner")
	xpCorner.CornerRadius = UDim.new(0, 6)
	xpCorner.Parent = xpFrame

	local xpFill = Instance.new("Frame")
	xpFill.Name = "Fill"
	xpFill.Size = UDim2.new(0, 0, 1, 0)
	xpFill.BackgroundColor3 = Color3.fromRGB(100, 200, 255)
	xpFill.BorderSizePixel = 0
	xpFill.Parent = xpFrame

	local xpFillCorner = Instance.new("UICorner")
	xpFillCorner.CornerRadius = UDim.new(0, 6)
	xpFillCorner.Parent = xpFill

	local levelLabel = Instance.new("TextLabel")
	levelLabel.Size = UDim2.new(1, 0, 1, 0)
	levelLabel.BackgroundTransparency = 1
	levelLabel.Text = "Level 1"
	levelLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	levelLabel.TextSize = 16
	levelLabel.Font = Enum.Font.GothamBold
	levelLabel.Parent = xpFrame

	return screenGui, hpFrame, hpFill, hpLabel, xpFrame, xpFill, levelLabel
end

function UIController:CreateLevelUpUI()
	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = "LevelUpUI"
	screenGui.Enabled = false
	screenGui.ResetOnSpawn = false
	screenGui.Parent = player:WaitForChild("PlayerGui")

	-- Background
	local background = Instance.new("Frame")
	background.Size = UDim2.new(1, 0, 1, 0)
	background.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	background.BackgroundTransparency = 0.5
	background.Parent = screenGui

	-- Title
	local title = Instance.new("TextLabel")
	title.Size = UDim2.new(0, 400, 0, 60)
	title.Position = UDim2.new(0.5, -200, 0.3, 0)
	title.BackgroundTransparency = 1
	title.Text = "🎉 LEVEL UP! 🎉"
	title.TextColor3 = Color3.fromRGB(255, 255, 0)
	title.TextSize = 32
	title.Font = Enum.Font.GothamBold
	title.Parent = screenGui

	-- Choice buttons container
	local choicesFrame = Instance.new("Frame")
	choicesFrame.Name = "Choices"
	choicesFrame.Size = UDim2.new(0, 600, 0, 200)
	choicesFrame.Position = UDim2.new(0.5, -300, 0.5, -100)
	choicesFrame.BackgroundTransparency = 1
	choicesFrame.Parent = screenGui

	local listLayout = Instance.new("UIListLayout")
	listLayout.FillDirection = Enum.FillDirection.Horizontal
	listLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	listLayout.Padding = UDim.new(0, 20)
	listLayout.Parent = choicesFrame

	return screenGui, choicesFrame
end

function UIController:UpdateHP(currentHP: number, maxHP: number)
	local hpBar = player.PlayerGui:FindFirstChild("GameHUD"):FindFirstChild("HPBar")
	if hpBar then
		local fill = hpBar:FindFirstChild("Fill")
		local label = hpBar:FindFirstChild("TextLabel")

		fill.Size = UDim2.new(currentHP / maxHP, 0, 1, 0)
		label.Text = string.format("%d / %d", currentHP, maxHP)
	end
end

function UIController:UpdateXP(currentXP: number, level: number)
	local xpBar = player.PlayerGui:FindFirstChild("GameHUD"):FindFirstChild("XPBar")
	if xpBar then
		local fill = xpBar:FindFirstChild("Fill")
		local label = xpBar:FindFirstChild("TextLabel")

		local LevelUpSystem = require(ReplicatedStorage.Shared.Systems.LevelUpSystem)
		local nextLevelXP = LevelUpSystem.GetXPForLevel(level + 1)
		local currentLevelXP = LevelUpSystem.GetXPForLevel(level)

		local progress = (currentXP - currentLevelXP) / (nextLevelXP - currentLevelXP)
		fill.Size = UDim2.new(progress, 0, 1, 0)
		label.Text = string.format("Level %d", level)
	end
end

function UIController:ShowLevelUpChoices(choices, level: number)
	local levelUpUI = player.PlayerGui:FindFirstChild("LevelUpUI")
	if not levelUpUI then
		return
	end

	local choicesFrame = levelUpUI:FindFirstChild("Choices")

	-- Clear existing choices
	for _, child in choicesFrame:GetChildren() do
		if child:IsA("TextButton") then
			child:Destroy()
		end
	end

	-- Create choice buttons
	for _, choice in choices do
		local button = Instance.new("TextButton")
		button.Size = UDim2.new(0, 180, 0, 150)
		button.BackgroundColor3 = Color3.fromRGB(60, 60, 80)
		button.Text = choice.DisplayName
		button.TextColor3 = Color3.fromRGB(255, 255, 255)
		button.TextSize = 24
		button.Font = Enum.Font.GothamBold
		button.Parent = choicesFrame

		local corner = Instance.new("UICorner")
		corner.CornerRadius = UDim.new(0, 12)
		corner.Parent = button

		button.MouseButton1Click:Connect(function()
			LevelUpChoice:FireServer(choice.Type, choice.Value)
			levelUpUI.Enabled = false
		end)
	end

	levelUpUI.Enabled = true
end

function UIController:Init()
	self:CreateHUD()
	self:CreateLevelUpUI()

	-- Listen for events
	DamagePlayer.OnClientEvent:Connect(function(currentHP, maxHP)
		self:UpdateHP(currentHP, maxHP)
	end)

	AddXP.OnClientEvent:Connect(function(currentXP, level)
		self:UpdateXP(currentXP, level)
	end)

	LevelUpChoice.OnClientEvent:Connect(function(choices, level)
		self:ShowLevelUpChoices(choices, level)
	end)

	print("✅ UI Controller initialized")
end

return UIController
