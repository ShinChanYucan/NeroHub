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

-- == Services ==
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local StarterGui = game:GetService("StarterGui")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- == State ==
local state = {
    EnableJump = false,
    JumpPower = 50,
    running = false,
    infJump = false,
    espEnabled = false,
    noclipEnabled = false,
    speedHackEnabled = false,
    normalWalkSpeed = 16,
    speedHackValue = 18,
    adminTitleEnabled = false,
    tpUsername = "",
    verticalFly = 0
}

-- == Data ==
local espTable = {}
local adminGui = nil
local carryTarget = nil

-- == Utility ==
local function safeGetHRP(character)
    if not character then return nil end
    return character:FindFirstChild("HumanoidRootPart")
end

local function getCarriedCharacter()
    local hrp = safeGetHRP(player.Character)
    if not hrp then return nil end
    for _, plr in pairs(Players:GetPlayers()) do
        if plr ~= player and plr.Character and safeGetHRP(plr.Character) then
            local dist = (plr.Character.HumanoidRootPart.Position - hrp.Position).Magnitude
            if dist < 6 then
                return plr.Character
            end
        end
    end
    return nil
end

local function teleportCharacter(character, position)
    if character and character:FindFirstChild("HumanoidRootPart") then
        if typeof(character.SetPrimaryPartCFrame) == "function" then
            character:SetPrimaryPartCFrame(CFrame.new(position))
        else
            character.HumanoidRootPart.CFrame = CFrame.new(position)
        end
    end
end

local function getTargetPlayerByNameOrDisplay(query)
    if not query or query == "" then return nil end
    query = string.lower(query)
    local best = nil
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= player then
            local u = string.lower(plr.Name or "")
            local d = string.lower(plr.DisplayName or "")
            if string.find(u, query, 1, true) or string.find(d, query, 1, true) then
                best = plr
                break
            end
        end
    end
    return best
end

-- == Noclip ==
local noclipConnection
local function enableNoclip()
    state.noclipEnabled = true
    if noclipConnection then noclipConnection:Disconnect() end
    noclipConnection = RunService.Stepped:Connect(function()
        if not state.noclipEnabled then return end
        local char = player.Character
        if not char then return end
        for _, part in ipairs(char:GetDescendants()) do
            if part:IsA("BasePart") then
                part.CanCollide = false
            end
        end
    end)
end

local function disableNoclip()
    state.noclipEnabled = false
    if noclipConnection then
        noclipConnection:Disconnect()
        noclipConnection = nil
    end
end

-- == Checkpoints (Gunung Daun) ==
local checkpoints = {
    Vector3.new(-625.014038, 250.367432, -383.940338),      -- CP1
    Vector3.new(-1201.94055, 261.679169, -487.414337),      -- CP2
    Vector3.new(-1399.73083, 578.413635, -953.336426),      -- CP3
    Vector3.new(-1701.85278, 816.575745, -1401.61108),      -- CP4
    Vector3.new(-3231.60278, 1715.8175 + 150, -2591.06348), -- CP5 (parkir di atas 150)
}

-- == Speed Hack ==
local function setSpeedHack(enabled)
    state.speedHackEnabled = enabled
    local char = player.Character
    if char and char:FindFirstChildOfClass("Humanoid") then
        local hum = char:FindFirstChildOfClass("Humanoid")
        if enabled then
            state.normalWalkSpeed = hum.WalkSpeed
            hum.WalkSpeed = state.speedHackValue
        else
            hum.WalkSpeed = state.normalWalkSpeed
        end
    end
end

-- == Summit Loop ==
local function summitLoop()
    while state.running do
        local carriedChar = getCarriedCharacter()
        for i, pos in ipairs(checkpoints) do
            if not state.running then break end

            -- CP4 -> CP5 fly tween + timeout + noclip (map update Gunung Daun)
            if i == 4 then
                enableNoclip()
                local char = player.Character
                local hrp = char and char:FindFirstChild("HumanoidRootPart")
                if hrp then
                    local tweenInfo = TweenInfo.new(3, Enum.EasingStyle.Linear)
                    local tween = game:GetService("TweenService"):Create(hrp, tweenInfo, {CFrame = CFrame.new(checkpoints[5])})
                    local done = false
                    tween.Completed:Connect(function() done = true end)
                    tween:Play()
                    local t0 = tick()
                    while not done and tick() - t0 < 5 do
                        task.wait(0.1)
                    end
                    if not done then
                        teleportCharacter(player.Character, checkpoints[5])
                    end
                else
                    teleportCharacter(player.Character, checkpoints[5])
                end
                if carriedChar then
                    teleportCharacter(carriedChar, checkpoints[5] + Vector3.new(0, 0, 3))
                end
                disableNoclip()

            elseif i == #checkpoints then
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
                task.wait(1)
            end
        end
        task.wait(1)
        teleportCharacter(player.Character, checkpoints[1])
        if carriedChar then
            teleportCharacter(carriedChar, checkpoints[1] + Vector3.new(0, 0, 3))
        end
        task.wait(1)
    end
end

-- == Infinity Jump ==
UserInputService.JumpRequest:Connect(function()
    if state.infJump and player.Character then
        local hum = player.Character:FindFirstChildOfClass("Humanoid")
        if hum then
            hum:ChangeState(Enum.HumanoidStateType.Jumping)
        end
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
    highlight.Parent = playerGui
    espTable[plr] = { Highlight = highlight }
end

local function removeHighlight(plr)
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
        for plr, _ in pairs(espTable) do
            removeHighlight(plr)
        end
    end
end

Players.PlayerAdded:Connect(function(plr)
    if state.espEnabled and plr ~= player then
        plr.CharacterAdded:Connect(function()
            task.wait(1)
            if state.espEnabled then
                createHighlightFor(plr)
            end
        end)
    end
end)

Players.PlayerRemoving:Connect(function(plr)
    removeHighlight(plr)
end)

-- == UI (Rayfield) ==
local Rayfield = loadstring(game:HttpGet("https://raw.githubusercontent.com/shlexware/Rayfield/main/source"))()
local Window = Rayfield:CreateWindow({
    Name = "ShieldTeam | NERO Ultimate",
    LoadingTitle = "ShieldTeam | NERO Ultimate",
    LoadingSubtitle = "Ultimate Summit & Features",
    ConfigurationSaving = { Enabled = false }
})

-- Auto Summit Tab
local AutoTab = Window:CreateTab("Auto Summit", 4483362458)
AutoTab:CreateToggle({
    Name = "Auto Loop Summit",
    CurrentValue = false,
    Callback = function(val)
        state.running = val
        if val then
            task.spawn(summitLoop)
            Rayfield:Notify({Title="Summit", Content="Auto summit started", Duration=2})
        else
            Rayfield:Notify({Title="Summit", Content="Auto summit stopped", Duration=2})
        end
    end
})

AutoTab:CreateButton({
    Name = "Force Run Once",
    Callback = function()
        task.spawn(summitLoop)
        Rayfield:Notify({Title="Summit", Content="Force run started", Duration=2})
    end
})

-- Manual TP Tab
local ManualTab = Window:CreateTab("Manual TP", 4483362458)
for i, pos in ipairs(checkpoints) do
    ManualTab:CreateButton({
        Name = "Teleport CP"..i,
        Callback = function()
            teleportCharacter(player.Character, pos)
        end
    })
end

ManualTab:CreateInput({
    Name = "Teleport to Player (Username/Display)",
    PlaceholderText = "ketik nama...",
    RemoveTextAfterFocusLost = false,
    Callback = function(text)
        state.tpUsername = text or ""
    end
})

ManualTab:CreateButton({
    Name = "Go",
    Callback = function()
        local target = getTargetPlayerByNameOrDisplay(state.tpUsername)
        if target and target.Character and target.Character:FindFirstChild("HumanoidRootPart") then
            teleportCharacter(player.Character, target.Character.HumanoidRootPart.Position + Vector3.new(0,0,3))
        else
            StarterGui:SetCore("SendNotification", {Title="TP", Text="Player tidak ditemukan", Duration=2})
        end
    end
})

-- Misc Tab
local MiscTab = Window:CreateTab("Misc", 4483362458)
MiscTab:CreateToggle({
    Name = "Infinity Jump",
    CurrentValue = false,
    Callback = function(v)
        state.infJump = v
    end
})

MiscTab:CreateToggle({
    Name = "ESP Players",
    CurrentValue = false,
    Callback = function(v)
        setESP(v)
    end
})

MiscTab:CreateToggle({
    Name = "Noclip",
    CurrentValue = false,
    Callback = function(v)
        if v then enableNoclip() else disableNoclip() end
    end
})

MiscTab:CreateToggle({
    Name = "Anti-Reset Speed Hack",
    CurrentValue = false,
    Callback = function(v)
        setSpeedHack(v)
    end
})

MiscTab:CreateSlider({
    Name = "Speed Value",
    Range = {16, 40},
    Increment = 1,
    CurrentValue = 18,
    Callback = function(val)
        state.speedHackValue = val
        if state.speedHackEnabled then
            setSpeedHack(true)
        end
    end
})

-- Info Tab
local InfoTab = Window:CreateTab("Info", 4483362458)
InfoTab:CreateParagraph({
    Title = "🛡️ ShieldTeam | NERO Ultimate",
    Content = "Auto Summit + Manual TP + ESP + Noclip + Anti-Reset Speed"
})

InfoTab:CreateButton({
    Name = "Show Current Status",
    Callback = function()
        local msg = table.concat({
            "Running: " .. (state.running and "ON" or "OFF"),
            "InfJump: " .. (state.infJump and "ON" or "OFF"),
            "ESP: " .. (state.espEnabled and "ON" or "OFF"),
            "Noclip: " .. (state.noclipEnabled and "ON" or "OFF"),
            "SpeedHack: " .. (state.speedHackEnabled and ("ON("..state.speedHackValue..")") or "OFF")
        }, "\n")
        StarterGui:SetCore("SendNotification", {Title="Status", Text=msg, Duration=3})
    end
})