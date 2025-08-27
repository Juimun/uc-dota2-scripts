--[[
  Images Overlay
  Created by Juimun ❤❤❤
  GitHub: https://github.com/Juimun/uc-dota2-scripts
  Version: 2.1 - Reliable
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
  }, --OPACITY
  BORDER = { --BORDER
    MIN = 0,
    MAX = 10,
    DEFAULT_COLOR = Color(255, 0, 0, 255)
  }, --BORDER
  UI = { --UI
    OFFSET_STEP = 0.0005,
    BASE_OFFSET = 0.053,
    BASE_Y_OFFSET = 0.045,
    BASE_SIZE = 0.033
  }, --UI
} --CONGIFS

local JSON = require('assets.JSON')

-- Попробовать изменить структуру
local function Trim(str)
  return string.match(str, "^%s*(.-)%s*$") or ""
end

local function IsNotEmpty(str)
  return str ~= nil and str ~= ""
end

local function IsLink(link)
  local trimmed_link = Trim(link)
  if not IsNotEmpty(trimmed_link) then return false end
  return string.match(trimmed_link, "https?://.+") ~= nil
end

local Utils = { --Utils
  Trim = Trim,

  IsNotEmpty = IsNotEmpty,

  IsLink = IsLink,

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
      local base_offset = CONFIG.UI.BASE_OFFSET + math.floor((thickness - 1) / 2) * CONFIG.UI.OFFSET_STEP
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
  } --Calculate
} --Utils

local Data = { --Data
  SaveConfig = function(data)
    local encode = JSON:encode(data)
    Config.WriteString(CONFIG.FILE_NAME, CONFIG.MAIN_CONFIG_KEY, encode)
    Log.Write(" [DEBUG] Saving config: " .. encode)
  end, --SaveFile

  ReadConfig = function()
    local config_string = Config.ReadString(CONFIG.FILE_NAME, CONFIG.MAIN_CONFIG_KEY)
    Log.Write(" [DEBUG] Reading config: " .. (config_string or "nil"))
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

  Default = function (self, data)
    for key in pairs(data) do
      data[key] = nil
    end --for
    data[CONFIG.DEFAULT_IMAGE.NAME] = CONFIG.DEFAULT_IMAGE.LINK
    self.SaveConfig(data)
    return self.GetKeys(data)
  end --Default
} --Data

local UI = { --UI
  SetControlsState = function(script_instance, state)
    local ui = script_instance.ui
    local controls = {
      --Images
      "preset_selector",

      --Images List
      "custom_name",
      "custom_link",
      "add_item",
      "remove_item",
      "default_item",

      --Settings
      "custom_scale",
      "custom_rounding",
      --#region Opacity
      "alpha_selector",
      "dynamic_opacity_scale",
      "static_opacity_scale",
      "warning_opacity_scale",
      --#region Opacity

      --Border
      "border_switch",
      "border_thickness",
      "border_color",
    } --controls

    for _, control in pairs(controls) do
      if ui[control] then
        ui[control]:Disabled(not state)
      end --if
    end --for

    if script_instance.add_item then
      script_instance.add_item:Disabled(not state)
    end --if

    if script_instance.remove_item then
      script_instance.remove_item:Disabled(not state)
    end --if
    
    if script_instance.default_item then
      script_instance.default_item:Disabled(not state)
    end --if
  end, --SetControlsState

  SetBorderState = function(ui, state)
    ui.border_thickness:Disabled(not state)
    ui.border_color:Disabled(not state)
  end, --SetBorderState

  SetOpacityState = function(ui, mode)
    if mode == "Static" then
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

local script = {}

-- Создание UI
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
    alpha_selector = self.image_settings:Combo("Opacity Mode", {"Static", "Dynamic"}),
    dynamic_opacity_scale = self.image_settings:Slider("Opacity Scale", CONFIG.OPACITY.MIN_ALPHA, CONFIG.OPACITY.DYNAMIC_ALPHA, CONFIG.OPACITY.MIN_ALPHA),
    static_opacity_scale = self.image_settings:Slider("Opacity Scale", CONFIG.OPACITY.MIN_ALPHA, CONFIG.OPACITY.MAX_ALPHA, CONFIG.OPACITY.MAX_ALPHA),
    warning_opacity_scale = self.image_settings:Slider("Warning Opacity Scale", CONFIG.OPACITY.MIN_ALPHA, CONFIG.OPACITY.MAX_ALPHA, CONFIG.OPACITY.MAX_ALPHA),
    --#endregion Opacity

    --Settings
    border_switch = self.border_settings:Switch("Enable Border", false), 
    border_thickness = self.border_settings:Slider("Border Scale", CONFIG.BORDER.MIN, CONFIG.BORDER.MAX, CONFIG.BORDER.MIN),
    border_color = self.border_settings:ColorPicker("Border Color", CONFIG.BORDER.DEFAULT_COLOR), 
  } --ui

  local script_ref = self
  self.add_item = self.list_settings:Button("Add link to List Images", function ()
    script_ref:AddItem()
  end)

  self.remove_item = self.list_settings:Button("Remove link to List Images", function ()
    script_ref:RemoveItem()
  end)

  self.default_item = self.list_settings:Button("Default List Images", function ()
    script_ref:DefaultItem()
  end)

  self:DecorationUI(self.ui, self.header)
end --CreateUI

-- Косметические улучшения UI
function script:DecorationUI(ui, header)
  --Icons -- Возможно заменить на более подходящие и упростить код
  header:Icon("🖌")
  ui.global_switch:Icon("\u{f00c}")
  ui.preset_selector:Icon("📋", Vec2(0, -4))
  ui.alpha_selector:Icon("📋", Vec2(0, -4))
  ui.custom_name:Icon("𝐓", Vec2(0, -5))
  ui.custom_link:Icon("🔗", Vec2(0, -5))
  ui.custom_scale:Icon("\u{f1ce}")
  ui.custom_rounding:Icon("\u{f1ce}")
  ui.border_switch:Icon("\u{f00c}")
  ui.border_thickness:Icon("\u{f1ce}")
  ui.border_color:Icon("\u{f53f}")
  ui.dynamic_opacity_scale:Icon("💧", Vec2(0, -4))
  ui.static_opacity_scale:Icon("💧", Vec2(0, -4))
  ui.warning_opacity_scale:Icon("💧", Vec2(0, -4))

  --ToolTips -- Переписать, уже неверные
  ui.global_switch:ToolTip("❤❤❤")
  self.add_item:ToolTip("Enter the name and link to the image, then click the button to add it")
  self.remove_item:ToolTip("Select the desired image from the list, then click the button to delete it")
  self.default_item:ToolTip("Restores default settings")
  ui.dynamic_opacity_scale:ToolTip("Maximum transparency in the image area")
  ui.warning_opacity_scale:ToolTip("Maximum transparency in the area in front of the image")
end --DecorationUI

function script:CallbacksUI()
  -- Switch callbacks
  script.ui.global_switch:SetCallback(function ()
    UI.SetControlsState(script, script.ui.global_switch:Get())
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
  UI.SetControlsState(script, script.ui.global_switch:Get())
  UI.SetBorderState(script.ui, script.ui.border_switch:Get() and script.ui.global_switch:Get())
  UI.SetOpacityState(script.ui, script.ui.alpha_selector:List()[script.ui.alpha_selector:Get() + 1])
  UI.UpdateOpacityLimits(script.ui)
end --CallbacksUI

-- Инициализация скрипта
function script:Initialize()
  -- Data
  self.data = Data:Load()

  local keys = Data.GetKeys(self.data)
  Log.Write(" [DEBUG] Loaded keys: " .. table.concat(keys, ", "))

  -- UI
  self:CreateUI(keys)
  self:CallbacksUI()

  -- Game objects
  self.hero = Heroes.GetLocal()
  self.screen_size = Render.ScreenSize()

  Log.Write(" [DEBUG] Script initialization completed")
end --Initialize

function script:AddItem()
  local new_link = self.ui.custom_link:Get()
  local new_name = self.ui.custom_name:Get()

  if IsLink(new_link) and IsNotEmpty(new_name) then
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

    Log.Write(" [+] [Images Overlay]\tИзображение " .. new_name .. " по ссылке " .. new_link .. " добавлено!")
  end --if

  self.ui.custom_name:Set("")
  self.ui.custom_link:Set("")
  self.ui.border_switch:Set(true)
end --AddItem

function script:RemoveItem()
  local index = self.ui.preset_selector:Get() + 1
  local keys = Data:RemoveItem(self.data, index)

  if #keys == 1 and keys[1] == CONFIG.NONE then
    self.ui.border_switch:Set(false)
  end --if
    
  self.ui.preset_selector:Set(0)
  self.ui.preset_selector:Update(keys)
  --self.ui.preset_selector:Disabled(#keys == 1 and keys[1] == CONFIG.NONE) -- Временно отключено

  --self.ui.border_switch:Disabled(#keys == 1 and keys[1] == CONFIG.NONE) -- Временно отключено

  Log.Write(" [+] [Images Overlay]\tИзображение удалено!")
end --RemoveItem

function script:DefaultItem()
  local keys = Data:Default(self.data)
  Log.Write("Default keys: " .. table.concat(keys, ", "))
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

  Log.Write(" [+] [Images Overlay]\tНастройки по умолчанию установлены!")
end --DefaultItem

function script:OnDraw()
  if not script.hero or not Entity.IsAlive(script.hero) or not script.ui.global_switch:Get() then
    return script
  end --if

  -- Загружаем картинку
  local key = script.ui.preset_selector:List()[script.ui.preset_selector:Get() + 1]
  local image = Render.LoadImage(script.data[key])

  local size = Vec2(script.screen_size.y * CONFIG.UI.BASE_SIZE, script.screen_size.y * CONFIG.UI.BASE_SIZE)
  local offset = Utils.Calculate.Offset(script.screen_size, size, script.ui.border_thickness:Get())
  local pos = Render.WorldToScreen(Entity.GetAbsOrigin(script.hero) + Vector(0, 0, NPC.GetHealthBarOffset(script.hero))) - offset

  local scale_value = script.ui.custom_scale:Get()
  local scaled_size = size + Vec2(scale_value, scale_value)
  local scaled_pos = pos - Vec2(scale_value, scale_value)

  local mouse_x, mouse_y = Input.GetCursorPos()
  local mouse_pos = Vec2(mouse_x, mouse_y)

  -- Рассчитываем расстояние от мыши до центра картинки
  local image_center = scaled_pos + scaled_size / 2
  local distance = (mouse_pos - image_center):Length()

  local alpha
  if script.ui.alpha_selector:List()[script.ui.alpha_selector:Get() + 1] == "Static" then
    alpha = script.ui.static_opacity_scale:Get()
  else
    alpha = Utils.Calculate.Opacity(distance, script.ui.dynamic_opacity_scale:Get(), script.ui.warning_opacity_scale:Get())
  end --if

  Render.Image(
      image,
      scaled_pos - script.ui.border_thickness:Get(),
      scaled_size + script.ui.border_thickness:Get(),
      Color(255, 255, 255, alpha),
      script.ui.custom_rounding:Get()
    ) --Image

    if script.ui.border_switch:Get() then
      -- Альфа для бордера
      local border_color = script.ui.border_color:Get()
      local transparent_border = Color(border_color.r, border_color.g, border_color.b, alpha)
      Render.Rect(
          scaled_pos - script.ui.border_thickness:Get(),
          scaled_pos + scaled_size,
          transparent_border,
          script.ui.custom_rounding:Get(),
          Enum.DrawFlags.None,
          script.ui.border_thickness:Get()
        ) --Rect
    end --if
end --OnDraw

script:Initialize()
return script