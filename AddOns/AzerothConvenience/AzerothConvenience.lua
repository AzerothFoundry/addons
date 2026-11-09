local A={version="0.2.1",status="尚未整理；点击整理背包开始。"};AzerothConvenience=A
local function config()
 AzerothConvenienceDB=AzerothConvenienceDB or {}
 for _,key in ipairs({"sell","repair","health"}) do if AzerothConvenienceDB[key]==nil then AzerothConvenienceDB[key]=true end end
 return AzerothConvenienceDB
end
function A.SetStatus(text) A.status=text;if A.statusText then A.statusText:SetText("状态："..text) end end
local function say(text) A.SetStatus(text);DEFAULT_CHAT_FRAME:AddMessage("便利工具："..text,0.7,0.9,1) end
local function short(n)
 if n>=1000000 then return string.format("%.1fm",n/1000000) end
 if n>=10000 then return string.format("%.1fk",n/1000) end
 return tostring(n)
end
function A.UpdateHealth()
 if not TargetFrameHealthBar then return end
 if not A.health then
  A.health=TargetFrameHealthBar:CreateFontString("AzerothTargetHealthText","OVERLAY","GameFontHighlightSmall")
  A.health:SetPoint("CENTER",TargetFrameHealthBar,"CENTER",0,0)
  A.health:SetShadowColor(0,0,0,1);A.health:SetShadowOffset(1,-1)
 end
 if not config().health or not UnitExists("target") then A.health:SetText("");return end
 local value,max=UnitHealth("target"),UnitHealthMax("target")
 if not max or max<=0 then A.health:SetText("");return end
 local pct=math.floor(value/max*100+0.5)
 if max==100 then A.health:SetText(pct.."%")
 else A.health:SetText(short(value).."/"..short(max).." "..pct.."%") end
end
local function saleKey(bag,slot)
 local link=GetContainerItemLink(bag,slot);local _,count,locked=GetContainerItemInfo(bag,slot)
 return (link or "")..":"..tostring(count or 0),link,locked
end
function A.MerchantStep()
 local v=A.visit;if not v or v.skip or not MerchantFrame:IsShown() then return end
 if A.sort then return end
 if CursorHasItem() or (CursorHasSpell and CursorHasSpell()) or (SpellIsTargeting and SpellIsTargeting()) then return end
 local cfg=config()
 if v.pending then
  local current,_,locked=saleKey(v.pending.bag,v.pending.slot)
  if locked then return end
  if current~=v.pending.key then v.sold=v.sold+1;v.pending=nil;v.pendingAge=0
  elseif v.pendingAge<3 then return
  else v.blocked[v.pending.bag..":"..v.pending.slot..":"..current]=true;v.pending=nil end
 end
 if cfg.sell then
  local unresolved=false
  for bag=0,4 do for slot=1,GetContainerNumSlots(bag) do
   local key,link,locked=saleKey(bag,slot)
   if link then
    local _,_,quality=GetItemInfo(link)
    if quality==nil or locked then unresolved=true
    elseif quality==0 and not v.blocked[bag..":"..slot..":"..key] then
     v.pending={bag=bag,slot=slot,key=key};v.pendingAge=0;UseContainerItem(bag,slot);return
    end
   end
  end end
  if unresolved and v.age<15 then return end
 end
 if cfg.repair and CanMerchantRepair() then
  local cost,needed=GetRepairAllCost()
  if needed and cost and cost>0 then
   if GetMoney()<cost then
    if not v.noMoney then say("金币不足，暂时无法修理。");v.noMoney=true end
   elseif not v.repairAt or v.age-v.repairAt>=3 then
    if not v.repairBefore then v.repairBefore=cost end
    v.repairAttempts=(v.repairAttempts or 0)+1
    if v.repairAttempts<=3 then v.repairAt=v.age;RepairAllItems();return end
    if not v.repairFailed then say("修理尚未获确认，请手动检查装备耐久。");v.repairFailed=true end
   end
  elseif v.repairBefore and not v.repaired then v.repaired=true;say("装备修理完成，费用约"..math.floor(v.repairBefore/10000).."金"..math.floor(math.mod(v.repairBefore,10000)/100).."银"..math.mod(v.repairBefore,100).."铜。");end
 end
 if not v.reported and v.sold>0 then say("已售出"..v.sold.."组灰色垃圾。");v.reported=true end
end
function A.ShowOptions()
 if not A.options then
  local f=CreateFrame("Frame","AzerothConvenienceOptions",UIParent);A.options=f
  f:SetWidth(460);f:SetHeight(425);f:SetPoint("CENTER",UIParent,"CENTER",0,0);f:SetFrameStrata("DIALOG");f:EnableMouse(true)
  f:SetBackdrop({bgFile="Interface\\DialogFrame\\UI-DialogBox-Background",edgeFile="Interface\\DialogFrame\\UI-DialogBox-Border",tile=true,tileSize=32,edgeSize=32,insets={left=8,right=8,top=8,bottom=8}})
  local title=f:CreateFontString("AzerothConvenienceTitle","OVERLAY","GameFontNormalLarge");title:SetPoint("TOPLEFT",f,"TOPLEFT",22,-20);title:SetText("便利工具 "..A.version)
  local close=CreateFrame("Button",nil,f,"UIPanelCloseButton");close:SetPoint("TOPRIGHT",f,"TOPRIGHT",-5,-5);close:SetScript("OnClick",function() f:Hide() end)
  A.checks={}
  for i,entry in ipairs({{"sell","商人自动卖灰色垃圾"},{"repair","使用自身金币自动修理"},{"health","目标血条常驻数字"}}) do
   local key,text=entry[1],entry[2];local box=CreateFrame("CheckButton","AzerothConvenienceOption"..i,f,"UICheckButtonTemplate");box:SetPoint("TOPLEFT",f,"TOPLEFT",20,-53-(i-1)*38)
   local label=f:CreateFontString(nil,"OVERLAY","GameFontHighlight");label:SetPoint("LEFT",box,"RIGHT",5,0);label:SetText(text)
   box:SetScript("OnClick",function() config()[key]=this:GetChecked()==1;A.UpdateHealth() end);A.checks[key]=box
  end
  local sort=CreateFrame("Button","AzerothConveniencePanelSort",f,"UIPanelButtonTemplate");sort:SetPoint("TOPLEFT",f,"TOPLEFT",24,-177);sort:SetWidth(180);sort:SetHeight(28);sort:SetText("整理背包 / 停止")
  sort:SetScript("OnClick",function() A.StartSort() end)
  local quests=CreateFrame("Button","AzerothConvenienceQuestOptions",f,"UIPanelButtonTemplate");quests:SetPoint("TOPLEFT",f,"TOPLEFT",220,-177);quests:SetWidth(205);quests:SetHeight(28);quests:SetText("自动接交任务设置")
  quests:SetScript("OnClick",function() if AutoQuest and AutoQuest.ShowOptions then AutoQuest.ShowOptions() else say("自动接交任务插件未加载，请检查插件列表。") end end)
  local rules=f:CreateFontString("AzerothConvenienceRules","OVERLAY","GameFontHighlightSmall");rules:SetPoint("TOPLEFT",f,"TOPLEFT",24,-220);rules:SetWidth(405);rules:SetJustifyH("LEFT")
  rules:SetText("整理顺序：炉石最前 → 装备（橙、紫、蓝、绿、白、灰；更高品质优先）→ 消耗品 → 任务物品 → 其它。\n先合并完全相同物品的未满堆叠；同类再按品质、类型、子类型、名称、ID排序，空格最后。\n只整理普通背包，特殊包不动；不出售或删除物品。脱战并关闭商人、放下光标物品后操作。")
  A.statusText=f:CreateFontString("AzerothConvenienceStatus","OVERLAY","GameFontHighlightSmall");A.statusText:SetPoint("TOPLEFT",f,"TOPLEFT",24,-335);A.statusText:SetWidth(405);A.statusText:SetJustifyH("LEFT")
  local tip=f:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall");tip:SetPoint("BOTTOMLEFT",f,"BOTTOMLEFT",22,20);tip:SetText("按住Shift打开商人，可跳过本次自动操作。")
 end
 A.SetStatus(A.status)
 for key,box in pairs(A.checks) do box:SetChecked(config()[key]) end
 A.options:Show()
end
local frame=CreateFrame("Frame")
for _,event in ipairs({"PLAYER_ENTERING_WORLD","PLAYER_TARGET_CHANGED","UNIT_HEALTH","UNIT_MAXHEALTH","MERCHANT_SHOW","MERCHANT_CLOSED"}) do frame:RegisterEvent(event) end
frame:SetScript("OnEvent",function()
 if event=="MERCHANT_SHOW" then if A.StopSort then A.StopSort("整理已停止：商人窗口已打开。") end;A.visit={skip=IsShiftKeyDown(),sold=0,blocked={},age=0,pendingAge=0,repaired=false};A.MerchantStep()
 elseif event=="MERCHANT_CLOSED" then A.visit=nil
 else A.UpdateHealth() end
end)
local elapsed=0
frame:SetScript("OnUpdate",function()
 elapsed=elapsed+arg1;if elapsed<0.2 then return end;local dt=elapsed;elapsed=0
 A.UpdateHealth()
 if A.AttachSortButton then A.AttachSortButton() end
 if A.SortStep then A.SortStep(dt) end
 if A.visit then A.visit.age=A.visit.age+dt;A.visit.pendingAge=A.visit.pendingAge+dt;A.MerchantStep() end
end)
SLASH_AZEROTHCONVENIENCE1="/aqol";SlashCmdList["AZEROTHCONVENIENCE"]=function(text) local command=string.lower(string.gsub(string.gsub(text or "","^%s+",""),"%s+$",""));if command=="sort" then A.StartSort() else A.ShowOptions() end end
config()
