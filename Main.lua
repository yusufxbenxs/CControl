--!strict
-- CLIENT-ONLY PLAYER CONTROL ILLUSION
-- Place in StarterPlayer > StarterPlayerScripts
--
-- The selected player is represented by a LOCAL clone.
-- No RemoteEvents or server-side movement are used.

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

local controlling = false
local selectedPlayer: Player? = nil
local puppet: Model? = nil

local originalCharacter: Model? = nil
local originalRoot: BasePart? = nil
local hiddenCharacter: Model? = nil

local keys = {
	W = false,
	A = false,
	S = false,
	D = false,
}

local animationTracks = {}

--==================================================
-- HELPERS
--==================================================

local function getHumanoid(character: Model?)
	if not character then
		return nil
	end

	return character:FindFirstChildOfClass("Humanoid")
end

local function getRoot(character: Model?)
	if not character then
		return nil
	end

	return character:FindFirstChild("HumanoidRootPart") :: BasePart?
end

local function makeCorner(object: GuiObject, radius: number)
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, radius)
	corner.Parent = object
end

local function setLocalVisibility(character: Model, visible: boolean)
	for _, object in ipairs(character:GetDescendants()) do
		if object:IsA("BasePart") then
			object.LocalTransparencyModifier = visible and 0 or 1

		elseif object:IsA("Decal") or object:IsA("Texture") then
			object.Transparency = visible and 0 or 1
		end
	end
end

--==================================================
-- GUI
--==================================================

local gui = Instance.new("ScreenGui")
gui.Name = "LocalControlUI"
gui.ResetOnSpawn = false
gui.Parent = PlayerGui

--==================================================
-- MAIN WINDOW
--==================================================

local main = Instance.new("Frame")
main.Size = UDim2.fromOffset(320, 210)
main.Position = UDim2.new(0.5, -160, 0.5, -105)
main.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
main.BorderSizePixel = 0
main.Parent = gui

makeCorner(main, 12)

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

makeCorner(dropdown, 8)

local playerList = Instance.new("ScrollingFrame")
playerList.Size = UDim2.new(1, -20, 0, 105)
playerList.Position = UDim2.fromOffset(10, 94)
playerList.BackgroundColor3 = Color3.fromRGB(32, 32, 38)
playerList.BorderSizePixel = 0
playerList.ScrollBarThickness = 5
playerList.Visible = false
playerList.Parent = main

makeCorner(playerList, 8)

local listLayout = Instance.new("UIListLayout")
listLayout.Padding = UDim.new(0, 3)
listLayout.Parent = playerList

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

makeCorner(controlButton, 8)

--==================================================
-- SESSION WINDOW
--==================================================

local session = Instance.new("Frame")
session.Size = UDim2.fromOffset(245, 180)

-- lower-right / middle-ish
session.Position = UDim2.new(1, -265, 0.5, -90)

session.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
session.BorderSizePixel = 0
session.Visible = false
session.Parent = gui

makeCorner(session, 12)

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

makeCorner(resetButton, 7)

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

makeCorner(leaveButton, 7)

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

makeCorner(stopButton, 7)

--==================================================
-- PLAYER LIST
--==================================================

local function refreshPlayerList()
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

			makeCorner(button, 6)

			button.MouseButton1Click:Connect(function()
				selectedPlayer = player
				dropdown.Text = player.DisplayName .. "  @" .. player.Name
				playerList.Visible = false
			end)
		end
	end

	playerList.CanvasSize = UDim2.fromOffset(0, count * 33)
end

refreshPlayerList()

Players.PlayerAdded:Connect(refreshPlayerList)

Players.PlayerRemoving:Connect(function(player)
	if selectedPlayer == player then
		selectedPlayer = nil
		dropdown.Text = "Select Player ▼"
	end

	refreshPlayerList()
end)

dropdown.MouseButton1Click:Connect(function()
	playerList.Visible = not playerList.Visible
end)

--==================================================
-- CREATE LOCAL PUPPET
--==================================================

local function createPuppet(player: Player): Model?
	local character = player.Character

	if not character then
		return nil
	end

	local root = getRoot(character)
	local humanoid = getHumanoid(character)

	if not root or not humanoid then
		return nil
	end

	character.Archivable = true

	local clone = character:Clone()
	clone.Name = "__LocalVisualPuppet"

	local cloneRoot = getRoot(clone)

	if not cloneRoot then
		clone:Destroy()
		return nil
	end

	clone.Parent = workspace
	cloneRoot.CFrame = root.CFrame

	-- Disable scripts in the clone.
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

	local cloneHumanoid = getHumanoid(clone)

	if cloneHumanoid then
		cloneHumanoid.WalkSpeed = 11
		cloneHumanoid.JumpPower = 50
		cloneHumanoid.AutoRotate = true
		cloneHumanoid.DisplayDistanceType =
			Enum.HumanoidDisplayDistanceType.None
	end

	return clone
end

--==================================================
-- ANIMATIONS
--==================================================

local function setupAnimations(character: Model)
	local humanoid = getHumanoid(character)

	if not humanoid then
		return
	end

	local animator = humanoid:FindFirstChildOfClass("Animator")

	if not animator then
		animator = Instance.new("Animator")
		animator.Parent = humanoid
	end

	-- R15/R6-compatible standard animation IDs.
	local ids = {
		Idle = "rbxassetid://507766666",
		Walk = "rbxassetid://507777826",
		Run = "rbxassetid://507767714",
		Jump = "rbxassetid://507765000",
		Fall = "rbxassetid://507767968",
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

	if animationTracks.Idle then
		animationTracks.Idle:Play()
	end
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
-- MOVEMENT
--==================================================

local function getInputVector(): Vector3
	local x = 0
	local z = 0

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

	local vector = Vector3.new(x, 0, z)

	if vector.Magnitude > 1 then
		vector = vector.Unit
	end

	return vector
end

local function updateMovement()
	if not controlling or not puppet then
		return
	end

	local humanoid = getHumanoid(puppet)

	if not humanoid then
		return
	end

	local inputVector = getInputVector()

	if inputVector.Magnitude == 0 then
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

	clearAnimations()

	-- Restore the actual target locally.
	if hiddenCharacter and hiddenCharacter.Parent then
		setLocalVisibility(hiddenCharacter, true)
	end

	hiddenCharacter = nil

	if puppet then
		puppet:Destroy()
		puppet = nil
	end

	-- Unanchor YOUR character locally.
	if originalRoot and originalRoot.Parent then
		originalRoot.Anchored = false
	end

	local camera = workspace.CurrentCamera
	camera.CameraType = Enum.CameraType.Custom

	if originalCharacter then
		local humanoid = getHumanoid(originalCharacter)

		if humanoid then
			camera.CameraSubject = humanoid
		end
	end

	selectedPlayer = nil
	controlling = false

	session.Visible = false
	main.Visible = true
end

--==================================================
-- START CONTROL
--==================================================

local function startControl(player: Player)
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

	-- Hide the REAL target only on this client.
	hiddenCharacter = targetCharacter
	setLocalVisibility(targetCharacter, false)

	-- Freeze YOUR real character locally.
	originalRoot.Anchored = true

	-- Camera follows the local puppet.
	local puppetHumanoid = getHumanoid(puppet)

	if puppetHumanoid then
		local camera = workspace.CurrentCamera

		camera.CameraType = Enum.CameraType.Custom
		camera.CameraSubject = puppetHumanoid
	end

	setupAnimations(puppet)

	sessionPlayer.Text =
		"Controlling: " ..
		player.DisplayName ..
		"  @" ..
		player.Name

	main.Visible = false
	session.Visible = true
end

--==================================================
-- BUTTONS
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

	local targetCharacter = selectedPlayer.Character
	local targetRoot = getRoot(targetCharacter)
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
		local startingCFrame = root.CFrame

		for i = 1, 25 do
			if not puppet or not puppet.Parent then
				break
			end

			local currentRoot = getRoot(puppet)

			if currentRoot then
				currentRoot.CFrame =
					startingCFrame
					* CFrame.new(0, i * 0.08, -i * 0.12)
			end

			task.wait(0.025)
		end
	end

	stopControl()
end)

--==================================================
-- KEYBOARD INPUT
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
		workspace.CurrentCamera.CameraSubject = humanoid
	end
end)

--==================================================
-- CHARACTER RESPAWN CLEANUP
--==================================================

LocalPlayer.CharacterAdded:Connect(function(character)
	if controlling then
		stopControl()
	end

	originalCharacter = character
	originalRoot = getRoot(character)
end)
