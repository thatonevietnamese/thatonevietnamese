-- auto star and fruits.lua
return function(State)
    local Players = game:GetService("Players")
    local PathfindingService = game:GetService("PathfindingService")
    local Workspace = game:GetService("Workspace")
    local player = Players.LocalPlayer

    local blacklist = {}

    local function isBlacklisted(obj)
        if not obj then return false end
        local expiry = blacklist[obj]
        if not expiry then return false end
        if os.clock() - expiry >= State.BlacklistExpiry then
            blacklist[obj] = nil
            return false
        end
        return true
    end
    local function markBlacklisted(obj)
        if obj then
            blacklist[obj] = os.clock()
        end
    end

    local function getChar()
        local c = player.Character or player.CharacterAdded:Wait()
        local h = c:FindFirstChild("Humanoid")
        local r = c and c:FindFirstChild("HumanoidRootPart")
        return c, h, r
    end

    local function getAgentParams()
        local _, h, _ = getChar()
        if h then
            local radius = math.max(1, math.min(h.HipHeight, 4))
            local height = math.max(4, math.min(h.HipHeight * 2, 8))
            return radius, height
        end
        return 2, 5
    end

    local function pos(obj)
        if not obj then return nil end
        if obj:IsA("BasePart") then return obj.Position end
        if obj:IsA("Model") then
            local pp = obj.PrimaryPart
            if pp and pp:IsA("BasePart") then return pp.Position end
            local bp = obj:FindFirstChildWhichIsA("BasePart", true)
            if bp and bp:IsA("BasePart") then return bp.Position end
        end
        return nil
    end

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

        local fruits = Workspace:FindFirstChild("SpawnedFruits")
        local stars = Workspace:FindFirstChild("EventStars")
        scan(fruits)
        if not closest then scan(stars) end
        return closest, cpos
    end

    local function moveTo(target)
        if not target then return false end
        local c, hum, root = getChar()
        if hum and hum.Health <= 0 then return false end
        if not hum or not root then return false end

        local agentRadius, agentHeight = getAgentParams()
        local pathParams = {
            AgentRadius = agentRadius,
            AgentHeight = agentHeight,
            AgentCanJump = true,
        }

        local okPath, errMsg = pcall(function()
            local path = PathfindingService:CreatePath(pathParams)
            path:ComputeAsync(root.Position, target)
            if path.Status ~= Enum.PathStatus.Success then return false end

            for _, wp in ipairs(path:GetWaypoints()) do
                if not State.BotActive then return false end
                if State.SmartJump and wp.Action == Enum.PathWaypointAction.Jump then
                    hum.Jump = true
                end
                hum:MoveTo(wp.Position)
                local arrived = hum.MoveToFinished:Wait(State.MoveToTimeout)
                if not arrived then return false end
            end
            return true
        end)

        if not okPath then
            warn("[Farmer] Pathfinding pcall error:", errMsg)
            return false
        end
        return okPath
    end

    task.spawn(function()
        print("[Farmer] Bot loaded")
        while true do
            task.wait(0.1)

            if not State.BotActive then
                task.wait(0.5)
            else
                local target, tpos = findTarget()
                if target and tpos then
                    local reached = moveTo(tpos)
                    if not reached and player.Character and player.Character:FindFirstChild("Humanoid") and player.Character.Humanoid.Health > 0 then
                        markBlacklisted(target)
                    end
                else
                    task.wait(State.WaitWhenEmpty)
                end
            end
        end
    end)
end
