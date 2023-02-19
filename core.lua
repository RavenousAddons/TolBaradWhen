local ADDON_NAME, ns = ...

local _, localizedName, _, _, _, _ = GetWorldPVPAreaInfo(2)

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

function ns:PrettyPrint(message)
    DEFAULT_CHAT_FRAME:AddMessage("|cff" .. ns.color .. ns.name .. "|r " .. message)
end

function ns:CheckPrint(message, raidWarning)
    local warmodeFormatted = "(WM |cff" .. (TBW_data.warmode and "44ff44On" or "ff4444Off") .. "|r|cff" .. ns.color .. ")|r"
    DEFAULT_CHAT_FRAME:AddMessage("|cff" .. ns.color .. localizedName .. " " .. warmodeFormatted .. " |r" .. message)
    if raidWarning then
        RaidNotice_AddMessage(RaidWarningFrame, "The Battle for " .. localizedName .. " (WM " .. (TBW_data.warmode and "On" or "Off") .. ") " .. message, ChatTypeInfo["RAID_WARNING"])
    end
end

function ns:SetDefaultOptions()
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

function ns:Check(forcedOutput, playerLogin)
    local now = GetServerTime()
    local _, _, _, _, secondsLeft, _ = GetWorldPVPAreaInfo(2)

    -- If we're not in Tol Barad, don't rely on secondsLeft
    if not contains(ns.data.mapIDs, C_Map.GetBestMapForUnit("player")) then
        -- If the cached time is after now and Warmode matches,
        -- use cached secondsLeft value
        if (TBW_data.startTimestamp + 900) > now and TBW_data.warmode == C_PvP.IsWarModeDesired() then
            secondsLeft = TBW_data.startTimestamp - now
        -- Otherwise kill the Check
        else
            -- If a reply is required, give warning message about no info
            if forcedOutput then
                ns:PrettyPrint("Unfortunately, |cff" .. ns.color .. localizedName .. "|r information is unavailable here! You'll have to go to |cff" .. ns.color .. localizedName .. "|r or ask for a group member to share their data with you.")
            end
            return
        end
    end

    -- If we are in Tol Barad or require a reply from the AddOn, proceed
    if contains(ns.data.mapIDs, C_Map.GetBestMapForUnit("player")) or forcedOutput or (playerLogin and TBW_data.startTimestamp + 900 > now) then
        local minutesLeft = math.floor(secondsLeft / 60)
        local startTimestamp = now + secondsLeft
        local startTime = date(GetCVar("timeMgrUseMilitaryTime") and "%H:%M" or "%I:%M %p", startTimestamp)

        -- Save the results to cache
        TBW_data.startTimestamp = startTimestamp
        TBW_data.warmode = C_PvP.IsWarModeDesired()

        -- Begin timers for 2 minutes and Begin
        if not ns.data.toggles.timing and secondsLeft > 0 then
            ns.data.toggles.timing = true
            ns:PlaySoundFile(567436) -- alarmclockwarning1.ogg
            ns:PrettyPrint("Timer has been set!")

            if secondsLeft >= 120 then
                C_Timer.After(secondsLeft - 120, function()
                    ns:PlaySoundFile(567458) -- alarmclockwarning3.ogg
                    ns:CheckPrint(("begins in 2 minutes at %s!"):format(startTime), true)
                end)
            elseif seceondsLeft >= 60 then
                C_Timer.After(secondsLeft - 60, function()
                    ns:PlaySoundFile(567458) -- alarmclockwarning3.ogg
                    ns:CheckPrint(("begins in 1 minute at %s!"):format(startTime), true)
                end)
            end

            C_Timer.After(secondsLeft, function()
                toggle("recentlyOutput", 90)

                ns:PlaySoundFile(567399) -- alarmclockwarning2.ogg
                ns:CheckPrint(("has begun! 15 minutes remaining from %s."):format(startTime), true)
                ns.data.toggles.timing = false
            end)
        end

        -- Inform the player about starting time
        if forcedOutput or not ns.data.toggles.recentlyOutput then
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

function ns:SendStart(channel, target)
    local now = GetServerTime()
    if not ns.data.toggles.recentlySentStart then
        if TBW_data.startTimestamp + 900 > now then
            local partyMembers = GetNumSubgroupMembers()
            local raidMembers = IsInRaid() and GetNumGroupMembers() or 0
            TBW_data.warmode = C_PvP.IsWarModeDesired()

            if channel then
                toggle("recentlySentStart", 3)

                C_ChatInfo.SendAddonMessage(ADDON_NAME, "S:" .. (TBW_data.warmode and "1" or "0") .. ":" .. TBW_data.startTimestamp, string.upper(channel), target)
            elseif raidMembers > 0 then
                toggle("recentlySentStart", 20)

                C_ChatInfo.SendAddonMessage(ADDON_NAME, "S:" .. (TBW_data.warmode and "1" or "0") .. ":" .. TBW_data.startTimestamp, "RAID")
            elseif partyMembers > 0 then
                toggle("recentlySentStart", 20)

                C_ChatInfo.SendAddonMessage(ADDON_NAME, "S:" .. (TBW_data.warmode and "1" or "0") .. ":" .. TBW_data.startTimestamp, "PARTY")
            else
                ns:PrettyPrint("You must either be in a group or specify a channel (e.g. party, raid, guild) in order to share your " .. localizedName .. " data.")
            end
        else
            ns:PrettyPrint("Your " .. localizedName .. " data doesn't contain any upcoming alerts that you can share.")
        end
    else
        ns:PrettyPrint("You must wait a short time before sharing your " .. localizedName .. " data again.")
    end
end

function TolBaradWhen_OnLoad(self)
    self:RegisterEvent("PLAYER_LOGIN")
    self:RegisterEvent("CHAT_MSG_ADDON")
    self:RegisterEvent("ZONE_CHANGED_NEW_AREA")
    self:RegisterEvent("RAID_BOSS_EMOTE")
end

function TolBaradWhen_OnEvent(self, event, arg, ...)
    if event == "PLAYER_LOGIN" then
        ns:SetDefaultOptions()
        ns:Check(false, true)
    elseif event == "CHAT_MSG_ADDON" and arg == ADDON_NAME then
        local message, channel, sender, _ = ...
        if message:match("S:") then
            local warmode, startTimestamp = strsplit(":", message:gsub("S:", ""))
            local now = GetServerTime()
            if tonumber(warmode) == TBW_data.warmode and tonumber(message) + 900 > now and not ns.data.toggles.recentlyReceivedStart then
                toggle("recentlyReceivedStart", 60)

                TBW_data.startTimestamp = tonumber(message)
                ns:Check()
            end
        end
    elseif event == "ZONE_CHANGED_NEW_AREA" then
        ns:Check()
    elseif event == "RAID_BOSS_EMOTE" and contains(ns.data.mapIDs, C_Map.GetBestMapForUnit("player")) and not ns.data.toggles.recentlyEnded then
        toggle("recentlyEnded", 3)

        C_Timer.After(3, function()
            ns:Check(true)
        end)
    end
end

SlashCmdList["TOLBARADWHEN"] = function(message)
    if message == "v" or message:match("ver") then
        ns:PrettyPrint(ns.version)
    elseif message == "h" or message:match("help") or message:match("config") then
        ns:PrettyPrint("This AddOn runs without any manual input. The only thing you need to do is zone into " .. localizedName .. " to get alerts running.")
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
    else
        ns:Check(true)
    end
end
SLASH_TOLBARADWHEN1 = "/tb"
SLASH_TOLBARADWHEN2 = "/tbw"
SLASH_TOLBARADWHEN3 = "/tolbarad"
SLASH_TOLBARADWHEN4 = "/tolbaradwhen"
