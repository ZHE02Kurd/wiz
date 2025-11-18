-- File: StarterPack/Tool/M4/CharacterController.lua (Jump/Roll Fix + Synced Tracer)

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local ContextActionService = game:GetService("ContextActionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Debris = game:GetService("Debris")
local TweenService = game:GetService("TweenService")
local ShowHitmarker = ReplicatedStorage:WaitForChild("ShowHitmarker")

local Config = require(ReplicatedStorage:WaitForChild("Config"))
local PlayerState = require(ReplicatedStorage:WaitForChild("PlayerState"))

local tool = script.Parent
local gunHandle = tool:WaitForChild("Handle")

-- This connection will be managed by Equip/Unequipped events
local updateConnection

-- These states are persistent across equips
local canFireSingleShot = true
local lastFireTime = 0
local fireModeIndex = 1

-- Universal helper function
local function createTracer(startPos, endPos, color)
	local TRACER_SPEED = 1000
	local distance = (startPos - endPos).Magnitude
	local duration = distance / TRACER_SPEED
	local tracerPart = Instance.new("Part")
	tracerPart.Name = "Tracer"; tracerPart.BrickColor = color; tracerPart.Material = Enum.Material.Neon
	tracerPart.Anchored = true; tracerPart.CanCollide = false; tracerPart.CanQuery = false; tracerPart.CanTouch = false
	tracerPart.Size = Vector3.new(0.1, 0.1, 8); tracerPart.CFrame = CFrame.lookAt(startPos, endPos)
	tracerPart.Parent = workspace
	local tweenInfo = TweenInfo.new(duration, Enum.EasingStyle.Linear)
	local goal = {CFrame = CFrame.lookAt(endPos, endPos + (endPos - startPos))}
	local tween = TweenService:Create(tracerPart, tweenInfo, goal)
	tween:Play()
	Debris:AddItem(tracerPart, duration)
end

local function dealDamage(attacker, target, damage, hitType)
	if target and target:FindFirstChild("Humanoid") then
		-- Apply damage
		target.Humanoid:TakeDamage(damage)

		-- Fire to attacker’s client so they see the hitmarker
		if attacker and attacker:IsA("Player") then
			ShowHitmarker:FireClient(attacker, damage, hitType or "BodyHit")
		end
	end
end

-- === CONNECTIONS ===

tool.Equipped:Connect(function()
	-- This table holds all variables for this specific equip session.
	local session = {}

	-- Get fresh character references every single time
	session.player = Players.LocalPlayer
	session.character = session.player.Character
	session.humanoid = session.character and session.character:FindFirstChildOfClass("Humanoid")
	session.animator = session.humanoid and session.humanoid:FindFirstChildOfClass("Animator")
	session.rootPart = session.character and session.character:FindFirstChild("HumanoidRootPart")

	if not session.animator then return end

	-- Safely load all required instances now
	session.fireRequestEvent = ReplicatedStorage:WaitForChild("FireRequest")
	session.fireSound = gunHandle:WaitForChild("FireSound")
	session.reloadSound = gunHandle:WaitForChild("ReloadSound")
	session.recoilEvent = ReplicatedStorage:WaitForChild("RecoilEvent")
	session.rollEvent = ReplicatedStorage:WaitForChild("RollEvent")
	session.weaponSettings = Config.WEAPONS[tool.Name]

	session.playerGui = session.player:WaitForChild("PlayerGui")
	session.hud = session.playerGui:WaitForChild("HUD")
	session.crosshair = session.hud:WaitForChild("Crosshair")
	session.ammoLabel = session.hud:WaitForChild("AmmoLabel")
	session.fireModeLabel = session.hud:WaitForChild("FireModeLabel")

	if not session.weaponSettings then
		warn("No weapon settings found in Config for:", tool.Name)
		return
	end

	-- Load animations
	session.aimAnimTrack = session.animator:LoadAnimation(gunHandle:WaitForChild("AimAnim"))
	session.reloadAnimTrack = session.animator:LoadAnimation(gunHandle:WaitForChild("ReloadAnim"))
	session.rollFwdAnimTrack = session.animator:LoadAnimation(gunHandle:WaitForChild("RollForward"))
	session.rollBackAnimTrack = session.animator:LoadAnimation(gunHandle:WaitForChild("RollBackward"))
	session.rollLeftAnimTrack = session.animator:LoadAnimation(gunHandle:WaitForChild("RollLeft"))
	session.rollRightAnimTrack = session.animator:LoadAnimation(gunHandle:WaitForChild("RollRight"))

	session.aimAnimTrack.Priority = Enum.AnimationPriority.Action; session.aimAnimTrack.Looped = true
	session.reloadAnimTrack.Priority = Enum.AnimationPriority.Action2
	session.rollFwdAnimTrack.Priority = Enum.AnimationPriority.Action3
	session.rollBackAnimTrack.Priority = Enum.AnimationPriority.Action3
	session.rollLeftAnimTrack.Priority = Enum.AnimationPriority.Action3
	session.rollRightAnimTrack.Priority = Enum.AnimationPriority.Action3

	local currentAmmo = session.weaponSettings.MAX_AMMO
	local currentSpread = Config.SPREAD.MIN

	---------------------------------------------------------------------
	-- ACTION AND HELPER FUNCTIONS (DEFINED *INSIDE* EQUIPPED)
	---------------------------------------------------------------------

	local function updateAmmoUI()
		session.ammoLabel.Text = currentAmmo .. " / " .. session.weaponSettings.MAX_AMMO
	end

	local function updateFireModeUI()
		local currentMode = session.weaponSettings.FIRE_MODES[fireModeIndex]
		session.fireModeLabel.Text = currentMode
	end

	local function updateSpread(dt)
		local targetSpread = Config.SPREAD.MIN
		if not PlayerState.isAiming then targetSpread = targetSpread + Config.SPREAD.HIPFIRE_BASE end
		if session.humanoid.MoveDirection.Magnitude > 0.1 then targetSpread = targetSpread + Config.SPREAD.MOVEMENT_PENALTY end
		currentSpread = math.max(targetSpread, currentSpread - Config.SPREAD.RECOVERY_RATE * dt)
		session.crosshair.Size = UDim2.fromOffset(currentSpread, currentSpread)
	end

	local function reload()
		if PlayerState.isReloading or currentAmmo == session.weaponSettings.MAX_AMMO or PlayerState.isRolling or PlayerState.isClimbing then return end
		PlayerState.isReloading = true
		session.reloadSound:Play()
		session.reloadAnimTrack:Play()
		task.wait(session.reloadAnimTrack.Length)
		currentAmmo = session.weaponSettings.MAX_AMMO
		PlayerState.isReloading = false
		updateAmmoUI()
	end

	local function fireWeapon()
		if PlayerState.isReloading or currentAmmo <= 0 or PlayerState.isRolling or PlayerState.isClimbing then return end

		session.recoilEvent:Fire()
		currentSpread = math.min(Config.SPREAD.MAX, currentSpread + Config.SPREAD.INCREASE_PER_SHOT)
		session.fireSound:Play()
		currentAmmo -= 1
		updateAmmoUI()

		-- get ray from crosshair
		local crosshairCenter = session.crosshair.AbsolutePosition + (session.crosshair.AbsoluteSize / 2)
		local unitRay = workspace.CurrentCamera:ScreenPointToRay(crosshairCenter.X, crosshairCenter.Y)
		local rayOrigin = unitRay.Origin
		local rayDirection = unitRay.Direction * 1000

		-- raycast for tracer endpoint
		local raycastParams = RaycastParams.new()
		raycastParams.FilterDescendantsInstances = {session.character}
		raycastParams.FilterType = Enum.RaycastFilterType.Blacklist
		local raycastResult = workspace:Raycast(rayOrigin, rayDirection, raycastParams)
		local hitPoint = raycastResult and raycastResult.Position or (rayOrigin + rayDirection)

		-- tracer always follows same ray as server
		createTracer(gunHandle:WaitForChild("Muzzle").WorldPosition, hitPoint, BrickColor.new("New Yeller"))

		-- 🔧 send ray to server
		session.fireRequestEvent:FireServer(tool.Name, rayOrigin, unitRay.Direction)

		if currentAmmo == 0 then
			reload()
		end
	end

	local function roll()
		if not PlayerState.isAiming then return end
		local humanoidState = session.humanoid:GetState()
		if humanoidState == Enum.HumanoidStateType.Jumping or humanoidState == Enum.HumanoidStateType.Freefall then
			return
		end
		if PlayerState.isRolling or (PlayerState.isSprinting and not PlayerState.isAiming) or PlayerState.isReloading or PlayerState.isClimbing then return end
		if session.humanoid.MoveDirection.Magnitude < 0.1 then return end

		PlayerState.isRolling = true
		task.wait()
		session.rollEvent:Fire()
		if PlayerState.isAiming then PlayerState.isAiming = false end

		local moveDirection = session.humanoid.MoveDirection
		local relativeMoveDir = session.rootPart.CFrame:VectorToObjectSpace(moveDirection)
		local animTrackToPlay
		if math.abs(relativeMoveDir.X) > math.abs(relativeMoveDir.Z) then
			animTrackToPlay = relativeMoveDir.X > 0 and session.rollRightAnimTrack or session.rollLeftAnimTrack
		else
			animTrackToPlay = relativeMoveDir.Z < 0 and session.rollFwdAnimTrack or session.rollBackAnimTrack
		end
		animTrackToPlay:Play()

		local force = Instance.new("LinearVelocity")
		force.Attachment0 = session.rootPart:FindFirstChildOfClass("Attachment") or Instance.new("Attachment", session.rootPart)
		force.MaxForce = math.huge
		force.VectorVelocity = moveDirection.Unit * Config.ROLL_SPEED
		force.Parent = session.rootPart
		Debris:AddItem(force, Config.ROLL_DURATION)
		animTrackToPlay.Ended:Wait()
		PlayerState.isRolling = false
		if UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton2) then
			PlayerState.isAiming = true
			session.aimAnimTrack:Play()
		end
	end

	local function onJumpRequest(actionName, inputState, inputObject)
		if PlayerState.isRolling then
			return Enum.ContextActionResult.Sink
		else
			return Enum.ContextActionResult.Pass
		end
	end

	local function onUpdate(dt)
		local canSprint = not PlayerState.isFiring and not PlayerState.isReloading and not PlayerState.isClimbing
		if PlayerState.isRolling then
		else
			PlayerState.isSprinting = false
			session.humanoid.WalkSpeed = Config.NORMAL_SPEED
		end

		if PlayerState.isFiring then
			local currentMode = session.weaponSettings.FIRE_MODES[fireModeIndex]
			if currentMode == "Automatic" then
				if os.clock() - lastFireTime >= session.weaponSettings.FIRE_RATE then
					lastFireTime = os.clock()
					fireWeapon()
				end
			elseif currentMode == "Single" and canFireSingleShot then
				fireWeapon()
				canFireSingleShot = false
			end
		end
		updateSpread(dt)
	end

	---------------------------------------------------------------------
	-- BIND ACTIONS AND START LOOP
	---------------------------------------------------------------------

	session.crosshair.Visible = true; session.ammoLabel.Visible = true; session.fireModeLabel.Visible = true
	updateAmmoUI()
	updateFireModeUI()

	ContextActionService:BindAction("Aim", function(_, s)
		if PlayerState.isRolling or PlayerState.isClimbing then return end
		if s == Enum.UserInputState.Begin then PlayerState.isAiming = true; session.aimAnimTrack:Play()
		elseif s == Enum.UserInputState.End then PlayerState.isAiming = false; session.aimAnimTrack:Stop() end
	end, false, Enum.UserInputType.MouseButton2)

	ContextActionService:BindAction("Reload", function(_, s) if s == Enum.UserInputState.Begin then reload() end end, false, Enum.KeyCode.R)
	ContextActionService:BindAction("Roll", function(_, s) if s == Enum.UserInputState.Begin then roll() end end, false, Enum.KeyCode.C)
	ContextActionService:BindAction("SwitchFireMode", function(_, s)
		if s == Enum.UserInputState.Begin then
			fireModeIndex = (fireModeIndex % #session.weaponSettings.FIRE_MODES) + 1
			updateFireModeUI()
		end
	end, false, Enum.KeyCode.V)

	ContextActionService:BindAction("Fire", function(_, s)
		if s == Enum.UserInputState.Begin then PlayerState.isFiring = true; canFireSingleShot = true
		elseif s == Enum.UserInputState.End then PlayerState.isFiring = false end
	end, false, Enum.UserInputType.MouseButton1)

	ContextActionService:BindAction("JumpBlocker", onJumpRequest, false, Enum.KeyCode.Space)

	if not updateConnection then
		updateConnection = RunService.RenderStepped:Connect(onUpdate)
	end
end)

tool.Unequipped:Connect(function()
	if updateConnection then
		updateConnection:Disconnect()
		updateConnection = nil
	end

	local playerGui = Players.LocalPlayer and Players.LocalPlayer:FindFirstChild("PlayerGui")
	local hud = playerGui and playerGui:FindFirstChild("HUD")
	if hud then
		local crosshair = hud:FindFirstChild("Crosshair")
		local ammoLabel = hud:FindFirstChild("AmmoLabel")
		local fireModeLabel = hud:FindFirstChild("FireModeLabel")
		if crosshair then crosshair.Visible = false end
		if ammoLabel then ammoLabel.Visible = false end
		if fireModeLabel then fireModeLabel.Visible = false end
	end

	PlayerState.isFiring = false; PlayerState.isAiming = false

	ContextActionService:UnbindAction("Aim")
	ContextActionService:UnbindAction("Fire")
	ContextActionService:UnbindAction("Reload")
	ContextActionService:UnbindAction("SwitchFireMode")
	ContextActionService:UnbindAction("Roll")
	ContextActionService:UnbindAction("JumpBlocker")
end)
