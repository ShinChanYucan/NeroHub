-- 🛡️ ShieldTeam | NERO - Final Merge Fixed GUI Version
-- Features:
-- Auto Loop Summit + Manual TP
-- Infinity Jump, ESP Player, Noclip
-- Fly (PC & Android) with numeric input
-- Walk Speed numeric input
-- Auto Teleport to Player (by username)
-- Fake Title "Admin" (blue) toggle in Special tab
-- Rayfield UI (no key)

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer

local running = false
local infJump = false
local espEnabled = false
local noclipEnabled = false
local flyEnabled = false
local flySpeed = 50
local walkSpeed = 16
local tpUsername = ""
local verticalFly = 0
local adminTitleEnabled = false

local espTable = {}
local adminGui = nil

-- Checkpoints Gunung Daun (sesuaikan dengan pos aslinya)
local checkpoints = {
    Vector3.new(-625.014038, 250.367432, -383.940338),   -- CP1
    Vector3.new(-1201.94055, 261.679169, -487.414337),   -- CP2
    Vector3.new(-1399.73083, 578.413635, -953.336426),   -- CP3
    Vector3.new(-1701.85278, 816.575745, -1401.61108),   -- CP4
    Vector3.new(-3231.60278, 1715.8175 + 150, -2591.06348), -- CP5 (fly dulu 150 atas)
}

-- Teleport function
local function teleportCharacter(character, position)
    if character and character:FindFirstChild("HumanoidRootPart") then
        character:SetPrimaryPartCFrame(CFrame.new(position))
    end
end

-- Get carried player character if near
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

-- Noclip control
local noclipConnection = nil
local function enableNoclip()
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

-- Summit Loop
local function summitLoop()
    while running do
        local carriedChar = getCarriedCharacter()
        for i, pos in ipairs(checkpoints) do
            if not running then break end

            if i == #checkpoints then
                -- CP5 special: fly + noclip + descend
                enableNoclip()
                teleportCharacter(player.Character, pos)
                if carriedChar then
                    teleportCharacter(carriedChar, pos + Vector3.new(0, 0, 3))
                end
                wait(1)
                for y = 150, 0, -10 do
                    local descendPos = Vector3.new(pos.X, pos.Y - y, pos.Z)
                    teleportCharacter(player.Character, descendPos)
                    if carriedChar then
                        teleportCharacter(carriedChar, descendPos + Vector3.new(0, 0, 3))
                    end
                    wait(0.2)
                end
                disableNoclip()
            else
                teleportCharacter(player.Character, pos)
                if carriedChar then
                    teleportCharacter(carriedChar, pos + Vector3.new(0, 0, 3))
                end
                wait(5.5)
            end
        end
        wait(1)
        teleportCharacter(player.Character, checkpoints[1])
        if carriedChar then
            teleportCharacter(carriedChar, checkpoints[1] + Vector3.new(0, 0, 3))
        end
        wait(2)
    end
end

-- Infinity Jump
UserInputService.JumpRequest:Connect(function()
    if infJump and player.Character then
        local h = player.Character:FindFirstChildOfClass("Humanoid")
        if h then pcall(function() h:ChangeState(Enum.HumanoidStateType.Jumping) end) end
    end
end)

-- ESP Player
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

-- Noclip body parts collider off
RunService.Stepped:Connect(function()
    if noclipEnabled and player and player.Character then
        for _, p in ipairs(player.Character:GetDescendants()) do
            if p:IsA("BasePart") then
                p.CanCollide = false
            end
        end
    end
end)

-- Fly control (PC & Android)
RunService.RenderStepped:Connect(function()
    if flyEnabled and player and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
        local hrp = player.Character.HumanoidRootPart
        local moveDir = Vector3.zero

        if UserInputService:IsKeyDown(Enum.KeyCode.W) then moveDir += hrp.CFrame.LookVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.S) then moveDir -= hrp.CFrame.LookVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.A) then moveDir -= hrp.CFrame.RightVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.D) then moveDir += hrp.CFrame.RightVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.Space) then moveDir += Vector3.yAxis end
        if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then moveDir -= Vector3.yAxis end

        if verticalFly ~= 0 then
            moveDir += Vector3.yAxis * verticalFly
        end

        if moveDir.Magnitude > 0 then
            hrp.AssemblyLinearVelocity = moveDir.Unit * flySpeed
        else
            hrp.AssemblyLinearVelocity = Vector3.zero
        end
    end
end)

-- WalkSpeed apply function
local function applyWalkSpeed()
    if player and player.Character and player.Character:FindFirstChildOfClass("Humanoid") then
        pcall(function()
            player.Character:FindFirstChildOfClass("Humanoid").WalkSpeed = walkSpeed
        end)
    end
end

player.CharacterAdded:Connect(function()
    task.wait(0.6)
    applyWalkSpeed()
end)

-- Fake Admin Title
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

Players.LocalPlayer.CharacterAdded:Connect(function()
    task.wait(0.3)
    if adminTitleEnabled then createAdminTitle() end
end)

-- Rayfield load
local success, Rayfield = pcall(function()
    return loadstring(game:HttpGet("https://sirius.menu/rayfield"))()
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
        if val then task.spawn(summitLoop) end
    end
})
AutoTab:CreateButton({ Name = "Force Run Once", Callback = function() task.spawn(summitLoop) end })

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

-- Main Tab
local MainTab = Window:CreateTab("Main", 4483362458)
MainTab:CreateToggle({ Name = "Infinity Jump", CurrentValue = false, Callback = function(v) infJump = v end })
MainTab:CreateToggle({ Name = "ESP Player", CurrentValue = false, Callback = function(v) setESP(v) end })
MainTab:CreateToggle({ Name = "Noclip", CurrentValue = false, Callback = function(v) noclipEnabled = v end })

-- Special Tab
local SpecialTab = Window:CreateTab("Special", 4483362458)
SpecialTab:CreateInput({
    Name = "Fly Speed (number)",
    PlaceholderText = "e.g. 50",
    Callback = function(val)
        local n = tonumber(val)
        if n and n > 0 then flySpeed = n end
    end
})
SpecialTab:CreateToggle({
    Name = "Fly Mode (toggle)",
    CurrentValue = false,
    Callback = function(v) flyEnabled = v end
})
SpecialTab:CreateButton({
    Name = "Ascend (mobile)",
    Callback = function()
        verticalFly = 1
        task.delay(0.25, function() verticalFly = 0 end)
    end
})
SpecialTab:CreateButton({
    Name = "Descend (mobile)",
    Callback = function()
        verticalFly = -1
        task.delay(0.25, function() verticalFly = 0 end)
    end
})

SpecialTab:CreateInput({
    Name = "Walk Speed (number)",
    PlaceholderText = "e.g. 16",
    Callback = function(val)
        local n = tonumber(val)
        if n and n > 0 then
            walkSpeed = n
            applyWalkSpeed()
        end
    end
})

SpecialTab:CreateInput({
    Name = "Teleport to Player (username)",
    PlaceholderText = "Masukkan username",
    Callback = function(text)
        tpUsername = text
    end
})
SpecialTab:CreateButton({
    Name = "Go To Player",
    Callback = function()
        local target = Players:FindFirstChild(tpUsername)
        if target and target.Character and target.Character:FindFirstChild("HumanoidRootPart") then
            teleportCharacter(player.Character, target.Character.HumanoidRootPart.Position)
        else
            Rayfield:Notify({Title="Teleport", Content="Player tidak ditemukan atau belum spawn.", Duration=3})
        end
    end
})

-- Fake Admin Title toggle
SpecialTab:CreateToggle({
    Name = "Fake Title: Admin (Blue)",
    CurrentValue = false,
    Callback = function(v)
        adminTitleEnabled = v
        if v then
            createAdminTitle()
            Rayfield:Notify({Title="Admin Title", Content="Admin title aktif.", Duration=2})
        else
            removeAdminTitle()
            Rayfield:Notify({Title="Admin Title", Content="Admin title nonaktif.", Duration=2})
        end
    end
})

-- Apply initial walk speed
task.delay(0.5, applyWalkSpeed)