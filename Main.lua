local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local localPlayer = Players.LocalPlayer
local camera = Workspace.CurrentCamera
local playerGui = localPlayer:WaitForChild("PlayerGui")

if playerGui:FindFirstChild("SimplePlayerControl") then
    playerGui.SimplePlayerControl:Destroy()
end

local sg = Instance.new("ScreenGui")
sg.Name = "SimplePlayerControl"
sg.ResetOnSpawn = false
sg.DisplayOrder = 999
sg.Parent = playerGui

local win = Instance.new("Frame")
win.Name = "MainWindow"
win.Size = UDim2.new(0, 200, 0, 140)
win.Position = UDim2.new(0.05, 0, 0.3, 0)
win.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
win.BorderSizePixel = 1
win.Active = true
win.Draggable = true
win.Parent = sg

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, 0, 0, 25)
title.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
title.Text = "Player Control"
title.TextColor3 = Color3.fromRGB(255, 255, 255)
title.Font = Enum.Font.SourceSansBold
title.TextSize = 14
title.Parent = win

local targetBtn = Instance.new("TextButton")
targetBtn.Size = UDim2.new(0.9, 0, 0, 25)
targetBtn.Position = UDim2.new(0.05, 0, 0.25, 0)
targetBtn.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
targetBtn.Text = "Select Target"
targetBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
targetBtn.Font = Enum.Font.SourceSans
targetBtn.TextSize = 13
targetBtn.Parent = win

local scrollFrame = Instance.new("ScrollingFrame")
scrollFrame.Size = UDim2.new(0.9, 0, 0, 60)
scrollFrame.Position = UDim2.new(0.05, 0, 0.48, 0)
scrollFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
scrollFrame.Visible = false
scrollFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
scrollFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y
scrollFrame.ZIndex = 10
scrollFrame.Parent = win

local listLayout = Instance.new("UIListLayout")
listLayout.Parent = scrollFrame

local toggleBtn = Instance.new("TextButton")
toggleBtn.Size = UDim2.new(0.9, 0, 0, 25)
toggleBtn.Position = UDim2.new(0.05, 0, 0.75, 0)
toggleBtn.BackgroundColor3 = Color3.fromRGB(46, 204, 113)
toggleBtn.Text = "Start Control"
toggleBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
toggleBtn.Font = Enum.Font.SourceSansBold
toggleBtn.TextSize = 13
toggleBtn.Parent = win

local selectedPlr = nil
local controlling = false
local fakeChar = nil
local origCFrame = nil
local renderConn = nil

local function updatePlayerList()
    for _, child in ipairs(scrollFrame:GetChildren()) do
        if child:IsA("TextButton") then child:Destroy() end
    end
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= localPlayer then
            local b = Instance.new("TextButton")
            b.Size = UDim2.new(1, 0, 0, 20)
            b.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
            b.Text = p.Name
            b.TextColor3 = Color3.fromRGB(255, 255, 255)
            b.Font = Enum.Font.SourceSans
            b.TextSize = 12
            b.ZIndex = 11
            b.Parent = scrollFrame

            b.MouseButton1Click:Connect(function()
                selectedPlr = p
                targetBtn.Text = p.Name
                scrollFrame.Visible = false
            end)
        end
    end
end

targetBtn.MouseButton1Click:Connect(function()
    updatePlayerList()
    scrollFrame.Visible = not scrollFrame.Visible
end)

toggleBtn.MouseButton1Click:Connect(function()
    if controlling then
        controlling = false
        if renderConn then renderConn:Disconnect() renderConn = nil end
        if fakeChar then fakeChar:Destroy() fakeChar = nil end

        local myHrp = localPlayer.Character and localPlayer.Character:FindFirstChild("HumanoidRootPart")
        local myHum = localPlayer.Character and localPlayer.Character:FindFirstChildOfClass("Humanoid")
        
        if myHrp then
            myHrp.Anchored = false
            if origCFrame then myHrp.CFrame = origCFrame end
        end
        if myHum then
            camera.CameraType = Enum.CameraType.Custom
            camera.CameraSubject = myHum
        end

        toggleBtn.Text = "Start Control"
        toggleBtn.BackgroundColor3 = Color3.fromRGB(46, 204, 113)
    else
        if not selectedPlr or not selectedPlr.Character then return end
        local myHrp = localPlayer.Character and localPlayer.Character:FindFirstChild("HumanoidRootPart")
        if not myHrp then return end

        controlling = true
        origCFrame = myHrp.CFrame
        myHrp.Anchored = true

        selectedPlr.Character.Archivable = true
        fakeChar = selectedPlr.Character:Clone()
        selectedPlr.Character.Archivable = false
        fakeChar.Parent = Workspace

        for _, part in ipairs(fakeChar:GetDescendants()) do
            if part:IsA("BasePart") then
                part.Anchored = false
                part.CanCollide = true
            end
        end

        local fakeHrp = fakeChar:FindFirstChild("HumanoidRootPart")
        local fakeHum = fakeChar:FindFirstChildOfClass("Humanoid")

        if fakeHrp and fakeHum then
            camera.CameraType = Enum.CameraType.Custom
            camera.CameraSubject = fakeHum

            renderConn = RunService.RenderStepped:Connect(function(dt)
                if not controlling or not fakeHrp then return end

                local camCFrame = camera.CFrame
                local moveDir = Vector3.zero

                if UserInputService:IsKeyDown(Enum.KeyCode.W) then moveDir = moveDir + Vector3.new(camCFrame.LookVector.X, 0, camCFrame.LookVector.Z).Unit end
                if UserInputService:IsKeyDown(Enum.KeyCode.S) then moveDir = moveDir - Vector3.new(camCFrame.LookVector.X, 0, camCFrame.LookVector.Z).Unit end
                if UserInputService:IsKeyDown(Enum.KeyCode.D) then moveDir = moveDir + Vector3.new(camCFrame.RightVector.X, 0, camCFrame.RightVector.Z).Unit end
                if UserInputService:IsKeyDown(Enum.KeyCode.A) then moveDir = moveDir - Vector3.new(camCFrame.RightVector.X, 0, camCFrame.RightVector.Z).Unit end

                if moveDir.Magnitude > 0 then
                    fakeHrp.CFrame = CFrame.new(fakeHrp.Position, fakeHrp.Position + moveDir.Unit) + (moveDir.Unit * 16 * dt)
                end
            end)
        end

        toggleBtn.Text = "Stop Control"
        toggleBtn.BackgroundColor3 = Color3.fromRGB(231, 76, 60)
    end
end)
