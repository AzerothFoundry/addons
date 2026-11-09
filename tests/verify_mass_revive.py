from pathlib import Path
import subprocess,os
root=Path(__file__).resolve().parents[1]
checks=[
'''GMCommands={};AzerothGM.Send=function(c) table.insert(GMCommands,".gmui "..c) end;AzerothGM.Toggle();AzerothGM.ShowTab(4);assert(AzerothGMMassRevive:IsVisible());AzerothGM.RequestMassRevive();assert(GMCommands[table.getn(GMCommands)]==".gmui raidtools revive preview");local n=table.getn(GMCommands);AzerothGM.HandleMessage("GMUI|MASSREVIVE|eligible=4|bots=4|players=0|skipped=0|map=389|instance=105");assert(table.getn(GMCommands)==n);StaticPopup1Button2:Click();assert(table.getn(GMCommands)==n);return "visible button previews only; cancellation never resurrects"''',
'''AzerothGM.RequestMassRevive();AzerothGM.HandleMessage("GMUI|MASSREVIVE|eligible=4|bots=3|players=1|skipped=2|map=389|instance=105");StaticPopup1Button1:Click();assert(GMCommands[table.getn(GMCommands)]==".gmui raidtools revive confirm 389 105");AzerothGM.HandleMessage("GMUI|MASSREVIVERESULT|bots=3|players=1|skipped=2");assert(string.find(AzerothGM.logs[table.getn(AzerothGM.logs)],"真人复活请求 1",1,true));return "explicit confirmation binds instance and distinguishes offers from revivals"''',
'''AzerothGM.RequestMassRevive();local n=table.getn(GMCommands);AzerothGM.HandleMessage("GMUI|MASSREVIVE|eligible=0|bots=0|players=0|skipped=4|map=389|instance=105");assert(table.getn(GMCommands)==n);assert(string.find(AzerothGM.logs[table.getn(AzerothGM.logs)],"没有可复活",1,true));return "no eligible members does not send confirm"''',
]
checks += ['AzerothGMMassRevive:Click();assert(GMCommands[table.getn(GMCommands)]==".gmui raidtools revive now");local n=table.getn(GMCommands);AzerothGM.MassReviveNow();assert(table.getn(GMCommands)==n+1 and GMCommands[n+1]==".gmui raidtools revive now");return "button and macro helper send immediate revival without preview"']
a=[os.environ['ADDON_HARNESS'],str(root/'AddOns'),'--probe','AzerothGM']
for c in checks:a+=['--eval',c]
r=subprocess.run(a,env=dict(os.environ,WOW_DATA=os.environ['WOW_DATA']),capture_output=True,text=True,timeout=60);s=r.stdout+r.stderr;Path('/tmp/mass-revive-ui.log').write_text(s);print(s)
assert r.returncode==0 and 'load errors: 0' in s and 'session errors: 0' in s and 'ERROR:' not in s and 'SYNTAX:' not in s
