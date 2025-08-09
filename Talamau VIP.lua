-- ShieldTeam | NERO - FINAL (Patched Fly)
-- Features: original features preserved, Fly replaced with InfinityYield-like module
-- (Toggle ON/OFF + numeric Fly Speed input added)

-- === Services ===
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local HttpService = game:GetService("HttpService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- === Config / State (default) ===
local CONFIG_FILE = "ShieldTeam_NERO_config.json"
local state = {
    -- main movement
    EnableJump = true,
    JumpPower = 50,
    SpeedHack = true,
    WalkSpeed = 16,
    -- fly
    FlyEnabled = false,
    FlySpeed = 50,
    -- auto summit
    AutoSummit = false,
    AutoResetAfterFinish = true,
    AutoSummitDelay = 4,
    -- misc
    ESP = false,
    Noclip = false,
    FakeAdmin = false
}

-- === UI refs / internals ===
local Rayfield = nil
local Window = nil

local jumpGui, jumpButton = nil, nil
local flyGui, ascendBtn, descendBtn = nil, nil, nil

local espTable = {}
local noclipConnection = nil
local runningAutoSummit = false

-- === helper: save/load config ===
local function saveConfig()
    local ok, err = pcall(function()
        local encoded = HttpService:JSONEncode(state)
        if writefile then writefile(CONFIG_FILE, encoded) end
    end)
    if not ok then warn("SaveConfig failed:", err) end
end

local function loadConfig()
    if isfile and isfile(CONFIG_FILE) then
        local ok, content = pcall(function() return readfile(CONFIG_FILE) end)
        if ok and content then
            local success, decoded = pcall(function() return HttpService:JSONDecode(content) end)
            if success and type(decoded) == "table" then
                for k,v in pairs(decoded) do state[k] = v end
            end
        end
    end
end

pcall(loadConfig)

-- === utilities ===
local function waitForCharacter()
    local char = player.Character or player.CharacterAdded:Wait()
    repeat task.wait() until char:FindFirstChild("HumanoidRootPart")
    return char
end

local function preventFallDeath()
    local humanoid = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
    if humanoid then
        pcall(function()
            humanoid:SetStateEnabled(Enum.HumanoidStateType.FallingDown, false)
            humanoid:SetStateEnabled(Enum.HumanoidStateType.Ragdoll, false)
        end)
    end
end

-- === noclip ===
local function enableNoclipLoop()
    if noclipConnection then return end
    noclipConnection = RunService.Stepped:Connect(function()
        if state.Noclip and player.Character then
            for _, part in pairs(player.Character:GetDescendants()) do
                if part:IsA("BasePart") then
                    pcall(function() part.CanCollide = false end)
                end
            end
        end
    end)
end

local function disableNoclipLoop()
    if noclipConnection then
        noclipConnection:Disconnect()
        noclipConnection = nil
    end
end

-- === ESP ===
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

local function setESP(v)
    state.ESP = v
    if v then
        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= player then createHighlightFor(p) end
        end
    else
        for k,_ in pairs(espTable) do removeHighlightFor(k) end
    end
    saveConfig()
end

Players.PlayerAdded:Connect(function(plr)
    plr.CharacterAdded:Connect(function()
        task.wait(0.8)
        if state.ESP then createHighlightFor(plr) end
    end)
end)
Players.PlayerRemoving:Connect(function(plr)
    removeHighlightFor(plr)
end)

-- === Fake Admin Title ===
local adminGui = nil
local function removeAdminTitle()
    if adminGui and adminGui.Parent then pcall(function() adminGui:Destroy() end) end
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
    txt.TextColor3 = Color3.fromRGB(0, 102, 255)
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
    ascendBtn.BackgroundTransparency = 0.1
    ascendBtn.Text = "▲"
    ascendBtn.TextScaled = true
    ascendBtn.Parent = flyGui
    ascendBtn.InputBegan:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.Touch or inp.UserInputType == Enum.UserInputType.MouseButton1 then
            verticalFly = 1
            task.delay(0.25, function() verticalFly = 0 end)
        end
    end)

    descendBtn = Instance.new("TextButton")
    descendBtn.Name = "DescendBtn"
    descendBtn.Size = UDim2.new(0, 60, 0, 60)
    descendBtn.Position = UDim2.new(1, -170, 1, -130)
    descendBtn.AnchorPoint = Vector2.new(1, 1)
    descendBtn.BackgroundTransparency = 0.1
    descendBtn.Text = "▼"
    descendBtn.TextScaled = true
    descendBtn.Parent = flyGui
    descendBtn.InputBegan:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.Touch or inp.UserInputType == Enum.UserInputType.MouseButton1 then
            verticalFly = -1
            task.delay(0.25, function() verticalFly = 0 end)
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
        end
    end
end)

-- === InfinityYield-like Fly Module (embedded and adapted) ===
-- This module provides sFLY (desktop), NOFLY, mobilefly/unmobilefly, and setSpeed setters.
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
            -- flipped sign here fixes forward/backward inversion
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

-- === Checkpoints (default Gunung Talamau) - editable ===
local checkpoints = {
    Vector3.new(-428.45752, 156.676239, -1668.62842), -- CP1
    Vector3.new(-254.988724, 125.26165, -609.324341), -- CP2
    Vector3.new(-294.946564, 500.852173, -114.75988), -- CP3
    Vector3.new(-805.197937, 797.936096, -155.540176), -- CP4
    Vector3.new(-823.335876, 895.877441, 193.117859), -- CP5
    Vector3.new(-655.288391, 1124.08484, 282.430511),  -- CP6 (summit)
}

local autoFlySpeed = 100
local function flyTo(pos)
    local char = player.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if not char or not hrp then return end
    local start = hrp.Position
    local distance = (start - pos).Magnitude
    local duration = math.max(0.15, distance / autoFlySpeed)
    local startTime = tick()
    while tick() - startTime < duration and state.AutoSummit and hrp and hrp.Parent do
        local t = (tick() - startTime) / duration
        local target = start:Lerp(pos, t)
        if hrp and hrp.Parent then hrp.CFrame = CFrame.new(target) else return end
        task.wait()
    end
    if hrp and hrp.Parent then hrp.CFrame = CFrame.new(pos) end
end

local function autoSummitLoop()
    state.AutoSummit = true
    runningAutoSummit = true
    while state.AutoSummit and runningAutoSummit do
        player.Character = waitForCharacter()
        local hrp = player.Character:WaitForChild("HumanoidRootPart")
        enableNoclipLoop()
        preventFallDeath()
        for i = 1, 5 do
            if not state.AutoSummit then break end
            flyTo(checkpoints[i])
            task.wait(state.AutoSummitDelay or 4)
        end
        if not state.AutoSummit then break end
        disableNoclipLoop()
        task.wait(1)
        if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
            player.Character.HumanoidRootPart.CFrame = CFrame.new(checkpoints[6])
        end
        for i = 1, 80 do
            if not state.AutoSummit then break end
            task.wait(0.1)
        end
        if state.AutoResetAfterFinish and player.Character then
            pcall(function()
                local hum = player.Character:FindFirstChildOfClass("Humanoid")
                if hum then hum.Health = 0 else player.Character:BreakJoints() end
            end)
        else
            if player.Character then pcall(function() player.Character:BreakJoints() end) end
        end
        repeat task.wait() until player.Character and player.Character:FindFirstChild("HumanoidRootPart")
        task.wait(6)
    end
    runningAutoSummit = false
end

-- === Manual teleport ===
local function teleportToCheckpoint(idx)
    if checkpoints[idx] and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
        player.Character.HumanoidRootPart.CFrame = CFrame.new(checkpoints[idx])
    end
end

local function teleportToVector(v3)
    if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
        player.Character.HumanoidRootPart.CFrame = CFrame.new(v3)
    end
end

-- Fungsi cari player berdasarkan username atau display name
local function findPlayerByNameOrDisplay(query)
    query = string.lower(query)
    for _, plr in ipairs(Players:GetPlayers()) do
        if string.lower(plr.Name) == query or string.lower(plr.DisplayName) == query then
            return plr
        end
    end
    return nil
end

-- Fungsi teleport ke player (fix tanpa harus render dulu)
local function teleportToPlayer(name)
    local target = findPlayerByNameOrDisplay(name)
    if not target then
        return false, "Player not found"
    end

    -- Pastikan target punya karakter
    if not target.Character then
        target.CharacterAdded:Wait() -- tunggu spawn sekali
    end
    local targetHRP = target.Character:WaitForChild("HumanoidRootPart", 5)
    if not targetHRP then
        return false, "Target has no HumanoidRootPart"
    end

    -- Pastikan local player juga punya karakter
    if not player.Character then
        player.CharacterAdded:Wait()
    end
    local myHRP = player.Character:WaitForChild("HumanoidRootPart", 5)
    if not myHRP then
        return false, "You have no HumanoidRootPart"
    end

    -- Teleport langsung
    myHRP.CFrame = targetHRP.CFrame
    return true, "Teleported to " .. target.Name
end

-- === Rayfield load & UI ===
local ok, lib = pcall(function()
    return loadstring(game:HttpGet("https://sirius.menu/rayfield"))()
end)
if not ok or not lib then
    warn("Rayfield failed to load.")
    return
end
Rayfield = lib

Window = Rayfield:CreateWindow({
    Name = "🛡️ ShieldTeam | NERO",
    LoadingTitle = "ShieldTeam | NERO",
    LoadingSubtitle = "Summit & Mobile Controls",
    ConfigurationSaving = { Enabled = false }
})

-- Tabs
local MainTab = Window:CreateTab("Main", 4483362458)
local AutoTab = Window:CreateTab("Auto Summit", 4483362458)
local ManualTab = Window:CreateTab("Manual TP", 4483362458)
local SpesialTab = Window:CreateTab("Spesial", 4483362458)

-- === Main Tab ===
MainTab:CreateToggle({
    Name = "Enable Jump (Mobile)",
    CurrentValue = state.EnableJump,
    Callback = function(v)
        state.EnableJump = v
        if v then createJumpButton() else removeJumpButton() end
        saveConfig()
    end
})

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
            saveConfig()
            Rayfield:Notify({Title = "Jump", Content = "JumpPower set to "..tostring(n), Duration = 2})
        else
            Rayfield:Notify({Title = "Jump", Content = "Input invalid", Duration = 2})
        end
    end
})

MainTab:CreateToggle({
    Name = "Speed Hack (WalkSpeed)",
    CurrentValue = state.SpeedHack,
    Callback = function(v)
        state.SpeedHack = v
        saveConfig()
    end
})

MainTab:CreateInput({
    Name = "Walk Speed (number)",
    PlaceholderText = tostring(state.WalkSpeed),
    Callback = function(val)
        local n = tonumber(val)
        if n and n > 0 then
            state.WalkSpeed = n
            pcall(function()
                local h = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
                if h and state.SpeedHack then h.WalkSpeed = n end
            end)
            saveConfig()
            Rayfield:Notify({Title="WalkSpeed", Content="Set to "..tostring(n), Duration=2})
        else
            Rayfield:Notify({Title="WalkSpeed", Content="Input invalid", Duration=2})
        end
    end
})

-- === Fly Toggle integration (replaces previous fly loop) ===
MainTab:CreateToggle({
    Name = "Fly (InfiniteYield-like, mobile joystick compatible)",
    CurrentValue = state.FlyEnabled,
    Callback = function(v)
        state.FlyEnabled = v
        saveConfig()
        if v then
            -- create mobile buttons regardless (safe)
            pcall(createFlyButtons)
            -- update module speed (set multiplier)
            pcall(function() FlyModule.setSpeed((state.FlySpeed or 50)/50) FlyModule.setVehicleSpeed((state.FlySpeed or 50)/50) end)
            -- enable appropriate fly implementation
            if UserInputService.TouchEnabled then
                pcall(function() FlyModule.mobilefly(player, false) end)
            else
                pcall(function() FlyModule.sFLY(false) end)
            end
            Rayfield:Notify({Title="Fly", Content="Fly enabled", Duration=2})
        else
            removeFlyButtons()
            pcall(function() FlyModule.NOFLY() FlyModule.unmobilefly(player) end)
            Rayfield:Notify({Title="Fly", Content="Fly disabled", Duration=2})
        end
    end
})

MainTab:CreateInput({
    Name = "Fly Speed (number)",
    PlaceholderText = tostring(state.FlySpeed),
    Callback = function(val)
        local n = tonumber(val)
        if n and n > 0 then
            state.FlySpeed = n
            saveConfig()
            -- update module speed (scale to module's expected base)
            pcall(function() FlyModule.setSpeed((n or 50)/50) FlyModule.setVehicleSpeed((n or 50)/50) end)
            Rayfield:Notify({Title="FlySpeed", Content="Set to "..tostring(n), Duration=2})
        else
            Rayfield:Notify({Title="FlySpeed", Content="Input invalid", Duration=2})
        end
    end
})

-- === Auto Summit Tab ===
AutoTab:CreateToggle({
    Name = "Auto Loop Summit",
    CurrentValue = state.AutoSummit,
    Callback = function(v)
        state.AutoSummit = v
        if v and not runningAutoSummit then
            task.spawn(autoSummitLoop)
            Rayfield:Notify({Title="AutoSummit", Content="Started", Duration=2})
        else
            state.AutoSummit = false
            Rayfield:Notify({Title="AutoSummit", Content="Stopped", Duration=2})
        end
        saveConfig()
    end
})

AutoTab:CreateInput({
    Name = "Delay between CP (seconds)",
    PlaceholderText = tostring(state.AutoSummitDelay),
    Callback = function(val)
        local n = tonumber(val)
        if n and n > 0 then
            state.AutoSummitDelay = n
            saveConfig()
            Rayfield:Notify({Title="AutoSummit", Content="Delay set to "..tostring(n), Duration=2})
        else
            Rayfield:Notify({Title="AutoSummit", Content="Invalid", Duration=2})
        end
    end
})

AutoTab:CreateToggle({
    Name = "Auto Reset After Finish",
    CurrentValue = state.AutoResetAfterFinish,
    Callback = function(v) state.AutoResetAfterFinish = v; saveConfig() end
})

-- === Manual TP Tab ===
for i = 1, #checkpoints do
    local idx = i
    ManualTab:CreateButton({
        Name = "Teleport CP"..idx,
        Callback = function() teleportToCheckpoint(idx) end
    })
end

ManualTab:CreateInput({
    Name = "Custom TP X,Y,Z (comma)",
    PlaceholderText = "e.g. 0,10,0",
    Callback = function(txt)
        local x,y,z = txt:match("%s*([%-?%d%.]+)%s*,%s*([%-?%d%.]+)%s*,%s*([%-?%d%.]+)%s*")
        if x and y and z then
            teleportToVector(Vector3.new(tonumber(x), tonumber(y), tonumber(z)))
            Rayfield:Notify({Title="Teleport", Content="Teleported to custom pos.", Duration=2})
        else
            Rayfield:Notify({Title="Teleport", Content="Format salah. Contoh: 0,10,0", Duration=2})
        end
    end
})

-- === Spesial Tab ===
SpesialTab:CreateToggle({
    Name = "ESP Player",
    CurrentValue = state.ESP,
    Callback = function(v) setESP(v) end
})

SpesialTab:CreateToggle({
    Name = "Noclip",
    CurrentValue = state.Noclip,
    Callback = function(v)
        state.Noclip = v
        if v then enableNoclipLoop() else disableNoclipLoop() end
        saveConfig()
    end
})

SpesialTab:CreateToggle({
    Name = "Fake Title: Admin (Blue)",
    CurrentValue = state.FakeAdmin,
    Callback = function(v)
        state.FakeAdmin = v
        if v then createAdminTitle() else removeAdminTitle() end
        saveConfig()
    end
})

-- Teleport to Player input + button
SpesialTab:CreateInput({
    Name = "Teleport to Player (username)",
    PlaceholderText = "Masukkan username atau display name",
    Callback = function(text)
        _G.__NERO_TP_TARGET = text
    end
})
SpesialTab:CreateButton({
    Name = "Go To Player",
    Callback = function()
        local name = _G.__NERO_TP_TARGET
        if not name or name == "" then
            Rayfield:Notify({Title="Teleport", Content="Masukkan username dulu.", Duration=2})
            return
        end
        local ok, msg = teleportToPlayer(tostring(name))
        if ok then
            Rayfield:Notify({Title="Teleport", Content=msg, Duration=2})
        else
            Rayfield:Notify({Title="Teleport", Content=msg, Duration=3})
        end
    end
})

-- === Apply settings on spawn / initial ===
if state.EnableJump then pcall(createJumpButton) end
if state.FlyEnabled then
    pcall(function()
        createFlyButtons()
        FlyModule.setSpeed((state.FlySpeed or 50)/50)
        if UserInputService.TouchEnabled then
            FlyModule.mobilefly(player, false)
        else
            FlyModule.sFLY(false)
        end
    end)
end
if state.Noclip then enableNoclipLoop() end
if state.FakeAdmin and player.Character then createAdminTitle() end

player.CharacterAdded:Connect(function()
    task.wait(0.6)
    local h = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
    if h then
        pcall(function()
            if state.SpeedHack then h.WalkSpeed = state.WalkSpeed end
            h.UseJumpPower = true
            h.JumpPower = state.JumpPower
        end)
    end
    if state.FakeAdmin then createAdminTitle() end
    -- re-apply fly on respawn if enabled
    if state.FlyEnabled then
        task.delay(0.7, function()
            pcall(function()
                if UserInputService.TouchEnabled then
                    FlyModule.mobilefly(player, false)
                else
                    FlyModule.sFLY(false)
                end
            end)
        end)
    else
        pcall(function() FlyModule.NOFLY() FlyModule.unmobilefly(player) end)
    end
end)

-- final notify & save
Rayfield:Notify({Title="ShieldTeam | NERO", Content="Full pack loaded (Fly patched).", Duration = 2})
saveConfig()

-- End of script