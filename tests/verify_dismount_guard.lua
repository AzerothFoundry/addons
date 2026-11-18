local source=(arg and arg[1]) or 'AddOns/AzerothDismountGuard/AzerothDismountGuard.lua'
local calls=0
local exists,dead,attack,assist=false,false,false,false
SPELL_FAILED_NOT_MOUNTED='mounted';ERR_ATTACK_MOUNTED='attack-mounted'
function UnitExists()return exists end
function UnitIsDeadOrGhost()return dead end
function UnitCanAttack()return attack and 1 or nil end
function UnitCanAssist()return assist and 1 or nil end
function EzDismount_chkandgetdown()calls=calls+1 end
dofile(source)
local function error()EzDismount_chkandgetdown('Dismount',{},'mounted',true) end
error();assert(calls==0,'no target must not dismount')
exists=true;attack=true;error();assert(calls==1,'attackable living target passes through')
dead=true;error();assert(calls==1,'dead target must not dismount')
dead=false;attack=false;error();assert(calls==1,'invalid target must not dismount')
assist=true;error();assert(calls==2,'assistable target passes through')
exists=false;EzDismount_chkandgetdown('Druid',{},'form',nil);assert(calls==3,'form handling unchanged')
EzDismount_chkandgetdown('Dismount',{},'unrelated',true);assert(calls==4,'other error handling unchanged')
print('PASS: absent, dead, invalid, enemy and friendly targets; unrelated errors preserved')
