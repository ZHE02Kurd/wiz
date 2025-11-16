-- Main Server Script
print("🎮 Magic Battle Royale Server Starting...")

local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Create RemoteEvents folder
local remoteEvents = Instance.new("Folder")
remoteEvents.Name = "RemoteEvents"
remoteEvents.Parent = ReplicatedStorage

-- Create all remote events
local events = {
	"DamagePlayer",
	"AddXP",
	"LevelUpChoice",
	"CastSpell",
	"ProjectileHit",
}

for _, eventName in events do
	local event = Instance.new("RemoteEvent")
	event.Name = eventName
	event.Parent = remoteEvents
end

print("✅ RemoteEvents created")

-- Initialize services
local PlayerDataService = require(script.Services.PlayerDataService)
local CombatService = require(script.Services.CombatService)
local MapService = require(script.Services.MapService)

PlayerDataService:Init()
CombatService:Init()
MapService:Init()

print("🚀 Server initialized successfully!")
