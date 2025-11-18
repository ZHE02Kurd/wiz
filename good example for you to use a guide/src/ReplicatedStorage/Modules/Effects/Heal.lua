-- services

local ReplicatedStorage	= game:GetService("ReplicatedStorage")

-- constants

local ITEMS		= ReplicatedStorage:WaitForChild("Items")
local BASE_PACK	= ITEMS:WaitForChild("Health Pack")

-- function

return function(character, healing, t)
	if healing then
		if not character:FindFirstChild("HealthPackEffect") then
			local healthPack	= BASE_PACK:Clone()
				healthPack.Name		= "HealthPackEffect"
				
				local weld	= Instance.new("Weld")
					weld.Part0	= character.RightHand
					weld.Part1	= healthPack.PrimaryPart
					weld.C0		= CFrame.Angles(-math.pi / 2, 0, 0)
					weld.C1		= healthPack.PrimaryPart.Grip.CFrame
					weld.Parent	= healthPack.PrimaryPart
					
				healthPack.Parent	= character
				
			healthPack.PrimaryPart.HealSound.PlaybackSpeed	= healthPack.PrimaryPart.HealSound.TimeLength / t
			healthPack.PrimaryPart.HealSound:Play()
			
			healthPack.PrimaryPart.Nozzle.SplashEmitter.Enabled	= true
		end
	else
		if character:FindFirstChild("HealthPackEffect") then
			character.HealthPackEffect:Destroy()
		end
	end
end