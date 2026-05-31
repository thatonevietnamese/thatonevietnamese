return function(State)
    local okInit, errInit = pcall(function()
        getgenv = getgenv or function() return _G end
        getgenv().FarmerState = State

        if game.CoreGui:FindFirstChild("HubUI") then
            game.CoreGui.HubUI:Destroy()
        end

        local guiTarget = game.CoreGui
        local okCore = pcall(function() return game.CoreGui end)
        if not okCore then
            guiTarget = game.Players.LocalPlayer.PlayerGui
        end

        local gui = Instance.new("ScreenGui")
        gui.Name = "HubUI"
        gui.ResetOnSpawn = false
        gui.Parent = guiTarget

        local container = Instance.new("Frame")
        container.Size = UDim2.new(0, 200, 0, 110)
        container.Position = UDim2.new(0, 50, 0, 80)
        container.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
        container.BorderSizePixel = 0
        container.Parent = gui

        local uiCorner = Instance.new("UICorner")
        uiCorner.CornerRadius = UDim.new(0, 8)
        uiCorner.Parent = container

        local function makeBtn(text, yOffset, callback)
            local btn = Instance.new("TextButton")
            btn.Size = UDim2.new(0, 180, 0, 38)
            btn.Position = UDim2.new(0, 10, 0, yOffset)
            btn.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
            btn.TextColor3 = Color3.fromRGB(255, 255, 255)
            btn.Text = text
            btn.Font = Enum.Font.GothamMedium
            btn.TextSize = 14
            btn.Parent = container

            local corner = Instance.new("UICorner")
            corner.CornerRadius = UDim.new(0, 6)
            corner.Parent = btn

            btn.MouseButton1Click:Connect(callback)
            return btn
        end

        local botBtn = makeBtn("BOT: OFF", 10, function()
            local s = getgenv().FarmerState
            if not s then return end
            s.BotActive = not s.BotActive
            botBtn.Text = s.BotActive and "BOT: ON" or "BOT: OFF"
            botBtn.BackgroundColor3 = s.BotActive and Color3.fromRGB(30, 120, 60) or Color3.fromRGB(45, 45, 45)
        end)

        local jumpBtn = makeBtn("SMART JUMP: ON", 56, function()
            local s = getgenv().FarmerState
            if not s then return end
            s.SmartJump = not s.SmartJump
            jumpBtn.Text = s.SmartJump and "SMART JUMP: ON" or "SMART JUMP: OFF"
            jumpBtn.BackgroundColor3 = s.SmartJump and Color3.fromRGB(30, 120, 60) or Color3.fromRGB(45, 45, 45)
        end)

        local closeBtn = makeBtn("HIDE", 102, function()
            container.Visible = not container.Visible
            closeBtn.Text = container.Visible and "HIDE" or "SHOW"
        end)
    end)

    if not okInit then
        warn("[Farmer UI] Init error:", errInit)
    end
end
