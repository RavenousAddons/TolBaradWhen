local _, ns = ...
local L = {}
ns.L = L

setmetatable(L, { __index = function(t, k)
    local v = tostring(k)
    t[k] = v
    return v
end })

-- Global
L.Enabled = _G.VIDEO_OPTIONS_ENABLED
L.WarMode = _G.PVP_LABEL_WAR_MODE
L.TolBarad = _G.DUNGEON_FLOOR_TOLBARADWARLOCKSCENARIO0
L.Alliance = _G.FACTION_ALLIANCE
L.Horde = _G.FACTION_HORDE
L.WarbandWide = _G.ITEM_UPGRADE_DISCOUNT_TOOLTIP_ACCOUNT_WIDE

-- English
L.Version = "%s is the current version." -- ns.version
L.Install = "Thanks for installing version |cff%1$s%2$s|r!" -- ns.color, ns.version
L.Update = "Thanks for updating to version |cff%1$s%2$s|r!" -- ns.color, ns.version
L.UpdateFound = "Version %s is now available for download. Please update!" -- sentVersion
L.Help = "This Addon sets alerts for future battles when you're in " .. L.TolBarad .. " and tracks some statistics.\nThere are also some slash commands available:\n/tbw options - Open options window\n/tbw share - Share your timers with group members\n/tbw request - Request timers from group members\n/tbw wins - See your win record across all tracked battles"
L.AlertSet = "Timer has been set!"
L.AlertAnnounce = "starts in %s."
L.AlertShort = "starts in %s at %s."
L.AlertLong = "starts in %s minutes at %s."
L.AlertStart = "has started (at %s)!"
L.AlertStartElapsedAnnounce = "started %s ago."
L.AlertStartElapsed = "started %s ago at %s."
L.AlertStartUnsure = "started and may still be ongoing!"
L.AlertToggleWarmode = "You will have to set " .. L.WarMode .. " to %s to participate!"
L.WarningNoInfo = "Unfortunately, " .. L.TolBarad .. " information is unavailable here! You'll have to go to " .. L.TolBarad .. " or ask for a group member to share their data with you."
L.WarningNoData = "Your " .. L.TolBarad .. " data doesn't contain any upcoming alerts that you can share."
L.WarningDisabledShare = "You must enable sharing in Options in order to share your " .. L.TolBarad .. " data with group members."
L.WarningNoShare = "You must either be in a group or specify a channel (e.g. party, raid, guild) in order to share your " .. L.TolBarad .. " data."
L.WarningNoRequest = "You must either be in a group or specify a channel (e.g. party, raid, guild) in order to request " .. L.TolBarad .. " data."
L.WarningFastAnnounce = "You must wait %s seconds before announcing your " .. L.TolBarad .. " data again." -- integer
L.WarningFastShare = "You must wait %s seconds before sharing your " .. L.TolBarad .. " data again." -- integer
L.WarningFastRequest = "You must wait %s seconds before requesting " .. L.TolBarad .. " data again." -- integer
L.TimerPrint = L.TolBarad .. " (" .. L.WarMode .. ": %s, Control: %s)"
L.TimerRaidWarning = "The Battle for " .. L.TolBarad .. " (" .. L.WarMode .. ": %s, Control: %s)"
L.ReceivedRequest = "Received request from %s in %s"
L.WinRecord = "Win Record"
L.AddonCompartmentTooltip1 = "|cff" .. ns.color .. "Left-Click:|r Open Settings"
L.AddonCompartmentTooltip2 = "|cff" .. ns.color .. "Right-Click:|r Share Timers"
L.OptionsTitle1 = "When do you want to be alerted?"
L.OptionsTitle2 = "How do you want to be alerted?"
L.OptionsTitle3 = "Extra Options:"
L.OptionsWhenTooltip = "Sets up an alert %s the next battle." -- string
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
    },
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
L.DebugAnnouncedStart = "Announced start times in %s"
L.DebugReceivedRequest = "Received request from %s in %s"
L.DebugReceivedStart = "Received start times from %s in %s"
L.DebugReceivedVersion = "Received version from %s in %s"
L.DebugRequestedStart = "Requested start times in %s"
L.DebugSentVersion = "Sent version in %s"
L.DebugToggleOn = "%s = true (%ss timeout)"
L.DebugToggleOff = "%s = false"
L.DebugSharedStart = "Shared start times in %s"

-- Check locale and apply appropriate changes below
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
