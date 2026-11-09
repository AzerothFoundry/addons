local A=AzerothGM
local U=A.UI
local R={}
local function send(command) A.Send("raidai "..command) end
local function show()
 if not R.frame then
  local f=CreateFrame("Frame","AzerothGMRaidCoordination",UIParent);R.frame=f
  f:SetWidth(760);f:SetHeight(340);f:SetPoint("CENTER",UIParent,"CENTER",0,0);f:SetFrameStrata("DIALOG");f:EnableMouse(true)
  f:SetBackdrop({bgFile="Interface\\DialogFrame\\UI-DialogBox-Background",edgeFile="Interface\\DialogFrame\\UI-DialogBox-Border",tile=true,tileSize=32,edgeSize=32,insets={left=10,right=10,top=10,bottom=10}})
  U.label(f,nil,"团队协作 · MC 首批策略",25,-25,700,"GameFontNormalLarge")
  U.label(f,nil,"快速编队的团队在副本内默认启用协调。状态与等待原因显示在 GM 日志。",25,-60,700,"GameFontHighlightSmall")
  U.button(f,"AzerothGMRaidAiStatus","查看团队职责 / 状态",25,-95,220,function()send("status")end)
  U.button(f,"AzerothGMRaidAiOn","启用团队协调",265,-95,220,function()send("on")end)
  U.button(f,"AzerothGMRaidAiOff","停用协调 / 取消开怪",505,-95,220,function()send("off")end)
  U.button(f,"AzerothGMRaidAiPull","当前目标：就位后开怪",25,-140,340,function()
   U.confirm("向全团发起就位确认？每名真人须自行确认。仅支持 MC 恶犬、迦顿、焚化者；安全条件不足时会等待或取消。",function()send("pull")end)
  end)
  U.button(f,"AzerothGMRaidAiCancel","取消待开怪 / 自动拉怪",385,-140,340,function()send("cancel")end)
  U.button(f,"AzerothGMRaidAiAuto","附近恶犬：自动拉怪试验",25,-185,340,function()
   U.confirm("授权在当前位置附近45码内自动拉熔火恶犬包？首次需要所有真人就位确认，之后仅在全团恢复、路径安全和坦克充足时继续。不会自动开 Boss；请先清理周围危险怪。",function()send("autopull on")end)
  end)
  U.button(f,"AzerothGMRaidAiAutoOff","停止自动拉怪",385,-185,340,function()send("autopull off")end)
  U.button(f,"AzerothGMRaidAiReset","重置职责（需脱战）",25,-230,340,function()
   U.confirm("清除当前团队的职责分配并取消待开怪？战斗中请先停用协调，避免突然重新分工。",function()send("reset")end)
  end)
  U.button(f,"AzerothGMRaidAiClose","关闭",385,-230,340,function()f:Hide()end)
  U.label(f,nil,"首批覆盖：小怪分坦、恶犬收尾、迦顿避让、焚化者分工。其它 Boss 不代表已具备完整机制。",25,-285,700,"GameFontHighlightSmall")
 end
 R.frame:Show();send("status")
end
local build=A.Build
function A.Build()
 build()
 if not R.button then R.button=U.button(A.pages[4],"AzerothGMRaidCoordinationOpen","团队协作 / MC 开怪",290,-350,270,show) end
end

-- Explicit GM-only combat resurrection, independent from raid tactics.
local M={epoch=0}
function A.MassReviveNow()
 M.pending=false;A.Send("raidtools revive now")
end
function A.RequestMassRevive()
 M.pending=true;M.requestAt=GetTime();A.Send("raidtools revive preview")
end
local previousHandle=A.HandleMessage
function A.HandleMessage(message)
 if message and string.sub(message,1,5)=="GMUI|" then
  local parts=U.split(message);local kind=parts[2]
  if kind=="MASSREVIVE" then
   if not M.pending or GetTime()-M.requestAt>20 then return true end
   M.pending=false;local v=U.parseFields(parts)
   local total=tonumber(v.eligible);local map=tonumber(v.map);local instance=tonumber(v.instance)
   if not total or total<0 or total>40 or not map or not instance then A.Log("群体复活响应不完整，请重试。");return true end
   if total==0 then A.Log("当前副本内没有可复活队友；已释放到副本外、离线等成员会跳过。");return true end
   local epoch=M.epoch;local at=GetTime()
   U.confirm("复活当前副本内 "..total.." 名队友（机器人 "..(v.bots or "0").."、真人 "..(v.players or "0").."）？允许战斗中使用，恢复100%血蓝。机器人直接复活，真人收到确认；副本外／已有复活请求等成员跳过。",function()
    if M.epoch==epoch and GetTime()-at<60 then A.Send("raidtools revive confirm "..map.." "..instance)
    else A.Log("队伍或副本已变化，请重新预览群体复活。");end
   end)
   return true
  elseif kind=="MASSREVIVERESULT" then
   local v=U.parseFields(parts);A.Log("群体复活：机器人已复活 "..(v.bots or "0").."，真人复活请求 "..(v.players or "0").."，跳过 "..(v.skipped or "0").."。");return true
  elseif kind=="ERROR" and M.pending then M.pending=false end
 end
 return previousHandle(message)
end
local oldBuild=A.Build
function A.Build()
 oldBuild()
 if not M.button then M.button=U.button(A.pages[4],"AzerothGMMassRevive","满血蓝群体复活",575,-350,270,A.MassReviveNow) end
end
local invalidate=CreateFrame("Frame")
for _,name in ipairs({"PLAYER_ENTERING_WORLD","PARTY_MEMBERS_CHANGED","RAID_ROSTER_UPDATE"}) do invalidate:RegisterEvent(name) end
invalidate:SetScript("OnEvent",function() M.epoch=M.epoch+1;M.pending=false end)
