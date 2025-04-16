# IP Lock System for FiveM - Setup Guide

This guide explains how to configure and use the IP lock authentication system for FiveM scripts. The goal is to ensure that each license key is bound to a single server IP address, preventing unauthorized use or distribution of your scripts.

---

## 🔧 Requirements

- A remote MySQL server (can be local for testing)  
- A licensed FiveM script  
- The following files:  
  - `server.lua`  
  - `client.lua`  
  - `config.lua`  
  - `fxmanifest.lua`

---

## 📁 File Structure

```
myScript/
├── server.lua
├── client.lua
├── config.lua
├── fxmanifest.lua
```

---

## 1. MySQL Database Setup

Create a MySQL database (e.g., `iplock`) and run the following SQL command to set up the `licenses` table:

```sql
CREATE TABLE IF NOT EXISTS licenses (
    id INT AUTO_INCREMENT PRIMARY KEY,
    license VARCHAR(255) NOT NULL UNIQUE,
    ip VARCHAR(255),
    discord_id VARCHAR(255)
);
```

This table stores all license keys and the IP address each one is bound to.

---

## 2. Configuration (config.lua)

In `config.lua`, users must place their license key:

```lua
Config = {}

Config.License = "YOUR_LICENSE_KEY_HERE"
```

This file is sent to users and is the only editable part of the script.

---

## 3. Server Connection (server.lua)

The server script connects directly to your remote MySQL database. The IP verification process is as follows:

- If the license exists and has no IP assigned: the current server IP is saved to the database.
- If the license has a registered IP:
  - If it matches the current server's IP: access is granted.
  - If it doesn't match: the script will stop and refuse authentication.

All checks are done remotely to ensure complete control.

**Note**: The `server.lua` script must be obfuscated to protect your logic and database connection.

---

## 4. fxmanifest.lua Example

```lua
fx_version 'cerulean'
game 'gta5'

server_script 'server.lua'
client_script 'client.lua'
shared_script 'config.lua'
```

---

## 5. IP Lock Behavior

- A license key is valid for **one IP only**.  
- If a client tries to use the key on another server, the system will deny access.  
- If no IP is stored yet, it is automatically bound to the server that first runs the script.  
- Any changes to the IP must be made **manually by the seller** via the license database.

---

## 6. Webhook Logging (Optional)

The server script can send authentication logs to a Discord webhook using embeds. These logs can include:

- Server IP  
- License key  
- Timestamp  
- Authorization status  
- Player identifiers (if desired)

This feature is built into `server.lua`.

---

## ✅ Summary

- Each license is locked to a single IP.  
- Database access is controlled entirely by the script owner.  
- License key is the only input required from the client.  
- Full control over authentication and license management.

---

## 📬 Support

For advanced features, automation tools, or a management panel, contact the developer or join the support Discord.

---

> Secure your scripts. Protect your work. Authorize only trusted servers.
