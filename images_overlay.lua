--[[
  Images Overlay
  Created by Juimun ❤❤❤
  GitHub: https://github.com/Juimun/uc-dota2-scripts
  Version: 2.2.1
  Description: Показывает на экране выбранное изображение из списка
]]--

local CONFIG = { --CONGIFS
  FILE_NAME = "images_overlay",
  NONE = "None",
  MAIN_CONFIG_KEY = "data",
  MAIN_PATH = Engine.GetCheatDirectory() .. "configs\\images_overlay.ini",
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
    MENU_NAMES = {
      "preset_selector", "custom_name", "custom_link",
      "add_item", "remove_item", "default_item", "custom_scale",
      "custom_rounding", "alpha_selector", "dynamic_opacity_scale",
      "static_opacity_scale", "warning_opacity_scale", "border_switch",
      "border_thickness", "border_color",
    },
  }, --UI
  ICONS = {
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
      ADD_BUTTON = "Enter the name and link to the image, then click the button to add it",
      REMOVE_BUTTON = "Select the desired image from the list, then click the button to delete it",
      DEFAULT_BUTTON = "Restores default settings",
      OPACITY_SCALE = "Maximum transparency in the image area",
      WARNING_SCALE = "Maximum transparency in the area in front of the image"
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

  File = { --File
    Exists = function(path)
      local file = io.open(path, "r")

      if file then
        local str = file:read("*a")
        io.close(file)

        if str and string.match(str, "%S") then
          return true
        end
      end
      return false
    end --Exists
  }, --File

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
    end
  } --Calculate
}


local Data = { --Data
  SaveConfig = function(data)
    local encode = JSON:encode(data)
    Config.WriteString(CONFIG.FILE_NAME, CONFIG.MAIN_CONFIG_KEY, encode)
  end, --SaveFile

  ReadConfig = function()
    local config_string = Config.ReadString(CONFIG.FILE_NAME, CONFIG.MAIN_CONFIG_KEY)
    return config_string
  end, --SaveFile

  Load = function(self)
    if not Utils.File.Exists(CONFIG.MAIN_PATH) then
      local default_data = {[CONFIG.DEFAULT_IMAGE.NAME] = CONFIG.DEFAULT_IMAGE.LINK}
      self.SaveConfig(default_data)
      return default_data
    else
      local decode_data = self.ReadConfig()
      return Utils.IsNotEmpty(decode_data) and JSON:decode(decode_data) or {[CONFIG.NONE] = ""}
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

  AddItem = function (self, data, name, link)
    data[name] = link
    self.SaveConfig(data)
    return self.GetKeys(data)
  end, --Add

  RemoveItem = function (self, data, index)
    local keys = self.GetKeys(data)
    if index < 1 or index > #keys then
      return keys
    end --if

    local remove_item = keys[index]
    data[remove_item] = nil
    if next(data) == nil then
      data[CONFIG.NONE] = ""
    end --if

    self.SaveConfig(data)
    return self.GetKeys(data)
  end, --Add

  DefaultItem = function (self, data)
    for key in pairs(data) do
      data[key] = nil
    end --for
    data[CONFIG.DEFAULT_IMAGE.NAME] = CONFIG.DEFAULT_IMAGE.LINK

    self.SaveConfig(data)
    return self.GetKeys(data)
  end --Default
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
  end --UpdateOpacityLimits
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

function script:CreateUI(keys)
  --#region Header
  self.header = Menu.Create("Changer", "Main", "Images Overlay")
  self.main = self.header:Create("Main"):Create("Images")
  self.image_settings = self.header:Create("Main"):Create("Image Settings")
  self.list_settings = self.header:Create("Main"):Create("List Images Settings")
  self.border_settings = self.header:Create("Main"):Create("Border Settings")
  --#endregion Header

  self.ui = { --ui
    --Images
    global_switch = self.main:Switch("Enable", false),
    preset_selector = self.main:Combo("List Images", keys),

    --Image List
    custom_name = self.list_settings:Input("Image name", ""),
    custom_link = self.list_settings:Input("Custom link", ""),

    --Settings
    custom_scale = self.image_settings:Slider("Image Scale", CONFIG.SCALE.MIN, CONFIG.SCALE.MAX, CONFIG.SCALE.MIN),
    custom_rounding = self.image_settings:Slider("Rounding Scale", CONFIG.SCALE.MIN, CONFIG.SCALE.MAX, CONFIG.SCALE.MIN),
    --#region Opacity
    alpha_selector = self.image_settings:Combo("Opacity Mode", {CONFIG.OPACITY.MODE.STATIC, CONFIG.OPACITY.MODE.DYNAMIC}),
    dynamic_opacity_scale = self.image_settings:Slider("Opacity Scale", CONFIG.OPACITY.MIN_ALPHA, CONFIG.OPACITY.DYNAMIC_ALPHA, CONFIG.OPACITY.MIN_ALPHA),
    static_opacity_scale = self.image_settings:Slider("Opacity Scale", CONFIG.OPACITY.MIN_ALPHA, CONFIG.OPACITY.MAX_ALPHA, CONFIG.OPACITY.MAX_ALPHA),
    warning_opacity_scale = self.image_settings:Slider("Warning Opacity Scale", CONFIG.OPACITY.MIN_ALPHA, CONFIG.OPACITY.MAX_ALPHA, CONFIG.OPACITY.MAX_ALPHA),
    --#endregion Opacity

    --Settings
    border_switch = self.border_settings:Switch("Enable Border", false),
    border_thickness = self.border_settings:Slider("Border Scale", CONFIG.BORDER.MIN, CONFIG.BORDER.MAX, CONFIG.BORDER.MIN),
    border_color = self.border_settings:ColorPicker("Border Color", CONFIG.BORDER.DEFAULT_COLOR),

    -- Buttons
    add_item = self.list_settings:Button("Add link to List Images", function() self:AddItem() end),
    remove_item = self.list_settings:Button("Remove link to List Images", function() self:RemoveItem() end),
    default_item = self.list_settings:Button("Default List Images", function() self:DefaultItem() end),
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

  -- Инициализация состояний
  UI.SetControlsState(script.ui, script.ui.global_switch:Get())
  UI.SetBorderState(script.ui, script.ui.border_switch:Get() and script.ui.global_switch:Get())
  UI.SetOpacityState(script.ui, script.ui.alpha_selector:List()[script.ui.alpha_selector:Get() + 1])
  UI.UpdateOpacityLimits(script.ui)
end --CallbacksUI

function script:Initialize()
  -- Data
  self.data = Data:Load()

  local keys = Data.GetKeys(self.data)

  -- UI
  self:CreateUI(keys)
  self:CallbacksUI()

  -- Game objects
  self.hero = Heroes.GetLocal()
  self.screen_size = Render.ScreenSize()
end --Initialize

function script:AddItem()
  local new_link = self.ui.custom_link:Get()
  local new_name = self.ui.custom_name:Get()

  if Utils:IsLink(new_link) and Utils.IsNotEmpty(new_name) then
    local keys = Data.GetKeys(self.data)

    if #keys == 1 and keys[1] == CONFIG.NONE then
      self.data[CONFIG.NONE] = nil
    end --if

    keys = Data:AddItem(self.data, new_name, new_link)
    self.ui.preset_selector:Update(keys)

    -- Вроде пишу фигню, но работает
    for i, key in ipairs(keys) do
      if key == new_name then
        self.ui.preset_selector:Set(i - 1)
        break
      end --if
    end --for

    self.ui.border_switch:Set(true)

    Log.Write("[Images Overlay]\tИзображение добавлено!")
  end --if

  self.ui.custom_name:Set("")
  self.ui.custom_link:Set("")
end --AddItem

function script:RemoveItem()
  local index = self.ui.preset_selector:Get() + 1
  local keys = Data:RemoveItem(self.data, index)

  if #keys == 1 and keys[1] == CONFIG.NONE then
    self.ui.border_switch:Set(false)
  end --if

  self.ui.preset_selector:Set(0)
  self.ui.preset_selector:Update(keys)

  Log.Write("[Images Overlay]\tИзображение удалено!")
end --RemoveItem

function script:DefaultItem()
  local keys = Data:DefaultItem(self.data)

  self.ui.preset_selector:Update(keys)
  self.ui.preset_selector:Set(0)

  -- Сброс настроек UI
  self.ui.custom_scale:Set(0)
  self.ui.custom_rounding:Set(0)
  self.ui.border_thickness:Set(0)
  self.ui.border_switch:Set(true)
  self.ui.border_color:Set(CONFIG.BORDER.DEFAULT_COLOR)
  self.ui.warning_opacity_scale:Set(CONFIG.OPACITY.MAX_ALPHA)
  self.ui.dynamic_opacity_scale:Set(CONFIG.OPACITY.MIN_ALPHA)
  self.ui.static_opacity_scale:Set(CONFIG.OPACITY.MAX_ALPHA)

  self.ui.border_switch:Disabled(false)
  self.ui.preset_selector:Disabled(false)

  Log.Write("[Images Overlay]\tНастройки по умолчанию установлены!")
end --DefaultItem

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