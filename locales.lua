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
L.Disabled = _G.VIDEO_OPTIONS_DISABLED
L.WarMode = _G.PVP_LABEL_WAR_MODE
L.TolBarad = _G.DUNGEON_FLOOR_TOLBARADWARLOCKSCENARIO0
L.Alliance = _G.FACTION_ALLIANCE
L.Horde = _G.FACTION_HORDE
L.WarbandWide = _G.ITEM_UPGRADE_DISCOUNT_TOOLTIP_ACCOUNT_WIDE

-- English
L.Version = "%s is the current version." -- ns.version
L.Install = "Thanks for installing version |cff%1$s%2$s|r!" -- ns.color, ns.version
L.UpdateFound = "Version %s is now available for download. Please update!" -- sentVersion
L.Help = "This Addon sets alerts for future battles when you're in " .. L.TolBarad .. " and tracks some statistics.|nThere are also some slash commands available:|n/tbw options - Open options window|n/tbw share - Share your timers with group members|n/tbw request - Request timers from group members|n/tbw wins - See your win record across all tracked battles"
L.AlertSet = "Timers have been set!"
L.AlertAnnounce = "starts in %s."
L.AlertShort = "starts in %s at %s."
L.AlertLong = "starts in %s minutes at %s."
L.AlertStart = "has started (at %s)!"
L.AlertStartElapsedAnnounce = "started %s ago."
L.AlertStartElapsed = "started %s ago at %s."
L.AlertStartUnsure = "started and may still be ongoing!"
L.AlertToggleWarmode = "You will have to set " .. L.WarMode .. " to %s to participate!"
L.NMinutes = "%s minutes"
L.WarningNoInfo = "Unfortunately, " .. L.TolBarad .. " information is unavailable here! You'll have to go to " .. L.TolBarad .. " or ask for a group member to share their data with you."
L.WarningNoData = "Your " .. L.TolBarad .. " data doesn't contain any upcoming alerts that you can share."
L.WarningDisabledShare = "You must enable sharing in Options in order to share your " .. L.TolBarad .. " data with group members."
L.WarningNoShare = "You must either be in a group or specify a channel (e.g. party, raid, guild) in order to share your " .. L.TolBarad .. " data."
L.WarningNoRequest = "You must either be in a group or specify a channel (e.g. party, raid, guild) in order to request " .. L.TolBarad .. " data."
L.WarningFastAnnounce = "You must wait %s seconds before announcing your " .. L.TolBarad .. " data again." -- integer
L.WarningFastShare = "You must wait %s seconds before sharing your " .. L.TolBarad .. " data again." -- integer
L.WarningFastRequest = "You must wait %s seconds before requesting " .. L.TolBarad .. " data again." -- integer
L.AlertDetail = "(Control: %s, " .. L.WarMode .. ": %s)"
L.TimerAlert = L.TolBarad .. " " .. L.AlertDetail
L.TimerRaidWarning = "The Battle for " .. L.TolBarad .. " " .. L.AlertDetail
L.ReceivedRequest = "Received request from %s in %s"
L.WinRecord = "Win Record"
L.DebugEnabled = "Debugging toggle enabled in Addon options. Reload your UI to see it."
L.Units = {
    minute = {
        s = "minute",
        p = "minutes",
        a = "min.",
        t = "m",
    },
    second = {
        s = "second",
        p = "seconds",
        a = "sec.",
        t = "s",
    },
}
L.AddonCompartmentTooltip1 = "|cff" .. ns.color .. "Left-Click:|r Open Settings"
L.AddonCompartmentTooltip2 = "|cff" .. ns.color .. "Right-Click:|r Share Timers"
L.OptionsTitle1 = "When do you want to be alerted?"
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
    [6] = {
        key = "alertCustomMinutes",
        name = "Custom before",
        tooltip = L.OptionsWhenTooltip:format("at a custom time before"),
        fn = function()
            local container = Settings.CreateControlTextContainer()
            container:Add(1, L.Disabled)
            for i = 15, 55, 5 do
                container:Add(i, L.NMinutes:format(i))
            end
            return container:GetData()
        end,
    },
}
L.OptionsTitle2 = "How do you want to be alerted?"
L.OptionsHowTooltip = "When important alerts go off, they will be accompanied by a %s."
L.OptionsHow = {
    [1] = {
        key = "printText",
        name = "Chat Messages",
        tooltip = L.OptionsHowTooltip:format("chat message"),
    },
    [2] = {
        key = "raidwarning",
        name = "Raid Warning Messages",
        tooltip = L.OptionsHowTooltip:format("raid warning message"),
    },
    [3] = {
        key = "sound",
        name = "Sounds",
        tooltip = L.OptionsHowTooltip:format("sound"),
    },
}
L.OptionsTitle3 = "Extra Options:"
L.OptionsExtra = {
    [1] = {
        key = "timeFormat",
        name = "Time Format",
        tooltip = "Choose a short or long time formatting.",
        fn = function()
            local container = Settings.CreateControlTextContainer()
            for i = 1, 3, 1 do
                container:Add(i, ns:Duration(754, i))
            end
            return container:GetData()
        end,
    },
    [2] = {
        key = "printWinsOnEnd",
        name = "Display wins/games stats at end",
        tooltip = "Prints your win/games record in your chat window when battles end.",
    },
    [3] = {
        key = "share",
        name = "Sharing",
        tooltip = "Enables silently sharing of start times with group members and through some chat channels.",
    },
    [4] = {
        key = "debug",
        name = "Debugging",
        tooltip = "Enables messages for debugging.",
        optionValue ="allowDebug",
    },
}
L.DebugToggleOn = "%s = true (%ss timeout)"
L.DebugToggleOff = "%s = false"
L.DebugTimerCheck = "TimerCheck()|n  Forced: %s"
L.DebugSetTimers = "SetTimers()|n  Warmode: %s|n  Timestamp: %s|n  Forced: %s"
L.DebugAnnouncedStart = "Announced start times in %s"
L.DebugRequestedStart = "Requested start times in %s|n%s"
L.DebugSentVersion = "Sent version in %s|n%s"
L.DebugSharedStart = "Shared start times in %s|n%s"
L.DebugChatMsgAddon = "Event: ChatMsgAddon|nReceived message from %s in %s|n%s"
L.DebugZoneChangedNewArea = "Event: ZoneChangedNewArea|n%s to %s"
L.DebugRaidBossEmote = "Event: RaidBossEmote|n%s"

-- Check locale and apply appropriate changes below
local CURRENT_LOCALE = GetLocale()

-- XXXX
-- if CURRENT_LOCALE == "xxXX" then return end
