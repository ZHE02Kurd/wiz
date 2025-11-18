-- services

local ReplicatedStorage	= game:GetService("ReplicatedStorage")
local Debris			= game:GetService("Debris")

-- constants

local MODULES	= ReplicatedStorage:WaitForChild("Modules")
	local CONFIG	= require(MODULES:WaitForChild("Config"))

-- module

return function(item, action, ...)
	if action == "Fire" then
		local s			= ...
		local handle	= item.Handle
		local config	= CONFIG:GetConfig(item)
		
		handle.Muzzle.FireSound:Play()
		
		if s then
			local sound		= handle.ReloadSound:Clone()
				sound.Name			= "ReloadSound_Clone"
				sound.Parent		= handle
				sound.PlaybackSpeed	= sound.TimeLength / config.Cooldown
			
			sound:Play()
			Debris:AddItem(sound, sound.TimeLength / sound.PlaybackSpeed)
		end
	end
end