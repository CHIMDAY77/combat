-- ==============================================================================
-- 1. CLEANUP & SAFETY (CHỐNG CRASH KHI CHẠY LẠI)
-- ==============================================================================
if getgenv().OxenHub_Loaded then
    -- Nếu script đã chạy, thông báo và dừng lại để tránh lỗi chồng chéo
    game:GetService("StarterGui"):SetCore("SendNotification", {
        Title = "Oxen Hub", Text = "Script is already running!", Duration = 3
    })
    return
end
getgenv().OxenHub_Loaded = true

-- ==============================================================================
-- 2. SETUP UI LIBRARY
-- ==============================================================================
local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

local Window = Rayfield:CreateWindow({
   Name = "Combat Arena (Mobile Final)",
   Icon = 0,
   LoadingTitle = "Oxen-Hub",
   LoadingSubtitle = "Optimized by K2PN",
   Theme = "Default",
   DisableRayfieldPrompts = false,
   DisableBuildWarnings = false,
   ConfigurationSaving = { Enabled = true, FileName = "OxenHub_Mobile_V5" },
   Discord = { Enabled = false, Invite = "", RememberJoins = true },
   KeySystem = false,
})

-- ==============================================================================
-- 3. SERVICES & GLOBAL CONFIG
-- ==============================================================================
local P = game:GetService("Players")
local RS = game:GetService("RunService")
local UIS = game:GetService("UserInputService")
local LP = P.LocalPlayer
local Camera = workspace.CurrentCamera

-- Cấu hình Aim (Đã tinh chỉnh cho Mobile)
_G.AIM_DATA = {
    Enabled = false,
    Part = "Head",
    TeamCheck = true,
    Pred = 0.162,        -- Ping mobile thường cao hơn PC chút (0.16 là đẹp)
    GravPred = 0.015,
    FOV = 130,           -- FOV vừa tầm mắt điện thoại
    Deadzone = 30,       -- Vùng khóa chết
}

-- Cấu hình ESP
_G.ESP_CONFIG = { Enabled = false, Box = true, Name = true, TeamCheck = true }

-- Biến chức năng khác
_G.NoRecoil = false
_G.InfJump = false

-- ==============================================================================
-- 4. CORE AIMBOT (HARD STICKY LOGIC)
-- ==============================================================================
local rayParams = RaycastParams.new()
rayParams.FilterType = Enum.RaycastFilterType.Exclude
rayParams.IgnoreWater = true

-- Visuals: Tối ưu Drawing (Giảm số cạnh để nhẹ máy)
local fovCircle, deadCircle
if Drawing then
    fovCircle = Drawing.new("Circle")
    fovCircle.NumSides = 32 -- Giảm từ 64 xuống 32 (Vẫn tròn nhưng nhẹ)
    fovCircle.Thickness = 1.5
    fovCircle.Color = Color3.new(1, 1, 1)
    fovCircle.Transparency, fovCircle.Filled = 0.8, false
    
    deadCircle = Drawing.new("Circle")
    deadCircle.NumSides = 24 -- Giảm tải tối đa
    deadCircle.Thickness = 1.5
    deadCircle.Color = Color3.new(1, 0, 0)
    deadCircle.Transparency, deadCircle.Filled = 0.8, false
end

local function getTarget()
    local max, target = _G.AIM_DATA.FOV, nil
    local center = Camera.ViewportSize / 2
    
    for _, p in ipairs(P:GetPlayers()) do
        if p ~= LP and p.Character and (not _G.AIM_DATA.TeamCheck or p.Team ~= LP.Team) then
            local h = p.Character:FindFirstChildOfClass("Humanoid")
            local part = p.Character:FindFirstChild(_G.AIM_DATA.Part)
            if h and h.Health > 0 and part then
                local pos, on = Camera:WorldToViewportPoint(part.Position)
                if on then
                    local mag = (Vector2.new(pos.X, pos.Y) - center).Magnitude
                    if mag < max then
                        rayParams.FilterDescendantsInstances = {LP.Character, p.Character}
                        if not workspace:Raycast(Camera.CFrame.Position, part.Position - Camera.CFrame.Position, rayParams) then
                            max, target = mag, p
                        end
                    end
                end
            end
        end
    end
    return target
end

-- Vòng lặp Aim (Được bảo vệ bằng pcall để không bao giờ crash)
RS.RenderStepped:Connect(function()
    pcall(function()
        local center = Camera.ViewportSize / 2
        
        -- Update Visuals
        if fovCircle then 
            fovCircle.Visible = _G.AIM_DATA.Enabled 
            fovCircle.Position, fovCircle.Radius = center, _G.AIM_DATA.FOV
        end
        if deadCircle then 
            deadCircle.Visible = _G.AIM_DATA.Enabled
            deadCircle.Position, deadCircle.Radius = center, _G.AIM_DATA.Deadzone
        end
        
        if not _G.AIM_DATA.Enabled then return end

        local t = getTarget()
        if t and t.Character then
            local part = t.Character:FindFirstChild(_G.AIM_DATA.Part)
            local hrp = t.Character:FindFirstChild("HumanoidRootPart")
            
            if part and hrp then
                -- Prediction 2D+3D
                local predPos = part.Position + (hrp.Velocity * _G.AIM_DATA.Pred)
                if math.abs(hrp.Velocity.Y) > 5 then
                    predPos = predPos + Vector3.new(0, hrp.Velocity.Y * _G.AIM_DATA.GravPred, 0)
                end

                local pos, _ = Camera:WorldToViewportPoint(part.Position)
                local dist = (Vector2.new(pos.X, pos.Y) - center).Magnitude

                -- /// CORE LOGIC: MOBILE HARD LOCK ///
                if dist <= _G.AIM_DATA.Deadzone then
                    -- Vùng Tử Thần: Dính cứng (0 delay)
                    Camera.CFrame = CFrame.new(Camera.CFrame.Position, predPos)
                else
                    -- Vùng Hỗ Trợ: Kéo mạnh (Assist)
                    Camera.CFrame = Camera.CFrame:Lerp(CFrame.new(Camera.CFrame.Position, predPos), 0.45)
                end
            end
        end
    end)
end)

-- ==============================================================================
-- 5. CORE ESP (BILLBOARD GUI - KHÔNG LAG)
-- ==============================================================================
local function AddESP(p)
    local function Setup(c)
        -- WaitForChild có timeout (5s) -> Tránh treo máy
        local root = c:WaitForChild("HumanoidRootPart", 5)
        if not root then return end

        -- Dọn dẹp ESP cũ
        if root:FindFirstChild("OxenESP") then root.OxenESP:Destroy() end

        -- Tạo GUI
        local bb = Instance.new("BillboardGui", root)
        bb.Name = "OxenESP"; bb.Size = UDim2.new(4,0,5.5,0); bb.AlwaysOnTop = true
        
        local frame = Instance.new("Frame", bb)
        frame.Size = UDim2.new(1,0,1,0); frame.BackgroundTransparency = 1
        
        -- Dùng UIStroke thay vì Frame viền -> Siêu nhẹ
        local stroke = Instance.new("UIStroke", frame)
        stroke.Color = Color3.fromRGB(255,0,0); stroke.Thickness = 1.5; stroke.Transparency = 0

        local txt = Instance.new("TextLabel", bb)
        txt.Size = UDim2.new(1,0,0,20); txt.Position = UDim2.new(0,0,-0.25,0)
        txt.BackgroundTransparency = 1; txt.TextColor3 = Color3.new(1,1,1)
        txt.TextStrokeTransparency = 0; txt.TextSize = 11; txt.Font = Enum.Font.GothamBold

        -- Update Loop (Tự hủy khi nhân vật mất)
        local loop
        loop = RS.RenderStepped:Connect(function()
            if not c.Parent or not root.Parent then loop:Disconnect() return end
            
            local show = _G.ESP_CONFIG.Enabled and (not _G.ESP_CONFIG.TeamCheck or p.Team ~= LP.Team)
            bb.Enabled = show
            
            if show then
                local dist = math.floor((Camera.CFrame.Position - root.Position).Magnitude)
                txt.Text = p.Name .. " [" .. dist .. "m]"
                stroke.Enabled = _G.ESP_CONFIG.Box
                txt.Visible = _G.ESP_CONFIG.Name
            end
        end)
    end
    p.CharacterAdded:Connect(Setup)
    if p.Character then Setup(p.Character) end
end
P.PlayerAdded:Connect(AddESP)
for _, v in ipairs(P:GetPlayers()) do if v ~= LP then AddESP(v) end end

-- ==============================================================================
-- 6. UI MENU ELEMENTS
-- ==============================================================================
local MainTab = Window:CreateTab("Combat", nil)
local MainSection = MainTab:CreateSection("Aim & Visuals")

MainTab:CreateToggle({
    Name = "Aim Lock (Sticky Mobile)",
    CurrentValue = false,
    Flag = "Aim",
    Callback = function(v) _G.AIM_DATA.Enabled = v end,
})

MainTab:CreateToggle({
    Name = "ESP Box (Always Visible)",
    CurrentValue = false,
    Flag = "ESP",
    Callback = function(v) _G.ESP_CONFIG.Enabled = v end,
})

MainTab:CreateToggle({
    Name = "No Recoil (Smart)",
    CurrentValue = false,
    Flag = "Recoil",
    Callback = function(v) 
        _G.NoRecoil = v 
        if v and not _G.RecoilLoop then
            local lastRot = Camera.CFrame.Rotation
            _G.RecoilLoop = RS.RenderStepped:Connect(function()
                if not _G.NoRecoil then return end
                -- Logic Smart: Chỉ chống giật khi người chơi KHÔNG vuốt màn hình
                local delta = UIS:GetMouseDelta()
                local curRot = Camera.CFrame.Rotation
                local x,y,z = curRot:ToOrientation()
                local lx,ly,lz = lastRot:ToOrientation()
                
                if math.deg(x-lx) > 0.05 and math.abs(delta.Y) < 2 then
                    Camera.CFrame = CFrame.new(Camera.CFrame.Position) * CFrame.fromOrientation(lx,y,z)
                    lastRot = CFrame.fromOrientation(lx,y,z)
                else
                    lastRot = curRot
                end
            end)
        elseif not v and _G.RecoilLoop then
            _G.RecoilLoop:Disconnect(); _G.RecoilLoop = nil
        end
    end,
})

local MoveSection = MainTab:CreateSection("Movement")

MainTab:CreateSlider({
   Name = "Walkspeed",
   Range = {16, 300}, Increment = 1, CurrentValue = 16,
   Callback = function(v) 
       if LP.Character and LP.Character:FindFirstChild("Humanoid") then 
           LP.Character.Humanoid.WalkSpeed = v 
       end 
   end,
})

MainTab:CreateToggle({
   Name = "Infinite Jump",
   CurrentValue = false,
   Callback = function(v) 
       _G.InfJump = v
       if not _G.IJConn then
           _G.IJConn = UIS.JumpRequest:Connect(function()
               if _G.InfJump and LP.Character then 
                   LP.Character.Humanoid:ChangeState(Enum.HumanoidStateType.Jumping) 
               end
           end)
       end
   end,
})

Rayfield:Notify({
   Title = "Oxen-Hub V5",
   Content = "Optimized for Mobile Performance",
   Duration = 3,
   Image = "rewind",
})