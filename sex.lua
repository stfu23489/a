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
        partChecker.Size = Vector3.new(0.01, 0.01, 0.01)
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
    local Player = game.Players.LocalPlayer

    local function getPlayerCharacter()
        return Player.Character or Player.CharacterAdded:Wait()
    end
    
    local function getRootPart(character)
        return character:FindFirstChild("HumanoidRootPart")
    end
    
    local function getHumanoid(character)
        return character:FindFirstChild("Humanoid")
    end
    
    local character
    local humanoid
    local rootPart
    
    local lastVelocity = Vector3.new(0, 0, 0)
    local lastTime = tick()
    
    local function onCharacterAdded(newCharacter)
        character = newCharacter
        humanoid = getHumanoid(character)
        rootPart = getRootPart(character)
    end
    
    local function onCharacterRemoved()
        character = nil
        humanoid = nil
        rootPart = nil
    end
    
    Player.CharacterAdded:Connect(onCharacterAdded)
    Player.CharacterRemoving:Connect(onCharacterRemoved)
    
    while wait(0.1) do
        if not character or not humanoid or not rootPart then
            character = getPlayerCharacter()
            humanoid = getHumanoid(character)
            rootPart = getRootPart(character)
    
            if not character or not humanoid or not rootPart then
                print("Player character no longer exists.")
                continue  -- Skip the rest of the loop iteration if the player character is still missing
            end
        end
    
        local currentVelocity = rootPart.Velocity
        local currentTime = tick()
    
        local deltaVelocity = currentVelocity - lastVelocity
        local deltaTime = currentTime - lastTime
    
        local verticalAcceleration = math.round(deltaVelocity.Y / deltaTime*100)/100
    
        if verticalAcceleration ~= 0 then
            print("Vertical Acceleration:", verticalAcceleration)
        end
    
        lastVelocity = currentVelocity
        lastTime = currentTime
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

local function runCoroutine(func)
    local co = coroutine.create(func)
    coroutine.resume(co)
    return co
end

local coFlight = runCoroutine(FlightCheck)
local coSpeed = runCoroutine(SpeedCheck)

while coroutine.status(coFlight) ~= "dead" and coroutine.status(coSpeed) ~= "dead" do
    wait(0.1)
end
