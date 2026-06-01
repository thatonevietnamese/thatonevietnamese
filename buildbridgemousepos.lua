local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local mouse = player:GetMouse()
local playerGui = player:WaitForChild("PlayerGui")

-- Variables lưu trữ trạng thái
local point1, point2 = nil, nil
local previewBeam, attach1, attach2 = nil, nil, nil
local builtBridgeParts = {} -- Lưu các part của cây cầu vừa xây để xóa
local isSelecting = false
local selectingPointNum = 1

------------------------------------------------------------------------
-- 1. TẠO GIAO DIỆN GUI (Hoàn toàn bằng Code để bạn tiện sử dụng)
------------------------------------------------------------------------
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "BridgeGui"
screenGui.ResetOnSpawn = false
screenGui.Parent = playerGui

-- Khung chính
local mainFrame = Instance.new("Frame")
mainFrame.Size = UDim2.new(0, 300, 0, 200)
mainFrame.Position = UDim2.new(0, 20, 0.5, -100)
mainFrame.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
mainFrame.BorderSizePixel = 0
mainFrame.Parent = screenGui

local uiCorner = Instance.new("UICorner")
uiCorner.CornerRadius = UDim.new(0, 8)
uiCorner.Parent = mainFrame

-- Tiêu đề
local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, 0, 0, 30)
title.Text = "CÔNG CỤ XÂY CẦU TỰ ĐỘNG"
title.TextColor3 = Color3.fromRGB(255, 255, 255)
title.TextSize = 14
title.Font = Enum.Font.SourceSansBold
title.BackgroundTransparency = 1
title.Parent = mainFrame

-- Text hiển thị tọa độ Điểm 1
local labelP1 = Instance.new("TextLabel")
labelP1.Size = UDim2.new(1, -20, 0, 25)
labelP1.Position = UDim2.new(0, 10, 0, 35)
labelP1.Text = "Điểm 1: Chưa chọn"
labelP1.TextColor3 = Color3.fromRGB(200, 200, 200)
labelP1.TextSize = 13
labelP1.TextXAlignment = Enum.TextXAlignment.Left
labelP1.BackgroundTransparency = 1
labelP1.Parent = mainFrame

-- Text hiển thị tọa độ Điểm 2
local labelP2 = labelP1:Clone()
labelP2.Position = UDim2.new(0, 10, 0, 60)
labelP2.Text = "Điểm 2: Chưa chọn"
labelP2.Parent = mainFrame

-- Nút "Chọn điểm"
local btnSelect = Instance.new("TextButton")
btnSelect.Size = UDim2.new(1, -20, 0, 30)
btnSelect.Position = UDim2.new(0, 10, 0, 95)
btnSelect.Text = "Bắt đầu chọn vị trí (Click chuột)"
btnSelect.BackgroundColor3 = Color3.fromRGB(0, 120, 215)
btnSelect.TextColor3 = Color3.fromRGB(255, 255, 255)
btnSelect.Font = Enum.Font.SourceSansBold
btnSelect.TextSize = 14
btnSelect.Parent = mainFrame
Instance.new("UICorner", btnSelect).CornerRadius = UDim.new(0, 4)

-- Nút "Xây Cầu"
local btnBuild = Instance.new("TextButton")
btnBuild.Size = UDim2.new(0, 135, 0, 35)
btnBuild.Position = UDim2.new(0, 10, 0, 140)
btnBuild.Text = "XÂY CẦU"
btnBuild.BackgroundColor3 = Color3.fromRGB(46, 204, 113)
btnBuild.TextColor3 = Color3.fromRGB(255, 255, 255)
btnBuild.Font = Enum.Font.SourceSansBold
btnBuild.TextSize = 16
btnBuild.Parent = mainFrame
Instance.new("UICorner", btnBuild).CornerRadius = UDim.new(0, 4)

-- Nút "Xóa Cầu"
local btnDelete = btnBuild:Clone()
btnDelete.Position = UDim2.new(0, 155, 0, 140)
btnDelete.Text = "XÓA CẦU TRƯỚC"
btnDelete.BackgroundColor3 = Color3.fromRGB(231, 76, 60)
btnDelete.Parent = mainFrame

------------------------------------------------------------------------
-- 2. HÀM VẼ LINE KHUNG CẦU TRƯỚC (PREVIEW LINE)
------------------------------------------------------------------------
local function updatePreviewLine()
	-- Xóa khung cũ nếu có
	if previewBeam then previewBeam:Destroy() end
	if attach1 then attach1:Destroy() end
	if attach2 then attach2:Destroy() end

	if point1 and point2 then
		-- Tạo các điểm neo cố định trong Terrain hoặc Workspace để treo sợi dây Line
		attach1 = Instance.new("Attachment", Workspace.Terrain)
		attach1.WorldPosition = point1
		
		attach2 = Instance.new("Attachment", Workspace.Terrain)
		attach2.WorldPosition = point2

		-- Dùng Beam để vẽ đường thẳng nối giữa 2 điểm (Không tốn tài nguyên hệ thống)
		previewBeam = Instance.new("Beam")
		previewBeam.Attachment0 = attach1
		previewBeam.Attachment1 = attach2
		previewBeam.Width0 = 0.5
		previewBeam.Width1 = 0.5
		previewBeam.Color = ColorSequence.new(Color3.fromRGB(241, 196, 15)) -- Khung màu vàng laser
		previewBeam.FaceCamera = true
		previewBeam.Transparency = NumberSequence.new(0)
		previewBeam.Parent = Workspace.Terrain
	end
end

------------------------------------------------------------------------
-- 3. HÀM XỬ LÝ CLICK CHUỘT CHỌN ĐỊA ĐIỂM
------------------------------------------------------------------------
btnSelect.MouseButton1Click:Connect(function()
	isSelecting = true
	selectingPointNum = 1
	btnSelect.Text = "Hãy click điểm thứ 1..."
	btnSelect.BackgroundColor3 = Color3.fromRGB(230, 126, 34)
end)

mouse.Button1Down:Connect(function()
	if not isSelecting then return end

	-- Lấy tọa độ không gian 3D nơi chuột đang chỉ vào
	local targetPos = mouse.Hit.Position

	if selectingPointNum == 1 then
		point1 = targetPos
		labelP1.Text = string.format("Điểm 1: X:%.1f, Y:%.1f, Z:%.1f", point1.X, point1.Y, point1.Z)
		selectingPointNum = 2
		btnSelect.Text = "Hãy click điểm thứ 2..."
	elseif selectingPointNum == 2 then
		point2 = targetPos
		labelP2.Text = string.format("Điểm 2: X:%.1f, Y:%.1f, Z:%.1f", point2.X, point2.Y, point2.Z)
		
		-- Vẽ đường Line khung cầu ngay lập tức sau khi có đủ 2 điểm
		updatePreviewLine()
		
		-- Hoàn thành chọn điểm
		isSelecting = false
		btnSelect.Text = "Bắt đầu chọn vị trí (Click chuột)"
		btnSelect.BackgroundColor3 = Color3.fromRGB(0, 120, 215)
	end
end)

------------------------------------------------------------------------
-- 4. HÀM XÂY DỰNG CẦU THẬT NỐI 2 ĐIỂM
------------------------------------------------------------------------
btnBuild.MouseButton1Click:Connect(function()
	if not point1 or not point2 then 
		btnBuild.Text = "CHƯA CHỌN ĐỦ ĐIỂM!"
		task.wait(1)
		btnBuild.Text = "XÂY CẦU"
		return 
	end

	-- Tính toán khoảng cách, hướng và góc quay giữa 2 điểm
	local distance = (point1 - point2).Magnitude
	local bridgeCFrame = CFrame.lookAt(point1, point2) * CFrame.new(0, 0, -distance/2)

	-- Khởi tạo viên gạch cầu thật
	local bridgePart = Instance.new("Part")
	bridgePart.Name = "BuiltBridge"
	bridgePart.Material = Enum.Material.SmoothPlastic
	bridgePart.Color = Color3.fromRGB(180, 180, 180)
	
	-- Độ rộng cầu là 10 studs, độ dày mặt cầu là 1 stud, chiều dài khớp khoảng cách 2 điểm
	bridgePart.Size = Vector3.new(10, 1, distance)
	bridgePart.CFrame = bridgeCFrame
	bridgePart.Anchored = true
	bridgePart.CanCollide = true
	bridgePart.Parent = Workspace

	-- Lưu vào danh sách để có thể xóa sau này
	table.insert(builtBridgeParts, bridgePart)
end)

------------------------------------------------------------------------
-- 5. HÀM XÓA CÂY CẦU VỪA XÂY TRƯỚC ĐÓ
------------------------------------------------------------------------
btnDelete.MouseButton1Click:Connect(function()
	if #builtBridgeParts == 0 then
		btnDelete.Text = "KHÔNG CÓ CẦU ĐỂ XÓA!"
		task.wait(1)
		btnDelete.Text = "XÓA CẦU TRƯỚC"
		return
	end

	-- Lấy cây cầu gần nhất vừa được tạo ra để hủy cấu trúc
	local lastBridge = table.remove(builtBridgeParts, #builtBridgeParts)
	if lastBridge and lastBridge:IsA("Part") then
		lastBridge:Destroy()
	end
end)
