-- Roblox Smart Orchestrator Bot - V14.4 (Touch-Lock State Machine)
-- SỬA TRIỆT ĐỂ: Bổ sung luồng kiểm tra ép chạm cổng vào/đích đến, chống trùng lặp lệnh gây kẹt loop.

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
    if not hum:IsA("Humanoid") or not root:IsA("BasePart") then return false, nil, nil end
    if hum.Health <= 0 then return false, nil, nil end
    
    return true, hum, root
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

    scan(Workspace:FindFirstChild("EventStars"))
    if not closest then scan(Workspace:FindFirstChild("SpawnedFruits")) end

    return closest, cpos
end

local function spawnLifterPlatform(targetPos)
    local isAlive, _, root = safeCheckHumanoid()
    if not isAlive or not targetPos then return end
    
    local cleanPos = targetPos
    if typeof(cleanPos) == "Instance" and cleanPos:IsA("BasePart") then
        cleanPos = cleanPos.Position
    elseif typeof(cleanPos) ~= "Vector3" then
        return
    end
    
    debugLog("LIFTER", "Phát hiện kẹt vị trí. Kích hoạt bệ nâng năng lượng vượt địa hình.")
    local platform = Instance.new("Part")
    platform.Size = Vector3.new(4, 0.6, 4)
    platform.Name = "BotPlatform"
    platform.Anchored = true 
    platform.CanCollide = true
    platform.Material = Enum.Material.Neon
    platform.Color = Color3.fromRGB(0, 255, 200)
    platform.Transparency = 0.5
    
    platform.CFrame = root.CFrame * CFrame.new(0, -2.6, 0)
    platform.Parent = Workspace
    
    for _ = 1, 8 do
        if not State.BotActive then break end
        local alive, _, currentRoot = safeCheckHumanoid()
        if not alive then break end
        
        platform.CFrame = platform.CFrame + Vector3.new(0, 1.2, 0)
        currentRoot.CFrame = currentRoot.CFrame + Vector3.new(0, 1.2, 0)
        task.wait(0.01)
    end
    
    local aliveAfter, finalHum, finalRoot = safeCheckHumanoid()
    if aliveAfter and State.BotActive then
        finalHum:MoveTo(cleanPos) 
        local direction = (cleanPos - finalRoot.Position).Unit
        finalRoot.AssemblyLinearVelocity = Vector3.new(direction.X * 35, 12, direction.Z * 35)
    end
    
    task.wait(0.3)
    if platform and platform.Parent then platform:Destroy() end
end

local function smartMoveTo(targetPosition, targetInstance)
	local isAlive, _, root = safeCheckHumanoid() 
	if not isAlive or not targetPosition then return false end

	local path = PathfindingService:CreatePath({ AgentRadius = 1.6, AgentHeight = 5.0, AgentCanJump = true, WaypointSpacing = 4.0 })
	local success, _ = pcall(function() path:ComputeAsync(root.Position, targetPosition) end)

    local lastCheckTime = os.clock()
    local lastPosition = root.Position
    local stuckCounter = 0

	if success and path.Status == Enum.PathStatus.Success then
		local waypoints = path:GetWaypoints()
        
		for i, waypoint in ipairs(waypoints) do
			local alive, currentHum, currentRoot = safeCheckHumanoid() 
			if not alive or not State.BotActive then return false end
            if targetInstance and not targetInstance:IsDescendantOf(Workspace) then return true end

            local isLast = (i == #waypoints)
            local targetRadius = isLast and 1.5 or 3.5
            
			currentHum:MoveTo(waypoint.Position)

			local startTime = os.clock()
			while (currentRoot.Position - waypoint.Position).Magnitude > targetRadius do
				task.wait()
				local loopAlive, _, cRoot = safeCheckHumanoid() 
				if not loopAlive or not State.BotActive then return false end
                if targetInstance and not targetInstance:IsDescendantOf(Workspace) then return true end

                if os.clock() - lastCheckTime > 0.35 then
                    if (cRoot.Position - lastPosition).Magnitude < 0.4 then
                        stuckCounter = stuckCounter + 1
                        if stuckCounter >= 2 then
                            if State.PlatformLifter then
                                spawnLifterPlatform(waypoint.Position)
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
	else
		local aliveFallback, currentHum, currentRoot = safeCheckHumanoid()
		if aliveFallback then
			currentHum:MoveTo(targetPosition)
			local fallbackStartTime = os.clock()
            
			while (currentRoot.Position - targetPosition).Magnitude > 1.5 do
				task.wait()
				local loopAlive, _, cRoot = safeCheckHumanoid()
				if not loopAlive or not State.BotActive then return false end
                if targetInstance and not targetInstance:IsDescendantOf(Workspace) then return true end

                if os.clock() - lastCheckTime > 0.35 then
                    if (cRoot.Position - lastPosition).Magnitude < 0.4 then
                        stuckCounter = stuckCounter + 1
                        if stuckCounter >= 2 then
                            if State.PlatformLifter then
                                spawnLifterPlatform(targetPosition)
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
end

local function startSmartOrchestrator()
    debugLog("SYSTEM", "Vòng lặp điều phối V14.4 Touch-Lock đã kích hoạt.")
    
    task.spawn(function()
        while true do
            task.wait(State.ScanTick)
            
            if State.BotActive then
                local chosenObbyStage = nil
                local alive, hum, root = safeCheckHumanoid()
                
                -- BƯỚC 1: KIỂM TRA KHÓA MỤC TIÊU NẾU ĐANG Ở TRONG KHU VỰC ẢI OBBY
                if alive then
                    for i, stage in ipairs(obbyStages) do
                        if (i == 1 and State.FarmObby1) or (i == 2 and State.FarmObby2) then
                            local dest = Workspace:FindFirstChild(stage.DestinationName, true)
                            local btn = Workspace:FindFirstChild(stage.TargetBlockName, true)
                            
                            -- Nếu đứng gần đích hoặc gần nút bấm của ải nào trong phạm vi 130 studs -> Khóa cứng chạy ải đó
                            if (dest and (root.Position - dest.Position).Magnitude < 130) or (btn and (root.Position - btn.Position).Magnitude < 130) then
                                chosenObbyStage = stage
                                break
                            end
                        end
                    end
                end
                
                -- BƯỚC 2: NẾU ĐANG Ở NGOÀI SẢNH, LỰA CHỌN ẢI THÔNG THOÁNG ĐỂ TIẾP CẬN
                if not chosenObbyStage then
                    if State.FarmObby1 then
                        local stage1 = obbyStages[1]
                        local timeBlock1 = Workspace:FindFirstChild(stage1.TimeBlockName, true)
                        local isBlocked1 = timeBlock1 and timeBlock1.CanCollide == true and timeBlock1.Transparency < 1
                        if not isBlocked1 then chosenObbyStage = stage1 end
                    end
                    
                    if not chosenObbyStage and State.FarmObby2 then
                        local stage2 = obbyStages[2]
                        local timeBlock2 = Workspace:FindFirstChild(stage2.TimeBlockName, true)
                        local isBlocked2 = timeBlock2 and timeBlock2.CanCollide == true and timeBlock2.Transparency < 1
                        if not isBlocked2 then chosenObbyStage = stage2 end
                    end
                    
                    if not chosenObbyStage then
                        if State.FarmObby1 then chosenObbyStage = obbyStages[1]
                        elseif State.FarmObby2 then chosenObbyStage = obbyStages[2] end
                    end
                end
                
                -- QUÉT HOA QUẢ DỰ PHÒNG
                local fruitTarget, fruitPos = nil, nil
                if State.FarmFruit then fruitTarget, fruitPos = findTarget() end
                
                -- BƯỚC 3: XỬ LÝ ĐIỀU PHỐI HÀNH ĐỘNG CHỐNG KẸT LOOP VẬT LÝ
                if chosenObbyStage and alive then
                    local stage = chosenObbyStage
                    State.CurrentTargetStr = "QUY TRÌNH OBBY: " .. stage.Name
                    
                    local startTp = Workspace:FindFirstChild(stage.StartTpName, true)
                    local targetBlock = Workspace:FindFirstChild(stage.TargetBlockName, true)
                    local timeBlock = Workspace:FindFirstChild(stage.TimeBlockName, true)
                    local destination = Workspace:FindFirstChild(stage.DestinationName, true)
                    
                    local distanceToStart = startTp and (root.Position - startTp.Position).Magnitude or math.huge
                    local distanceToDest = destination and (root.Position - destination.Position).Magnitude or math.huge
                    
                    -------------------------------------------------------------------------
                    -- KHÓA CHẠM 1: ĐÃ ĐẾN SÁT ĐÍCH (OBBY STAR) -> ĐỢI TELEPORT RA NGOÀI SẢNH
                    -------------------------------------------------------------------------
                    if destination and distanceToDest < 7 then
                        debugLog("TOUCH-LOCK", "Đã tiếp cận ĐÍCH. Đóng băng luồng lệnh để nhận thưởng & Chờ game teleport...")
                        hum:MoveTo(destination.Position)
                        
                        local lockStart = os.clock()
                        while destination and destination:IsDescendantOf(Workspace) and (root.Position - destination.Position).Magnitude < 12 do
                            task.wait(0.05)
                            local loopAlive, _, cRoot = safeCheckHumanoid()
                            if not loopAlive or not State.BotActive then break end
                            -- Nếu khoảng cách đột ngột vọt lên xa chứng tỏ đã bị game teleport đi nơi khác -> Thoát khóa
                            if (cRoot.Position - destination.Position).Magnitude > 25 then break end
                            if os.clock() - lockStart > 1.5 then break end -- Timeout an toàn
                        end
                        debugLog("TOUCH-LOCK", "Giải phóng trạng thái khóa chạm Đích.")
                        
                    -------------------------------------------------------------------------
                    -- KHÓA CHẠM 2: ĐÃ ĐẾN SÁT CỔNG VÀO (OBBY TP) -> ĐỢI TELEPORT VÀO TRONG ẢI
                    -------------------------------------------------------------------------
                    elseif startTp and distanceToStart < 7 then
                        debugLog("TOUCH-LOCK", "Đã tiếp cận CỔNG VÀO. Đóng băng luồng lệnh & Chờ game dịch chuyển vào ải...")
                        hum:MoveTo(startTp.Position)
                        
                        local lockStart = os.clock()
                        while startTp and (root.Position - startTp.Position).Magnitude < 7 do
                            task.wait(0.05)
                            local loopAlive, _, cRoot = safeCheckHumanoid()
                            if not loopAlive or not State.BotActive then break end
                            if (cRoot.Position - startTp.Position).Magnitude > 20 then break end -- Đã bị dịch chuyển vào trong
                            if os.clock() - lockStart > 1.5 then break end -- Timeout an toàn
                        end
                        debugLog("TOUCH-LOCK", "Giải phóng trạng thái khóa chạm Cổng vào.")
                        
                    -------------------------------------------------------------------------
                    -- ĐIỀU HƯỚNG DI CHUYỂN THÔNG THƯỜNG TRONG VÀ NGOÀI ẢI
                    -------------------------------------------------------------------------
                    else
                        local isInsideObby = false
                        if destination and (root.Position - destination.Position).Magnitude < 130 then
                            isInsideObby = true
                        elseif targetBlock and (root.Position - targetBlock.Position).Magnitude < 130 then
                            isInsideObby = true
                        end
                        
                        if not isInsideObby and startTp then
                            debugLog("OBBY-NAV", "Đang ở ngoài sảnh. Di chuyển tới cổng vào: " .. startTp.Name)
                            smartMoveTo(startTp.Position, startTp)
                        else
                            local isDoorBlocked = timeBlock and timeBlock.CanCollide == true and timeBlock.Transparency < 1
                            if isDoorBlocked then
                                if targetBlock then 
                                    debugLog("OBBY-NAV", "Cửa đang khóa! Tiến đến dẫm nút mở cửa: " .. targetBlock.Name)
                                    smartMoveTo(targetBlock.Position, targetBlock) 
                                end
                            else
                                if destination then 
                                    debugLog("OBBY-NAV", "Cửa đã mở thông thoáng! Lao thẳng về đích lấy sao: " .. destination.Name)
                                    smartMoveTo(destination.Position, destination) 
                                end
                            end
                        end
                    end
                    
                elseif fruitTarget and fruitPos then
                    -- LUỒNG NHẶT QUẢ KHI RẢNH (KHÔNG BẬT HOẶC KHÔNG CÓ ẢI OBBY KHẢ DỤNG)
                    State.CurrentTargetStr = string.format("NHẶT QUẢ (RẢNH): %s", fruitTarget.Name)
                    local reached = smartMoveTo(fruitPos, fruitTarget)
                    if not reached and fruitTarget and fruitTarget:IsDescendantOf(Workspace) then 
                        markBlacklisted(fruitTarget)
                    end
                else
                    State.CurrentTargetStr = "Hệ thống rảnh rỗi / Hoặc toàn bộ tính năng tắt."
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
    
    State.CurrentTargetStr = "Hệ thống UI V14.4"
    debugLog("UI", "Khởi tạo hoàn tất. Đã nạp kiến trúc Touch-Lock chống kẹt hoàn toàn!")
end

local function main()
    createUI()
    startSmartOrchestrator()
end

pcall(main)
