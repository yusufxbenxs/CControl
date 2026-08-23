-- Cross-Platform Player Control Script (Fixed Target Switching & Animation Engine)
local getService = function(service)
    return (cloneref and cloneref(game:GetService(service))) or game:GetService(service)
end

local Players = getService("Players")
local Workspace = getService("Workspace")
local UserInputService = getService("UserInputService")
local RunService = getService("RunService")
local CoreGui = getService("CoreGui")
local SoundService = getService("SoundService")

local localPlayer = Players.LocalPlayer
local camera = Workspace.CurrentCamera

-- Global States
local controlling = false
local targetPlayer = nil
local fakeChar = nil
local originalCFrame = nil
local renderConnection = nil
local visConnection = nil

-- Clean up existing UIs
local guiParent = (gethui and gethui()) or CoreGui or localPlayer:WaitForChild("PlayerGui")
if guiParent:FindFirstChild("ControlMainGUI") then guiParent.ControlMainGUI:Destroy() end
if guiParent:FindFirstChild("ControlSessionGUI") then guiParent.ControlSessionGUI:Destroy() end

--------------------------------------------------------------------------------
-- SOUND EFFECTS ENGINE
--------------------------------------------------------------------------------
local function playLocalSound(soundId, volume, parent)
    local snd = Instance.new("Sound")
    snd.SoundId = soundId
    snd.Volume = volume or 1
    snd.Parent = parent or SoundService
    snd:Play()
    snd.Ended:Connect(function() snd:Destroy() end)
    return snd
end

local SOUNDS = {
    Oof = "rbxassetid://12222084",
    Jump = "rbxassetid://12222216",
    Footstep = "rbxassetid://9114223179"
}

--------------------------------------------------------------------------------
-- GUI SETUP
--------------------------------------------------------------------------------
local mainGui = Instance.new("ScreenGui")
mainGui.Name = "ControlMainGUI"
mainGui.ResetOnSpawn = false
mainGui.Parent = guiParent

local sessionGui = Instance.new("ScreenGui")
sessionGui.Name = "ControlSessionGUI"
sessionGui.ResetOnSpawn = false
sessionGui.Enabled = false
sessionGui.Parent = guiParent

-- Main Window
local mainFrame = Instance.new("Frame")
mainFrame.Size = UDim2.new(0, 240, 0, 130)
mainFrame.Position = UDim2.new(0.05, 0, 0.3, 0)
mainFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
mainFrame.BorderSizePixel = 0
mainFrame.Active = true
mainFrame.Parent = mainGui

local mainCorner = Instance.new("UICorner")
mainCorner.CornerRadius = UDim.new(0, 8)
mainCorner.Parent = mainFrame

local titleLabel = Instance.new("TextLabel")
titleLabel.Size = UDim2.new(1, -30, 0, 30)
titleLabel.Position = UDim2.new(0, 10, 0, 0)
titleLabel.BackgroundTransparency = 1
titleLabel.Text = "Player Control"
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

local closeCorner = Instance.new("UICorner")
closeCorner.CornerRadius = UDim.new(0, 4)
closeCorner.Parent = closeBtn

local dropBtn = Instance.new("TextButton")
dropBtn.Size = UDim2.new(1, -20, 0, 30)
dropBtn.Position = UDim2.new(0, 10, 0, 35)
dropBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
dropBtn.Text = "Select Player ▼"
dropBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
dropBtn.Font = Enum.Font.SourceSans
dropBtn.TextSize = 13
dropBtn.Parent = mainFrame

local dropCorner = Instance.new("UICorner")
dropCorner.CornerRadius = UDim.new(0, 6)
dropCorner.Parent = dropBtn

local dropFrame = Instance.new("ScrollingFrame")
dropFrame.Size = UDim2.new(1, -20, 0, 100)
dropFrame.Position = UDim2.new(0, 10, 0, 68)
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
controlBtn.Position = UDim2.new(0, 10, 0, 80)
controlBtn.BackgroundColor3 = Color3.fromRGB(46, 204, 113)
controlBtn.Text = "Control Player"
controlBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
controlBtn.Font = Enum.Font.SourceSansBold
controlBtn.TextSize = 14
controlBtn.Parent = mainFrame

local controlCorner = Instance.new("UICorner")
controlCorner.CornerRadius = UDim.new(0, 6)
controlCorner.Parent = controlBtn

-- Session Overlay
local sessionFrame = Instance.new("Frame")
sessionFrame.Size = UDim2.new(0, 140, 0, 110)
sessionFrame.Position = UDim2.new(0, 10, 0.5, -55)
sessionFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
sessionFrame.BackgroundTransparency = 0.2
sessionFrame.BorderSizePixel = 0
sessionFrame.Parent = sessionGui

local sessionCorner = Instance.new("UICorner")
sessionCorner.CornerRadius = UDim.new(0, 8)
sessionCorner.Parent = sessionFrame

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

for _, btn in ipairs({stopBtn, resetBtn, leaveBtn}) do
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, 4)
    c.Parent = btn
end

--------------------------------------------------------------------------------
-- HELPER FUNCTIONS & DROPDOWN MANAGEMENT
--------------------------------------------------------------------------------
local selectedPlr = nil

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
    if visConnection then 
        visConnection:Disconnect() 
        visConnection = nil 
    end
    if targetPlayer and targetPlayer.Character then
        setCharacterVisibility(targetPlayer.Character, true)
    end
    if fakeChar then
        fakeChar:Destroy()
        fakeChar = nil
    end
    targetPlayer = nil
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

            btn.MouseButton1Click:Connect(function()
                -- When selecting a new target, clean old target references
                if selectedPlr ~= plr then
                    cleanPreviousTarget()
                    selectedPlr = plr
                end
                dropBtn.Text = plr.Name .. " ▼"
                dropFrame.Visible = false
            end)
        end
    end
end

dropBtn.MouseButton1Click:Connect(function()
    if not dropFrame.Visible then updateDropdown() end
    dropFrame.Visible = not dropFrame.Visible
end)

local function setupAnimations(char)
    local humanoid = char:FindFirstChildOfClass("Humanoid")
    if not humanoid then return end

    local animateScript = char:FindFirstChild("Animate")
    if animateScript then
        local cloneAnim = animateScript:Clone()
        animateScript:Destroy()
        cloneAnim.Disabled = false
        cloneAnim.Parent = char
    end
end

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

    setupAnimations(newClone)
    return newClone
end

--------------------------------------------------------------------------------
-- CORE CONTROLLER ENGINE
--------------------------------------------------------------------------------
local function stopControlSession(destroyClone)
    controlling = false
    if renderConnection then renderConnection:Disconnect() renderConnection = nil end

    if destroyClone then
        cleanPreviousTarget()
    end

    if localPlayer.Character and localPlayer.Character:FindFirstChild("HumanoidRootPart") then
        localPlayer.Character.HumanoidRootPart.Anchored = false
        if originalCFrame then
            localPlayer.Character.HumanoidRootPart.CFrame = originalCFrame
        end
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

    -- Reset previous target if target has changed
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

    -- Constant visibility enforcement for chosen target
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

        local lastFootstep = 0
        local wasJumping = false

        renderConnection = RunService.RenderStepped:Connect(function()
            if not controlling or not fakeHumanoid or not fakeHrp then return end

            local camCFrame = camera.CFrame
            local camLook = Vector3.new(camCFrame.LookVector.X, 0, camCFrame.LookVector.Z).Unit
            local camRight = Vector3.new(camCFrame.RightVector.X, 0, camCFrame.RightVector.Z).Unit

            local moveDirection = Vector3.zero

            -- Keyboard Controls
            if UserInputService:IsKeyDown(Enum.KeyCode.W) then moveDirection = moveDirection + camLook end
            if UserInputService:IsKeyDown(Enum.KeyCode.S) then moveDirection = moveDirection - camLook end
            if UserInputService:IsKeyDown(Enum.KeyCode.D) then moveDirection = moveDirection + camRight end
            if UserInputService:IsKeyDown(Enum.KeyCode.A) then moveDirection = moveDirection - camRight end

            -- Mobile Touch Controller
            local myHum = localPlayer.Character and localPlayer.Character:FindFirstChildOfClass("Humanoid")
            if myHum and myHum.MoveDirection.Magnitude > 0 then
                moveDirection = myHum.MoveDirection
            end

            -- Apply Movement & Footstep Audio
            if moveDirection.Magnitude > 0 then
                fakeHumanoid:Move(moveDirection.Unit, false)
                if tick() - lastFootstep > 0.35 and fakeHumanoid.FloorMaterial ~= Enum.Material.Air then
                    playLocalSound(SOUNDS.Footstep, 0.4, fakeHrp)
                    lastFootstep = tick()
                end
            else
                fakeHumanoid:Move(Vector3.zero, false)
            end

            -- Apply Jump & Jump Sound
            local isJumping = UserInputService:IsKeyDown(Enum.KeyCode.Space) or (myHum and myHum.Jump)
            if isJumping and not wasJumping and fakeHumanoid.FloorMaterial ~= Enum.Material.Air then
                fakeHumanoid.Jump = true
                playLocalSound(SOUNDS.Jump, 0.6, fakeHrp)
            end
            wasJumping = isJumping
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
        local hum = fakeChar:FindFirstChildOfClass("Humanoid")
        local hrp = fakeChar:FindFirstChild("HumanoidRootPart")
        if hum and hrp then
            playLocalSound(SOUNDS.Oof, 1, hrp)
            for _, descendant in ipairs(fakeChar:GetDescendants()) do
                if descendant:IsA("Motor6D") then
                    descendant:Destroy()
                end
            end
            hum:ChangeState(Enum.HumanoidStateType.Dead)
            hum.Health = 0
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
    if fakeChar then
        fakeChar:Destroy()
        fakeChar = nil
    end

    camera.CameraType = Enum.CameraType.Scriptable
    task.wait(3)

    stopControlSession(true)
end)

closeBtn.MouseButton1Click:Connect(function()
    stopControlSession(true)
    mainGui:Destroy()
    sessionGui:Destroy()
end)
