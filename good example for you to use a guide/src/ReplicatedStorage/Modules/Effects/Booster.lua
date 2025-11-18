-- services

local TweenService	= game:GetService("TweenService")
local Workspace		= game:GetService("Workspace")
local Debris		= game:GetService("Debris")

-- constants

local EFFECTS	= Workspace:WaitForChild("Effects")

-- functions

return function(character, boost)
	if not character then return end

	-- Temporarily disabled - needs particle emitter
	print("[BOOSTER EFFECT] " .. boost .. " effect played for " .. character.Name)

	-- Play sound if it exists
	local sound = script:FindFirstChild(boost .. "Sound")
	if sound then
		local soundClone = sound:Clone()
		soundClone.Parent = character:WaitForChild("UpperTorso")
		soundClone:Play()
		game:GetService("Debris"):AddItem(soundClone, soundClone.TimeLength)
	end
end