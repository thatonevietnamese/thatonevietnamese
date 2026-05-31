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

        local guiTarget = player:WaitForChild("PlayerGui")
        local successCore = pcall(function()
            local test = Instance.new("Folder")
            test.Parent = game.CoreGui
            test:Destroy()
        end)
        if successCore then
            guiTarget = game.CoreGui
        end

        local gui = Instance.new("ScreenGui")
        gui.Name = "HubUI"
        gui.ResetOnSpawn = false
        gui.Parent = guiTarget

        local container = Instance.new("Frame")
        container.Size = UDim2.new(0, 200, 0, 105)
        container.Position = UDim2.new(0, 50, 0, 80)
        container.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
        container.BorderSizePixel = 0
        container.Parent = gui

        local uiCorner = Instance.new("UICorner")
        uiCorner.CornerRadius = UDim.new(0, 8)
        uiCorner.Parent = container

        -- FIX CHÍ MẠNG: Hàm makeBtn tự quản lý việc đổi giao diện của CHÍNH NÓ (Không gọi biến ngoài)
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

            -- Truyền ngược chính instance 'btn' vào callback để xử lý an toàn
            btn.MouseButton1Click:Connect(function()
                callback(btn)
            end)
            return btn
        end

        -- Nút bật/tắt Bot (Dùng tham số 'selfBtn' truyền vào từ makeBtn)
        local botBtn = makeBtn(State.BotActive and "BOT: ON" or "BOT: OFF", 10, container, function(selfBtn)
            if not State then return end
            State.BotActive = not State.BotActive
            
            -- Tuyệt đối an toàn, không bao giờ lo nil với 'selfBtn'
            selfBtn.Text = State.BotActive and "BOT: ON" or "BOT: OFF"
            selfBtn.BackgroundColor3 = State.BotActive and Color3.fromRGB(30, 120, 60) or Color3.fromRGB(45, 45, 45)
        end)
        if State.BotActive then botBtn.BackgroundColor3 = Color3.fromRGB(30, 120, 60) end

        -- Nút bật/tắt SmartJump
        local jumpBtn = makeBtn(State.SmartJump and "SMART JUMP: ON" or "SMART JUMP: OFF", 56, container, function(selfBtn)
            if not State then return end
            State.SmartJump = not State.SmartJump
            
            selfBtn.Text = State.SmartJump and "SMART JUMP: ON" or "SMART JUMP: OFF"
            selfBtn.BackgroundColor3 = State.SmartJump and Color3.fromRGB(30, 120, 60) or Color3.fromRGB(45, 45, 45)
        end)
        if State.SmartJump then jumpBtn.BackgroundColor3 = Color3.fromRGB(30, 120, 60) end

        -- Nút HIDE/SHOW MENU
        local closeBtn = makeBtn("HIDE MENU", 190, gui, function(selfBtn)
            container.Visible = not container.Visible
            selfBtn.Text = container.Visible and "HIDE MENU" or "SHOW MENU"
            selfBtn.BackgroundColor3 = container.Visible and Color3.fromRGB(45, 45, 45) or Color3.fromRGB(120, 40, 40)
        end)
        closeBtn.Position = UDim2.new(0, 50, 0, 190)

    end)

    if not okInit then
        warn("[Farmer UI] Init error:", errInit)
    end
end
