local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local characterConnections = {}
local prevPositions = {}
local vlCounts = {}
local thresholdTicks = 5 -- Number of consecutive ticks for triggering VL increment

local violationLevels = {}

local function isPlayerSitting(player)
    local character = player.Character
    if character and character:FindFirstChild("Humanoid") then
        local humanoid = character:FindFirstChild("Humanoid")
        return humanoid and humanoid:GetState() == Enum.HumanoidStateType.Seated
    end
    return false
end

local function updateLeaningStatus(player)
    local character = player.Character
    if character and character:FindFirstChild("Humanoid") and not isPlayerSitting(player) then
        local torso = character:FindFirstChild("Torso") or character:FindFirstChild("UpperTorso")
        local head = character:FindFirstChild("Head")

        if torso and head then
            local pitch = math.deg(torso.Orientation.x) / 10
            local headPitch = math.deg(head.Orientation.x) / 10

            player:SetAttribute("Pitch", math.round(pitch))
            player:SetAttribute("HeadPitch", math.round(headPitch))
        end
    end
end

local function onCharacterAdded(player, char)
    -- Connect to humanoid changes
    local humanoid = char:WaitForChild("Humanoid")
    local characterConnection = humanoid:GetPropertyChangedSignal("Health"):Connect(function()
        checkOnGround(player, char)
    end)

    characterConnections[player] = characterConnection
    prevPositions[player] = char:FindFirstChild("HumanoidRootPart") and char:FindFirstChild("HumanoidRootPart").Position or Vector3.new() -- Initialize prevPositions for the player
end

local function onCharacterRemoving(player, char)
    -- Handle character removal
    if characterConnections[player] then
        characterConnections[player]:Disconnect()
        characterConnections[player] = nil
        prevPositions[player] = nil
        vlCounts[player] = nil
    end
end

local function checkOnGround(player, character)
    if not character then
        return
    end

    local humanoid = character:FindFirstChildOfClass("Humanoid")
    local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")

    if humanoid and humanoidRootPart then
        local rootPosition = humanoidRootPart.Position
        local rayOffsets = {
            Vector3.new(-2, 0, -2),  -- Top-left edge
            Vector3.new(2, 0, -2),   -- Top-right edge
            Vector3.new(-2, 0, 2),    -- Bottom-left edge
            Vector3.new(2, 0, 2)      -- Bottom-right edge
        }

        local isOnGround = false

        for _, offset in ipairs(rayOffsets) do
            local ray = Ray.new(rootPosition + offset, Vector3.new(0, -5, 0))
            local hit, _ = workspace:FindPartOnRay(ray, character, false, true)

            if hit then
                isOnGround = true
                break
            end
        end

        if humanoid:GetState() == Enum.HumanoidStateType.Seated then
            isOnGround = true
        end

        -- Ignore climbing players
        if humanoid:GetState() == Enum.HumanoidStateType.Climbing then
            isOnGround = true
        end

        if isOnGround then
            vlCounts[player] = 0 -- Reset VL count if on the ground
        elseif humanoid.Health <= 0 then
            vlCounts[player] = 0 -- Reset VL count if player is dead
        elseif humanoidRootPart.Position.Y < (prevPositions[player] and prevPositions[player].Y or 0) then
            vlCounts[player] = 0 -- Reset VL count if player is falling
        else
            vlCounts[player] = (vlCounts[player] or 0) + 1 -- Increment VL count

            if vlCounts[player] >= thresholdTicks then
                -- Implement VL increment logic here
                print(player.Name .. " failed Flight (B) VL: " .. math.max((vlCounts[player] or 0) - 4, 0) .. ".0")
            end
        end

        prevPositions[player] = humanoidRootPart.Position
    end
end

local function checkAllPlayers()
    for _, player in pairs(Players:GetPlayers()) do
        local character = player.Character
        if character then
            checkOnGround(player, character)
            updateLeaningStatus(player)
        end
    end
end

local function printFailedPlayers()
    for player, vl in pairs(violationLevels) do
        if vl > 0 then
            print(player.Name .. " failed Flight (A) VL: " .. vl)
        end
    end
end

Players.PlayerAdded:Connect(function(player)
    local character = player.Character
    if character then
        onCharacterAdded(player, character)
    end

    -- Initialize VL count for the player
    vlCounts[player] = 0

    player.CharacterAdded:Connect(function(char)
        onCharacterAdded(player, char)
    end)

    player.CharacterRemoving:Connect(function(char)
        onCharacterRemoving(player, char)
    end)
end)

Players.PlayerAdded:Connect(function(player)
    violationLevels[player] = 0
end)

Players.PlayerRemoving:Connect(function(player)
    violationLevels[player] = nil
end)

-- Replace wait(1) with wait(0.1)
while wait(0.1) do
    checkAllPlayers()
    printFailedPlayers()
end
