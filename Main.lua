-- Minimalist, Fail-Proof UI Test & Control Engine
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local localPlayer = Players.LocalPlayer
local camera = Workspace.CurrentCamera

print("[ExecTest] Starting Script...")

-- Direct GUI Parent Assignment with Fallback
local guiParent
local success, _ = pcall(function()
    guiParent = game:GetService("CoreGui")
end)

if not success or not guiParent then
    guiParent = localPlayer:WaitForChild("PlayerGui")
end

print("[ExecTest] Mounting UI to: " .. guiParent.Name)

-- Destroy Old GUI
if guiParent:FindFirstChild("DirectControlGUI") then
    guiParent.DirectControlGUI:Destroy()
end

-- Create ScreenGui
local mainGui = Instance.new("ScreenGui")
mainGui.Name = "DirectControlGUI"
mainGui.ResetOnSpawn = false
mainGui.DisplayOrder = 999999
mainGui.Parent = guiParent

-- Control Window Frame
local frame = Instance.new("Frame")
frame.Size = UDim2.new(0, 220, 0, 150)
frame.Position = UDim2.new(0.05, 0, 0.2, 0)
frame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
frame.BorderSizePixel = 2
frame.BorderColor3 = Color3.fromRGB(0, 255, 100)
frame.Active = true
frame.Draggable = true
frame.Parent = mainGui

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, 0, 0, 25)
title.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
title.Text = "Exec Control (Active)"
title.TextColor3 = Color3.fromRGB(0, 255, 100)
title.Font = Enum.Font.SourceSansBold
title.TextSize = 14
title.Parent = frame

local dropBtn = Instance.new("TextButton")
dropBtn.Size = UDim2.new(0.9, 0, 0, 25)
dropBtn.Position = UDim2.new(0.05, 0, 0.25, 0)
dropBtn.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
dropBtn.Text = "Select Target"
dropBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
dropBtn.Font = Enum.Font.SourceSans
dropBtn.TextSize = 13
dropBtn.Parent = frame

local dropFrame = Instance.new("ScrollingFrame")
dropFrame.Size = UDim2.new(0.9, 0, 0, 70)
dropFrame.Position = UDim2.new(0.05, 0, 0.45, 0)
dropFrame.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
dropFrame.Visible = false
dropFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
dropFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y
dropFrame.ZIndex = 5
dropFrame.Parent = frame

local layout = Instance.new("UIListLayout")
layout.Parent = dropFrame

local actionBtn = Instance.new("TextButton")
actionBtn.Size = UDim2.new(0.9, 0, 0, 25)
actionBtn.Position = UDim2.new(0.05, 0, 0.75, 0)
actionBtn.BackgroundColor3 = Color3.fromRGB(46, 204, 113)
actionBtn.Text = "Start Control"
actionBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
actionBtn.Font = Enum.Font.SourceSansBold
actionBtn.TextSize = 13
actionBtn.Parent = frame

print("[ExecTest] UI Elements Loaded Successfully!")

--------------------------------------------------------------------------------
-- SCRIPT LOGIC
--------------------------------------------------------------------------------
local selectedPlr = nil
local controlling = false
local fakeChar = nil
local origCFrame = nil
local renderConn = nil

local function populateList()
    for _, child in ipairs(dropFrame:GetChildren()) do
        if child:IsA("TextButton") then child:Destroy() end
    end
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= localPlayer then
            local b = Instance.new("TextButton")
            b.Size = UDim2.new(1, 0, 0, 20)
            b.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
            b.Text = p.Name
            b.TextColor3 = Color3.fromRGB(255, 255, 255)
            b.Font = Enum.Font.SourceSans
            b.TextSize = 12
            b.ZIndex = 6
            b.Parent = dropFrame

            b.MouseButton1Click:Connect(function()
                selectedPlr = p
                dropBtn.Text = "Target: " .. p.Name
                dropFrame.Visible = false
            end)
        end
    end
end

dropBtn.MouseButton1Click:Connect(function()
    populateList()
    dropFrame.Visible = not dropFrame.Visible
end)

actionBtn.MouseButton1Click:Connect(function()
    if controlling then
        -- STOP CONTROL
        controlling = false
        if renderConn then renderConn:Disconnect() end
        if fakeChar then fakeChar:Destroy() fakeChar = nil end

        if localPlayer.Character and localPlayer.Character:FindFirstChild("HumanoidRootPart") then
            localPlayer.Character.HumanoidRootPart.Anchored = false
            if origCFrame then localPlayer.Character.HumanoidRootPart.CFrame = origCFrame end
            camera.CameraType = Enum.CameraType.Custom
            camera.CameraSubject = localPlayer.Character:FindFirstChildOfClass("Humanoid")
        end

        actionBtn.Text = "Start Control"
        actionBtn.BackgroundColor3 = Color3.fromRGB(46, 204, 113)
    else
        -- START CONTROL
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

        for _, v in ipairs(fakeChar:GetDescendants()) do
            if v:IsA("BasePart") then
                v.Anchored = false
                v.CanCollide = true
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

        actionBtn.Text = "Stop Control"
        actionBtn.BackgroundColor3 = Color3.fromRGB(231, 76, 60)
    end
end)
