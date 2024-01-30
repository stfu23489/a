local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

function isPlayerSitting(player)
    local character = player.Character
    if character and character:FindFirstChild("Humanoid") then
        local humanoid = character:FindFirstChild("Humanoid")
        return humanoid and humanoid:GetState() == Enum.HumanoidStateType.Seated
    end
    return false
end

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

function collisionCheck(player, type)
    local torso = player.Character and (player.Character:FindFirstChild("Torso") or player.Character:FindFirstChild("UpperTorso"))
    
    if not torso then 
        return true 
    end
    
    local partChecker = Instance.new("Part")
    partChecker.Anchored = true
    partChecker.CanCollide = false
    partChecker.Transparency = 1
    partChecker.Parent = workspace
    
    if type == 7 then
        partChecker.Size = Vector3.new(3, 6, 1.5)
    elseif type == 1 then
        partChecker.Size = Vector3.new(0.25, 0.25, 0.25)
    else
        print('oh noes a stinky mistake happened plz report to devs :((((((((')
    end
    
    local lookVector = torso.CFrame.lookVector
    local upVector = torso.CFrame.upVector
    partChecker.CFrame = CFrame.fromMatrix(torso.Position, lookVector:Cross(upVector), upVector, -lookVector)
    
    local region = Region3.new(partChecker.Position - Vector3.new(partChecker.Size.X / 2 + 0.1, partChecker.Size.Y / 2 + 0.1, partChecker.Size.Z / 2 + 0.1), partChecker.Position + Vector3.new(partChecker.Size.X / 2 + 0.1, partChecker.Size.Y / 2 + 0.1, partChecker.Size.Z / 2 + 0.1))
    local parts = workspace:FindPartsInRegion3WithIgnoreList(region, {player.Character, workspace.CurrentCamera, partChecker}, math.huge)

    local hasUnanchored = false
    local isOnGround = false

    for _, part in ipairs(parts) do
        if part:IsA("BasePart") and part.Parent:IsA("Model") and not (part.Parent:IsA("Player") and part.Parent == player) and not part.Anchored then
            hasUnanchored = true
            break
        elseif part:IsA("BasePart") and part.Parent:IsA("Model") and not (part.Parent:IsA("Player") and part.Parent == player) then
            isOnGround = true
        end
    end

    partChecker:Destroy()

    if hasUnanchored then
        return 'unanchored'
    else
        return isOnGround
    end
end

function FlightCheck()
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
    
            if collisionCheck(player,7) or humanoid.Health <= 0 or humanoidRootPart.Position.Y < (prevPositions[player] and prevPositions[player].Y or 0) then
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
    print('Running Flight Check')
    while wait(0.1) do
        checkAllPlayers()
    end
end

function SpeedCheck()
    local playerSpeedData = {}
    local speedVL = {}
    print('Running Speed Check')
    
    while wait(0.1) do
        for _, player in pairs(game.Players:GetPlayers()) do
            local character = player.Character

            if character then
                local humanoid = character:FindFirstChildOfClass("Humanoid")
                local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")

                if humanoid and humanoidRootPart then
                    local currentPosition = humanoidRootPart.Position
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
                        if speedXZ >= 28 and not isPlayerSitting(player) and collisionCheck(player,7) ~= 'unanchored' then
                            if not speedVL[player] then
                                speedVL[player] = -4
                            else
                                speedVL[player] = speedVL[player] + 1
                            end
                        else
                            speedVL[player] = -5
                        end

                        if speedVL[player] > 0 then
                            print(player.Name, "failed Speed (Basic) x" .. speedVL[player])
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
end

function NoclipCheck()
    noclipVL = {}
    print('Running Noclip Check')
    while wait(0.1) do
        for _, player in pairs(game.Players:GetPlayers()) do
            if collisionCheck(player, 1) == true and not isPlayerSitting(player) then
                if not noclipVL[player] then
                    noclipVL[player] = 1
                else
                    noclipVL[player] = noclipVL[player] + 1
                end
            else
                noclipVL[player] = 0
            end
            if noclipVL[player] > 0 then
                print(player.name, "failed Noclip (Collision) x" .. noclipVL[player])
            end
        end
    end
end

local function runCoroutine(func)
    local co = coroutine.create(func)
    coroutine.resume(co)
    return co
end

local coFlight = runCoroutine(FlightCheck)
local coSpeed = runCoroutine(SpeedCheck)
local coNoclip = runCoroutine(NoclipCheck)

while coroutine.status(coFlight) ~= "dead" and coroutine.status(coSpeed) ~= "dead" and coroutine.status(coNoclip) ~= "dead" do
    wait(0.1)
end
