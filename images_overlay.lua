--[[
  Images Overlay
  Created by Juimun ❤❤❤
  GitHub: https://github.com/Juimun/uc-dota2-scripts
  Version: 2.3.1
  Description: Рендерит над портретом героя выбранное изображение по ссылке
]]--

local CONFIG = { --CONGIFS
  FILE_NAME = "images_overlay",
  NONE = "None",
  MAIN_CONFIG_KEY = "data",
  PRESETS_CONFIG_KEY = "presets_data",
  DEFAULT_IMAGE = { --DEFAULT_IMAGE
    NAME = "Umbrella",
    LINK = "https://i.imgur.com/mrygCXZ.gif",
  }, --DEFAULT_IMAGE
  SCALE = { --SCALE
    MIN = 0,
    MAX = 45,
  }, --SCALE
  OPACITY = { --OPACITY
    MIN_ALPHA = 0,
    MAX_ALPHA = 255,
    DYNAMIC_ALPHA = 254,
    WARNING_ALPHA = 255,
    MAX_DISTANCE = 150,
    WARNING_DISTANCE = 350,
    MODE = { --MODE
      STATIC = "Static",
      DYNAMIC = "Dynamic"
    } --MODE
  }, --OPACITY
  BORDER = { --BORDER
    MIN = 0,
    MAX = 10,
    DEFAULT_COLOR = Color(255, 0, 0, 255)
  }, --BORDER
  UI = { --UI
    STEP_OFFSET = 0.0005,
    BASE_OFFSET = 0.053,
    BASE_Y_OFFSET = 0.045,
    BASE_SIZE = 0.033,
    MENU_NAMES = { --MENU_NAMES
      "preset_selector", "custom_name", "custom_link",
      "add_item", "remove_item", "default_item", "custom_scale",
      "custom_rounding", "alpha_selector", "dynamic_opacity_scale",
      "static_opacity_scale", "warning_opacity_scale", "border_switch",
      "border_thickness", "border_color", "add_preset", "preset_name",
      "preset_list", "delete_preset", "use_preset", "update_preset",
    }, --MENU_NAMES
  }, --UI
  PRESET_MAPPING = { --PRESET_MAPPING
    selected_image_key = "selected_image_key",
    custom_scale = "custom_scale",
    custom_rounding = "custom_rounding",
    alpha_selector = "alpha_selector",
    dynamic_opacity_scale = "dynamic_opacity_scale",
    static_opacity_scale = "static_opacity_scale",
    warning_opacity_scale = "warning_opacity_scale",
    border_switch = "border_switch",
    border_thickness = "border_thickness",
    border_color = "border_color",
  }, --PRESET_MAPPING
  ICONS = { --ICONS
    HEADER = "\u{1F58C}",
    SWITCH = "\u{f00c}",
    COMBO = "\u{1F4CB}",
    INPUT = "\u{1F520}",
    LINK = "\u{1F517}",
    SCALE = "\u{f1ce}",
    COLOR = "\u{f53f}",
    OPACITY = "\u{1F4A7}",
  }, --ICONS
  TEXT = { --TEXT
    TOOLTIP = { --TOOLTIP
      MAIN = "❤❤❤",
      ADD_BUTTON = "Add new image link to the list",
      REMOVE_BUTTON = "Remove selected image from the list",
      DEFAULT_BUTTON = "Load demo preset with default settings",
      OPACITY_SCALE = "Maximum transparency in the image area",
      WARNING_SCALE = "Maximum transparency in the area in front of the image",
      ADD_PRESET_BUTTON = "Save current settings as new preset",
      DELETE_PRESET_BUTTON = "Delete selected preset from the list",
      USE_PRESET_BUTTON = "Apply selected preset settings",
      UPDATE_PRESET_BUTTON = "Update selected preset with current settings",
    } --TOOLTIP
  } --TEXT
} --CONGIFS


local JSON = require('assets.JSON')


local Utils = { --Utils
  Trim = function(str)
    return string.match(str, "^%s*(.-)%s*$") or ""
  end, --Trim

  IsNotEmpty = function(str)
    return str ~= nil and str ~= ""
  end, --IsNotEmpty

  IsLink = function(self, link)
    local trimmed_link = self.Trim(link)
    if not self.IsNotEmpty(trimmed_link) then return false end
    return string.match(trimmed_link, "https?://.+") ~= nil
  end, --IsLink

  ApplySettings = function(ui, settings, mapping)
    for ui_key, setting_key in pairs(mapping) do
      if settings[setting_key] ~= nil and ui[ui_key] then
        if setting_key == "border_color" then
          local color = settings[setting_key]
          ui[ui_key]:Set(Color(color.r, color.g, color.b, color.a))
        else
          ui[ui_key]:Set(settings[setting_key])
        end
      end
    end
  end, --ApplySettings

  IsEmptyTable = function(preset_index, preset_list)
    return preset_index < 0 or preset_index >= #preset_list or preset_list[preset_index + 1] == CONFIG.NONE
  end, --IsEmptyTable

  Calculate = { --Calculate
    Offset = function(screen_size, size, thickness)
      local base_offset = CONFIG.UI.BASE_OFFSET + math.floor((thickness - 1) / 2) * CONFIG.UI.STEP_OFFSET
      return Vec2(screen_size.y * base_offset, screen_size.y * CONFIG.UI.BASE_Y_OFFSET) + Vec2(size.x, 0)
    end, --Offset

    Opacity = function(distance, min_alpha, warning_alpha)
      local warning_distance = CONFIG.OPACITY.WARNING_DISTANCE
      local max_distance = CONFIG.OPACITY.MAX_DISTANCE
      local max_alpha = CONFIG.OPACITY.MAX_ALPHA

      if distance >= warning_distance then
        return max_alpha
      elseif distance >= max_distance then
        local ratio = (distance - max_distance) / (warning_distance - max_distance)
        return warning_alpha + (max_alpha - warning_alpha) * ratio
      else
        local ratio = distance / max_distance
        return min_alpha + (warning_alpha - min_alpha) * ratio
      end --if
    end, --Opacity

    ScaleImage = function(self, screen_size, hero, border_thickness, scale_value)
      local size = Vec2(screen_size.y * CONFIG.UI.BASE_SIZE, screen_size.y * CONFIG.UI.BASE_SIZE)
      local offset = self.Offset(screen_size, size, border_thickness)
      local pos = Render.WorldToScreen(Entity.GetAbsOrigin(hero) + Vector(0, 0, NPC.GetHealthBarOffset(hero))) - offset
      
      return {
        size = size + Vec2(scale_value, scale_value),
        pos = pos - Vec2(scale_value, scale_value)
      }
    end, --ScaleImage

    MouseDistance = function(pos, size)
      local mouse_x, mouse_y = Input.GetCursorPos()
      local mouse_pos = Vec2(mouse_x, mouse_y)
      local image_center = pos + size / 2

      return (mouse_pos - image_center):Length()
    end --MouseDistance
  } --Calculate
} --Utils


local Data = { --Data
  ConfigExists = function()
    local success, config_string = pcall(function()
      return Config.ReadString(CONFIG.FILE_NAME, CONFIG.MAIN_CONFIG_KEY)
    end) --pcall

    if success and Utils.IsNotEmpty(config_string) then return true end
    return false
  end, --ConfigExists

  SaveConfig = function(data)
    if not data or type(data) ~= "table" then return false end

    local success, encode = pcall(function()
      return JSON:encode(data)
    end) --pcall
    if not success or not encode then return false end

    local write_success = pcall(function()
      Config.WriteString(CONFIG.FILE_NAME, CONFIG.MAIN_CONFIG_KEY, encode)
    end) --pcall

    return write_success
  end, --SaveConfig

  ReadConfig = function()
    local success, config_string = pcall(function()
      return Config.ReadString(CONFIG.FILE_NAME, CONFIG.MAIN_CONFIG_KEY)
    end) --pcall

    if not success or not config_string or config_string == "" then
      return {[CONFIG.NONE] = ""}
    end --if

    local decode_success, decoded_data = pcall(function()
      return JSON:decode(config_string)
    end) --pcall
    if decode_success and decoded_data then
      return decoded_data
    else
      return {[CONFIG.NONE] = ""}
    end --if
  end, --ReadConfig

  Load = function(self)
    if not self.ConfigExists() then
      local default_data = {[CONFIG.DEFAULT_IMAGE.NAME] = CONFIG.DEFAULT_IMAGE.LINK}

      self.SaveConfig(default_data)
      return default_data
    else
      local loaded_data = self.ReadConfig()
      if not loaded_data or next(loaded_data) == nil or loaded_data[CONFIG.NONE] then
        local default_data = {[CONFIG.DEFAULT_IMAGE.NAME] = CONFIG.DEFAULT_IMAGE.LINK}
        self.SaveConfig(default_data)
        return default_data
      end --if

      return loaded_data
    end --if
  end, --Load

  GetKeys = function(data)
    local keys = {}
    for key in pairs(data) do
      table.insert(keys, key)
    end --for
    table.sort(keys)
    return keys
  end, --GetKeys

  AddItem = function(self, data, name, link)
    if not Utils.IsNotEmpty(name) or not Utils:IsLink(link) then
      return self.GetKeys(data)
    end --if

    if data[CONFIG.NONE] then data[CONFIG.NONE] = nil end
    data[name] = link

    self.SaveConfig(data)
    return self.GetKeys(data)
  end,

  RemoveItem = function(self, data, index)
    local keys = self.GetKeys(data)
    if index < 1 or index > #keys then return keys end

    local remove_item = keys[index]
    if remove_item == CONFIG.NONE then return keys end

    data[remove_item] = nil 
    if next(data) == nil then data[CONFIG.NONE] = "" end

    self.SaveConfig(data)
    return self.GetKeys(data)
  end,

  DefaultItem = function(self, data, image_name, image_link)
    for key in pairs(data) do data[key] = nil end
    data[image_name] = image_link

    self.SaveConfig(data)
    return self.GetKeys(data)
  end,

  Preset = { --Preset
    SavePresetsConfig = function(data)
      if not data or type(data) ~= "table" then return false end

      local success, encode = pcall(function()
        return JSON:encode(data)
      end) --pcall
      if not success or not encode then return false end

      local write_success = pcall(function()
        Config.WriteString(CONFIG.FILE_NAME, CONFIG.PRESETS_CONFIG_KEY, encode)
      end) --pcall

      return write_success
    end, --SavePresetsConfig

    ReadPresetsConfig = function()
      local success, config_string = pcall(function()
        return Config.ReadString(CONFIG.FILE_NAME, CONFIG.PRESETS_CONFIG_KEY)
      end) --pcall

      if not success or not config_string or config_string == "" then
        return {CONFIG.NONE}
      end --if

      local decode_success, decoded_data = pcall(function()
        return JSON:decode(config_string)
      end) --pcall
      if decode_success and decoded_data then
        return decoded_data
      else
        return {CONFIG.NONE}
      end --if
    end, --ReadPresetsConfig

    LoadPresets = function(self)
      local presets_data = self.ReadPresetsConfig()
      local presets = {}

      for name in pairs(presets_data) do
        table.insert(presets, name)
      end --for

      if #presets == 0 then return {CONFIG.NONE} end

      table.sort(presets)
      return presets
    end, --LoadPresets

    Save = function(self, preset_name, settings)
      local presets_data = self.ReadPresetsConfig()
      presets_data[preset_name] = settings
      self.SavePresetsConfig(presets_data)
    end, --Save

    Load = function(self, preset_name)
      local presets_data = self.ReadPresetsConfig()
      return presets_data[preset_name] or {}
    end, --Load

    Delete = function(self, preset_name)
      local presets_data = self.ReadPresetsConfig()
      presets_data[preset_name] = nil
      self.SavePresetsConfig(presets_data)
    end --Delete
  } --Preset
} --Data


local UI = { --UI
  SetControlsState = function(ui, state)
    for _, control in pairs(CONFIG.UI.MENU_NAMES) do
      if ui[control] then
        ui[control]:Disabled(not state)
      end --if
    end --for
  end, --SetControlsState

  SetBorderState = function(ui, state)
    ui.border_thickness:Disabled(not state)
    ui.border_color:Disabled(not state)
  end, --SetBorderState

  SetOpacityState = function(ui, mode)
    if mode == CONFIG.OPACITY.MODE.STATIC then
      ui.dynamic_opacity_scale:Visible(false)
      ui.static_opacity_scale:Visible(true)
      ui.warning_opacity_scale:Visible(false)
    else
      ui.dynamic_opacity_scale:Visible(true)
      ui.static_opacity_scale:Visible(false)
      ui.warning_opacity_scale:Visible(true)
    end --if
  end, --SetOpacityState

  UpdateOpacityLimits = function(ui)
    local current_value = ui.dynamic_opacity_scale:Get()
    local warning_value = ui.warning_opacity_scale:Get()

    if current_value >= warning_value then
      local new_max = math.max(CONFIG.OPACITY.MIN_ALPHA, warning_value - 1)
      ui.dynamic_opacity_scale:Update(0, new_max, new_max)
    else
      local new_max = math.max(0, warning_value - 1)
      if current_value > new_max then
        ui.dynamic_opacity_scale:Update(CONFIG.OPACITY.MIN_ALPHA, new_max, new_max)
      else
        ui.dynamic_opacity_scale:Update(CONFIG.OPACITY.MIN_ALPHA, new_max, current_value)
      end --if
    end --if
  end, --UpdateOpacityLimits

  SelectedSettings = function(ui)
    return { --settings
    global_switch = ui.global_switch:Get(),
    selected_image_key = ui.preset_selector:List()[ui.preset_selector:Get() + 1],

    custom_scale = ui.custom_scale:Get(),
    custom_rounding = ui.custom_rounding:Get(),

    alpha_selector = ui.alpha_selector:Get(),
    dynamic_opacity_scale = ui.dynamic_opacity_scale:Get(),
    static_opacity_scale = ui.static_opacity_scale:Get(),
    warning_opacity_scale = ui.warning_opacity_scale:Get(),

    border_switch = ui.border_switch:Get(),
    border_thickness = ui.border_thickness:Get(),
    border_color = {
      r = ui.border_color:Get().r,
      g = ui.border_color:Get().g,
      b = ui.border_color:Get().b,
      a = ui.border_color:Get().a
    },
  } --settings
  end --SelectedSettings
} --UI


local Rendered = { --Rendered
  Image = function(ui, image, scaled_image, alpha)
    Render.Image(
      image,
      scaled_image.pos - ui.border_thickness:Get(),
      scaled_image.size + ui.border_thickness:Get(),
      Color(255, 255, 255, alpha),
      ui.custom_rounding:Get()
    ) --Image
  end, --Image

  Border = function(ui, scaled_image, alpha)
    local border_color = ui.border_color:Get()

    Render.Rect(
      scaled_image.pos - ui.border_thickness:Get(),
      scaled_image.pos + scaled_image.size,
      Color(border_color.r, border_color.g, border_color.b, alpha),
      ui.custom_rounding:Get(),
      Enum.DrawFlags.None,
      ui.border_thickness:Get()
    ) --Rect
  end, --Border

  FramedImage = function(self, ui, image, scaled_image, alpha)
    self.Image(ui, image, scaled_image, alpha)
    if ui.border_switch:Get() then self.Border(ui,scaled_image, alpha) end
  end, --FramedImage
} --Rendered


local script = {}

function script:CreateUI(keys, presets)
  --#region Header
  self.header = Menu.Create("Changer", "Main", "Images Overlay")

  local main_page = self.header:Create("Main")
  local settings_page = self.header:Create("Settings")
  local preset_page = self.header:Create("Presets")
  --#endregion Header

  --Main
  local main = main_page:Create("Images", 3)
  local list_settings = main_page:Create("List Images Settings", 3)

  --Settings
  local image_settings = settings_page:Create("Image Settings", 3)
  local opacity_settings = settings_page:Create("Opacity Settings")
  local border_settings = settings_page:Create("Border Settings")

  -- Presets
  local demo_preset = preset_page:Create("Demo", 3)
  local main_preset = preset_page:Create("Presets")
  local preset_settings = preset_page:Create("Presets Settings")

  self.ui = { --ui
    --Images
    global_switch = main:Switch("Enable", false),
    preset_selector = main:Combo("List Images", keys),

    --Image List
    custom_name = list_settings:Input("Image name", ""),
    custom_link = list_settings:Input("Custom link", ""),

    --#region Settings
    --Image
    custom_scale = image_settings:Slider("Image Scale", CONFIG.SCALE.MIN, CONFIG.SCALE.MAX, CONFIG.SCALE.MIN),
    custom_rounding = image_settings:Slider("Rounding Scale", CONFIG.SCALE.MIN, CONFIG.SCALE.MAX, CONFIG.SCALE.MIN),

    --Border
    border_switch = border_settings:Switch("Enable Border", false),
    border_thickness = border_settings:Slider("Border Thickness", CONFIG.BORDER.MIN, CONFIG.BORDER.MAX, CONFIG.BORDER.MIN),
    border_color = border_settings:ColorPicker("Border Color", CONFIG.BORDER.DEFAULT_COLOR),

    --Opacity
    alpha_selector = opacity_settings:Combo("Opacity Mode", {CONFIG.OPACITY.MODE.STATIC, CONFIG.OPACITY.MODE.DYNAMIC}),
    dynamic_opacity_scale = opacity_settings:Slider("Opacity Scale", CONFIG.OPACITY.MIN_ALPHA, CONFIG.OPACITY.DYNAMIC_ALPHA, CONFIG.OPACITY.MIN_ALPHA),
    static_opacity_scale = opacity_settings:Slider("Opacity Scale", CONFIG.OPACITY.MIN_ALPHA, CONFIG.OPACITY.MAX_ALPHA, CONFIG.OPACITY.MAX_ALPHA),
    warning_opacity_scale = opacity_settings:Slider("Warning Opacity Scale", CONFIG.OPACITY.MIN_ALPHA, CONFIG.OPACITY.MAX_ALPHA, CONFIG.OPACITY.MAX_ALPHA),
    --#endregion Settings

    --Presets
    preset_list = main_preset:Combo("Preset List", presets),
    preset_name = preset_settings:Input("Preset name", ""),

    -- Buttons
    add_item = list_settings:Button("Add link", function() self:AddItem() end),
    remove_item = list_settings:Button("Remove link", function() self:RemoveItem() end),
    use_preset = main_preset:Button("Use Preset", function() self:UsePreset() end),
    update_preset = main_preset:Button("Update Preset", function() self:UpdatePreset() end),
    delete_preset = main_preset:Button("Delete Preset", function() self:DeletePreset() end),
    default_item = demo_preset:Button("Demo Preset", function() self:DefaultPreset() end),
    add_preset = preset_settings:Button("Save Preset", function() self:AddPreset() end),
  } --ui

  self:DecorationUI(self.ui, self.header)
end --CreateUI

function script:DecorationUI(ui, header)
  --#region Icons
  header:Icon(CONFIG.ICONS.HEADER)

  ui.global_switch:Icon(CONFIG.ICONS.SWITCH)
  ui.border_switch:Icon(CONFIG.ICONS.SWITCH)

  ui.preset_selector:Icon(CONFIG.ICONS.COMBO)
  ui.alpha_selector:Icon(CONFIG.ICONS.COMBO)
  ui.preset_list:Icon(CONFIG.ICONS.COMBO)

  ui.preset_name:Icon(CONFIG.ICONS.INPUT)
  ui.custom_name:Icon(CONFIG.ICONS.INPUT)
  ui.custom_link:Icon(CONFIG.ICONS.LINK)

  ui.custom_scale:Icon(CONFIG.ICONS.SCALE)
  ui.custom_rounding:Icon(CONFIG.ICONS.SCALE)
  ui.border_thickness:Icon(CONFIG.ICONS.SCALE)

  ui.border_color:Icon(CONFIG.ICONS.COLOR)

  ui.dynamic_opacity_scale:Icon(CONFIG.ICONS.OPACITY)
  ui.static_opacity_scale:Icon(CONFIG.ICONS.OPACITY)
  ui.warning_opacity_scale:Icon(CONFIG.ICONS.OPACITY)
  --#endregion Icons

  --#region ToolTips
  ui.global_switch:ToolTip(CONFIG.TEXT.TOOLTIP.MAIN)

  ui.add_item:ToolTip(CONFIG.TEXT.TOOLTIP.ADD_BUTTON)
  ui.remove_item:ToolTip(CONFIG.TEXT.TOOLTIP.REMOVE_BUTTON)
  ui.default_item:ToolTip(CONFIG.TEXT.TOOLTIP.DEFAULT_BUTTON)
  ui.delete_preset:ToolTip(CONFIG.TEXT.TOOLTIP.DELETE_PRESET_BUTTON)
  ui.use_preset:ToolTip(CONFIG.TEXT.TOOLTIP.USE_PRESET_BUTTON)
  ui.add_preset:ToolTip(CONFIG.TEXT.TOOLTIP.ADD_PRESET_BUTTON)
  ui.update_preset:ToolTip(CONFIG.TEXT.TOOLTIP.UPDATE_PRESET_BUTTON)

  ui.dynamic_opacity_scale:ToolTip(CONFIG.TEXT.TOOLTIP.OPACITY_BUTTON)
  ui.warning_opacity_scale:ToolTip(CONFIG.TEXT.TOOLTIP.WARNING_BUTTON)
  --#endregion ToolTips
end --DecorationUI

function script:CallbacksUI()
  -- Switch callbacks
  script.ui.global_switch:SetCallback(function ()
    UI.SetControlsState(script.ui, script.ui.global_switch:Get())
  end, true)

  script.ui.border_switch:SetCallback(function ()
    UI.SetBorderState(script.ui, script.ui.border_switch:Get() and script.ui.global_switch:Get())
  end, true)

  script.ui.alpha_selector:SetCallback(function ()
    UI.SetOpacityState(script.ui, script.ui.alpha_selector:List()[script.ui.alpha_selector:Get() + 1])
  end, true)

  script.ui.warning_opacity_scale:SetCallback(function ()
    UI.UpdateOpacityLimits(script.ui)
  end, true)

  UI.SetControlsState(script.ui, script.ui.global_switch:Get())
  UI.SetBorderState(script.ui, script.ui.border_switch:Get() and script.ui.global_switch:Get())
  UI.SetOpacityState(script.ui, script.ui.alpha_selector:List()[script.ui.alpha_selector:Get() + 1])
  UI.UpdateOpacityLimits(script.ui)
end --CallbacksUI

function script:Initialize()
  self.data = Data:Load()

  local keys = Data.GetKeys(self.data)
  local presets = Data.Preset:LoadPresets()

  self:CreateUI(keys, presets)
  self:CallbacksUI()

  self.hero = Heroes.GetLocal()
  self.screen_size = Render.ScreenSize()
end --Initialize

function script:AddItem()
  local new_link = self.ui.custom_link:Get()
  local new_name = self.ui.custom_name:Get()

  if Utils:IsLink(new_link) and Utils.IsNotEmpty(new_name) then
    self:RemoveEntry()

    local keys = Data:AddItem(self.data, new_name, new_link)
    self.ui.preset_selector:Update(keys)

    self:SelectItemByName(keys, new_name)

    self.ui.border_switch:Set(true)

    Log.Write("[Images Overlay] [ ✓ ]\tИзображение добавлено!")
  end --if

  self.ui.custom_name:Set("")
  self.ui.custom_link:Set("")
end --AddItem

function script:RemoveEntry()
  local keys = Data.GetKeys(self.data)
  if #keys == 1 and keys[1] == CONFIG.NONE then
      self.data[CONFIG.NONE] = nil
  end --if
end --RemoveEntry

function script:SelectItemByName(keys, selected_name)
  for i, key in ipairs(keys) do
    if key == selected_name then
      self.ui.preset_selector:Set(i - 1)
      break
    end --if
  end --for
end --SelectItemByName

function script:RemoveItem()
  local index = self.ui.preset_selector:Get() + 1
  local keys = Data.GetKeys(self.data)
  local removed_key = keys[index]
  if not self:IsValidItemToRemove(removed_key) then return end

  self:RemoveDependentPresets(removed_key)

  keys = Data:RemoveItem(self.data, index)

  if #keys == 1 and keys[1] == CONFIG.NONE then
    self.ui.border_switch:Set(false)
  end

  self.ui.preset_selector:Set(0)
  self.ui.preset_selector:Update(keys)

  Log.Write("[Images Overlay] [ ✓ ]\tИзображение удалено!")
end --RemoveItem

function script:IsValidItemToRemove(key)
  return key and key ~= CONFIG.NONE
end --IsValidItemToRemove

function script:RemoveDependentPresets(removed_key)
  local presets_data = Data.Preset:ReadPresetsConfig()
  local delete_presets = {}

  for name, settings in pairs(presets_data) do
    if settings.selected_image_key == removed_key then
      table.insert(delete_presets, name)
    end --if
  end --for

  for _, name in ipairs(delete_presets) do Data.Preset:Delete(name) end

  if #delete_presets > 0 then
    local updated_presets = Data.Preset:LoadPresets()
    self.ui.preset_list:Update(updated_presets)
    self.ui.preset_list:Set(0)
  end --if
end --RemoveDependentPresets

function script:DefaultPreset()
  local keys = Data:DefaultItem(self.data, CONFIG.DEFAULT_IMAGE.NAME, CONFIG.DEFAULT_IMAGE.LINK)

  self:DeleteAllPresets()

  -- Выставляем пресет
  self.ui.preset_selector:Update(keys)
  self.ui.preset_selector:Set(0)

  self.ui.custom_scale:Set(0)
  self.ui.custom_rounding:Set(25)

  self.ui.border_switch:Set(true)
  self.ui.border_thickness:Set(2)
  self.ui.border_color:Set(CONFIG.BORDER.DEFAULT_COLOR)

  self.ui.warning_opacity_scale:Set(CONFIG.OPACITY.MAX_ALPHA)
  self.ui.dynamic_opacity_scale:Set(CONFIG.OPACITY.MIN_ALPHA)
  self.ui.static_opacity_scale:Set(CONFIG.OPACITY.MAX_ALPHA)

  Log.Write("[Images Overlay] [ ✓ ]\tДемонстрационный пресет установлен!")
end --DefaultPreset

function script:AddPreset()
  local preset_name = self.ui.preset_name:Get()
  if not Utils.IsNotEmpty(preset_name) then return end

  local settings = UI.SelectedSettings(self.ui)
  Data.Preset:Save(preset_name, settings)

  local preset_list = self.ui.preset_list:List()
  if #preset_list == 1 and preset_list[1] == CONFIG.NONE then preset_list[1] = nil end
  table.insert(preset_list, preset_name)

  self.ui.preset_list:Update(preset_list)
  self.ui.preset_name:Set("")

  Log.Write("[Images Overlay] [ ✓ ]\tПресед сохранен!")
end --AddPreset

function script:DeletePreset()
  local preset_index = self.ui.preset_list:Get()
  local preset_list = self.ui.preset_list:List()
  if Utils.IsEmptyTable(preset_index, preset_list) then return end

  local preset_name = preset_list[preset_index + 1]
  Data.Preset:Delete(preset_name)

  local updated_presets = Data.Preset:LoadPresets()
  self.ui.preset_list:Update(updated_presets)
  self.ui.preset_list:Set(0)

  Log.Write("[Images Overlay] [ ✓ ]\tПресет удален!")
end --DeletePreset

function script:DeleteAllPresets()
  local presets_data = Data.Preset:ReadPresetsConfig()

  if next(presets_data) ~= nil then
    for preset_name in pairs(presets_data) do
      Data.Preset:Delete(preset_name)
    end --for
  end --if

  self.ui.preset_list:Update({CONFIG.NONE})
  self.ui.preset_list:Set(0)
end --DeleteAllPresets

function script:UsePreset()
  local preset_index = self.ui.preset_list:Get()
  local preset_list = self.ui.preset_list:List()
  if Utils.IsEmptyTable(preset_index, preset_list) then return end

  local preset_name = preset_list[preset_index + 1]
  local settings = Data.Preset:Load(preset_name)
  if not settings or next(settings) == nil then return end

  Utils.ApplySettings(self.ui, settings, CONFIG.PRESET_MAPPING)
  self:UseSelectedPresetImageKey(settings.selected_image_key)

  UI.SetControlsState(self.ui, self.ui.global_switch:Get())
  UI.SetBorderState(self.ui, self.ui.border_switch:Get() and self.ui.global_switch:Get())
  UI.SetOpacityState(self.ui, self.ui.alpha_selector:List()[self.ui.alpha_selector:Get() + 1])
  UI.UpdateOpacityLimits(self.ui)

  Log.Write("[Images Overlay] [ ✓ ]\tПресет применен!")
end --UsePreset

function script:UpdatePreset()
  local preset_index = self.ui.preset_list:Get()
  local preset_list = self.ui.preset_list:List()
  if Utils.IsEmptyTable(preset_index, preset_list) then return end

  local preset_name = preset_list[preset_index + 1]
  local current_settings = UI.SelectedSettings(self.ui)

  Data.Preset:Save(preset_name, current_settings)

  Log.Write("[Images Overlay] [ ✓ ]\tПресет обновлен!")
end --UpdatePreset

function script:UseSelectedPresetImageKey(selected_key)
  if selected_key then
    local keys = self.ui.preset_selector:List()
    for i, key in ipairs(keys) do
      if key == selected_key then
        self.ui.preset_selector:Set(i - 1)
        break
      end --if
    end --for
  end --if
end --UseSelectedPresetImageKey

function script:CanDraw()
  return self.hero
     and Entity.IsAlive(self.hero)
     and self.ui.global_switch:Get()
end --CanDraw

function script:OnScriptsLoaded()
  script:Initialize()
end --OnScriptsLoaded

function script:OnDraw()
  if not script:CanDraw() then return end

  local key = script.ui.preset_selector:List()[script.ui.preset_selector:Get() + 1]
  local image = Render.LoadImage(script.data[key])

  local scaled_image = Utils.Calculate:ScaleImage(script.screen_size, script.hero, script.ui.border_thickness:Get(), script.ui.custom_scale:Get())
  local distance = Utils.Calculate.MouseDistance(scaled_image.pos, scaled_image.size)

  local alpha
  if script.ui.alpha_selector:List()[script.ui.alpha_selector:Get() + 1] == CONFIG.OPACITY.MODE.STATIC then
    alpha = script.ui.static_opacity_scale:Get()
  else
    alpha = Utils.Calculate.Opacity(distance, script.ui.dynamic_opacity_scale:Get(), script.ui.warning_opacity_scale:Get())
  end --if

  Rendered:FramedImage(script.ui, image, scaled_image, alpha)
end --OnDraw

return script