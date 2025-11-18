-- services

local ReplicatedStorage	= game:GetService("ReplicatedStorage")
local TweenService		= game:GetService("TweenService")
local RunService		= game:GetService("RunService")
local SoundService		= game:GetService("SoundService")
local Workspace			= game:GetService("Workspace")
local Debris			= game:GetService("Debris")

-- constants

local CAMERA	= Workspace.CurrentCamera
local EFFECTS	= Workspace:WaitForChild("Effects")

local DAMAGE	= require(script.Parent:WaitForChild("Damage"))

-- functions

return function(item, t)
	local handle		= item.Handle
	
	local numSounds		= 0
	for _, s in pairs(handle:GetChildren()) do
		if string.match(s.Name, "SwingSound%d+") then
			numSounds	= numSounds + 1
		end
	end
	
	local sound		= handle["SwingSound" .. tostring(math.random(numSounds))]:Clone()
		sound.Name		= "SwingSound_Clone"
		sound.Parent	= handle
	
	sound:Play()
	Debris:AddItem(sound, sound.TimeLength)
	
	spawn(function()
		handle.SwingTrail.Enabled	= true
		wait(t * 0.6)
		handle.SwingTrail.Enabled	= false
	end)
end