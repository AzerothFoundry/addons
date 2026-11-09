from pathlib import Path
import subprocess,os
root=Path(__file__).resolve().parents[1]
setup=r'''
local A=AzerothConvenience
Inv={};Held=nil;Calls={};Money=0;Cost=100;Combat=false;Clock=0;Shift=false
Defs={ [1]={"布",1,"材料","布",20},[2]={"剑",3,"武器","剑",1},[3]={"垃圾",0,"杂物","垃圾",20},[4500]={"旅行者的背包",1,"容器","袋",1},[21340]={"灵魂袋",1,"容器","灵魂袋",1} }
BagLinks={[1]="item:4500",[2]="item:21340"}
GetContainerNumSlots=function(b) return b==0 and 6 or b==1 and 4 or b==2 and 2 or 0 end
ContainerIDToInventoryID=function(b) return b end
GetInventoryItemLink=function(unit,b) return BagLinks[b] end
GetItemInfo=function(link) local id=tonumber(type(link)=="number" and link or string.gsub(link,".*item:(%d+).*","%1"));local d=Defs[id];if not d then return end;return d[1],"item:"..id,d[2],1,d[3],d[4],d[5] end
GetContainerItemLink=function(b,s) local e=Inv[b..":"..s];return e and "item:"..e.id end
GetContainerItemInfo=function(b,s) local e=Inv[b..":"..s];if e then return "texture",e.n,e.locked,e.q end end
CursorHasItem=function() return Held and 1 or nil end
UnitAffectingCombat=function() return Combat end
PickupContainerItem=function(b,s)
 local k=b..":"..s;local e=Inv[k]
 if not Held then Held=e;Inv[k]=nil
 elseif e and e.id==Held.id and e.n<Defs[e.id][5] then local n=math.min(Held.n,Defs[e.id][5]-e.n);e.n=e.n+n;Held.n=Held.n-n;if Held.n==0 then Held=nil end
 else Inv[k]=Held;Held=e end
 table.insert(Calls,"pickup")
end
MerchantFrame=MerchantFrame or CreateFrame("Frame","MerchantFrame",UIParent);MerchantFrame:Hide()
CanMerchantRepair=function() return true end
GetRepairAllCost=function() return Cost,Cost>0 end
GetMoney=function() return Money end
RepairAllItems=function() table.insert(Calls,"repair");if Money>=Cost then Money=Money-Cost;Cost=0 end end
UseContainerItem=function(b,s) local e=Inv[b..":"..s];assert(e and Defs[e.id][2]==0,"non-grey sale");Inv[b..":"..s]=nil;Money=Money+100;table.insert(Calls,"sell") end
IsShiftKeyDown=function() return Shift end
function TickSort(n) for i=1,n do A.SortStep(.2) end end
return "inventory fixture installed"
'''
checks=[setup,
'''Inv={["0:1"]={id=1,n=7},["0:2"]={id=2,n=1},["0:3"]={id=1,n=18},["0:5"]={id=3,n=1},["2:1"]={id=1,n=9}};Calls={};AzerothConvenience.StartSort();TickSort(80);assert(not AzerothConvenience.sort and not Held);assert(Inv["0:1"].id==2);assert(Inv["0:2"].id==1 and Inv["0:2"].n==20);assert(Inv["0:3"].id==1 and Inv["0:3"].n==5);assert(Inv["0:4"].id==3);assert(Inv["0:5"]==nil and Inv["2:1"].n==9);return "merge partial stacks, quality/type sorting, compaction, special bag skipped"''',
'''Held={id=2,n=1};local n=table.getn(Calls);AzerothConvenience.StartSort();assert(not AzerothConvenience.sort and Held.id==2 and table.getn(Calls)==n);Held=nil;Combat=true;AzerothConvenience.StartSort();assert(not AzerothConvenience.sort);Combat=false;return "user cursor and combat prevent sort without item changes"''',
'''Inv={["0:1"]={id=99,n=1}};Calls={};AzerothConvenience.StartSort();TickSort(60);assert(not AzerothConvenience.sort and table.getn(Calls)==0);return "missing item cache waits then stops without guessing"''',
'''Inv={["0:1"]={id=3,n=1},["0:2"]={id=2,n=1},["0:3"]={id=3,n=2}};Calls={};Money=0;Cost=100;MerchantFrame:Show();AzerothConvenience.visit={skip=false,sold=0,blocked={},age=0,pendingAge=0};AzerothConvenience.MerchantStep();assert(table.getn(Calls)==1 and Calls[1]=="sell");for i=1,10 do local v=AzerothConvenience.visit;v.age=v.age+.4;v.pendingAge=v.pendingAge+.4;AzerothConvenience.MerchantStep() end;assert(Inv["0:2"].id==2 and Cost==0);assert(AzerothConvenience.visit.sold==2 and AzerothConvenience.visit.repaired);return "one sale per step, non-grey preserved, repair after sale acknowledgement and funds"''',
'''Calls={};Money=0;Cost=100;Inv={};AzerothConvenience.visit={skip=false,sold=0,blocked={},age=0,pendingAge=0};AzerothConvenience.MerchantStep();assert(table.getn(Calls)==0 and AzerothConvenience.visit.noMoney);AzerothConvenience.visit.skip=true;Inv={["0:1"]={id=3,n=1}};AzerothConvenience.MerchantStep();assert(Inv["0:1"] and table.getn(Calls)==0);MerchantFrame:Hide();return "no money does not repair; Shift visit suppresses both operations"''',
'''Inv={["0:1"]={id=3,n=1},["0:2"]={id=2,n=1}};Calls={};AzerothConvenience.StartSort();Combat=true;TickSort(1);assert(not AzerothConvenience.sort and table.getn(Calls)==0);Combat=false;Bagnon=CreateFrame("Frame","Bagnon",UIParent);AzerothConvenience.AttachSortButton();assert(AzerothConvenienceSort:GetText()=="整理");return "combat interrupts before transaction; Bagnon sort button attached"''',
'''MerchantFrame:Show();Inv={["0:1"]={id=99,n=1}};Calls={};AzerothConvenience.visit={skip=false,sold=0,blocked={},age=0,pendingAge=0};AzerothConvenience.MerchantStep();assert(table.getn(Calls)==0);Defs[99]={"迟到垃圾",0,"杂物","垃圾",1};AzerothConvenience.MerchantStep();assert(Calls[1]=="sell");return "merchant waits for uncached quality rather than selling unknown item"''',
]
checks += [r'''
MerchantFrame:Hide();Inv={["0:1"]={id=3,n=1},["0:2"]={id=2,n=1}};Held=nil;Calls={};
local original=PickupContainerItem;local captured={};PickupContainerItem=function(b,s) original(b,s);table.insert(captured,b..":"..s) end
AzerothConvenience.StartSort();TickSort(1);assert(AzerothConvenience.sort and AzerothConvenience.sort.pending and not Held)
Inv["0:1"].locked=true;local n=table.getn(Calls);TickSort(5);assert(table.getn(Calls)==n and AzerothConvenience.sort)
Inv["0:1"].locked=nil;TickSort(10);assert(not AzerothConvenience.sort and Inv["0:1"].id==2)
PickupContainerItem=original;return "server item lock prevents a second transaction until acknowledgement"
''',r'''
MerchantFrame:Show();Inv={["0:1"]={id=3,n=1},["0:2"]={id=3,n=1}};Calls={};Cost=0
local original=UseContainerItem;UseContainerItem=function(b,s) table.insert(Calls,"request");Inv[b..":"..s].locked=true end
AzerothConvenience.visit={skip=false,sold=0,blocked={},age=0,pendingAge=0};AzerothConvenience.MerchantStep();assert(table.getn(Calls)==1)
for i=1,5 do AzerothConvenience.visit.pendingAge=i*.2;AzerothConvenience.MerchantStep() end;assert(table.getn(Calls)==1)
Inv["0:1"]=nil;AzerothConvenience.MerchantStep();assert(table.getn(Calls)==2 and AzerothConvenience.visit.sold==1)
UseContainerItem=original;return "merchant serializes locked asynchronous sale acknowledgements"
''']
checks += [r'''
MerchantFrame:Hide();local bag=Defs[4500];Defs[4500]=nil;BAGNON_ITEMTYPE_CONTAINER="容器";BAGNON_SUBTYPE_BAG="袋";BagLinks[1]="item:4";Defs[4]={"普通小包",1,"容器","袋",1};Inv={["1:2"]={id=2,n=1},["2:1"]={id=1,n=9}};Calls={};AzerothConvenience.StartSort();TickSort(60);assert(not AzerothConvenience.sort and Inv["0:1"].id==2 and Inv["2:1"].n==9);Defs[4500]=bag;BagLinks[1]="item:4500";return "uncached reference bag uses actual Bagnon localized ordinary-bag constants"
''']
checks += [r'''
MerchantFrame:Hide();Inv={["0:1"]={id=3,n=1},["0:2"]={id=2,n=1}};Held=nil;Calls={};local original=PickupContainerItem;local source
PickupContainerItem=function(b,s) local k=b..":"..s;if not Held then Held=Inv[k];source=k else local dest=Inv[k];Inv[k]=Held;Inv[source]=dest;Held=nil;source=nil end;table.insert(Calls,"native_swap") end
AzerothConvenience.StartSort();TickSort(20);assert(not AzerothConvenience.sort and Inv["0:1"].id==2 and Inv["0:2"].id==3 and not Held);assert(table.getn(Calls)==2);PickupContainerItem=original;return "native atomic swap clears cursor and does not pick the source up again"
''']
checks += [r'''
MerchantFrame:Hide();Inv={["0:1"]={id=2,n=1}};Held=nil;Calls={};CursorHasSpell=function() return 1 end;AzerothConvenience.StartSort();assert(not AzerothConvenience.sort and table.getn(Calls)==0);CursorHasSpell=function() return nil end;SpellIsTargeting=function() return 1 end;AzerothConvenience.StartSort();assert(not AzerothConvenience.sort);MerchantFrame:Show();Inv={["0:1"]={id=3,n=1}};AzerothConvenience.visit={skip=false,sold=0,blocked={},age=0,pendingAge=0};AzerothConvenience.MerchantStep();assert(table.getn(Calls)==0);SpellIsTargeting=function() return nil end;return "spell-targeting cursor is preserved and cannot act on inventory"
''']
checks += [r'''
SpellIsTargeting=function() return nil end;MerchantFrame:Hide();Inv={["0:1"]={id=3,n=1},["0:2"]={id=2,n=1}};Calls={};Held=nil;AzerothConvenience.ShowOptions();assert(string.find(AzerothConvenienceTitle:GetText(),"0.2.1",1,true));assert(string.find(AzerothConvenienceRules:GetText(),"炉石最前",1,true));AzerothConveniencePanelSort:Click();assert(AzerothConvenience.sort);assert(string.find(AzerothConvenienceStatus:GetText(),"开始整理",1,true));AzerothConveniencePanelSort:Click();assert(not AzerothConvenience.sort);assert(string.find(AzerothConvenienceStatus:GetText(),"已停止",1,true));SlashCmdList["AZEROTHCONVENIENCE"]("  SoRt  ");assert(AzerothConvenience.sort);TickSort(30);assert(not AzerothConvenience.sort and Inv["0:1"].id==2);assert(string.find(AzerothConvenienceStatus:GetText(),"整理完成",1,true));return "visible version/rules/status and GUI sort stop; whitespace/case slash starts actual sorting"
''']
checks += [r'''
MerchantFrame:Hide();Defs[6948]={"炉石",1,"杂物","杂物",1};Defs[5]={"橙装",5,"护甲","板甲",1};Defs[6]={"紫装",4,"武器","剑",1};Defs[7]={"蓝装",3,"护甲","布甲",1};Defs[8]={"药水",0,"消耗品","药水",1};Defs[9]={"任务信",5,"任务","任务",1};Defs[10]={"稀有材料",5,"材料","材料",1};
Inv={["0:1"]={id=10,n=1},["0:2"]={id=9,n=1},["0:3"]={id=8,n=1},["0:4"]={id=7,n=1},["0:5"]={id=6,n=1},["0:6"]={id=5,n=1},["1:1"]={id=6948,n=1}};Held=nil;Calls={};AzerothConvenience.StartSort();TickSort(100);assert(not AzerothConvenience.sort);local order={6948,5,6,7,8,9};for i,id in ipairs(order) do assert(Inv["0:"..i].id==id,"category order") end;assert(Inv["1:1"].id==10);local n=0;AutoQuest={ShowOptions=function() n=n+1 end};AzerothConvenience.ShowOptions();AzerothConvenienceQuestOptions:Click();assert(n==1);return "hearthstone first, equipment orange-purple-blue, then consumables quests others; visible quest settings entry"
''']
args=[os.environ['ADDON_HARNESS'],str(root/'AddOns'),'--probe','AzerothConvenience']
for check in checks:args+=['--eval',check]
r=subprocess.run(args,env=dict(os.environ,WOW_DATA=os.environ['WOW_DATA']),capture_output=True,text=True,timeout=60)
text=r.stdout+r.stderr;print(text);(root/'tests/convenience-validation.log').write_text(text)
assert r.returncode==0 and 'load errors: 0' in text and 'session errors: 0' in text and 'ERROR:' not in text
