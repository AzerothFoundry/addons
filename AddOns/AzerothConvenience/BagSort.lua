local A=AzerothConvenience
local function say(text) A.SetStatus(text);DEFAULT_CHAT_FRAME:AddMessage("便利工具："..text,0.7,0.9,1) end
local function cursorBusy() return CursorHasItem() or (CursorHasSpell and CursorHasSpell()) or (SpellIsTargeting and SpellIsTargeting()) or (CursorHasMoney and CursorHasMoney()) end
local function busy() return UnitAffectingCombat("player") or (MerchantFrame and MerchantFrame:IsShown()) end
-- GetItemInfo is a cache-only read in 1.12. Tooltip setters request missing records.
local function requestInfo(bag,slot,inventory)
 if not A.cacheTip then
  A.cacheTip=CreateFrame("GameTooltip","AzerothConvenienceCacheTooltip",UIParent,"GameTooltipTemplate")
 end
 A.cacheTip:SetOwner(UIParent,"ANCHOR_NONE")
 if inventory then A.cacheTip:SetInventoryItem("player",inventory)
 else A.cacheTip:SetBagItem(bag,slot) end
 A.cacheTip:Hide()
end
local function item(bag,slot)
 local link=GetContainerItemLink(bag,slot)
 if not link then return {bag=bag,slot=slot,empty=true} end
 local _,count,locked=GetContainerItemInfo(bag,slot)
 local name,_,quality,level,kind,sub,maxStack=GetItemInfo(link)
 if not name or not count or not quality then requestInfo(bag,slot);return nil,"等待背包"..bag.."第"..slot.."格的物品资料……" end
 return {bag=bag,slot=slot,link=link,id=tonumber(string.match and string.match(link,"item:(%d+)") or string.gsub(link,".*item:(%d+).*","%1")),count=count,locked=locked,name=name,quality=quality,kind=kind or "",sub=sub or "",max=maxStack or 1}
end
local function ordinary(bag)
 if bag==0 then return true end
 local link=GetInventoryItemLink("player",ContainerIDToInventoryID(bag))
 if not link then return false end
 local name,_,_,_,kind,sub=GetItemInfo(link)
 if not name then requestInfo(nil,nil,ContainerIDToInventoryID(bag));return nil,"等待背包"..bag.."本身的物品资料……" end
 -- Compare against a native ordinary bag subtype, localized by the client.
 local _,_,_,_,normalKind,normalSub=GetItemInfo(4500)
 normalKind=normalKind or BAGNON_ITEMTYPE_CONTAINER
 normalSub=normalSub or BAGNON_SUBTYPE_BAG
 if not normalKind or not normalSub then return nil,"等待普通背包分类资料；请确认Bagnon核心已加载。" end
 return kind==normalKind and sub==normalSub
end
local function snapshot()
 local slots={}
 for bag=0,4 do
  local normal,reason=ordinary(bag)
  if normal==nil then return nil,reason end
  if normal then for slot=1,GetContainerNumSlots(bag) do
   local e,reason=item(bag,slot);if not e then return nil,reason end
   if e.locked then return nil,"等待背包"..bag.."第"..slot.."格解除锁定……" end
   table.insert(slots,e)
  end end
 end
 return slots
end
local function key(e) return e.empty and "-" or e.link..":"..e.count end
local function category(e)
 if e.id==6948 then return 0 end
 -- GetItemInfo supplies the native localized item class (not the item name).
 local kinds={Weapon=1,Armor=1,["武器"]=1,["护甲"]=1,["防具"]=1,Consumable=2,["消耗品"]=2,Quest=3,["任务"]=3}
 return kinds[e.kind] or 4
end
local function before(a,b)
 if a.empty then return false end;if b.empty then return true end
 local ac,bc=category(a),category(b);if ac~=bc then return ac<bc end
 if a.quality~=b.quality then return a.quality>b.quality end
 if a.kind~=b.kind then return a.kind<b.kind end
 if a.sub~=b.sub then return a.sub<b.sub end
 if a.name~=b.name then return a.name<b.name end
 return (a.id or 0)<(b.id or 0)
end
local function plan(slots)
 -- Exact links preserve random properties and enchants when merging stacks.
 for i,a in ipairs(slots) do if not a.empty and a.count<a.max then
  for j=i+1,table.getn(slots) do local b=slots[j]
   if not b.empty and a.link==b.link and b.count>0 then return b,a,"merge" end
  end
 end end
 for i,a in ipairs(slots) do
  local best=i
  for j=i+1,table.getn(slots) do if before(slots[j],slots[best]) then best=j end end
  if best~=i then return slots[best],a,"swap" end
 end
end
function A.StopSort(reason)
 if not A.sort then return end
 A.sort=nil
 if reason then say(reason) end
end
function A.StartSort()
 if A.sort then A.StopSort("已停止整理。");return end
 if busy() then say("请脱战并关闭商人窗口后整理。");return end
 if cursorBusy() then say("请先放下鼠标上的物品。");return end
 A.sort={age=0,wait=0,moves=0};say("开始整理普通背包；再次点击可停止。")
end
function A.SortStep(dt)
 local s=A.sort;if not s then return end
 s.age=s.age+dt
 if busy() then A.StopSort("整理已暂停：战斗或商人窗口已打开。");return end
 if cursorBusy() then A.StopSort("整理已停止，请先放下鼠标上的物品。");return end
 local slots,reason=snapshot()
 if not slots then
  if s.waitReason~=reason then s.wait=0;s.waitReason=reason end
  A.SetStatus(reason or "等待物品信息或锁定解除……");s.wait=s.wait+dt;if s.wait>10 then A.StopSort("物品信息或锁定状态尚未就绪，请稍后重试。");end;return end
 if s.pending then
  local a=item(s.pending.a.bag,s.pending.a.slot);local b=item(s.pending.b.bag,s.pending.b.slot)
  if not a or not b or a.locked or b.locked then return end
  if key(a)==s.pending.ak and key(b)==s.pending.bk then
   s.wait=s.wait+dt;if s.wait>5 then A.StopSort("背包移动未获确认，已停止；请稍后重试。");end;return
  end
  s.pending=nil;s.wait=0;A.SetStatus("正在整理，已完成"..s.moves.."次移动。")
 end
 s.waitReason=nil
 local from,to,mode=plan(slots)
 if not from then A.StopSort("背包整理完成（"..s.moves.."次移动）。");return end
 if s.moves>=600 then A.StopSort("本轮整理已达上限，请确认背包后重试。");return end
 s.pending={a=from,b=to,ak=key(from),bk=key(to)};s.wait=0
 -- One native inventory transaction per tick. A swap/partial merge leaves the
 -- displaced/remainder item on the cursor; return it to this transaction's source.
 PickupContainerItem(from.bag,from.slot)
 if not CursorHasItem() then A.StopSort("无法拾起物品，已停止整理。");return end
 PickupContainerItem(to.bag,to.slot)
 if CursorHasItem() then PickupContainerItem(from.bag,from.slot) end
 if CursorHasItem() then A.StopSort("移动被服务器拒绝，请把鼠标物品放回空格后重试。");return end
 s.moves=s.moves+1;A.SetStatus("正在整理，等待第"..s.moves.."次移动确认……")
end
function A.AttachSortButton()
 if not Bagnon or A.sortButton then return end
 local b=CreateFrame("Button","AzerothConvenienceSort",Bagnon,"UIPanelButtonTemplate")
 b:SetWidth(55);b:SetHeight(20);b:SetPoint("TOPRIGHT",Bagnon,"TOPRIGHT",-45,-8);b:SetText("整理")
 b:SetScript("OnClick",function() A.StartSort() end);A.sortButton=b
end
A.SortSnapshot=snapshot;A.SortPlan=plan
