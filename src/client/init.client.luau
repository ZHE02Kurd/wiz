-- Main Client Script
print("🎮 Magic Battle Royale Client Starting...")

local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Wait for RemoteEvents
local remoteEvents = ReplicatedStorage:WaitForChild("RemoteEvents")
print("✅ Connected to server")

-- Initialize controllers
local InputController = require(script.Controllers.InputController)
local UIController = require(script.UI.UIController)

InputController:Init()
UIController:Init()

print("🚀 Client initialized successfully!")
