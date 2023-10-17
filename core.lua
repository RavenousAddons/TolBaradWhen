local ADDON_NAME, ns = ...
local L = ns.L

local factionName, _ = UnitFactionGroup("player")
local tolbarad = select(2, GetWorldPVPAreaInfo(2))

-- Utility Functions

local function contains(table, input)
    for index, value in ipairs(table) do
        if value == input then
            return index
        end
    end
    return false
end

local function toggle(toggle, timeout)
    timeout = timeout and timeout or ns.data.timeouts.long
    if not ns.data.toggles[toggle] then
        ns.data.toggles[toggle] = true
        TBW_data.toggles[toggle] = GetServerTime()
        if TBW_options.debug then
            ns:PrettyPrint("\n" .. toggle .. " = true (" .. timeout .. "s timeout)")
        end
        C_Timer.After(timeout, function()
            ns.data.toggles[toggle] = false
            if TBW_options.debug then
                ns:PrettyPrint("\n" .. toggle .. " = false")
            end
        end)
    end
end

local function PlaySound(id)
    if TBW_options.sound then
        PlaySoundFile(id)
    end
end

local function StartStopwatch(minutes, seconds)
    if TBW_options.stopwatch and not ns.data.toggles.stopwatch then
        minutes = minutes or 0
        seconds = seconds or 0
        toggle("stopwatch", (minutes * 60) + seconds)
        StopwatchFrame:Show()
        Stopwatch_StartCountdown(0, minutes, seconds)
        Stopwatch_Play()
    end
end

-- General Functions

function ns:SetDefaultOptions()
    TBW_data = TBW_data == nil and {} or TBW_data
    TBW_options = TBW_options == nil and {} or TBW_options
    for option, default in pairs(ns.data.defaults) do
        if TBW_options[option] == nil then
            TBW_options[option] = default
        end
    end
    TBW_data.toggles = TBW_data.toggles == nil and {} or TBW_data.toggles
    TBW_data.startTimestampWM = TBW_data.startTimestampWM == nil and 0 or TBW_data.startTimestampWM
    TBW_data.startTimestamp = TBW_data.startTimestamp == nil and 0 or TBW_data.startTimestamp
    TBW_data.gamesWM = TBW_data.gamesWM == nil and 0 or TBW_data.gamesWM
    TBW_data.games = TBW_data.games == nil and 0 or TBW_data.games
    TBW_data.winsWM = TBW_data.winsWM == nil and 0 or TBW_data.winsWM
    TBW_data.wins = TBW_data.wins == nil and 0 or TBW_data.wins
end

function ns:SendVersionUpdate(type)
    local now = GetServerTime()
    if not ns.version:match("-") and (TBW_data.updateSentTimestamp and TBW_data.updateSentTimestamp > now) then
        return
    end
    TBW_data.updateSentTimestamp = now + ns.data.timeouts.short
    C_ChatInfo.SendAddonMessage(ADDON_NAME, "V:" .. ns.version, type)
end

function ns:PrettyPrint(message)
    DEFAULT_CHAT_FRAME:AddMessage("|cff" .. ns.color .. ns.name .. "|r " .. message)
end

-- Battle Functions

function ns:BattlePrint(warmode, message, raidWarning)
    local warmodeFormatted = "|cff" .. (warmode and "44ff44On" or "ff4444Off") .. "|r"
    local controlledFormatted = warmode and (TBW_data.statusWM == "alliance" and "|cff0078ffAlliance|r" or "|cffb30000Horde|r") or (TBW_data.status == "alliance" and "|cff0078ffAlliance|r" or "|cffb30000Horde|r")
    DEFAULT_CHAT_FRAME:AddMessage("|cff" .. ns.color .. "Tol Barad (WM: " .. warmodeFormatted .. "|cff888888,|r Control: " .. controlledFormatted .. ") |r" .. message)
    if raidWarning and TBW_options.raidwarning then
        local controlled = warmode and (TBW_data.statusWM == "alliance" and "Alliance" or "Horde") or (TBW_data.status == "alliance" and "Alliance" or "Horde")
        RaidNotice_AddMessage(RaidWarningFrame, "The Battle for Tol Barad (WM " .. (warmode and "On" or "Off") .. ", " .. controlled .. ") " .. message, ChatTypeInfo["RAID_WARNING"])
    end
end

function ns:BattleCheck(forced)
    local now = GetServerTime()
    local warmode = C_PvP.IsWarModeDesired()
    local secondsLeft = select(5, GetWorldPVPAreaInfo(2))

    -- If we're in Tol Barad, secondsLeft is reliable
    if contains(ns.data.mapIDs, ns.data.location) then
        local textureIndex = C_AreaPoiInfo.GetAreaPOIInfo(244, 2485) and C_AreaPoiInfo.GetAreaPOIInfo(244, 2485).textureIndex or C_AreaPoiInfo.GetAreaPOIInfo(244, 2486).textureIndex
        -- If Tol Barad is active
        if secondsLeft == 0 then
            if warmode then
                TBW_data.startTimestampWM = now > TBW_data.startTimestampWM + 900 and now or TBW_data.startTimestampWM
                if textureIndex == 46 then
                    TBW_data.statusWM = "alliance"
                else
                    TBW_data.statusWM = "horde"
                end
            else
                TBW_data.startTimestamp = now > TBW_data.startTimestamp + 900 and now or TBW_data.startTimestamp
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
        if forced then
            ns:PrettyPrint(L.WarningNoInfo)
        end
        return
    end

    -- If we are in Tol Barad OR Forced
    -- THEN send data over to SetBattleAlerts()
    if (not ns.data.toggles.timingWM and TBW_data.startTimestampWM > now) or (not ns.data.toggles.timing and TBW_data.startTimestamp > now) or contains(ns.data.mapIDs, ns.data.location) or forced then
        ns:SetBattleAlerts(true, now, TBW_data.startTimestampWM, forced)
        ns:SetBattleAlerts(false, now, TBW_data.startTimestamp, forced)
    end
end

function ns:SetBattleAlerts(warmode, now, startTimestamp, forced)
    local secondsLeft = startTimestamp - now
    local minutesLeft = math.floor(secondsLeft / 60)
    local startTime = date(GetCVar("timeMgrUseMilitaryTime") and "%H:%M" or "%I:%M %p", startTimestamp)

    -- If the Battle has not started yet, set Alerts
    if secondsLeft > 0 and (TBW_options.alertStart or TBW_options.alert1Minute or TBW_options.alert2Minutes or TBW_options.alert10Minutes or TBW_options.alertCustomMinutes > 1) and ((warmode and not ns.data.toggles.timingWM) or (not warmode and not ns.data.toggles.timing)) then
        -- Timing has begun
        if warmode then
            toggle("timingWM", secondsLeft)
        else
            toggle("timing", secondsLeft)
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
                    toggle("recentlyOutputWM")
                else
                    toggle("recentlyOutput")
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
        if warmode then
            toggle("recentlyOutputWM")
        else
            toggle("recentlyOutput")
        end

        -- Start time is unknown
        if secondsLeft == 0 then
            ns:BattlePrint(warmode, L.AlertStartUnsure, true)
            PlaySound(567399) -- alarmclockwarning2.ogg
        -- Battle has started, print elapsed
        elseif secondsLeft < 0 then
            -- Convert to absolute values to present elapsed time
            minutesLeft = math.floor(secondsLeft * -1 / 60)
            secondsLeft = secondsLeft * -1
            ns:BattlePrint(warmode, L.AlertStartElapsed:format(minutesLeft, math.fmod(secondsLeft, 60), startTime), true)
            PlaySound(567399) -- alarmclockwarning2.ogg
        -- Print time to next battle
        else
            ns:BattlePrint(warmode, L.AlertShort:format(minutesLeft, math.fmod(secondsLeft, 60), startTime))
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
            toggle("recentlyRequestedStart", 20)
            local message = "R!" .. now
            local response = C_ChatInfo.SendAddonMessage(ADDON_NAME, message, string.upper(channel), target)
            if TBW_options.debug then
                ns:PrettyPrint("\nRequested start times in " .. string.upper(channel) .. "\n" .. message)
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
                    toggle("recentlyAnnouncedStart", 20)
                    -- WM On
                    secondsLeft = TBW_data.startTimestampWM - now
                    if secondsLeft > 0 then
                        minutesLeft = math.floor(secondsLeft / 60)
                        message = L.AlertAnnounce:format(minutesLeft, math.fmod(secondsLeft, 60))
                        SendChatMessage("Tol Barad (WM: On, Control: " .. (TBW_data.statusWM == "alliance" and "Alliance" or "Horde") .. ") " .. message, string.upper(channel), nil, target)
                    else
                        -- Convert to absolute values to present elapsed time
                        minutesLeft = math.floor(secondsLeft * -1 / 60)
                        secondsLeft = secondsLeft * -1
                        message = L.AlertStartElapsedAnnounce:format(minutesLeft, math.fmod(secondsLeft, 60), startTime)
                        SendChatMessage("Tol Barad (WM: On, Control: " .. (TBW_data.statusWM == "alliance" and "Alliance" or "Horde") .. ") " .. message, string.upper(channel), nil, target)
                    end
                    -- WM Off
                    secondsLeft = TBW_data.startTimestamp - now
                    if secondsLeft > 0 then
                        minutesLeft = math.floor(secondsLeft / 60)
                        message = L.AlertAnnounce:format(minutesLeft, math.fmod(secondsLeft, 60), startTime)
                        SendChatMessage("Tol Barad (WM: Off, Control: " .. (TBW_data.status == "alliance" and "Alliance" or "Horde") .. ") " .. message, string.upper(channel), nil, target)
                    else
                        -- Convert to absolute values to present elapsed time
                        minutesLeft = math.floor(secondsLeft * -1 / 60)
                        secondsLeft = secondsLeft * -1
                        message = L.AlertStartElapsedAnnounce:format(minutesLeft, math.fmod(secondsLeft, 60), startTime)
                        SendChatMessage("Tol Barad (WM: Off, Control: " .. (TBW_data.status == "alliance" and "Alliance" or "Horde") .. ") " .. message, string.upper(channel), nil, target)
                    end
                    if TBW_options.debug then
                        ns:PrettyPrint("\nAnnounced start times in " .. string.upper(channel) .. "\n" .. message)
                    end
                else
                    ns:PrettyPrint(L.WarningFastShare:format(20 - (GetServerTime() - TBW_data.toggles.recentlyAnnouncedStart)))
                end
            else
                if not ns.data.toggles.recentlySentStart then
                    -- Send
                    toggle("recentlySentStart", 20)
                    local message = "S:" .. (TBW_data.statusWM == "alliance" and "A" or "H") .. TBW_data.startTimestampWM .. ":" .. (TBW_data.status == "alliance" and "A" or "H") .. TBW_data.startTimestamp
                    local response = C_ChatInfo.SendAddonMessage(ADDON_NAME, message, string.upper(channel), target)
                    if TBW_options.debug then
                        ns:PrettyPrint("\nShared start times in " .. string.upper(channel) .. "\n" .. message)
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
        if arg:match(factionName) then
            TBW_data.winsWM = TBW_data.winsWM + 1
        end
    else
        TBW_data.games = TBW_data.games + 1
        if arg:match(factionName) then
            TBW_data.wins = TBW_data.wins + 1
        end
    end
end

-- Print wins / games based on WM status
function ns:PrintCounts(all)
    local warmode = C_PvP.IsWarModeDesired()
    local warmodeFormatted = "|cff" .. (warmode and "44ff44On" or "ff4444Off") .. "|r"

    local gamesTotal = TBW_data.gamesWM + TBW_data.games
    local winsTotal = TBW_data.winsWM + TBW_data.wins

    local string = "\nWin Record: " .. winsTotal .. "/" .. gamesTotal
    if warmode or all then
        string = string .. "\nWM |cff44ff44On|r: " .. TBW_data.winsWM .. "/" .. TBW_data.gamesWM
    end
    if not warmode or all then
        string = string .. "\nWM |cffff4444Off|r: " .. TBW_data.wins .. "/" .. TBW_data.games
    end

    ns:PrettyPrint(string)
end

function ns:OpenSettings()
    PlaySound(SOUNDKIT.IG_MAINMENU_OPEN)
    Settings.OpenToCategory(ns.Settings:GetID())
end

-- Setup Functions

function TolBaradWhen_OnLoad(self)
    self:RegisterEvent("PLAYER_LOGIN")
    self:RegisterEvent("CHAT_MSG_ADDON")
    self:RegisterEvent("GROUP_ROSTER_UPDATE")
    self:RegisterEvent("ZONE_CHANGED_NEW_AREA")
    self:RegisterEvent("RAID_BOSS_EMOTE")
end

function TolBaradWhen_OnEvent(self, event, arg, ...)
    if event == "PLAYER_LOGIN" then
        ns:SetDefaultOptions()
        ns:CreateSettingsPanel()
        if not ns.version:match("-") then
            if not TBW_version then
                ns:PrettyPrint(L.Install:format(ns.color, ns.version))
            elseif TBW_version ~= ns.version then
                ns:PrettyPrint(L.Update:format(ns.color, ns.version))
                -- Version-specific messages
            end
            TBW_version = ns.version
        end
        ns:BattleCheck()
        C_ChatInfo.RegisterAddonMessagePrefix(ADDON_NAME)
    elseif event == "GROUP_ROSTER_UPDATE" then
        local partyMembers = GetNumSubgroupMembers()
        local raidMembers = IsInRaid() and GetNumGroupMembers() or 0
        if not ns.version:match("-") and TBW_options.share and not IsInGroup(LE_PARTY_CATEGORY_INSTANCE) then
            if raidMembers == 0 and partyMembers > ns.data.partyMembers then
                ns:SendVersionUpdate("PARTY")
            elseif raidMembers > ns.data.raidMembers then
                ns:SendVersionUpdate("RAID")
            end
        end
        ns.data.partyMembers = partyMembers
        ns.data.raidMembers = raidMembers
    elseif event == "CHAT_MSG_ADDON" and arg == ADDON_NAME and TBW_options.share then
        local message, channel, sender, _ = ...
        if TBW_options.debug then
            ns:PrettyPrint("\nReceived start times in " .. channel .. " from " .. channel .. "\n" .. message)
        end
        if message:match("V:") and not ns.data.toggles.updateFound then
            local version = message:gsub("V:", "")
            if not message:match("-") then
                local v1, v2, v3 = strsplit(".", version)
                local c1, c2, c3 = strsplit(".", ns.version)
                if v1 > c1 or (v1 == c1 and v2 > c2) or (v1 == c1 and v2 == c2 and v3 > c3) then
                    ns:PrettyPrint(L.UpdateFound:format(version))
                    ns.data.toggles.updateFound = true
                end
            end
        elseif message:match("R!") then
            local now = GetServerTime()
            if not ns.data.toggles.recentlyRequestedStart and (TBW_data.startTimestamp > now or TBW_data.startTimestampWM > now) then
                ns:SendStart(channel, sender)
            end
        elseif message:match("S:") and (message:match("A") or message:match("H")) then
            local timestamps = message:gsub("S:", "")
            local dataWM, data = strsplit(":", timestamps)
            local statusWM = dataWM:match("A") and "alliance" or "horde"
            local status = data:match("A") and "alliance" or "horde"
            local startTimestampWM = dataWM:gsub("A", ""):gsub("H", "")
            local startTimestamp = data:gsub("A", ""):gsub("H", "")
            if not ns.data.toggles.recentlyReceivedStartWM then
                if tonumber(startTimestampWM) > TBW_data.startTimestampWM then
                    toggle("recentlyReceivedStartWM", 30)
                    TBW_data.statusWM = statusWM
                    TBW_data.startTimestampWM = tonumber(startTimestampWM)
                    ns:BattleCheck(true)
                end
            end
            if not ns.data.toggles.recentlyReceivedStart then
                if tonumber(startTimestamp) > TBW_data.startTimestamp then
                    toggle("recentlyReceivedStart", 30)
                    TBW_data.status = status
                    TBW_data.startTimestamp = tonumber(startTimestamp)
                    ns:BattleCheck(true)
                end
            end
        end
    elseif event == "ZONE_CHANGED_NEW_AREA" then
        local newLocation = C_Map.GetBestMapForUnit("player")
        if not contains(ns.data.mapIDs, ns.data.location) or not contains(ns.data.mapIDs, newLocation) then
            C_Timer.After(1, function()
                ns:BattleCheck()
            end)
        end
        ns.data.location = C_Map.GetBestMapForUnit("player")
    elseif event == "RAID_BOSS_EMOTE" and contains(ns.data.mapIDs, ns.data.location) and arg:match(tolbarad) and not arg:match("1") then
        if not ns.data.toggles.recentlyEnded then
            toggle("recentlyEnded", 1)
            C_Timer.After(1, function()
                ns:IncrementCounts(arg)
                ns:PrintCounts()
                ns:BattleCheck()
            end)
        end
    end
end

function TolBaradWhen_OnAddonCompartmentClick(addonName, buttonName)
    if buttonName == "RightButton" then
        ns:SendStart()
        return
    end
    ns:OpenSettings()
end

function TolBaradWhen_OnAddonCompartmentEnter()
    GameTooltip:SetOwner(DropDownList1)
    GameTooltip:SetText(ns.name .. "        v" .. ns.version)
    GameTooltip:AddLine(" ", 1, 1, 1, true)
    GameTooltip:AddLine(L.AddonCompartmentTooltip1, 1, 1, 1, true)
    GameTooltip:AddLine(L.AddonCompartmentTooltip2, 1, 1, 1, true)
    GameTooltip:Show()
end

SlashCmdList["TOLBARADWHEN"] = function(message)
    if message == "v" or message:match("ver") then
        ns:PrettyPrint(L.Version:format(ns.version))
    elseif message == "h" or message:match("help") then
        ns:PrettyPrint(L.Help)
    elseif message == "c" or message:match("con") or message == "o" or message:match("opt") or message == "s" or message:match("sett") or message:match("togg") then
        ns:OpenSettings()
    elseif message == "r" or message:match("req") then
        if TBW_options.share then
            local _, channel, target = strsplit(" ", message)
            ns:RequestStart(channel, target)
        else
            ns:PrettyPrint(L.WarningDisabledShare)
        end
    elseif message == "a" or message:match("ann") then
        local _, channel, target = strsplit(" ", message)
        ns:SendStart(channel, target, true)
    elseif message == "s" or message:match("send") or message:match("share") then
        if TBW_options.share then
            local _, channel, target = strsplit(" ", message)
            ns:SendStart(channel, target)
        else
            ns:PrettyPrint(L.WarningDisabledShare)
        end
    elseif message == "w" or message:match("win") or message == "g" or message:match("game") or message == "b" or message:match("battle") then
        ns:PrintCounts(true)
    elseif message == "d" or message:match("bug") then
        local now = GetServerTime()
        print("|cff44ff44WM On|r " .. (TBW_data.statusWM == "alliance" and "|cff0078ffAlliance|r" or "|cffb30000Horde|r") .. " " .. (TBW_data.startTimestampWM - now))
        print("|cffff4444WM Off|r " .. (TBW_data.status == "alliance" and "|cff0078ffAlliance|r" or "|cffb30000Horde|r") .. " " .. (TBW_data.startTimestamp - now))
    else
        ns:BattleCheck(true)
    end
end
SLASH_TOLBARADWHEN1 = "/" .. ns.command
SLASH_TOLBARADWHEN2 = "/tb"
SLASH_TOLBARADWHEN3 = "/tolbarad"
SLASH_TOLBARADWHEN4 = "/tolbaradwhen"
