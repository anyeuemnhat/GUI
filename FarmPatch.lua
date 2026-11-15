-- Lex Farm patch 2
return function(M)
local P=game:GetService("Players").LocalPlayer
local RS=game:GetService("ReplicatedStorage")

local function norm(s)
 return tostring(s):gsub("%b[]",""):lower():gsub("[^%a]","")
end

local aliases={
 Bandit="Băng Cướp",
 Trainee="Nhân Viên Tập Sự",
}

local function alive()
 local c=P.Character
 local h=c and c:FindFirstChildOfClass("Humanoid")
 local r=c and c:FindFirstChild("HumanoidRootPart")
 if h and h.Health>0 and r then return c,h,r end
end

local function shown(o)
 while o and o~=P do
  if o.Name=="LexHubUI"
   or o:IsA("GuiObject") and not o.Visible
   or o:IsA("ScreenGui") and not o.Enabled then
   return false
  end
  o=o.Parent
 end
 return true
end

local create=M.Create

function M.Create(config,report)
 local s=create(config,report)
 local cfg=s.Config

 for k,v in pairs({
  Fast=true,Delay=.14,
  Hover=true,Height=3,
  Backend="Auto",
 }) do
  if cfg[k]==nil then cfg[k]=v end
 end

 local say,stop=s.Say,s.Stop

 function s:Say(text)
  self.Diagnostic=tostring(text)
   .."\nInput="..tostring(self.InputChoice or cfg.Backend)
   .." / Range="..cfg.Range
   .." / Height="..cfg.Height
   .."\nQuestUI="..tostring(self.QuestPath)
   .."\n"..tostring(self.QuestText)
   .."\nInputError="..tostring(self.InputError)
  say(self,text)
 end

 function s:ClearHover()
  if self.Float then
   self.Float:Destroy()
   self.Float=nil
  end
  if self.FloatHum then
   pcall(function()
    self.FloatHum.AutoRotate=self.OldRotate
   end)
  end
  self.FloatRoot=nil
  self.FloatHum=nil
 end

 function s:Hold(root,h)
  if self.FloatRoot==root
   and self.Float and self.Float.Parent then return end

  self:ClearHover()
  self.OldRotate=h.AutoRotate
  self.FloatHum=h
  self.FloatRoot=root
  h.AutoRotate=false

  local b=Instance.new("BodyVelocity")
  b.Name="LexFarmHover"
  b.MaxForce=Vector3.new(0,math.huge,0)
  b.Velocity=Vector3.new(0,0,0)
  b.P=1250
  b.Parent=root
  self.Float=b
 end

 function s:ReleaseClick()
  local held=self.Held
  self.Held=nil
  if not held then return end

  pcall(function()
   if held.kind=="Mouse" then
    held.service:SendMouseButtonEvent(
     held.point.X,held.point.Y,0,false,game,0
    )
   else
    held.service:Button1Up(held.point,held.camera)
   end
  end)
 end

 function s:Stop(message)
  self:ClearHover()
  self:ReleaseClick()

  if self.RequestThread
   and self.RequestThread~=coroutine.running() then
   pcall(task.cancel,self.RequestThread)
  end

  self.RequestThread=nil
  self.Request=nil
  self.ActiveQuest=nil
  self.WasActive=false
  self.ScanAt=0
  stop(self,message)
 end

 function s:Point()
  local cam=workspace.CurrentCamera
  local v=cam and cam.ViewportSize or Vector2.new(1280,720)
  local points={{.92,.3},{.08,.3},{.92,.52},{.5,.06}}

  for _,p in ipairs(points) do
   local x,y=math.floor(v.X*p[1]),math.floor(v.Y*p[2])
   local blocked=false
   local w=self.Window

   if w and w.Visible then
    local a,b=w.AbsolutePosition,w.AbsoluteSize
    blocked=x>=a.X and x<=a.X+b.X
     and y>=a.Y and y<=a.Y+b.Y
   end

   local pg=P:FindFirstChild("PlayerGui")
   if not blocked and pg then
    local ok,list=pcall(function()
     return pg:GetGuiObjectsAtPosition(x,y)
    end)
    if ok then
     for _,o in ipairs(list) do
      if shown(o) and (
       o:IsA("TextButton")
       or o:IsA("ImageButton")
       or o.Active
      ) then
       blocked=true
       break
      end
     end
    end
   end

   if not blocked then return Vector2.new(x,y) end
  end

  return Vector2.new(
   math.floor(v.X*.92),
   math.floor(v.Y*.3)
  )
 end

 function s:Send(tool,kind,token)
  local ok,err=pcall(function()
   if kind=="Tool" then
    assert(tool.Enabled~=false,"Tool.Enabled=false")
    tool:Activate()
    return
   end

   local point=self:Point()
   local cam=workspace.CurrentCamera
   local service=game:GetService(
    kind=="Mouse" and "VirtualInputManager" or "VirtualUser"
   )
   local held={
    kind=kind,service=service,point=point,
    camera=cam and cam.CFrame or CFrame.new(),
   }

   if kind=="VirtualUser" then service:CaptureController() end
   if not self.Alive or not cfg.Enabled
    or token~=self.Token then return end

   self.Held=held

   if kind=="Mouse" then
    service:SendMouseButtonEvent(
     point.X,point.Y,0,true,game,0
    )
   else
    service:Button1Down(point,held.camera)
   end

   task.wait(.025)
   self:ReleaseClick()
  end)

  if not ok then
   self:ReleaseClick()
   self.InputError=tostring(err)
  end
  return ok
 end

 function s:Attack(c,h,root,mob,stationary)
  local target=mob:FindFirstChild("HumanoidRootPart")
  local hp=mob:FindFirstChildOfClass("Humanoid")
  if not target or not hp or hp.Health<=0 then return end

  local tool=self:Equip(c,h)
  if not tool then
   self:CancelMove()
   self:ClearHover()
   self:Say("Chưa có vũ khí "..cfg.Weapon
    ..". Thử chọn Đang cầm.")
   return
  end

  local d=(root.Position-target.Position).Magnitude

  if not stationary then
   local side=math.max(.5,math.min(2,cfg.Range*.35))
   local height=cfg.Hover and math.min(
    cfg.Height,
    math.sqrt(math.max(0,(cfg.Range-.9)^2-side^2))
   ) or 0

   local pos=target.Position+Vector3.new(side,height,0)

   if cfg.Hover and d<60 then
    self:Hold(root,h)
   else
    self:ClearHover()
   end

   if (root.Position-pos).Magnitude>1 then
    self:Move(root,CFrame.new(pos))
   else
    self:CancelMove()
   end
  else
   self:CancelMove()
   self:ClearHover()
  end

  if d>cfg.Range then
   self:Say("Đang tiếp cận "..mob.Name
    .." / "..math.floor(d).." studs")
   return
  end

  local face=Vector3.new(
   target.Position.X,root.Position.Y,target.Position.Z
  )
  if not self.Tween and (face-root.Position).Magnitude>.1 then
   root.CFrame=CFrame.lookAt(root.Position,face)
  end

  local now=os.clock()

  if self.LastTool~=tool then
   self.LastTool=tool
   self.InputChoice=nil
   self.BackendSince=now
   self.Confirmed=false
  end

  if self.Target~=mob then
   self.Target=mob
   self.Health=hp.Health
   self.DamageAt=now
   self.BackendSince=now
   self.Confirmed=false
  end

  local hit=self.Health and hp.Health<self.Health
  if hit then
   self.DamageAt=now
   self.BackendSince=now
   self.Confirmed=true
  end
  self.Health=hp.Health

  if now<self.NextAttack then return end
  self.NextAttack=now+(
   cfg.Fast and math.clamp(cfg.Delay,.08,.6) or .35
  )

  local kinds={"Mouse","VirtualUser","Tool"}
  local kind=cfg.Backend

  if kind=="Auto" then
   kind=self.InputChoice or "Mouse"
   if now-(self.BackendSince or now)>3 then
    local index=table.find(kinds,kind) or 1
    kind=kinds[index%#kinds+1]
    self.BackendSince=now
    self.Confirmed=false
   end
  end

  self.InputChoice=kind
  local token=self.Token
  local ok=self:Send(tool,kind,token)

  if not self.Alive or not cfg.Enabled
   or token~=self.Token then return end

  if not ok then
   if cfg.Backend=="Auto" then
    local index=table.find(kinds,kind) or 1
    self.InputChoice=kinds[index%#kinds+1]
    self.BackendSince=now
   end
   self:Say("Không gửi được "..kind..": "
    ..tostring(self.InputError):sub(1,100))
   return
  end

  if now-(self.DamageAt or now)>8 then
   self:Say(
    "Chưa thấy HP giảm. Giảm tầm/độ cao hoặc thử đánh tay. Input: "
     ..kind
   )
  else
   self:Say(
    (self.Confirmed and "Đã thấy HP giảm: "
     or "Đã gửi M1, chờ HP: ")
     ..mob.Name.." / "..kind.." / HP "..math.floor(hp.Health)
   )
  end
 end

 function s:QuestUI(quests)
  if self.ScanList==quests
   and os.clock()<(self.ScanAt or 0) then
   return self.QuestActive,self.QuestMatch
  end

  local pg=P:FindFirstChild("PlayerGui")
  if not pg then return false end
  local groups={}

  for _,o in ipairs(pg:GetDescendants()) do
   if (o:IsA("TextLabel") or o:IsA("TextButton"))
    and shown(o) then
    local a,group=o,nil

    while a and a~=pg do
     if a.Name:lower():find("quest",1,true) then
      group=a
     end
     a=a.Parent
    end

    if group then
     local g=groups[group] or {text="",node=group}
     groups[group]=g
     g.text=g.text.." "..o.Text
      .." "..tostring(o.ContentText or "")
    end
   end
  end

  local active,matched=false,nil
  local selected

  for _,g in pairs(groups) do
   if g.text:match("%d+%s*/%s*%d+") then
    active=true
    selected=selected or g
    local text=norm(g.text)

    for _,q in ipairs(quests) do
     if text:find(norm(q.mob),1,true)
      or quests[1].required<=10
       and aliases[q.mob]
       and text:find(norm(aliases[q.mob]),1,true) then
      matched=q
      selected=g
      break
     end
    end

    if matched then break end
   end
  end

  self.QuestPath=selected and selected.node:GetFullName()
   or "Không thấy quest có tiến độ"
  self.QuestText=selected and selected.text:sub(1,350) or ""
  self.ScanList=quests
  self.ScanAt=os.clock()+.15
  self.QuestActive=active
  self.QuestMatch=matched
  return active,matched
 end

 local step=s.Step

 function s:Step(token)
  if not self.Alive or not cfg.Enabled
   or token~=self.Token then return end

  local c,h,root=alive()
  if not c or not P.Team then
   self:ClearHover()
   return step(self,token)
  end

  if cfg.Mode~="Level" then
   local radius=cfg.Mode=="Aura" and cfg.Range or cfg.Radius
   local mob=self:Nearest(root,nil,radius)

   if mob then
    self:Attack(c,h,root,mob,cfg.Mode=="Aura")
   else
    self:CancelMove()
    self:ClearHover()
    self:Say("Không có quái trong "..radius.." studs.")
   end
   return
  end

  local quests,err=self:Quests()
  if not self.Alive or not cfg.Enabled
   or token~=self.Token then return end

  if not quests then
   self:CancelMove()
   self:ClearHover()
   self:Say(err)
   return
  end

  local active,q=self:QuestUI(quests)

  if not active and self.WasActive then
   self.ActiveQuest=nil
   self.Request=nil
   self.NextQuest=0
  end
  self.WasActive=active

  if active then
   q=q or self.ActiveQuest or self.Request and self.Request.quest
   if not q then
    self:CancelMove()
    self:ClearHover()
    self:Say(
     "Quest đã hiện nhưng chưa xác định được tên. "
      .."Dùng nút Ghép quest ở Farm Settings."
    )
    return
   end

   self.ActiveQuest=q
   local mob=self:Nearest(root,q.mob,math.huge)

   if mob then
    self:Attack(c,h,root,mob,false)
    return
   end

   self:ClearHover()
   local nearest,d=nil,math.huge
   for _,cf in ipairs(self:Spawns(q.mob)) do
    local n=(cf.Position-root.Position).Magnitude
    if n<d then nearest,d=cf,n end
   end

   if nearest then
    self:Move(root,nearest*CFrame.new(0,3,0))
    self:Say("Chờ spawn: "..q.mob)
   else
    self:CancelMove()
    self:Say("Chưa thấy quái/spawn: "..q.mob)
   end
   return
  end

  self:ClearHover()
  q=quests[1]

  if (root.Position-q.npc.Position).Magnitude>8 then
   self:Move(root,q.npc*CFrame.new(0,0,3))
   self:Say("Tới NPC nhận quest: "..q.mob)
   return
  end

  self:CancelMove()

  if self.Request and not self.Request.done then
   self:Say("Đang chờ StartQuest trả lời...")
   return
  end

  if os.clock()<self.NextQuest then
   self:Say(
    "Chờ quest có tiến độ. Bấm Chép chẩn đoán nếu vẫn đứng."
   )
   return
  end

  local folder=RS:FindFirstChild("Remotes")
  local remote=folder and folder:FindFirstChild("CommF_")
  if not remote then
   self:Say("Không thấy CommF_.")
   return
  end

  self.NextQuest=os.clock()+4
  local request={quest=q,done=false}
  self.Request=request
  self:Say("Gửi StartQuest: "..q.id.." / "..q.stage)

  self.RequestThread=task.spawn(function()
   local ok,result=pcall(function()
    return remote:InvokeServer("StartQuest",q.id,q.stage)
   end)

   if not self.Alive or not cfg.Enabled
    or token~=self.Token or self.Request~=request then
    return
   end

   request.done=true
   request.result=tostring(result)
   if not ok then
    self:Say("StartQuest lỗi: "..tostring(result))
   end
  end)
 end

 function s:Start()
  if not self.Alive or cfg.Enabled then return end

  local places={
   [2753915549]=true,
   [4442272183]=true,
   [7449423635]=true,
  }
  if game.GameId~=994732206 and not places[game.PlaceId] then
   self:Say("Vào Blox Fruits trước.")
   return
  end

  cfg.Enabled=true
  self.Token=self.Token+1
  self.NextAttack=0
  self.Target=nil
  self.LastTool=nil
  self.Confirmed=false
  local token=self.Token

  self.Thread=task.spawn(function()
   while self.Alive and cfg.Enabled and token==self.Token do
    local ok,err=pcall(function() self:Step(token) end)
    if not ok then
     self:Stop("Lỗi farm: "..tostring(err))
     break
    end
    task.wait(.04)
   end
  end)

  self:Say("Đã bật farm v2.")
 end

 return s
end

local function mountSettings(ctx,controller)
 local page=assert(ctx.pages["Farm Settings"],"Missing Farm Settings")
 for _,o in ipairs(page:GetChildren()) do
  if o:IsA("GuiObject") then o:Destroy() end
 end

 local cfg,C=controller.Config,ctx.C
 ctx.section(page,"Đòn đánh và vị trí farm")

 local function button(name,text,callback)
  local b=ctx.card(page,58,true)
  b.Name="LexFarm"..name
  b.Text=text
  b.TextSize=16
  b.Font=Enum.Font.GothamBold
  b.TextColor3=C.text
  ctx.on(b.Activated,function() callback(b) end)
  return b
 end

 local function toggle(field,title,changed)
  local function text()
   return title..(cfg[field] and ": Bật" or ": Tắt")
  end
  button(field,text(),function(b)
   cfg[field]=not cfg[field]
   b.Text=text()
   controller.NextAttack=0
   if changed then changed() end
  end)
 end

 toggle("Fast","Fast Attack")
 toggle("Hover","Bay phía trên quái",function()
  if not cfg.Hover then controller:ClearHover() end
 end)

 local function slider(name,title,a,b,value,changed)
  local old={}
  for _,o in ipairs(page:GetChildren()) do old[o]=true end

  ctx.slider(page,title,a,b,value,changed)

  for _,o in ipairs(page:GetChildren()) do
   if not old[o] and o:IsA("GuiObject") then
    o.Name="LexFarm"..name
   end
  end
 end

 slider(
  "Delay","Nhịp Fast Attack (ms)",80,600,
  math.floor(cfg.Delay*1000+.5),
  function(n) cfg.Delay=n/1000 end
 )
 slider(
  "Range","Phạm vi kích hoạt M1 (studs)",3,30,cfg.Range,
  function(n) cfg.Range=n end
 )
 slider(
  "Height","Độ cao phía trên quái (studs)",0,12,cfg.Height,
  function(n) cfg.Height=n end
 )

 local choices={"Auto","Mouse","VirtualUser","Tool"}
 local index=1
 for i,v in ipairs(choices) do
  if v==cfg.Backend then index=i end
 end

 button("Backend","Cách kích hoạt: "..choices[index].."  >",function(b)
  controller:ReleaseClick()
  index=index%#choices+1
  cfg.Backend=choices[index]
  controller.InputChoice=nil
  controller.DamageAt=os.clock()
  controller.NextAttack=0
  b.Text="Cách kích hoạt: "..cfg.Backend.."  >"
 end)

 local output

 button("CopyDiagnostic","Sao chép chẩn đoán",function(b)
  local text=tostring(
   controller.Diagnostic or controller.LastMessage
    or "Chưa có dữ liệu."
  )

  local ok=pcall(function()
   assert(type(setclipboard)=="function","Clipboard unavailable")
   setclipboard(text)
  end)

  b.Text=ok and "Đã sao chép chẩn đoán" or "Chẩn đoán ở bên dưới"
  output.Text=text
 end)

 local card=ctx.card(page,148)
 card.Name="LexFarmDiagnosticPanel"

 output=ctx.label(
  card,
  "Phạm vi M1 chỉ quyết định lúc gửi đòn; sát thương và cooldown do game xử lý.",
  13,UDim2.fromOffset(16,12),UDim2.new(1,-32,1,-24),C.muted
 )
 output.Name="LexFarmDiagnosticText"
 output.TextWrapped=true
 output.TextTruncate=Enum.TextTruncate.None
 output.TextYAlignment=Enum.TextYAlignment.Top
end

local mount=M.Mount

function M.Mount(ctx)
 local s=mount(ctx)
 s.Window=ctx.gui:FindFirstChild("Window")
 ctx.gui:SetAttribute("LexFarmV2",true)

 for _,row in ipairs(ctx.pages.Main:GetChildren()) do
  for _,o in ipairs(row:GetChildren()) do
   if o:IsA("TextLabel") and (
    o.Text:find("Tầm Farm Aura",1,true)
    or o.Text:find("Bán kính Farm Distance",1,true)
   ) then
    row:Destroy()
    break
   end
  end
 end

 mountSettings(ctx,s)

 local b=ctx.card(ctx.pages["Farm Settings"],58,true)
 b.Name="LexFarmLinkQuest"
 b.Text="Ghép quest đang có theo cấp"
 b.TextSize=15
 b.TextColor3=ctx.C.text
 b.Font=Enum.Font.GothamBold

 ctx.on(b.Activated,function()
  local qs,err=s:Quests()
  if not qs then s:Say(err);return end

  if s:QuestUI(qs) then
   s.ActiveQuest=qs[1]
   s:Say("Đã ghép quest hiện tại với "..qs[1].mob)
  else
   s:Say("Chưa thấy quest có tiến độ trên màn hình.")
  end
 end)

 ctx.slider(
  ctx.pages["Farm Settings"],"Bán kính tìm quái Distance",
  50,2000,s.Config.Radius,
  function(n) s.Config.Radius=n end
 )

 s:Say(
  "Farm v2 sẵn sàng. Chỉnh nhịp, tầm, độ cao ở Farm Settings."
 )
 return s
end

M.Version="LexFarm2"
return M
end