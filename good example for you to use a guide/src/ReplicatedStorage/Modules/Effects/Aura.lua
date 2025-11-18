-- services

local ReplicatedStorage	= game:GetService("ReplicatedStorage")

-- constants

local CUSTOMIZATION	= ReplicatedStorage:WaitForChild("Customization")

-- variables

local effects	= {}

-- function
	
return function(character, aura)
	print(character, aura)
	if not character:FindFirstChild("Effects") then
		local effects	= Instance.new("Folder")
			effects.Name	= "Effects"
			effects.Parent	= character
	end
	
	if not effects[aura] then
		if CUSTOMIZATION.Auras:FindFirstChild(aura) then
			effects[aura]	= require(CUSTOMIZATION.Auras[aura])
		end
	end
	
	if effects[aura] then
		effects[aura](character)
	end
end