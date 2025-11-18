-- function

return function(character, grinding)
	local rootPart	= character.HumanoidRootPart
	local grindAtt	= rootPart.GrindAttachment
	
	grindAtt.SparkEmitter.Enabled	= grinding
	
	if grinding then
		grindAtt.GrindSound:Play()
	else
		grindAtt.GrindSound:Stop()
	end
end