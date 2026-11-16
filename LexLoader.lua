-- Lex Hub / single-file loader.
local LexMakeBrand=(function()
return function(config)
 local cfg=config or {}
 cfg.Title=cfg.Title or "Lex Hub - Blox Fruit"
 cfg.Caption=cfg.Caption or "Lex Hub nơi chấp cánh ước mơ :)"
 cfg.Logo=cfg.Logo or "rbxassetid://92599590358566"
 cfg.Portrait=cfg.Portrait or cfg.Logo
 cfg.LibraryURL=cfg.LibraryURL or "https://raw.githubusercontent.com/obiiyeuem/vthangsitink/046c2b7b51819a2d30439d575c77af2f2ba7d69c/zzzz.lua"

 local Players=game:GetService("Players")
 local Input=game:GetService("UserInputService")
 local player=Players.LocalPlayer
 local self={
  State={owned={},candidates={},windows={}},
  Alive=true,Config=cfg,
 }
 local state=self.State
 local connections,watched={},{}
 local parents={}
 local busy={}

 local function on(signal,fn)
  local c=signal:Connect(fn)
  connections[#connections+1]=c
  return c
 end

 local function make(class,props,parent)
  local o=Instance.new(class)
  for k,v in pairs(props) do o[k]=v end
  o.Parent=parent
  return o
 end

 local function addParent(p)
  if not p then return end
  for _,v in ipairs(parents) do
   if p==v then return end
  end
  parents[#parents+1]=p
 end

 addParent(player:WaitForChild("PlayerGui"))
 pcall(function() addParent(game:GetService("CoreGui")) end)

 if type(gethui)=="function" then
  pcall(function()
   local p=gethui()
   if typeof(p)=="Instance" then addParent(p) end
  end)
 end

 local function compact(text)
  return tostring(text):lower():gsub("[%s%p]","")
 end

 local function known(root)
  local n=compact(root.Name)
  return n:find("nousigi",1,true)
   or n:find("banana",1,true)
   or n:find("3nana",1,true)
 end

 local function screen(o)
  while o do
   if o:IsA("ScreenGui") then return o end
   o=o.Parent
  end
 end

 local function textObject(o)
  return o:IsA("TextLabel")
   or o:IsA("TextButton")
   or o:IsA("TextBox")
 end

 local function tint(c,white)
  local h,s,v=c:ToHSV()
  if h>=.075 and h<=.205 and s>.28 and v>.12 then
   if white then return Color3.fromRGB(247,240,255) end
   return Color3.fromHSV(
    .755,math.clamp(s,.32,.72),math.max(v,.22)
   )
  end
  return c
 end

 local function ancestor(o,a)
  while o do
   if o==a then return true end
   o=o.Parent
  end
  return false
 end

 local function dimensions(o)
  local a=o.AbsoluteSize
  return a.X>0 and a.X or o.Size.X.Offset,
   a.Y>0 and a.Y or o.Size.Y.Offset
 end

 function self:FindWindow(title,root)
  local p=title.Parent
  while p and p~=root do
   if p:IsA("Frame")
    or p:IsA("ImageLabel")
    or p:IsA("CanvasGroup") then
    local w,h=dimensions(p)
    if w>=220 and h>=130 then
     state.windows[root]=p
     return p
    end
   end
   p=p.Parent
  end
 end

 function self:Header(o,root)
  if not textObject(o) or o:IsA("TextBox") then return end
  if not tostring(o.Text):find(cfg.Title,1,true) then return end
  if o.Text~=cfg.Title then o.Text=cfg.Title end

  state.header=o
  self:FindWindow(o,root)

  if o:GetAttribute("LexHeader") then return end
  o:SetAttribute("LexHeader",true)

  local parent=o.Parent
  if not parent then return end

  local oldPosition,oldSize=o.Position,o.Size
  local managed=parent:FindFirstChildOfClass("UIListLayout")
   or parent:FindFirstChildOfClass("UIGridLayout")

  local image=make("ImageLabel",{
   Name="LexFrieren",
   BackgroundTransparency=1,
   Size=UDim2.fromOffset(32,32),
   Image=cfg.Portrait,
   ScaleType=Enum.ScaleType.Crop,
   ZIndex=o.ZIndex,
   LayoutOrder=o.LayoutOrder-1,
  },parent)

  make("UICorner",{
   CornerRadius=UDim.new(0,8),
  },image)

  if not managed then
   image.AnchorPoint=Vector2.new(0,.5)
   image.Position=UDim2.new(
    oldPosition.X.Scale,oldPosition.X.Offset,
    oldPosition.Y.Scale,
    oldPosition.Y.Offset+oldSize.Y.Offset/2
   )

   o.Position=UDim2.new(
    oldPosition.X.Scale,oldPosition.X.Offset+40,
    oldPosition.Y.Scale,oldPosition.Y.Offset
   )

   local width=oldSize.X.Offset-40
   if oldSize.X.Scale==0 then width=math.max(40,width) end

   o.Size=UDim2.new(
    oldSize.X.Scale,width,
    oldSize.Y.Scale,oldSize.Y.Offset
   )
  end

  o.TextColor3=Color3.fromRGB(247,240,255)
  o.TextScaled=true

  if not o:FindFirstChildOfClass("UITextSizeConstraint") then
   make("UITextSizeConstraint",{
    MinTextSize=10,
    MaxTextSize=22,
   },o)
  end
 end

 function self:Startup(title)
  self.StartupSeen=true
  state.startupTitle=title

  local p=title.Parent
  local depth=0

  while p and not p:IsA("ScreenGui") and depth<3 do
   depth=depth+1
   local labels={}

   for _,o in ipairs(p:GetDescendants()) do
    if o~=title and o:IsA("TextLabel") and #o.Text>3 then
     labels[#labels+1]=o
    end
   end

   local w,h=0,0
   if p:IsA("GuiObject") then w,h=dimensions(p) end

   if #labels>0 and #labels<=5 and w<=600 and h<=240 then
    local desc=labels[1]
    for _,o in ipairs(labels) do
     if o.TextSize<desc.TextSize then desc=o end
    end
    state.startupDesc=desc
    desc.Text=cfg.Caption
    desc.TextWrapped=true
    return
   end

   p=p.Parent
  end
 end

 local bind

 function self:Paint(o,root)
  if not self.Alive or busy[o] then return end
  busy[o]=true

  pcall(function()
   if textObject(o) then
    local n=compact(o.Text)

    if state.startupTitle==o then
     o.Text="Lex Hub Gui"
    elseif state.startupDesc==o then
     o.Text=cfg.Caption
    elseif n:find("3nanauilibrary",1,true)
     or n:find("bananauilibrary",1,true) then
     o.Text="Lex Hub Gui"
     self:Startup(o)
    elseif n=="bananacathub"
     or n=="bananahub" or n=="3nana" then
     o.Text="Lex Hub"
    end

    self:Header(o,root)

    local pending=state.startupTitle
    if pending and pending.Parent
     and not state.startupDesc and o~=pending
     and screen(o)==screen(pending) then
     self:Startup(pending)
    end
   end

   local properties={}

   if o:IsA("GuiObject") then
    properties={"BackgroundColor3","BorderColor3"}

    if textObject(o) then
     properties[#properties+1]="TextColor3"
    end

    if o:IsA("ImageLabel") or o:IsA("ImageButton") then
     properties[#properties+1]="ImageColor3"
    end

    if o:IsA("ScrollingFrame") then
     properties[#properties+1]="ScrollBarImageColor3"
    end
   elseif o:IsA("UIStroke") then
    properties={"Color"}
   end

   for _,property in ipairs(properties) do
    local old=o[property]
    local color=tint(old,property=="TextColor3")
    if old~=color then o[property]=color end
   end

   if o:IsA("UIGradient") then
    local keys,changed={},false

    for _,k in ipairs(o.Color.Keypoints) do
     local c=tint(k.Value,false)
     changed=changed or c~=k.Value
     keys[#keys+1]=ColorSequenceKeypoint.new(k.Time,c)
    end

    if changed then o.Color=ColorSequence.new(keys) end
   end
  end)

  busy[o]=nil
 end

 bind=function(o,root)
  if watched[o] then
   self:Paint(o,root)
   return
  end

  watched[o]=true
  self:Paint(o,root)
  local props={}

  if textObject(o) then
   props[#props+1]="Text"
   props[#props+1]="TextColor3"
  end

  if o:IsA("GuiObject") then
   props[#props+1]="BackgroundColor3"
   props[#props+1]="BorderColor3"

   if o:IsA("ImageLabel") or o:IsA("ImageButton") then
    props[#props+1]="ImageColor3"
   end

   if o:IsA("ScrollingFrame") then
    props[#props+1]="ScrollBarImageColor3"
   end
  elseif o:IsA("UIStroke") or o:IsA("UIGradient") then
   props[#props+1]="Color"
  end

  for _,prop in ipairs(props) do
   on(o:GetPropertyChangedSignal(prop),function()
    self:Paint(o,root)
   end)
  end
 end

 function self:Claim(root)
  if state.owned[root] or root.Name=="LexBrandDock" then return end
  state.owned[root]=true

  for _,o in ipairs(root:GetDescendants()) do bind(o,root) end

  on(root.DescendantAdded,function(o)
   task.defer(function()
    if o.Parent then bind(o,root) end
   end)
  end)
 end

 function self:Watch(root)
  if not root or root.Name=="LexBrandDock" then return end

  if known(root) then
   self:Claim(root)
   return
  end

  if state.candidates[root] then return end
  state.candidates[root]=true

  local function inspect(o)
   if not textObject(o) then return end

   local function check()
    if not self.Alive then return end
    local n=compact(o.Text)

    if tostring(o.Text):find(cfg.Title,1,true)
     or n:find("3nana",1,true)
     or n:find("bananacathub",1,true) then
     self:Claim(root)
    end
   end

   check()
   on(o:GetPropertyChangedSignal("Text"),check)
  end

  for _,o in ipairs(root:GetDescendants()) do inspect(o) end
  on(root.DescendantAdded,inspect)
 end

 function self:Discover()
  for _,parent in ipairs(parents) do
   for _,o in ipairs(parent:GetDescendants()) do
    if o:IsA("ScreenGui") and (
     known(o) or state.candidates[o] or self.Collecting
    ) then
     self:Watch(o)
    end
   end
  end

  for root in pairs(state.owned) do
   if root.Parent then
    for _,o in ipairs(root:GetDescendants()) do
     if textObject(o) then self:Header(o,root) end
    end

    local window=state.windows[root]

    for _,o in ipairs(root:GetDescendants()) do
     if o:IsA("ImageButton") then
      local w,h=dimensions(o)
      local n=compact(o.Name)
      local depth,p=0,o.Parent

      while p and p~=root do
       depth=depth+1
       p=p.Parent
      end

      local outside=window
       and not ancestor(o,window) and depth<=3

      if w>=24 and h>=24 and w<=96 and h<=96
       and (
        outside
        or n:find("toggle",1,true)
        or n:find("open",1,true)
        or n:find("logo",1,true)
       ) then
       o.Visible=false
       o:SetAttribute("LexOldLauncher",true)
      end
     end
    end
   end
  end

  if state.startupTitle and state.startupTitle.Parent
   and not state.startupDesc then
   self:Startup(state.startupTitle)
  end
 end

 for _,parent in ipairs(parents) do
  on(parent.DescendantAdded,function(o)
   local root=screen(o)
   if root and (
    self.Collecting or known(root) or state.candidates[root]
   ) then
    self:Watch(root)
   end
  end)
 end

 local dockGui,dock

 local function viewport()
  local c=workspace.CurrentCamera
  return c and c.ViewportSize or Vector2.new(1280,720)
 end

 local function clampDock(x,y)
  if not dock then return end
  local v=viewport()
  local w,h=dimensions(dock)

  dock.Position=UDim2.fromOffset(
   math.clamp(x,4,math.max(4,v.X-w-4)),
   math.clamp(y,4,math.max(4,v.Y-h-4))
  )
 end

 function self:Toggle()
  self:Discover()
  local targets={}

  for root in pairs(state.owned) do
   if root.Parent then
    local window=state.windows[root]

    if window then
     targets[#targets+1]=window
    elseif known(root) and #root:GetDescendants()>20 then
     targets[#targets+1]=root
    end
   end
  end

  local show=true

  for _,o in ipairs(targets) do
   local p,visible=o,true

   while p do
    if p:IsA("ScreenGui") and not p.Enabled
     or p:IsA("GuiObject") and not p.Visible then
     visible=false
     break
    end
    p=p.Parent
   end

   if visible then
    show=false
    break
   end
  end

  for _,o in ipairs(targets) do
   if o:IsA("ScreenGui") then
    o.Enabled=show
   else
    o.Visible=show

    if show then
     local p=o.Parent
     while p do
      if p:IsA("ScreenGui") then
       p.Enabled=true
       break
      end
      if p:IsA("GuiObject") then p.Visible=true end
      p=p.Parent
     end
    end
   end
  end
 end

 function self:Dock()
  if dockGui then return end

  dockGui=make("ScreenGui",{
   Name="LexBrandDock",
   ResetOnSpawn=false,
   IgnoreGuiInset=true,
   DisplayOrder=30000,
  },parents[#parents])

  dock=make("ImageButton",{
   Name="OpenLexHub",
   Size=UDim2.fromOffset(54,54),
   BackgroundColor3=Color3.fromRGB(32,20,48),
   BorderSizePixel=0,
   Image=cfg.Logo,
   ScaleType=Enum.ScaleType.Fit,
   AutoButtonColor=false,
  },dockGui)

  make("UICorner",{
   CornerRadius=UDim.new(0,14),
  },dock)

  make("UIStroke",{
   Color=Color3.fromRGB(188,137,255),
   Thickness=1.5,
  },dock)

  clampDock(16,viewport().Y*.5-27)
  state.dock=dock
  state.dockGui=dockGui

  local held,start,origin,moved

  on(dock.InputBegan,function(input)
   if input.UserInputType~=Enum.UserInputType.MouseButton1
    and input.UserInputType~=Enum.UserInputType.Touch then
    return
   end

   held=input
   start=input.Position
   origin=dock.Position
   moved=false
  end)

  on(Input.InputChanged,function(input)
   if not held then return end

   if input~=held and not(
    held.UserInputType==Enum.UserInputType.MouseButton1
    and input.UserInputType==Enum.UserInputType.MouseMovement
   ) then
    return
   end

   local delta=input.Position-start
   if delta.Magnitude>5 then moved=true end

   if moved then
    clampDock(
     origin.X.Offset+delta.X,
     origin.Y.Offset+delta.Y
    )
   end
  end)

  on(Input.InputEnded,function(input)
   if held and (
    input==held
    or held.UserInputType==Enum.UserInputType.MouseButton1
     and input.UserInputType==Enum.UserInputType.MouseButton1
   ) then
    held=nil
    if not moved then self:Toggle() end
   end
  end)

  on(Input.WindowFocusReleased,function()
   held=nil
  end)

  local cameraConnection

  local function watchCamera()
   if cameraConnection then cameraConnection:Disconnect() end
   local camera=workspace.CurrentCamera

   if camera then
    cameraConnection=on(
     camera:GetPropertyChangedSignal("ViewportSize"),
     function()
      clampDock(dock.Position.X.Offset,dock.Position.Y.Offset)
     end
    )
   end

   clampDock(dock.Position.X.Offset,dock.Position.Y.Offset)
  end

  on(workspace:GetPropertyChangedSignal("CurrentCamera"),watchCamera)
  watchCamera()

  on(dockGui.Destroying,function()
   self:Destroy()
  end)
 end

 function self:WrapLibrary(lib)
  assert(
   type(lib)=="table" and type(lib.CreateMain)=="function",
   "GUI library API changed"
  )

  local proxy={}
  setmetatable(proxy,{__index=lib})

  proxy.CreateMain=function(options,...)
   local opts={}
   for k,v in pairs(options or {}) do opts[k]=v end
   opts.Title=cfg.Title
   opts.Desc=""

   self.Collecting=true
   local result=table.pack(lib.CreateMain(opts,...))

   self:Discover()
   self:Dock()
   self.Collecting=false

   if type(lib.CreateNoti)=="function"
    and not self.StartupSeen then
    lib.CreateNoti({
     Title="Lex Hub Gui",
     Desc=cfg.Caption,
     ShowTime=5,
    })
   end

   task.delay(.5,function()
    if self.Alive then self:Discover() end
   end)

   return table.unpack(result,1,result.n)
  end

  if type(lib.CreateNoti)=="function" then
   proxy.CreateNoti=function(options,...)
    local opts={}
    for k,v in pairs(options or {}) do opts[k]=v end
    opts.Title="Lex Hub Gui"
    return lib.CreateNoti(opts,...)
   end
  end

  self.Library=proxy
  return proxy
 end

 function self.LoadLibrary()
  local code=game:HttpGet(cfg.LibraryURL)
  local run,err=loadstring(code,"@LexHub/original-library")
  assert(run,err)

  self.Collecting=true
  local ok,lib=pcall(run)
  self:Discover()
  self.Collecting=false

  assert(ok,lib)
  return self:WrapLibrary(lib)
 end

 function self:Destroy()
  if not self.Alive then return end
  self.Alive=false

  for _,c in ipairs(connections) do c:Disconnect() end
  connections={}

  if dockGui and dockGui.Parent then dockGui:Destroy() end
 end

 self:Discover()
 return self
end
end)()

repeat task.wait() until game:IsLoaded()

local ROOT="https://raw.githubusercontent.com/anyeuemnhat/GUI/"
local SOURCE=ROOT.."accfb39c3cb654dec6fc5881e7b616359d69da7f/message%20%281%29.txt"
local LOADER=ROOT.."refs/heads/main/LexLoader.lua"
local env=getgenv()

local ok,err=pcall(function()
 if env.LoadScript then
  local prior=env.__LexHubBrand

  assert(
   prior and prior.Alive and prior.State.header,
   "Banana đã chạy trong server này. Vào server mới rồi chạy LexLoader."
  )

  prior:Discover()
  prior:Dock()
  return
 end

 local makeBrand=LexMakeBrand

 if env.__LexHubBrand and env.__LexHubBrand.Alive then
  env.__LexHubBrand:Destroy()
 end

 local brand=makeBrand({
  Title="Lex Hub - Blox Fruit",
  Caption="Lex Hub nơi chấp cánh ước mơ :)",
  Logo="rbxassetid://92599590358566",
  Portrait="rbxassetid://92599590358566",
 })

 env.__LexHubBrand=brand

 local parents={
  game:GetService("Players").LocalPlayer:WaitForChild("PlayerGui")
 }

 pcall(function()
  parents[#parents+1]=game:GetService("CoreGui")
 end)

 if type(gethui)=="function" then
  pcall(function() parents[#parents+1]=gethui() end)
 end

 for _,parent in ipairs(parents) do
  local old=parent:FindFirstChild("LexHubUI")
  if old then old:Destroy() end
 end

 local source=game:HttpGet(SOURCE)

 local anchor='local lib = loadstring(game:HttpGet("https://raw.githubusercontent.com/obiiyeuem/vthangsitink/refs/heads/main/zzzz.lua"))()'

 local a,b=source:find(anchor,1,true)
 assert(a,"Không tìm thấy dòng nạp GUI trong bản nguồn này")

 source=source:sub(1,a-1)
  .."local lib = getgenv().__LexHubBrand.LoadLibrary()"
  ..source:sub(b+1)

 local oldURL="https://raw.githubusercontent.com/obiiyeuem/vthangsitink/main/BananaHub.lua"
 local from,to=source:find(oldURL,1,true)
 assert(from,"Không tìm thấy dòng tự tải sau teleport")

 source=source:sub(1,from-1)..LOADER..source:sub(to+1)

 local run,why=loadstring(source,"@LexHub/supplied-source")
 assert(run,why)
 run()
end)

if not ok then
 warn("[Lex Hub] "..tostring(err))

 pcall(function()
  game:GetService("StarterGui"):SetCore("SendNotification",{
   Title="Lex Hub",
   Text=tostring(err):sub(1,180),
   Duration=12,
  })
 end)
end
task.defer(function()
    loadstring(game:HttpGet(
        "https://raw.githubusercontent.com/anyeuemnhat/GUI/refs/heads/main/LexBrandFix.lua"
    ))()
end)