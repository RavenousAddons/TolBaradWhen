local ADDON_NAME, ns = ...
local L = ns.L

local CT = C_Timer

local character = UnitName("player") .. "-" .. GetRealmName("player")
local _, className, _ = UnitClass("player")
local _, localizedFactionName = UnitFactionGroup("player")
local allianceString = "|cff0078ff" .. L.Alliance .. "|r"
local hordeString = "|cffb30000" .. L.Horde .. "|r"

---
-- Local Functions
---

--- Plays a sound if "sound" option in enabled
-- @param {number} id
local function PlaySound(id)
    if ns:GetOptionValue("sound") then
        PlaySoundFile(id)
    end
end

--- Starts the Stopwatch if the "stopwatch" option is enabled and it hasn't
--- recently been started.
-- @param {number} minutes
-- @param {number} seconds
local function StartStopwatch(minutes, seconds)
    if ns:GetOptionValue("stopwatch") and not ns.data.toggles.stopwatch then
        minutes = minutes or 0
        seconds = seconds or 0
        ns:Toggle("stopwatch", (minutes * 60) + seconds)
        StopwatchFrame:Show()
        Stopwatch_StartCountdown(0, minutes, seconds)
        Stopwatch_Play()
    end
end

--- Formats a duration in seconds to a "Xm XXs" string
-- @param {number} duration
-- @return {string}
local function Duration(duration)
    local minutes = math.floor(duration / 60)
    local seconds = math.fmod(duration, 60)
    if minutes > 0 then
        return string.format("%dm %02ds", minutes, seconds)
    end
    return string.format("%d seconds", seconds)
end

-- Set default values for options which are not yet set.
-- @param {string} option
-- @param {any} default
local function RegisterDefaultOption(option, default)
    if TBW_options[ns.prefix .. option] == nil then
        if TBW_options[option] ~= nil then
            TBW_options[ns.prefix .. option] = TBW_options[option]
            TBW_options[option] = nil
        else
            TBW_options[ns.prefix .. option] = default
        end
    end
end

-- Set default values for character data which are not yet set.
-- @param {string} option
-- @param {any} default
local function RegisterDefaultCharacterData(option, default)
    if TBW_data.characters[character][option] == nil then
        TBW_data.characters[character][option] = 0
    end
end

--- Get active widget text.
-- @return {string}
local function GetActiveTimerWidget()
    local widget = _G["UIWidgetTopCenterContainerFrame"]["widgetFrames"][682]
    return widget and widget.Text:GetText() or nil
end

--- Get inactive widget text.
-- @return {string}
local function GetInactiveTimerWidget()
    local widget = _G["UIWidgetTopCenterContainerFrame"]["widgetFrames"][688]
    return widget and widget.Text:GetText() or nil
end

--- Get remaining seconds in current battle (negative) or until next battle (positive).
-- @return {number|boolean}
local function GetSeconds()
    -- Unknown when not in either zone
    if not ns:InTolBarad(ns.data.location) then
        return false
    end

    local widgetText

    -- Time remaining in active battle
    -- Returns time REMAINING (negative number)
    widgetText = GetActiveTimerWidget()
    if widgetText then
        local minutes, seconds = widgetText:match("(%d+):(%d+)")
        if minutes and seconds then
            return (900 - (tonumber(minutes) * 60) - tonumber(seconds)) * -1
        end
    end

    -- Time until next battle
    -- Returns time UNTIL (positive number)
    widgetText = GetInactiveTimerWidget()
    if widgetText then
        local minutes, seconds = widgetText:match("(%d+):(%d+)")
        if minutes and seconds then
            return (tonumber(minutes) * 60) + tonumber(seconds)
        end
    end

    -- Unknown when battle is active and in Peninsula
    return false
end

--- Returns a formatted Alliance/Horde string based on control value
-- @return {string}
local function ControlToString(control)
    return control == "alliance" and L.Alliance or L.Horde
end

--- Returns a formatted Alliance/Horde string ID based on control value
-- @return {string}
local function ControlToStringID(control)
    return control == "alliance" and "A" or "H"
end

--- Prints a message about the current battle state
-- @param {boolean} warmode
-- @param {string} message
-- @param {boolean} raidWarning
local function TimerPrint(warmode, message, raidWarningGate)
    local warmodeFormatted = "|cff" .. (warmode and ("44ff44" .. L.Enabled) or ("ff4444" .. L.Disabled)) .. "|r"
    local controlledFormatted = warmode and (TBW_data.controlWM == "alliance" and allianceString or hordeString) or (TBW_data.control == "alliance" and allianceString or hordeString)
    DEFAULT_CHAT_FRAME:AddMessage("|cff" .. ns.color .. L.TimerPrint:format(warmodeFormatted, controlledFormatted) .. " |r" .. message .. (warmode ~= C_PvP.IsWarModeDesired() and " " .. L.AlertToggleWarmode:format(warmodeFormatted) or ""))
    if raidWarningGate and ns:GetOptionValue("raidwarning") then
        local controlled = warmode and ControlToString(TBW_data.controlWM) or ControlToString(TBW_data.control)
        RaidNotice_AddMessage(RaidWarningFrame, L.TimerRaidWarning:format(warmode and L.Enabled or L.Disabled, controlled) .. " " .. message .. (warmode ~= C_PvP.IsWarModeDesired() and "|n" .. L.AlertToggleWarmode:format(warmode and L.Enabled or L.Disabled) or ""), ChatTypeInfo["RAID_WARNING"])
    end
end

--- Sets alerts for future battles
-- @param {boolean} warmode
-- @param {number} timestamp
-- @param {boolean} forced
local function SetTimers(warmode, timestamp, forced)
    local now = GetServerTime()
    local secondsUntil = timestamp - now
    local dateFormat = GetCVar("timeMgrUseMilitaryTime") == "1" and "%H:%M" or "%I:%M%p"
    local startTime = date(dateFormat, timestamp)

    -- Remove starting zero from non-military time
    if GetCVar("timeMgrUseMilitaryTime") == "0" then
        startTime = startTime:gsub("^0", ""):lower()
    end

    -- If no alerts are enabled, exit function
    if not ns:GetOptionValue("alertStart") and not ns:GetOptionValue("alert1Minute") and not ns:GetOptionValue("alert2Minutes") and not ns:GetOptionValue("alert10Minutes") and ns:GetOptionValue("alertCustomMinutes") == 1 then
        return
    end

    -- Prevent duplicate timers
    ns:Toggle(warmode and "timerActiveWM" or "timerActive", secondsUntil)

    -- Alert that timers have been set
    ns:PrettyPrint(L.AlertSet)
    PlaySound(ns.data.sounds.timerSet)

    -- Set Pre-Defined Alerts
    for option, minutes in pairs(ns.data.timers) do
        if secondsUntil >= (minutes * 60) then
            CT.After(secondsUntil - (minutes * 60), function()
                if ns:GetOptionValue(option) then
                    TimerPrint(warmode, L.AlertLong:format(minutes, startTime), true)
                    PlaySound(ns.data.sounds.future)
                    StartStopwatch(minutes, 0)
                end
            end)
        end
    end

    -- Set Custom Alert
    for minutes = 15, 55, 5 do
        if secondsUntil >= (minutes * 60) then
            CT.After(secondsUntil - (minutes * 60), function()
                if minutes == ns:GetOptionValue("alertCustomMinutes") then
                    TimerPrint(warmode, L.AlertLong:format(minutes, startTime), true)
                    PlaySound(ns.data.sounds.future)
                    StartStopwatch(minutes, 0)
                end
            end)
        end
    end

    -- Set Start Alert
    CT.After(secondsUntil, function()
        if ns:GetOptionValue("alertStart") then
            if warmode then
                ns:Toggle("recentlyOutputWM", ns.data.timeouts.long)
            else
                ns:Toggle("recentlyOutput", ns.data.timeouts.long)
            end
            TimerPrint(warmode, L.AlertStart:format(startTime), true)
            PlaySound(ns.data.sounds.start)
            if ns:GetOptionValue("stopwatch") then
                StopwatchFrame:Hide()
            end
        end
    end)
end

--- Returns the faction that controls Tol Barad based on the widget texture
-- @return {string}
local function GetControl()
    local textureIndex = C_AreaPoiInfo.GetAreaPOIInfo(ns.data.mapIDs.main, 2485) and C_AreaPoiInfo.GetAreaPOIInfo(ns.data.mapIDs.main, 2485).textureIndex or C_AreaPoiInfo.GetAreaPOIInfo(ns.data.mapIDs.main, 2486).textureIndex
    return textureIndex == 46 and "alliance" or "horde"
end

--- Returns a date-formatted string based on a timestamp
-- @return {string}
local function DateFormat(timestamp)
    local dateFormat = GetCVar("timeMgrUseMilitaryTime") == "1" and "%H:%M" or "%I:%M%p"
    local string = date(dateFormat, timestamp)

    -- Remove starting zero from non-military time
    if GetCVar("timeMgrUseMilitaryTime") == "0" then
        string = string:gsub("^0", ""):lower()
    end

    return string
end

---
-- Namespaced Functions
---

--- Returns an option from the options table
-- @return {any}
function ns:GetOptionValue(option)
    return TBW_options[ns.prefix .. option]
end

--- Sets default options if they are not already set
function ns:SetDefaultOptions()
    TBW_data = TBW_data or {}
    TBW_data.characters = TBW_data.characters or {}
    TBW_data.characters[character] = TBW_data.characters[character] or {}
    for option, default in pairs(ns.data.characterDefaults) do
        RegisterDefaultCharacterData(option, default)
    end
    TBW_options = TBW_options or {}
    for option, default in pairs(ns.data.defaults) do
        RegisterDefaultOption(option, default)
    end
end

--- Sends a version update message
-- @param {string} channel
function ns:SendVersionUpdate(channel)
    local now = GetServerTime()
    if not ns.version:match("-") and not ns.data.toggles.recentlySentVersion then
        return
    end
    ns:Toggle("recentlySentVersion")
    C_ChatInfo.SendAddonMessage(ADDON_NAME, "V:" .. ns.version, channel)
    if ns:GetOptionValue("debug") then
        ns:PrettyPrint("\n" .. L.DebugSentVersion:format(channel) .. "\n" .. "V:" .. ns.version)
    end
end

--- Prints a formatted message to the chat
-- @param {string} message
function ns:PrettyPrint(message)
    DEFAULT_CHAT_FRAME:AddMessage("|cff" .. ns.color .. ns.name .. "|r " .. message)
end

--- Checks if player is in Tol Barad
-- @param {number} location
-- @return {boolean}
function ns:InTolBarad(location)
    return location == ns.data.mapIDs.main or location == ns.data.mapIDs.peninsula
end

--- Toggles a feature with a specified timeout
-- @param {string} toggle
-- @param {number} timeout
function ns:Toggle(toggle, timeout)
    timeout = timeout and timeout or ns.data.timeouts.medium
    if not ns.data.toggles[toggle] then
        ns.data.toggles[toggle] = true
        TBW_data.toggles[toggle] = GetServerTime()
        if ns:GetOptionValue("debug") then
            ns:PrettyPrint("\n" .. L.DebugToggleOn:format(toggle, timeout))
        end
        CT.After(timeout, function()
            ns.data.toggles[toggle] = false
            if ns:GetOptionValue("debug") then
                ns:PrettyPrint("\n" .. L.DebugToggleOff:format(toggle))
            end
        end)
    end
end

--- Opens the Addon settings menu and plays a sound
function ns:OpenSettings()
    PlaySound(SOUNDKIT.IG_MAINMENU_OPEN)
    Settings.OpenToCategory(ns.Settings:GetID())
end

--- Returns true if timestamp is past the active battle time (by 15 min est.)
-- @param {number}
-- @return {boolean}
function ns:IsPast(timestamp)
    local now = GetServerTime()
    return timestamp + 900 < now
end

--- Returns true if timestamp is inside the active battle time
-- @param {number}
-- @return {boolean}
function ns:IsPresent(timestamp)
    local now = GetServerTime()
    return timestamp < now and now < timestamp + 900
end

--- Returns true if timestamp is before the active battle time
-- @param {number}
-- @return {boolean}
function ns:IsFuture(timestamp)
    local now = GetServerTime()
    return now < timestamp
end

--- Checks the current battle(s) state
-- @param {boolean} forced
function ns:TimerCheck(forced)
    local now = GetServerTime()
    local warmode = C_PvP.IsWarModeDesired()
    -- Remaining time (negative) or Until (positive) or Unknown (false)
    local seconds = GetSeconds()

    -- If in Tol Barad, set the control based on WM enabled/disabled
    if ns:InTolBarad(ns.data.location) then
        TBW_data[warmode and "controlWM" or "control"] = GetControl()
    end

    -- If reliable seconds returned, then we're in Tol Barad, set the timestamp based on WM enabled/disabled
    if seconds ~= false then
        TBW_data[warmode and "startTimestampWM" or "startTimestamp"] = now + seconds
    end

    -- If within 15 minute window after start, battle may be active, display alert
    -- For WM Enabled
    if ns:IsPresent(TBW_data.startTimestampWM) then
        if forced or not ns.data.toggles.recentlyOutputWM then
            ns:Toggle("recentlyOutputWM")
            TimerPrint(true, L.AlertStartElapsed:format(Duration((TBW_data.startTimestampWM - now) * -1), DateFormat(TBW_data.startTimestampWM)), true)
            PlaySound(ns.data.sounds.start)
        end
    end
    -- For WM Disabled
    if ns:IsPresent(TBW_data.startTimestamp) then
        if forced or not ns.data.toggles.recentlyOutputWM then
            ns:Toggle("recentlyOutput")
            TimerPrint(false, L.AlertStartElapsed:format(Duration((TBW_data.startTimestamp - now) * -1), DateFormat(TBW_data.startTimestamp)), true)
            PlaySound(ns.data.sounds.start)
        end
    end

    -- If past 15 minute window after start and FORCED, battle likely over, display alert
    if ns:IsPast(TBW_data.startTimestampWM) and ns:IsPast(TBW_data.startTimestamp) and forced then
        ns:PrettyPrint(L.WarningNoInfo)
    end

    -- If start is in the future
    -- For WM Enabled
    if now < TBW_data.startTimestampWM then
        -- Set alert if timer isn't active
        if not ns.data.toggles.timerActiveWM then
            SetTimers(true, TBW_data.startTimestampWM, forced)
        end
        -- Alert Timer
        if forced or not ns.data.toggles.recentlyOutputWM then
            ns:Toggle("recentlyOutputWM")
            TimerPrint(true, L.AlertShort:format(Duration(TBW_data.startTimestampWM - now), DateFormat(TBW_data.startTimestampWM)))
        end
    end
    -- For WM Disabled
    if now < TBW_data.startTimestamp then
        -- Set alert if timer isn't active
        if not ns.data.toggles.timerActive then
            SetTimers(false, TBW_data.startTimestamp, forced)
        end
        -- Alert Timer
        if forced or not ns.data.toggles.recentlyOutput then
            ns:Toggle("recentlyOutput")
            TimerPrint(warmode, L.AlertShort:format(Duration(TBW_data.startTimestamp - now), DateFormat(TBW_data.startTimestamp)))
        end
    end
end

--- Request the start time from a channel or player
-- @param {string} channel
-- @param {string} target
function ns:RequestStart(channel, target)
    local now = GetServerTime()
    if not ns.data.toggles.recentlyRequestedStart then
        if not channel and not IsInGroup(LE_PARTY_CATEGORY_INSTANCE) then
            ns.data.partyMembers = GetNumSubgroupMembers()
            ns.data.raidMembers = IsInRaid() and GetNumGroupMembers() or 0
            if ns.data.raidMembers > 1 then
                channel = "RAID"
            elseif ns.data.partyMembers > 0 then
                channel = "PARTY"
            end
        end
        if channel then
            ns:Toggle("recentlyRequestedStart")
            local message = "R!" .. now
            local response = C_ChatInfo.SendAddonMessage(ADDON_NAME, message, string.upper(channel), target)
            if ns:GetOptionValue("debug") then
                ns:PrettyPrint("\n" .. L.DebugRequestedStart:format(string.upper(channel)) .. "\n" .. message)
            end
        else
            ns:PrettyPrint(L.WarningNoRequest)
        end
    else
        ns:PrettyPrint(L.WarningFastRequest:format(20 - (GetServerTime() - TBW_data.toggles.recentlyRequestedStart)))
    end
end

--- Send or Announce the start time to a channel or player
-- @param {string} channel
-- @param {string} target
-- @param {boolean} announce
function ns:SendStart(channel, target, announce)
    announce = announce == nil and false or announce
    local now = GetServerTime()
    if ns:IsPresent(TBW_data.startTimestampWM) or ns:IsFuture(TBW_data.startTimestampWM) or ns:IsPresent(TBW_data.startTimestamp) or ns:IsFuture(TBW_data.startTimestamp) then
        if not channel and not IsInGroup(LE_PARTY_CATEGORY_INSTANCE) then
            ns.data.partyMembers = GetNumSubgroupMembers()
            ns.data.raidMembers = IsInRaid() and GetNumGroupMembers() or 0
            if ns.data.raidMembers > 1 then
                channel = "RAID"
            elseif ns.data.partyMembers > 0 then
                channel = "PARTY"
            end
        end
        if channel then
            if announce then
                -- Announce
                if not ns.data.toggles.recentlyAnnouncedStart then
                    local secondsUntil, message
                    ns:Toggle("recentlyAnnouncedStart")
                    -- WM Enabled
                    secondsUntil = TBW_data.startTimestampWM - now
                    if secondsUntil > 0 then
                        message = L.AlertAnnounce:format(Duration(secondsUntil))
                        SendChatMessage(L.TimerPrint:format(L.Enabled, ControlToString(TBW_data.controlWM)) .. " " .. message, string.upper(channel), nil, target)
                    elseif secondsUntil > -900 then
                        -- Convert absolute values to present elapsed time
                        message = L.AlertStartElapsedAnnounce:format(Duration(secondsUntil * -1))
                        SendChatMessage(L.TimerPrint:format(L.Enabled, ControlToString(TBW_data.controlWM)) .. " " .. message, string.upper(channel), nil, target)
                    end
                    -- WM Disabled
                    secondsUntil = TBW_data.startTimestamp - now
                    if secondsUntil > 0 then
                        message = L.AlertAnnounce:format(Duration(secondsUntil))
                        SendChatMessage(L.TimerPrint:format(L.Disabled, ControlToString(TBW_data.control)) .. " " .. message, string.upper(channel), nil, target)
                    elseif secondsUntil > -900 then
                        -- Convert absolute values to present elapsed time
                        message = L.AlertStartElapsedAnnounce:format(Duration(secondsUntil * -1))
                        SendChatMessage(L.TimerPrint:format(L.Disabled, ControlToString(TBW_data.control)) .. " " .. message, string.upper(channel), nil, target)
                    end
                    if ns:GetOptionValue("debug") then
                        ns:PrettyPrint("\n" .. L.DebugAnnouncedStart:format(string.upper(channel)))
                    end
                else
                    ns:PrettyPrint(L.WarningFastShare:format(20 - (GetServerTime() - TBW_data.toggles.recentlyAnnouncedStart)))
                end
            else
                -- Send
                if not ns.data.toggles.recentlySentStart then
                    ns:Toggle("recentlySentStart")
                    local message = "S:" .. ControlToStringID(TBW_data.controlWM) .. TBW_data.startTimestampWM .. ":" .. ControlToStringID(TBW_data.control) .. TBW_data.startTimestamp
                    local response = C_ChatInfo.SendAddonMessage(ADDON_NAME, message, string.upper(channel), target)
                    if ns:GetOptionValue("debug") then
                        ns:PrettyPrint("\n" .. L.DebugSharedStart:format(string.upper(channel)) .. "\n" .. message)
                    end
                else
                    ns:PrettyPrint(L.WarningFastShare:format(20 - (GetServerTime() - TBW_data.toggles.recentlySentStart)))
                end
            end
        else
            ns:PrettyPrint(L.WarningNoShare)
        end
    else
        ns:PrettyPrint(L.WarningNoData)
    end
end

--- Increment wins & games based on WM enabled/disabled
-- @param {string} message
function ns:IncrementCounts(message)
    local warmode = C_PvP.IsWarModeDesired()
    local gamesKey = warmode and "gamesWM" or "games"
    local winsKey = warmode and "winsWM" or "wins"

    TBW_data.characters[character][gamesKey] = TBW_data.characters[character][gamesKey] + 1
    if message:match(localizedFactionName) then
        TBW_data.characters[character][winsKey] = TBW_data.characters[character][winsKey] + 1
    end
end

--- Print wins / games
function ns:PrintCounts()
    local warmode = C_PvP.IsWarModeDesired()
    local string

    ns:PrettyPrint("")

    local warbandGamesWM = TBW_data.gamesWM
    local warbandGames = TBW_data.games
    local warbandWinsWM = TBW_data.winsWM
    local warbandWins = TBW_data.wins
    for _, data in pairs(TBW_data.characters) do
        warbandGamesWM = warbandGamesWM + data.gamesWM
        warbandGames = warbandGames + data.games
        warbandWinsWM = warbandWinsWM + data.winsWM
        warbandWins = warbandWins + data.wins
    end
    local warbandGamesTotal = warbandGamesWM + warbandGames
    local warbandWinsTotal = warbandWinsWM + warbandWins

    -- Warband-Wide
    string = "|cff01e2ff" .. L.WarbandWide .. ":|r\n" .. L.WinRecord .. ": " .. warbandWinsTotal .. "/" .. warbandGamesTotal
    string = string .. "\n" .. L.WarMode .. " |cff44ff44" .. L.Enabled .. "|r: " .. warbandWinsWM .. "/" .. warbandGamesWM
    string = string .. "\n" .. L.WarMode .. " |cffff4444" .. L.Disabled .. "|r: " .. warbandWins .. "/" .. warbandGames
    print(string)

    local characterGamesWM = TBW_data.characters[character].gamesWM
    local characterGames = TBW_data.characters[character].games
    local characterWinsWM = TBW_data.characters[character].winsWM
    local characterWins = TBW_data.characters[character].wins
    local characterGamesTotal = characterGamesWM + characterGames
    local characterWinsTotal = characterWinsWM + characterWins

    -- Character-Specific
    string = "|cff" .. ns.data.classColors[className:lower()] .. character .. ":|r\n" .. L.WinRecord .. ": " .. characterWinsTotal .. "/" .. characterGamesTotal
    string = string .. "\n" .. L.WarMode .. " |cff44ff44" .. L.Enabled .. "|r: " .. characterWinsWM .. "/" .. characterGamesWM
    string = string .. "\n" .. L.WarMode .. " |cffff4444" .. L.Disabled .. "|r: " .. characterWins .. "/" .. characterGames
    print(string)
end
