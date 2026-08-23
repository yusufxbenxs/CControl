-- Cross-Platform Player Control Script (Client-Side Visual Simulation)
local getService = function(service)
    return (cloneref and cloneref(game:GetService(service))) or game:GetService(service)
end

local Players = getService("Players")
local Workspace = getService("Workspace")
local UserInputService = getService("UserInputService")
local RunService = getService("RunService")
local CoreGui = getService("CoreGui")

local localPlayer = Players.LocalPlayer
local camera = Workspace.CurrentCamera

-- Global States
local controlling = false
local targetPlayer = nil
local fakeChar = nil
local originalCFrame = nil
local renderConnection = nil

-- Clean up existing UIs
local guiParent = (gethui and gethui()) or CoreGui or localPlayer:WaitForChild("PlayerGui")
if guiParent:FindFirstChild("ControlMainGUI") then guiParent.ControlMainGUI:Destroy() end
if guiParent:FindFirstChild("ControlSessionGUI") then guiParent.ControlSessionGUI:Destroy() end

--------------------------------------------------------------------------------
-- UI CREATION
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

-- Main Selection Window
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

-- Close Button (X)
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

-- Dropdown Button
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

-- Control Start Button
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

-- Session Window (Left-Middle Alignment)
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
-- DROPDOWN MANAGEMENT
--------------------------------------------------------------------------------
local selectedPlr = nil

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
                selectedPlr = plr
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

--------------------------------------------------------------------------------
-- CONTROL ENGINE
--------------------------------------------------------------------------------
local function stopControlSession()
    controlling = false
    if renderConnection then renderConnection:Disconnect() renderConnection = nil end

    if fakeChar then
        fakeChar:Destroy()
        fakeChar = nil
    end

    if targetPlayer and targetPlayer.Character then
        for _, part in ipairs(targetPlayer.Character:GetDescendants()) do
            if part:IsA("BasePart") or part:IsA("Decal") then
                part.LocalTransparencyModifier = 0
            end
        end
    end

    if localPlayer.Character and localPlayer.Character:FindFirstChild("HumanoidRootPart") then
        localPlayer.Character.HumanoidRootPart.Anchored = false
        if originalCFrame then
            localPlayer.Character.HumanoidRootPart.CFrame = originalCFrame
        end
        if localPlayer.Character:FindFirstChildOfClass("Humanoid") then
            camera.CameraSubject = localPlayer.Character:FindFirstChildOfClass("Humanoid")
        end
    end

    targetPlayer = nil
    sessionGui.Enabled = false
    mainGui.Enabled = true
end

local function startControlSession()
    if not selectedPlr or not selectedPlr.Character then return end
    local realChar = selectedPlr.Character
    local realHrp = realChar:FindFirstChild("HumanoidRootPart")
    local myChar = localPlayer.Character
    local myHrp = myChar and myChar:FindFirstChild("HumanoidRootPart")

    if not realHrp or not myHrp then return end

    controlling = true
    targetPlayer = selectedPlr
    originalCFrame = myHrp.CFrame

    -- Anchor local real player to keep position on server
    myHrp.Anchored = true

    -- Hide real player target locally
    for _, part in ipairs(realChar:GetDescendants()) do
        if part:IsA("BasePart") or part:IsA("Decal") then
            part.LocalTransparencyModifier = 1
        end
    end

    -- Clone model
    realChar.Archivable = true
    fakeChar = realChar:Clone()
    realChar.Archivable = false
    fakeChar.Name = realChar.Name .. "_Controlled"
    fakeChar.Parent = Workspace

    -- Ensure all parts are unanchored so physics work
    for _, part in ipairs(fakeChar:GetDescendants()) do
        if part:IsA("BasePart") then
            part.Anchored = false
            part.CanCollide = true
        end
    end

    local fakeHumanoid = fakeChar:FindFirstChildOfClass("Humanoid")
    local fakeHrp = fakeChar:FindFirstChild("HumanoidRootPart")

    if fakeHumanoid and fakeHrp then
        -- Refresh Humanoid Animator & Animate Script
        local animator = fakeHumanoid:FindFirstChildOfClass("Animator") or Instance.new("Animator", fakeHumanoid)
        local animateScript = fakeChar:FindFirstChild("Animate")
        if animateScript then
            animateScript.Disabled = true
            task.wait()
            animateScript.Disabled = false
        end

        camera.CameraType = Enum.CameraType.Custom
        camera.CameraSubject = fakeHumanoid

        local speed = 16
        local jumpPower = 50

        renderConnection = RunService.RenderStepped:Connect(function(dt)
            if not controlling or not fakeHumanoid or not fakeHrp then return end

            local moveVector = Vector3.zero
            local camCFrame = camera.CFrame
            local forward = Vector3.new(camCFrame.LookVector.X, 0, camCFrame.LookVector.Z).Unit
            local right = Vector3.new(camCFrame.RightVector.X, 0, camCFrame.RightVector.Z).Unit

            -- Keyboard inputs
            if UserInputService:IsKeyDown(Enum.KeyCode.W) then moveVector = moveVector + forward end
            if UserInputService:IsKeyDown(Enum.KeyCode.S) then moveVector = moveVector - forward end
            if UserInputService:IsKeyDown(Enum.KeyCode.D) then moveVector = moveVector + right end
            if UserInputService:IsKeyDown(Enum.KeyCode.A) then moveVector = moveVector - right end

            -- Mobile Touch joystick input
            local myHum = localPlayer.Character and localPlayer.Character:FindFirstChildOfClass("Humanoid")
            if myHum and myHum.MoveDirection.Magnitude > 0 then
                moveVector = myHum.MoveDirection
            end

            -- Apply Movement
            if moveVector.Magnitude > 0 then
                moveVector = moveVector.Unit
                fakeHrp.CFrame = CFrame.new(fakeHrp.Position, fakeHrp.Position + moveVector)
                fakeHrp.AssemblyLinearVelocity = Vector3.new(moveVector.X * speed, fakeHrp.AssemblyLinearVelocity.Y, moveVector.Z * speed)
                fakeHumanoid:ChangeState(Enum.HumanoidStateType.Running)
            else
                fakeHrp.AssemblyLinearVelocity = Vector3.new(0, fakeHrp.AssemblyLinearVelocity.Y, 0)
            end

            -- Apply Jump
            local isJumping = UserInputService:IsKeyDown(Enum.KeyCode.Space) or (myHum and myHum.Jump)
            if isJumping and (fakeHumanoid:GetState() == Enum.HumanoidStateType.Running or fakeHumanoid:GetState() == Enum.HumanoidStateType.Landed or fakeHumanoid.FloorMaterial ~= Enum.Material.Air) then
                fakeHrp.AssemblyLinearVelocity = Vector3.new(fakeHrp.AssemblyLinearVelocity.X, jumpPower, fakeHrp.AssemblyLinearVelocity.Z)
                fakeHumanoid:ChangeState(Enum.HumanoidStateType.Jumping)
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
stopBtn.MouseButton1Click:Connect(stopControlSession)

resetBtn.MouseButton1Click:Connect(function()
    if fakeChar then
        local hum = fakeChar:FindFirstChildOfClass("Humanoid")
        if hum then
            -- Break all Motor6D joints so parts collapse and scatter (classic Roblox break-apart death)
            for _, descendant in ipairs(fakeChar:GetDescendants()) do
                if descendant:IsA("Motor6D") then
                    descendant:Destroy()
                end
            end

            -- Trigger Roblox default death state
            hum:ChangeState(Enum.HumanoidStateType.Dead)
            hum.Health = 0
        end

        task.wait(1.5)
        stopControlSession()
    end
end)

leaveBtn.MouseButton1Click:Connect(function()
    if fakeChar then
        fakeChar:Destroy()
        fakeChar = nil
    end
    task.wait(0.5)
    stopControlSession()
end)

closeBtn.MouseButton1Click:Connect(function()
    stopControlSession()
    mainGui:Destroy()
    sessionGui:Destroy()
end)
