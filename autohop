local HttpService = game:GetService("HttpService")
local TweenService = game:GetService("TweenService")
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

local MainFrameGradient = Instance.new("UIGradient")
MainFrameGradient.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, Color3.fromRGB(55, 55, 55)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(25, 25, 25))
})
MainFrameGradient.Parent = MainFrame

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
MaxPlayersLabel.Text = "Nếu Server vượt quá số người:"
MaxPlayersLabel.TextColor3 = Color3.fromRGB(220, 220, 220)
MaxPlayersLabel.TextSize = 18
MaxPlayersLabel.TextXAlignment = Enum.TextXAlignment.Left

local MaxPlayersInput = Instance.new("TextBox")
MaxPlayersInput.Parent = ConfigFrame
MaxPlayersInput.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
MaxPlayersInput.Position = UDim2.new(0.38, 0, 0.15, 0)
MaxPlayersInput.Size = UDim2.new(0, 60, 0, 30)
MaxPlayersInput.Font = Enum.Font.SourceSansBold
MaxPlayersInput.Text = "5"
MaxPlayersInput.TextColor3 = Color3.fromRGB(255, 255, 255)
MaxPlayersInput.TextSize = 18
local UICorner_Input = Instance.new("UICorner")
UICorner_Input.CornerRadius = UDim.new(0, 4)
UICorner_Input.Parent = MaxPlayersInput

local AutoHopToggle = Instance.new("TextButton")
AutoHopToggle.Parent = ConfigFrame
AutoHopToggle.BackgroundColor3 = Color3.fromRGB(150, 50, 50)
AutoHopToggle.Position = UDim2.new(0.5, 0, 0.15, 0)
AutoHopToggle.Size = UDim2.new(0, 150, 0, 30)
AutoHopToggle.Font = Enum.Font.SourceSansBold
AutoHopToggle.Text = "Auto-Hop: TẮT"
AutoHopToggle.TextColor3 = Color3.fromRGB(255, 255, 255)
AutoHopToggle.TextSize = 16
local UICorner_Toggle = Instance.new("UICorner")
UICorner_Toggle.CornerRadius = UDim.new(0, 6)
UICorner_Toggle.Parent = AutoHopToggle

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

local HideShow = Instance.new("TextButton")
HideShow.Parent = LowServerFinder
HideShow.BackgroundColor3 = Color3.fromRGB(0, 200, 0)
HideShow.Position = UDim2.new(-0.001, 0, 0.465, 0)
HideShow.Size = UDim2.new(0, 55, 0, 36)
HideShow.Font = Enum.Font.SourceSans
HideShow.Text = "Hide"
HideShow.TextColor3 = Color3.fromRGB(255, 255, 255)
HideShow.TextScaled = true
local UICorner_HideShow = Instance.new("UICorner")
UICorner_HideShow.CornerRadius = UDim.new(0, 8)
UICorner_HideShow.Parent = HideShow

local isHidden = false
HideShow.MouseButton1Click:Connect(function()
    if not isHidden then
        MainFrame.Visible = false
        HideShow.Text = "Show"
        isHidden = true
    else
        MainFrame.Visible = true
        HideShow.Text = "Hide"
        isHidden = false
    end
end)

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
-- LOGIC TÌM SERVER (Tối ưu sịn sò, chống Rate Limit)
-- ==========================================
local bannedServers = {[game.JobId] = true} -- Tự động cho phòng hiện tại vào sổ đen

local function fetchServers(cursor)
    -- sortOrder=Asc đã tự động đưa server ít người lên đầu tiên rồi!
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
    local maxPages = 2 -- CHỈ QUÉT TỐI ĐA 2 TRANG! (200 server) là quá đủ để tìm phòng vắng, chống bị chặn API.
    local pagesScanned = 0

    repeat
        local data = fetchServers(cursor)
        if data and data.data then
            for _, server in ipairs(data.data) do
                table.insert(servers, server)
            end
            cursor = data.nextPageCursor
            pagesScanned = pagesScanned + 1
            task.wait(0.1) -- Delay siêu nhỏ để Roblox khỏi nghi spam
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
-- LOGIC AUTO HOP (Đã fix lỗi so sánh điều kiện)
-- ==========================================
local autoHopEnabled = false
local isTeleporting = false

AutoHopToggle.MouseButton1Click:Connect(function()
    autoHopEnabled = not autoHopEnabled
    if autoHopEnabled then
        AutoHopToggle.BackgroundColor3 = Color3.fromRGB(50, 150, 50)
        AutoHopToggle.Text = "Auto-Hop: BẬT"
    else
        AutoHopToggle.BackgroundColor3 = Color3.fromRGB(150, 50, 50)
        AutoHopToggle.Text = "Auto-Hop: TẮT"
        isTeleporting = false
    end
end)

task.spawn(function()
    while task.wait(5) do
        if isTeleporting then continue end

        if autoHopEnabled then
            local maxLimit = tonumber(MaxPlayersInput.Text) or 5
            local currentPlayersCount = #Players:GetPlayers()

            -- CHỈ KHI phòng hiện tại đông hơn mức cài đặt thì mới nhảy
            if currentPlayersCount > maxLimit then
                Title.Text = "⚠️ Đang tìm server có <= " .. maxLimit .. " người..."
                
                local servers = getBestServers()
                local targetServer = nil

                -- Lọc server thoả mãn: Chưa bị ban và số người PHẢI NHỎ HƠN HOẶC BẰNG giới hạn bạn đặt
                for _, server in ipairs(servers) do
                    if not bannedServers[server.id] and server.playing <= maxLimit then
                        targetServer = server
                        break
                    end
                end

                if targetServer then
                    Title.Text = "🚀 Lụm được server " .. targetServer.playing .. " người! Đang bay..."
                    
                    -- Cho server này vào sổ đen luôn, lỡ nó bị lỗi thì vòng lặp sau sẽ lấy server khác
                    bannedServers[targetServer.id] = true 
                    isTeleporting = true
                    
                    pcall(function()
                        TeleportService:TeleportToPlaceInstance(game.PlaceId, targetServer.id, LocalPlayer)
                    end)
                    
                    task.wait(10) -- Chờ game dịch chuyển
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
MakeDraggable(HideShow)
