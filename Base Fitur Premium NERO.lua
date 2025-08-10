-- ShieldTeam | NERO Ultimate v2.1
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local state = {
    running = false,
    infJump = true,
    espEnabled = false,
    noclipEnabled = false,
    flyEnabled = false,
    flySpeed = 1,
    speedHackEnabled = false,
    normalWalkSpeed = 16,
    speedHackValue = 18,
    adminTitleEnabled = false,
    tpUsername = "",
    verticalFly = 0
}

local espTable = {}
local adminGui = nil
local flyGui, ascendBtn, descendBtn = nil, nil, nil

local function teleportCharacter(character, cframe)
    if character and character:FindFirstChild("HumanoidRootPart") then
        if typeof(character.SetPrimaryPartCFrame) == "function" then
            character:SetPrimaryPartCFrame(cframe)
        else
            character.HumanoidRootPart.CFrame = cframe
        end
        local hrp = character:FindFirstChild("HumanoidRootPart")
        if hrp then
            hrp.AssemblyLinearVelocity = Vector3.zero
            hrp.RotVelocity = Vector3.zero
        end
    end
end

local function getCarriedCharacter()
    local hrp = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
    if not hrp then return nil end
    for _, plr in pairs(Players:GetPlayers()) do
        if plr ~= player and plr.Character and plr.Character:FindFirstChild("HumanoidRootPart") then
            local dist = (plr.Character.HumanoidRootPart.Position - hrp.Position).Magnitude
            if dist < 8 then
                return plr.Character
            end
        end
    end
    return nil
end

local function findPlayerByName(searchName)
    if not searchName or searchName == "" then return nil end
    local lowerSearch = searchName:lower()
    
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr.Name:lower() == lowerSearch then
            return plr
        end
    end
    
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr.DisplayName:lower() == lowerSearch then
            return plr
        end
    end
    
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr.Name:lower():find(lowerSearch) or plr.DisplayName:lower():find(lowerSearch) then
            return plr
        end
    end
    
    return nil
end

local noclipConnection = nil
local function enableNoclip()
    if noclipConnection then return end
    noclipConnection = RunService.Stepped:Connect(function()
        if player.Character and player.Character:FindFirstChildOfClass("Humanoid") then
            player.Character:FindFirstChildOfClass("Humanoid"):ChangeState(11)
        end
    end)
end

local function disableNoclip()
    if noclipConnection then
        noclipConnection:Disconnect()
        noclipConnection = nil
    end
end

UserInputService.JumpRequest:Connect(function()
    if state.infJump and player.Character then
        local h = player.Character:FindFirstChildOfClass("Humanoid")
        if h then pcall(function() h:ChangeState(Enum.HumanoidStateType.Jumping) end) end
    end
end)

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

local function setESP(enabled)
    state.espEnabled = enabled
    if enabled then
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
        if state.espEnabled then createHighlightFor(plr) end
    end)
end)
Players.PlayerRemoving:Connect(function(plr) removeHighlightFor(plr) end)

RunService.Stepped:Connect(function()
    if state.noclipEnabled and player and player.Character then
        for _, p in ipairs(player.Character:GetDescendants()) do
            if p:IsA("BasePart") then
                p.CanCollide = false
            end
        end
    end
end)

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
            state.verticalFly = 1
        end
    end)
    
    ascendBtn.InputEnded:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.Touch or inp.UserInputType == Enum.UserInputType.MouseButton1 then
            state.verticalFly = 0
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
            state.verticalFly = -1
        end
    end)
    
    descendBtn.InputEnded:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.Touch or inp.UserInputType == Enum.UserInputType.MouseButton1 then
            state.verticalFly = 0
        end
    end)
end

RunService.RenderStepped:Connect(function()
    if player.Character and player.Character:FindFirstChildOfClass("Humanoid") then
        local h = player.Character:FindFirstChildOfClass("Humanoid")
        local hrp = player.Character:FindFirstChild("HumanoidRootPart")
        
        if h and state.speedHackEnabled then
            pcall(function() h.WalkSpeed = state.speedHackValue end)
            if hrp and h.WalkSpeed ~= state.speedHackValue then
                local moveDir = Vector3.zero
                if h.MoveDirection and h.MoveDirection.Magnitude > 0 then
                    moveDir = h.MoveDirection.Unit
                else
                    moveDir = hrp.CFrame.LookVector
                end
                if moveDir.Magnitude > 0 then
                    hrp.AssemblyLinearVelocity = Vector3.new(moveDir.X * state.speedHackValue, hrp.AssemblyLinearVelocity.Y, moveDir.Z * state.speedHackValue)
                end
            end
        elseif h and not state.speedHackEnabled then
            pcall(function() h.WalkSpeed = state.normalWalkSpeed end)
        end
    end
end)

local FlyModule = (function()
    local IYMouse = player:GetMouse()

    local function getRoot(char)
        if not char then return nil end
        return char:FindFirstChild('HumanoidRootPart') or char:FindFirstChild('Torso') or char:FindFirstChild('UpperTorso')
    end

    local FLYING = false
    local QEfly = true
    local iyflyspeed = 1
    local vehicleflyspeed = 1
    local flyKeyDown, flyKeyUp
    local mfly1, mfly2

    local function sFLY(vfly)
        repeat task.wait() until player and player.Character and player.Character:FindFirstChildOfClass("Humanoid")
        repeat task.wait() until IYMouse

        if flyKeyDown or flyKeyUp then
            pcall(function()
                if flyKeyDown then flyKeyDown:Disconnect() end
                if flyKeyUp then flyKeyUp:Disconnect() end
            end)
        end

        local T = getRoot(player.Character)
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
                    if not vfly and player.Character:FindFirstChildOfClass('Humanoid') then
                        pcall(function() player.Character:FindFirstChildOfClass('Humanoid').PlatformStand = true end)
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
                if player.Character:FindFirstChildOfClass('Humanoid') then
                    player.Character:FindFirstChildOfClass('Humanoid').PlatformStand = false
                end
            end)
        end

        flyKeyDown = IYMouse.KeyDown:Connect(function(KEY)
            local key = KEY:lower()
            if key == 'w' then
                CONTROL.F = (vfly and vehicleflyspeed or iyflyspeed)
            elseif key == 's' then
                CONTROL.B = -(vfly and vehicleflyspeed or iyflyspeed)
            elseif key == 'a' then
                CONTROL.L = -(vfly and vehicleflyspeed or iyflyspeed)
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
            if key == 'w' then CONTROL.F = 0
            elseif key == 's' then CONTROL.B = 0
            elseif key == 'a' then CONTROL.L = 0
            elseif key == 'd' then CONTROL.R = 0
            elseif key == 'e' then CONTROL.Q = 0
            elseif key == 'q' then CONTROL.E = 0 end
        end)

        FLY()
    end

    local function NOFLY()
        FLYING = false
        pcall(function()
            if flyKeyDown then flyKeyDown:Disconnect() end
            if flyKeyUp then flyKeyUp:Disconnect() end
        end)
        if player.Character and player.Character:FindFirstChildOfClass('Humanoid') then
            pcall(function() player.Character:FindFirstChildOfClass('Humanoid').PlatformStand = false end)
        end
        pcall(function() workspace.CurrentCamera.CameraType = Enum.CameraType.Custom end)
    end

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
                if state.verticalFly ~= 0 then
                    VelocityHandler.Velocity = VelocityHandler.Velocity + Vector3.new(0, state.verticalFly * ((vfly and vehicleflyspeed or iyflyspeed) * 50), 0)
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

player.CharacterAdded:Connect(function(char)
    task.wait(0.6)
    
    if state.speedHackEnabled then
        task.wait(0.2)
        local humanoid = char:FindFirstChildOfClass("Humanoid")
        if humanoid then
            humanoid.WalkSpeed = state.speedHackValue
        end
    else
        local humanoid = char:FindFirstChildOfClass("Humanoid")
        if humanoid then
            humanoid.WalkSpeed = state.normalWalkSpeed
        end
    end
    
    if state.flyEnabled then
        task.wait(0.5)
        if UserInputService.TouchEnabled then
            FlyModule.mobilefly(player, false)
            createFlyButtons()
        else
            FlyModule.sFLY(false)
        end
    end
    
    if state.adminTitleEnabled then
        task.delay(0.1, function()
            if state.adminTitleEnabled then
                createAdminTitle()
            end
        end)
    end
end)

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
    txt.TextColor3 = Color3.fromRGB(0, 102, 255)
    txt.TextStrokeTransparency = 0
    txt.TextScaled = true
    txt.Font = Enum.Font.SourceSansBold
    txt.Parent = billboard

    billboard.Parent = head
    adminGui = billboard
end

local success, Rayfield = pcall(function()
    return loadstring(game:HttpGet("https://sirius.menu/rayfield"))()
end)

if not success or not Rayfield then
    warn("Rayfield failed to load.")
    return
end

local Window = Rayfield:CreateWindow({
    Name = "🛡️ ShieldTeam | NERO Premium Feature",
    LoadingTitle = "ShieldTeam | NERO",
    LoadingSubtitle = "Developer NERO💖",
    ConfigurationSaving = { Enabled = false }
})

local MainTab = Window:CreateTab("Main", 4483362458)
MainTab:CreateToggle({
    Name = "Infinity Jump",
    CurrentValue = false,
    Callback = function(v)
        state.infJump = v
        Rayfield:Notify({Title="Jump", Content=v and "Infinity jump enabled" or "Infinity jump disabled", Duration=2})
    end
})

MainTab:CreateToggle({
    Name = "ESP Player",
    CurrentValue = false,
    Callback = function(v)
        setESP(v)
        Rayfield:Notify({Title="ESP", Content=v and "Player ESP enabled" or "Player ESP disabled", Duration=2})
    end
})

MainTab:CreateToggle({
    Name = "Noclip",
    CurrentValue = false,
    Callback = function(v)
        state.noclipEnabled = v
        Rayfield:Notify({Title="Noclip", Content=v and "Noclip enabled" or "Noclip disabled", Duration=2})
    end
})

local MovementTab = Window:CreateTab("Movement", 4483362458)

MovementTab:CreateInput({
    Name = "Fly Speed",
    PlaceholderText = "e.g. 1",
    Callback = function(val)
        local n = tonumber(val)
        if n and n > 0 then
            state.flySpeed = n
            FlyModule.setSpeed(n)
            Rayfield:Notify({Title="Fly", Content="Fly speed set to: " .. n, Duration=2})
        end
    end
})

MovementTab:CreateToggle({
    Name = "Fly Mode (InfinityYield Style)",
    CurrentValue = false,
    Callback = function(v)
        state.flyEnabled = v
        if v then
            FlyModule.setSpeed(state.flySpeed)
            if UserInputService.TouchEnabled then
                FlyModule.mobilefly(player, false)
                createFlyButtons()
                Rayfield:Notify({Title="Fly", Content="Mobile fly enabled with GUI buttons", Duration=3})
            else
                FlyModule.sFLY(false)
                Rayfield:Notify({Title="Fly", Content="PC fly enabled (WASD + QE)", Duration=3})
            end
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

MovementTab:CreateInput({
    Name = "Speed Hack Value",
    PlaceholderText = "e.g. 100",
    Callback = function(val)
        local n = tonumber(val)
        if n and n > 0 then
            state.speedHackValue = n
            if state.speedHackEnabled and player.Character and player.Character:FindFirstChildOfClass("Humanoid") then
                player.Character:FindFirstChildOfClass("Humanoid").WalkSpeed = n
            end
            Rayfield:Notify({Title="Speed", Content="Speed hack value set to: " .. n, Duration=2})
        end
    end
})

MovementTab:CreateToggle({
    Name = "Speed Hack (Anti-Reset)",
    CurrentValue = false,
    Callback = function(v)
        state.speedHackEnabled = v
        if v then
            Rayfield:Notify({Title="Speed Hack", Content="Speed hack enabled: " .. state.speedHackValue .. " (Anti-Reset)", Duration=3})
        else
            Rayfield:Notify({Title="Speed Hack", Content="Speed hack disabled", Duration=2})
        end
    end
})

local SpecialTab = Window:CreateTab("Special", 4483362458)

SpecialTab:CreateButton({
    Name = "Ascend (Manual)",
    Callback = function()
        state.verticalFly = 1
        task.delay(0.3, function() state.verticalFly = 0 end)
        Rayfield:Notify({Title="Fly", Content="Manual ascend", Duration=1})
    end
})

SpecialTab:CreateButton({
    Name = "Descend (Manual)",
    Callback = function()
        state.verticalFly = -1
        task.delay(0.3, function() state.verticalFly = 0 end)
        Rayfield:Notify({Title="Fly", Content="Manual descend", Duration=1})
    end
})

SpecialTab:CreateSection("Enhanced Player Teleport")

SpecialTab:CreateInput({
    Name = "Teleport to Player",
    PlaceholderText = "Username or Display Name",
    Callback = function(text)
        state.tpUsername = text
    end
})

SpecialTab:CreateButton({
    Name = "Go To Player",
    Callback = function()
        local targetPlayer = findPlayerByName(state.tpUsername)
        if targetPlayer and targetPlayer.Character and targetPlayer.Character:FindFirstChild("HumanoidRootPart") then
            teleportCharacter(player.Character, targetPlayer.Character.HumanoidRootPart.CFrame)
            Rayfield:Notify({
                Title="Teleport Success", 
                Content="Teleported to " .. targetPlayer.DisplayName .. " (@" .. targetPlayer.Name .. ")", 
                Duration=3
            })
        else
            Rayfield:Notify({
                Title="Teleport Failed", 
                Content="Player '" .. state.tpUsername .. "' not found or not spawned", 
                Duration=3
            })
        end
    end
})

SpecialTab:CreateButton({
    Name = "📍 TP to Nearest Player",
    Callback = function()
        if not (player.Character and player.Character:FindFirstChild("HumanoidRootPart")) then
            Rayfield:Notify({Title="Error", Content="Your character is not spawned", Duration=2})
            return
        end
        
        local myPos = player.Character.HumanoidRootPart.Position
        local nearestPlayer = nil
        local nearestDistance = math.huge
        
        for _, plr in ipairs(Players:GetPlayers()) do
            if plr ~= player and plr.Character and plr.Character:FindFirstChild("HumanoidRootPart") then
                local distance = (plr.Character.HumanoidRootPart.Position - myPos).Magnitude
                if distance < nearestDistance then
                    nearestDistance = distance
                    nearestPlayer = plr
                end
            end
        end
        
        if nearestPlayer then
            teleportCharacter(player.Character, nearestPlayer.Character.HumanoidRootPart.CFrame)
            Rayfield:Notify({
                Title="Teleport Success", 
                Content="Teleported to nearest player: " .. nearestPlayer.DisplayName .. " (Distance: " .. math.floor(nearestDistance) .. ")", 
                Duration=3
            })
        else
            Rayfield:Notify({
                Title="No Players Found", 
                Content="No other players are spawned in the server", 
                Duration=3
            })
        end
    end
})

SpecialTab:CreateButton({
    Name = "🌟 Bring All Players to Me",
    Callback = function()
        if not (player.Character and player.Character:FindFirstChild("HumanoidRootPart")) then
            Rayfield:Notify({Title="Error", Content="Your character is not spawned", Duration=2})
            return
        end
        
        local myPos = player.Character.HumanoidRootPart.Position
        local teleportedCount = 0
        
        for _, plr in ipairs(Players:GetPlayers()) do
            if plr ~= player and plr.Character and plr.Character:FindFirstChild("HumanoidRootPart") then
                local offsetPos = myPos + Vector3.new(
                    math.random(-5, 5), 
                    0, 
                    math.random(-5, 5)
                )
                teleportCharacter(plr.Character, CFrame.new(offsetPos))
                teleportedCount = teleportedCount + 1
            end
        end
        
        if teleportedCount > 0 then
            Rayfield:Notify({
                Title="Mass Teleport", 
                Content="Teleported " .. teleportedCount .. " players to your location", 
                Duration=3
            })
        else
            Rayfield:Notify({
                Title="No Players", 
                Content="No other players to teleport", 
                Duration=2
            })
        end
    end
})

SpecialTab:CreateButton({
    Name = "📋 List All Players",
    Callback = function()
        local playerList = {}
        for _, plr in ipairs(Players:GetPlayers()) do
            if plr ~= player then
                table.insert(playerList, plr.DisplayName .. " (@" .. plr.Name .. ")")
            end
        end
        if #playerList > 0 then
            local listText = table.concat(playerList, ", ")
            if string.len(listText) > 100 then
                listText = string.sub(listText, 1, 100) .. "..."
            end
            Rayfield:Notify({
                Title="Players Online (" .. #playerList .. ")", 
                Content=listText, 
                Duration=5
            })
        else
            Rayfield:Notify({
                Title="Players Online", 
                Content="No other players found", 
                Duration=3
            })
        end
    end
})

SpecialTab:CreateToggle({
    Name = "Fake Title: Admin (Blue)",
    CurrentValue = false,
    Callback = function(v)
        state.adminTitleEnabled = v
        if v then
            createAdminTitle()
            Rayfield:Notify({Title="Admin Title", Content="Admin title enabled", Duration=2})
        else
            removeAdminTitle()
            Rayfield:Notify({Title="Admin Title", Content="Admin title disabled", Duration=2})
        end
    end
})

-- Add this to your SpecialTab section, after the other buttons

SpecialTab:CreateToggle({
    Name = "🛡️ BYPASS ANTICHEAT",
    CurrentValue = false,
    Callback = function(v)
        state.anticheatBypassEnabled = v
        if v then
            pcall(function() 
                loadstring(game:HttpGet("https://raw.githubusercontent.com/hm5650/ACR/refs/heads/main/Acr", true))() 
            end)
            Rayfield:Notify({
                Title="Bypass Anticheat", 
                Content="Anticheat bypass enabled successfully!", 
                Duration=3
            })
        else
            Rayfield:Notify({
                Title="Bypass Anticheat", 
                Content="Anticheat bypass disabled", 
                Duration=2
            })
        end
    end
})

local SettingsTab = Window:CreateTab("Settings", 4483362458)

SettingsTab:CreateButton({
    Name = "Reset All Settings",
    Callback = function()
        state.running = false
        state.infJump = false
        setESP(false)
        state.noclipEnabled = false
        
        if state.flyEnabled then
            state.flyEnabled = false
            if UserInputService.TouchEnabled then
                FlyModule.unmobilefly(player)
                removeFlyButtons()
            else
                FlyModule.NOFLY()
            end
        end
        
        state.speedHackEnabled = false
        state.normalWalkSpeed = 16
        state.speedHackValue = 100
        
        if state.adminTitleEnabled then
            state.adminTitleEnabled = false
            removeAdminTitle()
        end
        
        if player.Character and player.Character:FindFirstChildOfClass("Humanoid") then
            player.Character:FindFirstChildOfClass("Humanoid").WalkSpeed = 16
        end
        
        Rayfield:Notify({Title="Settings", Content="All settings have been reset", Duration=3})
    end
})

SettingsTab:CreateButton({
    Name = "Show Current Status",
    Callback = function()
        local status = {
            "Jump: " .. (state.infJump and "ON" or "OFF"),
            "ESP: " .. (state.espEnabled and "ON" or "OFF"),
            "Noclip: " .. (state.noclipEnabled and "ON" or "OFF"),
            "Fly: " .. (state.flyEnabled and "ON" or "OFF"),
            "Speed: " .. (state.speedHackEnabled and "ON" or "OFF"),
            "Admin Title: " .. (state.adminTitleEnabled and "ON" or "OFF")
        }
        local statusText = table.concat(status, " | ")
        Rayfield:Notify({
            Title="Current Status", 
            Content=statusText, 
            Duration=5
        })
    end
})

local InfoTab = Window:CreateTab("Info", 4483362458)

InfoTab:CreateParagraph({
    Title = "🎮 Controls (PC)",
    Content = "Fly: WASD (movement) + QE (up/down) • Mobile: Use GUI buttons or manual controls in Special tab"
})

InfoTab:CreateParagraph({
    Title = "🚀 Enhanced Teleport Features",
    Content = "• Quick TP buttons for nearby players • Teleport to nearest player • Bring all players to you • Manual teleport with username/display name search"
})

InfoTab:CreateParagraph({
    Title = "🔧 Speed Hack",
    Content = "Anti-reset technology prevents speed from being reset by the game. Uses velocity backup if WalkSpeed fails."
})

InfoTab:CreateParagraph({
    Title = "ℹ️ Script Info",
    Content = "ShieldTeam | NERO Ultimate v2.1 - Updated with Basecamp to CP8 route and customizable delay system. For support, contact ShieldTeam developers."
})

game:GetService("Players").PlayerRemoving:Connect(function(plr)
    if plr == player then
        if state.flyEnabled then
            FlyModule.NOFLY()
            FlyModule.unmobilefly(player)
            removeFlyButtons()
        end
        removeAdminTitle()
        disableNoclip()
    end
end)

task.delay(1, function()
    if player.Character and player.Character:FindFirstChildOfClass("Humanoid") then
        player.Character:FindFirstChildOfClass("Humanoid").WalkSpeed = state.normalWalkSpeed
    end
    
    Rayfield:Notify({
        Title="🛡️ NERO Ultimate v2.1", 
        Content="Loaded successfully! Updated with Basecamp→CP8 route and customizable delay. Check Info tab for details.", 
        Duration=5
    })
end)