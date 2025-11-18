local CONFIG	= {}

function CONFIG.GetConfig(self, item)
	local config	= {}
	local itemConf	= require(item:WaitForChild("Config"))
	
	for i, v in pairs(itemConf) do
		config[i]	= v
	end
	
	if item:FindFirstChild("Attachments") then
		for _, attachment in pairs(item.Attachments:GetChildren()) do
			local attachConf	= require(attachment:WaitForChild("Config"))
			
			for c, info in pairs(attachConf.Mod) do
				if info.Mode == "Multiply" then
					config[c]	= config[c] * info.Value
				elseif info.Mode == "Add" then
					config[c]	= config[c] + info.Value
				elseif info.Mode == "Set" then
					config[c]	= info.Value
				end
				
				if info.Round then
					if info.Round == "Ceil" then
						config[c]	= math.ceil(config[c])
					elseif info.Round == "Floor" then
						config[c]	= math.floor(config[c])
					else
						config[c]	= math.floor(config[c] + 0.5)
					end
				end
			end
		end
	end
	
	return config
end

return CONFIG