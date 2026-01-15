-- loader.lua (STABLE, NO UI LIBS)

local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

-- ================= CONFIG =================
local API_BASE = "https://loquacious-tyrell-ferociously.ngrok-free.dev"
-- ==========================================

-- HWID
local function getHWID()
    return tostring(LocalPlayer.UserId)
end

-- API
local function verifyKey(key)
    local res = HttpService:PostAsync(
        API_BASE .. "/verify",
        HttpService:JSONEncode({
            key = key,
            hwid = getHWID()
        }),
        Enum.HttpContentType.ApplicationJson
    )
    return HttpService:JSONDecode(res)
end

local function fetchScript(key)
    return game:HttpGet(
        API_BASE .. "/script?key=" .. key .. "&hwid=" .. getHWID()
    )
end

-- ================= UI =================
local gui = Instance.new("ScreenGui")
gui.Name = "CelestialLoader"
gui.ResetOnSpawn = false
gui.Parent = PlayerGui

local frame = Instance.new("Frame", gui)
frame.Size = UDim2.fromScale(0.3, 0.25)
frame.Position = UDim2.fromScale(0.35, 0.35)
frame.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
frame.BorderSizePixel = 0

Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 12)

local title = Instance.new("TextLabel", frame)
title.Size = UDim2.new(1, 0, 0.25, 0)
title.Text = "Celestial Loader"
title.Font = Enum.Font.GothamBold
title.TextSize = 18
title.TextColor3 = Color3.new(1,1,1)
title.BackgroundTransparency = 1

local keyBox = Instance.new("TextBox", frame)
keyBox.Size = UDim2.new(0.9, 0, 0.2, 0)
keyBox.Position = UDim2.new(0.05, 0, 0.35, 0)
keyBox.PlaceholderText = "Enter your key (BB-XXXXXXX)"
keyBox.Text = ""
keyBox.Font = Enum.Font.Gotham
keyBox.TextSize = 14
keyBox.TextColor3 = Color3.new(1,1,1)
keyBox.BackgroundColor3 = Color3.fromRGB(35,35,40)
keyBox.BorderSizePixel = 0
Instance.new("UICorner", keyBox).CornerRadius = UDim.new(0, 8)

local button = Instance.new("TextButton", frame)
button.Size = UDim2.new(0.9, 0, 0.2, 0)
button.Position = UDim2.new(0.05, 0, 0.62, 0)
button.Text = "Verify & Load"
button.Font = Enum.Font.GothamBold
button.TextSize = 14
button.TextColor3 = Color3.new(1,1,1)
button.BackgroundColor3 = Color3.fromRGB(90, 70, 200)
button.BorderSizePixel = 0
Instance.new("UICorner", button).CornerRadius = UDim.new(0, 8)

local status = Instance.new("TextLabel", frame)
status.Size = UDim2.new(1, 0, 0.15, 0)
status.Position = UDim2.new(0, 0, 0.85, 0)
status.Text = ""
status.Font = Enum.Font.Gotham
status.TextSize = 12
status.TextColor3 = Color3.fromRGB(200,200,200)
status.BackgroundTransparency = 1

-- ================= LOGIC =================
button.MouseButton1Click:Connect(function()
    local key = keyBox.Text:gsub("%s+", "")
    if key == "" then
        status.Text = "❌ Please enter a key"
        return
    end

    status.Text = "⏳ Verifying..."

    local ok, result = pcall(function()
        return verifyKey(key)
    end)

    if not ok or not result then
        status.Text = "❌ API error"
        return
    end

    if not result.valid then
        status.Text = "❌ Invalid / expired key"
        return
    end

    status.Text = "✅ Verified! Loading..."

    local code = fetchScript(key)
    loadstring(code)()

    task.wait(0.5)
    gui:Destroy()
end)
