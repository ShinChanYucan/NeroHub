-- 🛡️ ShieldTeam | NERO - Final Merge
-- Features:
-- Auto Loop Summit + Manual TP
-- Infinity Jump, ESP Player, Noclip
-- Fly (PC & Android) with numeric input
-- Walk Speed numeric input
-- Auto Teleport to Player (by username)
-- Fake Title "Admin" (blue) toggle in Special tab
-- Rayfield UI (no key)

-- == Services & Init ==
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local StarterGui = game:GetService("StarterGui")

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

-- Keep refs to cleanup
local espTable = {}
local adminGui = nil

-- == Checkpoints & Finish (from your provided script) ==
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

local function runRouteOnce()
    if not (player and player.Character and player.Character:FindFirstChild("HumanoidRootPart")) then return end
    for _, cf in ipairs(checkpoints) do
        safeTeleportCharacterTo(player, cf)
        if player.Character then jumpOnceForChar(player.Character) end
        task.wait(2.5)
    end
    safeTeleportCharacterTo(player, finishCFrame)
    if player.Character then jumpOnceForChar(player.Character) end
    task.wait(2.5)
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

-- == Fly (PC & Android) using AssemblyLinearVelocity for smoothness ==
RunService.RenderStepped:Connect(function(dt)
    if flyEnabled and player and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
        local hrp = player.Character.HumanoidRootPart
        local moveDir = Vector3.zero

        -- PC keys
        if UserInputService:IsKeyDown(Enum.KeyCode.W) then moveDir += hrp.CFrame.LookVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.S) then moveDir -= hrp.CFrame.LookVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.A) then moveDir -= hrp.CFrame.RightVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.D) then moveDir += hrp.CFrame.RightVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.Space) then moveDir += Vector3.yAxis end
        if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then moveDir -= Vector3.yAxis end

        -- Android vertical control from GUI
        if verticalFly ~= 0 then moveDir += Vector3.yAxis * verticalFly end

        if moveDir.Magnitude > 0 then
            hrp.AssemblyLinearVelocity = moveDir.Unit * (flySpeed)
        else
            hrp.AssemblyLinearVelocity = Vector3.zero
        end
    end
end)

-- Ensure default WalkSpeed applied on spawn
local function applyWalkSpeed()
    if player and player.Character and player.Character:FindFirstChildOfClass("Humanoid") then
        pcall(function() player.Character:FindFirstChildOfClass("Humanoid").WalkSpeed = walkSpeed end)
    end
end

player.CharacterAdded:Connect(function(char)
    task.wait(0.6)
    applyWalkSpeed()
    -- re-apply admin title if enabled
    if adminTitleEnabled then
        -- small delay to ensure Head exists
        task.delay(0.1, function()
            if adminTitleEnabled then
                -- createAdminTitle will attach if needed
                -- call below after function declared
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
    local head = char:FindFirstChild("Head") or char:FindFirstChild("Head") -- try
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

-- If CharacterAdded and adminTitleEnabled, recreate
Players.LocalPlayer.CharacterAdded:Connect(function()
    task.wait(0.3)
    if adminTitleEnabled then createAdminTitle() end
end)

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
    Callback = function() verticalFly = 1; task.delay(0.25, function() verticalFly = 0 end) end
})
SpecialTab:CreateButton({
    Name = "Descend (mobile)",
    Callback = function() verticalFly = -1; task.delay(0.25, function() verticalFly = 0 end) end
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
    Callback = function(text) tpUsername = text end
})
SpecialTab:CreateButton({
    Name = "Go To Player",
    Callback = function()
        local target = Players:FindFirstChild(tpUsername)
        if target and target.Character and target.Character:FindFirstChild("HumanoidRootPart") then
            safeTeleportCharacterTo(player, target.Character.HumanoidRootPart.CFrame)
        else
            Rayfield:Notify({Title="Teleport", Content="Player tidak ditemukan atau belum spawn.", Duration=3})
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
            Rayfield:Notify({Title="Admin Title", Content="Admin title aktif.", Duration=2})
        else
            removeAdminTitle()
            Rayfield:Notify({Title="Admin Title", Content="Admin title nonaktif.", Duration=2})
        end
    end
})

-- Final: ensure initial walk speed applied
task.delay(0.5, applyWalkSpeed)