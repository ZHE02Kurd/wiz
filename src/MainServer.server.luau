--[[
    Name: MainServer.server.luau
    Author: Magica Development Team
    Date: 2025-11-18
    Location: ServerScriptService/MainServer
    Affects: ALL server-side game systems - this is the main entry point
    
    Description: Main server entry point. This script auto-runs when the server starts.
    It initializes all server-side systems and starts the game loop.
]]--

print("[⚡ MAIN] ========================================")
print("[⚡ MAIN] 🌟 MAGICA GAME STARTING...")
print("[⚡ MAIN] ========================================")

-- Services
local ServerScriptService = game:GetService("ServerScriptService")

-- Wait for Server folder to load
local Server = ServerScriptService:WaitForChild("Server")
print("[⚡ MAIN] 📁 Server folder loaded!")
print("[⚡ MAIN] 🔧 Loading server modules...")

-- Load server modules
local GameManagerServer = require(Server:WaitForChild("GameManagerServer"))
local CombatServer = require(Server:WaitForChild("CombatServer"))
local LevelUpServer = require(Server:WaitForChild("LevelUpServer"))

-- Initialize game systems
GameManagerServer:Initialize()

print("[⚡ MAIN] ========================================")
print("[⚡ MAIN] 🎉 GAME IS LIVE!")
print("[⚡ MAIN] ========================================")
