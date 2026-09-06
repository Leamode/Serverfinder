-- ============================================================
-- LEA BYPASS - SERVER FİND v8
-- AÇILIR AÇILMAZ UPDATE UYARISI | TAMAM DEYİNCE TEK BUTON
-- SERVER FİND'E BAS → ANINDA 1 KİŞİLİK SUNUCUYA AT
-- PC + MOBİL UYUMLU | SÜRÜKLE
-- ============================================================

local Players = game:GetService("Players")
local TeleportService = game:GetService("TeleportService")
local HttpService = game:GetService("HttpService")
local UserInputService = game:GetService("UserInputService")
local CoreGui = game:GetService("CoreGui")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LocalPlayer = Players.LocalPlayer

local GuiRef = nil
local CurrentServerId = game.JobId
local IsSearching = false

-- ============================================================
-- GÜVENLİ HTTP
-- ============================================================
local function SafeHttpGet(url)
    local success, response = pcall(function()
        return game:HttpGet(url)
    end)
    if success and response and response ~= "" then
        return response
    end
    return nil
end

-- ============================================================
-- ANINDA 1 KİŞİLİK SUNUCU BUL
-- ============================================================
local function FindSinglePlayerServer()
    local url = "https://games.roblox.com/v1/games/" .. game.PlaceId .. "/servers/Public?sortOrder=Asc&limit=100"
    
    local rawData = SafeHttpGet(url)
    if rawData then
        local success, result = pcall(function()
            return HttpService:JSONDecode(rawData)
        end)
        
        if success and result and result.data then
            for _, server in ipairs(result.data) do
                if server and server.id and server.playing then
                    if server.playing == 1 and server.maxPlayers > 1 and server.id ~= CurrentServerId then
                        return server.id
                    end
                end
            end
        end
    end
    
    return nil
end

-- ============================================================
-- REMOTE TEMİZLİĞİ
-- ============================================================
local function CleanRemotes()
    if ReplicatedStorage then
        for _, child in ipairs(ReplicatedStorage:GetChildren()) do
            if child:IsA("RemoteEvent") or child:IsA("RemoteFunction") then
                child.Name = "_blocked_" .. child.Name
            end
        end
    end
    
    if workspace then
        for _, child in ipairs(workspace:GetDescendants()) do
            if child:IsA("RemoteEvent") or child:IsA("RemoteFunction") then
                child.Name = "_blocked_" .. child.Name
            end
        end
    end
    
    if LocalPlayer and LocalPlayer.PlayerScripts then
        for _, child in ipairs(LocalPlayer.PlayerScripts:GetDescendants()) do
            if child:IsA("RemoteEvent") or child:IsA("RemoteFunction") then
                child.Name = "_blocked_" .. child.Name
            end
        end
    end
end

-- ============================================================
-- TELEPORT ET
-- ============================================================
local function TeleportToServer(serverId)
    CleanRemotes()
    
    task.spawn(function()
        pcall(function()
            TeleportService:TeleportToPlaceInstance(game.PlaceId, serverId, LocalPlayer)
        end)
    end)
end

-- ============================================================
-- ANA MENÜ - LEA BYPASS SERVER FİND
-- ============================================================
local function CreateMainMenu()
    local old = CoreGui:FindFirstChild("LeaBypass")
    if old then old:Destroy() end

    local gui = Instance.new("ScreenGui")
    gui.Name = "LeaBypass"
    gui.Parent = CoreGui
    gui.ResetOnSpawn = false
    gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    GuiRef = gui

    local menu = Instance.new("Frame")
    menu.Name = "MainMenu"
    menu.Size = UDim2.new(0, 150, 0, 80)
    menu.Position = UDim2.new(0.5, -75, 0.5, -40)
    menu.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    menu.BackgroundTransparency = 0
    menu.Parent = gui
    menu.Active = true
    menu.Draggable = false
    Instance.new("UICorner", menu).CornerRadius = UDim.new(0, 12)
    Instance.new("UIStroke", menu).Color = Color3.fromRGB(255, 0, 0)

    local title = Instance.new("TextLabel")
    title.Name = "Title"
    title.Size = UDim2.new(1, 0, 0, 22)
    title.BackgroundColor3 = Color3.fromRGB(180, 0, 0)
    title.Text = "LEA BYPASS"
    title.TextColor3 = Color3.fromRGB(255, 255, 255)
    title.TextSize = 10
    title.Font = Enum.Font.GothamBold
    title.Parent = menu
    Instance.new("UICorner", title).CornerRadius = UDim.new(0, 12)

    local btn = Instance.new("TextButton")
    btn.Name = "ServerFindButton"
    btn.Size = UDim2.new(1, -10, 0, 42)
    btn.Position = UDim2.new(0, 5, 0, 28)
    btn.BackgroundColor3 = Color3.fromRGB(180, 0, 0)
    btn.Text = "SERVER FİND"
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.TextSize = 14
    btn.Font = Enum.Font.GothamBold
    btn.Parent = menu
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 8)
    Instance.new("UIStroke", btn).Color = Color3.fromRGB(255, 0, 0)

    btn.MouseEnter:Connect(function()
        btn.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
    end)
    btn.MouseLeave:Connect(function()
        btn.BackgroundColor3 = Color3.fromRGB(180, 0, 0)
    end)

    btn.MouseButton1Click:Connect(function()
        if IsSearching then return end
        IsSearching = true
        btn.Text = "GİDİLİYOR..."
        
        task.spawn(function()
            local serverId = FindSinglePlayerServer()
            
            if serverId then
                if GuiRef then pcall(function() GuiRef:Destroy() end) end
                GuiRef = nil
                TeleportToServer(serverId)
            else
                btn.Text = "TEKRAR DENE"
                task.wait(1)
                btn.Text = "SERVER FİND"
                IsSearching = false
            end
        end)
    end)

    -- SÜRÜKLEME
    local dragging = false
    local dragInput = nil
    local dragStart = nil
    local startPos = nil

    local function startDrag(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or 
           input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = menu.Position
            if input.UserInputType == Enum.UserInputType.MouseButton1 then
                input.Changed:Connect(function()
                    if input.UserInputState == Enum.UserInputState.End then
                        dragging = false
                    end
                end)
            end
        end
    end

    local function updateDrag(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or 
           input.UserInputType == Enum.UserInputType.Touch then
            dragInput = input
        end
    end

    title.InputBegan:Connect(startDrag)
    title.InputChanged:Connect(updateDrag)

    UserInputService.InputChanged:Connect(function(input)
        if input == dragInput and dragging and menu and menu.Parent then
            local delta = input.Position - dragStart
            menu.Position = UDim2.new(
                startPos.X.Scale, 
                startPos.X.Offset + delta.X, 
                startPos.Y.Scale, 
                startPos.Y.Offset + delta.Y
            )
        end
    end)

    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end)
end

-- ============================================================
-- UPDATE UYARISI
-- ============================================================
local function CreateUpdateWarning()
    local old = CoreGui:FindFirstChild("UpdateWarning")
    if old then old:Destroy() end

    local gui = Instance.new("ScreenGui")
    gui.Name = "UpdateWarning"
    gui.Parent = CoreGui
    gui.ResetOnSpawn = false
    gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    gui.DisplayOrder = 999

    local background = Instance.new("Frame")
    background.Size = UDim2.new(1, 0, 1, 0)
    background.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    background.BackgroundTransparency = 0.5
    background.Parent = gui

    local warningFrame = Instance.new("Frame")
    warningFrame.Name = "WarningFrame"
    warningFrame.Size = UDim2.new(0, 220, 0, 100)
    warningFrame.Position = UDim2.new(0.5, -110, 0.5, -50)
    warningFrame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    warningFrame.BackgroundTransparency = 0
    warningFrame.Parent = gui
    Instance.new("UICorner", warningFrame).CornerRadius = UDim.new(0, 12)
    Instance.new("UIStroke", warningFrame).Color = Color3.fromRGB(255, 0, 0)

    local updateLabel = Instance.new("TextLabel")
    updateLabel.Name = "UpdateLabel"
    updateLabel.Size = UDim2.new(1, 0, 0, 30)
    updateLabel.Position = UDim2.new(0, 0, 0, 5)
    updateLabel.BackgroundTransparency = 1
    updateLabel.Text = "UPDATE"
    updateLabel.TextColor3 = Color3.fromRGB(255, 0, 0)
    updateLabel.TextSize = 18
    updateLabel.Font = Enum.Font.GothamBold
    updateLabel.Parent = warningFrame

    local messageLabel = Instance.new("TextLabel")
    messageLabel.Name = "MessageLabel"
    messageLabel.Size = UDim2.new(1, 0, 0, 30)
    messageLabel.Position = UDim2.new(0, 0, 0, 35)
    messageLabel.BackgroundTransparency = 1
    messageLabel.Text = "erdem 5km otede amcigini siktiriyor!!"
    messageLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    messageLabel.TextSize = 10
    messageLabel.Font = Enum.Font.Gotham
    messageLabel.TextWrapped = true
    messageLabel.Parent = warningFrame

    local okButton = Instance.new("TextButton")
    okButton.Name = "OkButton"
    okButton.Size = UDim2.new(1, -20, 0, 25)
    okButton.Position = UDim2.new(0, 10, 0, 68)
    okButton.BackgroundColor3 = Color3.fromRGB(180, 0, 0)
    okButton.Text = "TAMAM"
    okButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    okButton.TextSize = 12
    okButton.Font = Enum.Font.GothamBold
    okButton.Parent = warningFrame
    Instance.new("UICorner", okButton).CornerRadius = UDim.new(0, 6)

    okButton.MouseButton1Click:Connect(function()
        pcall(function() gui:Destroy() end)
        CreateMainMenu()
    end)
end

-- ============================================================
-- BAŞLAT - ÖNCE UPDATE UYARISI
-- ============================================================
task.wait(0.5)
pcall(function()
    CreateUpdateWarning()
end)

print("LEA BYPASS - SERVER FİND v8 AKTİF")
print("UPDATE UYARISI GÖSTERİLDİ")
print("TAMAM'A BAS → LEA BYPASS MENÜ → SERVER FİND")
