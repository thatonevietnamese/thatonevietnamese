local HttpService = game:GetService("HttpService")
local TeleportService = game:GetService("TeleportService")
local Players = game:GetService("Players")
local MarketplaceService = game:GetService("MarketplaceService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Stats = game:GetService("Stats")
local LocalPlayer = Players.LocalPlayer

if LocalPlayer:WaitForChild("PlayerGui"):FindFirstChild("LowServerFinder") then
    LocalPlayer.PlayerGui.LowServerFinder:Destroy()
end

local setclipboard = setclipboard or toclipboard or function(text) warn("Executor không hỗ trợ copy!") end

local requestFunc = nil
if syn and syn.request then requestFunc = syn.request
elseif http and http.request then requestFunc = http.request
elseif http_request then requestFunc = http_request
elseif fluxus and fluxus.request then requestFunc = fluxus.request
elseif request then requestFunc = request
else error("Không tìm thấy hàm HTTP request!") end

local gameName = "Unknown Game"
local gameIconId = 0
pcall(function()
    local info = MarketplaceService:GetProductInfo(game.PlaceId)
    gameName = info.Name or gameName
    gameIconId = info.IconImageAssetId or 0
end)

local currentThemeColor = Color3.fromRGB(40, 40, 40)
local currentTransparency = 0
local currentTab = 1
local isBindingKey = false

-- ==========================================
-- HỆ THỐNG LƯU FILE (ĐÃ NÂNG CẤP LƯU TIỆN ÍCH)
-- ==========================================
local ConfigFile = "AutoHop_Data.json"
local AppData = {
    MaxPlayers = 5,
    AutoHopEnabled = false,
    AutoRefresh = 0,
    UIScale = 1,
    ToggleKey = "RightControl",
    BannedServers = {},
    ThemeRGB = {R = 40, G = 40, B = 40},
    Transparency = 0,
    -- DỮ LIỆU TÍNH NĂNG MỚI ĐƯỢC LƯU
    SavedWalkSpeed = "",
    SavedJumpPower = "",
    LoopModsEnabled = false,
    InfJumpEnabled = false
}

local function SaveData()
    if writefile then
        local now = os.time()
        local cleanBanned = {}
        for id, banTime in pairs(AppData.BannedServers) do
            if type(banTime) == "number" and now - banTime < 600 then cleanBanned[id] = banTime end
        end
        AppData.BannedServers = cleanBanned
        AppData.ThemeRGB = { R = math.floor(currentThemeColor.R * 255), G = math.floor(currentThemeColor.G * 255), B = math.floor(currentThemeColor.B * 255) }
        AppData.Transparency = currentTransparency
        pcall(function() writefile(ConfigFile, HttpService:JSONEncode(AppData)) end)
    end
end

local function LoadData()
    if isfile and isfile(ConfigFile) and readfile then
        pcall(function()
            local decoded = HttpService:JSONDecode(readfile(ConfigFile))
            if decoded then
                AppData.MaxPlayers = decoded.MaxPlayers or 5
                AppData.AutoHopEnabled = decoded.AutoHopEnabled or false
                AppData.AutoRefresh = decoded.AutoRefresh or 0
                AppData.UIScale = decoded.UIScale or 1
                AppData.ToggleKey = decoded.ToggleKey or "RightControl"
                
                -- Khôi phục tính năng Tiện ích
                AppData.SavedWalkSpeed = decoded.SavedWalkSpeed or ""
                AppData.SavedJumpPower = decoded.SavedJumpPower or ""
                AppData.LoopModsEnabled = decoded.LoopModsEnabled or false
                AppData.InfJumpEnabled = decoded.InfJumpEnabled or false
                
                local now = os.time()
                local cleanBanned = {}
                if decoded.BannedServers then
                    for id, banTime in pairs(decoded.BannedServers) do
                        if type(banTime) == "number" and now - banTime < 600 then cleanBanned[id] = banTime end
                    end
                end
                AppData.BannedServers = cleanBanned
                
                if decoded.ThemeRGB and decoded.ThemeRGB.R then currentThemeColor = Color3.fromRGB(decoded.ThemeRGB.R, decoded.ThemeRGB.G, decoded.ThemeRGB.B) end
                if decoded.Transparency then currentTransparency = decoded.Transparency end
            end
        end)
    end
end

LoadData()
AppData.BannedServers[game.JobId] = os.time()
SaveData()

-- ==========================================
-- KHỞI TẠO GIAO DIỆN
-- ==========================================
local LowServerFinder = Instance.new("ScreenGui")
LowServerFinder.Name = "LowServerFinder"
LowServerFinder.ResetOnSpawn = false
LowServerFinder.Parent = LocalPlayer:WaitForChild("PlayerGui")
LowServerFinder.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

local MainFrame = Instance.new("Frame", LowServerFinder)
MainFrame.Name = "MainFrame"
MainFrame.BorderSizePixel = 0
MainFrame.Position = UDim2.new(0.12, 0, 0.1, 0)
MainFrame.Size = UDim2.new(0, 700, 0, 480)
Instance.new("UICorner", MainFrame).CornerRadius = UDim.new(0, 12)

local MainScale = Instance.new("UIScale", MainFrame)
MainScale.Scale = AppData.UIScale

local function MakeDraggable(guiObject)
    local dragging, dragInput, dragStart, startPos
    guiObject.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true; dragStart = input.Position; startPos = guiObject.AbsolutePosition
            input.Changed:Connect(function() if input.UserInputState == Enum.UserInputState.End then dragging = false end end)
        end
    end)
    guiObject.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then dragInput = input end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if input == dragInput and dragging then
            local delta = input.Position - dragStart
            guiObject.Position = UDim2.new(0, startPos.X + (delta.X / MainScale.Scale), 0, startPos.Y + (delta.Y / MainScale.Scale))
        end
    end)
end
MakeDraggable(MainFrame)

local Title = Instance.new("TextLabel", MainFrame)
Title.BackgroundTransparency = 1; Title.Position = UDim2.new(0.02, 0, 0.015, 0); Title.Size = UDim2.new(0, 450, 0, 30); Title.Font = Enum.Font.GothamBold; Title.Text = "Server Finder & Auto-Hop ⚡"; Title.TextColor3 = Color3.fromRGB(255, 255, 255); Title.TextSize = 18; Title.TextXAlignment = Enum.TextXAlignment.Left

local TabBar = Instance.new("Frame", MainFrame)
TabBar.BackgroundTransparency = 1; TabBar.Position = UDim2.new(0, 0, 0.09, 0); TabBar.Size = UDim2.new(1, 0, 0, 35)

local function CreateTabBtn(text, posX)
    local btn = Instance.new("TextButton", TabBar)
    btn.Position = UDim2.new(posX, 0, 0, 0); btn.Size = UDim2.new(0, 150, 1, 0); btn.Font = Enum.Font.GothamBold; btn.Text = text; btn.TextColor3 = Color3.fromRGB(220, 220, 220); btn.TextSize = 13
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6)
    return btn
end

local Tab1Btn = CreateTabBtn("🌍 Server List", 0.01)
local Tab2Btn = CreateTabBtn("🛠️ Tiện Ích", 0.24)
local Tab3Btn = CreateTabBtn("⚙️ Cài Đặt UI", 0.47)

local Tab1Container = Instance.new("Frame", MainFrame); Tab1Container.BackgroundTransparency = 1; Tab1Container.Position = UDim2.new(0, 0, 0.18, 0); Tab1Container.Size = UDim2.new(1, 0, 0.8, 0)
local Tab2Container = Instance.new("Frame", MainFrame); Tab2Container.BackgroundTransparency = 1; Tab2Container.Position = UDim2.new(0, 0, 0.18, 0); Tab2Container.Size = UDim2.new(1, 0, 0.8, 0); Tab2Container.Visible = false
local Tab3Container = Instance.new("ScrollingFrame", MainFrame); Tab3Container.BackgroundTransparency = 1; Tab3Container.Position = UDim2.new(0, 0, 0.18, 0); Tab3Container.Size = UDim2.new(1, 0, 0.8, 0); Tab3Container.CanvasSize = UDim2.new(0, 0, 0, 520); Tab3Container.ScrollBarThickness = 5; Tab3Container.Visible = false

local MinimizeBtn = Instance.new("TextButton", MainFrame); MinimizeBtn.BackgroundColor3 = Color3.fromRGB(200, 150, 0); MinimizeBtn.Position = UDim2.new(0.825, 0, 0.015, 0); MinimizeBtn.Size = UDim2.new(0, 50, 0, 30); MinimizeBtn.Font = Enum.Font.SourceSansBold; MinimizeBtn.Text = "-"; MinimizeBtn.TextColor3 = Color3.fromRGB(255, 255, 255); MinimizeBtn.TextSize = 20; Instance.new("UICorner", MinimizeBtn).CornerRadius = UDim.new(0, 6)
local Close = Instance.new("TextButton", MainFrame); Close.BackgroundColor3 = Color3.fromRGB(200, 0, 0); Close.Position = UDim2.new(0.91, 0, 0.015, 0); Close.Size = UDim2.new(0, 50, 0, 30); Close.Font = Enum.Font.SourceSansBold; Close.Text = "x"; Close.TextColor3 = Color3.fromRGB(255, 255, 255); Close.TextSize = 18; Instance.new("UICorner", Close).CornerRadius = UDim.new(0, 6)

local OpenBtn = Instance.new("TextButton", LowServerFinder)
OpenBtn.Name = "OpenToggleBtn"; OpenBtn.Position = UDim2.new(0.02, 0, 0.2, 0); OpenBtn.Size = UDim2.new(0, 90, 0, 35); OpenBtn.Font = Enum.Font.GothamBold; OpenBtn.Text = "⚡ Menu"; OpenBtn.TextColor3 = Color3.fromRGB(255, 255, 255); OpenBtn.TextSize = 13; OpenBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 40); OpenBtn.Visible = false
Instance.new("UICorner", OpenBtn).CornerRadius = UDim.new(0, 8); local OpenBtnStroke = Instance.new("UIStroke", OpenBtn); OpenBtnStroke.Color = Color3.fromRGB(255, 255, 255); OpenBtnStroke.Thickness = 1.5
MakeDraggable(OpenBtn)

Close.MouseButton1Click:Connect(function() LowServerFinder:Destroy() end)
MinimizeBtn.MouseButton1Click:Connect(function() MainFrame.Visible = false; OpenBtn.Visible = true end)
OpenBtn.MouseButton1Click:Connect(function() MainFrame.Visible = true; OpenBtn.Visible = false end)

UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if isBindingKey and input.UserInputType == Enum.UserInputType.Keyboard then
        AppData.ToggleKey = input.KeyCode.Name; isBindingKey = false; SaveData(); return
    end
    if not gameProcessed and AppData.ToggleKey and AppData.ToggleKey ~= "" then
        local valid, keyEnum = pcall(function() return Enum.KeyCode[AppData.ToggleKey] end)
        if valid and input.KeyCode == keyEnum then
            MainFrame.Visible = not MainFrame.Visible; OpenBtn.Visible = not MainFrame.Visible
        end
    end
end)

-- UI Biến Tab 1 & Tab 2
local ConfigFrame = Instance.new("Frame", Tab1Container); local ServerListFrame = Instance.new("ScrollingFrame", Tab1Container)
local MaxPlayersInput = Instance.new("TextBox", ConfigFrame); local AutoHopToggle = Instance.new("TextButton", ConfigFrame); local AutoRefreshInput = Instance.new("TextBox", ConfigFrame); local RefreshBtn = Instance.new("TextButton", ConfigFrame)
local GameIcon = Instance.new("ImageLabel", Tab2Container); local JobIdInput = Instance.new("TextBox", Tab2Container); local JoinJobIdBtn = Instance.new("TextButton", Tab2Container); local CopyJobIdBtn = Instance.new("TextButton", Tab2Container)
local RandomServerBtn = Instance.new("TextButton", Tab2Container); local RandomLowServerBtn = Instance.new("TextButton", Tab2Container); local RandLowPingBtn = Instance.new("TextButton", Tab2Container); local RandHighPingBtn = Instance.new("TextButton", Tab2Container); local JoinFriendBtn = Instance.new("TextButton", Tab2Container)
local SetSpeedInput = Instance.new("TextBox", Tab2Container); local SetJumpInput = Instance.new("TextBox", Tab2Container); local ApplyModsBtn = Instance.new("TextButton", Tab2Container)
local InfJumpBtn = Instance.new("TextButton", Tab2Container); local ShowStatsBtn = Instance.new("TextButton", Tab2Container); local IYBtn = Instance.new("TextButton", Tab2Container); local AntiLagBtn = Instance.new("TextButton", Tab2Container)

-- ==========================================
-- ĐỒNG BỘ THEME & MÀU SẮC AUTO-SAVE
-- ==========================================
local function ApplyTheme(color, transparency)
    if color then currentThemeColor = color end
    if transparency then currentTransparency = transparency end
    local darkTone = currentThemeColor:Lerp(Color3.fromRGB(0, 0, 0), 0.25); local lighterTone = currentThemeColor:Lerp(Color3.fromRGB(255, 255, 255), 0.15); local deepDark = currentThemeColor:Lerp(Color3.fromRGB(0, 0, 0), 0.45)
    
    MainFrame.BackgroundColor3 = currentThemeColor; MainFrame.BackgroundTransparency = currentTransparency; OpenBtn.BackgroundColor3 = currentThemeColor
    Tab1Btn.BackgroundColor3 = (currentTab == 1) and lighterTone or darkTone; Tab2Btn.BackgroundColor3 = (currentTab == 2) and lighterTone or darkTone; Tab3Btn.BackgroundColor3 = (currentTab == 3) and lighterTone or darkTone
    
    ConfigFrame.BackgroundColor3 = darkTone; ServerListFrame.BackgroundColor3 = deepDark; GameIcon.BackgroundColor3 = darkTone
    MaxPlayersInput.BackgroundColor3 = deepDark; JobIdInput.BackgroundColor3 = deepDark; SetSpeedInput.BackgroundColor3 = deepDark; SetJumpInput.BackgroundColor3 = deepDark
    
    RefreshBtn.BackgroundColor3 = lighterTone; JoinJobIdBtn.BackgroundColor3 = lighterTone; CopyJobIdBtn.BackgroundColor3 = darkTone
    
    RandomServerBtn.BackgroundColor3 = Color3.fromRGB(60, 110, 200); RandomLowServerBtn.BackgroundColor3 = Color3.fromRGB(110, 60, 200)
    RandLowPingBtn.BackgroundColor3 = Color3.fromRGB(0, 140, 140); RandHighPingBtn.BackgroundColor3 = Color3.fromRGB(150, 70, 0)
    JoinFriendBtn.BackgroundColor3 = Color3.fromRGB(200, 120, 30); IYBtn.BackgroundColor3 = Color3.fromRGB(80, 80, 180); AntiLagBtn.BackgroundColor3 = Color3.fromRGB(80, 180, 80)
    
    if AppData.AutoHopEnabled then AutoHopToggle.BackgroundColor3 = Color3.fromRGB(50, 150, 50); AutoHopToggle.Text = "Auto Hop: BẬT 🟢" else AutoHopToggle.BackgroundColor3 = Color3.fromRGB(150, 50, 50); AutoHopToggle.Text = "Auto Hop: TẮT 🔴" end
    
    -- Cập nhật màu nút tiện ích dựa theo state
    if AppData.LoopModsEnabled then ApplyModsBtn.BackgroundColor3 = Color3.fromRGB(50, 150, 50) else ApplyModsBtn.BackgroundColor3 = lighterTone end
    if AppData.InfJumpEnabled then InfJumpBtn.BackgroundColor3 = Color3.fromRGB(50, 150, 50) else InfJumpBtn.BackgroundColor3 = lighterTone end

    SaveData() 
end

local function SwitchTab(tab)
    currentTab = tab; Tab1Container.Visible = (tab == 1); Tab2Container.Visible = (tab == 2); Tab3Container.Visible = (tab == 3)
    ApplyTheme()
end
Tab1Btn.MouseButton1Click:Connect(function() SwitchTab(1) end); Tab2Btn.MouseButton1Click:Connect(function() SwitchTab(2) end); Tab3Btn.MouseButton1Click:Connect(function() SwitchTab(3) end)

-- Thiết kế nhanh UI Tab 1 & Tab 2 (Lược gọn phần size/pos để tối ưu mã)
ConfigFrame.Position = UDim2.new(0.008, 0, 0, 0); ConfigFrame.Size = UDim2.new(0, 688, 0, 45); Instance.new("UICorner", ConfigFrame).CornerRadius = UDim.new(0, 8)
ServerListFrame.BorderSizePixel = 0; ServerListFrame.Position = UDim2.new(0.008, 0, 0.14, 0); ServerListFrame.Size = UDim2.new(0, 688, 0, 330); ServerListFrame.ScrollBarThickness = 4
local ServerListLayout = Instance.new("UIListLayout", ServerListFrame); ServerListLayout.Padding = UDim.new(0, 6); ServerListLayout.SortOrder = Enum.SortOrder.LayoutOrder
ServerListLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function() ServerListFrame.CanvasSize = UDim2.new(0, 0, 0, ServerListLayout.AbsoluteContentSize.Y + 10) end)

MaxPlayersInput.Position = UDim2.new(0.02, 0, 0.15, 0); MaxPlayersInput.Size = UDim2.new(0, 120, 0, 30); MaxPlayersInput.Font = Enum.Font.SourceSansBold; MaxPlayersInput.PlaceholderText = "Giới hạn người"; MaxPlayersInput.Text = tostring(AppData.MaxPlayers); MaxPlayersInput.TextColor3 = Color3.fromRGB(255, 255, 255); MaxPlayersInput.TextSize = 15; Instance.new("UICorner", MaxPlayersInput).CornerRadius = UDim.new(0, 6)
AutoHopToggle.Position = UDim2.new(0.21, 0, 0.15, 0); AutoHopToggle.Size = UDim2.new(0, 150, 0, 30); AutoHopToggle.Font = Enum.Font.GothamBold; AutoHopToggle.TextColor3 = Color3.fromRGB(255, 255, 255); AutoHopToggle.TextSize = 13; Instance.new("UICorner", AutoHopToggle).CornerRadius = UDim.new(0, 6)
AutoRefreshInput.Position = UDim2.new(0.44, 0, 0.15, 0); AutoRefreshInput.Size = UDim2.new(0, 120, 0, 30); AutoRefreshInput.Font = Enum.Font.SourceSansBold; AutoRefreshInput.PlaceholderText = "Auto Refresh(s)"; AutoRefreshInput.Text = AppData.AutoRefresh > 0 and tostring(AppData.AutoRefresh) or "Tắt"; AutoRefreshInput.TextColor3 = Color3.fromRGB(255, 255, 255); AutoRefreshInput.TextSize = 15; Instance.new("UICorner", AutoRefreshInput).CornerRadius = UDim.new(0, 6)
RefreshBtn.Position = UDim2.new(0.63, 0, 0.15, 0); RefreshBtn.Size = UDim2.new(0, 240, 0, 30); RefreshBtn.Font = Enum.Font.GothamBold; RefreshBtn.Text = "Làm Mới Bảng Ngay 🔄"; RefreshBtn.TextColor3 = Color3.fromRGB(255, 255, 255); RefreshBtn.TextSize = 13; Instance.new("UICorner", RefreshBtn).CornerRadius = UDim.new(0, 6)

GameIcon.Position = UDim2.new(0.05, 0, 0.02, 0); GameIcon.Size = UDim2.new(0, 60, 0, 60); GameIcon.Image = "rbxassetid://" .. gameIconId; Instance.new("UICorner", GameIcon).CornerRadius = UDim.new(0, 10)
local GameNameTxt = Instance.new("TextLabel", Tab2Container); GameNameTxt.BackgroundTransparency = 1; GameNameTxt.Position = UDim2.new(0.18, 0, 0.02, 0); GameNameTxt.Size = UDim2.new(0.7, 0, 0, 30); GameNameTxt.Font = Enum.Font.GothamBold; GameNameTxt.Text = gameName; GameNameTxt.TextColor3 = Color3.fromRGB(255, 255, 255); GameNameTxt.TextSize = 18; GameNameTxt.TextXAlignment = Enum.TextXAlignment.Left

CopyJobIdBtn.Position = UDim2.new(0.18, 0, 0.12, 0); CopyJobIdBtn.Size = UDim2.new(0, 150, 0, 25); CopyJobIdBtn.Font = Enum.Font.GothamBold; CopyJobIdBtn.Text = "📋 Copy Server JobId"; CopyJobIdBtn.TextColor3 = Color3.fromRGB(255, 255, 255); CopyJobIdBtn.TextSize = 12; Instance.new("UICorner", CopyJobIdBtn).CornerRadius = UDim.new(0, 6)
JobIdInput.Position = UDim2.new(0.05, 0, 0.22, 0); JobIdInput.Size = UDim2.new(0, 440, 0, 35); JobIdInput.Font = Enum.Font.SourceSans; JobIdInput.PlaceholderText = "Dán mã JobId cần kết nối vào đây..."; JobIdInput.Text = ""; JobIdInput.TextColor3 = Color3.fromRGB(255, 255, 255); JobIdInput.TextSize = 14; Instance.new("UICorner", JobIdInput).CornerRadius = UDim.new(0, 6)
JoinJobIdBtn.Position = UDim2.new(0.70, 0, 0.22, 0); JoinJobIdBtn.Size = UDim2.new(0, 160, 0, 35); JoinJobIdBtn.Font = Enum.Font.GothamBold; JoinJobIdBtn.Text = "🚀 Bay Tới Server"; JoinJobIdBtn.TextColor3 = Color3.fromRGB(255, 255, 255); JoinJobIdBtn.TextSize = 13; Instance.new("UICorner", JoinJobIdBtn).CornerRadius = UDim.new(0, 6)
RandomServerBtn.Position = UDim2.new(0.05, 0, 0.33, 0); RandomServerBtn.Size = UDim2.new(0, 290, 0, 35); RandomServerBtn.Font = Enum.Font.GothamBold; RandomServerBtn.Text = "🎲 Random Server (Toàn Cầu)"; RandomServerBtn.TextColor3 = Color3.fromRGB(255, 255, 255); RandomServerBtn.TextSize = 13; Instance.new("UICorner", RandomServerBtn).CornerRadius = UDim.new(0, 6)
RandomLowServerBtn.Position = UDim2.new(0.51, 0, 0.33, 0); RandomLowServerBtn.Size = UDim2.new(0, 290, 0, 35); RandomLowServerBtn.Font = Enum.Font.GothamBold; RandomLowServerBtn.Text = "👻 Random Server Ít Người"; RandomLowServerBtn.TextColor3 = Color3.fromRGB(255, 255, 255); RandomLowServerBtn.TextSize = 13; Instance.new("UICorner", RandomLowServerBtn).CornerRadius = UDim.new(0, 6)
RandLowPingBtn.Position = UDim2.new(0.05, 0, 0.44, 0); RandLowPingBtn.Size = UDim2.new(0, 290, 0, 35); RandLowPingBtn.Font = Enum.Font.GothamBold; RandLowPingBtn.Text = "📶 Server Ping Thấp Khác Nhau"; RandLowPingBtn.TextColor3 = Color3.fromRGB(255, 255, 255); RandLowPingBtn.TextSize = 13; Instance.new("UICorner", RandLowPingBtn).CornerRadius = UDim.new(0, 6)
RandHighPingBtn.Position = UDim2.new(0.51, 0, 0.44, 0); RandHighPingBtn.Size = UDim2.new(0, 290, 0, 35); RandHighPingBtn.Font = Enum.Font.GothamBold; RandHighPingBtn.Text = "⚠️ Server Ping Cao (Né Trẻ Trâu)"; RandHighPingBtn.TextColor3 = Color3.fromRGB(255, 255, 255); RandHighPingBtn.TextSize = 13; Instance.new("UICorner", RandHighPingBtn).CornerRadius = UDim.new(0, 6)
JoinFriendBtn.Position = UDim2.new(0.05, 0, 0.55, 0); JoinFriendBtn.Size = UDim2.new(0, 580, 0, 35); JoinFriendBtn.Font = Enum.Font.GothamBold; JoinFriendBtn.Text = "👥 Join Random Friend Server (Tham gia cùng bạn bè)"; JoinFriendBtn.TextColor3 = Color3.fromRGB(255, 255, 255); JoinFriendBtn.TextSize = 13; Instance.new("UICorner", JoinFriendBtn).CornerRadius = UDim.new(0, 6)
SetSpeedInput.Position = UDim2.new(0.05, 0, 0.66, 0); SetSpeedInput.Size = UDim2.new(0, 190, 0, 35); SetSpeedInput.Font = Enum.Font.SourceSans; SetSpeedInput.PlaceholderText = "Tốc độ chạy"; SetSpeedInput.TextColor3 = Color3.fromRGB(255, 255, 255); SetSpeedInput.TextSize = 14; Instance.new("UICorner", SetSpeedInput).CornerRadius = UDim.new(0, 6)
SetJumpInput.Position = UDim2.new(0.35, 0, 0.66, 0); SetJumpInput.Size = UDim2.new(0, 190, 0, 35); SetJumpInput.Font = Enum.Font.SourceSans; SetJumpInput.PlaceholderText = "Lực nhảy"; SetJumpInput.TextColor3 = Color3.fromRGB(255, 255, 255); SetJumpInput.TextSize = 14; Instance.new("UICorner", SetJumpInput).CornerRadius = UDim.new(0, 6)
ApplyModsBtn.Position = UDim2.new(0.65, 0, 0.66, 0); ApplyModsBtn.Size = UDim2.new(0, 195, 0, 35); ApplyModsBtn.Font = Enum.Font.GothamBold; ApplyModsBtn.Text = "⚡ Khóa Chỉ Số: TẮT"; ApplyModsBtn.TextColor3 = Color3.fromRGB(255, 255, 255); ApplyModsBtn.TextSize = 13; Instance.new("UICorner", ApplyModsBtn).CornerRadius = UDim.new(0, 6)
InfJumpBtn.Position = UDim2.new(0.05, 0, 0.77, 0); InfJumpBtn.Size = UDim2.new(0, 190, 0, 35); InfJumpBtn.Font = Enum.Font.GothamBold; InfJumpBtn.Text = "🦘 Nhảy Vô Hạn: TẮT"; InfJumpBtn.TextColor3 = Color3.fromRGB(255, 255, 255); InfJumpBtn.TextSize = 13; Instance.new("UICorner", InfJumpBtn).CornerRadius = UDim.new(0, 6)
ShowStatsBtn.Position = UDim2.new(0.28, 0, 0.77, 0); ShowStatsBtn.Size = UDim2.new(0, 190, 0, 35); ShowStatsBtn.Font = Enum.Font.GothamBold; ShowStatsBtn.Text = "🖥️ Mở Bảng Stats"; ShowStatsBtn.TextColor3 = Color3.fromRGB(255, 255, 255); ShowStatsBtn.TextSize = 13; Instance.new("UICorner", ShowStatsBtn).CornerRadius = UDim.new(0, 6)
IYBtn.Position = UDim2.new(0.51, 0, 0.77, 0); IYBtn.Size = UDim2.new(0, 130, 0, 35); IYBtn.Font = Enum.Font.GothamBold; IYBtn.Text = "🛠️ Mở IY"; IYBtn.TextColor3 = Color3.fromRGB(255, 255, 255); IYBtn.TextSize = 13; Instance.new("UICorner", IYBtn).CornerRadius = UDim.new(0, 6)
AntiLagBtn.Position = UDim2.new(0.72, 0, 0.77, 0); AntiLagBtn.Size = UDim2.new(0, 130, 0, 35); AntiLagBtn.Font = Enum.Font.GothamBold; AntiLagBtn.Text = "🚀 Anti Lag"; AntiLagBtn.TextColor3 = Color3.fromRGB(255, 255, 255); AntiLagBtn.TextSize = 13; Instance.new("UICorner", AntiLagBtn).CornerRadius = UDim.new(0, 6)

-- Tab 3 (Cài đặt)
local function createSectionTitle(text, posY)
    local lbl = Instance.new("TextLabel", Tab3Container)
    lbl.BackgroundTransparency = 1; lbl.Position = UDim2.new(0.05, 0, posY, 0); lbl.Size = UDim2.new(0, 600, 0, 25); lbl.Font = Enum.Font.GothamBold; lbl.Text = text; lbl.TextColor3 = Color3.fromRGB(255, 220, 100); lbl.TextSize = 15; lbl.TextXAlignment = Enum.TextXAlignment.Left
end
createSectionTitle("📐 Kích Thước Giao Diện (UI Scale):", 0.02)
local ScaleMinusBtn = Instance.new("TextButton", Tab3Container); ScaleMinusBtn.BackgroundColor3 = Color3.fromRGB(70, 70, 70); ScaleMinusBtn.Position = UDim2.new(0.05, 0, 0.08, 0); ScaleMinusBtn.Size = UDim2.new(0, 40, 0, 30); ScaleMinusBtn.Font = Enum.Font.GothamBold; ScaleMinusBtn.Text = "-"; ScaleMinusBtn.TextColor3 = Color3.fromRGB(255, 255, 255); Instance.new("UICorner", ScaleMinusBtn).CornerRadius = UDim.new(0, 6)
local ScaleValueLabel = Instance.new("TextLabel", Tab3Container); ScaleValueLabel.BackgroundColor3 = Color3.fromRGB(30, 30, 30); ScaleValueLabel.Position = UDim2.new(0.12, 0, 0.08, 0); ScaleValueLabel.Size = UDim2.new(0, 100, 0, 30); ScaleValueLabel.Font = Enum.Font.GothamBold; ScaleValueLabel.Text = string.format("%.1fx", AppData.UIScale); ScaleValueLabel.TextColor3 = Color3.fromRGB(255, 255, 255); Instance.new("UICorner", ScaleValueLabel).CornerRadius = UDim.new(0, 6)
local ScalePlusBtn = Instance.new("TextButton", Tab3Container); ScalePlusBtn.BackgroundColor3 = Color3.fromRGB(70, 70, 70); ScalePlusBtn.Position = UDim2.new(0.28, 0, 0.08, 0); ScalePlusBtn.Size = UDim2.new(0, 40, 0, 30); ScalePlusBtn.Font = Enum.Font.GothamBold; ScalePlusBtn.Text = "+"; ScalePlusBtn.TextColor3 = Color3.fromRGB(255, 255, 255); Instance.new("UICorner", ScalePlusBtn).CornerRadius = UDim.new(0, 6)
local function UpdateScale(newScale)
    AppData.UIScale = math.clamp(math.round(newScale * 10) / 10, 0.5, 2.0); MainScale.Scale = AppData.UIScale; ScaleValueLabel.Text = string.format("%.1fx", AppData.UIScale); SaveData()
end
ScaleMinusBtn.MouseButton1Click:Connect(function() UpdateScale(AppData.UIScale - 0.1) end); ScalePlusBtn.MouseButton1Click:Connect(function() UpdateScale(AppData.UIScale + 0.1) end)

createSectionTitle("👁️ Độ Mờ Trong Suốt (Transparency):", 0.17)
local TransContainer = Instance.new("Frame", Tab3Container); TransContainer.BackgroundTransparency = 1; TransContainer.Position = UDim2.new(0.05, 0, 0.23, 0); TransContainer.Size = UDim2.new(0, 600, 0, 30)
local TransOptions = { {text = "0% (Đậm)", val = 0}, {text = "20%", val = 0.2}, {text = "50%", val = 0.5}, {text = "70% (Mờ)", val = 0.7} }
for idx, opt in ipairs(TransOptions) do
    local btn = Instance.new("TextButton", TransContainer)
    btn.Position = UDim2.new((idx - 1) * 0.23, 0, 0, 0); btn.Size = UDim2.new(0, 120, 1, 0); btn.BackgroundColor3 = Color3.fromRGB(60, 60, 60); btn.Font = Enum.Font.GothamBold; btn.Text = opt.text; btn.TextColor3 = Color3.fromRGB(255, 255, 255); btn.TextSize = 12; Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6)
    btn.MouseButton1Click:Connect(function() ApplyTheme(nil, opt.val) end)
end

createSectionTitle("⌨️ Phím Tắt Ẩn/Hiện Menu:", 0.33)
local KeybindBtn = Instance.new("TextButton", Tab3Container); KeybindBtn.Position = UDim2.new(0.05, 0, 0.39, 0); KeybindBtn.Size = UDim2.new(0, 260, 0, 35); KeybindBtn.BackgroundColor3 = Color3.fromRGB(80, 80, 180); KeybindBtn.Font = Enum.Font.GothamBold; KeybindBtn.Text = "Phím hiện tại: " .. tostring(AppData.ToggleKey); KeybindBtn.TextColor3 = Color3.fromRGB(255, 255, 255); KeybindBtn.TextSize = 13; Instance.new("UICorner", KeybindBtn).CornerRadius = UDim.new(0, 6)
KeybindBtn.MouseButton1Click:Connect(function()
    isBindingKey = true; KeybindBtn.Text = "👉 Nhấn phím bất kỳ..."; KeybindBtn.BackgroundColor3 = Color3.fromRGB(200, 120, 0)
    local conn; conn = UserInputService.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.Keyboard then
            KeybindBtn.Text = "Phím hiện tại: " .. AppData.ToggleKey; KeybindBtn.BackgroundColor3 = Color3.fromRGB(80, 80, 180); conn:Disconnect()
        end
    end)
end)

createSectionTitle("🎨 Chủ Đề Màu Sắc (Theme Presets):", 0.50)
local ColorGrid = Instance.new("Frame", Tab3Container); ColorGrid.BackgroundTransparency = 1; ColorGrid.Position = UDim2.new(0.05, 0, 0.56, 0); ColorGrid.Size = UDim2.new(0, 600, 0, 45)
local UIGridLayout = Instance.new("UIGridLayout", ColorGrid); UIGridLayout.CellSize = UDim2.new(0, 40, 0, 40); UIGridLayout.CellPadding = UDim2.new(0, 10, 0, 10)
local ColorPresets = { Color3.fromRGB(40, 40, 40), Color3.fromRGB(20, 20, 20), Color3.fromRGB(15, 25, 60), Color3.fromRGB(60, 15, 15), Color3.fromRGB(15, 60, 25), Color3.fromRGB(60, 15, 60), Color3.fromRGB(80, 50, 10), Color3.fromRGB(10, 70, 80) }
for _, color in ipairs(ColorPresets) do
    local cBtn = Instance.new("TextButton", ColorGrid)
    cBtn.BackgroundColor3 = color; cBtn.Text = ""; Instance.new("UICorner", cBtn).CornerRadius = UDim.new(1, 0)
    cBtn.MouseButton1Click:Connect(function() ApplyTheme(color, nil) end)
end

local RandomColorBtn = Instance.new("TextButton", Tab3Container); RandomColorBtn.BackgroundColor3 = Color3.fromRGB(180, 80, 140); RandomColorBtn.Position = UDim2.new(0.05, 0, 0.70, 0); RandomColorBtn.Size = UDim2.new(0, 160, 0, 32); RandomColorBtn.Font = Enum.Font.GothamBold; RandomColorBtn.Text = "🌈 Random Màu"; RandomColorBtn.TextColor3 = Color3.fromRGB(255, 255, 255); RandomColorBtn.TextSize = 12; Instance.new("UICorner", RandomColorBtn).CornerRadius = UDim.new(0, 6)
RandomColorBtn.MouseButton1Click:Connect(function() ApplyTheme(Color3.fromRGB(math.random(15, 80), math.random(15, 80), math.random(15, 80)), nil) end)
local ResetConfigBtn = Instance.new("TextButton", Tab3Container); ResetConfigBtn.BackgroundColor3 = Color3.fromRGB(180, 40, 40); ResetConfigBtn.Position = UDim2.new(0.35, 0, 0.70, 0); ResetConfigBtn.Size = UDim2.new(0, 180, 0, 32); ResetConfigBtn.Font = Enum.Font.GothamBold; ResetConfigBtn.Text = "🔄 Reset Cài Đặt Ban Đầu"; ResetConfigBtn.TextColor3 = Color3.fromRGB(255, 255, 255); ResetConfigBtn.TextSize = 12; Instance.new("UICorner", ResetConfigBtn).CornerRadius = UDim.new(0, 6)
ResetConfigBtn.MouseButton1Click:Connect(function()
    AppData.UIScale = 1; AppData.ToggleKey = "RightControl"; MainScale.Scale = 1; ScaleValueLabel.Text = "1.0x"; KeybindBtn.Text = "Phím hiện tại: RightControl"; ApplyTheme(Color3.fromRGB(40, 40, 40), 0)
end)

-- ==========================================
-- LOGIC SERVER LIST
-- ==========================================
local isRefreshing = false
local function fetchServers(cursor)
    local url = string.format("https://games.roblox.com/v1/games/%d/servers/Public?sortOrder=Asc&limit=100", game.PlaceId)
    if cursor then url = url .. "&cursor=" .. cursor end
    local s, r = pcall(function() return requestFunc({Url = url, Method = "GET"}) end)
    if s and r and r.Body then return HttpService:JSONDecode(r.Body) end
    return nil
end

local function getAllServersSorted()
    local servers, cursor, pages = {}, nil, 0
    repeat
        local data = fetchServers(cursor)
        if data and data.data then
            for _, s in ipairs(data.data) do
                if s.playing < s.maxPlayers then s.ping = s.ping or math.huge; table.insert(servers, s) end
            end
            cursor = data.nextPageCursor; pages = pages + 1; task.wait(0.05)
        else break end
    until not cursor or pages >= 3
    table.sort(servers, function(a, b)
        if a.ping == b.ping then return a.playing < b.playing end
        return a.ping < b.ping
    end)
    return servers
end

local function TeleportToTarget(srvId)
    if not srvId then return end
    Title.Text = "Đang kết nối Server... 🚀"
    local s = pcall(function() TeleportService:TeleportToPlaceInstance(game.PlaceId, srvId, LocalPlayer) end)
    if not s then Title.Text = "Lỗi kết nối! Thử lại..."; task.wait(1.5); Title.Text = "Server Finder & Auto-Hop ⚡" end
end

local function PopulateServerList()
    if isRefreshing then return end
    isRefreshing = true; Title.Text = "Đang quét Server Ping... 📡"
    for _, child in ipairs(ServerListFrame:GetChildren()) do if child:IsA("Frame") then child:Destroy() end end
    local servers = getAllServersSorted()
    Title.Text = "Server Finder & Auto-Hop ⚡"
    
    for _, server in ipairs(servers) do
        if server.id ~= game.JobId then
            local clone = Instance.new("Frame", ServerListFrame)
            clone.BackgroundColor3 = Color3.fromRGB(50, 50, 50); clone.Size = UDim2.new(0, 668, 0, 45); Instance.new("UICorner", clone).CornerRadius = UDim.new(0, 8)
            local displayPing = (server.ping == math.huge) and "N/A" or tostring(server.ping)
            local txt = Instance.new("TextLabel", clone)
            txt.BackgroundTransparency = 1; txt.Position = UDim2.new(0.02, 0, 0, 0); txt.Size = UDim2.new(0.75, 0, 1, 0); txt.Font = Enum.Font.SourceSans; txt.TextColor3 = Color3.fromRGB(255, 255, 255); txt.TextSize = 14; txt.TextXAlignment = Enum.TextXAlignment.Left
            txt.Text = string.format("Server: %s...\n👥 %d/%d | Ping: %s ms", string.sub(tostring(server.id), 1, 12), server.playing, server.maxPlayers, displayPing)
            local jBtn = Instance.new("TextButton", clone)
            jBtn.BackgroundColor3 = Color3.fromRGB(80, 130, 255); jBtn.Position = UDim2.new(0.81, 0, 0.1, 0); jBtn.Size = UDim2.new(0, 114, 0, 36); jBtn.Font = Enum.Font.SourceSansBold; jBtn.Text = "Join 🚀"; jBtn.TextColor3 = Color3.fromRGB(255, 255, 255); jBtn.TextSize = 15; Instance.new("UICorner", jBtn).CornerRadius = UDim.new(0, 6)
            jBtn.MouseButton1Click:Connect(function() TeleportToTarget(server.id) end)
        end
    end
    isRefreshing = false
end

RefreshBtn.MouseButton1Click:Connect(function() if not isRefreshing then PopulateServerList() end end)
task.spawn(function()
    local timeCounter = 0
    while task.wait(1) do
        if AppData.AutoRefresh > 0 and not isRefreshing then
            timeCounter = timeCounter + 1
            if timeCounter >= AppData.AutoRefresh then PopulateServerList(); timeCounter = 0 end
        elseif isRefreshing then timeCounter = 0 end
    end
end)
AutoRefreshInput.FocusLost:Connect(function()
    local val = tonumber(AutoRefreshInput.Text)
    if val and val > 0 then AppData.AutoRefresh = val; SaveData() else AppData.AutoRefresh = 0; AutoRefreshInput.Text = "Tắt"; SaveData() end
end)

-- ==========================================
-- 🟢 LOGIC TIỆN ÍCH - CÓ AUTO SAVE
-- ==========================================
RandomServerBtn.MouseButton1Click:Connect(function() local servers = getAllServersSorted(); if #servers > 0 then TeleportToTarget(servers[math.random(1, #servers)].id) end end)
RandomLowServerBtn.MouseButton1Click:Connect(function() local servers = getAllServersSorted(); table.sort(servers, function(a, b) return a.playing < b.playing end); if #servers > 0 then TeleportToTarget(servers[math.random(1, math.min(8, #servers))].id) end end)
RandLowPingBtn.MouseButton1Click:Connect(function() local servers = getAllServersSorted(); if #servers > 0 then TeleportToTarget(servers[math.random(1, math.min(10, #servers))].id) end end)
RandHighPingBtn.MouseButton1Click:Connect(function() local servers = getAllServersSorted(); if #servers > 15 then TeleportToTarget(servers[math.random(#servers - 15, #servers)].id) elseif #servers > 0 then TeleportToTarget(servers[math.random(1, #servers)].id) end end)
JoinFriendBtn.MouseButton1Click:Connect(function()
    Title.Text = "Đang quét danh sách bạn bè... 👥"
    local s, friends = pcall(function() return LocalPlayer:GetFriendsOnline(200) end)
    if s and friends then
        local valid = {}
        for _, f in ipairs(friends) do if f.PlaceId == game.PlaceId and f.GameId and f.GameId ~= "" and f.GameId ~= game.JobId then table.insert(valid, f.GameId) end end
        if #valid > 0 then TeleportToTarget(valid[math.random(1, #valid)]) else Title.Text = "❌ Không có bạn bè nào đang chơi game này!"; task.wait(2.5); Title.Text = "Server Finder & Auto-Hop ⚡" end
    else Title.Text = "Lỗi hệ thống khi quét bạn bè!"; task.wait(2); Title.Text = "Server Finder & Auto-Hop ⚡" end
end)

CopyJobIdBtn.MouseButton1Click:Connect(function() setclipboard(tostring(game.JobId)); CopyJobIdBtn.Text = "✅ Đã Copy!"; task.wait(1.5); CopyJobIdBtn.Text = "📋 Copy Server JobId" end)
JoinJobIdBtn.MouseButton1Click:Connect(function() local j = JobIdInput.Text; if j ~= "" then TeleportToTarget(j) end end)
IYBtn.MouseButton1Click:Connect(function() pcall(function() loadstring(game:HttpGet('https://raw.githubusercontent.com/EdgeIY/infiniteyield/master/source'))() end) end)
AntiLagBtn.MouseButton1Click:Connect(function() pcall(function() loadstring(game:HttpGet('https://raw.githubusercontent.com/thatonevietnamese/thatonevietnamese/refs/heads/main/antilag.lua'))() end) end)

-- Khôi phục text hiển thị ngay khi load
SetSpeedInput.Text = AppData.SavedWalkSpeed
SetJumpInput.Text = AppData.SavedJumpPower

-- Tự động lưu giá trị khi bạn gõ xong
SetSpeedInput.FocusLost:Connect(function() AppData.SavedWalkSpeed = SetSpeedInput.Text; SaveData() end)
SetJumpInput.FocusLost:Connect(function() AppData.SavedJumpPower = SetJumpInput.Text; SaveData() end)

local loopWalkSpeed, loopJumpPower = nil, nil

-- Thiết lập lại biến Loop ngay lúc vừa load server nếu trạng thái là BẬT
if AppData.LoopModsEnabled then
    local s = tonumber(AppData.SavedWalkSpeed); local j = tonumber(AppData.SavedJumpPower)
    if s then loopWalkSpeed = math.clamp(s, 0, 200) end
    if j then loopJumpPower = math.clamp(j, 0, 200) end
    ApplyModsBtn.Text = "✅ Khóa Loop: BẬT"
end

ApplyModsBtn.MouseButton1Click:Connect(function()
    AppData.LoopModsEnabled = not AppData.LoopModsEnabled
    if AppData.LoopModsEnabled then
        local s = tonumber(SetSpeedInput.Text); local j = tonumber(SetJumpInput.Text)
        loopWalkSpeed = s and math.clamp(s, 0, 200) or nil
        loopJumpPower = j and math.clamp(j, 0, 200) or nil
        ApplyModsBtn.Text = "✅ Khóa Loop: BẬT"
    else
        loopWalkSpeed = nil; loopJumpPower = nil
        ApplyModsBtn.Text = "⚡ Khóa Chỉ Số: TẮT"
    end
    ApplyTheme() -- Đổi màu nút
end)

RunService.Heartbeat:Connect(function()
    local char = LocalPlayer.Character
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    if hum then
        if loopWalkSpeed then hum.WalkSpeed = loopWalkSpeed end
        if loopJumpPower then hum.JumpPower = loopJumpPower; hum.UseJumpPower = true end
    end
end)

-- Khôi phục trạng thái Nhảy Vô Hạn
local infJumpEnabled = AppData.InfJumpEnabled
if infJumpEnabled then InfJumpBtn.Text = "🦘 Nhảy Vô Hạn: BẬT" end

InfJumpBtn.MouseButton1Click:Connect(function()
    AppData.InfJumpEnabled = not AppData.InfJumpEnabled
    infJumpEnabled = AppData.InfJumpEnabled
    if infJumpEnabled then InfJumpBtn.Text = "🦘 Nhảy Vô Hạn: BẬT" else InfJumpBtn.Text = "🦘 Nhảy Vô Hạn: TẮT" end
    ApplyTheme() -- Đổi màu nút
end)

UserInputService.JumpRequest:Connect(function()
    if infJumpEnabled then local hum = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid"); if hum then hum:ChangeState(Enum.HumanoidStateType.Jumping) end end
end)

-- ==========================================
-- AUTO-HOP LOGIC & STATS TRACKER
-- ==========================================
MaxPlayersInput.FocusLost:Connect(function()
    local val = tonumber(MaxPlayersInput.Text)
    if val then AppData.MaxPlayers = val; SaveData() else MaxPlayersInput.Text = tostring(AppData.MaxPlayers) end
end)
AutoHopToggle.MouseButton1Click:Connect(function() AppData.AutoHopEnabled = not AppData.AutoHopEnabled; ApplyTheme() end)

local isTeleporting = false
task.spawn(function()
    while task.wait(3) do
        if AppData.AutoHopEnabled and not isTeleporting and #Players:GetPlayers() > AppData.MaxPlayers then
            isTeleporting = true
            local servers = getAllServersSorted()
            local targetServer = nil
            for _, srv in ipairs(servers) do
                if srv.id ~= game.JobId and srv.playing <= AppData.MaxPlayers and not AppData.BannedServers[srv.id] then targetServer = srv.id; break end
            end
            if targetServer then
                Title.Text = "Auto-Hop: Tìm thấy server, đang vào... 🚀"
                AppData.BannedServers[targetServer] = os.time(); SaveData(); TeleportToTarget(targetServer); task.wait(6)
            else Title.Text = "Auto-Hop: Đang tìm kiếm server phù hợp..." end
            isTeleporting = false
        end
    end
end)

local StatsGui = Instance.new("ScreenGui", LocalPlayer:WaitForChild("PlayerGui"))
StatsGui.Name = "StatsTracker"; StatsGui.ResetOnSpawn = false; StatsGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling; StatsGui.Enabled = false
local StatsFrame = Instance.new("Frame", StatsGui); StatsFrame.Size = UDim2.new(0, 150, 0, 60); StatsFrame.Position = UDim2.new(0.01, 0, 0.4, 0); StatsFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 25); StatsFrame.BackgroundTransparency = 0.4; Instance.new("UICorner", StatsFrame).CornerRadius = UDim.new(0, 8); MakeDraggable(StatsFrame)
local FpsLabel = Instance.new("TextLabel", StatsFrame); FpsLabel.Size = UDim2.new(1, 0, 0.5, 0); FpsLabel.BackgroundTransparency = 1; FpsLabel.TextColor3 = Color3.fromRGB(100, 255, 100); FpsLabel.Font = Enum.Font.GothamBold; FpsLabel.Text = "FPS: ..."
local PingLabel = Instance.new("TextLabel", StatsFrame); PingLabel.Size = UDim2.new(1, 0, 0.5, 0); PingLabel.Position = UDim2.new(0, 0, 0.5, 0); PingLabel.BackgroundTransparency = 1; PingLabel.TextColor3 = Color3.fromRGB(255, 200, 100); PingLabel.Font = Enum.Font.GothamBold; PingLabel.Text = "Ping: ..."

ShowStatsBtn.MouseButton1Click:Connect(function()
    StatsGui.Enabled = not StatsGui.Enabled
    if StatsGui.Enabled then ShowStatsBtn.Text = "🖥️ Đóng Bảng Stats"; ShowStatsBtn.BackgroundColor3 = Color3.fromRGB(150, 50, 50) else ShowStatsBtn.Text = "🖥️ Mở Bảng Stats"; ShowStatsBtn.BackgroundColor3 = Color3.fromRGB(50, 50, 55); ApplyTheme() end
end)

local frameCount, lastTime = 0, tick()
RunService.RenderStepped:Connect(function()
    if StatsGui.Enabled then
        frameCount = frameCount + 1
        local currentTime = tick()
        if currentTime - lastTime >= 1 then
            FpsLabel.Text = "FPS: " .. math.floor(frameCount / (currentTime - lastTime))
            frameCount = 0; lastTime = currentTime
            pcall(function() PingLabel.Text = "Ping: " .. math.floor(Stats.Network.ServerStatsItem["Data Ping"]:GetValue()) .. " ms" end)
        end
    end
end)

SwitchTab(1)
ApplyTheme()
PopulateServerList()
