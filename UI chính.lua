return function(State)

    local gui = Instance.new("ScreenGui")
    gui.Name = "HubUI"
    gui.Parent = game.CoreGui

    local button = Instance.new("TextButton")
    button.Size = UDim2.new(0, 180, 0, 45)
    button.Position = UDim2.new(0, 50, 0, 80)
    button.BackgroundColor3 = Color3.fromRGB(30,30,30)
    button.TextColor3 = Color3.fromRGB(255,255,255)
    button.Text = "BOT: OFF"
    button.Parent = gui

    button.MouseButton1Click:Connect(function()
        State.BotActive = not State.BotActive
        button.Text = State.BotActive and "BOT: ON" or "BOT: OFF"
    end)

    local jumpBtn = Instance.new("TextButton")
    jumpBtn.Size = UDim2.new(0, 180, 0, 45)
    jumpBtn.Position = UDim2.new(0, 50, 0, 130)
    jumpBtn.BackgroundColor3 = Color3.fromRGB(30,30,30)
    jumpBtn.TextColor3 = Color3.fromRGB(255,255,255)
    jumpBtn.Text = "SMART JUMP: ON"
    jumpBtn.Parent = gui

    jumpBtn.MouseButton1Click:Connect(function()
        State.SmartJump = not State.SmartJump
        jumpBtn.Text = State.SmartJump and "SMART JUMP: ON" or "SMART JUMP: OFF"
    end)

end
