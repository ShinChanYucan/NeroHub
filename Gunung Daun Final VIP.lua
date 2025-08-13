-- 🛡️ ShieldTeam | NERO - Final Merge Ultimate Version
-- Features:
-- Auto Loop Summit + Manual TP (Support Carry Player)
-- Infinity Jump, ESP Player, Noclip
-- InfinityYield-style Fly System (PC & Mobile)
-- Anti-Reset Speed Hack with toggle
-- Fixed Auto Teleport to Player (username + display name support)
-- Enhanced Player Teleport Buttons System
-- Fake Title "Admin" (blue) toggle in Special tab
-- Rayfield UI (no key)

-- == Services & Init ==
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local StarterGui = game:GetService("StarterGui")
local TweenService = game:GetService("TweenService")
local player = Players.LocalPlayer
local camera = workspace.CurrentCamera

-- Global State
local state = {
    running = false,
    infJump = false,
    espEnabled = false,
    noclipEnabled = false,
    flyEnabled = false,
    flySpeed = 1,
    normalWalkSpeed = 16,
    speedHackValue = 18,
    adminTitleEnabled = false,
    tpUsername = "",
    verticalFly = 0
}

-- Keep refs to cleanup
local espTable = {}
local adminGui = nil
local flyGui, ascendBtn, descendBtn = nil, nil, nil

-- Checkpoints Gunung Daun (sesuaikan dengan pos aslinya)
local checkpoints = {
    Vector3.new(-625.014038, 250.367432, -383.940338),   -- CP1
    Vector3.new(-1201.94055, 261.679169, -487.414337),   -- CP2
    Vector3.new(-1399.73083, 578.413635, -953.336426),   -- CP3
    Vector3.new(-1701.85278, 816.575745, -1401.61108),   -- CP4
    Vector3.new(-3231.60278, 1715.8175 + 150, -2591.06348), -- CP5 (fly dulu 150 atas)
}

-- == Helper Functions ==
local function teleportCharacter(character, position)
    if character and character:FindFirstChild("HumanoidRootPart") then
        if typeof(character.SetPrimaryPartCFrame) == "function" then
            character:SetPrimaryPartCFrame(CFrame.new(position))
        else
            character.HumanoidRootPart.CFrame = CFrame.new(position)
        end
        -- Stop velocity
        local hrp = character:FindFirstChild("HumanoidRootPart")
        if hrp then
            hrp.AssemblyLinearVelocity = Vector3.zero
            hrp.RotVelocity = Vector3.zero
        end
    end
end

-- Get carried player character if near
local function getCarriedCharacter()
    local nearest = nil
    local nearestDist = math.huge
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= player and plr.Character and plr.Character:FindFirstChild("HumanoidRootPart") then
            local myChar = player.Character
            if myChar and myChar:FindFirstChild("HumanoidRootPart") then
                local d = (plr.Character.HumanoidRootPart.Position - myChar.HumanoidRootPart.Position).Magnitude
                if d < 8 and d < nearestDist then
                    nearest = plr.Character
                    nearestDist = d
                end
            end
        end
    end
    return nearest
end

-- Find by display name or username
local function findPlayerByName(search)
    if not search or search == "" then return nil end
    local lowerSearch = search:lower()

    -- Exact matches first
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr.Name:lower() == lowerSearch or plr.DisplayName:lower() == lowerSearch then
            return plr
        end
    end

    -- Then startswith
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr.Name:lower():sub(1, #lowerSearch) == lowerSearch or plr.DisplayName:lower():sub(1, #lowerSearch) == lowerSearch then
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

-- Noclip control
local noclipConnection = nil
local function enableNoclip()
    if noclipConnection then return end
    noclipConnection = RunService.Stepped:Connect(function()
        if state.noclipEnabled then return end -- safety
        local char = player.Character
        if char then
            for _, part in ipairs(char:GetDescendants()) do
                if part:IsA("BasePart") and part.CanCollide then
                    part.CanCollide = false
                end
            end
        end
    end)
    state.noclipEnabled = true
end

local function disableNoclip()
    if noclipConnection then
        noclipConnection:Disconnect()
        noclipConnection = nil
    end
    state.noclipEnabled = false
end

-- Summit Loop with carry support
local function summitLoop()
    while state.running do
        local carriedChar = getCarriedCharacter()
        for i, pos in ipairs(checkpoints) do
            if not state.running then break end
            local __ok,__err=pcall(function()

            if i == #checkpoints then
                -- CP5 special: fly + noclip + descend
                enableNoclip()
                teleportCharacter(player.Character, pos)
                if carriedChar then
                    teleportCharacter(carriedChar, pos + Vector3.new(0, 0, 3))
                end
                task.wait(0.5)
                for y = 150, 0, -10 do
                    local descendPos = Vector3.new(pos.X, pos.Y - y, pos.Z)
                    teleportCharacter(player.Character, descendPos)
                    if carriedChar then
                        teleportCharacter(carriedChar, descendPos + Vector3.new(0, 0, 3))
                    end
                    task.wait(0.2)
                end
                disableNoclip()
            else
                teleportCharacter(player.Character, pos)
                if carriedChar then
                    teleportCharacter(carriedChar, pos + Vector3.new(0, 0, 3))
                end
                if i == 4 then
                    enableNoclip()
                    local startPos = pos
                    local targetPos = checkpoints[5]
                    local steps = 50
                    for s = 1, steps do
                        if not state.running then break end
                        local alpha = s/steps
                        local lerpPos = Vector3.new(
                            startPos.X + (targetPos.X - startPos.X)*alpha,
                            startPos.Y + (targetPos.Y - startPos.Y)*alpha,
                            startPos.Z + (targetPos.Z - startPos.Z)*alpha
                        )
                        teleportCharacter(player.Character, lerpPos)
                        if carriedChar then
                            teleportCharacter(carriedChar, lerpPos + Vector3.new(0, 0, 3))
                        end
                        task.wait(0.03)
                    end
                end
                task.wait(1)
            end
            end)
        end
        task.wait(1)
        teleportCharacter(player.Character, checkpoints[1])
        if carriedChar then
            teleportCharacter(carriedChar, checkpoints[1] + Vector3.new(0, 0, 3))
        end
        task.wait(1)
    end
end

-- Infinity Jump
UserInputService.JumpRequest:Connect(function()
    if state.infJump and player.Character then
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
    highlight.FillColor = Color3.fromRGB(0, 170, 255)
    highlight.OutlineColor = Color3.fromRGB(255,255,255)
    highlight.Parent = char
    
    espTable[plr] = { Highlight = highlight }
end

local function removeHighlightFor(plr)
    if espTable[plr] and espTable[plr].Highlight then
        espTable[plr].Highlight:Destroy()
        espTable[plr] = nil
    end
end

local function setESP(enabled)
    state.espEnabled = enabled
    if enabled then
        for _, plr in ipairs(Players:GetPlayers()) do
            if plr ~= player then createHighlightFor(plr) end
        end
    else
        for plr, _ in pairs(espTable) do
            removeHighlightFor(plr)
        end
    end
end

Players.PlayerAdded:Connect(function(plr)
    if state.espEnabled then createHighlightFor(plr) end
end)
Players.PlayerRemoving:Connect(function(plr)
    removeHighlightFor(plr)
end)

-- == Admin Title ==
local function enableAdminTitle()
    if adminGui then return end
    adminGui = Instance.new("BillboardGui")
    adminGui.Size = UDim2.new(0, 200, 0, 50)
    adminGui.StudsOffset = Vector3.new(0, 3, 0)
    adminGui.AlwaysOnTop = true
    adminGui.Name = "NERO_Admin_Title"

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, 0, 1, 0)
    label.BackgroundTransparency = 1
    label.Text = "Admin"
    label.TextColor3 = Color3.fromRGB(0, 170, 255)
    label.TextStrokeTransparency = 0.5
    label.Font = Enum.Font.SourceSansBold
    label.TextScaled = true
    label.Parent = adminGui

    adminGui.Parent = player.Character or player.CharacterAdded:Wait()
end

local function disableAdminTitle()
    if adminGui then
        adminGui:Destroy()
        adminGui = nil
    end
end

-- == Fly (InfinityYield-Style) ==
local FlyModule = {}
do
    local v3inf = Vector3.new(math.huge, math.huge, math.huge)
    local v3none = Vector3.new(0, 0, 0)
    local VelocityHandlerName = "NERO_Fly_Velocity"
    local GyroHandlerName = "NERO_Fly_Gyro"

    local controlModule = nil
    local function getControlModule()
        local plrScripts = player:FindFirstChildOfClass("PlayerScripts")
        if not plrScripts then return nil end
        for _, m in ipairs(plrScripts:GetDescendants()) do
            if m:IsA("ModuleScript") and m.Name == "ControlModule" then
                local ok, ret = pcall(function() return require(m) end)
                if ok then return ret end
            end
        end
        return nil
    end

    local function ensureHandlers()
        local char = player.Character
        if not char then return nil, nil, nil end
        local root = char:FindFirstChild("HumanoidRootPart")
        local humanoid = char:FindFirstChildWhichIsA("Humanoid")
        if not root or not humanoid then return nil, nil, nil end

        local v = root:FindFirstChild(VelocityHandlerName) or Instance.new("BodyVelocity")
        v.Name = VelocityHandlerName
        v.MaxForce = v3none
        v.P = 1250
        v.Velocity = v3none
        v.Parent = root

        local g = root:FindFirstChild(GyroHandlerName) or Instance.new("BodyGyro")
        g.Name = GyroHandlerName
        g.MaxTorque = v3none
        g.P = 3000
        g.CFrame = root.CFrame
        g.Parent = root

        return humanoid, v, g
    end

    function FlyModule.start()
        if state.flyEnabled then return end
        state.flyEnabled = true
        controlModule = getControlModule()

        local char = player.Character or player.CharacterAdded:Wait()
        local root = char:FindFirstChild("HumanoidRootPart")
        local h = char:FindFirstChildWhichIsA("Humanoid")
        if not root or not h then return end

        local VelocityHandler, GyroHandler

        local heartbeatConn
        heartbeatConn = RunService.Stepped:Connect(function(_, step)
            if not state.flyEnabled or not player.Character then
                if heartbeatConn then heartbeatConn:Disconnect() heartbeatConn = nil end
                return
            end

            -- Re-ensure
            local speaker = player
            if speaker.Character and speaker.Character:FindFirstChild("HumanoidRootPart") then
                local root = speaker.Character:FindFirstChild("HumanoidRootPart")
                local velocityHandlerName = "NERO_Fly_Velocity"
                local gyroHandlerName = "NERO_Fly_Gyro"

                if root and root:FindFirstChild(velocityHandlerName) and root:FindFirstChild(gyroHandlerName) then
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
                    end

                    if UserInputService:IsKeyDown(Enum.KeyCode.W) then direction = direction + camera.CFrame.LookVector end
                    if UserInputService:IsKeyDown(Enum.KeyCode.S) then direction = direction - camera.CFrame.LookVector end
                    if UserInputService:IsKeyDown(Enum.KeyCode.A) then direction = direction - camera.CFrame.RightVector end
                    if UserInputService:IsKeyDown(Enum.KeyCode.D) then direction = direction + camera.CFrame.RightVector end

                    if UserInputService:IsKeyDown(Enum.KeyCode.E) or state.verticalFly == 1 then
                        direction = direction + Vector3.new(0, 1, 0)
                    elseif UserInputService:IsKeyDown(Enum.KeyCode.Q) or state.verticalFly == -1 then
                        direction = direction - Vector3.new(0, 1, 0)
                    end

                    if direction.Magnitude > 0 then
                        direction = direction.Unit * (50 * (state.flySpeed or 1))
                    end

                    VelocityHandler.Velocity = direction
                end
            end
        end)
    end

    function FlyModule.stop()
        if not state.flyEnabled then return end
        state.flyEnabled = false
        local char = player.Character
        if not char then return end
        local root = char:FindFirstChild("HumanoidRootPart")
        if not root then return end
        local v = root:FindFirstChild(VelocityHandlerName)
        local g = root:FindFirstChild(GyroHandlerName)
        if v then v:Destroy() end
        if g then g:Destroy() end
        local h = char:FindFirstChildWhichIsA("Humanoid")
        if h then pcall(function() h.PlatformStand = false end) end
    end

    function FlyModule.setSpeed(n)
        state.flySpeed = n
    end
end

-- Mobile Fly GUI
local function createFlyGui()
    if flyGui then return end
    flyGui = Instance.new("ScreenGui")
    flyGui.Name = "NERO_FlyGUI"
    flyGui.ResetOnSpawn = false
    flyGui.IgnoreGuiInset = true
    flyGui.Parent = player:WaitForChild("PlayerGui")

    ascendBtn = Instance.new("TextButton")
    ascendBtn.Size = UDim2.new(0, 80, 0, 80)
    ascendBtn.Position = UDim2.new(1, -90, 1, -180)
    ascendBtn.Text = "↑"
    ascendBtn.TextScaled = true
    ascendBtn.BackgroundColor3 = Color3.fromRGB(50,50,50)
    ascendBtn.TextColor3 = Color3.new(1,1,1)
    ascendBtn.Parent = flyGui

    descendBtn = Instance.new("TextButton")
    descendBtn.Size = UDim2.new(0, 80, 0, 80)
    descendBtn.Position = UDim2.new(1, -90, 1, -90)
    descendBtn.Text = "↓"
    descendBtn.TextScaled = true
    descendBtn.BackgroundColor3 = Color3.fromRGB(50,50,50)
    descendBtn.TextColor3 = Color3.new(1,1,1)
    descendBtn.Parent = flyGui

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

local function removeFlyGui()
    if flyGui then
        flyGui:Destroy()
        flyGui = nil
        ascendBtn, descendBtn = nil, nil
    end
end

-- == UI (Rayfield) ==
local Rayfield = loadstring(game:HttpGet("https://sirius.menu/rayfield"))()
local Window = Rayfield:CreateWindow({
    Name = "🛡️ ShieldTeam | NERO",
    LoadingTitle = "NERO - Final Ultimate",
    LoadingSubtitle = "Rayfield UI"
})

-- Tabs
local MainTab = Window:CreateTab("Main", 4483362458)
local MovementTab = Window:CreateTab("Movement", 4483362458)
local ESPTab = Window:CreateTab("ESP", 4483362458)
local SpecialTab = Window:CreateTab("Special", 4483362458)
local AutoTab = Window:CreateTab("Auto Summit", 4483362458)
local ManualTab = nil -- will set later
local SettingsTab = Window:CreateTab("Settings", 4483362458)
local InfoTab = Window:CreateTab("Info", 4483362458)

-- Movement Tab
MovementTab:CreateToggle({
    Name = "Enable Fly",
    CurrentValue = false,
    Callback = function(v)
        if v then
            FlyModule.start()
            createFlyGui()
        else
            FlyModule.stop()
            removeFlyGui()
        end
    end
})

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

-- ESP Tab
ESPTab:CreateToggle({
    Name = "ESP Player",
    CurrentValue = false,
    Callback = function(v)
        setESP(v)
        Rayfield:Notify({Title="ESP", Content="ESP ".. (v and "enabled" or "disabled"), Duration=2})
    end
})

-- Special Tab: Admin Title, Speed Hack, Quick TPs, Manual Teleport to Player
SpecialTab:CreateToggle({
    Name = "Fake Blue Admin Title",
    CurrentValue = false,
    Callback = function(v)
        state.adminTitleEnabled = v
        if v then enableAdminTitle() else disableAdminTitle() end
        Rayfield:Notify({Title="Admin", Content="Admin title ".. (v and "enabled" or "disabled"), Duration=2})
    end
})

SpecialTab:CreateToggle({
    Name = "Anti-Reset Speed Hack",
    CurrentValue = false,
    Callback = function(v)
        state.speedHackEnabled = v
        local hum = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
        if hum then
            if v then
                hum.WalkSpeed = state.speedHackValue
                local conn; conn = hum:GetPropertyChangedSignal("WalkSpeed"):Connect(function()
                    if not state.speedHackEnabled then if conn then conn:Disconnect() end return end
                    if hum.WalkSpeed ~= state.speedHackValue then
                        hum.WalkSpeed = state.speedHackValue
                    end
                end)
            else
                hum.WalkSpeed = state.normalWalkSpeed
            end
        end
        Rayfield:Notify({Title="Speed", Content="Speed hack ".. (v and "enabled" or "disabled"), Duration=2})
    end
})

SpecialTab:CreateInput({
    Name = "Set Speed Value",
    PlaceholderText = "e.g. 18",
    Callback = function(val)
        local n = tonumber(val)
        if n and n > 0 then
            state.speedHackValue = n
            if state.speedHackEnabled and player.Character and player.Character:FindFirstChildOfClass("Humanoid") then
                player.Character:FindFirstChildOfClass("Humanoid").WalkSpeed = n
            end
            Rayfield:Notify({Title="Speed", Content="Speed set to "..n, Duration=2})
        end
    end
})

-- Manual Teleport to Player (username/display)
SpecialTab:CreateInput({
    Name = "TP to Player (username/display)",
    PlaceholderText = "Username or Display Name",
    Callback = function(val)
        state.tpUsername = tostring(val or "")
    end
})

SpecialTab:CreateButton({
    Name = "Teleport Now",
    Callback = function()
        local targetPlayer = findPlayerByName(state.tpUsername)
        if targetPlayer and targetPlayer.Character and targetPlayer.Character:FindFirstChild("HumanoidRootPart") then
            teleportCharacter(player.Character, targetPlayer.Character.HumanoidRootPart.Position)
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

-- Quick Teleport to Nearest Player
SpecialTab:CreateButton({
    Name = "📍 TP to Nearest Player",
    Callback = function()
        local myChar = player.Character
        local myHRP = myChar and myChar:FindFirstChild("HumanoidRootPart")
        if not myHRP then return end
        local nearestDist, nearest = math.huge, nil
        for _, plr in ipairs(Players:GetPlayers()) do
            if plr ~= player and plr.Character and plr.Character:FindFirstChild("HumanoidRootPart") then
                local d = (plr.Character.HumanoidRootPart.Position - myHRP.Position).Magnitude
                if d < nearestDist then nearestDist = d nearest = plr end
            end
        end
        if nearest and nearest.Character and nearest.Character:FindFirstChild("HumanoidRootPart") then
            teleportCharacter(player.Character, nearest.Character.HumanoidRootPart.Position + Vector3.new(0,0,2))
            Rayfield:Notify({Title="Teleport", Content="Teleported near "..nearest.DisplayName, Duration=2})
        else
            Rayfield:Notify({Title="Teleport", Content="No nearby players found", Duration=2})
        end
    end
})

-- Auto Summit Tab
AutoTab:CreateToggle({
    Name = "Auto Loop Summit",
    CurrentValue = false,
    Callback = function(val)
        state.running = val
        if val then 
            task.spawn(summitLoop)
            Rayfield:Notify({Title="Summit", Content="Auto summit started with carry support", Duration=2})
        else
            Rayfield:Notify({Title="Summit", Content="Auto summit stopped", Duration=2})
        end
    end
})

AutoTab:CreateButton({
    Name = "Force Run Once",
    Callback = function()
        task.spawn(summitLoop)
        Rayfield:Notify({Title="Summit", Content="Running summit once", Duration=2})
    end
})

-- Manual TP Tab
local ManualTab = Window:CreateTab("Manual TP", 4483362458)
for i, pos in ipairs(checkpoints) do
    ManualTab:CreateButton({
        Name = "Teleport CP"..i,
        Callback = function()
            teleportCharacter(player.Character, pos)
            Rayfield:Notify({
                Title="Teleport", Content="Teleported to CP"..i, Duration=2})
        end
    })
end

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
    end
})

MainTab:CreateInput({
    Name = "Set JumpPower",
    PlaceholderText = "e.g. 50",
    Callback = function(val)
        local n = tonumber(val)
        if n then
            state.JumpPower = n
            local h = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
            pcall(function()
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
MainTab:CreateToggle({
    Name = "Infinity Jump",
    CurrentValue = false,
    Callback = function(v)
        state.infJump = v
        Rayfield:Notify({Title="Jump", Content="Infinity Jump "..(v and "ON" or "OFF"), Duration=2})
    end
})

MainTab:CreateToggle({
    Name = "ESP",
    CurrentValue = false,
    Callback = function(v)
        setESP(v)
    end
})

MainTab:CreateToggle({
    Name = "Noclip",
    CurrentValue = false,
    Callback = function(v)
        if v then enableNoclip() else disableNoclip() end
        Rayfield:Notify({Title="Noclip", Content="Noclip "..(v and "ON" or "OFF"), Duration=2})
    end
})

-- Movement Tab extras
MovementTab:CreateToggle({
    Name = "Mobile Fly Buttons",
    CurrentValue = false,
    Callback = function(v)
        if v then createFlyGui() else removeFlyGui() end
        Rayfield:Notify({Title="Fly UI", Content="Mobile buttons "..(v and "shown" or "hidden"), Duration=2})
    end
})

-- Settings Tab
local SettingsTab = Window:CreateTab("Settings", 4483362458)

SettingsTab:CreateButton({
    Name = "Reset All Settings",
    Callback = function()
        -- Reset all states
        state.running = false
        state.infJump = false
        setESP(false)
        state.noclipEnabled = false
        
        -- Disable fly
        if state.flyEnabled then
            state.flyEnabled = false
            if UserInputService.TouchEnabled then
                removeFlyGui()
            end
            FlyModule.stop()
        end

        -- Remove admin title
        disableAdminTitle()
        
        -- Remove noclip connection
        disableNoclip()

        -- Apply normal walk speed
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
            "Summit: " .. (state.running and "ON" or "OFF"),
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

-- Info Tab
InfoTab:CreateParagraph({
    Title = "🛡️ NERO Ultimate Features",
    Content = "Auto Summit with carry support • InfinityYield-style Fly (PC & Mobile) • Anti-reset speed hack • Enhanced player teleport system • ESP & Noclip • Quick TP tools"
})

InfoTab:CreateParagraph({
    Title = "🎮 Controls (PC)",
    Content = "Fly: WASD (movement) + QE (up/down) • Mobile: Use GUI buttons or manual controls in Special tab"
})

InfoTab:CreateParagraph({
    Title = "🚀 Enhanced Teleport Features",
    Content = "• Quick TP buttons for nearby players • Teleport to nearest player • Bring players to you • Manual teleport with username/display name search"
})

InfoTab:CreateParagraph({
    Title = "🔧 Speed Hack",
    Content = "Anti-reset technology prevents speed from being reset by the game. Uses velocity handlers to maintain consistent walk speed."
})

-- Ensure GUI stays loaded in PlayerGui
task.spawn(function()
    local gui = player:WaitForChild("PlayerGui")
    if flyGui and flyGui.Parent ~= gui then
        flyGui.Parent = gui
    end
end)

-- Auto carry reminder
task.spawn(function()
    while true do
        task.wait(30)
        if state.running then
            Rayfield:Notify({Title="Summit", Content="Auto loop running...", Duration=2})
        end
    end
end)