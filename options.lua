local ADDON_NAME, ns = ...
local L = ns.L

local gameVersion = GetBuildInfo()

local defaults = ns.data.defaults

local function CreateCheckBox(category, option)
    local setting = Settings.RegisterAddOnSetting(category, ns.prefix .. option.key, ns.prefix .. option.key, TBW_options, type(defaults[option.key]), option.name, defaults[option.key])
    setting.owner = ADDON_NAME
    Settings.CreateCheckbox(category, setting, option.tooltip)
    if option.new == ns.version then
        if not NewSettings[gameVersion] then
            NewSettings[gameVersion] = {}
        end
        table.insert(NewSettings[gameVersion], ns.prefix .. option.key)
    end
end

local function CreateDropDown(category, option)
    local setting = Settings.RegisterAddOnSetting(category, ns.prefix .. option.key, ns.prefix .. option.key, TBW_options, type(defaults[option.key]), option.name, defaults[option.key])
    setting.owner = ADDON_NAME
    Settings.CreateDropdown(category, setting, option.fn, option.tooltip)
    if option.new == ns.version then
        if not NewSettings[gameVersion] then
            NewSettings[gameVersion] = {}
        end
        table.insert(NewSettings[gameVersion], ns.prefix .. option.key)
    end
end

function ns:CreateSettingsPanel()
    local category, layout = Settings.RegisterVerticalLayoutCategory(ns.name)
    Settings.RegisterAddOnCategory(category)

    layout:AddInitializer(CreateSettingsListSectionHeaderInitializer(L.OptionsTitle1))

    for index = 1, #L.OptionsWhen do
        local option = L.OptionsWhen[index]
        if option.optionValue == nil or (option.optionValue and ns:OptionValue(TBW_options, option.optionValue)) then
            if option.fn then
                CreateDropDown(category, option)
            else
                CreateCheckBox(category, option)
            end
        end
    end

    layout:AddInitializer(CreateSettingsListSectionHeaderInitializer(L.OptionsTitle2))

    for index = 1, #L.OptionsHow do
        local option = L.OptionsHow[index]
        if option.optionValue == nil or (option.optionValue and ns:OptionValue(TBW_options, option.optionValue)) then
            if option.fn then
                CreateDropDown(category, option)
            else
                CreateCheckBox(category, option)
            end
        end
    end

    layout:AddInitializer(CreateSettingsListSectionHeaderInitializer(L.OptionsTitle3))

    for index = 1, #L.OptionsExtra do
        local option = L.OptionsExtra[index]
        if option.optionValue == nil or (option.optionValue and ns:OptionValue(TBW_options, option.optionValue)) then
            if option.fn then
                CreateDropDown(category, option)
            else
                CreateCheckBox(category, option)
            end
        end
    end

    ns.Settings = category
end
