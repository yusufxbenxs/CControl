-- Complete Client Control Engine (GitHub Loadstring Safe)
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local SoundService = game:GetService("SoundService")

local localPlayer = Players.LocalPlayer
local camera = Workspace.CurrentCamera
local playerGui = localPlayer:WaitForChild("PlayerGui")

-- Global States
local controlling = false
local selectedPlr = nil
local targetPlayer = nil
local fakeChar = nil
local originalCFrame = nil
local renderConnection = nil
local visConnection = nil
local loadedTracks = {}

-- UI Cleanup
if playerGui:FindFirstChild("FullControlGUI") then playerGui.FullControlGUI:Destroy() end
if playerGui:FindFirstChild("FullSessionGUI") then playerGui.FullSessionGUI:Destroy() end

--------------------------------------------------------------------------------
-- SOUND ENGINE
--------------------------------------------------------------------------------
local function playLocalSound(soundId, volume, parent)
    pcall(function()
        local snd = Instance.new("Sound")
        snd.SoundId = soundId
        snd.Volume = volume or 1
        snd.Parent = parent or SoundService
        snd:Play()
        snd.Ended:Connect(function() snd:Destroy() end)
    end)
end

local SOUNDS = {
    Oof = "rbxassetid://12222084",
    Jump = "rbxassetid://12222216",
    Footstep = "rbxassetid://9114223179"
}

--------------------------------------------------------------------------------
-- MANUAL ANIMATION SYSTEM
--------------------------------------------------------------------------------
local function loadManualAnimations(char)
    local hum = char:FindFirstChildOfClass("Humanoid")
    if not hum then return end
    
    local animator = hum:FindFirstChildOfClass("Animator") or Instance.new("Animator", hum)
    loadedTracks = {}

    local isR15 = char:FindFirstChild("UpperTorso") ~= nil
    local animIds = isR15 and {
        Idle = "rbxassetid://507766388",
        Walk = "rbxassetid://913403203"
    } or {
        Idle = "rbxassetid://180435571",
        Walk = "rbxassetid://180436334"
    }

    for name, id in pairs(animIds) do
        pcall(function()
            local anim = Instance.new("Animation")
            anim.AnimationId = id
            local track = animator:LoadAnimation(anim)
            loadedTracks[name] = track
        end)
    end
    
    if loadedTracks.Idle then loadedTracks.Idle:Play() end
end

local function playTrack(name)
    if not loadedTracks[name] then return end
    for trackName, track in pairs(loadedTracks) do
        if trackName ~= name and track.IsPlaying then
            track:Stop(0.15)
        end
    end
    if not loadedTracks[name].IsPlaying then
        loadedTracks[name]:Play(0.15)
    end
end

--------------------------------------------------------------------------------
-- GUI CREATION
--------------------------------------------------------------------------------
local mainGui = Instance.new("ScreenGui")
mainGui.Name = "FullControlGUI"
mainGui.ResetOnSpawn = false
mainGui.DisplayOrder = 999
mainGui.Parent = playerGui

local sessionGui = Instance.new("ScreenGui")
sessionGui.Name = "FullSessionGUI"
sessionGui.ResetOnSpawn = false
sessionGui.DisplayOrder = 999
sessionGui.Enabled = false
sessionGui.Parent = playerGui

-- Main Panel
local mainFrame = Instance.new("Frame")
mainFrame.Size = UDim2.new(0, 240, 0, 180)
mainFrame.Position = UDim2.new(0.05, 0, 0.3, 0)
mainFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
mainFrame.BorderSizePixel = 0
mainFrame.Active = true
mainFrame.Draggable = true
mainFrame.Parent = mainGui

local mainCorner = Instance.new("UICorner")
mainCorner.CornerRadius = UDim.new(0, 8)
mainCorner.Parent = mainFrame

local titleLabel = Instance.new("TextLabel")
titleLabel.Size = UDim2.new(1, -30, 0, 30)
titleLabel.Position = UDim2.new(0, 10, 0, 0)
titleLabel.BackgroundTransparency = 1
titleLabel.Text = "Player Control Center"
titleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
titleLabel.Font = Enum.Font.SourceSansBold
titleLabel.TextSize = 14
titleLabel.TextXAlignment = Enum.TextXAlignment.Left
titleLabel.Parent = mainFrame

local closeBtn = Instance.new("TextButton")
closeBtn.Size = UDim2.new(0, 22, 0, 22)
closeBtn.Position = UDim2.new(1, -26, 0, 4)
closeBtn.BackgroundColor3 = Color3.fromRGB(200, 40, 40)
closeBtn.Text = "X"
closeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
closeBtn.Font = Enum.Font.SourceSansBold
closeBtn.TextSize = 13
closeBtn.Parent = mainFrame

-- Dropdown Button
local dropBtn = Instance.new("TextButton")
dropBtn.Size = UDim2.new(1, -20, 0, 28)
dropBtn.Position = UDim2.new(0, 10, 0, 35)
dropBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
dropBtn.Text = "Select Player ▼"
dropBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
dropBtn.Font = Enum.Font.SourceSans
dropBtn.TextSize = 13
dropBtn.Parent = mainFrame

-- Textbox Search Option
local searchBox = Instance.new("TextBox")
searchBox.Size = UDim2.new(1, -20, 0, 28)
searchBox.Position = UDim2.new(0, 10, 0, 70)
searchBox.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
searchBox.PlaceholderText = "Or type username/display..."
searchBox.PlaceholderColor3 = Color3.fromRGB(150, 150, 150)
searchBox.Text = ""
searchBox.TextColor3 = Color3.fromRGB(255, 255, 255)
searchBox.Font = Enum.Font.SourceSans
searchBox.TextSize = 12
searchBox.ClearTextOnFocus = false
searchBox.Parent = mainFrame

local dropFrame = Instance.new("ScrollingFrame")
dropFrame.Size = UDim2.new(1, -20, 0, 90)
dropFrame.Position = UDim2.new(0, 10, 0, 65)
dropFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
dropFrame.Visible = false
dropFrame.ZIndex = 10
dropFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
dropFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y
dropFrame.Parent = mainFrame

local dropLayout = Instance.new("UIListLayout")
dropLayout.Parent = dropFrame

local controlBtn = Instance.new("TextButton")
controlBtn.Size = UDim2.new(1, -20, 0, 30)
controlBtn.Position = UDim2.new(0, 10, 0, 135)
controlBtn.BackgroundColor3 = Color3.fromRGB(46, 204, 113)
controlBtn.Text = "Control Player"
controlBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
controlBtn.Font = Enum.Font.SourceSansBold
controlBtn.TextSize = 14
controlBtn.Parent = mainFrame

-- Active Control Overlay Panel
local sessionFrame = Instance.new("Frame")
sessionFrame.Size = UDim2.new(0, 140, 0, 110)
sessionFrame.Position = UDim2.new(0, 10, 0.5, -55)
sessionFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
sessionFrame.BackgroundTransparency = 0.2
sessionFrame.BorderSizePixel = 0
sessionFrame.Active = true
sessionFrame.Draggable = true
sessionFrame.Parent = sessionGui

local sessionLayout = Instance.new("UIListLayout")
sessionLayout.Padding = UDim.new(0, 5)
sessionLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
sessionLayout.VerticalAlignment = Enum.VerticalAlignment.Center
sessionLayout.Parent = sessionFrame

local stopBtn = Instance.new("TextButton")
stopBtn.Size = UDim2.new(0, 120, 0, 28)
stopBtn.BackgroundColor3 = Color3.fromRGB(231, 76, 60)
stopBtn.Text = "Stop Controlling"
stopBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
stopBtn.Font = Enum.Font.SourceSansBold
stopBtn.TextSize = 12
stopBtn.Parent = sessionFrame

local resetBtn = Instance.new("TextButton")
resetBtn.Size = UDim2.new(0, 120, 0, 28)
resetBtn.BackgroundColor3 = Color3.fromRGB(230, 126, 34)
resetBtn.Text = "Reset Character"
resetBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
resetBtn.Font = Enum.Font.SourceSansBold
resetBtn.TextSize = 12
resetBtn.Parent = sessionFrame

local leaveBtn = Instance.new("TextButton")
leaveBtn.Size = UDim2.new(0, 120, 0, 28)
leaveBtn.BackgroundColor3 = Color3.fromRGB(142, 68, 173)
leaveBtn.Text = "Leave Game"
leaveBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
leaveBtn.Font = Enum.Font.SourceSansBold
leaveBtn.TextSize = 12
leaveBtn.Parent = sessionFrame

for _, btn in ipairs({stopBtn, resetBtn, leaveBtn, controlBtn, dropBtn, closeBtn, searchBox}) do
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, 5)
    c.Parent = btn
end

--------------------------------------------------------------------------------
-- TARGET & SELECTION HANDLER
--------------------------------------------------------------------------------
local function setCharacterVisibility(character, visible)
    if not character then return end
    local alpha = visible and 0 or 1
    for _, part in ipairs(character:GetDescendants()) do
        if part:IsA("BasePart") or part:IsA("Decal") then
            part.LocalTransparencyModifier = alpha
        end
    end
end

local function cleanPreviousTarget()
    if visConnection then visConnection:Disconnect() visConnection = nil end
    if targetPlayer and targetPlayer.Character then
        setCharacterVisibility(targetPlayer.Character, true)
    end
    if fakeChar then
        fakeChar:Destroy()
        fakeChar = nil
    end
    targetPlayer = nil
end

local function selectUser(plr)
    if selectedPlr ~= plr then
        cleanPreviousTarget()
        selectedPlr = plr
    end
    dropBtn.Text = plr.Name .. " ▼"
    searchBox.Text = plr.Name
    dropFrame.Visible = false
end

local function updateDropdown()
    for _, child in ipairs(dropFrame:GetChildren()) do
        if child:IsA("TextButton") then child:Destroy() end
    end
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= localPlayer then
            local btn = Instance.new("TextButton")
            btn.Size = UDim2.new(1, 0, 0, 24)
            btn.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
            btn.Text = plr.DisplayName .. " (@" .. plr.Name .. ")"
            btn.TextColor3 = Color3.fromRGB(255, 255, 255)
            btn.Font = Enum.Font.SourceSans
            btn.TextSize = 12
            btn.ZIndex = 11
            btn.Parent = dropFrame

            btn.MouseButton1Click:Connect(function() selectUser(plr) end)
        end
    end
end

dropBtn.MouseButton1Click:Connect(function()
    if not dropFrame.Visible then updateDropdown() end
    dropFrame.Visible = not dropFrame.Visible
end)

-- Textbox Typing Filter
searchBox:GetPropertyChangedSignal("Text"):Connect(function()
    local text = searchBox.Text:lower()
    if text == "" then return end
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= localPlayer then
            if plr.Name:lower():sub(1, #text) == text or plr.DisplayName:lower():sub(1, #text) == text then
                selectedPlr = plr
                dropBtn.Text = plr.Name .. " ▼"
                break
            end
        end
    end
end)

local function spawnCloneForTarget(target)
    if not target or not target.Character then return nil end
    local realChar = target.Character
    realChar.Archivable = true
    local newClone = realChar:Clone()
    realChar.Archivable = false
    newClone.Name = target.Name .. "_Controlled"
    newClone.Parent = Workspace

    for _, part in ipairs(newClone:GetDescendants()) do
        if part:IsA("BasePart") then
            part.Anchored = false
            part.CanCollide = true
        end
    end

    loadManualAnimations(newClone)
    return newClone
end

--------------------------------------------------------------------------------
-- SMOOTH PHYSICS ENGINE & CONTROLLER
--------------------------------------------------------------------------------
local function stopControlSession(destroyClone)
    controlling = false
    if renderConnection then renderConnection:Disconnect() renderConnection = nil end

    if destroyClone then cleanPreviousTarget() end

    if localPlayer.Character and localPlayer.Character:FindFirstChild("HumanoidRootPart") then
        localPlayer.Character.HumanoidRootPart.Anchored = false
        if originalCFrame then localPlayer.Character.HumanoidRootPart.CFrame = originalCFrame end
        if localPlayer.Character:FindFirstChildOfClass("Humanoid") then
            camera.CameraType = Enum.CameraType.Custom
            camera.CameraSubject = localPlayer.Character:FindFirstChildOfClass("Humanoid")
        end
    end

    sessionGui.Enabled = false
    mainGui.Enabled = true
end

local function startControlSession()
    if not selectedPlr or not selectedPlr.Character then return end

    if targetPlayer ~= selectedPlr then
        cleanPreviousTarget()
        targetPlayer = selectedPlr
    end

    local myChar = localPlayer.Character
    local myHrp = myChar and myChar:FindFirstChild("HumanoidRootPart")
    if not myHrp then return end

    controlling = true
    originalCFrame = myHrp.CFrame
    myHrp.Anchored = true

    if visConnection then visConnection:Disconnect() end
    visConnection = RunService.RenderStepped:Connect(function()
        if targetPlayer and targetPlayer.Character then
            setCharacterVisibility(targetPlayer.Character, false)
        end
    end)

    if not fakeChar then
        fakeChar = spawnCloneForTarget(targetPlayer)
    end

    local fakeHumanoid = fakeChar and fakeChar:FindFirstChildOfClass("Humanoid")
    local fakeHrp = fakeChar and fakeChar:FindFirstChild("HumanoidRootPart")

    if fakeHumanoid and fakeHrp then
        camera.CameraType = Enum.CameraType.Custom
        camera.CameraSubject = fakeHumanoid

        local speed = 16
        local verticalVelocity = 0
        local lastFootstep = 0
        local wasJumping = false

        renderConnection = RunService.RenderStepped:Connect(function(dt)
            if not controlling or not fakeHrp then return end

            local camCFrame = camera.CFrame
            local camLook = Vector3.new(camCFrame.LookVector.X, 0, camCFrame.LookVector.Z).Unit
            local camRight = Vector3.new(camCFrame.RightVector.X, 0, camCFrame.RightVector.Z).Unit

            local moveDir = Vector3.zero

            if UserInputService:IsKeyDown(Enum.KeyCode.W) then moveDir = moveDir + camLook end
            if UserInputService:IsKeyDown(Enum.KeyCode.S) then moveDir = moveDir - camLook end
            if UserInputService:IsKeyDown(Enum.KeyCode.D) then moveDir = moveDir + camRight end
            if UserInputService:IsKeyDown(Enum.KeyCode.A) then moveDir = moveDir - camRight end

            -- Downward Raycast Physics for Jump & Ground Detection
            local ray = Ray.new(fakeHrp.Position, Vector3.new(0, -3.2, 0))
            local hitPart = Workspace:FindPartOnRayWithIgnoreList(ray, {fakeChar, localPlayer.Character})
            local isGrounded = hitPart ~= nil

            -- Gravity / Jump Solver
            local isJumping = UserInputService:IsKeyDown(Enum.KeyCode.Space)
            if isGrounded then
                if verticalVelocity < 0 then verticalVelocity = 0 end
                if isJumping and not wasJumping then
                    verticalVelocity = 48
                    playLocalSound(SOUNDS.Jump, 0.6, fakeHrp)
                end
            else
                verticalVelocity = verticalVelocity - (196.2 * dt)
            end
            wasJumping = isJumping

            -- Smooth Angular Rotation (60 FPS Interpolation)
            if moveDir.Magnitude > 0 then
                moveDir = moveDir.Unit
                local targetLook = CFrame.lookAt(fakeHrp.Position, fakeHrp.Position + moveDir)
                fakeHrp.CFrame = fakeHrp.CFrame:Lerp(targetLook, 15 * dt) + (moveDir * speed * dt) + Vector3.new(0, verticalVelocity * dt, 0)
                
                playTrack("Walk")

                if tick() - lastFootstep > 0.35 and isGrounded then
                    playLocalSound(SOUNDS.Footstep, 0.4, fakeHrp)
                    lastFootstep = tick()
                end
            else
                fakeHrp.CFrame = fakeHrp.CFrame + Vector3.new(0, verticalVelocity * dt, 0)
                playTrack("Idle")
            end
        end)
    end

    mainGui.Enabled = false
    sessionGui.Enabled = true
end

--------------------------------------------------------------------------------
-- EVENT BINDINGS
--------------------------------------------------------------------------------
controlBtn.MouseButton1Click:Connect(startControlSession)

stopBtn.MouseButton1Click:Connect(function()
    stopControlSession(false)
end)

resetBtn.MouseButton1Click:Connect(function()
    if fakeChar then
        local hrp = fakeChar:FindFirstChild("HumanoidRootPart")
        if hrp then playLocalSound(SOUNDS.Oof, 1, hrp) end
        
        for _, desc in ipairs(fakeChar:GetDescendants()) do
            if desc:IsA("Motor6D") then desc:Destroy() end
        end

        task.wait(1.2)
        if fakeChar then fakeChar:Destroy() fakeChar = nil end

        if targetPlayer then
            fakeChar = spawnCloneForTarget(targetPlayer)
            startControlSession()
        end
    end
end)

leaveBtn.MouseButton1Click:Connect(function()
    if fakeChar then fakeChar:Destroy() fakeChar = nil end
    camera.CameraType = Enum.CameraType.Scriptable
    task.wait(3)
    stopControlSession(true)
end)

closeBtn.MouseButton1Click:Connect(function()
    stopControlSession(true)
    mainGui:Destroy()
    sessionGui:Destroy()
end)
