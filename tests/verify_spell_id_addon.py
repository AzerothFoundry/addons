from pathlib import Path
import os
import subprocess

root = Path(__file__).resolve().parents[1]
checks = [
    'AzerothSpellIDNames={["暗影箭\\001等级 1"]={686},["Shadow Bolt\\001Rank 1"]={686},["Lash of Pain\\001Rank 1"]={7814}}; return "minimal authored lookup fixture; no extracted database"',
    'assert(GetLocale()=="zhCN"); assert(AzerothSpellID); local ids=AzerothSpellID.Resolve("暗影箭","等级 1"); assert(ids); local found=false; for _,id in ipairs(ids) do if id==686 then found=true end end; assert(found); return "Chinese exact name and rank lookup"',
    'local ids=AzerothSpellID.Resolve("Shadow Bolt","Rank 1"); assert(ids and table.getn(ids)>0); assert(not AzerothSpellID.Resolve("Shadow Bolt","Rank 999")); assert(not AzerothSpellID.Resolve("not a spell","")); return "English rank matching; unknown ranks never guessed"',
    'CapturedIDLines={}; SavedIDAddLine=GameTooltip.AddLine; GameTooltip.AddLine=function(self,text,r,g,b) table.insert(CapturedIDLines,text); return SavedIDAddLine(self,text,r,g,b) end; return "capture appended lines while retaining native tooltip methods"',
    'SavedSpellName=GetSpellName; GetSpellName=function(slot,book) if book=="pet" then return "Lash of Pain","Rank 1" else return "Shadow Bolt","Rank 1" end end; GameTooltip:ClearLines(); GameTooltip:SetSpell(1,"pet"); local text=CapturedIDLines[table.getn(CapturedIDLines)] or ""; assert(string.find(text,"宠物技能 ID",1,true) and string.find(text,"7814",1,true)); GameTooltip:ClearLines(); GameTooltip:SetSpell(1,"spell"); local text=CapturedIDLines[table.getn(CapturedIDLines)] or ""; assert(string.find(text,"技能 ID",1,true) and string.find(text,"686",1,true)); GetSpellName=SavedSpellName; return "player and pet book hover adapters with injected book metadata"',
    'SavedPetInfo=GetPetActionInfo; GetPetActionInfo=function() return "Lash of Pain","Rank 1",nil,nil end; GameTooltip:ClearLines(); GameTooltip:SetPetAction(4); local text=CapturedIDLines[table.getn(CapturedIDLines)] or ""; assert(string.find(text,"宠物技能 ID",1,true) and string.find(text,"7814",1,true)); GetPetActionInfo=function() return "PET_ACTION_ATTACK",nil,nil,1 end; GameTooltip:ClearLines(); local n=table.getn(CapturedIDLines); GameTooltip:SetPetAction(1); assert(table.getn(CapturedIDLines)==n); GetPetActionInfo=SavedPetInfo; return "pet bar hover adapter; attack command is not a spell"',
    'local n=table.getn(CapturedIDLines); GameTooltip:SetAction(120); assert(table.getn(CapturedIDLines)==n); return "empty action clears stale ID"',
]
args = [os.environ["ADDON_HARNESS"], str(root / "AddOns"), "--probe", "AzerothSpellID"]
for check in checks:
    args += ["--eval", check]
args += ["--tick", "0.2"]
env = dict(os.environ, WOW_DATA=os.environ["WOW_DATA"])
result = subprocess.run(args, env=env, text=True, capture_output=True, timeout=60)
output = result.stdout + result.stderr
(root / "tests/spell-id-validation.log").write_text(output)
print(output)
assert result.returncode == 0
assert "load errors: 0" in output and "session errors: 0" in output
assert "ERROR:" not in output and "SYNTAX:" not in output
