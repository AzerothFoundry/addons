-- Current-instance Boss directory. The server owns eligibility and safe staging positions.
local A=AzerothGM
local U=A.UI
local B={rows={},page=1,epoch=0,dirty=true}
A.bossTele=B
local function text(zh,en) if GetLocale()=="zhCN" then return zh end return en end
local function number(value,min)
 local n=tonumber(value)
 if n and n==math.floor(n) and n>=(min or 0) and n<=4294967295 then return n end
end
local function active() return A.tab==3 and A.teleView=="bosses" end
local function hideRows()
 for _,row in ipairs(B.widgets or {}) do row.entry=nil;row.label:SetText("");row.button:Hide() end
end
local function zone()
 return (GetRealZoneText and GetRealZoneText()) or (GetZoneText and GetZoneText()) or ""
end
function A.PaintBossTele()
 if not B.widgets then return end
 hideRows()
 for i,entry in ipairs(B.rows) do
  local row=B.widgets[i]
  if row then
   row.entry=entry
   local suffix=entry.available=="1" and "" or text("  · 无可用位置来源","  · No known location")
   row.label:SetText(text("第 ","Boss ")..(entry.order or ((B.page-1)*8+i))..text(" 号 · "," · ")..entry.name..suffix)
   row.button:Show()
   if entry.available=="1" and B.loaded and not B.loading then row.button:Enable() else row.button:Disable() end
  end
 end
 B.title:SetText(text("当前副本：","Current instance: ")..zone())
 if B.loading then B.status:SetText(text("正在读取当前副本Boss…","Loading current-instance Bosses…"))
 elseif B.error then B.status:SetText(B.error)
 elseif B.loaded then
  if table.getn(B.rows)==0 then B.status:SetText(text("当前副本没有可列出的Boss。","No Bosses are listed for this instance."))
  else B.status:SetText(text("第 ","Page ")..B.page.." / "..math.max(1,math.ceil((B.total or 0)/8))..text(" 页 · 共 "," · ")..(B.total or 0)..text(" 位Boss"," Bosses")) end
 else B.status:SetText(text("请刷新当前副本Boss列表。","Refresh the current-instance Boss list.")) end
 if B.loaded and not B.loading and B.page>1 then B.prev:Enable() else B.prev:Disable() end
 if B.loaded and not B.loading and B.more then B.next:Enable() else B.next:Disable() end
end
function A.RequestBossPage(page)
 B.teleportPending=nil;B.epoch=B.epoch+1;B.rows={};B.loaded=false;B.error=nil
 if B.loading then
  B.discard=true;B.refreshQueued=true;A.PaintBossTele();return
 end
 B.loading=true;B.discard=false;B.refreshQueued=false;B.pending={};B.meta=nil;B.invalid=false
 B.requestPage=number(page,1) or 1;B.dirty=false
 A.PaintBossTele();A.Send("tele bosses "..B.requestPage)
end
function A.InvalidateBossTele()
 B.teleportPending=nil;B.epoch=B.epoch+1;B.rows={};B.loaded=false;B.dirty=true;B.error=nil
 if B.loading then B.discard=true;B.refreshQueued=active() end
 A.PaintBossTele()
 if active() and not B.loading then A.RequestBossPage(1) end
end
function A.ShowBossTele()
 A.bossTeleFrame:Show()
 if B.dirty or (not B.loaded and not B.loading) then A.RequestBossPage(1) else A.PaintBossTele() end
end
local function finish()
 B.loading=false
 if B.discard then
  B.pending={};B.rows={};B.loaded=false
  local refresh=B.refreshQueued and active();B.refreshQueued=false;B.discard=false
  if refresh then A.RequestBossPage(1) else A.PaintBossTele() end
  return
 end
 local m=B.meta
 if not m or B.invalid or number(m.page,1)~=B.requestPage or not number(m.total) or not number(m.map) or not number(m.instance) then
  B.rows={};B.error=text("Boss列表响应不完整，请刷新。","Incomplete Boss list; please refresh.")
 else
  for _,entry in ipairs(B.pending) do
   if entry.map~=m.map or entry.instance~=m.instance then B.invalid=true end
  end
  if B.invalid then B.rows={};B.error=text("副本上下文已变化，请刷新。","Instance context changed; please refresh.")
  else B.rows=B.pending;B.page=tonumber(m.page);B.total=tonumber(m.total);B.more=m.more=="1" and B.page*8<B.total;B.map=m.map;B.instance=m.instance;B.loaded=true end
 end
 B.pending={};A.PaintBossTele()
end
function A.HandleBossMessage(message)
 local parts=U.split(message);local kind=parts[2]
 if kind=="BOSSUNSAFE" then
  local v=U.parseFields(parts);local pending=B.teleportPending
  B.teleportPending=nil
  if not pending or not active() or not B.loaded or B.loading or B.epoch~=pending.epoch or v.id~=pending.id or v.map~=pending.map or v.instance~=pending.instance or GetTime()-pending.at>30 then return true end
  U.confirm(text("没有找到已验证的安全落脚点。仍传送到 ","No verified safe landing point. Teleport to ")..pending.name..text(" 的原始位置？可能立即引怪、落在障碍附近或卡地形。", " at the known anchor anyway? You may pull enemies or land near blocked terrain."),function()
   if active() and B.loaded and not B.loading and B.epoch==pending.epoch and B.map==pending.map and B.instance==pending.instance and GetTime()-pending.at<=60 then
    A.Send("tele boss "..pending.id.." fallback "..pending.map.." "..pending.instance)
   else A.Log(text("副本列表已变化，请刷新后重新选择Boss。","Instance list changed; refresh and choose the Boss again.")) end
  end)
  return true
 elseif kind=="BOSS" then
  if B.loading and not B.discard then
   local entry=U.parseFields(parts)
   if not number(entry.id,1) or not entry.name or entry.name=="" or not number(entry.map) or not number(entry.instance) or table.getn(B.pending)>=8 then B.invalid=true
   else
    for _,old in ipairs(B.pending) do if old.id==entry.id then B.invalid=true end end
    table.insert(B.pending,entry)
   end
  end
  return true
 elseif kind=="BOSSMETA" then
  if B.loading and not B.discard then B.meta=U.parseFields(parts) end
  return true
 elseif kind=="DONE" and parts[3]=="bosses" then
  if B.loading then finish() end
  return true
 elseif kind=="ERROR" and B.loading then
  B.loading=false;B.rows={};B.pending={};B.loaded=false;B.error=text("无法读取当前副本Boss，请查看操作结果。","Cannot load current-instance Bosses; see the operation log.")
  B.discard=false;B.refreshQueued=false;A.PaintBossTele()
 end
 return false
end
function A.BuildBossTelePanel(parent)
 U.button(A.teleCommon,"AzerothGMTeleBosses",text("当前副本Boss","Instance Bosses"),545,0,135,function() A.ShowTeleView("bosses") end)
 local p=CreateFrame("Frame","AzerothGMBossTele",parent);A.bossTeleFrame=p;p:SetAllPoints(parent)
 U.label(p,nil,text("当前副本Boss","Current-instance Bosses"),0,0,600)
 U.button(p,"AzerothGMBossBack",text("返回常用分类","Back to destinations"),635,0,205,function() A.ShowTeleView("common") end)
 B.title=U.label(p,"AzerothGMBossZone","",0,-40,560,"GameFontHighlightSmall")
 U.button(p,"AzerothGMBossRefresh",text("刷新当前副本","Refresh current instance"),600,-34,240,function() A.RequestBossPage(1) end)
 B.widgets={}
 for i=1,8 do
  local row={}
  row.label=U.label(p,"AzerothGMBossName"..i,"",0,-83-(i-1)*27,700,"GameFontHighlightSmall")
  row.button=U.button(p,"AzerothGMBossGo"..i,text("传送","Teleport"),735,-76-(i-1)*27,100,function()
   local entry=row.entry
   if not active() or not B.loaded or B.loading or not entry or entry.available~="1" then return end
   local epoch=B.epoch
   U.confirm(text("传送到 ","Teleport before ")..entry.name..text(" 前方？优先寻找安全点；找不到时会提示并允许继续。","? A safe point is preferred; if unavailable, you can confirm an unverified landing."),function()
    if active() and B.loaded and not B.loading and B.epoch==epoch and row.entry==entry then B.teleportPending={id=entry.id,map=entry.map,instance=entry.instance,name=entry.name,epoch=epoch,at=GetTime()};A.Send("tele boss "..entry.id)
    else A.Log(text("副本列表已变化，请刷新后重新选择Boss。","Instance list changed; refresh and choose the Boss again.")) end
   end)
  end)
  B.widgets[i]=row
 end
 B.status=U.label(p,"AzerothGMBossPaging","",0,-312,550,"GameFontHighlightSmall")
 B.prev=U.button(p,"AzerothGMBossPrev",text("上一页","Previous"),600,-305,110,function() if B.loaded and not B.loading and B.page>1 then A.RequestBossPage(B.page-1) end end)
 B.next=U.button(p,"AzerothGMBossNext",text("下一页","Next"),725,-305,110,function() if B.loaded and not B.loading and B.more then A.RequestBossPage(B.page+1) end end)
 U.label(p,nil,text("当前副本常见路线顺序；分支可自行选择。无安全点时可确认传送，仍保留副本与战斗限制。","Common instance route order; branches may vary. Unverified landing requires confirmation; instance/combat restrictions remain."),0,-350,840,"GameFontHighlightSmall")
 A.PaintBossTele();p:Hide()
end
local events=CreateFrame("Frame","AzerothGMBossEvents",UIParent)
events:RegisterEvent("PLAYER_ENTERING_WORLD");events:RegisterEvent("ZONE_CHANGED_NEW_AREA")
events:SetScript("OnEvent",function() A.InvalidateBossTele() end)
