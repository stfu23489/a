local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

function strictAirCheck(player)
    local torso = player.Character and (player.Character:FindFirstChild("Torso") or player.Character:FindFirstChild("UpperTorso"))
    
    if not torso then 
        return true 
    end

    local sphere = Instance.new("Part")
    sphere.Shape = Enum.PartType.Ball
    sphere.Size = Vector3.new(7, 7, 7)
    sphere.Position = torso.Position
    sphere.Anchored = true
    sphere.CanCollide = false
    sphere.Transparency = 1
    sphere.Parent = workspace

    local region = Region3.new(sphere.Position - Vector3.new(sphere.Size.X / 2, sphere.Size.Y / 2, sphere.Size.Z / 2), sphere.Position + Vector3.new(sphere.Size.X / 2, sphere.Size.Y / 2, sphere.Size.Z / 2))
    local parts = workspace:FindPartsInRegion3WithIgnoreList(region, {player.Character, workspace.CurrentCamera, sphere}, math.huge)

    local isOnGround = false
    for _, part in ipairs(parts) do
        if part:IsA("BasePart") and part.Parent:IsA("Model") then
            sphere:Destroy()
            return true
        end
    end
    sphere:Destroy()
    return false
end

function FlightACheck()
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

                player:SetAttribute("Pitch", math.floor(pitch + 0.5))
                player:SetAttribute("HeadPitch", math.floor(headPitch + 0.5))
            end
        end
    end

    local function printFailedPlayers()
        for player, vl in pairs(violationLevels) do
            if vl > 0 then
                print(player.Name, "failed Flight (Angle) x" .. vl)
            end
        end
    end

    RunService.Stepped:Connect(function()
        for _, player in pairs(Players:GetPlayers()) do
            updateLeaningStatus(player)
        end
    end)

    local function onPlayerAdded(player)
        violationLevels[player] = 0
    end

    local function onPlayerRemoving(player)
        violationLevels[player] = nil
    end

    Players.PlayerAdded:Connect(onPlayerAdded)
    Players.PlayerRemoving:Connect(onPlayerRemoving)
    print('Running Flight A Check')
    while true do
        wait(0.1)

        for _, player in pairs(Players:GetPlayers()) do
            if player.Character and player.Character:FindFirstChild("Humanoid") and player.Character:FindFirstChild("Humanoid").Health > 0 then
                local pitch = player:GetAttribute("Pitch") or 0
                local headPitch = player:GetAttribute("HeadPitch") or 0

                if headPitch ~= 0 and pitch ~= 0 and headPitch == pitch and not isPlayerSitting(player) then
                    if not violationLevels[player] then
                        violationLevels[player] = -4
                    else
                        violationLevels[player] = violationLevels[player] + 1
                    end
                else
                    violationLevels[player] = -5
                end
            end
        end

        printFailedPlayers()
    end
end

function SpeedCheck()
    local playerSpeedData = {}
    local speedVL = {}
    while wait(0.1) do
        for _, player in pairs(game.Players:GetPlayers()) do
            local character = player.Character
            local humanoid = character and character:FindFirstChildOfClass("Humanoid")

            if humanoid then
                local currentPosition = character.HumanoidRootPart.Position
                local currentTimestamp = tick()

                local speedData = playerSpeedData[player] or {}

                if speedData.prevPosition and speedData.prevTimestamp then
                    -- Calculate the distance traveled in X and Z axes
                    local deltaX = currentPosition.X - speedData.prevPosition.X
                    local deltaZ = currentPosition.Z - speedData.prevPosition.Z

                    -- Calculate the time elapsed
                    local deltaTime = currentTimestamp - speedData.prevTimestamp

                    -- Calculate speed (distance / time)
                    local speedXZ = math.sqrt(deltaX^2 + deltaZ^2) / deltaTime
                    if speedXZ >= 28 then
                        if not speedVL[player] then
                            speedVL[player] = -4
                        else
                            speedVL[player] = speedVL[player] + 1
                        end
                    else
                        speedVL[player] = -5
                    end
                    if speedVL[player] > 0 then
                        print(player.Name, "failed Speed (Position) x" .. speedVL[player])
                    end
                end

                -- Update previous values for the next iteration
                playerSpeedData[player] = {
                    prevPosition = currentPosition,
                    prevTimestamp = currentTimestamp
                }
            end
        end
    end
end

function FlightBCheck()
    local characterConnections = {}
    local prevPositions = {}
    local vlCounts = {}
    local thresholdTicks = 5
    
    local function checkOnGround(player, character)
        if not character then
            return
        end
    
        local humanoid = character:FindFirstChildOfClass("Humanoid")
        local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
    
        if humanoid and humanoidRootPart then
            local rootPosition = humanoidRootPart.Position
            local isOnGround = strictAirCheck(player)
    
            if isOnGround or humanoid.Health <= 0 or humanoidRootPart.Position.Y < (prevPositions[player] and prevPositions[player].Y or 0) then
                vlCounts[player] = 0
            else
                vlCounts[player] = (vlCounts[player] or 0) + 1
    
                if vlCounts[player] >= thresholdTicks then
                    print(player.Name, "failed Flight (Float) x" .. math.max((vlCounts[player] or 0) - 4, 0))
                end
            end
    
            prevPositions[player] = humanoidRootPart.Position
        end
    end

    local function onCharacterAdded(player, char)
        local humanoid = char:WaitForChild("Humanoid")
        local characterConnection = humanoid:GetPropertyChangedSignal("Health"):Connect(function()
            checkOnGround(player, char)
        end)
    
        characterConnections[player] = characterConnection
        prevPositions[player] = char:FindFirstChild("HumanoidRootPart") and char:FindFirstChild("HumanoidRootPart").Position or Vector3.new()
    end
    
    local function onCharacterRemoving(player, char)
        local characterConnection = characterConnections[player]
        if characterConnection then
            characterConnection:Disconnect()
            characterConnections[player] = nil
            prevPositions[player] = nil
            vlCounts[player] = nil
        end
    end

    local function checkAllPlayers()
        for _, player in pairs(Players:GetPlayers()) do
            local character = player.Character
            if character then
                checkOnGround(player, character)
            end
        end
    end

    Players.PlayerAdded:Connect(function(player)
        local character = player.Character
        if character then
            onCharacterAdded(player, character)
        end

        vlCounts[player] = 0

        player.CharacterAdded:Connect(function(char)
            onCharacterAdded(player, char)
        end)

        player.CharacterRemoving:Connect(function(char)
            onCharacterRemoving(player, char)
        end)
    end)
    print('Running Flight B Check')
    while wait(0.1) do
        checkAllPlayers()
    end
end

local function runCoroutine(func)
    local co = coroutine.create(func)
    coroutine.resume(co)
    return co
end

local coFlightA = runCoroutine(FlightACheck)
local coFlightB = runCoroutine(FlightBCheck)
local coSpeed = runCoroutine(SpeedCheck)

while coroutine.status(coFlightA) ~= "dead" and coroutine.status(coFlightB) ~= "dead" and coroutine.status(coSpeed) do
    wait(0.1)
end
