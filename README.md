# IP Lock System for FiveM - Full Setup Guide (With Remote PHP API)

This guide explains how to set up and use the IP Lock authentication system for FiveM scripts, where each license key is linked to **a single IP address**. It also includes instructions for setting up the **PHP API backend** that will communicate securely between your script and your MySQL database.

---

## 🔧 Requirements

- A remote web server with PHP support (Apache or Nginx)
- A remote MySQL database (can be the same server)
- A licensed FiveM script
- The following files:
  - `server.lua`
  - `client.lua`
  - `config.lua`
  - `fxmanifest.lua`
  - `api.php` (your PHP backend)

---

## 📁 File Structure

```
iplock-system/
├── api.php               # Remote PHP API (host on your webserver)
└── fivem-resource/
    ├── server.lua
    ├── client.lua
    ├── config.lua
    └── fxmanifest.lua
```

---

## 1. MySQL Database Setup

Create a MySQL database named `iplock` and execute the following SQL schema:

```sql
CREATE TABLE IF NOT EXISTS licenses (
    id INT AUTO_INCREMENT PRIMARY KEY,
    license VARCHAR(255) NOT NULL UNIQUE,
    ip VARCHAR(255),
    discord_id VARCHAR(255),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
```

---

## 2. PHP API Setup (api.php)

Upload this file to your **remote web server**, for example: `https://yourdomain.com/api.php`

```php
<?php
header('Content-Type: application/json');

$pdo = new PDO("mysql:host=localhost;dbname=iplock;charset=utf8", "db_user", "db_password");

$license = $_GET['license'] ?? null;
$ip = $_SERVER['REMOTE_ADDR'];

if (!$license) {
    echo json_encode(['status' => 'error', 'message' => 'License is required']);
    exit;
}

$stmt = $pdo->prepare("SELECT * FROM licenses WHERE license = ?");
$stmt->execute([$license]);
$data = $stmt->fetch(PDO::FETCH_ASSOC);

if (!$data) {
    echo json_encode(['status' => 'denied', 'message' => 'License not found']);
    exit;
}

if ($data['ip'] === null) {
    $stmt = $pdo->prepare("UPDATE licenses SET ip = ? WHERE license = ?");
    $stmt->execute([$ip, $license]);
    echo json_encode(['status' => 'granted', 'message' => 'IP assigned']);
    exit;
}

if ($data['ip'] === $ip) {
    echo json_encode(['status' => 'granted', 'message' => 'License and IP match']);
    exit;
}

echo json_encode(['status' => 'denied', 'message' => 'Invalid IP for this license']);
exit;
?>
```

> 🔐 **Secure your API** with rate limiting, a secret key, or .htaccess rules in production.

---

## 3. config.lua (Client-side)

```lua
Config = {}

Config.License = "YOUR_LICENSE_KEY_HERE"
```

This is the **only file the client edits**.

---

## 4. server.lua (Authentication System)

```lua
local licenseKey = Config.License
local apiURL = "https://yourdomain.com/api.php?license=" .. licenseKey

PerformHttpRequest(apiURL, function(statusCode, response, headers)
    if statusCode ~= 200 or not response then
        print("[IPLOCK] Server error or unreachable.")
        StopResource(GetCurrentResourceName())
        return
    end

    local data = json.decode(response)

    if data.status == "granted" then
        print("[IPLOCK] License is valid and IP accepted.")
    else
        print("[IPLOCK] License refused: " .. (data.message or "Unknown reason"))
        sendLogToDiscord(data.message or "Refused", licenseKey)
        StopResource(GetCurrentResourceName())
    end
end, "GET", "", { ["Content-Type"] = "application/json" })

function sendLogToDiscord(reason, license)
    local ip = GetConvar("sv_hostname", "unknown")
    local jsonData = json.encode({
        embeds = {{
            title = "IP Lock Authorization Log",
            description = "Authorization Failed",
            color = 16711680,
            fields = {
                { name = "License", value = license, inline = true },
                { name = "Reason", value = reason, inline = true },
                { name = "Server Name", value = ip, inline = false },
                { name = "Timestamp", value = os.date("%Y-%m-%d %H:%M:%S"), inline = false }
            }
        }}
    })

    PerformHttpRequest("YOUR_DISCORD_WEBHOOK_URL", function() end, "POST", jsonData, {
        ["Content-Type"] = "application/json"
    })
end
```

---

## 5. fxmanifest.lua

```lua
fx_version 'cerulean'
game 'gta5'

server_script 'server.lua'
client_script 'client.lua'
shared_script 'config.lua'
```

---

## 🔒 How It Works

1. Player starts the script.
2. `server.lua` contacts your remote `api.php` script with the provided license.
3. The API checks if the license exists.
4. If the license has no IP: it assigns the current server IP.
5. If the IP is already set:
   - If the current IP matches → access granted.
   - If not → script shuts down, Discord log is sent.

---

## 📝 Behavior Summary

- **One license = One IP.**
- **Automatic first-time binding** of the IP.
- If IP mismatch: script is terminated.
- Webhook logging is **fully detailed**, with license, IP, timestamp, and reason.

---

## 💡 Tips for Sellers

- Use phpMyAdmin or a custom panel to manage `iplock` entries.
- Only send `config.lua` to clients.
- Obfuscate `server.lua` using a tool like Luraph or Shrouder.
- Host `api.php` on a secure, private domain.
- Always enable HTTPS to prevent sniffing.

---

## ✅ Final Notes

- This system is extremely lightweight.
- Zero client setup (just drop the script).
- Full control remains in the hands of the script seller.
- Can be expanded with Discord bots, key managers, IP reset limits, etc.

---

## 📬 Support

Need extra features like:
- Client IP reset panel  
- Discord bot for license editing  
- HWID/IP Lock combo  
- Advanced logging system  
→ Contact the author or join the private support Discord.

---

> Secure your scripts. Protect your work. Authorize only trusted servers.
