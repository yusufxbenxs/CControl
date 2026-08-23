local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

-- Main GUI Container
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "SyncControlUI"
screenGui.ResetOnSpawn = false
screenGui.Parent = PlayerGui

-- Main Panel
local mainFrame = Instance.new("Frame")
mainFrame.Name = "MainFrame"
mainFrame.Size = UDim2.new(0, 280, 0, 220)
mainFrame.Position = UDim2.new(0.5, -140, 0.5, -110)
mainFrame.BackgroundColor3 = Color3.fromRGB(35, 35, 45)
mainFrame.BorderSizePixel = 0
mainFrame.Active = true
mainFrame.Draggable = true
mainFrame.Parent = screenGui

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 8)
corner.Parent = mainFrame

-- UI Title
local titleLabel = Instance.new("TextLabel")
titleLabel.Size = UDim2.new(1, 0, 0, 35)
titleLabel.BackgroundTransparency = 1
titleLabel.Text = "Session Sync Controller"
titleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
titleLabel.TextSize = 16
titleLabel.Font = Enum.Font.SourceSansBold
titleLabel.Parent = mainFrame

-- Session ID Input Box
local sessionInput = Instance.new("TextBox")
sessionInput.Name = "SessionInput"
sessionInput.Size = UDim2.new(0.9, 0, 0, 35)
sessionInput.Position = UDim2.new(0.05, 0, 0.2, 0)
sessionInput.BackgroundColor3 = Color3.fromRGB(50, 50, 65)
sessionInput.BorderSizePixel = 0
sessionInput.PlaceholderText = "Enter Session ID..."
sessionInput.Text = ""
sessionInput.TextColor3 = Color3.fromRGB(255, 255, 255)
sessionInput.PlaceholderColor3 = Color3.fromRGB(150, 150, 160)
sessionInput.TextSize = 14
sessionInput.Font = Enum.Font.SourceSans
sessionInput.Parent = mainFrame

local inputCorner = Instance.new("UICorner")
inputCorner.CornerRadius = UDim.new(0, 6)
inputCorner.Parent = sessionInput

-- Opt-In / Allow Sync Toggle Button
local toggleBtn = Instance.new("TextButton")
toggleBtn.Name = "ToggleSyncBtn"
toggleBtn.Size = UDim2.new(0.9, 0, 0, 35)
toggleBtn.Position = UDim2.new(0.05, 0, 0.42, 0)
toggleBtn.BackgroundColor3 = Color3.fromRGB(180, 50, 50) -- Default Red (Off)
toggleBtn.BorderSizePixel = 0
toggleBtn.Text = "Allow Sync: OFF"
toggleBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
toggleBtn.TextSize = 14
toggleBtn.Font = Enum.Font.SourceSansBold
toggleBtn.Parent = mainFrame

local btnCorner = Instance.new("UICorner")
btnCorner.CornerRadius = UDim.new(0, 6)
btnCorner.Parent = toggleBtn

-- Action Button (e.g., Command Walk)
local actionBtn = Instance.new("TextButton")
actionBtn.Name = "ActionBtn"
actionBtn.Size = UDim2.new(0.9, 0, 0, 40)
actionBtn.Position = UDim2.new(0.05, 0, 0.7, 0)
actionBtn.BackgroundColor3 = Color3.fromRGB(60, 120, 210)
actionBtn.BorderSizePixel = 0
actionBtn.Text = "Send Walk Command"
actionBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
actionBtn.TextSize = 15
actionBtn.Font = Enum.Font.SourceSansBold
actionBtn.Parent = mainFrame

local actionCorner = Instance.new("UICorner")
actionCorner.CornerRadius = UDim.new(0, 6)
actionCorner.Parent = actionBtn

----------------------------------------------------
-- UI Interaction Logic
----------------------------------------------------
local isSyncAllowed = false

toggleBtn.MouseButton1Click:Connect(function()
	isSyncAllowed = not isSyncAllowed
	
	if isSyncAllowed then
		toggleBtn.Text = "Allow Sync: ON"
		toggleBtn.BackgroundColor3 = Color3.fromRGB(50, 180, 90) -- Green
	else
		toggleBtn.Text = "Allow Sync: OFF"
		toggleBtn.BackgroundColor3 = Color3.fromRGB(180, 50, 50) -- Red
	end
end)

actionBtn.MouseButton1Click:Connect(function()
	local enteredID = sessionInput.Text
	if enteredID == "" then
		print("Please enter a Session ID first!")
	else
		print("Triggered action for Session ID: " .. enteredID)
	end
end)
