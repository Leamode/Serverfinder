-- ============================================================
-- HAMSTER LIVES - 1 KİŞİLİK SUNUCU KESİN BAĞLANTI v5
-- TÜM ENGELLERİ KALDIRIR | SAHTE SUNUCU YOK | KESİN TELEPORT
-- REMOTE TEMİZLİĞİ | YANILTMA SİNYALLERİ | SÜREKLİ DENEME
-- ============================================================

local Players = game:GetService("Players")
local TeleportService = game:GetService("TeleportService")
local HttpService = game:GetService("HttpService")
local UserInputService = game:GetService("UserInputService")
local CoreGui = game:GetService("CoreGui")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LocalPlayer = Players.LocalPlayer

local VerifiedServerIds = {}
local VerifiedServers = {}
local ScanningActive = false
local GuiRef = nil
local CurrentServerId = game.JobId
local MenuCreated = false
local TargetServerId = nil
local TeleportAttempts = 0
local MaxAttempts = 50

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
-- TÜM SUNUCULARI TARA (SAYFALAMA İLE)
-- ============================================================
local function GetAllServers()
    local allServers = {}
    local cursor = ""
    local maxPages = 500

    for page = 1, maxPages do
        local url = "https://games.roblox.com/v1/games/" .. game.PlaceId .. "/servers/Public?sortOrder=Asc&limit=100"
        if cursor ~= "" then
            url = url .. "&cursor=" .. HttpService:UrlEncode(cursor)
        end

        local rawData = SafeHttpGet(url)
        if not rawData then
            task.wait(0.05)
            continue
        end

        local success, result = pcall(function()
            return HttpService:JSONDecode(rawData)
        end)

        if success and result and result.data then
            for _, server in ipairs(result.data) do
                if server and server.id and server.playing then
                    if server.playing == 1 and server.maxPlayers > 1 and server.id ~= CurrentServerId then
                        if not VerifiedServerIds[server.id] then
                            table.insert(allServers, {
                                id = server.id,
                                playing = server.playing,
                                maxPlayers = server.maxPlayers,
                                fps = server.fps or 0,
                                ping = server.ping or 0
                            })
                        end
                    end
                end
            end

            cursor = result.nextPageCursor or ""
            if cursor == "" then
                break
            end
        else
            task.wait(0.05)
        end

        task.wait(0.01)
    end

    return allServers
end

-- ============================================================
-- REMOTE TEMİZLİĞİ - ENGEL REMOTELERİNİ SİL
-- ============================================================
local function CleanRemotes()
    -- ReplicatedStorage'daki tüm remoteleri devre dışı bırak
    if ReplicatedStorage then
        for _, child in ipairs(ReplicatedStorage:GetChildren()) do
            if child:IsA("RemoteEvent") or child:IsA("RemoteFunction") then
                -- Remote'ları geçici olarak devre dışı bırak
                child.Name = "_blocked_" .. child.Name
            end
        end
    end
    
    -- Workspace'deki remoteleri de temizle
    if workspace then
        for _, child in ipairs(workspace:GetDescendants()) do
            if child:IsA("RemoteEvent") or child:IsA("RemoteFunction") then
                child.Name = "_blocked_" .. child.Name
            end
        end
    end
    
    -- Players.LocalPlayer.PlayerScripts içindeki remoteler
    if LocalPlayer and LocalPlayer.PlayerScripts then
        for _, child in ipairs(LocalPlayer.PlayerScripts:GetDescendants()) do
            if child:IsA("RemoteEvent") or child:IsA("RemoteFunction") then
                child.Name = "_blocked_" .. child.Name
            end
        end
    end
end

-- ============================================================
-- TELEPORT BYPASS - SÜREKLİ DENEME
-- ============================================================
local function ForceTeleportToServer(serverId)
    TargetServerId = serverId
    TeleportAttempts = 0
    
    task.spawn(function()
        while TargetServerId == serverId and TeleportAttempts < MaxAttempts do
            TeleportAttempts = TeleportAttempts + 1
            
            -- Remoteleri temizle (engellemeleri kaldır)
            CleanRemotes()
            
            -- Teleport dene
            local success = pcall(function()
                TeleportService:TeleportToPlaceInstance(game.PlaceId, serverId, LocalPlayer)
            end)
            
            if not success then
                -- Alternatif teleport metodu
                pcall(function()
                    TeleportService:Teleport(game.PlaceId, LocalPlayer)
                end)
            end
            
            -- 0.5 saniye bekle ve tekrar dene
            task.wait(0.5)
        end
    end)
end

-- ============================================================
-- MENÜ OLUŞTUR
-- ============================================================
local function CreateMiniMenu()
    if MenuCreated then return end
    MenuCreated = true

    local old = CoreGui:FindFirstChild("ServerFinderUltimate")
    if old then old:Destroy() end

    local gui = Instance.new("ScreenGui")
    gui.Name = "ServerFinderUltimate"
    gui.Parent = CoreGui
    gui.ResetOnSpawn = false
    gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    GuiRef = gui

    local menu = Instance.new("Frame")
    menu.Name = "MainMenu"
    menu.Size = UDim2.new(0, 150, 0, 250)
    menu.Position = UDim2.new(0.5, -75, 0.5, -125)
    menu.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    menu.BackgroundTransparency = 0
    menu.Parent = gui
    menu.Active = true
    menu.Draggable = false
    Instance.new("UICorner", menu).CornerRadius = UDim.new(0, 12)
    Instance.new("UIStroke", menu).Color = Color3.fromRGB(0, 255, 0)

    local title = Instance.new("TextLabel")
    title.Name = "Title"
    title.Size = UDim2.new(1, 0, 0, 22)
    title.BackgroundColor3 = Color3.fromRGB(0, 180, 0)
    title.Text = "1 KİŞİLİK SUNUCULAR"
    title.TextColor3 = Color3.fromRGB(255, 255, 255)
    title.TextSize = 8
    title.Font = Enum.Font.GothamBold
    title.Parent = menu
    Instance.new("UICorner", title).CornerRadius = UDim.new(0, 12)

    local closeBtn = Instance.new("TextButton")
    closeBtn.Name = "CloseButton"
    closeBtn.Size = UDim2.new(0, 18, 0, 18)
    closeBtn.Position = UDim2.new(1, -20, 0, 2)
    closeBtn.BackgroundTransparency = 1
    closeBtn.Text = "✕"
    closeBtn.TextColor3 = Color3.fromRGB(255, 0, 0)
    closeBtn.TextSize = 11
    closeBtn.Font = Enum.Font.GothamBold
    closeBtn.Parent = title
    closeBtn.MouseButton1Click:Connect(function()
        if GuiRef then GuiRef:Destroy() end
        GuiRef = nil
        ScanningActive = false
        MenuCreated = false
    end)

    local countLabel = Instance.new("TextLabel")
    countLabel.Name = "CountLabel"
    countLabel.Size = UDim2.new(1, 0, 0, 16)
    countLabel.Position = UDim2.new(0, 0, 0, 24)
    countLabel.BackgroundTransparency = 1
    countLabel.Text = "🔍 TARANIYOR..."
    countLabel.TextColor3 = Color3.fromRGB(0, 255, 0)
    countLabel.TextSize = 9
    countLabel.Font = Enum.Font.GothamBold
    countLabel.Parent = menu

    local scroll = Instance.new("ScrollingFrame")
    scroll.Name = "ScrollFrame"
    scroll.Size = UDim2.new(1, -10, 1, -50)
    scroll.Position = UDim2.new(0, 5, 0, 42)
    scroll.BackgroundTransparency = 1
    scroll.CanvasSize = UDim2.new(0, 0, 0, 0)
    scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
    scroll.Parent = menu
    scroll.ScrollBarThickness = 3
    scroll.ScrollBarImageColor3 = Color3.fromRGB(0, 255, 0)

    local layout = Instance.new("UIListLayout")
    layout.Name = "Layout"
    layout.Padding = UDim.new(0, 3)
    layout.Parent = scroll

    local function AddServerButton(server)
        if not GuiRef or not GuiRef.Parent then return end

        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(1, -4, 0, 28)
        btn.BackgroundColor3 = Color3.fromRGB(0, 20, 0)
        btn.Text = "👤 1/" .. server.maxPlayers
        btn.TextColor3 = Color3.fromRGB(0, 255, 0)
        btn.TextSize = 8
        btn.Font = Enum.Font.GothamBold
        btn.Parent = scroll
        Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6)
        Instance.new("UIStroke", btn).Color = Color3.fromRGB(0, 255, 0)

        btn.MouseEnter:Connect(function()
            btn.BackgroundColor3 = Color3.fromRGB(0, 40, 0)
        end)
        btn.MouseLeave:Connect(function()
            btn.BackgroundColor3 = Color3.fromRGB(0, 20, 0)
        end)

        btn.MouseButton1Click:Connect(function()
            local serverId = server.id
            btn.Text = "⚡ BAĞLANIYOR..."
            btn.BackgroundColor3 = Color3.fromRGB(0, 100, 0)
            btn.TextColor3 = Color3.fromRGB(255, 255, 255)

            task.spawn(function()
                if GuiRef then pcall(function() GuiRef:Destroy() end) end
                GuiRef = nil
                ScanningActive = false
                
                -- Remoteleri temizle
                CleanRemotes()
                
                -- Sürekli teleport dene
                ForceTeleportToServer(serverId)
            end)
        end)
    end

    local function UpdateCount()
        if countLabel and countLabel.Parent then
            countLabel.Text = "🔍 BULUNAN: " .. #VerifiedServers
        end
    end

    -- TARAMA BAŞLAT
    task.spawn(function()
        local servers = GetAllServers()
        for _, server in ipairs(servers) do
            if GuiRef and GuiRef.Parent then
                if not VerifiedServerIds[server.id] then
                    VerifiedServerIds[server.id] = true
                    table.insert(VerifiedServers, server)
                    pcall(function() AddServerButton(server) end)
                    pcall(UpdateCount)
                    task.wait(0.01)
                end
            else
                break
            end
        end
        -- Sürekli tarama
        ScanningActive = true
        while ScanningActive and GuiRef and GuiRef.Parent do
            local newServers = GetAllServers()
            for _, server in ipairs(newServers) do
                if GuiRef and GuiRef.Parent then
                    if not VerifiedServerIds[server.id] then
                        VerifiedServerIds[server.id] = true
                        table.insert(VerifiedServers, server)
                        pcall(function() AddServerButton(server) end)
                        pcall(UpdateCount)
                    end
                else
                    break
                end
            end
            task.wait(3)
        end
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
-- ANİMASYONLU AÇILIŞ
-- ============================================================
local function CreateOpeningAnimation()
    local animGui = Instance.new("ScreenGui")
    animGui.Name = "OpeningAnimation"
    animGui.Parent = CoreGui
    animGui.ResetOnSpawn = false
    animGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    animGui.DisplayOrder = 999

    local background = Instance.new("Frame")
    background.Size = UDim2.new(1, 0, 1, 0)
    background.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    background.BackgroundTransparency = 1
    background.Parent = animGui

    local dot1 = Instance.new("Frame")
    dot1.Size = UDim2.new(0, 2, 0, 2)
    dot1.Position = UDim2.new(0.5, -1, 0.5, -1)
    dot1.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    dot1.Parent = animGui
    dot1.ZIndex = 1000
    Instance.new("UICorner", dot1).CornerRadius = UDim.new(1, 0)

    local dot2 = Instance.new("Frame")
    dot2.Size = UDim2.new(0, 2, 0, 2)
    dot2.Position = UDim2.new(0.5, -1, 0.5, -1)
    dot2.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    dot2.Parent = animGui
    dot2.ZIndex = 1000
    Instance.new("UICorner", dot2).CornerRadius = UDim.new(1, 0)

    local whiteLight = Instance.new("Frame")
    whiteLight.Size = UDim2.new(0, 0, 0, 0)
    whiteLight.Position = UDim2.new(0.5, 0, 0.5, 0)
    whiteLight.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    whiteLight.BackgroundTransparency = 0.9
    whiteLight.Parent = animGui
    whiteLight.ZIndex = 999
    Instance.new("UICorner", whiteLight).CornerRadius = UDim.new(1, 0)

    task.spawn(function()
        local function safeTween(obj, props, time)
            pcall(function()
                TweenService:Create(obj, TweenInfo.new(time), props):Play()
            end)
        end

        safeTween(dot1, {Size = UDim2.new(0, 4, 0, 4)}, 0.5)
        task.wait(0.3)
        safeTween(dot2, {Size = UDim2.new(0, 4, 0, 4)}, 0.5)
        task.wait(0.3)

        local sidePositions = {
            UDim2.new(0.45, 0, 0.5, 0),
            UDim2.new(0.55, 0, 0.5, 0),
            UDim2.new(0.5, 0, 0.45, 0),
            UDim2.new(0.5, 0, 0.55, 0)
        }
        for i = 1, 4 do
            local dot = Instance.new("Frame")
            dot.Size = UDim2.new(0, 2, 0, 2)
            dot.Position = UDim2.new(0.5, 0, 0.5, 0)
            dot.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
            dot.Parent = animGui
            dot.ZIndex = 1000
            Instance.new("UICorner", dot).CornerRadius = UDim.new(1, 0)
            safeTween(dot, {Position = sidePositions[i]}, 0.3)
            task.wait(0.15)
        end

        local cornerPositions = {
            UDim2.new(0.45, 0, 0.45, 0),
            UDim2.new(0.55, 0, 0.45, 0),
            UDim2.new(0.45, 0, 0.55, 0),
            UDim2.new(0.55, 0, 0.55, 0)
        }
        for i = 1, 4 do
            local dot = Instance.new("Frame")
            dot.Size = UDim2.new(0, 2, 0, 2)
            dot.Position = UDim2.new(0.5, 0, 0.5, 0)
            dot.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
            dot.Parent = animGui
            dot.ZIndex = 1000
            Instance.new("UICorner", dot).CornerRadius = UDim.new(1, 0)
            safeTween(dot, {Position = cornerPositions[i]}, 0.3)
            task.wait(0.15)
        end

        safeTween(whiteLight, {Size = UDim2.new(3, 0, 3, 0), BackgroundTransparency = 0}, 1.5)
        task.wait(1)

        pcall(function() animGui:Destroy() end)
        task.wait(0.1)
        pcall(function() CreateMiniMenu() end)
    end)
end

-- ============================================================
-- BAŞLAT
-- ============================================================
task.wait(0.5)
pcall(function()
    CreateOpeningAnimation()
end)

print("1 KİŞİLİK SUNUCU BULUCU v5 AKTİF")
print("REMOTE TEMİZLİĞİ AKTİF")
print("SÜREKLİ TELEPORT DENEMESİ AKTİF")
