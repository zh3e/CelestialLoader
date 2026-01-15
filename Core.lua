-- Blade Ball Core (Original)
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Stats = game:GetService("Stats")
local LocalPlayer = Players.LocalPlayer

local CurveHistory = {}
local HISTORY = 20

local function getPing()
    local net = Stats:FindFirstChild("Network")
    local s = net and net:FindFirstChild("ServerStatsItem")
    local p = s and s:FindFirstChild("Data Ping")
    return p and p:GetValue()/1000 or 0
end

local function getBall()
    local folder = workspace:FindFirstChild("Balls")
    if not folder then return end
    for _, b in pairs(folder:GetChildren()) do
        if b:GetAttribute("realBall") then
            return b
        end
    end
end

local function updateCurve(ball)
    CurveHistory[ball] = CurveHistory[ball] or {}
    table.insert(CurveHistory[ball], ball.Position)
    if #CurveHistory[ball] > HISTORY then
        table.remove(CurveHistory[ball], 1)
    end

    if #CurveHistory[ball] < 6 then return false, 0 end

    local deviation = 0
    for i = 2, #CurveHistory[ball]-1 do
        local a = (CurveHistory[ball][i] - CurveHistory[ball][i-1]).Unit
        local b = (CurveHistory[ball][i+1] - CurveHistory[ball][i]).Unit
        deviation += math.acos(math.clamp(a:Dot(b), -1, 1))
    end

    local strength = math.clamp(deviation / (#CurveHistory[ball] * 0.6), 0, 1)
    return strength > 0.25, strength
end

RunService.Heartbeat:Connect(function()
    local char = LocalPlayer.Character
    if not char or not char.PrimaryPart then return end

    local ball = getBall()
    if not ball then return end
    if ball:GetAttribute("target") ~= LocalPlayer.Name then return end

    local zoomies = ball:FindFirstChild("zoomies")
    if not zoomies then return end

    local vel = zoomies.VectorVelocity
    local speed = vel.Magnitude
    local dir = (char.PrimaryPart.Position - ball.Position).Unit
    local dot = dir:Dot(vel.Unit)

    if dot <= 0 then return end

    local curved, strength = updateCurve(ball)
    local ping = getPing()

    local delay = 0.035 + strength*0.07 + math.min(speed/1700, 0.055) + ping*0.6
    if curved then
        task.delay(delay, function()
            mouse1click()
        end)
    else
        if (char.PrimaryPart.Position - ball.Position).Magnitude < 30 then
            mouse1click()
        end
    end
end)

print("[CelestialHubl] Loaded")
