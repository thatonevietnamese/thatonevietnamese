return function(State)
    local Players = game:GetService("Players")
    local PathfindingService = game:GetService("PathfindingService")
    local Workspace = game:GetService("Workspace")
    
    local player = Players.LocalPlayer

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

    local function getChar()
        local c = player.Character or player.CharacterAdded:Wait()
        local h = c:FindFirstChildOfClass("Humanoid")
        local r = c:FindFirstChild("HumanoidRootPart")
        return c, h, r
    end

    local function getAgentParams(h)
        if h then
            -- Tính toán mượt theo tỷ lệ nhân vật, không cần pcall rác
            local hip = h.HipHeight > 0 and h.HipHeight or 2
            local radius = math.clamp(hip, 1, 4)
            local height = math.clamp(hip * 2, 4, 8)
            return radius, height
        end
        return 2, 5
    end

    local function safeGetPos(obj)
        if not obj or not obj:IsDescendantOf(game) then return nil end
        if obj:IsA("BasePart") then
            return obj.Position
        elseif obj:IsA("Model") then
            local pp = obj.PrimaryPart
            if pp and pp:IsA("BasePart") then return pp.Position end
            local bp = obj:FindFirstChildWhichIsA("BasePart", true)
            if bp then return bp.Position end
        end
        return nil
    end

    -- ---------- Target Scanner (Sửa lỗi pcall tuple) ----------
    local function findTarget()
        local c, h, root = getChar()
        if not root or not h or h.Health <= 0 then
            return nil, nil
        end

        local closest, cpos, dist = nil, nil, math.huge

        local function scan(folder)
            if not folder then return end
            for _, v in ipairs(folder:GetChildren()) do
                if not isBlacklisted(v) then
                    local p = safeGetPos(v)
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

        -- Quét thư mục trái cây và sao event
        scan(Workspace:FindFirstChild("SpawnedFruits"))
        if not closest then scan(Workspace:FindFirstChild("EventStars")) end

        return closest, cpos
    end

    -- ---------- Movement Core (ChatGPT Minimalist Backbone) ----------
    local function moveTo(targetPos)
        if not targetPos then return false end

        local c, h, root = getChar()
        if not h or not root or h.Health <= 0 then return false end

        local agentRadius, agentHeight = getAgentParams(h)
        
        local path = PathfindingService:CreatePath({
            AgentRadius = agentRadius,
            AgentHeight = agentHeight,
            AgentCanJump = true,
        })
        
        -- Chỉ pcall duy nhất lệnh ComputeAsync của Engine để tránh crash do lỗi nạp map
        local success, _ = pcall(function()
            path:ComputeAsync(root.Position, targetPos)
        end)

        if not success or path.Status ~= Enum.PathStatus.Success then
            return false
        end

        local waypoints = path:GetWaypoints()
        
        for i, wp in ipairs(waypoints) do
            -- Thốt khỏi loop nếu người dùng tắt bot giữa chừng hoặc chết
            local _, currentHum, currentRoot = getChar()
            if not currentHum or not currentRoot or currentHum.Health <= 0 or not State.BotActive then
                return false
            end

            -- SmartJump tinh gọn
            if State.SmartJump then
                if wp.Action == Enum.PathWaypointAction.Jump or currentHum.FloorMaterial == Enum.Material.Air then
                    currentHum.Jump = true
                end
            end

            -- Di chuyển Native không Jitter
            currentHum:MoveTo(wp.Position)
            
            -- Đợi tín hiệu từ Engine C++ (Có Timeout chuẩn)
            local reached = currentHum.MoveToFinished:Wait(State.MoveToTimeout)
            
            -- Cơ chế Unstuck nhẹ nếu hết thời gian mà chưa tới điểm node
            if not reached and i < #waypoints then
                currentHum:MoveTo(currentRoot.Position)
                return false
            end
        end

        return true
    end

    -- ---------- Main Game Loop ----------
    task.spawn(function()
        print("[Farmer] Bot successfully loaded with Clean-Tuple fixes.")
        
        while true do
            task.wait(0.1) -- Giữ nhịp độ quét ổn định

            if not State.BotActive then
                task.wait(0.4)
            else
                -- Chạy an toàn vòng lặp quét tìm target
                local okBot, target, tpos = pcall(findTarget)
                
                if okBot and target and tpos then
                    local reached = moveTo(tpos)
                    
                    -- Nếu không nhặt được và bot vẫn còn sống -> Đưa vào danh sách đen để đổi mục tiêu
                    local _, hum, _ = getChar()
                    if not reached and hum and hum.Health > 0 then
                        markBlacklisted(target)
                    end
                else
                    task.wait(State.WaitWhenEmpty)
                end
            end
        end
    end)
end
