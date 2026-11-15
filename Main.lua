-- Lex Hub / Auto Farm test: Level, Distance, Aura.
local M={}
local P=game:GetService("Players")
local R=game:GetService("ReplicatedStorage")
local T=game:GetService("TweenService")
local me=P.LocalPlayer
local seas={[2753915549]=1,[4442272183]=2,[7449423635]=3}

local function norm(s)
 return tostring(s):gsub("%b[]",""):lower():gsub("[^%a]","")
end

local function location(o)
 if typeof(o)=="CFrame" then return o end
 if typeof(o)=="Vector3" then return CFrame.new(o) end
 if typeof(o)=="Instance" then
  if o:IsA("BasePart") then return o.CFrame end
  if o:IsA("Model") then return o:GetPivot() end
 elseif type(o)=="table" then
  return location(o.CFrame or o.Position)
 end
end

local function character()
 local c=me.Character
 local h=c and c:FindFirstChildOfClass("Humanoid")
 local r=c and c:FindFirstChild("HumanoidRootPart")
 if h and h.Health>0 and r then return c,h,r end
end

local function level()
 local d=me:FindFirstChild("Data")
 local v=d and d:FindFirstChild("Level")
 return v and tonumber(v.Value) or 0
end

function M.Create(config,report)
 local cfg=config or {}
 for k,v in pairs({
  Enabled=false,Mode="Level",Weapon="Melee",
  Radius=600,Range=7,Speed=160,
 }) do
  if cfg[k]==nil then cfg[k]=v end
 end
 cfg.Enabled=false

 local self={
  Config=cfg,Alive=true,Token=0,
  Report=report or print,NextQuest=0,NextAttack=0,
 }

 function self:Say(s)
  if not self.Alive then return end
  local out="Sea "..tostring(seas[game.PlaceId] or "?")
   .." / Lv."..level().." / "..cfg.Mode.."\n"..s
  if out~=self.LastMessage then
   self.LastMessage=out
   self.Report(out)
  end
 end

 function self:CancelMove()
  if self.Tween then
   pcall(function() self.Tween:Cancel() end)
  end
  self.Tween=nil
  self.MoveRoot=nil
  self.Goal=nil
 end

 function self:ReleaseClick()
  if self.MouseDown and self.Input then
   pcall(function()
    self.Input:SendMouseButtonEvent(
     2,self.ClickY,0,false,game,0
    )
   end)
  end
  self.MouseDown=false
 end

 function self:Stop(message)
  cfg.Enabled=false
  self.Token=self.Token+1
  self:CancelMove()
  self:ReleaseClick()
  self.Target=nil
  self.Health=nil
  self.DamageAt=nil
  self.NextAttack=0

  if self.Thread and self.Thread~=coroutine.running() then
   pcall(task.cancel,self.Thread)
  end
  self.Thread=nil
  self:Say(message or "Đã tắt Auto Farm.")
 end

 function self:Move(root,goal)
  if (root.Position-goal.Position).Magnitude<.75 then
   self:CancelMove()
   return true
  end

  if self.Tween and self.MoveRoot==root and self.Goal
   and (self.Goal.Position-goal.Position).Magnitude<2
   and self.Tween.PlaybackState==Enum.PlaybackState.Playing then
   return false
  end

  self:CancelMove()
  self.MoveRoot=root
  self.Goal=goal
  self.Tween=T:Create(
   root,
   TweenInfo.new(
    math.max(.1,(root.Position-goal.Position).Magnitude/cfg.Speed),
    Enum.EasingStyle.Linear
   ),
   {CFrame=goal}
  )
  self.Tween:Play()
  return false
 end

 function self:Spawns(name)
  local result={}
  local origin=workspace:FindFirstChild("_WorldOrigin")
  local folder=workspace:FindFirstChild("EnemySpawns")
   or origin and origin:FindFirstChild("EnemySpawns")

  if folder then
   for _,o in ipairs(folder:GetChildren()) do
    if norm(o.Name)==norm(name) then
     local cf=location(o)
     if cf then result[#result+1]=cf end
    end
   end
  end
  return result
 end

 function self:Quests()
  local lv=level()
  if self.Candidates and self.ReadLevel==lv
   and os.clock()<(self.ReadAt or 0)+5 then
   return #self.Candidates>0 and self.Candidates or nil,
    self.QuestError
  end

  if not self.QuestData then
   local q=R:FindFirstChild("Quests")
   local g=R:FindFirstChild("GuideModule")
   if not q or not g
    or not q:IsA("ModuleScript")
    or not g:IsA("ModuleScript") then
    return nil,"Không tìm thấy Quests/GuideModule trong bản game này."
   end

   local a,b=pcall(require,q)
   local c,d=pcall(require,g)
   if not a or not c
    or type(b)~="table" or type(d)~="table" then
    return nil,"Không đọc được dữ liệu nhiệm vụ của game."
   end
   self.QuestData=b
   self.Guide=d
  end

  local list=self.Guide.Data and self.Guide.Data.NPCList
  if type(list)~="table" then
   return nil,"Cấu trúc GuideModule.NPCList đã thay đổi."
  end

  local result,seen={},{}
  for npc,data in pairs(list) do
   if type(data)=="table" and type(data.Levels)=="table" then
    local cf=location(npc) or location(data.Position)
    if cf then
     for stage,required in pairs(data.Levels) do
      required=tonumber(required)
      if required and required<=lv then
       for id,stages in pairs(self.QuestData) do
        local entry=type(stages)=="table"
         and (stages[stage] or stages[tonumber(stage)])

        if type(id)=="string"
         and id~="CitizenQuest"
         and id~="BartiloQuest"
         and type(entry)=="table"
         and tonumber(entry.LevelReq)==required
         and type(entry.Task)=="table" then

         for mob,count in pairs(entry.Task) do
          if type(mob)=="string"
           and tonumber(count) and tonumber(count)>=2
           and not(
            me.Team and norm(me.Team.Name)=="pirates"
            and norm(mob)=="trainee"
           ) then
           local spawn=self:Spawns(mob)
           local score=math.huge
           for _,s in ipairs(spawn) do
            score=math.min(
             score,(s.Position-cf.Position).Magnitude
            )
           end

           local key=id..":"..tostring(stage)
           if not seen[key] or score<seen[key].score then
            seen[key]={
             id=id,stage=tonumber(stage) or stage,
             mob=mob,npc=cf,required=required,score=score,
            }
           end
          end
         end
        end
       end
      end
     end
    end
   end
  end

  for _,q in pairs(seen) do result[#result+1]=q end

  local _,_,root=character()
  table.sort(result,function(a,b)
   if a.required~=b.required then
    return a.required>b.required
   end
   if root then
    return (a.npc.Position-root.Position).Magnitude
     <(b.npc.Position-root.Position).Magnitude
   end
   return a.score<b.score
  end)

  self.Candidates=result
  self.ReadLevel=lv
  self.ReadAt=os.clock()
  self.QuestError=#result==0
   and "Chưa tìm được quest phù hợp. Chọn phe và chờ game tải NPC."
   or nil

  if #result==0 then return nil,self.QuestError end
  return result
 end

 function self:Nearest(root,name,radius)
  local folder=workspace:FindFirstChild("Enemies")
  if not folder then return nil end
  local best,dist=nil,radius

  for _,mob in ipairs(folder:GetChildren()) do
   local h=mob:FindFirstChildOfClass("Humanoid")
   local r=mob:FindFirstChild("HumanoidRootPart")
   if h and r and h.Health>0
    and (not name or norm(mob.Name)==norm(name)) then
    local d=(r.Position-root.Position).Magnitude
    if d<dist then best,dist=mob,d end
   end
  end
  return best,dist
 end

 function self:Equip(c,h)
  local held=c:FindFirstChildOfClass("Tool")
  if cfg.Weapon=="Đang cầm" then return held end
  if held and held.ToolTip==cfg.Weapon then return held end

  local bag=me:FindFirstChild("Backpack")
  if bag then
   for _,tool in ipairs(bag:GetChildren()) do
    if tool:IsA("Tool") and tool.ToolTip==cfg.Weapon then
     h:EquipTool(tool)
     return tool
    end
   end
  end
 end

 function self:Attack(c,h,root,mob,stationary)
  local target=mob:FindFirstChild("HumanoidRootPart")
  local health=mob:FindFirstChildOfClass("Humanoid")
  if not target or not health then return end

  local tool=self:Equip(c,h)
  if not tool then
   self:CancelMove()
   self:Say("Không có vũ khí "..cfg.Weapon
    ..". Mở túi và kiểm tra vũ khí.")
   return
  end

  local distance=(target.Position-root.Position).Magnitude
  if distance>cfg.Range then
   local offset=math.max(.5,math.min(3,cfg.Range-1))
   if not stationary then
    self:Move(root,target.CFrame*CFrame.new(0,0,offset))
    self:Say("Đang tới "..mob.Name
     .." / "..math.floor(distance).." studs")
   end
   return
  end

  self:CancelMove()
  local face=Vector3.new(
   target.Position.X,root.Position.Y,target.Position.Z
  )
  if (face-root.Position).Magnitude>.1 then
   root.CFrame=CFrame.lookAt(root.Position,face)
  end

  local now=os.clock()
  if self.Target~=mob then
   self.Target=mob
   self.Health=health.Health
   self.DamageAt=now
  end
  if health.Health<(self.Health or health.Health) then
   self.DamageAt=now
  end
  self.Health=health.Health

  if now<self.NextAttack then return end
  self.NextAttack=now+.28

  if tool.Enabled==false then
   self:Say(tool.Name
    ..": Tool.Enabled=false; chưa kích hoạt được vũ khí.")
   return
  end

  tool:Activate()
  if not self.Alive or not cfg.Enabled then return end

  if now-(self.DamageAt or now)>3 then
   local a,input=pcall(function()
    return game:GetService("VirtualInputManager")
   end)
   if a then
    self.Input=input
    self.ClickY=math.floor(
     (workspace.CurrentCamera
      and workspace.CurrentCamera.ViewportSize.Y or 720)*.5
    )
    pcall(function()
     input:SendMouseButtonEvent(
      2,self.ClickY,0,true,game,0
     )
     self.MouseDown=true
     task.wait(.035)
     self:ReleaseClick()
    end)
   end
  end

  if not self.Alive or not cfg.Enabled then return end
  if now-(self.DamageAt or now)>8 then
   self:Say("Đã kích hoạt "..tool.Name
    .." nhưng quái chưa mất máu. Kiểm tra M1 và tầm đánh.")
  else
   self:Say("Đang đánh "..mob.Name
    .." / "..tool.Name.." / HP "..math.floor(health.Health))
  end
 end

 function self:Step(token)
  if not self.Alive or not cfg.Enabled
   or token~=self.Token then return end

  local c,h,root=character()
  if not c then
   self:CancelMove()
   self:Say("Chờ nhân vật hồi sinh hoặc chọn phe.")
   return
  end

  if not me.Team then
   self:CancelMove()
   self:Say("Chọn phe Pirates hoặc Marines trước.")
   return
  end

  if cfg.Mode~="Level" then
   local radius=cfg.Mode=="Aura" and cfg.Range or cfg.Radius
   local mob=self:Nearest(root,nil,radius)
   if mob then
    self:Attack(c,h,root,mob,cfg.Mode=="Aura")
   else
    self:CancelMove()
    self:Say("Không có quái trong "..radius.." studs.")
   end
   return
  end

  local quests,err=self:Quests()
  if not self.Alive or not cfg.Enabled
   or token~=self.Token then return end
  if not quests then
   self:CancelMove()
   self:Say(err)
   return
  end

  local pg=me:FindFirstChild("PlayerGui")
  local main=pg and pg:FindFirstChild("Main")
  local quest=main and main:FindFirstChild("Quest")
  if not quest then
   self:CancelMove()
   self:Say("Chưa đọc được bảng Quest của game.")
   return
  end

  local q
  if quest.Visible then
   local container=quest:FindFirstChild("Container")
   local holder=container and container:FindFirstChild("QuestTitle")
   local title=holder and holder:FindFirstChild("Title")
   if not title then
    self:CancelMove()
    self:Say("Chưa đọc được tên nhiệm vụ.")
    return
   end

   local current=norm(title.Text)
   for _,item in ipairs(quests) do
    if current:find(norm(item.mob),1,true) then
     q=item
     break
    end
   end
   if not q then
    self:CancelMove()
    self:Say("Quest đang có chưa khớp dữ liệu. "
     .."Hoàn tất hoặc bỏ quest đó trước.")
    return
   end
  else
   q=quests[1]
   if (root.Position-q.npc.Position).Magnitude>8 then
    self:Move(root,q.npc*CFrame.new(0,0,3))
    self:Say("Đang tới NPC nhận quest: "..q.mob)
    return
   end

   self:CancelMove()
   if os.clock()<self.NextQuest then
    self:Say("Chờ quest hiện trên màn hình...")
    return
   end

   local remotes=R:FindFirstChild("Remotes")
   local remote=remotes and remotes:FindFirstChild("CommF_")
   if not remote then
    self:Say("Không tìm thấy remote nhận nhiệm vụ.")
    return
   end

   self.NextQuest=os.clock()+3
   local a,b=pcall(function()
    return remote:InvokeServer("StartQuest",q.id,q.stage)
   end)

   if not self.Alive or not cfg.Enabled
    or token~=self.Token then return end

   self:Say(a and ("Đang nhận nhiệm vụ: "..q.mob)
    or ("Lỗi nhận quest: "..tostring(b)))
   return
  end

  local mob=self:Nearest(root,q.mob,math.huge)
  if mob then
   self:Attack(c,h,root,mob,false)
   return
  end

  local closest,best=nil,math.huge
  for _,spawn in ipairs(self:Spawns(q.mob)) do
   local d=(spawn.Position-root.Position).Magnitude
   if d<best then closest,best=spawn,d end
  end

  if closest then
   self:Move(root,closest*CFrame.new(0,3,0))
   self:Say("Chờ quái xuất hiện: "..q.mob)
  else
   self:CancelMove()
   self:Say("Chưa thấy quái hoặc điểm spawn: "
    ..q.mob..". Chờ map tải.")
  end
 end

 function self:Start()
  if not self.Alive or cfg.Enabled then return end
  if not seas[game.PlaceId] and game.GameId~=994732206 then
   self:Say("Bản này chỉ chạy farm trong Blox Fruits.")
   return
  end

  cfg.Enabled=true
  self.Token=self.Token+1
  self.Target=nil
  self.Health=nil
  self.DamageAt=nil
  self.NextAttack=0
  local token=self.Token

  self:Say("Đã bật. Đang kiểm tra nhân vật...")
  self.Thread=task.spawn(function()
   while self.Alive and cfg.Enabled and token==self.Token do
    local a,b=pcall(function() self:Step(token) end)
    if not a then
     cfg.Enabled=false
     self:CancelMove()
     self:ReleaseClick()
     self:Say("Lỗi: "..tostring(b))
     warn("[Lex Farm] "..tostring(b))
     break
    end
    task.wait(.25)
   end
  end)
 end

 function self:Destroy()
  self.Alive=false
  self:Stop("Đã đóng Auto Farm.")
 end

 return self
end

function M.Mount(ctx)
 local page=assert(ctx.pages.Main,"Missing Main page")
 for _,o in ipairs(page:GetChildren()) do
  if o:IsA("GuiObject") then o:Destroy() end
 end

 local new,card,label,on,C=
  ctx.new,ctx.card,ctx.label,ctx.on,ctx.C

 ctx.section(page,"Auto Farm / Bản thử")

 local auto=card(page,62,true)
 auto.Name="LexAutoFarmToggle"
 auto.Text="Auto Farm: Tắt"
 auto.TextSize=17
 auto.Font=Enum.Font.GothamBold
 auto.TextColor3=C.text

 local modes=card(page,100)
 label(modes,"Chế độ farm",16,
  UDim2.fromOffset(18,10),
  UDim2.new(1,-36,0,24))

 local weapon=card(page,60,true)
 weapon.Name="LexFarmWeapon"
 weapon.Text="Vũ khí: Melee  >"
 weapon.TextSize=16
 weapon.Font=Enum.Font.Gotham
 weapon.TextColor3=C.text

 local state=card(page,122)
 local status=label(
  state,"Sẵn sàng: Sea 1 / Level 1 / Melee",14,
  UDim2.fromOffset(18,12),UDim2.new(1,-36,1,-24),C.muted
 )
 status.TextWrapped=true
 status.TextTruncate=Enum.TextTruncate.None
 status.TextYAlignment=Enum.TextYAlignment.Top

 local controller
 local function report(s)
  if not ctx.gui.Parent then return end
  status.Text=s
  auto.Text=controller.Config.Enabled
   and "Auto Farm: Bật" or "Auto Farm: Tắt"
  auto.TextColor3=controller.Config.Enabled
   and C.accent or C.text
 end

 controller=M.Create(ctx.Config,report)

 on(auto.Activated,function()
  if controller.Config.Enabled then
   controller:Stop()
  else
   controller:Start()
  end
 end)

 local buttons={}
 for i,name in ipairs({"Level","Distance","Aura"}) do
  local b=new("TextButton",{
   Name="LexFarmMode"..name,
   Position=UDim2.new((i-1)/3,12,0,48),
   Size=UDim2.new(1/3,-20,0,34),
   Text="Farm "..name,
   TextSize=13,
   Font=Enum.Font.GothamBold,
   TextColor3=C.text,
   BackgroundColor3=C.card,
   BorderSizePixel=0,
  },modes)
  ctx.corner(b,9)
  buttons[name]=b

  on(b.Activated,function()
   controller.Config.Mode=name
   controller:Stop(
    "Đã chọn Farm "..name..". Bật Auto Farm để chạy."
   )
   for key,button in pairs(buttons) do
    button.TextColor3=key==name and C.base or C.text
    button.BackgroundColor3=key==name and C.accent or C.card
   end
  end)
 end

 buttons.Level.BackgroundColor3=C.accent
 buttons.Level.TextColor3=C.base

 local weapons,index={"Melee","Sword","Đang cầm"},1
 on(weapon.Activated,function()
  index=index%#weapons+1
  controller.Config.Weapon=weapons[index]
  weapon.Text="Vũ khí: "..weapons[index].."  >"
 end)

 ctx.slider(
  page,"Bán kính Farm Distance (studs)",50,2000,600,
  function(n) controller.Config.Radius=n end
 )
 ctx.slider(
  page,"Tầm Farm Aura (studs)",3,12,7,
  function(n) controller.Config.Range=n end
 )

 ctx.gui.Destroying:Connect(function()
  controller:Destroy()
 end)

 controller:Say(
  "Farm Level + Melee đã chọn sẵn. "
   .."Vào Blox Fruits rồi bật Auto Farm."
 )
 return controller
end

return M