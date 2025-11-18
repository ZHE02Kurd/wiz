-- services

local TweenService		= game:GetService("TweenService")

-- functions

return function(down, character, radius)
	if down then
		local revivePart	= script.RevivePart:Clone()
			revivePart.Size		= Vector3.new(radius * 2, 0.1, radius * 2)
			revivePart.Parent	= character
			
		local weld	= Instance.new("Weld")
			weld.Part0	= character.HumanoidRootPart
			weld.Part1	= revivePart
			weld.C0		= CFrame.new(0, -1, 0)
			weld.Parent	= revivePart
			
		revivePart.ReviveGui.CircleLabel.Size	= UDim2.new()
		revivePart.ReviveGui.RingLabel.Size		= UDim2.new()
		
		local info			= TweenInfo.new(0.5, Enum.EasingStyle.Sine, Enum.EasingDirection.Out)
		local ringTween		= TweenService:Create(revivePart.ReviveGui.RingLabel, info, {Size = UDim2.new(1, 0, 1, 0)})
		local circleTween	= TweenService:Create(revivePart.ReviveGui.CircleLabel, info, {Size = UDim2.new(1, 0, 1, 0)})
		
		ringTween:Play()
		circleTween:Play()
	else
		if character:FindFirstChild("RevivePart") then
			character.RevivePart:Destroy()
		end
	end
end