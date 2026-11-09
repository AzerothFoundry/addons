local P={tabs={},plan={},buttons={}};AzerothTalentPreview=P
local nativeToggle=ToggleTalentFrame
local function say(s) DEFAULT_CHAT_FRAME:AddMessage("天赋预览："..s,1,0.85,0.4) end
local function sum(tab,plan,before)
 local n=0;for i,node in ipairs(P.tabs[tab].nodes) do if not before or node.row<before then n=n+((plan[tab] or {})[i] or 0) end end;return n
end
function P.Spent(plan)local n=0;for tab=1,table.getn(P.tabs) do n=n+sum(tab,plan) end;return n end
function P.Valid(plan,budget)
 if P.Spent(plan)>budget then return false,"超过预览点数预算。" end
 for tab,data in ipairs(P.tabs) do
  for i,node in ipairs(data.nodes) do
   local rank=(plan[tab] or {})[i] or 0
   if rank<0 or rank>node.max then return false,"天赋等级无效。" end
   if rank>0 then
    if sum(tab,plan,node.row)<(node.row-1)*5 then return false,"需要先在本系较低层投入足够点数。" end
    for _,req in ipairs(node.req) do if ((plan[tab] or {})[req[1]] or 0)<req[2] then return false,"需要先满足前置天赋。" end end
   end
  end
 end
 return true
end
function P.RealPlan()
 local real={};for tab,data in ipairs(P.tabs) do real[tab]={};for i,_ in ipairs(data.nodes) do local _,_,_,_,rank=GetTalentInfo(tab,i);real[tab][i]=rank or 0 end end;return real
end
function P.Read()
 P.tabs={}
 for tab=1,GetNumTalentTabs() do
  local name,icon,points,bg=GetTalentTabInfo(tab);local graph=AzerothTalentData[bg]
  if not graph or table.getn(graph)~=GetNumTalents(tab) then return false,"当前天赋数据与原版预览数据不一致。" end
  local data={name=name,bg=bg,nodes={}}
  for i,node in ipairs(graph) do
   local talent,texture,tier,column,rank,max=GetTalentInfo(tab,i)
   if tier~=node.row or column~=node.col or max~=node.max then return false,"天赋位置不匹配，已停止预览。" end
   data.nodes[i]={name=talent,texture=texture,row=node.row,col=node.col,max=max,req=node.req,desc=node.desc}
  end
  P.tabs[tab]=data
 end
 return table.getn(P.tabs)>0,"10级后才能查看天赋。"
end
function P.Paint()
 if not P.frame then return end
 local points=tonumber(P.budget:GetText()) or 0
 local spent=P.Spent(P.plan);local counts={}
 for tab,data in ipairs(P.tabs) do
  table.insert(counts,tostring(sum(tab,P.plan)))
  P.titles[tab]:SetText(data.name.."（"..sum(tab,P.plan).."）")
  for i,node in ipairs(data.nodes) do
   local b=P.buttons[tab][i];b.rank:SetText(((P.plan[tab] or {})[i] or 0).."/"..node.max)
   if ((P.plan[tab] or {})[i] or 0)>0 then b.rank:SetTextColor(0.2,1,0.2) else b.rank:SetTextColor(1,1,1) end
  end
 end
 P.summary:SetText("预览 "..table.concat(counts," / ").."  · 已用 "..spent.." / 预算 "..points.."  · 左键加点，右键减点；此处点击不会立即学习。")
end
function P.Change(tab,index,delta)
 if P.applying then return end
 local rank=P.plan[tab][index] or 0;P.plan[tab][index]=rank+delta
 local valid,message=P.Valid(P.plan,tonumber(P.budget:GetText()) or 0)
 if not valid then P.plan[tab][index]=rank;say(message) end
 P.Paint()
end
function P.ApplyStep(elapsed)
 if not P.applying then return end
 P.applyAge=(P.applyAge or 0)+elapsed
 if UnitAffectingCombat("player") or UnitIsDeadOrGhost("player") then P.applying=false;say("状态改变，已停止应用。");return end
 if P.pending then
  local _,_,_,_,rank=GetTalentInfo(P.pending[1],P.pending[2])
  if rank>P.pending[3] then P.pending=nil;P.applyAge=0
  elseif P.applyAge>4 then P.applying=false;say("服务端尚未确认加点，已停止；请检查可用点数与前置条件。");return
  else return end
 end
 local real=P.RealPlan();local free=UnitCharacterPoints("player") or 0
 for tab,data in ipairs(P.tabs) do for i,node in ipairs(data.nodes) do
  if (P.plan[tab][i] or 0)>(real[tab][i] or 0) then
   local old=real[tab][i];real[tab][i]=old+1
   local valid=P.Valid(real,300);real[tab][i]=old
   if valid and free>0 then P.pending={tab,i,old};P.applyAge=0;LearnTalent(tab,i);return end
  end
 end end
 P.applying=false;say("应用结束；实际已学天赋请在原生面板核对。")
end
function P.Apply()
 if P.applying then return end
 local budget=tonumber(P.budget:GetText()) or 0;local valid,message=P.Valid(P.plan,budget)
 if not valid then say(message);return end
 local real=P.RealPlan()
 for tab,data in ipairs(P.tabs) do for i,_ in ipairs(data.nodes) do if P.plan[tab][i]<real[tab][i] then say("预览低于已学天赋，请先自行洗点后再应用。");return end end end
 local required=P.Spent(P.plan)-P.Spent(real);local free=UnitCharacterPoints("player") or 0
 if required<=0 then say("与当前天赋相同，无需应用。");return end
 if required>free then say("实际未分配点数不足；预览预算不等于服务器授予的点数。");return end
 StaticPopup_Show("AZEROTH_TALENT_APPLY",tostring(required))
end
StaticPopupDialogs["AZEROTH_TALENT_APPLY"]={text="确认实际学习预览中的 %s 点天赋？这会消耗真实天赋点。",button1="确认应用",button2="取消",timeout=0,whileDead=0,hideOnEscape=1,OnAccept=function()P.applying=true;P.applyAge=0;P.pending=nil end}
function P.Build()
 local f=CreateFrame("Frame","AzerothTalentPreviewFrame",UIParent);P.frame=f
 f:SetWidth(880);f:SetHeight(510);f:SetPoint("CENTER",UIParent,"CENTER",0,0);f:SetFrameStrata("DIALOG");f:EnableMouse(true);f:SetMovable(true);f:RegisterForDrag("LeftButton")
 f:SetScript("OnDragStart",function()this:StartMoving()end);f:SetScript("OnDragStop",function()this:StopMovingOrSizing()end)
 f:SetBackdrop({bgFile="Interface\\DialogFrame\\UI-DialogBox-Background",edgeFile="Interface\\DialogFrame\\UI-DialogBox-Border",tile=true,tileSize=32,edgeSize=32,insets={left=8,right=8,top=8,bottom=8}})
 local title=f:CreateFontString(nil,"OVERLAY","GameFontNormalLarge");title:SetPoint("TOPLEFT",f,"TOPLEFT",22,-20);title:SetText("天赋预览（原版1.12）")
 local close=CreateFrame("Button",nil,f,"UIPanelCloseButton");close:SetPoint("TOPRIGHT",f,"TOPRIGHT",-5,-5);close:SetScript("OnClick",function()f:Hide()end)
 P.titles={};P.buttons={}
 for tab,data in ipairs(P.tabs) do
  local x=25+(tab-1)*285;P.titles[tab]=f:CreateFontString(nil,"OVERLAY","GameFontNormal");P.titles[tab]:SetPoint("TOPLEFT",f,"TOPLEFT",x,-53)
  P.buttons[tab]={}
  for i,node in ipairs(data.nodes) do
   local t,index=tab,i;local b=CreateFrame("Button","AzerothTalentNode"..t.."_"..index,f);P.buttons[tab][i]=b;b:SetWidth(38);b:SetHeight(38)
   b:SetPoint("TOPLEFT",f,"TOPLEFT",x+25+(node.col-1)*54,-82-(node.row-1)*45);b:SetNormalTexture(node.texture);b:SetHighlightTexture("Interface\\Buttons\\ButtonHilight-Square");b:RegisterForClicks("LeftButtonUp","RightButtonUp")
   b.rank=b:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall");b.rank:SetPoint("BOTTOMRIGHT",b,"BOTTOMRIGHT",2,-2)
   b:SetScript("OnClick",function()P.Change(t,index,arg1=="RightButton" and -1 or 1)end)
   b:SetScript("OnEnter",function()
    local rank=P.plan[t][index] or 0;GameTooltip:SetOwner(this,"ANCHOR_RIGHT");GameTooltip:SetText(node.name.."（预览 "..rank.."/"..node.max.."）")
    GameTooltip:AddLine(node.desc[math.max(1,rank)] or "",1,1,1,1);GameTooltip:Show()
   end);b:SetScript("OnLeave",function()GameTooltip:Hide()end)
  end
 end
 P.summary=f:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall");P.summary:SetPoint("TOPLEFT",f,"TOPLEFT",25,-407);P.summary:SetWidth(830);P.summary:SetJustifyH("LEFT")
 local function button(name,text,x,y,width,fn)local b=CreateFrame("Button",name,f,"UIPanelButtonTemplate");b:SetPoint("TOPLEFT",f,"TOPLEFT",x,y);b:SetWidth(width);b:SetHeight(25);b:SetText(text);b:SetScript("OnClick",fn);return b end
 P.budget=CreateFrame("EditBox","AzerothTalentBudget",f,"InputBoxTemplate");P.budget:SetPoint("TOPLEFT",f,"TOPLEFT",35,-436);P.budget:SetWidth(55);P.budget:SetHeight(24);P.budget:SetAutoFocus(false);P.budget:SetMaxLetters(3);P.budget:SetScript("OnEscapePressed",function()this:ClearFocus()end);P.budget:SetScript("OnTextChanged",function()if P.frame then P.Paint()end end)
 button("AzerothTalentCurrent","复制当前",110,-433,105,function()P.plan=P.RealPlan();P.Paint()end)
 button("AzerothTalentClear","清空预览",230,-433,105,function()P.applying=false;for t,data in ipairs(P.tabs) do P.plan[t]={};for i,_ in ipairs(data.nodes) do P.plan[t][i]=0 end end;P.Paint()end)
 button("AzerothTalentApply","确认后应用",350,-433,150,function()P.Apply()end)
 button("AzerothTalentNative","原生天赋",515,-433,140,function()f:Hide();if nativeToggle then nativeToggle()else LoadAddOn("Blizzard_TalentUI");ShowUIPanel(TalentFrame)end end)
 local tip=f:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall");tip:SetPoint("TOPLEFT",f,"TOPLEFT",25,-475);tip:SetText("左下角为预览预算；只有“确认后应用”才向服务器学习。GM可在技能/天赋页免费洗点。")
 f:SetScript("OnUpdate",function()P.ApplyStep(arg1)end);f:SetScript("OnHide",function()P.applying=false;P.budget:ClearFocus()end)
end
function P.Toggle()
 if P.frame and P.frame:IsShown() then P.frame:Hide();return end
 local ok,message=P.Read();if not ok then say(message);return end
 if not P.frame then P.Build() end
 P.plan=P.RealPlan();local free=UnitCharacterPoints("player") or 0
 P.budget:SetText(tostring(math.max(UnitLevel("player")-9,P.Spent(P.plan)+free,0)))
 P.frame:Show();P.Paint()
end
ToggleTalentFrame=function()P.Toggle()end
SLASH_AZEROTHTALENTPREVIEW1="/talentpreview";SLASH_AZEROTHTALENTPREVIEW2="/tpv";SlashCmdList["AZEROTHTALENTPREVIEW"]=function()P.Toggle()end
