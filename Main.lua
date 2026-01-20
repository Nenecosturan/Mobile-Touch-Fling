--[[
    Universal Mobile-Optimized Touch-Fling Script
    Features: Draggable UI (Mobil Uyumlu), Neon Visuals, Anti-Spin
]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local CoreGui = game:GetService("CoreGui")
local UserInputService = game:GetService("UserInputService")
local LocalPlayer = Players.LocalPlayer

-- UI Oluşturma
local function createUI()
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "MobileFlingGUI"
    screenGui.ResetOnSpawn = false
    
    -- Executor uyumluluğu kontrolü
    pcall(function()
        screenGui.Parent = CoreGui
    end)
    if not screenGui.Parent then
        screenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")
    end

    -- Buton (Mobilde daha rahat basılması için boyutu biraz büyüttüm)
    local mainFrame = Instance.new("TextButton")
    mainFrame.Name = "FlingButton"
    mainFrame.Parent = screenGui
    mainFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
    mainFrame.Position = UDim2.new(0.4, 0, 0.2, 0) -- Başlangıç konumu (Ortalara yakın)
    mainFrame.Size = UDim2.new(0, 150, 0, 60)
    mainFrame.Text = ""
    mainFrame.AutoButtonColor = false
    
    -- Yuvarlatılmış Köşeler
    local uiCorner = Instance.new("UICorner")
    uiCorner.CornerRadius = UDim.new(0, 16)
    uiCorner.Parent = mainFrame

    -- Parlama Efekti
    local uiStroke = Instance.new("UIStroke")
    uiStroke.Parent = mainFrame
    uiStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    uiStroke.Color = Color3.fromRGB(255, 0, 0) 
    uiStroke.Thickness = 2.5
    uiStroke.Transparency = 0

    -- Yazı
    local statusLabel = Instance.new("TextLabel")
    statusLabel.Parent = mainFrame
    statusLabel.Size = UDim2.new(1, 0, 1, 0)
    statusLabel.BackgroundTransparency = 1
    statusLabel.Text = "Touch-Fling:\nDisabled" -- Mobilde daha iyi okunması için alt satıra geçirdim
    statusLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    statusLabel.TextSize = 16
    statusLabel.Font = Enum.Font.GothamBold

    return mainFrame, uiStroke, statusLabel
end

local button, stroke, label = createUI()

-- MOBİL İÇİN SÜRÜKLEME FONKSİYONU (DRAGGABLE)
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
            if input.UserInputState == Enum.UserInputState.End then
                dragging = false
            end
        end)
    end
end)

button.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
        dragInput = input
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if input == dragInput and dragging then
        update(input)
    end
end)

-- Mantık Kısmı
local flingActive = false
local rotVelocity = Vector3.new(0, 30000, 0) -- Güç mobilde de aynı etkiyi verir

local function toggleFling()
    -- Sürükleme işlemi bittikten hemen sonra tıklama algılanmasın diye ufak kontrol
    if dragging then return end 

    flingActive = not flingActive

    if flingActive then
        game:GetService("TweenService"):Create(stroke, TweenInfo.new(0.3), {Color = Color3.fromRGB(0, 255, 0)}):Play()
        label.Text = "Touch-Fling:\nActive"
        label.TextColor3 = Color3.fromRGB(100, 255, 100)
    else
        game:GetService("TweenService"):Create(stroke, TweenInfo.new(0.3), {Color = Color3.fromRGB(255, 0, 0)}):Play()
        label.Text = "Touch-Fling:\nDisabled"
        label.TextColor3 = Color3.fromRGB(255, 255, 255)
    end
end

button.MouseButton1Click:Connect(toggleFling)

-- Fling Döngüsü
RunService.Heartbeat:Connect(function()
    if not flingActive then return end
    
    local character = LocalPlayer.Character
    if not character then return end
    local rootPart = character:FindFirstChild("HumanoidRootPart")
    
    if not rootPart then return end

    -- Çarpışma kapalı (Noclip)
    for _, part in pairs(character:GetDescendants()) do
        if part:IsA("BasePart") and part.CanCollide then part.CanCollide = false end
    end

    local targetFound = false
    for _, player in pairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
            local targetRoot = player.Character.HumanoidRootPart
            local distance = (rootPart.Position - targetRoot.Position).Magnitude
            
            if distance < 5 then -- Mobilde lag olabileceği için menzili 4'ten 5'e çıkardım
                targetFound = true
                rootPart.AssemblyAngularVelocity = rotVelocity
            end
        end
    end
    
    if not targetFound then
        rootPart.AssemblyAngularVelocity = Vector3.zero
    end
end)
