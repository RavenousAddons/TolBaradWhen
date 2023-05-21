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
L.Help2 = "You can share your Tol Barad timer with group members:\n/tb share"
L.AlertSet = "Timer has been set!"
L.AlertShort = "starts in %sm%ss at %s."
L.AlertLong = "starts in %s minutes at %s."
L.AlertStart = "has begun! 15 minutes remaining from %s."
L.AlertStartElapsed = "has begun! %sm%ss elapsed from %s."
L.AlertStartUnsure = "has begun!"
L.WarningNoInfo = "Unfortunately, Tol Barad information is unavailable here! You'll have to go to Tol Barad or ask for a group member to share their data with you."
L.WarningNoData = "Your Tol Barad data doesn't contain any upcoming alerts that you can share."
L.WarningDisabledShare = "You must enable sharing in Options in order to share your Tol Barad data with group members."
L.WarningNoShare = "You must either be in a group or specify a channel (e.g. party, raid, guild) in order to share your Tol Barad data."
L.WarningFastShare = "You must wait a short time before sharing your Tol Barad data again."
L.AddonCompartmentTooltip1 = "|cff" .. ns.color .. "Left-Click:|r Open Settings"
L.AddonCompartmentTooltip2 = "|cff" .. ns.color .. "Right-Click:|r Share Timers"
L.OptionsWhenTooltip = "Sets up an alert %s the next battle."
L.OptionsWhen = {
    [1] = {
        key = "alertStart",
        name = "Start of Battle",
        tooltip = L.OptionsWhenTooltip:format("for the start of"),
    },
    [2] = {
        key = "alert1Minute",
        name = "1 minute before",
        tooltip = L.OptionsWhenTooltip:format("1 minute before"),
    },
    [3] = {
        key = "alert2Minutes",
        name = "2 minutes before",
        tooltip = L.OptionsWhenTooltip:format("2 minutes before"),
    },
    [4] = {
        key = "alert5Minutes",
        name = "5 minutes before",
        tooltip = L.OptionsWhenTooltip:format("5 minutes before"),
    },
    [5] = {
        key = "alert10Minutes",
        name = "10 minutes before",
        tooltip = L.OptionsWhenTooltip:format("10 minutes before"),
    }
}
L.OptionsWhenCustom = {
    key = "alertCustomMinutes",
    name = "Custom Alert",
    tooltip = L.OptionsWhenTooltip:format("at a custom time before"),
    warning = "Requires a UI reload.",
}
L.OptionsHowTooltip = "When important alerts go off, they will be accompanied by a %s, in addition to the chat box alert."
L.OptionsHow = {
    [1] = {
        key = "sound",
        name = "Sounds",
        tooltip = L.OptionsHowTooltip:format("Sound"),
    },
    [2] = {
        key = "raidwarning",
        name = "Raid Warnings",
        tooltip = L.OptionsHowTooltip:format("Raid Warning"),
    },
    [3] = {
        key = "stopwatch",
        name = "Stopwatch",
        tooltip = L.OptionsHowTooltip:format("Stopwatch"),
    },
}
L.OptionsExtra = {
    [1] = {
        key = "share",
        name = "Sharing",
        tooltip = "Enables silently sharing of start times with group members.",
    },
    [2] = {
        key = "debug",
        name = "Debugging",
        tooltip = "Enables messages for debugging.",
    },
}

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
