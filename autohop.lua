local HttpService = game:GetService("HttpService")
local TeleportService = game:GetService("TeleportService")
local Players = game:GetService("Players")
local MarketplaceService = game:GetService("MarketplaceService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Stats = game:GetService("Stats")
local LocalPlayer = Players.LocalPlayer

-- Hàm hỗ trợ sao chép cho Executor
local setclipboard = setclipboard or toclipboard or function(text)
    warn("Executor của bạn không hỗ trợ tính năng copy (setclipboard)!")
end

local requestFunc = nil
if syn and syn.request then requestFunc = syn.request
elseif http and http.request then requestFunc = http.request
elseif http_request then requestFunc = http_request
elseif fluxus and fluxus.request then requestFunc = fluxus.request
elseif request then requestFunc = request
else 
    error("Không tìm thấy hàm HTTP request phù hợp để quét server công khai!") 
end

local gameName = "Unknown Game"
local gameIconId = 0
pcall(function()
    local info = MarketplaceService:GetProductInfo(game.PlaceId)
    gameName = info.Name or gameName
    gameIconId = info.IconImageAssetId or 0
end)

-- ==========================================
-- HỆ THỐNG LƯU FILE CẤU HÌNH AUTO-HOP
-- ==========================================
local ConfigFile = "AutoHop_Data.json"
local AppData = {
    MaxPlayers = 5,
    AutoHopEnabled = false,
    BannedServers = {}
}

local function SaveData()
    if writefile then
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
                AppData.BannedServers = decoded.BannedServers or {}
            end
        end)
    end
end

LoadData()
AppData.BannedServers[game.JobId] = true
SaveData()

-- ==========================================
-- HỆ THỐNG DI CHUYỂN KHUNG GUI (DRAGGABLE)
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
-- TẠO GIAO DIỆN CHÍNH (MAIN GUI)
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
MainFrame.Position = UDim2.new(0.12, 0, 0.1, 0)
MainFrame.Size = UDim2.new(0, 700, 0, 480)
local UICorner_Main = Instance.new("UICorner")
UICorner_Main.CornerRadius = UDim.new(0, 12)
UICorner_Main.Parent = MainFrame

local Title = Instance.new("TextLabel")
Title.Parent = MainFrame
Title.BackgroundTransparency = 1
Title.Position = UDim2.new(0.02, 0, 0.015, 0)
Title.Size = UDim2.new(0, 450, 0, 30)
Title.Font = Enum.Font.GothamBold
Title.Text = "Server Finder & Auto-Hop ⚡"
Title.TextColor3 = Color3.fromRGB(255, 255, 255)
Title.TextSize = 18
Title.TextXAlignment = Enum.TextXAlignment.Left

-- THANH CHỌN TAB (TAB BAR)
local TabBar = Instance.new("Frame")
TabBar.Parent = MainFrame
TabBar.BackgroundTransparency = 1
TabBar.Position = UDim2.new(0, 0, 0.09, 0)
TabBar.Size = UDim2.new(1, 0, 0, 35)

local function CreateTabBtn(text, posX)
    local btn = Instance.new("TextButton")
    btn.Parent = TabBar
    btn.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    btn.Position = UDim2.new(posX, 0, 0, 0)
    btn.Size = UDim2.new(0, 150, 1, 0)
    btn.Font = Enum.Font.GothamBold
    btn.Text = text
    btn.TextColor3 = Color3.fromRGB(220, 220, 220)
    btn.TextSize = 13
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6)
    return btn
end

local Tab1Btn = CreateTabBtn("🌍 Server List", 0.01)
local Tab2Btn = CreateTabBtn("🛠️ Tiện Ích", 0.24)
local Tab3Btn = CreateTabBtn("⚙️ Cài Đặt UI", 0.47)

-- KHUNG CHỨA NỘI DUNG TỪNG TAB
local Tab1Container = Instance.new("Frame")
Tab1Container.Parent = MainFrame
Tab1Container.BackgroundTransparency = 1
Tab1Container.Position = UDim2.new(0, 0, 0.18, 0)
Tab1Container.Size = UDim2.new(1, 0, 0.8, 0)
Tab1Container.Visible = true

local Tab2Container = Instance.new("ScrollingFrame")
Tab2Container.Parent = MainFrame
Tab2Container.BackgroundTransparency = 1
Tab2Container.Position = UDim2.new(0, 0, 0.18, 0)
Tab2Container.Size = UDim2.new(1, 0, 0.8, 0)
Tab2Container.CanvasSize = UDim2.new(0, 0, 0, 580)
Tab2Container.ScrollBarThickness = 5
Tab2Container.Visible = false

local Tab3Container = Instance.new("Frame")
Tab3Container.Parent = MainFrame
Tab3Container.BackgroundTransparency = 1
Tab3Container.Position = UDim2.new(0, 0, 0.18, 0)
Tab3Container.Size = UDim2.new(1, 0, 0.8, 0)
Tab3Container.Visible = false

-- ==========================================
-- NÚT ĐÓNG & THU NHỎ GIAO DIỆN
-- ==========================================
local MinimizeBtn = Instance.new("TextButton")
MinimizeBtn.Parent = MainFrame
MinimizeBtn.BackgroundColor3 = Color3.fromRGB(200, 150, 0)
MinimizeBtn.Position = UDim2.new(0.825, 0, 0.015, 0)
MinimizeBtn.Size = UDim2.new(0, 50, 0, 30)
MinimizeBtn.Font = Enum.Font.SourceSansBold
MinimizeBtn.Text = "-"
MinimizeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
MinimizeBtn.TextSize = 20
Instance.new("UICorner", MinimizeBtn).CornerRadius = UDim.new(0, 6)

local Close = Instance.new("TextButton")
Close.Parent = MainFrame
Close.BackgroundColor3 = Color3.fromRGB(200, 0, 0)
Close.Position = UDim2.new(0.91, 0, 0.015, 0)
Close.Size = UDim2.new(0, 50, 0, 30)
Close.Font = Enum.Font.SourceSansBold
Close.Text = "x"
Close.TextColor3 = Color3.fromRGB(255, 255, 255)
Close.TextSize = 18
Instance.new("UICorner", Close).CornerRadius = UDim.new(0, 6)

local OpenBtn = Instance.new("TextButton")
OpenBtn.Parent = LowServerFinder
OpenBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
OpenBtn.Position = UDim2.new(0.02, 0, 0.05, 0)
OpenBtn.Size = UDim2.new(0, 50, 0, 50)
OpenBtn.Font = Enum.Font.SourceSans
OpenBtn.Text = "👁️"
OpenBtn.TextSize = 24
OpenBtn.Visible = false
Instance.new("UICorner", OpenBtn).CornerRadius = UDim.new(1, 0)
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
-- HỆ THỐNG THAY ĐỔI MÀU TOÀN DIỆN (THEME SYSTEM)
-- ==========================================
local currentThemeColor = Color3.fromRGB(40, 40, 40)
local currentTransparency = 0
local currentTab = 1

local ConfigFrame = Instance.new("Frame", Tab1Container)
ConfigFrame.Position = UDim2.new(0.008, 0, 0, 0)
ConfigFrame.Size = UDim2.new(0, 688, 0, 45)
Instance.new("UICorner", ConfigFrame).CornerRadius = UDim.new(0, 8)

local ServerListFrame = Instance.new("ScrollingFrame", Tab1Container)
ServerListFrame.BorderSizePixel = 0
ServerListFrame.Position = UDim2.new(0.008, 0, 0.14, 0)
ServerListFrame.Size = UDim2.new(0, 688, 0, 330)
ServerListFrame.ScrollBarThickness = 4
Instance.new("UIListLayout", ServerListFrame).Padding = UDim.new(0, 6)

-- Các phần tử nhập liệu khác cần đổi màu nền
local MaxPlayersInput = Instance.new("TextBox", ConfigFrame)
local AutoHopToggle = Instance.new("TextButton", ConfigFrame)
local RefreshBtn = Instance.new("TextButton", ConfigFrame)

local GameIcon = Instance.new("ImageLabel", Tab2Container)
local JobIdInput = Instance.new("TextBox", Tab2Container)
local JoinJobIdBtn = Instance.new("TextButton", Tab2Container)
local CopyJobIdBtn = Instance.new("TextButton", Tab2Container)

local SetSpeedInput = Instance.new("TextBox", Tab2Container)
local SetJumpInput = Instance.new("TextBox", Tab2Container)
local ApplyModsBtn = Instance.new("TextButton", Tab2Container)

local TransInput = Instance.new("TextBox", Tab3Container)
local RGBInput = Instance.new("TextBox", Tab3Container)

local function ApplyTheme(color, transparency)
    if color then currentThemeColor = color end
    if transparency then currentTransparency = transparency end
    
    local darkTone = currentThemeColor:Lerp(Color3.fromRGB(0, 0, 0), 0.25)
    local lighterTone = currentThemeColor:Lerp(Color3.fromRGB(255, 255, 255), 0.15)
    local deepDark = currentThemeColor:Lerp(Color3.fromRGB(0, 0, 0), 0.45)
    
    -- Áp dụng cho Khung chính và nút đóng mở
    MainFrame.BackgroundColor3 = currentThemeColor
    MainFrame.BackgroundTransparency = currentTransparency
    OpenBtn.BackgroundColor3 = currentThemeColor
    
    -- Màu các nút Tab dựa trên Tab đang mở
    Tab1Btn.BackgroundColor3 = (currentTab == 1) and lighterTone or darkTone
    Tab2Btn.BackgroundColor3 = (currentTab == 2) and lighterTone or darkTone
    Tab3Btn.BackgroundColor3 = (currentTab == 3) and lighterTone or darkTone
    
    -- Đồng bộ màu các khung chứa
    ConfigFrame.BackgroundColor3 = darkTone
    ServerListFrame.BackgroundColor3 = deepDark
    GameIcon.BackgroundColor3 = darkTone
    
    -- Đồng bộ màu các hộp nhập liệu và các nút cấu hình
    MaxPlayersInput.BackgroundColor3 = deepDark
    JobIdInput.BackgroundColor3 = deepDark
    SetSpeedInput.BackgroundColor3 = deepDark
    SetJumpInput.BackgroundColor3 = deepDark
    TransInput.BackgroundColor3 = deepDark
    RGBInput.BackgroundColor3 = deepDark
    
    -- Đổi màu đồng bộ cho các nút phụ trong giao diện
    AutoHopToggle.BackgroundColor3 = AppData.AutoHopEnabled and Color3.fromRGB(50, 150, 50) or Color3.fromRGB(150, 50, 50)
    RefreshBtn.BackgroundColor3 = lighterTone
    JoinJobIdBtn.BackgroundColor3 = lighterTone
    CopyJobIdBtn.BackgroundColor3 = darkTone
    ApplyModsBtn.BackgroundColor3 = lighterTone
end

-- ==========================================
-- LOGIC ĐIỀU HƯỚNG TAB
-- ==========================================
local function SwitchTab(tab)
    currentTab = tab
    Tab1Container.Visible = (tab == 1)
    Tab2Container.Visible = (tab == 2)
    Tab3Container.Visible = (tab == 3)
    ApplyTheme()
end

Tab1Btn.MouseButton1Click:Connect(function() SwitchTab(1) end)
Tab2Btn.MouseButton1Click:Connect(function() SwitchTab(2) end)
Tab3Btn.MouseButton1Click:Connect(function() SwitchTab(3) end)

-- ==========================================
-- THIẾT KẾ CHI TIẾT TAB 1: SERVER LIST
-- ==========================================
local MaxPlayersLabel = Instance.new("TextLabel", ConfigFrame)
MaxPlayersLabel.BackgroundTransparency = 1
MaxPlayersLabel.Position = UDim2.new(0.02, 0, 0.15, 0)
MaxPlayersLabel.Size = UDim2.new(0, 240, 0, 30)
MaxPlayersLabel.Font = Enum.Font.GothamBold
MaxPlayersLabel.Text = "Hạn chế tối đa số người chơi:"
MaxPlayersLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
MaxPlayersLabel.TextSize = 14
MaxPlayersLabel.TextXAlignment = Enum.TextXAlignment.Left

MaxPlayersInput.Position = UDim2.new(0.38, 0, 0.15, 0)
MaxPlayersInput.Size = UDim2.new(0, 60, 0, 30)
MaxPlayersInput.Font = Enum.Font.SourceSansBold
MaxPlayersInput.Text = tostring(AppData.MaxPlayers)
MaxPlayersInput.TextColor3 = Color3.fromRGB(255, 255, 255)
MaxPlayersInput.TextSize = 16
Instance.new("UICorner", MaxPlayersInput).CornerRadius = UDim.new(0, 6)

AutoHopToggle.Position = UDim2.new(0.49, 0, 0.15, 0)
AutoHopToggle.Size = UDim2.new(0, 150, 0, 30)
AutoHopToggle.Font = Enum.Font.SourceSansBold
AutoHopToggle.TextColor3 = Color3.fromRGB(255, 255, 255)
AutoHopToggle.TextSize = 14
Instance.new("UICorner", AutoHopToggle).CornerRadius = UDim.new(0, 6)

RefreshBtn.Position = UDim2.new(0.725, 0, 0.15, 0)
RefreshBtn.Size = UDim2.new(0, 175, 0, 30)
RefreshBtn.Font = Enum.Font.SourceSansBold
RefreshBtn.Text = "Làm Mới Danh Sách 🔄"
RefreshBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
RefreshBtn.TextSize = 14
Instance.new("UICorner", RefreshBtn).CornerRadius = UDim.new(0, 6)

-- ==========================================
-- THIẾT KẾ CHI TIẾT TAB 2: TIỆN ÍCH (SCROLLING)
-- ==========================================
-- Thông tin game đang chơi
GameIcon.Position = UDim2.new(0.05, 0, 0.02, 0)
GameIcon.Size = UDim2.new(0, 70, 0, 70)
GameIcon.Image = "rbxassetid://" .. gameIconId
Instance.new("UICorner", GameIcon).CornerRadius = UDim.new(0, 10)

local GameNameTxt = Instance.new("TextLabel", Tab2Container)
GameNameTxt.BackgroundTransparency = 1
GameNameTxt.Position = UDim2.new(0.18, 0, 0.02, 0)
GameNameTxt.Size = UDim2.new(0.7, 0, 0, 35)
GameNameTxt.Font = Enum.Font.GothamBold
GameNameTxt.Text = gameName
GameNameTxt.TextColor3 = Color3.fromRGB(255, 255, 255)
GameNameTxt.TextSize = 18
GameNameTxt.TextXAlignment = Enum.TextXAlignment.Left

CopyJobIdBtn.Position = UDim2.new(0.18, 0, 0.10, 0)
CopyJobIdBtn.Size = UDim2.new(0, 150, 0, 25)
CopyJobIdBtn.Font = Enum.Font.GothamBold
CopyJobIdBtn.Text = "📋 Copy Server JobId"
CopyJobIdBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
CopyJobIdBtn.TextSize = 12
Instance.new("UICorner", CopyJobIdBtn).CornerRadius = UDim.new(0, 6)

-- Kết nối bằng ID trực tiếp
JobIdInput.Position = UDim2.new(0.05, 0, 0.18, 0)
JobIdInput.Size = UDim2.new(0, 440, 0, 35)
JobIdInput.Font = Enum.Font.SourceSans
JobIdInput.PlaceholderText = "Dán mã JobId cần kết nối vào đây..."
JobIdInput.Text = ""
JobIdInput.TextColor3 = Color3.fromRGB(255, 255, 255)
JobIdInput.TextSize = 14
Instance.new("UICorner", JobIdInput).CornerRadius = UDim.new(0, 6)

JoinJobIdBtn.Position = UDim2.new(0.70, 0, 0.18, 0)
JoinJobIdBtn.Size = UDim2.new(0, 160, 0, 35)
JoinJobIdBtn.Font = Enum.Font.GothamBold
JoinJobIdBtn.Text = "🚀 Bay Tới Server"
JoinJobIdBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
JoinJobIdBtn.TextSize = 13
Instance.new("UICorner", JoinJobIdBtn).CornerRadius = UDim.new(0, 6)

-- Hệ thống nhảy Server ngẫu nhiên và theo khu vực (Region)
local RandomServerBtn = Instance.new("TextButton", Tab2Container)
RandomServerBtn.BackgroundColor3 = Color3.fromRGB(60, 110, 200)
RandomServerBtn.Position = UDim2.new(0.05, 0, 0.28, 0)
RandomServerBtn.Size = UDim2.new(0, 290, 0, 35)
RandomServerBtn.Font = Enum.Font.GothamBold
RandomServerBtn.Text = "🎲 Random Server (Toàn Cầu)"
RandomServerBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
RandomServerBtn.TextSize = 13
Instance.new("UICorner", RandomServerBtn).CornerRadius = UDim.new(0, 6)

local RandomLowServerBtn = Instance.new("TextButton", Tab2Container)
RandomLowServerBtn.BackgroundColor3 = Color3.fromRGB(110, 60, 200)
RandomLowServerBtn.Position = UDim2.new(0.51, 0, 0.28, 0)
RandomLowServerBtn.Size = UDim2.new(0, 290, 0, 35)
RandomLowServerBtn.Font = Enum.Font.GothamBold
RandomLowServerBtn.Text = "👻 Random Server Ít Người"
RandomLowServerBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
RandomLowServerBtn.TextSize = 13
Instance.new("UICorner", RandomLowServerBtn).CornerRadius = UDim.new(0, 6)

local RandRegionBtn = Instance.new("TextButton", Tab2Container)
RandRegionBtn.BackgroundColor3 = Color3.fromRGB(0, 140, 140)
RandRegionBtn.Position = UDim2.new(0.05, 0, 0.37, 0)
RandRegionBtn.Size = UDim2.new(0, 290, 0, 35)
RandRegionBtn.Font = Enum.Font.GothamBold
RandRegionBtn.Text = "🌍 Random Cùng Vùng (Ping Thấp)"
RandRegionBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
RandRegionBtn.TextSize = 13
Instance.new("UICorner", RandRegionBtn).CornerRadius = UDim.new(0, 6)

local RandLowRegionBtn = Instance.new("TextButton", Tab2Container)
RandLowRegionBtn.BackgroundColor3 = Color3.fromRGB(0, 100, 150)
RandLowRegionBtn.Position = UDim2.new(0.51, 0, 0.37, 0)
RandLowRegionBtn.Size = UDim2.new(0, 290, 0, 35)
RandLowRegionBtn.Font = Enum.Font.GothamBold
RandLowRegionBtn.Text = "🧊 Random Ít Người & Cùng Vùng"
RandLowRegionBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
RandLowRegionBtn.TextSize = 13
Instance.new("UICorner", RandLowRegionBtn).CornerRadius = UDim.new(0, 6)

-- Khung hiệu chỉnh thông số Nhân Vật (Speed, Jump)
SetSpeedInput.Position = UDim2.new(0.05, 0, 0.48, 0)
SetSpeedInput.Size = UDim2.new(0, 190, 0, 35)
SetSpeedInput.Font = Enum.Font.SourceSans
SetSpeedInput.PlaceholderText = "Tốc độ chạy (Tối đa 200)"
SetSpeedInput.TextColor3 = Color3.fromRGB(255, 255, 255)
SetSpeedInput.TextSize = 14
Instance.new("UICorner", SetSpeedInput).CornerRadius = UDim.new(0, 6)

SetJumpInput.Position = UDim2.new(0.35, 0, 0.48, 0)
SetJumpInput.Size = UDim2.new(0, 190, 0, 35)
SetJumpInput.Font = Enum.Font.SourceSans
SetJumpInput.PlaceholderText = "Lực nhảy (Tối đa 200)"
SetJumpInput.TextColor3 = Color3.fromRGB(255, 255, 255)
SetJumpInput.TextSize = 14
Instance.new("UICorner", SetJumpInput).CornerRadius = UDim.new(0, 6)

ApplyModsBtn.Position = UDim2.new(0.65, 0, 0.48, 0)
ApplyModsBtn.Size = UDim2.new(0, 195, 0, 35)
ApplyModsBtn.Font = Enum.Font.GothamBold
ApplyModsBtn.Text = "⚡ Khóa Chỉ Số (Loop)"
ApplyModsBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
ApplyModsBtn.TextSize = 13
Instance.new("UICorner", ApplyModsBtn).CornerRadius = UDim.new(0, 6)

-- Infinite Jump & Pop-up Ping FPS
local InfJumpBtn = Instance.new("TextButton", Tab2Container)
InfJumpBtn.BackgroundColor3 = Color3.fromRGB(90, 90, 90)
InfJumpBtn.Position = UDim2.new(0.05, 0, 0.59, 0)
InfJumpBtn.Size = UDim2.new(0, 290, 0, 35)
InfJumpBtn.Font = Enum.Font.GothamBold
InfJumpBtn.Text = "🦘 Nhảy Vô Hạn: TẮT"
InfJumpBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
InfJumpBtn.TextSize = 13
Instance.new("UICorner", InfJumpBtn).CornerRadius = UDim.new(0, 6)

local ShowStatsBtn = Instance.new("TextButton", Tab2Container)
ShowStatsBtn.BackgroundColor3 = Color3.fromRGB(220, 140, 0)
ShowStatsBtn.Position = UDim2.new(0.51, 0, 0.59, 0)
ShowStatsBtn.Size = UDim2.new(0, 290, 0, 35)
ShowStatsBtn.Font = Enum.Font.GothamBold
ShowStatsBtn.Text = "🖥️ Mở Bảng Ping & FPS"
ShowStatsBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
ShowStatsBtn.TextSize = 13
Instance.new("UICorner", ShowStatsBtn).CornerRadius = UDim.new(0, 6)

-- ==========================================
-- THIẾT KẾ CHI TIẾT TAB 3: CÀI ĐẶT UI (UNIVERSAL)
-- ==========================================
local TransparencyLabel = Instance.new("TextLabel", Tab3Container)
TransparencyLabel.BackgroundTransparency = 1
TransparencyLabel.Position = UDim2.new(0.05, 0, 0.05, 0)
TransparencyLabel.Size = UDim2.new(0, 250, 0, 30)
TransparencyLabel.Font = Enum.Font.GothamBold
TransparencyLabel.Text = "Độ trong suốt giao diện (0 -> 1):"
TransparencyLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
TransparencyLabel.TextSize = 14
TransparencyLabel.TextXAlignment = Enum.TextXAlignment.Left

TransInput.Position = UDim2.new(0.45, 0, 0.05, 0)
TransInput.Size = UDim2.new(0, 100, 0, 30)
TransInput.Font = Enum.Font.SourceSansBold
TransInput.Text = "0"
TransInput.TextColor3 = Color3.fromRGB(255, 255, 255)
TransInput.TextSize = 16
Instance.new("UICorner", TransInput).CornerRadius = UDim.new(0, 6)

local ColorLabel = Instance.new("TextLabel", Tab3Container)
ColorLabel.BackgroundTransparency = 1
ColorLabel.Position = UDim2.new(0.05, 0, 0.18, 0)
ColorLabel.Size = UDim2.new(0, 300, 0, 30)
ColorLabel.Font = Enum.Font.GothamBold
ColorLabel.Text = "🎨 Bảng màu giao diện có sẵn:"
ColorLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
ColorLabel.TextSize = 14
ColorLabel.TextXAlignment = Enum.TextXAlignment.Left

-- Bảng chọn màu nhanh
local ColorGrid = Instance.new("Frame", Tab3Container)
ColorGrid.BackgroundTransparency = 1
ColorGrid.Position = UDim2.new(0.05, 0, 0.28, 0)
ColorGrid.Size = UDim2.new(0, 400, 0, 50)
local UIGridLayout = Instance.new("UIGridLayout", ColorGrid)
UIGridLayout.CellSize = UDim2.new(0, 40, 0, 40)
UIGridLayout.CellPadding = UDim2.new(0, 10, 0, 10)

local ColorPresets = {
    Color3.fromRGB(40, 40, 40),   -- Xám Đen (Gốc)
    Color3.fromRGB(15, 15, 60),   -- Xanh Dương Thẫm
    Color3.fromRGB(60, 15, 15),   -- Đỏ Thẫm
    Color3.fromRGB(15, 60, 15),   -- Xanh Lá Thẫm
    Color3.fromRGB(60, 15, 60),   -- Tím Thẫm
    Color3.fromRGB(70, 45, 10)    -- Cam Đất
}

for _, color in ipairs(ColorPresets) do
    local cBtn = Instance.new("TextButton", ColorGrid)
    cBtn.BackgroundColor3 = color
    cBtn.Text = ""
    Instance.new("UICorner", cBtn).CornerRadius = UDim.new(1, 0)
    cBtn.MouseButton1Click:Connect(function() 
        ApplyTheme(color, nil) 
    end)
end

-- Tùy chọn Random Màu & Nhập mã màu thủ công
local RandomColorBtn = Instance.new("TextButton", Tab3Container)
RandomColorBtn.BackgroundColor3 = Color3.fromRGB(180, 80, 140)
RandomColorBtn.Position = UDim2.new(0.05, 0, 0.43, 0)
RandomColorBtn.Size = UDim2.new(0, 150, 0, 35)
RandomColorBtn.Font = Enum.Font.GothamBold
RandomColorBtn.Text = "🌈 Random Màu"
RandomColorBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
RandomColorBtn.TextSize = 12
Instance.new("UICorner", RandomColorBtn).CornerRadius = UDim.new(0, 6)

local RGBLabel = Instance.new("TextLabel", Tab3Container)
RGBLabel.BackgroundTransparency = 1
RGBLabel.Position = UDim2.new(0.05, 0, 0.56, 0)
RGBLabel.Size = UDim2.new(0, 250, 0, 30)
RGBLabel.Font = Enum.Font.GothamBold
RGBLabel.Text = "Nhập mã màu RGB (Ví dụ: 80, 20, 20):"
RGBLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
RGBLabel.TextSize = 13
RGBLabel.TextXAlignment = Enum.TextXAlignment.Left

RGBInput.Position = UDim2.new(0.45, 0, 0.56, 0)
RGBInput.Size = UDim2.new(0, 150, 0, 30)
RGBInput.Font = Enum.Font.SourceSans
RGBInput.PlaceholderText = "R, G, B"
RGBInput.TextColor3 = Color3.fromRGB(255, 255, 255)
RGBInput.TextSize = 15
Instance.new("UICorner", RGBInput).CornerRadius = UDim.new(0, 6)

-- ==========================================
-- LOGIC XỬ LÝ KHÁC & HOẠT ĐỘNG THU THẬP SERVER
-- ==========================================
local function fetchServers(cursor)
    local url = string.format("https://games.roblox.com/v1/games/%d/servers/Public?sortOrder=Asc&limit=100", game.PlaceId)
    if cursor then url = url .. "&cursor=" .. cursor end
    local success, result = pcall(function() 
        return requestFunc({Url = url, Method = "GET"}) 
    end)
    if success and result and result.Body then 
        return HttpService:JSONDecode(result.Body) 
    end
    return nil
end

local function getBestServers()
    local servers = {}
    local cursor = nil
    local pages = 0
    repeat
        local data = fetchServers(cursor)
        if data and data.data then
            for _, s in ipairs(data.data) do table.insert(servers, s) end
            cursor = data.nextPageCursor
            pages = pages + 1
            task.wait(0.05) 
        else break end
    until not cursor or pages >= 3
    table.sort(servers, function(a, b) return a.playing < b.playing end)
    return servers
end

local function getRegionServers(servers)
    local regionServers = {}
    for _, s in ipairs(servers) do
        -- Các server khu vực của người chơi thường có ping thấp (< 120ms)
        if s.ping and s.ping < 120 then
            table.insert(regionServers, s)
        end
    end
    if #regionServers == 0 then return servers end
    return regionServers
end

-- Điền dữ liệu cho server list (Có nút Join trực tiếp)
local function PopulateServerList()
    Title.Text = "Đang quét danh sách Server... 🔍"
    for _, child in ipairs(ServerListFrame:GetChildren()) do
        if child:IsA("Frame") then child:Destroy() end
    end
    
    local servers = getBestServers()
    Title.Text = "Server Finder & Auto-Hop ⚡"
    
    for _, server in ipairs(servers) do
        if server.playing < server.maxPlayers and server.id ~= game.JobId then
            local clone = Instance.new("Frame")
            clone.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
            clone.Size = UDim2.new(0, 668, 0, 45)
            Instance.new("UICorner", clone).CornerRadius = UDim.new(0, 8)
            clone.Parent = ServerListFrame
            
            local txt = Instance.new("TextLabel")
            txt.BackgroundTransparency = 1
            txt.Position = UDim2.new(0.02, 0, 0, 0)
            txt.Size = UDim2.new(0.75, 0, 1, 0)
            txt.Font = Enum.Font.SourceSans
            txt.TextColor3 = Color3.fromRGB(255, 255, 255)
            txt.TextSize = 14
            txt.TextXAlignment = Enum.TextXAlignment.Left
            txt.Text = string.format("Server: %s...\n👥 %d/%d người chơi | Ping: %d ms", 
                string.sub(tostring(server.id), 1, 12), server.playing, server.maxPlayers, server.ping or 0)
            txt.Parent = clone

            local jBtn = Instance.new("TextButton")
            jBtn.BackgroundColor3 = Color3.fromRGB(80, 130, 255)
            jBtn.Position = UDim2.new(0.81, 0, 0.1, 0)
            jBtn.Size = UDim2.new(0, 114, 0, 36)
            jBtn.Font = Enum.Font.SourceSansBold
            jBtn.Text = "Join 🚀"
            jBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
            jBtn.TextSize = 15
            Instance.new("UICorner", jBtn).CornerRadius = UDim.new(0, 6)
            jBtn.Parent = clone
            
            jBtn.MouseButton1Click:Connect(function() 
                TeleportService:TeleportToPlaceInstance(game.PlaceId, server.id, LocalPlayer) 
            end)
        end
    end
end

RefreshBtn.MouseButton1Click:Connect(PopulateServerList)

-- ==========================================
-- LOGIC CHO CÁC NÚT RANDOM SERVER
-- ==========================================
local function TeleportToTarget(srv)
    if srv then
        Title.Text = "Đang kết nối Server... 🚀"
        local success, err = pcall(function()
            TeleportService:TeleportToPlaceInstance(game.PlaceId, srv.id, LocalPlayer)
        end)
        if not success then
            Title.Text = "Lỗi kết nối! Thử lại..."
            task.wait(1.5)
            Title.Text = "Server Finder & Auto-Hop ⚡"
        end
    end
end

RandomServerBtn.MouseButton1Click:Connect(function()
    local servers = getBestServers()
    if #servers > 0 then
        local srv = servers[math.random(1, #servers)]
        TeleportToTarget(srv)
    end
end)

RandomLowServerBtn.MouseButton1Click:Connect(function()
    local servers = getBestServers()
    if #servers > 0 then
        local range = math.min(8, #servers)
        local srv = servers[math.random(1, range)]
        TeleportToTarget(srv)
    end
end)

RandRegionBtn.MouseButton1Click:Connect(function()
    local servers = getRegionServers(getBestServers())
    if #servers > 0 then
        local srv = servers[math.random(1, #servers)]
        TeleportToTarget(srv)
    end
end)

RandLowRegionBtn.MouseButton1Click:Connect(function()
    local servers = getRegionServers(getBestServers())
    if #servers > 0 then
        local range = math.min(8, #servers)
        local srv = servers[math.random(1, range)]
        TeleportToTarget(srv)
    end
end)

-- ==========================================
-- VÒNG LẶP KHÓA SPEED & JUMP POWER (LOOP)
-- ==========================================
local loopWalkSpeed = nil
local loopJumpPower = nil

ApplyModsBtn.MouseButton1Click:Connect(function()
    local speed = tonumber(SetSpeedInput.Text)
    local jump = tonumber(SetJumpInput.Text)
    
    loopWalkSpeed = speed and math.clamp(speed, 0, 200) or nil
    loopJumpPower = jump and math.clamp(jump, 0, 200) or nil
    
    ApplyModsBtn.Text = "✅ Đang khóa Loop!"
    task.wait(1.5)
    ApplyModsBtn.Text = "⚡ Khóa Chỉ Số (Loop)"
end)

RunService.Heartbeat:Connect(function()
    local char = LocalPlayer.Character
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    if hum then
        if loopWalkSpeed then
            hum.WalkSpeed = loopWalkSpeed
        end
        if loopJumpPower then
            hum.JumpPower = loopJumpPower
            hum.UseJumpPower = true 
        end
    end
end)

-- Infinite Jump
local infJumpEnabled = false
InfJumpBtn.MouseButton1Click:Connect(function()
    infJumpEnabled = not infJumpEnabled
    if infJumpEnabled then
        InfJumpBtn.BackgroundColor3 = Color3.fromRGB(50, 150, 50)
        InfJumpBtn.Text = "🦘 Nhảy Vô Hạn: BẬT"
    else
        InfJumpBtn.BackgroundColor3 = Color3.fromRGB(90, 90, 90)
        InfJumpBtn.Text = "🦘 Nhảy Vô Hạn: TẮT"
    end
end)

UserInputService.JumpRequest:Connect(function()
    if infJumpEnabled then
        local hum = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
        if hum then hum:ChangeState(Enum.HumanoidStateType.Jumping) end
    end
end)

-- ==========================================
-- CẤU HÌNH CHO POP-UP PING & FPS
-- ==========================================
local FpsGuiActive = false
local FpsPingGui = Instance.new("ScreenGui")
FpsPingGui.Name = "FpsPingTracker"
FpsPingGui.Parent = LocalPlayer:WaitForChild("PlayerGui")
FpsPingGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

local StatsFrame = Instance.new("Frame", FpsPingGui)
StatsFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
StatsFrame.BackgroundTransparency = 0.3
StatsFrame.Position = UDim2.new(0.4, 0, 0.02, 0)
StatsFrame.Size = UDim2.new(0, 180, 0, 40)
StatsFrame.Visible = false
Instance.new("UICorner", StatsFrame).CornerRadius = UDim.new(0, 8)
MakeDraggable(StatsFrame)

local StatsLabel = Instance.new("TextLabel", StatsFrame)
StatsLabel.BackgroundTransparency = 1
StatsLabel.Size = UDim2.new(1, 0, 1, 0)
StatsLabel.Font = Enum.Font.GothamBold
StatsLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
StatsLabel.TextSize = 13
StatsLabel.Text = "FPS: -- | Ping: --"

ShowStatsBtn.MouseButton1Click:Connect(function()
    FpsGuiActive = not FpsGuiActive
    StatsFrame.Visible = FpsGuiActive
    ShowStatsBtn.Text = FpsGuiActive and "🖥️ Tắt Bảng Ping & FPS" or "🖥️ Mở Bảng Ping & FPS"
end)

RunService.RenderStepped:Connect(function(step)
    if FpsGuiActive then
        local fps = math.floor(1 / step)
        local ping = 0
        pcall(function() ping = math.floor(Stats.Network.ServerStatsItem["Data Ping"]:GetValue()) end)
        StatsLabel.Text = string.format("FPS: %d | Ping: %d ms", fps, ping)
        
        if ping < 80 then StatsLabel.TextColor3 = Color3.fromRGB(100, 255, 100)
        elseif ping < 180 then StatsLabel.TextColor3 = Color3.fromRGB(255, 255, 100)
        else StatsLabel.TextColor3 = Color3.fromRGB(255, 100, 100) end
    end
end)

-- Copy & Join trực tiếp từ Tab 2
CopyJobIdBtn.MouseButton1Click:Connect(function()
    setclipboard(tostring(game.JobId))
    CopyJobIdBtn.Text = "✅ Đã Copy!"
    task.wait(1.5)
    CopyJobIdBtn.Text = "📋 Copy Server JobId"
end)

JoinJobIdBtn.MouseButton1Click:Connect(function()
    local jobId = JobIdInput.Text
    if jobId and jobId ~= "" then 
        TeleportService:TeleportToPlaceInstance(game.PlaceId, jobId, LocalPlayer) 
    end
end)

-- ==========================================
-- SỰ KIỆN KHI THAY ĐỔI CẤU HÌNH GIAO DIỆN Ở TAB 3
-- ==========================================
TransInput.FocusLost:Connect(function()
    local val = tonumber(TransInput.Text)
    if val and val >= 0 and val <= 1 then
        ApplyTheme(nil, val)
    else
        TransInput.Text = tostring(currentTransparency)
    end
end)

RandomColorBtn.MouseButton1Click:Connect(function()
    local randomColor = Color3.fromRGB(math.random(15, 80), math.random(15, 80), math.random(15, 80))
    ApplyTheme(randomColor, nil)
end)

RGBInput.FocusLost:Connect(function()
    local text = RGBInput.Text
    local r, g, b = text:match("(%d+)%s*,%s*(%d+)%s*,%s*(%d+)")
    if r and g and b then
        local userColor = Color3.fromRGB(math.clamp(tonumber(r), 0, 255), math.clamp(tonumber(g), 0, 255), math.clamp(tonumber(b), 0, 255))
        ApplyTheme(userColor, nil)
    else
        RGBInput.Text = "Hãy nhập: R,G,B"
    end
end)

-- ==========================================
-- CHẠY CHỨC NĂNG TỰ ĐỘNG HOP (AUTO HOP)
-- ==========================================
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
    ApplyTheme()
    SaveData()
end)

local isTeleporting = false
task.spawn(function()
    while task.wait(5) do
        if isTeleporting then continue end
        if AppData.AutoHopEnabled then
            if #Players:GetPlayers() > AppData.MaxPlayers then
                local servers = getBestServers()
                local target = nil
                for _, s in ipairs(servers) do
                    if not AppData.BannedServers[s.id] and s.playing <= AppData.MaxPlayers then
                        target = s
                        break
                    end
                end
                if target then
                    AppData.BannedServers[target.id] = true
                    SaveData()
                    isTeleporting = true
                    pcall(function() 
                        TeleportService:TeleportToPlaceInstance(game.PlaceId, target.id, LocalPlayer) 
                    end)
                    task.wait(10)
                    isTeleporting = false
                end
            end
        end
    end
end)

-- ==========================================
-- KHỞI CHẠY LẦN ĐẦU
-- ==========================================
MakeDraggable(MainFrame)
ApplyTheme(Color3.fromRGB(40, 40, 40), 0) -- Áp dụng cấu hình giao diện mặc định
task.spawn(PopulateServerList) -- Tự động tải danh sách Server ngay khi bật
