[[
Features:
- Anti Aim
- Auto Shoot (Wallbang)
- No Recoil & No Spread
- ESP

Known bugs:
- Knockback weapons have bad auto shoot.

- Made by deividcomsono
]]


-- Change 'false' to 'true' to enable the feature.
getgenv().debug_mode = false
getgenv().auto_shoot = false
getgenv().anti_aim = false
getgenv().no_recoil = false
getgenv().no_spread = false

getgenv().debug_print = function(...)
    if not debug_mode then return end
    print("[clutch.lua]", ...)
end
getgenv().debug_warn = function(...)
    if not debug_mode then return end
    warn("[clutch.lua]", ...)
end

local RunService = game:GetService("RunService")

local ESPLibrary = loadstring(game:HttpGet("https://raw.githubusercontent.com/mstudio45/MSESP/refs/heads/main/source.luau"))()
ESPLibrary.GlobalConfig.IgnoreCharacter = true

local RemotesTable = {}


local CharacterService
local PhysicsService
local BulletLibrary
local ReplicationController

local equipWeapon
local getFireDirection
local writeBuffer

getgenv().currentWeapon = nil

--// Functions \\--

local PlayerColor = Color3.new(0, 0.75, 0)
function CharacterESP(playerInfo)
    local Highlight = playerInfo.PlayerModel.Highlight
    Highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    Highlight.Enabled = true
    Highlight.FillColor = PlayerColor
    Highlight.FillTransparency = 0.5

    Highlight:GetPropertyChangedSignal("Enabled"):Connect(function()
        Highlight.Enabled = true
    end)
    Highlight:GetPropertyChangedSignal("FillColor"):Connect(function()
        Highlight.FillColor = PlayerColor
    end)
    Highlight:GetPropertyChangedSignal("FillTransparency"):Connect(function()
        Highlight.FillTransparency = 0.5
    end)

    ESPLibrary:Add({
        Name = playerInfo.Name,
        Model = playerInfo.PlayerModel.Model:WaitForChild("RootPart"):FindFirstChild("spine2", true),

        Color = Color3.new(1, 1, 1),
        TextSize = 16,

        ESPType = "Highlight",

        Tracer = {
            Enabled = true,
            Color = PlayerColor,
            From = "Bottom"
        },
        Arrow = {
            Enabled = true,
            Color = PlayerColor,
            CenterOffset = 160,
        }
    })
end

function ShowHitbox(info)
    local Part = Instance.new("Part")
    Part.Anchored = true
    Part.CanCollide = false
    Part.CanQuery = false
    Part.CanTouch = false
    Part.CastShadow = false
    Part.Transparency = 0
    Part.Parent = workspace

    local Connection
    Connection = RunService.RenderStepped:Connect(function()
        Part.CFrame = info.CFrame
        Part.Size = info.Size

        if not info.Weld._updateConnection.Connected then
            Part:Destroy()
            Connection:Disconnect()
        end
    end)
end

function HandlePlayer(playerInfo)
    for _, hitboxInfo in pairs(playerInfo.Hitboxes) do
        ShowHitbox(hitboxInfo)
    end

    CharacterESP(playerInfo)
end

function SimulateFire(GunInfo, Origin, Direction)
	local Hits = {}
	local Hit = false

    local Range = GunInfo.Range
    local Damage = GunInfo.Damage

    local WallbangCount = 0
    local FromWall = false

    local BulletOrigin = Origin

    while WallbangCount < BulletLibrary.MAX_WALLS and Damage > 0 do
        local HitPosition, _, HitResult, Material, HitboxInfo = PhysicsService:Raycast(BulletOrigin, Direction, Range, FromWall)
        if not HitPosition then
            break
        end

        local HitDistance = (BulletOrigin - HitPosition).Magnitude
        Range = Range - HitDistance

        if FromWall then
            Damage = Damage - HitDistance * PhysicsService:GetMaterialDensity(Material) / GunInfo.PenetrationPower * BulletLibrary.DROPOFF_COEFFICIENT
            WallbangCount += 1
            BulletOrigin = HitPosition
        else
            BulletOrigin = HitPosition + Direction * 0.01
        end

        if HitResult == "hitbox" then
            local HitPart = BulletLibrary.HITBOX_EQUIVALENTS[HitboxInfo._name]
            local MultipliedDamage = GunInfo.DamageMultipliers[HitPart]

            local HitInfo = Hits[HitboxInfo._parentEntity]
            if HitInfo then
                if GunInfo.DamageMultipliers[HitInfo[1]] < MultipliedDamage then
                    Hits[HitboxInfo._parentEntity] = {
                        HitPart,
                        HitPosition,
                        Vector2.zero,
                        Damage * MultipliedDamage * GunInfo.RangeModifier ^ ((GunInfo.Range - Range) / 500)
                    }
                end
            else
                Hits[HitboxInfo._parentEntity] = {
                    HitPart,
                    HitPosition,
                    Vector2.zero,
                    Damage * MultipliedDamage * GunInfo.RangeModifier ^ ((GunInfo.Range - Range) / 500)
                }
                Hit = true
            end
        end
        if Range <= 0 or Damage < 1 then
            break
        end
        if HitResult == "triangle" then
            FromWall = not FromWall
        end
    end

	if Hit then
		local HitsResult = {}
		local SimulationResult = { Origin, Direction, HitsResult }
        local Damages = {}

		for Entity, HitInfo in pairs(Hits) do
			table.insert(HitsResult, {
				Entity.Name, -- Player/Bot Name
				HitInfo[2], -- Hit Position
				HitInfo[3], -- Spread
				HitInfo[1] -- Hitbox Name
			})

            table.insert(Damages, HitInfo[4])
		end
		return SimulationResult, Damages
	end

    return nil
end

--// Load \\--

for _, v in pairs(getgc(true)) do
    if typeof(v) == "table" then
        if rawget(v, "PointInTimeToRender") then
            CharacterService = v
            getgenv().Collider = rawget(v, "Collider")
        elseif rawget(v, "Raycast") then
            PhysicsService = v
        elseif rawget(v, "MAX_WALLS") then
            BulletLibrary = v
        elseif rawget(v, "PlayerJoined") and rawget(v, "PlayerLeft") then
            ReplicationController = v
        elseif rawget(v, "_getFireDirection") then
            getFireDirection = rawget(v, "_getFireDirection")
        elseif rawget(v, "worldStateChanged") then
            RemotesTable = v
        elseif rawget(v, "Equipped") == true then
            getgenv().currentWeapon = v
        end
    elseif typeof(v) == "function" then
        local info = debug.getinfo(v)
        if info.name == "_equipWeapon" and info.short_src:match("BackpackController") then
            print("got here")
            equipWeapon = v
        elseif info.name == "_writeBuffer" and info.short_src:match("CharacterService") then
            writeBuffer = v
        end
    end
end

if equipWeapon then
    local hook; hook = hookfunction(equipWeapon, function(weaponTable, ...)
        getgenv().currentWeapon = weaponTable
        return hook(weaponTable, ...)
    end)
else
    debug_warn("Failed to find equipWeapon function")
end

if writeBuffer then
    getgenv().yaw = 0

    local hook; hook = hookfunction(writeBuffer, function(charInfo, ...)
        if getgenv().anti_aim then
            getgenv().yaw = if getgenv().yaw > 0 then 0 else math.pi

            charInfo.lX = -math.pi/2
            charInfo.lY = getgenv().yaw
            
            if not charInfo.c and (charInfo.x == 0 and charInfo.z == 0) and (Collider and Collider.Grounded) then
                charInfo.c = true
            end
        end
        
        return hook(charInfo, ...)
    end)
else
    debug_warn("Failed to find writeBuffer function")
end

-- No Spread + No Recoil
if getFireDirection then
    local hook; hook = hookfunction(getFireDirection, function(self, ...)
        local result = hook(self, ...)

        --// No Recoil
        if getgenv().no_recoil then
            self._visualRecoil = Vector2.zero
        end

        --// No Spread
        if getgenv().no_spread then
            return CFrame.identity
        end
        
        return result
    end)
else
    debug_warn("Failed to find getFireDirection function")
end

-- Auto Bhop
firesignal(RemotesTable["worldStateIndexChanged"].OnClientEvent, "pl_autobhop", true)


for _, playerInfo in pairs(ReplicationController.Players) do
    HandlePlayer(playerInfo)
end
ReplicationController.PlayerJoined:Connect(function(info)
    local playerInfo = ReplicationController.Players[info.UserId]
    if not playerInfo then return debug_warn("Failed to get player info") end

    HandlePlayer(playerInfo)
end)

RunService.RenderStepped:Connect(function()
    local _currentWeapon = getgenv().currentWeapon
    if not (getgenv().auto_shoot and _currentWeapon and _currentWeapon._bullet and _currentWeapon.Equipped) then return end

    local BulletTable = _currentWeapon._bullet
    for _, Player in pairs(ReplicationController.Players) do
        if not (not Player.Dead and Player.PlayerModel.Model.RootPart.Transparency == 0) then continue end

        task.spawn(function()
            local camPos = workspace.CurrentCamera.CFrame.Position
            local dest = (Player.PlayerModel.Model.RootPart.root.hip.spine3.neck.TransformedWorldCFrame * CFrame.new(0, 0.5, 0)).Position
            local lookVector = (dest - camPos).Unit

            local result, damages = SimulateFire(BulletTable, camPos, lookVector)
            if result then
                if damages[1] <= 0 then return end

                local maxDamage = _currentWeapon._stats.BaseDamage * _currentWeapon._stats.DamageMultipliers["Head"]
                if not _currentWeapon._stats.FullAuto and (damages[1] < Player.Health and (maxDamage >= 100 and damages[1] < 100)) then
                    return
                end

                if _currentWeapon._stats.Repel_Magnitude then
                    --Collider.Velocity = Collider.Velocity * Vector3.new(1, 0, 1) - (lookVector * _currentWeapon._stats.Repel_Magnitude)
                    RemotesTable["weaponEvent"]:FireServer(_currentWeapon._stats.Id, "f", CharacterService.PointInTimeToRender, _currentWeapon.Ammo, lookVector, result)
                else
                    RemotesTable["weaponEvent"]:FireServer(_currentWeapon._stats.Id, "f", CharacterService.PointInTimeToRender, _currentWeapon.Ammo, result)
                end
            end
        end)
    end
end)
