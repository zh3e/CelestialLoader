-- Celestial Loader (FIXED & CLEAN)

local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

-- ======================
-- CONFIG
-- ======================
local API_BASE = "https://loquacious-tyrell-ferociously.ngrok-free.dev"

-- ======================
-- HWID
-- ======================
local function getHWID()
    return tostring(LocalPlayer.UserId)
end

-- ======================
-- API
-- ======================
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

-- ======================
-- UI
-- ======================
local Library = loadstring(game:HttpGet(
    "https://raw.githubusercontent.com/zh3e/CelestialUI/refs/heads/main/Source.lua"
))()

local ui = Library.new({
    title = "Celestial Loader"
})

local tab = ui:create_tab("Loader", "")

local enteredKey = ""

local module = tab:create_module({
    title = "Key System",
    description = "Paste your key below and click Verify & Load",
    callback = function() end
})

module:create_textbox({
    title = "Key",
    callback = function(value)
        enteredKey = tostring(value or "")
    end
})

module:create_button({
    title = "Verify & Load",
    callback = function()
        if enteredKey == "" then
            warn("No key entered")
            return
        end

        local ok, data = pcall(function()
            return verifyKey(enteredKey)
        end)

        if not ok then
            warn("API error")
            return
        end

        if not data.valid then
            warn("Key invalid:", data.reason)
            return
        end

        local code = fetchScript(enteredKey)
        loadstring(code)()
    end
})

ui:load()
