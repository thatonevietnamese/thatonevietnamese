--// SERVICES
local PathfindingService = game:GetService("PathfindingService")
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer

--// FOLDERS (refetched dynamically for robustness)
local function getFolders()
    local fruitsFolder = Workspace:FindFirstChild("SpawnedFruits")
    local starsFolder = Workspace:FindFirstChild("EventStars")
    return fruitsFolder, starsFolder
end

--// SETTINGS
local SAFE_SPEED = 27
local BotActive = true
local SmartJumpActive = true

-- Event system references (with safety for non-Roblox environments)
local v1 = script and script.Parent
local EventTime, EventTitle, EventState, IsInProgress, NextEventAt, EventEndsAt
if v1 then
    EventTime = v1:WaitForChild("EventTime")
    EventTitle = v1:WaitForChild("EventTitle")
    EventState = ReplicatedStorage:WaitForChild("EventState")
    IsInProgress = EventState:WaitForChild("IsInProgress")
    NextEventAt = EventState:WaitForChild("NextEventAt")
    EventEndsAt = EventState:WaitForChild("EventEndsAt")
else
    EventTime = {Text = ""}
    EventTitle = {Visible = false}
    local dummyBool = {Value = false}
    local dummyNum = {Value = 0}
    EventState, IsInProgress, NextEventAt, EventEndsAt = dummyBool, dummyBool, dummyNum, dummyNum
end

-- Stucky detection settings
local STUCK_CHECK_INTERVAL = 3
local STUCK_THRESHOLD_DISTANCE = 20
local STUCK_CONSECUTIVE_CHECKS = 3
local STUCK_JUMP_ATTEMPTS = 5
local blacklistedItems = {}

--// CHARACTER
local function getCharacter()
    local char = player.Character or player.CharacterAdded:Wait()
    local hum = char:WaitForChild("Humanoid", 5)
    local root = char:WaitForChild("HumanoidRootPart", 5)
    if hum then hum.WalkSpeed = SAFE_SPEED end
    return char, hum, root
end

--// GET POSITION
local function getPos(obj)
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

--// FIND TARGET (fruits first, then stars)
local function findNearestTarget()
    local _, _, root = getCharacter()
    if not root then return nil, nil, nil end

    local fruitsFolder, starsFolder = getFolders()
    local myPos = root.Position
    local nearestItem, nearestPos, nearestType
    local shortestDistance = math.huge

    -- Check fruits first when no event
    if not IsInProgress.Value and fruitsFolder then
        for _, obj in ipairs(fruitsFolder:GetChildren()) do
            if not blacklistedItems[obj] then
                local pos = getPos(obj)
                if pos then
                    local dist = (pos - myPos).Magnitude
                    if dist < shortestDistance then
                        shortestDistance = dist
                        nearestItem = obj
                        nearestPos = pos
                        nearestType = "Trái Cây 🍎"
                    end
                end
            end
        end
    end

    -- If found fruit, return early
    if nearestItem then
        return nearestItem, nearestPos, nearestType
    end

    -- Then check stars when event is active
    if IsInProgress.Value and starsFolder then
        for _, obj in ipairs(starsFolder:GetChildren()) do
            if not blacklistedItems[obj] then
                local pos = getPos(obj)
                if pos then
                    local dist = (pos - myPos).Magnitude
                    if dist < shortestDistance then
                        shortestDistance = dist
                        nearestItem = obj
                        nearestPos = pos
                        nearestType = "Sao Sự Kiện ✨"
                    end
                end
            end
        end
    end

    return nearestItem, nearestPos, nearestType
end

--// VARIABLES FOR STUCK DETECTION
local lastPositionForReset = nil
local stuckCounter = 0
local isAttemptingStuckJump = false
local stuckJumpAttempts = 0

--// SMART JUMP (ANTI NGU + ANTI SPAM)
task.spawn(function()
    while true do
        task.wait(0.2)

        if not (BotActive and SmartJumpActive) then continue end

        local char = player.Character
        if not char then continue end

        local humanoid = char:FindFirstChildOfClass("Humanoid")
        local rootPart = char:FindFirstChild("HumanoidRootPart")
        
        if not humanoid or not rootPart or humanoid.Health <= 0 then continue end

        local target, targetPos, _ = findNearestTarget()
        
        if target and targetPos then
            local dist = (rootPart.Position - targetPos).Magnitude
            if dist > 5 and humanoid.FloorMaterial ~= Enum.Material.Air then
                humanoid.Jump = true
            end
        else
            -- Smart jump when no target - detect if stuck
            local velocity = rootPart.AssemblyLinearVelocity
            local currentSpeed = math.sqrt(velocity.X^2 + velocity.Z^2)
            if currentSpeed < (SAFE_SPEED / 2) and humanoid.MoveDirection.Magnitude > 0 then
                humanoid.Jump = true
                task.wait(0.05)
                humanoid.Jump = false
            end
        end
    end
end)

--// STUCK RESET LOOP
task.spawn(function()
    while true do
        task.wait(STUCK_CHECK_INTERVAL)

        if not BotActive then continue end

        local _, _, root = getCharacter()
        if not root then continue end

        local currentPos = root.Position
        if lastPositionForReset then
            local distanceMoved = (currentPos - lastPositionForReset).Magnitude

            if distanceMoved < STUCK_THRESHOLD_DISTANCE then
                stuckCounter = stuckCounter + 1

                if stuckCounter >= STUCK_CONSECUTIVE_CHECKS then
                    if not isAttemptingStuckJump then
                        isAttemptingStuckJump = true
                        stuckJumpAttempts = 0
                        print("--- Stuck detected! Attempting to jump out... ---")
                    end

                    if stuckJumpAttempts < STUCK_JUMP_ATTEMPTS then
                        local _, hum = getCharacter()
                        if hum then
                            hum.Jump = true
                            task.wait(0.1)
                            hum.Jump = false
                            stuckJumpAttempts = stuckJumpAttempts + 1
                            print(string.format("--- Jump attempt %d/%d ---", stuckJumpAttempts, STUCK_JUMP_ATTEMPTS))
                        end
                    else
                        print("--- Jump attempts failed. Performing full reset... ---")
                        local _, hum = getCharacter()
                        if hum then
                            hum.Health = 0
                            print("--- Đã reset nhân vật do bị kẹt lâu ---")
                        end
                        stuckCounter = 0
                        isAttemptingStuckJump = false
                    end
                end
            else
                if stuckCounter > 0 then
                    print(string.format("--- Character moving normally (%.1f studs). Resetting stuck counter. ---", distanceMoved))
                end
                stuckCounter = 0
                isAttemptingStuckJump = false
            end
        end
        lastPositionForReset = currentPos
    end
end)

--// MOVE TO TARGET
local function moveToTarget(targetPosition)
    local _, humanoid, root = getCharacter()
    if not humanoid or not root or humanoid.Health <= 0 then return false end

    local path = PathfindingService:CreatePath({
        AgentRadius = 2,
        AgentHeight = 5,
        AgentCanJump = true
    })

    path:ComputeAsync(root.Position, targetPosition)

    if path.Status ~= Enum.PathStatus.Success then return false end

    for _, wp in ipairs(path:GetWaypoints()) do
        if not BotActive then return false end
        if humanoid.Health <= 0 then return false end

        humanoid:MoveTo(wp.Position)

        if wp.Action == Enum.PathWaypointAction.Jump then
            humanoid.Jump = true
        end

        local reached = humanoid.MoveToFinished:Wait(1.5)
        if not reached then return false end
    end

    return true
end

--// UPDATE EVENT DISPLAY
local function formatTime(seconds)
    local v2 = math.max(0, math.ceil(seconds))
    return string.format("%d:%02d", math.floor(v2 / 60), v2 % 60)
end

local function updateEventDisplay()
    if IsInProgress.Value then
        local timeLeft = math.max(0, math.ceil(math.max(0, EventEndsAt.Value - Workspace:GetServerTimeNow())))
        EventTime.Text = "Event In Progress: " .. formatTime(timeLeft)
        EventTitle.Visible = true
    else
        local v9 = math.max(0, math.ceil(NextEventAt.Value > 0 and NextEventAt.Value - Workspace:GetServerTimeNow() or 300))
        EventTime.Text = "Cooldown: " .. formatTime(v9)
        EventTitle.Visible = false
    end
end

--// BLACKLIST RESET
task.spawn(function()
    while true do
        task.wait(120)
        blacklistedItems = {}
        print("♻️ Reset blacklist")
    end
end)

--// EVENT DISPLAY UPDATE
task.spawn(function()
    while true do
        task.wait(0.25)
        updateEventDisplay()
    end
end)

--// MAIN BOT
local function startBot()
    print("🔥 BOT PRO MAX ĐÃ KHỞI ĐỘNG 🔥")

    while true do
        task.wait(0.1)

        if not BotActive then continue end

        local target, pos, itemType = findNearestTarget()

        if target and pos then
            print("Mục tiêu GẦN NHẤT - " .. itemType .. ": " .. target.Name)
            local success = moveToTarget(pos)

            if not success or not target.Parent then
                blacklistedItems[target] = true
            end
        else
            task.wait(1)
        end
    end
end

--// KEYBINDS
UserInputService.InputBegan:Connect(function(input, gpe)
    if gpe then return end

    if input.KeyCode == Enum.KeyCode.H then
        BotActive = not BotActive
        print("🤖 Bot:", BotActive and "ON" or "OFF")
        if not BotActive then
            local _, humanoid, root = getCharacter()
            if humanoid and root then humanoid:MoveTo(root.Position) end
        end
    elseif input.KeyCode == Enum.KeyCode.J then
        SmartJumpActive = not SmartJumpActive
        print("🦘 SmartJump:", SmartJumpActive and "ON" or "OFF")
    end
end)

task.spawn(startBot)
