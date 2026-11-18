math.mod=math.mod or function(a,b)return a-math.floor(a/b)*b end
local source=(arg and arg[1]) or 'AddOns/AzerothDismountGuard/AzerothDismountGuard.lua'
local calls,nativeCalls,clock=0,0,10
local exists,dead,enemy,friend=true,false,true,false
local range,usable,noPower=1,1,nil
local start,duration=0,0
local targetName,creature='Enemy','Humanoid'
local deferred=false
local autoSelf="0"
function GetCVar()return autoSelf end
function UnitIsUnit(a,b)return a==b end
local globals,events={},{}
SPELL_FAILED_NOT_MOUNTED='mounted';ERR_ATTACK_MOUNTED='attack-mounted'
UIParent={};SlashCmdList={};DEFAULT_CHAT_FRAME={AddMessage=function()end}
AzerothDismountData={spells={['Frost\001Rank 1']={kind='enemy',creatures=0},['Heal\001Rank 1']={kind='friend',creatures=0},['Control\001Rank 1']={kind='enemy',creatures=1}},creatures={Humanoid=1,Beast=2}}
local actions={[1]={name='Frost',rank='Rank 1'},[2]={name='Heal',rank='Rank 1'},[3]={name='Unknown',rank=''},[4]={name='Control',rank='Rank 1'},[5]={name='Frost',rank='Rank 1',macro='Macro'}}
function UnitExists(unit)return (unit=="player" or exists) and 1 or nil end
function UnitIsDeadOrGhost(unit)return unit~="player" and dead and 1 or nil end
function UnitCanAttack()return enemy and 1 or nil end
function UnitCanAssist()return friend and 1 or nil end
function UnitName()return targetName end
function UnitCreatureType()return creature end
function GetTime()return clock end
function GetActionText(slot)return actions[slot].macro end
function GetActionCount()return 0 end
function IsConsumableAction()return nil end
function IsActionInRange()return range end
function IsUsableAction()return usable,noPower end
function GetActionCooldown()return start,duration,1 end
function getglobal(name)return globals[name] end
function CreateFrame(kind,name)
 local obj={}
 function obj:Hide()end
 function obj:SetOwner()end
 function obj:ClearLines()end
 function obj:SetAction(slot)
  local action=actions[slot]
  globals[name..'TextLeft1']={GetText=function()return action.name end}
  globals[name..'TextRight1']={IsShown=function()return true end,GetText=function()return action.rank end}
 end
 function obj:RegisterEvent()end
 function obj:SetScript(_,fn)events.fn=fn end
 return obj
end
function EzDismount_chkandgetdown()calls=calls+1 end
local function mountedError()EzDismount_chkandgetdown('Dismount',{},'mounted',true)end
function UseAction(slot)nativeCalls=nativeCalls+1;if not deferred then mountedError()end;return 'native-return',slot end
function CastSpellByName()end
function CastSpell()end
dofile(source)
local G=AzerothDismountGuard
local function denied(slot,label)local before=calls;UseAction(slot);assert(calls==before,label)end
local a,b=UseAction(1);assert(a=='native-return' and b==1 and calls==1,'valid enemy and native return values preserved')
enemy=false;friend=true;denied(1,'attack on friendly must stay mounted')
UseAction(2);assert(calls==2,'heal on friendly may dismount')
enemy=true;friend=false;denied(2,'heal on enemy must stay mounted')
exists=false;denied(1,'no target');exists=true
dead=true;denied(1,'dead target');dead=false
enemy=false;denied(1,'neutral/invalid target');enemy=true
range=0;denied(1,'out of range');range=nil;denied(1,'unknown range');range=1
usable=nil;denied(1,'not usable');usable=1;noPower=1;denied(1,'no power');noPower=nil
start=clock;duration=5;denied(1,'cooldown');start=0;duration=0
local before=calls;UseAction(1,nil,1);assert(calls==before,'explicit self target must not inherit enemy permission')
denied(3,'unknown spell must fail closed');denied(5,'macro must fail closed')
creature='Beast';denied(4,'creature restriction');creature='Humanoid';UseAction(4);assert(calls==3,'compatible creature type')
deferred=true;UseAction(1);clock=clock+1;mountedError();assert(calls==3,'stale request')
UseAction(1);targetName='Other';mountedError();assert(calls==3,'changed target');targetName='Enemy'
UseAction(1);CastSpellByName('Heal');mountedError();assert(calls==3,'unsupported entry clears permission')
UseAction(1);enemy=false;friend=true;mountedError();assert(calls==3,'relation rechecked after press');enemy=true;friend=false
UseAction(1);actions[1]={name='Heal',rank='Rank 1'};enemy=false;friend=true;mountedError();assert(calls==3,'changed slot must not authorize earlier spell')
actions[1]={name='Frost',rank='Rank 1'};enemy=true;friend=false
UseAction(1);event='ACTIONBAR_SLOT_CHANGED';events.fn();mountedError();assert(calls==3,'actionbar event invalidates pending cast')
UseAction(1);mountedError();assert(calls==4,'deferred valid event');mountedError();assert(calls==4,'permission consumed once')
EzDismount_chkandgetdown('Druid',{},'form',nil);assert(calls==5,'other form errors preserved')
-- Own-target spells and the client's automatic/explicit self fallback.
AzerothDismountData.spells['Armor\001Rank 1']={kind='self',creatures=0}
AzerothDismountData.spells['OtherOnly\001Rank 1']={kind='friend-other',creatures=0}
actions[6]={name='Armor',rank='Rank 1'};actions[7]={name='OtherOnly',rank='Rank 1'}
deferred=false;exists=false;range=0
local count=calls;UseAction(6);assert(calls==count+1,'intrinsic self cast without target')
count=calls;UseAction(2);assert(calls==count,'autoSelfCast off keeps no-target heal mounted')
autoSelf='1';UseAction(2);assert(calls==count+1,'auto self heal without target')
exists=true;enemy=true;friend=false;count=calls;UseAction(2);assert(calls==count+1,'auto self heal with enemy selected, selected range ignored')
count=calls;UseAction(1);assert(calls==count,'auto self does not turn enemy spell into self spell')
count=calls;UseAction(7);assert(calls==count,'self-excluding friend spell stays mounted')
autoSelf='0';count=calls;UseAction(2,nil,1);assert(calls==count+1,'explicit self heal')
friend=true;enemy=false;range=0;autoSelf='1';count=calls;UseAction(2);assert(calls==count,'out-of-range friendly target does not silently become self')
range=1;count=calls;UseAction(2);assert(calls==count+1,'valid friendly target retained with auto self on')
usable=nil;count=calls;UseAction(6);assert(calls==count,'self spell resources still checked');usable=1
print('PASS: spell-specific enemy/friend/creature gates, range, usability, cooldown, unknown/macro, stale/changed requests and native returns')
