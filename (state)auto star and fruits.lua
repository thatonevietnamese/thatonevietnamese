return function(State)
    local Players = game:GetService("Players")
    local PathfindingService = game:GetService("PathfindingService")
    local Workspace = game:GetService("Workspace")
    local player = Players.LocalPlayer
    local RunService = game:GetService("RunService")

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
        local c = player.Character
        if not c then
            c = player.CharacterAdded:Wait()
        end
        local h = c:FindFirstChild("Humanoid")
        local r = c:FindFirstChild("HumanoidRootPart")
        return c, h, r
    end

    local function getAgentParams()
        local _, h, _ = getChar()
        if h then
            local radius = math.max(1, math.min(h.HipHeight or 2, 4))
            local height = math.max(4, math.min((h.HipHeight or 2) * 2, 8))
            return radius, height
        end
        return 2, 5
    end

    local function safeGetPos(obj)
        if not obj then return nil end
        if obj:IsA("BasePart") then
            return obj.Position
        end
        if obj:IsA("Model") then
            local pp = obj.PrimaryPart
            if pp and pp:IsA("BasePart") then
                return pp.Position
            end
            local bp = obj:FindFirstChildWhichIsA("BasePart", true)
            if bp then
                return bp.Position
            end
        end
        return nil
    end

    local function findTarget()
        local ok, result = pcall(function()
            local c, h, root = getChar()
            if not root or not h then
                return nil, nil
            end

            local closest, cpos, dist = nil, nil, math.huge

            local function scan(folder)
                if not folder then return end
                for _, v in ipairs(folder:GetChildren()) do
                    if not isBlacklisted(v) then
                        local p = safeGetPos(v)
                        if p then
                            local okPos, d = pcall(function()
                                return (p - root.Position).Magnitude
                            end)
                            if okPos and d < dist then
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
        end)
        if not ok then
            return nil, nil
        end
        return result[1], result[2]
    end

    local function moveTo(target)
        if not target then return false end

        local okCheck, c, h, root = pcall(getChar)
        if not okCheck or not h or not root then
            return false
        end
        if h.Health <= 0 then
            return false
        end

        local okR, agentRadius = pcall(function()
            local r, _ = getAgentParams()
            return r
        end)
        local okH, agentHeight = pcall(function()
            local _, hgt = getAgentParams()
            return hgt
        end)
        if not okR or not okH then
            return false
        end

        local okPath, reached = pcall(function()
            local path = PathfindingService:CreatePath({
                AgentRadius = agentRadius,
                AgentHeight = agentHeight,
                AgentCanJump = true,
            })
            path:ComputeAsync(root.Position, target)
            if path.Status ~= Enum.PathStatus.Success then
                return false
            end

            for _, wp in ipairs(path:GetWaypoints()) do
                if not State.BotActive then
                    return false
                end
                if State.SmartJump and wp.Action == Enum.PathWaypointAction.Jump then
                    h.Jump = true
                end
                h:MoveTo(wp.Position)
                local arrived = h.MoveToFinished:Wait(State.MoveToTimeout)
                if not arrived then
                    return false
                end
            end
            return true
        end)

        if not okPath then
            return false
        end
        return reached
    end

    task.spawn(function()
        print("[Farmer] Bot loaded")
        while true do
            task.wait(0.1)

            if not State.BotActive then
                task.wait(0.5)
            else
                local okBot, target, tpos = pcall(findTarget)
                if okBot and target and tpos then
                    local reached = moveTo(tpos)
                    local okAlive = pcall(function()
                        local ch = player.Character
                        return ch and ch:FindFirstChild("Humanoid") and ch.Humanoid.Health > 0
                    end)
                    if not reached and okAlive then
                        markBlacklisted(target)
                    end
                else
                    task.wait(State.WaitWhenEmpty)
                end
            end
        end
    end)
end
