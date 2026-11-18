-- Require evidence about THIS spell press, never just a generic mounted error.
if AzerothDismountGuard then return end
local original=EzDismount_chkandgetdown
if type(original)~="function" then return end
local G={version="0.3.0",last="尚未施法"};AzerothDismountGuard=G
local function block(reason) G.pending=nil;G.last=reason;return false end
local function bitHas(value,bit) return math.mod(math.floor(value/bit),2)==1 end
function G.Action(slot,onSelf)
 G.pending=nil
 if GetActionText(slot) or GetActionCount(slot)>0 or IsConsumableAction(slot) then return block("宏或物品需手动下马") end
 if not G.tooltip then G.tooltip=CreateFrame("GameTooltip","AzerothDismountProbe",UIParent,"GameTooltipTemplate");G.tooltip:Hide() end
 local tip=G.tooltip;tip:SetOwner(UIParent,"ANCHOR_NONE");tip:ClearLines();tip:SetAction(slot)
 local left=getglobal("AzerothDismountProbeTextLeft1");local right=getglobal("AzerothDismountProbeTextRight1")
 local name=left and left:GetText();local rank=right and right:IsShown() and right:GetText() or ""
 tip:Hide()
 local data=AzerothDismountData
 local profile=name and data and data.spells[name.."\001"..rank]
 if not profile then return block("无法确认当前法术类型，保留骑乘") end
 local target="target"
 local explicit=onSelf and onSelf~=0
 if profile.kind=="self" then target="player"
 elseif profile.kind=="enemy" then
  if explicit or not UnitExists("target") or not UnitCanAttack("player","target") then return block("攻击法术的目标不可攻击") end
 elseif profile.kind=="friend" or profile.kind=="friend-other" then
  if explicit then target="player"
  elseif not UnitExists("target") or not UnitCanAssist("player","target") then
   local auto=GetCVar("autoSelfCast")
   if auto=="1" or auto==1 then target="player" else return block("友方法术的目标不可协助") end
  end
  if profile.kind=="friend-other" and (target=="player" or (UnitIsUnit and UnitIsUnit("target","player"))) then return block("该法术不能对自己施放") end
 else return block("未支持的目标类型") end
 if not UnitExists(target) or UnitIsDeadOrGhost(target) then return block("实际施法目标不存在或已死亡") end
 if profile.creatures>0 then
  local bit=data.creatures[UnitCreatureType(target) or ""]
  if not bit or not bitHas(profile.creatures,bit) then return block("目标生物类型不符") end
 end
 -- Self has no target-distance requirement; do not use the selected enemy's range for it.
 if target~="player" and IsActionInRange(slot)~=1 then return block("超出射程或射程未知") end
 local usable,noPower=IsUsableAction(slot)
 if not usable or noPower then return block("法术不可用或资源不足") end
 local start,duration=GetActionCooldown(slot)
 if not start or not duration or (duration>0 and start+duration>GetTime()) then return block("冷却中或冷却未知") end
 G.pending={at=GetTime(),name=UnitName("target"),slot=slot,onSelf=onSelf,target=target,spellKey=name.."\001"..rank,kind=profile.kind,creatures=profile.creatures}
 G.last="当前法术目标检查通过"
 return true
end
function G.Allowed()
 local pending=G.pending;G.pending=nil
 if not pending or GetTime()<pending.at or GetTime()-pending.at>0.75 then return block("没有有效的本次施法记录") end
 if UnitName("target")~=pending.name then return block("目标已改变") end
 -- Re-read the actual action and target; range/resources may have changed since the press.
 local ok,allowed=pcall(G.Action,pending.slot,pending.onSelf);local current=G.pending;G.pending=nil
 if not ok then return block("检查接口不可用，保留骑乘") end
 if allowed and current and (current.target~=pending.target or current.spellKey~=pending.spellKey or current.kind~=pending.kind or current.creatures~=pending.creatures) then return block("动作栏法术已改变") end
 return allowed
end
local useAction=UseAction
UseAction=function(slot,a,b)
 local ok=pcall(G.Action,slot,b)
 if not ok then block("检查接口不可用，保留骑乘") end
 return useAction(slot,a,b)
end
-- Unsupported entry points must invalidate an earlier action, not inherit its permission.
local castByName=CastSpellByName
if type(castByName)=="function" then CastSpellByName=function(a,b) G.pending=nil;return castByName(a,b) end end
local castSpell=CastSpell
if type(castSpell)=="function" then CastSpell=function(a,b) G.pending=nil;return castSpell(a,b) end end
EzDismount_chkandgetdown=function(kind,errors,message,mount)
 if kind=="Dismount" and mount and (message==SPELL_FAILED_NOT_MOUNTED or message==ERR_ATTACK_MOUNTED) then
  if not G.Allowed() then return end
 end
 return original(kind,errors,message,mount)
end
local frame=CreateFrame("Frame")
frame:RegisterEvent("PLAYER_TARGET_CHANGED");frame:RegisterEvent("PLAYER_ENTERING_WORLD");frame:RegisterEvent("UI_ERROR_MESSAGE");frame:RegisterEvent("ACTIONBAR_SLOT_CHANGED");frame:RegisterEvent("ACTIONBAR_PAGE_CHANGED")
frame:SetScript("OnEvent",function()
 if event~="UI_ERROR_MESSAGE" or (arg1~=SPELL_FAILED_NOT_MOUNTED and arg1~=ERR_ATTACK_MOUNTED) then G.pending=nil end
end)
SLASH_AZEROTHDISMOUNTGUARD1="/ezguard"
SlashCmdList["AZEROTHDISMOUNTGUARD"]=function()DEFAULT_CHAT_FRAME:AddMessage("下马保护 "..G.version.."："..G.last)end
