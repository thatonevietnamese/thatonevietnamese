-- Roblox Smart Orchestrator Bot - V14.8 (Dynamic Cloud Walker)
-- CẬP NHẬT: Làm lại hoàn toàn cơ chế Lifter thành bệ đỡ di động, giữ nhân vật lơ lửng di chuyển xuyên tường cho đến khi thoát kẹt hoàn toàn.

local State = {
    BotActive = false,
    PlatformLifter = true, 
    FarmFruit = true,   
    FarmObby1 = false,  
    FarmObby2 = false,  
    BlacklistExpiry = 6,        
    ScanTick = 0.15,            
    MoveToTimeout = 1.2,
    CurrentTargetStr = "Chưa có",
    IsStuckEscaping = false, -- Trạng thái đang trong quá trình thoát kẹt
}

local UI_Elements = { MasterBtn = nil, FruitBtn = nil, Obby1Btn = nil, Obby2Btn = nil, LifterBtn = nil }
local Players = game:GetService("Players")
local PathfindingService = game:GetService("PathfindingService")
local Workspace = game:GetService("Workspace")
local player = Players.LocalPlayer
local blacklist = {}

local obbyStages = {
	{ Name = "Obby 1", StartTpName = "ObbyTp", TargetBlockName = "ObbyTp2", TimeBlockName = "Time1", DestinationName = "ObbyStar" },
	{ Name = "Obby 2", StartTpName = "ObbyTp3", TargetBlockName = "ObbyTp4", TimeBlockName = "Time2", DestinationName = "ObbyStar2" }
}

local function debugLog(category, text)
    local targetInfo = State.CurrentTargetStr or "Không có"
    print(string.format("[%s] [%s] [Mục tiêu: %s] -> %s", os.date("%X"), category, targetInfo, text))
end

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
        debugLog("BLACKLIST", "Đã đưa mục tiêu lỗi vào danh sách đen: " .. obj.Name)
    end
end

local function safeCheckHumanoid()
    local char = player.Character
    if not char then return false, nil, nil end
    
    local hum = char:FindFirstChildOfClass("Humanoid")
    local root = char:FindFirstChild("HumanoidRootPart")
    
    if not hum or not root then return false, nil, nil end
    if hum:IsA("Humanoid") and root:IsA("BasePart") then
        if hum.Health > 0 then
            return true, hum, root
        end
    end
    return false, nil, nil
end

local function findTarget()
    local isAlive, _, root = safeCheckHumanoid()
    if not isAlive then return nil, nil end

    local closest, cpos = nil, nil
    local dist = math.huge

    local function scan(folder)
        if not folder then return end
        for _, v in ipairs(folder:GetChildren()) do
            if not isBlacklisted(v) then
                local isA_BasePart = v:IsA("BasePart")
                local p = isA_BasePart and v.Position
                if not p and v:IsA("Model") then
                    p = v.PrimaryPart and v.PrimaryPart.Position or v:FindFirstChildWhichIsA("BasePart", true) and v:FindFirstChildWhichIsA("BasePart", true).Position
                end
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

    local starsFolder = Workspace:FindFirstChild("EventStars", true)
    local fruitsFolder = Workspace:FindFirstChild("SpawnedFruits", true)

    scan(starsFolder)
    if not closest then scan(fruitsFolder) end

    return closest, cpos
end

-- CẬP NHẬT CHÍ MẠNG V14.8: BỆ ĐỠ DI ĐỘNG HỘ TỐNG XUYÊN TƯỜNG
local function startCloudWalker(targetPos)
    local isAlive, hum, root = safeCheckHumanoid()
    if not isAlive or not targetPos or State.IsStuckEscaping then return end
    
    State.IsStuckEscaping = true
    debugLog("LIFTER-V2", "Kích hoạt Đạp Mây Vượt Địa Hình. Thiết lập bệ đỡ di động...")

    local platform = Instance.new("Part")
    platform.Size = Vector3.new(4.5, 0.6, 4.5)
    platform.Name = "BotCloudPlatform"
    platform.Anchored = true 
    platform.CanCollide = true
    platform.Material = Enum.Material.Neon
    platform.Color = Color3.fromRGB(0, 170, 255)
    platform.Transparency = 0.4
    
    local targetY = root.Position.Y + 4.0
    root.CFrame = CFrame.new(root.Position.X, targetY, root.Position.Z)
    platform.CFrame = CFrame.new(root.Position.X, targetY - 2.8, root.Position.Z)
    platform.Parent = Workspace

    task.spawn(function()
        local escapeStartTime = os.clock()
        
        while State.BotActive and State.IsStuckEscaping do
            local alive, currentHum, currentRoot = safeCheckHumanoid()
            if not alive then break end
            
            currentHum:MoveTo(targetPos)
            platform.CFrame = CFrame.new(currentRoot.Position.X, targetY - 2.8, currentRoot.Position.Z)
            
            local currentDist = (currentRoot.Position - targetPos).Magnitude
            if currentDist <= 3.0 or (os.clock() - escapeStartTime) > 3.0 then
                break
            end
            
            task.wait()
        end
        
        if platform and platform.Parent then platform:Destroy() end
        State.IsStuckEscaping = false
        debugLog("LIFTER-V2", "Đã thoát kẹt an toàn. Hủy bệ đỡ di động.")
    end)
end

-- CẤU TRÚC CANH TỈNH: Cấm nhảy hoàn toàn + điều chỉnh AgentHeight phù hợp không gian hẹp
local function smartMoveTo(targetPosition, targetInstance)
    local isAlive, _, root = safeCheckHumanoid() 
    if not isAlive or not targetPosition then return false end

    local path = PathfindingService:CreatePath({ 
        AgentRadius = 2.0, 
        AgentHeight = 3.0, 
        AgentCanJump = false, 
        AgentMaxSlope = 25,
        WaypointSpacing = 4.0
    })

    local success, _ = pcall(function() 
        path:ComputeAsync(root.Position, targetPosition) 
    end)

    local isPathTooSteep = false

    if success and path.Status == Enum.PathStatus.Success then
        local waypoints = path:GetWaypoints()

        for i = 2, #waypoints do
            local dy = math.abs(waypoints[i].Position.Y - waypoints[i-1].Position.Y)
            if dy > 4 then
                isPathTooSteep = true
                debugLog("PATH", "Phát hiện đường dốc bất thường → fallback")
                break
            end
        end
    end

    local lastCheckTime = os.clock()
    local lastPosition = root.Position
    local stuckCounter = 0

    if success and path.Status == Enum.PathStatus.Success and not isPathTooSteep then
        local waypoints = path:GetWaypoints()

        for i, waypoint in ipairs(waypoints) do
            local alive, currentHum, currentRoot = safeCheckHumanoid() 
            if not alive or not State.BotActive then return false end
            if targetInstance and not targetInstance:IsDescendantOf(Workspace) then return true end

            if State.IsStuckEscaping then 
                task.wait(0.1)
                continue 
            end

            local isLast = (i == #waypoints)
            local targetRadius = isLast and 1.5 or 3.5

            currentHum:MoveTo(waypoint.Position)

            local startTime = os.clock()

            while (currentRoot.Position - waypoint.Position).Magnitude > targetRadius do
                task.wait()

                local loopAlive, _, cRoot = safeCheckHumanoid() 
                if not loopAlive or not State.BotActive then return false end
                if targetInstance and not targetInstance:IsDescendantOf(Workspace) then return true end
                if State.IsStuckEscaping then break end

                if os.clock() - lastCheckTime > 0.35 then
                    if (cRoot.Position - lastPosition).Magnitude < 0.4 then
                        stuckCounter += 1

                        if stuckCounter >= 2 then
                            if State.PlatformLifter then
                                startCloudWalker(targetPosition)
                            end
                            stuckCounter = 0
                            lastCheckTime = os.clock() + 0.3
                        end
                    else
                        stuckCounter = 0
                    end

                    lastPosition = cRoot.Position
                    lastCheckTime = os.clock()
                end

                if (os.clock() - startTime) > 1.5 then break end
            end
        end

        return true
    end

    debugLog("PATH", "Dùng fallback MoveTo")

    local aliveFallback, currentHum, currentRoot = safeCheckHumanoid()
    if aliveFallback then
        currentHum:MoveTo(targetPosition)

        local fallbackStartTime = os.clock()

        while (currentRoot.Position - targetPosition).Magnitude > 1.5 do
            task.wait()

            local loopAlive, _, cRoot = safeCheckHumanoid()
            if not loopAlive or not State.BotActive then return false end
            if targetInstance and not targetInstance:IsDescendantOf(Workspace) then return true end

            if State.IsStuckEscaping then 
                task.wait(0.1) 
                continue 
            end

            if os.clock() - lastCheckTime > 0.35 then
                if (cRoot.Position - lastPosition).Magnitude < 0.4 then
                    stuckCounter += 1

                    if stuckCounter >= 2 then
                        if State.PlatformLifter then
                            startCloudWalker(targetPosition)
                        end
                        stuckCounter = 0
                    end
                else
                    stuckCounter = 0
                end

                lastPosition = cRoot.Position
                lastCheckTime = os.clock()
            end

            if (os.clock() - fallbackStartTime) > State.MoveToTimeout then break end
        end

        return (currentRoot.Position - targetPosition).Magnitude <= 2.0
    end

    return false
end

local function startSmartOrchestrator()
    debugLog("SYSTEM", "Vòng lặp điều phối V14.8 Cloud Walker hoạt động.")
    
    task.spawn(function()
        while true do
            task.wait(State.ScanTick)
            
            if State.BotActive then
                local alive, hum, root = safeCheckHumanoid()
                
                if alive then
                    local fruitTarget, fruitPos = nil, nil
                    if State.FarmFruit then 
                        fruitTarget, fruitPos = findTarget() 
                    end
                    
                    local activeObbyStage = nil
                    local isInsideObby = false
                    for i, stage in ipairs(obbyStages) do
                        if (i == 1 and State.FarmObby1) or (i == 2 and State.FarmObby2) then
                            local dest = Workspace:FindFirstChild(stage.DestinationName, true)
                            local btn = Workspace:FindFirstChild(stage.TargetBlockName, true)
                            if (dest and (root.Position - dest.Position).Magnitude < 130) or (btn and (root.Position - btn.Position).Magnitude < 130) then
                                activeObbyStage = stage
                                isInsideObby = true
                                break
                            end
                        end
                    end

                    -------------------------------------------------------------------------
                    -- TRƯỜNG HỢP 1: NẾU THẤY QUẢ/SAO Ở SẢNH
                    -------------------------------------------------------------------------
                    if fruitTarget and fruitPos and not (isInsideObby and (fruitPos - root.Position).Magnitude > 50) then
                        State.CurrentTargetStr = string.format("ƯU TIÊN EVENT: %s", fruitTarget.Name)
                        local reached = smartMoveTo(fruitPos, fruitTarget)
                        if not reached and fruitTarget and fruitTarget:IsDescendantOf(Workspace) then 
                            markBlacklisted(fruitTarget)
                        end

                    -------------------------------------------------------------------------
                    -- TRƯỜNG HỢP 2: ĐANG LEO ẢI OBBY
                    -------------------------------------------------------------------------
                    elseif isInsideObby and activeObbyStage then
                        local stage = activeObbyStage
                        State.CurrentTargetStr = "ĐANG LEO ẢI: " .. stage.Name
                        
                        local startTp = Workspace:FindFirstChild(stage.StartTpName, true)
                        local targetBlock = Workspace:FindFirstChild(stage.TargetBlockName, true)
                        local timeBlock = Workspace:FindFirstChild(stage.TimeBlockName, true)
                        local destination = Workspace:FindFirstChild(stage.DestinationName, true)
                        
                        local distanceToStart = startTp and (root.Position - startTp.Position).Magnitude or math.huge
                        local distanceToDest = destination and (root.Position - destination.Position).Magnitude or math.huge
                        
                        if destination and distanceToDest < 7 then
                            debugLog("TOUCH-LOCK", "Chạm ĐÍCH Obby. Khóa vị trí nhận thưởng...")
                            hum:MoveTo(destination.Position)
                            local lockStart = os.clock()
                            while destination and destination:IsDescendantOf(Workspace) and (root.Position - destination.Position).Magnitude < 12 do
                                task.wait(0.05)
                                local loopAlive, _, cRoot = safeCheckHumanoid()
                                if not loopAlive or not State.BotActive then break end
                                if (cRoot.Position - destination.Position).Magnitude > 25 then break end
                                if os.clock() - lockStart > 1.5 then break end
                            end
                        elseif startTp and distanceToStart < 7 then
                            debugLog("TOUCH-LOCK", "Chạm CỔNG VÀO. Đang đợi game nạp map...")
                            hum:MoveTo(startTp.Position)
                            local lockStart = os.clock()
                            while startTp and (root.Position - startTp.Position).Magnitude < 7 do
                                task.wait(0.05)
                                local loopAlive, _, cRoot = safeCheckHumanoid()
                                if not loopAlive or not State.BotActive then break end
                                if (cRoot.Position - startTp.Position).Magnitude > 20 then break end
                                if os.clock() - lockStart > 1.5 then break end
                            end
                        else
                            local isDoorBlocked = timeBlock and timeBlock.CanCollide == true and timeBlock.Transparency < 1
                            if isDoorBlocked then
                                if targetBlock then smartMoveTo(targetBlock.Position, targetBlock) end
                            else
                                if destination then smartMoveTo(destination.Position, destination) end
                            end
                        end
                        
                    -------------------------------------------------------------------------
                    -- TRƯỜNG HỢP 3: SẢNH TRỐNG -> ĐI TÌM CỔNG OBBY
                    -------------------------------------------------------------------------
                    else
                        local chosenLobbyObby = nil
                        
                        if State.FarmObby1 then
                            local stage1 = obbyStages[1]
                            local timeBlock1 = Workspace:FindFirstChild(stage1.TimeBlockName, true)
                            local isBlocked1 = timeBlock1 and timeBlock1.CanCollide == true and timeBlock1.Transparency < 1
                            if not isBlocked1 then chosenLobbyObby = stage1 end
                        end
                        
                        if not chosenLobbyObby and State.FarmObby2 then
                            local stage2 = obbyStages[2]
                            local timeBlock2 = Workspace:FindFirstChild(stage2.TimeBlockName, true)
                            local isBlocked2 = timeBlock2 and timeBlock2.CanCollide == true and timeBlock2.Transparency < 1
                            if not isBlocked2 then chosenLobbyObby = stage2 end
                        end
                        
                        if not chosenLobbyObby then
                            if State.FarmObby1 then chosenLobbyObby = obbyStages[1]
                            elseif State.FarmObby2 then chosenLobbyObby = obbyStages[2] end
                        end
                        
                        if chosenLobbyObby then
                            State.CurrentTargetStr = "TIẾN TỚI CỔNG: " .. chosenLobbyObby.Name
                            local startTp = Workspace:FindFirstChild(chosenLobbyObby.StartTpName, true)
                            if startTp then
                                local distanceToStart = (root.Position - startTp.Position).Magnitude
                                if distanceToStart < 7 then
                                    debugLog("TOUCH-LOCK", "Đang đứng tại cổng chờ. Ép luồng đi vào...")
                                    hum:MoveTo(startTp.Position)
                                    local lockStart = os.clock()
                                    while startTp and (root.Position - startTp.Position).Magnitude < 7 do
                                        task.wait(0.05)
                                        local loopAlive, _, cRoot = safeCheckHumanoid()
                                        if not loopAlive or not State.BotActive then break end
                                        if (cRoot.Position - startTp.Position).Magnitude > 20 then break end
                                        if os.clock() - lockStart > 1.5 then break end
                                    end
                                else
                                    smartMoveTo(startTp.Position, startTp)
                                end
                            end
                        else
                            State.CurrentTargetStr = "Sảnh trống / Toàn bộ tính năng đang tắt."
                        end
                    end
                end
            end
        end
    end)
end

local function createUI()
    if game.CoreGui:FindFirstChild("HubUI") then game.CoreGui.HubUI:Destroy() end
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
    container.Size = UDim2.new(0, 140, 0, 185) 
    container.Position = UDim2.new(0, 20, 0, 120)
    container.BackgroundColor3 = Color3.fromRGB(18, 18, 18)
    container.BorderSizePixel = 0
    container.Parent = gui

    local corner = Instance.new("UICorner", container)
    corner.CornerRadius = UDim.new(0, 5)

    local function makeBtn(text, yOffset, callback)
        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(0, 124, 0, 24) 
        btn.Position = UDim2.new(0, 8, 0, yOffset)
        btn.BackgroundColor3 = Color3.fromRGB(33, 33, 33)
        btn.TextColor3 = Color3.fromRGB(245, 245, 245)
        btn.Text = text
        btn.Font = Enum.Font.SourceSansBold
        btn.TextSize = 11
        btn.Parent = container
        
        local bCorner = Instance.new("UICorner", btn)
        bCorner.CornerRadius = UDim.new(0, 4)
        
        btn.MouseButton1Click:Connect(function() callback(btn) end)
        return btn
    end

    UI_Elements.MasterBtn = makeBtn("BOT ACTIVE: OFF", 8, function(self)
        State.BotActive = not State.BotActive
        if self then
            self.Text = State.BotActive and "BOT ACTIVE: ON" or "BOT ACTIVE: OFF"
            self.BackgroundColor3 = State.BotActive and Color3.fromRGB(26, 107, 54) or Color3.fromRGB(33, 33, 33)
        end
    end)

    UI_Elements.FruitBtn = makeBtn("FARM FRUIT: ON", 36, function(self)
        State.FarmFruit = not State.FarmFruit
        if self then
            self.Text = State.FarmFruit and "FARM FRUIT: ON" or "FARM FRUIT: OFF"
            self.BackgroundColor3 = State.FarmFruit and Color3.fromRGB(26, 70, 133) or Color3.fromRGB(33, 33, 33)
        end
    end)

    UI_Elements.Obby1Btn = makeBtn("FARM OBBY 1: OFF", 64, function(self)
        State.FarmObby1 = not State.FarmObby1
        if self then
            self.Text = State.FarmObby1 and "FARM OBBY 1: ON" or "FARM OBBY 1: OFF"
            self.BackgroundColor3 = State.FarmObby1 and Color3.fromRGB(112, 34, 130) or Color3.fromRGB(33, 33, 33)
        end
    end)

    UI_Elements.Obby2Btn = makeBtn("FARM OBBY 2: OFF", 92, function(self)
        State.FarmObby2 = not State.FarmObby2
        if self then
            self.Text = State.FarmObby2 and "FARM OBBY 2: ON" or "FARM OBBY 2: OFF"
            self.BackgroundColor3 = State.FarmObby2 and Color3.fromRGB(112, 34, 130) or Color3.fromRGB(33, 33, 33)
        end
    end)

    UI_Elements.LifterBtn = makeBtn("PLATFORM LIFTER: ON", 120, function(self)
        State.PlatformLifter = not State.PlatformLifter
        if self then
            self.Text = State.PlatformLifter and "PLATFORM LIFTER: ON" or "PLATFORM LIFTER: OFF"
            self.BackgroundColor3 = State.PlatformLifter and Color3.fromRGB(26, 107, 54) or Color3.fromRGB(33, 33, 33)
        end
    end)

    makeBtn("MINIMIZE UI", 148, function(self)
        local list = {UI_Elements.MasterBtn, UI_Elements.FruitBtn, UI_Elements.Obby1Btn, UI_Elements.Obby2Btn, UI_Elements.LifterBtn}
        for _, c in ipairs(list) do 
            if c then c.Visible = not c.Visible end 
        end
        
        local isVisible = UI_Elements.MasterBtn and UI_Elements.MasterBtn.Visible
        if self then
            self.Text = isVisible and "MINIMIZE UI" or "EXPAND"
            container.Size = isVisible and UDim2.new(0, 140, 0, 185) or UDim2.new(0, 140, 0, 38)
            self.Position = isVisible and UDim2.new(0, 8, 0, 148) or UDim2.new(0, 8, 0, 7)
        end
    end)
    
    if UI_Elements.FruitBtn then UI_Elements.FruitBtn.BackgroundColor3 = Color3.fromRGB(26, 70, 133) end
    if UI_Elements.LifterBtn then UI_Elements.LifterBtn.BackgroundColor3 = Color3.fromRGB(26, 107, 54) end
    
    State.CurrentTargetStr = "Hệ thống UI V14.8"
    debugLog("UI", "Khởi tạo hoàn tất! Đã kích hoạt cơ chế Đạp Mây Vượt Địa Hình mới.")
end

local function main()
    createUI()
    startSmartOrchestrator()
end

pcall(main)
