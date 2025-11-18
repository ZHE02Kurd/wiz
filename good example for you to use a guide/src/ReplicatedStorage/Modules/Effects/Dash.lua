-- services

local ReplicatedStorage	= game:GetService("ReplicatedStorage")
local TweenService		= game:GetService("TweenService")
local RunService		= game:GetService("RunService")
local SoundService		= game:GetService("SoundService")
local Workspace			= game:GetService("Workspace")
local Debris			= game:GetService("Debris")

-- constants

local EFFECTS	= Workspace:WaitForChild("Effects")

-- functions

return function(mode, rootPart, direction)
	if mode == "Double" then
		local attachment	= Instance.new("Attachment")
			attachment.Name		= "DashEffectAttach"
			attachment.CFrame	= CFrame.new(0, -2, 0) * CFrame.Angles(-math.pi / 2, 0, 0)
			attachment.Parent	= rootPart
			
		local emitter	= script.DashEmitter:Clone()
			emitter.Parent	= attachment
			
		emitter:Emit(5)
		
		Debris:AddItem(attachment, 0.4)
	elseif mode == "Dash" or mode == "Bounce" then
		local attachA	= Instance.new("Attachment")
			attachA.Name	= "DashTrailAttachA"
			attachA.CFrame	= CFrame.new(0, 1.5, 0)
			attachA.Parent	= rootPart
			
		local attachB	= Instance.new("Attachment")
			attachB.Name	= "DashTrailAttachB"
			attachB.CFrame	= CFrame.new(0, -0.5, 0)
			attachB.Parent	= rootPart
			
		local trail		= script.DashTrail:Clone()
			trail.Attachment0	= attachA
			trail.Attachment1	= attachB
			trail.Parent		= rootPart
			
		Debris:AddItem(attachA, 0.2)
		Debris:AddItem(attachB, 0.2)
		Debris:AddItem(trail, 0.2)
		
		if mode == "Bounce" then
			local sound	= script["BounceSound" .. tostring(math.random(4))]:Clone()
			sound.Parent	= rootPart
			
			sound:Play()
			Debris:AddItem(sound, sound.TimeLength)
		else
			local sound	= script["DashSound" .. tostring(math.random(5))]:Clone()
			sound.Parent	= rootPart
			
			sound:Play()
			Debris:AddItem(sound, sound.TimeLength)
		end
	end
end