-- Local Simulation Control Script (Visual Only)
local getService = function(service)
    return (cloneref and cloneref(game:GetService(service))) or game:GetService(service)
end

local Players = getService("Players")
local Workspace = getService("Workspace")
local UserInputService = getService("UserInputService")
local RunService = getService("RunService")
local SoundService = getService("SoundService")
local CoreGui = getService("CoreGui")

local localPlayer = Players.LocalPlayer
local camera = Workspace.CurrentCamera

-- Global States
local controlling = false
local targetPlayer = nil
local fakeChar = nil
local originalCFrame = nil
local moveConnection = nil
local renderConnection = nil

-- Clean up existing UIs
local guiParent = (gethui and gethui()) or CoreGui or localPlayer:WaitForChild("PlayerGui")
if guiParent:FindFirstChild("FakeControlMainGUI") then guiParent.FakeControlMainGUI:Destroy() end
if guiParent:FindFirstChild("FakeControlSessionGUI") then guiParent.FakeControlSessionGUI:Destroy() end

--------------------------------------------------------------------------------
-- UI CREATION HELPERS
--------------------------------------------------------------------------------
local mainGui = Instance.new("ScreenGui")
mainGui.Name = "FakeControlMainGUI"
mainGui.ResetOnSpawn = false
mainGui.Parent = guiParent

local sessionGui = Instance.new("ScreenGui")
sessionGui.Name = "FakeControlSessionGUI"
sessionGui.ResetOnSpawn = false
sessionGui.Enabled = false
sessionGui.Parent = guiParent

-- Main Selection Window
local mainFrame = Instance.new("Frame")
mainFrame.Size = UDim2.new(0, 220, 0, 130)
mainFrame.Position = UDim2.new(0.05, 0, 0.3, 0)
mainFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
mainFrame.BorderSizePixel = 0
mainFrame.Active = true
mainFrame.Parent = mainGui

local mainCorner = Instance.new("UICorner")
mainCorner.CornerRadius = UDim.new(0, 8)
mainCorner.Parent = mainFrame

local titleLabel = Instance.new("TextLabel")
titleLabel.Size = UDim2.new(1, 0, 0, 30)
titleLabel.BackgroundTransparency = 1
titleLabel.Text = "Player Control (Visual Only)"
titleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
titleLabel.Font = Enum.Font.SourceSansBold
titleLabel.TextSize = 14
titleLabel.Parent = mainFrame

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

-- Session Bar Window (Left-Middle Alignment)
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
resetBtn.Text = "Fake Reset"
resetBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
resetBtn.Font = Enum.Font.SourceSansBold
resetBtn.TextSize = 12
resetBtn.Parent = sessionFrame

local leaveBtn = Instance.new("TextButton")
leaveBtn.Size = UDim2.new(0, 120, 0, 28)
leaveBtn.BackgroundColor3 = Color3.fromRGB(142, 68, 173)
leaveBtn.Text = "Fake Leave"
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
-- CONTROL & SIMULATION ENGINE
--------------------------------------------------------------------------------
local function stopControlSession()
    controlling = false
    if renderConnection then renderConnection:Disconnect() renderConnection = nil end

    -- Destroy visual character clone
    if fakeChar then
        fakeChar:Destroy()
        fakeChar = nil
    end

    -- Restore Target Real Character Visually
    if targetPlayer and targetPlayer.Character then
        for _, part in ipairs(targetPlayer.Character:GetDescendants()) do
            if part:IsA("BasePart") or part:IsA("Decal") then
                part.LocalTransparencyModifier = 0
            end
        end
    end

    -- Unanchor Local Character & Reset Camera
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

    -- Anchor Real Client-side Character on Server Position
    myHrp.Anchored = true

    -- Hide target player's original model locally so it doesn't duplicate visually
    for _, part in ipairs(realChar:GetDescendants()) do
        if part:IsA("BasePart") or part:IsA("Decal") then
            part.LocalTransparencyModifier = 1
        end
    end

    -- Create local clone of target player for client manipulation
    realChar.Archivable = true
    fakeChar = realChar:Clone()
    realChar.Archivable = false
    fakeChar.Parent = Workspace

    local fakeHumanoid = fakeChar:FindFirstChildOfClass("Humanoid")
    local fakeHrp = fakeChar:FindFirstChild("HumanoidRootPart")

    -- Setup animations and camera
    if fakeHumanoid and fakeHrp then
        camera.CameraType = Enum.CameraType.Custom
        camera.CameraSubject = fakeHumanoid

        -- Client-side Animation and Input Handling Loop
        renderConnection = RunService.RenderStepped:Connect(function()
            if not controlling or not fakeHumanoid or not fakeHrp then return end

            local moveVector = Vector3.zero
            local camCFrame = camera.CFrame
            local forward = Vector3.new(camCFrame.LookVector.X, 0, camCFrame.LookVector.Z).Unit
            local right = Vector3.new(camCFrame.RightVector.X, 0, camCFrame.RightVector.Z).Unit

            if UserInputService:IsKeyDown(Enum.KeyCode.W) then moveVector = moveVector + forward end
            if UserInputService:IsKeyDown(Enum.KeyCode.S) then moveVector = moveVector - forward end
            if UserInputService:IsKeyDown(Enum.KeyCode.D) then moveVector = moveVector + right end
            if UserInputService:IsKeyDown(Enum.KeyCode.A) then moveVector = moveVector - right end

            if moveVector.Magnitude > 0 then
                moveVector = moveVector.Unit
                fakeHumanoid:Move(moveVector, false)
            end

            if UserInputService:IsKeyDown(Enum.KeyCode.Space) then
                fakeHumanoid.Jump = true
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
    if fakeChar and fakeChar:FindFirstChildOfClass("Humanoid") then
        local hum = fakeChar:FindFirstChildOfClass("Humanoid")
        hum:TakeDamage(100) -- Visual local break/reset
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
