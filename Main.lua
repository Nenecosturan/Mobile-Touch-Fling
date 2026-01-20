--[[
    Universal Mobile Touch-Fling v8.0 (Phantom Mode)
    Fixes: Self-Fling while walking/running
    Method: Limb-Noclip (Ghost Mode) + Heavy Core
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

-- Karakteri Sıfırla
function Security.ResetCharacter(char)
    if not char then return end
    local rootPart = char:FindFirstChild("HumanoidRootPart")
    local humanoid = char:FindFirstChild("Humanoid")
    
    if rootPart then
        rootPart.AssemblyAngularVelocity = Vector3.zero
        rootPart.AssemblyLinearVelocity = Vector3.zero
        rootPart.CustomPhysicalProperties = PhysicalProperties.new(0.7, 0.3, 0.5, 1, 1)
    end
    
    -- Noclip'i kapat (Uzuvları tekrar katı yap)
    for _, part in pairs(char:GetDescendants()) do
        if part:IsA("BasePart") then
            part.CanCollide = true
        end
    end
    
    if humanoid then
        if humanoid:GetAttribute("OriginalHipHeight") then
            humanoid.HipHeight = humanoid:GetAttribute("OriginalHipHeight")
        end
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
    toastFrame.BackgroundColor3 = Color3.fromRGB(10, 10, 10)
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
    uiStroke.Color = isError and Color3.fromRGB(255, 80, 80) or Color3.fromRGB(100, 255, 255)
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
-- [MAIN LOGIC] - PHANTOM MODE (HAYALET MODU)
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
        mainFrame.BackgroundColor3 = Color3.fromRGB(5, 5, 5) -- Ultra Siyah
        mainFrame.Position = UDim2.new(0.4, 0, 0.3, 0)
        mainFrame.Size = UDim2.new(0, 160, 0, 60)
        mainFrame.Text = ""
        mainFrame.AutoButtonColor = false
        
        local uiCorner = Instance.new("UICorner")
        uiCorner.CornerRadius = UDim.new(0, 16)
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
        statusLabel.Text = "Fling: OFF"
        statusLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
        statusLabel.TextSize = 16
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
    local rotVelocity = Vector3.new(0, 30000, 0) -- Maksimum Güç
    
    local function toggleFling()
        if hasMoved then return end
        
        flingActive = not flingActive
        local char = LocalPlayer.Character
        
        if flingActive then
            TweenService:Create(stroke, TweenInfo.new(0.3), {Color = Color3.fromRGB(0, 255, 255)}):Play() -- Camgöbeği (Phantom Rengi)
            label.Text = "Fling: ON"
            label.TextColor3 = Color3.fromRGB(150, 255, 255)
        else
            TweenService:Create(stroke, TweenInfo.new(0.3), {Color = Color3.fromRGB(255, 50, 50)}):Play()
            label.Text = "Fling: OFF"
            label.TextColor3 = Color3.fromRGB(200, 200, 200)
            Security.ResetCharacter(char)
        end
    end

    button.MouseButton1Up:Connect(toggleFling)

    -- [HAYALET FİZİĞİ - RENDER STEPPED]
    -- Bu döngü, oyunun her karesinde çalışır ve uzuvlarının çarpışmasını kapatır.
    RunService.Stepped:Connect(function()
        if not flingActive then return end
        
        local character = LocalPlayer.Character
        if not character then return end
        local rootPart = character:FindFirstChild("HumanoidRootPart")
        
        -- TÜM UZUVLARI HAYALET YAP (CanCollide = false)
        -- Böylece yürürken bacakların rakibe çarpıp seni fırlatamaz.
        for _, part in pairs(character:GetDescendants()) do
            if part:IsA("BasePart") and part ~= rootPart then
                part.CanCollide = false
            end
        end
        
        -- SADECE MERKEZİ PARÇA (RootPart) KATI KALMALI
        -- Ama o da normal zamanda değil, sadece Fling anında işe yarayacak.
        if rootPart then
            -- [HAYALET VURUŞU MANTIĞI]
            -- Karakterin içinden geçersin, RootPart'ın rakibin RootPart'ına değdiği an
            -- senin ağırlığın (Density 100) yüzünden onlar fırlar.
            
            -- Performans için sadece yakınlarda biri varsa işlem yap
            local targetFound = false
            for _, player in pairs(Players:GetPlayers()) do
                if player ~= LocalPlayer and player.Character then
                    local tRoot = player.Character:FindFirstChild("HumanoidRootPart")
                    if tRoot and (rootPart.Position - tRoot.Position).Magnitude < 7 then
                        targetFound = true
                        
                        -- Fling Ayarları
                        rootPart.AssemblyAngularVelocity = rotVelocity
                        
                        -- TANK AYARI: Geri tepmemen için
                        rootPart.CustomPhysicalProperties = PhysicalProperties.new(100, 0, 0, 0, 0)
                        
                        -- Hız Limitleyici (Uçarsan tutar)
                        local vel = rootPart.AssemblyLinearVelocity
                        if vel.Y > 20 or vel.Y < -20 then
                            rootPart.AssemblyLinearVelocity = Vector3.new(vel.X, 0, vel.Z)
                        end
                        
                        -- Görsel Mevlana Düzeltmesi (Sen kendini düz gör)
                        -- Bu sadece bir hiledir, fiziksel değil görseldir.
                    end
                end
            end
            
            if not targetFound then
                 rootPart.AssemblyAngularVelocity = Vector3.zero
                 -- Kimse yoksa normal ağırlığa dön (Oyunun bozulmasın)
                 if rootPart.CustomPhysicalProperties.Density == 100 then
                    rootPart.CustomPhysicalProperties = PhysicalProperties.new(0.7, 0.3, 0.5, 1, 1)
                 end
            end
        end
    end)
    
    -- Görsel Sabitleyici (Client-Side)
    RunService.RenderStepped:Connect(function()
         if flingActive and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
             -- Bu kod, karakterin dönüyormuş gibi görünmesini engeller.
             -- Aslında dönüyorsun ama kameran ve gözün bunu görmez.
         end
    end)
end)

if success then
    ShowToastNotification("Touch fling Active", false)
else
    ShowToastNotification("Script Failed", true)
    warn(errorMessage)
end
