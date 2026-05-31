return function(State)

    local gui = Instance.new("ScreenGui")
    gui.Parent = game.CoreGui

    local button = Instance.new("TextButton")
    button.Size = UDim2.new(0, 200, 0, 50)
    button.Position = UDim2.new(0, 50, 0, 50)
    button.Text = "BOT: OFF"
    button.Parent = gui

    button.MouseButton1Click:Connect(function()
        State.BotActive = not State.BotActive
        button.Text = State.BotActive and "BOT: ON" or "BOT: OFF"
    end)

end
