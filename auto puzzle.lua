local Request = game:GetService("ReplicatedStorage")
    :WaitForChild("Remotes")
    :WaitForChild("PuzzleGame")
    :WaitForChild("Request")

print("[V24] Auto Loop Matching Mode")

local function safeRequest(action, data)
    local success, result = pcall(function()
        return Request:InvokeServer(action, data)
    end)
    if success and type(result) == "table" then
        return result
    else
        return { Success = false, Reason = "RequestFailed" }
    end
end

local function checkCooldown()
    local result = safeRequest("Start")
    if not result.Success and result.Reason == "Cooldown" then
        return result.Remaining or 0
    end
    return 0
end

-- 🔁 LOOP VĨNH CỬU
while true do
    local remaining = checkCooldown()

    if remaining > 0 then
        print("⏳ Cooldown:", remaining, "s")
        task.wait(remaining + 0.5)
        continue -- 🔥 KHÔNG return nữa
    end

    print("🚀 Bắt đầu game mới...")

    local Memory = {}
    local Solved = {}

    local FLIP_DELAY = 0.5
    local MISMATCH_HIDE_DELAY = 1

    for i = 1, 16 do
        if Solved[i] then continue end

        local res1 = safeRequest("Flip", {Index = i})
        task.wait(FLIP_DELAY)

        if not res1 or not res1.Success then
            continue
        end

        local img1 = res1.Image
        if not img1 then continue end

        if Memory[img1] and not Solved[Memory[img1]] then
            local j = Memory[img1]

            Request:InvokeServer("Flip", {Index = j})
            task.wait(FLIP_DELAY)

            Solved[i] = true
            Solved[j] = true
            Memory[img1] = nil

            task.wait(1.2)
        else
            local j = nil
            for k = 1, 16 do
                if k ~= i and not Solved[k] then
                    j = k
                    break
                end
            end

            if j then
                local res2 = safeRequest("Flip", {Index = j})
                task.wait(FLIP_DELAY)

                if res2 and res2.Success then
                    Memory[img1] = i
                    if res2.Image then
                        Memory[res2.Image] = j
                    end

                    if not res2.Matched then
                        local delay = res2.HideMismatchDelaySeconds or MISMATCH_HIDE_DELAY
                        task.wait(delay + 0.1)
                    end
                end
            end

            task.wait(0.8)
        end
    end

    print("✅ DONE 1 ROUND")

    -- ⏳ đợi server set cooldown xong rồi loop tiếp
    task.wait(2)
end
