local ADDON_NAME, ns = ...
local L = ns.L

local defaults = ns.data.defaults

local function CreateCheckBox(category, variable, name, tooltip)
    local setting = Settings.RegisterAddOnSetting(category, name, variable, type(defaults[variable]), TBW_data.options[variable])
    Settings.SetOnValueChangedCallback(variable, function(event)
        TBW_data.options[variable] = setting:GetValue()
    end)
    Settings.CreateCheckBox(category, setting, tooltip)
end

function ns:CreateSettingsPanel()
    local category, layout = Settings.RegisterVerticalLayoutCategory(ns.name)

    layout:AddInitializer(CreateSettingsListSectionHeaderInitializer(_G.GAMEOPTIONS_MENU .. ":"))

    for option, _ in pairs(ns.data.defaults) do
        if option ~= "debug" then
            CreateCheckBox(category, option, L.Options[option].name, L.Options[option].tooltip)
        end
    end

    Settings.RegisterAddOnCategory(category)

    ns.Settings = category
end
