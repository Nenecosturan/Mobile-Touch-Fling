--[[
    Universal Mobile Touch-Fling + Status Notification
    GitHub: Main.lua
    Author: Nenecosturan / Optimized by Gemini
]]

local TweenService = game:GetService("TweenService")
local CoreGui = game:GetService("CoreGui")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local LocalPlayer = Players.LocalPlayer

-------------------------------------------------------------------------
-- 1. BİLDİRİM SİSTEMİ (NOTIFICATION SYSTEM)
-------------------------------------------------------------------------
local function ShowStatusNotification(isSuccess, errorMsg)
    -- GUI Oluşturma
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "FlingStatusNotification"
    -- Executor koruması: CoreGui'ye, olmazsa PlayerGui'ye
    if pcall(function() screenGui.Parent = CoreGui end) then else screenGui.Parent = LocalPlayer:WaitForChild("PlayerGui") end

    -- Ana Çerçeve (Bildirim Kutusu)
    local notifFrame = Instance.new("Frame")
    notifFrame.Name = "StatusFrame"
    notifFrame.Parent = screenGui
    notifFrame.BackgroundColor3 = Color3.fromRGB(15, 15, 20)
    notifFrame.BackgroundTransparency = 0.2
    notifFrame.Position = UDim2.new(0.5, 0, -0.2, 0) -- Başlangıçta ekranın yukarısında gizli
    notifFrame.AnchorPoint = Vector2.new(0.5, 0)
    notifFrame.Size = UDim2.new(0, 220, 0, 40)
    
    -- Köşeleri Yuvarlatma
    local uiCorner = Instance.new("UICorner")
    uiCorner.CornerRadius = UDim.new(0, 8)
    uiCorner.Parent = notifFrame

    -- Mavi Parlayan Kenarlık (İstek üzerine)
    local uiStroke = Instance.new("UIStroke")
    uiStroke.Parent = notifFrame
    uiStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    uiStroke.Color = Color3.fromRGB(0, 170, 255) -- Neon Mavi
    uiStroke.Thickness = 2
    uiStroke.Transparency = 0

    -- Glow Efekti (Gölge ile parlama hissi verme)
    local shadow = Instance.new("ImageLabel")
    shadow.Name = "Glow"
    shadow.Parent = notifFrame
    shadow.BackgroundTransparency = 1
    shadow.Position = UDim2.new(0, -15, 0, -15)
    shadow.Size = UDim2.new(1, 30, 1, 30)
    shadow.Image = "rbxassetid://5028857472" -- Soft glow texture
    shadow.ImageColor3 = Color3.fromRGB(0, 170, 255)
    shadow.ScaleType = Enum.ScaleType.Slice
    shadow.SliceCenter = Rect.new(24, 24, 276, 276)
    shadow.ZIndex = 0

    -- Durum Yazısı
    local label = Instance.new("TextLabel")
    label.Parent = notifFrame
    label.Size = UDim2.new(1, 0, 1, 0)
    label.BackgroundTransparency = 1
    label.Font = Enum.Font.GothamBold
    label.TextSize = 14
    label.TextColor3 = Color3.fromRGB(255, 255, 255)
    
    if isSuccess then
        label.Text = "Touch-Fling is ready"
    else
        label.Text = "Touch-Fling Failed"
        warn("Fling Script Error: " .. tostring(errorMsg)) -- Hata varsa konsola basar
    end

    -- Animasyon: Yukarıdan Aşağı İniş
    notifFrame:TweenPosition(UDim2.new(0.5, 0, 0.05, 0), Enum.EasingDirection.Out, Enum.EasingStyle.Back, 0.5)

    -- 3 Saniye bekle sonra yukarı kaybol ve sil
    task.delay(3, function()
        local tweenOut = TweenService:Create(notifFrame, TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {Position = UDim2.new(0.5, 0, -0.2, 0)})
        tweenOut:Play()
        tweenOut.Completed:Connect(function()
            screenGui:Destroy()
        end)
    end)
end

-------------------------------------------------------------------------
-- 2. ANA SCRİPT (TOUCH-FLING LOGIC)
-- Bu kısmı pcall içine alıyoruz ki hata olursa bildirim "Failed" desin.
-------------------------------------------------------------------------
local success, errorMessage = pcall(function()
    
    -- UI Kurulumu
    local function createFlingUI()
        local screenGui = Instance.new("ScreenGui")
        screenGui.Name = "MobileFlingGUI"
        screenGui.ResetOnSpawn = false
        
        if pcall(function() screenGui.Parent = CoreGui end) then else screenGui.Parent = LocalPlayer:WaitForChild("PlayerGui") end

        local mainFrame = Instance.new("TextButton")
        mainFrame.Name = "FlingButton"
        mainFrame.Parent = screenGui
        mainFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
        mainFrame.Position = UDim2.new(0.4, 0, 0.2, 0)
        mainFrame.Size = UDim2.new(0, 150, 0, 60)
        mainFrame.Text = ""
        mainFrame.AutoButtonColor = false
        
        local uiCorner = Instance.new("UICorner")
        uiCorner.CornerRadius = UDim.new(0, 16)
        uiCorner.Parent = mainFrame

        local uiStroke = Instance.new("UIStroke")
        uiStroke.Parent = mainFrame
        uiStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
        uiStroke.Color = Color3.fromRGB(255, 0, 0) 
        uiStroke.Thickness = 2.5
        uiStroke.Transparency = 0

        local statusLabel = Instance.new("TextLabel")
        statusLabel.Parent = mainFrame
        statusLabel.Size = UDim2.new(1, 0, 1, 0)
        statusLabel.BackgroundTransparency = 1
        statusLabel.Text = "Touch-Fling:\nDisabled"
        statusLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
        statusLabel.TextSize = 16
        statusLabel.Font = Enum.Font.GothamBold

        return mainFrame, uiStroke, statusLabel, screenGui
    end

    local button, stroke, label, gui = createFlingUI()

    -- SÜRÜKLEME (DRAGGABLE)
    local dragging, dragInput, dragStart, startPos
    local function update(input)
        local delta = input.Position - dragStart
        button.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    end

    button.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
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

    -- MANTIK
    local flingActive = false
    local rotVelocity = Vector3.new(0, 30000, 0)

    local function toggleFling()
        if dragging then return end 
        flingActive = not flingActive

        if flingActive then
            TweenService:Create(stroke, TweenInfo.new(0.3), {Color = Color3.fromRGB(0, 255, 0)}):Play()
            label.Text = "Touch-Fling:\nActive"
            label.TextColor3 = Color3.fromRGB(100, 255, 100)
        else
            TweenService:Create(stroke, TweenInfo.new(0.3), {Color = Color3.fromRGB(255, 0, 0)}):Play()
            label.Text = "Touch-Fling:\nDisabled"
            label.TextColor3 = Color3.fromRGB(255, 255, 255)
        end
    end

    button.MouseButton1Click:Connect(toggleFling)

    RunService.Heartbeat:Connect(function()
        if not flingActive then return end
        
        local character = LocalPlayer.Character
        if not character then return end
        local rootPart = character:FindFirstChild("HumanoidRootPart")
        if not rootPart then return end

        for _, part in pairs(character:GetDescendants()) do
            if part:IsA("BasePart") and part.CanCollide then part.CanCollide = false end
        end

        local targetFound = false
        for _, player in pairs(Players:GetPlayers()) do
            if player ~= LocalPlayer and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
                local targetRoot = player.Character.HumanoidRootPart
                local distance = (rootPart.Position - targetRoot.Position).Magnitude
                
                if distance < 5 then
                    targetFound = true
                    rootPart.AssemblyAngularVelocity = rotVelocity
                end
            end
        end
        
        if not targetFound then
            rootPart.AssemblyAngularVelocity = Vector3.zero
        end
    end)
end)

-------------------------------------------------------------------------
-- 3. SONUÇ BİLDİRİMİ
-------------------------------------------------------------------------
if success then
    ShowStatusNotification(true)
else
    ShowStatusNotification(false, errorMessage)
end
