--#region File
---@param path string --Путь к файлу
---@return nil
function CreateDeafaultFile(path)
  local file = io.open(path, "w")

  if file then
    file:write("https://i.imgur.com/JPO2QEO.gif\n")
    io.close(file)
  end
end

---@param path string --Путь к файлу
---@return nil
function CreateFile(path)
  local file = io.open(path, "w")

  if file then
    io.close(file)
  end
end

---@param path string --Путь к файлу
---@param link string --Ссылка на картинку или Gif
---@return nil
function AddLinkToFile(path, link)
  local file = io.open(path, "a")

  if file then
    file:write(link .. "\n")
    io.close(file)
  end
end

---@param path string --Путь к файлу
---@param link_arr table<string> --Массив ссылок на изображения
---@return nil
function UpdateFile(path, link_arr)
  local file = io.open(path, "w")

  if file then
    for i, link in ipairs(link_arr) do
      file:write(link .. "\n")
    end
    io.close(file)
  end
end

---@param path string --Путь к файлу
---@return boolean --Вернет true, если файл не пустой и существует
function FileExists(path)
  local file = io.open(path, "r")

  if file then
    local str = file:read("*a")
    io.close(file)

    if str and string.match(str, "%S") then
      return true
    end
  end
  return false
end

---@param path string --Путь к файлу
---@return nil
function CheckEmptyFile(path)
  local file = io.open(path, "r")
  if file then
    local first_str = file:read("*1")
    if first_str ~= "Empty list" then
      return false
    end
    io.close(file)
  end
  return true
end

---@param path string --Путь к файлу
---@return table
function ReadFile(path)
  local arr = {}
  local file = io.open(path, "r")

  if file then
    for line in file:lines() do
      line = string.gsub(line, "^%s*(.-)%s*$", "%1")

      if line ~= "" then
        table.insert(arr, line)
      end
    end
    io.close(file)
  end
  return arr
end
--#endregion File

--#region Validation
---@param link string --Ссылка для проверки
---@return boolean --Вернет true, если ссылка валидна
function CheckLink(link)
  return string.match(link, "https?://.+") ~= nil
end

---@param arr table<string> --Массив ссылок на изображения
---@param new_link string --Ссылка для проверки
---@return boolean --Вернет true, если ссылка не уникальна
function CheckUniqueLink(arr ,new_link)
  for i, link in ipairs(arr) do
    if link == new_link then
      return false
    end
  end

  return true
end
--#endregion Validation

---@param ui table 
---@param path string 
---@return nil 
function DefaultSettings(ui, path)
  CreateDeafaultFile(path)
  ui.preset_selector:Update(ReadFile(path))

  ui.custom_scale:Set(20)
  ui.border_switch:Set(true)
  ui.border_thickness:Set(2)
  ui.border_color:Set(Color(255, 0, 0, 255))
  ui.border_switch:Disabled(false)
end

---@param arr table<string> 
---@param index integer 
---@return table<string> 
function RemoveLink(arr, index)
  if #arr == 0 then return {} end

  local new_items = {}
   for i = 1, #arr do
    if i ~= index then
      new_items[#new_items + 1] = arr[i]
    end
   end
   return new_items
end

---@param screen_size Vec2
---@param size Vec2
---@param thickness integer
---@return Vec2 
function CalculateOffset(screen_size, size, thickness)
  local step = 0.0005
  local base_offset = 0.053 + math.floor((thickness - 1) / 2) * step

  return Vec2(screen_size.y * base_offset, screen_size.y * 0.045) + Vec2(size.x, 0)
end

local script = {}

function script:Init()
  --#region HeaderPanel
  self.header = Menu.Create("Changer", "Main", "Images Overlay")
  self.header:Icon("🖼")

  self.main = self.header:Create("Main"):Create("Images")
  self.settings = self.header:Create("Main"):Create("Image Settings")
  --#endregion HeaderPanel

   self.path = Engine.GetCheatDirectory() .. "Images.txt"
   if not FileExists(self.path) then
    CreateDeafaultFile(self.path)
  end

  --#region UIPanel
   self.ui = {
    --#region Main
    global_switch = self.main:Switch("Enable", false, "\u{f00c}"),
    preset_selector = self.main:Combo("List Images", ReadFile(self.path)),
    custom_link = self.main:Input("Custom link", ""),

    add_item = self.main:Button("Add link to List Images", function ()
      local new_link = self.ui.custom_link:Get()

      if CheckLink(new_link) and CheckUniqueLink(self.ui.preset_selector:List(), new_link) then
        AddLinkToFile(self.path, new_link)
        self.ui.preset_selector:Update(ReadFile(self.path))

        self.ui.border_switch:Set(true)
        self.ui.border_switch:Disabled(false)
      end
        self.ui.custom_link:Set("")
    end),

    remove_item = self.main:Button("Remove link to List Images", function () 
      local new_arr_links = RemoveLink(self.ui.preset_selector:List(), self.ui.preset_selector:Get() + 1)

      if #new_arr_links == 0 then
        UpdateFile(self.path, {"Empty list"})
        self.ui.preset_selector:Update({"Empty list"})

        self.ui.border_switch:Set(false)
      else
        UpdateFile(self.path, new_arr_links)
        self.ui.preset_selector:Update(new_arr_links)
      end
    end),

    default_item = self.main:Button("Default List Images", function () DefaultSettings(self.ui, self.path) end),
    --#endregion Main

    --#region Settings
    custom_scale = self.settings:Slider("Scale Image", 0, 45, 20),
    border_switch = self.settings:Switch("Enable Border", false, "\u{f00c}"),
    border_thickness = self.settings:Slider("Scale Border", 0, 10, 2),
    border_color = self.settings:ColorPicker("Border Color", Color(255, 0, 0, 255), "\u{f53f}"),
    --#endregion Settings
  } --ui

  self.ui.preset_selector:Icon("📋", Vec2(0, -4))
  self.ui.custom_link:Icon("🔗", Vec2(0, -4))
  self.ui.custom_scale:Icon("\u{f1ce}")
  self.ui.border_thickness:Icon("\u{f1ce}")

  self.ui.global_switch:ToolTip("Created by Juimun with love ❤❤❤")
  self.ui.add_item:ToolTip("Enter a link to any image or gif and click the button to save it in the list")
  self.ui.remove_item:ToolTip("Select a link from the list and then click the button to delete")
  self.ui.default_item:ToolTip("Click to remove all non-default GIFs")
  --#endregion UIPanel
end --Init

function script:OnUpdate()
  --#region Switch callbacks
  script.ui.global_switch:SetCallback(function ()
    script.ui.preset_selector:Disabled(not script.ui.global_switch:Get())
    script.ui.custom_link:Disabled(not script.ui.global_switch:Get())
    script.ui.add_item:Disabled(not script.ui.global_switch:Get())
    script.ui.remove_item:Disabled(not script.ui.global_switch:Get())
    script.ui.default_item:Disabled(not script.ui.global_switch:Get())
    script.ui.custom_scale:Disabled(not script.ui.global_switch:Get())
    script.ui.border_switch:Disabled(not script.ui.global_switch:Get())
  end, true)

  script.ui.border_switch:SetCallback(function ()
    script.ui.border_thickness:Disabled(not script.ui.border_switch:Get() or not script.ui.global_switch:Get())
    script.ui.border_color:Disabled(not script.ui.border_switch:Get() or not script.ui.global_switch:Get())
  end, true)
--#endregion Switch callbacks
end

function script:OnDraw()
  local hero = Heroes.GetLocal()
  if not hero then return script end

  local screen_size = Render.ScreenSize()
 
  if not hero or not Entity.IsAlive(hero) or not script.ui.global_switch:Get() then return script end

  local image = Render.LoadImage(script.ui.preset_selector:List()[script.ui.preset_selector:Get() + 1])

  -- Смещения
  local size = Vec2(screen_size.y * 0.033, screen_size.y * 0.033)
  local offset = CalculateOffset(screen_size, size, script.ui.border_thickness:Get())

  local pos = Render.WorldToScreen(Entity.GetAbsOrigin(hero) + Vector(0, 0, NPC.GetHealthBarOffset(hero))) - offset
  local scale_value = script.ui.custom_scale:Get()
  local scaled_size = size + Vec2(scale_value, scale_value)
  local scaled_pos = pos - Vec2(scale_value, scale_value)

  Render.Image(
      image,
      scaled_pos - script.ui.border_thickness:Get(),
      scaled_size + script.ui.border_thickness:Get(),
      Color(255, 255, 255, 255),
      5
  )

    if script.ui.border_switch:Get() then
      Render.Rect(
          scaled_pos - script.ui.border_thickness:Get(),
          scaled_pos + scaled_size,
          script.ui.border_color:Get(),
          5,
          Enum.DrawFlags.None,
          script.ui.border_thickness:Get()
      )
    end
end

script:Init()
return script