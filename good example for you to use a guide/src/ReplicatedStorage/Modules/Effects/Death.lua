-- services

local ReplicatedStorage	= game:GetService("ReplicatedStorage")

-- constants

local CUSTOMIZATION	= ReplicatedStorage:WaitForChild("Customization")

-- variables

local effects	= {}

-- function
	
return function(character, death)
	if not character:FindFirstChild("Effects") then
		local effects	= Instance.new("Folder")
			effects.Name	= "Effects"
			effects.Parent	= character
	end
	
	if not effects[death] then
		if CUSTOMIZATION.KillEffects:FindFirstChild(death) then
			effects[death]	= require(CUSTOMIZATION.KillEffects[death])
		end
	end
	
	if effects[death] then
		effects[death](character)
	end
end