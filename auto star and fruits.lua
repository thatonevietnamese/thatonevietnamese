return function(State)

    local Players = game:GetService("Players")
    local PathfindingService = game:GetService("PathfindingService")
    local Workspace = game:GetService("Workspace")

    local player = Players.LocalPlayer

    local fruits = Workspace:FindFirstChild("SpawnedFruits")
    local stars = Workspace:FindFirstChild("EventStars")

    local blacklisted = {}

    ----------------------------------------------------
    local function getChar()
        local c = player.Character or player.CharacterAdded:Wait()
        local h = c:FindFirstChild("Humanoid")
        local r = c:FindFirstChild("HumanoidRootPart")
        return c,h,r
    end

    ----------------------------------------------------
    local function pos(obj)
        if obj:IsA("BasePart") then return obj.Position end
        if obj:IsA("Model") then
            return obj.PrimaryPart and obj.PrimaryPart.Position
                or obj:FindFirstChildWhichIsA("BasePart", true).Position
        end
    end

    ----------------------------------------------------
    local function findTarget()
        local _,_,root = getChar()
        if not root then return end

        local closest, cpos, dist = nil, nil, math.huge

        local function scan(folder)
            if not folder then return end
            for _,v in ipairs(folder:GetChildren()) do
                if not blacklisted[v] then
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

        scan(fruits)
        if not closest then scan(stars) end

        return closest, cpos
    end

    ----------------------------------------------------
    local function moveTo(target)
        local _,hum,root = getChar()
        if not hum or not root then return false end

        local path = PathfindingService:CreatePath({
            AgentRadius = 2,
            AgentHeight = 5,
            AgentCanJump = true
        })

        path:ComputeAsync(root.Position, target)
        if path.Status ~= Enum.PathStatus.Success then
            return false
        end

        for _,wp in ipairs(path:GetWaypoints()) do

            if not State.BotActive then
                return false
            end

            if State.SmartJump and wp.Action == Enum.PathWaypointAction.Jump then
                hum.Jump = true
            end

            hum:MoveTo(wp.Position)

            local ok = hum.MoveToFinished:Wait(1.5)
            if not ok then return false end
        end

        return true
    end

    ----------------------------------------------------
    task.spawn(function()

        print("🤖 HUB BOT LOADED")

        while true do
            task.wait(0.1)

            if not State.BotActive then
                task.wait(0.5)
                continue
            end

            local obj,pos = findTarget()

            if obj and pos then
                local ok = moveTo(pos)

                if not ok or not obj.Parent then
                    blacklisted[obj] = true
                end
            else
                task.wait(1)
            end
        end
    end)

end
