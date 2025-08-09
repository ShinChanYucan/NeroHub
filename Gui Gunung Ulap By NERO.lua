-- ShieldTeam | NERO
-- Developer by NERO

-- Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local hrp = character:WaitForChild("HumanoidRootPart")
local humanoid = character:WaitForChild("Humanoid")

-- Checkpoints
local checkpoints = {
    Vector3.new(-597.99, 15.94, -733.90),   -- CP1
    Vector3.new(-742.27, 148.82, -699.98),  -- CP2
    Vector3.new(-702.02, 86.04, -313.23),   -- CP3
    Vector3.new(-863.99, -29.74, 246.28),   -- CP4
    Vector3.new(-882.93, -171.42, 695.09),  -- CP5
    Vector3.new(-541.61, -133.50, 456.79),  -- CP6
    Vector3.new(-368.54, -130.27, 517.68),  -- CP7
    Vector3.new(145.48, -47.59, 825.86),    -- CP8
    Vector3.new(713.34, -106.13, 577.01),   -- CP9
    Vector3.new(180.64, -6.32, 363.78),     -- CP10
    Vector3.new(484.67, -76.76, -454.40),   -- CP11
    Vector3.new(-89.12, 66.19, 231.91),     -- CP12
    Vector3.new(232.60, 195.04, 32.36),     -- CP13
    Vector3.new(90.31, 478.34, -27.42),     -- CP14
}

local preFinishTrigger = Vector3.new(71.24, 391.62, 103.52)
local realFinishTrigger = Vector3.new(65.25, 452.57, 53.39)
local baseSpawn = Vector3.new(-362.87, -83.51, -812.64)

-- Functions
local function updateCharacterRefs()
    character = player.Character or player.CharacterAdded:Wait()
    hrp = character:WaitForChild("HumanoidRootPart")
    humanoid = character:WaitForChild("Humanoid")
end

local function safeTeleport(pos)
    updateCharacterRefs()
    for _, v in pairs(character:GetChildren()) do
        if v:IsA("BasePart") then v.Velocity = Vector3.zero end
    end
    hrp.CFrame = CFrame.new(pos + Vector3.new(0,2,0))
    task.wait(0.3)
    humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
end

local function walkTo(pos, speed, forceJumping)
    updateCharacterRefs()
    humanoid.WalkSpeed = speed or 16
    humanoid:MoveTo(pos)

    local jumpLoop
    if forceJumping then
        jumpLoop = task.spawn(function()
            while humanoid.WalkSpeed > 0 do
                task.wait(1)
                humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
            end
        end)
    end

    humanoid.MoveToFinished:Wait()
    if jumpLoop then task.cancel(jumpLoop) end
    humanoid.WalkSpeed = 16
    humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
end

-- Anti AFK
task.spawn(function()
    local vim = game:GetService("VirtualInputManager")
    while task.wait(60) do
        vim:SendKeyEvent(true, "W", false, game)
        vim:SendKeyEvent(false, "W", false, game)
    end
end)

-- Rayfield GUI
local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()
local Window = Rayfield:CreateWindow({
    Name = "ShieldTeam | NERO",
    LoadingTitle = "Developer by NERO",
    LoadingSubtitle = "Teleport & Auto Summit",
    ConfigurationSaving = { Enabled = false }
})

-- Manual Teleports
local TabManual = Window:CreateTab("Manual Teleport", 4483362458)
for i, pos in ipairs(checkpoints) do
    TabManual:CreateButton({
        Name = "Teleport to CP" .. i,
        Callback = function() safeTeleport(pos) end
    })
end
TabManual:CreateButton({
    Name = "Teleport to Base Spawn",
    Callback = function() safeTeleport(baseSpawn) end
})

-- Auto Summit
local TabAuto = Window:CreateTab("Auto Summit", 4483362458)
local auto = false
TabAuto:CreateToggle({
    Name = "Auto Summit",
    CurrentValue = false,
    Callback = function(state)
        auto = state
        if auto then
            task.spawn(function()
                while auto do
                    safeTeleport(preFinishTrigger)
                    task.wait(3)
                    if not auto then break end
                    walkTo(realFinishTrigger, 60, true)
                    task.wait(1)
                    if not auto then break end
                    walkTo(checkpoints[14], 60)
                    task.wait(2)
                    if not auto then break end
                    safeTeleport(baseSpawn)
                    task.wait(8)
                end
            end)
        end
    end
})