-- Celestial Core (Original)
if getgenv().BB_PRESET then
    ApplyPreset(getgenv().BB_PRESET)
end

local Config = {
    base_delay = 0.035,
    strength_scale = 0.07,
    speed_scale = 1700,
    ping_scale = 0.6,
    dot_scale = 0.25,
    parry_distance = 30
}

local HttpService = game:GetService("HttpService")
local CONFIG_FILE = "bladeball_config.json"

local function SaveConfig()
    if not writefile then return end
    writefile(CONFIG_FILE, HttpService:JSONEncode(Config))
end

local function LoadConfig()
    if not readfile or not isfile or not isfile(CONFIG_FILE) then return end
    local ok, data = pcall(function()
        return HttpService:JSONDecode(readfile(CONFIG_FILE))
    end)
    if ok then
        for k,v in pairs(data) do
            Config[k] = v
        end
    end
end

LoadConfig()

local Presets = {
    ["Balanced"] = {
        0.035, 0.07, 1700, 0.6, 0.25, 30
    },
    ["Low Ping"] = {
        0.025, 0.05, 2000, 0.4, 0.2, 28
    },
    ["High Ping"] = {
        0.05, 0.1, 1200, 1.0, 0.35, 38
    },
    ["Aggressive"] = {
        0.03, 0.09, 1500, 0.55, 0.22, 34
    }
}

local function ApplyPreset(name)
    local p = Presets[name]
    if not p then return end
    Config.base_delay = p[1]
    Config.strength_scale = p[2]
    Config.speed_scale = p[3]
    Config.ping_scale = p[4]
    Config.dot_scale = p[5]
    Config.parry_distance = p[6]
end

ApplyPreset("Balanced")

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

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

local debugGui = Instance.new("ScreenGui", LocalPlayer.PlayerGui)
debugGui.Name = "CurveDebug"

local label = Instance.new("TextLabel", debugGui)
label.Size = UDim2.new(0, 260, 0, 70)
label.Position = UDim2.new(0, 15, 0, 300)
label.BackgroundColor3 = Color3.fromRGB(20,20,25)
label.TextColor3 = Color3.new(1,1,1)
label.Font = Enum.Font.GothamBold
label.TextSize = 14
label.TextWrapped = true
label.Text = "Curve Debug"
Instance.new("UICorner", label).CornerRadius = UDim.new(0,10)

local function UpdateDebug(strength, delay)
    label.Text =
        ("Curve Strength: %.2f\nDelay: %.3f"):format(strength, delay)
end

do
    local expected = "Celestial Core"
    if not tostring(script):find(expected) then
        warn("Tamper detected.")
        return
    end

    local mt = getrawmetatable(game)
    if mt and not isreadonly(mt) then
        warn("Metatable modified.")
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
