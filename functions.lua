local ADDON_NAME, ns = ...
local L = ns.L

local CT = C_Timer

local allianceString = "|cff" .. ns.data.colors.alliance .. L.Alliance .. "|r"
local hordeString = "|cff" .. ns.data.colors.horde .. L.Horde .. "|r"
local enabledString = "|cff" .. ns.data.colors.enabled .. L.Enabled .. "|r"
local disabledString = "|cff" .. ns.data.colors.disabled .. L.Disabled .. "|r"

local minute = L.Units.minute
local second = L.Units.second

---
-- Local Functions
---

--- Plays a sound if "sound" option in enabled
-- @param {number} id
local function PlaySound(id)
    if ns:OptionValue("sound") then
        PlaySoundFile(id)
    end
end

-- Set default values for options which are not yet set
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

-- Set default values for character data which are not yet set
-- @param {string} option
-- @param {any} default
local function RegisterDefaultCharacterData(option, default)
    if TBW_data.characters[ns.data.characterName][option] == nil then
        TBW_data.characters[ns.data.characterName][option] = 0
    end
end

--- Get widget text
-- @param {number}
-- @return {table}
local function GetWidget(id)
    local widget = _G["UIWidgetTopCenterContainerFrame"]["widgetFrames"][id]
    return widget
end

--- Get remaining seconds in current battle (negative) or until next battle (positive)
-- @return {number|boolean}
local function GetSeconds()
    -- Unknown when not in either zone
    if not ns:InTolBarad(ns.data.location) then
        return nil
    end

    local widget

    -- Time remaining in active battle
    -- Returns time REMAINING (negative number)
    widget = GetWidget(ns.data.widgets.active.timer)
    if widget then
        local minutes, seconds = widget.Text:GetText():match("(%d+):(%d+)")
        if minutes and seconds then
            return (ns.data.durations.full - (tonumber(minutes) * 60) - tonumber(seconds)) * -1
        end
    end

    -- Time until next battle
    -- Returns time UNTIL (positive number)
    widget = GetWidget(ns.data.widgets.inactive.timer)
    if widget then
        local minutes, seconds = widget.Text:GetText():match("(%d+):(%d+)")
        if minutes and seconds then
            return (tonumber(minutes) * 60) + tonumber(seconds)
        end
    end

    -- Unknown when battle is active and in Peninsula
    return nil
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
local function TimerAlert(warmode, message, sound, raidWarningGate)
    local controlFormatted = ns.data.warmode and (TBW_data.controlWM == "alliance" and allianceString or hordeString) or (TBW_data.control == "alliance" and allianceString or hordeString)
    local wmMismatchAlert = (ns:OptionValue("warnAboutWMMismatch") and ns.data.warmode ~= warmode) and " |cffffff00" .. L.AlertToggleWarmode:format(warmode and enabledString or disabledString) .. "|r" or ""
    if ns:OptionValue("printText") then
        DEFAULT_CHAT_FRAME:AddMessage("|cff" .. ns.color .. L.TimerAlert:format(controlFormatted, warmode and enabledString or disabledString) .. " |r" .. message .. wmMismatchAlert)
    end
    if raidWarningGate and ns:OptionValue("raidwarning") then
        RaidNotice_AddMessage(RaidWarningFrame, "|cff" .. ns.color .. L.TimerRaidWarning:format(controlFormatted, warmode and enabledString or disabledString) .. "|r |cffffffff" .. message .. wmMismatchAlert .. "|r", ChatTypeInfo["RAID_WARNING"])
    end
    if sound then
        PlaySound(ns.data.sounds[sound])
    end
end

--- Returns the faction that controls Tol Barad based on the widget texture
-- @return {string}
local function GetControl()
    local widget
    widget = GetWidget(ns.data.widgets.active.control)
    if widget then
        return widget.Text:GetText():match(L.Alliance) and "horde" or "alliance"
    end
    widget = GetWidget(ns.data.widgets.inactive.control)
    if widget then
        return widget.Text:GetText():match(L.Alliance) and "alliance" or "horde"
    end
    widget = GetWidget(ns.data.widgets.activePeninsula.control)
    if widget then
        return widget.Text:GetText():match(L.Alliance) and "horde" or "alliance"
    end
end

---
-- Namespaced Functions
---

--- Set some data about the player
function ns:SetPlayerState()
    ns.data.characterName = UnitName("player") .. "-" .. GetNormalizedRealmName("player")
    local _, className, _ = UnitClass("player")
    ns.data.className = className
    local _, factionName = UnitFactionGroup("player")
    ns.data.factionName = factionName
    ns.data.location = C_Map.GetBestMapForUnit("player")
    ns.data.characterNameFormatted = "|cff" .. ns.data.classColors[ns.data.className:lower()] .. ns.data.characterName .. "|r"
end

--- Returns an option from the options table
-- @return {any}
function ns:OptionValue(option)
    return TBW_options[ns.prefix .. option]
end

--- Sets default options if they are not already set
function ns:SetDefaultOptions()
    TBW_data = TBW_data or {}
    TBW_data.startTimestampWM = TBW_data.startTimestampWM or 0
    TBW_data.startTimestamp = TBW_data.startTimestamp or 0
    TBW_data.toggles = TBW_data.toggles or {}
    TBW_data.characters = TBW_data.characters or {}
    local oldCharKey = UnitName("player") .. "-" .. GetRealmName("player")
    if oldCharKey ~= ns.data.characterName and TBW_data.characters[oldCharKey] then
        TBW_data.characters[ns.data.characterName] = TBW_data.characters[oldCharKey]
        TBW_data.characters[oldCharKey] = nil
    end
    TBW_data.characters[ns.data.characterName] = TBW_data.characters[ns.data.characterName] or {}
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
    local message = "V:" .. ns.version
    C_ChatInfo.SendAddonMessage(ADDON_NAME, message, channel)
    ns:DebugPrint(L.DebugSentVersion:format(channel, message))
end

--- Formats a duration in seconds to a "Xm Xs" string
-- @param {number} duration
-- @param {number} [timeFormat]
-- @return {string}
function ns:DurationFormat(duration, timeFormat)
    timeFormat = timeFormat and timeFormat or ns:OptionValue("timeFormat")
    local minutes = math.floor(duration / 60)
    local seconds = math.fmod(duration, 60)
    local m, s
    if timeFormat == 3 then
        m = " " .. (minutes > 1 and minute.p or minute.s)
        s = " " .. (seconds > 1 and second.p or second.s)
    elseif timeFormat == 2 then
        m = " " .. minute.a
        s = " " .. second.a
    else
        m = minute.t
        s = second.t
    end
    if minutes > 0 then
        if seconds > 0 then
            return string.format("%d" .. m .. (timeFormat ~= 2 and "," or "") .. " %d" .. s, minutes, seconds)
        end
        return string.format("%d" .. m, minutes)
    end
    return string.format("%d" .. s, seconds)
end

--- Format a timestamp to a local time string
-- @param {number} timestamp
-- @return {string}
function ns:TimeFormat(timestamp, includeSeconds)
    local useMilitaryTime = GetCVar("timeMgrUseMilitaryTime") == "1"
    local timeFormat = useMilitaryTime and ("%H:%M" .. (includeSeconds and ":%S" or "")) or ("%I:%M" .. (includeSeconds and ":%S" or "") .. "%p")
    local time = date(timeFormat, timestamp)

    -- Remove starting zero from non-military time
    if not useMilitaryTime then
        time = time:gsub("^0", ""):lower()
    end

    return time
end

--- Prints a formatted message to the chat
-- @param {string} message
function ns:PrettyPrint(message)
    DEFAULT_CHAT_FRAME:AddMessage("|cff" .. ns.color .. ns.name .. "|r " .. message)
end

--- Prints a debug message to the chat
-- @param {string} message
function ns:DebugPrint(message)
    if ns:OptionValue("allowDebug") and ns:OptionValue("debug") then
        print("|cff" .. ns.color .. "TBW|r |cfff8b700Debug|r " .. ns:TimeFormat(GetServerTime(), true) .. "|n" .. message)
    end
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
        ns:DebugPrint(L.DebugToggleOn:format(toggle, timeout))
        CT.After(timeout, function()
            ns.data.toggles[toggle] = false
            ns:DebugPrint(L.DebugToggleOff:format(toggle))
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
    return timestamp + ns.data.durations.full < now
end

--- Returns true if timestamp is inside the active battle time
-- @param {number}
-- @return {boolean}
function ns:IsPresent(timestamp)
    local now = GetServerTime()
    return timestamp < now and now < timestamp + ns.data.durations.full
end

--- Returns true if timestamp is before the active battle time
-- @param {number}
-- @return {boolean}
function ns:IsFuture(timestamp)
    local now = GetServerTime()
    return now < timestamp
end

--- Sets alerts for future battles
-- @param {boolean} warmode
-- @param {number} timestamp
-- @param {boolean} forced
function ns:SetTimers(warmode, timestamp)
    ns:DebugPrint(L.DebugSetTimers:format(ns.data.warmode and L.Enabled or L.Disabled, timestamp .. " " .. ns:TimeFormat(timestamp, true)))

    local now = GetServerTime()
    local secondsUntil = timestamp - now
    local startTime = ns:TimeFormat(timestamp)

    -- If no alerts are enabled, exit function
    if not ns:OptionValue("alertStart") and not ns:OptionValue("alert1Minute") and not ns:OptionValue("alert2Minutes") and not ns:OptionValue("alert10Minutes") and ns:OptionValue("alertCustomMinutes") == 1 then
        return
    end

    -- Prevent duplicate timers
    ns:Toggle(ns.data.warmode and "timerActiveWM" or "timerActive", secondsUntil)


    -- Set Pre-Defined Alerts
    for option, minutes in pairs(ns.data.timers) do
        if secondsUntil >= (minutes * 60) then
            CT.After(secondsUntil - (minutes * 60), function()
                if ns:OptionValue(option) then
                    local futureNow = GetServerTime()
                    TimerAlert(warmode, ns:AlertFuture(futureNow, futureNow + minutes * 60), "future", true)
                end
            end)
        end
    end

    -- Set Custom Alert
    for minutes = 15, 55, 5 do
        if secondsUntil >= (minutes * 60) then
            CT.After(secondsUntil - (minutes * 60), function()
                if minutes == ns:OptionValue("alertCustomMinutes") then
                    local futureNow = GetServerTime()
                    TimerAlert(warmode, ns:AlertFuture(futureNow, futureNow + minutes * 60), "future", true)
                end
            end)
        end
    end

    -- Set Start Alert
    CT.After(secondsUntil, function()
        if ns:OptionValue("alertStart") then
            if ns.data.warmode then
                ns:Toggle("recentlyOutputWM", ns.data.timeouts.long)
            else
                ns:Toggle("recentlyOutput", ns.data.timeouts.long)
            end
            TimerAlert(warmode, L.AlertNow:format(startTime), "present", true)
        end
    end)
end

--- Checks the current battle(s) state
-- @param {boolean} forced
function ns:TimerCheck(forced, seconds, control)
    ns:DebugPrint(L.DebugTimerCheck:format(forced and L.Enabled or L.Disabled))

    local now = GetServerTime()
    -- Remaining time (negative) or Until (positive) or Unknown (nil)
    seconds = seconds and seconds or GetSeconds()

    -- If in Tol Barad, set the control based on WM enabled/disabled
    if control or ns:InTolBarad(ns.data.location) then
        TBW_data[ns.data.warmode and "controlWM" or "control"] = control and control or GetControl()
    end

    -- If reliable seconds returned, then we're in Tol Barad, set the timestamp based on WM enabled/disabled
    if seconds ~= nil then
        TBW_data[ns.data.warmode and "startTimestampWM" or "startTimestamp"] = now + seconds
    end

    -- Set Data Broker text
    ns:SetDataBrokerText()

    -- If within 15 minute window after start, battle may be active, display alert
    -- For WM Enabled
    if ns:IsPresent(TBW_data.startTimestampWM) then
        if forced or not ns.data.toggles.recentlyOutputWM then
            ns:Toggle("recentlyOutputWM")
            TimerAlert(true, ns:AlertPast(now, TBW_data.startTimestampWM), "present", true)
        end
    end
    -- For WM Disabled
    if ns:IsPresent(TBW_data.startTimestamp) then
        if forced or not ns.data.toggles.recentlyOutput then
            ns:Toggle("recentlyOutput")
            TimerAlert(false, ns:AlertPast(now, TBW_data.startTimestamp), "present", true)
        end
    end

    -- If past 15 minute window after start and FORCED, battle likely over, display alert
    if forced and ns:IsPast(TBW_data.startTimestampWM) and ns:IsPast(TBW_data.startTimestamp) then
        if ns.data.location == ns.data.mapIDs.peninsula then
            ns:PrettyPrint(L.WarningNoInfoPeninsula)
        else
            ns:PrettyPrint(L.WarningNoInfo)
        end
    end

    -- If start is in the future
    -- For WM Enabled
    if now < TBW_data.startTimestampWM then
        -- Set alert if timer isn't active
        if not ns.data.toggles.timerActiveWM then
            ns:SetTimers(true, TBW_data.startTimestampWM)
        end
        -- Alert Timer
        if forced or not ns.data.toggles.recentlyOutputWM then
            ns:Toggle("recentlyOutputWM")
            TimerAlert(true, ns:AlertFuture(now, TBW_data.startTimestampWM), not forced and "future" or nil, true)
        end
    end
    -- For WM Disabled
    if now < TBW_data.startTimestamp then
        -- Set alert if timer isn't active
        if not ns.data.toggles.timerActive then
            ns:SetTimers(false, TBW_data.startTimestamp)
        end
        -- Alert Timer
        if forced or not ns.data.toggles.recentlyOutput then
            ns:Toggle("recentlyOutput")
            TimerAlert(false, ns:AlertFuture(now, TBW_data.startTimestamp), not forced and "future" or nil, true)
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
            ns:DebugPrint(L.DebugRequestedStart:format(string.upper(channel), message))
        else
            ns:PrettyPrint(L.WarningRequestUnable)
        end
    else
        ns:PrettyPrint(L.WarningFastRequest:format(20 - (GetServerTime() - TBW_data.toggles.recentlyRequestedStart)))
    end
end

--- Send or Announce the start time to a channel or player
-- @param {string} channel
-- @param {string} target
-- @param {boolean} announce
function ns:SendStart(channel, target, announce, manuallyInvoked)
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
                    -- WM Enabled
                    secondsUntil = TBW_data.startTimestampWM - now
                    if secondsUntil > 0 then
                        message = L.AlertAnnounceFutureDuration:format(ns:DurationFormat(secondsUntil))
                        ns:Toggle("recentlyAnnouncedStart")
                        SendChatMessage(L.TimerAlert:format(L.Enabled, ControlToString(TBW_data.controlWM)) .. " " .. message, string.upper(channel), nil, target)
                    elseif secondsUntil > (ns.data.durations.full * -1) then
                        -- Convert absolute values to present elapsed time
                        message = L.AlertAnnouncePastDuration:format(ns:DurationFormat(secondsUntil * -1))
                        ns:Toggle("recentlyAnnouncedStart")
                        SendChatMessage(L.TimerAlert:format(L.Enabled, ControlToString(TBW_data.controlWM)) .. " " .. message, string.upper(channel), nil, target)
                    end
                    -- WM Disabled
                    secondsUntil = TBW_data.startTimestamp - now
                    if secondsUntil > 0 then
                        message = L.AlertAnnounceFutureDuration:format(ns:DurationFormat(secondsUntil))
                        ns:Toggle("recentlyAnnouncedStart")
                        SendChatMessage(L.TimerAlert:format(L.Disabled, ControlToString(TBW_data.control)) .. " " .. message, string.upper(channel), nil, target)
                    elseif secondsUntil > (ns.data.durations.full * -1) then
                        -- Convert absolute values to present elapsed time
                        message = L.AlertAnnouncePastDuration:format(ns:DurationFormat(secondsUntil * -1))
                        ns:Toggle("recentlyAnnouncedStart")
                        SendChatMessage(L.TimerAlert:format(L.Disabled, ControlToString(TBW_data.control)) .. " " .. message, string.upper(channel), nil, target)
                    end
                    ns:DebugPrint(L.DebugAnnouncedStart:format(string.upper(channel)))
                else
                    ns:PrettyPrint(L.WarningFastAnnounce:format(20 - (GetServerTime() - TBW_data.toggles.recentlyAnnouncedStart)))
                end
            else
                -- Send
                if not ns.data.toggles.recentlySentStart then
                    ns:Toggle("recentlySentStart")
                    local message = "S:" .. ControlToStringID(TBW_data.controlWM) .. TBW_data.startTimestampWM .. ":" .. ControlToStringID(TBW_data.control) .. TBW_data.startTimestamp
                    local response = C_ChatInfo.SendAddonMessage(ADDON_NAME, message, string.upper(channel), target)
                    if manuallyInvoked then
                        ns:PrettyPrint(L.SharedStart:format(target and ("to " .. target) or ("in " .. string.upper(channel))))
                    else
                        ns:DebugPrint(L.SharedStart:format(target and ("to " .. target) or ("in " .. string.upper(channel))))
                    end
                else
                    ns:PrettyPrint(L.WarningFastShare:format(20 - (GetServerTime() - TBW_data.toggles.recentlySentStart)))
                end
            end
        else
            ns:GetSendTarget(announce)
        end
    elseif manuallyInvoked then
        ns:PrettyPrint(L.WarningNoData)
    end
end

--- Increment wins & games based on WM enabled/disabled
-- @param {string} message
function ns:IncrementCounts(message)
    local gamesKey = ns.data.warmode and "gamesWM" or "games"
    local winsKey = ns.data.warmode and "winsWM" or "wins"

    TBW_data.characters[ns.data.characterName][gamesKey] = TBW_data.characters[ns.data.characterName][gamesKey] + 1
    if message:match(ns.data.factionName) then
        TBW_data.characters[ns.data.characterName][winsKey] = TBW_data.characters[ns.data.characterName][winsKey] + 1
    end
end

--- Print wins / games
function ns:PrintCounts()
    local string

    ns:PrettyPrint("Wins/Games Record")

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
    string = "|cff01e2ff" .. L.WarbandWide .. "|r:  " .. warbandWinsTotal .. "/" .. warbandGamesTotal
    string = string .. "|n|cff" .. ns.color .. L.WarMode .. "|r:  " .. enabledString .. " " .. warbandWinsWM .. "/" .. warbandGamesWM .. "  " .. disabledString .. " " .. warbandWins .. "/" .. warbandGames
    print(string)

    local characterGamesWM = TBW_data.characters[ns.data.characterName].gamesWM
    local characterGames = TBW_data.characters[ns.data.characterName].games
    local characterWinsWM = TBW_data.characters[ns.data.characterName].winsWM
    local characterWins = TBW_data.characters[ns.data.characterName].wins
    local characterGamesTotal = characterGamesWM + characterGames
    local characterWinsTotal = characterWinsWM + characterWins

    -- Character-Specific
    string = ns.data.characterNameFormatted .. ":  " .. characterWinsTotal .. "/" .. characterGamesTotal
    string = string .. "|n|cff" .. ns.color .. L.WarMode .. "|r:  " .. enabledString .. ": " .. characterWinsWM .. "/" .. characterGamesWM .. "  " .. disabledString .. " " .. characterWins .. "/" .. characterGames
    print(string)
end

--- Build Data for Data Broker
function ns:BuildLibData()
    if LibStub then
        local ldb = LibStub:GetLibrary("LibDataBroker-1.1")
        ns.DataSource = ldb:NewDataObject(ns.name, {
            id = ADDON_NAME,
            type = "data source",
            version = ns.version,
            label = L.TolBarad .. " (" .. (ns.data.warmode and L.WMOn or L.WMOff) .. ")",
            icon = "Interface\\Icons\\achievement_zone_tolbarad",
            notes = "Keep track of the next Tol Barad battles (War Mode enabled & disabled)",
            OnClick = function(_, button)
                if IsAltKeyDown() then
                    ns:SendStart(nil, nil, true, true)
                elseif IsControlKeyDown() or IsShiftKeyDown() then
                    ns:GetSendTarget(IsControlKeyDown())
                elseif button == "RightButton" then
                    ns:SendStart(nil, nil, false, true)
                else
                    ns:OpenSettings()
                end
            end,
            OnTooltipShow = function(tooltip)
                local now = GetServerTime()
                local timestamp = TBW_data[ns.data.warmode and "startTimestampWM" or "startTimestamp"]
                local wmMismatchAlert
                tooltip:SetText(ns.name .. "        v" .. ns.version)
                if now < TBW_data.startTimestampWM + ns.data.durations.full then
                    wmMismatchAlert = (ns:OptionValue("warnAboutWMMismatch") and ns.data.warmode == false) and "|n|cffffff00" .. L.AlertToggleWarmode:format(enabledString) .. "|r" or ""
                    tooltip:AddLine(" ")
                    if now < TBW_data.startTimestampWM then
                        tooltip:AddLine("|cff" .. ns.color .. L.TimerRaidWarning:format(TBW_data.controlWM == "alliance" and allianceString or hordeString, enabledString) .. "|r|n|cffffffff" .. ns:AlertFuture(now, TBW_data.startTimestampWM) .. wmMismatchAlert .. "|r")
                    else
                        tooltip:AddLine("|cff" .. ns.color .. L.TimerRaidWarning:format(TBW_data.controlWM == "alliance" and allianceString or hordeString, enabledString) .. "|r|n|cffffffff" .. ns:AlertPast(now, TBW_data.startTimestampWM) .. wmMismatchAlert .. "|r")
                    end
                end
                if now < TBW_data.startTimestamp + ns.data.durations.full then
                    wmMismatchAlert = (ns:OptionValue("warnAboutWMMismatch") and ns.data.warmode == true) and "|n|cffffff00" .. L.AlertToggleWarmode:format(disabledString) .. "|r" or ""
                    tooltip:AddLine(" ")
                    if now < TBW_data.startTimestamp then
                        tooltip:AddLine("|cff" .. ns.color .. L.TimerRaidWarning:format(TBW_data.control == "alliance" and allianceString or hordeString, disabledString) .. "|r|n|cffffffff" .. ns:AlertFuture(now, TBW_data.startTimestamp) .. wmMismatchAlert .. "|r")
                    else
                        tooltip:AddLine("|cff" .. ns.color .. L.TimerRaidWarning:format(TBW_data.control == "alliance" and allianceString or hordeString, disabledString) .. "|r|n|cffffffff" .. ns:AlertPast(now, TBW_data.startTimestamp) .. wmMismatchAlert .. "|r")
                    end
                end
                tooltip:AddLine("|n")
                tooltip:AddLine("|cffffffff" .. L.AddonCompartmentTooltip1 .. "|r")
                tooltip:AddLine("|cffffffff" .. L.AddonCompartmentTooltip2 .. "|r")
                tooltip:AddLine("|cffffffff" .. L.AddonCompartmentTooltip3 .. "|r")
                tooltip:AddLine("|cffffffff" .. L.AddonCompartmentTooltip4 .. "|r")
                tooltip:AddLine("|cffffffff" .. L.AddonCompartmentTooltip5 .. "|r")
            end,
        })
    end
end

--- Set text value for Data Broker
function ns:SetDataBrokerText()
    if ns.DataSource then
        local now = GetServerTime()
        local timestamp = ns.data.warmode and TBW_data.startTimestampWM or TBW_data.startTimestamp
        if now < timestamp then
            ns.DataSource.text = L.AlertAnnounceFutureTime:format(ns:TimeFormat(timestamp)):gsub("%.", "")
        elseif now - ns.data.durations.full < timestamp then
            ns.DataSource.text = L.AlertAnnouncePastTime:format(ns:TimeFormat(timestamp)):gsub("%.", "")
        else
            ns.DataSource.text = L.Unknown
        end
    end
end

--- Set up Edit Box for share/announce via whisper
function ns:SetupEditBox()
    ns.EditBox = CreateFrame("EditBox", nil, UIParent, "InputBoxTemplate")
    ns.EditBox:SetSize(200, 30)
    ns.EditBox:SetPoint("CENTER")
    ns.EditBox:SetScale(1.5)
    ns.EditBox:SetText("")
    ns.EditBox:Hide()
    ns.EditBox:SetAutoFocus(true)
    ns.EditBox:SetScript("OnEnterPressed", function(self)
        local userInput = self:GetText():gsub("%s+", "")
        if userInput ~= "" then
            if ns.EditBox.announce then
                if userInput:match("^[A-Z]+$") ~= nil then
                    ns:SendStart(userInput, nil, true, true)
                else
                    ns:SendStart("WHISPER", userInput, true, true)
                end
            else
                if userInput:match("^[A-Z]+$") ~= nil then
                    ns:SendStart(userInput, nil, false, true)
                else
                    ns:SendStart("WHISPER", userInput, false, true)
                end
            end
        end
        ns.EditBox:ClearFocus()
        ns.EditBox:EnableKeyboard(false)
        ns.EditBox:Hide()
        ns.EditBoxLabel:Hide()
    end)
    ns.EditBox:SetScript("OnKeyDown", function(self, key)
        if key == "ESCAPE" then
            ns.EditBox:ClearFocus()
            ns.EditBox:EnableKeyboard(false)
            ns.EditBox:Hide()
            ns.EditBoxLabel:Hide()
        end
    end)

    ns.EditBoxLabel = CreateFrame("Frame", nil, UIParent)
    ns.EditBoxLabel:SetWidth(1)
    ns.EditBoxLabel:SetHeight(1)
    ns.EditBoxLabel:SetPoint("CENTER", 0, 0)
    ns.EditBoxLabel.text = ns.EditBoxLabel:CreateFontString(nil, "ARTWORK")
    ns.EditBoxLabel.text:SetFont("Fonts\\ARIALN.ttf", 16, "OUTLINE")
    ns.EditBoxLabel.text:SetPoint("BOTTOM", ns.EditBox, "TOP", 0, 0)
    ns.EditBoxLabel:Hide()
end

--- Prompt the user for whisper target
-- @param {boolean} announce
function ns:GetSendTarget(announce)
    ns.EditBox.announce = announce
    if announce then
        ns.EditBoxLabel.text:SetText(L.LabelAnnounceWhisper)
    else
        ns.EditBoxLabel.text:SetText(L.LabelShareWhisper)
    end
    ns.EditBox:EnableKeyboard(true)
    ns.EditBox:SetAlpha(0)
    ns.EditBox:Show()
    UIFrameFadeIn(ns.EditBox, 0.15, 0, 1)
    ns.EditBoxLabel:SetAlpha(0)
    ns.EditBoxLabel:Show()
    UIFrameFadeIn(ns.EditBoxLabel, 0.15, 0, 1)
end

--- Returns a formatted string for future alerts
-- @param {number} now
-- @param {number} timestamp
function ns:AlertFuture(now, timestamp)
    local durationColor = timestamp - now <= ns.data.durations.short and ns.data.durationColors.future.short or timestamp - now <= ns.data.durations.medium and ns.data.durationColors.future.medium or timestamp - now <= ns.data.durations.long and ns.data.durationColors.future.long or ns.color
    return L.AlertFuture:format(durationColor, ns:DurationFormat(timestamp - now), ns:TimeFormat(timestamp))
end

--- Returns a formatted string for past alerts
-- @param {number} now
-- @param {number} timestamp
function ns:AlertPast(now, timestamp)
    local durationColor = now - timestamp <= ns.data.durations.short and ns.data.durationColors.past.short or now - timestamp <= ns.data.durations.medium and ns.data.durationColors.past.medium or ns.data.durationColors.past.long
    return L.AlertPast:format(durationColor, ns:DurationFormat(now - timestamp), ns:TimeFormat(timestamp))
end