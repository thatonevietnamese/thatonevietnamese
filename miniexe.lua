local CoreGui = game:GetService("CoreGui")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local UserInputService = game:GetService("UserInputService")

-- Chống trùng lặp (xóa cái cũ nếu lỡ bấm chạy 2 lần)
local existing = CoreGui:FindFirstChild("MiniExecutorGui") or LocalPlayer.PlayerGui:FindFirstChild("MiniExecutorGui")
if existing then existing:Destroy() end

-- Ưu tiên nhét UI vào CoreGui để chống bị game phát hiện, nếu không hỗ trợ thì xài PlayerGui
local success, parentTarget = pcall(function() return CoreGui end)
if not success or not parentTarget then
    parentTarget = LocalPlayer:WaitForChild("PlayerGui")
end

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

-- Chức năng kéo thả UI
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
Title.Text = "  💻 Cục Nợ Code Runner"
Title.TextColor3 = Color3.fromRGB(255, 255, 255)
Title.Font = Enum.Font.GothamBold
Title.TextSize = 14
Title.TextXAlignment = Enum.TextXAlignment.Left

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
InputBox.Text = "-- Dán script của bác vào đây...\nprint('Chạy ngon!')"
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

-- Nút Phá Hủy
local DestroyBtn = Instance.new("TextButton", MainFrame)
DestroyBtn.Size = UDim2.new(0.47, 0, 0, 35)
DestroyBtn.Position = UDim2.new(1, -10 - (MainFrame.AbsoluteSize.X * 0.47), 1, -45) -- Căn phải
DestroyBtn.BackgroundColor3 = Color3.fromRGB(180, 50, 50)
DestroyBtn.Text = "🗑️ Phá Hủy UI"
DestroyBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
DestroyBtn.Font = Enum.Font.GothamBold
DestroyBtn.TextSize = 14
Instance.new("UICorner", DestroyBtn).CornerRadius = UDim.new(0, 6)

-- Cập nhật lại vị trí nút hủy nếu size thay đổi
MainFrame:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
    DestroyBtn.Position = UDim2.new(1, -10 - (MainFrame.AbsoluteSize.X * 0.47), 1, -45)
end)

-- ==========================================
-- LOGIC HOẠT ĐỘNG
-- ==========================================

-- Logic chạy code
ExecBtn.MouseButton1Click:Connect(function()
    local code = InputBox.Text
    -- Dùng loadstring để biên dịch code từ dạng Text sang Lua Script
    local func, err = loadstring(code)
    
    if func then
        -- Chạy code trong luồng riêng (task.spawn) để không làm đơ UI nếu script kia bị lỗi vòng lặp
        task.spawn(function()
            local success, runErr = pcall(func)
            if not success then
                warn("Lỗi khi chạy script: " .. tostring(runErr))
            end
        end)
    else
        warn("Lỗi cú pháp (Syntax Error): " .. tostring(err))
    end
end)

-- Logic Phá Hủy
DestroyBtn.MouseButton1Click:Connect(function()
    ScreenGui:Destroy()
end)
