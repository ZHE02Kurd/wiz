-- services

local ReplicatedStorage	= game:GetService("ReplicatedStorage")
local TweenService		= game:GetService("TweenService")
local Players			= game:GetService("Players")

-- constants

local STORM		= ReplicatedStorage.Storm
local REMOTES	= ReplicatedStorage.Remotes

local MAP_RADIUS	= 1700

-- variables
local stormActive = false
local activeTweens = {}
local finalPosition	= Vector3.new(math.random(-MAP_RADIUS * 0.4, MAP_RADIUS * 0.4), 0, math.random(-MAP_RADIUS * 0.4, MAP_RADIUS * 0.4))

-- functions

local function Lerp(a, b, d) return a + (b - a) * d end

local function MoveToTarget(t)
	local info		= TweenInfo.new(t, Enum.EasingStyle.Linear, Enum.EasingDirection.Out)
	local tweenA	= TweenService:Create(STORM.Center, info, {Value = STORM.TargetCenter.Value})
	local tweenB	= TweenService:Create(STORM.Radius, info, {Value = STORM.TargetRadius.Value})


	table.insert(activeTweens, tweenA)
	table.insert(activeTweens, tweenB)


	tweenA:Play()
	tweenB:Play()

	wait(t) -- Wait for the tween to finish

	-- Remove tweens after completion (safer way)
	local indexA = table.find(activeTweens, tweenA)
	if indexA then table.remove(activeTweens, indexA) end
	local indexB = table.find(activeTweens, tweenB)
	if indexB then table.remove(activeTweens, indexB) end
end

local function SetTarget(p, r)
	STORM.TargetCenter.Value	= p
	STORM.TargetRadius.Value	= r
end

local function Timer(t)
	for i = t, 0, -1 do
		if not stormActive then return end -- Stop timer if storm is stopped
		STORM.Timer.Value	= i
		wait(1)
	end
end

local function GetRandomPosition(newRadius)
	local center	= STORM.Center.Value
	local maxDist	= STORM.Radius.Value - newRadius

	local offset	= finalPosition - center
	local direction	= Vector3.new()
	if offset.Magnitude > 1 then
		direction	= offset.Unit
	end
	local distance	= offset.Magnitude

	return center + direction * math.min(distance, maxDist)
end

local function RunSequence()
	if stormActive then return end -- Don't run twice
	stormActive = true

	-- !! REMINDER: Make sure your MAP_RADIUS variable is set to a good value for your map (e.g., 2000) !!

	-- ========== 3-MINUTE (180-SECOND) STORM SEQUENCE ==========

	-- PHASE 1: First Shrink (Total time: 60 seconds)
	REMOTES.RoundInfo:FireAllClients("Message", "Storm shrinking in 30 seconds")
	SetTarget(GetRandomPosition(MAP_RADIUS * 0.6), MAP_RADIUS * 0.6) -- Set target to 60% map size
	Timer(30) -- 30-second warning
	if not stormActive then return end

	REMOTES.RoundInfo:FireAllClients("Message", "Storm is closing in")
	MoveToTarget(30) -- 30 seconds to shrink
	if not stormActive then return end

	-- PHASE 2: Second Shrink (Total time: 60 seconds)
	REMOTES.RoundInfo:FireAllClients("Message", "Storm shrinking in 30 seconds")
	SetTarget(GetRandomPosition(MAP_RADIUS * 0.25), MAP_RADIUS * 0.25) -- Set target to 25% map size
	Timer(30) -- 30-second warning
	if not stormActive then return end

	REMOTES.RoundInfo:FireAllClients("Message", "Storm is closing in")
	MoveToTarget(30) -- 30 seconds to shrink
	if not stormActive then return end

	-- PHASE 3: Final Collapse (Total time: 60 seconds)
	REMOTES.RoundInfo:FireAllClients("Message", "Storm is collapsing!")
	SetTarget(GetRandomPosition(0), 0) -- Set target to 0 (fully closed)
	MoveToTarget(60) -- 60 seconds to collapse completely
	if not stormActive then return end

	-- Storm sequence is over
	stormActive = false
end

local function StopSequence()
	stormActive = false

	-- Cancel all running storm tweens
	for _, tween in pairs(activeTweens) do
		if tween then
			tween:Cancel()
		end
	end
	activeTweens = {}

	-- Reset storm to be huge and harmless
	STORM.Radius.Value			= 100000
	STORM.TargetRadius.Value	= 100000
	STORM.Center.Value			= Vector3.new()
	STORM.TargetCenter.Value	= Vector3.new()
end

-- initiate
StopSequence() -- Start with the storm reset

-- events
script.RunSequence.Event:connect(function()
	spawn(RunSequence)
end)
script.StopSequence.Event:connect(StopSequence)


-- loop
while true do
	wait(1)

	-- Only run damage loop if the storm is active
	if stormActive then
		local center	= Vector3.new(STORM.Center.Value.X, 0, STORM.Center.Value.Z)
		local alpha		= math.clamp(STORM.Radius.Value / 2000 + 0.1, 0, 1)
		local damage	= Lerp(10, 2, alpha)

		for _, player in pairs(Players:GetPlayers()) do
			local character	= player.Character
			if character then
				local humanoid	= character:FindFirstChildOfClass("Humanoid")

				if humanoid and humanoid.Health > 0 then
					local rootPart	= character:FindFirstChild("HumanoidRootPart")

					if rootPart then
						local distance	= (center - Vector3.new(rootPart.Position.X, 0, rootPart.Position.Z)).Magnitude

						if distance > STORM.Radius.Value then
							if humanoid:FindFirstChild("KillTag") then
								humanoid.KillTag:Destroy()
							end
							humanoid:TakeDamage(damage)
						end
					end
				end
			end
		end
	end
end