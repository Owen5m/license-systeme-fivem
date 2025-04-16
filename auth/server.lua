local authorized = false
local checking = false

-- Webhook Discord URL
local discordWebhookURL = "YOUR WEBHOOK"

-- Utility function to get formatted date/time
local function getTime()
    return os.date("%Y-%m-%d %H:%M:%S")
end

-- Send rich and detailed logs to Discord
function sendDiscordLog(title, description, color, data)
    local fields = {}

    for key, value in pairs(data) do
        table.insert(fields, {
            name = tostring(key),
            value = "```" .. tostring(value) .. "```",
            inline = false
        })
    end

    local embed = {
        {
            ["color"] = color,
            ["title"] = title,
            ["description"] = description,
            ["fields"] = fields,
            ["footer"] = {
                ["text"] = "FiveM Authentication Logger • " .. getTime()
            }
        }
    }

    PerformHttpRequest(discordWebhookURL, function(err, text, headers)
    end, 'POST', json.encode({
        username = "FiveM Authentication System",
        embeds = embed
    }), { ['Content-Type'] = 'application/json' })
end

AddEventHandler('onResourceStart', function(resource)
    if GetCurrentResourceName() ~= resource then return end
    checking = true

    local license = Config.LicenseKey
    if license == "" or license == "YOUR_LICENSE_KEY_HERE" then
        print("[AUTH] License key is missing in config.lua.")
        sendDiscordLog("License Missing", "The license key is not configured in `config.lua`. Resource has been stopped.", 16711680, {
            Resource = GetCurrentResourceName(),
            Hostname = GetConvar("sv_hostname", "Unknown"),
            IP = GetConvar("endpoint_add_tcp", "Unknown")
        })
        StopResource(GetCurrentResourceName())
        return
    end

    local serverIp = GetConvar("endpoint_add_tcp", "127.0.0.1")

    PerformHttpRequest("https://localhost/api.php", function(statusCode, responseText, headers)
        checking = false

        local response = json.decode(responseText or "{}")

        local logData = {
            License = license,
            IP = serverIp,
            Resource = GetCurrentResourceName(),
            Hostname = GetConvar("sv_hostname", "Unknown"),
            ServerVersion = GetConvar("version", "unknown"),
            StatusCode = statusCode,
            RawResponse = responseText or "nil"
        }

        if statusCode == 200 and response.status == "OK" then
            authorized = true
            print("[AUTH] License validated successfully: " .. response.message)
            sendDiscordLog("License Validated", response.message, 3066993, logData)
        elseif statusCode == 200 and response.status == "KO" then
            print("[AUTH] License refused: " .. response.message)
            sendDiscordLog("License Refused", response.message, 16711680, logData)
            -- Stop the resource immediately if not authorized
            StopResource(GetCurrentResourceName())
        else
            print("[AUTH] Server error while checking license.")
            sendDiscordLog("License Server Error", "Failed to connect or bad response from license server.", 16711680, logData)
            -- Stop the resource immediately if the server cannot validate
            StopResource(GetCurrentResourceName())
        end
    end, "POST", json.encode({
        license = license,
        ip = serverIp
    }), { ["Content-Type"] = "application/json" })
end)

RegisterServerEvent("auth:check")
AddEventHandler("auth:check", function()
    if not authorized or checking then
        DropPlayer(source, "Unauthorized server. This resource is not licensed.")
        -- Stopping the resource when authentication fails
        StopResource(GetCurrentResourceName())
    end
end)
