local Model = script.Parent
local Handler = Model:WaitForChild("Handler")
local Knob = Model:WaitForChild("Knob")

local ClickDetector = Knob:WaitForChild("ClickDetector")

local AngleIncrement = 45 --change this to whatever you want, its how fast the door swings open/close
local WhitelistGroupIds = {--group ids, seperate each group with ',' and remove everything inside to let everyone in
	
	
}

local Open = false

function OpenDoor()
	for i=1, 360 / 4, AngleIncrement do
		for _,v in pairs(Model:GetChildren()) do
			if v:IsA("BasePart") then
				v.CFrame = (Handler.CFrame * CFrame.Angles(0, math.rad(AngleIncrement), 0)) * Handler.CFrame:toObjectSpace(v.CFrame)
			end
		end
		wait()
	end
	Open = true
end

function CloseDoor()
	for i=360 / 4, 1, -AngleIncrement do
		for _,v in pairs(Model:GetChildren()) do
			if v:IsA("BasePart") then
				v.CFrame = (Handler.CFrame * CFrame.Angles(0, math.rad(-AngleIncrement), 0)) * Handler.CFrame:toObjectSpace(v.CFrame)
			end
		end
		wait()
	end
	Open = false
end

function OpenCloseDoor()
	if not Open then
		OpenDoor()
	else
		CloseDoor()
	end
end

local debounce = false
ClickDetector.MouseClick:connect(function(plr)
	if debounce then return end
	debounce = true
	
	if #WhitelistGroupIds > 0 then
		for i=1, #WhitelistGroupIds do
			if plr:IsInGroup(WhitelistGroupIds[i]) then
				OpenCloseDoor()
			end
		end
	else
		OpenCloseDoor()
	end
	
	debounce = false
end)
