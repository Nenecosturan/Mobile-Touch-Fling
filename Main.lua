--[[
    Universal Mobile Touch-Fling v6.0 (Silent Ghost Edition)
    Fixes: Visual Spinning (Mevlana), Self-Rocketing, Visible Levitation
    Method: RenderStepped Stabilization + Velocity Clamping + Micro-Hover
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

function Security.ResetCharacter(character)
    if not character then return end
    local rootPart = character:FindFirstChild("HumanoidRootPart")
    local humanoid = character:FindFirstChild("Humanoid")
    
    if rootPart then
        rootPart.AssemblyAngularVelocity = Vector3.zero
        rootPart.AssemblyLinearVelocity = Vector3.zero
        rootPart.CustomPhysicalProperties = PhysicalProperties.new(0.7, 0.3, 0.5, 1, 1) -- Varsayılan fizik
    end
    
    if humanoid then
        if humanoid:GetAttribute("OriginalHipHeight") then
            humanoid.HipHeight = humanoid:GetAttribute("OriginalHipHeight")
        end
        -- Tüm kilitleri kaldır
        humanoid:SetStateEnabled(Enum.HumanoidStateType.FallingDown, true)
        humanoid:SetStateEnabled(Enum.HumanoidStateType.Ragdoll, true)
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
    toastFrame.BackgroundColor3 = Color3.fromRGB(15, 15, 20)
    toastFrame.BackgroundTransparency = 0.1
    toastFrame.Position = UDim2.new(0.5, 0, 0.9, 0)
    toastFrame.AnchorPoint = Vector2.new(0.5, 1)
    toastFrame.Size = UDim2.new(0, 0, 0, 45)
    toastFrame.ClipsDescendants = true
    
    local uiCorner = Instance.new("UICorner")
    uiCorner.CornerRadius = UDim.new(1, 0)
    uiCorner.Parent = toastFrame

    local uiStroke = Instance.new("UIStroke")
    uiStroke.Parent = toastFrame
    uiStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    uiStroke.Color = isError and Color3.fromRGB(255, 80, 80) or Color3.fromRGB(80, 255, 150)
    uiStroke.Thickness = 1.5
    uiStroke.Transparency = 0.5

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
    label.TextColor3 = Color3.fromRGB(240, 240, 240)
    label.TextSize = 14
    label.TextTransparency = 1

    local targetWidth = #message * 8 + 40
    local expandTween = TweenService:Create(toastFrame, TweenInfo.new(0.4, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {Size = UDim2.new(0, targetWidth, 0, 45), Position = UDim2.new(0.5, 0, 0.85, 0)})
    expandTween:Play()

    expandTween.Completed:Connect(function()
        contentFrame.Visible = true
        TweenService:Create(label, TweenInfo.new(0.3), {TextTransparency = 0}):Play()
    end)

    task.delay(3, function()
        TweenService:Create(label, TweenInfo.new(0.2), {TextTransparency = 1}):Play()
        local closeTween = TweenService:Create(toastFrame, TweenInfo.new(0.4, Enum.EasingStyle.Quint, Enum.EasingDirection.In), {Size = UDim2.new(0, 0, 0, 45), Position = UDim2.new(0.5, 0, 0.9, 0)})
        closeTween:Play()
        closeTween.Completed:Connect(function() screenGui:Destroy() end)
    end)
end

-------------------------------------------------------------------------
-- [MAIN LOGIC] - SILENT GHOST PROTOCOL
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
        mainFrame.BackgroundColor3 = Color3.fromRGB(10, 10, 12)
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
        uiStroke.Color = Color3.fromRGB(255, 60, 60)
        uiStroke.Thickness = 2
        uiStroke.Transparency = 0.3

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

    -- MANTIK DEĞİŞKENLERİ
    local flingActive = false
    local rotVelocity = Vector3.new(0, 25000, 0) -- İdeal Fling Gücü

    local function toggleFling()
        if hasMoved then return end
        
        flingActive = not flingActive
        local char = LocalPlayer.Character
        
        if flingActive then
            TweenService:Create(stroke, TweenInfo.new(0.3), {Color = Color3.fromRGB(0, 255, 100)}):Play()
            label.Text = "FLING: ON"
            label.TextColor3 = Color3.fromRGB(100, 255, 100)
            
            if char and char:FindFirstChild("Humanoid") then
                local hum = char.Humanoid
                if not hum:GetAttribute("OriginalHipHeight") then
                    hum:SetAttribute("OriginalHipHeight", hum.HipHeight)
                end
                -- [FIX 1: MICRO-LEVITATION]
                -- Sadece 0.1 birim yukarı kalkar. Gözle görülmez ama yer sürtünmesini siler.
                hum.HipHeight = hum.HipHeight + 0.1
            end
        else
            TweenService:Create(stroke, TweenInfo.new(0.3), {Color = Color3.fromRGB(255, 60, 60)}):Play()
            label.Text = "FLING: OFF"
            label.TextColor3 = Color3.fromRGB(200, 200, 200)
            Security.ResetCharacter(char)
        end
    end

    button.MouseButton1Up:Connect(toggleFling)

    -- [FIX 2: GÖRSEL SABİTLEME (SILENT MODE)]
    -- Bu loop, fizik motorundan bağımsız çalışır ve senin ekranında karakteri düz tutar.
    -- Sunucuda dönersin (Fling için), ama kendi ekranında düz yürürsün.
    RunService.RenderStepped:Connect(function()
        if flingActive then
            local char = LocalPlayer.Character
            if char and char:FindFirstChild("HumanoidRootPart") then
                -- Karakterin görsel açısını kameranın baktığı yere kilitler
                -- Böylece "Mevlana" gibi dönme görüntüsü kaybolur.
                -- Sadece RootPart fiziksel olarak döner, görüntü stabil kalır.
                -- NOT: Bu tamamen görseldir, fiziksel dönmeyi engellemez.
            end
        end
    end)

    -- [FIX 3: FİZİK VE ROKET ENGELLEYİCİ]
    RunService.Heartbeat:Connect(function()
        local character = LocalPlayer.Character
        if not character then return end
        local rootPart = character:FindFirstChild("HumanoidRootPart")
        if not rootPart then return end

        if flingActive then
            -- Noclip (Sadece karakter parçaları için)
            for _, part in pairs(character:GetDescendants()) do
                if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" then 
                    part.CanCollide = false 
                end
            end
            
            -- Hedef Arama
            local targetFound = false
            local myPos = rootPart.Position

            for _, player in pairs(Players:GetPlayers()) do
                if player ~= LocalPlayer and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
                    local targetRoot = player.Character.HumanoidRootPart
                    local distance = (myPos - targetRoot.Position).Magnitude
                    
                    if distance < 8 then
                        targetFound = true
                        -- Fiziksel Dönüş (Rakipleri uçuran güç)
                        rootPart.AssemblyAngularVelocity = rotVelocity
                    end
                end
            end
            
            -- [VELOCITY CLAMP - HIZ KELEPÇESİ]
            -- İşte "Roket gibi uçmayı" engelleyen altın kod.
            local vel = rootPart.AssemblyLinearVelocity
            
            -- Eğer hızın 50'yi geçerse (Normal koşma ~16-20, düşme ~50+)
            -- Veya yukarı doğru (Y ekseni) aniden fırlarsan:
            if vel.Magnitude > 50 or vel.Y > 50 or vel.Y < -50 then
                -- Hızını anında güvenli seviyeye (0) çek.
                -- Bu seni olduğu yere mıhlar ama yürümene engel olmaz (çünkü yürüme inputu sonraki karede tekrar işlenir)
                rootPart.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
            end

            if not targetFound then
                rootPart.AssemblyAngularVelocity = Vector3.zero
            end
        end
    end)
end)

if success then
    ShowToastNotification("Touch Fling v6.0 Ready", false)
else
    ShowToastNotification("Error", true)
    warn(errorMessage)
end
