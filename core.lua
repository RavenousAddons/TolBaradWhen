local ADDON_NAME, ns = ...
local L = ns.L

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
    ns.data.toggles[toggle] = true
    C_Timer.After(timeout, function()
        ns.data.toggles[toggle] = false
    end)
end

-- General Functions

function ns:SetDefaultOptions()
    if TBW_data == nil then
        TBW_data = {}
    end
    if TBW_data.options == nil then
        TBW_data.options = {}
    end
    for option, default in pairs(ns.data.defaults) do
        if TBW_data.options[option] == nil then
            TBW_data.options[option] = default
        end
    end
    if TBW_data.startTimestampWM == nil then
        TBW_data.startTimestampWM = 0
    end
    if TBW_data.startTimestamp == nil then
        TBW_data.startTimestamp = 0
    end
end

function ns:DoToggle(option)
    if TBW_data.options[option] ~= nil then
        if TBW_data.options[option] then
            TBW_data.options[option] = false
        else
            TBW_data.options[option] = true
        end
        ns:PrettyPrint(L.Toggled:format(option, TBW_data.options[option] and "44ff44On" or "ff4444Off"))
    else
        local i = 1
        local options = ""
        for option, _ in pairs(ns.data.defaults) do
            options = options .. (i > 1 and ", " or "") .. option
            i = i + 1
        end
        ns:PrettyPrint(L.NotAnOption:format(options))
    end
end

function ns:SendUpdate(type)
    local now = GetServerTime()
    if TBW_data.updateSentTimestamp and TBW_data.updateSentTimestamp > now then
        return
    end
    TBW_data.updateSentTimestamp = now + ns.data.timeouts.short
    C_ChatInfo.SendAddonMessage(ADDON_NAME, "V:" .. ns.version, type)
end

function ns:PlaySoundFile(id)
    if TBW_data.options.sound then
        PlaySoundFile(id)
    end
end

function ns:PrettyPrint(message)
    DEFAULT_CHAT_FRAME:AddMessage("|cff" .. ns.color .. ns.name .. "|r " .. message)
end

-- Battle Functions

function ns:BattlePrint(warmode, message, raidWarning)
    local warmodeFormatted = "|cff" .. (warmode and "44ff44On" or "ff4444Off") .. "|r"
    local controlledFormatted = warmode and (TBW_data.statusWM == "alliance" and "|cff0078ffAlliance|r" or "|cffb30000Horde|r") or (TBW_data.status == "alliance" and "|cff0078ffAlliance|r" or "|cffb30000Horde|r")
    DEFAULT_CHAT_FRAME:AddMessage("|cff" .. ns.color .. "Tol Barad (WM " .. warmodeFormatted .. "|cff888888,|r " .. controlledFormatted .. ") |r" .. message)
    if raidWarning and TBW_data.options.raidwarning then
        local controlled = warmode and (TBW_data.statusWM == "alliance" and "Alliance" or "Horde") or (TBW_data.status == "alliance" and "Alliance" or "Horde")
        RaidNotice_AddMessage(RaidWarningFrame, "The Battle for " .. "Tol Barad (WM " .. (warmode and "On" or "Off") .. ", " .. controlled .. ") " .. message, ChatTypeInfo["RAID_WARNING"])
    end
end

function ns:BattleCheck(forced)
    local now = GetServerTime()
    local warmode = C_PvP.IsWarModeDesired()
    local secondsLeft = select(5, GetWorldPVPAreaInfo(2))

    -- If we're in Tol Barad, secondsLeft is reliable
    if contains(ns.data.mapIDs, ns.data.location) then
        local textureIndex = C_AreaPoiInfo.GetAreaPOIInfo(244, 2485) and C_AreaPoiInfo.GetAreaPOIInfo(244, 2485).textureIndex or C_AreaPoiInfo.GetAreaPOIInfo(244, 2486).textureIndex
        if secondsLeft <= 0 then
            if warmode then
                if textureIndex == 46 then
                    TBW_data.statusWM = "alliance"
                else
                    TBW_data.statusWM = "horde"
                end
            else
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
    if contains(ns.data.mapIDs, ns.data.location) or forced then
        ns:SetBattleAlerts(true, now, TBW_data.startTimestampWM, forced)
        ns:SetBattleAlerts(false, now, TBW_data.startTimestamp, forced)
    end
end

function ns:SetBattleAlerts(warmode, now, startTimestamp, forced)
    local secondsLeft = startTimestamp - now
    local minutesLeft = math.floor(secondsLeft / 60)
    local startTime = date(GetCVar("timeMgrUseMilitaryTime") and "%H:%M" or "%I:%M %p", startTimestamp)

    -- If the Battle has not started yet, set Alerts
    if secondsLeft > 0 and ((warmode and not ns.data.toggles.timingWM) or (not warmode and not ns.data.toggles.timing)) then
        if warmode then
            ns.data.toggles.timingWM = true
        else
            ns.data.toggles.timing = true
        end

        ns:PlaySoundFile(567436) -- alarmclockwarning1.ogg
        ns:PrettyPrint(L.AlertSet)

        if secondsLeft > 120 then
            C_Timer.After(secondsLeft - 120, function()
                ns:PlaySoundFile(567458) -- alarmclockwarning3.ogg
                ns:BattlePrint(warmode, L.Alert2Min:format(startTime), true)
            end)
        end

        C_Timer.After(secondsLeft, function()
            if warmode then
                toggle("recentlyOutputWM")
            else
                toggle("recentlyOutput")
            end
            ns:PlaySoundFile(567399) -- alarmclockwarning2.ogg
            ns:BattlePrint(warmode, L.AlertStart:format(minutesLeft, math.fmod(secondsLeft, 60), startTime), true)
            if warmode then
                ns.data.toggles.timingWM = false
            else
                ns.data.toggles.timing = false
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

        if secondsLeft <= 0 then
            -- Convert to absolute values to present elapsed time
            minutesLeft = minutesLeft * -1
            secondsLeft = secondsLeft * -1
            ns:PlaySoundFile(567399) -- alarmclockwarning2.ogg
            ns:BattlePrint(warmode, L.AlertStart:format(minutesLeft, math.fmod(secondsLeft, 60), startTime), true)
        elseif minutesLeft <= 5 then
            ns:BattlePrint(warmode, L.AlertShort:format(minutesLeft, math.fmod(secondsLeft, 60), startTime))
        else
            ns:BattlePrint(warmode, L.AlertLong:format(minutesLeft, startTime))
        end
    end
end

function ns:SendStart(channel, target)
    local now = GetServerTime()
    if not ns.data.toggles.recentlySentStart then
        if not channel and not IsInGroup(LE_PARTY_CATEGORY_INSTANCE) then
            ns.data.partyMembers = GetNumSubgroupMembers()
            ns.data.raidMembers = IsInRaid() and GetNumGroupMembers() or 0
            if ns.data.raidMembers > 1 then
                channel = "RAID"
            elseif ns.data.partyMembers > 1 then
                channel = "PARTY"
            end
        end
        if channel then
            if TBW_data.startTimestampWM + 900 > now or TBW_data.startTimestamp + 900 > now then
                toggle("recentlySentStart", 20)
                C_ChatInfo.SendAddonMessage(ADDON_NAME, "S:" .. (TBW_data.statusWM == "alliance" and "A" or "H") .. TBW_data.startTimestampWM .. ":" .. (TBW_data.status == "alliance" and "A" or "H") .. TBW_data.startTimestamp, string.upper(channel), target)
            else
                ns:PrettyPrint(L.WarningNoData)
            end
        else
            ns:PrettyPrint(L.WarningNoShare)
        end
    else
        ns:PrettyPrint(L.WarningFastShare)
    end
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
        if not ns.version:match("-") then
            if not TBW_version then
                ns:PrettyPrint(L.Install:format(ns.color, ns.version))
            elseif TBW_version ~= ns.version then
                ns:PrettyPrint(L.Update:format(ns.color, ns.version))
            end
            TBW_version = ns.version
        end
        ns:BattleCheck()
    elseif event == "GROUP_ROSTER_UPDATE" then
        local partyMembers = GetNumSubgroupMembers()
        local raidMembers = IsInRaid() and GetNumGroupMembers() or 0
        if not IsInGroup(LE_PARTY_CATEGORY_INSTANCE) then
            if raidMembers == 0 and partyMembers > ns.data.partyMembers then
                ns:SendUpdate("PARTY")
            elseif raidMembers > ns.data.raidMembers then
                ns:SendUpdate("RAID")
            end
        end
        ns.data.partyMembers = partyMembers
        ns.data.raidMembers = raidMembers
    elseif event == "CHAT_MSG_ADDON" and arg == ADDON_NAME then
        local message, channel, sender, _ = ...
        if message:match("V:") and not ns.data.toggles.updateFound then
            if TBW_data.options.debug then
                ns:PrettyPrint(sender .. " " .. message)
            end
            local version = message:gsub("V:", "")
            if not version:match("-") then
                local v1, v2, v3 = strsplit(".", version)
                local c1, c2, c3 = strsplit(".", ns.version)
                if v1 > c1 or (v1 == c1 and v2 > c2) or (v1 == c1 and v2 == c2 and v3 > c3) then
                    ns:PrettyPrint(L.UpdateFound:format(version))
                    ns.data.toggles.updateFound = true
                end
            end
        elseif message:match("S:") and (message:match("A") or message:match("H")) then
            if TBW_data.options.debug then
                ns:PrettyPrint("Received a message from " .. sender .. " in " .. channel .. ":\n" .. message)
            end
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
    elseif event == "RAID_BOSS_EMOTE" and contains(ns.data.mapIDs, ns.data.location) and (arg:match("has successfully defended") or arg:match("has successfully taken")) then
        if not ns.data.toggles.recentlyEnded then
            toggle("recentlyEnded", 3)
            C_Timer.After(2, function()
                ns:BattleCheck()
            end)
        end
    end
end

SlashCmdList["TOLBARADWHEN"] = function(message)
    if message == "v" or message:match("ver") then
        ns:PrettyPrint(L.Version:format(ns.version))
    elseif message == "h" or message:match("help") or message:match("config") then
        ns:PrettyPrint(L.Help1)
        print(L.Help2)
        print(L.Help3)
    elseif message == "s" or message:match("send") or message:match("share") then
        local message, channel, target = strsplit(" ", message)
        ns:SendStart(channel, target)
    elseif message:match("tog") and message:match(" ") then
        local _, option = strsplit(" ", message)
        ns:DoToggle(option)
    elseif message == "so" or message:match("sound") then
        if TBW_data.options.sound then
            TBW_data.options.sound = false
        else
            TBW_data.options.sound = true
        end
        ns:PrettyPrint(L.Sound:format(TBW_data.options.sound and "44ff44On" or "ff4444Off"))
    elseif message == "d" or message:match("bug") then
        local now = GetServerTime()
        print(TBW_data.startTimestampWM - now)
        print(TBW_data.startTimestamp - now)
    else
        ns:BattleCheck(true)
    end
end
SLASH_TOLBARADWHEN1 = "/tb"
SLASH_TOLBARADWHEN2 = "/tbw"
SLASH_TOLBARADWHEN3 = "/tolbarad"
SLASH_TOLBARADWHEN4 = "/tolbaradwhen"
