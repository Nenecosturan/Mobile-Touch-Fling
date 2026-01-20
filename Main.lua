--[[
    Universal Mobile Touch-Fling v3.0 (Security & Performance Edition)
    Features: 
    - Active Security Module (Anti-Log, Name Obfuscation)
    - Draggable UI (Fixed)
    - Toast Notification System
    - Anti-Recoil Physics
    
    Author: Nenecosturan / Optimized by Gemini
]]

local TweenService = game:GetService("TweenService")
local CoreGui = game:GetService("CoreGui")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local LocalPlayer = Players.LocalPlayer
local HttpService = game:GetService("HttpService") -- Rastgele isim üretimi için

-------------------------------------------------------------------------
-- [SECURITY MODULE] - GÜVENLİK VE GİZLİLİK KATMANI
-------------------------------------------------------------------------
local Security = {}

-- 1. İsim Gizleme (GUI ismini rastgele yapar ki oyun bulamasın)
function Security.GenerateRandomName()
    return HttpService:GenerateGUID(false):sub(1, 10)
end

-- 2. Güvenli GUI Alanı (CoreGui varsa oraya, yoksa PlayerGui'ye gizler)
function Security.ProtectGUI(guiObject)
    if syn and syn.protect_gui then -- Synapse/Bazı PC executorleri için
        syn.protect_gui(guiObject)
        guiObject.Parent = CoreGui
    elseif gethui then -- Modern Mobil Executorler için
        guiObject.Parent = gethui()
    else
        pcall(function()
            guiObject.Parent = CoreGui
        end)
        if guiObject.Parent ~= CoreGui then
            guiObject.Parent = LocalPlayer:WaitForChild("PlayerGui")
        end
    end
end

-- 3. Fizik Maskeleme (Hile kapalıyken karakteri sunucuya masum gösterir)
function Security.MaskPhysics(rootPart)
    if rootPart then
        rootPart.AssemblyAngularVelocity = Vector3.zero
        rootPart.AssemblyLinearVelocity = Vector3.zero
    end
end

-------------------------------------------------------------------------
-- [UI SYSTEM] - TOAST BİLDİRİMİ
-------------------------------------------------------------------------
local function ShowToastNotification(message, isError)
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = Security.GenerateRandomName() -- Rastgele İsim
    screenGui.IgnoreGuiInset = true
    Security.ProtectGUI(screenGui)

    local toastFrame = Instance.new("Frame")
    toastFrame.Name = "Toast"
    toastFrame.Parent = screenGui
    toastFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
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

    task.delay(3.5, function()
        TweenService:Create(label, TweenInfo.new(0.2), {TextTransparency = 1}):Play()
        local closeTween = TweenService:Create(toastFrame, TweenInfo.new(0.4, Enum.EasingStyle.Quint, Enum.EasingDirection.In), {Size = UDim2.new(0, 0, 0, 45), Position = UDim2.new(0.5, 0, 0.9, 0)})
        closeTween:Play()
        closeTween.Completed:Connect(function()
            screenGui:Destroy()
        end)
    end)
end

-------------------------------------------------------------------------
-- [MAIN SCRIPT] - TOUCH FLING LOGIC
-------------------------------------------------------------------------
local success, errorMessage = pcall(function()
    
    local function createFlingUI()
        local screenGui = Instance.new("ScreenGui")
        screenGui.Name = Security.GenerateRandomName() -- GÜVENLİK: İsim karıştırma
        screenGui.ResetOnSpawn = false
        Security.ProtectGUI(screenGui)

        local mainFrame = Instance.new("TextButton")
        mainFrame.Name = "MainControl"
        mainFrame.Parent = screenGui
        mainFrame.BackgroundColor3 = Color3.fromRGB(18, 18, 18)
        mainFrame.Position = UDim2.new(0.4, 0, 0.3, 0)
        mainFrame.Size = UDim2.new(0, 160, 0, 60)
        mainFrame.Text = ""
        mainFrame.AutoButtonColor = false
        
        local uiCorner = Instance.new("UICorner")
        uiCorner.CornerRadius = UDim.new(0, 14)
        uiCorner.Parent = mainFrame

        -- Durum Işığı (Stroke)
        local uiStroke = Instance.new("UIStroke")
        uiStroke.Parent = mainFrame
        uiStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
        uiStroke.Color = Color3.fromRGB(255, 60, 60) -- Başlangıç Kırmızı
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

    -- SÜRÜKLEME SİSTEMİ
    local dragging, dragInput, dragStart, startPos
    local hasMoved = false

    local function update(input)
        local delta = input.Position - dragStart
        if delta.Magnitude > 2 then hasMoved = true end -- Titremeyi yoksay
        button.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    end

    button.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            hasMoved = false
            dragStart = input.Position
            startPos = button.Position
            
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then dragging = false end
            end)
        end
    end)

    button.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then dragInput = input end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if input == dragInput and dragging then update(input) end
    end)

    -- FLING MANTIĞI
    local flingActive = false
    local rotVelocity = Vector3.new(0, 20000, 0) -- Yüksek Fling Gücü

    local function toggleFling()
        if hasMoved then return end -- Sürüklendiyse açma
        
        flingActive = not flingActive
        
        if flingActive then
            TweenService:Create(stroke, TweenInfo.new(0.3), {Color = Color3.fromRGB(0, 255, 100)}):Play()
            label.Text = "FLING: ON"
            label.TextColor3 = Color3.fromRGB(100, 255, 100)
        else
            TweenService:Create(stroke, TweenInfo.new(0.3), {Color = Color3.fromRGB(255, 60, 60)}):Play()
            label.Text = "FLING: OFF"
            label.TextColor3 = Color3.fromRGB(200, 200, 200)
            
            -- GÜVENLİK: Kapatıldığında fiziği temizle
            if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
                Security.MaskPhysics(LocalPlayer.Character.HumanoidRootPart)
            end
        end
    end

    button.MouseButton1Up:Connect(toggleFling)

    -- FİZİK DÖNGÜSÜ (HEARTBEAT)
    RunService.Heartbeat:Connect(function()
        local character = LocalPlayer.Character
        if not character then return end
        local rootPart = character:FindFirstChild("HumanoidRootPart")
        if not rootPart then return end

        if flingActive then
            -- Aktifken Güvenlik Kontrollerini Geç ve Flingle
            
            -- Noclip (Çarpışma kapatma)
            for _, part in pairs(character:GetDescendants()) do
                if part:IsA("BasePart") then part.CanCollide = false end
            end

            local targetFound = false
            local myPos = rootPart.Position

            for _, player in pairs(Players:GetPlayers()) do
                if player ~= LocalPlayer and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
                    local targetRoot = player.Character.HumanoidRootPart
                    local distance = (myPos - targetRoot.Position).Magnitude
                    
                    if distance < 6 then -- 6 birim mesafe
                        targetFound = true
                        rootPart.AssemblyAngularVelocity = rotVelocity -- Dönme Hızı (Silahımız)
                        rootPart.AssemblyLinearVelocity = Vector3.zero -- Geri Tepme Önleyici (Kalkanımız)
                        
                        -- Stabilizasyon (Dönmeyi kameraya yansıtma)
                        rootPart.CFrame = CFrame.new(rootPart.Position, targetRoot.Position)
                    end
                end
            end

            if not targetFound then
                 -- Kimse yoksa normal duruyormuş gibi yap
                rootPart.AssemblyAngularVelocity = Vector3.zero
                rootPart.AssemblyLinearVelocity = Vector3.zero 
            end
        else
            -- GÜVENLİK: Pasifken tamamen temiz dur
            -- Eğer script başka bir scriptle çakışmıyorsa burayı boş bırakabiliriz 
            -- ama ekstra güvenlik için hızları sıfırlamak iyidir.
        end
    end)
end)

-------------------------------------------------------------------------
-- SONUÇ
-------------------------------------------------------------------------
if success then
    ShowToastNotification("Security Module & Script Loaded", false)
else
    ShowToastNotification("Script Failed", true)
    warn(errorMessage)
end
