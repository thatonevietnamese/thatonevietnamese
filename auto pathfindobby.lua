local PathfindingService = game:GetService("PathfindingService")
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")

local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local humanoid = character:WaitForChild("Humanoid")
local rootPart = character:WaitForChild("HumanoidRootPart")

local obbyStages = {
	{
		Name = "Obby 1",
		StartTp = Workspace:WaitForChild("ObbyTp"),
		TargetBlockName = "ObbyTp2",
		TimeBlock = Workspace:WaitForChild("Time1"),
		DestinationName = "ObbyStar"
	},
	{
		Name = "Obby 2",
		StartTp = Workspace:WaitForChild("ObbyTp3"),
		TargetBlockName = "ObbyTp4",
		TimeBlock = Workspace:WaitForChild("Time2"),
		DestinationName = "ObbyStar2"
	}
}

local function waitForGameToLoad()
	if not game:IsLoaded() then game.Loaded:Wait() end
	local playerGui = player:FindFirstChild("PlayerGui")
	if playerGui then
		local loadingGui = playerGui:FindFirstChild("Loading") or playerGui:FindFirstChild("LoadingGui") or playerGui:FindFirstChild("Transition")
		if loadingGui and loadingGui.Enabled == true then
			while loadingGui.Enabled == true do task.wait(0.5) end
			task.wait(1)
		end
	end
end

local function pathfindTo(targetPosition)
	waitForGameToLoad()
	local path = PathfindingService:CreatePath({
		AgentRadius = 3,
		AgentHeight = 5,
		AgentCanJump = true,
		WaypointSpacing = 4
	})

	local success, errorMessage = pcall(function()
		path:ComputeAsync(rootPart.Position, targetPosition)
	end)

	if success and path.Status == Enum.PathStatus.Success then
		local waypoints = path:GetWaypoints()
		for _, waypoint in ipairs(waypoints) do
			if humanoid.Health <= 0 then return false end
			waitForGameToLoad()

			if waypoint.Action == Enum.PathWaypointAction.Jump then
				humanoid.Jump = true
			end

			humanoid:MoveTo(waypoint.Position)

			local maxTime = 2.5
			local startTime = os.clock()
			while (rootPart.Position - waypoint.Position).Magnitude > 3.5 do
				task.wait()
				if (os.clock() - startTime) > maxTime or humanoid.Health <= 0 then break end
			end
		end
		return true
	else
		-- Phương án dự phòng nếu Pathfinding lỗi: Đi thẳng trực tiếp bằng MoveTo thuần
		humanoid:MoveTo(targetPosition)
		task.wait(1)
		return false
	end
end

local function startPurePathfind()
	print("🏃 --- BẮT ĐẦU LUỒNG DI CHUYỂN AUTO ---")
	for index, stage in ipairs(obbyStages) do
		print("👉 Đang chạy chặng: " .. stage.Name)
		waitForGameToLoad()

		-- Bước 1: Đến bệ kích hoạt gốc
		print("-> Đi tới: " .. stage.StartTp.Name)
		pathfindTo(stage.StartTp.Position)
		task.wait(0.8)

		-- Bước 2: Chờ bệ ẩn xuất hiện rồi đi vào
		print("-> Đợi bệ đứng: " .. stage.TargetBlockName)
		local targetBlock = Workspace:WaitForChild(stage.TargetBlockName, 7)
		if targetBlock then
			pathfindTo(targetBlock.Position)
			task.wait(0.5)
		end

		-- Bước 3: Chờ Cooldown của game
		while stage.TimeBlock.Transparency < 1 and stage.TimeBlock.CanCollide == true do
			print("-> Đang kẹt Cooldown, đợi mở khóa...")
			task.wait(0.5)
		end

		-- Bước 4: Chờ ngôi sao xuất hiện và chạy vào ăn điểm bằng chân
		print("-> Tìm ngôi sao đích: " .. stage.DestinationName)
		local destination = Workspace:WaitForChild(stage.DestinationName, 7)
		if destination then
			pathfindTo(destination.Position) 
			humanoid:MoveTo(destination.Position)
			task.wait(1) 
			print("🎉 Hoàn thành xong bằng chân: " .. stage.Name)
		else
			warn("❌ Không thấy đích của: " .. stage.Name)
		end

		task.wait(3) -- Nghỉ giữa hiệp
	end
	print("🏃 --- HOÀN THÀNH TOÀN BỘ LUỒNG DI CHUYỂN ---")
end

startPurePathfind()
