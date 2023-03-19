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

local function CreateDropDown(category, variable, name, options, tooltip)
    local setting = Settings.RegisterAddOnSetting(category, name, variable, type(defaults[variable]), TBW_data.options[variable])
    Settings.SetOnValueChangedCallback(variable, function(event)
        TBW_data.options[variable] = setting:GetValue()
    end)
    Settings.CreateDropDown(category, setting, options, tooltip)
end

function ns:CreateSettingsPanel()
    local category, layout = Settings.RegisterVerticalLayoutCategory(ns.name)

    layout:AddInitializer(CreateSettingsListSectionHeaderInitializer("When do you want to be alerted?"))

    for index = 1, #L.OptionsWhen do
        local option = L.OptionsWhen[index]
        CreateCheckBox(category, option.key, option.name, option.tooltip)
    end

    local function GetCustomAlertOptions()
        local container = Settings.CreateControlTextContainer()
        container:Add(1, "Disabled")
        for i = 15, 55, 5 do
            container:Add(i, i .. " minutes")
        end
        return container:GetData()
    end
    CreateDropDown(category, L.OptionsWhenCustom.key, L.OptionsWhenCustom.name, GetCustomAlertOptions, L.OptionsWhenCustom.tooltip)

    layout:AddInitializer(CreateSettingsListSectionHeaderInitializer("How do you want to be alerted?"))

    for index = 1, #L.OptionsHow do
        local option = L.OptionsHow[index]
        CreateCheckBox(category, option.key, option.name, option.tooltip)
    end

    layout:AddInitializer(CreateSettingsListSectionHeaderInitializer("Extra Options:"))

    for index = 1, #L.OptionsExtra do
        local option = L.OptionsExtra[index]
        CreateCheckBox(category, option.key, option.name, option.tooltip)
    end

    Settings.RegisterAddOnCategory(category)

    ns.Settings = category
end
