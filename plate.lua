local Workspace = game:GetService("Workspace")

------------------------------------------------------------
-- CONFIG
------------------------------------------------------------
local PATH_WIDTH = 12
local EXTRA_PATH_WIDTH = PATH_WIDTH * 2 -- 🔥 CHỈ EXTRA MỞ RỘNG GẤP ĐÔI
local PATH_THICKNESS = 0.1

local OBBY1_CENTER = Vector3.new(21, 99, -1518)
local OBBY1_RADIUS = 150

local FOLDER_NAME = "Total_Obby_Visual_Path"

------------------------------------------------------------
-- CLEAN OLD
------------------------------------------------------------
local old = Workspace:FindFirstChild(FOLDER_NAME)
if old then
	old:Destroy()
	task.wait(0.05)
end

local folder = Instance.new("Folder")
folder.Name = FOLDER_NAME
folder.Parent = Workspace

------------------------------------------------------------
-- DRAW FUNCTION
------------------------------------------------------------
local function drawPath(p1, p2, name, width)
	local dist = (p1 - p2).Magnitude
	local cf = CFrame.lookAt(p1, p2) * CFrame.new(0, 0, -dist / 2)

	local part = Instance.new("Part")
	part.Name = name
	part.Size = Vector3.new(width, PATH_THICKNESS, dist) -- 👈 WIDTH = chiều ngang
	part.CFrame = cf

	part.Material = Enum.Material.Neon
	part.Color = Color3.fromRGB(255, 0, 128)
	part.Transparency = 0.3
	part.Anchored = true
	part.CanCollide = true
	part.Parent = folder
end

------------------------------------------------------------
-- OBBY1 FIXED PLATE (GIỮ NGUYÊN)
------------------------------------------------------------
local function createObby1Plate()
	if folder:FindFirstChild("Obby1_ThinFloor") then return end

	local part = Instance.new("Part")
	part.Name = "Obby1_ThinFloor"
	part.Shape = Enum.PartType.Cylinder
	part.Material = Enum.Material.Neon
	part.Color = Color3.fromRGB(255, 0, 128)
	part.Transparency = 0.3

	part.Anchored = true
	part.CanCollide = true

	part.Size = Vector3.new(0.1, OBBY1_RADIUS * 2, OBBY1_RADIUS * 2)
	part.CFrame = CFrame.new(OBBY1_CENTER) * CFrame.Angles(0, 0, math.rad(90))

	part.Parent = folder
end

------------------------------------------------------------
-- POINTS
------------------------------------------------------------
local P1 = Vector3.new(735.1, 155.5, -1778.2)
local P2 = Vector3.new(747.9, 167.3, -1804.6)

local P3 = Vector3.new(732.3, 132.8, -1446.8)
local P4 = Vector3.new(734.2, 155.5, -1773.5)

------------------------------------------------------------
-- BUILD PATHS (EXTRA X2 WIDTH)
------------------------------------------------------------
local function buildPaths()
	-- EXTRA PATHS (RỘNG GẤP ĐÔI)
	drawPath(P1, P2, "Pair_1", EXTRA_PATH_WIDTH)
	drawPath(P3, P4, "Pair_2", EXTRA_PATH_WIDTH)
end

------------------------------------------------------------
-- START
------------------------------------------------------------
local function startSystem()
	print("🚀 SYSTEM STARTED (EXTRA WIDTH x2)")

	createObby1Plate()
	buildPaths()

	print("✔ DONE: Obby1 + EXTRA PATHS x2 WIDTH")
end

startSystem()
