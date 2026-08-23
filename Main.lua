-- Modern Local Sync & Control Engine (GitHub Safe)
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
local renderConnection = nil
local visConnection = nil
local alignWeld = nil

-- UI Cleanup
if playerGui:FindFirstChild("SyncControlGUI") then playerGui.SyncControlGUI:Destroy() end
if playerGui:FindFirstChild("SyncSessionGUI") then playerGui.SyncSessionGUI:Destroy() end

--------------------------------------------------------------------------------
-- OFFICIAL SOUND ENGINE
--------------------------------------------------------------------------------
local function playOfficialSound(soundPath)
    pcall(function()
        local snd = Instance.new("Sound")
        snd.SoundId = soundPath
        snd.Volume = 0.5
        snd.Parent = SoundService
        snd:Play()
        snd.Ended:Connect(function() snd:Destroy() end)
    end)
end

local SOUNDS = {
    Jump = "rbxasset://sounds/action_jump.mp3",
    Land = "rbxasset://sounds/action_jump_land.mp3",
    Oof = "rbxasset://sounds/uuhhh.mp3"
}

--------------------------------------------------------------------------------
-- GUI CREATION
--------------------------------------------------------------------------------
local mainGui = Instance.new("ScreenGui")
mainGui.Name = "SyncControlGUI"
mainGui.ResetOnSpawn = false
mainGui.DisplayOrder = 999
mainGui.Parent = playerGui

local sessionGui = Instance.new("ScreenGui")
sessionGui.Name = "SyncSessionGUI"
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
-- VISIBILITY & SELECTION LOGIC
--------------------------------------------------------------------------------
local function setCharacterLocalTransparency(character, alpha)
    if not character then return end
    for _, part in ipairs(character:GetDescendants()) do
        if part:IsA("BasePart") or part:IsA("Decal") then
            part.LocalTransparencyModifier = alpha
        end
    end
end

local function cleanPreviousTarget()
    if visConnection then visConnection:Disconnect() visConnection = nil end
    if targetPlayer and targetPlayer.Character then
        setCharacterLocalTransparency(targetPlayer.Character, 0)
    end
    if localPlayer.Character then
        setCharacterLocalTransparency(localPlayer.Character, 0)
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

--------------------------------------------------------------------------------
-- REAL CHARACTER MOVEMENT & ANIMATION SYNC
--------------------------------------------------------------------------------
local function stopControlSession(destroySession)
    controlling = false
    if renderConnection then renderConnection:Disconnect() renderConnection = nil end

    if destroySession then cleanPreviousTarget() end

    if localPlayer.Character then
        setCharacterLocalTransparency(localPlayer.Character, 0)
        local hum = localPlayer.Character:FindFirstChildOfClass("Humanoid")
        if hum then
            camera.CameraType = Enum.CameraType.Custom
            camera.CameraSubject = hum
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
    local myHum = myChar and myChar:FindFirstChildOfClass("Humanoid")
    if not myHrp or not myHum then return end

    controlling = true

    -- Enforce local screen transparency
    if visConnection then visConnection:Disconnect() end
    visConnection = RunService.RenderStepped:Connect(function()
        if targetPlayer and targetPlayer.Character then
            setCharacterLocalTransparency(targetPlayer.Character, 1)
        end
        if localPlayer.Character then
            setCharacterLocalTransparency(localPlayer.Character, 1)
        end
    end)

    local targetHum = targetPlayer.Character:FindFirstChildOfClass("Humanoid")
    if targetHum then
        camera.CameraType = Enum.CameraType.Custom
        camera.CameraSubject = targetHum
    end

    -- Real-time position & native animation synchronization loop
    renderConnection = RunService.RenderStepped:Connect(function()
        if not controlling or not targetPlayer or not targetPlayer.Character then return end
        
        local targetHrp = targetPlayer.Character:FindFirstChild("HumanoidRootPart")
        if targetHrp and myHrp then
            myHrp.CFrame = targetHrp.CFrame
        end
    end)

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

-- Robust Reset Action
resetBtn.MouseButton1Click:Connect(function()
    playOfficialSound(SOUNDS.Oof)
    if localPlayer.Character then
        local myChar = localPlayer.Character
        local hum = myChar:FindFirstChildOfClass("Humanoid")
        
        -- Break joints and zero health to force immediate respawn
        myChar:BreakJoints()
        if hum then
            hum.Health = 0
        end
    end
    stopControlSession(true)
end)

leaveBtn.MouseButton1Click:Connect(function()
    camera.CameraType = Enum.CameraType.Scriptable
    task.wait(2)
    stopControlSession(true)
end)

closeBtn.MouseButton1Click:Connect(function()
    stopControlSession(true)
    mainGui:Destroy()
    sessionGui:Destroy()
end)
