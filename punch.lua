local function createTool()
    local Players = game:GetService("Players")
    local ReplicatedStorage = game:GetService("ReplicatedStorage")
    local UserInputService = game:GetService("UserInputService")

    local plr = Players.LocalPlayer
    tool = Instance.new("Tool", plr.Backpack)
    tool.GripPos = Vector3.new(0, 0, 0)
    tool.Name = "punch"
    local k = Instance.new("Part", tool)
    k.Name = "Handle"
    k.Size = Vector3.new(2, 2, 5)
    k.Material = Enum.Material.ForceField
    local l = Instance.new("Animation", tool)
    l.AnimationId = "rbxassetid://204062532"
    local m = plr.Character.Humanoid:LoadAnimation(l)
    local isEquipped = false
    local da = false

    function activateTool()
        if isLeftMouseDown and tool and isEquipped then
            m:Play()
            wait()
            da = true
            wait(0.5)
            da = false
            if isLeftMouseDown then
                activateTool()
            end
        end
    end

    k.Touched:Connect(function(n)
        if da then
            local o = n.Parent:FindFirstChildOfClass("Humanoid")
            if o then
                local p = Players:FindFirstChild(n.Parent.Name)
                if p and p.Name ~= "FunnyVideo15" then
                    for j = 1, 20 do
                        ReplicatedStorage.meleeEvent:FireServer(p)
                    end
                end
            end
        end
    end)

    tool.Equipped:Connect(function()
        isEquipped = true
        plr.Character.Humanoid.WalkSpeed = 50
    end)

    tool.Unequipped:Connect(function()
        isEquipped = false
        plr.Character.Humanoid.WalkSpeed = 16
    end)

    UserInputService.InputBegan:Connect(function(input, isProcessed)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            isLeftMouseDown = true
            activateTool()
        end
    end)

    UserInputService.InputEnded:Connect(function(input, isProcessed)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            isLeftMouseDown = false
        end
    end)
end

local function onCharacterAdded(character)
    character:WaitForChild("Humanoid")
    createTool()
end

game.Players.LocalPlayer.CharacterAdded:Connect(onCharacterAdded)

if game.Players.LocalPlayer.Character then
    onCharacterAdded(game.Players.LocalPlayer.Character)
end
