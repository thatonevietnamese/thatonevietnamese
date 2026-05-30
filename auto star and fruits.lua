local PathfindingService = game:GetService("PathfindingService")
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local fruitsFolder = Workspace:FindFirstChild("SpawnedFruits")
local starsFolder = Workspace:FindFirstChild("EventStars")

local SAFE_SPEED = 24 
local blacklistedItems = {} 

-- --- CẤU HÌNH TOGGLE ---
local BotActive = true          -- Bấm H để Tắt/Bật Auto Farm
local SmartJumpActive = true    -- Bấm J để Tắt/Bật chế độ Nhảy Thông Minh Chống Kẹt

local function getCharacterComponents()
    local char = player.Character or player.CharacterAdded:Wait()
    local hum = char:WaitForChild("Humanoid", 5)
    local root = char:WaitForChild("HumanoidRootPart", 5)
    if hum then hum.WalkSpeed = SAFE_SPEED end
    return char, hum, root
end

-- NHẢY LIÊN TỤC KHI CÓ MỤC TIÊU (FIX LỖI CONTINUE)
task.spawn(function()
while true do
task.wait(0.2)
    if BotActive and SmartJumpActive then
        local char = player.Character

        if char then
            local humanoid = char:FindFirstChild("Humanoid")
            local rootPart = char:FindFirstChild("HumanoidRootPart")

            if humanoid and rootPart and humanoid.Health > 0 then
                local itemObject, targetPos = findNearestTarget()

                if itemObject and targetPos then
                    local distance = (rootPart.Position - targetPos).Magnitude

                    if distance > 5 then
                        humanoid.Jump = true
                    end
                end
            end
        end
    end
end
end)

local function moveToTarget(targetPosition)
    local _, humanoid, rootPart = getCharacterComponents()
    if not humanoid or not rootPart or humanoid.Health <= 0 then return false end

    local path = PathfindingService:CreatePath({
        AgentRadius = 2,
        AgentHeight = 5,
        AgentCanJump = true
    })

    path:ComputeAsync(rootPart.Position, targetPosition)

    if path.Status == Enum.PathStatus.Success then
        local waypoints = path:GetWaypoints()
        for _, waypoint in ipairs(waypoints) do
            if not BotActive then return false end
            if humanoid.Health <= 0 then return false end
            
            -- Pathfinding gốc vẫn giữ tính năng tự nhảy ở các điểm bắt buộc nếu SmartJump tắt
            if waypoint.Action == Enum.PathWaypointAction.Jump then 
                humanoid.Jump = true 
            end
            
            humanoid:MoveTo(waypoint.Position)
            local arrived = humanoid.MoveToFinished:Wait(1.5)
            if not arrived then return false end
        end
        return true
    end
    return false
end

local function getObjectPosition(obj)
    if obj:IsA("BasePart") then
        return obj.Position
    elseif obj:IsA("Model") then
        if obj.PrimaryPart then
            return obj.PrimaryPart.Position
        else
            local part = obj:FindFirstChildWhichIsA("BasePart", true)
            if part then return part.Position end
        end
    end
    return nil
end

local function findNearestTarget()
    local _, _, rootPart = getCharacterComponents()
    if not rootPart then return nil, nil, nil end
    
    local myPos = rootPart.Position
    local nearestItem = nil
    local nearestPos = nil
    local nearestType = nil
    local shortestDistance = math.huge

    if fruitsFolder then
        for _, fruit in ipairs(fruitsFolder:GetChildren()) do
            if not blacklistedItems[fruit] then
                local pos = getObjectPosition(fruit)
                if pos then
                    local distance = (pos - myPos).Magnitude
                    if distance < shortestDistance then
                        shortestDistance = distance
                        nearestItem = fruit
                        nearestPos = pos
                        nearestType = "Trái Cây 🍎"
                    end
                end
            end
        end
    end

    if nearestItem then
        return nearestItem, nearestPos, nearestType
    end

    if starsFolder then
        for _, star in ipairs(starsFolder:GetChildren()) do
            if not blacklistedItems[star] then
                local pos = getObjectPosition(star)
                if pos then
                    local distance = (pos - myPos).Magnitude
                    if distance < shortestDistance then
                        shortestDistance = distance
                        nearestItem = star
                        nearestPos = pos
                        nearestType = "Sao Sự Kiện ✨"
                    end
                end
            end
        end
    end

    return nearestItem, nearestPos, nearestType
end

local function startUltimateFarmer()
    print("--- Khởi chạy Bot v4.3: Nhảy Thông Minh Chống Kẹt (< 1/2 Vận tốc) ---")
    
    task.spawn(function()
        while true do
            task.wait(180)
            blacklistedItems = {}
            print("--- Đã làm mới danh sách đen chống kẹt ---")
        end
    end)

    while true do
        if BotActive then
            local itemObject, targetPos, itemType = findNearestTarget()

            if itemObject and targetPos then
                print("Mục tiêu GẦN NHẤT - " .. itemType .. ": " .. itemObject.Name)
                local success = moveToTarget(targetPos)
                
                if not success or (itemObject and not itemObject.Parent) then
                    blacklistedItems[itemObject] = true
                end
                task.wait(0.1)
            else
                task.wait(1.5)
            end
        else
            task.wait(1)
        end
    end
end

-- LẮNG NGHE SỰ KIỆN BẤM PHÍM
UserInputService.InputBegan:Connect(function(input, gameProcessedEvent)
    if gameProcessedEvent then return end 
    
    if input.KeyCode == Enum.KeyCode.H then
        BotActive = not BotActive
        print("🤖 Trạng thái Auto Farm: " .. (BotActive and "BẬT" or "TẮT"))
        if not BotActive then
            local _, humanoid, rootPart = getCharacterComponents()
            if humanoid and rootPart then humanoid:MoveTo(rootPart.Position) end
        end
    elseif input.KeyCode == Enum.KeyCode.J then
        SmartJumpActive = not SmartJumpActive
        print("🦘 Trạng thái Smart Jump Chống Kẹt: " .. (SmartJumpActive and "BẬT" or "TẮT"))
    end
end)

task.spawn(startUltimateFarmer)
