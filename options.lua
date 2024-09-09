local ADDON_NAME, ns = ...
local L = ns.L

local defaults = ns.data.defaults

local function CreateCheckBox(category, variable, name, tooltip)
    local setting = Settings.RegisterAddOnSetting(category, ns.prefix .. variable, ns.prefix .. variable, TBW_options, type(defaults[variable]), name, defaults[variable])
    Settings.CreateCheckbox(category, setting, tooltip)
end

local function CreateDropDown(category, variable, name, options, tooltip)
    local setting = Settings.RegisterAddOnSetting(category, ns.prefix .. variable, ns.prefix .. variable, TBW_options, type(defaults[variable]), name, defaults[variable])
    Settings.CreateDropdown(category, setting, options, tooltip)
end

function ns:CreateSettingsPanel()
    local category, layout = Settings.RegisterVerticalLayoutCategory(ns.name)
    Settings.RegisterAddOnCategory(category)

    layout:AddInitializer(CreateSettingsListSectionHeaderInitializer(L.OptionsTitle1))

    for index = 1, #L.OptionsWhen do
        local option = L.OptionsWhen[index]
        if option.optionValue == nil or (option.optionValue and ns:OptionValue(option.optionValue)) then
            if option.fn then
                CreateDropDown(category, option.key, option.name, option.fn, option.tooltip)
            else
                CreateCheckBox(category, option.key, option.name, option.tooltip)
            end
        end
    end

    layout:AddInitializer(CreateSettingsListSectionHeaderInitializer(L.OptionsTitle2))

    for index = 1, #L.OptionsHow do
        local option = L.OptionsHow[index]
        if option.optionValue == nil or (option.optionValue and ns:OptionValue(option.optionValue)) then
            if option.fn then
                CreateDropDown(category, option.key, option.name, option.fn, option.tooltip)
            else
                CreateCheckBox(category, option.key, option.name, option.tooltip)
            end
        end
    end

    layout:AddInitializer(CreateSettingsListSectionHeaderInitializer(L.OptionsTitle3))

    for index = 1, #L.OptionsExtra do
        local option = L.OptionsExtra[index]
        if option.optionValue == nil or (option.optionValue and ns:OptionValue(option.optionValue)) then
            if option.fn then
                CreateDropDown(category, option.key, option.name, option.fn, option.tooltip)
            else
                CreateCheckBox(category, option.key, option.name, option.tooltip)
            end
        end
    end

    ns.Settings = category
end
