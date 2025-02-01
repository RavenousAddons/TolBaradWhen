local ADDON_NAME, ns = ...
local L = ns.L

local CT = C_Timer

local allianceString = "|cff" .. ns.data.colors.alliance .. L.Alliance .. "|r"
local hordeString = "|cff" .. ns.data.colors.horde .. L.Horde .. "|r"
local enabledString = "|cff" .. ns.data.colors.enabled .. L.Enabled .. "|r"
local disabledString = "|cff" .. ns.data.colors.disabled .. L.Disabled .. "|r"

-- Load the Addon

function TolBaradWhen_OnLoad(self)
    self:RegisterEvent("PLAYER_ENTERING_WORLD")
    self:RegisterEvent("CHAT_MSG_ADDON")
    self:RegisterEvent("GROUP_ROSTER_UPDATE")
    self:RegisterEvent("PLAYER_FLAGS_CHANGED")
    self:RegisterEvent("ZONE_CHANGED_NEW_AREA")
    self:RegisterEvent("RAID_BOSS_EMOTE")
end

-- Event Triggers

function TolBaradWhen_OnEvent(self, event, ...)
    if event == "PLAYER_ENTERING_WORLD" then
        local isInitialLogin, isReloadingUi = ...
        ns.registered = C_ChatInfo.RegisterAddonMessagePrefix(ADDON_NAME)
        ns:SetPlayerState()
        ns:SetOptionDefaults()
        ns:CreateSettingsPanel(TBW_options, ns.data.defaults, L.Settings, ns.name, ns.prefix, ns.version)
        ns:BuildLibData()
        ns:SetupEditBox()
        if not TBW_version then
            ns:PrettyPrint(L.Install:format(ns.color, ns.version))
        elseif TBW_version ~= ns.version then
            -- Version-specific messages go here...
        end
        TBW_version = ns.version
        local now = GetServerTime()
        if isInitialLogin or (TBW_data.startTimestampWM < now and now <= TBW_data.startTimestampWM + 900) or (TBW_data.startTimestamp < now and now <= TBW_data.startTimestamp + 900) then
            ns:TimerCheck()
        else
            if now < TBW_data.startTimestampWM then
                ns:SetTimers(true, TBW_data.startTimestampWM)
            end
            if now < TBW_data.startTimestamp then
                ns:SetTimers(false, TBW_data.startTimestamp)
            end
        end
        ns:SetDataBrokerText()
        self:UnregisterEvent("PLAYER_ENTERING_WORLD")
    elseif event == "GROUP_ROSTER_UPDATE" then
        local partyMembers = GetNumSubgroupMembers()
        local raidMembers = IsInRaid() and GetNumGroupMembers() or 0
        if not ns.version:match("-") and ns:OptionValue(TBW_options, "share") and not IsInGroup(LE_PARTY_CATEGORY_INSTANCE) and (partyMembers > 1 or raidMembers > 1) then
            if raidMembers == 0 and ns.data.partyMembers < partyMembers then
                ns:SendVersionUpdate("PARTY")
                if not ns.data.toggles.recentlySentStart then
                    ns:SendStart("PARTY")
                end
            elseif ns.data.raidMembers < raidMembers then
                ns:SendVersionUpdate("RAID")
                if not ns.data.toggles.recentlySentStart then
                    ns:SendStart("RAID")
                end
            end
        end
        ns.data.partyMembers = partyMembers
        ns.data.raidMembers = raidMembers
    elseif event == "PLAYER_FLAGS_CHANGED" then
        ns.data.warmode = C_PvP.IsWarModeDesired()
        if ns.DataSource then
            ns.DataSource.label = L.TolBarad .. " (" .. (ns.data.warmode and L.WMOn or L.WMOff) .. ")"
        end
    elseif event == "CHAT_MSG_ADDON" and ns:OptionValue(TBW_options, "share") then
        local addonName, message, channel, sender, _ = ...
        if addonName ~= ADDON_NAME then
            return
        end
        if sender == ns.data.characterName then
            return
        end
        ns:DebugPrint(L.DebugChatMsgAddon:format(sender, channel, message))
        if message:match("V:") and not ns.data.toggles.updateFound then
            local version = message:gsub("V:", "")
            if not message:match("-") then
                local v1, v2, v3 = strsplit(".", version)
                local c1, c2, c3 = strsplit(".", ns.version)
                v1, v2, v3 = tonumber(v1), tonumber(v2), tonumber(string.match(v3, "([^%-]+)"))
                c1, c2, c3 = tonumber(c1), tonumber(c2), tonumber(string.match(c3, "([^%-]+)"))
                if c1 < v1 or (c1 == v1 and c2 < v2) or (c1 == v1 and c2 == v2 and c3 < v3) then
                    ns:PrettyPrint(L.UpdateFound:format(version))
                    ns.data.toggles.updateFound = true
                end
            end
        elseif message:match("R!") then
            ns:PrettyPrint(L.ReceivedRequest:format(sender, channel))
            local now = GetServerTime()
            if not ns.data.toggles.recentlyRequestedStart and (ns:IsPresent(TBW_data.startTimestampWM) or ns:IsFuture(TBW_data.startTimestampWM) or ns:IsPresent(TBW_data.startTimestamp) or ns:IsFuture(TBW_data.startTimestamp)) then
                ns:SendStart(channel, sender)
            end
        elseif message:match("S:") and (message:match("A") or message:match("H")) then
            local timestamps = message:gsub("S:", "")
            local dataWM, data = strsplit(":", timestamps)
            local controlWM = dataWM:match("A") and "alliance" or "horde"
            local control = data:match("A") and "alliance" or "horde"
            local startTimestampWM = dataWM:gsub("A", ""):gsub("H", "")
            local startTimestamp = data:gsub("A", ""):gsub("H", "")
            if not ns.data.toggles.recentlyReceivedStartWM then
                if tonumber(TBW_data.startTimestampWM) + 1 < tonumber(startTimestampWM) then
                    ns:Toggle("recentlyReceivedStartWM")
                    TBW_data.controlWM = controlWM
                    TBW_data.startTimestampWM = tonumber(startTimestampWM)
                    ns:TimerCheck()
                end
            end
            if not ns.data.toggles.recentlyReceivedStart then
                if tonumber(TBW_data.startTimestamp) + 1 < tonumber(startTimestamp) then
                    ns:Toggle("recentlyReceivedStart")
                    TBW_data.control = control
                    TBW_data.startTimestamp = tonumber(startTimestamp)
                    ns:TimerCheck()
                end
            end
        end
    elseif event == "ZONE_CHANGED_NEW_AREA" then
        local newLocation = C_Map.GetBestMapForUnit("player")
        if ns.data.location and (not ns:InTolBarad(ns.data.location) or ns:IsPast(ns.data.warmode and TBW_data.startTimestampWM or TBW_data.startTimestamp)) and ns:InTolBarad(newLocation) then
            ns:DebugPrint(L.DebugZoneChangedNewArea:format(ns.data.location, newLocation))
            CT.After(1, function()
                ns:TimerCheck()
            end)
        end
        ns.data.location = newLocation
    elseif event == "RAID_BOSS_EMOTE" and ns:InTolBarad(ns.data.location) then
        local string, _ = ...
        if string:match(L.TolBarad) and not string:match("1") then
            local control = string:match(L.Alliance) and "alliance" or "horde"
            ns:DebugPrint(L.DebugRaidBossEmote:format(string))
            if not ns.data.toggles.recentlyEnded then
                ns:Toggle("recentlyEnded", ns.data.timeouts.short)
                ns:IncrementCounts(string)
                if ns:OptionValue(TBW_options, "printWinsOnEnd") then
                    ns:PrintCounts()
                end
                ns:TimerCheck(false, 3600, control)
                if ns.DataSource then
                    ns.DataSource.text = ns:TimeFormat(GetServerTime() + 3600)
                end
            end
        end
    end
end

-- Addon Compartment Handling

AddonCompartmentFrame:RegisterAddon({
    text = ns.name,
    icon = ns.icon,
    registerForAnyClick = true,
    notCheckable = true,
    func = function(button, menuInputData, menu)
        local mouseButton = menuInputData.buttonName
        if IsAltKeyDown() then
            ns:SendStart(nil, nil, true, true)
        elseif IsControlKeyDown() or IsShiftKeyDown() then
            ns:GetSendTarget(IsControlKeyDown())
        elseif mouseButton == "RightButton" then
            ns:SendStart(nil, nil, false, true)
        else
            ns:OpenSettings()
        end
    end,
    funcOnEnter = function(menuItem)
        local now = GetServerTime()
        local timestamp = TBW_data[ns.data.warmode and "startTimestampWM" or "startTimestamp"]
        local wmMismatchAlert
        GameTooltip:SetOwner(menuItem)
        GameTooltip:SetText(ns.name .. "  v" .. ns.version)
        if now < TBW_data.startTimestampWM + ns.data.durations.full then
            wmMismatchAlert = (ns:OptionValue(TBW_options, "warnAboutWMMismatch") and ns.data.warmode == false) and "|n|cffffff00" .. L.AlertToggleWarmode:format(enabledString) .. "|r" or ""
            GameTooltip:AddLine(" ", 1, 1, 1, true)
            if now < TBW_data.startTimestampWM then
                GameTooltip:AddLine("|cff" .. ns.color .. L.TimerRaidWarning:format(TBW_data.controlWM == "alliance" and allianceString or hordeString, enabledString) .. "|r |cffffffff" .. ns:AlertFuture(now, TBW_data.startTimestampWM) .. wmMismatchAlert .. "|r", 1, 1, 1, true)
            else
                GameTooltip:AddLine("|cff" .. ns.color .. L.TimerRaidWarning:format(TBW_data.controlWM == "alliance" and allianceString or hordeString, enabledString) .. "|r |cffffffff" .. ns:AlertPast(now, TBW_data.startTimestampWM) .. wmMismatchAlert .. "|r", 1, 1, 1, true)
            end
        end
        if now < TBW_data.startTimestamp + ns.data.durations.full then
            wmMismatchAlert = (ns:OptionValue(TBW_options, "warnAboutWMMismatch") and ns.data.warmode == true) and "|n|cffffff00" .. L.AlertToggleWarmode:format(disabledString) .. "|r" or ""
            GameTooltip:AddLine(" ", 1, 1, 1, true)
            if now < TBW_data.startTimestamp then
                GameTooltip:AddLine("|cff" .. ns.color .. L.TimerRaidWarning:format(TBW_data.control == "alliance" and allianceString or hordeString, disabledString) .. "|r |cffffffff" .. ns:AlertFuture(now, TBW_data.startTimestamp) .. wmMismatchAlert .. "|r", 1, 1, 1, true)
            else
                GameTooltip:AddLine("|cff" .. ns.color .. L.TimerRaidWarning:format(TBW_data.control == "alliance" and allianceString or hordeString, disabledString) .. "|r |cffffffff" .. ns:AlertPast(now, TBW_data.startTimestamp) .. wmMismatchAlert .. "|r", 1, 1, 1, true)
            end
        end
        GameTooltip:AddLine(" ", 1, 1, 1, true)
        GameTooltip:AddLine(L.AddonCompartmentTooltip1, 1, 1, 1, true)
        GameTooltip:AddLine(L.AddonCompartmentTooltip2, 1, 1, 1, true)
        GameTooltip:AddLine(L.AddonCompartmentTooltip3, 1, 1, 1, true)
        GameTooltip:AddLine(L.AddonCompartmentTooltip4, 1, 1, 1, true)
        GameTooltip:AddLine(L.AddonCompartmentTooltip5, 1, 1, 1, true)
        GameTooltip:Show()
    end,
    funcOnLeave = function()
        GameTooltip:Hide()
    end,
})

-- Slash Command Handling

SlashCmdList["TOLBARADWHEN"] = function(message)
    if message == "v" or message:match("ver") then
        -- Print the current addon version
        ns:PrettyPrint(L.Version:format(ns.version))
    elseif message == "h" or message:match("help") then
        -- Print ways to interact with addon
        ns:PrettyPrint("|n" .. L.Help)
    elseif message == "c" or message:match("con") or message == "o" or message:match("opt") or message:match("sett") or message:match("togg") then
        -- Open settings window
        ns:OpenSettings()
    elseif message == "r" or message:match("req") then
        -- Request TB times from an appropriate chat channel
        if ns:OptionValue(TBW_options, "share") then
            local _, channel, target = strsplit(" ", message)
            ns:RequestStart(channel, target)
        else
            ns:PrettyPrint(L.WarningShareDisabled)
        end
    elseif message:match("ann") then
        -- Announce your timers in an appropriate chat channel
        local _, channel, target = strsplit(" ", message)
        ns:SendStart(channel, target, true, true)
    elseif message == "s" or message:match("send") or message:match("share") then
        -- Share your timers in an appropriate chat channel
        if ns:OptionValue(TBW_options, "share") then
            local _, channel, target = strsplit(" ", message)
            ns:SendStart(channel, target, false, true)
        else
            ns:PrettyPrint(L.WarningShareDisabled)
        end
    elseif message == "w" or message:match("win") or message == "g" or message:match("game") or message == "b" or message:match("battle") then
        -- Print wins / battles counts
        ns:PrintCounts()
    elseif message == "d" or message:match("bug") then
        -- Debug
        local now = GetServerTime()
        print((TBW_data.startTimestampWM - now) .. "  " .. L.AlertDetail:format((TBW_data.controlWM == "alliance" and allianceString or hordeString), "|cff44ff44" .. L.Enabled .. "|r"))
        print((TBW_data.startTimestamp - now) .. "  " .. L.AlertDetail:format((TBW_data.control == "alliance" and allianceString or hordeString), "|cffff4444" .. L.Disabled .. "|r"))
        -- Handle Debug enabling/disabling
        if not TBW_options[ns.prefix .. "allowDebug"] and not message:match("disable") then
            TBW_options[ns.prefix .. "allowDebug"] = true
            ns:PrettyPrint(L.DebugEnabled)
        elseif message:match("disable") then
            TBW_options[ns.prefix .. "allowDebug"] = false
            TBW_options[ns.prefix .. "debug"] = false
        end
    else
        -- Print your timers
        ns:TimerCheck(true)
    end
end
SLASH_TOLBARADWHEN1 = "/" .. ns.command
SLASH_TOLBARADWHEN2 = "/tb"
SLASH_TOLBARADWHEN3 = "/tolbarad"
SLASH_TOLBARADWHEN4 = "/tolbaradwhen"
