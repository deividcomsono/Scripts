-- Credits to linsonder6 for helping with supporting Solara (https://github.com/linsonder6/DoorsClutch/blob/main/clutch.lua)
if game.GameId ~= 2440500124 then return end -- Universe ID

local cloneref = cloneref or function(o) return o end
local function GetService(name)
    return cloneref(game:GetService(name))
end

local firetouchtransmitter = firetouchtransmitter or firetouchinterest
local oldfireproximityprompt = fireproximityprompt
fireproximityprompt = function(prompt: ProximityPrompt)
    oldfireproximityprompt(prompt, 0)
    return oldfireproximityprompt(prompt, 1)
end

local Lighting = GetService("Lighting")
local PathfindingService = GetService("PathfindingService")
local Players = GetService("Players")
local ProximityPromptService = GetService("ProximityPromptService")
local ReplicatedStorage = GetService("ReplicatedStorage")
local RunService = GetService("RunService")
local SoundService = GetService("SoundService")
local TextChatService = GetService("TextChatService")
local UserInputService = GetService("UserInputService")

local Midnight, Flags = loadstring(game:HttpGet("https://raw.githubusercontent.com/deividcomsono/Midnight/main/Source.lua"))()

local Console = loadstring(game:HttpGet("https://raw.githubusercontent.com/mstudio45/MSDOORS/main/Utils/Console/Utility.lua"))() -- Made by Upio
local message = Console.custom_console_progressbar({
    msg = "[clutch.lua]: Loading...",
    img = "",
    clr = Color3.fromRGB(255, 255, 255),
    length = 5
})

if not game:IsLoaded() then
    game.Loaded:Wait(1)
end

if Players.LocalPlayer.PlayerGui:FindFirstChild("LoadingUI") and Players.LocalPlayer.PlayerGui.LoadingUI.Enabled then
    Midnight:Notify("Waiting for the game to load...", 3)

    repeat 
        task.wait()
    until not Players.LocalPlayer.PlayerGui.LoadingUI.Enabled
end

message.update_message_with_progress("[clutch.lua]: Creating variables...", 1)
-- #region Variables --
local RBXGeneral: TextChannel = TextChatService.TextChannels.RBXGeneral

local connections = {}
local objects = {}
local tracks = {}

local espTable = {
    ["Door"] = {},
    ["Entity"] = {},
    ["Objective"] = {},
    ["Item"] = {},
    ["Gold"] = {},
    ["Player"] = {},
    ["NoType"] = {},
}

local entitiesTable = {
    ["Entities"] = {
        "BackdoorRush", "BackdoorLookman", "RushMoving", "AmbushMoving", "Eyes", "Screech", "Halt", "JeffTheKiller", "A60", "A120"
    },

    ["Names"] = {
        ["BackdoorRush"] = "Blitz",
        ["BackdoorLookman"] = "Lookman",
        ["RushMoving"] = "Rush",
        ["AmbushMoving"] = "Ambush",
        ["JeffTheKiller"] = "Jeff The Killer"
    }
}
local itemsTable = {
    ["Names"] = {
        ["CrucifixWall"] = "Crucifix"
    }
}

local promptTable = {
    ["Aura"] = {
        ["ActivateEventPrompt"] = false,
        ["HerbPrompt"] = true,
        ["LootPrompt"] = false,
        ["ModulePrompt"] = true,
    },
    ["AuraFools"] = {
        ["UnlockPrompt"] = false
    },
    ["AuraPrompts"] = {},

    ["Clip"] = {
        "HerbPrompt",
        "HidePrompt",
        "LootPrompt",
        "ModulePrompt",
        "SkullPrompt",
        "UnlockPrompt",
        "Prompt"
    },
    ["ClipObjects"] = {
        "LeverForGate",
        "LiveHintBook",
        "LiveBreakerPolePickup"
    },

    ["Visible"] = {},

    ["Excluded"] = {
        "HintPrompt",
        "InteractPrompt"
    }
}

local exitKeycodes = {
    Enum.KeyCode.W,
    Enum.KeyCode.A,
    Enum.KeyCode.S,
    Enum.KeyCode.D
}

local holdAnim = Instance.new("Animation"); holdAnim.AnimationId = "rbxassetid://10479585177"
local throwAnim = Instance.new("Animation"); throwAnim.AnimationId = "rbxassetid://10482563149"
local twerkAnim = Instance.new("Animation"); twerkAnim.AnimationId = "rbxassetid://12874447851"

local holdingObj
local holdingJeff
local throwingObj = false

local camera = workspace.CurrentCamera

local localPlayer = Players.LocalPlayer
local mouse = localPlayer:GetMouse()
local alive = localPlayer:GetAttribute("Alive")

local character = localPlayer.Character
local humanoid
local rootPart
local collision
local collisionClone

local playerGui = localPlayer.PlayerGui

local mainUI = playerGui:WaitForChild("MainUI")
local rawMainGame = mainUI:WaitForChild("Initiator"):WaitForChild("Main_Game")

local permUI = playerGui:WaitForChild("PermUI")
local hints = permUI:WaitForChild("Hints")

local mainSoundGroup = SoundService:WaitForChild("Main")
local jamSoundEffect = mainSoundGroup:WaitForChild("Jamming")

local entityModules = ReplicatedStorage:WaitForChild("ClientModules"):WaitForChild("EntityModules")

local gameData = ReplicatedStorage:WaitForChild("GameData")
local floor = gameData:WaitForChild("Floor")
local latestRoom = gameData:WaitForChild("LatestRoom")

local isBackdoor = floor.Value == "Backdoor"
local isHotel = floor.Value == "Hotel"
local isFools = floor.Value == "Fools"
local isRetro = floor.Value == "Retro"
local isRooms = floor.Value == "Rooms"

local liveModifiers = ReplicatedStorage:WaitForChild("LiveModifiers")

local remotesFolder = isFools and ReplicatedStorage:WaitForChild("EntityInfo") or ReplicatedStorage:WaitForChild("RemotesFolder")

-- Auto Doors ---
local charPos = alive and character:GetPivot() or CFrame.new()
local downOffset = -8
local lastYBeforeOpening = 0

local currentRoom
local currentDoor
local doorPos

local path = PathfindingService:CreatePath()
local waypoints
local nextWaypointIndex
-- End --

type ESP = {
    Object: Instance,
    Text: string,
    Color: Color3,
    Offset: Vector3,
    IsEntity: boolean
}
-- #endregion --

message.update_message_with_progress("[clutch.lua]: Creating functions...", 2)
-- #region Functions --
function distanceFromCharacter(position)
    if typeof(position) == "Instance" then
        position = position:GetPivot().Position
    end

    if alive then
        return (rootPart.Position - position).Magnitude
    else
        return (camera.CFrame.Position - position).Magnitude
    end

    return 9e9
end

local function inCutscene(): boolean
    local dist = (camera.CFrame.Position - character.Head.Position).Magnitude
    return (dist > 1)
end

function isEntitySpawned(): boolean
    local entity = workspace:FindFirstChild("RushMoving") or workspace:FindFirstChild("AmbushMoving")

    if entity then
        if not entity.PrimaryPart then 
            repeat
                task.wait()
            until entity.PrimaryPart or not entity:IsDescendantOf(workspace)
        end

        if entity and distanceFromCharacter(entity:GetPivot().Position) < 2000 then
            return true
        end
    end

    return false
end
--

function isEyesSpawned(): boolean
    local eyes = nil

    if not isBackdoor then
        eyes = workspace:FindFirstChild("Eyes")
    else
        eyes = workspace:FindFirstChild("Lookman")
    end

    return eyes ~= nil
end

function enableBreaker(breaker, value)
    breaker:SetAttribute("Enabled", value)

    if value then
        breaker:FindFirstChild("PrismaticConstraint", true).TargetPosition = -0.2
        breaker.Light.Material = Enum.Material.Neon
        breaker.Light.Attachment.Spark:Emit(1)
        breaker.Sound.Pitch = 1.3
    else
        breaker:FindFirstChild("PrismaticConstraint", true).TargetPosition = 0.2
        breaker.Light.Material = Enum.Material.Glass
        breaker.Sound.Pitch = 1.2
    end

    breaker.Sound:Play()
end

function esp(params: ESP)
    local EspManager = {
        Type = params.Type or "NoType",
        Object = params.Object,
        Text = params.Text or "No Text",
        TextParent = params.TextParent or nil,
        Color = params.Color or Color3.new(0, 0, 0),

        Offset = params.Offset or Vector3.zero,
        IsEntity = params.IsEntity or false,

        rsConnection = nil
    }

    local tableIndex = #espTable[EspManager.Type] + 1

    local traceDrawing = Drawing.new("Line") do
        traceDrawing.Visible = false
        traceDrawing.Color = EspManager.Color
        traceDrawing.Thickness = 1
    end

    if EspManager.Object and EspManager.IsEntity and EspManager.Object.PrimaryPart.Transparency == 1 then
        EspManager.Object:SetAttribute("OldTransparency", EspManager.Object.PrimaryPart.Transparency)
        Instance.new("Humanoid", EspManager.Object)
        EspManager.Object.PrimaryPart.Transparency = 0.99
    end

    local highlight = Instance.new("Highlight") do
        highlight.Adornee = EspManager.Object
        highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
        highlight.FillColor = EspManager.Color
        highlight.FillTransparency = Flags["ESPFillTransparency"].Value
        highlight.OutlineColor = EspManager.Color
        highlight.OutlineTransparency = Flags["ESPOutlineTransparency"].Value
        highlight.Parent = EspManager.Object
    end

    local billboardGui = Instance.new("BillboardGui") do
        billboardGui.Adornee = EspManager.TextParent or EspManager.Object
		billboardGui.AlwaysOnTop = true
		billboardGui.ClipsDescendants = false
		billboardGui.Size = UDim2.new(0, 1, 0, 1)
		billboardGui.StudsOffset = EspManager.Offset
        billboardGui.Parent = EspManager.TextParent or EspManager.Object
	end

    local textLabel = Instance.new("TextLabel") do
		textLabel.BackgroundTransparency = 1
		textLabel.Font = Enum.Font.Oswald
		textLabel.Size = UDim2.new(1, 0, 1, 0)
		textLabel.Text = EspManager.Text
		textLabel.TextColor3 = EspManager.Color
		textLabel.TextSize = Flags["ESPTextSize"].Value
        textLabel.TextStrokeColor3 = Color3.new(0, 0, 0)
        textLabel.TextStrokeTransparency = 0.75
        textLabel.Parent = billboardGui
	end

    function EspManager:SetColor(newColor: Color3)
        EspManager.Color = newColor

        highlight.FillColor = newColor
        highlight.OutlineColor = newColor

        textLabel.TextColor3 = newColor

        if traceDrawing then
            traceDrawing.Color = newColor
        end
    end

    function EspManager.Delete()
        if EspManager.rsConnection then
            EspManager.rsConnection:Disconnect()
        end

        if EspManager.IsEntity and EspManager.Object and (EspManager.Object:IsA("Model") and EspManager.Object.PrimaryPart) then
            EspManager.Object.PrimaryPart.Transparency = EspManager.Object:GetAttribute("OldTransparency")
        end

        traceDrawing:Destroy()
        highlight:Destroy()
        billboardGui:Destroy()

        if espTable[EspManager.Type][tableIndex] then
            espTable[EspManager.Type][tableIndex] = nil
        end
    end

    EspManager.rsConnection = RunService.RenderStepped:Connect(function()
        if not EspManager.Object or not EspManager.Object:IsDescendantOf(workspace) or not (EspManager.Object:IsA("Model") and EspManager.Object:GetPivot().Position or EspManager.Object:IsA("BasePart") and EspManager.Object.Position) then
            EspManager.Delete()
            return
        end

        highlight.FillTransparency = Flags["ESPFillTransparency"].Value
        highlight.OutlineTransparency = Flags["ESPOutlineTransparency"].Value
        textLabel.TextSize = Flags["ESPTextSize"].Value
        
        if rawMainGame and rawMainGame:FindFirstChild("PromptService") then 
            local promptHighlight = rawMainGame.PromptService.Highlight

            if promptHighlight and promptHighlight.Adornee and (promptHighlight.Adornee == EspManager.Object or promptHighlight.Adornee.Parent == EspManager.Object.Parent) then
                promptHighlight.Adornee = nil
            end
        end

        if Flags["ESPShowDistance"].Value then
            textLabel.Text = string.format("%s\n[%s]", EspManager.Text, math.ceil(distanceFromCharacter(EspManager.Object:IsA("Model") and EspManager.Object:GetPivot().Position or EspManager.Object:IsA("BasePart") and EspManager.Object.Position)))
        else
            textLabel.Text = EspManager.Text
        end
        
        if Flags["ESPShowTracers"].Value then
            local vector, onScreen = camera:WorldToViewportPoint(EspManager.Object:IsA("Model") and EspManager.Object:GetPivot().Position or EspManager.Object:IsA("BasePart") and EspManager.Object.Position)

            if onScreen then
                traceDrawing.From = Vector2.new(camera.ViewportSize.X / 2, camera.ViewportSize.Y / 1)
                traceDrawing.To = Vector2.new(vector.X, vector.Y)
                traceDrawing.Visible = true
            else
                traceDrawing.Visible = false
            end
        else
            traceDrawing.Visible = false
        end
    end)

    espTable[EspManager.Type][tableIndex] = EspManager
    return EspManager
end

function addDoorEsp(room)
    local door = room:WaitForChild("Door")
    local locked = room:GetAttribute("RequiresKey")

    local isLibrary = room.Name == "49" or room.Name == "50"

    if door and door:GetAttribute("Opened") ~= true then
        local doorEsp = esp({
            Type = "Door",
            Object = ((isHotel or isFools) and isLibrary) and door or door:WaitForChild("Door"),
            Text = locked and string.format("Door %s [Locked]", room.Name + 1) or string.format("Door %s", room.Name + 1),
            Color = Flags["DoorESPColor"].Color
        })

        door:GetAttributeChangedSignal("Opened"):Connect(function()
            local value = door:GetAttribute("Opened")
            if doorEsp and value then doorEsp.Delete() end
        end)
    end
end

function addEntityEsp(entity)
    local entityName = getEntityName(entity)
            
    local entityEsp = esp({
        Type = "Entity",
        Object = entity,
        Text = entityName,
        TextParent = entity.Name == "JeffTheKiller" and entity.PrimaryPart or nil,
        Color = Flags["EntityESPColor"].Color,
        Offset = Vector3.new(0, 4, 0),
        IsEntity = entity.Name ~= "JeffTheKiller" and true or false
    })

    if entityName == "Eyes" then
        entity.PrimaryPart:WaitForChild("Ambience"):GetPropertyChangedSignal("Playing"):Connect(function()
            if not entity.PrimaryPart.Ambience.Playing then
                entityEsp.Delete()
            end
        end)

        task.delay(3, function()
            if not entity.PrimaryPart.Ambience.Playing then
                entityEsp.Delete()
            end
        end)
    end
end

function addObjectiveEsp(room)
    task.spawn(function()
        if not room:WaitForChild("Assets", 3) then return end

        if room:GetAttribute("RequiresKey") then
            local key = room:FindFirstChild("KeyObtain", true)

            if key then
                esp({
                    Type = "Objective",
                    Object = key,
                    Text = "Key",
                    Color = Flags["ObjectiveESPColor"].Color
                })
            end
        end

        if room.Assets:FindFirstChild("LeverForGate") then
            local lever = room.Assets.LeverForGate

            local esp = esp({
                Type = "Objective",
                Object = lever,
                Text = "Lever",
                Color = Flags["ObjectiveESPColor"].Color
            })

            lever.PrimaryPart:WaitForChild("SoundToPlay").Played:Connect(function()
                esp.Delete()
            end)
        elseif room.Name == "100" then
            local key = room.Assets:WaitForChild("ElectricalKeyObtain", 5)
            if key then
                esp({
                    Type = "Objective",
                    Object = key,
                    Text = "Key",
                    Color = Flags["ObjectiveESPColor"].Color
                })
            end
        end
    end)
end

function addItemEsp(item, drop)
    local itemName = itemsTable.Names[item.Name] or item.Name

    esp({
        Type = drop and "ItemDrop" or "Item",
        Object = item,
        Text = itemName,
        Color = Flags["ItemESPColor"].Color
    })
end

function addGoldEsp(gold)
    esp({
        Type = "Gold",
        Object = gold,
        Text = string.format("Gold Pile [%s]", gold:GetAttribute("GoldValue")),
        Color = Flags["GoldESPColor"].Color
    })
end

function addPlayerEsp(player)
    if player.Character.Humanoid.Health == 0 then return end

    local playerEsp = esp({
        Type = "Player",
        Object = player.Character,
        Text = string.format("%s [%s]", player.DisplayName, player.Character.Humanoid.Health),
        TextParent = player.Character:FindFirstChild("HumanoidRootPart"),
        Color = Flags["PlayerESPColor"].Color,
    })

    player.Character.Humanoid.HealthChanged:Connect(function(newHealth)
        if newHealth > 0 then
            playerEsp.Text = string.format("%s [%s]", player.DisplayName, newHealth)
        else
            playerEsp.Delete()
        end
    end)
end

function addRoomEsp(room)
    task.spawn(function()
        if Flags["ESPWhat"].Value.Door then
            addDoorEsp(room)
        end

        if Flags["ESPWhat"].Value.Objective then
            task.delay(room.Name == "50" and 3 or 1, addObjectiveEsp, room)
        end
    end)
end

function addRoomConnection(room)
    room.DescendantAdded:Connect(function(child)
        if child:IsA("BasePart") and (child.Parent and child.Parent.Name == "TriggerEventCollision" and child.Name == "Collision") then
            if #Players:GetPlayers() > 1 and Flags["FEAntiSeek"].Value and rootPart then
                local currentRoom = latestRoom.Value + 1

                task.spawn(function()
                    repeat
                        firetouchtransmitter(child, rootPart, 1)
                        task.wait()
                        firetouchtransmitter(child, rootPart, 0)
                    until not child or latestRoom.Value > currentRoom
                end)
            elseif Flags["AntiSeek"].Value then
                child.CanTouch = false
            end
        end

        task.delay(0, function()
            if child:IsA("ProximityPrompt") then
                if promptTable.Aura[child.Name] ~= nil and not child:FindFirstAncestor("Padlock") and not (isFools and child:FindFirstAncestor("KeyObtainFake")) and not (isRetro and child:FindFirstAncestor("RetroWardrobe")) then
                    table.insert(promptTable.AuraPrompts, child)
                end
                if isFools and promptTable.AuraFools[child.Name] ~= nil then
                    table.insert(promptTable.AuraPrompts, child)
                end
            end
        end)

        task.delay(0.1, function()
            if child:IsDescendantOf(workspace) and child:IsA("ProximityPrompt") then
                if not table.find(promptTable.Excluded, child.Name) then
                    if not child:GetAttribute("OriginalDistance") then
                        child:SetAttribute("OriginalDistance", child.MaxActivationDistance)
                    end
                    if not child:GetAttribute("OriginalEnabled") then
                        child:SetAttribute("OriginalEnabled", child.Enabled)
                    end
                    if not child:GetAttribute("OriginalClip") then
                        child:SetAttribute("OriginalClip", child.RequiresLineOfSight)
                    end
                    
                    child.MaxActivationDistance = child:GetAttribute("OriginalDistance") * Flags["PromptRangeBoost"].Value
                    
                    if isFools and Flags["InstaInteract"].Value then
                        if not child:GetAttribute("OriginalDuration") then
                            child:SetAttribute("OriginalDuration", child.HoldDuration)
                        end
    
                        child.HoldDuration = 0
                    end
    
                    if child:IsDescendantOf(workspace) and Flags["PromptClip"].Value and (table.find(promptTable.Clip, child.Name) or table.find(promptTable.ClipObjects, child.Parent.Name)) then
                        child.Enabled = true
                        child.RequiresLineOfSight = false
        
                        if child.Name == "ModulePrompt" then
                            child:GetPropertyChangedSignal("Enabled"):Connect(function()
                                if Flags["PromptClip"].Value then
                                    child.Enabled = true
                                end
                            end) 
                        end
                    end
                end
            end
    
            if inCutscene() and child.Name == "ElevatorBreaker" and Flags["AutoBreakerBox"].Value then
                local autoConnections = {}
                local using = false
    
                if not child:GetAttribute("DreadReaction") then
                    child:SetAttribute("DreadReaction", true)
                    using = true
    
                    if not (child:WaitForChild("SurfaceGui", 5) and child.SurfaceGui:WaitForChild("Frame", 5)) then return warn("Could not find elevator breaker gui") end
                    local code = child.SurfaceGui.Frame:WaitForChild("Code", 5)
    
                    local breakers = {}
                    for _, breaker in pairs(child:GetChildren()) do
                        if breaker.Name == "BreakerSwitch" then
                            local id = string.format("%02d", breaker:GetAttribute("ID"))
                            breakers[id] = breaker
                        end
                    end
    
                    if code and code:FindFirstChild("Frame") then   
                        local correct = child.Box.Correct
                        local used = {}
                        
                        autoConnections["Reset"] = correct:GetPropertyChangedSignal("Playing"):Connect(function()
                            if correct.Playing then
                                table.clear(used)
                            end
                        end)
    
                        autoConnections["Code"] = code:GetPropertyChangedSignal("Text"):Connect(function()
                            task.wait(0.1)
                            local newCode = code.Text
                            local isEnabled = code.Frame.BackgroundTransparency == 0
    
                            local breaker = breakers[newCode]
    
                            if newCode == "??" and #used == 9 then
                                for i = 1, 10 do
                                    local id = string.format("%02d", i)
    
                                    if not table.find(used, id) then
                                        breaker = breakers[id]
                                    end
                                end
                            end
    
                            if breaker then
                                table.insert(used, newCode)
                                if breaker:GetAttribute("Enabled") ~= isEnabled then
                                    enableBreaker(breaker, isEnabled)
                                end
                            end
                        end)
                    end
    
                    repeat
                        task.wait()
                    until not child or not Flags["AutoBreakerBox"].Value or not using
    
                    if child then child:SetAttribute("DreadReaction", nil) end
                end
    
                for _, connection in pairs(autoConnections) do
                    connection:Disconnect()
                end
            end

            if child.Name == "ScaryHaltCollision" and Flags["NotifyEntities"].Value["Halt"] then
                Midnight:Notify("Halt will spawn on next room!")
            end
    
            if Flags["ESPWhat"].Value.Entity then
                if child.Name == "FigureRagdoll" then
                    esp({
                        Type = "Entity",
                        Object = child,
                        Text = "Figure",
                        Color = Flags["EntityESPColor"].Color
                    })
                elseif child.Name == "Snare" then
                    esp({
                        Type = "Entity",
                        Object = child,
                        Text = "Snare",
                        Color = Flags["EntityESPColor"].Color
                    })
                end
            end
            if Flags["ESPWhat"].Value.Objective then
                if child.Name == "LiveHintBook" then
                    esp({
                        Type = "Objective",
                        Object = child,
                        Text = "Book",
                        Color = Flags["ObjectiveESPColor"].Color
                    })
                elseif child.Name == "LiveBreakerPolePickup" then               
                    esp({
                        Type = "Objective",
                        Object = child,
                        Text = "Breaker",
                        Color = Flags["ObjectiveESPColor"].Color
                    })
                end
            end
            if Flags["ESPWhat"].Value.Gold then
                if child.Name == "GoldPile" then
                    addGoldEsp(child)
                end  
            end

            if child:IsA("Model") and (child:GetAttribute("Pickup") or child:GetAttribute("PropType")) and not child:GetAttribute("JeffShop") then
                if child.Parent.Name == "Assets" and child.Parent.Parent:FindFirstChild("Green_Herb") then return end
                local itemName = itemsTable.Names[child.Name] or child.Name

                if Flags["ESPWhat"].Value.Item then
                    addItemEsp(child)
                end

                if Flags["NotifyItems"].Value then
                    Midnight:Notify(Flags["ItemChatMessage"].Text:gsub("{item}", itemName))

                    if Flags["ChatNotify"].Value then
                        RBXGeneral:SendAsync(Flags["ItemChatMessage"].Text:gsub("{item}", itemName))
                    end
                end    
            end

            if isRetro then
                if child.Name == "Lava" and Flags["AntiLava"].Value then
                    child.CanTouch = false
                end
            end

            if Flags["AntiObstructions"].Value then
                if child.Name == "HurtPart" then
                    child.CanTouch = false
                elseif child.Name == "AnimatorPart" then
                    child.CanTouch = false
                end
            end
            if Flags["AntiDupe"].Value and child.Name == "DoorFake" and child.Parent.Name:match("Closet") then
                disableDupe(child.Parent, true)
            end
            if Flags["AntiSnare"].Value and child.Name == "Snare" then
                child:WaitForChild("Hitbox", 5).CanTouch = false
            end
        end)
    end)

    task.delay(0.1, function()
        if room.Name == "50" and Flags["DeleteFigure"].Value then
            local figureSetup = room:WaitForChild("FigureSetup", 5)

            if figureSetup then
                local figure = figureSetup:WaitForChild("FigureRagdoll", 5)

                if figure and figure:WaitForChild("Root", 1) then
                    Midnight:Notify("Trying to delete figure...")

                    for _, part in pairs(figure:GetDescendants()) do
                        if part:IsA("BasePart") then
                            part.CanCollide = false
                        end
                    end

                    repeat
                        figure:PivotTo(figure.PrimaryPart.CFrame * CFrame.new(0, -1000, 0))
                        task.wait()
                    until not figure or latestRoom.Value > 49

                    if not figure then
                        Midnight:Notify("Figure has been deleted")
                    end
                end
            end
        end
    end)
end

function disableDupe(closet, value)
    local doorFake = closet:WaitForChild("DoorFake", 5)

    if doorFake then
        doorFake:WaitForChild("Hidden", 5).CanTouch = not value
        local lock = doorFake:WaitForChild("LockPart", 5)

        if lock and lock:FindFirstChild("UnlockPrompt") then
            lock.UnlockPrompt.Enabled = not value
        end
    end
end

function ghostPart(part)
    if Flags["GhostBody"].Value then
        part.LocalTransparencyModifier = Flags["BodyTransparency"].Value
    end
end

function ghostPlayer(character)
    for _, part in pairs(character:GetChildren()) do
        if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" then
            ghostPart(part)

            part:GetPropertyChangedSignal("LocalTransparencyModifier"):Connect(function()
                ghostPart(part)
            end)
        end
    end
end

function setupCharacterConnection(newCharacter, reloading)
    if not newCharacter then return warn("Invalid character") end

    character = newCharacter

    local bodyVelocity = Instance.new("BodyVelocity") do
        bodyVelocity.Velocity = Vector3.new(0, 0, 0)
        bodyVelocity.MaxForce = Vector3.new(9e9, 9e9, 9e9)
    end

    objects.bodyVelocity = bodyVelocity

    task.spawn(ghostPlayer, character)
    connections["CharacterChildAdded"] = character.ChildAdded:Connect(function(child)
        if child:IsA("BasePart") and child.Name ~= "HumanoidRootPart" then
            ghostPart(child)

            child:GetPropertyChangedSignal("LocalTransparencyModifier"):Connect(function()
                ghostPart(child)
            end)
        end

        if child:IsA("Tool") and child.Name:match("LibraryHintPaper") then
            task.wait()
            local code = table.concat(getPadlockCode(child))
            local output, count = code:gsub("_", "x")

            if Flags["AutoPadlock"].Value and tonumber(code) then
                remotesFolder.PL:FireServer(code)
            end

            if count < 5 then
                if Flags["NotifyPadlockCode"].Value then
                    Midnight:Notify(string.format("The padlock code is: %s", output))
                end
            end
        end
    end)

    connections["CharacterHiding"] = character:GetAttributeChangedSignal("LastHid"):Connect(function()
        lastHidden = character:GetAttribute("Hiding") and workspace:GetServerTimeNow() or 0
    end)

    humanoid = character:WaitForChild("Humanoid", 3)
    if humanoid then
        if humanoid.Health > 0 then
            task.delay(1, function()
                tracks.holdingObjTrack = humanoid:LoadAnimation(holdAnim)
                tracks.throwObjTrack = humanoid:LoadAnimation(throwAnim)
                tracks.twerkTrack = humanoid:LoadAnimation(twerkAnim)

                if Flags["Twerk"].Value then
                    tracks.twerkTrack:Play()
                end

                
            end)
        end

        connections["HumanoidDied"] = humanoid.Died:Connect(function()
            if collisionClone then
                collisionClone:Destroy()
            end
        end)
    end

    rootPart = character:WaitForChild("HumanoidRootPart", 3)
    if rootPart then
        if Flags["NoAcceleration"].Value then
            rootPart.CustomPhysicalProperties = PhysicalProperties.new(100, 0, 0, 0, 0)
        end

        if isFools then
            rootPart:GetPropertyChangedSignal("Anchored"):Connect(function()
                if Flags["AntiAnchor"].Value then
                    rootPart.Anchored = false
                end
            end)
        end
        
    end

    collision = character:WaitForChild("Collision", 3)
    if collision then
        collisionClone = collision:Clone()
        collisionClone.CanCollide = false
        collisionClone.Massless = true
        collisionClone.Name = "CollisionClone"
        if collisionClone:FindFirstChild("CollisionCrouch") then
            collisionClone.CollisionCrouch:Destroy()
        end
        collisionClone.Parent = character

        if Flags["UpsideDown"].Value then
            collision.Rotation = Vector3.new(collision.Rotation.X, collision.Rotation.Y, -90)
        end 
    end

    if reloading then
        Midnight:Notify("clutch.lua reloaded successfully!", 3)
    end
end

function setupOtherPlayerConnection(player)
    if not player then return warn("Invalid player") end

    if player.Character then
        if Flags["ESPWhat"].Value.Player then
            task.spawn(addPlayerEsp, player)
        end

        task.spawn(setupOtherCharacterConnection, player.Character)
    end

    connections[player.Name .. "CharacterAdded"] = player.CharacterAdded:Connect(function(newCharacter)
        task.delay(0.1, function()
            if not newCharacter then return end

            if Flags["ESPWhat"].Value.Player then
                task.spawn(addPlayerEsp, player)
            end

            task.spawn(setupOtherCharacterConnection, newCharacter)
        end)
    end)
end

function setupOtherCharacterConnection(character)
    if not character then return warn("Invalid character") end

    connections[character.Name .. "ChildAdded"] = character.ChildAdded:Connect(function(child)
        if child:IsA("Tool") and child.Name:match("LibraryHintPaper") then
            local code = table.concat(getPadlockCode(tool))
            local output, count = code:gsub("_", "x")

            if Flags["AutoPadlock"].Value and tonumber(code) then
                remotesFolder.PL:FireServer(code)
            end

            if count < 5 then
                if Flags["NotifyPadlockCode"].Value then
                    Midnight:Notify(string.format("The padlock code is: %s", output))
                end
            end
        end
    end)
end

function getEntityName(entity)
    local entityName = entitiesTable.Names[entity.Name] or entity.Name

    if isFools and entityName == "Rush" then
        entityName = entity.PrimaryPart.Name:gsub("New", "")
    end

    return entityName
end

function getEntitiesName()
    local names = {}

    for _, entity in pairs(entitiesTable.Entities) do
        local entityName = entitiesTable.Names[entity] or entity

        table.insert(names, entityName)
    end    

    return names
end

function getPadlockCode(paper)
    if paper and paper:FindFirstChild("UI") then
        local code = {}

        for _, image: ImageLabel in pairs(paper.UI:GetChildren()) do
            if image:IsA("ImageLabel") and tonumber(image.Name) then
                code[image.ImageRectOffset.X .. " " .. image.ImageRectOffset.Y] = {tonumber(image.Name), "_"}
            end
        end

        for _, image in pairs(hints:GetChildren()) do
            if image.Name == "Icon" then
                if code[image.ImageRectOffset.X .. " " .. image.ImageRectOffset.Y] then
                    code[image.ImageRectOffset.X .. " " .. image.ImageRectOffset.Y][2] = image.TextLabel.Text
                end
            end
        end

        local normalizedCode = {}
        for _, num in pairs(code) do
            normalizedCode[num[1]] = num[2]
        end

        return normalizedCode
    end

    return {}
end

function getLookCFrame(cf)
    local cfPos = cf.Position
    return CFrame.new(cfPos, cfPos - (Vector3.new(camera.CFrame.Position.X, cfPos.Y, camera.CFrame.Position.Z) - cfPos).Unit)
end
-- #endregion --

message.update_message_with_progress("[clutch.lua]: Creating library...", 3)
-- #region Library --
local Window = Midnight:CreateWindow({
    Title = "clutch.lua",
    SaveFolder = "clutch.lua"
})

local PlayerTab = Window:AddTab("Player") do
    local Speed = PlayerTab:AddElementToggle({
        Name = "Speed",
        Flag = "Speed"
    })

    Speed:AddSlider({
        Name = "Speed Boost",
        Flag = "SpeedBoost",
        Increment = 0.5,
        Min = 0,
        Max = isFools and 50 or 7,
    })

    Speed:AddDropdown({
        Name = "Mode",
        Flag = "SpeedMethod",
        AllowNull = false,
        Values = {"Boost", "WalkSpeed"},
        Value = "Boost",
        Callback = function()
            if humanoid then
                humanoid.WalkSpeed = 15
                humanoid:SetAttribute("SpeedBoostBehind", 0)
            end
        end
    })

    PlayerTab:AddElementToggle({
        Name = "Noclip",
        Flag = "Noclip"
    })

    PlayerTab:AddElementToggle({
        Name = "No Acceleration",
        Flag = "NoAcceleration",
        Callback = function(value)
            if rootPart then
                rootPart.CustomPhysicalProperties = value and PhysicalProperties.new(100, 0, 0, 0, 0) or PhysicalProperties.new(0.7, 0.7, 0, 1, 1)
            end
        end
    })

    local FlyToggle = PlayerTab:AddElementToggle({
        Name = "Fly",
        Flag = "Fly",
        Keybind = Enum.KeyCode.F,
        Callback = function(value)
            if humanoid then
                humanoid.PlatformStand = value
            end

            objects.bodyVelocity.Parent = value and rootPart or nil

            if value then
                while Flags["Fly"].Value and RunService.Heartbeat:Wait() do
                    local add = Vector3.zero

                    if UserInputService:IsKeyDown(Enum.KeyCode.W) then add += camera.CFrame.LookVector + (camera.CFrame.UpVector * Flags["FlyUpOffset"].Value) end
                    if UserInputService:IsKeyDown(Enum.KeyCode.S) then add -= camera.CFrame.LookVector + (camera.CFrame.UpVector * Flags["FlyUpOffset"].Value) end
                    if UserInputService:IsKeyDown(Enum.KeyCode.D) then add += camera.CFrame.RightVector end
                    if UserInputService:IsKeyDown(Enum.KeyCode.A) then add -= camera.CFrame.RightVector end
                    if UserInputService:IsKeyDown(Enum.KeyCode.Space) then add += camera.CFrame.UpVector end
                    if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then add -= camera.CFrame.UpVector end

                    objects.bodyVelocity.Velocity = add * Flags["FlySpeed"].Value * 22   
                end
            end
        end
    }) do
        FlyToggle:AddSlider({
            Name = "Fly Speed",
            Flag = "FlySpeed",
            Increment = 0.05,
            Min = 0.5,
            Max = isFools and 3 or 2,
            Value = 1
        })

        FlyToggle:AddSlider({
            Name = "Up Offset",
            Flag = "FlyUpOffset",
            Increment = 0.05,
            Max = 0.2,
            Value = 0
        })
    end

    PlayerTab:AddElementToggle({
        Name = "Fix Exit Delay",
        Flag = "FixExitDelay"
    })

    local Reach = PlayerTab:AddElementSection("Reach") do
        Reach:AddToggle({
            Name = "Door Reach",
            Flag = "DoorReach"
        })

        Reach:AddToggle({
            Name = "Prompt Clip",
            Flag = "PromptClip",
            Callback = function(value)
                for _, prompt: ProximityPrompt in pairs(workspace.CurrentRooms:GetDescendants()) do
                    if prompt:IsA("ProximityPrompt") and (table.find(promptTable.Clip, prompt.Name) or table.find(promptTable.ClipObjects, prompt.Parent.Name)) then
                        if value then
                            if not prompt:GetAttribute("OriginalEnabled") then
                                prompt:SetAttribute("OriginalEnabled", prompt.Enabled)
                            end
                            if not prompt:GetAttribute("OriginalClip") then
                                prompt:SetAttribute("OriginalClip", prompt.RequiresLineOfSight)
                            end

                            prompt.Enabled = true
                            prompt.RequiresLineOfSight = false
                        else
                            prompt.Enabled = prompt:GetAttribute("OriginalEnabled") or true
                            prompt.RequiresLineOfSight = prompt:GetAttribute("OriginalClip") or true
                        end
                    end
                end
            end
        })

        Reach:AddSlider({
            Name = "Prompt Range Boost",
            Flag = "PromptRangeBoost",
            Increment = 0.05,
            Min = 1,
            Max = 2,
            Callback = function(value)
                for _, prompt: ProximityPrompt in pairs(workspace.CurrentRooms:GetDescendants()) do
                    if prompt:IsA("ProximityPrompt") and not table.find(promptTable.Excluded, prompt.Name) then
                        if not prompt:GetAttribute("OriginalDistance") then
                            prompt:SetAttribute("OriginalDistance", prompt.MaxActivationDistance)
                        end

                        prompt.MaxActivationDistance = prompt:GetAttribute("OriginalDistance") * value
                    end
                end
            end
        })
    end

    local TrollingSection = PlayerTab:AddElementSection("Trolling") do
        TrollingSection:AddToggle({
            Name = "Twerk",
            Flag = "Twerk",
            Callback = function(value)
                if not humanoid then return end
    
                if value then                
                    tracks.twerkTrack:Play()
                else
                    tracks.twerkTrack:Stop()
                end
            end
        })

        TrollingSection:AddToggle({
            Name = "Upside Down",
            Flag = "UpsideDown",
            Callback = function(value)
                if not collision then return end

                local currentRotation = collision.Rotation
                if value then
                    collision.Rotation = Vector3.new(currentRotation.X, currentRotation.Y, -90)
                else
                    collision.Rotation = Vector3.new(currentRotation.X, currentRotation.Y, 90)
                end
            end
        })
    end

    local MiscSection = PlayerTab:AddElementSection("Misc") do
        MiscSection:AddButton({
            Name = "Die",
            DoubleClick = true,
            Callback = function()
                if not humanoid then return end
                humanoid.Health = 0
            end
        })

        MiscSection:AddButton({
            Name = "Revive",
            DoubleClick = true,
            Callback = function()
                remotesFolder.Revive:FireServer()
            end
        })

        MiscSection:AddButton({
            Name = "Play Again",
            DoubleClick = true,
            Callback = function()
                remotesFolder.PlayAgain:FireServer()

                local queueing = not localPlayer:GetAttribute("Ready")
                if queueing then
                    Midnight:Notify("Teleporting, click again to cancel")
                else
                    Midnight:Notify("Teleport canceled")
                end
            end
        })

        MiscSection:AddButton({
            Name = "Lobby",
            DoubleClick = true,
            Callback = function()
                remotesFolder.Lobby:FireServer()
            end
        })
    end
end

local ExploitTab = Window:AddTab("Exploits") do
    local oldNoclip = Flags["Noclip"].Value
    local NoclipBypassToggle = ExploitTab:AddElementToggle({
        Name = "Noclip Bypass",
        Flag = "NoclipBypass",
        Callback = function(value)
            if value then
                oldNoclip = Flags["Noclip"].Value

                Flags["Noclip"]:SetLocked(true)
                Flags["Noclip"]:Set(true)

                task.wait()
                
                if collision then
                    collision.Weld.C0 = CFrame.new(-Flags["NoclipBypassOffset"].Value, 0, 0) * CFrame.Angles(0, 0, math.rad(90))
                end
            else
                if collision then
                    collision.Weld.C0 = CFrame.new() * CFrame.Angles(0, 0, math.rad(90))
                end

                task.wait()

                Flags["Noclip"]:Set(oldNoclip)
                Flags["Noclip"]:SetLocked(false)
            end
        end
    }) do
        NoclipBypassToggle:AddSlider({
            Name = "Offset",
            Flag = "NoclipBypassOffset",
            Min = 7,
            Max = 10,
            Value = 8,
            Callback = function(value)
                if Flags["NoclipBypass"].Value and collision then
                    collision.Weld.C0 = CFrame.new(-value, 0, 0) * CFrame.Angles(0, 0, math.rad(90))
                end
            end
        })
    end

    local SpamOthersToolsToggle = ExploitTab:AddElementToggle({
        Name = "Spam Tools",
        Flag = "SpamTools",
        Mode = "Hold"
    }) do
        SpamOthersToolsToggle:AddDropdown({
            Name = "Mode",
            Flag = "SpamToolsMode",
            AllowNull = false,
            Values = {"Hold", "Toggle"},
            Value = Flags["SpamTools"].Mode,
            Callback = function(value)
                Flags["SpamTools"].Mode = value
            end
        })
    end

    local EntitiesSection = ExploitTab:AddElementSection("Bypass Entities") do
        EntitiesSection:AddToggle({
            Name = "Anti-Dupe",
            Flag = "AntiDupe",
            Callback = function(value)
                for _, room in pairs(workspace.CurrentRooms:GetChildren()) do
                    for _, closet in pairs(room:GetChildren()) do
                        if closet.Name:match("Closet") and closet:FindFirstChild("DoorFake") then
                            disableDupe(closet, value)
                        end
                    end
                end
            end
        })

        EntitiesSection:AddToggle({
            Name = "Anti-Eyes",
            Flag = "AntiEyes"
        })

        EntitiesSection:AddToggle({
            Name = "Anti-Snare",
            Flag = "AntiSnare",
            Callback = function(value)
                for _, room in pairs(workspace.CurrentRooms:GetChildren()) do
                    if not room:FindFirstChild("Assets") then return end
                    for _, snare in pairs(room.Assets:GetChildren()) do
                        if snare.Name == "Snare" then
                            snare:WaitForChild("Hitbox", 5).CanTouch = not value
                        end
                    end
                end
            end
        })

        EntitiesSection:AddToggle({
            Name = "Anti-Seek",
            Flag = "AntiSeek",
            Callback = function(value)
                for _, room in pairs(workspace.CurrentRooms:GetChildren()) do
                    if room:FindFirstChild("TriggerEventCollision") then
                        for _, part in pairs(room.TriggerEventCollision:GetChildren()) do
                            part.CanTouch = not value
                        end
                    end
                end
            end
        })

        EntitiesSection:AddToggle({
            Name = "Anti-Seek [FE]",
            Flag = "FEAntiSeek"
        })

        EntitiesSection:AddToggle({
            Name = "Anti-Obstructions",
            Flag = "AntiObstructions",
            Callback = function(value)
                for _, obstruction in pairs(workspace.CurrentRooms:GetDescendants()) do
                    if obstruction.Name == "HurtPart" then
                        obstruction.CanTouch = not value
                    elseif obstruction.Name == "AnimatorPart" then
                        obstruction.CanTouch = not value
                    end
                end
            end
        })

        EntitiesSection:AddToggle({
            Name = "Delete Figure",
            Flag = "DeleteFigure",
            Callback = function(value)
                if value and latestRoom.Value == 49 then
                    local figure = workspace.CurrentRooms:FindFirstChild("FigureRagdoll", true)

                    if figure then
                        Midnight:Notify("Trying to delete figure...")

                        for _, part in pairs(figure:GetDescendants()) do
                            if part:IsA("BasePart") then
                                part.CanCollide = false
                            end
                        end

                        repeat
                            task.wait()
                            figure:PivotTo(figure.PrimaryPart.CFrame * CFrame.new(0, -1000, 0))
                        until not figure or latestRoom.Value > 49

                        if not figure then
                            Midnight:Notify("Figure has been deleted")
                        end
                    end
                end
            end
        })
    
        EntitiesSection:AddToggle({
            Name = "No Screech",
            Flag = "NoScreech",
            Callback = function(value)
                for _, screech in pairs(camera:GetChildren()) do
                    if screech.Name:match("Screech") then
                        screech:Destroy()
                    end
                end

                if rawMainGame and rawMainGame:FindFirstChild("RemoteListener") then
                    local module = rawMainGame.RemoteListener:FindFirstChild("Screech", true) or rawMainGame.RemoteListener:FindFirstChild("OldScreech", true)

                    if module then
                        module.Name = value and "OldScreech" or "Screech"
                    end
                end
            end
        })

        EntitiesSection:AddToggle({
            Name = "No A-90",
            Flag = "NoA90",
            Callback = function(value)
                if rawMainGame and rawMainGame:FindFirstChild("RemoteListener") then
                    local module = rawMainGame.RemoteListener:FindFirstChild("A90", true) or rawMainGame.RemoteListener:FindFirstChild("OldA90", true)

                    if module then
                        module.Name = value and "OldA90" or "A90"
                    end
                end
            end
        })
    end
end

local VisualsTab = Window:AddTab("Visuals") do
    local GhostBodyToggle = VisualsTab:AddElementToggle({
        Name = "Ghost Body",
        Flag = "GhostBody",
        Callback = function(value)
            for _, part in pairs(character:GetChildren()) do
                if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" then
                    part.LocalTransparencyModifier = value and Flags["BodyTransparency"].Value or 0
                end
            end
        end
    }) do
        GhostBodyToggle:AddSlider({
            Name = "Body Transparency",
            Flag = "BodyTransparency",
            Increment = 0.05,
            Min = 0,
            Max = 1,
            Value = 0.5,
            Callback = function(value)
                if not Flags["GhostBody"].Value then return end

                for _, part in pairs(character:GetChildren()) do
                    if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" then
                        part.LocalTransparencyModifier = value
                    end
                end
            end
        })
    end

    local AmbientSection = VisualsTab:AddElementSection("Ambient") do
        AmbientSection:AddToggle({
            Name = "Fullbright",
            Flag = "Fullbright",
            Callback = function(value)
                if value then
                    Lighting.Ambient = Color3.new(1, 1, 1)
                else
                    if character then
                        Lighting.Ambient = workspace.CurrentRooms[localPlayer:GetAttribute("CurrentRoom")]:GetAttribute("Ambient")
                    else
                        Lighting.Ambient = Color3.fromRGB(67, 51, 56)
                    end
                end
            end
        })

        if liveModifiers:FindFirstChild("Fog") then
            AmbientSection:AddToggle({
                Name = "No Fog",
                Flag = "NoFog",
                Callback = function(value)
                    if value then
                        Lighting.Fog.Density = 0
                    else
                        Lighting.Fog.Density = 0.938
                    end
                end
            })
        end
    end

    local CamManipulation = VisualsTab:AddElementSection("Camera Manipulation") do    
        CamManipulation:AddSlider({
            Name = "Field Of View",
            Flag = "FOV",
            Value = 70,
            Min = 70,
            Max = 120
        })
    end

    local Esp = VisualsTab:AddElementSection("ESP") do
        Esp:AddDropdown({
            Name = "What",
            Flag = "ESPWhat",
            Multi = true,
            Values = {"Door", "Entity", "Objective", "Item", "Dropped Item", "Gold", "Player"},
            Callback = function(value, oldValue)
                if value.Door ~= oldValue.Door then
                    if value.Door then
                        for _, room in pairs(workspace.CurrentRooms:GetChildren()) do
                            addDoorEsp(room)
                        end
                    else
                        for _, esp in pairs(espTable.Door) do
                            esp.Delete()
                        end
                    end
                end

                if value.Entity ~= oldValue.Entity then
                    if value.Entity then
                        for _, child in pairs(workspace:GetChildren()) do
                            if child:IsA("Model") and table.find(entitiesTable.Entities, child.Name) and distanceFromCharacter(child:GetPivot().Position) < 2000 then
                                addEntityEsp(child)
                            end
                        end

                        for _, child in pairs(workspace.CurrentRooms:GetDescendants()) do
                            if child.Name == "FigureRagdoll" then
                                esp({
                                    Type = "Entity",
                                    Object = child,
                                    Text = "Figure",
                                    Color = Flags["EntityESPColor"].Color
                                })
                            elseif child.Name == "Snare" then
                                esp({
                                    Type = "Entity",
                                    Object = child,
                                    Text = "Snare",
                                    Color = Flags["EntityESPColor"].Color
                                })
                            end
                        end
                    else
                        for _, esp in pairs(espTable.Entity) do
                            esp.Delete()
                        end
                    end
                end

                if value.Objective ~= oldValue.Objective then
                    if value.Objective then
                        for _, room in pairs(workspace.CurrentRooms:GetChildren()) do
                            addObjectiveEsp(room)
                        end
                    else
                        for _, esp in pairs(espTable.Objective) do
                            esp.Delete()
                        end
                    end
                end

                if value.Item ~= oldValue.Item then
                    if value.Item then
                        for _, room in pairs(workspace.CurrentRooms:GetChildren()) do
                            if not room:FindFirstChild("Assets") then return end

                            for _, item in pairs(room.Assets:GetDescendants()) do
                                if item:IsA("Model") and (item:GetAttribute("Pickup") or item:GetAttribute("PropType")) and not item:GetAttribute("JeffShop") then
                                    addItemEsp(item)
                                end
                            end
                        end
                    else
                        for _, esp in pairs(espTable.Item) do
                            esp.Delete()
                        end
                    end
                end

                if value["Dropped Item"] ~= oldValue["Dropped Item"] then
                    if value["Dropped Item"] then
                        for _, item in pairs(workspace.Drops:GetChildren()) do
                            if item:IsA("Model") and (item:GetAttribute("Pickup") or item:GetAttribute("PropType")) and not item:GetAttribute("JeffShop") then
                                addItemEsp(item, true)
                            end
                        end
                    else
                        for _, esp in pairs(espTable.ItemDrop) do
                            esp.Delete()
                        end
                    end
                end

                if value.Gold ~= oldValue.Gold then
                    if value.Gold then
                        for _, room in pairs(workspace.CurrentRooms:GetChildren()) do
                            if not room:FindFirstChild("Assets") then return end

                            for _, gold in pairs(room.Assets:GetDescendants()) do
                                if gold.Name == "GoldPile" then
                                    addGoldEsp(gold)
                                end
                            end
                        end
                    else
                        for _, esp in pairs(espTable.Gold) do
                            esp.Delete()
                        end
                    end
                end

                if value.Player ~= oldValue.Player then
                    if value.Player then
                        for _, player in pairs(Players:GetPlayers()) do
                            if player == localPlayer or not player.Character then continue end
                            addPlayerEsp(player)
                        end
                    else
                        for _, esp in pairs(espTable.Player) do
                            esp.Delete()
                        end
                    end
                end
            end
        })

        Esp:AddDivider()

        Esp:AddColorPicker({
            Name = "Door ESP Color",
            Flag = "DoorESPColor",
            Color = Color3.new(0, 1, 1),
            Callback = function(color)
                for _, esp in pairs(espTable.Door) do
                    esp:SetColor(color)
                end
            end
        })

        Esp:AddColorPicker({
            Name = "Entity ESP Color",
            Flag = "EntityESPColor",
            Color = Color3.new(1, 0, 0),
            Callback = function(color)
                for _, esp in pairs(espTable.Entity) do
                    esp:SetColor(color)
                end
            end
        })

        Esp:AddColorPicker({
            Name = "Objective ESP Color",
            Flag = "ObjectiveESPColor",
            Color = Color3.new(0, 1, 0),
            Callback = function(color)
                for _, esp in pairs(espTable.Objective) do
                    esp:SetColor(color)
                end
            end
        })

        Esp:AddColorPicker({
            Name = "Item ESP Color",
            Flag = "ItemESPColor",
            Color = Color3.new(1, 0, 1),
            Callback = function(color)
                for _, esp in pairs(espTable.Item) do
                    esp:SetColor(color)
                end
            end
        })

        Esp:AddColorPicker({
            Name = "Gold ESP Color",
            Flag = "GoldESPColor",
            Color = Color3.new(1, 1, 0),
            Callback = function(color)
                for _, esp in pairs(espTable.Gold) do
                    esp:SetColor(color)
                end
            end
        })

        Esp:AddColorPicker({
            Name = "Player ESP Color",
            Flag = "PlayerESPColor",
            Color = Color3.new(1, 1, 1),
            Callback = function(color)
                for _, esp in pairs(espTable.Player) do
                    esp:SetColor(color)
                end
            end
        })

        Esp:AddDivider()

        Esp:AddToggle({
            Name = "Show Tracers",
            Flag = "ESPShowTracers",
            Value = false
        })

        Esp:AddToggle({
            Name = "Show Distance",
            Flag = "ESPShowDistance",
            Value = false
        })

        Esp:AddSlider({
            Name = "Text Size",
            Flag = "ESPTextSize",
            Min = 16,
            Max = 26,
            Value = 22,
        })

        Esp:AddSlider({
            Name = "Fill Transparency",
            Flag = "ESPFillTransparency",
            Increment = 0.05,
            Min = 0,
            Max = 1,
            Value = 0.5
        })

        Esp:AddSlider({
            Name = "Outline Transparency",
            Flag = "ESPOutlineTransparency",
            Increment = 0.05,
            Min = 0,
            Max = 1,
            Value = 0
        })
    end

    local Notifier = VisualsTab:AddElementSection("Notifier") do
        Notifier:AddToggle({
            Name = "Notify in Chat",
            Flag = "ChatNotify"
        })

        Notifier:AddToggle({
            Name = "Notify Padlock Code",
            Flag = "NotifyPadlockCode"
        })

        Notifier:AddDivider()

        Notifier:AddTextbox({
            Name = "Message",
            Flag = "EntityChatMessage",
            Text = "Entity '{entity}' has spawned!"
        })

        Notifier:AddDropdown({
            Name = "Entities",
            Flag = "NotifyEntities",
            Multi = true,
            Values = getEntitiesName()
        })

        Notifier:AddDivider()

        Notifier:AddTextbox({
            Name = "Message",
            Flag = "ItemChatMessage",
            Text = "Item '{item}' has spawned!"
        })

        Notifier:AddToggle({
            Name = "Notify Items",
            Flag = "NotifyItems"
        })

        Notifier:AddToggle({
            Name = "Notify Items Drop",
            Flag = "NotifyItemsDrop"
        })
    end

    --[[
    local HideTimer = VisualsTab:AddElementToggle({
        Name = "Hide Timer",
        Flag = "HideTimer"
    }) do
        HideTimer:AddSlider({
            Name = "Alert Minimum",
            Flag = "HideTimerMin",
            Increment = 1,
            Min = 1,
            Max = 10,
            Value = 5
        })

        HideTimer:AddToggle({
            Name = "AutoLeave",
            Flag = "AutoLeave"
        })

        HideTimer:AddSlider({
            Name = "Leave Minimum",
            Flag = "LeaveTimeMin",
            Increment = 0.05,
            Min = 0.3,
            Max = 1,
            Value = 0.5,
        })
    end]]
end

local AutomationTab = Window:AddTab("Automation") do
    local AutoInteractToggle = AutomationTab:AddElementToggle({
        Name = "Auto Interact",
        Flag = "AutoInteract",
        Keybind = Enum.KeyCode.R,
        Mode = "Hold"
    }) do
        AutoInteractToggle:AddDropdown({
            Name = "Mode",
            Flag = "AutoInteractMode",
            AllowNull = false,
            Values = {"Hold", "Toggle"},
            Value = "Hold",
            Callback = function(value)
                Flags["AutoInteract"].Mode = value
            end
        })

        AutoInteractToggle:AddToggle({
            Name = "Ignore Gold",
            Flag = "AutoInteractIgnoreGold"
        })
    end

    AutomationTab:AddElementToggle({
        Name = "Auto Padlock",
        Flag = "AutoPadlock",
        Callback = function(value)
            for _, player in pairs(Players:GetPlayers()) do
                if not player.Character then continue end
                
                local tool = player.Character:FindFirstChildOfClass("Tool")

                if tool and tool.Name:match("LibraryHintPaper") then
                    local code = table.concat(getPadlockCode(tool))
                    local output, count = code:gsub("_", "x")

                    if value and tonumber(code) then
                        remotesFolder.PL:FireServer(code)
                    end

                    if count < 5 then
                        if Flags["NotifyPadlockCode"].Value then
                            Midnight:Notify(string.format("The padlock code is: %s", output))
                        end
                    end
                end
            end
        end
    })

    AutomationTab:AddElementToggle({
        Name = "Auto Breaker Box",
        Flag = "AutoBreakerBox",
        Callback = function(value)
            if value then
                local autoConnections = {}
                local using = false

                if workspace.CurrentRooms:FindFirstChild("100") then
                    local elevatorBreaker = workspace.CurrentRooms["100"]:FindFirstChild("ElevatorBreaker")

                    if elevatorBreaker and not elevatorBreaker:GetAttribute("DreadReaction") then
                        elevatorBreaker:SetAttribute("DreadReaction", true)
                        using = true 

                        local code = elevatorBreaker:FindFirstChild("Code", true)

                        local breakers = {}
                        for _, breaker in pairs(elevatorBreaker:GetChildren()) do
                            if breaker.Name == "BreakerSwitch" then
                                local id = string.format("%02d", breaker:GetAttribute("ID"))
                                breakers[id] = breaker
                            end
                        end

                        if code and code:FindFirstChild("Frame") then
                            local correct = elevatorBreaker.Box.Correct
                            local used = {}
                            
                            autoConnections["Reset"] = correct:GetPropertyChangedSignal("Playing"):Connect(function()
                                if correct.Playing then
                                    table.clear(used)
                                end
                            end)

                            autoConnections["Code"] = code:GetPropertyChangedSignal("Text"):Connect(function()
                                task.wait(0.1)
                                local newCode = code.Text
                                local isEnabled = code.Frame.BackgroundTransparency == 0

                                local breaker = breakers[newCode]

                                if newCode == "??" and #used == 9 then
                                    for i = 1, 10 do
                                        local id = string.format("%02d", i)

                                        if not table.find(used, id) then
                                            breaker = breakers[id]
                                        end
                                    end
                                end

                                if breaker then
                                    table.insert(used, newCode)
                                    if breaker:GetAttribute("Enabled") ~= isEnabled then
                                        enableBreaker(breaker, isEnabled)
                                    end
                                end
                            end)
                        end
                    end

                    repeat
                        task.wait()
                    until not elevatorBreaker or not Flags["AutoBreakerBox"].Value or not using

                    if elevatorBreaker then elevatorBreaker:SetAttribute("DreadReaction", nil) end
                end

                for _, connection in pairs(autoConnections) do
                    connection:Disconnect()
                end
            end
        end
    })
end

if #liveModifiers:GetChildren() > 0 then
    local ModifiersTab = Window:AddTab("Modifiers") do
        if liveModifiers:FindFirstChild("Jammin") then
            ModifiersTab:AddElementToggle({
                Name = "No Jammin",
                Flag = "NoJammin",
                Callback = function(value)
                    if value then
                        rawMainGame.Health.Jam.Volume = 0
                        jamSoundEffect.Enabled = false
                    else
                        jamSoundEffect.Enabled = true
                        rawMainGame.Health.Jam.Volume = 0.45
                    end
                end
            })
        end
    end
end

if not isHotel then
    local FloorTab = Window:AddTab("Floor") do
        if isBackdoor then

        elseif isFools then
            PlayerTab:AddElementToggle({
                Name = "Anti-Anchor",
                Flag = "AntiAnchor",
                Callback = function(value)
                    if value and rootPart then
                        rootPart.Anchored = false
                    end
                end
            })

            FloorTab:AddElementToggle({
                Name = "Insta Interact",
                Flag = "InstaInteract",
                Callback = function(value)
                    for _, prompt in pairs(workspace.CurrentRooms:GetDescendants()) do
                        if prompt:IsA("ProximityPrompt") then
                            if value then
                                if not prompt:GetAttribute("OriginalDuration") then
                                    prompt:SetAttribute("OriginalDuration", prompt.HoldDuration)
                                end

                                prompt.HoldDuration = 0
                            else
                                prompt.HoldDuration = prompt:GetAttribute("OriginalDuration") or 0
                            end
                        end
                    end
                end
            })

            FloorTab:AddElementToggle({
                Name = "Auto Revive",
                Flag = "AutoRevive",
                Callback = function(value)
                    if value and not alive then
                        remotesFolder.Revive:FireServer()
                    end
                end
            })

            local GrabBananaToggle = FloorTab:AddElementToggle({
                Name = "Grab Banana",
                Flag = "GrabBanana",
                Callback = function(value)
                    if not value and holdingObj and holdingObj.Name == "BananaPeel" then
                        holdingObj = nil
                    end
                end
            }) do
                GrabBananaToggle:AddSlider({
                    Name = "Throw Power",
                    Flag = "BananaThrowPower",
                    Min = 5,
                    Max = 20,
                    Value = 6,
                })
            end

            local GrabJeffToggle =  FloorTab:AddElementToggle({
                Name = "Grab Jeff",
                Flag = "GrabJeff",
                Callback = function(value)
                    if not value and holdingJeff then
                        holdingObj = nil
                        holdingJeff = nil
                    end
                end
            }) do
                GrabJeffToggle:AddSlider({
                    Name = "Throw Power",
                    Flag = "JeffThrowPower",
                    Min = 5,
                    Max = 25,
                    Value = 10,
                })
            end

            local EntitiesSection = FloorTab:AddElementSection("Bypass Entities") do
                EntitiesSection:AddToggle({
                    Name = "Anti-Banana",
                    Flag = "AntiBanana",
                    Callback = function(value)
                        for _, banana in pairs(workspace:GetChildren()) do
                            if banana.Name == "BananaPeel" then
                                banana.CanTouch = not value
                            end
                        end
                    end
                })

                EntitiesSection:AddToggle({
                    Name = "Anti-Jeff",
                    Flag = "AntiJeff",
                    Callback = function(value)
                        for _, jeff in pairs(workspace:GetChildren()) do
                            if jeff.Name == "JeffTheKiller" then
                                for _, part in pairs(jeff:GetChildren()) do
                                    if part:IsA("BasePart") then
                                        part.CanTouch = not value
                                    end
                                end
                            end
                        end
                    end
                })
            end
        elseif isRetro then
            local EntitiesSection = FloorTab:AddElementSection("Bypass Entities") do
                EntitiesSection:AddToggle({
                    Name = "Anti-Lava",
                    Flag = "AntiLava",
                    Callback = function(value)
                        for _, room in pairs(workspace.CurrentRooms:GetChildren()) do
                            if room:FindFirstChild("ScaryLava") then
                                for _, lava in pairs(room.ScaryLava:GetDescendants()) do
                                    if lava:IsA("BasePart") then
                                        lava.CanTouch = not value
                                    end
                                end
                            end
                        end
                    end
                })
            end
        elseif isRooms then
        else
            FloorTab:AddElementSection("Floor not supported")
        end
    end
end

local SettingsTab = Window:AddTab("Settings") do
    Window:BuildSettingsElement(SettingsTab)

    local CreditsSection = SettingsTab:AddElementSection("Credits") do
        CreditsSection:AddLabel("mstudio45 - Grab Banana/Jeff and Twerk Emote")
        CreditsSection:AddLabel("upio - ESP and FE Anti Seek")
    end
end

Midnight.OnUnload = function()
    for _, prompt: ProximityPrompt in pairs(workspace.CurrentRooms:GetDescendants()) do
        if prompt:IsA("ProximityPrompt") and not table.find(promptTable.Excluded, prompt.Name) then
            prompt.MaxActivationDistance = prompt:GetAttribute("OriginalDistance") or 8
            prompt.Enabled = prompt:GetAttribute("OriginalEnabled") or true
            prompt.RequiresLineOfSight = prompt:GetAttribute("OriginalClip") or true
        end
    end

    Flags["Fly"]:Set(false)
    holdingObj = nil

    for _, obj in pairs(objects) do
        obj:Destroy()
    end

    for _, track in pairs(tracks) do
        track:Stop()
    end

    if rawMainGame and rawMainGame:FindFirstChild("RemoteListener") then
        local a90Module = rawMainGame.RemoteListener:FindFirstChild("OldA90", true)
        local screechModule = rawMainGame.RemoteListener:FindFirstChild("OldScreech", true)

        if a90Module then a90Module.Name = "A90" end
        if screechModule then screechModule.Name = "Screech" end
    end

    camera.FieldOfView = 70

    if character then
        Lighting.Ambient = workspace.CurrentRooms[localPlayer:GetAttribute("CurrentRoom")]:GetAttribute("Ambient")

        for _, part in pairs(character:GetChildren()) do
            if part:IsA("BasePart") then
                part.LocalTransparencyModifier = 0
            end
        end
    else
        Lighting.Ambient = Color3.fromRGB(67, 51, 56)
    end

    if humanoid then
        humanoid:SetAttribute("SpeedBoostBehind", 0)
        humanoid.WalkSpeed = 15
    end

    if rootPart then
        rootPart.CanCollide = true
    end

    if collision then
        collision.CanCollide = true
        if collision:FindFirstChild("CollisionCrouch") then
            collision.CollisionCrouch.CanCollide = false
        end
    end

    collisionClone:Destroy()

    for _, espType in pairs(espTable) do
        for _, esp in pairs(espType) do
            esp.Delete()
        end
    end

    for _, connection in pairs(connections) do
        connection:Disconnect()
    end
end

-- #endregion -

message.update_message_with_progress("[clutch.lua]: Adding Connections...", 4)
-- #region Connections --
task.spawn(setupCharacterConnection, character)

Midnight:AddConnection(workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(function()
    if workspace.CurrentCamera then
        camera = workspace.CurrentCamera
    end
end))

Midnight:AddConnection(camera.ChildAdded:Connect(function(child)
    if table.find(entitiesTable.Entities, child.Name) then
        local rawEntityName = entitiesTable.Names[child.Name] or child.Name
        local entityName = getEntityName(child)

        if Flags["NotifyEntities"].Value[rawEntityName] then
            Midnight:Notify(Flags["EntityChatMessage"].Text:gsub("{entity}", entityName))
        end
    end
end))

for _, room in pairs(workspace.CurrentRooms:GetChildren()) do
    task.spawn(addRoomConnection, room)
    task.spawn(function()
        for _, prompt in pairs(room:GetDescendants()) do
            if prompt:IsA("ProximityPrompt") then
                if promptTable.Aura[prompt.Name] ~= nil and not prompt:FindFirstAncestor("Padlock") and not (isFools and prompt:FindFirstAncestor("KeyObtainFake")) and not (isRetro and prompt:FindFirstAncestor("RetroWardrobe")) then
                    table.insert(promptTable.AuraPrompts, prompt)
                end
                if isFools and promptTable.AuraFools[prompt.Name] ~= nil then
                    table.insert(promptTable.AuraPrompts, prompt)
                end
            end
        end
    end)
end
Midnight:AddConnection(workspace.CurrentRooms.ChildAdded:Connect(function(room)
    task.spawn(addRoomConnection, room)
    addRoomEsp(room)
end))

for _, item in pairs(workspace.Drops:GetChildren()) do
    if Flags["ESPWhat"].Value["Dropped Item"] then
        task.spawn(addItemEsp, item, true)
    end

    task.spawn(function()
        local prompt = item:WaitForChild("ModulePrompt", 3)

        if prompt then
            if promptTable.Aura[prompt.Name] ~= nil then
                table.insert(promptTable.AuraPrompts, prompt)
            end
            if isFools and promptTable.AuraFools[prompt.Name] ~= nil then
                table.insert(promptTable.AuraPrompts, prompt)
            end
        end
    end)
end
Midnight:AddConnection(workspace.Drops.ChildAdded:Connect(function(child)
    local itemName = itemsTable.Names[child.Name] or child.Name

    if Flags["ESPWhat"].Value["Dropped Item"] then
        addItemEsp(child, true)
    end

    if Flags["NotifyItemsDrop"].Value then
        Midnight:Notify(Flags["ItemChatMessage"].Text:gsub("{item}", itemName))

        if Flags["ChatNotify"].Value then
            RBXGeneral:SendAsync(Flags["ItemChatMessage"].Text:gsub("{item}", itemName))
        end
    end

    task.spawn(function()
        local prompt = child:WaitForChild("ModulePrompt", 3)

        if prompt then
            if promptTable.Aura[prompt.Name] ~= nil then
                table.insert(promptTable.AuraPrompts, prompt)
            end
            if isFools and promptTable.AuraFools[prompt.Name] ~= nil then
                table.insert(promptTable.AuraPrompts, prompt)
            end
        end
    end)
end))

Midnight:AddConnection(workspace.ChildAdded:Connect(function(child)
    child.DescendantAdded:Connect(function(descendant)
        if isFools and Flags["AntiJeff"].Value and child.Name == "JeffTheKiller" and descendant:IsA("BasePart") then
            descendant.CanTouch = false
        end
    end)

    task.delay(0.1, function()
        if isFools then
            if Flags["AntiBanana"].Value and child.Name == "BananaPeel" then
                child.CanTouch = false
            end
        end
    
        if table.find(entitiesTable.Entities, child.Name) then
            task.spawn(function()
                repeat
                    task.wait()
                until distanceFromCharacter(child:GetPivot().Position) < 2000 or not child:IsDescendantOf(workspace)
    
                if child:IsDescendantOf(workspace) then 
                    local rawEntityName = entitiesTable.Names[child.Name] or child.Name
                    local entityName = getEntityName(child)
    
                    if Flags["ESPWhat"].Value.Entity then
                        addEntityEsp(child)
                    end  
    
                    if Flags["NotifyEntities"].Value[rawEntityName] then
                        Midnight:Notify(Flags["EntityChatMessage"].Text:gsub("{entity}", entityName))
    
                        if Flags["ChatNotify"].Value then
                            RBXGeneral:SendAsync(Flags["EntityChatMessage"].Text:gsub("{entity}", entityName))
                        end
                    end
                end
            end)
        end
    end)
end))

for _, player in pairs(Players:GetPlayers()) do
    if player == localPlayer then continue end

    task.spawn(setupOtherPlayerConnection, player)
end
Midnight:AddConnection(Players.PlayerAdded:Connect(function(player: Player)
    task.spawn(setupOtherPlayerConnection, player)
end))

Midnight:AddConnection(localPlayer:GetAttributeChangedSignal("Alive"):Connect(function()
    alive = localPlayer:GetAttribute("Alive")
    if not alive then
        Flags["Fly"]:Set(false)
    end

    if not isFools then return end
    while not alive and Flags["AutoRevive"].Value do
        task.wait(1)
        if alive then break end
        remotesFolder.Revive:FireServer()
    end
end))

Midnight:AddConnection(localPlayer.CharacterAdded:Connect(function(newCharacter)
    Midnight:Notify("Reloading clutch.lua...", 3)
    task.delay(1, setupCharacterConnection, newCharacter, true)
end))

Midnight:AddConnection(playerGui.ChildAdded:Connect(function(child)
    if child.Name == "MainUI" then
        task.wait()
        mainUI = child
        task.delay(1, function()
            if mainUI then
                rawMainGame = mainUI:WaitForChild("Initiator", 1):WaitForChild("Main_Game", 1)

                if rawMainGame then
                    if not rawMainGame:WaitForChild("RemoteListener", 1) then return end

                    if Flags["NoA90"].Value then
                        local module = rawMainGame.RemoteListener:FindFirstChild("A90", true)

                        if module then
                            module.Name = "OldA90"
                        end
                    end

                    if Flags["NoScreech"].Value then
                        local module = rawMainGame.RemoteListener:FindFirstChild("Screech", true)

                        if module then
                            module.Name = "OldScreech"
                        end
                    end
                end
            end
        end)
    end
end))

Midnight:AddConnection(Lighting:GetPropertyChangedSignal("Ambient"):Connect(function()
    if Flags["Fullbright"].Value then
        Lighting.Ambient = Color3.new(1, 1, 1)
    end
end))

Midnight:AddConnection(mouse.Button1Down:Connect(function()
    local target = mouse.Target

    if isFools and not holdingObj and target and ((Flags["GrabBanana"].Value and target.Name == "BananaPeel") or (Flags["GrabJeff"].Value and target:FindFirstAncestor("JeffTheKiller"))) and isnetworkowner(target) then
        local jeff = target:FindFirstAncestor("JeffTheKiller")
        
        if jeff then
            holdingJeff = jeff

            if not jeff.PrimaryPart:FindFirstChild("BodyGyro") then
                Instance.new("BodyGyro", jeff.PrimaryPart) 
            end        

            for _, part in pairs(jeff:GetChildren()) do
                if part:IsA("BasePart") then
                    part.CanTouch = false
                end
            end
        else
            if not target:FindFirstChild("BodyGyro") then
                Instance.new("BodyGyro", target) 
            end

            target.CanTouch = false
        end
        
        holdingObj = jeff and jeff.PrimaryPart or target
        tracks.holdingObjTrack:Play()
    elseif holdingObj and not throwingObj then
        throwingObj = true

        if tracks.holdingObjTrack then tracks.holdingObjTrack:Stop() end
        if tracks.throwObjTrack then
            tracks.throwObjTrack:Play()
            task.wait(0.5) 
        end

        if holdingObj:FindFirstChild("BodyGyro") then
            holdingObj.BodyGyro:Destroy()
        end

        local direction = (mouse.Hit.Position - holdingObj.Position).Unit
        local upwardVelocity = holdingJeff and Vector3.zero or Vector3.new(0, 0.1, 0)
        local velocity = (direction + upwardVelocity).Unit * ((holdingJeff and Flags["JeffThrowPower"].Value or Flags["BananaThrowPower"].Value) * 10)

        local savedJeff = holdingJeff
        local savedObj = holdingObj

        holdingObj.Velocity = velocity
        holdingObj = nil
        holdingJeff = nil

        throwingObj = false

        task.delay(0.01, function()
            if savedJeff then
                for _, part in pairs(savedJeff:GetChildren()) do
                    if part:IsA("BasePart") then
                        part.CanTouch = not Flags["AntiJeff"].Value
                    end
                end
            else
                savedObj.CanTouch = not Flags["AntiBanana"].Value
            end
        end)
    end
end))

Midnight:AddConnection(ProximityPromptService.PromptShown:Connect(function(prompt)
    if not table.find(promptTable.Visible, prompt) then
        table.insert(promptTable.Visible, prompt)
    end
end))

Midnight:AddConnection(ProximityPromptService.PromptHidden:Connect(function(prompt)
    local promptIndex = table.find(promptTable.Visible, prompt)
    if promptIndex then
        table.remove(promptTable.Visible, promptIndex)
    end
end))

Midnight:AddConnection(ProximityPromptService.PromptTriggered:Connect(function(prompt)
    local promptIndex = table.find(promptTable.Visible, prompt)
    if promptIndex then
        local fakePrompt = prompt:Clone()
        table.insert(promptTable.Visible, fakePrompt)

        task.delay(0.1, function()
            local fakeIndex = table.find(promptTable.Visible, fakePrompt)
            if fakeIndex then
                table.remove(promptTable.Visible, fakeIndex)
            end
        end)
    end
end))

Midnight:AddConnection(UserInputService.InputBegan:Connect(function(input: InputObject, gameProcessedEvent)
    if alive then
        if Flags["FixExitDelay"].Value and character:GetAttribute("Hiding") and table.find(exitKeycodes, input.KeyCode) and not gameProcessedEvent then
            remotesFolder.CamLock:FireServer()
            character:SetAttribute("Hiding", false)
        end
    end
end))

Midnight:AddConnection(RunService.RenderStepped:Connect(function(deltaTime)
    camera.FieldOfView = Flags["FOV"].Value

    if character then
        if alive then
            if holdingObj and isnetworkowner(holdingObj) then
                holdingObj.CFrame = character.RightHand.RightGripAttachment.WorldCFrame * (holdingJeff and CFrame.new(0, 0, -1) or CFrame.new())
                holdingObj.CanTouch = false
            else
                if tracks.holdingObjTrack and tracks.holdingObjTrack.IsPlaying then
                    tracks.holdingObjTrack:Stop()
                end
            end

            if humanoid then
                if Flags["Speed"].Value then
                    if Flags["SpeedMethod"].Value == "Boost" then
                        humanoid:SetAttribute("SpeedBoostBehind", Flags["SpeedBoost"].Value)
                    else
                        humanoid.WalkSpeed = 15 + Flags["SpeedBoost"].Value
                    end
                end
            end

            if Flags["AntiEyes"].Value and isEyesSpawned() then
                remotesFolder.MotorReplication:FireServer(0, -89, 0, false)
            end
        end

        if rootPart then
            rootPart.CanCollide = not Flags["Noclip"].Value
        end

        if collision then
            collision.CanCollide = not Flags["Noclip"].Value
            if collision:FindFirstChild("CollisionCrouch") then
                collision.CollisionCrouch.CanCollide = not Flags["Noclip"].Value
            end
        end

        if character:FindFirstChild("UpperTorso") then
            character.UpperTorso.CanCollide = not Flags["Noclip"].Value
        end
        if character:FindFirstChild("LowerTorso") then
            character.LowerTorso.CanCollide = not Flags["Noclip"].Value
        end

        if Flags["DoorReach"].Value and workspace.CurrentRooms:FindFirstChild(latestRoom.Value) then
            local door = workspace.CurrentRooms[latestRoom.Value]:FindFirstChild("Door")

            if door and door:FindFirstChild("ClientOpen") then
                door.ClientOpen:FireServer()
            end
        end

        if Flags["AutoInteract"].Value then
            for _, prompt in pairs(promptTable.AuraPrompts) do
                task.spawn(function()
                    local interactionName = promptTable.Aura[prompt.Name] and "Interactions" .. localPlayer.Name or "Interactions"
                    if prompt:GetAttribute(interactionName) then return end
    
                    local root = prompt:FindFirstAncestorWhichIsA("BasePart") or prompt:FindFirstAncestorWhichIsA("Model")
                    
                    if root and not (Flags["AutoInteractIgnoreGold"].Value and root.Name == "GoldPile" or root:GetAttribute("JeffShop")) then
                        if distanceFromCharacter(root) <= prompt.MaxActivationDistance then 
                            fireproximityprompt(prompt)
                        end
                    end
                end)
            end
        end
    end

    if Flags["SpamTools"].Value then
        for _, player in pairs(Players:GetPlayers()) do
            if player == localPlayer then continue end

            if player.Character then
                local tool = player.Character:FindFirstChildOfClass("Tool")

                if tool and tool:FindFirstChild("Remote") then
                    tool.Remote:FireServer()
                end
            end
        end
    end
end))
-- #endregion --

message.update_message("[clutch.lua]: Successfully loaded!", "rbxasset://textures/AudioDiscovery/done.png", Color3.fromRGB(51, 255, 85))
Midnight:LoadAutoloadConfig()
