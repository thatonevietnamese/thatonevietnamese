local player = game.Players.LocalPlayer
local coreGui = game:GetService("CoreGui") or player:WaitForChild("PlayerGui")

-- ==========================================
-- 1. TỰ ĐỘNG XÓA UI CŨ
-- ==========================================
local uiName = "AutoFlowersUI"
if coreGui:FindFirstChild(uiName) then
    coreGui:FindFirstChild(uiName):Destroy()
end

local isFarming = false

-- ==========================================
-- 2. TẠO GIAO DIỆN (UI)
-- ==========================================
local screenGui = Instance.new("ScreenGui")
screenGui.Name = uiName
screenGui.Parent = coreGui

local frame = Instance.new("Frame")
frame.Size = UDim2.new(0, 220, 0, 110)
frame.Position = UDim2.new(0.5, -110, 0, 20)
frame.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
frame.BorderSizePixel = 0
frame.Active = true
frame.Draggable = true
frame.Parent = screenGui

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, 0, 0, 30)
title.Text = "Auto Collect Flowers"
title.TextColor3 = Color3.fromRGB(255, 255, 255)
title.Font = Enum.Font.SourceSansBold
title.TextSize = 18
title.BackgroundTransparency = 1
title.Parent = frame

local toggleBtn = Instance.new("TextButton")
toggleBtn.Size = UDim2.new(0, 160, 0, 45)
toggleBtn.Position = UDim2.new(0.5, -80, 0, 45)
toggleBtn.Text = "TẮT"
toggleBtn.Font = Enum.Font.SourceSansBold
toggleBtn.TextSize = 20
toggleBtn.BackgroundColor3 = Color3.fromRGB(220, 60, 60) 
toggleBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
toggleBtn.Parent = frame

-- ==========================================
-- 3. HÀM ANTI-SIT (CHỐNG NGỒI LÚC NHẶT ĐỒ)
-- ==========================================
local function toggleAntiSit(state)
    local char = player.Character
    if char then
        local humanoid = char:FindFirstChildOfClass("Humanoid")
        if humanoid then
            if state == true then
                humanoid.Sit = false 
                humanoid:SetStateEnabled(Enum.HumanoidStateType.Seated, false)
            else
                humanoid:SetStateEnabled(Enum.HumanoidStateType.Seated, true)
            end
        end
    end
end

-- ==========================================
-- 4. HÀM XỬ LÝ AUTO COLLECT HOA
-- ==========================================
local function autoCollectLoop()
    while isFarming do
        if not screenGui.Parent then 
            isFarming = false 
            break 
        end
        
        toggleAntiSit(true)

        -- Trỏ thẳng vào thư mục FlowersSpawners
        local folder = workspace:FindFirstChild("LivingGarden") and workspace.LivingGarden:FindFirstChild("FlowersSpawners")
        
        if folder then
            -- Quét các Model bên trong folder
            for _, flowerModel in pairs(folder:GetChildren()) do
                if not isFarming then break end 
                
                if flowerModel:IsA("Model") then
                    -- Tìm ProximityPrompt trực tiếp trong Model
                    local prompt = flowerModel:FindFirstChildWhichIsA("ProximityPrompt", true)
                    
                    if prompt then
                        local char = player.Character
                        if char and char:FindFirstChild("HumanoidRootPart") then
                            
                            -- Dùng GetPivot() để lấy tọa độ của Model hoa, cộng thêm 5 stud để không kẹt đất
                            char.HumanoidRootPart.CFrame = flowerModel:GetPivot() + Vector3.new(0, 5, 0)
                            task.wait(0.5) -- Chờ server đồng bộ vị trí
                            
                            if fireproximityprompt then
                                fireproximityprompt(prompt)
                                task.wait(0.4) -- Chờ một chút trước khi sang cây tiếp theo
                            end
                        end
                    end
                end
            end
        end
        
        task.wait(1)
    end
end

-- ==========================================
-- 5. XỬ LÝ NÚT TOGGLE
-- ==========================================
toggleBtn.MouseButton1Click:Connect(function()
    isFarming = not isFarming 
    
    if isFarming then
        toggleBtn.Text = "ĐANG BẬT"
        toggleBtn.BackgroundColor3 = Color3.fromRGB(60, 200, 60) 
        task.spawn(autoCollectLoop)
    else
        toggleBtn.Text = "TẮT"
        toggleBtn.BackgroundColor3 = Color3.fromRGB(220, 60, 60) 
        toggleAntiSit(false)
    end
end)
