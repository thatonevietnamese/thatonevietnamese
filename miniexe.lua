local CoreGui = game:GetService("CoreGui")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local UserInputService = game:GetService("UserInputService")

-- Xóa UI cũ nếu có
local existing = CoreGui:FindFirstChild("MiniExecutorGui") or LocalPlayer.PlayerGui:FindFirstChild("MiniExecutorGui")
if existing then existing:Destroy() end

local success, parentTarget = pcall(function() return CoreGui end)
if not success or not parentTarget then parentTarget = LocalPlayer:WaitForChild("PlayerGui") end

-- ==========================================
-- KHỞI TẠO GIAO DIỆN
-- ==========================================
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "MiniExecutorGui"
ScreenGui.Parent = parentTarget
ScreenGui.ResetOnSpawn = false

local MainFrame = Instance.new("Frame", ScreenGui)
MainFrame.Size = UDim2.new(0, 450, 0, 280)
MainFrame.Position = UDim2.new(0.5, -225, 0.5, -140)
MainFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
MainFrame.BorderSizePixel = 0
Instance.new("UICorner", MainFrame).CornerRadius = UDim.new(0, 8)

-- Chức năng kéo thả
local dragging, dragInput, dragStart, startPos
MainFrame.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = true; dragStart = input.Position; startPos = MainFrame.Position
        input.Changed:Connect(function() if input.UserInputState == Enum.UserInputState.End then dragging = false end end)
    end
end)
MainFrame.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then dragInput = input end
end)
UserInputService.InputChanged:Connect(function(input)
    if input == dragInput and dragging then
        local delta = input.Position - dragStart
        MainFrame.Position = UDim2.new(0, startPos.X.Offset + delta.X, 0, startPos.Y.Offset + delta.Y)
    end
end)

-- Tiêu đề
local Title = Instance.new("TextLabel", MainFrame)
Title.Size = UDim2.new(1, 0, 0, 35)
Title.BackgroundTransparency = 1
Title.Text = "  💻 Code Runner (Có chức năng Kill)"
Title.TextColor3 = Color3.fromRGB(255, 200, 100)
Title.Font = Enum.Font.GothamBold
Title.TextSize = 14
Title.TextXAlignment = Enum.TextXAlignment.Left

-- Nút Đóng UI
local CloseBtn = Instance.new("TextButton", MainFrame)
CloseBtn.Size = UDim2.new(0, 30, 0, 30)
CloseBtn.Position = UDim2.new(1, -35, 0, 2)
CloseBtn.BackgroundTransparency = 1
CloseBtn.Text = "❌"
CloseBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
CloseBtn.Font = Enum.Font.GothamBold
CloseBtn.TextSize = 14
CloseBtn.MouseButton1Click:Connect(function() ScreenGui:Destroy() end)

-- Ô nhập Script
local InputBox = Instance.new("TextBox", MainFrame)
InputBox.Size = UDim2.new(1, -20, 1, -90)
InputBox.Position = UDim2.new(0, 10, 0, 35)
InputBox.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
InputBox.TextColor3 = Color3.fromRGB(200, 255, 200)
InputBox.Font = Enum.Font.Code
InputBox.TextSize = 13
InputBox.TextXAlignment = Enum.TextXAlignment.Left
InputBox.TextYAlignment = Enum.TextYAlignment.Top
InputBox.ClearTextOnFocus = false
InputBox.MultiLine = true
InputBox.Text = "while task.wait(1) do\n    print('Đang chạy vòng lặp...')\nend"
Instance.new("UICorner", InputBox).CornerRadius = UDim.new(0, 6)

-- Nút Execute
local ExecBtn = Instance.new("TextButton", MainFrame)
ExecBtn.Size = UDim2.new(0.47, 0, 0, 35)
ExecBtn.Position = UDim2.new(0, 10, 1, -45)
ExecBtn.BackgroundColor3 = Color3.fromRGB(50, 150, 50)
ExecBtn.Text = "▶️ Execute"
ExecBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
ExecBtn.Font = Enum.Font.GothamBold
ExecBtn.TextSize = 14
Instance.new("UICorner", ExecBtn).CornerRadius = UDim.new(0, 6)

-- Nút Dừng Script
local StopBtn = Instance.new("TextButton", MainFrame)
StopBtn.Size = UDim2.new(0.47, 0, 0, 35)
StopBtn.Position = UDim2.new(1, -10 - (MainFrame.AbsoluteSize.X * 0.47), 1, -45)
StopBtn.BackgroundColor3 = Color3.fromRGB(180, 50, 50)
StopBtn.Text = "🛑 Dừng Script"
StopBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
StopBtn.Font = Enum.Font.GothamBold
StopBtn.TextSize = 14
Instance.new("UICorner", StopBtn).CornerRadius = UDim.new(0, 6)

MainFrame:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
    StopBtn.Position = UDim2.new(1, -10 - (MainFrame.AbsoluteSize.X * 0.47), 1, -45)
end)

-- ==========================================
-- LOGIC HOẠT ĐỘNG (LƯU & ÉP DỪNG THREAD)
-- ==========================================
local runningThread = nil -- Biến lưu trữ luồng đang chạy

ExecBtn.MouseButton1Click:Connect(function()
    local code = InputBox.Text
    local func, err = loadstring(code)
    
    if func then
        -- Tự động kill script cũ nếu bác lỡ bấm chạy nhiều lần
        if runningThread then
            pcall(function() task.cancel(runningThread) end)
        end
        
        -- Khởi tạo luồng mới và gán vào biến
        runningThread = task.spawn(function()
            Title.Text = "  💻 Code Runner - [ĐANG CHẠY 🟢]"
            local success, runErr = pcall(func)
            if not success then
                warn("Lỗi khi chạy script: " .. tostring(runErr))
            end
            Title.Text = "  💻 Code Runner - [ĐÃ XONG ⚪]"
        end)
    else
        warn("Lỗi cú pháp (Syntax Error): " .. tostring(err))
    end
end)

StopBtn.MouseButton1Click:Connect(function()
    if runningThread then
        -- Ép hủy luồng
        pcall(function() task.cancel(runningThread) end)
        runningThread = nil
        Title.Text = "  💻 Code Runner - [ĐÃ ÉP DỪNG 🔴]"
        print("Đã hủy thành công script đang chạy!")
    else
        Title.Text = "  💻 Code Runner - [KHÔNG CÓ SCRIPT 🟡]"
    end
end)
