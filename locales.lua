local _, ns = ...
local L = {}
ns.L = L

setmetatable(L, { __index = function(t, k)
    local v = tostring(k)
    t[k] = v
    return v
end })

-- Default (English)
L.Version = "%s is the current version." -- ns.version
L.Install = "Thanks for installing version |cff%1$s%2$s|r!" -- ns.color, ns.version
L.Update = "Thanks for updating to version |cff%1$s%2$s|r!" -- ns.color, ns.version
L.UpdateFound = "Version %s is now available for download. Please update!" -- sentVersion
L.Help1 = "This AddOn runs without any manual input. The only thing you need to do is zone into Tol Barad to get alerts running."
L.Help3 = "You can share your Tol Barad timer with group members:\n/tb share"
L.Help3 = "You can also toggle sounds on and off:\n/tb sound"
L.AlertSet = "Timer has been set!"
L.Alert2Min = "begins in 2 minutes at %s!"
L.AlertStart = "has begun! 15 minutes remaining from %s."
L.AlertStartUnsure = "has begun!"
L.AlertShort = "begins in %sm%ss at %s."
L.AlertLong = "begins in %s minutes at %s."
L.Toggled = "Toggled %s: |cff%s|r"
L.NotAnOption = "That option doesn't exist.\nOptions are: %s"
L.Sound = "Sound alerts are now |cff%s|r."
L.WarningNoInfo = "Unfortunately, Tol Barad information is unavailable here! You'll have to go to Tol Barad or ask for a group member to share their data with you."
L.WarningNoData = "Your Tol Barad data doesn't contain any upcoming alerts that you can share."
L.WarningNoShare = "You must either be in a group or specify a channel (e.g. party, raid, guild) in order to share your Tol Barad data."
L.WarningFastShare = "You must wait a short time before sharing your Tol Barad data again."

-- Check locale and assign appropriate
local CURRENT_LOCALE = GetLocale()

-- German
if CURRENT_LOCALE == "deDE" then return end

-- Spanish
if CURRENT_LOCALE == "esES" then return end

-- Latin-American Spanish
if CURRENT_LOCALE == "esMX" then return end

-- French
if CURRENT_LOCALE == "frFR" then return end

-- Italian
if CURRENT_LOCALE == "itIT" then return end

-- Brazilian Portuguese
if CURRENT_LOCALE == "ptBR" then return end

-- Russian
if CURRENT_LOCALE == "ruRU" then return end

-- Korean
if CURRENT_LOCALE == "koKR" then return end

-- Simplified Chinese
if CURRENT_LOCALE == "zhCN" then return end

-- Traditional Chinese
if CURRENT_LOCALE == "zhTW" then return end

-- Swedish
if CURRENT_LOCALE == "svSE" then return end
