-- loader.lua (CelestialUI)

local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

-- ===== CONFIG =====
local API_BASE = "https://loquacious-tyrell-ferociously.ngrok-free.dev"
-- ==================

-- HWID (stable & Roblox-safe)
local function getHWID()
    return tostring(LocalPlayer.UserId)
end

-- REST helpers
local function verifyKey(key)
    local body = HttpService:JSONEncode({
        key = key,
        hwid = getHWID()
    })

    local res = HttpService:PostAsync(
        API_BASE .. "/verify",
        body,
        Enum.HttpContentType.ApplicationJson
    )

    return HttpService:JSONDecode(res)
end

local function fetchScript(key)
    local url = API_BASE .. "/script?key=" .. key .. "&hwid=" .. getHWID()
    return game:HttpGet(url)
end

-- ===== UI =====
local Library = loadstring(game:HttpGet(
    "https://raw.githubusercontent.com/zh3e/CelestialUI/refs/heads/main/Source.lua"
))()

local ui = Library.new()
local tab = ui:create_tab("Loader", "")

local module = tab:create_module({
    title = "Celestial Loader",
    description = "Enter your key to load",
    callback = function() end
})

local enteredKey = ""

module:create_textbox({
    title = "Key",
    placeholder = "BB-XXXXXXX",
    callback = function(v)
        enteredKey = v
    end
})

module:create_dropdown({
    title = "Preset",
    options = {"Balanced", "Low Ping", "High Ping", "Aggressive"},
    callback = function(v)
        -- core.lua will read this
        getgenv().BB_PRESET = v
    end
})

module:create_button({
    title = "Verify & Load",
    callback = function()
        if not enteredKey or enteredKey == "" then
            warn("No key entered")
            return
        end

        local ok, result = pcall(function()
            return verifyKey(enteredKey)
        end)

        if not ok or not result then
            warn("API error")
            return
        end

        if not result.valid then
            warn("Key rejected:", result.reason or "unknown")
            return
        end

        -- Fetch & execute private script
        local code = fetchScript(enteredKey)
        loadstring(code)()
    end
})

ui:load()
