-- RITUAL HUB - Simplified Mobile Button Fix
-- Black & Gold, Vertical, Clean
-- Author: Ritualz999

local Players = game:GetService("Players")
local Player = Players.LocalPlayer
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local screenSize = workspace.CurrentCamera.ViewportSize

-- ===== CREATE GUI =====
local gui = Instance.new("ScreenGui")
gui.Name = "RitualHub"
gui.ResetOnSpawn = false
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.DisplayOrder = 999  -- Ensure it's on top
gui.Parent = Player:WaitForChild("PlayerGui")

-- ===== R BUTTON (TextButton - handles both tap and drag) =====
local rButton = Instance.new("TextButton")
rButton.Size = UDim2.new(0, 80, 0, 80)          -- Big enough for mobile
rButton.Position = UDim2.new(0.02, 0, 0.02, 0)
rButton.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
rButton.BackgroundTransparency = 0              -- Fully opaque
rButton.BorderSizePixel = 4
rButton.BorderColor3 = Color3.fromRGB(255, 215, 0) -- Gold
rButton.Text = "R"
rButton.TextColor3 = Color3.fromRGB(255, 215, 0)
rButton.TextScaled = true
rButton.Font = Enum.Font.GothamBold
rButton.TextSize = 40
rButton.AutoButtonColor = false                 -- Prevent auto darkening
rButton.ClipsDescendants = true
rButton.ZIndex = 999
rButton.Parent = gui

-- Round corners
local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(1, 0)
corner.Parent = rButton

-- ===== MAIN FRAME (Vertical, Sacred style) =====
local mainFrame = Instance.new("Frame")
mainFrame.Size = UDim2.new(0, 280, 0, 380)
mainFrame.Position = UDim2.new(0.5, -140, 0.5, -190)
mainFrame.BackgroundColor3 = Color3.fromRGB(10, 10, 15)
mainFrame.BackgroundTransparency = 0.15
mainFrame.BorderSizePixel = 3
mainFrame.BorderColor3 = Color3.fromRGB(255, 215, 0)
mainFrame.ClipsDescendants = true
mainFrame.Visible = false
mainFrame.ZIndex = 100
mainFrame.Parent = gui

local mainCorner = Instance.new("UICorner")
mainCorner.CornerRadius = UDim.new(0, 16)
mainCorner.Parent = mainFrame

-- Inner gold border
local innerBorder = Instance.new("Frame")
innerBorder.Size = UDim2.new(0.97, 0, 0.97, 0)
innerBorder.Position = UDim2.new(0.015, 0, 0.015, 0)
innerBorder.BackgroundColor3 = Color3.fromRGB(10, 10, 15)
innerBorder.BackgroundTransparency = 0.3
innerBorder.BorderSizePixel = 2
innerBorder.BorderColor3 = Color3.fromRGB(255, 215, 0)
innerBorder.ClipsDescendants = true
innerBorder.Parent = mainFrame

local innerCorner = Instance.new("UICorner")
innerCorner.CornerRadius = UDim.new(0, 12)
innerCorner.Parent = innerBorder

-- Header
local header = Instance.new("TextLabel")
header.Size = UDim2.new(1, 0, 0, 60)
header.BackgroundTransparency = 1
header.Text = "RITUAL HUB"
header.TextColor3 = Color3.fromRGB(255, 215, 0)
header.TextScaled = true
header.Font = Enum.Font.GothamBold
header.TextSize = 28
header.TextXAlignment = Enum.TextXAlignment.Center
header.TextYAlignment = Enum.TextYAlignment.Center
header.Parent = innerBorder

-- Subtitle
local subtitle = Instance.new("TextLabel")
subtitle.Size = UDim2.new(1, 0, 0, 30)
subtitle.Position = UDim2.new(0, 0, 0, 60)
subtitle.BackgroundTransparency = 1
subtitle.Text = "by Ritualz999"
subtitle.TextColor3 = Color3.fromRGB(180, 180, 200)
subtitle.TextScaled = true
subtitle.Font = Enum.Font.Gotham
subtitle.TextSize = 14
subtitle.TextXAlignment = Enum.TextXAlignment.Center
subtitle.TextYAlignment = Enum.TextYAlignment.Top
subtitle.Parent = innerBorder

-- Divider
local divider = Instance.new("Frame")
divider.Size = UDim2.new(0.9, 0, 0, 2)
divider.Position = UDim2.new(0.05, 0, 0, 92)
divider.BackgroundColor3 = Color3.fromRGB(255, 215, 0)
divider.BackgroundTransparency = 0.5
divider.BorderSizePixel = 0
divider.Parent = innerBorder

-- Empty content area
local emptyArea = Instance.new("Frame")
emptyArea.Size = UDim2.new(0.9, 0, 0.6, 0)
emptyArea.Position = UDim2.new(0.05, 0, 0.25, 0)
emptyArea.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
emptyArea.BackgroundTransparency = 0.2
emptyArea.BorderSizePixel = 2
emptyArea.BorderColor3 = Color3.fromRGB(255, 215, 0)
emptyArea.ClipsDescendants = true
emptyArea.Parent = innerBorder

local emptyCorner = Instance.new("UICorner")
emptyCorner.CornerRadius = UDim.new(0, 8)
emptyCorner.Parent = emptyArea

-- Bottom bar
local bottomBar = Instance.new("Frame")
bottomBar.Size = UDim2.new(0.9, 0, 0, 40)
bottomBar.Position = UDim2.new(0.05, 0, 0.87, 0)
bottomBar.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
bottomBar.BackgroundTransparency = 0.4
bottomBar.BorderSizePixel = 2
bottomBar.BorderColor3 = Color3.fromRGB(255, 215, 0)
bottomBar.Parent = innerBorder

local bottomCorner = Instance.new("UICorner")
bottomCorner.CornerRadius = UDim.new(0, 6)
bottomCorner.Parent = bottomBar

local f512 = Instance.new("TextLabel")
f512.Size = UDim2.new(0.25, 0, 1, 0)
f512.Position = UDim2.new(0.03, 0, 0, 0)
f512.BackgroundTransparency = 1
f512.Text = "f512"
f512.TextColor3 = Color3.fromRGB(180, 180, 200)
f512.TextScaled = true
f512.Font = Enum.Font.Gotham
f512.TextXAlignment = Enum.TextXAlignment.Left
f512.TextYAlignment = Enum.TextYAlignment.Center
f512.Parent = bottomBar

local cash = Instance.new("TextLabel")
cash.Size = UDim2.new(0.35, 0, 1, 0)
cash.Position = UDim2.new(0.33, 0, 0, 0)
cash.BackgroundTransparency = 1
cash.Text = "$4,973,310"
cash.TextColor3 = Color3.fromRGB(255, 215, 0)
cash.TextScaled = true
cash.Font = Enum.Font.GothamBold
cash.TextXAlignment = Enum.TextXAlignment.Center
cash.TextYAlignment = Enum.TextYAlignment.Center
cash.Parent = bottomBar

local version = Instance.new("TextLabel")
version.Size = UDim2.new(0.35, 0, 1, 0)
version.Position = UDim2.new(0.62, 0, 0, 0)
version.BackgroundTransparency = 1
version.Text = "v31.4.0-Sea3:3249/131"
version.TextColor3 = Color3.fromRGB(180, 180, 200)
version.TextScaled = true
version.Font = Enum.Font.Gotham
version.TextSize = 9
version.TextXAlignment = Enum.TextXAlignment.Right
version.TextYAlignment = Enum.TextYAlignment.Center
version.Parent = bottomBar

-- ===== TOGGLE & DRAG LOGIC =====
local isVisible = false
local isDragging = false
local dragStart = nil
local buttonStartPos = nil
local dragThreshold = 15

local function toggleGUI()
    isVisible = not isVisible
    mainFrame.Visible = isVisible
    if isVisible then
        rButton.BorderColor3 = Color3.fromRGB(255, 230, 100)
        rButton.BorderSizePixel = 5
        rButton.TextColor3 = Color3.fromRGB(255, 230, 100)
    else
        rButton.BorderColor3 = Color3.fromRGB(255, 215, 0)
        rButton.BorderSizePixel = 4
        rButton.TextColor3 = Color3.fromRGB(255, 215, 0)
    end
end

-- Button input handling
rButton.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.Touch or 
       input.UserInputType == Enum.UserInputType.MouseButton1 then
        isDragging = false
        dragStart = input.Position
        buttonStartPos = rButton.Position
        -- Visual feedback
        rButton.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
        rButton.BorderSizePixel = 5
    end
end)

rButton.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.Touch or 
       input.UserInputType == Enum.UserInputType.MouseMovement then
        if dragStart and buttonStartPos then
            local delta = input.Position - dragStart
            if delta.Magnitude > dragThreshold then
                isDragging = true
                local newX = buttonStartPos.X.Scale + (delta.X / screenSize.X)
                local newY = buttonStartPos.Y.Scale + (delta.Y / screenSize.Y)
                newX = math.clamp(newX, 0, 1 - (rButton.Size.X.Offset / screenSize.X))
                newY = math.clamp(newY, 0, 1 - (rButton.Size.Y.Offset / screenSize.Y))
                rButton.Position = UDim2.new(newX, 0, newY, 0)
            end
        end
    end
end)

rButton.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.Touch or 
       input.UserInputType == Enum.UserInputType.MouseButton1 then
        -- Reset visual
        rButton.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
        if not isVisible then
            rButton.BorderSizePixel = 4
        end
        -- If not a drag, toggle
        if not isDragging then
            toggleGUI()
        end
        -- Reset state
        isDragging = false
        dragStart = nil
        buttonStartPos = nil
    end
end)

-- Fallback touch events (some devices)
rButton.TouchTap:Connect(function()
    if not isDragging then
        toggleGUI()
    end
end)

rButton.MouseButton1Click:Connect(function()
    if not isDragging then
        toggleGUI()
    end
end)

-- ===== ENSURE BUTTON IS INTERACTABLE =====
-- Keep it on top and visible
RunService.Heartbeat:Connect(function()
    rButton.Visible = true
    rButton.ZIndex = 999
end)

print("✅ RITUAL HUB LOADED - Mobile Button Fixed")
print("📱 Tap the gold 'R' button to toggle GUI")
print("🔄 Drag the gold 'R' button to reposition")
