return function(State)

    local PathfindingService = game:GetService("PathfindingService")
    local Players = game:GetService("Players")
    local Workspace = game:GetService("Workspace")

    local player = Players.LocalPlayer
    local fruitsFolder = Workspace:FindFirstChild("SpawnedFruits")
    local starsFolder = Workspace:FindFirstChild("EventStars")

    local SAFE_SPEED = 24
    local blacklistedItems = {}

    ----------------------------------------------------
    -- CHARACTER
    ----------------------------------------------------
    local function getCharacterComponents()
        local char = player.Character or player.CharacterAdded:Wait()
        local hum = char:FindFirstChild("Humanoid")
        local root = char:FindFirstChild("HumanoidRootPart")

        if hum then hum.WalkSpeed = SAFE_SPEED end
        return char, hum, root
    end

    ----------------------------------------------------
    -- POSITION
    ----------------------------------------------------
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

    ----------------------------------------------------
    -- FIND TARGET
    ----------------------------------------------------
    local function findNearestTarget()
        local _, _, root = getCharacterComponents()
        if not root then return nil end

        local myPos = root.Position
        local nearest, nearestPos, shortest = nil, nil, math.huge

        local function scan(folder, label)
            if not folder then return end

            for _, obj in ipairs(folder:GetChildren()) do
                if not blacklistedItems[obj] then
                    local pos = getObjectPosition(obj)
                    if pos then
                        local dist = (pos - myPos).Magnitude
                        if dist < shortest then
                            shortest = dist
                            nearest = obj
                            nearestPos = pos
                        end
                    end
                end
            end
        end

        scan(fruitsFolder)
        if not nearest then scan(starsFolder) end

        return nearest, nearestPos
    end

    ----------------------------------------------------
    -- MOVE
    ----------------------------------------------------
    local function moveToTarget(targetPosition)
        local _, humanoid, root = getCharacterComponents()
        if not humanoid or not root then return false end

        local path = PathfindingService:CreatePath({
            AgentRadius = 2,
            AgentHeight = 5,
            AgentCanJump = true
        })

        path:ComputeAsync(root.Position, targetPosition)

        if path.Status ~= Enum.PathStatus.Success then
            return false
        end

        for _, wp in ipairs(path:GetWaypoints()) do

            if not State.BotActive then
                return false
            end

            if humanoid.Health <= 0 then
                return false
            end

            if State.SmartJump and wp.Action == Enum.PathWaypointAction.Jump then
                humanoid.Jump = true
            end

            humanoid:MoveTo(wp.Position)

            local ok = humanoid.MoveToFinished:Wait(1.5)
            if not ok then return false end
        end

        return true
    end

    ----------------------------------------------------
    -- MAIN LOOP (ONLY ONCE)
    ----------------------------------------------------
    task.spawn(function()

        print("🤖 Bot loaded")

        while true do
            task.wait(0.1)

            if not State.BotActive then
                task.wait(0.5)
                continue
            end

            local item, pos = findNearestTarget()

            if item and pos then
                local success = moveToTarget(pos)

                if not success or not item.Parent then
                    blacklistedItems[item] = true
                end
            else
                task.wait(1)
            end
        end
    end)

end
