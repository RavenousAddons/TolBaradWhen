local ADDON_NAME, ns = ...
local L = ns.L

local _, localizedFactionName = UnitFactionGroup("player")
local allianceString = "|cff0078ff" .. _G.FACTION_ALLIANCE .. "|r"
local hordeString = "|cffb30000" .. _G.FACTION_HORDE .. "|r"

-- Utility Functions

-- Plays a sound if "sound" option in enabled
local function PlaySound(id)
    if TBW_options.sound then
        PlaySoundFile(id)
    end
end

-- Starts the Stopwatch if the "stopwatch" option is enabled and it hasn't
-- recently been started.
local function StartStopwatch(minutes, seconds)
    if TBW_options.stopwatch and not ns.data.toggles.stopwatch then
        minutes = minutes or 0
        seconds = seconds or 0
        ns:Toggle("stopwatch", (minutes * 60) + seconds)
        StopwatchFrame:Show()
        Stopwatch_StartCountdown(0, minutes, seconds)
        Stopwatch_Play()
    end
end

-- Formats a duration in seconds to a "XmXXs" string
local function Duration(duration)
    local minutes = math.floor(duration / 60)
    local seconds = math.fmod(duration, 60)
    return string.format("%dm%02ds", minutes, seconds)
end

-- General Functions

-- Sets default options if they are not already set
function ns:SetDefaultOptions()
    TBW_data = TBW_data or {}
    TBW_options = TBW_options or {}
    for option, default in pairs(ns.data.defaults) do
        TBW_options[option] = TBW_options[option] or default
    end
    TBW_data.toggles = TBW_data.toggles or {}
    TBW_data.startTimestampWM = TBW_data.startTimestampWM or 0
    TBW_data.startTimestamp = TBW_data.startTimestamp or 0
    TBW_data.gamesWM = TBW_data.gamesWM or 0
    TBW_data.games = TBW_data.games or 0
    TBW_data.winsWM = TBW_data.winsWM or 0
    TBW_data.wins = TBW_data.wins or 0
end

-- Sends a version update message
function ns:SendVersionUpdate(type)
    local now = GetServerTime()
    if not ns.version:match("-") and (TBW_data.updateSentTimestamp and TBW_data.updateSentTimestamp > now) then
        return
    end
    TBW_data.updateSentTimestamp = now + ns.data.timeouts.short
    C_ChatInfo.SendAddonMessage(ADDON_NAME, "V:" .. ns.version, type)
end

-- Prints a Tol Barad When? formatted message to the chat
function ns:PrettyPrint(message)
    DEFAULT_CHAT_FRAME:AddMessage("|cff" .. ns.color .. ns.name .. "|r " .. message)
end

-- Checks if an element is in a table
function ns:Contains(table, input)
    for index, value in ipairs(table) do
        if value == input then
            return index
        end
    end
    return false
end

-- Toggles a feature with a specified timeout
function ns:Toggle(toggle, timeout)
    timeout = timeout and timeout or ns.data.timeouts.long
    if not ns.data.toggles[toggle] then
        ns.data.toggles[toggle] = true
        TBW_data.toggles[toggle] = GetServerTime()
        if TBW_options.debug then
            ns:PrettyPrint("\n" .. L.DebugToggleOn:format(toggle, timeout))
        end
        C_Timer.After(timeout, function()
            ns.data.toggles[toggle] = false
            if TBW_options.debug then
                ns:PrettyPrint("\n" .. L.DebugToggleOff:format(toggle))
            end
        end)
    end
end

-- Battle Functions

-- Prints a message about the current battle state
function ns:BattlePrint(warmode, message, raidWarning)
    local warmodeFormatted = "|cff" .. (warmode and ("44ff44" .. L.On) or ("ff4444" .. L.Off)) .. "|r"
    local controlledFormatted = warmode and (TBW_data.statusWM == "alliance" and allianceString or hordeString) or (TBW_data.status == "alliance" and allianceString or hordeString)
    DEFAULT_CHAT_FRAME:AddMessage("|cff" .. ns.color .. L.BattlePrint:format(warmodeFormatted, controlledFormatted) .. " |r" .. message)
    if raidWarning and TBW_options.raidwarning then
        local controlled = warmode and (TBW_data.statusWM == "alliance" and _G.FACTION_ALLIANCE or _G.FACTION_HORDE) or (TBW_data.status == "alliance" and _G.FACTION_ALLIANCE or _G.FACTION_HORDE)
        RaidNotice_AddMessage(RaidWarningFrame, L.BattleRaidWarning:format(warmode and L.On or L.Off, controlled) .. " " .. message, ChatTypeInfo["RAID_WARNING"])
    end
end

local function GetTime()
    local widgetText = _G["UIWidgetTopCenterContainerFrame"]["widgetFrames"][688].Text:GetText()

    local minutes, seconds = widgetText:match("(%d+):(%d+)")

    return (tonumber(minutes) * 60) + tonumber(seconds)
end

-- Checks the current battle(s) state
function ns:BattleCheck(forced)
    local now = GetServerTime()
    local warmode = C_PvP.IsWarModeDesired()
    local secondsLeft = GetTime()
    -- local secondsLeft = select(5, GetWorldPVPAreaInfo(2))

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
        local secondsLeft = GetTime()
        -- local secondsLeft = select(5, GetWorldPVPAreaInfo(2))

        -- Final check for Tol Barad Peninsula during battle
        if ns.data.location == 245 then
            -- Start time is unknown
            if secondsLeft == 0 then
                ns:BattlePrint(warmode, L.AlertStartUnsure, true)
                PlaySound(567399) -- alarmclockwarning2.ogg
            end
        elseif forced then
            ns:PrettyPrint(L.WarningNoInfo)
        end
        return
    end

    -- If we are in Tol Barad OR Forced
    -- THEN send data over to SetBattleAlerts()
    if (not ns.data.toggles.timingWM and TBW_data.startTimestampWM > now) or (not ns.data.toggles.timing and TBW_data.startTimestamp > now) or ns:Contains(ns.data.mapIDs, ns.data.location) or forced then
        ns:SetBattleAlerts(true, now, TBW_data.startTimestampWM, forced)
        ns:SetBattleAlerts(false, now, TBW_data.startTimestamp, forced)
    end
end

-- Sets alerts for future battles
function ns:SetBattleAlerts(warmode, now, startTimestamp, forced)
    local secondsLeft = startTimestamp - now
    local minutesLeft = math.floor(secondsLeft / 60)
    local startTime = date(GetCVar("timeMgrUseMilitaryTime") and "%H:%M" or "%I:%M %p", startTimestamp)

    -- If the Battle has not started yet, set Alerts
    if secondsLeft > 0 and (TBW_options.alertStart or TBW_options.alert1Minute or TBW_options.alert2Minutes or TBW_options.alert10Minutes or TBW_options.alertCustomMinutes > 1) and ((warmode and not ns.data.toggles.timingWM) or (not warmode and not ns.data.toggles.timing)) then
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
                C_Timer.After(secondsLeft - (minutes * 60), function()
                    if minutes == TBW_options.alertCustomMinutes then
                        ns:BattlePrint(warmode, L.AlertLong:format(minutes, startTime), true)
                        PlaySound(567458) -- alarmclockwarning3.ogg
                        StartStopwatch(minutes, 0)
                    end
                end)
            end
        end

        -- Set Pre-Defined Alerts
        for default, minutes in pairs(ns.data.timers) do
            if secondsLeft >= (minutes * 60) then
                C_Timer.After(secondsLeft - (minutes * 60), function()
                    if TBW_options[default] then
                        ns:BattlePrint(warmode, L.AlertLong:format(minutes, startTime), true)
                        PlaySound(567458) -- alarmclockwarning3.ogg
                        StartStopwatch(minutes, 0)
                    end
                end)
            end
        end

        -- Set Start Alert
        C_Timer.After(secondsLeft, function()
            if TBW_options.alertStart then
                if warmode then
                    ns:Toggle("recentlyOutputWM")
                else
                    ns:Toggle("recentlyOutput")
                end
                ns:BattlePrint(warmode, L.AlertStart:format(startTime), true)
                PlaySound(567399) -- alarmclockwarning2.ogg
                if TBW_options.stopwatch then
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
            ns:BattlePrint(warmode, L.AlertStartUnsure, true)
            PlaySound(567399) -- alarmclockwarning2.ogg
        -- Battle has started, print elapsed
        elseif secondsLeft < 0 then
            -- Convert to absolute values to present elapsed time
            ns:BattlePrint(warmode, L.AlertStartElapsed:format(Duration(secondsLeft * -1), startTime), true)
            PlaySound(567399) -- alarmclockwarning2.ogg
        -- Print time to next battle
        else
            ns:BattlePrint(warmode, L.AlertShort:format(Duration(secondsLeft), startTime))
        end
    end
end

-- Request the start time from a channel or player
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
            ns:Toggle("recentlyRequestedStart", 20)
            local message = "R!" .. now
            local response = C_ChatInfo.SendAddonMessage(ADDON_NAME, message, string.upper(channel), target)
            if TBW_options.debug then
                ns:PrettyPrint("\n" .. L.DebugRequestedStart:format(string.upper(channel)) .. "\n" .. message)
            end
        else
            ns:PrettyPrint(L.WarningNoRequest)
        end
    else
        ns:PrettyPrint(L.WarningFastRequest:format(20 - (GetServerTime() - TBW_data.toggles.recentlyRequestedStart)))
    end
end

-- Send or Announce the start time to a channel or player
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
                    ns:Toggle("recentlyAnnouncedStart", 20)
                    -- WM On
                    secondsLeft = TBW_data.startTimestampWM - now
                    if secondsLeft > 0 then
                        message = L.AlertAnnounce:format(Duration(secondsLeft))
                        SendChatMessage(L.BattlePrint:format(L.On, TBW_data.statusWM == "alliance" and _G.FACTION_ALLIANCE or _G.FACTION_HORDE) .. " " .. message, string.upper(channel), nil, target)
                    elseif secondsLeft > -900 then
                        -- Convert to absolute values to present elapsed time
                        message = L.AlertStartElapsedAnnounce:format(Duration(secondsLeft * -1))
                        SendChatMessage(L.BattlePrint:format(L.On, TBW_data.statusWM == "alliance" and _G.FACTION_ALLIANCE or _G.FACTION_HORDE) .. " " .. message, string.upper(channel), nil, target)
                    end
                    -- WM Off
                    secondsLeft = TBW_data.startTimestamp - now
                    if secondsLeft > 0 then
                        message = L.AlertAnnounce:format(Duration(secondsLeft))
                        SendChatMessage(L.BattlePrint:format(L.Off, TBW_data.status == "alliance" and _G.FACTION_ALLIANCE or _G.FACTION_HORDE) .. " " .. message, string.upper(channel), nil, target)
                    elseif secondsLeft > -900 then
                        -- Convert to absolute values to present elapsed time
                        message = L.AlertStartElapsedAnnounce:format(Duration(secondsLeft * -1))
                        SendChatMessage(L.BattlePrint:format(L.Off, TBW_data.status == "alliance" and _G.FACTION_ALLIANCE or _G.FACTION_HORDE) .. " " .. message, string.upper(channel), nil, target)
                    end
                    if TBW_options.debug then
                        ns:PrettyPrint("\n" .. L.DebugAnnouncedStart:format(string.upper(channel)) .. "\n" .. message)
                    end
                else
                    ns:PrettyPrint(L.WarningFastShare:format(20 - (GetServerTime() - TBW_data.toggles.recentlyAnnouncedStart)))
                end
            else
                if not ns.data.toggles.recentlySentStart then
                    -- Send
                    ns:Toggle("recentlySentStart", 20)
                    local message = "S:" .. (TBW_data.statusWM == "alliance" and "A" or "H") .. TBW_data.startTimestampWM .. ":" .. (TBW_data.status == "alliance" and "A" or "H") .. TBW_data.startTimestamp
                    local response = C_ChatInfo.SendAddonMessage(ADDON_NAME, message, string.upper(channel), target)
                    if TBW_options.debug then
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

-- Increment win + battle counts
function ns:IncrementCounts(arg)
    if C_PvP.IsWarModeDesired() then
        TBW_data.gamesWM = TBW_data.gamesWM + 1
        if arg:match(localizedFactionName) then
            TBW_data.winsWM = TBW_data.winsWM + 1
        end
    else
        TBW_data.games = TBW_data.games + 1
        if arg:match(localizedFactionName) then
            TBW_data.wins = TBW_data.wins + 1
        end
    end
end

-- Print wins / games, optionally based on WM status
function ns:PrintCounts(all)
    local warmode = C_PvP.IsWarModeDesired()

    local gamesTotal = TBW_data.gamesWM + TBW_data.games
    local winsTotal = TBW_data.winsWM + TBW_data.wins

    local string = "\n" .. L.WinRecord .. ": " .. winsTotal .. "/" .. gamesTotal
    if warmode or all then
        string = string .. "\n" .. L.WarMode .. " |cff44ff44" .. L.On .. "|r: " .. TBW_data.winsWM .. "/" .. TBW_data.gamesWM
    end
    if not warmode or all then
        string = string .. "\n" .. L.WarMode .. " |cffff4444" .. L.Off .. "|r: " .. TBW_data.wins .. "/" .. TBW_data.games
    end

    ns:PrettyPrint(string)
end

-- Get the index of a buff based on a given spell ID
function ns:GetBuffIndex(spellID)
    for i = 1, 40 do
        if select(10, UnitBuff("player", i)) == spellID then
            return i
        end
    end
    return 0
end

-- Opens the AddOn settings menu and plays a sound
function ns:OpenSettings()
    PlaySound(SOUNDKIT.IG_MAINMENU_OPEN)
    Settings.OpenToCategory(ns.Settings:GetID())
end