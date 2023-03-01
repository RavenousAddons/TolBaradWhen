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

    layout:AddInitializer(CreateSettingsListSectionHeaderInitializer("When do you want to be alerted?"))

    for index = 1, #L.OptionsWhen do
        local option = L.OptionsWhen[index]
        CreateCheckBox(category, option.key, option.name, option.tooltip)
    end

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
