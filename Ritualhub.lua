-- ==================== OBSIDIAN UI (DELTA-SAFE LOADER v5) ====================
-- v5 fixes: the menu not showing on Delta.
--  * multi-method HTTP download (HttpGet / request / syn.request) with retries
--  * safe fallback repos
--  * forces the ScreenGui into a container Delta can actually render
--  * mobile/touch friendly (custom cursor off, always-visible open button)
--  * every cosmetic step is pcall-wrapped so it can never hide the menu

local HttpService   = game:GetService("HttpService")
local TweenService  = game:GetService("TweenService")
local CoreGuiSvc    = game:GetService("CoreGui")
local Players       = game:GetService("Players")
local UIS           = game:GetService("UserInputService")

local UI_REPOS = {
    "https://raw.githubusercontent.com/deividcomsono/Obsidian/main/",
    "https://raw.githubusercontent.com/bloodball/-back-ups-for-libs/main/",
}

local httpRequest = (syn and syn.request) or (http and http.request) or http_request or request

local function fetch(url)
    -- method 1: game:HttpGet
    local ok, res = pcall(function() return game:HttpGet(url, true) end)
    if ok and type(res) == "string" and #res > 500 and not res:find("404: Not Found", 1, true) then
        return res
    end
    -- method 2: executor request()
    if httpRequest then
        local ok2, res2 = pcall(function()
            return httpRequest({ Url = url, Method = "GET" })
        end)
        if ok2 and type(res2) == "table" and res2.Body and #res2.Body > 500
            and (res2.StatusCode == nil or res2.StatusCode == 200) then
            return res2.Body
        end
    end
    return nil
end

local function loadModule(path)
    for attempt = 1, 3 do
        for _, base in ipairs(UI_REPOS) do
            local body = fetch(base .. path)
            if body then
                local chunk, err = loadstring(body)
                if chunk then
                    local ok, mod = pcall(chunk)
                    if ok and mod then return mod end
                    warn("[NamelessWare] runtime error in " .. path .. ": " .. tostring(mod))
                else
                    warn("[NamelessWare] compile error for " .. path .. ": " .. tostring(err))
                end
            end
        end
        task.wait(0.6)
    end
    error("[NamelessWare] Failed to load UI module: " .. path .. " (check your executor's internet access)")
end

local Library = loadModule("Library.lua")
local ThemeManager = loadModule("addons/ThemeManager.lua")
local SaveManager = loadModule("addons/SaveManager.lua")

local Options = Library.Options
local Toggles = Library.Toggles

pcall(function()
    if not isfolder("NamelessConfigs") then makefolder("NamelessConfigs") end
    if not isfolder("NamelessConfigs/Fonts") then makefolder("NamelessConfigs/Fonts") end
end)

-- Delta / mobile detection: custom cursor + big desktop window break there.
local IS_TOUCH = false
pcall(function() IS_TOUCH = UIS.TouchEnabled and not UIS.MouseEnabled end)
local viewportX = 1280
pcall(function() viewportX = workspace.CurrentCamera.ViewportSize.X end)
local IS_SMALL = viewportX < 800

local Window = Library:CreateWindow({
    Title = "NamelessWare",
    Footer = "lumexa on top",
    ShowCustomCursor = not IS_TOUCH,
    NotifySide = "Right",
    Size = IS_SMALL and UDim2.new(0, 460, 0, 340) or UDim2.new(0, 600, 0, 460),
    Center = true,
    AutoShow = true,
})

-- ==================== DELTA VISIBILITY FIX ====================
-- Some executors (Delta especially) refuse the container Obsidian picks, so the
-- menu is created but never rendered. Re-home it and force it visible.
task.spawn(function()
    local gui
    for _ = 1, 40 do
        gui = Library.ScreenGui or Library.Holder
        if gui then break end
        task.wait(0.1)
    end
    if not gui then
        warn("[NamelessWare] UI ScreenGui missing")
        return
    end

    local function parentOk(g)
        local ok = pcall(function() return g.Parent ~= nil and g.Parent.Name end)
        return ok and g.Parent ~= nil
    end

    if not parentOk(gui) then
        local targets = {}
        if gethui then table.insert(targets, (pcall(gethui) and gethui()) or nil) end
        table.insert(targets, CoreGuiSvc)
        table.insert(targets, Players.LocalPlayer:FindFirstChildOfClass("PlayerGui"))
        for _, t in ipairs(targets) do
            if t and pcall(function() gui.Parent = t end) and parentOk(gui) then break end
        end
    end

    pcall(function()
        gui.Enabled = true
        gui.IgnoreGuiInset = true
        gui.ResetOnSpawn = false
        gui.DisplayOrder = 9999
        if syn and syn.protect_gui then syn.protect_gui(gui) end
    end)

    -- Make sure the main window frame itself is on-screen and visible.
    pcall(function()
        for _, child in ipairs(gui:GetChildren()) do
            if child:IsA("Frame") and child.AbsoluteSize.X > 120 then
                child.Visible = true
                local vp = workspace.CurrentCamera.ViewportSize
                if child.AbsolutePosition.X > vp.X - 40 or child.AbsolutePosition.Y > vp.Y - 40
                    or child.AbsolutePosition.X < -child.AbsoluteSize.X + 40
                    or child.AbsolutePosition.Y < -20 then
                    child.Position = UDim2.fromOffset(
                        math.floor(vp.X / 2 - child.AbsoluteSize.X / 2),
                        math.floor(vp.Y / 2 - child.AbsoluteSize.Y / 2)
                    )
                end
            end
        end
    end)

    -- Always-available floating open/close button (Delta mobile has no End key).
    pcall(function()
        local btnGui = Instance.new("ScreenGui")
        btnGui.Name = "NamelessWareToggle"
        btnGui.ResetOnSpawn = false
        btnGui.IgnoreGuiInset = true
        btnGui.DisplayOrder = 10000
        local placed = false
        if gethui then placed = pcall(function() btnGui.Parent = gethui() end) end
        if not placed or not btnGui.Parent then
            if not pcall(function() btnGui.Parent = CoreGuiSvc end) then
                btnGui.Parent = Players.LocalPlayer:FindFirstChildOfClass("PlayerGui")
            end
        end

        local btn = Instance.new("TextButton")
        btn.Name = "NWButton"
        btn.Size = UDim2.fromOffset(52, 52)
        btn.Position = UDim2.new(0, 14, 0.35, 0)
        btn.BackgroundColor3 = Color3.fromRGB(18, 18, 24)
        btn.BackgroundTransparency = 0.08
        btn.Text = "NW"
        btn.TextColor3 = Color3.fromRGB(235, 225, 255)
        btn.TextSize = 16
        btn.Font = Enum.Font.GothamBold
        btn.AutoButtonColor = false
        btn.Active = true
        btn.Draggable = true
        btn.ZIndex = 50
        btn.Parent = btnGui

        local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0, 14); c.Parent = btn
        local s = Instance.new("UIStroke"); s.Color = Color3.fromRGB(160, 80, 255); s.Thickness = 2; s.Parent = btn

        btn.MouseButton1Click:Connect(function()
            pcall(function()
                if Library.Toggled ~= nil and Library.Toggle then
                    Library:Toggle()
                else
                    gui.Enabled = not gui.Enabled
                end
            end)
        end)
    end)

    pcall(function()
        Library:Notify({ Title = "NamelessWare", Description = "UI loaded. Press End or tap the NW button to toggle.", Time = 4 })
    end)
end)



task.delay(0.2, function()
    local CoreGui = game:GetService("CoreGui")
    local Players = game:GetService("Players")
    local lp = Players.LocalPlayer

    local function applyLogo()
        local titleLabel = nil
        local containers = { CoreGui, lp:FindFirstChild("PlayerGui") }
        
        for _, parent in ipairs(containers) do
            if parent then
                for _, descendant in ipairs(parent:GetDescendants()) do
                    if descendant:IsA("TextLabel") and (descendant.Text == "NamelessWare" or descendant.Text:find("Nameless")) then
                        if descendant.Parent and descendant.Parent:FindFirstChild("NamelessLogoIcon") then
                            return true
                        end
                        titleLabel = descendant
                        break
                    end
                end
            end
            if titleLabel then break end
        end

        if titleLabel then
            titleLabel.RichText = true
            titleLabel.Text = '<font color="#ffffff">Nameless</font><font color="#a050ff">Ware</font>'
            
            local titleParent = titleLabel.Parent
            if titleParent then
                local existingLogo = titleParent:FindFirstChild("NamelessLogoIcon")
                if existingLogo then existingLogo:Destroy() end

                local logoImg = Instance.new("ImageButton")
                logoImg.Name = "NamelessLogoIcon"
                logoImg.BackgroundTransparency = 1
                logoImg.Size = UDim2.new(0, 22, 0, 22)
                logoImg.Image = "rbxassetid://105243902490842"
                logoImg.ScaleType = Enum.ScaleType.Fit
                logoImg.AutoButtonColor = false
                
                local UICornerLogo = Instance.new("UICorner")
                UICornerLogo.CornerRadius = UDim.new(0, 4)
                UICornerLogo.Parent = logoImg

                local listLayout = titleParent:FindFirstChildOfClass("UIListLayout")
                if listLayout then
                    logoImg.LayoutOrder = 0
                    titleLabel.LayoutOrder = 1
                else
                    logoImg.Position = UDim2.new(0, 8, 0, (titleLabel.Position.Y.Offset > 0 and titleLabel.Position.Y.Offset or 6))
                    titleLabel.Position = UDim2.new(0, 36, 0, titleLabel.Position.Y.Offset)
                end
                
                logoImg.Parent = titleParent

                local windowFrame = titleParent
                while windowFrame and windowFrame.Parent and not windowFrame.Parent:IsA("ScreenGui") do
                    windowFrame = windowFrame.Parent
                end
                
                local screenGui = windowFrame and windowFrame.Parent
                local toggleBtn = nil
                
                if screenGui then
                    toggleBtn = screenGui:FindFirstChild("NamelessToggleIcon")
                    if not toggleBtn then
                        toggleBtn = Instance.new("ImageButton")
                        toggleBtn.Name = "NamelessToggleIcon"
                        toggleBtn.Size = UDim2.new(0, 42, 0, 42)
                        toggleBtn.Position = UDim2.new(0.05, 0, 0.15, 0)
                        toggleBtn.BackgroundColor3 = Color3.fromRGB(15, 15, 20)
                        toggleBtn.BackgroundTransparency = 0.1
                        toggleBtn.Image = "rbxassetid://105243902490842"
                        toggleBtn.ScaleType = Enum.ScaleType.Fit
                        toggleBtn.Visible = false
                        toggleBtn.Active = true
                        toggleBtn.Draggable = true
                        toggleBtn.Parent = screenGui

                        local corner = Instance.new("UICorner")
                        corner.CornerRadius = UDim.new(0, 10)
                        corner.Parent = toggleBtn

                        local stroke = Instance.new("UIStroke")
                        stroke.Color = Color3.fromRGB(160, 80, 255)
                        stroke.Thickness = 2
                        stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
                        stroke.Parent = toggleBtn
                        
                        toggleBtn.MouseButton1Click:Connect(function()
                            if not windowFrame then return end
                            toggleBtn.Visible = false
                            windowFrame.Visible = true
                            local scale = windowFrame:FindFirstChild("NamelessSmoothScale") or Instance.new("UIScale")
                            scale.Name = "NamelessSmoothScale"
                            scale.Scale = 0.94
                            scale.Parent = windowFrame
                            TweenService:Create(scale, TweenInfo.new(0.22, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {Scale = 1}):Play()
                        end)
                    end
                end

                -- Smooth, modern open/close animation.
                local smoothScale = Instance.new("UIScale")
                smoothScale.Name = "NamelessSmoothScale"
                smoothScale.Scale = 1
                smoothScale.Parent = windowFrame

                logoImg.MouseEnter:Connect(function()
                    TweenService:Create(logoImg, TweenInfo.new(0.14, Enum.EasingStyle.Quad), {ImageTransparency = 0.12}):Play()
                end)
                logoImg.MouseLeave:Connect(function()
                    TweenService:Create(logoImg, TweenInfo.new(0.14, Enum.EasingStyle.Quad), {ImageTransparency = 0}):Play()
                end)
                logoImg.MouseButton1Click:Connect(function()
                    if not windowFrame then return end
                    TweenService:Create(smoothScale, TweenInfo.new(0.16, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {Scale = 0.94}):Play()
                    task.delay(0.16, function()
                        if toggleBtn then
                            toggleBtn.Position = UDim2.new(
                                windowFrame.Position.X.Scale,
                                windowFrame.Position.X.Offset + 10,
                                windowFrame.Position.Y.Scale,
                                windowFrame.Position.Y.Offset + 10
                            )
                            toggleBtn.Visible = true
                            toggleBtn.ImageTransparency = 1
                            TweenService:Create(toggleBtn, TweenInfo.new(0.18, Enum.EasingStyle.Quad), {ImageTransparency = 0}):Play()
                        end
                        windowFrame.Visible = false
                        smoothScale.Scale = 1
                    end)
                end)
                return true
            end
        end
        return false
    end

    for i = 1, 5 do
        if applyLogo() then break end
        task.wait(0.3)
    end
end)


-- ==================== MODERN UI POLISH (smooth motion + soft styling) ====================
task.delay(0.35, function()
    local gui = Library.ScreenGui
    if not gui then return end

    local FAST = TweenInfo.new(0.16, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
    local SOFT = TweenInfo.new(0.28, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)

    local function roundify(inst, radius)
        if not inst:IsA("GuiObject") then return end
        local corner = inst:FindFirstChildOfClass("UICorner")
        if not corner then
            corner = Instance.new("UICorner")
            corner.Parent = inst
        end
        corner.CornerRadius = UDim.new(0, radius or 6)
    end

    local function polish(inst)
        pcall(function()
            if inst:IsA("Frame") or inst:IsA("ImageLabel") or inst:IsA("ImageButton") or inst:IsA("TextButton") then
                if inst.AbsoluteSize.X > 8 and inst.AbsoluteSize.Y > 8 then
                    roundify(inst, inst.AbsoluteSize.Y > 60 and 10 or 6)
                end
            end
            if inst:IsA("TextButton") or inst:IsA("ImageButton") then
                local base = inst.BackgroundTransparency
                inst.AutoButtonColor = false
                inst.MouseEnter:Connect(function()
                    TweenService:Create(inst, FAST, { BackgroundTransparency = math.max(base - 0.15, 0) }):Play()
                end)
                inst.MouseLeave:Connect(function()
                    TweenService:Create(inst, FAST, { BackgroundTransparency = base }):Play()
                end)
                inst.MouseButton1Down:Connect(function()
                    TweenService:Create(inst, TweenInfo.new(0.08), { BackgroundTransparency = math.max(base - 0.25, 0) }):Play()
                end)
                inst.MouseButton1Up:Connect(function()
                    TweenService:Create(inst, FAST, { BackgroundTransparency = base }):Play()
                end)
            end
        end)
    end

    local function watchPage(page)
        if not (page:IsA("ScrollingFrame") or page:IsA("Frame")) then return end
        page:GetPropertyChangedSignal("Visible"):Connect(function()
            if page.Visible then
                pcall(function()
                    local pos = page.Position
                    page.Position = pos + UDim2.fromOffset(0, 8)
                    TweenService:Create(page, SOFT, { Position = pos }):Play()
                end)
            end
        end)
    end

    for _, inst in ipairs(gui:GetDescendants()) do
        polish(inst)
        watchPage(inst)
    end
    gui.DescendantAdded:Connect(function(inst)
        task.defer(function()
            polish(inst)
            watchPage(inst)
        end)
    end)

    local main = gui:FindFirstChildWhichIsA("Frame")
    if main then
        pcall(function()
            local scale = main:FindFirstChildOfClass("UIScale") or Instance.new("UIScale", main)
            scale.Scale = 0.96
            TweenService:Create(scale, TweenInfo.new(0.35, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Scale = 1 }):Play()
            local stroke = main:FindFirstChildOfClass("UIStroke") or Instance.new("UIStroke", main)
            stroke.Thickness = 1
            stroke.Transparency = 0.55
            roundify(main, 12)
        end)
    end
end)

local Tabs = {
    Macro       = Window:AddTab("Macro", "keyboard"),
    SilentAim   = Window:AddTab("Silent Aim", "crosshair"),
    SABlacklist = Window:AddTab("SA Blacklist", "ban"),
    Glitch      = Window:AddTab("Glitch", "zap"),
    Movement    = Window:AddTab("Movement", "move"),
    Apparence   = Window:AddTab("Appearance", "user"),
    Misc        = Window:AddTab("Misc", "box"),
    ESP         = Window:AddTab("ESP", "eye"),
    Settings    = Window:AddTab("Settings", "settings"),
}

-- ==================== SERVICES ====================
local Players = game:GetService("Players")
local lp = Players.LocalPlayer
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local camera = workspace.CurrentCamera
local RS = game:GetService("ReplicatedStorage")

local SilentAimModule

-- ==================== VSKILL & DAMAGE STATE ====================
local sharkZActive, vActive, cursedZActive = false, false, false
local rightTouchActive = false
local damageDetected = false
local isBunnyHopping = false

-- ==================== LOADERS AHK ====================
local ahk_soru_loaded = false
local function UnloadAHKsoru()
    ahk_soru_loaded = false
    _G.NamelessAHKRunning = nil
    pcall(function()
        local containers = {lp:FindFirstChild("PlayerGui"), game:GetService("CoreGui")}
        for _, parent in ipairs(containers) do
            if parent then
                for _, child in pairs(parent:GetChildren()) do
                    if child.Name:find("AHK_Soru") or child.Name:find("namelessWare_AHK_Soru") then
                        child:Destroy()
                    end
                end
            end
        end
    end)
    Library:Notify({ Title = "AHK Soru", Description = "Script disabled!", Time = 3 })
end

local function LoadAHKsoru()
    _G.NamelessAHKRunning = nil
    ahk_soru_loaded = false
    local success, err = pcall(function()
        local script_code = game:HttpGet("https://raw.githubusercontent.com/sykq0/Namelesssoru/refs/heads/main/ahk.lua")
        loadstring(script_code)()
    end)
    if success then
        ahk_soru_loaded = true
        Library:Notify({ Title = "AHK Soru", Description = "Script loaded!", Time = 3 })
    else
        Library:Notify({ Title = "AHK Soru", Description = "Loading error.", Time = 3 })
    end
end

local ahk_combo_script_loaded = false
local function UnloadAHKComboScript()
    ahk_combo_script_loaded = false
    _G.NamelessComboRunning = nil
    pcall(function()
        local containers = {lp:FindFirstChild("PlayerGui"), game:GetService("CoreGui")}
        for _, parent in ipairs(containers) do
            if parent then
                for _, child in pairs(parent:GetChildren()) do
                    if child.Name:find("AHK_Combo") or child.Name:find("namelessWare_AHK_Combo") then
                        child:Destroy()
                    end
                end
            end
        end
    end)
    Library:Notify({ Title = "AHK Combo", Description = "Script disabled!", Time = 3 })
end

local function LoadAHKComboScript()
    _G.NamelessComboRunning = nil
    ahk_combo_script_loaded = false
    local success, err = pcall(function()
        local script_code = game:HttpGet("https://raw.githubusercontent.com/sykq0/Namelesssoru/refs/heads/main/fetched-1.lua")
        loadstring(script_code)()
    end)
    if success then
        ahk_combo_script_loaded = true
        Library:Notify({ Title = "AHK Combo", Description = "Script loaded!", Time = 3 })
    else
        Library:Notify({ Title = "AHK Combo", Description = "Loading error.", Time = 3 })
    end
end



-- ==================== DAMAGE MONITOR ====================
local function watchDamageCounter()
    task.spawn(function()
        while true do
            local gui = lp:FindFirstChild("PlayerGui") and lp.PlayerGui:FindFirstChild("Main")
            local dmgCounter = gui and gui:FindFirstChild("DmgCounter")
            local dmgTextLabel = dmgCounter and dmgCounter:FindFirstChild("Text")
            
            if dmgTextLabel then
                dmgTextLabel:GetPropertyChangedSignal("Text"):Connect(function()
                    local dmgText = tonumber(dmgTextLabel.Text) or 0
                    damageDetected = (dmgText > 0)
                end)
                break
            end
            task.wait(1)
        end
    end)
end
watchDamageCounter()

local function isValidStopCondition()
    local tool = lp.Character and lp.Character:FindFirstChildOfClass("Tool")
    return (tool and tool.Name == "Shark Anchor" and sharkZActive)
        or (vActive)
        or (tool and tool.Name == "Cursed Dual Katana" and cursedZActive)
end

-- ==================== BOOSTS (Sanguine, Diamond, EClaw) ====================
local multiEnabled = false; local multiPower = 400; local multiDuration = 0.9
local multiCharging = false; local multiChargeStart = 0; local multiRequiredCharge = 1.0

local diamondEnabled = false; local diamondPower = 250; local diamondDuration = 0.3
local diamondCharging = false; local diamondChargeStart = 0; local diamondRequiredCharge = 1.0

local dtalonEnabled = false; local dtalonPower = 400; local dtalonDuration = 0.9
local dtalonCharging = false; local dtalonChargeStart = 0; local dtalonRequiredCharge = 1.0

local EClawBoost

local function MegaBoost()
    local char = lp.Character; local hrp = char and char:FindFirstChild("HumanoidRootPart"); local hum = char and char:FindFirstChild("Humanoid")
    if not hrp or not hum then return end
    
    local dir = camera.CFrame.LookVector

    hum.PlatformStand = true
    local att = Instance.new("Attachment", hrp); local lv = Instance.new("LinearVelocity", hrp)
    lv.MaxForce = 9999999; lv.VelocityConstraintMode = Enum.VelocityConstraintMode.Vector; lv.VectorVelocity = dir * multiPower; lv.Attachment0 = att
    local boostActive = true; local boostEndTime = tick() + multiDuration; local dmgConn
    local function stopPropulsion()
        if not boostActive then return end; boostActive = false
        if lv then lv:Destroy() end; if att then att:Destroy() end; if hum then hum.PlatformStand = false end; if dmgConn then dmgConn:Disconnect() end
    end
    local dmgLabel = lp:FindFirstChild("PlayerGui") and lp.PlayerGui:FindFirstChild("Main") and lp.PlayerGui.Main:FindFirstChild("DmgCounter") and lp.PlayerGui.Main.DmgCounter:FindFirstChild("Text")
    local startText = dmgLabel and dmgLabel.Text or ""
    if dmgLabel then
        dmgConn = dmgLabel:GetPropertyChangedSignal("Text"):Connect(function()
            local currentText = dmgLabel.Text
            if (currentText ~= startText and currentText ~= "" and currentText ~= "0") or (rightTouchActive and isValidStopCondition()) then
                stopPropulsion()
            end
        end)
    end
    while boostActive and tick() < boostEndTime do task.wait() end; stopPropulsion()
end

RunService.Heartbeat:Connect(function()
    if not multiEnabled then return end
    local char = lp.Character; local hum = char and char:FindFirstChild("Humanoid"); if not hum then return end
    local isGC = false
    for _, a in pairs(hum:GetPlayingAnimationTracks()) do
        if a.Animation.AnimationId:find("14418367908") or a.Name == "GhoulZCharge" then isGC = true; break end
    end
    if isGC then if not multiCharging then multiCharging = true; multiChargeStart = tick() end
    else if multiCharging then if (tick() - multiChargeStart) >= multiRequiredCharge then task.spawn(MegaBoost) end; multiCharging = false; multiChargeStart = 0 end end
end)

local function DiamondBoost()
    local char = lp.Character; local hrp = char and char:FindFirstChild("HumanoidRootPart"); local hum = char and char:FindFirstChild("Humanoid")
    if not hrp or not hum then return end

    local dir = camera.CFrame.LookVector

    hum.PlatformStand = true
    local att = Instance.new("Attachment", hrp); local lv = Instance.new("LinearVelocity", hrp)
    lv.MaxForce = 9999999; lv.VelocityConstraintMode = Enum.VelocityConstraintMode.Vector; lv.VectorVelocity = dir * diamondPower; lv.Attachment0 = att
    local boostActive = true; local boostEndTime = tick() + diamondDuration; local dmgConn
    local function stopPropulsion()
        if not boostActive then return end; boostActive = false
        if lv then lv:Destroy() end; if att then att:Destroy() end; if hum then hum.PlatformStand = false end; if dmgConn then dmgConn:Disconnect() end
    end
    local dmgLabel = lp:FindFirstChild("PlayerGui") and lp.PlayerGui:FindFirstChild("Main") and lp.PlayerGui.Main:FindFirstChild("DmgCounter") and lp.PlayerGui.Main.DmgCounter:FindFirstChild("Text")
    local startText = dmgLabel and dmgLabel.Text or ""
    if dmgLabel then
        dmgConn = dmgLabel:GetPropertyChangedSignal("Text"):Connect(function()
            local currentText = dmgLabel.Text
            if (currentText ~= startText and currentText ~= "" and currentText ~= "0") or (rightTouchActive and isValidStopCondition()) then
                stopPropulsion()
            end
        end)
    end
    while boostActive and tick() < boostEndTime do task.wait() end; stopPropulsion()
end

RunService.Heartbeat:Connect(function()
    if not diamondEnabled then return end
    local char = lp.Character; local hum = char and char:FindFirstChild("Humanoid"); if not hum then return end
    local isC = false
    for _, a in pairs(hum:GetPlayingAnimationTracks()) do
        if a.Animation.AnimationId:find("14414815375") then isC = true; break end
    end
    if isC then if not diamondCharging then diamondCharging = true; diamondChargeStart = tick() end
    else if diamondCharging then if (tick() - diamondChargeStart) >= diamondRequiredCharge then task.spawn(DiamondBoost) end; diamondCharging = false; diamondChargeStart = 0 end end
end)

local function DTalonBoost()
    local char = lp.Character; local hrp = char and char:FindFirstChild("HumanoidRootPart"); local hum = char and char:FindFirstChild("Humanoid")
    if not hrp or not hum then return end

    local dir = camera.CFrame.LookVector

    hum.PlatformStand = true
    local att = Instance.new("Attachment", hrp); local lv = Instance.new("LinearVelocity", hrp)
    lv.MaxForce = 9999999; lv.VelocityConstraintMode = Enum.VelocityConstraintMode.Vector; lv.VectorVelocity = dir * dtalonPower; lv.Attachment0 = att
    local boostActive = true; local boostEndTime = tick() + dtalonDuration; local dmgConn
    local function stopPropulsion()
        if not boostActive then return end; boostActive = false
        if lv then lv:Destroy() end; if att then att:Destroy() end; if hum then hum.PlatformStand = false end; if dmgConn then dmgConn:Disconnect() end
    end
    local dmgLabel = lp:FindFirstChild("PlayerGui") and lp.PlayerGui:FindFirstChild("Main") and lp.PlayerGui.Main:FindFirstChild("DmgCounter") and lp.PlayerGui.Main.DmgCounter:FindFirstChild("Text")
    local startText = dmgLabel and dmgLabel.Text or ""
    if dmgLabel then
        dmgConn = dmgLabel:GetPropertyChangedSignal("Text"):Connect(function()
            local currentText = dmgLabel.Text
            if (currentText ~= startText and currentText ~= "" and currentText ~= "0") or (rightTouchActive and isValidStopCondition()) then
                stopPropulsion()
            end
        end)
    end
    while boostActive and tick() < boostEndTime do task.wait() end; stopPropulsion()
end

RunService.Heartbeat:Connect(function()
    if not dtalonEnabled then return end
    local char = lp.Character; local hum = char and char:FindFirstChild("Humanoid"); if not hum then return end
    local isC = false
    for _, a in pairs(hum:GetPlayingAnimationTracks()) do
        if a.Animation.AnimationId:find("18839089313") or a.Name == "DTalon_ZCharge" then isC = true; break end
    end
    if isC then if not dtalonCharging then dtalonCharging = true; dtalonChargeStart = tick() end
    else if dtalonCharging then if (tick() - dtalonChargeStart) >= dtalonRequiredCharge then task.spawn(DTalonBoost) end; dtalonCharging = false; dtalonChargeStart = 0 end end
end)

EClawBoost = (function()
    local M = {}; local enabled = false; local power = 400; local duration = 1.7; local requiredCharge = 0.0; local boosted = false
    local function boost()
        local char = lp.Character; local hrp = char and char:FindFirstChild("HumanoidRootPart"); local hum = char and char:FindFirstChildOfClass("Humanoid")
        if not hrp or not hum then return end; local mouse = lp:GetMouse(); local dir = (mouse.Hit.p - hrp.Position).Unit
        hum.PlatformStand = true; local att = Instance.new("Attachment", hrp); local lv = Instance.new("LinearVelocity", hrp)
        lv.MaxForce = 9999999; lv.VelocityConstraintMode = Enum.VelocityConstraintMode.Vector; lv.VectorVelocity = dir * power; lv.Attachment0 = att
        local boostActive = true; local boostEndTime = tick() + duration; local dmgConn
        local function stopPropulsion()
            if not boostActive then return end; boostActive = false
            if lv then lv:Destroy() end; if att then att:Destroy() end; if hum then hum.PlatformStand = false end; if dmgConn then dmgConn:Disconnect() end
        end
        local dmgLabel = lp:FindFirstChild("PlayerGui") and lp.PlayerGui:FindFirstChild("Main") and lp.PlayerGui.Main:FindFirstChild("DmgCounter") and lp.PlayerGui.Main.DmgCounter:FindFirstChild("Text")
        local startText = dmgLabel and dmgLabel.Text or ""
        if dmgLabel then
            dmgConn = dmgLabel:GetPropertyChangedSignal("Text"):Connect(function()
                local currentText = dmgLabel.Text
                if (currentText ~= startText and currentText ~= "" and currentText ~= "0") or (rightTouchActive and isValidStopCondition()) then
                    stopPropulsion()
                end
            end)
        end
        while boostActive and tick() < boostEndTime do task.wait() end; stopPropulsion()
    end
    local function hookAnimations(hum)
        hum.AnimationPlayed:Connect(function(track)
            if not enabled then return end
            if track.Animation.AnimationId:find("6875496851") or track.Name == "ElectroClawXImpact" then
                boosted = false; local chargeStart = tick()
                track.Stopped:Connect(function()
                    if not enabled and not boosted then return end
                    if (tick() - chargeStart) >= requiredCharge then boosted = true; task.spawn(boost) end
                end)
            end
        end)
    end
    function M:Toggle(v) enabled = v; if not v then boosted = false end end
    function M:SetPower(v) power = v end
    function M:SetDuration(v) duration = v end
    function M:SetRequiredCharge(v) requiredCharge = v end
    function M:Init(char) local hum = char:WaitForChild("Humanoid"); hookAnimations(hum) end
    return M
end)()
lp.CharacterAdded:Connect(function(char) EClawBoost:Init(char) end)
if lp.Character then EClawBoost:Init(lp.Character) end

-- ==================== FAKE ITEMS (Headless / Korblox) ====================
local fakeHeadlessEnabled = false
local fakeHeadlessVersion = "V1"
local fakeKorbloxEnabled = false
local fakeKorbloxVersion = "V1"
local korbloxMeshes = {}

function applyFakeKorblox()
    local char = lp.Character if not char then return end
    local rl  = char:FindFirstChild("RightUpperLeg")
    local rl2 = char:FindFirstChild("RightLowerLeg")
    local rf  = char:FindFirstChild("RightFoot")
    if rl then
        rl.Transparency = 1
        for _, c in pairs(rl:GetChildren()) do if c:IsA("SpecialMesh") then c:Destroy() end end
        local mesh = Instance.new("SpecialMesh")
        mesh.MeshId = "rbxassetid://139607718"
        mesh.TextureId = "rbxassetid://139607673"
        mesh.Scale = Vector3.new(1,1,1) mesh.Parent = rl
        table.insert(korbloxMeshes, mesh)
    end
    if rl2 then rl2.Transparency = 1 end
    if rf  then rf.Transparency  = 1 end
    if fakeKorbloxVersion == "V2" then
        for _, n in pairs({"LeftUpperLeg","LeftLowerLeg","LeftFoot"}) do
            local p = char:FindFirstChild(n) if p then p.Transparency = 1 end
        end
    end
end

function removeFakeKorblox()
    for _, m in pairs(korbloxMeshes) do pcall(function() m:Destroy() end) end
    korbloxMeshes = {}
    local char = lp.Character if not char then return end
    for _, n in pairs({"RightUpperLeg","RightLowerLeg","RightFoot","LeftUpperLeg","LeftLowerLeg","LeftFoot"}) do
        local p = char:FindFirstChild(n) if p then p.Transparency = 0 end
    end
end

function applyFakeHeadless()
    local char = lp.Character if not char then return end
    local head = char:FindFirstChild("Head")
    if head then
        head.Transparency = 1
        local face = head:FindFirstChild("face")
        if face then face.Transparency = 1 end
    end
    if fakeHeadlessVersion == "V2" then
        for _, obj in pairs(char:GetChildren()) do
            if obj:IsA("Accessory") then
                local handle = obj:FindFirstChild("Handle")
                if handle then handle.Transparency = 1 end
            end
        end
    end
end

function removeFakeHeadless()
    local char = lp.Character if not char then return end
    local head = char:FindFirstChild("Head")
    if head then
        head.Transparency = 0
        local face = head:FindFirstChild("face")
        if face then face.Transparency = 0 end
    end
    for _, obj in pairs(char:GetChildren()) do
        if obj:IsA("Accessory") then
            local handle = obj:FindFirstChild("Handle")
            if handle then handle.Transparency = 0 end
        end
    end
end

local function onCharacterAddedApparence(char)
    task.spawn(function()
        task.wait(0.3)
        if fakeHeadlessEnabled then applyFakeHeadless() end
        if fakeKorbloxEnabled then applyFakeKorblox() end
    end)
end
lp.CharacterAdded:Connect(onCharacterAddedApparence)
if lp.Character then onCharacterAddedApparence(lp.Character) end

-- ==================== MOVEMENT FEATURES ====================
local bunnyHopEnabled = false

local superJumpEnabled = false
local superJumpMode = "V1"
local superJumpPower = 150
local normalJumpPower = 50
local superJumpButton = nil

local dashLengthEnabled = false
local dashLengthValue = 1
local dashLengthConnection = nil

local flySettings = { flyActive = false, noclipActive = false, mode = "CFrame", speed = 50, incore = nil, nocore = nil }
local flyMiniGui = nil; local flyMiniButton = nil; local flyDragConn, flyEndConn = nil, nil

local speedSettings = { speedActive = false, mode = "WalkSpeed", speedValue = 50, incore = nil }
local speedMiniGui = nil; local speedMiniButton = nil; local speedDragConn, speedEndConn = nil, nil

-- ==================== FLY LOGIC ====================
local function StartFly()
    if flySettings.incore then flySettings.incore:Disconnect() end
    flySettings.flyActive = true
    flySettings.incore = RunService.Stepped:Connect(function()
        local char = lp.Character; local hrp = char and char:FindFirstChild("HumanoidRootPart"); local hum = char and char:FindFirstChildOfClass("Humanoid")
        if not flySettings.flyActive or not hrp or not hum then return end
        local moveDir = hum.MoveDirection
        local camCF = camera.CFrame
        local direction = Vector3.new(0, 0, 0)

        if moveDir.Magnitude > 0 then
            local relativeMove = camCF:VectorToObjectSpace(moveDir)
            direction = ((camCF.RightVector * relativeMove.X) + (camCF.LookVector * -relativeMove.Z)).Unit
        end

        if flySettings.mode == "CFrame" then
            hum.PlatformStand = true
            hrp.CFrame = hrp.CFrame + (direction * (flySettings.speed / 10))
            hrp.Velocity = Vector3.zero
        elseif flySettings.mode == "Velocity" then
            hrp.Velocity = (direction * flySettings.speed) + Vector3.new(0, 2, 0)
        end
        if UserInputService:IsKeyDown(Enum.KeyCode.Space) then hrp.CFrame = hrp.CFrame + Vector3.new(0, flySettings.speed / 15, 0) end
        if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then hrp.CFrame = hrp.CFrame + Vector3.new(0, -flySettings.speed / 15, 0) end
    end)
end
local function StopFly()
    flySettings.flyActive = false; if flySettings.incore then flySettings.incore:Disconnect(); flySettings.incore = nil end
    if lp.Character and lp.Character:FindFirstChild("Humanoid") then lp.Character.Humanoid.PlatformStand = false end
end
local function StartNoClip()
    if flySettings.nocore then flySettings.nocore:Disconnect() end
    flySettings.nocore = RunService.Stepped:Connect(function()
        if lp.Character then for _, p in pairs(lp.Character:GetDescendants()) do if p:IsA("BasePart") then p.CanCollide = false end end end
    end)
end
local function StopNoClip()
    if flySettings.nocore then flySettings.nocore:Disconnect(); flySettings.nocore = nil end
end

-- ==================== SPEED HACK LOGIC ====================
local function applySpeedHack()
    local char = lp.Character; local hrp = char and char:FindFirstChild("HumanoidRootPart"); local hum = char and char:FindFirstChildOfClass("Humanoid")
    if not hrp or not hum then return end
    local moveDir = hum.MoveDirection
    if speedSettings.mode == "WalkSpeed" then
        hum.WalkSpeed = speedSettings.speedValue
    elseif speedSettings.mode == "CFrame" and moveDir.Magnitude > 0 then
        hrp.CFrame = hrp.CFrame + (moveDir * (speedSettings.speedValue / 100))
    elseif speedSettings.mode == "Velocity" and moveDir.Magnitude > 0 then
        hrp.Velocity = Vector3.new(moveDir.X * speedSettings.speedValue, hrp.Velocity.Y, moveDir.Z * speedSettings.speedValue)
    elseif speedSettings.mode == "TP-Flash" and moveDir.Magnitude > 0 then
        hrp.CFrame = hrp.CFrame * CFrame.new(0, 0, -speedSettings.speedValue / 50)
    elseif speedSettings.mode == "AnimSpeed" then
        hum.WalkSpeed = speedSettings.speedValue
        for _, track in pairs(hum:GetPlayingAnimationTracks()) do track:AdjustSpeed(speedSettings.speedValue / 16) end
    end
end

local function StartSpeedHack()
    speedSettings.speedActive = true
end
local function StopSpeedHack()
    speedSettings.speedActive = false
    if lp.Character and lp.Character:FindFirstChildOfClass("Humanoid") then lp.Character.Humanoid.WalkSpeed = 16 end
end

RunService.Heartbeat:Connect(function()
    if not speedSettings.speedActive then return end
    applySpeedHack()
end)

-- ==================== SUPER JUMP ====================
local function applySuperJumpV1()
    local char = lp.Character
    if not char then return end
    local hum = char:FindFirstChildOfClass("Humanoid")
    if hum then
        hum.UseJumpPower = true
        hum.JumpPower = superJumpPower
    end
end

local function resetSuperJumpToNormal()
    local char = lp.Character
    if not char then return end
    local hum = char:FindFirstChildOfClass("Humanoid")
    if hum then
        hum.JumpPower = normalJumpPower
    end
end

local function createSuperJumpButton()
    if superJumpButton then return end
    local gui = Instance.new("ScreenGui", game:GetService("CoreGui"))
    gui.Name = "SuperJumpBtn"
    local btn = Instance.new("TextButton", gui)
    btn.Size = UDim2.new(0, 120, 0, 50)
    btn.Position = UDim2.new(0.05, 0, 0.8, 0)
    btn.BackgroundColor3 = Color3.fromRGB(200, 70, 30)
    btn.TextColor3 = Color3.new(1,1,1)
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 15
    btn.Text = "ð SUPER JUMP"
    btn.BorderSizePixel = 0
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 10)

    btn.MouseButton1Click:Connect(function()
        local char = lp.Character
        local hrp = char and char:FindFirstChild("HumanoidRootPart")
        if hrp then
            if damageDetected then return end
            hrp.Velocity = Vector3.new(hrp.Velocity.X, superJumpPower, hrp.Velocity.Z)
        end
    end)

    local dragging, dragStart, startPos
    btn.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
            dragging = true; dragStart = i.Position; startPos = btn.AbsolutePosition
        end
    end)
    UserInputService.InputChanged:Connect(function(i)
        if dragging and (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch) then
            local delta = i.Position - dragStart
            local vp = workspace.CurrentCamera.ViewportSize
            btn.Position = UDim2.new(0, math.clamp(startPos.X + delta.X, 0, vp.X - btn.AbsoluteSize.X), 0, math.clamp(startPos.Y + delta.Y, 0, vp.Y - btn.AbsoluteSize.Y))
        end
    end)
    UserInputService.InputEnded:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then dragging = false end
    end)

    superJumpButton = gui
end

local function destroySuperJumpButton()
    if superJumpButton then superJumpButton:Destroy(); superJumpButton = nil end
end

local function updateSuperJumpState()
    if not superJumpEnabled then
        resetSuperJumpToNormal()
        if superJumpButton then destroySuperJumpButton() end
        return
    end

    if superJumpMode == "V1" then
        if superJumpButton then destroySuperJumpButton() end
        applySuperJumpV1()
    elseif superJumpMode == "V2" then
        resetSuperJumpToNormal()
        createSuperJumpButton()
    elseif superJumpMode == "V3" then
        resetSuperJumpToNormal()
        if superJumpButton then destroySuperJumpButton() end
    end
end

RunService.Heartbeat:Connect(function()
    if superJumpEnabled and superJumpMode == "V1" and lp.Character then
        local hum = lp.Character:FindFirstChildOfClass("Humanoid")
        if hum then hum.JumpPower = (damageDetected or isBunnyHopping) and normalJumpPower or superJumpPower end
    end
end)

-- ==================== CORRECTION SUPER JUMP V3 ====================
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if superJumpEnabled and superJumpMode == "V3" and input.KeyCode == Enum.KeyCode.Space then
        local char = lp.Character
        if not char then return end
        local hum = char:FindFirstChildOfClass("Humanoid")
        local hrp = char:FindFirstChild("HumanoidRootPart")
        if not hum or not hrp then return end
        
        -- DÃ©tection du sol robuste par Raycast (fallback si FloorMaterial bugue)
        local onGround = false
        if hum.FloorMaterial ~= Enum.Material.Air then
            onGround = true
        else
            local raycastParams = RaycastParams.new()
            raycastParams.FilterDescendantsInstances = {char}
            raycastParams.FilterType = Enum.RaycastFilterType.Exclude
            local ray = workspace:Raycast(hrp.Position, Vector3.new(0, -4.5, 0), raycastParams)
            if ray then
                onGround = true
            end
        end
        
        if not onGround then return end
        if damageDetected then return end
        
        local originalJumpPower = hum.JumpPower
        hum.JumpPower = superJumpPower
        hum:Jump()
        task.delay(0.1, function()
            if hum then hum.JumpPower = originalJumpPower end
        end)
    end
end)

-- ==================== MINI TOGGLES ====================
local function CreateFlyMiniToggle()
    if flyMiniGui then return end
    local screenGui = Instance.new("ScreenGui"); screenGui.Name = "FlyMiniToggle"; screenGui.ResetOnSpawn = false; screenGui.Parent = game:GetService("CoreGui")
    flyMiniGui = screenGui
    local button = Instance.new("TextButton", screenGui)
    button.Size = UDim2.new(0, 80, 0, 40); button.Position = UDim2.new(0, 10, 0.5, -20); button.Text = "FLY: ON"; button.TextScaled = true
    button.BackgroundColor3 = Color3.fromRGB(30, 30, 30); button.TextColor3 = Color3.fromRGB(255, 255, 255); button.BorderSizePixel = 0
    Instance.new("UICorner", button).CornerRadius = UDim.new(0, 8)
    local gradient = Instance.new("UIGradient", button); gradient.Rotation = 45
    local function updateButton(state)
        button.Text = "FLY: "..(state and "ON" or "OFF")
        gradient.Color = ColorSequence.new{
            ColorSequenceKeypoint.new(0, state and Color3.fromRGB(50,200,50) or Color3.fromRGB(80,80,80)),
            ColorSequenceKeypoint.new(1, state and Color3.fromRGB(50,255,50) or Color3.fromRGB(50,50,50))
        }
    end
    local function onButtonClick()
        local newState = not flySettings.flyActive
        if newState then StartFly() else StopFly() end
        updateButton(newState)
        local toggle = Library.Options and Library.Options.FlyToggle
        if toggle then toggle:SetValue(newState) end
    end
    button.MouseButton1Click:Connect(onButtonClick)
    flyMiniButton = button
    local dragging, dragStart, startPos
    button.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true; dragStart = input.Position; startPos = button.AbsolutePosition
        end
    end)
    flyDragConn = UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseMovement) then
            local delta = input.Position - dragStart; local vp = camera.ViewportSize
            button.Position = UDim2.new(0, math.clamp(startPos.X + delta.X, 0, vp.X - button.AbsoluteSize.X), 0, math.clamp(startPos.Y + delta.Y, 0, vp.Y - button.AbsoluteSize.Y))
        end
    end)
    flyEndConn = UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = false
        end
    end)
end
local function DestroyFlyMiniToggle()
    if flyDragConn then flyDragConn:Disconnect(); flyDragConn = nil end
    if flyEndConn then flyEndConn:Disconnect(); flyEndConn = nil end
    if flyMiniGui then flyMiniGui:Destroy(); flyMiniGui = nil; flyMiniButton = nil end
end

local function CreateSpeedMiniToggle()
    if speedMiniGui then return end
    local screenGui = Instance.new("ScreenGui"); screenGui.Name = "SpeedMiniToggle"; screenGui.ResetOnSpawn = false; screenGui.Parent = game:GetService("CoreGui")
    speedMiniGui = screenGui
    local button = Instance.new("TextButton", screenGui)
    button.Size = UDim2.new(0, 80, 0, 40); button.Position = UDim2.new(0, 10, 0.5, 30); button.Text = "SPEED: ON"; button.TextScaled = true
    button.BackgroundColor3 = Color3.fromRGB(30, 30, 30); button.TextColor3 = Color3.fromRGB(255, 255, 255); button.BorderSizePixel = 0
    Instance.new("UICorner", button).CornerRadius = UDim.new(0, 8)
    local gradient = Instance.new("UIGradient", button); gradient.Rotation = 45
    local function updateButton(state)
        button.Text = "SPEED: "..(state and "ON" or "OFF")
        gradient.Color = ColorSequence.new{
            ColorSequenceKeypoint.new(0, state and Color3.fromRGB(50,200,50) or Color3.fromRGB(80,80,80)),
            ColorSequenceKeypoint.new(1, state and Color3.fromRGB(50,255,50) or Color3.fromRGB(50,50,50))
        }
    end
    local function onButtonClick()
        local newState = not speedSettings.speedActive
        if newState then StartSpeedHack() else StopSpeedHack() end
        updateButton(newState)
        local toggle = Library.Options and Library.Options.SpeedHackToggle
        if toggle then toggle:SetValue(newState) end
    end
    button.MouseButton1Click:Connect(onButtonClick)
    speedMiniButton = button
    local dragging, dragStart, startPos
    button.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true; dragStart = input.Position; startPos = button.AbsolutePosition
        end
    end)
    speedDragConn = UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseMovement) then
            local delta = input.Position - dragStart; local vp = camera.ViewportSize
            button.Position = UDim2.new(0, math.clamp(startPos.X + delta.X, 0, vp.X - button.AbsoluteSize.X), 0, math.clamp(startPos.Y + delta.Y, 0, vp.Y - button.AbsoluteSize.Y))
        end
    end)
    speedEndConn = UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = false
        end
    end)
end
local function DestroySpeedMiniToggle()
    if speedDragConn then speedDragConn:Disconnect(); speedDragConn = nil end
    if speedEndConn then speedEndConn:Disconnect(); speedEndConn = nil end
    if speedMiniGui then speedMiniGui:Destroy(); speedMiniGui = nil; speedMiniButton = nil end
end

-- ==================== DASH GLITCH (Skull Guitar) â V1 & V2 uniquement ====================
local DashGlitch = (function()
    local module = {}
    local enabled = false
    local version = "V1"
    local cooldown = 1.5
    local dashLength = 190
    local speedBoost = 350
    local airWalkSpeed = 400

    local tapButton = nil
    local tapGui = nil
    local v1Active = false
    local v2Trigger = false

    local autoLoop = nil

    local args = {
        "TAP",
        Vector3.new(-1221.487548828125, 69.36107635498047, -566.5001220703125)
    }

    local function createTapButton()
        if tapGui then return end
        local gui = Instance.new("ScreenGui")
        gui.Name = "DashGlitchTap"
        gui.ResetOnSpawn = false
        gui.Parent = game:GetService("CoreGui")
        tapGui = gui

        local btn = Instance.new("TextButton", gui)
        btn.Size = UDim2.new(0, 50, 0, 30)
        btn.Position = UDim2.new(0.02, 0, 0.45, 0)
        btn.BackgroundColor3 = Color3.fromRGB(50, 100, 200)
        btn.TextColor3 = Color3.fromRGB(255,255,255)
        btn.Text = (version == "V1") and "DASH: OFF" or "TAP"
        btn.Font = Enum.Font.GothamBold
        btn.TextSize = 9
        btn.BorderSizePixel = 0
        Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6)
        
        local dragging, dragStart, startPos
        btn.InputBegan:Connect(function(i)
            if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
                dragging = true; dragStart = i.Position; startPos = btn.AbsolutePosition
            end
        end)
        UserInputService.InputChanged:Connect(function(i)
            if dragging and (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch) then
                local delta = i.Position - dragStart
                local vp = camera.ViewportSize
                btn.Position = UDim2.new(0, math.clamp(startPos.X + delta.X, 0, vp.X - btn.AbsoluteSize.X), 0, math.clamp(startPos.Y + delta.Y, 0, vp.Y - btn.AbsoluteSize.Y))
            end
        end)
        UserInputService.InputEnded:Connect(function(i)
            if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
                dragging = false
            end
        end)
        
        btn.MouseButton1Click:Connect(function()
            if version == "V2" then
                v2Trigger = true
            elseif version == "V1" then
                v1Active = not v1Active
                btn.Text = "DASH: " .. (v1Active and "ON" or "OFF")
                btn.BackgroundColor3 = v1Active and Color3.fromRGB(0, 200, 100) or Color3.fromRGB(200, 70, 30)
            end
        end)
        tapButton = btn
    end

    local function destroyTapButton()
        if tapGui then tapGui:Destroy(); tapGui = nil; tapButton = nil end
    end

    local function doDashCombo()
        local char = lp.Character
        if not char then return end
        local hrp = char:FindFirstChild("HumanoidRootPart")
        local hum = char:FindFirstChildOfClass("Humanoid")
        local tool = char:FindFirstChildOfClass("Tool")
        if not tool or tool.Name ~= "Skull Guitar" or not hrp or not hum then return end
        local remote = tool:FindFirstChild("RemoteEvent")
        if not remote then return end

        hum.PlatformStand = true
        hum:ChangeState(Enum.HumanoidStateType.Physics)
        remote:FireServer(unpack(args))

        char:SetAttribute("DashLength", dashLength)
        char:SetAttribute("DashLengthAir", dashLength)
        hrp.AssemblyLinearVelocity = hrp.CFrame.LookVector * speedBoost

        task.delay(0.2, function()
            if char then
                char:SetAttribute("DashLength", 1)
                char:SetAttribute("DashLengthAir", 1)
            end
        end)
        task.wait(0.25)
        hum.PlatformStand = false
        hum:ChangeState(Enum.HumanoidStateType.GettingUp)
    end

    local function startAuto()
        if autoLoop then return end
        autoLoop = task.spawn(function()
            while enabled and (version == "V1") do
                if v1Active then
                    local char = lp.Character
                    local tool = char and char:FindFirstChildOfClass("Tool")
                    if tool and tool.Name == "Skull Guitar" then
                        doDashCombo()
                    end
                end
                task.wait(cooldown)
            end
        end)
    end

    local function stopAuto()
        if autoLoop then task.cancel(autoLoop); autoLoop = nil end
        local char = lp.Character
        if char then
            char:SetAttribute("DashLength", 1)
            char:SetAttribute("DashLengthAir", 1)
            local hum = char:FindFirstChildOfClass("Humanoid")
            if hum then hum.PlatformStand = false; hum.WalkSpeed = 16 end
        end
    end

    local function v2Watch()
        task.spawn(function()
            while enabled and version == "V2" do
                if v2Trigger then
                    v2Trigger = false
                    doDashCombo()
                end
                task.wait(0.05)
            end
        end)
    end

    function module:SetEnabled(state)
        if state == enabled then return end
        enabled = state
        if state then
            if version == "V1" then
                v1Active = false
                createTapButton()
                startAuto()
            elseif version == "V2" then
                createTapButton()
                v2Watch()
            end
        else
            stopAuto()
            destroyTapButton()
            v2Trigger = false
            v1Active = false
        end
    end

    function module:SetVersion(v)
        if v == version then return end
        local wasEnabled = enabled
        if wasEnabled then module:SetEnabled(false) end
        version = v
        if wasEnabled then module:SetEnabled(true) end
    end

    function module:SetCooldown(v) cooldown = v end
    function module:SetDashLength(v) dashLength = v end
    function module:SetSpeedBoost(v) speedBoost = v end
    function module:SetAirWalkSpeed(v) airWalkSpeed = v end

    RunService.Stepped:Connect(function()
        if not enabled or version ~= "V1" then return end
        local char = lp.Character
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        local tool = char and char:FindFirstChildOfClass("Tool")
        if hum and tool and tool.Name == "Skull Guitar" then
            if hum.FloorMaterial == Enum.Material.Air then
                hum.WalkSpeed = airWalkSpeed
            else
                hum.WalkSpeed = 16
                hum.PlatformStand = false
            end
        elseif hum then
            hum.WalkSpeed = 16
            hum.PlatformStand = false
        end
    end)

    return module
end)()

-- ==================== MISC FEATURES ====================
local fontChangerEnabled = false
local fontPreset = "GothamSsm"
local updatedFonts = {}
local fontConn = nil

local antiMoverEnabled = false
local antiMoverConnection = nil

local unbreakableEnabled = false
local unbreakableConnection = nil

local function enableFonts()
    if fontConn then fontConn:Disconnect() end
    fontConn = RunService.Heartbeat:Connect(function()
        local guiList = { lp:FindFirstChild("PlayerGui"), game:GetService("CoreGui") }
        for _, gui in pairs(guiList) do
            if gui then
                for _, obj in pairs(gui:GetDescendants()) do
                    if obj:IsA("TextLabel") or obj:IsA("TextButton") or obj:IsA("TextBox") then
                        if obj.Font ~= Enum.Font[fontPreset] then
                            obj.Font = Enum.Font[fontPreset]
                            table.insert(updatedFonts, obj)
                        end
                    end
                end
            end
        end
    end)
end

local function disableFonts()
    if fontConn then fontConn:Disconnect(); fontConn = nil end
    for _, obj in pairs(updatedFonts) do pcall(function() obj.Font = Enum.Font.SourceSans end) end
    updatedFonts = {}
end

local function loadCustomFont(fileName)
    if fileName == "None" then return end
end

-- ==================== NO GFX MODULE ====================
local noGfxMode = "Off"
local noGfxConnections = {}
local noGfxModifiedObjects = {}
local hotbarIconsOriginals = {}

local function restoreNoGfx()
    for obj, data in pairs(noGfxModifiedObjects) do
        pcall(function()
            if data.Texture ~= nil then obj.Texture = data.Texture end
            if data.Enabled ~= nil then obj.Enabled = data.Enabled end
        end)
    end
    noGfxModifiedObjects = {}
    for iconLabel, oldImage in pairs(hotbarIconsOriginals) do
        pcall(function() iconLabel.Image = oldImage or "" end)
    end
    hotbarIconsOriginals = {}
    if noGfxConnections.DescendantAdded then noGfxConnections.DescendantAdded:Disconnect(); noGfxConnections.DescendantAdded = nil end
    if noGfxConnections.HotbarChildAdded then noGfxConnections.HotbarChildAdded:Disconnect(); noGfxConnections.HotbarChildAdded = nil end
end

local function processObject(inst)
    local className = inst.ClassName
    if className == "Beam" or className == "Trail" then
        if not noGfxModifiedObjects[inst] then
            noGfxModifiedObjects[inst] = {Texture = inst.Texture}
            inst.Texture = "rbxassetid://84308155859778"
        end
    elseif className == "ParticleEmitter" then
        if not noGfxModifiedObjects[inst] then
            noGfxModifiedObjects[inst] = {Texture = inst.Texture, Enabled = inst.Enabled}
            inst.Texture = ""
            inst.Enabled = false
        end
    end
end

local function startNoGfxV1()
    restoreNoGfx()
    task.spawn(function()
        local descendants = workspace:GetDescendants()
        for i = 1, #descendants do
            local inst = descendants[i]
            if not inst:IsA("Terrain") and not inst:IsA("Camera") then processObject(inst) end
            if i % 100 == 0 then RunService.Heartbeat:Wait() end
        end
    end)
    noGfxConnections.DescendantAdded = workspace.DescendantAdded:Connect(processObject)
end

local function startNoGfxV2()
    restoreNoGfx()
    task.spawn(function()
        local descendants = workspace:GetDescendants()
        for i = 1, #descendants do
            local inst = descendants[i]
            if not inst:IsA("Terrain") and not inst:IsA("Camera") then processObject(inst) end
            if i % 100 == 0 then RunService.Heartbeat:Wait() end
        end
    end)
    noGfxConnections.DescendantAdded = workspace.DescendantAdded:Connect(processObject)
    task.spawn(function()
        local PlayerGui = lp:WaitForChild("PlayerGui")
        local Backpack = PlayerGui:WaitForChild("Backpack")
        local HotbarContainer = Backpack:WaitForChild("Hotbar"):WaitForChild("Container")
        local function updateHotbarIconSilent()
            for _, slot in ipairs(HotbarContainer:GetChildren()) do
                local iconLabel = slot:FindFirstChild("Icon") or slot:FindFirstChild("Image") or slot:FindFirstChildOfClass("ImageLabel")
                if iconLabel and iconLabel:IsA("ImageLabel") then
                    if not hotbarIconsOriginals[iconLabel] then hotbarIconsOriginals[iconLabel] = iconLabel.Image end
                    iconLabel.Image = "rbxassetid://84308155859778"
                    iconLabel.ImageColor3 = Color3.fromRGB(255,255,255)
                end
            end
        end
        updateHotbarIconSilent()
        noGfxConnections.HotbarChildAdded = HotbarContainer.ChildAdded:Connect(function() task.defer(updateHotbarIconSilent) end)
    end)
end

local function stopNoGfx() restoreNoGfx() end

local function setNoGfxMode(mode)
    if mode == noGfxMode then return end
    noGfxMode = mode
    stopNoGfx()
    if mode == "V1" then startNoGfxV1() elseif mode == "V2" then startNoGfxV2() end
end

-- ==================== DELETE SHIP MODULE ====================
local deleteShipActive = false
local deleteShipRunning = false

local function deleteShipStructure()
    if not deleteShipActive then return end
    task.spawn(function()
        local shipNames = {"CursedShip", "Cursed Ship", "Ship"}
        local exteriorNames = {"Wall", "Floor", "Ceiling", "Base", "Hull", "Window", "DoorFrame"}
        for _, obj in pairs(workspace:GetDescendants()) do
            for _, sName in ipairs(shipNames) do
                if obj.Name:find(sName) and (obj:IsA("Model") or obj:IsA("Folder")) then
                    for _, child in pairs(obj:GetDescendants()) do
                        if child:IsA("BasePart") and not child.Parent:FindFirstChild("Humanoid") then
                            local isExterior = false
                            for _, ext in ipairs(exteriorNames) do
                                if child.Name:find(ext) then
                                    isExterior = true
                                    break
                                end
                            end
                            if not isExterior then
                                child:Destroy()
                            end
                        end
                    end
                end
            end
        end
    end)
end

local function startDeleteShipLoop()
    if deleteShipRunning then return end
    deleteShipRunning = true
    task.spawn(function()
        while deleteShipActive do
            deleteShipStructure()
            task.wait(3)
        end
        deleteShipRunning = false
    end)
end

-- ==================== WALK ON WATER MODULE ====================
local WalkOnWaterEnabled = false
local waterPart = nil

task.spawn(function()
    local function getWaterPart()
        if not waterPart or not waterPart.Parent then
            waterPart = Instance.new("Part")
            waterPart.Size = Vector3.new(200, 1, 200)
            waterPart.Transparency = 1
            waterPart.Anchored = true
            waterPart.CanCollide = false
            waterPart.Name = "SacredWaterPlatform"
            waterPart.Parent = workspace
        end
        return waterPart
    end

    while true do
        task.wait(0.15)
        if WalkOnWaterEnabled then
            local hrp = lp.Character and lp.Character:FindFirstChild("HumanoidRootPart")
            local wp = getWaterPart()
            if hrp and hrp.Position.Y >= 9.5 then
                wp.Position = Vector3.new(hrp.Position.X, 9.2, hrp.Position.Z)
                wp.CanCollide = true
            else
                wp.CanCollide = false
            end
        elseif waterPart and waterPart.Parent then
            waterPart.CanCollide = false
        end
    end
end)

-- ==================== ANTI LAVA MODULE ====================
local antiLavaActive = false
local antiLavaConnection = nil

local function startAntiLava()
    if antiLavaConnection then antiLavaConnection:Disconnect() end
    local antiLavaTimer = 0
    antiLavaConnection = RunService.Stepped:Connect(function(_, dt)
        antiLavaTimer = antiLavaTimer + dt
        if antiLavaTimer < 0.2 then return end
        antiLavaTimer = 0
        local char = lp.Character
        if not (char and antiLavaActive) then return end
        for _, part in pairs(char:GetDescendants()) do
            if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart"
                and part.Name ~= "Torso" and part.Name ~= "UpperTorso"
                and part.Name ~= "LowerTorso" and part.Name ~= "Head" then
                part.CanTouch = false
            end
        end
    end)
end

local function stopAntiLava()
    if antiLavaConnection then
        antiLavaConnection:Disconnect()
        antiLavaConnection = nil
    end
end

-- ==================== BIG SKIN BUG MODULE ====================
local bigSkinBugEnabled = false
local bigSkinBugOriginal = {}
local bigSkinBugConnections = {}

local function applyBigSkin(char)
    local data = bigSkinBugOriginal[char]
    if not data then return end
    for item, saved in pairs(data.accessories) do
        item.Parent = nil
    end
    for part, saved in pairs(data.parts) do
        part.Color = Color3.fromRGB(128, 128, 128)
        part.Material = Enum.Material.SmoothPlastic
        part.CanCollide = true
        if part:IsA("MeshPart") then part.TextureID = "" end
        local nameLower = part.Name:lower()
        if nameLower:match("torso") then
            part.Size = Vector3.new(5.6, 4.4, 3.4)
        elseif nameLower:match("leg") or nameLower:match("arm") then
            part.Size = Vector3.new(2.6, 4.8, 2.6)
        elseif nameLower == "head" then
            part.Size = Vector3.new(2.2, 2.2, 2.2)
            local mesh = part:FindFirstChildOfClass("SpecialMesh")
            if mesh then mesh.Parent = nil end
        end
    end
    for joint, saved in pairs(data.joints) do
        local jName = joint.Name:lower()
        local c0 = saved.C0
        if jName:match("rightshoulder") or jName:match("right shoulder") then
            joint.C0 = c0 * CFrame.new(2.4, 0.6, 0)
        elseif jName:match("leftshoulder") or jName:match("left shoulder") then
            joint.C0 = c0 * CFrame.new(-2.4, 0.6, 0)
        elseif jName:match("righthip") or jName:match("right hip") then
            joint.C0 = c0 * CFrame.new(0.9, -0.6, 0)
        elseif jName:match("lefthip") or jName:match("left hip") then
            joint.C0 = c0 * CFrame.new(-0.9, -0.6, 0)
        elseif jName:match("neck") then
            joint.C0 = c0 * CFrame.new(0, 0.8, 0)
        end
    end
end

local function saveBigSkinOriginal(char)
    local data = { parts = {}, accessories = {}, joints = {} }
    for _, item in pairs(char:GetDescendants()) do
        if item:IsA("Accessory") or item:IsA("Clothing") or item:IsA("ShirtGraphic") or item:IsA("Decal") then
            data.accessories[item] = { Parent = item.Parent }
        elseif item:IsA("BasePart") and item.Name ~= "HumanoidRootPart" then
            local saved = { Size = item.Size, Color = item.Color, Material = item.Material, TextureID = item:IsA("MeshPart") and item.TextureID or nil }
            if item.Name == "Head" then
                local mesh = item:FindFirstChildOfClass("SpecialMesh")
                if mesh then saved.MeshParent = mesh.Parent end
            end
            data.parts[item] = saved
        elseif item:IsA("Motor6D") and item.Part0 and item.Part1 then
            data.joints[item] = { C0 = item.C0, C1 = item.C1 }
        end
    end
    bigSkinBugOriginal[char] = data
end

local function restoreBigSkin(char)
    local data = bigSkinBugOriginal[char]
    if not data then return end
    for item, saved in pairs(data.accessories) do
        if saved.Parent then item.Parent = saved.Parent end
    end
    for part, saved in pairs(data.parts) do
        part.Size = saved.Size
        part.Color = saved.Color
        part.Material = saved.Material
        if saved.TextureID and part:IsA("MeshPart") then part.TextureID = saved.TextureID end
        if saved.MeshParent and part.Name == "Head" then
            local mesh = part:FindFirstChildOfClass("SpecialMesh")
            if not mesh and saved.MeshParent ~= part then
                local oldMesh = saved.MeshParent:FindFirstChildOfClass("SpecialMesh")
                if oldMesh then oldMesh.Parent = part end
            end
        end
    end
    for joint, saved in pairs(data.joints) do
        joint.C0 = saved.C0
        joint.C1 = saved.C1
    end
    bigSkinBugOriginal[char] = nil
end

local function onCharAddedBigSkin(char)
    if not bigSkinBugEnabled then return end
    task.wait(0.4)
    saveBigSkinOriginal(char)
    applyBigSkin(char)
end

local function enableBigSkin()
    if bigSkinBugEnabled then return end
    bigSkinBugEnabled = true
    if lp.Character then
        saveBigSkinOriginal(lp.Character)
        applyBigSkin(lp.Character)
    end
    bigSkinBugConnections.CharAdded = lp.CharacterAdded:Connect(onCharAddedBigSkin)
end

local function disableBigSkin()
    bigSkinBugEnabled = false
    if bigSkinBugConnections.CharAdded then
        bigSkinBugConnections.CharAdded:Disconnect()
        bigSkinBugConnections.CharAdded = nil
    end
    if lp.Character then
        restoreBigSkin(lp.Character)
    end
end

-- ==================== ESP MODULE ====================
local ESPModule = (function()
    local module = {}
    local ESPEnabled = false
    local ShowBox, ShowName, ShowDistance, ShowHealth, ShowLine = true, true, true, true, true
    local BoxColor, TextColor, LineColor = "Red", "White", "Red"
    local ShowAllPlayers = false
    local LineOrigin = "Player"
    local drawings = {}
    local function clearDrawings() for _, d in pairs(drawings) do pcall(function() d:Remove() end) end drawings = {} end
    local function getColor(name)
        local colors = { Red=Color3.new(1,0,0), Green=Color3.new(0,1,0), Blue=Color3.new(0,0,1), Yellow=Color3.new(1,1,0), White=Color3.new(1,1,1), Black=Color3.new(0,0,0), Cyan=Color3.new(0,1,1), Magenta=Color3.new(1,0,1) }
        return colors[name] or Color3.new(1,1,1)
    end
    local function isEnemy(plr)
        if plr == lp then return false end
        if ShowAllPlayers then return true end
        local myTeam = lp.Team; local targetTeam = plr.Team
        if myTeam and targetTeam then
            if myTeam.Name=="Pirates" and targetTeam.Name=="Marines" then return true
            elseif myTeam.Name=="Marines" and targetTeam.Name=="Pirates" then return true end
            if myTeam.Name=="Pirates" and targetTeam.Name=="Pirates" then return true end
            if myTeam.Name=="Marines" and targetTeam.Name=="Marines" then return false end
        end
        return true
    end
    local function updateESP()
        clearDrawings()
        if not ESPEnabled then return end
        local myHrp = lp.Character and lp.Character:FindFirstChild("HumanoidRootPart")
        local vp = camera.ViewportSize
        for _, plr in pairs(Players:GetPlayers()) do
            if plr == lp or not plr.Character or not plr.Character:FindFirstChild("HumanoidRootPart") then continue end
            if not isEnemy(plr) then continue end
            local hrp = plr.Character.HumanoidRootPart
            local hum = plr.Character:FindFirstChildOfClass("Humanoid")
            if not hum or hum.Health <= 0 then continue end
            local pos, onScreen = camera:WorldToViewportPoint(hrp.Position)
            local screenPos = Vector2.new(pos.X, pos.Y)
            local isVisible = onScreen
            local lineEnd = screenPos
            if pos.Z < 0 then
                local center = Vector2.new(vp.X/2, vp.Y/2)
                local dirToTarget = (center - screenPos).Unit
                local maxX, maxY = (vp.X/2)-5, (vp.Y/2)-5
                local t = 1
                if math.abs(dirToTarget.X)>0.001 and math.abs(dirToTarget.Y)>0.001 then t = math.min(math.abs(maxX/dirToTarget.X), math.abs(maxY/dirToTarget.Y))
                elseif math.abs(dirToTarget.X)>0.001 then t = math.abs(maxX/dirToTarget.X)
                elseif math.abs(dirToTarget.Y)>0.001 then t = math.abs(maxY/dirToTarget.Y) end
                lineEnd = center + dirToTarget * t
            end
            local boxCol = getColor(BoxColor)
            local txtCol = getColor(TextColor)
            local lineCol = getColor(LineColor)
            if ShowBox and isVisible then
                local size = Vector2.new(2000/(camera.CFrame.Position-hrp.Position).Magnitude, 4000/(camera.CFrame.Position-hrp.Position).Magnitude)
                local topLeft = Vector2.new(pos.X-size.X/2, pos.Y-size.Y/2)
                local topRight = Vector2.new(pos.X+size.X/2, pos.Y-size.Y/2)
                local bottomLeft = Vector2.new(pos.X-size.X/2, pos.Y+size.Y/2)
                local bottomRight = Vector2.new(pos.X+size.X/2, pos.Y+size.Y/2)
                local function addLine(p1,p2) local l=Drawing.new("Line"); l.Visible=true; l.Color=boxCol; l.Thickness=1; l.From=p1; l.To=p2; table.insert(drawings,l) end
                addLine(topLeft, topRight); addLine(topRight, bottomRight); addLine(bottomRight, bottomLeft); addLine(bottomLeft, topLeft)
            end
            if ShowName and isVisible then
                local size = Vector2.new(2000/(camera.CFrame.Position-hrp.Position).Magnitude, 4000/(camera.CFrame.Position-hrp.Position).Magnitude)
                local t = Drawing.new("Text"); t.Visible=true; t.Text=plr.Name; t.Color=txtCol; t.Size=13; t.Center=true; t.Position=Vector2.new(pos.X, pos.Y-size.Y/2-15); t.Font=2; table.insert(drawings,t)
            end
            if ShowDistance and isVisible then
                local dist = math.floor((hrp.Position-(myHrp and myHrp.Position or Vector3.zero)).Magnitude)
                local t = Drawing.new("Text"); t.Visible=true; t.Text=dist.."m"; t.Color=txtCol; t.Size=13; t.Center=true; t.Position=Vector2.new(pos.X, pos.Y+size.Y/2+2); t.Font=2; table.insert(drawings,t)
            end
            if ShowHealth and isVisible then
                local size = Vector2.new(2000/(camera.CFrame.Position-hrp.Position).Magnitude, 4000/(camera.CFrame.Position-hrp.Position).Magnitude)
                local hpRatio = math.clamp(hum.Health/hum.MaxHealth,0,1)
                local barW, barH = size.X, 4
                local barPos = Vector2.new(pos.X-barW/2, pos.Y+size.Y/2+12)
                local bg = Drawing.new("Square"); bg.Visible=true; bg.Color=Color3.new(0,0,0); bg.Filled=true; bg.Size=Vector2.new(barW,barH); bg.Position=barPos; table.insert(drawings,bg)
                local fg = Drawing.new("Square"); fg.Visible=true; fg.Color=Color3.new(1-hpRatio, hpRatio, 0); fg.Filled=true; fg.Size=Vector2.new(barW*hpRatio,barH); fg.Position=barPos; table.insert(drawings,fg)
            end
            if ShowLine then
                local lineStart = nil
                if LineOrigin == "Player" then
                    if myHrp then
                        local myPos, onScr = camera:WorldToViewportPoint(myHrp.Position)
                        if onScr then lineStart = Vector2.new(myPos.X, myPos.Y) else lineStart = Vector2.new(vp.X/2, vp.Y/2) end
                    else lineStart = Vector2.new(vp.X/2, vp.Y/2) end
                elseif LineOrigin == "Center" then lineStart = Vector2.new(vp.X/2, vp.Y/2)
                elseif LineOrigin == "Top" then lineStart = Vector2.new(vp.X/2, 0) end
                if lineStart then
                    local l = Drawing.new("Line"); l.Visible=true; l.Color=lineCol; l.Thickness=1; l.From=lineStart; l.To=lineEnd; table.insert(drawings,l)
                end
            end
        end
    end
    local espConnection
    function module:SetESPEnabled(state) ESPEnabled=state; if state then if espConnection then espConnection:Disconnect() end espConnection=RunService.RenderStepped:Connect(updateESP) else if espConnection then espConnection:Disconnect(); espConnection=nil end clearDrawings() end end
    function module:SetShowBox(v) ShowBox=v end
    function module:SetShowName(v) ShowName=v end
    function module:SetShowDistance(v) ShowDistance=v end
    function module:SetShowHealth(v) ShowHealth=v end
    function module:SetShowLine(v) ShowLine=v end
    function module:SetBoxColor(c) BoxColor=c end
    function module:SetTextColor(c) TextColor=c end
    function module:SetLineColor(c) LineColor=c end
    function module:SetShowAllPlayers(v) ShowAllPlayers=v end
    function module:SetLineOrigin(v) LineOrigin=v end
    return module
end)()

-- ==================== M1 EXTENDER ====================
local M1Extender = (function()
    local M = {}; local active = false; local maxRange = 100
    local Net = RS:WaitForChild("Modules"):WaitForChild("Net")
    local RegisterHit = Net["RE/RegisterHit"]; local RegisterAttack = Net["RE/RegisterAttack"]
    local function getTarget()
        local myChar = lp.Character; local myRoot = myChar and myChar:FindFirstChild("HumanoidRootPart")
        if not myRoot then return nil end
        local target, shortestDist = nil, maxRange
        for _, folder in pairs({workspace:FindFirstChild("Enemies"), workspace:FindFirstChild("Characters")}) do
            if folder then for _, v in pairs(folder:GetChildren()) do
                local eRoot = v:FindFirstChild("HumanoidRootPart"); local eHum = v:FindFirstChildOfClass("Humanoid")
                if v ~= myChar and eRoot and eHum and eHum.Health > 0 then
                    local dist = (eRoot.Position - myRoot.Position).Magnitude
                    if dist < shortestDist then shortestDist = dist; target = v end
                end
            end end
        end
        return target
    end
    UserInputService.InputBegan:Connect(function(input, processed)
        if processed or not active then return end
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            local target = getTarget()
            local tool = lp.Character and lp.Character:FindFirstChildOfClass("Tool")
            if target and tool then
                local head = target:FindFirstChild("Head") or target:FindFirstChild("HumanoidRootPart")
                if head then
                    local sessionId = tostring(lp.UserId):sub(2,4) .. tostring(coroutine.running()):sub(11,15)
                    pcall(function()
                        RegisterAttack:FireServer()
                        local hitData = {}
                        for _, part in pairs(target:GetChildren()) do if part:IsA("BasePart") then table.insert(hitData, {target, part}) end end
                        RegisterHit:FireServer(head, hitData, {}, sessionId)
                    end)
                end
            end
        end
    end)
    function M:Toggle(v) active = v end
    function M:SetRange(v) maxRange = v end
    return M
end)()

-- ==================== GUN CLICK SL MODULE ====================
local GunClickSL = (function()
    local enabled = false
    local aimPos = nil
    local hookInstalled = false

    local function getClosestTarget()
        local char = lp.Character
        if not char then return nil end
        local root = char:FindFirstChild("HumanoidRootPart")
        if not root then return nil end
        local closest, dist = nil, math.huge
        local myPos = root.Position
        for _, player in ipairs(Players:GetPlayers()) do
            if player ~= lp and player.Character then
                local entity = player.Character
                local targetPart = entity:FindFirstChild("HumanoidRootPart")
                if targetPart then
                    local hum = entity:FindFirstChildOfClass("Humanoid")
                    if not hum or hum.Health > 0 then
                        local d = (targetPart.Position - myPos).Magnitude
                        if d < dist then
                            dist = d
                            closest = targetPart
                        end
                    end
                end
            end
        end
        return closest
    end

    local function installHook()
        if hookInstalled then return end
        hookInstalled = true
        local mt = getrawmetatable(game)
        local oldNamecall = mt.__namecall
        setreadonly(mt, false)
        mt.__namecall = newcclosure(function(self, ...)
            local args = {...}
            local method = getnamecallmethod()
            if enabled and aimPos and method == "FireServer" then
                local remoteName = tostring(self.Name or self)
                if remoteName:find("ShootGunEvent") then
                    if typeof(args[1]) == "Vector3" then
                        args[1] = aimPos.Position
                    end
                    if typeof(args[2]) == "table" then
                        args[2] = { [1] = aimPos }
                    end
                end
            end
            return oldNamecall(self, unpack(args))
        end)
        setreadonly(mt, true)
    end

    local function startLoop()
        task.spawn(function()
            while enabled do
                aimPos = getClosestTarget()
                task.wait(0.05)
            end
        end)
    end

    local M = {}
    function M:SetEnabled(state)
        if state == enabled then return end
        enabled = state
        if state then
            aimPos = nil
            installHook()
            startLoop()
        else
            aimPos = nil
        end
    end
    return M
end)()

-- ==================== SILENT AIM MODULE (prÃ©diction fixe + override Melee & Sword ====================
SilentAimModule = (function()
    local module = {}
    local Players = game:GetService("Players")
    local player = Players.LocalPlayer
    local UserInputService = game:GetService("UserInputService")
    local RunService = game:GetService("RunService")
    local CoreGui = game:GetService("CoreGui")
    local camera = workspace.CurrentCamera
    local RS = game:GetService("ReplicatedStorage")
    local commE = RS:WaitForChild("Remotes"):WaitForChild("CommE")
    local MouseModule = RS:FindFirstChild("Mouse")
    local Mouse = nil
    if MouseModule and typeof(MouseModule) == "Instance" then
        local ok, res = pcall(require, MouseModule)
        if ok and type(res) == "table" then Mouse = res end
    end

    -- FIXES : pas de toggle dans l'UI, tout est verrouillÃ© en interne
    local SilentAimPlayersEnabled = false
    local SilentAimNPCsEnabled = false
    local PredictionEnabled = true       -- activÃ© par dÃ©faut
    local PredictionAmount = 0.12        -- valeur fixe
    local ZSkillorM1 = true
    local ShowFOVCircle = false; local FOVRadius = 100; local FOVMode = "V1"; local AimMode = "360"; local TargetPriority = "Nearest"
    local SoruAutoAimEnabled = false; local SoruAutoAimRange = 300; local SoruTargetingMode = "360"; local SoruFOVType = "V1"; local SoruFOVRadius = 100; local SoruTargetPriority = "Nearest"; local SoruShowFOVCircle = false; local SoruCurrentTarget = nil
    local SoruPredictionEnabled = true; local SoruPredictionAmount = 0.12; local SoruStickyTarget = true; local SoruWallCheck = false; local SoruTargetPart = "HumanoidRootPart"; local SoruUpdateRate = 0.08
    local TracerEnabled = false; local TracerColor = "Red"; local tracerModel, tracerAttachment0, tracerAttachment1, tracerBeam = nil, nil, nil, nil
    local renderConnection, heartbeatConnection = nil, nil
    local currentTool, currentToolCategory = nil, "Melee"
    local PlayersPosition, NPCPosition = nil, nil
    local Selectedplayer = nil
    local characterConnections = {}
    local Skills = {"X"}; local Booms = {}; local maxRange = 1000
    local BlacklistedKeys = {
        Melee = { Z=false, X=false, C=false },
        Sword = { Z=false, X=false },
        Fruit = { Z=false, X=false, C=false, V=false, F=false, TAP=false },
        Gun   = { Z=false, X=false }
    }
    local currentSkillKey = nil; local SKILL_KEYS = {"Z","X","C","V","F","TAP"}
    local lastSkillTime = 0

    -- ==================== OVERRIDE MELEE & SWORD (Yama incluse) ====================
    local OverrideGodhumanSanguineEnabled = true  -- toujours activÃ© en arriÃ¨re-plan

    -- Fonction Ã©largie : accepte Godhuman, Sanguine, et toutes les Ã©pÃ©es (dont Yama)
    local function isOverrideTool(tool)
        if not tool then return false end
        local name = string.lower(tool.Name)
        -- On accepte Godhuman, Sanguine, et toutes les Ã©pÃ©es (catÃ©gorie Sword)
        if name == "godhuman" or string.find(name, "sanguine") then
            return true
        end
        -- On vÃ©rifie la catÃ©gorie via getToolCategory (qui sera dÃ©finie plus tard)
        -- Mais getToolCategory est dÃ©finie plus bas, donc on va utiliser une approche directe :
        if currentToolCategory == "Sword" then
            return true
        end
        -- Sinon, on vÃ©rifie si le nom contient "yama" (pour Ãªtre sÃ»r)
        if string.find(name, "yama") then
            return true
        end
        return false
    end

    -- ==================== ROTATION VERS LA CIBLE ====================
    local function faceTarget(targetPos)
        if not targetPos then return end
        local char = player.Character
        if not char then return end
        local hrp = char:FindFirstChild("HumanoidRootPart")
        if not hrp then return end

        local currentPos = hrp.Position
        local lookVector = (Vector3.new(targetPos.X, currentPos.Y, targetPos.Z) - currentPos).Unit
        if lookVector.Magnitude < 0.001 then return end

        local newCFrame = CFrame.lookAt(currentPos, currentPos + lookVector, Vector3.new(0, 1, 0))
        hrp.CFrame = newCFrame

        local hum = char:FindFirstChildOfClass("Humanoid")
        if hum then hum.AutoRotate = true end
    end

    local function setCurrentSkillKey(key)
        currentSkillKey = key
        lastSkillTime = os.clock()

        if SilentAimPlayersEnabled or SilentAimNPCsEnabled then
            local targetPos = PlayersPosition or NPCPosition
            if targetPos then
                task.spawn(function() faceTarget(targetPos) end)
            end
        end

        task.spawn(function()
            local myTime = lastSkillTime
            task.wait(1.5)
            if lastSkillTime == myTime and currentSkillKey == key then
                currentSkillKey = nil
            end
        end)
    end

    local ScreenGui = Instance.new("ScreenGui"); ScreenGui.Name="FOV_System_Linoria"; ScreenGui.ResetOnSpawn=false; ScreenGui.IgnoreGuiInset=true
    if syn and syn.protect_gui then syn.protect_gui(ScreenGui); ScreenGui.Parent=CoreGui elseif getgui then ScreenGui.Parent=getgui() else ScreenGui.Parent=CoreGui or player:WaitForChild("PlayerGui") end
    local FOVFrame = Instance.new("Frame"); FOVFrame.Name="FOVCircle"; FOVFrame.AnchorPoint=Vector2.new(0.5,0.5); FOVFrame.BackgroundTransparency=1; FOVFrame.Visible=false; FOVFrame.Parent=ScreenGui
    local UIStroke = Instance.new("UIStroke"); UIStroke.Color=Color3.fromRGB(255,0,0); UIStroke.Thickness=2; UIStroke.Parent=FOVFrame
    local FOVCorner = Instance.new("UICorner"); FOVCorner.CornerRadius=UDim.new(1,0); FOVCorner.Parent=FOVFrame
    local SoruFOVFrame = Instance.new("Frame"); SoruFOVFrame.Name="SoruFOVCircle"; SoruFOVFrame.AnchorPoint=Vector2.new(0.5,0.5); SoruFOVFrame.BackgroundTransparency=1; SoruFOVFrame.Visible=false; SoruFOVFrame.Parent=ScreenGui
    local SoruUIStroke = Instance.new("UIStroke"); SoruUIStroke.Color=Color3.fromRGB(0,255,0); SoruUIStroke.Thickness=2; SoruUIStroke.Parent=SoruFOVFrame
    local SoruFOVCorner = Instance.new("UICorner"); SoruFOVCorner.CornerRadius=UDim.new(1,0); SoruFOVCorner.Parent=SoruFOVFrame
    module.ScreenGui = ScreenGui

    local PingService = game:GetService("Stats").Network.ServerStatsItem

    local function getToolCategory(tool)
        if not tool then return "Melee" end
        local name = string.lower(tool.Name)
        local gunNames = {"guitar","rifle","cannon","gun","slingshot","kabucha","serpent bow","bow"}
        for _,g in ipairs(gunNames) do if string.find(name,g) then return "Gun" end end
        local meleeNames = {"claw","godhuman","superhuman","talon","step","karate","breath","kung fu","combat","fist","sanguine"}
        for _,m in ipairs(meleeNames) do if string.find(name,m) then return "Melee" end end
        if string.find(name,"fruit") or string.find(name,"-") then return "Fruit" end
        return "Sword"   -- tout le reste est considÃ©rÃ© comme Ã©pÃ©e
    end

    local function isKeyCurrentlyBlacklisted(key)
        if not key then return false end
        local cat = currentToolCategory
        if BlacklistedKeys[cat] and BlacklistedKeys[cat][key] ~= nil then return BlacklistedKeys[cat][key] end
        return false
    end
    local function getHRP(model) if model and model:FindFirstChild("HumanoidRootPart") then return model.HumanoidRootPart end return nil end
    local function clearConnections() for _,c in ipairs(characterConnections) do pcall(function() c:Disconnect() end) end characterConnections = {} end

    -- ==================== PRÃDICTION INTELLIGENTE FIXE ====================
    local lastVelocity = nil
    local lastDirection = nil

    local function predicted(hrp)
        if not hrp then return nil end
        local hum = hrp.Parent:FindFirstChildOfClass("Humanoid")
        if not hum or hum.Health <= 0 then return hrp.Position end
        if not PredictionEnabled then return hrp.Position end

        local vel = hrp.Velocity
        local speed = vel.Magnitude

        if speed < 5 then
            lastVelocity = nil
            lastDirection = nil
            return hrp.Position
        end

        local currentDirection = vel.Unit

        if lastDirection then
            local dot = lastDirection:Dot(currentDirection)
            if dot < 0.7 then
                lastVelocity = nil
                lastDirection = nil
                return hrp.Position
            end
        end

        lastDirection = currentDirection
        lastVelocity = vel

        local ping = 0
        pcall(function()
            if PingService then
                ping = PingService:GetValue() / 1000
            end
        end)
        ping = math.clamp(ping, 0, 0.35)
        local predictionFactor = PredictionAmount + ping

        if speed > 100 then
            predictionFactor = math.min(predictionFactor, 0.15)
        end

        return hrp.Position + (vel * predictionFactor)
    end

    local function isAllyWithMe(targetplayer)
        local myGui = player:FindFirstChild("PlayerGui")
        if not myGui then return false end
        local scrolling = myGui:FindFirstChild("Main") and myGui.Main:FindFirstChild("Allies") and myGui.Main.Allies:FindFirstChild("Container") and myGui.Main.Allies.Container:FindFirstChild("Allies") and myGui.Main.Allies.Container.Allies:FindFirstChild("ScrollingFrame")
        if scrolling then for _,frame in pairs(scrolling:GetDescendants()) do if frame:IsA("ImageButton") and frame.Name==targetplayer.Name then return true end end end
        return false
    end
    local function isTargetProtected(targetPlayer)
        if not targetPlayer then return false end
        local char = targetPlayer.Character; if not char then return false end
        if char:GetAttribute("SafeZone")==true or char:GetAttribute("PvpDisabled")==true or char:GetAttribute("CombatProtected")==true or char:GetAttribute("PVP")==false then return true end
        if targetPlayer:GetAttribute("SafeZone")==true or targetPlayer:GetAttribute("PvpDisabled")==true or targetPlayer:GetAttribute("CombatProtected")==true then return true end
        if char:FindFirstChild("SafeZone") or char:FindFirstChild("CombatPD") or char:FindFirstChild("PvpDisabled") then return true end
        if char:FindFirstChildWhichIsA("ForceField") then return true end
        return false
    end
    local function isEnemy(targetplayer)
        if not targetplayer or targetplayer==player then return false end
        if isTargetProtected(targetplayer) then return false end
        local myTeam = player.Team; local targetTeam = targetplayer.Team
        if myTeam and targetTeam then
            if myTeam.Name=="Pirates" and targetTeam.Name=="Marines" then return true
            elseif myTeam.Name=="Marines" and targetTeam.Name=="Pirates" then return true end
            if myTeam.Name=="Pirates" and targetTeam.Name=="Pirates" then return not isAllyWithMe(targetplayer) end
            if myTeam.Name=="Marines" and targetTeam.Name=="Marines" then return false end
        end
        return true
    end
    local function getFOVCenter(mode)
        if mode=="V2" then return UserInputService:GetMouseLocation() end
        if not camera then camera=workspace.CurrentCamera end
        return camera.ViewportSize/2
    end
    local function isTargetValid(hrp, lpHRP, aimMode, fovRadius, fovType)
        if not hrp or not lpHRP then return false end
        if aimMode=="180" then local dir=(hrp.Position-lpHRP.Position).Unit; if lpHRP.CFrame.LookVector:Dot(dir)<0 then return false end
        elseif aimMode=="FOV" then
            local screenPos, onScreen = camera:WorldToViewportPoint(hrp.Position)
            if not onScreen then return false end
            local center = getFOVCenter(fovType)
            if (Vector2.new(screenPos.X, screenPos.Y)-center).Magnitude > fovRadius then return false end
        end
        return true
    end
    local function getClosestplayer(lpHRP)
        if not lpHRP then return nil end
        if TargetPriority=="Lock Player" then
            if Selectedplayer and Selectedplayer.Character and Selectedplayer.Character.Parent then
                if isTargetProtected(Selectedplayer) then return nil end
                local hum = Selectedplayer.Character:FindFirstChildWhichIsA("Humanoid"); local hrp = getHRP(Selectedplayer.Character)
                if hum and hum.Health>0 and hrp then
                    if isTargetValid(hrp, lpHRP, AimMode, FOVRadius, FOVMode) and (hrp.Position-lpHRP.Position).Magnitude <= maxRange then return Selectedplayer end
                end
            end
            return nil
        end
        local valid = {}
        for _,pl in ipairs(Players:GetPlayers()) do
            if pl~=player and isEnemy(pl) and pl.Character and pl.Character.Parent then
                local hum = pl.Character:FindFirstChildWhichIsA("Humanoid"); local hrp = getHRP(pl.Character)
                if hum and hum.Health>0 and hrp and isTargetValid(hrp, lpHRP, AimMode, FOVRadius, FOVMode) then
                    local dist = (hrp.Position-lpHRP.Position).Magnitude
                    if dist <= maxRange then table.insert(valid, {Player=pl, Humanoid=hum, HRP=hrp, Distance=dist}) end
                end
            end
        end
        if #valid==0 then return nil end
        if AimMode == "360" or AimMode == "180" then
            if TargetPriority=="Nearest" then table.sort(valid, function(a,b) return a.Distance<b.Distance end)
            elseif TargetPriority=="Low HP" then table.sort(valid, function(a,b) return a.Humanoid.Health<b.Humanoid.Health end)
            elseif TargetPriority=="Looking At Me" then table.sort(valid, function(a,b) local dirA=(lpHRP.Position-a.HRP.Position).Unit; local lookA=a.HRP.CFrame.LookVector; local dirB=(lpHRP.Position-b.HRP.Position).Unit; local lookB=b.HRP.CFrame.LookVector; return lookA:Dot(dirA)>lookB:Dot(dirB) end) end
        else
            local center = getFOVCenter(FOVMode)
            table.sort(valid, function(a,b)
                local pA = camera:WorldToViewportPoint(a.HRP.Position)
                local pB = camera:WorldToViewportPoint(b.HRP.Position)
                return (Vector2.new(pA.X, pA.Y) - center).Magnitude < (Vector2.new(pB.X, pB.Y) - center).Magnitude
            end)
        end
        return valid[1].Player
    end
    local function getClosestNPC(lpHRP)
        if not lpHRP then return nil end
        local enemiesFolder = workspace:FindFirstChild("Enemies"); if not enemiesFolder then return nil end
        local closest, closestDist = nil, math.huge
        for _,npc in ipairs(enemiesFolder:GetChildren()) do
            if npc:IsA("Model") then
                local hum = npc:FindFirstChildWhichIsA("Humanoid"); local hrp = getHRP(npc)
                if hum and hum.Health>0 and hrp and isTargetValid(hrp, lpHRP, AimMode, FOVRadius, FOVMode) then
                    local dist = (hrp.Position-lpHRP.Position).Magnitude
                    if dist<=maxRange and dist<closestDist then closestDist=dist; closest=npc end
                end
            end
        end
        return closest
    end

    local SoruPredictedPosition = nil
    local function getSoruAimPart(character)
        if not character then return nil end
        return character:FindFirstChild(SoruTargetPart) or character:FindFirstChild("HumanoidRootPart")
    end
    local function isSoruVisible(part)
        if not SoruWallCheck or not part then return true end
        local origin = camera.CFrame.Position
        local params = RaycastParams.new()
        params.FilterType = Enum.RaycastFilterType.Exclude
        params.FilterDescendantsInstances = {player.Character, camera}
        local hit = workspace:Raycast(origin, part.Position - origin, params)
        return not hit or hit.Instance:IsDescendantOf(part.Parent)
    end
    local function isSoruPartUsable(part, lpHRP)
        if not part or not part.Parent or not lpHRP then return false end
        local hum = part.Parent:FindFirstChildWhichIsA("Humanoid")
        if not hum or hum.Health <= 0 then return false end
        if (part.Position - lpHRP.Position).Magnitude > SoruAutoAimRange then return false end
        return isTargetValid(part, lpHRP, SoruTargetingMode, SoruFOVRadius, SoruFOVType) and isSoruVisible(part)
    end
    local function getSoruTarget(lpHRP)
        if not lpHRP then return nil end
        local valid = {}
        for _,pl in ipairs(Players:GetPlayers()) do
            if pl~=player and pl.Character and pl.Character.Parent then
                if not isEnemy(pl) then continue end
                local hum = pl.Character:FindFirstChildWhichIsA("Humanoid"); local aimPart = getSoruAimPart(pl.Character)
                if hum and hum.Health>0 and aimPart and isSoruPartUsable(aimPart, lpHRP) then
                    local dist = (aimPart.Position-lpHRP.Position).Magnitude
                    table.insert(valid, {HRP=aimPart, Humanoid=hum, Distance=dist})
                end
            end
        end
        if #valid==0 then return nil end
        if SoruTargetingMode == "360" or SoruTargetingMode == "180" then
            if SoruTargetPriority=="Nearest" then table.sort(valid, function(a,b) return a.Distance<b.Distance end)
            elseif SoruTargetPriority=="Low HP" then table.sort(valid, function(a,b) return a.Humanoid.Health<b.Humanoid.Health end)
            elseif SoruTargetPriority=="Looking At Me" then table.sort(valid, function(a,b) local dirA=(lpHRP.Position-a.HRP.Position).Unit; local lookA=a.HRP.CFrame.LookVector; local dirB=(lpHRP.Position-b.HRP.Position).Unit; local lookB=b.HRP.CFrame.LookVector; return lookA:Dot(dirA)>lookB:Dot(dirB) end) end
        else
            local center = getFOVCenter(SoruFOVType)
            table.sort(valid, function(a,b)
                local pA = camera:WorldToViewportPoint(a.HRP.Position)
                local pB = camera:WorldToViewportPoint(b.HRP.Position)
                return (Vector2.new(pA.X, pA.Y) - center).Magnitude < (Vector2.new(pB.X, pB.Y) - center).Magnitude
            end)
        end
        return valid[1].HRP
    end

    task.spawn(function()
        while true do
            task.wait(SoruUpdateRate)
            if SoruAutoAimEnabled then
                local myHRP = getHRP(player.Character)
                local targetHRP = nil
                if SoruStickyTarget and isSoruPartUsable(SoruCurrentTarget, myHRP) then
                    targetHRP = SoruCurrentTarget
                else
                    targetHRP = myHRP and getSoruTarget(myHRP)
                end
                if targetHRP then
                    local velocity = targetHRP.AssemblyLinearVelocity or Vector3.zero
                    SoruPredictedPosition = targetHRP.Position + (SoruPredictionEnabled and velocity * SoruPredictionAmount or Vector3.zero)
                    SoruCurrentTarget = targetHRP
                else
                    SoruCurrentTarget = nil
                    SoruPredictedPosition = nil
                end
            else
                SoruCurrentTarget = nil
                SoruPredictedPosition = nil
            end
        end
    end)

    local function handleAttackRotation(key)
        -- RetirÃ©e
    end

    local function createTracer()
        if tracerModel then return end
        tracerModel = Instance.new("Model", workspace); tracerModel.Name="SilentAimTracer"
        tracerAttachment0 = Instance.new("Attachment", tracerModel); tracerAttachment1 = Instance.new("Attachment", tracerModel)
        tracerBeam = Instance.new("Beam", tracerModel)
        tracerBeam.Attachment0 = tracerAttachment0; tracerBeam.Attachment1 = tracerAttachment1
        tracerBeam.Width0=0.1; tracerBeam.Width1=0.1; tracerBeam.FaceCamera=true
        updateTracerColor()
    end
    local function destroyTracer() if tracerModel then tracerModel:Destroy(); tracerModel=nil; tracerAttachment0=nil; tracerAttachment1=nil; tracerBeam=nil end end
    local function updateTracerColor()
        if not tracerBeam then return end
        local colorMap = { Red=Color3.fromRGB(255,0,0), Green=Color3.fromRGB(0,255,0), Blue=Color3.fromRGB(0,0,255), Yellow=Color3.fromRGB(255,255,0), White=Color3.fromRGB(255,255,255) }
        local col = colorMap[TracerColor] or Color3.fromRGB(255,0,0)
        tracerBeam.Color = ColorSequence.new(col)
    end
    function module:SetTracerEnabled(state) TracerEnabled=state; if state then createTracer() else destroyTracer() end end
    function module:SetTracerColor(color) TracerColor=color; updateTracerColor() end

    -- ==================== OVERRIDE MELEE & SWORD : INSTALLATION DU HOOK ====================
    local function installMouseOverride()
        local MouseModuleInstance = RS:FindFirstChild("Mouse")
        if not MouseModuleInstance then return end
        local MouseModule = nil
        pcall(function() MouseModule = require(MouseModuleInstance) end)
        if not MouseModule or typeof(MouseModule) ~= "table" then return end
        local realStore = { Hit = rawget(MouseModule, "Hit"), Target = rawget(MouseModule, "Target") }
        local mmt = getrawmetatable(MouseModule)
        if mmt then setreadonly(mmt, false) else mmt = {}; setmetatable(MouseModule, mmt) end
        rawset(MouseModule, "Hit", nil); rawset(MouseModule, "Target", nil)
        mmt.__index = function(self, key)
            if key == "Hit" then
                if OverrideGodhumanSanguineEnabled and (SilentAimPlayersEnabled or SilentAimNPCsEnabled) and (PlayersPosition or NPCPosition) and isOverrideTool(currentTool) and currentSkillKey == "Z" and not isKeyCurrentlyBlacklisted(currentSkillKey) then
                    local pos = PlayersPosition or NPCPosition
                    if pos then return CFrame.new(pos) end
                end
                return realStore.Hit
            elseif key == "Target" then
                if OverrideGodhumanSanguineEnabled and (SilentAimPlayersEnabled or SilentAimNPCsEnabled) and (PlayersPosition or NPCPosition) and isOverrideTool(currentTool) and currentSkillKey == "Z" and not isKeyCurrentlyBlacklisted(currentSkillKey) then
                    return nil
                end
                return realStore.Target
            end
            return rawget(self, key)
        end
        mmt.__newindex = function(self, key, value)
            if key == "Hit" or key == "Target" then realStore[key] = value else rawset(self, key, value) end
        end
        setreadonly(mmt, true)
    end
    installMouseOverride()

    UserInputService.InputBegan:Connect(function(input, gp)
        if gp then return end
        local keyMap = { [Enum.KeyCode.Z]="Z", [Enum.KeyCode.X]="X", [Enum.KeyCode.C]="C", [Enum.KeyCode.V]="V", [Enum.KeyCode.F]="F" }
        local key = keyMap[input.KeyCode]
        if key then setCurrentSkillKey(key) end
    end)

    local function hookMobileButton(btn)
        if btn:GetAttribute("Hooked") then return end; btn:SetAttribute("Hooked", true)
        local key = btn.Name
        if table.find(SKILL_KEYS, key) then
            btn.Activated:Connect(function() setCurrentSkillKey(key) end)
        end
    end
    spawn(function()
        while not player.PlayerGui do wait(0.5) end
        local pg = player.PlayerGui; local main = pg:WaitForChild("Main",10)
        if main then
            local skills = main:WaitForChild("Skills",10)
            if skills then
                for _,wf in ipairs(skills:GetChildren()) do if wf:IsA("GuiObject") then for _,b in ipairs(wf:GetChildren()) do if b:IsA("ImageButton") or b:IsA("TextButton") then hookMobileButton(b) end end end end
                skills.ChildAdded:Connect(function(wf) if wf:IsA("GuiObject") then for _,b in ipairs(wf:GetChildren()) do if b:IsA("ImageButton") or b:IsA("TextButton") then hookMobileButton(b) end end end end)
            end
        end
    end)

    local function getSkillKeyFromArgs(args)
        for _,arg in ipairs(args) do if type(arg)=="string" and table.find(SKILL_KEYS, arg) then return arg end end
        return nil
    end

    local function startRenderLoop()
        if not renderConnection then
            renderConnection = RunService.RenderStepped:Connect(function()
                if ShowFOVCircle then local center=getFOVCenter(FOVMode); FOVFrame.Position=UDim2.new(0,center.X,0,center.Y); FOVFrame.Size=UDim2.new(0,FOVRadius*2,0,FOVRadius*2); FOVFrame.Visible=true else FOVFrame.Visible=false end
                if SoruShowFOVCircle then local center=getFOVCenter(SoruFOVType); SoruFOVFrame.Position=UDim2.new(0,center.X,0,center.Y); SoruFOVFrame.Size=UDim2.new(0,SoruFOVRadius*2,0,SoruFOVRadius*2); SoruFOVFrame.Visible=true else SoruFOVFrame.Visible=false end
                pcall(function()
                    local lpChar = player.Character; if not lpChar then return end
                    local lpHRP = lpChar:FindFirstChild("HumanoidRootPart"); if not lpHRP then return end
                    if not SilentAimPlayersEnabled and not SilentAimNPCsEnabled then
                        if TracerEnabled and tracerBeam then tracerBeam.Enabled=false end
                        PlayersPosition = nil; NPCPosition = nil
                        return
                    end
                    if SilentAimPlayersEnabled then
                        local targetplayer = getClosestplayer(lpHRP)
                        if targetplayer and targetplayer.Character then
                            PlayersPosition = predicted(getHRP(targetplayer.Character))
                        else PlayersPosition=nil end
                    end
                    if SilentAimNPCsEnabled then
                        local npc = getClosestNPC(lpHRP)
                        if npc then NPCPosition = predicted(getHRP(npc))
                        else NPCPosition=nil end
                    end
                    if TracerEnabled and tracerBeam and tracerAttachment0 and tracerAttachment1 then
                        local targetPos = PlayersPosition or NPCPosition
                        if lpHRP and targetPos then tracerAttachment0.WorldPosition=lpHRP.Position; tracerAttachment1.WorldPosition=targetPos; tracerBeam.Enabled=true
                        else tracerBeam.Enabled=false end
                    end
                end)
            end)
        end
        if not heartbeatConnection then
            heartbeatConnection = RunService.Heartbeat:Connect(function()
                if not ZSkillorM1 or (not SilentAimPlayersEnabled and not SilentAimNPCsEnabled) then return end
                if currentSkillKey and isKeyCurrentlyBlacklisted(currentSkillKey) then return end
                if currentTool and (string.find(string.lower(currentTool.Name),"portal") or string.find(string.lower(currentTool.Name),"lightning")) then return end
                
                -- ========== OVERRIDE MELEE & SWORD ==========
                if not OverrideGodhumanSanguineEnabled then return end
                if not isOverrideTool(currentTool) then return end
                if currentSkillKey ~= "Z" then return end

                local targetPos = PlayersPosition or NPCPosition
                if targetPos and Mouse then
                    local targetCFrame = CFrame.new(targetPos)
                    pcall(function() Mouse.Hit = targetCFrame; Mouse.Target = nil end)
                    if MouseModule then pcall(function() local MouseData = require(MouseModule); MouseData.Hit = targetCFrame; MouseData.Target = nil end) end
                end
                -- ===========================================
            end)
        end
    end

    local function stopRenderLoop()
        if renderConnection then renderConnection:Disconnect(); renderConnection=nil end
        if heartbeatConnection then heartbeatConnection:Disconnect(); heartbeatConnection=nil end
        FOVFrame.Visible=false; SoruFOVFrame.Visible=false; destroyTracer()
        PlayersPosition = nil; NPCPosition = nil
        if Mouse then pcall(function() Mouse.Hit = CFrame.new(0,0,0) end) end
    end

    local Mouse = player:GetMouse()
    spawn(function()
        local mt = getrawmetatable(game); if not mt then return end
        local oldNamecall = mt.__namecall; local oldIndex = mt.__index
        setreadonly(mt, false)
        mt.__namecall = newcclosure(function(self, ...)
            local Method = getnamecallmethod(); local args = {...}
            if args[1]=="TAP" then return oldNamecall(self, ...) end
            local skillKey = getSkillKeyFromArgs(args)
            if skillKey then
                if SilentAimPlayersEnabled or SilentAimNPCsEnabled then
                    local targetPos = PlayersPosition or NPCPosition
                    if targetPos then
                        task.spawn(function() faceTarget(targetPos) end)
                    end
                end
                setCurrentSkillKey(skillKey)
            end
            
            -- SORU AUTO AIM (INTACT)
            if SoruAutoAimEnabled and SoruPredictedPosition and skillKey=="C" then
                for i,arg in ipairs(args) do
                    if typeof(arg)=="Vector3" then
                        args[i]=SoruPredictedPosition
                    end
                end
            end
            
            local skip = false
            if skillKey and isKeyCurrentlyBlacklisted(skillKey) then skip=true
            elseif not skillKey and currentSkillKey and isKeyCurrentlyBlacklisted(currentSkillKey) then skip=true end
            if not skip then
                if Method=="FireServer" then
                    if typeof(args[1])=="Vector3" then
                        if SilentAimPlayersEnabled and PlayersPosition then args[1]=PlayersPosition
                        elseif SilentAimNPCsEnabled and NPCPosition then args[1]=NPCPosition end
                    end
                elseif Method=="InvokeServer" and currentTool and currentTool.Name=="Buddy Sword" then
                    if type(args[1])=="string" and table.find(Skills, args[1]) then
                        if SilentAimPlayersEnabled and PlayersPosition then args[2]=PlayersPosition
                        elseif SilentAimNPCsEnabled and NPCPosition then args[2]=NPCPosition end
                    end
                end
            end
            return oldNamecall(self, unpack(args))
        end)
        mt.__index = newcclosure(function(t,k)
            -- SORU AUTO AIM (INTACT)
            if SoruAutoAimEnabled and t==Mouse and SoruPredictedPosition then
                if k=="Hit" then return CFrame.new(SoruPredictedPosition) end
                if k=="Target" then return nil end
            end
            return oldIndex(t,k)
        end)
        setreadonly(mt, true)
    end)

    local function onCharacterAdded(char)
        clearConnections()
        local hum = char:WaitForChild("Humanoid", 10)
        if hum then
            table.insert(characterConnections, hum.AnimationPlayed:Connect(function(track)
                local anim = track.Animation
                local id = anim and tostring(anim.AnimationId):match("%d+")
                local animName = string.lower(anim and anim.Name or "")
                if bunnyHopEnabled and (string.find(animName, "dash") or string.find(animName, "flashstep") or id == "17555632156" or id == "1846164274" or id == "1846163351") then
                    task.spawn(function()
                        task.wait(0.05)
                        if hum and hum.FloorMaterial ~= Enum.Material.Air then
                            hum:ChangeState(Enum.HumanoidStateType.Jumping)
                        end
                    end)
                end
            end))
        end
        for _,child in ipairs(char:GetChildren()) do
            if child:IsA("Tool") then currentTool=child; currentToolCategory=getToolCategory(child); currentSkillKey=nil
                table.insert(characterConnections, child.AncestryChanged:Connect(function(_,p) if not p then currentTool=nil end end)) end
        end
        table.insert(characterConnections, char.ChildAdded:Connect(function(child)
            if child:IsA("Tool") then currentTool=child; currentToolCategory=getToolCategory(child); currentSkillKey=nil
                table.insert(characterConnections, child.AncestryChanged:Connect(function(_,p) if not p then currentTool=nil end end)) end
        end))
        table.insert(characterConnections, char.ChildRemoved:Connect(function(child) if child==currentTool then currentTool=nil end end))
    end
    player.CharacterAdded:Connect(onCharacterAdded)
    if player.Character then onCharacterAdded(player.Character) end

    local UserWantsplayerAim, UserWantsNPCAim = false, false
    function module:SetZSkillorM1(state) ZSkillorM1=state end
    function module:SetPrediction(state) PredictionEnabled=state end
    function module:SetPredictionAmount(amt) PredictionAmount=amt end
    function module:SetDistanceLimit(num) if type(num)=="number" then maxRange=num end end
    function module:SetSelectedPlayer(playerName) if not playerName or playerName=="" then Selectedplayer=nil return end; Selectedplayer=Players:FindFirstChild(playerName) end
    function module:SetPlayerSilentAim(state) UserWantsplayerAim=state; SilentAimPlayersEnabled=state; if state then startRenderLoop() elseif not SilentAimNPCsEnabled then stopRenderLoop() end end
    function module:SetNPCSilentAim(state) UserWantsNPCAim=state; SilentAimNPCsEnabled=state; if state then startRenderLoop() elseif not SilentAimPlayersEnabled then stopRenderLoop() end end
    function module:SetBlacklistKey(cat,key,state) if BlacklistedKeys[cat] and BlacklistedKeys[cat][key]~=nil then BlacklistedKeys[cat][key]=state end end
    function module:IsKeyBlacklisted(cat,key) return BlacklistedKeys[cat] and BlacklistedKeys[cat][key] or false end
    function module:SetAimMode(mode) AimMode=mode end
    function module:SetTargetPriority(prio) TargetPriority=prio end
    function module:SetShowFOVCircle(state) ShowFOVCircle=state end
    function module:SetFOVRadius(num) FOVRadius=num end
    function module:SetFOVMode(mode) FOVMode=mode end
    function module:SetSoruAutoAim(state) SoruAutoAimEnabled=state; if not state then SoruCurrentTarget=nil; SoruPredictedPosition=nil end end
    function module:SetSoruRange(r) SoruAutoAimRange=r end
    function module:SetSoruAimMode(mode) SoruTargetingMode=mode end
    function module:SetSoruFOVType(mode) SoruFOVType=mode end
    function module:SetSoruFOVRadius(r) SoruFOVRadius=r end
    function module:SetSoruPriority(p) SoruTargetPriority=p end
    function module:SetSoruShowFOVCircle(state) SoruShowFOVCircle=state end
    function module:SetSoruPrediction(state) SoruPredictionEnabled=state end
    function module:SetSoruPredictionAmount(v) SoruPredictionAmount=v end
    function module:SetSoruStickyTarget(state) SoruStickyTarget=state; if not state then SoruCurrentTarget=nil end end
    function module:SetSoruWallCheck(state) SoruWallCheck=state end
    function module:SetSoruTargetPart(part) SoruTargetPart=part; SoruCurrentTarget=nil end
    function module:SetSoruUpdateRate(v) SoruUpdateRate=v end
    function module:GetTargetPos() return PlayersPosition or NPCPosition end
    return module
end)()

-- ==================== ONGLETS ====================

-- Macro
MacroTab = Tabs.Macro
MacroLeft = MacroTab:AddLeftGroupbox("Macro Hub")
MacroLeft:AddLabel("Combat automation")
MacroLeft:AddToggle("AHKSoru", { Text="AHK Soru", Default=false, Callback=function(v) if v then LoadAHKsoru() else UnloadAHKsoru() end end })
MacroLeft:AddToggle("AHKCombo", { Text="AHK Combo", Default=false, Callback=function(v) if v then LoadAHKComboScript() else UnloadAHKComboScript() end end })
MacroLeft:AddButton("Reload enabled macros", function()
    if ahk_soru_loaded then UnloadAHKsoru(); task.wait(0.15); LoadAHKsoru() end
    if ahk_combo_script_loaded then UnloadAHKComboScript(); task.wait(0.15); LoadAHKComboScript() end
end)
MacroLeft:AddButton("Stop all macros", function()
    if Toggles.AHKSoru then Toggles.AHKSoru:SetValue(false) else UnloadAHKsoru() end
    if Toggles.AHKCombo then Toggles.AHKCombo:SetValue(false) else UnloadAHKComboScript() end
end)
MacroLeft:AddToggle("MacroAutoResume", { Text="Resume after respawn", Default=true })
lp.CharacterAdded:Connect(function()
    task.wait(1)
    if Toggles.MacroAutoResume and Toggles.MacroAutoResume.Value then
        if Toggles.AHKSoru and Toggles.AHKSoru.Value and not ahk_soru_loaded then LoadAHKsoru() end
        if Toggles.AHKCombo and Toggles.AHKCombo.Value and not ahk_combo_script_loaded then LoadAHKComboScript() end
    end
end)

SoruGroup = MacroTab:AddRightGroupbox("Soru Assist")
SoruGroup:AddToggle("SoruToggle", { Text="Enable Soru Assist", Default=false, Callback=function(v) SilentAimModule:SetSoruAutoAim(v) end }):AddKeyPicker("SoruKey", { Default="None", SyncToggleState=true, Mode="Toggle", Text="Soru Assist" })
SoruGroup:AddDropdown("SoruAimMode", { Values={"360","180","FOV"}, Default="360", Text="Aim Mode", Callback=function(v) SilentAimModule:SetSoruAimMode(v) end })
SoruGroup:AddDropdown("SoruTargetPart", { Values={"HumanoidRootPart","Head","UpperTorso"}, Default="HumanoidRootPart", Text="Target Part", Callback=function(v) SilentAimModule:SetSoruTargetPart(v) end })
SoruGroup:AddDropdown("SoruPriority", { Values={"Nearest","Low HP","Looking At Me"}, Default="Nearest", Text="Target Priority", Callback=function(v) SilentAimModule:SetSoruPriority(v) end })
SoruGroup:AddToggle("SoruSticky", { Text="Sticky Target", Default=true, Callback=function(v) SilentAimModule:SetSoruStickyTarget(v) end })
SoruGroup:AddToggle("SoruWallCheck", { Text="Wall Check", Default=false, Callback=function(v) SilentAimModule:SetSoruWallCheck(v) end })
SoruGroup:AddToggle("SoruPrediction", { Text="Movement Prediction", Default=true, Callback=function(v) SilentAimModule:SetSoruPrediction(v) end })
SoruGroup:AddSlider("SoruPredictionAmount", { Text="Prediction", Default=12, Min=0, Max=50, Rounding=0, Suffix="%", Callback=function(v) SilentAimModule:SetSoruPredictionAmount(v/100) end })
SoruGroup:AddSlider("SoruRange", { Text="Max Range", Default=300, Min=50, Max=1000, Rounding=0, Suffix=" studs", Callback=function(v) SilentAimModule:SetSoruRange(v) end })
SoruGroup:AddDropdown("SoruFOVType", { Values={"V1","V2"}, Default="V1", Text="FOV Center", Callback=function(v) SilentAimModule:SetSoruFOVType(v) end })
SoruGroup:AddSlider("SoruFOVRadius", { Text="FOV Radius", Default=100, Min=10, Max=800, Rounding=0, Callback=function(v) SilentAimModule:SetSoruFOVRadius(v) end })
SoruGroup:AddToggle("SoruShowFOV", { Text="Show FOV Circle", Default=false, Callback=function(v) SilentAimModule:SetSoruShowFOVCircle(v) end })
SoruGroup:AddSlider("SoruRefresh", { Text="Refresh Speed", Default=8, Min=3, Max=20, Rounding=0, Suffix=" cs", Callback=function(v) SilentAimModule:SetSoruUpdateRate(v/100) end })

-- ==================== MACRO + SORU PRESET / AUTO-LAUNCH SYSTEM ====================
-- HttpService declared at top
PRESET_DIR = "NamelessConfigs/MacroSoru"
AUTOLOAD_FILE = PRESET_DIR .. "/_autoload.txt"
STARTUP_FILE = PRESET_DIR .. "/_startup.json"

-- safe filesystem wrappers (executors differ / some sandboxes miss these)
local function fs_isfolder(p) local ok, r = pcall(isfolder, p) return ok and r end
local function fs_makefolder(p) pcall(makefolder, p) end
local function fs_isfile(p) local ok, r = pcall(isfile, p) return ok and r end
local function fs_readfile(p) local ok, r = pcall(readfile, p) if ok then return r end return nil end
local function fs_writefile(p, c) return (pcall(writefile, p, c)) end
local function fs_delfile(p) pcall(delfile, p) end

if not fs_isfolder("NamelessConfigs") then fs_makefolder("NamelessConfigs") end
if not fs_isfolder(PRESET_DIR) then fs_makefolder(PRESET_DIR) end

PRESET_TOGGLES = {
    "AHKSoru","AHKCombo","MacroAutoResume",
    "SoruToggle","SoruSticky","SoruWallCheck","SoruPrediction","SoruShowFOV",
}
PRESET_OPTIONS = {
    "SoruAimMode","SoruTargetPart","SoruPriority","SoruPredictionAmount",
    "SoruRange","SoruFOVType","SoruFOVRadius","SoruRefresh",
}

local function sanitizePresetName(name)
    name = tostring(name or ""):gsub("[^%w _%-]", "")
    return (name:gsub("^%s*(.-)%s*$", "%1"))
end

-- forces the real macro/soru state to match the toggles, even when the
-- toggle value did not change (so no callback fired)
local function enforceMacroState()
    local wantSoru = Toggles.AHKSoru and Toggles.AHKSoru.Value
    local wantCombo = Toggles.AHKCombo and Toggles.AHKCombo.Value
    if wantSoru and not ahk_soru_loaded then pcall(LoadAHKsoru)
    elseif (not wantSoru) and ahk_soru_loaded then pcall(UnloadAHKsoru) end
    if wantCombo and not ahk_combo_script_loaded then pcall(LoadAHKComboScript)
    elseif (not wantCombo) and ahk_combo_script_loaded then pcall(UnloadAHKComboScript) end
    if Toggles.SoruToggle then
        pcall(function() SilentAimModule:SetSoruAutoAim(Toggles.SoruToggle.Value) end)
    end
end

local function collectPresetData()
    local data = { toggles = {}, options = {}, keybind = nil }
    for _, name in ipairs(PRESET_TOGGLES) do
        if Toggles[name] then data.toggles[name] = Toggles[name].Value end
    end
    for _, name in ipairs(PRESET_OPTIONS) do
        if Options[name] then data.options[name] = Options[name].Value end
    end
    if Options.SoruKey then data.keybind = Options.SoruKey.Value end
    return data
end

local function applyPresetData(data)
    if type(data) ~= "table" then return false end
    if type(data.options) == "table" then
        for name, value in pairs(data.options) do
            if Options[name] and value ~= nil then pcall(function() Options[name]:SetValue(value) end) end
        end
    end
    if data.keybind and Options.SoruKey then
        pcall(function() Options.SoruKey:SetValue({ data.keybind, Options.SoruKey.Mode or "Toggle" }) end)
    end
    if type(data.toggles) == "table" then
        for name, value in pairs(data.toggles) do
            if Toggles[name] and value ~= nil then pcall(function() Toggles[name]:SetValue(value) end) end
        end
    end
    task.defer(enforceMacroState)
    return true
end

local function listPresets()
    local out = {}
    local ok, files = pcall(listfiles, PRESET_DIR)
    if ok and type(files) == "table" then
        for _, path in ipairs(files) do
            local file = path:match("([^/\\]+)%.json$")
            if file and file:sub(1, 1) ~= "_" then table.insert(out, file) end
        end
    end
    table.sort(out)
    return out
end

local function savePreset(name)
    name = sanitizePresetName(name)
    if name == "" then
        Library:Notify({ Title = "Presets", Description = "Enter a preset name first.", Time = 3 })
        return false
    end
    local ok, encoded = pcall(function() return HttpService:JSONEncode(collectPresetData()) end)
    if not ok or not fs_writefile(PRESET_DIR .. "/" .. name .. ".json", encoded) then
        Library:Notify({ Title = "Presets", Description = "Failed to save preset.", Time = 3 })
        return false
    end
    Library:Notify({ Title = "Presets", Description = "Saved preset: " .. name, Time = 3 })
    return true
end

local function loadPreset(name, silent)
    name = sanitizePresetName(name)
    local path = PRESET_DIR .. "/" .. name .. ".json"
    if name == "" or not fs_isfile(path) then
        if not silent then Library:Notify({ Title = "Presets", Description = "Preset not found.", Time = 3 }) end
        return false
    end
    local raw = fs_readfile(path)
    local ok, data = pcall(function() return HttpService:JSONDecode(raw) end)
    if not ok or not applyPresetData(data) then
        Library:Notify({ Title = "Presets", Description = "Preset file is corrupted.", Time = 3 })
        return false
    end
    Library:Notify({ Title = "Presets", Description = "Loaded preset: " .. name, Time = 3 })
    return true
end

PresetGroup = MacroTab:AddLeftGroupbox("Macro & Soru Presets")
PresetGroup:AddLabel("Save your macro + Soru setup")
PresetGroup:AddInput("PresetName", { Text = "Preset Name", Default = "", Placeholder = "my setup", Numeric = false, Finished = false })
PresetGroup:AddDropdown("PresetList", { Values = listPresets(), Default = nil, Text = "Saved Presets", AllowNull = true })

local function refreshPresetList(selected)
    pcall(function() Options.PresetList:SetValues(listPresets()) end)
    if selected then pcall(function() Options.PresetList:SetValue(selected) end) end
end

PresetGroup:AddButton("Save preset", function()
    local name = Options.PresetName and Options.PresetName.Value or ""
    if savePreset(name) then refreshPresetList(sanitizePresetName(name)) end
end)
PresetGroup:AddButton("Load selected", function()
    loadPreset(Options.PresetList and Options.PresetList.Value or "")
end)
PresetGroup:AddButton("Overwrite selected", function()
    local sel = Options.PresetList and Options.PresetList.Value or ""
    if sel == nil or sel == "" then
        Library:Notify({ Title = "Presets", Description = "Select a preset first.", Time = 3 })
    else
        savePreset(sel)
    end
end)
PresetGroup:AddButton("Delete selected", function()
    local sel = sanitizePresetName(Options.PresetList and Options.PresetList.Value or "")
    local path = PRESET_DIR .. "/" .. sel .. ".json"
    if sel ~= "" and fs_isfile(path) then
        fs_delfile(path)
        Library:Notify({ Title = "Presets", Description = "Deleted preset: " .. sel, Time = 3 })
        refreshPresetList()
    else
        Library:Notify({ Title = "Presets", Description = "Select a preset first.", Time = 3 })
    end
end)
PresetGroup:AddButton("Refresh list", function() refreshPresetList() end)

-- ---------- AUTO LOAD + AUTO LAUNCH ----------
StartupGroup = MacroTab:AddRightGroupbox("Auto Load & Auto Launch")
StartupStatus = StartupGroup:AddLabel("Status: idle", true)

local function setStatus(text)
    pcall(function() StartupStatus:SetText("Status: " .. text) end)
end

local startupCfg = { autoLoadPreset = false, preset = "", launchSoru = false, launchCombo = false, launchAssist = false, delay = 3 }

local function readStartupCfg()
    local raw = fs_readfile(STARTUP_FILE)
    if raw then
        local ok, data = pcall(function() return HttpService:JSONDecode(raw) end)
        if ok and type(data) == "table" then
            for k, v in pairs(data) do startupCfg[k] = v end
        end
    end
    -- legacy autoload file support
    if startupCfg.preset == "" and fs_isfile(AUTOLOAD_FILE) then
        startupCfg.preset = sanitizePresetName(fs_readfile(AUTOLOAD_FILE) or "")
        if startupCfg.preset ~= "" then startupCfg.autoLoadPreset = true end
    end
end
readStartupCfg()

local startupReady = false
local function writeStartupCfg()
    if not startupReady then return end
    local ok, encoded = pcall(function() return HttpService:JSONEncode(startupCfg) end)
    if ok then fs_writefile(STARTUP_FILE, encoded) end
end

StartupGroup:AddToggle("StartupAutoLoad", { Text = "Auto-load preset on launch", Default = startupCfg.autoLoadPreset, Tooltip = "Loads the preset chosen below every time the script starts",
    Callback = function(v) startupCfg.autoLoadPreset = v; writeStartupCfg() end })
StartupGroup:AddDropdown("StartupPreset", { Values = listPresets(), Default = nil, Text = "Preset to auto-load", AllowNull = true,
    Callback = function(v) startupCfg.preset = sanitizePresetName(v or ""); writeStartupCfg() end })
if startupCfg.preset ~= "" then pcall(function() Options.StartupPreset:SetValue(startupCfg.preset) end) end

StartupGroup:AddDivider()
StartupGroup:AddToggle("StartupLaunchSoru", { Text = "Auto launch AHK Soru", Default = startupCfg.launchSoru,
    Callback = function(v) startupCfg.launchSoru = v; writeStartupCfg() end })
StartupGroup:AddToggle("StartupLaunchCombo", { Text = "Auto launch AHK Combo", Default = startupCfg.launchCombo,
    Callback = function(v) startupCfg.launchCombo = v; writeStartupCfg() end })
StartupGroup:AddToggle("StartupLaunchAssist", { Text = "Auto launch Soru Assist", Default = startupCfg.launchAssist,
    Callback = function(v) startupCfg.launchAssist = v; writeStartupCfg() end })
StartupGroup:AddSlider("StartupDelay", { Text = "Launch delay", Default = tonumber(startupCfg.delay) or 3, Min = 0, Max = 20, Rounding = 0, Suffix = " s",
    Callback = function(v) startupCfg.delay = v; writeStartupCfg() end })
startupReady = true

local function runStartupSequence(manual)
    task.spawn(function()
        local waitTime = tonumber(startupCfg.delay) or 3
        if manual then waitTime = 0 end
        if waitTime > 0 then
            for i = waitTime, 1, -1 do
                setStatus("launching in " .. i .. "s")
                task.wait(1)
            end
        end
        if startupCfg.autoLoadPreset and startupCfg.preset ~= "" then
            setStatus("loading preset " .. startupCfg.preset)
            refreshPresetList(startupCfg.preset)
            loadPreset(startupCfg.preset, true)
            task.wait(0.3)
        end
        if startupCfg.launchSoru and Toggles.AHKSoru then pcall(function() Toggles.AHKSoru:SetValue(true) end) end
        if startupCfg.launchCombo and Toggles.AHKCombo then pcall(function() Toggles.AHKCombo:SetValue(true) end) end
        if startupCfg.launchAssist and Toggles.SoruToggle then pcall(function() Toggles.SoruToggle:SetValue(true) end) end
        task.wait(0.2)
        enforceMacroState()
        local parts = {}
        if ahk_soru_loaded then table.insert(parts, "AHK Soru") end
        if ahk_combo_script_loaded then table.insert(parts, "AHK Combo") end
        if Toggles.SoruToggle and Toggles.SoruToggle.Value then table.insert(parts, "Soru Assist") end
        if #parts == 0 then
            setStatus("nothing to launch")
        else
            setStatus("running - " .. table.concat(parts, ", "))
            Library:Notify({ Title = "Auto Launch", Description = "Started: " .. table.concat(parts, ", "), Time = 4 })
        end
    end)
end

StartupGroup:AddButton("Run auto-launch now", function() runStartupSequence(true) end)
StartupGroup:AddButton("Save startup settings", function()
    startupCfg.preset = sanitizePresetName(Options.StartupPreset and Options.StartupPreset.Value or startupCfg.preset)
    writeStartupCfg()
    if startupCfg.preset ~= "" then fs_writefile(AUTOLOAD_FILE, startupCfg.preset) end
    Library:Notify({ Title = "Auto Launch", Description = "Startup settings saved.", Time = 3 })
end)
StartupGroup:AddButton("Clear startup settings", function()
    startupCfg = { autoLoadPreset = false, preset = "", launchSoru = false, launchCombo = false, launchAssist = false, delay = 3 }
    if Toggles.StartupAutoLoad then Toggles.StartupAutoLoad:SetValue(false) end
    if Toggles.StartupLaunchSoru then Toggles.StartupLaunchSoru:SetValue(false) end
    if Toggles.StartupLaunchCombo then Toggles.StartupLaunchCombo:SetValue(false) end
    if Toggles.StartupLaunchAssist then Toggles.StartupLaunchAssist:SetValue(false) end
    fs_delfile(STARTUP_FILE)
    fs_delfile(AUTOLOAD_FILE)
    setStatus("cleared")
    Library:Notify({ Title = "Auto Launch", Description = "Startup settings cleared.", Time = 3 })
end)

-- keep macros alive after respawn / re-sync every few seconds
task.spawn(function()
    while task.wait(5) do
        if Toggles.MacroAutoResume and Toggles.MacroAutoResume.Value then
            pcall(enforceMacroState)
        end
    end
end)

-- fire the startup sequence once the UI is fully built
task.delay(1, function()
    refreshPresetList(startupCfg.preset ~= "" and startupCfg.preset or nil)
    pcall(function() Options.StartupPreset:SetValues(listPresets()) end)
    if startupCfg.preset ~= "" then pcall(function() Options.StartupPreset:SetValue(startupCfg.preset) end) end
    if startupCfg.autoLoadPreset or startupCfg.launchSoru or startupCfg.launchCombo or startupCfg.launchAssist then
        runStartupSequence(false)
    else
        setStatus("idle (nothing configured)")
    end
end)

-- Glitch
GlitchTab = Tabs.Glitch

SanguineGroup = GlitchTab:AddLeftGroupbox("Sanguine Z Boost")
SanguineGroup:AddToggle("SanguineToggle", { Text="Enable Sanguine", Default=false, Callback=function(v) multiEnabled=v; if not v then multiCharging=false; multiChargeStart=0 end end })
SanguineGroup:AddSlider("SanguinePower", { Text="Power", Default=400, Min=100, Max=5000, Rounding=0, Suffix=" force", Callback=function(v) multiPower=v end })
SanguineGroup:AddSlider("SanguineDuration", { Text="Duration (cs)", Default=90, Min=10, Max=200, Rounding=0, Suffix=" cs", Callback=function(v) multiDuration=v/100 end })
SanguineGroup:AddSlider("SanguineCharge", { Text="Min Charge", Default=10, Min=1, Max=50, Rounding=0, Suffix="", Callback=function(v) multiRequiredCharge=v/10 end })

DTalonGroup = GlitchTab:AddLeftGroupbox("DTalon Z Boost")
DTalonGroup:AddToggle("DTalonToggle", { Text="Enable DTalon", Default=false, Callback=function(v) dtalonEnabled=v; if not v then dtalonCharging=false; dtalonChargeStart=0 end end })
DTalonGroup:AddSlider("DTalonPower", { Text="Power", Default=400, Min=100, Max=5000, Rounding=0, Suffix=" force", Callback=function(v) dtalonPower=v end })
DTalonGroup:AddSlider("DTalonDuration", { Text="Duration (cs)", Default=90, Min=10, Max=200, Rounding=0, Suffix=" cs", Callback=function(v) dtalonDuration=v/100 end })
DTalonGroup:AddSlider("DTalonCharge", { Text="Min Charge", Default=10, Min=1, Max=50, Rounding=0, Suffix="", Callback=function(v) dtalonRequiredCharge=v/10 end })



BigSkinGroup = GlitchTab:AddLeftGroupbox("Big Skin Bug")
BigSkinGroup:AddToggle("BigSkinToggle", { Text="Enable Big Skin Bug", Default=false, Callback=function(v)
    if v then enableBigSkin() else disableBigSkin() end
end })

DiamondGroup = GlitchTab:AddRightGroupbox("Diamond Boost")
DiamondGroup:AddToggle("DiamondToggle", { Text="Enable Diamond", Default=false, Callback=function(v) diamondEnabled=v; if not v then diamondCharging=false; diamondChargeStart=0 end end })
DiamondGroup:AddSlider("DiamondPower", { Text="Power", Default=250, Min=100, Max=5000, Rounding=0, Suffix=" force", Callback=function(v) diamondPower=v end })
DiamondGroup:AddSlider("DiamondDuration", { Text="Duration (cs)", Default=30, Min=10, Max=200, Rounding=0, Suffix=" cs", Callback=function(v) diamondDuration=v/100 end })
DiamondGroup:AddSlider("DiamondCharge", { Text="Min Charge", Default=10, Min=1, Max=50, Rounding=0, Suffix="", Callback=function(v) diamondRequiredCharge=v/10 end })

EClawGroup = GlitchTab:AddRightGroupbox("EClaw X Boost")
EClawGroup:AddToggle("EClawToggle", { Text="Enable EClaw Boost", Default=false, Callback=function(v) EClawBoost:Toggle(v) end })
EClawGroup:AddSlider("EClawPower", { Text="Power", Default=400, Min=100, Max=5000, Rounding=0, Suffix=" force", Callback=function(v) EClawBoost:SetPower(v) end })
EClawGroup:AddSlider("EClawDuration", { Text="Duration (cs)", Default=170, Min=10, Max=200, Rounding=0, Suffix=" cs", Callback=function(v) EClawBoost:SetDuration(v/100) end })
EClawGroup:AddSlider("EClawCharge", { Text="Min Charge", Default=0, Min=0, Max=50, Rounding=0, Suffix="", Callback=function(v) EClawBoost:SetRequiredCharge(v/10) end })

-- Movement
MoveTab = Tabs.Movement
MoveGroup = MoveTab:AddLeftGroupbox("Player Movement")
MoveGroup:AddToggle("BunnyHopToggle", { Text="Bunny Hop", Default=false, Callback=function(v) bunnyHopEnabled=v end })

SuperJumpGroup = MoveTab:AddLeftGroupbox("Super Jump")
SuperJumpGroup:AddToggle("SuperJumpToggle", { Text="Enable Super Jump", Default=false, Callback=function(v) superJumpEnabled=v; updateSuperJumpState(); if not v then resetSuperJumpToNormal(); if superJumpButton then destroySuperJumpButton() end end end })
SuperJumpGroup:AddDropdown("SuperJumpMode", { Values={"V1","V2","V3"}, Default="V1", Text="", Callback=function(v) superJumpMode=v; updateSuperJumpState() end })
SuperJumpGroup:AddSlider("SuperJumpPower", { Text="Jump Power", Default=150, Min=50, Max=500, Rounding=0, Callback=function(v) superJumpPower=v; if superJumpEnabled and superJumpMode=="V1" then applySuperJumpV1() end end })

DashLengthGroup = MoveTab:AddRightGroupbox("Dash Length")
DashLengthGroup:AddToggle("DashToggle", { Text="Enable Dash Length", Default=false, Callback=function(v)
    dashLengthEnabled=v
    if v then
        if dashLengthConnection then task.cancel(dashLengthConnection) end
        dashLengthConnection = task.spawn(function()
            while dashLengthEnabled do task.wait(0.1)
                local character = lp.Character
                if character then
                    local cv = character:GetAttribute("DashLength")
                    if cv ~= dashLengthValue then character:SetAttribute("DashLength", dashLengthValue); character:SetAttribute("DashLengthAir", dashLengthValue) end
                end
            end
        end)
    else
        if dashLengthConnection then task.cancel(dashLengthConnection); dashLengthConnection=nil end
        if lp.Character then lp.Character:SetAttribute("DashLength",1); lp.Character:SetAttribute("DashLengthAir",1) end
    end
end })
DashLengthGroup:AddSlider("DashLengthValue", { Text="Dash Distance", Default=1, Min=1, Max=300, Rounding=0, Callback=function(v) dashLengthValue=v end })

SpeedGroup = MoveTab:AddLeftGroupbox("Speed Hack")
SpeedGroup:AddToggle("SpeedHackToggle", { Text="Enable Speed Hack", Default=false, Callback=function(v) if v then StartSpeedHack(); CreateSpeedMiniToggle() else StopSpeedHack(); DestroySpeedMiniToggle() end end })
SpeedGroup:AddDropdown("SpeedMode", { Values={"WalkSpeed","CFrame","Velocity","TP-Flash","AnimSpeed"}, Default="WalkSpeed", Text="Mode", Callback=function(v) speedSettings.mode=v end })
SpeedGroup:AddSlider("SpeedHackValue", { Text="Speed Value", Default=50, Min=16, Max=500, Rounding=0, Callback=function(v) speedSettings.speedValue=v end })

FlyGroup = MoveTab:AddRightGroupbox("Fly")
FlyGroup:AddToggle("FlyToggle", { Text="Toggle Fly", Default=false, Callback=function(v) if v then StartFly(); CreateFlyMiniToggle() else StopFly(); DestroyFlyMiniToggle() end; flySettings.flyActive=v end })
FlyGroup:AddDropdown("FlyMode", { Values={"CFrame","Velocity","Swim","TP-Fast","Float","Tween"}, Default="CFrame", Text="Mode", Callback=function(v) flySettings.mode=v; if flySettings.flyActive then StopFly(); StartFly() end end })
FlyGroup:AddSlider("FlySpeed", { Text="Speed", Default=50, Min=10, Max=500, Rounding=0, Callback=function(v) flySettings.speed=v end })
FlyGroup:AddToggle("NoClipToggle", { Text="NoClip", Default=false, Callback=function(v) flySettings.noclipActive=v; if v then StartNoClip() else StopNoClip() end end })

DashGlitchGroup = MoveTab:AddRightGroupbox("Skull Guitar Dash")
DashGlitchGroup:AddToggle("DashGlitchToggle", { Text="Enable Dash Glitch", Default=false, Callback=function(v) DashGlitch:SetEnabled(v) end })
DashGlitchGroup:AddDropdown("DashGlitchVersion", { Values={"V1 (Auto)","V2 (Manual Tap)"}, Default="V1 (Auto)", Text="Version", Callback=function(v)
    local ver = v:match("^(%w+)")
    DashGlitch:SetVersion(ver)
end })
DashGlitchGroup:AddSlider("DashGlitchCooldown", { Text="Cooldown", Default=1.5, Min=0.2, Max=5, Rounding=1, Suffix="s", Callback=function(v) DashGlitch:SetCooldown(v) end })
DashGlitchGroup:AddSlider("DashGlitchDashLength", { Text="Dash Length", Default=190, Min=10, Max=500, Rounding=0, Callback=function(v) DashGlitch:SetDashLength(v) end })
DashGlitchGroup:AddSlider("DashGlitchSpeedBoost", { Text="Propulsion", Default=350, Min=50, Max=1000, Rounding=0, Callback=function(v) DashGlitch:SetSpeedBoost(v) end })
DashGlitchGroup:AddSlider("DashGlitchAirSpeed", { Text="Air Speed", Default=400, Min=50, Max=1000, Rounding=0, Callback=function(v) DashGlitch:SetAirWalkSpeed(v) end })

lp.CharacterAdded:Connect(function(char) if dashLengthEnabled then task.wait(0.1); char:SetAttribute("DashLength", dashLengthValue); char:SetAttribute("DashLengthAir", dashLengthValue) end end)

-- Apparence
ApparenceTab = Tabs.Apparence
HeadlessGroup = ApparenceTab:AddLeftGroupbox("Fake Headless")
HeadlessGroup:AddDropdown("HeadlessVersion", { Values={"V1","V2"}, Default="V1", Text="Version", Callback=function(v) fakeHeadlessVersion=v; if fakeHeadlessEnabled then removeFakeHeadless(); applyFakeHeadless() end end })
HeadlessGroup:AddToggle("HeadlessToggle", { Text="Enable Fake Headless", Default=false, Callback=function(v) fakeHeadlessEnabled=v; if v then applyFakeHeadless() else removeFakeHeadless() end end })

KorbloxGroup = ApparenceTab:AddRightGroupbox("Fake Korblox")
KorbloxGroup:AddDropdown("KorbloxVersion", { Values={"V1","V2"}, Default="V1", Text="Version", Callback=function(v) fakeKorbloxVersion=v; if fakeKorbloxEnabled then removeFakeKorblox(); applyFakeKorblox() end end })
KorbloxGroup:AddToggle("KorbloxToggle", { Text="Enable Fake Korblox", Default=false, Callback=function(v) fakeKorbloxEnabled=v; if v then applyFakeKorblox() else removeFakeKorblox() end end })

-- Misc
MiscTab = Tabs.Misc
FontChangerGroup = MiscTab:AddLeftGroupbox("Font Changer")
local fontList = {}
for _,v in Enum.Font:GetEnumItems() do table.insert(fontList, tostring(v):split(".")[3]) end
local function getCustomFonts()
    local list = {"None"}
    if listfiles and isfolder and isfolder("NamelessConfigs/Fonts") then
        for _,v in ipairs(listfiles("NamelessConfigs/Fonts")) do
            local filename = v:match("([^/\\]+)$")
            if filename:lower():find("%.ttf") or filename:lower():find("%.otf") then table.insert(list, filename) end
        end
    end
    return list
end
FontChangerGroup:AddDropdown("FontStyle", { Values=fontList, Default="GothamSsm", Text="Font Style", Callback=function(v) fontPreset=v; if fontChangerEnabled then disableFonts(); enableFonts() end end })
FontChangerGroup:AddDropdown("CustomFontFile", { Values=getCustomFonts(), Default="None", Text="Custom Font (.ttf)", Callback=function(val) loadCustomFont(val); if fontChangerEnabled then disableFonts(); enableFonts() end end })
FontChangerGroup:AddToggle("FontChangerToggle", { Text="Enable Font Changer", Default=false, Callback=function(v) fontChangerEnabled=v; if v then enableFonts() else disableFonts() end end })

AntiMoverGroup = MiscTab:AddRightGroupbox("Anti Mover")
AntiMoverGroup:AddToggle("AntiMoverToggle", { Text="Enable Anti Mover", Default=false, Callback=function(v)
    antiMoverEnabled=v
    if v then
        local function add(char) if not char:FindFirstChild("AntiMover") then Instance.new("Folder", char).Name="AntiMover" end end
        if lp.Character then add(lp.Character) end
        antiMoverConnection = lp.CharacterAdded:Connect(add)
    else
        if antiMoverConnection then antiMoverConnection:Disconnect(); antiMoverConnection=nil end
        if lp.Character and lp.Character:FindFirstChild("AntiMover") then lp.Character.AntiMover:Destroy() end
    end
end })

UnbreakableGroup = MiscTab:AddRightGroupbox("Unbreakable")
UnbreakableGroup:AddToggle("UnbreakableToggle", { Text="Enable Unbreakable", Default=false, Callback=function(v)
    unbreakableEnabled=v
    if v then
        if unbreakableConnection then task.cancel(unbreakableConnection) end
        unbreakableConnection = task.spawn(function()
            while unbreakableEnabled do task.wait(0.1); if lp.Character and lp.Character:GetAttribute("UnbreakableAll")~=true then lp.Character:SetAttribute("UnbreakableAll", true) end end
        end)
    else
        if unbreakableConnection then task.cancel(unbreakableConnection); unbreakableConnection=nil end
        if lp.Character then lp.Character:SetAttribute("UnbreakableAll", false) end
    end
end })

NoGFXGroup = MiscTab:AddRightGroupbox("No GFX")
NoGFXGroup:AddDropdown("NoGFXMode", { Values={"Off","V1","V2"}, Default="Off", Text="No GFX Mode", Callback=function(v) setNoGfxMode(v) end })

DeleteShipGroup = MiscTab:AddLeftGroupbox("Delete Ship")
DeleteShipGroup:AddToggle("DeleteShipToggle", { Text="Enable Delete Ship", Default=false, Callback=function(v)
    deleteShipActive = v
    if v then startDeleteShipLoop() end
end })

WalkOnWaterGroup = MiscTab:AddLeftGroupbox("Walk on Water")
WalkOnWaterGroup:AddToggle("WalkOnWaterToggle", { Text="Enable Walk on Water", Default=false, Callback=function(v) WalkOnWaterEnabled = v end })

AntiLavaGroup = MiscTab:AddLeftGroupbox("Anti Lava")
AntiLavaGroup:AddToggle("AntiLavaToggle", { Text="Enable Anti Lava", Default=false, Callback=function(v)
    antiLavaActive = v
    if v then startAntiLava() else stopAntiLava() end
end })

-- ESP
ESPTab = Tabs.ESP
ESPGroup = ESPTab:AddLeftGroupbox("ESP Settings")
ESPVisualGroup = ESPTab:AddRightGroupbox("ESP Appearance")

ESPGroup:AddToggle("ESPToggle", { Text="Enable ESP", Default=false, Callback=function(v) ESPModule:SetESPEnabled(v) end })
ESPGroup:AddToggle("ShowBox", { Text="Show Box", Default=true, Callback=function(v) ESPModule:SetShowBox(v) end })
ESPGroup:AddToggle("ShowName", { Text="Show Name", Default=true, Callback=function(v) ESPModule:SetShowName(v) end })
ESPGroup:AddToggle("ShowDistance", { Text="Show Distance", Default=true, Callback=function(v) ESPModule:SetShowDistance(v) end })
ESPGroup:AddToggle("ShowHealth", { Text="Show Health Bar", Default=true, Callback=function(v) ESPModule:SetShowHealth(v) end })
ESPGroup:AddToggle("ShowAllPlayers", { Text="Show All Players", Default=false, Callback=function(v) ESPModule:SetShowAllPlayers(v) end })
ESPGroup:AddDropdown("LineOrigin", { Values={"Player","Center","Top"}, Default="Player", Text="Line Origin", Callback=function(v) ESPModule:SetLineOrigin(v) end })

ESPVisualGroup:AddToggle("ShowLine", { Text="Show Tracers (Lines)", Default=true, Callback=function(v) ESPModule:SetShowLine(v) end })
ESPVisualGroup:AddDropdown("BoxColor", { Values={"Red","Green","Blue","Yellow","White","Cyan","Magenta"}, Default="Red", Text="Box Color", Callback=function(v) ESPModule:SetBoxColor(v) end })
ESPVisualGroup:AddDropdown("TextColor", { Values={"Red","Green","Blue","Yellow","White","Cyan","Magenta"}, Default="White", Text="Text Color", Callback=function(v) ESPModule:SetTextColor(v) end })
ESPVisualGroup:AddDropdown("LineColor", { Values={"Red","Green","Blue","Yellow","White","Cyan","Magenta"}, Default="Red", Text="Line Color", Callback=function(v) ESPModule:SetLineColor(v) end })

-- Silent Aim (on a supprimÃ© les toggles et sliders inutiles)
SA = Tabs.SilentAim
MainGroup = SA:AddLeftGroupbox("Main")
MainGroup:AddToggle("EnablePlayerAim", { Text="Player Silent Aim", Default=false, Callback=function(v) SilentAimModule:SetPlayerSilentAim(v) end })
MainGroup:AddToggle("EnableNPCAim", { Text="NPC Silent Aim", Default=false, Callback=function(v) SilentAimModule:SetNPCSilentAim(v) end })
-- Plus de toggle Prediction, plus de slider Prediction Amount, plus de toggle Godhuman Sl

TargetGroup = SA:AddLeftGroupbox("Target Settings")
TargetGroup:AddDropdown("AimModeSelection", { Values={"360","180","FOV"}, Default="360", Text="Aim Angle Mode", Callback=function(v) SilentAimModule:SetAimMode(v) end })
TargetGroup:AddDropdown("PrioritySelection", { Values={"Nearest","Low HP","Looking At Me","Lock Player"}, Default="Nearest", Text="Target Priority", Callback=function(v) SilentAimModule:SetTargetPriority(v) end })

FOVGroup = SA:AddLeftGroupbox("FOV Settings")
FOVGroup:AddToggle("ShowFOVCircle", { Text="Show FOV Circle", Default=false, Callback=function(v) SilentAimModule:SetShowFOVCircle(v) end })
FOVGroup:AddDropdown("FOVModeSelection", { Values={"V1","V2"}, Default="V1", Text="FOV Mode", Callback=function(v) SilentAimModule:SetFOVMode(v) end })
FOVGroup:AddSlider("FOVRadiusSize", { Text="FOV Radius Size", Default=100, Min=10, Max=800, Rounding=0, Callback=function(v) SilentAimModule:SetFOVRadius(v) end })

M1ExtGroup = SA:AddRightGroupbox("M1 Extender")
M1ExtGroup:AddToggle("M1ExtenderToggle", { Text="Enable M1 Extender", Default=false, Callback=function(v) M1Extender:Toggle(v) end })
M1ExtGroup:AddSlider("M1ExtenderRange", { Text="Extender Range", Default=50, Min=10, Max=100, Rounding=0, Callback=function(v) M1Extender:SetRange(v) end })

GunGroup = SA:AddRightGroupbox("Gun Click SL")
GunGroup:AddToggle("GunClickSLToggle", { Text="Enable Gun Click SL", Default=false, Callback=function(v) GunClickSL:SetEnabled(v) end })

OptionsGroup = SA:AddRightGroupbox("Options")
PlayerDropdown = OptionsGroup:AddDropdown("LockPlayerSelect", { Values={"None"}, Default="None", Text="Target Player List", Callback=function(v) SilentAimModule:SetSelectedPlayer(v) end })
local function refreshPlayerList()
    local list = {"None"}
    for _,p in ipairs(Players:GetPlayers()) do if p~=lp then table.insert(list, p.Name) end end
    PlayerDropdown:SetValues(list)
end
task.spawn(function() while true do refreshPlayerList(); task.wait(5) end end)
OptionsGroup:AddButton("Refresh Player List", refreshPlayerList)
OptionsGroup:AddSlider("MaxRange", { Text="Max Range", Default=1000, Min=100, Max=3000, Rounding=0, Suffix="m", Callback=function(v) SilentAimModule:SetDistanceLimit(v) end })
OptionsGroup:AddToggle("EnableTracer", { Text="Enable Tracer", Default=false, Callback=function(v) SilentAimModule:SetTracerEnabled(v) end })
OptionsGroup:AddDropdown("TracerColor", { Values={"Red","Green","Blue","Yellow","White"}, Default="Red", Text="Tracer Color", Callback=function(v) SilentAimModule:SetTracerColor(v) end })

-- SA Blacklist
BLTab = Tabs.SABlacklist
BlacklistLeft = BLTab:AddLeftGroupbox("Blacklist Melee & Fruit")
BlacklistRight = BLTab:AddRightGroupbox("Blacklist Swords & Guns")

BlacklistLeft:AddLabel("--- MELEES ---")
for _,key in ipairs({"Z","X","C"}) do
    BlacklistLeft:AddToggle("B_Melee_"..key, { Text="Melee: Blacklist "..key, Default=false, Callback=function(v) SilentAimModule:SetBlacklistKey("Melee", key, v) end })
end
BlacklistLeft:AddLabel("--- FRUITS ---")
for _,key in ipairs({"Z","X","C","V","F","TAP"}) do
    BlacklistLeft:AddToggle("B_Fruit_"..key, { Text="Fruit: Blacklist "..key, Default=false, Callback=function(v) SilentAimModule:SetBlacklistKey("Fruit", key, v) end })
end
BlacklistRight:AddLabel("--- SWORDS ---")
for _,key in ipairs({"Z","X"}) do
    BlacklistRight:AddToggle("B_Sword_"..key, { Text="Sword: Blacklist "..key, Default=false, Callback=function(v) SilentAimModule:SetBlacklistKey("Sword", key, v) end })
end
BlacklistRight:AddLabel("--- GUNS ---")
for _,key in ipairs({"Z","X"}) do
    BlacklistRight:AddToggle("B_Gun_"..key, { Text="Gun: Blacklist "..key, Default=false, Callback=function(v) SilentAimModule:SetBlacklistKey("Gun", key, v) end })
end

-- Settings
local function closeTheScript()
    _G.NamelessLoaded = false
    _G.NamelessAuthToken = nil
    _G.NamelessScriptBasiqueRunning = nil
    _G.NamelessAHKRunning = nil
    _G.NamelessComboRunning = nil

    pcall(UnloadAHKsoru)
    pcall(UnloadAHKComboScript)

    pcall(function() Library:Unload() end)

    pcall(function()
        local containers = {lp:FindFirstChild("PlayerGui"), game:GetService("CoreGui")}
        if get_hidden_gui then table.insert(containers, get_hidden_gui()) end
        for _, parent in ipairs(containers) do
            if parent then
                for _, g in pairs(parent:GetChildren()) do
                    if g:IsA("ScreenGui") and (g.Name:find("Nameless") or g.Name:find("nameless") or g.Name:find("AHK") or g.Name:find("NM_Notify") or g.Name:find("Obsidian") or g.Name:find("Linoria")) then
                        g:Destroy()
                    end
                end
            end
        end
    end)
end

MenuGroup = Tabs.Settings:AddLeftGroupbox("Menu")
MenuGroup:AddButton("Unload", function() Library:Unload() end)
MenuGroup:AddButton("Close The Script", closeTheScript)
MenuGroup:AddLabel("Menu bind"):AddKeyPicker("MenuKeybind", { Default="End", NoUI=true, Text="Menu keybind" })
Library.ToggleKeybind = Options.MenuKeybind

ThemeManager:SetLibrary(Library)
SaveManager:SetLibrary(Library)
SaveManager:IgnoreThemeSettings()
SaveManager:SetIgnoreIndexes({"MenuKeybind"})
ThemeManager:SetFolder("LinoriaMobile")
SaveManager:SetFolder("LinoriaMobile/game")
ThemeManager:ApplyToGroupbox(MenuGroup)
SaveManager:BuildConfigSection(Tabs.Settings)

SaveManager:LoadAutoloadConfig()
task.wait(0.5)
for _,cat in ipairs({"Melee","Sword","Fruit","Gun"}) do
    local keys = {}
    if cat=="Melee" then keys={"Z","X","C"} elseif cat=="Sword" then keys={"Z","X"} elseif cat=="Fruit" then keys={"Z","X","C","V","F","TAP"} elseif cat=="Gun" then keys={"Z","X"} end
    for _,key in ipairs(keys) do
        local toggleName = "B_"..cat.."_"..key
        if Options[toggleName] then SilentAimModule:SetBlacklistKey(cat, key, Options[toggleName].Value) end
    end
end

-- ==================== CHAT COMMANDS ====================
local function onChatted(msg)
    local msgLower = msg:lower()
    if not msgLower:match("^/e%s+") then return end
    
    local command = msgLower:gsub("^/e%s+", ""):gsub("%s+", " "):gsub("^%s*(.-)%s*$", "%1")
    
    if command == "hide" then
        if Library.ScreenGui then
            Library.ScreenGui.Enabled = false
        end
    elseif command == "unhide" or command == "show" then
        if Library.ScreenGui then
            Library.ScreenGui.Enabled = true
        end
    end
end

lp.Chatted:Connect(onChatted)
