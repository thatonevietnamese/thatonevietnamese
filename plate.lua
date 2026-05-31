local Workspace = game:GetService("Workspace")

-- CẤU HÌNH ĐƯỜNG ĐI SIÊU MỎNG (DÀNH CHO CẢ CHẶNG 1 VÀ 2)
local PATH_WIDTH = 12
local PATH_THICKNESS = 0.1

-- Danh sách tọa độ chuẩn chặng 2 bạn cung cấp
local OBBY2_WAYPOINTS = {
	Vector3.new(731, 136, -1448),
	Vector3.new(730, 136, -1490),
	Vector3.new(729, 143, -1547),
	Vector3.new(738, 139, -1602),
	Vector3.new(734, 145, -1645),
	Vector3.new(719, 151, -1700),
	Vector3.new(723, 154, -1737),
	Vector3.new(751, 171, -1805),
	Vector3.new(764, 173, -1816)
}

local FOLDER_NAME = "Total_Obby_Visual_Path"

-- Xóa folder cũ nếu có để làm sạch map trước khi xây
local oldFolder = Workspace:FindFirstChild(FOLDER_NAME)
if oldFolder then oldFolder:Destroy() task.wait(0.05) end

local folder = Instance.new("Folder")
folder.Name = FOLDER_NAME
folder.Parent = Workspace

------------------------------------------------------------------------
-- HÀM NỐI ĐOẠN ĐƯỜNG THẲNG TRỰC QUAN
------------------------------------------------------------------------
local function drawPathSegment(p1, p2, segmentName)
	local distance = (p1 - p2).Magnitude
	local baseCFrame = CFrame.lookAt(p1, p2) * CFrame.new(0, 0, -distance / 2)
	
	local segment = Instance.new("Part")
	segment.Name = segmentName
	segment.Size = Vector3.new(PATH_WIDTH, PATH_THICKNESS, distance)
	segment.CFrame = baseCFrame
	
	segment.Material = Enum.Material.Neon
	segment.Color = Color3.fromRGB(255, 0, 128) -- Hồng cánh sen nổi bật
	segment.Transparency = 0.3
	segment.Anchored = true
	segment.CanCollide = true
	segment.Parent = folder
end

------------------------------------------------------------------------
-- HÀM TẠO MÂM TRÒN CHO CHẶNG 1
------------------------------------------------------------------------
------------------------------------------------------------------------
-- HÀM TẠO MÂM TRÒN CHO CHẶNG 1 (ĐÃ HẠ THẤP 6 STUDS)
------------------------------------------------------------------------
local function deployObby1Cylinder(startPart, endPart, name)
    local p1 = startPart.Position
    local p2 = endPart.Position
    local radius = (p1 - p2).Magnitude
    
    -- Chỗ này: Lấy trung điểm (Lerp 0.5) rồi trừ đi Vector3.new(0, 6, 0) để hạ độ cao
    local centerPos = p1:Lerp(p2, 0.5) - Vector3.new(0, 6, 0)
    
    local cylinder = Instance.new("Part")
    cylinder.Name = name
    cylinder.Shape = Enum.PartType.Cylinder
    cylinder.Material = Enum.Material.Neon
    cylinder.Color = Color3.fromRGB(255, 0, 128)
    -- Giữ nguyên kích thước nhưng thay đổi CFrame xuống dưới
    cylinder.Size = Vector3.new(PATH_THICKNESS, radius * 2, radius * 2)
    cylinder.CFrame = CFrame.new(centerPos) * CFrame.Angles(0, 0, math.rad(90))
    
    cylinder.Anchored = true
    cylinder.CanCollide = true
    cylinder.Parent = folder
    print("✔️ [Chặng 1] Đã thảm xong mâm tròn, hạ thấp 6 studs!")
end
------------------------------------------------------------------------
-- LUỒNG CHẠY TỔNG HỢP (RÌNH SAO CẢ 2 CHẶNG)
------------------------------------------------------------------------
local function startTotalPathListener()
	print("🚀 --- ĐANG RÌNH ĐỂ XÂY FULL ĐỊA HÌNH 2 CHẶNG CHO BẠN WALKTEST ---")

	-- 🟩 CHẶNG 1: Rình ObbyStar xuất hiện thì trải sàn tròn mỏng
	task.spawn(function()
		while true do
			local obbyStar = Workspace:FindFirstChild("ObbyStar", true)
			local obbyTp2 = Workspace:FindFirstChild("ObbyTp2", true)
			if obbyStar and obbyTp2 and not folder:FindFirstChild("Obby1_ThinFloor") then
				deployObby1Cylinder(obbyTp2, obbyStar, "Obby1_ThinFloor")
			end
			task.wait(0.5)
		end
	end)

	-- 🟩 CHẶNG 2: Xây con đường dốc uốn lượn hạ vị trí gốc 6 studs
	task.spawn(function()
		local obbyTp4 = Workspace:FindFirstChild("ObbyTp4", true)
		local startPoint = nil
		
		if obbyTp4 then
			startPoint = obbyTp4.Position - Vector3.new(0, 6, 0) -- Hạ độ cao Y gốc xuống 6 studs theo ý bạn
		else
			startPoint = OBBY2_WAYPOINTS[1]
		end
		
		-- Nối từ điểm gốc hạ thấp sang Waypoint 1
		drawPathSegment(startPoint, OBBY2_WAYPOINTS[1], "Obby2_Start_Offset")
		
		-- Nối tuần tự chuỗi Waypoint ngoằn ngoèo lên tới đích
		for i = 1, #OBBY2_WAYPOINTS - 1 do
			local p1 = OBBY2_WAYPOINTS[i]
			local p2 = OBBY2_WAYPOINTS[i+1]
			drawPathSegment(p1, p2, "Obby2_Segment_" .. i)
		end
		print("✔️ [Chặng 2] Đã trải xong thảm dốc nghiêng uốn lượn nối Waypoint!")
	end)
end

startTotalPathListener()
