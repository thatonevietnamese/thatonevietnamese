-------------------------------------------------------------------------
-- SERVICES SYSTEM
-------------------------------------------------------------------------
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")
local PathfindingService = game:GetService("PathfindingService")
local VirtualUser = game:GetService("VirtualUser") 
local player = Players.LocalPlayer

local EventStateFolder = ReplicatedStorage:WaitForChild("EventState", 10)
local EventInProgress = EventStateFolder and EventStateFolder:WaitForChild("IsInProgress", 10)

-------------------------------------------------------------------------
-- HỆ THỐNG DEBUG LOG & ANTI-AFK
-------------------------------------------------------------------------
local function debugLog(msg, isWarn)
    if isWarn then warn("[BOT_DEBUG_WARN] " .. tostring(msg))
    else print("[BOT_DEBUG] " .. tostring(msg)) end
end

player.Idled:Connect(function()
    VirtualUser:CaptureController()
    VirtualUser:ClickButton2(Vector2.new())
end)

-------------------------------------------------------------------------
-- CONFIG SYSTEM
-------------------------------------------------------------------------
local PATH_WIDTH = 12
local OBBY1_PATH_WIDTH = PATH_WIDTH * 2 
local OBBY2_PATH_WIDTH = PATH_WIDTH * 4 
local PATH_THICKNESS = 0.1

local OBBY1_CENTER = Vector3.new(21, 99, -1518) 
local OBBY1_RADIUS = 150
local FOLDER_NAME = "Total_Obby_Visual_Path"

local P1 = Vector3.new(735.1, 155.5, -1778.2) 
local P2 = Vector3.new(747.9, 167.3, -1804.6) 
local P3 = Vector3.new(732.3, 132.8, -1446.8) 
local P4 = Vector3.new(734.2, 155.5, -1773.5) 

local State = {
    BotActive = true,       -- [ĐÃ ĐỔI] Tự động bật Agent khi khởi động
    PlatformLifter = true, 
    FarmItems = true,      
    FarmObby1 = true,       -- [ĐÃ ĐỔI] Tự động bật làm Obby 1
    FarmObby2 = true,       -- [ĐÃ ĐỔI] Tự động bật làm Obby 2
    BlacklistExpiry = 5, 
    ScanTick = 0.1,         
    CurrentTargetStr = "Chưa có",
    IsStuckEscaping = false,
    Obby1PlatformReached = false, 
    
    LastTarget = nil,
    LobbyStuckCount = 0,
    RawStuckTick = 0,
    RawStuckPos = Vector3.new(),
    ObbyRawStuckTick = 0,
    ObbyRawStuckPos = Vector3.new()
}

local UI_Elements = { MasterBtn = nil, ItemBtn = nil, Obby1Btn = nil, Obby2Btn = nil, LifterBtn = nil }

-------------------------------------------------------------------------
-- CƠ CHẾ WEAK TABLES & RAM CLEANER
-------------------------------------------------------------------------
local blacklist = setmetatable({}, {__mode = "k"})
local strikeTable = setmetatable({}, {__mode = "k"})
local permanentBlacklist = setmetatable({}, {__mode = "k"})

if EventInProgress then
    EventInProgress.Changed:Connect(function(val)
        if val == false then
            table.clear(blacklist)
            table.clear(strikeTable)
            table.clear(permanentBlacklist)
            debugLog("🧹 [RAM CLEANER] Đã xóa sạch toàn bộ Blacklist khỏi bộ nhớ!", false)
        end
    end)
end

local obbyStages = {
    { Name = "Obby 1", StartTpName = "ObbyTp", TargetBlockName = "ObbyTp2", TimeBlockName = "Time1", DestinationName = "ObbyStar" },
    { Name = "Obby 2", StartTpName = "ObbyTp3", TargetBlockName = "ObbyTp4", TimeBlockName = "Time2", DestinationName = "ObbyStar2" }
}

local GlobalRobloxPath = PathfindingService:CreatePath({ 
    AgentRadius = 2.0, AgentHeight = 3.0, AgentCanJump = true, AgentMaxSlope = 15, WaypointSpacing = 3.5
})
local lastPathComputation = 0
local PATH_COOLDOWN = 0.35 

-------------------------------------------------------------------------
-- TẠO ĐƯỜNG CẦU VISUAL & PHÁ CÂY TRONG LOBBY
-------------------------------------------------------------------------
task.spawn(function()
    while true do
        task.wait(2)
        for _, v in ipairs(Workspace:GetChildren()) do
            if v:IsA("Model") or v:IsA("BasePart") then
                local nameLower = v.Name:lower()
                if nameLower:find("oak") or nameLower:find("birch") then
                    v:Destroy()
                end
            end
        end
    end
end)

local function buildVisualPaths()
    local old = Workspace:FindFirstChild(FOLDER_NAME)
    if old then old:Destroy() task.wait(0.05) end

    local folder = Instance.new("Folder")
    folder.Name = FOLDER_NAME
    folder.Parent = Workspace

    local function drawPath(p1, p2, name, width)
        local dist = (p1 - p2).Magnitude
        local cf = CFrame.lookAt(p1, p2) * CFrame.new(0, 0, -dist / 2)
        local part = Instance.new("Part")
        part.Name = name
        part.Size = Vector3.new(width, PATH_THICKNESS, dist)
        part.CFrame = cf
        part.Material = Enum.Material.Neon
        part.Color = Color3.fromRGB(255, 0, 128)
        part.Transparency = 0.3
        part.CanCollide = true
        part.Anchored = true
        part.Parent = folder
    end

    local function createObby1Plate()
        local part = Instance.new("Part")
        part.Name = "Obby1_ThinFloor"
        part.Shape = Enum.PartType.Cylinder
        part.Material = Enum.Material.Neon
        part.Color = Color3.fromRGB(255, 0, 128)
        part.Transparency = 0.3
        part.Anchored = true
        part.CanCollide = true 
        part.Size = Vector3.new(0.1, OBBY1_RADIUS * 2, OBBY1_RADIUS * 2)
        part.CFrame = CFrame.new(OBBY1_CENTER) * CFrame.Angles(0, 0, math.rad(90))
        part.Parent = folder
    end

    createObby1Plate()
    drawPath(P1, P2, "Pair_1_Obby1", OBBY1_PATH_WIDTH)
    drawPath(P3, P4, "Pair_2_Obby2", OBBY2_PATH_WIDTH)
end

-------------------------------------------------------------------------
-- LOGIC BLACKLIST
-------------------------------------------------------------------------
local function isBlacklisted(obj)
    if not obj or not obj:IsDescendantOf(game) then return false end
    if permanentBlacklist[obj] then return true end
    
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
        strikeTable[obj] = (strikeTable[obj] or 0) + 1
        
        if strikeTable[obj] >= 3 then
            permanentBlacklist[obj] = true
            blacklist[obj] = nil 
            debugLog("🚫 [PERMANENT BLACKLIST] Đã dính 3 strike! Khóa cứng vật thể lỗi: " .. obj.Name, true)
        else
            blacklist[obj] = os.clock()
            debugLog("🔴 [BLACKLIST TẠM THỜI] Strike " .. strikeTable[obj] .. "/3 cho: " .. obj.Name, false)
        end
    end
end

local function safeCheckHumanoid()
    local char = player.Character
    if not char then return false, nil, nil end
    local hum = char:FindFirstChildOfClass("Humanoid")
    local root = char:FindFirstChild("HumanoidRootPart")
    if not hum or not root then return false, nil, nil end
    if hum:IsA("Humanoid") and root:IsA("BasePart") and hum.Health > 0 then
        return true, hum, root
    end
    return false, nil, nil
end

-------------------------------------------------------------------------
-- CƠ CHẾ KIỂM TRA SAO BỊ CHÔN TRONG TƯỜNG DÀY (NEW V35.4)
-------------------------------------------------------------------------
local function isStarTrappedInThickWall(starInstance)
    if not starInstance or not starInstance:IsDescendantOf(Workspace) then return false end
    
    local params = OverlapParams.new()
    params.FilterDescendantsInstances = {player.Character, Workspace:FindFirstChild(FOLDER_NAME), starInstance}
    params.FilterType = Enum.RaycastFilterType.Exclude
    
    -- Lấy toàn bộ các Part đang giao nhau/chôn đè lên Star
    local overlappingParts = Workspace:GetPartsInPart(starInstance, params)
    
    for _, part in ipairs(overlappingParts) do
        if part:IsA("BasePart") and part.CanCollide then
            -- Đo độ dày cạnh nhỏ nhất của khối vật thể cản đó
            local minSize = math.min(part.Size.X, part.Size.Y, part.Size.Z)
            
            -- Nếu độ dày > 3.5 stud, bot đứng ngoài bề mặt sẽ không bao giờ chạm được tâm Star -> Bỏ qua!
            if minSize > 3.5 then
                return true 
            end
        end
    end
    return false
end

local function findTarget()
    if not State.FarmItems then return nil, nil end
    local isAlive, _, root = safeCheckHumanoid()
    if not isAlive then return nil, nil end

    local function getClosestInFolder(folder, checkWall)
        if not folder then return nil, nil end
        local closestTarget, closestPos = nil, nil
        local minDist = math.huge
        
        for _, v in ipairs(folder:GetChildren()) do
            if v:IsA("MeshPart") and not isBlacklisted(v) then
                local pos = v.Position
                local d = (pos - root.Position).Magnitude
                if d < minDist then 
                    -- Nếu là thư mục EventStars, kích hoạt bộ lọc quét độ dày khối hình học
                    if checkWall and isStarTrappedInThickWall(v) then
                        continue -- Bỏ qua ngôi sao lỗi này, chuyển sang quét quả/sao tiếp theo
                    end
                    minDist = d; closestTarget = v; closestPos = pos 
                end
            end
        end
        return closestTarget, closestPos
    end

    local fruitTarget, fruitPos = getClosestInFolder(Workspace:FindFirstChild("SpawnedFruits"), false)
    if fruitTarget then return fruitTarget, fruitPos end

    if EventInProgress and EventInProgress.Value == true then
        local starTarget, starPos = getClosestInFolder(Workspace:FindFirstChild("EventStars"), true)
        if starTarget then return starTarget, starPos end
    end
    return nil, nil
end

local function isStageBlocked(stage)
    local timeBlock = Workspace:FindFirstChild(stage.TimeBlockName, true)
    return timeBlock and timeBlock.CanCollide == true and timeBlock.Transparency < 1
end

-------------------------------------------------------------------------
-- TÍNH NĂNG ĐẠP MÂY THÔNG MINH (CLOUD WALKER)
-------------------------------------------------------------------------
local function startLobbyCloudWalker(targetPos, maxDuration, targetInstance)
    local isAlive, hum, root = safeCheckHumanoid()
    if not isAlive or not targetPos or State.IsStuckEscaping then return end
    
    State.IsStuckEscaping = true
    local durationLimit = maxDuration or 4.0
    local startY = root.Position.Y
    local targetY = startY
    local maxLiftY = startY + 14.0 

    local platform = Instance.new("Part")
    platform.Size = Vector3.new(6.0, 0.6, 6.0) 
    platform.Name = "BotLobbyCloudPlatform"
    platform.Anchored = true 
    platform.CanCollide = true
    platform.Material = Enum.Material.Neon
    platform.Color = Color3.fromRGB(0, 255, 128) 
    platform.Transparency = 0.4
    platform.CFrame = CFrame.new(root.Position.X, targetY - 1.5, root.Position.Z)
    platform.Parent = Workspace

    root.CFrame = root.CFrame + Vector3.new(0, 3, 0)

    task.spawn(function()
        local escapeStartTime = os.clock()
        local lastLiftTime = os.clock()
        
        while State.BotActive and State.IsStuckEscaping do
            task.wait()
            local alive, currentHum, currentRoot = safeCheckHumanoid()
            if not alive then break end
            
            local currentPos = currentRoot.Position
            local dist2D = (Vector2.new(currentPos.X, currentPos.Z) - Vector2.new(targetPos.X, targetPos.Z)).Magnitude
            
            if dist2D <= 2.2 then break end
            if dist2D <= 3.5 or (os.clock() - escapeStartTime) > durationLimit then break end 
            
            if os.clock() - lastLiftTime >= 0.2 then
                if targetY < maxLiftY then 
                    targetY = math.min(targetY + 1.5, maxLiftY) 
                    currentRoot.CFrame = currentRoot.CFrame + Vector3.new(0, 1.5, 0)
                end
                lastLiftTime = os.clock()
            end
            
            currentHum:MoveTo(Vector3.new(targetPos.X, targetY, targetPos.Z))
            platform.CFrame = CFrame.new(currentPos.X, targetY - 1.5, currentPos.Z)
        end
        if platform then platform:Destroy() end
        State.IsStuckEscaping = false
    end)
end

local function obbyWalkOnCloud(targetPos, targetY, timeout)
    local isAlive, hum, root = safeCheckHumanoid()
    if not isAlive then return end
    
    local currentY = root.Position.Y
    local cloud = Instance.new("Part")
    cloud.Name = "ObbyRescueCloud"
    cloud.Size = Vector3.new(12, 1, 12)
    cloud.Anchored = true
    cloud.CanCollide = true
    cloud.Material = Enum.Material.Neon
    cloud.Color = Color3.fromRGB(255, 200, 0)
    cloud.Transparency = 0.4
    cloud.Parent = Workspace
    
    root.CFrame = root.CFrame + Vector3.new(0, 3, 0)
    
    local startTime = os.clock()
    while State.BotActive and (os.clock() - startTime) < timeout do
        task.wait()
        local alive, cHum, cRoot = safeCheckHumanoid()
        if not alive then break end
        
        local dist2D = (Vector2.new(cRoot.Position.X, cRoot.Position.Z) - Vector2.new(targetPos.X, targetPos.Z)).Magnitude
        if dist2D <= 2.2 then break end

        cloud.CFrame = CFrame.new(cRoot.Position.X, currentY - 1.5, cRoot.Position.Z)
        cHum:MoveTo(Vector3.new(targetPos.X, currentY, targetPos.Z))
    end
    if cloud then cloud:Destroy() end
end

-------------------------------------------------------------------------
-- PATHFINDING ENGINE: SMART RAYCAST
-------------------------------------------------------------------------
local function smartMoveTo(targetPosition, targetInstance)
    if not State.BotActive then return "ERROR" end
    if State.IsStuckEscaping then task.wait(0.05) return "ESCAPING" end

    local isAlive, hum, root = safeCheckHumanoid() 
    if not isAlive or not targetPosition then return "ERROR" end
    if targetInstance and not targetInstance:IsDescendantOf(Workspace) then return "DESTROYED" end

    if (root.Position - targetPosition).Magnitude < 4.0 then 
        hum:MoveTo(targetPosition) 
        return "SUCCESS"
    end

    if os.clock() - lastPathComputation < PATH_COOLDOWN then return "COOLDOWN" end
    lastPathComputation = os.clock()

    local success, _ = pcall(function() GlobalRobloxPath:ComputeAsync(root.Position, targetPosition) end)

    if not success or GlobalRobloxPath.Status ~= Enum.PathStatus.Success or #GlobalRobloxPath:GetWaypoints() == 0 then
        return "PATH_FAILED" 
    end

    local waypoints = GlobalRobloxPath:GetWaypoints()
    local lastCheckTime = os.clock()
    local lastPosition = root.Position
    local stuckCounter = 0
    local brokenPath = false
    local isInsideObby = ((root.Position - OBBY1_CENTER).Magnitude < 350) or ((root.Position - P3).Magnitude < 350)

    for i, waypoint in ipairs(waypoints) do
        local alive, currentHum, currentRoot = safeCheckHumanoid() 
        if not alive or not State.BotActive or State.IsStuckEscaping then 
            if currentHum then currentHum:MoveTo(currentRoot.Position) end
            return "ERROR" 
        end
        if targetInstance and not targetInstance:IsDescendantOf(Workspace) then return "DESTROYED" end

        local targetRadius = (i == #waypoints) and 1.5 or 3.5

        if not isInsideObby then
            local rayParams = RaycastParams.new()
            rayParams.FilterDescendantsInstances = {player.Character, Workspace:FindFirstChild(FOLDER_NAME)}
            rayParams.FilterType = Enum.RaycastFilterType.Exclude

            local rayResult = Workspace:Raycast(currentRoot.Position, currentRoot.CFrame.LookVector * 4.0, rayParams)
            if rayResult and rayResult.Instance and rayResult.Instance.CanCollide then
                local hit = rayResult.Instance
                local obstacleTopY = hit.Position.Y + (hit.Size.Y / 2)
                
                if obstacleTopY > (currentRoot.Position.Y - 1.5) and hit.Size.Y <= 25 then
                    return "TRIGGER_CLOUD"
                elseif obstacleTopY > 37.0 or hit.Size.X > 30 or hit.Size.Z > 30 then
                    return "WALL_BLOCKED" 
                else
                    return "OBSTACLE", obstacleTopY
                end
            end
        end

        if waypoint.Action == Enum.PathWaypointAction.Jump then currentHum.Jump = true end
        currentHum:MoveTo(waypoint.Position) 
        
        local startTime = os.clock()

        while (currentRoot.Position - waypoint.Position).Magnitude > targetRadius do
            task.wait()
            local loopAlive, loopHum, cRoot = safeCheckHumanoid() 
            if not loopAlive or not State.BotActive or State.IsStuckEscaping then 
                if loopHum and cRoot then loopHum:MoveTo(cRoot.Position) end
                return "ERROR" 
            end
            
            if loopHum:GetState() == Enum.HumanoidStateType.Climbing then
                return "TRIGGER_CLOUD"
            end

            if not isInsideObby and loopHum.MoveDirection.Magnitude > 0 then loopHum.Jump = true end
            
            if os.clock() - lastCheckTime > 0.35 then
                local currentPos = cRoot.Position
                local movedDistXZ = Vector2.new(currentPos.X - lastPosition.X, currentPos.Z - lastPosition.Z).Magnitude
                
                if movedDistXZ < 1.5 then 
                    stuckCounter = stuckCounter + 1
                    if stuckCounter >= 2 then brokenPath = true break end
                else
                    stuckCounter = 0
                end
                lastPosition = currentPos
                lastCheckTime = os.clock()
            end
            if (os.clock() - startTime) > 0.9 then break end
        end
        if brokenPath then break end 
    end

    if brokenPath then return "PHYSICAL_STUCK" end 
    return "SUCCESS"
end

-------------------------------------------------------------------------
-- VÒNG LẶP ĐIỀU PHỐI CHÍNH
-------------------------------------------------------------------------
local function startSmartOrchestrator()
    task.spawn(function()
        while true do
            task.wait(State.ScanTick)
            if State.BotActive then
                local alive, hum, root = safeCheckHumanoid()
                if alive then
                    hum.WalkSpeed = 25
                    local myPos = root.Position
                    local isInsideObby = false
                    local activeObbyStage = nil
                    
                    if (myPos - OBBY1_CENTER).Magnitude < 350 then
                        isInsideObby = true; activeObbyStage = obbyStages[1]
                    elseif (myPos - P3).Magnitude < 350 then
                        isInsideObby = true; activeObbyStage = obbyStages[2]
                    end

                    if isInsideObby and activeObbyStage then
                        local stage = activeObbyStage
                        local targetBlock = Workspace:FindFirstChild(stage.TargetBlockName, true) 
                        local timeBlock = Workspace:FindFirstChild(stage.TimeBlockName, true)
                        local destination = Workspace:FindFirstChild(stage.DestinationName, true)
                        
                        local isDoorBlocked = timeBlock and timeBlock.CanCollide == true and timeBlock.Transparency < 1
                        local finalTargetInst = isDoorBlocked and targetBlock or destination
                        
                        if not finalTargetInst then
                            State.CurrentTargetStr = string.format("[%s] Chờ Server...", stage.Name)
                        else
                            local finalTargetPos = finalTargetInst.Position

                            if stage.Name == "Obby 1" and not isDoorBlocked then
                                local status = smartMoveTo(finalTargetPos, finalTargetInst)
                                if status == "PATH_FAILED" or status == "COOLDOWN" then hum:MoveTo(finalTargetPos) end
                                if status == "PHYSICAL_STUCK" or status == "TRIGGER_CLOUD" then obbyWalkOnCloud(finalTargetPos, finalTargetPos.Y, 1.5) end
                                State.CurrentTargetStr = "[Obby 1] -> Đang Về Đích"

                            elseif stage.Name == "Obby 2" then
                                local distToP3 = (myPos - P3).Magnitude
                                local distToP4 = (myPos - P4).Magnitude 
                                
                                if distToP3 > 15 and distToP4 > (P3 - P4).Magnitude then 
                                    State.CurrentTargetStr = "[Obby 2] -> Lên Đầu Cầu (P3)"
                                    smartMoveTo(P3, nil)
                                elseif distToP4 > 12 then
                                    State.CurrentTargetStr = "[Obby 2] -> Chạy Thẳng Trên Cầu (P4)"
                                    hum:MoveTo(P4)
                                    if hum.MoveDirection.Magnitude > 0 then hum.Jump = true end
                                else
                                    State.CurrentTargetStr = "[Obby 2] -> Đóng Mây Lao Vào Đích"
                                    obbyWalkOnCloud(finalTargetPos, finalTargetPos.Y, 2.0)
                                end
                            end
                        end
                    else
                        State.Obby1PlatformReached = false

                        local function processLobbyMovement(targetPos, targetInstance, labelPrefix, isItemTarget)
                            if State.LastTarget ~= targetInstance then
                                State.LastTarget = targetInstance
                                State.LobbyStuckCount = 0
                                State.RawStuckPos = root.Position
                                State.RawStuckTick = os.clock()
                            end
                            
                            State.CurrentTargetStr = labelPrefix
                            if hum.MoveDirection.Magnitude > 0 then hum.Jump = true end 

                            local status, extraData = smartMoveTo(targetPos, targetInstance)
                            
                            if status == "PATH_FAILED" or status == "COOLDOWN" then
                                hum:MoveTo(targetPos)
                                if os.clock() - State.RawStuckTick > 0.5 then
                                    local distXZ = (Vector2.new(root.Position.X, root.Position.Z) - Vector2.new(State.RawStuckPos.X, State.RawStuckPos.Z)).Magnitude
                                    if distXZ < 1.0 then status = "PHYSICAL_STUCK" end
                                    State.RawStuckPos = root.Position; State.RawStuckTick = os.clock()
                                end
                            end

                            if status == "TRIGGER_CLOUD" then
                                State.CurrentTargetStr = labelPrefix .. " (Gọi mây qua rào!)"
                                if State.PlatformLifter then
                                    startLobbyCloudWalker(targetPos, 4.0, targetInstance)
                                elseif isItemTarget then
                                    markBlacklisted(targetInstance)
                                end
                            elseif status == "PHYSICAL_STUCK" or status == "OBSTACLE" then
                                State.LobbyStuckCount = State.LobbyStuckCount + 1
                                
                                if State.LobbyStuckCount >= 3 then
                                    State.CurrentTargetStr = labelPrefix .. " (Lùi 5 stud!)"
                                    local backDir = -root.CFrame.LookVector
                                    local flatDir = Vector3.new(backDir.X, 0, backDir.Z).Unit 
                                    if flatDir.Magnitude > 0 then
                                        hum:MoveTo(root.Position + (flatDir * 5))
                                        task.wait(0.7) 
                                    end
                                    State.LobbyStuckCount = 0 
                                    if isItemTarget then markBlacklisted(targetInstance) end 
                                else
                                    State.CurrentTargetStr = labelPrefix .. " (Đạp mây " .. State.LobbyStuckCount .. "/3)"
                                    if State.PlatformLifter then
                                        startLobbyCloudWalker(targetPos, 3.5, targetInstance)
                                    elseif isItemTarget then
                                        markBlacklisted(targetInstance)
                                    end
                                end
                            elseif status == "SUCCESS" then
                                State.RawStuckPos = root.Position
                                State.RawStuckTick = os.clock()
                            elseif status == "WALL_BLOCKED" then
                                if isItemTarget then markBlacklisted(targetInstance) end
                            end
                        end

                        local itemTarget, itemPos = findTarget()
                        
                        if itemTarget and itemPos then
                            processLobbyMovement(itemPos, itemTarget, "SĂN -> " .. itemTarget.Name, true)
                        else
                            local isEventRunning = EventInProgress and EventInProgress.Value == true
                            local chosenLobbyObby = not isEventRunning and ((State.FarmObby1 and not isStageBlocked(obbyStages[1]) and obbyStages[1]) 
                                                 or (State.FarmObby2 and not isStageBlocked(obbyStages[2]) and obbyStages[2]))
                            
                            if chosenLobbyObby then
                                local startTp = Workspace:FindFirstChild(chosenLobbyObby.StartTpName, true)
                                if startTp then
                                    processLobbyMovement(startTp.Position, startTp, "CỔNG -> " .. chosenLobbyObby.Name, false)
                                end
                            else
                                State.CurrentTargetStr = isEventRunning and "LOBBY -> Đang chạy Event Sao" or "LOBBY -> Trống"
                                hum:MoveTo(myPos + Vector3.new(math.random(-2,2), 0, math.random(-2,2))) 
                            end
                        end
                    end
                end
            else
                local alive, hum, root = safeCheckHumanoid()
                if alive and hum.MoveDirection.Magnitude > 0 then
                    hum:MoveTo(root.Position)
                end
            end
        end
    end)
end

-------------------------------------------------------------------------
-- GIAO DIỆN UI
-------------------------------------------------------------------------
local function createUI()
    if game.CoreGui:FindFirstChild("HubUI") then game.CoreGui.HubUI:Destroy() end
    local guiTarget = player:WaitForChild("PlayerGui")
    pcall(function() local d = Instance.new("ScreenGui", game.CoreGui) d:Destroy() guiTarget = game.CoreGui end)

    local gui = Instance.new("ScreenGui")
    gui.Name = "HubUI"
    gui.ResetOnSpawn = false
    gui.Parent = guiTarget

    local container = Instance.new("Frame", gui)
    container.Size = UDim2.new(0, 140, 0, 185) 
    container.Position = UDim2.new(0, 20, 0, 120)
    container.BackgroundColor3 = Color3.fromRGB(18, 18, 18)
    container.BorderSizePixel = 0
    Instance.new("UICorner", container).CornerRadius = UDim.new(0, 5)

    local function makeBtn(text, y, cb)
        local b = Instance.new("TextButton", container)
        b.Size = UDim2.new(0, 124, 0, 24) 
        b.Position = UDim2.new(0, 8, 0, y)
        b.BackgroundColor3 = Color3.fromRGB(33, 33, 33)
        b.TextColor3 = Color3.fromRGB(245, 245, 245)
        b.Text = text
        b.Font = Enum.Font.SourceSansBold
        b.TextSize = 11
        Instance.new("UICorner", b).CornerRadius = UDim.new(0, 4)
        b.MouseButton1Click:Connect(function() cb(b) end)
        return b
    end

    -- [CẬP NHẬT] Đồng bộ text và màu nền ban đầu hiển thị đúng trạng thái ON khi khởi chạy
    UI_Elements.MasterBtn = makeBtn("BOT ACTIVE: ON", 8, function(self)
        State.BotActive = not State.BotActive
        self.Text = State.BotActive and "BOT ACTIVE: ON" or "BOT ACTIVE: OFF"
        self.BackgroundColor3 = State.BotActive and Color3.fromRGB(26, 107, 54) or Color3.fromRGB(33, 33, 33)
        if not State.BotActive then
            local alive, hum, root = safeCheckHumanoid()
            if alive then hum:MoveTo(root.Position) end
        end
    end)
    UI_Elements.MasterBtn.BackgroundColor3 = Color3.fromRGB(26, 107, 54)

    UI_Elements.ItemBtn = makeBtn("FARM ITEMS: ON", 36, function(self)
        State.FarmItems = not State.FarmItems
        self.Text = State.FarmItems and "FARM ITEMS: ON" or "FARM ITEMS: OFF"
        self.BackgroundColor3 = State.FarmItems and Color3.fromRGB(26, 70, 133) or Color3.fromRGB(33, 33, 33)
    end)
    UI_Elements.ItemBtn.BackgroundColor3 = Color3.fromRGB(26, 70, 133)

    UI_Elements.Obby1Btn = makeBtn("FARM OBBY 1: ON", 64, function(self)
        State.FarmObby1 = not State.FarmObby1
        self.Text = State.FarmObby1 and "FARM OBBY 1: ON" or "FARM OBBY 1: OFF"
        self.BackgroundColor3 = State.FarmObby1 and Color3.fromRGB(112, 34, 130) or Color3.fromRGB(33, 33, 33)
    end)
    UI_Elements.Obby1Btn.BackgroundColor3 = Color3.fromRGB(112, 34, 130)

    UI_Elements.Obby2Btn = makeBtn("FARM OBBY 2: ON", 92, function(self)
        State.FarmObby2 = not State.FarmObby2
        self.Text = State.FarmObby2 and "FARM OBBY 2: ON" or "FARM OBBY 2: OFF"
        self.BackgroundColor3 = State.FarmObby2 and Color3.fromRGB(112, 34, 130) or Color3.fromRGB(33, 33, 33)
    end)
    UI_Elements.Obby2Btn.BackgroundColor3 = Color3.fromRGB(112, 34, 130)

    UI_Elements.LifterBtn = makeBtn("PLATFORM LIFTER: ON", 120, function(self)
        State.PlatformLifter = not State.PlatformLifter
        self.Text = State.PlatformLifter and "PLATFORM LIFTER: ON" or "PLATFORM LIFTER: OFF"
        self.BackgroundColor3 = State.PlatformLifter and Color3.fromRGB(26, 107, 54) or Color3.fromRGB(33, 33, 33)
    end)
    UI_Elements.LifterBtn.BackgroundColor3 = Color3.fromRGB(26, 107, 54)

    makeBtn("MINIMIZE UI", 148, function(self)
        local vis = not UI_Elements.MasterBtn.Visible
        for _, c in ipairs({UI_Elements.MasterBtn, UI_Elements.ItemBtn, UI_Elements.Obby1Btn, UI_Elements.Obby2Btn, UI_Elements.LifterBtn}) do c.Visible = vis end
        self.Text = vis and "MINIMIZE UI" or "EXPAND"
        container.Size = vis and UDim2.new(0, 140, 0, 185) or UDim2.new(0, 140, 0, 38)
        self.Position = vis and UDim2.new(0, 8, 0, 148) or UDim2.new(0, 8, 0, 7)
    end)
end

-------------------------------------------------------------------------
-- RUN ENGINE
-------------------------------------------------------------------------
local function main()
    buildVisualPaths()      
    createUI()              
    startSmartOrchestrator()
end
pcall(main)
