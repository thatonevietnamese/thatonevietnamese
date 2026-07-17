local HttpService = game:GetService("HttpService")
local TeleportService = game:GetService("TeleportService")
local Players = game:GetService("Players")
local MarketplaceService = game:GetService("MarketplaceService")
local UserInputService = game:GetService("UserInputService")
local LocalPlayer = Players.LocalPlayer

-- Hàm Copy cho Executor
local setclipboard = setclipboard or toclipboard or function(text)
    warn("Executor của bạn không hỗ trợ tính năng copy (setclipboard)!")
end

local requestFunc = nil
if syn and syn.request then requestFunc = syn.request
elseif http and http.request then requestFunc = http.request
elseif http_request then requestFunc = http_request
elseif fluxus and fluxus.request then requestFunc = fluxus.request
elseif request then requestFunc = request
else error("Không tìm thấy hàm HTTP request phù hợp! 😢") end

local gameName = "Unknown"
local gameIconId = 0
pcall(function()
    local info = MarketplaceService:GetProductInfo(game.PlaceId)
    gameName = info.Name or gameName
    gameIconId = info.IconImageAssetId or 0
end)

-- ==========================================
-- HỆ THỐNG LƯU FILE
-- ==========================================
local ConfigFile = "AutoHop_Data.json"
local AppData = {
    MaxPlayers = 5,
    AutoHopEnabled = false,
    BannedServers = {}
}

local function SaveData()
    if writefile then
        pcall(function()
            writefile(ConfigFile, HttpService:JSONEncode(AppData))
        end)
    end
end

local function LoadData()
    if isfile and isfile(ConfigFile) and readfile then
        pcall(function()
            local decoded = HttpService:JSONDecode(readfile(ConfigFile))
            if decoded then
                AppData.MaxPlayers = decoded.MaxPlayers or 5
                AppData.AutoHopEnabled = decoded.AutoHopEnabled or false
                AppData.BannedServers = decoded.BannedServers or {}
            end
        end)
    end
end

LoadData()
AppData.BannedServers[game.JobId] = true
SaveData()

-- ==========================================
-- KÉO THẢ GUI
-- ==========================================
local function MakeDraggable(guiObject)
    local dragging, dragInput, dragStart, startPos
    guiObject.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = guiObject.AbsolutePosition
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then dragging = false end
            end)
        end
    end)
    guiObject.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            dragInput = input
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if input == dragInput and dragging then
            local delta = input.Position - dragStart
            guiObject.Position = UDim2.new(0, startPos.X + delta.X, 0, startPos.Y + delta.Y)
        end
    end)
end

-- ==========================================
-- TẠO GUI CHÍNH & TABS
-- ==========================================
local LowServerFinder = Instance.new("ScreenGui")
LowServerFinder.Name = "LowServerFinder"
LowServerFinder.Parent = LocalPlayer:WaitForChild("PlayerGui")
LowServerFinder.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

local MainFrame = Instance.new("Frame")
MainFrame.Name = "MainFrame"
MainFrame.Parent = LowServerFinder
MainFrame.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
MainFrame.BorderSizePixel = 0
MainFrame.Position = UDim2.new(0.1267, 0, 0.1183, 0)
MainFrame.Size = UDim2.new(0, 700, 0, 480) -- Tăng xíu chiều cao cho rộng rãi
local UICorner_Main = Instance.new("UICorner")
UICorner_Main.CornerRadius = UDim.new(0, 12)
UICorner_Main.Parent = MainFrame

local Title = Instance.new("TextLabel")
Title.Name = "Title"
Title.Parent = MainFrame
Title.BackgroundTransparency = 1
Title.Position = UDim2.new(0.02, 0, 0.015, 0)
Title.Size = UDim2.new(0, 500, 0, 30)
Title.Font = Enum.Font.GothamBold
Title.Text = "Server Finder & Auto-Hop ⚡"
Title.TextColor3 = Color3.fromRGB(255, 255, 255)
Title.TextScaled = true
Title.TextXAlignment = Enum.TextXAlignment.Left

-- Thanh Tab (Tab Bar)
local TabBar = Instance.new("Frame")
TabBar.Parent = MainFrame
TabBar.BackgroundTransparency = 1
TabBar.Position = UDim2.new(0, 0, 0.09, 0)
TabBar.Size = UDim2.new(1, 0, 0, 35)

local Tab1Btn = Instance.new("TextButton")
Tab1Btn.Parent = TabBar
Tab1Btn.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
Tab1Btn.Position = UDim2.new(0.01, 0, 0, 0)
Tab1Btn.Size = UDim2.new(0, 150, 1, 0)
Tab1Btn.Font = Enum.Font.GothamBold
Tab1Btn.Text = "🌍 Server List"
Tab1Btn.TextColor3 = Color3.fromRGB(255, 255, 255)
Tab1Btn.TextSize = 16
local UICorner_T1 = Instance.new("UICorner")
UICorner_T1.Parent = Tab1Btn

local Tab2Btn = Instance.new("TextButton")
Tab2Btn.Parent = TabBar
Tab2Btn.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
Tab2Btn.Position = UDim2.new(0.24, 0, 0, 0)
Tab2Btn.Size = UDim2.new(0, 150, 1, 0)
Tab2Btn.Font = Enum.Font.GothamBold
Tab2Btn.Text = "🛠️ Tiện Ích"
Tab2Btn.TextColor3 = Color3.fromRGB(200, 200, 200)
Tab2Btn.TextSize = 16
local UICorner_T2 = Instance.new("UICorner")
UICorner_T2.Parent = Tab2Btn

-- ==========================================
-- TAB 1: SERVER LIST (NỘI DUNG CŨ)
-- ==========================================
local Tab1Container = Instance.new("Frame")
Tab1Container.Parent = MainFrame
Tab1Container.BackgroundTransparency = 1
Tab1Container.Position = UDim2.new(0, 0, 0.18, 0)
Tab1Container.Size = UDim2.new(1, 0, 0.8, 0)
Tab1Container.Visible = true

local ConfigFrame = Instance.new("Frame")
ConfigFrame.Parent = Tab1Container
ConfigFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
ConfigFrame.Position = UDim2.new(0.008, 0, 0, 0)
ConfigFrame.Size = UDim2.new(0, 688, 0, 45)
local UICorner_Config = Instance.new("UICorner")
UICorner_Config.CornerRadius = UDim.new(0, 8)
UICorner_Config.Parent = ConfigFrame

local MaxPlayersLabel = Instance.new("TextLabel")
MaxPlayersLabel.Parent = ConfigFrame
MaxPlayersLabel.BackgroundTransparency = 1
MaxPlayersLabel.Position = UDim2.new(0.02, 0, 0.1, 0)
MaxPlayersLabel.Size = UDim2.new(0.35, 0, 0.8, 0)
MaxPlayersLabel.Font = Enum.Font.SourceSansBold
MaxPlayersLabel.Text = "Nếu Server vượt quá:"
MaxPlayersLabel.TextColor3 = Color3.fromRGB(220, 220, 220)
MaxPlayersLabel.TextSize = 18
MaxPlayersLabel.TextXAlignment = Enum.TextXAlignment.Left

local MaxPlayersInput = Instance.new("TextBox")
MaxPlayersInput.Parent = ConfigFrame
MaxPlayersInput.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
MaxPlayersInput.Position = UDim2.new(0.38, 0, 0.15, 0)
MaxPlayersInput.Size = UDim2.new(0, 60, 0, 30)
MaxPlayersInput.Font = Enum.Font.SourceSansBold
MaxPlayersInput.Text = tostring(AppData.MaxPlayers)
MaxPlayersInput.TextColor3 = Color3.fromRGB(255, 255, 255)
MaxPlayersInput.TextSize = 18
local UICorner_Input = Instance.new("UICorner")
UICorner_Input.Parent = MaxPlayersInput

local AutoHopToggle = Instance.new("TextButton")
AutoHopToggle.Parent = ConfigFrame
AutoHopToggle.Position = UDim2.new(0.5, 0, 0.15, 0)
AutoHopToggle.Size = UDim2.new(0, 150, 0, 30)
AutoHopToggle.Font = Enum.Font.SourceSansBold
AutoHopToggle.TextSize = 16
local UICorner_Toggle = Instance.new("UICorner")
UICorner_Toggle.Parent = AutoHopToggle

local function UpdateToggleUI()
    if AppData.AutoHopEnabled then
        AutoHopToggle.BackgroundColor3 = Color3.fromRGB(50, 150, 50)
        AutoHopToggle.Text = "Auto-Hop: BẬT"
    else
        AutoHopToggle.BackgroundColor3 = Color3.fromRGB(150, 50, 50)
        AutoHopToggle.Text = "Auto-Hop: TẮT"
    end
end
UpdateToggleUI()

local RefreshBtn = Instance.new("TextButton")
RefreshBtn.Parent = ConfigFrame
RefreshBtn.BackgroundColor3 = Color3.fromRGB(85, 85, 255)
RefreshBtn.Position = UDim2.new(0.74, 0, 0.15, 0)
RefreshBtn.Size = UDim2.new(0, 160, 0, 30)
RefreshBtn.Font = Enum.Font.SourceSansBold
RefreshBtn.Text = "Làm Mới List 🔄"
RefreshBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
RefreshBtn.TextSize = 16
local UICorner_Refresh = Instance.new("UICorner")
UICorner_Refresh.Parent = RefreshBtn

local ServerListFrame = Instance.new("ScrollingFrame")
ServerListFrame.Parent = Tab1Container
ServerListFrame.BackgroundColor3 = Color3.fromRGB(70, 70, 70)
ServerListFrame.BorderSizePixel = 0
ServerListFrame.Position = UDim2.new(0.008, 0, 0.14, 0)
ServerListFrame.Size = UDim2.new(0, 688, 0, 330)
ServerListFrame.ScrollBarThickness = 4

local UIListLayout = Instance.new("UIListLayout")
UIListLayout.Parent = ServerListFrame

local ServerFrameTemplate = Instance.new("Frame")
ServerFrameTemplate.BackgroundColor3 = Color3.fromRGB(80, 80, 80)
ServerFrameTemplate.Size = UDim2.new(0, 668, 0, 40)
ServerFrameTemplate.Visible = false
local UICorner_Server = Instance.new("UICorner")
UICorner_Server.Parent = ServerFrameTemplate

local ServerInfo = Instance.new("TextLabel")
ServerInfo.Name = "ServerInfo"
ServerInfo.Parent = ServerFrameTemplate
ServerInfo.BackgroundTransparency = 1
ServerInfo.Position = UDim2.new(0.02, 0, 0, 0)
ServerInfo.Size = UDim2.new(0.75, 0, 1, 0)
ServerInfo.Font = Enum.Font.SourceSans
ServerInfo.TextColor3 = Color3.fromRGB(255, 255, 255)
ServerInfo.TextScaled = true
ServerInfo.TextXAlignment = Enum.TextXAlignment.Left

local Join = Instance.new("TextButton")
Join.Name = "Join"
Join.Parent = ServerFrameTemplate
Join.BackgroundColor3 = Color3.fromRGB(85, 85, 255)
Join.Position = UDim2.new(0.81, 0, 0, 0)
Join.Size = UDim2.new(0, 114, 0, 40)
Join.Font = Enum.Font.SourceSans
Join.Text = "Join 🚀"
Join.TextColor3 = Color3.fromRGB(255, 255, 255)
Join.TextScaled = true

-- ==========================================
-- TAB 2: TIỆN ÍCH (MỚI)
-- ==========================================
local Tab2Container = Instance.new("Frame")
Tab2Container.Parent = MainFrame
Tab2Container.BackgroundTransparency = 1
Tab2Container.Position = UDim2.new(0, 0, 0.18, 0)
Tab2Container.Size = UDim2.new(1, 0, 0.8, 0)
Tab2Container.Visible = false

-- Ảnh Game & Tên Game
local GameIcon = Instance.new("ImageLabel")
GameIcon.Parent = Tab2Container
GameIcon.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
GameIcon.Position = UDim2.new(0.05, 0, 0.05, 0)
GameIcon.Size = UDim2.new(0, 100, 0, 100)
GameIcon.Image = "rbxassetid://" .. gameIconId
local UICorner_Icon = Instance.new("UICorner")
UICorner_Icon.CornerRadius = UDim.new(0, 12)
UICorner_Icon.Parent = GameIcon

local GameNameTxt = Instance.new("TextLabel")
GameNameTxt.Parent = Tab2Container
GameNameTxt.BackgroundTransparency = 1
GameNameTxt.Position = UDim2.new(0.22, 0, 0.05, 0)
GameNameTxt.Size = UDim2.new(0.7, 0, 0, 40)
GameNameTxt.Font = Enum.Font.GothamBold
GameNameTxt.Text = gameName
GameNameTxt.TextColor3 = Color3.fromRGB(255, 255, 255)
GameNameTxt.TextSize = 24
GameNameTxt.TextWrapped = true
GameNameTxt.TextXAlignment = Enum.TextXAlignment.Left

-- Copy JobId
local CopyJobIdBtn = Instance.new("TextButton")
CopyJobIdBtn.Parent = Tab2Container
CopyJobIdBtn.BackgroundColor3 = Color3.fromRGB(200, 100, 0)
CopyJobIdBtn.Position = UDim2.new(0.22, 0, 0.18, 0)
CopyJobIdBtn.Size = UDim2.new(0, 200, 0, 35)
CopyJobIdBtn.Font = Enum.Font.GothamBold
CopyJobIdBtn.Text = "📋 Copy JobId Hiện Tại"
CopyJobIdBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
CopyJobIdBtn.TextSize = 14
local UICorner_CopyBtn = Instance.new("UICorner")
UICorner_CopyBtn.Parent = CopyJobIdBtn

-- Join by JobId
local JobIdInput = Instance.new("TextBox")
JobIdInput.Parent = Tab2Container
JobIdInput.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
JobIdInput.Position = UDim2.new(0.05, 0, 0.4, 0)
JobIdInput.Size = UDim2.new(0, 450, 0, 40)
JobIdInput.Font = Enum.Font.SourceSans
JobIdInput.PlaceholderText = "Dán JobId vào đây để join..."
JobIdInput.Text = ""
JobIdInput.TextColor3 = Color3.fromRGB(255, 255, 255)
JobIdInput.TextSize = 18
local UICorner_JobInput = Instance.new("UICorner")
UICorner_JobInput.Parent = JobIdInput

local JoinJobIdBtn = Instance.new("TextButton")
JoinJobIdBtn.Parent = Tab2Container
JoinJobIdBtn.BackgroundColor3 = Color3.fromRGB(85, 255, 85)
JoinJobIdBtn.Position = UDim2.new(0.72, 0, 0.4, 0)
JoinJobIdBtn.Size = UDim2.new(0, 150, 0, 40)
JoinJobIdBtn.Font = Enum.Font.GothamBold
JoinJobIdBtn.Text = "🚀 Bay Tới"
JoinJobIdBtn.TextColor3 = Color3.fromRGB(0, 50, 0)
JoinJobIdBtn.TextSize = 16
local UICorner_JoinJobId = Instance.new("UICorner")
UICorner_JoinJobId.Parent = JoinJobIdBtn

-- Random Servers Buttons
local RandomServerBtn = Instance.new("TextButton")
RandomServerBtn.Parent = Tab2Container
RandomServerBtn.BackgroundColor3 = Color3.fromRGB(85, 85, 255)
RandomServerBtn.Position = UDim2.new(0.05, 0, 0.6, 0)
RandomServerBtn.Size = UDim2.new(0, 300, 0, 45)
RandomServerBtn.Font = Enum.Font.GothamBold
RandomServerBtn.Text = "🎲 Random 1 Server Bất Kỳ"
RandomServerBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
RandomServerBtn.TextSize = 16
local UICorner_Rand1 = Instance.new("UICorner")
UICorner_Rand1.Parent = RandomServerBtn

local RandomLowServerBtn = Instance.new("TextButton")
RandomLowServerBtn.Parent = Tab2Container
RandomLowServerBtn.BackgroundColor3 = Color3.fromRGB(150, 50, 255)
RandomLowServerBtn.Position = UDim2.new(0.5, 0, 0.6, 0)
RandomLowServerBtn.Size = UDim2.new(0, 300, 0, 45)
RandomLowServerBtn.Font = Enum.Font.GothamBold
RandomLowServerBtn.Text = "👻 Random Server ÍT Người"
RandomLowServerBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
RandomLowServerBtn.TextSize = 16
local UICorner_Rand2 = Instance.new("UICorner")
UICorner_Rand2.Parent = RandomLowServerBtn

-- ==========================================
-- NÚT ĐÓNG & ẨN UI
-- ==========================================
local Close = Instance.new("TextButton")
Close.Parent = MainFrame
Close.BackgroundColor3 = Color3.fromRGB(200, 0, 0)
Close.Position = UDim2.new(0.91, 0, 0, 0)
Close.Size = UDim2.new(0, 55, 0, 36)
Close.Font = Enum.Font.SourceSans
Close.Text = "x"
Close.TextColor3 = Color3.fromRGB(255, 255, 255)
Close.TextScaled = true
local UICorner_Close = Instance.new("UICorner")
UICorner_Close.Parent = Close

local MinimizeBtn = Instance.new("TextButton")
MinimizeBtn.Parent = MainFrame
MinimizeBtn.BackgroundColor3 = Color3.fromRGB(200, 150, 0)
MinimizeBtn.Position = UDim2.new(0.825, 0, 0, 0)
MinimizeBtn.Size = UDim2.new(0, 55, 0, 36)
MinimizeBtn.Font = Enum.Font.SourceSans
MinimizeBtn.Text = "-"
MinimizeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
MinimizeBtn.TextScaled = true
local UICorner_Minimize = Instance.new("UICorner")
UICorner_Minimize.Parent = MinimizeBtn

local OpenBtn = Instance.new("TextButton")
OpenBtn.Parent = LowServerFinder
OpenBtn.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
OpenBtn.Position = UDim2.new(0.02, 0, 0.05, 0)
OpenBtn.Size = UDim2.new(0, 50, 0, 50)
OpenBtn.Font = Enum.Font.SourceSans
OpenBtn.Text = "👁️"
OpenBtn.TextScaled = true
OpenBtn.Visible = false
local UICorner_Open = Instance.new("UICorner")
UICorner_Open.CornerRadius = UDim.new(1, 0)
UICorner_Open.Parent = OpenBtn

MakeDraggable(OpenBtn)

Close.MouseButton1Click:Connect(function() LowServerFinder:Destroy() end)
MinimizeBtn.MouseButton1Click:Connect(function()
    MainFrame.Visible = false
    OpenBtn.Visible = true
end)
OpenBtn.MouseButton1Click:Connect(function()
    MainFrame.Visible = true
    OpenBtn.Visible = false
end)

-- ==========================================
-- LOGIC CÁC TAB
-- ==========================================
Tab1Btn.MouseButton1Click:Connect(function()
    Tab1Container.Visible = true
    Tab2Container.Visible = false
    Tab1Btn.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
    Tab1Btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    Tab2Btn.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    Tab2Btn.TextColor3 = Color3.fromRGB(200, 200, 200)
end)

Tab2Btn.MouseButton1Click:Connect(function()
    Tab1Container.Visible = false
    Tab2Container.Visible = true
    Tab2Btn.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
    Tab2Btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    Tab1Btn.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    Tab1Btn.TextColor3 = Color3.fromRGB(200, 200, 200)
end)

-- ==========================================
-- LOGIC TÌM SERVER (DÙNG CHUNG)
-- ==========================================
local function fetchServers(cursor)
    local url = string.format("https://games.roblox.com/v1/games/%d/servers/Public?sortOrder=Asc&limit=100", game.PlaceId)
    if cursor then url = url .. "&cursor=" .. cursor end
    
    local success, response = pcall(function()
        return requestFunc({Url = url, Method = "GET"})
    end)

    if success and response and response.Body then
        return HttpService:JSONDecode(response.Body)
    end
    return nil
end

local function getBestServers()
    local servers = {}
    local cursor = nil
    local maxPages = 2 
    local pagesScanned = 0

    repeat
        local data = fetchServers(cursor)
        if data and data.data then
            for _, server in ipairs(data.data) do
                table.insert(servers, server)
            end
            cursor = data.nextPageCursor
            pagesScanned = pagesScanned + 1
            task.wait(0.1) 
        else
            break
        end
    until not cursor or pagesScanned >= maxPages

    table.sort(servers, function(a, b)
        return a.playing < b.playing
    end)

    return servers
end

-- ==========================================
-- LOGIC TAB 1: HIỂN THỊ LIST SERVER
-- ==========================================
UIListLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
    ServerListFrame.CanvasSize = UDim2.new(0, 0, 0, UIListLayout.AbsoluteContentSize.Y)
end)

local function createServerEntry(serverData)
    local clone = ServerFrameTemplate:Clone()
    clone.Name = "ServerFrameClone"
    clone.Visible = true
    clone.Parent = ServerListFrame

    clone:FindFirstChild("ServerInfo").Text = string.format("Server: %s | (ID: %s)\n👥 %d / %d", 
        gameName, string.sub(tostring(serverData.id), 1, 8).."...", serverData.playing, serverData.maxPlayers)

    clone:FindFirstChild("Join").MouseButton1Click:Connect(function()
        TeleportService:TeleportToPlaceInstance(game.PlaceId, serverData.id, LocalPlayer)
    end)
end

local function reloadServerList()
    Title.Text = "Đang quét server... 🔍"
    for _, child in ipairs(ServerListFrame:GetChildren()) do
        if child.Name == "ServerFrameClone" then child:Destroy() end
    end

    local servers = getBestServers()
    Title.Text = "Server Finder & Auto-Hop ⚡"
    
    for _, server in ipairs(servers) do
        if server.playing < server.maxPlayers then
            createServerEntry(server)
        end
    end
end

RefreshBtn.MouseButton1Click:Connect(reloadServerList)
task.spawn(reloadServerList)

MaxPlayersInput.FocusLost:Connect(function()
    local val = tonumber(MaxPlayersInput.Text)
    if val then
        AppData.MaxPlayers = val
        SaveData()
    else
        MaxPlayersInput.Text = tostring(AppData.MaxPlayers)
    end
end)

AutoHopToggle.MouseButton1Click:Connect(function()
    AppData.AutoHopEnabled = not AppData.AutoHopEnabled
    UpdateToggleUI()
    SaveData()
end)

-- ==========================================
-- LOGIC TAB 2: TIỆN ÍCH (MỚI)
-- ==========================================
CopyJobIdBtn.MouseButton1Click:Connect(function()
    setclipboard(tostring(game.JobId))
    CopyJobIdBtn.Text = "✅ Đã Copy!"
    task.wait(2)
    CopyJobIdBtn.Text = "📋 Copy JobId Hiện Tại"
end)

JoinJobIdBtn.MouseButton1Click:Connect(function()
    local jobId = JobIdInput.Text
    if jobId and jobId ~= "" then
        JoinJobIdBtn.Text = "Đang bay..."
        pcall(function()
            TeleportService:TeleportToPlaceInstance(game.PlaceId, jobId, LocalPlayer)
        end)
        task.wait(3)
        JoinJobIdBtn.Text = "🚀 Bay Tới"
    end
end)

RandomServerBtn.MouseButton1Click:Connect(function()
    RandomServerBtn.Text = "Đang tìm..."
    local servers = getBestServers()
    if #servers > 0 then
        -- Lấy random từ toàn bộ list
        local randomSrv = servers[math.random(1, #servers)]
        RandomServerBtn.Text = "Bay vào phòng: " .. randomSrv.playing .. " người"
        TeleportService:TeleportToPlaceInstance(game.PlaceId, randomSrv.id, LocalPlayer)
    else
        RandomServerBtn.Text = "❌ Lỗi"
        task.wait(2)
        RandomServerBtn.Text = "🎲 Random 1 Server Bất Kỳ"
    end
end)

RandomLowServerBtn.MouseButton1Click:Connect(function()
    RandomLowServerBtn.Text = "Đang tìm phòng ma..."
    local servers = getBestServers()
    if #servers > 0 then
        -- Lấy random trong top 10 server ít người nhất (do bảng đã sort ascending)
        local range = math.min(10, #servers)
        local randomSrv = servers[math.random(1, range)]
        RandomLowServerBtn.Text = "Tìm thấy phòng: " .. randomSrv.playing .. " người!"
        TeleportService:TeleportToPlaceInstance(game.PlaceId, randomSrv.id, LocalPlayer)
    else
        RandomLowServerBtn.Text = "❌ Không tìm thấy"
        task.wait(2)
        RandomLowServerBtn.Text = "👻 Random Server ÍT Người"
    end
end)

-- ==========================================
-- VÒNG LẶP AUTO HOP KHI TREO
-- ==========================================
local isTeleporting = false
task.spawn(function()
    while task.wait(5) do
        if isTeleporting then continue end
        if AppData.AutoHopEnabled then
            local currentPlayersCount = #Players:GetPlayers()
            if currentPlayersCount > AppData.MaxPlayers then
                Title.Text = "⚠️ Đang tìm server có <= " .. AppData.MaxPlayers .. " người..."
                local servers = getBestServers()
                local targetServer = nil

                for _, server in ipairs(servers) do
                    if not AppData.BannedServers[server.id] and server.playing <= AppData.MaxPlayers then
                        targetServer = server
                        break
                    end
                end

                if targetServer then
                    Title.Text = "🚀 Lụm được server " .. targetServer.playing .. " người! Đang bay..."
                    AppData.BannedServers[targetServer.id] = true 
                    SaveData()
                    isTeleporting = true
                    pcall(function()
                        TeleportService:TeleportToPlaceInstance(game.PlaceId, targetServer.id, LocalPlayer)
                    end)
                    task.wait(10)
                    isTeleporting = false
                else
                    Title.Text = "❌ Chưa tìm thấy server hợp lý! Chờ tí..."
                end
            else
                Title.Text = "Server Finder & Auto-Hop ⚡"
            end
        end
    end
end)

MakeDraggable(MainFrame)
