--[[
    LOCAL PLAYER CONTROL ILLUSION
    Roblox Studio LocalScript
    Place in StarterPlayer > StarterPlayerScripts

    PC:
      W A S D = movement
      SPACE   = jump
      Mouse   = camera

    Mobile:
      Left joystick = movement
      JUMP button   = jump
      Normal Roblox touch camera = camera

    Everything involving the selected player is local-only.
]]

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

local Camera = workspace.CurrentCamera

local controlling = false
local selectedPlayer = nil
local puppet = nil

local originalCharacter = nil
local originalRoot = nil

local hiddenCharacter = nil

local keys = {
	W = false,
	A = false,
	S = false,
	D = false
}

local mobileMove = Vector2.zero
local mobileTouch = nil

local animationTracks = {}

--==================================================
-- HELPERS
--==================================================

local function getHumanoid(character)
	if not character then
		return nil
	end

	return character:FindFirstChildOfClass("Humanoid")
end

local function getRoot(character)
	if not character then
		return nil
	end

	return character:FindFirstChild("HumanoidRootPart")
end

local function corner(object, radius)
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, radius)
	c.Parent = object
end

local function hideLocally(character)
	if not character then
		return
	end

	for _, object in ipairs(character:GetDescendants()) do
		if object:IsA("BasePart") then
			object.LocalTransparencyModifier = 1
		elseif object:IsA("Decal") or object:IsA("Texture") then
			object.Transparency = 1
		end
	end
end

local function showLocally(character)
	if not character then
		return
	end

	for _, object in ipairs(character:GetDescendants()) do
		if object:IsA("BasePart") then
			object.LocalTransparencyModifier = 0
		elseif object:IsA("Decal") or object:IsA("Texture") then
			object.Transparency = 0
		end
	end
end

--==================================================
-- GUI
--==================================================

local gui = Instance.new("ScreenGui")
gui.Name = "LocalControlUI"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.Parent = PlayerGui

--==================================================
-- MAIN UI
--==================================================

local main = Instance.new("Frame")
main.Size = UDim2.fromOffset(320, 210)
main.Position = UDim2.new(0.5, -160, 0.5, -105)
main.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
main.BorderSizePixel = 0
main.Parent = gui

corner(main, 12)

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, -20, 0, 35)
title.Position = UDim2.fromOffset(10, 8)
title.BackgroundTransparency = 1
title.Text = "Player Control"
title.TextColor3 = Color3.new(1, 1, 1)
title.TextSize = 21
title.Font = Enum.Font.GothamBold
title.TextXAlignment = Enum.TextXAlignment.Left
title.Parent = main

local dropdown = Instance.new("TextButton")
dropdown.Size = UDim2.new(1, -20, 0, 38)
dropdown.Position = UDim2.fromOffset(10, 52)
dropdown.BackgroundColor3 = Color3.fromRGB(42, 42, 50)
dropdown.BorderSizePixel = 0
dropdown.Text = "Select Player ▼"
dropdown.TextColor3 = Color3.new(1, 1, 1)
dropdown.TextSize = 14
dropdown.Font = Enum.Font.Gotham
dropdown.Parent = main

corner(dropdown, 8)

local playerList = Instance.new("ScrollingFrame")
playerList.Size = UDim2.new(1, -20, 0, 105)
playerList.Position = UDim2.fromOffset(10, 94)
playerList.BackgroundColor3 = Color3.fromRGB(32, 32, 38)
playerList.BorderSizePixel = 0
playerList.ScrollBarThickness = 5
playerList.Visible = false
playerList.Parent = main

corner(playerList, 8)

local layout = Instance.new("UIListLayout")
layout.Padding = UDim.new(0, 3)
layout.Parent = playerList

local controlButton = Instance.new("TextButton")
controlButton.Size = UDim2.new(1, -20, 0, 38)
controlButton.Position = UDim2.new(0, 10, 1, -48)
controlButton.BackgroundColor3 = Color3.fromRGB(55, 120, 255)
controlButton.BorderSizePixel = 0
controlButton.Text = "CONTROL"
controlButton.TextColor3 = Color3.new(1, 1, 1)
controlButton.TextSize = 15
controlButton.Font = Enum.Font.GothamBold
controlButton.Parent = main

corner(controlButton, 8)

--==================================================
-- SESSION UI
--==================================================

local session = Instance.new("Frame")
session.Size = UDim2.fromOffset(245, 180)
session.Position = UDim2.new(1, -265, 0.5, -90)
session.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
session.BorderSizePixel = 0
session.Visible = false
session.Parent = gui

corner(session, 12)

local sessionTitle = Instance.new("TextLabel")
sessionTitle.Size = UDim2.new(1, -20, 0, 32)
sessionTitle.Position = UDim2.fromOffset(10, 8)
sessionTitle.BackgroundTransparency = 1
sessionTitle.Text = "CONTROL SESSION"
sessionTitle.TextColor3 = Color3.new(1, 1, 1)
sessionTitle.TextSize = 17
sessionTitle.Font = Enum.Font.GothamBold
sessionTitle.TextXAlignment = Enum.TextXAlignment.Left
sessionTitle.Parent = session

local sessionPlayer = Instance.new("TextLabel")
sessionPlayer.Size = UDim2.new(1, -20, 0, 25)
sessionPlayer.Position = UDim2.fromOffset(10, 39)
sessionPlayer.BackgroundTransparency = 1
sessionPlayer.Text = ""
sessionPlayer.TextColor3 = Color3.fromRGB(175, 175, 175)
sessionPlayer.TextSize = 13
sessionPlayer.Font = Enum.Font.Gotham
sessionPlayer.TextXAlignment = Enum.TextXAlignment.Left
sessionPlayer.Parent = session

local resetButton = Instance.new("TextButton")
resetButton.Size = UDim2.new(1, -20, 0, 30)
resetButton.Position = UDim2.fromOffset(10, 68)
resetButton.BackgroundColor3 = Color3.fromRGB(55, 55, 65)
resetButton.BorderSizePixel = 0
resetButton.Text = "RESET"
resetButton.TextColor3 = Color3.new(1, 1, 1)
resetButton.TextSize = 13
resetButton.Font = Enum.Font.GothamBold
resetButton.Parent = session

corner(resetButton, 7)

local leaveButton = Instance.new("TextButton")
leaveButton.Size = UDim2.new(1, -20, 0, 30)
leaveButton.Position = UDim2.fromOffset(10, 103)
leaveButton.BackgroundColor3 = Color3.fromRGB(55, 55, 65)
leaveButton.BorderSizePixel = 0
leaveButton.Text = "LEAVE"
leaveButton.TextColor3 = Color3.new(1, 1, 1)
leaveButton.TextSize = 13
leaveButton.Font = Enum.Font.GothamBold
leaveButton.Parent = session

corner(leaveButton, 7)

local stopButton = Instance.new("TextButton")
stopButton.Size = UDim2.new(1, -20, 0, 30)
stopButton.Position = UDim2.fromOffset(10, 138)
stopButton.BackgroundColor3 = Color3.fromRGB(180, 65, 65)
stopButton.BorderSizePixel = 0
stopButton.Text = "STOP CONTROLLING"
stopButton.TextColor3 = Color3.new(1, 1, 1)
stopButton.TextSize = 12
stopButton.Font = Enum.Font.GothamBold
stopButton.Parent = session

corner(stopButton, 7)

--==================================================
-- MOBILE CONTROLS
--==================================================

local mobileControls = Instance.new("Frame")
mobileControls.Name = "MobileControls"
mobileControls.Size = UDim2.fromScale(1, 1)
mobileControls.BackgroundTransparency = 1
mobileControls.Visible = false
mobileControls.Parent = gui

local movePad = Instance.new("Frame")
movePad.Size = UDim2.fromOffset(150, 150)
movePad.Position = UDim2.new(0, 25, 1, -175)
movePad.BackgroundColor3 = Color3.fromRGB(35, 35, 42)
movePad.BackgroundTransparency = 0.25
movePad.BorderSizePixel = 0
movePad.Parent = mobileControls

corner(movePad, 75)

local moveKnob = Instance.new("Frame")
moveKnob.Size = UDim2.fromOffset(60, 60)
moveKnob.Position = UDim2.new(0.5, -30, 0.5, -30)
moveKnob.BackgroundColor3 = Color3.fromRGB(100, 100, 110)
moveKnob.BackgroundTransparency = 0.15
moveKnob.BorderSizePixel = 0
moveKnob.Parent = movePad

corner(moveKnob, 30)

local jumpButton = Instance.new("TextButton")
jumpButton.Size = UDim2.fromOffset(85, 85)
jumpButton.Position = UDim2.new(1, -120, 1, -125)
jumpButton.BackgroundColor3 = Color3.fromRGB(55, 120, 255)
jumpButton.BackgroundTransparency = 0.15
jumpButton.BorderSizePixel = 0
jumpButton.Text = "JUMP"
jumpButton.TextColor3 = Color3.new(1, 1, 1)
jumpButton.TextSize = 15
jumpButton.Font = Enum.Font.GothamBold
jumpButton.Parent = mobileControls

corner(jumpButton, 42)

-- Only show mobile controls on touch devices.
local isMobile = UserInputService.TouchEnabled

--==================================================
-- PLAYER LIST
--==================================================

local function refreshPlayers()
	for _, child in ipairs(playerList:GetChildren()) do
		if child:IsA("TextButton") then
			child:Destroy()
		end
	end

	local count = 0

	for _, player in ipairs(Players:GetPlayers()) do
		if player ~= LocalPlayer then
			count += 1

			local button = Instance.new("TextButton")
			button.Size = UDim2.new(1, -8, 0, 30)
			button.BackgroundColor3 = Color3.fromRGB(45, 45, 55)
			button.BorderSizePixel = 0
			button.Text = player.DisplayName .. "  @" .. player.Name
			button.TextColor3 = Color3.new(1, 1, 1)
			button.TextSize = 13
			button.Font = Enum.Font.Gotham
			button.Parent = playerList

			corner(button, 6)

			button.MouseButton1Click:Connect(function()
				selectedPlayer = player
				dropdown.Text = player.DisplayName .. "  @" .. player.Name
				playerList.Visible = false
			end)
		end
	end

	playerList.CanvasSize = UDim2.fromOffset(0, count * 33)
end

refreshPlayers()

Players.PlayerAdded:Connect(refreshPlayers)

Players.PlayerRemoving:Connect(function(player)
	if selectedPlayer == player then
		selectedPlayer = nil
		dropdown.Text = "Select Player ▼"
	end

	refreshPlayers()
end)

dropdown.MouseButton1Click:Connect(function()
	playerList.Visible = not playerList.Visible
end)

--==================================================
-- LOCAL PUPPET
--==================================================

local function createPuppet(player)
	local character = player.Character

	if not character then
		return nil
	end

	local targetRoot = getRoot(character)
	local targetHumanoid = getHumanoid(character)

	if not targetRoot or not targetHumanoid then
		return nil
	end

	character.Archivable = true

	local clone = character:Clone()

	if not clone then
		return nil
	end

	clone.Name = "__LocalVisualPuppet"

	local cloneRoot = getRoot(clone)

	if not cloneRoot then
		clone:Destroy()
		return nil
	end

	clone.Parent = workspace
	cloneRoot.CFrame = targetRoot.CFrame

	for _, object in ipairs(clone:GetDescendants()) do
		if object:IsA("Script")
			or object:IsA("LocalScript")
			or object:IsA("ModuleScript") then

			object.Disabled = true

		elseif object:IsA("BasePart") then
			object.CanCollide = false
			object.CanTouch = false
			object.CanQuery = false
			object.Massless = true
		end
	end

	local humanoid = getHumanoid(clone)

	if humanoid then
		humanoid.WalkSpeed = 11
		humanoid.JumpPower = 50
		humanoid.AutoRotate = true
		humanoid.DisplayDistanceType =
			Enum.HumanoidDisplayDistanceType.None
	end

	return clone
end

--==================================================
-- ANIMATIONS
--==================================================

local function setupAnimations(character)
	local humanoid = getHumanoid(character)

	if not humanoid then
		return
	end

	local animator = humanoid:FindFirstChildOfClass("Animator")

	if not animator then
		animator = Instance.new("Animator")
		animator.Parent = humanoid
	end

	local ids = {
		Idle = "rbxassetid://507766666",
		Walk = "rbxassetid://507777826",
		Run = "rbxassetid://507767714",
		Jump = "rbxassetid://507765000",
		Fall = "rbxassetid://507767968"
	}

	for name, id in pairs(ids) do
		local animation = Instance.new("Animation")
		animation.AnimationId = id

		local track = animator:LoadAnimation(animation)

		if name == "Idle" then
			track.Priority = Enum.AnimationPriority.Idle
			track.Looped = true
		elseif name == "Walk" or name == "Run" then
			track.Priority = Enum.AnimationPriority.Movement
			track.Looped = true
		else
			track.Priority = Enum.AnimationPriority.Action
		end

		animationTracks[name] = track
	end

	animationTracks.Idle:Play()
end

local function stopAnimation(name)
	local track = animationTracks[name]

	if track and track.IsPlaying then
		track:Stop(0.15)
	end
end

local function playAnimation(name)
	local track = animationTracks[name]

	if track and not track.IsPlaying then
		track:Play(0.15)
	end
end

local function clearAnimations()
	for _, track in pairs(animationTracks) do
		pcall(function()
			track:Stop()
			track:Destroy()
		end)
	end

	table.clear(animationTracks)
end

local function updateAnimations()
	if not puppet then
		return
	end

	local humanoid = getHumanoid(puppet)

	if not humanoid then
		return
	end

	local state = humanoid:GetState()

	if state == Enum.HumanoidStateType.Jumping then
		stopAnimation("Idle")
		stopAnimation("Walk")
		stopAnimation("Run")
		playAnimation("Jump")
		return
	end

	if state == Enum.HumanoidStateType.Freefall then
		stopAnimation("Idle")
		stopAnimation("Walk")
		stopAnimation("Run")
		playAnimation("Fall")
		return
	end

	if humanoid.MoveDirection.Magnitude > 0.05 then
		stopAnimation("Idle")

		if humanoid.WalkSpeed >= 15 then
			stopAnimation("Walk")
			playAnimation("Run")
		else
			stopAnimation("Run")
			playAnimation("Walk")
		end
	else
		stopAnimation("Walk")
		stopAnimation("Run")
		playAnimation("Idle")
	end
end

--==================================================
-- INPUT VECTOR
--==================================================

local function getInputVector()
	local x = 0
	local z = 0

	-- PC keyboard
	if keys.A then
		x -= 1
	end

	if keys.D then
		x += 1
	end

	if keys.W then
		z -= 1
	end

	if keys.S then
		z += 1
	end

	-- Mobile joystick
	if mobileMove.Magnitude > 0.05 then
		x += mobileMove.X
		z += mobileMove.Y
	end

	local vector = Vector3.new(x, 0, z)

	if vector.Magnitude > 1 then
		vector = vector.Unit
	end

	return vector
end

--==================================================
-- MOVEMENT
--==================================================

local function updateMovement()
	if not controlling or not puppet then
		return
	end

	local humanoid = getHumanoid(puppet)

	if not humanoid then
		return
	end

	local inputVector = getInputVector()

	if inputVector.Magnitude <= 0.01 then
		humanoid:Move(Vector3.zero, false)
		return
	end

	local camera = workspace.CurrentCamera

	local forward = Vector3.new(
		camera.CFrame.LookVector.X,
		0,
		camera.CFrame.LookVector.Z
	)

	local right = Vector3.new(
		camera.CFrame.RightVector.X,
		0,
		camera.CFrame.RightVector.Z
	)

	if forward.Magnitude > 0 then
		forward = forward.Unit
	end

	if right.Magnitude > 0 then
		right = right.Unit
	end

	local direction =
		(forward * -inputVector.Z)
		+ (right * inputVector.X)

	if direction.Magnitude > 0 then
		direction = direction.Unit
	end

	humanoid:Move(direction, false)
end

--==================================================
-- MOBILE JOYSTICK
--==================================================

local function updateJoystick(position)
	local center =
		movePad.AbsolutePosition +
		(movePad.AbsoluteSize / 2)

	local offset = position - center
	local radius = movePad.AbsoluteSize.X / 2

	if offset.Magnitude > radius then
		offset = offset.Unit * radius
	end

	mobileMove = Vector2.new(
		offset.X / radius,
		offset.Y / radius
	)

	moveKnob.Position = UDim2.fromOffset(
		movePad.AbsoluteSize.X / 2 + offset.X - 30,
		movePad.AbsoluteSize.Y / 2 + offset.Y - 30
	)
end

local function resetJoystick()
	mobileMove = Vector2.zero
	mobileTouch = nil

	moveKnob.Position =
		UDim2.new(0.5, -30, 0.5, -30)
end

movePad.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.Touch then
		mobileTouch = input
		updateJoystick(input.Position)
	end
end)

UserInputService.TouchMoved:Connect(function(input)
	if controlling and mobileTouch == input then
		updateJoystick(input.Position)
	end
end)

UserInputService.TouchEnded:Connect(function(input)
	if mobileTouch == input then
		resetJoystick()
	end
end)

jumpButton.MouseButton1Click:Connect(function()
	if not controlling or not puppet then
		return
	end

	local humanoid = getHumanoid(puppet)

	if humanoid then
		humanoid.Jump = true
	end
end)

--==================================================
-- START CONTROL
--==================================================

local function startControl(player)
	if controlling then
		return
	end

	local targetCharacter = player.Character

	if not targetCharacter then
		return
	end

	local targetRoot = getRoot(targetCharacter)

	if not targetRoot then
		return
	end

	originalCharacter = LocalPlayer.Character

	if not originalCharacter then
		return
	end

	originalRoot = getRoot(originalCharacter)

	if not originalRoot then
		return
	end

	local newPuppet = createPuppet(player)

	if not newPuppet then
		return
	end

	puppet = newPuppet
	selectedPlayer = player
	controlling = true

	-- Hide target ONLY locally.
	hiddenCharacter = targetCharacter
	hideLocally(hiddenCharacter)

	-- Freeze your actual character locally.
	originalRoot.Anchored = true

	local humanoid = getHumanoid(puppet)

	if humanoid then
		Camera.CameraType = Enum.CameraType.Custom
		Camera.CameraSubject = humanoid
	end

	setupAnimations(puppet)

	sessionPlayer.Text =
		"Controlling: " ..
		player.DisplayName ..
		"  @" ..
		player.Name

	main.Visible = false
	session.Visible = true

	if isMobile then
		mobileControls.Visible = true
	end
end

--==================================================
-- STOP CONTROL
--==================================================

local function stopControl()
	if not controlling then
		return
	end

	controlling = false

	for key in pairs(keys) do
		keys[key] = false
	end

	resetJoystick()

	clearAnimations()

	if hiddenCharacter and hiddenCharacter.Parent then
		showLocally(hiddenCharacter)
	end

	hiddenCharacter = nil

	if puppet then
		puppet:Destroy()
		puppet = nil
	end

	if originalRoot and originalRoot.Parent then
		originalRoot.Anchored = false
	end

	Camera.CameraType = Enum.CameraType.Custom

	if originalCharacter then
		local humanoid = getHumanoid(originalCharacter)

		if humanoid then
			Camera.CameraSubject = humanoid
		end
	end

	session.Visible = false
	main.Visible = true
	mobileControls.Visible = false

	selectedPlayer = nil
end

--==================================================
-- PC KEYBOARD
--==================================================

UserInputService.InputBegan:Connect(function(input, processed)
	if processed or not controlling then
		return
	end

	if input.KeyCode == Enum.KeyCode.W then
		keys.W = true

	elseif input.KeyCode == Enum.KeyCode.A then
		keys.A = true

	elseif input.KeyCode == Enum.KeyCode.S then
		keys.S = true

	elseif input.KeyCode == Enum.KeyCode.D then
		keys.D = true

	elseif input.KeyCode == Enum.KeyCode.Space then
		if puppet then
			local humanoid = getHumanoid(puppet)

			if humanoid then
				humanoid.Jump = true
			end
		end
	end
end)

UserInputService.InputEnded:Connect(function(input)
	if input.KeyCode == Enum.KeyCode.W then
		keys.W = false

	elseif input.KeyCode == Enum.KeyCode.A then
		keys.A = false

	elseif input.KeyCode == Enum.KeyCode.S then
		keys.S = false

	elseif input.KeyCode == Enum.KeyCode.D then
		keys.D = false
	end
end)

--==================================================
-- CONTROL BUTTON
--==================================================

controlButton.MouseButton1Click:Connect(function()
	if selectedPlayer then
		startControl(selectedPlayer)
	end
end)

stopButton.MouseButton1Click:Connect(function()
	stopControl()
end)

--==================================================
-- FAKE RESET
--==================================================

resetButton.MouseButton1Click:Connect(function()
	if not controlling or not puppet or not selectedPlayer then
		return
	end

	local targetRoot = getRoot(selectedPlayer.Character)
	local puppetRoot = getRoot(puppet)

	if targetRoot and puppetRoot then
		puppetRoot.CFrame = targetRoot.CFrame
	end

	local humanoid = getHumanoid(puppet)

	if humanoid then
		humanoid.Health = humanoid.MaxHealth
		humanoid:Move(Vector3.zero, false)
	end
end)

--==================================================
-- FAKE LEAVE
--==================================================

leaveButton.MouseButton1Click:Connect(function()
	if not controlling or not puppet then
		return
	end

	local root = getRoot(puppet)

	if root then
		local startCFrame = root.CFrame

		for i = 1, 25 do
			if not puppet or not puppet.Parent then
				break
			end

			local currentRoot = getRoot(puppet)

			if currentRoot then
				currentRoot.CFrame =
					startCFrame *
					CFrame.new(
						0,
						i * 0.08,
						-i * 0.12
					)
			end

			task.wait(0.025)
		end
	end

	stopControl()
end)

--==================================================
-- RENDER LOOP
--==================================================

RunService.RenderStepped:Connect(function()
	if not controlling or not puppet then
		return
	end

	updateMovement()
	updateAnimations()

	local humanoid = getHumanoid(puppet)

	if humanoid then
		Camera.CameraSubject = humanoid
	end
end)

--==================================================
-- RESPAWN CLEANUP
--==================================================

LocalPlayer.CharacterAdded:Connect(function(character)
	if controlling then
		stopControl()
	end

	originalCharacter = character
	originalRoot = getRoot(character)
end)

-- Initial state
if isMobile then
	mobileControls.Visible = false
end
