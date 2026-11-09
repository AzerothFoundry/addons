local A=AzerothGM
local U=A.UI
local roleNames={[1]="近战输出",[2]="远程输出",[3]="坦克",[4]="治疗"}
local classNames={[1]="战士",[2]="骑士",[3]="猎人",[4]="盗贼",[5]="牧师",[7]="萨满",[8]="法师",[9]="术士",[11]="德鲁伊"}
local profiles={{0,"当前副本"},{409,"熔火之心 MC"},{469,"黑翼之巢 BWL"},{533,"纳克萨玛斯 Naxx"},{531,"安其拉神殿 AQ40"},{249,"奥妮克希亚"},{309,"祖尔格拉布"},{509,"安其拉废墟"}}
local R={role=2,profile=1,lines={},token=nil};A.raidSetup=R
function R.Paint()
 if not R.summary then return end
 R.roleButton:SetText("我的职责："..roleNames[R.role])
 R.summary:SetText(table.concat(R.lines,"\n"))
 if R.profileButton then R.profileButton:SetText("编队："..profiles[R.profile][2]) end
 if R.token then R.apply:Enable() else R.apply:Disable() end
end
function R.Preview()
 R.lines={"正在请求当前副本阵容；现有队友会保留。"};R.members=0;R.token=nil;R.Paint()
 A.Send("party raid preview "..R.role..(profiles[R.profile][1]~=0 and " "..profiles[R.profile][1] or ""))
end
function R.Show()
 if not R.frame then
  local f=CreateFrame("Frame","AzerothGMRaidSetup",UIParent);R.frame=f
  f:SetWidth(860);f:SetHeight(500);f:SetPoint("CENTER",UIParent,"CENTER",0,0);f:SetFrameStrata("DIALOG");f:EnableMouse(true)
  f:SetBackdrop({bgFile="Interface\\DialogFrame\\UI-DialogBox-Background",edgeFile="Interface\\DialogFrame\\UI-DialogBox-Border",tile=true,tileSize=32,edgeSize=32,insets={left=10,right=10,top=10,bottom=10}})
  U.label(f,nil,"按当前副本快速编队",25,-25,780,"GameFontNormalLarge")
  U.label(f,nil,"60级、脱战、队长可用。先预览再补齐；不移除现有成员，不会自动开怪。",25,-58,800,"GameFontHighlightSmall")
  R.roleButton=U.button(f,"AzerothGMRaidRole","",25,-90,190,function() R.role=R.role==4 and 1 or R.role+1;R.token=nil;R.lines={"职责已改变，请重新预览。"};R.Paint() end)
  U.button(f,"AzerothGMRaidPreview","预览 / 重新随机",230,-90,190,function()R.Preview()end)
  R.apply=U.button(f,"AzerothGMRaidApply","一键补齐团队",435,-90,190,function()
   if not R.token then return end
   local token=R.token
   U.confirm("按照预览补齐当前副本团队？超过5人会转为团队；队伍会按小队分配。预览60秒有效，职业齐全不代表已实现所有Boss机制。",function()
    if R.token~=token then A.Log("预览已变化，请重新确认。");return end
    R.token=nil;R.Paint();A.Send("party raid apply "..token);A.RequestPartyStatus()
   end)
  end)
  U.button(f,"AzerothGMRaidClose","关闭",640,-90,175,function()f:Hide()end)
  R.profileButton=U.button(f,"AzerothGMRaidProfile","编队：当前副本",25,-130,290,function()
   R.profile=R.profile+1;if R.profile>table.getn(profiles) then R.profile=1 end;R.token=nil;R.lines={"预设已变化，请重新预览。野外可先按所选预设组团，再手动传送进入对应副本。"};R.Paint()
  end)
  R.summary=U.label(f,"AzerothGMRaidSummary","",25,-175,805,"GameFontHighlightSmall")
  U.label(f,nil,"预览包含现有成员职责和新增职业。配置不满足时服务端会拒绝，不会随机冒充合格。\nNaxx预留八坦；四骑士轮换、教官控制等专项机制需另行核验。",25,-445,800,"GameFontHighlightSmall")
 end
 R.frame:Show();R.Paint()
end
local handle=A.HandleMessage
function A.HandleMessage(message)
 handle(message)
 if type(message)~="string" then return end
 local kind=string.match and string.match(message,"^GMUI|([^|]+)") or nil
 if not kind then local _,_,k=string.find(message,"^GMUI|([^|]+)");kind=k end
 if kind=="ERROR" then R.token=nil;R.Paint();return end
 if kind~="RAIDMEMBER" and kind~="RAIDADD" and kind~="RAIDPLAN" then return end
 local row={};for k,v in string.gfind(message,"|([^=|]+)=([^|]*)") do row[k]=v end
 if kind=="RAIDMEMBER" then
  R.members=(R.members or 0)+1;local line="已有："..(row.name or "?").." · "..(classNames[tonumber(row.class)] or "?").." · "..(roleNames[tonumber(row.role)] or "未知职责");A.Log(line);if R.members<=3 then table.insert(R.lines,line) end
 elseif kind=="RAIDADD" then table.insert(R.lines,"补充："..(classNames[tonumber(row.class)] or "?").." / "..(roleNames[tonumber(row.role)] or "?").." ×"..(row.count or "?"))
 else
  R.token=row.token
  table.insert(R.lines,1,(row.name or "副本").." · "..(row.size or "?").."人：坦克 "..(row.tanks or "?").." / 治疗 "..(row.heals or "?").." / 输出 "..(row.dps or "?"))
  table.insert(R.lines,"已有成员 "..(row.existing or "?").." 人；全部职责详见GM日志。")
  table.insert(R.lines,"本次新增 "..(row.add or "?").." 名机器人；确认后请刷新机器人状态，等待全部就绪。")
 end
 R.Paint()
end
local build=A.Build
function A.Build()
 build()
 if not A.raidSetupButton then A.raidSetupButton=U.button(A.pages[4],"AzerothGMRaidSetupOpen","当前副本：一键编队",0,-350,270,function()R.Show()end) end
end
