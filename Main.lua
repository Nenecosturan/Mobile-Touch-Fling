--[[
    Universal Mobile Touch-Fling v9.0 (God-Walk Edition)
    Fixes: 100% Recoil Removal, Self-Fling on Impact
    Method: Linear Velocity Override (Physics Bypass)
    Author: Nenecosturan / Optimized by Gemini
]]

local TweenService = game:GetService("TweenService")
local CoreGui = game:GetService("CoreGui")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local LocalPlayer = Players.LocalPlayer
local HttpService = game:GetService("HttpService")

-------------------------------------------------------------------------
-- [SECURITY MODULE]
-------------------------------------------------------------------------
local Security = {}

function Security.GenerateRandomName()
    return HttpService:GenerateGUID(false):sub(1, 10)
end

function Security.ProtectGUI(guiObject)
    if syn and syn.protect_gui then
        syn.protect_gui(guiObject)
        guiObject.Parent = CoreGui
    elseif gethui then
        guiObject.Parent = gethui()
    else
        pcall(function() guiObject.Parent = CoreGui end)
        if guiObject.Parent ~= CoreGui then guiObject.Parent = LocalPlayer:WaitForChild("PlayerGui") end
    end
end

function Security.ResetCharacter(char)
    if not char then return end
    local rootPart = char:FindFirstChild("HumanoidRootPart")
    
    if rootPart then
        rootPart.AssemblyAngularVelocity = Vector3.zero
        rootPart.CustomPhysicalProperties = PhysicalProperties.new(0.7, 0.3, 0.5, 1, 1)
    end
    -- Noclip kapat
    for _, part in pairs(char:GetDescendants()) do
        if part:IsA("BasePart") then part.CanCollide = true end
    end
end

-------------------------------------------------------------------------
-- [UI SYSTEM]
-------------------------------------------------------------------------
local function ShowToastNotification(message, isError)
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = Security.GenerateRandomName()
    screenGui.IgnoreGuiInset = true
    Security.ProtectGUI(screenGui)

    local toastFrame = Instance.new("Frame")
    toastFrame.Name = "Toast"
    toastFrame.Parent = screenGui
    toastFrame.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
    toastFrame.BackgroundTransparency = 0.1
    toastFrame.Position = UDim2.new(0.5, 0, 0.85, 0)
    toastFrame.AnchorPoint = Vector2.new(0.5, 1)
    toastFrame.Size = UDim2.new(0, 0, 0, 45)
    toastFrame.ClipsDescendants = true
    
    local uiCorner = Instance.new("UICorner")
    uiCorner.CornerRadius = UDim.new(1, 0)
    uiCorner.Parent = toastFrame

    local uiStroke = Instance.new("UIStroke")
    uiStroke.Parent = toastFrame
    uiStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    uiStroke.Color = isError and Color3.fromRGB(255, 50, 50) or Color3.fromRGB(255, 170, 0) -- Turuncu (God Mode)
    uiStroke.Thickness = 1.5
    uiStroke.Transparency = 0.3

    local contentFrame = Instance.new("Frame")
    contentFrame.Parent = toastFrame
    contentFrame.Size = UDim2.new(1, 0, 1, 0)
    contentFrame.BackgroundTransparency = 1
    contentFrame.Visible = false

    local label = Instance.new("TextLabel")
    label.Parent = contentFrame
    label.Size = UDim2.new(1, 0, 1, 0)
    label.BackgroundTransparency = 1
    label.Font = Enum.Font.GothamMedium
    label.Text = message
    label.TextColor3 = Color3.fromRGB(255, 255, 255)
    label.TextSize = 14
    label.TextTransparency = 1

    local targetWidth = #message * 8 + 40
    local expandTween = TweenService:Create(toastFrame, TweenInfo.new(0.4, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {Size = UDim2.new(0, targetWidth, 0, 45), Position = UDim2.new(0.5, 0, 0.85, 0)})
    expandTween:Play()

    expandTween.Completed:Connect(function()
        contentFrame.Visible = true
        TweenService:Create(label, TweenInfo.new(0.3), {TextTransparency = 0}):Play()
    end)

    task.delay(2.5, function()
        TweenService:Create(label, TweenInfo.new(0.2), {TextTransparency = 1}):Play()
        local closeTween = TweenService:Create(toastFrame, TweenInfo.new(0.4, Enum.EasingStyle.Quint, Enum.EasingDirection.In), {Size = UDim2.new(0, 0, 0, 45), Position = UDim2.new(0.5, 0, 0.9, 0)})
        closeTween:Play()
        closeTween.Completed:Connect(function() screenGui:Destroy() end)
    end)
end

-------------------------------------------------------------------------
-- [MAIN LOGIC] - GOD-WALK PHYSICS
-------------------------------------------------------------------------
local success, errorMessage = pcall(function()
    
    local function createFlingUI()
        local screenGui = Instance.new("ScreenGui")
        screenGui.Name = Security.GenerateRandomName()
        screenGui.ResetOnSpawn = false
        Security.ProtectGUI(screenGui)

        local mainFrame = Instance.new("TextButton")
        mainFrame.Name = "Main"
        mainFrame.Parent = screenGui
        mainFrame.BackgroundColor3 = Color3.fromRGB(12, 12, 12)
        mainFrame.Position = UDim2.new(0.4, 0, 0.3, 0)
        mainFrame.Size = UDim2.new(0, 160, 0, 60)
        mainFrame.Text = ""
        mainFrame.AutoButtonColor = false
        
        local uiCorner = Instance.new("UICorner")
        uiCorner.CornerRadius = UDim.new(0, 14)
        uiCorner.Parent = mainFrame

        local uiStroke = Instance.new("UIStroke")
        uiStroke.Parent = mainFrame
        uiStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
        uiStroke.Color = Color3.fromRGB(255, 50, 50)
        uiStroke.Thickness = 2
        uiStroke.Transparency = 0.2

        local statusLabel = Instance.new("TextLabel")
        statusLabel.Parent = mainFrame
        statusLabel.Size = UDim2.new(1, 0, 1, 0)
        statusLabel.BackgroundTransparency = 1
        statusLabel.Text = "FLING: OFF"
        statusLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
        statusLabel.TextSize = 18
        statusLabel.Font = Enum.Font.GothamBold

        return mainFrame, uiStroke, statusLabel, screenGui
    end

    local button, stroke, label, gui = createFlingUI()

    -- DRAG LOGIC
    local dragging, dragInput, dragStart, startPos
    local hasMoved = false

    local function update(input)
        local delta = input.Position - dragStart
        if delta.Magnitude > 2 then hasMoved = true end
        button.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    end

    button.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            hasMoved = false
            dragStart = input.Position
            startPos = button.Position
            input.Changed:Connect(function() if input.UserInputState == Enum.UserInputState.End then dragging = false end end)
        end
    end)

    button.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then dragInput = input end
    end)

    UserInputService.InputChanged:Connect(function(input) if input == dragInput and dragging then update(input) end end)

    -- MANTIK
    local flingActive = false
    local rotVelocity = Vector3.new(0, 25000, 0)
    
    local function toggleFling()
        if hasMoved then return end
        flingActive = not flingActive
        local char = LocalPlayer.Character
        
        if flingActive then
            TweenService:Create(stroke, TweenInfo.new(0.3), {Color = Color3.fromRGB(255, 170, 0)}):Play() -- Turuncu
            label.Text = "FLING: ON"
            label.TextColor3 = Color3.fromRGB(255, 200, 100)
        else
            TweenService:Create(stroke, TweenInfo.new(0.3), {Color = Color3.fromRGB(255, 50, 50)}):Play()
            label.Text = "FLING: OFF"
            label.TextColor3 = Color3.fromRGB(200, 200, 200)
            Security.ResetCharacter(char)
        end
    end

    button.MouseButton1Up:Connect(toggleFling)

    -- [PHYSICS OVERRIDE - HEARTBEAT]
    RunService.Heartbeat:Connect(function()
        if not flingActive then return end
        
        local character = LocalPlayer.Character
        if not character then return end
        local rootPart = character:FindFirstChild("HumanoidRootPart")
        local humanoid = character:FindFirstChild("Humanoid")
        if not rootPart or not humanoid then return end

        -- 1. YAKINLIK KONTROLÜ (Lag olmaması için)
        local targetFound = false
        local myPos = rootPart.Position
        
        for _, player in pairs(Players:GetPlayers()) do
            if player ~= LocalPlayer and player.Character then
                local tRoot = player.Character:FindFirstChild("HumanoidRootPart")
                if tRoot and (myPos - tRoot.Position).Magnitude < 7 then
                    targetFound = true
                    
                    -- Fling Dönüşü (Silahımız)
                    rootPart.AssemblyAngularVelocity = rotVelocity
                    
                    -- Noclip (Çarpışma kapalı - Hayalet Modu)
                    for _, p in pairs(character:GetChildren()) do
                        if p:IsA("BasePart") then p.CanCollide = false end
                    end
                end
            end
        end
        
        -- 2. HIZ KONTROLÜ (KALKANIMIZ - Geri Tepme Önleyici)
        -- Eğer Fling aktifse (hedef olsun olmasın), senin hareketini fiziğe değil, joystiğe kilitliyoruz.
        if targetFound then
            -- Joystick yönünü al
            local moveDir = humanoid.MoveDirection
            -- Senin yürümek istediğin hız
            local walkSpeed = humanoid.WalkSpeed
            
            -- Hızı MANUEL olarak ayarla. Fizik motorunu ez geç.
            -- Y eksenini (Zıplama) korumak için Velocity.Y'ye dokunmuyoruz, sadece X ve Z (Yürüme)
            local currentY = rootPart.AssemblyLinearVelocity.Y
            
            -- Eğer zıplamıyorsan yere sabitle (Roket önleyici)
            if math.abs(currentY) > 5 and humanoid:GetState() ~= Enum.HumanoidStateType.Jumping and humanoid:GetState() ~= Enum.HumanoidStateType.Freefall then
                currentY = 0 -- Uçuşu iptal et
            end

            rootPart.AssemblyLinearVelocity = Vector3.new(
                moveDir.X * walkSpeed, -- Sadece senin bastığın yöne git
                currentY,              -- Zıplamaya izin ver ama uçmaya izin verme
                moveDir.Z * walkSpeed  -- Sadece senin bastığın yöne git
            )
            
            -- Ağırlık Ayarı (Düşmana vurunca hissetmesi için)
            rootPart.CustomPhysicalProperties = PhysicalProperties.new(100, 0, 0, 0, 0)
        else
            -- Hedef yoksa dönmeyi durdur
            rootPart.AssemblyAngularVelocity = Vector3.zero
            if rootPart.CustomPhysicalProperties.Density == 100 then
                 rootPart.CustomPhysicalProperties = PhysicalProperties.new(0.7, 0.3, 0.5, 1, 1)
            end
        end
    end)
    
    -- [GÖRSEL SABİTLEME]
    RunService.RenderStepped:Connect(function()
        if flingActive and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
             -- Karakterin dönüşünü kamera açısına kitlemeyi buraya ekleyebilirsin
             -- Ancak v8'deki visual glitch olmaması için burayı sade bıraktım.
        end
    end)
end)

if success then
    ShowToastNotification("Latest Version Executed", false)
else
    ShowToastNotification("Script Failed", true)
    warn(errorMessage)
end
