-- Loader (CelestialUI style)
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

local KEYS_URL = "https://raw.githubusercontent.com/YOURNAME/YOURREPO/main/keys.json"
local SCRIPT_URL = "https://raw.githubusercontent.com/YOURNAME/YOURREPO/main/core.lua"
local WEBHOOK = "https://discord.com/api/webhooks/XXXXX"

local Library = loadstring(game:HttpGet(
  "https://raw.githubusercontent.com/zh3e/CelestialUI/main/Source.lua"
))()

local ui = Library.new()
local tab = ui:create_tab("Loader", "")

-- HWID (Roblox-safe & stable)
local function getHWID()
    return tostring(LocalPlayer.UserId)
end

local function log(msg)
    pcall(function()
        HttpService:PostAsync(WEBHOOK, HttpService:JSONEncode({
            content = msg
        }))
    end)
end

local function fetchKeys()
    return HttpService:JSONDecode(game:HttpGet(KEYS_URL))
end

local module = tab:create_module({
    title = "Celestial Loader",
    description = "Enter your key",
    callback = function() end
})

local enteredKey = ""

module:create_textbox({
    title = "Key",
    placeholder = "XXXX-XXXX",
    callback = function(v)
        enteredKey = v
    end
})

module:create_button({
    title = "Verify & Load",
    callback = function()
        local db = fetchKeys()
        local data = db[enteredKey]

        if not data then
            log("❌ Invalid key: "..enteredKey)
            return
        end

        if data.expires ~= 0 and os.time() > data.expires then
            log("⌛ Expired key: "..enteredKey)
            return
        end

        local hwid = getHWID()
        if data.hwid and data.hwid ~= hwid then
            log("🔒 HWID mismatch: "..enteredKey)
            return
        end

        if not data.hwid then
            data.hwid = hwid
            log("🔗 HWID bound: "..enteredKey)
        end

        log("✅ Loaded by "..LocalPlayer.Name)
        loadstring(game:HttpGet(SCRIPT_URL))()
    end
})

ui:load()
