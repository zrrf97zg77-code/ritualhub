-- RITUAL HUB - Mobile Only (Fixed Click & Drag)
-- Black Background with Gold Outlines

local Players = game:GetService("Players")
local Player = Players.LocalPlayer
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")

-- ===== CREATE MAIN GUI =====
local gui = Instance.new("ScreenGui")
gui.Name = "RitualHub"
gui.ResetOnSpawn = false
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.Parent = Player:WaitForChild("PlayerGui")

local screenSize = workspace.CurrentCamera.ViewportSize

-- ===== DRAGGABLE R BUTTON (TextButton for better touch) =====
local rButton = Instance.new("TextButton")
rButton.Name = "RButton"
rButton.Size = UDim2.new(0, 60, 0, 60)
rButton.Position = UDim2.new(0.02, 0, 0.02, 0)
rButton.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
rButton.BackgroundTransparency = 0
rButton.BorderSizePixel = 3
rButton.BorderColor3 = Color3.fromRGB(255, 215, 0) -- Gold
rButton.AutoButtonColor = false  -- Prevent auto color change
rButton.Text = "R"
rButton.TextColor3 = Color3.fromRGB(255, 215, 0)
rButton.TextScaled = true
rButton.Font = Enum.Font.GothamBold
rButton.TextSize = 35
rButton.TextXAlignment = Enum.TextXAlignment.Center
rButton.TextYAlignment = Enum.TextYAlignment.Center
rButton.Visible = true
rButton.ZIndex = 999
rButton.Parent = gui

-- R Button Corner (circle)
local rCorner = Instance.new("UICorner")
rCorner.CornerRadius = UDim.new(1, 0)
rCorner.Parent = rButton

-- Inner gold border (for extra style)
local innerGold = Instance.new("Frame")
innerGold.Size = UDim2.new(0.85, 0, 0.85, 0)
innerGold.Position = UDim2.new(0.075, 0, 0.075, 0)
innerGold.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
innerGold.BorderSizePixel = 2
innerGold.BorderColor3 = Color3.fromRGB(255, 215, 0)
innerGold.BackgroundTransparency = 0
innerGold.ZIndex = 998  -- Behind button
innerGold.Parent = rButton

local innerCorner = Instance.new("UICorner")
innerCorner.CornerRadius = UDim.new(1, 0)
innerCorner.Parent = innerGold

-- Glow effect behind button
local glow = Instance.new("Frame")
glow.Size = UDim2.new(1.4, 0, 1.4, 0)
glow.Position = UDim2.new(-0.2, 0, -0.2, 0)
glow.BackgroundColor3 = Color3.fromRGB(255, 215, 0)
glow.BackgroundTransparency = 0.85
glow.BorderSizePixel = 0
glow.ZIndex = -1
glow.Parent = rButton

local glowCorner = Instance.new("UICorner")
glowCorner.CornerRadius = UDim.new(1, 0)
glowCorner.Parent = glow

-- ===== MAIN GUI FRAME (Small) =====
local mainFrame = Instance.new("Frame")
mainFrame.Name = "MainFrame"
mainFrame.Size = UDim2.new(0, 250, 0, 320)
mainFrame.Position = UDim2.new(0.5, -125, 0.5, -160)
mainFrame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
mainFrame.BackgroundTransparency = 0
mainFrame.BorderSizePixel = 4
mainFrame.BorderColor3 = Color3.fromRGB(255, 215, 0)
mainFrame.ClipsDescendants = true
mainFrame.Visible = false
mainFrame.ZIndex = 100
mainFrame.Parent = gui

local mainCorner = Instance.new("UICorner")
mainCorner.CornerRadius = UDim.new(0, 12)
mainCorner.Parent = mainFrame

-- Inner border
local innerBorder = Instance.new("Frame")
innerBorder.Size = UDim2.new(0.97, 0, 0.97, 0)
innerBorder.Position = UDim2.new(0.015, 0, 0.015, 0)
innerBorder.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
innerBorder.BorderSizePixel = 2
innerBorder.BorderColor3 = Color3.fromRGB(255, 215, 0)
innerBorder.BackgroundTransparency = 0
innerBorder.ClipsDescendants = true
innerBorder.Parent = mainFrame

local innerCornerMain = Instance.new("UICorner")
innerCornerMain.CornerRadius = UDim.new(0, 8)
innerCornerMain.Parent = innerBorder

-- Header
local header = Instance.new("TextLabel")
header.Size = UDim2.new(1, 0, 0, 45)
header.Position = UDim2.new(0, 0, 0, 0)
header.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
header.BackgroundTransparency = 0
header.Text = "RITUAL HUB"
header.TextColor3 = Color3.fromRGB(255, 215, 0)
header.TextScaled = true
header.Font = Enum.Font.GothamBold
header.TextSize = 22
header.TextXAlignment = Enum.TextXAlignment.Center
header.TextYAlignment = Enum.TextYAlignment.Center
header.BorderSizePixel = 0
header.Parent = innerBorder

-- Divider
local divider = Instance.new("Frame")
divider.Size = UDim2.new(0.9, 0, 0, 2)
divider.Position = UDim2.new(0.05, 0, 0, 43)
divider.BackgroundColor3 = Color3.fromRGB(255, 215, 0)
divider.BackgroundTransparency = 0
divider.BorderSizePixel = 0
divider.Parent = innerBorder

-- Empty content area with gold border
local contentArea = Instance.new("Frame")
contentArea.Size = UDim2.new(0.92, 0, 0.7, 0)
contentArea.Position = UDim2.new(0.04, 0, 0.16, 0)
contentArea.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
contentArea.BackgroundTransparency = 0
contentArea.BorderSizePixel = 0
contentArea.Parent = innerBorder

local contentBorder = Instance.new("Frame")
contentBorder.Size = UDim2.new(1, 0, 1, 0)
contentBorder.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
contentBorder.BorderSizePixel = 2
contentBorder.BorderColor3 = Color3.fromRGB(255, 215, 0)
contentBorder.BackgroundTransparency = 0
contentBorder.Parent = contentArea

local contentBorderCorner = Instance.new("UICorner")
contentBorderCorner.CornerRadius = UDim.new(0, 6)
contentBorderCorner.Parent = contentBorder

-- Bottom bar
local bottomBar = Instance.new("Frame")
bottomBar.Size = UDim2.new(0.92, 0, 0, 30)
bottomBar.Position = UDim2.new(0.04, 0, 0.87, 0)
bottomBar.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
bottomBar.BackgroundTransparency = 0
bottomBar.BorderSizePixel = 2
bottomBar.BorderColor3 = Color3.fromRGB(255, 215, 0)
bottomBar.Parent = innerBorder

local bottomCorner = Instance.new("UICorner")
bottomCorner.CornerRadius = UDim.new(0, 4)
bottomCorner.Parent = bottomBar

-- ===== TOGGLE & DRAG LOGIC =====
local isVisible = false
local isDragging = false
local dragStart = nil
local buttonStartPos = nil
local dragThreshold = 15  -- pixels to distinguish drag from tap

local function toggleGUI()
    isVisible = not isVisible
    mainFrame.Visible = isVisible
    
    if isVisible then
        rButton.BorderColor3 = Color3.fromRGB(255, 230, 100)
        rButton.BorderSizePixel = 4
        rButton.TextColor3 = Color3.fromRGB(255, 230, 100)
        innerGold.BorderColor3 = Color3.fromRGB(255, 230, 100)
        glow.BackgroundTransparency = 0.7
    else
        rButton.BorderColor3 = Color3.fromRGB(255, 215, 0)
        rButton.BorderSizePixel = 3
        rButton.TextColor3 = Color3.fromRGB(255, 215, 0)
        innerGold.BorderColor3 = Color3.fromRGB(255, 215, 0)
        glow.BackgroundTransparency = 0.85
    end
end

-- Handle input on the button itself
rButton.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.Touch or 
       input.UserInputType == Enum.UserInputType.MouseButton1 then
        -- Record start position for drag detection
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
                -- Move button
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
        -- Reset appearance
        if not isVisible then
            rButton.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
            rButton.BorderSizePixel = 3
        end
        -- If not dragging, treat as tap/click
        if not isDragging then
            toggleGUI()
        end
        -- Clear drag state
        isDragging = false
        dragStart = nil
        buttonStartPos = nil
    end
end)

-- Also handle touch tap directly (in case InputEnded doesn't fire)
rButton.TouchTap:Connect(function()
    -- Only toggle if not dragging (we use a variable to prevent double toggle)
    if not isDragging then
        toggleGUI()
    end
end)

-- ===== PULSE ANIMATION =====
RunService.RenderStepped:Connect(function()
    if not isVisible then
        local pulse = math.sin(tick() * 2.5) * 0.3 + 0.7
        rButton.BorderSizePixel = 2 + pulse * 2
        innerGold.BorderSizePixel = 1 + pulse * 2
        local glowPulse = math.sin(tick() * 1.5) * 0.08 + 0.85
        glow.BackgroundTransparency = glowPulse
        glow.Size = UDim2.new(1.2 + (1 - glowPulse) * 0.5, 0, 1.2 + (1 - glowPulse) * 0.5, 0)
    end
end)

-- ===== ENSURE BUTTON VISIBLE =====
RunService.Heartbeat:Connect(function()
    rButton.Visible = true
    rButton.ZIndex = 999
end)

print("✅ RITUAL HUB - Mobile Optimized (Fixed Click & Drag)")
print("📱 Tap the gold R button to toggle GUI")
print("🔄 Drag the R button to reposition it (drag more than 15 pixels)")
print("⚫ Black & Gold theme")
