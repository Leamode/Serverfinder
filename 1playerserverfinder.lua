-- ============================================================
-- LEA BYPASS - SERVER FİND v14 (FİNAL)
-- 1 KİŞİLİK SUNUCULARI ANINDA LİSTELE
-- BEKLEME YOK | 100-200 BEKLEME YOK | SADECE 1 KİŞİLİK
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
local VerifiedServerIds = {}
local VerifiedServers = {}

-- ============================================================
-- Безопасный HTTP запрос
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
-- Мгновенный поиск всех одиночных серверов
-- ============================================================
local function GetSinglePlayerServers()
    local servers = {}
    local cursor = ""
    local found = false

    for page = 1, 5 do
        local url = "https://games.roblox.com/v1/games/" .. game.PlaceId .. "/servers/Public?sortOrder=Asc&limit=100"
        if cursor ~= "" then
            url = url .. "&cursor=" .. HttpService:UrlEncode(cursor)
        end

        local rawData = SafeHttpGet(url)
        if not rawData then break end

        local success, result = pcall(function()
            return HttpService:JSONDecode(rawData)
        end)

        if success and result and result.data then
            for _, server in ipairs(result.data) do
                if server and server.id and server.playing then
                    if server.playing == 1 and server.maxPlayers > 1 and server.id ~= CurrentServerId then
                        if not VerifiedServerIds[server.id] then
                            table.insert(servers, {
                                id = server.id,
                                playing = server.playing,
                                maxPlayers = server.maxPlayers
                            })
                            found = true
                        end
                    end
                end
            end

            cursor = result.nextPageCursor or ""
            if cursor == "" or found then break end
        else
            break
        end

        task.wait(0.01)
    end

    return servers
end

-- ============================================================
-- Очистка Remote
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
-- Мгновенный телепорт
-- ============================================================
local function InstantTeleport(serverId)
    if not serverId then return end
    CleanRemotes()
    task.spawn(function()
        pcall(function()
            TeleportService:TeleportToPlaceInstance(game.PlaceId, serverId, LocalPlayer)
        end)
    end)
end

-- ============================================================
-- Меню со списком
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
    menu.Size = UDim2.new(0, 150, 0, 250)
    menu.Position = UDim2.new(0.5, -75, 0.5, -125)
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
    title.Text = "LEA BYPASS - 1 KİŞİLİK"
    title.TextColor3 = Color3.fromRGB(255, 255, 255)
    title.TextSize = 8
    title.Font = Enum.Font.GothamBold
    title.Parent = menu
    Instance.new("UICorner", title).CornerRadius = UDim.new(0, 12)

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
    scroll.ScrollBarImageColor3 = Color3.fromRGB(255, 0, 0)

    local layout = Instance.new("UIListLayout")
    layout.Name = "Layout"
    layout.Padding = UDim.new(0, 3)
    layout.Parent = scroll

    local function AddServerButton(server)
        if not GuiRef or not GuiRef.Parent then return end

        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(1, -4, 0, 28)
        btn.BackgroundColor3 = Color3.fromRGB(20, 0, 0)
        btn.Text = "👤 1/" .. server.maxPlayers
        btn.TextColor3 = Color3.fromRGB(255, 0, 0)
        btn.TextSize = 8
        btn.Font = Enum.Font.GothamBold
        btn.Parent = scroll
        Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6)
        Instance.new("UIStroke", btn).Color = Color3.fromRGB(255, 0, 0)

        btn.MouseEnter:Connect(function()
            btn.BackgroundColor3 = Color3.fromRGB(40, 0, 0)
        end)
        btn.MouseLeave:Connect(function()
            btn.BackgroundColor3 = Color3.fromRGB(20, 0, 0)
        end)

        btn.MouseButton1Click:Connect(function()
            local serverId = server.id
            btn.Text = "GİDİLİYOR..."
            btn.BackgroundColor3 = Color3.fromRGB(100, 0, 0)

            task.spawn(function()
                if GuiRef then pcall(function() GuiRef:Destroy() end) end
                GuiRef = nil
                InstantTeleport(serverId)
            end)
        end)
    end

    local function UpdateCount()
        if countLabel and countLabel.Parent then
            countLabel.Text = "🔍 BULUNAN: " .. #VerifiedServers
        end
    end

    -- Мгновенное сканирование при открытии
    task.spawn(function()
        local servers = GetSinglePlayerServers()
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
    end)

    -- Перетаскивание
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
-- Запуск
-- ============================================================
task.wait(0.5)
pcall(function()
    CreateMainMenu()
end)

print("LEA BYPASS - SERVER FİND v14 АКТИВЕН")
print("МГНОВЕННОЕ СКАНИРОВАНИЕ")
print("ТОЛЬКО 1-МЕСТНЫЕ СЕРВЕРА")
