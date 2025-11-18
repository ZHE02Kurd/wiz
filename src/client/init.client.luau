--[[
    Name: init.client.luau
    Author: Magica Development Team
    Date: 2025-11-18
    Location: StarterPlayer/StarterPlayerScripts/Client/init.client.luau
    Affects: Client-side game initialization
    
    Description: This is the MAIN client script that starts when a player joins.
    It sets up the client-side systems like UI, controls, and spell casting.
]]--

print("[🎨 CLIENT] ========================================")
print("[🎨 CLIENT] 🚀 MAGICA CLIENT STARTING...")
print("[🎨 CLIENT] ========================================")

-- Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

-- Get the player
local player = Players.LocalPlayer

print("[🎨 CLIENT] 👤 Player:", player.Name)
print("[🎨 CLIENT] ========================================")
print("[🎨 CLIENT] ✅ CLIENT READY!")
print("[🎨 CLIENT] 📡 Waiting for game to start...")
print("[🎨 CLIENT] ========================================")
