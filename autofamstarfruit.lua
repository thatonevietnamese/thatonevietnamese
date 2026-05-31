--[[
    Roblox Ultimate Farmer - Clean & Optimized Version
    - Built on ChatGPT's Minimalist Backbone.
    - Zero Event Leaks / Zero Over-Engineering.
    - Focuses on native Roblox Engine stability.
]]

-- ---------- Shared state ----------
local State = {
    BotActive = false,
    SmartJump = true,
    BlacklistExpiry = 8,
    ScanTick = 0.3,             -- Tăng nhẹ lên để giảm tải cho CPU
    WaitWhenEmpty = 0.5,
    MoveToTimeout = 1.5,
}

-- ---------- Services ----------
local Players = game:GetService("Players")
local PathfindingService = game:GetService("PathfindingService")
local Workspace = game:GetService("Workspace")

local player = Players.LocalPlayer

-- ---------- Blacklist (Simple & Efficient) ----------
local blacklist = {}

local function isBlacklisted(obj)
    if not obj or not obj:IsDescendantOf(game) then return false end
    local expiry = blacklist[obj]
    if not expiry then return false end
    
    if os.clock() - expiry >= State.BlacklistExpiry then
        blacklist[obj] = nil
        return false
    end
    return true
end

local function markBlacklisted(obj)
    if obj and obj:IsDescendantOf(game) then
        blacklist[obj] = os.clock()
    end
end

-- ---------- Character Cache ----------
local function getChar()
    local c = player.Character
    local h = c and c:FindFirstChildOfClass("Humanoid")
    local r = c and c:FindFirstChild("HumanoidRootPart")
    return c, h, r
end

local function pos(obj)
    if not obj or not obj:IsDescendantOf(game) then return nil end
    if obj:IsA("BasePart") then return obj.Position end
    if obj:IsA("Model") then
        local pp = obj.PrimaryPart
        if pp and pp:IsA("BasePart") then return pp.Position end
        local bp = obj:FindFirstChildWhichIsA("BasePart", true)
        if bp and bp:IsA("BasePart") then return bp.Position end
    end
    return nil
end

-- ---------- Target scanner ----------
local function findTarget()
    local _, _, root = getChar()
    if not root then return nil, nil end

    local closest, cpos, dist = nil, nil, math.huge

    local function scan(folder)
        if not folder then return end
        for _, v in ipairs(folder:GetChildren()) do
            if not isBlacklisted(v) then
                local p = pos(v)
                if p then
                    local d = (p - root.Position).Magnitude
                    if d < dist then
                        dist = d
                        closest = v
                        cpos = p
                    end
                end
            end
        end
    end

    scan(Workspace:FindFirstChild("SpawnedFruits"))
    if not closest then scan(Workspace:FindFirstChild("EventStars")) end

    return closest, cpos
end

-- ---------- Pathfinding + movement (The ChatGPT Backbone) ----------
local function moveTo(targetPos)
    if not targetPos then return false end

    local _, hum, root = getChar()
    if not hum or not root or hum.Health <= 0 then return false end

    -- Khởi tạo Path đơn giản, tính toán 1 lần duy nhất không retry phức tạp
    local path = PathfindingService:CreatePath({
        AgentRadius = 2,
        AgentHeight = (hum.RigType == Enum.HumanoidRigType.R15) and 5 or 6,
        AgentCanJump = true,
    })
    
    local success, _ = pcall(function()
        path:ComputeAsync(root.Position, targetPos)
    end)

    if not success or path.Status ~= Enum.PathStatus.Success then 
        return false 
    end

    local waypoints = path:GetWaypoints()
    
    for i, wp in ipairs(waypoints) do
        -- Check trạng thái bot ở mỗi waypoint
        local _, currentHum, currentRoot = getChar()
        if not currentHum or not currentRoot or currentHum.Health <= 0 or not State.BotActive then
            return false
        end

        -- SmartJump tối giản theo ý ChatGPT
        if State.SmartJump then
            if wp.Action == Enum.PathWaypointAction.Jump or currentHum.FloorMaterial == Enum.Material.Air then
                currentHum.Jump = true
            end
        end

        -- Lệnh di chuyển nguyên bản của Roblox Engine
        currentHum:MoveTo(wp.Position)
        
        -- Chờ native từ Engine, không tạo Event Connection, không Loop Heartbeat
        local reached = currentHum.MoveToFinished:Wait(State.MoveToTimeout)

        -- Xử lý unstuck nhẹ nếu hết timeout mà không tới được waypoint
        if not reached and i < #waypoints then
            currentHum:MoveTo(currentRoot.Position)
            return false
        end
    end

    return true
end

-- ---------- UI ----------
local function createUI()
    if game.CoreGui:FindFirstChild("HubUI") then
        game.CoreGui.HubUI:Destroy()
    end

    local guiTarget = player:WaitForChild("PlayerGui")
    local successCore, _ = pcall(function()
        local dummy = Instance.new("ScreenGui", game.CoreGui)
        dummy:Destroy()
    end)
    
    if successCore then guiTarget = game.CoreGui end

    local gui = Instance.new("ScreenGui")
    gui.Name = "HubUI"
    gui.ResetOnSpawn = false
    gui.Parent = guiTarget

    local container = Instance.new("Frame")
    container.Size = UDim2.new(0, 200, 0, 155)
    container.Position = UDim2.new(0, 50, 0, 80)
    container.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
    container.BorderSizePixel = 0
    container.Parent = gui

    Instance.new("UICorner", container).CornerRadius = UDim.new(0, 8)

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
        Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6)
        btn.MouseButton1Click:Connect(callback)
        return btn
    end

    local botBtn = makeBtn("BOT: OFF", 10, function()
        State.BotActive = not State.BotActive
        botBtn.Text = State.BotActive and "BOT: ON" or "BOT: OFF"
        botBtn.BackgroundColor3 = State.BotActive and Color3.fromRGB(30, 120, 60) or Color3.fromRGB(45, 45, 45)
    end)

    local jumpBtn = makeBtn("SMART JUMP: ON", 56, function()
        State.SmartJump = not State.SmartJump
        jumpBtn.Text = State.SmartJump and "SMART JUMP: ON" or "SMART JUMP: OFF"
        jumpBtn.BackgroundColor3 = State.SmartJump and Color3.fromRGB(30, 120, 60) or Color3.fromRGB(45, 45, 45)
    end)

    local closeBtn = makeBtn("HIDE UI", 102, function()
        botBtn.Visible = not botBtn.Visible
        jumpBtn.Visible = not jumpBtn.Visible
        closeBtn.Text = botBtn.Visible and "HIDE UI" or "SHOW UI"
        container.Size = botBtn.Visible and UDim2.new(0, 200, 0, 155) or UDim2.new(0, 200, 0, 55)
        closeBtn.Position = botBtn.Visible and UDim2.new(0, 10, 0, 102) or UDim2.new(0, 10, 0, 10)
    end)
end

-- ---------- Main farm loop ----------
local function startBot()
    print("[Farmer] Booted with Optimized Clean Version.")

    task.spawn(function()
        while true do
            task.wait(State.ScanTick)

            if State.BotActive then
                local ok, err = pcall(function()
                    local target, targetPos = findTarget()
                    if target and targetPos then
                        local reached = moveTo(targetPos)
                        if not reached then
                            markBlacklisted(target)
                        end
                    else
                        task.wait(State.WaitWhenEmpty)
                    end
                end)

                if not ok then
                    warn("[Farmer] Vòng lặp gặp lỗi:", err)
                end
            end
        end
    end)
end

-- ---------- Boot ----------
local function main()
    createUI()
    startBot()
end

pcall(main)
