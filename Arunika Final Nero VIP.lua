-- 🛡️ ShieldTeam | NERO - Final Merge (OPTIMIZED)
-- Features:
-- Auto Loop Summit + Manual TP
-- Infinity Jump, ESP Player, Noclip
-- InfinityYield-style Fly (PC & Mobile) with GUI buttons
-- Anti-reset Speed Hack with toggle
-- Fixed Auto Teleport to Player (username + display name support)
-- Fake Title "Admin" (blue) toggle in Special tab
-- Rayfield UI (no key)

-- == Services & Init ==
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local StarterGui = game:GetService("StarterGui")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local running = false
local infJump = false
local espEnabled = false
local noclipEnabled = false

-- State object for better organization
local state = {
    EnableJump = false,
    JumpPower = 50,
    SpeedHack = false,
    WalkSpeed = 16,
    NormalSpeed = 16,
    FlyEnabled = false,
    FlySpeed = 1
}

local tpUsername = ""
local adminTitleEnabled = false

-- Keep refs to cleanup
local espTable = {}
local adminGui = nil
local flyGui, ascendBtn, descendBtn = nil, nil, nil

-- == Checkpoints & Finish ==
local checkpoints = {
    CFrame.new(134.742233, 141.4449, -176.765503, -0.475946844, 0, -0.879474044, 0, 1, 0, 0.879474044, 0, -0.475946844),
    CFrame.new(326.75235, 89.475029, -433.596954),
    CFrame.new(475.196442, 169.611084, -939.119934),
    CFrame.new(929.849731, 133.267303, -626.776672),
    CFrame.new(923.586609, 101.468292, 279.119934),
}
local finishCFrame = CFrame.new(262.496887, 324.952942, 718.184692)

-- == Helpers ==
local function getHumanoidChar(plr)
    if not plr or not plr.Character then return nil end
    return plr.Character:FindFirstChildOfClass("Humanoid") and plr.Character or nil
end

local function jumpOnceForChar(char)
    local h = char and char:FindFirstChildOfClass("Humanoid")
    if h then pcall(function() h:ChangeState(Enum.HumanoidStateType.Jumping) end) end
end

local function safeTeleportCharacterTo(plr, targetCFrame)
    if not (plr and plr.Character) then return end
    local char = plr.Character
    pcall(function()
        if typeof(char.PivotTo) == "function" then
            char:PivotTo(targetCFrame + Vector3.new(0, 2, 0))
        else
            local primary = char.PrimaryPart or char:FindFirstChild("HumanoidRootPart")
            if primary then
                if typeof(char.SetPrimaryPartCFrame) == "function" and char.PrimaryPart then
                    char:SetPrimaryPartCFrame(targetCFrame + Vector3.new(0, 2, 0))
                else
                    primary.CFrame = targetCFrame + Vector3.new(0, 2, 0)
                end
            end
        end
        local hrp = char:FindFirstChild("HumanoidRootPart")
        if hrp and hrp:IsA("BasePart") then
            hrp.AssemblyLinearVelocity = Vector3.zero
            hrp.RotVelocity = Vector3.zero
        end
    end)
    task.wait(0.20)
end

-- == Fixed Player Finding Function ==
local function findPlayerByName(searchName)
    if not searchName or searchName == "" then return nil end
    local lowerSearch = searchName:lower()
    
    -- First try exact username match
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr.Name:lower() == lowerSearch then
            return plr
        end
    end
    
    -- Then try display name match
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr.DisplayName:lower() == lowerSearch then
            return plr
        end
    end
    
    -- Finally try partial matches
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr.Name:lower():find(lowerSearch) or plr.DisplayName:lower():find(lowerSearch) then
            return plr
        end
    end
    
    return nil
end

local function runRouteOnce()
    if not (player and player.Character and player.Character:FindFirstChild("HumanoidRootPart")) then return end
    for _, cf in ipairs(checkpoints) do
        safeTeleportCharacterTo(player, cf)
        if player.Character then jumpOnceForChar(player.Character) end
        task.wait(0.5)
    end
    safeTeleportCharacterTo(player, finishCFrame)
    if player.Character then jumpOnceForChar(player.Character) end
    task.wait(0.3)
    pcall(function()
        if player.Character and player.Character:FindFirstChildOfClass("Humanoid") then
            player.Character:FindFirstChildOfClass("Humanoid").Health = 0
        end
    end)
end

local function loopSummit()
    while running do
        runRouteOnce()
        if not running then break end
        local waited = 0
        while running and waited < 7 do task.wait(0.5); waited = waited + 0.5 end
        if not running then break end
        local t = 0
        while running and (not player.Character or not player.Character:FindFirstChild("HumanoidRootPart")) and t < 40 do
            task.wait(0.5); t = t + 0.5
        end
    end
end

-- == Infinity Jump ==
UserInputService.JumpRequest:Connect(function()
    if infJump and player.Character then
        local h = player.Character:FindFirstChildOfClass("Humanoid")
        if h then pcall(function() h:ChangeState(Enum.HumanoidStateType.Jumping) end) end
    end
end)

-- == ESP Player ==
local function createHighlightFor(plr)
    if not plr or plr == player then return end
    if espTable[plr] and espTable[plr].Highlight and espTable[plr].Highlight.Parent then return end
    local char = plr.Character
    if not char then return end
    local highlight = Instance.new("Highlight")
    highlight.Name = "NERO_ESP"
    highlight.Adornee = char
    highlight.FillTransparency = 0.6
    highlight.FillColor = Color3.fromRGB(255, 60, 60)
    highlight.OutlineColor = Color3.fromRGB(255,255,255)
    highlight.Parent = char
    espTable[plr] = {Highlight = highlight}
end

local function removeHighlightFor(plr)
    if espTable[plr] and espTable[plr].Highlight then
        pcall(function() espTable[plr].Highlight:Destroy() end)
    end
    espTable[plr] = nil
end

local function setESP(state)
    espEnabled = state
    if state then
        for _, plr in ipairs(Players:GetPlayers()) do
            if plr ~= player then
                createHighlightFor(plr)
            end
        end
    else
        for k, _ in pairs(espTable) do removeHighlightFor(k) end
    end
end

Players.PlayerAdded:Connect(function(plr)
    plr.CharacterAdded:Connect(function()
        task.wait(0.8)
        if espEnabled then createHighlightFor(plr) end
    end)
end)
Players.PlayerRemoving:Connect(function(plr) removeHighlightFor(plr) end)

-- == Noclip ==
RunService.Stepped:Connect(function()
    if noclipEnabled and player and player.Character then
        for _, p in ipairs(player.Character:GetDescendants()) do
            if p:IsA("BasePart") then
                p.CanCollide = false
            end
        end
    end
end)

-- === Fly buttons (mobile ascend/descend) ===
local verticalFly = 0
local function removeFlyButtons()
    if flyGui then pcall(function() flyGui:Destroy() end) end
    flyGui, ascendBtn, descendBtn = nil, nil, nil
end

local function createFlyButtons()
    removeFlyButtons()
    flyGui = Instance.new("ScreenGui")
    flyGui.Name = "NERO_FlyGui"
    flyGui.ResetOnSpawn = false
    flyGui.Parent = playerGui

    ascendBtn = Instance.new("TextButton")
    ascendBtn.Name = "AscendBtn"
    ascendBtn.Size = UDim2.new(0, 60, 0, 60)
    ascendBtn.Position = UDim2.new(1, -170, 1, -200)
    ascendBtn.AnchorPoint = Vector2.new(1, 1)
    ascendBtn.BackgroundColor3 = Color3.fromRGB(0, 170, 255)
    ascendBtn.BackgroundTransparency = 0.1
    ascendBtn.Text = "▲"
    ascendBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    ascendBtn.TextScaled = true
    ascendBtn.Font = Enum.Font.SourceSansBold
    ascendBtn.Parent = flyGui
    
    local ascendCorner = Instance.new("UICorner")
    ascendCorner.CornerRadius = UDim.new(0, 10)
    ascendCorner.Parent = ascendBtn
    
    ascendBtn.InputBegan:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.Touch or inp.UserInputType == Enum.UserInputType.MouseButton1 then
            verticalFly = 1
        end
    end)
    
    ascendBtn.InputEnded:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.Touch or inp.UserInputType == Enum.UserInputType.MouseButton1 then
            verticalFly = 0
        end
    end)

    descendBtn = Instance.new("TextButton")
    descendBtn.Name = "DescendBtn"
    descendBtn.Size = UDim2.new(0, 60, 0, 60)
    descendBtn.Position = UDim2.new(1, -170, 1, -130)
    descendBtn.AnchorPoint = Vector2.new(1, 1)
    descendBtn.BackgroundColor3 = Color3.fromRGB(255, 85, 85)
    descendBtn.BackgroundTransparency = 0.1
    descendBtn.Text = "▼"
    descendBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    descendBtn.TextScaled = true
    descendBtn.Font = Enum.Font.SourceSansBold
    descendBtn.Parent = flyGui
    
    local descendCorner = Instance.new("UICorner")
    descendCorner.CornerRadius = UDim.new(0, 10)
    descendCorner.Parent = descendBtn
    
    descendBtn.InputBegan:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.Touch or inp.UserInputType == Enum.UserInputType.MouseButton1 then
            verticalFly = -1
        end
    end)
    
    descendBtn.InputEnded:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.Touch or inp.UserInputType == Enum.UserInputType.MouseButton1 then
            verticalFly = 0
        end
    end)
end

-- === Speed hack (anti-reset) ===
RunService.RenderStepped:Connect(function()
    if player.Character and player.Character:FindFirstChildOfClass("Humanoid") then
        local h = player.Character:FindFirstChildOfClass("Humanoid")
        local hrp = player.Character:FindFirstChild("HumanoidRootPart")
        if h and state.SpeedHack then
            pcall(function() h.WalkSpeed = state.WalkSpeed end)
            if hrp and h.WalkSpeed ~= state.WalkSpeed then
                local moveDir = Vector3.zero
                if h.MoveDirection and h.MoveDirection.Magnitude > 0 then
                    moveDir = h.MoveDirection.Unit
                else
                    moveDir = hrp.CFrame.LookVector
                end
                if moveDir.Magnitude > 0 then
                    hrp.AssemblyLinearVelocity = Vector3.new(moveDir.X * state.WalkSpeed, hrp.AssemblyLinearVelocity.Y, moveDir.Z * state.WalkSpeed)
                end
            end
        elseif h and not state.SpeedHack then
            pcall(function() h.WalkSpeed = state.NormalSpeed end)
        end
    end
end)

-- === InfinityYield-like Fly Module (embedded and adapted) ===
local FlyModule = (function()
    local Players = Players
    local RunService = RunService
    local playerLocal = player
    local IYMouse = playerLocal:GetMouse()

    local function getRoot(char)
        if not char then return nil end
        local rootPart = char:FindFirstChild('HumanoidRootPart') or char:FindFirstChild('Torso') or char:FindFirstChild('UpperTorso')
        return rootPart
    end

    local FLYING = false
    local QEfly = true
    local iyflyspeed = 1
    local vehicleflyspeed = 1

    local flyKeyDown, flyKeyUp
    local mfly1, mfly2

    local function sFLY(vfly)
        repeat task.wait() until playerLocal and playerLocal.Character and playerLocal.Character:FindFirstChildOfClass("Humanoid")
        repeat task.wait() until IYMouse

        if flyKeyDown or flyKeyUp then
            pcall(function()
                if flyKeyDown then flyKeyDown:Disconnect() end
                if flyKeyUp then flyKeyUp:Disconnect() end
            end)
        end

        local T = getRoot(playerLocal.Character)
        if not T then return end
        local CONTROL = {F = 0, B = 0, L = 0, R = 0, Q = 0, E = 0}
        local lCONTROL = {F = 0, B = 0, L = 0, R = 0, Q = 0, E = 0}
        local SPEED = 0

        local function FLY()
            FLYING = true
            local BG = Instance.new('BodyGyro')
            local BV = Instance.new('BodyVelocity')
            BG.P = 9e4
            BG.Parent = T
            BV.Parent = T
            BG.MaxTorque = Vector3.new(9e9, 9e9, 9e9)
            BG.CFrame = T.CFrame
            BV.Velocity = Vector3.new(0, 0, 0)
            BV.MaxForce = Vector3.new(9e9, 9e9, 9e9)
            task.spawn(function()
                repeat task.wait()
                    if not vfly and playerLocal.Character:FindFirstChildOfClass('Humanoid') then
                        pcall(function() playerLocal.Character:FindFirstChildOfClass('Humanoid').PlatformStand = true end)
                    end
                    if CONTROL.L + CONTROL.R ~= 0 or CONTROL.F + CONTROL.B ~= 0 or CONTROL.Q + CONTROL.E ~= 0 then
                        SPEED = 50
                    elseif not (CONTROL.L + CONTROL.R ~= 0 or CONTROL.F + CONTROL.B ~= 0 or CONTROL.Q + CONTROL.E ~= 0) and SPEED ~= 0 then
                        SPEED = 0
                    end
                    if (CONTROL.L + CONTROL.R) ~= 0 or (CONTROL.F + CONTROL.B) ~= 0 or (CONTROL.Q + CONTROL.E) ~= 0 then
                        BV.Velocity = ((workspace.CurrentCamera.CFrame.lookVector * (CONTROL.F + CONTROL.B)) + (workspace.CurrentCamera.CFrame.rightVector * (CONTROL.L + CONTROL.R)) + Vector3.new(0, (CONTROL.Q + CONTROL.E) * 0.2, 0)) * SPEED
                        lCONTROL = {F = CONTROL.F, B = CONTROL.B, L = CONTROL.L, R = CONTROL.R, Q = CONTROL.Q, E = CONTROL.E}
                    elseif (CONTROL.L + CONTROL.R) == 0 and (CONTROL.F + CONTROL.B) == 0 and (CONTROL.Q + CONTROL.E) == 0 and SPEED ~= 0 then
                        BV.Velocity = ((workspace.CurrentCamera.CFrame.lookVector * (lCONTROL.F + lCONTROL.B)) + (workspace.CurrentCamera.CFrame.rightVector * (lCONTROL.L + lCONTROL.R)) + Vector3.new(0, (lCONTROL.Q + lCONTROL.E) * 0.2, 0)) * SPEED
                    else
                        BV.Velocity = Vector3.new(0, 0, 0)
                    end
                    BG.CFrame = workspace.CurrentCamera.CFrame
                until not FLYING
                CONTROL = {F = 0, B = 0, L = 0, R = 0, Q = 0, E = 0}
                lCONTROL = {F = 0, B = 0, L = 0, R = 0, Q = 0, E = 0}
                SPEED = 0
                pcall(function() BG:Destroy() end)
                pcall(function() BV:Destroy() end)
                if playerLocal.Character:FindFirstChildOfClass('Humanoid') then
                    playerLocal.Character:FindFirstChildOfClass('Humanoid').PlatformStand = false
                end
            end)
        end

        flyKeyDown = IYMouse.KeyDown:Connect(function(KEY)
            local key = KEY:lower()
            if key == 'w' then
                CONTROL.F = (vfly and vehicleflyspeed or iyflyspeed)
            elseif key == 's' then
                CONTROL.B = - (vfly and vehicleflyspeed or iyflyspeed)
            elseif key == 'a' then
                CONTROL.L = - (vfly and vehicleflyspeed or iyflyspeed)
            elseif key == 'd' then
                CONTROL.R = (vfly and vehicleflyspeed or iyflyspeed)
            elseif QEfly and key == 'e' then
                CONTROL.Q = (vfly and vehicleflyspeed or iyflyspeed)*2
            elseif QEfly and key == 'q' then
                CONTROL.E = -(vfly and vehicleflyspeed or iyflyspeed)*2
            end
            pcall(function() workspace.CurrentCamera.CameraType = Enum.CameraType.Track end)
        end)

        flyKeyUp = IYMouse.KeyUp:Connect(function(KEY)
            local key = KEY:lower()
            if key == 'w' then
                CONTROL.F = 0
            elseif key == 's' then
                CONTROL.B = 0
            elseif key == 'a' then
                CONTROL.L = 0
            elseif key == 'd' then
                CONTROL.R = 0
            elseif key == 'e' then
                CONTROL.Q = 0
            elseif key == 'q' then
                CONTROL.E = 0
            end
        end)

        FLY()
    end

    local function NOFLY()
        FLYING = false
        pcall(function()
            if flyKeyDown then flyKeyDown:Disconnect() end
            if flyKeyUp then flyKeyUp:Disconnect() end
        end)
        if playerLocal.Character and playerLocal.Character:FindFirstChildOfClass('Humanoid') then
            pcall(function() playerLocal.Character:FindFirstChildOfClass('Humanoid').PlatformStand = false end)
        end
        pcall(function() workspace.CurrentCamera.CameraType = Enum.CameraType.Custom end)
    end

    -- Mobile helpers
    local velocityHandlerName = "_iy_fly_v"
    local gyroHandlerName = "_iy_fly_g"

    local function unmobilefly(speaker)
        pcall(function()
            if not (speaker and speaker.Character) then return end
            local root = getRoot(speaker.Character)
            if root and root:FindFirstChild(velocityHandlerName) then root:FindFirstChild(velocityHandlerName):Destroy() end
            if root and root:FindFirstChild(gyroHandlerName) then root:FindFirstChild(gyroHandlerName):Destroy() end
            if speaker.Character:FindFirstChildWhichIsA("Humanoid") then
                speaker.Character:FindFirstChildWhichIsA("Humanoid").PlatformStand = false
            end
            if mfly1 then mfly1:Disconnect() mfly1 = nil end
            if mfly2 then mfly2:Disconnect() mfly2 = nil end
        end)
    end

    local function mobilefly(speaker, vfly)
        pcall(function() unmobilefly(speaker) end)
        FLYING = true
        if not (speaker and speaker.Character) then return end
        local root = getRoot(speaker.Character)
        if not root then return end
        local camera = workspace.CurrentCamera
        local v3none = Vector3.new()
        local v3zero = Vector3.new(0, 0, 0)
        local v3inf = Vector3.new(9e9, 9e9, 9e9)

        local controlModule = nil
        pcall(function()
            if speaker.PlayerScripts and speaker.PlayerScripts:FindFirstChild("PlayerModule") then
                controlModule = require(speaker.PlayerScripts:WaitForChild("PlayerModule"):WaitForChild("ControlModule"))
            end
        end)

        local bv = Instance.new("BodyVelocity")
        bv.Name = velocityHandlerName
        bv.Parent = root
        bv.MaxForce = v3zero
        bv.Velocity = v3zero

        local bg = Instance.new("BodyGyro")
        bg.Name = gyroHandlerName
        bg.Parent = root
        bg.MaxTorque = v3inf
        bg.P = 1000
        bg.D = 50

        mfly2 = RunService.RenderStepped:Connect(function()
            root = getRoot(speaker.Character)
            camera = workspace.CurrentCamera
            if speaker.Character and speaker.Character:FindFirstChildWhichIsA("Humanoid") and root and root:FindFirstChild(velocityHandlerName) and root:FindFirstChild(gyroHandlerName) then
                local humanoid = speaker.Character:FindFirstChildWhichIsA("Humanoid")
                local VelocityHandler = root:FindFirstChild(velocityHandlerName)
                local GyroHandler = root:FindFirstChild(gyroHandlerName)

                VelocityHandler.MaxForce = v3inf
                GyroHandler.MaxTorque = v3inf
                if not vfly then pcall(function() humanoid.PlatformStand = true end) end
                GyroHandler.CFrame = camera.CFrame
                VelocityHandler.Velocity = v3none

                local direction = Vector3.new()
                if controlModule then
                    local dv = controlModule:GetMoveVector()
                    direction = Vector3.new(dv.X, 0, dv.Z)
                else
                    if humanoid and humanoid.MoveDirection and humanoid.MoveDirection.Magnitude > 0 then
                        direction = Vector3.new(humanoid.MoveDirection.X, 0, humanoid.MoveDirection.Z)
                    end
                end

                if direction.X ~= 0 then
                    VelocityHandler.Velocity = VelocityHandler.Velocity + camera.CFrame.rightVector * (direction.X * ((vfly and vehicleflyspeed or iyflyspeed) * 50))
                end
                if direction.Z ~= 0 then
                    VelocityHandler.Velocity = VelocityHandler.Velocity - camera.CFrame.lookVector * (direction.Z * ((vfly and vehicleflyspeed or iyflyspeed) * 50))
                end
                if verticalFly ~= 0 then
                    VelocityHandler.Velocity = VelocityHandler.Velocity + Vector3.new(0, verticalFly * ((vfly and vehicleflyspeed or iyflyspeed) * 50), 0)
                end
            end
        end)
    end

    return {
        sFLY = sFLY,
        NOFLY = NOFLY,
        mobilefly = mobilefly,
        unmobilefly = unmobilefly,
        setSpeed = function(n) iyflyspeed = n end,
        setVehicleSpeed = function(n) vehicleflyspeed = n end,
    }
end)()

-- Character spawn handler
player.CharacterAdded:Connect(function(char)
    task.wait(0.6)
    -- Re-apply speed settings
    if state.SpeedHack then
        task.wait(0.2)
        if char:FindFirstChildOfClass("Humanoid") then
            char:FindFirstChildOfClass("Humanoid").WalkSpeed = state.WalkSpeed
        end
    end
    -- Re-apply fly if enabled
    if state.FlyEnabled then
        task.wait(0.5)
        if UserInputService.TouchEnabled then
            FlyModule.mobilefly(player, false)
            createFlyButtons()
        else
            FlyModule.sFLY(false)
        end
    end
    -- Re-apply admin title if enabled
    if adminTitleEnabled then
        task.delay(0.1, function()
            if adminTitleEnabled then
                createAdminTitle()
            end
        end)
    end
end)

-- == Fake Admin Title ==
local function removeAdminTitle()
    if adminGui and adminGui.Parent then
        pcall(function() adminGui:Destroy() end)
    end
    adminGui = nil
end

local function createAdminTitle()
    removeAdminTitle()
    if not (player and player.Character) then return end
    local char = player.Character
    local head = char:FindFirstChild("Head")
    if not head then return end

    local billboard = Instance.new("BillboardGui")
    billboard.Name = "NERO_AdminTitle"
    billboard.Adornee = head
    billboard.AlwaysOnTop = true
    billboard.Size = UDim2.new(0, 200, 0, 40)
    billboard.StudsOffset = Vector3.new(0, 2.1, 0)
    billboard.LightInfluence = 0

    local txt = Instance.new("TextLabel")
    txt.Name = "TitleLabel"
    txt.Size = UDim2.new(1, 0, 1, 0)
    txt.BackgroundTransparency = 1
    txt.Text = "Admin"
    txt.TextColor3 = Color3.fromRGB(0, 102, 255) -- blue
    txt.TextStrokeTransparency = 0
    txt.TextScaled = true
    txt.Font = Enum.Font.SourceSansBold
    txt.Parent = billboard

    billboard.Parent = head
    adminGui = billboard
end
-- === Mobile Jump Button ===
local function removeJumpButton()
    if jumpGui then pcall(function() jumpGui:Destroy() end) end
    jumpGui, jumpButton = nil, nil
end

local function createJumpButton()
    removeJumpButton()
    jumpGui = Instance.new("ScreenGui")
    jumpGui.Name = "NERO_JumpGui"
    jumpGui.ResetOnSpawn = false
    jumpGui.Parent = playerGui

    jumpButton = Instance.new("ImageButton")
    jumpButton.Name = "JumpBtn"
    jumpButton.Size = UDim2.new(0, 90, 0, 90)
    jumpButton.Position = UDim2.new(1, -100, 1, -120)
    jumpButton.AnchorPoint = Vector2.new(1, 1)
    jumpButton.BackgroundTransparency = 1
    jumpButton.Image = "rbxassetid://3926305904"
    jumpButton.Parent = jumpGui

    jumpButton.InputBegan:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.Touch or inp.UserInputType == Enum.UserInputType.MouseButton1 then
            local h = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
            if h then
                pcall(function()
                    h.UseJumpPower = true
                    h.JumpPower = state.JumpPower or 50
                    h:ChangeState(Enum.HumanoidStateType.Jumping)
                end)
            end
        end
    end)
end
-- == Rayfield UI ==
local success, Rayfield = pcall(function()
    return loadstring(game:HttpGet('https://sirius.menu/rayfield'))()
end)
if not success or not Rayfield then
    warn("Rayfield failed to load.")
    return
end

local Window = Rayfield:CreateWindow({
    Name = "🛡️ ShieldTeam | NERO",
    LoadingTitle = "ShieldTeam | NERO",
    LoadingSubtitle = "Summit & Main Features",
    ConfigurationSaving = { Enabled = false }
})

-- Auto Summit Tab
local AutoTab = Window:CreateTab("Auto Summit", 4483362458)
AutoTab:CreateToggle({
    Name = "Auto Loop Summit",
    CurrentValue = false,
    Callback = function(val)
        running = val
        if val then task.spawn(loopSummit) end
    end
})
AutoTab:CreateButton({ Name = "Force Run Once", Callback = function() task.spawn(runRouteOnce) end })

-- Manual TP Tab
local ManualTab = Window:CreateTab("Manual TP", 4483362458)
for i, cf in ipairs(checkpoints) do
    ManualTab:CreateButton({
        Name = "Teleport CP"..i,
        Callback = function()
            safeTeleportCharacterTo(player, cf)
        end
    })
end
ManualTab:CreateButton({ Name = "Teleport Finish", Callback = function() safeTeleportCharacterTo(player, finishCFrame) end })

-- Main Features Tab
local MainTab = Window:CreateTab("Main", 4483362458)
MainTab:CreateToggle({
    Name = "Enable Jump (Mobile)",
    CurrentValue = state.EnableJump,
    Callback = function(v)
        state.EnableJump = v
        if v then 
            createJumpButton() 
        else 
            removeJumpButton() 
        end
        saveConfig() -- Note: saveConfig() belum ada di script ini
    end
})

-- LOKASI 4: Jump Power Input (Baris 668-684)
MainTab:CreateInput({
    Name = "Jump Power (number)",
    PlaceholderText = tostring(state.JumpPower),
    Callback = function(val)
        local n = tonumber(val)
        if n and n > 0 then
            state.JumpPower = n
            pcall(function()
                local h = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
                if h then
                    h.UseJumpPower = true
                    h.JumpPower = n
                end
            end)
            Rayfield:Notify({Title = "Jump", Content = "JumpPower set to "..tostring(n), Duration = 2})
        else
            Rayfield:Notify({Title = "Jump", Content = "Input invalid", Duration = 2})
        end
    end
})
MainTab:CreateToggle({ Name = "Infinity Jump", CurrentValue = false, Callback = function(v) infJump = v end })
MainTab:CreateToggle({ Name = "ESP Player", CurrentValue = false, Callback = function(v) setESP(v) end })
MainTab:CreateToggle({ Name = "Noclip", CurrentValue = false, Callback = function(v) noclipEnabled = v end })

-- Special Tab
local SpecialTab = Window:CreateTab("Special", 4483362458)

-- Fly System UI
SpecialTab:CreateInput({
    Name = "Fly Speed",
    PlaceholderText = "e.g. 1",
    Callback = function(val)
        local n = tonumber(val)
        if n and n > 0 then
            state.FlySpeed = n
            FlyModule.setSpeed(n)
        end
    end
})

SpecialTab:CreateToggle({
    Name = "Fly Mode",
    CurrentValue = false,
    Callback = function(v)
        state.FlyEnabled = v
        if v then
            FlyModule.setSpeed(state.FlySpeed)
            if UserInputService.TouchEnabled then
                FlyModule.mobilefly(player, false)
                createFlyButtons()
            else
                FlyModule.sFLY(false)
            end
            Rayfield:Notify({Title="Fly", Content="Fly mode enabled", Duration=2})
        else
            if UserInputService.TouchEnabled then
                FlyModule.unmobilefly(player)
                removeFlyButtons()
            else
                FlyModule.NOFLY()
            end
            Rayfield:Notify({Title="Fly", Content="Fly mode disabled", Duration=2})
        end
    end
})

-- Speed Hack System UI

SpecialTab:CreateInput({
    Name = "Speed Hack Value",
    PlaceholderText = "e.g. 100",
    Callback = function(val)
        local n = tonumber(val)
        if n and n > 0 then
            state.WalkSpeed = n
            if state.SpeedHack and player.Character and player.Character:FindFirstChildOfClass("Humanoid") then
                player.Character:FindFirstChildOfClass("Humanoid").WalkSpeed = n
            end
        end
    end
})

SpecialTab:CreateToggle({
    Name = "Speed Hack (Anti-Reset)",
    CurrentValue = false,
    Callback = function(v)
        state.SpeedHack = v
        if v then
            Rayfield:Notify({Title="Speed Hack", Content="Speed hack enabled: " .. state.WalkSpeed, Duration=2})
        else
            Rayfield:Notify({Title="Speed Hack", Content="Speed hack disabled", Duration=2})
        end
    end
})

-- Fixed Player Teleport UI
SpecialTab:CreateInput({
    Name = "Teleport to Player",
    PlaceholderText = "Username or Display Name",
    Callback = function(text) tpUsername = text end
})

SpecialTab:CreateButton({
    Name = "Go To Player",
    Callback = function()
        local targetPlayer = findPlayerByName(tpUsername)
        if targetPlayer and targetPlayer.Character and targetPlayer.Character:FindFirstChild("HumanoidRootPart") then
            safeTeleportCharacterTo(player, targetPlayer.Character.HumanoidRootPart.CFrame)
            Rayfield:Notify({
                Title="Teleport Success", 
                Content="Teleported to " .. targetPlayer.DisplayName .. " (@" .. targetPlayer.Name .. ")", 
                Duration=3
            })
        else
            Rayfield:Notify({
                Title="Teleport Failed", 
                Content="Player '" .. tpUsername .. "' not found or not spawned", 
                Duration=3
            })
        end
    end
})

-- Fake Title Admin toggle (blue)
SpecialTab:CreateToggle({
    Name = "Fake Title: Admin (Blue)",
    CurrentValue = false,
    Callback = function(v)
        adminTitleEnabled = v
        if v then
            createAdminTitle()
            Rayfield:Notify({Title="Admin Title", Content="Admin title enabled", Duration=2})
        else
            removeAdminTitle()
            Rayfield:Notify({Title="Admin Title", Content="Admin title disabled", Duration=2})
        end
    end
})

-- Cleanup on script end
game:GetService("Players").PlayerRemoving:Connect(function(plr)
    if plr == player then
        FlyModule.NOFLY()
        FlyModule.unmobilefly(player)
        removeFlyButtons()
        removeAdminTitle()
    end
end)

-- Final: ensure initial speed applied
task.delay(1, function()
    if player.Character and player.Character:FindFirstChildOfClass("Humanoid") then
        player.Character:FindFirstChildOfClass("Humanoid").WalkSpeed = state.NormalSpeed
    end
end)