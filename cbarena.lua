-- Đợi game load hoàn toàn
if not game:IsLoaded() then game.Loaded:Wait() end

local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local player = game:GetService("Players").LocalPlayer
local camera = workspace.CurrentCamera

local enabled = false
local holdingRightClick = false
local lastMousePos = Vector2.new(0,0)
local sensitivity = 0.4 

-- Hàm ép trạng thái chuột
local function setMouseState(state)
    if state then
        UserInputService.MouseBehavior = Enum.MouseBehavior.Default
        UserInputService.MouseIconEnabled = true
    end
end

-- Bật/Tắt bằng phím K
UserInputService.InputBegan:Connect(function(input, gpe)
    if gpe then return end
    if input.KeyCode == Enum.KeyCode.K then
        enabled = not enabled
        setMouseState(enabled)
        print("Hybrid Mouse: " .. (enabled and "ON" or "OFF"))
    end
end)

-- Xử lý nhấn giữ chuột phải
UserInputService.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton2 then
        holdingRightClick = true
        lastMousePos = UserInputService:GetMouseLocation()
    end
end)

UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton2 then
        holdingRightClick = false
    end
end)

-- Vòng lặp chính: Chạy với ưu tiên cao hơn Camera của game
RunService:BindToRenderStep("MouseForceFix", Enum.RenderPriority.Camera.Value + 1, function()
    if not enabled then return end
    
    if holdingRightClick then
        -- Khi xoay: Cho phép khóa tâm tạm thời để lấy Delta chuẩn
        UserInputService.MouseBehavior = Enum.MouseBehavior.LockCenter
        local currentPos = UserInputService:GetMouseLocation()
        local delta = currentPos - lastMousePos
        
        -- Tính toán xoay Camera thủ công
        local newCFrame = camera.CFrame * CFrame.Angles(0, math.rad(-delta.X * sensitivity), 0)
        local verticalRotation = CFrame.Angles(math.rad(-delta.Y * sensitivity), 0, 0)
        
        -- Áp dụng CFrame mới và giữ vị trí cũ
        camera.CFrame = CFrame.new(camera.CFrame.Position) * (newCFrame * verticalRotation).Rotation
        lastMousePos = currentPos
    else
        -- Khi không xoay: Cưỡng bức hiện chuột
        UserInputService.MouseBehavior = Enum.MouseBehavior.Default
        UserInputService.MouseIconEnabled = true
    end
end)

-- Fix khi hồi sinh
player.CharacterAdded:Connect(function()
    camera = workspace.CurrentCamera
    task.wait(0.5)
    setMouseState(enabled)
end)

print("--- SCRIPT MOUSE STABLE LOADED ---")
