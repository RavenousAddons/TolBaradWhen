local ADDON_NAME, ns = ...
local L = ns.L

local CT = C_Timer

local character = UnitName("player") .. "-" .. GetRealmName("player")
local _, className, _ = UnitClass("player")
local _, localizedFactionName = UnitFactionGroup("player")
local allianceString = "|cff0078ff" .. L.Alliance .. "|r"
local hordeString = "|cffb30000" .. L.Horde .. "|r"

---
-- Utility Functions
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
    return string.format("%dm %02ds", minutes, seconds)
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

--- Get seconds in current battle or until next battle.
-- @return {number}
local function GetSeconds()
    if not ns:Contains(ns.data.mapIDs, ns.data.location) then
        return 0
    end

    -- Tol Barad (Main)
    --   Zone: 244
    --   Widget: 682
    -- Tol Barad Peninsula
    --   Zone: 245
    --   Widget: 688

    local widgetText

    -- Time remaining in active battle
    widgetText = GetActiveTimerWidget()
    if widgetText then
        local minutes, seconds = widgetText:match("(%d+):(%d+)")
        if minutes and seconds then
            return (900 - (tonumber(minutes) * 60) - tonumber(seconds)) * -1
        end
    end

    -- Time until next battle
    widgetText = GetInactiveTimerWidget()
    if widgetText then
        local minutes, seconds = widgetText:match("(%d+):(%d+)")
        if minutes and seconds then
            return (tonumber(minutes) * 60) + tonumber(seconds)
        end
    end

    return 0
end

--- Sets alerts for future battles
-- @param {boolean} warmode
-- @param {number} now
-- @param {number} startTimestamp
-- @param {boolean} forced
local function SetTimers(warmode, now, startTimestamp, forced)
    local secondsLeft = startTimestamp - now
    local minutesLeft = math.floor(secondsLeft / 60)
    local dateFormat = GetCVar("timeMgrUseMilitaryTime") == "1" and "%H:%M" or "%I:%M%p"
    local startTime = date(dateFormat, startTimestamp)

    if GetCVar("timeMgrUseMilitaryTime") == "0" then
        startTime = startTime:gsub("^0", ""):lower()
    end

    -- If the Battle has not started yet, set Alerts
    if secondsLeft > 0 and (ns:GetOptionValue("alertStart") or ns:GetOptionValue("alert1Minute") or ns:GetOptionValue("alert2Minutes") or ns:GetOptionValue("alert10Minutes") or ns:GetOptionValue("alertCustomMinutes") > 1) and ((warmode and not ns.data.toggles.timingWM) or (not warmode and not ns.data.toggles.timing)) then
        -- Timing has begun
        if warmode then
            ns:Toggle("timingWM", secondsLeft)
        else
            ns:Toggle("timing", secondsLeft)
        end

        -- Alert that a timer will be set
        ns:PrettyPrint(L.AlertSet)
        PlaySound(567436) -- alarmclockwarning1.ogg

        -- Set Custom Alerts
        for minutes = 15, 55, 5 do
            if secondsLeft >= (minutes * 60) then
                CT.After(secondsLeft - (minutes * 60), function()
                    if minutes == ns:GetOptionValue("alertCustomMinutes") then
                        TimerPrint(warmode, L.AlertLong:format(minutes, startTime), true)
                        PlaySound(567458) -- alarmclockwarning3.ogg
                        StartStopwatch(minutes, 0)
                    end
                end)
            end
        end

        -- Set Pre-Defined Alerts
        for option, minutes in pairs(ns.data.timers) do
            if secondsLeft >= (minutes * 60) then
                CT.After(secondsLeft - (minutes * 60), function()
                    if ns:GetOptionValue(option) then
                        TimerPrint(warmode, L.AlertLong:format(minutes, startTime), true)
                        PlaySound(567458) -- alarmclockwarning3.ogg
                        StartStopwatch(minutes, 0)
                    end
                end)
            end
        end

        -- Set Start Alert
        CT.After(secondsLeft, function()
            if ns:GetOptionValue("alertStart") then
                if warmode then
                    ns:Toggle("recentlyOutputWM", ns.data.timeouts.long)
                else
                    ns:Toggle("recentlyOutput", ns.data.timeouts.long)
                end
                TimerPrint(warmode, L.AlertStart:format(startTime), true)
                PlaySound(567399) -- alarmclockwarning2.ogg
                if ns:GetOptionValue("stopwatch") then
                    StopwatchFrame:Hide()
                end
            end
        end)
    end

    -- Inform the player about starting time
    if secondsLeft + 900 > 0 and (forced or (warmode and not ns.data.toggles.recentlyOutputWM) or (not warmode and not ns.data.toggles.recentlyOutput)) then
        ns:Toggle(warmode and "recentlyOutputWM" or "recentlyOutput")

        -- Start time is unknown (don't think this will ever happen anymore)
        if secondsLeft == 0 then
            TimerPrint(warmode, L.AlertStartUnsure, true)
            PlaySound(567399) -- alarmclockwarning2.ogg
        -- Battle has started, print elapsed
        elseif secondsLeft < 0 then
            -- Convert to absolute values to present elapsed time
            TimerPrint(warmode, L.AlertStartElapsed:format(Duration(secondsLeft * -1), startTime), true)
            PlaySound(567399) -- alarmclockwarning2.ogg
        -- Print time to next battle
        else
            TimerPrint(warmode, L.AlertShort:format(Duration(secondsLeft), startTime))
        end
    end
end

--- Prints a message about the current battle state
-- @param {boolean} warmode
-- @param {string} message
-- @param {boolean} raidWarning
local function TimerPrint(warmode, message, raidWarning)
    local warmodeFormatted = "|cff" .. (warmode and ("44ff44" .. L.Enabled) or ("ff4444" .. L.Disabled)) .. "|r"
    local controlledFormatted = warmode and (TBW_data.statusWM == "alliance" and allianceString or hordeString) or (TBW_data.status == "alliance" and allianceString or hordeString)
    DEFAULT_CHAT_FRAME:AddMessage("|cff" .. ns.color .. L.TimerPrint:format(warmodeFormatted, controlledFormatted) .. " |r" .. message .. (warmode ~= C_PvP.IsWarModeDesired() and " " .. L.AlertToggleWarmode:format(warmodeFormatted) or ""))
    if raidWarning and ns:GetOptionValue("raidwarning") then
        local controlled = warmode and (TBW_data.statusWM == "alliance" and L.Alliance or L.Horde) or (TBW_data.status == "alliance" and L.Alliance or L.Horde)
        RaidNotice_AddMessage(RaidWarningFrame, L.TimerRaidWarning:format(warmode and L.Enabled or L.Disabled, controlled) .. " " .. message .. (warmode ~= C_PvP.IsWarModeDesired() and "|n" .. L.AlertToggleWarmode:format(warmode and L.Enabled or L.Disabled) or ""), ChatTypeInfo["RAID_WARNING"])
    end
end

---
-- Namespaced Functions
---

--- Returns an option from the options table
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

--- Checks if an element is in a table
-- @param {table} table
-- @param {string} input
-- @return {number|boolean}
function ns:Contains(table, input)
    for index, value in ipairs(table) do
        if value == input then
            return index
        end
    end
    return false
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

--- Checks the current battle(s) state
-- @param {boolean} forced
function ns:TimerCheck(forced)
    local now = GetServerTime()
    local warmode = C_PvP.IsWarModeDesired()
    local secondsLeft = GetSeconds()

    -- If we're in Tol Barad, secondsLeft is reliable
    if ns:Contains(ns.data.mapIDs, ns.data.location) then
        local textureIndex = C_AreaPoiInfo.GetAreaPOIInfo(244, 2485) and C_AreaPoiInfo.GetAreaPOIInfo(244, 2485).textureIndex or C_AreaPoiInfo.GetAreaPOIInfo(244, 2486).textureIndex
        -- If Tol Barad is active
        if secondsLeft == 0 then
            if warmode then
                if ns.data.location == 244 then
                    TBW_data.startTimestampWM = now > TBW_data.startTimestampWM + 900 and now or TBW_data.startTimestampWM
                end
                if textureIndex == 46 then
                    TBW_data.statusWM = "alliance"
                else
                    TBW_data.statusWM = "horde"
                end
            else
                if ns.data.location == 244 then
                    TBW_data.startTimestamp = now > TBW_data.startTimestamp + 900 and now or TBW_data.startTimestamp
                end
                if textureIndex == 46 then
                    TBW_data.status = "alliance"
                else
                    TBW_data.status = "horde"
                end
            end
        else
            if warmode then
                TBW_data.startTimestampWM = now + secondsLeft
                if textureIndex == 46 then
                    TBW_data.statusWM = "alliance"
                else
                    TBW_data.statusWM = "horde"
                end
            else
                TBW_data.startTimestamp = now + secondsLeft
                if textureIndex == 46 then
                    TBW_data.status = "alliance"
                else
                    TBW_data.status = "horde"
                end
            end
        end
    end

    -- If the cached battles are in the past, exit BattleCheck()
    if (TBW_data.startTimestampWM + 900) < now and (TBW_data.startTimestamp + 900) < now then
        local secondsLeft = GetSeconds()

        -- Final check for Tol Barad Peninsula during battle
        if ns.data.location == 245 then
            -- Start time is unknown
            if secondsLeft == 0 then
                TimerPrint(warmode, L.AlertStartUnsure, true)
                PlaySound(567399) -- alarmclockwarning2.ogg
            end
        elseif forced then
            ns:PrettyPrint(L.WarningNoInfo)
        end
        return
    end

    -- If we are in Tol Barad OR Forced
    -- THEN send data over to SetTimers()
    if (not ns.data.toggles.timingWM and TBW_data.startTimestampWM > now) or (not ns.data.toggles.timing and TBW_data.startTimestamp > now) or ns:Contains(ns.data.mapIDs, ns.data.location) or forced then
        SetTimers(true, now, TBW_data.startTimestampWM, forced)
        SetTimers(false, now, TBW_data.startTimestamp, forced)
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
    if TBW_data.startTimestampWM + 900 > now or TBW_data.startTimestamp + 900 > now then
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
                if not ns.data.toggles.recentlyAnnouncedStart then
                    -- Announce
                    local secondsLeft, minutesLeft, message
                    ns:Toggle("recentlyAnnouncedStart")
                    -- WM Enabled
                    secondsLeft = TBW_data.startTimestampWM - now
                    if secondsLeft > 0 then
                        message = L.AlertAnnounce:format(Duration(secondsLeft))
                        SendChatMessage(L.TimerPrint:format(L.Enabled, TBW_data.statusWM == "alliance" and L.Alliance or L.Horde) .. " " .. message, string.upper(channel), nil, target)
                    elseif secondsLeft > -900 then
                        -- Convert to absolute values to present elapsed time
                        message = L.AlertStartElapsedAnnounce:format(Duration(secondsLeft * -1))
                        SendChatMessage(L.TimerPrint:format(L.Enabled, TBW_data.statusWM == "alliance" and L.Alliance or L.Horde) .. " " .. message, string.upper(channel), nil, target)
                    end
                    -- WM Disabled
                    secondsLeft = TBW_data.startTimestamp - now
                    if secondsLeft > 0 then
                        message = L.AlertAnnounce:format(Duration(secondsLeft))
                        SendChatMessage(L.TimerPrint:format(L.Disabled, TBW_data.status == "alliance" and L.Alliance or L.Horde) .. " " .. message, string.upper(channel), nil, target)
                    elseif secondsLeft > -900 then
                        -- Convert to absolute values to present elapsed time
                        message = L.AlertStartElapsedAnnounce:format(Duration(secondsLeft * -1))
                        SendChatMessage(L.TimerPrint:format(L.Disabled, TBW_data.status == "alliance" and L.Alliance or L.Horde) .. " " .. message, string.upper(channel), nil, target)
                    end
                    if ns:GetOptionValue("debug") then
                        ns:PrettyPrint("\n" .. L.DebugAnnouncedStart:format(string.upper(channel)) .. "\n" .. message)
                    end
                else
                    ns:PrettyPrint(L.WarningFastShare:format(20 - (GetServerTime() - TBW_data.toggles.recentlyAnnouncedStart)))
                end
            else
                if not ns.data.toggles.recentlySentStart then
                    -- Send
                    ns:Toggle("recentlySentStart")
                    local message = "S:" .. (TBW_data.statusWM == "alliance" and "A" or "H") .. TBW_data.startTimestampWM .. ":" .. (TBW_data.status == "alliance" and "A" or "H") .. TBW_data.startTimestamp
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

--- Increment wins & games based on WM status
-- @param {string} message
function ns:IncrementCounts(message)
    local gamesKey = C_PvP.IsWarModeDesired() and "gamesWM" or "games"
    local winsKey = C_PvP.IsWarModeDesired() and "winsWM" or "wins"

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
