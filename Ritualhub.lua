-- RITUAL HUB - Sacred AHK Style (Mobile Fixed)
-- Black Glass Background with Gold Outlines
-- Fully functional draggable R button

local Players = game:GetService("Players")
local Player = Players.LocalPlayer
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")

local screenSize = workspace.CurrentCamera.ViewportSize

-- ===== MAIN GUI =====
local gui = Instance.new("ScreenGui")
gui.Name = "RitualHub"
gui.ResetOnSpawn = false
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.Parent = Player:WaitForChild("PlayerGui")

-- ===== DRAGGABLE R BUTTON (TextButton) =====
local rButton = Instance.new("TextButton")
rButton.Size = UDim2.new(0, 65, 0, 65)
rButton.Position = UDim2.new(0.02, 0, 0.02, 0)
rButton.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
rButton.BackgroundTransparency = 0.15   -- slight glass effect
rButton.BorderSizePixel = 3
rButton.BorderColor3 = Color3.fromRGB(255, 215, 0)
rButton.AutoButtonColor = false
rButton.Text = "R"
rButton.TextColor3 = Color3.fromRGB(255, 215, 0)
rButton.TextScaled = true
rButton.Font = Enum.Font.GothamBold
rButton.TextSize = 35
rButton.ClipsDescendants = true
rButton.ZIndex = 999
rButton.Parent = gui

-- Circle corner
local rCorner = Instance.new("UICorner")
rCorner.CornerRadius = UDim.new(1, 0)
rCorner.Parent = rButton

-- Inner gold ring
local innerRing = Instance.new("Frame")
innerRing.Size = UDim2.new(0.85, 0, 0.85, 0)
innerRing.Position = UDim2.new(0.075, 0, 0.075, 0)
innerRing.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
innerRing.BackgroundTransparency = 0.3
innerRing.BorderSizePixel = 2
innerRing.BorderColor3 = Color3.fromRGB(255, 215, 0)
innerRing.ZIndex = 998
innerRing.Parent = rButton

local innerCorner = Instance.new("UICorner")
innerCorner.CornerRadius = UDim.new(1, 0)
innerCorner.Parent = innerRing

-- Glow effect
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

-- ===== SACRED-STYLE MAIN FRAME =====
local mainFrame = Instance.new("Frame")
mainFrame.Size = UDim2.new(0, 340, 0, 460)
mainFrame.Position = UDim2.new(0.5, -170, 0.5, -230)
mainFrame.BackgroundColor3 = Color3.fromRGB(10, 10, 15)  -- dark glass
mainFrame.BackgroundTransparency = 0.15
mainFrame.BorderSizePixel = 3
mainFrame.BorderColor3 = Color3.fromRGB(255, 215, 0)
mainFrame.ClipsDescendants = true
mainFrame.Visible = false
mainFrame.ZIndex = 100
mainFrame.Parent = gui

-- Rounded corners
local mainCorner = Instance.new("UICorner")
mainCorner.CornerRadius = UDim.new(0, 16)
mainCorner.Parent = mainFrame

-- Inner glow border (gold)
local innerGlow = Instance.new("Frame")
innerGlow.Size = UDim2.new(0.97, 0, 0.97, 0)
innerGlow.Position = UDim2.new(0.015, 0, 0.015, 0)
innerGlow.BackgroundColor3 = Color3.fromRGB(10, 10, 15)
innerGlow.BackgroundTransparency = 0.3
innerGlow.BorderSizePixel = 2
innerGlow.BorderColor3 = Color3.fromRGB(255, 215, 0)
innerGlow.ClipsDescendants = true
innerGlow.Parent = mainFrame

local innerCornerMain = Instance.new("UICorner")
innerCornerMain.CornerRadius = UDim.new(0, 12)
innerCornerMain.Parent = innerGlow

-- ===== HEADER =====
local header = Instance.new("TextLabel")
header.Size = UDim2.new(1, 0, 0, 55)
header.Position = UDim2.new(0, 0, 0, 0)
header.BackgroundTransparency = 1
header.Text = "RITUAL HUB"
header.TextColor3 = Color3.fromRGB(255, 215, 0)
header.TextScaled = true
header.Font = Enum.Font.GothamBold
header.TextSize = 26
header.TextXAlignment = Enum.TextXAlignment.Center
header.TextYAlignment = Enum.TextYAlignment.Center
header.Parent = innerGlow

-- Subtitle (like "by iSacredRivals")
local subtitle = Instance.new("TextLabel")
subtitle.Size = UDim2.new(1, 0, 0, 25)
subtitle.Position = UDim2.new(0, 0, 0, 55)
subtitle.BackgroundTransparency = 1
subtitle.Text = "by iSacredRivals"
subtitle.TextColor3 = Color3.fromRGB(180, 180, 200)
subtitle.TextScaled = true
subtitle.Font = Enum.Font.Gotham
subtitle.TextSize = 14
subtitle.TextXAlignment = Enum.TextXAlignment.Center
subtitle.TextYAlignment = Enum.TextYAlignment.Top
subtitle.Parent = innerGlow

-- Divider line
local divider = Instance.new("Frame")
divider.Size = UDim2.new(0.9, 0, 0, 2)
divider.Position = UDim2.new(0.05, 0, 0, 82)
divider.BackgroundColor3 = Color3.fromRGB(255, 215, 0)
divider.BackgroundTransparency = 0.5
divider.BorderSizePixel = 0
divider.Parent = innerGlow

-- ===== SECTIONS (Empty with labels) =====
local sections = {"Combat Main", "Glitches", "Soru Engine", "Songs & Music"}
local yPos = 0.18
for i, name in ipairs(sections) do
    local sectionFrame = Instance.new("Frame")
    sectionFrame.Size = UDim2.new(0.9, 0, 0, 30)
    sectionFrame.Position = UDim2.new(0.05, 0, yPos, 0)
    sectionFrame.BackgroundTransparency = 1
    sectionFrame.Parent = innerGlow
    
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, 0, 1, 0)
    label.BackgroundTransparency = 1
    label.Text = name
    label.TextColor3 = Color3.fromRGB(200, 200, 220)
    label.TextScaled = true
    label.Font = Enum.Font.Gotham
    label.TextSize = 15
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.TextYAlignment = Enum.TextYAlignment.Center
    label.Parent = sectionFrame
    
    -- Small divider under each section
    local smallDiv = Instance.new("Frame")
    smallDiv.Size = UDim2.new(0.9, 0, 0, 1)
    smallDiv.Position = UDim2.new(0.05, 0, 1, 0)
    smallDiv.BackgroundColor3 = Color3.fromRGB(255, 215, 0)
    smallDiv.BackgroundTransparency = 0.6
    smallDiv.BorderSizePixel = 0
    smallDiv.Parent = sectionFrame
    
    yPos = yPos + 0.08
end

-- ===== BOTTOM INFO BAR =====
local bottomBar = Instance.new("Frame")
bottomBar.Size = UDim2.new(0.9, 0, 0, 35)
bottomBar.Position = UDim2.new(0.05, 0, 0.88, 0)
bottomBar.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
bottomBar.BackgroundTransparency = 0.4
bottomBar.BorderSizePixel = 2
bottomBar.BorderColor3 = Color3.fromRGB(255, 215, 0)
bottomBar.Parent = innerGlow

local bottomCorner = Instance.new("UICorner")
bottomCorner.CornerRadius = UDim.new(0, 6)
bottomCorner.Parent = bottomBar

-- f512
local f512 = Instance.new("TextLabel")
f512.Size = UDim2.new(0.25, 0, 1, 0)
f512.Position = UDim2.new(0.02, 0, 0, 0)
f512.BackgroundTransparency = 1
f512.Text = "f512"
f512.TextColor3 = Color3.fromRGB(180, 180, 200)
f512.TextScaled = true
f512.Font = Enum.Font.Gotham
f512.TextSize = 12
f512.TextXAlignment = Enum.TextXAlignment.Left
f512.TextYAlignment = Enum.TextYAlignment.Center
f512.Parent = bottomBar

-- Cash
local cash = Instance.new("TextLabel")
cash.Size = UDim2.new(0.35, 0, 1, 0)
cash.Position = UDim2.new(0.33, 0, 0, 0)
cash.BackgroundTransparency = 1
cash.Text = "$4,973,310"
cash.TextColor3 = Color3.fromRGB(255, 215, 0)
cash.TextScaled = true
cash.Font = Enum.Font.GothamBold
cash.TextSize = 14
cash.TextXAlignment = Enum.TextXAlignment.Center
cash.TextYAlignment = Enum.TextYAlignment.Center
cash.Parent = bottomBar

-- Version
local version = Instance.new("TextLabel")
version.Size = UDim2.new(0.35, 0, 1, 0)
version.Position = UDim2.new(0.63, 0, 0, 0)
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
        rButton.BorderSizePixel = 4
        rButton.TextColor3 = Color3.fromRGB(255, 230, 100)
        innerRing.BorderColor3 = Color3.fromRGB(255, 230, 100)
        glow.BackgroundTransparency = 0.7
    else
        rButton.BorderColor3 = Color3.fromRGB(255, 215, 0)
        rButton.BorderSizePixel = 3
        rButton.TextColor3 = Color3.fromRGB(255, 215, 0)
        innerRing.BorderColor3 = Color3.fromRGB(255, 215, 0)
        glow.BackgroundTransparency = 0.85
    end
end

-- DIRECT INPUT HANDLING ON THE BUTTON
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
        rButton.BackgroundTransparency = 0.15
        if not isVisible then
            rButton.BorderSizePixel = 3
        end
        if not isDragging then
            toggleGUI()
        end
        isDragging = false
        dragStart = nil
        buttonStartPos = nil
    end
end)

-- Fallback for touch tap (some devices may not fire InputEnded)
rButton.TouchTap:Connect(function()
    if not isDragging then
        toggleGUI()
    end
end)

-- ===== PULSE ANIMATION =====
RunService.RenderStepped:Connect(function()
    if not isVisible then
        local pulse = math.sin(tick() * 2.5) * 0.3 + 0.7
        rButton.BorderSizePixel = 2 + pulse * 2
        innerRing.BorderSizePixel = 1 + pulse * 2
        local glowPulse = math.sin(tick() * 1.5) * 0.08 + 0.85
        glow.BackgroundTransparency = glowPulse
        glow.Size = UDim2.new(1.2 + (1 - glowPulse) * 0.5, 0, 1.2 + (1 - glowPulse) * 0.5, 0)
    end
end)

-- Keep button on top
RunService.Heartbeat:Connect(function()
    rButton.Visible = true
    rButton.ZIndex = 999
end)

print("✅ RITUAL HUB - Sacred Style Loaded")
print("📱 Tap the gold R button to toggle GUI")
print("🔄 Drag the R button to reposition")
print("⚫ Dark glass with gold outlines")
