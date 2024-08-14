local ADDON_NAME, ns = ...
local L = ns.L

local CT = C_Timer

local allianceString = "|cff0078ff" .. _G.FACTION_ALLIANCE .. "|r"
local hordeString = "|cffb30000" .. _G.FACTION_HORDE .. "|r"

-- Load the Addon

function TolBaradWhen_OnLoad(self)
    self:RegisterEvent("PLAYER_LOGIN")
    self:RegisterEvent("CHAT_MSG_ADDON")
    self:RegisterEvent("GROUP_ROSTER_UPDATE")
    self:RegisterEvent("ZONE_CHANGED_NEW_AREA")
    self:RegisterEvent("RAID_BOSS_EMOTE")
end

-- Event Triggers

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
            ns:PrettyPrint("\n" .. L.DebugReceivedStart:format(sender, channel) .. "\n" .. message)
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
            ns:PrettyPrint(L.ReceivedRequest:format(sender, channel))
            local now = GetServerTime()
            if not ns.data.toggles.recentlyRequestedStart and (TBW_data.startTimestamp + 900 > now or TBW_data.startTimestampWM + 900 > now) then
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
                    ns:Toggle("recentlyReceivedStartWM", 30)
                    TBW_data.statusWM = statusWM
                    TBW_data.startTimestampWM = tonumber(startTimestampWM)
                    ns:BattleCheck(true)
                end
            end
            if not ns.data.toggles.recentlyReceivedStart then
                if tonumber(startTimestamp) > TBW_data.startTimestamp then
                    ns:Toggle("recentlyReceivedStart", 30)
                    TBW_data.status = status
                    TBW_data.startTimestamp = tonumber(startTimestamp)
                    ns:BattleCheck(true)
                end
            end
        end
    elseif event == "ZONE_CHANGED_NEW_AREA" then
        local newLocation = C_Map.GetBestMapForUnit("player")
        if not ns:Contains(ns.data.mapIDs, ns.data.location) or not ns:Contains(ns.data.mapIDs, newLocation) then
            CT.After(1, function()
                ns:BattleCheck()
            end)
        end
        ns.data.location = C_Map.GetBestMapForUnit("player")
    elseif event == "RAID_BOSS_EMOTE" and ns:Contains(ns.data.mapIDs, ns.data.location) and arg:match(L.TolBarad) and not arg:match("1") then
        if not ns.data.toggles.recentlyEnded then
            ns:Toggle("recentlyEnded", 3)
            CT.After(3, function()
                ns:IncrementCounts(arg)
                ns:PrintCounts()
                ns:BattleCheck()
            end)
        end
    end
end

AddonCompartmentFrame:RegisterAddon({
    text = ns.title,
    icon = ns.icon,
    registerForAnyClick = true,
    notCheckable = true,
    func = function(button, menuInputData, menu)
        local mouseButton = menuInputData.buttonName
        if mouseButton == "RightButton" then
            ns:SendStart()
            return
        end
        ns:OpenSettings()
    end,
    funcOnEnter = function(menuItem)
        GameTooltip:SetOwner(menuItem)
        GameTooltip:SetText(ns.name .. "        v" .. ns.version)
        GameTooltip:AddLine(" ", 1, 1, 1, true)
        GameTooltip:AddLine(L.AddonCompartmentTooltip1, 1, 1, 1, true)
        GameTooltip:AddLine(L.AddonCompartmentTooltip2, 1, 1, 1, true)
        GameTooltip:Show()
    end,
    funcOnLeave = function()
        GameTooltip:Hide()
    end,
})

SlashCmdList["TOLBARADWHEN"] = function(message)
    if message == "v" or message:match("ver") then
        -- Print the current addon version
        ns:PrettyPrint(L.Version:format(ns.version))
    elseif message == "h" or message:match("help") then
        -- Print ways to interact with addon
        ns:PrettyPrint(L.Help)
    elseif message == "c" or message:match("con") or message == "o" or message:match("opt") or message == "s" or message:match("sett") or message:match("togg") then
        -- Open settings window
        ns:OpenSettings()
    elseif message == "r" or message:match("req") then
        -- Request TB times from an appropriate chat channel
        if TBW_options.share then
            local _, channel, target = strsplit(" ", message)
            ns:RequestStart(channel, target)
        else
            ns:PrettyPrint(L.WarningDisabledShare)
        end
    elseif message == "a" or message:match("ann") then
        -- Announce your timers in an appropriate chat channel
        local _, channel, target = strsplit(" ", message)
        ns:SendStart(channel, target, true)
    elseif message == "s" or message:match("send") or message:match("share") then
        -- Share your timers in an appropriate chat channel
        if TBW_options.share then
            local _, channel, target = strsplit(" ", message)
            ns:SendStart(channel, target)
        else
            ns:PrettyPrint(L.WarningDisabledShare)
        end
    elseif message == "w" or message:match("win") or message == "g" or message:match("game") or message == "b" or message:match("battle") then
        -- Print win:loss counts
        ns:PrintCounts(true)
    elseif message == "d" or message:match("bug") then
        -- Debug
        local now = GetServerTime()
        print("|cff44ff44" .. L.WarMode .. " " .. L.On .. "|r " .. (TBW_data.statusWM == "alliance" and allianceString or hordeString) .. " " .. (TBW_data.startTimestampWM - now))
        print("|cffff4444" .. L.WarMode .. " " .. L.Off .. "|r " .. (TBW_data.status == "alliance" and allianceString or hordeString) .. " " .. (TBW_data.startTimestamp - now))
    else
        -- Print your timers
        ns:BattleCheck(true)
    end
end
SLASH_TOLBARADWHEN1 = "/" .. ns.command
SLASH_TOLBARADWHEN2 = "/tb"
SLASH_TOLBARADWHEN3 = "/tolbarad"
SLASH_TOLBARADWHEN4 = "/tolbaradwhen"
