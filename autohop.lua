local HttpService = game:GetService("HttpService")
local TeleportService = game:GetService("TeleportService")
local Players = game:GetService("Players")
local MarketplaceService = game:GetService("MarketplaceService")
local UserInputService = game:GetService("UserInputService")
local LocalPlayer = Players.LocalPlayer

local requestFunc = nil
if syn and syn.request then requestFunc = syn.request
elseif http and http.request then requestFunc = http.request
elseif http_request then requestFunc = http_request
elseif fluxus and fluxus.request then requestFunc = fluxus.request
elseif request then requestFunc = request
else error("Không tìm thấy hàm HTTP request phù hợp! 😢") end

local gameName = "Unknown"
pcall(function()
    local info = MarketplaceService:GetProductInfo(game.PlaceId)
    gameName = info.Name or gameName
end)

-- ==========================================
-- HỆ THỐNG LƯU FILE (CHO AUTO-EXECUTE)
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
                
                -- Giữ Blacklist để không chui lại vào server cũ
                AppData.BannedServers = decoded.BannedServers or {}
            end
        end)
    end
end

-- Tải dữ liệu từ file ngay khi script vừa chạy (do autoexec)
LoadData()
-- Tự động đưa phòng hiện tại vào Blacklist để không lặp lại
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
-- TẠO GUI 
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
MainFrame.Size = UDim2.new(0, 700, 0, 450)
local UICorner_Main = Instance.new("UICorner")
UICorner_Main.CornerRadius = UDim.new(0, 12)
UICorner_Main.Parent = MainFrame

local Title = Instance.new("TextLabel")
Title.Name = "Title"
Title.Parent = MainFrame
Title.BackgroundTransparency = 1
Title.Position = UDim2.new(0.00857, 0, 0.015, 0)
Title.Size = UDim2.new(0, 500, 0, 30)
Title.Font = Enum.Font.GothamBold
Title.Text = "Server Finder & Auto-Hop ⚡"
Title.TextColor3 = Color3.fromRGB(255, 255, 255)
Title.TextScaled = true
Title.TextXAlignment = Enum.TextXAlignment.Left

local ConfigFrame = Instance.new("Frame")
ConfigFrame.Name = "ConfigFrame"
ConfigFrame.Parent = MainFrame
ConfigFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
ConfigFrame.Position = UDim2.new(0.00857, 0, 0.1, 0)
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
MaxPlayersInput.Text = tostring(AppData.MaxPlayers) -- Lấy từ file lưu
MaxPlayersInput.TextColor3 = Color3.fromRGB(255, 255, 255)
MaxPlayersInput.TextSize = 18
local UICorner_Input = Instance.new("UICorner")
UICorner_Input.CornerRadius = UDim.new(0, 4)
UICorner_Input.Parent = MaxPlayersInput

local AutoHopToggle = Instance.new("TextButton")
AutoHopToggle.Parent = ConfigFrame
AutoHopToggle.Position = UDim2.new(0.5, 0, 0.15, 0)
AutoHopToggle.Size = UDim2.new(0, 150, 0, 30)
AutoHopToggle.Font = Enum.Font.SourceSansBold
AutoHopToggle.TextSize = 16
local UICorner_Toggle = Instance.new("UICorner")
UICorner_Toggle.CornerRadius = UDim.new(0, 6)
UICorner_Toggle.Parent = AutoHopToggle

-- Cập nhật giao diện nút Toggle dựa trên dữ liệu load từ file
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
UICorner_Refresh.CornerRadius = UDim.new(0, 6)
UICorner_Refresh.Parent = RefreshBtn

local ServerListFrame = Instance.new("ScrollingFrame")
ServerListFrame.Parent = MainFrame
ServerListFrame.BackgroundColor3 = Color3.fromRGB(70, 70, 70)
ServerListFrame.BorderSizePixel = 0
ServerListFrame.Position = UDim2.new(0.00857, 0, 0.22, 0)
ServerListFrame.Size = UDim2.new(0, 688, 0, 340)
ServerListFrame.ScrollBarThickness = 4

local UIListLayout = Instance.new("UIListLayout")
UIListLayout.Parent = ServerListFrame

local ServerFrameTemplate = Instance.new("Frame")
ServerFrameTemplate.BackgroundColor3 = Color3.fromRGB(80, 80, 80)
ServerFrameTemplate.Size = UDim2.new(0, 668, 0, 40)
ServerFrameTemplate.Visible = false
local UICorner_Server = Instance.new("UICorner")
UICorner_Server.CornerRadius = UDim.new(0, 8)
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

local Close = Instance.new("TextButton")
Close.Parent = MainFrame
Close.BackgroundColor3 = Color3.fromRGB(200, 0, 0)
Close.Position = UDim2.new(0.91286, 0, 0, 0)
Close.Size = UDim2.new(0, 55, 0, 36)
Close.Font = Enum.Font.SourceSans
Close.Text = "x"
Close.TextColor3 = Color3.fromRGB(255, 255, 255)
Close.TextScaled = true
local UICorner_Close = Instance.new("UICorner")
UICorner_Close.CornerRadius = UDim.new(0, 8)
UICorner_Close.Parent = Close

Close.MouseButton1Click:Connect(function()
    LowServerFinder:Destroy()
end)

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

-- ==========================================
-- LOGIC TÌM SERVER 
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

-- ==========================================
-- SỰ KIỆN TƯƠNG TÁC (LƯU LẠI KHI THAY ĐỔI)
-- ==========================================
MaxPlayersInput.FocusLost:Connect(function()
    local val = tonumber(MaxPlayersInput.Text)
    if val then
        AppData.MaxPlayers = val
        SaveData() -- Lưu lại số mới vào file
    else
        MaxPlayersInput.Text = tostring(AppData.MaxPlayers)
    end
end)

AutoHopToggle.MouseButton1Click:Connect(function()
    AppData.AutoHopEnabled = not AppData.AutoHopEnabled
    UpdateToggleUI()
    SaveData() -- Lưu lại trạng thái BẬT/TẮT vào file
end)

-- ==========================================
-- VÒNG LẶP AUTO HOP KHI TREO AUTO-EXEC
-- ==========================================
local isTeleporting = false

task.spawn(function()
    while task.wait(5) do
        if isTeleporting then continue end

        -- Nó sẽ đọc biến AppData.AutoHopEnabled (đã được load từ file)
        if AppData.AutoHopEnabled then
            local currentPlayersCount = #Players:GetPlayers()

            if currentPlayersCount > AppData.MaxPlayers then
                Title.Text = "⚠️ Đang tìm server có <= " .. AppData.MaxPlayers .. " người..."
                
                local servers = getBestServers()
                local targetServer = nil

                for _, server in ipairs(servers) do
                    -- Kiểm tra xem ID có nằm trong file Blacklist không
                    if not AppData.BannedServers[server.id] and server.playing <= AppData.MaxPlayers then
                        targetServer = server
                        break
                    end
                end

                if targetServer then
                    Title.Text = "🚀 Lụm được server " .. targetServer.playing .. " người! Đang bay..."
                    
                    -- Ghi ID server mới vào Blacklist và Save liền
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
