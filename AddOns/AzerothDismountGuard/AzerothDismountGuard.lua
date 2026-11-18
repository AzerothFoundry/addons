-- Additive compatibility guard; the third-party addon remains unmodified.
if AzerothDismountGuard then return end
local original=EzDismount_chkandgetdown
if type(original)~="function" then return end
local G={version="0.1.0"};AzerothDismountGuard=G
function G.Allowed()
 if not UnitExists("target") then return false end
 if UnitIsDeadOrGhost("target") then return false end
 return UnitCanAttack("player","target") or UnitCanAssist("player","target")
end
EzDismount_chkandgetdown=function(kind,errors,message,mount)
 if kind=="Dismount" and mount and (message==SPELL_FAILED_NOT_MOUNTED or message==ERR_ATTACK_MOUNTED) then
  if not G.Allowed() then return end
 end
 return original(kind,errors,message,mount)
end
