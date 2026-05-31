return function(State)
    local okInit, errInit = pcall(function()
        local Players = game:GetService("Players")
        local player = Players.LocalPlayer

        -- Dọn dẹp UI cũ nếu có trùng tên
        if game.CoreGui:FindFirstChild("HubUI") then
            game.CoreGui.HubUI:Destroy()
        elseif player.PlayerGui:FindFirstChild("HubUI") then
            player.PlayerGui.HubUI:Destroy()
        end

        -- BUG 3 Fix: Check quyền CoreGui thực tế bằng cách ép thử gán một Part ảo
        local guiTarget = player:WaitForChild("PlayerGui")
        local successCore = pcall(function()
            local test = Instance.new("Folder")
            test.Parent = game.CoreGui
            test:Destroy()
        end)
        if successCore then
            guiTarget = game.CoreGui
        end

        -- Khởi tạo ScreenGui chính
        local gui = Instance.new("ScreenGui")
        gui.Name = "HubUI"
        gui.ResetOnSpawn = false
        gui.Parent = guiTarget

        -- Khung chứa Menu chính (BUG 2 Fix: Tăng chiều cao lên 105 để vừa khít 2 nút chính)
        local container = Instance.new("Frame")
        container.Size = UDim2.new(0, 200, 0, 105)
        container.Position = UDim2.new(0, 50, 0, 80)
        container.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
        container.BorderSizePixel = 0
        container.Parent = gui

        local uiCorner = Instance.new("UICorner")
        uiCorner.CornerRadius = UDim.new(0, 8)
        uiCorner.Parent = container

        -- Hàm tạo nút bấm chuẩn hóa
        local function makeBtn(text, yOffset, parent, callback)
            local btn = Instance.new("TextButton")
            btn.Size = UDim2.new(0, 180, 0, 38)
            btn.Position = UDim2.new(0, 10, 0, yOffset)
            btn.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
            btn.TextColor3 = Color3.fromRGB(255, 255, 255)
            btn.Text = text
            btn.Font = Enum.Font.GothamMedium
            btn.TextSize = 14
            btn.Parent = parent

            local corner = Instance.new("UICorner")
            corner.CornerRadius = UDim.new(0, 6)
            corner.Parent = btn

            btn.MouseButton1Click:Connect(callback)
            return btn
        end

        -- Nút bật/tắt Bot (Đọc trực tiếp từ State truyền vào, không qua getgenv rác)
        local botBtn = makeBtn(State.BotActive and "BOT: ON" or "BOT: OFF", 10, container, function()
            if not State then return end
            State.BotActive = not State.BotActive
            botBtn.Text = State.BotActive and "BOT: ON" or "BOT: OFF"
            botBtn.BackgroundColor3 = State.BotActive and Color3.fromRGB(30, 120, 60) or Color3.fromRGB(45, 45, 45)
        end)
        if State.BotActive then botBtn.BackgroundColor3 = Color3.fromRGB(30, 120, 60) end

        -- Nút bật/tắt SmartJump
        local jumpBtn = makeBtn(State.SmartJump and "SMART JUMP: ON" or "SMART JUMP: OFF", 56, container, function()
            if not State then return end
            State.SmartJump = not State.SmartJump
            jumpBtn.Text = State.SmartJump and "SMART JUMP: ON" or "SMART JUMP: OFF"
            jumpBtn.BackgroundColor3 = State.SmartJump and Color3.fromRGB(30, 120, 60) or Color3.fromRGB(45, 45, 45)
        end)
        if State.SmartJump then jumpBtn.BackgroundColor3 = Color3.fromRGB(30, 120, 60) end

        -- BUG 1 Fix: Đặt nút HIDE/SHOW ra ngoài container (Gắn trực tiếp vào gui)
        -- Vị trí Y = 190 (nằm ngay sát dưới đáy container 80 + 105 = 185) để không bị ẩn theo container
        local closeBtn = makeBtn("HIDE MENU", 190, gui, function()
            container.Visible = not container.Visible
            closeBtn.Text = container.Visible and "HIDE MENU" or "SHOW MENU"
            
            -- Đổi màu nhẹ cho nút Hide/Show để dễ phân biệt
            closeBtn.BackgroundColor3 = container.Visible and Color3.fromRGB(45, 45, 45) or Color3.fromRGB(120, 40, 40)
        end)
        -- Đồng bộ vị trí X của nút HIDE với container
        closeBtn.Position = UDim2.new(0, 50, 0, 190)

    end)

    if not okInit then
        warn("[Farmer UI] Init error:", errInit)
    end
end
