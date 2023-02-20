local ADDON_NAME, ns = ...

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
    timeout = timeout and timeout or 60
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
    if TBW_data.startTimestampWM == nil then
        TBW_data.startTimestampWM = 0
    end
    if TBW_data.startTimestamp == nil then
        TBW_data.startTimestamp = 0
    end
    if TBW_data.options == nil then
        TBW_data.options = {}
        for key, value in pairs(ns.data.defaults) do
            if TBW_data.options[key] == nil then
                TBW_data.options[key] = value
            end
        end
    end
end

function ns:PlaySoundFile(id)
    if TBW_data.options.sound then
        PlaySoundFile(id)
    end
end

function ns:PrettyPrint(message)
    DEFAULT_CHAT_FRAME:AddMessage("|cff" .. ns.color .. ns.name .. "|r " .. message)
end

function ns:BattlePrint(warmode, message, raidWarning)
    local warmodeFormatted = "(WM |cff" .. (warmode and "44ff44On" or "ff4444Off") .. "|r|cff" .. ns.color .. ")|r"
    DEFAULT_CHAT_FRAME:AddMessage("|cff" .. ns.color .. "Tol Barad " .. warmodeFormatted .. " |r" .. message)
    if raidWarning then
        RaidNotice_AddMessage(RaidWarningFrame, "The Battle for " .. "Tol Barad (WM " .. (warmode and "On" or "Off") .. ") " .. message, ChatTypeInfo["RAID_WARNING"])
    end
end

function ns:BattleCheck(forced)
    local now = GetServerTime()
    local warmode = C_PvP.IsWarModeDesired() == 1 and true or false
    local secondsLeft

    -- If we're in Tol Barad, GetWorldPVPAreaInfo() is reliable
    if contains(ns.data.mapIDs, ns.data.location) then
        secondsLeft = select(5, GetWorldPVPAreaInfo(2))
        if warmode then
            TBW_data.startTimestampWM = now + secondsLeft
        else
            TBW_data.startTimestamp = now + secondsLeft
        end
    end

    -- If the cached battles are in the past, exit BattleCheck()
    if (TBW_data.startTimestampWM + 900) < now and (TBW_data.startTimestamp + 900) < now then
        if forced then
            ns:PrettyPrint("Unfortunately, |cff" .. ns.color .. "Tol Barad|r information is unavailable here! You'll have to go to |cff" .. ns.color .. "Tol Barad|r or ask for a group member to share their data with you.")
        end
        return
    end

    -- If we are in Tol Barad OR Forced
    if contains(ns.data.mapIDs, ns.data.location) or forced then
        ns:SetBattleAlarms(true, now, TBW_data.startTimestampWM, forced)
        ns:SetBattleAlarms(false, now, TBW_data.startTimestamp, forced)
    end
end

function ns:SetBattleAlarms(warmode, now, startTimestamp, forced)
    local secondsLeft = startTimestamp - now
    local minutesLeft = math.floor(secondsLeft / 60)
    local startTime = date(GetCVar("timeMgrUseMilitaryTime") and "%H:%M" or "%I:%M %p", startTimestamp)

    -- If the Battle has not started yet, set Alarms
    if secondsLeft > 0 and ((warmode and not ns.data.toggles.timingWM) or (not warmode and not ns.data.toggles.timing)) then
        if warmode then
            ns.data.toggles.timingWM = true
        else
            ns.data.toggles.timing = true
        end

        ns:PlaySoundFile(567436) -- alarmclockwarning1.ogg
        ns:PrettyPrint("Timer has been set!")

        if secondsLeft > 120 then
            C_Timer.After(secondsLeft - 120, function()
                ns:PlaySoundFile(567458) -- alarmclockwarning3.ogg
                ns:BattlePrint(warmode, ("begins in 2 minutes at %s!"):format(startTime), true)
            end)
        end

        C_Timer.After(secondsLeft, function()
            toggle("recentlyOutput", 90)
            ns:PlaySoundFile(567399) -- alarmclockwarning2.ogg
            ns:BattlePrint(warmode, ("has begun! 15 minutes remaining from %s."):format(startTime), true)
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
            toggle("recentlyOutputWM", 90)
        else
            toggle("recentlyOutput", 90)
        end

        if secondsLeft <= 3 then
            ns:BattlePrint(warmode, "has begun!", true)
        elseif minutesLeft <= 5 then
            ns:BattlePrint(warmode, ("begins in %sm%ss at %s."):format(minutesLeft, math.fmod(secondsLeft, 60), startTime))
        else
            ns:BattlePrint(warmode, ("begins in %s minutes at %s."):format(minutesLeft, startTime))
        end
    end
end

function ns:SendStart(channel, target)
    local now = GetServerTime()
    if not ns.data.toggles.recentlySentStart then
        local partyMembers = GetNumSubgroupMembers()
        local raidMembers = IsInRaid() and GetNumGroupMembers() or 0
        channel = channel and channel or
            raidMembers > 0 and "RAID" or
            partyMembers > 0 and "PARTY" or
            nil

        if channel then
            if TBW_data.startTimestampWM + 900 > now or TBW_data.startTimestamp + 900 > now then
                toggle("recentlySentStart", 20)
                C_ChatInfo.SendAddonMessage(ADDON_NAME, "S:" .. TBW_data.startTimestampWM .. ":" .. TBW_data.startTimestamp, string.upper(channel), target)
            else
                ns:PrettyPrint("Your Tol Barad data doesn't contain any upcoming alerts that you can share.")
            end
        else
            ns:PrettyPrint("You must either be in a group or specify a channel (e.g. party, raid, guild) in order to share your Tol Barad data.")
        end
    else
        ns:PrettyPrint("You must wait a short time before sharing your Tol Barad data again.")
    end
end

-- Setup Functions

function TolBaradWhen_OnLoad(self)
    self:RegisterEvent("PLAYER_LOGIN")
    self:RegisterEvent("CHAT_MSG_ADDON")
    self:RegisterEvent("ZONE_CHANGED_NEW_AREA")
    self:RegisterEvent("RAID_BOSS_EMOTE")
end

function TolBaradWhen_OnEvent(self, event, arg, ...)
    if event == "PLAYER_LOGIN" then
        ns:SetDefaultOptions()
        ns:BattleCheck(true)
    elseif event == "CHAT_MSG_ADDON" and arg == ADDON_NAME then
        local message, channel, sender, _ = ...
        if message:match("S:") then
            local startTimestampWM, startTimestamp = strsplit(":", message:gsub("S:", ""))
            local now = GetServerTime()
            if not ns.data.toggles.recentlyReceivedStart then
                toggle("recentlyReceivedStart", 60)
                if tonumber(startTimestampWM) + 900 > now then
                    TBW_data.startTimestampWM = tonumber(startTimestampWM)
                    ns:BattleCheck()
                end
                if tonumber(startTimestamp) + 900 > now then
                    TBW_data.startTimestamp = tonumber(startTimestamp)
                    ns:BattleCheck()
                end
            end
        end
    elseif event == "ZONE_CHANGED_NEW_AREA" then
        ns.data.location = C_Map.GetBestMapForUnit("player")
        ns:BattleCheck(contains(ns.data.mapIDs, ns.data.location) and true or false)
    elseif event == "RAID_BOSS_EMOTE" and contains(ns.data.mapIDs, ns.data.location) then
        if not ns.data.toggles.recentlyEnded then
            toggle("recentlyEnded", 3)
            C_Timer.After(2, function()
                ns:BattleCheck(true)
            end)
        end
    end
end

SlashCmdList["TOLBARADWHEN"] = function(message)
    if message == "v" or message:match("ver") then
        ns:PrettyPrint(ns.version)
    elseif message == "h" or message:match("help") or message:match("config") then
        ns:PrettyPrint("This AddOn runs without any manual input. The only thing you need to do is zone into Tol Barad to get alerts running.")
        print("You can share your Tol Barad timer with group members:\n/tb share")
        print("You can also toggle sounds on and off:\n/tb sound")
    elseif message == "s" or message:match("send") or message:match("share") then
        local message, channel, target = strsplit(" ", message)
        ns:SendStart(channel, target)
    elseif message:match("tog") and message:match(" ") then
        local _, key = strsplit(" ", message)
        if TBW_data.options[key] ~= nil then
            if TBW_data.options[key] then
                TBW_data.options[key] = false
            else
                TBW_data.options[key] = true
            end
            ns:PrettyPrint(("Toggled %s: |cff%s|r"):format(key, TBW_data.options[key] and "44ff44On" or "ff4444Off"))
        else
            print(#ns.data.defaults)
            local s = ""
            for i, option in ipairs(ns.data.defaults) do
                print(option)
                s = s .. (i > 1 and ", " or "") .. option
            end
            ns:PrettyPrint("That option doesn't exist.\nOptions are: " .. s)
        end
    elseif message == "so" or message:match("sound") then
        if TBW_data.options.sound then
            TBW_data.options.sound = false
        else
            TBW_data.options.sound = true
        end
        ns:PrettyPrint(("Sound alerts are now |cff%s|r."):format(TBW_data.options.sound and "44ff44On" or "ff4444Off"))
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
