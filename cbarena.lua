local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

local player = Players.LocalPlayer
local camera = workspace.CurrentCamera

local enabled = false
local holdingRightClick = false
local lastMousePos = nil

-- Cài đặt
local sensitivity = 0.4 -- Độ nhạy xoay (tăng nếu thấy xoay chậm)

-- Hàm bật/tắt bằng phím K
UserInputService.InputBegan:Connect(function(input, processed)
    if processed then return end
    if input.KeyCode == Enum.KeyCode.K then
        enabled = not enabled
        if enabled then
            UserInputService.MouseBehavior = Enum.MouseBehavior.Default
            UserInputService.MouseIconEnabled = true
        end
        print("Chế độ Chuột Tự Do: " .. (enabled and "BẬT" or "TẮT"))
    end
end)

-- Theo dõi nhấn chuột phải
UserInputService.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton2 then
        holdingRightClick = true
        lastMousePos = UserInputService:GetMouseLocation()
    end
end)

UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton2 then
        holdingRightClick = false
        lastMousePos = nil
    end
end)

-- Vòng lặp xử lý Camera và Chuột
RunService.RenderStepped:Connect(function()
    if enabled then
        -- Luôn ép hiện chuột dù game có script khóa chuột
        UserInputService.MouseIconEnabled = true
        if not holdingRightClick then
            UserInputService.MouseBehavior = Enum.MouseBehavior.Default
        end

        -- Xử lý xoay camera thủ công khi giữ chuột phải
        if holdingRightClick then
            local currentPos = UserInputService:GetMouseLocation()
            if lastMousePos then
                local delta = currentPos - lastMousePos
                
                -- Xoay Camera dựa trên khoảng cách di chuyển của chuột trên màn hình
                local rotationX = -delta.X * sensitivity
                local rotationY = -delta.Y * sensitivity
                
                -- Áp dụng góc xoay mới
                local currentCFrame = camera.CFrame
                local newRotation = CFrame.Angles(0, math.rad(rotationX), 0) * currentCFrame * CFrame.Angles(math.rad(rotationY), 0, 0)
                
                camera.CFrame = CFrame.new(currentCFrame.Position) * newRotation.Rotation
            end
            lastMousePos = currentPos
        end
    end
end)

-- Xử lý khi hồi sinh
player.CharacterAdded:Connect(function()
    camera = workspace.CurrentCamera
    task.wait(0.5)
    if enabled then
        UserInputService.MouseBehavior = Enum.MouseBehavior.Default
        UserInputService.MouseIconEnabled = true
    end
end)

print("Script FIX XOAY CAMERA đã sẵn sàng. Nhấn K để dùng!")
