-- loader.lua (CelestialUI - CLEAN & FIXED)

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

-- ===== LOAD UI LIBRARY SAFELY =====
local Library
do
    local ok, lib = pcall(function()
        return loadstring(game:HttpGet(
            "https://raw.githubusercontent.com/zh3e/CelestialUI/refs/heads/main/Source.lua"
        ))()
    end)

    if not ok or not lib then
        warn("[Celestial Loader] Failed to load UI library")
        return
    end

    Library = lib
end

-- ===== UI =====
local ui = Library.new()

local tab = ui:create_tab(
    "Loader",
    "rbxassetid://10723346959"
)

local module = tab:create_module({
    title = "Celestial Loader",
    description = "Paste your key below and click Verify & Load",
    section = "left",
    callback = function() end
})

local enteredKey = ""

-- 🔑 KEY INPUT (FIXED)
module:create_textbox({
    title = "Key",
    placeholder = "BB-XXXXXXX",
    callback = function(v)
        if type(v) ~= "string" then
            enteredKey = ""
            return
        end

        v = v:gsub("%s+", "") -- trim spaces
        enteredKey = v
    end
})

-- ▶ VERIFY BUTTON
module:create_button({
    title = "Verify & Load",
    callback = function()
        if not enteredKey or enteredKey == "" or enteredKey == "None" then
            warn("[Celestial Loader] Please enter a valid key")
            return
        end

        local ok, result = pcall(function()
            return verifyKey(enteredKey)
        end)

        if not ok or not result then
            warn("[Celestial Loader] API error")
            return
        end

        if not result.valid then
            warn("[Celestial Loader] Key rejected:", result.reason or "unknown")
            return
        end

        -- Fetch & execute private script
        local code = fetchScript(enteredKey)
        loadstring(code)()
    end
})

ui:load()
