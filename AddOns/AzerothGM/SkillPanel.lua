local A=AzerothGM
local U=A.UI
local scopes={{"player","本职技能"},{"pet","当前宠物"},{"profession","专业技能"},{"known","角色已学"},{"all","全部职业 / NPC"},{"mistaught","误学宠物技能"}}
local skillKinds={{"skill","技能"},{"teaching","教学法术"},{"all","全部记录"}}
local skillSchools={{"all","全部学派"},{"physical","物理"},{"holy","神圣"},{"fire","火焰"},{"nature","自然"},{"frost","冰霜"},{"shadow","暗影"},{"arcane","奥术"}}
local skillEffects={{"all","全部效果"},{"damage","伤害"},{"dot","持续伤害"},{"heal","治疗"},{"hot","持续治疗"},{"slow","减速"},{"root","定身"},{"stun","昏迷"},{"silence","沉默"},{"interrupt","打断"},{"fear","恐惧"},{"dispel","驱散"},{"buff","增益"},{"debuff","减益"},{"summon","召唤"},{"taunt","嘲讽"},{"shield","吸收盾"}}
local skillTargets={{"all","全部范围"},{"single","单体"},{"aoe","AOE / 多目标"},{"chain","链式"},{"self","自身"},{"passive","被动"}}
local professions={{171,"炼金术"},{164,"锻造"},{333,"附魔"},{202,"工程学"},{182,"草药学"},{165,"制皮"},{186,"采矿"},{393,"剥皮"},{197,"裁缝"},{185,"烹饪"},{129,"急救"},{356,"钓鱼"}}
local errors={
 ["Leave combat before changing skills"]="请先脱离战斗；战场内脱战或排队时允许调整单个技能。",
 ["Leave combat battleground and queue before changing skills"]="请先退出战斗、战场和战场队列，再调整技能或上限。",
 ["Reset talents before lowering the total"]="已用天赋点超过新上限，请先点击“免费洗点”，再修改或恢复上限。",
 ["Forget excess professions before lowering the limit"]="已学主要专业数量超过目标上限，请先明确遗忘多余专业。",
 ["Primary profession limit reached"]="主要专业名额已满，可先调整本角色专业上限。",
 ["Spell does not fit current pet or level"]="技能不属于当前宠物，或宠物等级不足。",
 ["Spell does not fit current class or level"]="技能不适合当前职业或等级；教学法术不能作为战斗技能学习。",
 ["Profession skill requirement not met"]="专业熟练度不足，请先提升专业熟练度。",
 ["Summon a living pet first"]="请先召唤存活的宠物。",
 ["Summon a living warlock demon first"]="请先召唤一只存活的术士恶魔。",
 ["Player does not know this spell"]="角色尚未学会这个技能。",
 ["Pet does not know this spell"]="当前宠物尚未学会这个技能。",
 ["Use the talent tree or reset talents"]="天赋技能请在天赋树中分配，或通过免费洗点遗忘。",
 ["Learned professions raised to 300; no bulk recipes granted"]="已将选中的已学专业提升至大师级300熟练度；未额外批量赠送配方。",
 ["Learn a profession first"]="请先学习所选专业，再提升熟练度。",
 ["Level 35 required for the GM artisan shortcut"]="该GM大师级快捷入口要求角色至少35级。",
 ["Profession already learned"]="已学会这个专业；这里学习的是初级专业，不会覆盖熟练度。",
 ["Profession not learned"]="尚未学会这个专业。",
 ["Mistaught demon spells removed from player"]="已清理角色误学的恶魔技能，并补齐本职技能；宠物技能栏已刷新。",
 ["Demon spell cleanup is only for warlocks"]="此清理入口只处理术士旧版误学的恶魔技能。",
 ["Force learned spell saved"]="已强行学习并保存；技能是否可施放仍取决于法术自身的目标、姿态、资源和材料要求。",
 ["Administrator access required"]="强行学习需要管理员权限。",
 ["Player already knows this spell or force learn unavailable"]="已学会该法术，或当前状态不能强行学习。",
 ["Native learn did not retain the requested spell"]="原生学习流程未保留该法术，请检查法术类型。",
 ["Invalid skill filter"]="技能筛选条件无效，请重新选择。",
 ["Invalid spell ID"]="技能ID无效。",
 ["Unknown spell"]="服务器不存在此技能。",
 ["Invalid player spell"]="该法术数据无效，无法学习。",
 ["Force learn supports the current player and one spell ID only"]="强行学习只作用于自己，不作用于宠物。",
 ["Skill change saved"]="技能更改已保存。",
 ["Profession change saved"]="专业更改已保存。",
 ["Character limits saved"]="本角色上限已保存，重登仍保留。",
 ["Talents reset without gold cost"]="已免费重置天赋，上限保持当前设置。",
 ["Current demon spells learned and saved"]="当前恶魔已学习符合种类和等级的技能，并保存、刷新技能栏。",
 ["Player class spells learned; pet spells are separate"]="已学习当前等级的角色职业技能；宠物技能请使用独立入口。",
}
function A.HandleSkillMessage(text)
 local parts=U.split(text);local kind=parts[2]
 if (kind=="OK" or kind=="ERROR") and errors[parts[3]] then A.Log(errors[parts[3]]);return true end
 if kind=="CLEANUP" then
  local v=U.parseFields(parts);A.cleanCount=tonumber(v.count) or 0;A.Log(v.removed and ("已清理 "..v.removed.." 条误学记录。") or ("查到 "..A.cleanCount.." 条误学宠物技能，请检查列表后确认清理。"));return true
 elseif kind=="REGEN" then
  local v=U.parseFields(parts);A.Log("当前生命 "..v.hp.."/"..v.maxHp.."、法力 "..v.mana.."/"..v.maxMana.."；精神 "..v.spirit.."；"..(v.combat=="1" and "战斗中" or "已脱战")..(v.fiveSecondRule=="1" and "，仍在施法五秒回蓝规则内。" or "，未处于施法五秒规则。"));return true
 elseif kind=="REGENRATE" then
  local v=U.parseFields(parts);A.Log("基础自然恢复参考：生命 "..(v.healthTickRest or v.healthTickBase).." /2秒（不含食物），法力 "..v.manaTickRest.." /2秒；近期施法回蓝 "..v.manaTickCasting.." /2秒。回血/回蓝倍率 "..v.healthRate.."/"..v.manaRate.."。");return true
 elseif kind=="SKILL" then
  if A.skillsFinished then A.skills={};A.skillsFinished=false end
  table.insert(A.skills,U.parseFields(parts));return true
 elseif kind=="SKILLEFFECT" then
  local v=U.parseFields(parts)
  local hover=A.skillHoverRequest
  local text=A.AcceptSkillEffectPart(hover,v)
  if text and hover and hover.owner:IsVisible() and hover.owner.entry and tostring(hover.owner.entry.id)==hover.id then
   A.skillEffectCache=A.skillEffectCache or {};A.skillEffectCache[hover.id]=text
   A.PaintSkillTooltip(hover.owner,hover.owner.entry,text)
  end
  return true
 elseif kind=="SKILLMETA" then
  if A.skillsFinished then A.skills={};A.skillsFinished=false end
  local v=U.parseFields(parts);A.skillPage=tonumber(v.page) or 1;A.skillTotal=tonumber(v.total) or 0;A.skillMore=v.more=="1";return true
 elseif kind=="DONE" and parts[3]=="skills" then A.skillsFinished=true;A.PaintSkills();return true
 elseif kind=="PROFESSION" then
  local v=U.parseFields(parts);A.professions=A.professions or {};A.professions[tonumber(v.id)]=v;if A.professionButton then A.PaintProfession() end;return true
 elseif kind=="LIMITS" then
  A.professions={};if A.professionButton then A.PaintProfession() end
  A.limits=U.parseFields(parts)
  if A.skillLimits then A.skillLimits:SetText("天赋：已用 "..(A.limits.used or "?").." / 总点数 "..(A.limits.talents or "?").."，未分配 "..(A.limits.free or "?").."  ·  主要专业 "..(A.limits.professionsUsed or "?").." / "..(A.limits.professions or "?")) end
  return true
 end
 return false
end
function A.AcceptSkillEffectPart(request,v)
 local part,total=tonumber(v.part),tonumber(v.total)
 if not request or v.id~=request.id or not part or not total or part<1 or total<1 or total>64 or part>total or (request.total and request.total~=total) then return end
 request.total=total;request.parts[part]=v.text or ""
 for i=1,total do if request.parts[i]==nil then return end end
 return table.concat(request.parts,"")
end
function A.PaintSkillTooltip(owner,e,text)
 GameTooltip:SetOwner(owner,"ANCHOR_RIGHT")
 GameTooltip:SetText((e.name or "技能").." "..(e.rank or ""))
 GameTooltip:AddLine("技能ID："..e.id.."  ·  数据等级："..(e.level or "?"),0.5,0.8,1)
 GameTooltip:AddLine(text,1,1,1,true)
 GameTooltip:AddLine("基础说明，非角色实时数值。",0.6,0.6,0.6,true)
 GameTooltip:Show()
end
function A.SkillTooltip(owner,e)
 if not e then return end
 A.skillEffectCache=A.skillEffectCache or {}
 local cached=A.skillEffectCache[tostring(e.id)]
 A.skillHoverRequest={id=tostring(e.id),parts={},owner=owner}
 A.PaintSkillTooltip(owner,e,cached or e.effect or "正在读取技能介绍……")
 if not cached then A.Send("skills info "..e.id) end
end
function A.HideSkillTooltip()
 A.skillHoverRequest=nil;GameTooltip:Hide()
end
function A.SkillFilterToken()
 return "@"..skillKinds[A.skillKindFilter or 1][1]..":"..skillSchools[A.skillSchoolFilter or 1][1]..":"..skillEffects[A.skillEffectFilter or 1][1]..":"..skillTargets[A.skillTargetFilter or 1][1]
end
function A.SearchSkills()
 local query=U.trim(A.skillSearch:GetText());if string.find(query,"[|\r\n]") then A.Log("请输入正常技能名称或ID。");return end
 A.HideSkillTooltip();A.skillEffectCache={}
 A.skills={};A.skillsFinished=false;A.PaintSkills()
 A.Send("skills search "..scopes[A.skillScope][1].." "..(A.skillPage or 1).." "..A.SkillFilterToken()..(query~="" and " "..query or ""))
end
function A.PaintSkills()
 if not A.skillRows then return end
 for i,row in ipairs(A.skillRows) do
  local e=A.skills[i];row.entry=e;row.text.entry=e
  if e then
   local kind=e.kind=="teaching" and "教学法术" or e.kind=="pet" and "宠物" or e.kind=="profession" and "专业" or "技能"
   row.text:SetText("#"..e.id.." "..e.name.." "..(e.rank or "").." · 等级"..(e.level or "?").." ["..kind.."]"..(e.known=="1" and " 已学" or ""))
   if e.scope=="player" and e.forceable=="1" and e.known~="1" then row.force:Enable() else row.force:Disable() end
   if e.learnable=="1" and e.known~="1" then row.learn:Enable() else row.learn:Disable() end
   if e.known=="1" then row.forget:Enable() else row.forget:Disable() end
   row.frame:Show()
  else row.frame:Hide() end
 end
 A.skillPaging:SetText("共 "..(A.skillTotal or 0).." 个 · 第 "..(A.skillPage or 1).." 页")
end
function A.ChangeSkill(e,action)
 if action=="forcelearn" then
  if not e or e.scope~="player" or e.forceable~="1" or e.known=="1" then return end
  U.confirm("强行给自己学习 "..e.name.." "..(e.rank or "").."（#"..e.id.."）？将跳过职业、种族、等级、天赋和专业学习限制。技能可能依赖特定目标或条件；会保留原生学习附带的被动或关联技能效果。",function()
   A.Send("skills forcelearn player "..e.id);A.SearchSkills()
  end)
  return
 end
 if not e or (action=="learn" and (e.learnable~="1" or e.known=="1")) or (action=="forget" and e.known~="1") then return end
 local target=e.scope=="pet" and "当前宠物" or "自己"
 U.confirm((action=="learn" and "给"..target.."学习 " or "让"..target.."遗忘 ")..e.name.." "..(e.rank or "").."（#"..e.id.."）？遗忘后可能恢复较低等级技能；专业整体遗忘请使用下方专业入口。",function()
  A.Send("skills "..action.." "..e.scope.." "..e.id);A.SearchSkills()
 end)
end
function A.PaintProfession()
 local selected=professions[A.professionIndex or 1];local info=(A.professions or {})[selected[1]]
 A.professionButton:SetText(selected[2]..(info and (" "..info.value.."/"..info.max) or "（未学）"))
end
function A.BuildSkillPanel(p)
 local function edit(name,text,x,y,w)local e=U.input(p,name,text,x,y,w);table.insert(A.inputs,e);return e end
 A.skills={};A.skillScope=1;A.skillPage=1
 A.skillKindFilter=1;A.skillSchoolFilter=1;A.skillEffectFilter=1;A.skillTargetFilter=1
 p:SetHeight(417)
 A.skillSearch=edit("AzerothGMSkillSearch","",10,0,290);A.skillSearch:SetMaxLetters(80)
 A.skillSearch:SetScript("OnEnterPressed",function() A.skillPage=1;A.SearchSkills() end)
 A.skillSearch:SetScript("OnTextChanged",function() A.skills={};A.PaintSkills() end)
 A.skillScopeButton=U.button(p,"AzerothGMSkillScope","本职技能",320,3,200,function()
  A.skillScope=A.skillScope+1;if A.skillScope>table.getn(scopes) then A.skillScope=1 end
  A.skillScopeButton:SetText(scopes[A.skillScope][2]);A.skillPage=1;A.SearchSkills()
 end)
 U.button(p,"AzerothGMSkillFind","查询名称 / ID",540,3,145,function() A.skillPage=1;A.SearchSkills() end)
 U.button(p,"AzerothGMSkillRefresh","刷新角色上限",700,3,145,function() A.Send("skills status") end)
 local function filter(name,key,options,x,width)
  local b
  b=U.button(p,name,options[A[key]][2].." >",x,-31,width,function()
   A[key]=A[key]+1;if A[key]>table.getn(options) then A[key]=1 end
   b:SetText(options[A[key]][2].." >")
   if key=="skillKindFilter" and options[A[key]][1]=="teaching" then A.skillScope=5;A.skillScopeButton:SetText(scopes[5][2]) end
   A.skillPage=1;A.SearchSkills()
  end)
  return b
 end
 A.skillKindButton=filter("AzerothGMSkillKind","skillKindFilter",skillKinds,0,180)
 A.skillSchoolButton=filter("AzerothGMSkillSchool","skillSchoolFilter",skillSchools,190,175)
 A.skillEffectButton=filter("AzerothGMSkillEffectFilter","skillEffectFilter",skillEffects,375,230)
 A.skillTargetButton=filter("AzerothGMSkillTarget","skillTargetFilter",skillTargets,615,200)
 A.skillRows={}
 for i=1,6 do
  local row={};row.frame=CreateFrame("Frame","AzerothGMSkillRow"..i,p);row.frame:SetPoint("TOPLEFT",p,"TOPLEFT",0,-70-(i-1)*28);row.frame:SetWidth(850);row.frame:SetHeight(26)
  row.text=U.button(row.frame,"AzerothGMSkillText"..i,"",0,0,565,function() end);row.text:SetHeight(26)
  row.text:SetScript("OnEnter",function() A.SkillTooltip(this,this.entry) end)
  row.text:SetScript("OnLeave",function() A.HideSkillTooltip() end)
  row.text:SetScript("OnHide",function() if A.skillHoverRequest and A.skillHoverRequest.owner==this then A.HideSkillTooltip() end end)
  row.learn=U.button(row.frame,"AzerothGMSkillLearn"..i,"学习",575,0,65,function() A.ChangeSkill(row.entry,"learn") end)
  row.force=U.button(row.frame,"AzerothGMSkillForce"..i,"强行学习",645,0,85,function() A.ChangeSkill(row.entry,"forcelearn") end)
  row.forget=U.button(row.frame,"AzerothGMSkillForget"..i,"遗忘",730,0,85,function() A.ChangeSkill(row.entry,"forget") end)
  A.skillRows[i]=row;row.frame:Hide()
 end
 A.skillPaging=U.label(p,"AzerothGMSkillPaging","",0,-250,340,"GameFontHighlightSmall")
 U.button(p,"AzerothGMSkillPrev","上一页",380,-242,100,function() if A.skillPage>1 then A.skillPage=A.skillPage-1;A.SearchSkills() end end)
 U.button(p,"AzerothGMSkillNext","下一页",495,-242,100,function() if A.skillMore then A.skillPage=A.skillPage+1;A.SearchSkills() end end)
 A.skillLimits=U.label(p,"AzerothGMSkillLimits","请刷新角色上限。",0,-281,850,"GameFontHighlightSmall")
 U.label(p,nil,"天赋总点数",0,-313,95,"GameFontHighlightSmall");A.talentCap=edit("AzerothGMTalentCap","51",110,-308,55)
 U.button(p,"AzerothGMTalentSet","设置",185,-306,80,function() local n=U.integer(A.talentCap,0,300);if n then U.confirm("将本角色天赋总点数设为 "..n.."？已用点数超过目标时需先免费洗点。重登、升级和洗点后仍保留此上限；不会增加新的天赋树。",function() A.Send("skills limits talents "..n) end) end end)
 U.button(p,"AzerothGMTalentDefault","恢复默认",280,-306,105,function() U.confirm("恢复按等级和服务器倍率计算的默认天赋总点数？已用点数超过默认值时，请先免费洗点。",function() A.Send("skills limits talents default") end) end)
 U.button(p,"AzerothGMTalentReset","免费洗点",400,-306,100,function() U.confirm("清空本角色已分配的全部天赋？不扣金币，保留当前总点数设置。",function() A.Send("skills resettalents") end) end)
 U.button(p,"AzerothGMClassSpells","学习本职技能",515,-306,150,function() U.confirm("学习当前等级的角色职业、护甲与基础武器技能？不学习天赋，不把宠物技能学到角色身上。",function() A.Send("classspells") end) end)
 U.button(p,"AzerothGMDemonSpells","学习当前恶魔技能",680,-306,165,function() U.confirm("为当前召唤的术士恶魔学习符合种类和等级的技能，并保存、刷新技能栏？不会给角色学习宠物技能。",function() A.Send("skills petall") end) end)
 A.professionIndex=1
 A.professionButton=U.button(p,"AzerothGMProfession","专业：炼金术",0,-350,170,function() A.professionIndex=A.professionIndex+1;if A.professionIndex>table.getn(professions) then A.professionIndex=1 end;A.PaintProfession() end)
 U.button(p,"AzerothGMProfessionLearn","学习初级",185,-350,100,function() local e=professions[A.professionIndex];U.confirm("学习初级"..e[2].."（入门熟练度）？不会自动满级或赠送全部配方。",function() A.Send("skills profession learn "..e[1]) end) end)
 U.button(p,"AzerothGMProfessionForget","遗忘专业",300,-350,100,function() local e=professions[A.professionIndex];U.confirm("遗忘"..e[2].."？熟练度和相关配方将丢失，相关专业任务按游戏原生遗忘流程清理。",function() A.Send("skills profession forget "..e[1]) end) end)
 U.label(p,nil,"主要专业上限",415,-357,120,"GameFontHighlightSmall");A.professionCap=edit("AzerothGMProfessionCap","9",545,-352,40)
 U.button(p,"AzerothGMProfessionSet","设置",600,-350,75,function() local n=U.integer(A.professionCap,1,9);if n then U.confirm("将本角色主要专业上限设为 "..n.."？烹饪、急救和钓鱼不占名额。",function() A.Send("skills limits professions "..n) end) end end)
 U.button(p,"AzerothGMProfessionDefault","恢复默认",690,-350,125,function() U.confirm("恢复服务器默认专业上限？需先自行遗忘超出名额的专业。",function() A.Send("skills limits professions default") end) end)
 U.button(p,"AzerothGMProfessionMax","所选专业升至300",0,-390,160,function()
  local e=professions[A.professionIndex];U.confirm("将已学的"..e[2].."提升到1.12大师级300/300？这是GM快捷操作，跳过训练费用与升阶任务；不额外批量学习配方。要求角色35级以上。",function() A.Send("skills profession max "..e[1]) end)
 end)
 U.button(p,"AzerothGMProfessionMaxAll","已学专业全满300",170,-390,160,function()
  U.confirm("将本角色所有已学主要专业及烹饪、急救、钓鱼提升至300/300？未学的专业不新增；不额外批量学习配方。要求角色35级以上。",function() A.Send("skills profession max all") end)
 end)
 U.button(p,"AzerothGMCleanupPreview","查询误学技能",340,-390,150,function()
  A.skillSchoolFilter=1;A.skillEffectFilter=1;A.skillTargetFilter=1;A.skillSchoolButton:SetText(skillSchools[1][2].." >");A.skillEffectButton:SetText(skillEffects[1][2].." >");A.skillTargetButton:SetText(skillTargets[1][2].." >");A.skillKindFilter=3;A.skillKindButton:SetText(skillKinds[3][2].." >");A.skillScope=6;A.skillScopeButton:SetText(scopes[6][2]);A.skillSearch:SetText("");A.skillPage=1;A.skills={};A.skillsFinished=false;A.PaintSkills();A.Send("skills cleanup preview")
 end)
 U.button(p,"AzerothGMCleanupConfirm","清理误学技能",500,-390,150,function()
  if not A.cleanCount then A.Log("请先查询误学宠物技能，检查清理范围。");return end
  if A.cleanCount==0 then A.Log("没有查到需要清理的误学宠物技能。");return end
  U.confirm("清理角色身上查到的 "..A.cleanCount.." 条误学恶魔技能，并补齐当前等级的术士本职技能？当前恶魔技能单独保留；请先退出战斗、战场和队列。",function() A.Send("skills cleanup confirm");A.SearchSkills() end)
 end)
 U.button(p,"AzerothGMRegenInspect","恢复状态",660,-390,165,function() A.Send("skills inspect") end)
 A.PaintSkills()
end
