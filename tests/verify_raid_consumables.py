from pathlib import Path
import os,subprocess,json,re
root=Path(__file__).resolve().parents[1]
source=(root/'AddOns/AzerothGM/RaidConsumables.lua').read_text()
proof=json.loads((root/'research/副本消耗品目录/native-items.json').read_text());items={int(r['entry']):r for r in sorted(proof['items'],key=lambda r:int(r['patch']))}
ids=set(map(int,re.findall(r'\{(\d+),"',source)))
assert len(ids)>=35 and ids<=set(items),ids-set(items)
for id in [17333,22754,20079,20080,20081]:assert int(items[id]['max_count'])==1
checks=[
'''GMCommands={};AzerothGM.Send=function(c) table.insert(GMCommands,".gmui "..c) end;AzerothGM.Toggle();AzerothGM.ShowTab(7);AzerothGMItemView4:Click();assert(AzerothGM.itemView=="raidconsumables" and AzerothGMRaidConsumableRole:IsVisible());assert(string.find(AzerothGMTitle:GetText(),"0.6.10",1,true));AzerothGMRaidConsumableItem1:Click();assert(GMCommands[table.getn(GMCommands)]==".gmui item 13446 20");return "visible raid submenu default common and quantity20"''',
'''AzerothGMRaidConsumableQuantity:SetText("100000");AzerothGMRaidConsumableItem1:Click();assert(GMCommands[table.getn(GMCommands)]==".gmui item 13446 100000");local n=table.getn(GMCommands);AzerothGMRaidConsumableQuantity:SetText("100001");AzerothGMRaidConsumableItem1:Click();assert(table.getn(GMCommands)==n);AzerothGMRaidConsumableQuantity:SetText("0");AzerothGMRaidConsumableItem1:Click();assert(table.getn(GMCommands)==n);AzerothGMRaidConsumableQuantity:SetText("20");return "quantity1..100000 checked on explicit click"''',
'''AzerothGMRaidConsumableNext:Click();assert(AzerothGM.raidConsumablePage==2);AzerothGMRaidConsumableItem5:Click();assert(GMCommands[table.getn(GMCommands)]==".gmui item 20080 1");AzerothGMRaidConsumableRole:Click();assert(AzerothGM.raidConsumablePage==1);assert(string.find(AzerothGMRaidConsumableRole:GetText(),"坦克",1,true));AzerothGMRaidConsumableItem1:Click();assert(GMCommands[table.getn(GMCommands)]==".gmui item 13510 20");return "paging and unique Zanza singleton; role switch resets page"''',
'''AzerothGMRaidConsumableRole:Click();assert(string.find(AzerothGMRaidConsumableRole:GetText(),"物理",1,true));AzerothGMRaidConsumableRole:Click();AzerothGMRaidConsumableItem1:Click();assert(GMCommands[table.getn(GMCommands)]==".gmui item 13512 20");AzerothGMRaidConsumableRole:Click();AzerothGMRaidConsumableItem2:Click();assert(GMCommands[table.getn(GMCommands)]==".gmui item 20748 20");AzerothGMRaidConsumableRole:Click();AzerothGMRaidConsumableQuantity:SetText("100000");AzerothGMRaidConsumableItem1:Click();assert(GMCommands[table.getn(GMCommands)]==".gmui item 17333 1");AzerothGMRaidConsumableItem2:Click();assert(GMCommands[table.getn(GMCommands)]==".gmui item 22754 1");assert(AzerothGMRaidConsumableItem3:IsVisible()~=1);return "caster/healer differentiated choices and both MC essences singleton"''',
'''local n=0;local old=AzerothGM.ItemTooltip;AzerothGM.ItemTooltip=function(owner,e) n=tonumber(e.id) end;this=AzerothGMRaidConsumableItem2;AzerothGMRaidConsumableItem2:GetScript("OnEnter")();assert(n==22754);AzerothGM.ItemTooltip=old;AzerothGM.ShowItemView("supplies");AzerothGM.supplyClassIndex=8;AzerothGM.PaintSupplies();AzerothGMSupplyQuantity:SetText("100000");AzerothGMSupplyItem1:Click();assert(GMCommands[table.getn(GMCommands)]==".gmui item 6265 100000");AzerothGM.supplyClassIndex=4;AzerothGM.PaintSupplies();AzerothGMSupplyItem3:Click();assert(GMCommands[table.getn(GMCommands)]==".gmui item 5060 1");assert(AzerothGMRaidConsumableRole:IsVisible()~=1);return "native tooltip route, class materials100000, rogue tool singleton, submenu visibility"''',
]
args=[os.environ['ADDON_HARNESS'],str(root/'AddOns'),'--probe','AzerothGM']
for c in checks:args+=['--eval',c]
r=subprocess.run(args,env=dict(os.environ,WOW_DATA=os.environ['WOW_DATA']),capture_output=True,text=True,timeout=60)
text=r.stdout+r.stderr;(root/'tests/raid-consumables-validation.log').write_text(text);print(text)
assert r.returncode==0 and 'load errors: 0' in text and 'session errors: 0' in text and 'ERROR:' not in text
print('PASS native catalog IDs',len(ids),'and 5 actual Lua UI checks')
