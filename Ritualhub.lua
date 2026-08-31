-- RITUAL HUB - Sacred Style, Vertical, No Bottom Bar
-- Draggable by top header, R button toggles visibility
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
gui.DisplayOrder = 999
gui.Parent = Player:WaitForChild("PlayerGui")

-- ===== R BUTTON (TextButton - tap to toggle, drag to reposition) =====
local rButton = Instance.new("TextButton")
rButton.Size = UDim2.new(0, 80, 0, 80)
rButton.Position = UDim2.new(0.02, 0, 0.02, 0)
rButton.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
rButton.BackgroundTransparency = 0
rButton.BorderSizePixel = 4
rButton.BorderColor3 = Color3.fromRGB(255, 215, 0)  -- Gold
rButton.Text = "R"
rButton.TextColor3 = Color3.fromRGB(255, 215, 0)
rButton.TextScaled = true
rButton.Font = Enum.Font.GothamBold
rButton.TextSize = 40
rButton.AutoButtonColor = false
rButton.ClipsDescendants = true
rButton.ZIndex = 999
rButton.Parent = gui

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(1, 0)
corner.Parent = rButton

-- ===== MAIN FRAME (Vertical, Sacred style, no bottom bar) =====
local mainFrame = Instance.new("Frame")
mainFrame.Size = UDim2.new(0, 280, 0, 320)  -- Slightly shorter without bottom bar
mainFrame.Position = UDim2.new(0.5, -140, 0.5, -160)
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

-- ===== HEADER (Draggable) =====
local header = Instance.new("Frame")
header.Size = UDim2.new(1, 0, 0, 60)
header.BackgroundColor3 = Color3.fromRGB(10, 10, 15)
header.BackgroundTransparency = 0
header.BorderSizePixel = 0
header.ZIndex = 2
header.Parent = innerBorder

local headerLabel = Instance.new("TextLabel")
headerLabel.Size = UDim2.new(1, 0, 1, 0)
headerLabel.BackgroundTransparency = 1
headerLabel.Text = "RITUAL HUB"
headerLabel.TextColor3 = Color3.fromRGB(255, 215, 0)
headerLabel.TextScaled = true
headerLabel.Font = Enum.Font.GothamBold
headerLabel.TextSize = 28
headerLabel.TextXAlignment = Enum.TextXAlignment.Center
headerLabel.TextYAlignment = Enum.TextYAlignment.Center
headerLabel.Parent = header

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

-- Empty content area (just black space with gold border)
local emptyArea = Instance.new("Frame")
emptyArea.Size = UDim2.new(0.9, 0, 0.65, 0)
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

-- No bottom bar – removed as requested

-- ===== DRAG FUNCTIONALITY FOR HEADER (move the whole GUI) =====
local function makeDraggable(frame)
    local dragging = false
    local dragStart = nil
    local startPos = nil

    frame.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.Touch or 
           input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            dragStart = input.Position
            startPos = mainFrame.Position
        end
    end)

    frame.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.Touch or 
                         input.UserInputType == Enum.UserInputType.MouseMovement) then
            local delta = input.Position - dragStart
            local newX = startPos.X.Scale + (delta.X / screenSize.X)
            local newY = startPos.Y.Scale + (delta.Y / screenSize.Y)
            -- Clamp to screen
            newX = math.clamp(newX, 0, 1 - (mainFrame.Size.X.Offset / screenSize.X))
            newY = math.clamp(newY, 0, 1 - (mainFrame.Size.Y.Offset / screenSize.Y))
            mainFrame.Position = UDim2.new(newX, 0, newY, 0)
        end
    end)

    frame.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.Touch or 
           input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = false
            dragStart = nil
            startPos = nil
        end
    end)
end

makeDraggable(header)  -- Now the header can be dragged to move the GUI

-- ===== TOGGLE & DRAG FOR R BUTTON =====
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
        rButton.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
        if not isVisible then
            rButton.BorderSizePixel = 4
        end
        if not isDragging then
            toggleGUI()
        end
        isDragging = false
        dragStart = nil
        buttonStartPos = nil
    end
end)

-- Fallback events
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

-- ===== ENSURE BUTTON IS ON TOP =====
RunService.Heartbeat:Connect(function()
    rButton.Visible = true
    rButton.ZIndex = 999
end)

print("✅ RITUAL HUB - Vertical, No Bottom Bar, Header Draggable")
print("📱 Tap the gold 'R' button to toggle GUI")
print("🔄 Drag the 'R' button to reposition it")
print("🔄 Drag the header 'RITUAL HUB' to move the whole GUI")
