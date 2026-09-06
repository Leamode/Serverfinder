-- ============================================================
-- HAMSTER LIVES - TEK BUTON 1 KİŞİLİK SUNUCU v7
-- AÇILIR AÇILMAZ BUTON GELİR | TIKLAYINCA ANINDA TARAR VE ATAR
-- PC + MOBİL UYUMLU | SÜRÜKLE | KESİN 1 KİŞİLİK
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
-- HIZLI SUNUCU BUL - İLK 1 KİŞİLİĞİ GETİR
-- ============================================================
local function FindSinglePlayerServer()
    local cursor = ""
    local maxPages = 50

    for page = 1, maxPages do
        local url = "https://games.roblox.com/v1/games/" .. game.PlaceId .. "/servers/Public?sortOrder=Asc&limit=100"
        if cursor ~= "" then
            url = url .. "&cursor=" .. HttpService:UrlEncode(cursor)
        end

        local rawData = SafeHttpGet(url)
        if not rawData then
            task.wait(0.1)
            continue
        end

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

            cursor = result.nextPageCursor or ""
            if cursor == "" then
                break
            end
        else
            task.wait(0.1)
        end

        task.wait(0.05)
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
    
    task.spawn(function()
        task.wait(1)
        pcall(function()
            TeleportService:Teleport(game.PlaceId, LocalPlayer)
        end)
    end)
end

-- ============================================================
-- MENÜ OLUŞTUR - SADECE TEK BUTON
-- ============================================================
local function CreateMiniMenu()
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
    menu.Size = UDim2.new(0, 150, 0, 60)
    menu.Position = UDim2.new(0.5, -75, 0.5, -30)
    menu.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    menu.BackgroundTransparency = 0
    menu.Parent = gui
    menu.Active = true
    menu.Draggable = false
    Instance.new("UICorner", menu).CornerRadius = UDim.new(0, 12)
    Instance.new("UIStroke", menu).Color = Color3.fromRGB(0, 255, 0)

    local title = Instance.new("TextLabel")
    title.Name = "Title"
    title.Size = UDim2.new(1, 0, 0, 18)
    title.BackgroundColor3 = Color3.fromRGB(0, 180, 0)
    title.Text = "1 KİŞİLİK SUNUCU"
    title.TextColor3 = Color3.fromRGB(255, 255, 255)
    title.TextSize = 8
    title.Font = Enum.Font.GothamBold
    title.Parent = menu
    Instance.new("UICorner", title).CornerRadius = UDim.new(0, 12)

    local btn = Instance.new("TextButton")
    btn.Name = "FindButton"
    btn.Size = UDim2.new(1, -10, 0, 32)
    btn.Position = UDim2.new(0, 5, 0, 22)
    btn.BackgroundColor3 = Color3.fromRGB(0, 100, 0)
    btn.Text = "⚡ 1 KİŞİLİK SUNUCUYA GİT"
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.TextSize = 9
    btn.Font = Enum.Font.GothamBold
    btn.Parent = menu
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6)
    Instance.new("UIStroke", btn).Color = Color3.fromRGB(0, 255, 0)

    btn.MouseEnter:Connect(function()
        btn.BackgroundColor3 = Color3.fromRGB(0, 150, 0)
    end)
    btn.MouseLeave:Connect(function()
        btn.BackgroundColor3 = Color3.fromRGB(0, 100, 0)
    end)

    btn.MouseButton1Click:Connect(function()
        if IsSearching then return end
        IsSearching = true
        btn.Text = "🔍 ARANIYOR..."
        btn.BackgroundColor3 = Color3.fromRGB(100, 100, 0)
        
        task.spawn(function()
            local serverId = FindSinglePlayerServer()
            
            if serverId then
                btn.Text = "⚡ BAĞLANIYOR..."
                btn.BackgroundColor3 = Color3.fromRGB(0, 200, 0)
                
                if GuiRef then pcall(function() GuiRef:Destroy() end) end
                GuiRef = nil
                
                TeleportToServer(serverId)
            else
                btn.Text = "❌ BULUNAMADI - TEKRAR DENE"
                btn.BackgroundColor3 = Color3.fromRGB(100, 0, 0)
                task.wait(2)
                btn.Text = "⚡ 1 KİŞİLİK SUNUCUYA GİT"
                btn.BackgroundColor3 = Color3.fromRGB(0, 100, 0)
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
-- BAŞLAT - ANİMASYONSUZ DİREK MENÜ
-- ============================================================
task.wait(0.5)
pcall(function()
    CreateMiniMenu()
end)

print("TEK BUTON 1 KİŞİLİK SUNUCU v7 AKTİF")
print("BUTONA TIKLA → ANINDA TARA → ANINDA BAĞLAN")
