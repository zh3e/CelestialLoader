-- Loader (CelestialUI style | REST API)
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

-- 🔐 REST API
local API_URL = "http://YOUR_SERVER_IP:3000/verify"
local SCRIPT_URL = "https://raw.githubusercontent.com/YOURNAME/YOURREPO/main/core.lua"

-- Optional webhook (client-side, non-critical)
local WEBHOOK = "https://discord.com/api/webhooks/XXXXX"

local Library = loadstring(game:HttpGet(
  "https://raw.githubusercontent.com/zh3e/CelestialUI/main/Source.lua"
))()

local ui = Library.new()
local tab = ui:create_tab("Loader", "")

-- HWID (stable & Roblox-safe)
local function getHWID()
    return tostring(LocalPlayer.UserId)
end

local function log(msg)
    pcall(function()
        HttpService:PostAsync(
            WEBHOOK,
            HttpService:JSONEncode({ content = msg }),
            Enum.HttpContentType.ApplicationJson
        )
    end)
end

-- 🔎 Verify key via REST API
local function verifyKey(key)
    local body = HttpService:JSONEncode({
        key = key,
        hwid = getHWID()
    })

    local response = HttpService:PostAsync(
        API_URL,
        body,
        Enum.HttpContentType.ApplicationJson
    )

    return HttpService:JSONDecode(response)
end

-- UI
local module = tab:create_module({
    title = "Celestial Loader",
    description = "Enter your key",
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
        getgenv().BB_PRESET = v
    end
})

-- These are applied AFTER core.lua loads
module:create_textbox({
    title = "Import Config",
    placeholder = "Paste JSON here",
    callback = function(text)
        getgenv().BB_IMPORT_CONFIG = text
    end
})

module:create_button({
    title = "Export Config",
    callback = function()
        getgenv().BB_EXPORT_CONFIG = true
    end
})

module:create_button({
    title = "Verify & Load",
    callback = function()
        if enteredKey == "" then return end

        local result
        local ok, err = pcall(function()
            result = verifyKey(enteredKey)
        end)

        if not ok or not result then
            log("❌ API error for "..enteredKey)
            return
        end

        if not result.valid then
            log("❌ Key rejected (" .. (result.reason or "unknown") .. "): "..enteredKey)
            return
        end

        log("✅ Loaded by "..LocalPlayer.Name)

        local core = loadstring(game:HttpGet(SCRIPT_URL))
        core()

        -- Apply deferred config actions
        if getgenv().BB_IMPORT_CONFIG and ImportConfig then
            ImportConfig(getgenv().BB_IMPORT_CONFIG)
        end

        if getgenv().BB_EXPORT_CONFIG and ExportConfig then
            ExportConfig()
        end
    end
})

ui:load()
