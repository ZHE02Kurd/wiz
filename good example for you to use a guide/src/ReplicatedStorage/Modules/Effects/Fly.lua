-- services

local Workspace	= game:GetService("Workspace")
local Debris	= game:GetService("Debris")

-- constants

local EFFECTS	= Workspace:WaitForChild("Effects")

-- function

return function(character, flying)
	character.RightHand.FlightTrail.Enabled	= flying
	character.LeftHand.FlightTrail.Enabled	= flying
	character.RightFoot.FlightTrail.Enabled	= flying
	character.LeftFoot.FlightTrail.Enabled	= flying
	
	if not flying then
		local rootPart	= character.HumanoidRootPart
		local ray		= Ray.new(rootPart.Position, Vector3.new(0, -10, 0))
		local _, pos	= Workspace:FindPartOnRayWithIgnoreList(ray, {character, EFFECTS})
		
		local landing	= script.LandingPart:Clone()
			landing.CFrame	= CFrame.new(pos)
			landing.Parent	= EFFECTS
			
		landing.DirtEmitter:Emit(10)
		landing.ImpactEmitter:Emit(10)
		
		landing.LandingSound:Play()
		
		Debris:AddItem(landing, 10)
	end
end