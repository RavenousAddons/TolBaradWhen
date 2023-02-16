local ADDON_NAME, ns = ...

local optionDefaults = {
    sounds = true
}

local settings = {
    timing = false,
    recentlyOutput = false,
    recentlySentStart = false,
    recentlyReceivedStart = false
}

local _, localizedName, _, _, _, _ = GetWorldPVPAreaInfo(2)

local mapIDs = {244, 245}

local function contains(table, input)
    for index, value in ipairs(table) do
        if value == input then
            return index
        end
    end
    return false
end

local function toggle(setting, timeout)
    timeout = timeout and timeout or 60
    settings[setting] = true
    C_Timer.After(timeout, function()
        settings[setting] = false
    end)
end

function ns:PrettyPrint(message)
    DEFAULT_CHAT_FRAME:AddMessage("|cff" .. ns.color .. ns.name .. "|r " .. message)
end

function ns:CheckPrint(message, raidWarning)
    local warmodeFormatted = "(WM |cff" .. (TBW_data.warmode and "44ff44On" or "ff4444Off") .. "|r|cff" .. ns.color .. ")|r"
    DEFAULT_CHAT_FRAME:AddMessage("|cff" .. ns.color .. localizedName .. " " .. warmodeFormatted .. " |r" .. message)
    if raidWarning then
        RaidNotice_AddMessage(RaidWarningFrame, localizedName .. " (WM " .. (TBW_data.warmode and "On" or "Off") .. ") " .. message, ChatTypeInfo["RAID_WARNING"])
    end
end

function ns:SetDefaultSettings()
    if TBW_data == nil then
        TBW_data = {}
    end
    if TBW_data.startTimestamp == nil then
        TBW_data.startTimestamp = 0
    end
    if TBW_data.warmode == nil then
        TBW_data.warmode = C_PvP.IsWarModeDesired()
    end
    if TBW_data.options == nil then
        TBW_data.options = {}
        for k, v in pairs(optionDefaults) do
            TBW_data.options[k] = TBW_data.options[k] and TBW_data.options[k] or v
        end
    end
end

function ns:Check(forcedOutput, playerLogin)
    local mapLinks = C_Map.GetMapLinksForMap(244);
    for i, mapLink in ipairs(mapLinks) do
        print(i)
    end

    local now = GetServerTime()
    local _, _, _, _, secondsLeft, _ = GetWorldPVPAreaInfo(2)

    -- If we're not in Tol Barad, don't rely on secondsLeft
    if not contains(mapIDs, C_Map.GetBestMapForUnit("player")) then
        -- If the cached time is after now and Warmode matches,
        -- use cached secondsLeft value
        if (TBW_data.startTimestamp + 900) > now and TBW_data.warmode == C_PvP.IsWarModeDesired() then
            secondsLeft = TBW_data.startTimestamp - now
        -- Otherwise kill the Check
        else
            -- If a reply is required, give warning message about no info
            if forcedOutput then
                ns:PrettyPrint("Unfortunately, |cff" .. ns.color .. "Tol Barad|r information is unavailable here! You'll have to go to |cff" .. ns.color .. "Tol Barad|r or ask for a group member to share their data with you.")
            end
            return
        end
    end

    -- If we are in Tol Barad or require a reply from the AddOn, proceed
    if contains(mapIDs, C_Map.GetBestMapForUnit("player")) or forcedOutput or (playerLogin and TBW_data.startTimestamp + 900 > now) then
        local startTimestamp = now + secondsLeft
        local minutesLeft = math.floor(secondsLeft / 60)
        local startTime = date(GetCVar("timeMgrUseMilitaryTime") and "%H:%M" or "%I:%M %p", startTimestamp)

        -- Save the results to cache
        TBW_data.startTimestamp = startTimestamp
        TBW_data.warmode = C_PvP.IsWarModeDesired()

        -- Begin timers for 2 minutes and Begin
        if not settings.timing and secondsLeft > 0 then
            settings.timing = true
            PlaySoundFile(567436) -- alarmclockwarning1.ogg
            ns:PrettyPrint("Timer has been set!")

            if secondsLeft >= 120 then
                C_Timer.After(secondsLeft - 120, function()
                    PlaySoundFile(567458) -- alarmclockwarning3.ogg
                    ns:CheckPrint(("begins in 2 minutes at %s!"):format(startTime), true)
                end)
            elseif seceondsLeft >= 60 then
                C_Timer.After(secondsLeft - 60, function()
                    PlaySoundFile(567458) -- alarmclockwarning3.ogg
                    ns:CheckPrint(("begins in 1 minute at %s!"):format(startTime), true)
                end)
            end

            C_Timer.After(secondsLeft, function()
                toggle("recentlyOutput", 90)

                PlaySoundFile(567399) -- alarmclockwarning2.ogg
                ns:CheckPrint("has begun! 15 minutes remaining.", true)
                settings.timing = false
            end)
        end

        -- Inform the player about starting time
        if forcedOutput or not settings.recentlyOutput then
            toggle("recentlyOutput", 60)

            if secondsLeft <= 3 then
                ns:CheckPrint("has begun!", true)
            elseif minutesLeft <= 5 then
                ns:CheckPrint(("begins in %sm%ss at %s."):format(minutesLeft, math.fmod(secondsLeft, 60), startTime))
            else
                ns:CheckPrint(("begins in %s minutes at %s."):format(minutesLeft, startTime))
            end
        end
    end
end

function ns:SendStart()
    local now = GetServerTime()
    if TBW_data.startTimestamp + 900 > now and not settings.recentlySentStart then
        toggle("recentlySentStart", 30)

        local partyMembers = GetNumSubgroupMembers()
        local raidMembers = IsInRaid() and GetNumGroupMembers() or 0
        if raidMembers > 0 then
            C_ChatInfo.SendAddonMessage(ADDON_NAME, TBW_data.startTimestamp, "RAID")
        elseif partyMembers > 0 then
            C_ChatInfo.SendAddonMessage(ADDON_NAME, TBW_data.startTimestamp, "PARTY")
        else
            C_ChatInfo.SendAddonMessage(ADDON_NAME, TBW_data.startTimestamp, "GUILD")
        end
    end
end

function TolBaradWhen_OnLoad(self)
    self:RegisterEvent("PLAYER_LOGIN")
    self:RegisterEvent("CHAT_MSG_ADDON")
    self:RegisterEvent("ZONE_CHANGED_NEW_AREA")
end

function TolBaradWhen_OnEvent(self, event, arg, ...)
    if event == "PLAYER_LOGIN" then
        ns:SetDefaultSettings()
        ns:Check(false, true)
    elseif event == "CHAT_MSG_ADDON" and arg == ADDON_NAME then
        local message, channel, sender, _ = ...
        local now = GetServerTime()
        if tonumber(message) + 900 > now and not settings.recentlyReceivedStart then
            toggle("recentlyReceivedStart", 60)

            TBW_data.startTimestamp = tonumber(message)
            ns:Check()
        end
    elseif event == "ZONE_CHANGED_NEW_AREA" then
        ns:Check()
    end
end

SlashCmdList["TOLBARADWHEN"] = function(message)
    if message == "version" or message == "v" then
        ns:PrettyPrint(ns.version)
    elseif message == "share" then
        ns:SendStart(TBW_data.startTimestamp)
    elseif message == "share" then
        ns:SendStart(TBW_data.startTimestamp)
    else
        ns:Check(true)
    end
end
SLASH_TOLBARADWHEN1 = "/tb"
SLASH_TOLBARADWHEN2 = "/tbw"
SLASH_TOLBARADWHEN3 = "/tolbarad"
SLASH_TOLBARADWHEN4 = "/tolbaradwhen"
