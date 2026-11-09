local A=AzerothGM
local U=A.UI
local groups={{"common","通用 / 防护"},{"tank","坦克"},{"physical","物理输出"},{"caster","法系输出"},{"healer","治疗"},{"mc","MC灭火"}}
-- IDs and unique limits checked against this realm's native 1.12.1 templates.
-- Role lists are convenient choices, not a claim that every effect stacks.
local catalog={
 common={{13446,"特效治疗药水","恢复生命"},{13444,"特效法力药水","有蓝职业恢复法力"},{18253,"特效活力药水","恢复生命和法力"},{3387,"有限无敌药水","短时物理伤害免疫；不是全伤害无敌"},{5634,"自由行动药剂","预防昏迷、减速等移动限制；不是万能解控"},{9030,"滋补药剂","周期移除部分负面效果"},{13457,"强效火焰防护药水","吸收火焰伤害"},{13459,"强效暗影防护药水","吸收暗影伤害"},{13458,"强效自然防护药水","吸收自然伤害"},{13456,"强效冰霜防护药水","吸收冰霜伤害"},{13461,"强效奥术防护药水","吸收奥术伤害"},{13513,"多重抗性合剂","提高魔法抗性"},{20080,"赞扎之光","反射法术效果；唯一物品",1},{20081,"赞扎之速","提高移动速度；唯一物品",1}},
 tank={{13510,"泰坦合剂","提高生命上限"},{21023,"迪尔格的超美味奇美拉肉片","耐力食物"},{20079,"赞扎之魂","提高耐力和精神；唯一物品",1},{13452,"猫鼬药剂","敏捷与暴击"},{12451,"魂能之力","力量增益"},{12460,"魂能之击","攻击强度增益"},{12404,"致密磨刀石","适用近战武器；与其它临时武器效果取舍"},{18262,"元素磨刀石","适用武器的暴击临时效果"}},
 physical={{13452,"猫鼬药剂","敏捷与暴击"},{9206,"巨人药剂","力量增益"},{12451,"魂能之力","力量增益；注意同类效果取舍"},{12460,"魂能之击","攻击强度增益"},{13928,"烤鱿鱼","敏捷食物"},{20452,"沙漠肉丸子","力量食物"},{18262,"元素磨刀石","适用武器暴击效果"},{12404,"致密磨刀石","适用近战武器伤害效果"},{21023,"迪尔格的超美味奇美拉肉片","需要生存时可选耐力食物"}},
 caster={{13512,"超级能量合剂","法术伤害"},{20749,"卓越巫师之油","法伤与法术暴击；占临时武器效果"},{13454,"强效奥法药剂","法术伤害"},{9264,"暗影之力药剂","暗影法术伤害"},{21546,"强效火力药剂","火焰法术伤害"},{9179,"强效聪颖药剂","智力"},{18254,"洛恩塔姆薯块","智力食物"},{13511,"精炼智慧合剂","需要法力上限时可选"},{13444,"特效法力药水","恢复法力"}},
 healer={{13511,"精炼智慧合剂","提高法力上限"},{20748,"卓越法力之油","法力回复与治疗；占临时武器效果"},{13931,"夜鳞鱼汤","法力回复食物"},{18254,"洛恩塔姆薯块","智力食物"},{13447,"先知药剂","智力与精神"},{9179,"强效聪颖药剂","智力；注意同类效果取舍"},{20079,"赞扎之魂","耐力和精神；唯一物品",1},{13444,"特效法力药水","恢复法力"},{18253,"特效活力药水","恢复生命和法力"}},
 mc={{17333,"水之精萃","MC符文灭火；使用消耗，唯一物品",1},{22754,"永恒精萃","MC符文灭火；可重复用，原生1小时冷却",1}},
}
A.raidConsumableCatalog=catalog
function A.PaintRaidConsumables()
 if not A.raidConsumableRows then return end
 local group=groups[A.raidConsumableGroup or 1];local items=catalog[group[1]];local page=A.raidConsumablePage or 1
 A.raidConsumableRole:SetText("用途："..group[2].." >")
 for i,row in ipairs(A.raidConsumableRows) do
  local e=items[(page-1)*8+i];row.button.entry=e
  if e then row.button:SetText(e[2].."  #"..e[1]..(e[4] and " ×1" or ""));row.hint:SetText(e[3]);row.frame:Show() else row.frame:Hide() end
 end
 A.raidConsumablePaging:SetText("第"..page.." / "..math.max(1,math.ceil(table.getn(items)/8)).."页 · "..table.getn(items).."项")
end
function A.BuildRaidConsumables(parent)
 local p=CreateFrame("Frame","AzerothGMRaidConsumables",parent);A.raidConsumableFrame=p;p:SetPoint("TOPLEFT",parent,"TOPLEFT",0,-35);p:SetWidth(870);p:SetHeight(385)
 A.raidConsumableRole=U.button(p,"AzerothGMRaidConsumableRole","",0,0,265,function() A.raidConsumableGroup=(A.raidConsumableGroup or 1)+1;if A.raidConsumableGroup>table.getn(groups) then A.raidConsumableGroup=1 end;A.raidConsumablePage=1;A.PaintRaidConsumables() end)
 U.label(p,nil,"领取数量（件）",290,-8,150,"GameFontHighlightSmall")
 A.raidConsumableQuantity=U.input(p,"AzerothGMRaidConsumableQuantity","20",440,-3,90);table.insert(A.inputs,A.raidConsumableQuantity)
 A.raidConsumableQuantity:SetScript("OnEnter",function() GameTooltip:SetOwner(this,"ANCHOR_RIGHT");GameTooltip:SetText("每次1–100000件；唯一物品固定1件。背包容量及唯一限制仍由服务器检查。");GameTooltip:Show() end)
 A.raidConsumableQuantity:SetScript("OnLeave",function() GameTooltip:Hide() end)
 U.label(p,nil,"点击领取；悬停看原生物品说明。职责分类仅供选择，不代表所有增益可叠加。",0,-39,850,"GameFontHighlightSmall")
 A.raidConsumableRows={};A.raidConsumableGroup=1;A.raidConsumablePage=1
 for i=1,8 do local row={};row.frame=CreateFrame("Frame","AzerothGMRaidConsumableRow"..i,p);row.frame:SetPoint("TOPLEFT",p,"TOPLEFT",math.mod(i-1,2)*435,-67-math.floor((i-1)/2)*65);row.frame:SetWidth(425);row.frame:SetHeight(60)
  row.button=U.button(row.frame,"AzerothGMRaidConsumableItem"..i,"",0,0,420,function() local e=this.entry;if not e then return end;local n=e[4] or U.integer(A.raidConsumableQuantity,1,100000);if n then A.Send("item "..e[1].." "..n) end end)
  row.button:SetScript("OnEnter",function() if this.entry then A.ItemTooltip(this,{id=tostring(this.entry[1]),name=this.entry[2]}) end end)
  row.button:SetScript("OnLeave",function() GameTooltip:Hide() end)
  row.hint=U.label(row.frame,nil,"",0,-31,420,"GameFontHighlightSmall");A.raidConsumableRows[i]=row
 end
 A.raidConsumablePaging=U.label(p,"AzerothGMRaidConsumablePaging","",0,-337,260,"GameFontHighlightSmall")
 U.button(p,"AzerothGMRaidConsumablePrev","上一页",290,-330,110,function() if A.raidConsumablePage>1 then A.raidConsumablePage=A.raidConsumablePage-1;A.PaintRaidConsumables() end end)
 U.button(p,"AzerothGMRaidConsumableNext","下一页",420,-330,110,function() local list=catalog[groups[A.raidConsumableGroup][1]];if A.raidConsumablePage*8<table.getn(list) then A.raidConsumablePage=A.raidConsumablePage+1;A.PaintRaidConsumables() end end)
 A.PaintRaidConsumables()
end
