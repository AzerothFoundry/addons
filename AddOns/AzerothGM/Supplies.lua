local A=AzerothGM
local U=A.UI
local classes={{1,"战士"},{2,"圣骑士"},{3,"猎人"},{4,"盗贼"},{5,"牧师"},{7,"萨满"},{8,"法师"},{9,"术士"},{11,"德鲁伊"}}
local kits={
 [1]={},
 [2]={{21177,"王者印记"},{17033,"神圣符印"}},
 [3]={{18042,"瑟银箭（52级）"},{15997,"瑟银弹（52级）"}},
 [4]={{5140,"闪光粉"},{5530,"致盲粉"},{5060,"盗贼工具",1}},
 [5]={{17028,"圣洁蜡烛"},{17029,"神圣蜡烛"},{17056,"轻羽毛"}},
 [7]={{17030,"十字章（复生材料）"},{17057,"闪亮的鱼鳞"},{17058,"鱼油"}},
 [8]={{17020,"魔粉"},{17031,"传送符文"},{17032,"传送门符文"},{17056,"轻羽毛"}},
 [9]={{6265,"灵魂碎片（每片占一格）"},{5565,"地狱火石"},{16583,"恶魔雕像"}},
 [11]={{17021,"野生浆果"},{17026,"野生棘根草"},{17034,"枫树种子"},{17035,"荆棘种子"},{17036,"白蜡树种子"},{17037,"角树种子"},{17038,"铁木种子"}},
}
function A.PaintSupplies()
 if not A.supplyClassButton then return end
 if not A.supplyClassIndex then
  A.supplyClassIndex=8
  for i,c in ipairs(classes) do if c[1]==tonumber(A.status.class) then A.supplyClassIndex=i end end
 end
 local cls=classes[A.supplyClassIndex];A.supplyClassButton:SetText("职业材料："..cls[2])
 local items=kits[cls[1]] or {}
 for i,b in ipairs(A.supplyRows) do
  b.item=items[i]
  if b.item then b:SetText(b.item[2].."  #"..b.item[1]);b:Show() else b:Hide() end
 end
 A.supplyHint:SetText(table.getn(items)==0 and "战士没有通用施法材料，可领取上方食水。" or "点击材料直接领取。灵魂碎片不堆叠，请留足普通背包或灵魂袋空间；盗贼工具每次只领1件。")
end
function A.BuildSupplyPanel(parent)
 local p=CreateFrame("Frame","AzerothGMSupplies",parent);A.supplyFrame=p;p:SetPoint("TOPLEFT",parent,"TOPLEFT",0,-35);p:SetWidth(870);p:SetHeight(345)
 U.label(p,nil,"法师食水：所有职业可领取；自动选择当前等级可以使用的最高档。",0,0,840,"GameFontHighlightSmall")
 U.button(p,"AzerothGMSupplyFood","领取法师面包 ×20",0,-30,230,function() A.Send("supplies food") end)
 U.button(p,"AzerothGMSupplyWater","领取法师饮水 ×20",250,-30,230,function() A.Send("supplies water") end)
 A.supplyClassButton=U.button(p,"AzerothGMSupplyClass","",0,-78,270,function() A.supplyClassIndex=(A.supplyClassIndex or 1)+1;if A.supplyClassIndex>table.getn(classes) then A.supplyClassIndex=1 end;A.PaintSupplies() end)
 U.label(p,nil,"每次领取数量",310,-85,130,"GameFontHighlightSmall")
 A.supplyQuantity=U.input(p,"AzerothGMSupplyQuantity","20",450,-81,90);table.insert(A.inputs,A.supplyQuantity)
 A.supplyQuantity:SetScript("OnEnter",function() GameTooltip:SetOwner(this,"ANCHOR_RIGHT");GameTooltip:SetText("材料每次1–100000件；盗贼工具固定1件。非堆叠物品占用大量空间，服务器仍检查容量。");GameTooltip:Show() end)
 A.supplyQuantity:SetScript("OnLeave",function() GameTooltip:Hide() end)
 A.supplyRows={}
 for i=1,8 do
  local b=U.button(p,"AzerothGMSupplyItem"..i,"",math.mod(i-1,2)*425,-120-math.floor((i-1)/2)*40,410,function()
   local item=this.item;if not item then return end
   local n=item[3] or U.integer(A.supplyQuantity,1,100000);if n then A.Send("item "..item[1].." "..n) end
  end)
  A.supplyRows[i]=b
 end
 A.supplyHint=U.label(p,"AzerothGMSupplyHint","",0,-296,840,"GameFontHighlightSmall")
 A.PaintSupplies()
end
