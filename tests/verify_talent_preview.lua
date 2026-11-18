-- Exercise the actual module during first-open UI callbacks, without learning talents.
local source = arg[1] or 'AddOns/AzerothTalentPreview/AzerothTalentPreview.lua'
table.getn = table.getn or function(t) return #t end -- host Lua compatibility for the 1.12 API
local frames, tooltips, learned = {}, {}, 0
StaticPopupDialogs = {}; SlashCmdList = {}; UIParent = {}
DEFAULT_CHAT_FRAME = {AddMessage=function() end}
GameTooltip = {SetOwner=function() end, SetText=function(_, text) table.insert(tooltips,text) end,
 AddLine=function() end, Show=function() end, Hide=function() end}
local methods = {}
function methods:SetScript(event,fn)
 self.scripts[event]=fn
 -- Reproduce a hover arriving as a visible frame is being constructed.
 if event=='OnEnter' and not (self.parent and self.parent.hidden) then this=self;fn() end
end
function methods:Hide() self.hidden=true;if self.scripts.OnHide then this=self;self.scripts.OnHide() end end
function methods:Show()
 self.hidden=false
 for _,child in ipairs(frames) do if child.parent==self and child.scripts.OnEnter then this=child;child.scripts.OnEnter() end end
end
function methods:IsShown() return not self.hidden end
function methods:SetText(text) self.text=text;if self.scripts.OnTextChanged then this=self;self.scripts.OnTextChanged() end end
function methods:GetText() return self.text or '' end
local function widget(name,parent)
 local object={name=name,parent=parent,scripts={}}
 setmetatable(object,{__index=function(_,key) return methods[key] or function() end end})
 table.insert(frames,object);if name then _G[name]=object end;return object
end
function methods:CreateFontString() return widget(nil,self) end
function CreateFrame(_,name,parent) return widget(name,parent) end
function GetNumTalentTabs() return 1 end
function GetTalentTabInfo() return '测试系','icon',3,'test-tree' end
function GetNumTalents() return 2 end
function GetTalentInfo(_,index) return '天赋'..index,'icon',1,index,index,5 end
function UnitCharacterPoints() return 48 end
function UnitLevel() return 60 end
function UnitAffectingCombat() return false end
function UnitIsDeadOrGhost() return false end
function LearnTalent() learned=learned+1 end
AzerothTalentData={['test-tree']={
 {row=1,col=1,max=5,req={},desc={'第一天赋'}},
 {row=1,col=2,max=5,req={},desc={'第二天赋'}}}}
dofile(source)
local P=AzerothTalentPreview
P.Toggle()
assert(P.plan[1][1]==1 and P.plan[1][2]==2,'first open must copy real talents')
assert(string.find(tooltips[1],'预览 1/5',1,true),'first tooltip must use initialized plan')
assert(string.find(tooltips[2],'预览 2/5',1,true),'each callback must retain its node')
P.Toggle();assert(not P.frame:IsShown(),'second toggle closes')
P.Toggle();assert(P.frame:IsShown(),'reopen succeeds')
P.plan={};this=P.buttons[1][1];this.scripts.OnEnter()
assert(string.find(tooltips[table.getn(tooltips)],'预览 0/5',1,true),'missing plan safely previews zero')
assert(learned==0,'opening and hovering must not spend real talent points')
print('PASS: first-open hover, per-node tooltips, reopen, missing-plan guard; no LearnTalent')
