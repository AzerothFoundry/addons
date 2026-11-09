-- WoW 1.12: all frequent actions use the server's self-only GMUI interface.
local A = { status = {}, gear = {}, teles = {}, logs = {}, tab = 1, bg = 1, catalogPage = 1, telePage = 1, teleMore = false, partySpecs = {}, partySpecsLoaded = false }
AzerothGM = A
local bgKeys = { "warsong", "arathi", "alterac" }
local bgNames = { "战歌峡谷", "阿拉希盆地", "奥特兰克山谷" }
local tabs = { "角色", "技能 / 天赋", "传送", "组队机器人", "战场测试", "命令 / 日志", "物品 / 邮件" }
local roles = { [1] = "近战输出", [2] = "远程输出", [3] = "坦克", [4] = "治疗" }
local messages = {
    ["Invalid recipient name"] = "收件角色名无效。",
    ["Recipient character not found"] = "没有找到收件角色，请填写角色名而不是账号。",
    ["PvP item does not belong to recipient faction"] = "该军装物品不属于收件角色的阵营，未发送。",
    ["Unavailable item or invalid count"] = "当前版本物品不可用或数量无效，未发送。",
    ["Count exceeds unique-item limit"] = "数量超过唯一物品限制，未发送。",
    ["At most 1000 mail attachments per request"] = "一次最多邮寄1000个堆叠，请分批发送。",
    ["Mail transaction failed; nothing delivered"] = "邮件提交失败，未寄出。",
    ["Tier is incomplete in the active content phase; nothing sent"] = "当前版本套装不完整，未发送。",
    ["Temporary bots cannot receive GM mail"] = "临时机器人不能接收GM邮件。",
    ["No legal complete weapon plan for current class/level/learned skills; nothing changed."] = "当前职业、等级或已学武器熟练不足以组成完整方案，未更换；请先向武器大师训练本职合法武器技能。",
    ["Free ordinary bag slots for replacement weapons and old offhand first; nothing changed."] = "普通背包空位不足，请先腾出位置保留原武器和副手；未更换。",
    ["Tank reference remains below the level-63 yellow-hit requirement; companion not ready."] = "坦克尚未达到63级首领近战黄字命中参考，队友未就绪；请查看机器人状态。",
    ["Reserve the last party slot for a phase-6 healer."] = "最后一个队伍位置请先召唤P6毕业治疗；服务端已计入正在加入的机器人。",
    ["Not enough bag capacity or unique-item limit; nothing granted. Use mail for large quantities"] = "背包容量不足或超过唯一物品限制，未发放；大批量可改用邮寄。",
    ["Native item grant did not complete; inspect received count before retrying"] = "物品未完整发放，请先核对实际收到的数量再重试。",
    ["Item grant saved"] = "物品领取已保存。",
    ["Expected positive item id and count 1 to 100000"] = "请输入有效物品ID，数量为1–100000。",
    ["Action completed"] = "操作完成。",
    ["Administrator session required"] = "需要管理员权限；权限调整后请退出游戏再登录。",
    ["Action rejected; see server response"] = "操作被服务端拒绝，请查看日志中的具体原因。",
    ["Leave combat and battleground before changing level"] = "请先离开战斗和战场，再调整等级。",
    ["Leave combat/battleground before changing gear"] = "请先离开战斗和战场，再更换测试装备。",
    ["Player level is below template level; use level action explicitly"] = "等级不足，请先在角色页明确调整等级。",
    ["Template not available for this class"] = "这个套装不适合当前职业。",
    ["Boss teleport refused during an active encounter"] = "副本首领战正在进行，暂时不能传送。",
    ["Boss teleport requires the current dungeon instance"] = "请先进入要查询的副本实例。",
    ["Expected tele bosses [page]"] = "Boss列表页码无效，请刷新。",
    ["Expected tele boss entry"] = "Boss编号无效，请重新选择。",
    ["Boss teleport requires alive, out of combat and off transport"] = "请先复活、脱战并离开载具，再传送到Boss。",
    ["Boss is not registered in the current map"] = "这个Boss不属于当前副本，请刷新列表。",
    ["Teleported to unverified current-instance Boss anchor"] = "已传送到未验证安全的Boss位置，可用返回上次位置离开。",
    ["Boss teleport context changed; refresh the list"] = "副本上下文已变化，请刷新Boss列表。",
    ["Boss has no static spawn; teleport unsupported"] = "这个Boss没有固定出生点，暂不支持传送。",
    ["No verified safe Boss staging point found"] = "尚未找到已核实的Boss安全落点，未传送。",
    ["Current instance teleport rejected"] = "当前副本实例拒绝了传送，位置未改变。",
    ["Unknown teleport key"] = "没有找到这个传送位置。",
    ["Leave combat/battleground before teleporting"] = "请先离开战斗和战场。",
    ["Leave battleground queue before changing level"] = "请先退出战场队列，再调整等级。",
    ["No active battleground match request."] = "尚未开始匹配。",
    ["No active test request."] = "没有正在运行的测试请求。",
    ["Test request cancelled; only its bots were removed."] = "本次匹配已取消，已清理本次创建的机器人。",
    ["Join the matching battleground queue first; your level is never changed automatically."] = "请先在原生战场窗口排队，再开始匹配；当前等级不会自动改变。",
    ["Other players/bots already occupy this test bracket; refusing to mix requests."] = "该战场等级段已有其他玩家或机器人，本次测试不会与他们混入同一请求。",
    ["A test owner already controls this queue/bracket. Cancel that request first."] = "该等级段已有测试请求，请先结束原请求。",
    ["Choose queue in the battleground window, then enable matching"] = "请在战场窗口点击排队，然后在本面板开启匹配。",
    ["Battleground access rejected; check level or current battleground"] = "无法打开该战场，请检查等级限制或先离开当前战场。",
    ["Item requirements not met; level, rank, reputation and skills are not raised automatically"] = "装备使用条件不足，请检查等级、军衔、声望或武器防具技能。",
    ["Free more general bag slots before applying template"] = "普通背包空位不足，请先腾出空间以保留原装备。",
    ["Template items placed in bags; existing equipment unchanged"] = "套装物品已放入背包。",
}

local function trim(s)
    local value = string.gsub(s or "", "^%s+", "")
    value = string.gsub(value, "%s+$", "")
    return value
end
local function label(parent, name, text, x, y, width, font)
    local f = parent:CreateFontString(name, "OVERLAY", font or "GameFontNormal")
    f:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y)
    f:SetWidth(width or 800); f:SetJustifyH("LEFT"); f:SetText(text)
    return f
end
local function button(parent, name, text, x, y, width, callback)
    local b = CreateFrame("Button", name, parent, "UIPanelButtonTemplate")
    b:SetWidth(width or 145); b:SetHeight(26); b:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y)
    b:SetText(text); b:SetScript("OnClick", callback)
    return b
end
local function input(parent, name, text, x, y, width)
    local e = CreateFrame("EditBox", name, parent, "InputBoxTemplate")
    e:SetWidth(width or 100); e:SetHeight(24); e:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y)
    e:SetAutoFocus(false); e:SetMaxLetters(180); e:SetText(text or "")
    e:SetScript("OnEscapePressed", function() this:ClearFocus() end)
    return e
end
local function integer(box, lo, hi)
    local n = tonumber(trim(box:GetText()))
    if not n or n ~= math.floor(n) or n < lo or n > hi then
        UIErrorsFrame:AddMessage("请输入 " .. lo .. " 到 " .. hi .. " 的整数。", 1, 0.3, 0.2)
        return nil
    end
    return n
end
local function clearFocus()
    for _, box in ipairs(A.inputs or {}) do box:ClearFocus() end
end
function A.Log(text)
    table.insert(A.logs, date("%H:%M:%S") .. "  " .. (messages[text] or text))
    while table.getn(A.logs) > 8 do table.remove(A.logs, 1) end
    if A.logText then A.logText:SetText(table.concat(A.logs, "\n")) end
end
function A.Send(command, native)
    if not command or string.find(command, "[\r\n]") or string.len(command) > 210 then return end
    clearFocus()
    SendChatMessage(native and ("." .. command) or (".gmui " .. command), "SAY")
end
local pending
StaticPopupDialogs["AZEROTHGM_CONFIRM"] = {
    text = "%s", button1 = "确认", button2 = "取消", timeout = 0, whileDead = 1, hideOnEscape = 1,
    OnAccept = function() local action = pending; pending = nil; if action then action() end end,
    OnCancel = function() pending = nil end,
}
local function confirm(text, action)
    pending = action; StaticPopup_Show("AZEROTHGM_CONFIRM", text)
end
local function parseFields(parts)
    local result = {}
    for _, part in ipairs(parts) do
        local _, _, key, value = string.find(part, "^([^=]+)=(.*)$")
        if key then result[key] = value end
    end
    return result
end
local function split(text)
    local result = {}
    for part in string.gfind(text .. "|", "(.-)|") do table.insert(result, part) end
    return result
end
local function goldText(copper)
    local n = tonumber(copper) or 0
    return math.floor(n / 10000) .. "金 " .. math.mod(math.floor(n / 100), 100) .. "银 " .. math.mod(n, 100) .. "铜"
end
A.UI={label=label,button=button,input=input,integer=integer,confirm=confirm,trim=trim,split=split,parseFields=parseFields}

function A.HandleMessage(text)
    if not text or string.sub(text, 1, 5) ~= "GMUI|" then
        if A.frame and A.frame:IsShown() then A.Log(text or "") end
        return false
    end
    if A.HandleSkillMessage and A.HandleSkillMessage(text) then return true end
    if A.HandleBossMessage and A.HandleBossMessage(text) then return true end
    local parts = split(text); local kind = parts[2]
    if (kind=="PARTYBOT" or kind=="PARTYSTATS" or kind=="PARTYDEFENSE" or kind=="PARTYMETA") and A.partyStatusFinished then
        A.partyBotStatus={};A.partyStats={};A.partyStatsShown={};A.partyDefense={};A.partyDefenseShown={};A.partyMeta=nil;A.partyRevisionShown=false;A.partyStatusFinished=false
    end
    if kind == "ITEMGRANT" then
        local v=parseFields(parts);A.Log("物品 #"..(v.id or "?").."：申请 "..(v.requested or "?").."，实际收到 "..(v.received or "?").."。");return true
    elseif kind == "STATUS" then
        local oldLevel,oldTeam=A.status.level,A.status.team
        A.status = parseFields(parts)
        if A.partySpecsLoaded and (oldLevel~=A.status.level or oldTeam~=A.status.team) then A.partySpecsLoaded=false end
        if A.summary then
            A.summary:SetText("角色：" .. (UnitName("player") or "") .. "    等级：" .. (A.status.level or "?") ..
                "    金钱：" .. goldText(A.status.money) .. "    军衔：R" .. (A.status.rank or "0") ..
                "    军装：" .. (A.status.pvpPieces or "0") .. " 件")
        end
        if A.level then A.level:SetText(A.status.level or "1") end
        if A.flags then
            A.flags:SetText("GM模式：" .. (A.status.gm == "1" and "开" or "关") ..
                "    可见：" .. (A.status.visible == "0" and "否" or "是") ..
                "    无敌：" .. (A.status.god == "1" and "开" or "关") ..
                "    飞行：" .. (A.status.fly == "1" and "开" or "关"))
        end
        if A.PaintPartySpecs then A.PaintPartySpecs() end
    elseif kind == "PARTYSPEC" or kind == "SPEC" then
        local entry=parseFields(parts)
        if tonumber(entry.id) and tonumber(entry.class) and tonumber(entry.role) then
            local replaced=false
            for i,previous in ipairs(A.partySpecs) do if previous.id==entry.id then A.partySpecs[i]=entry;replaced=true;break end end
            if not replaced then table.insert(A.partySpecs,entry) end
        end
    elseif kind == "DONE" and (parts[3]=="party" or parts[3]=="specs") then
        A.partySpecsLoaded=true;A.partyLoading=false
        table.sort(A.partySpecs,function(a,b) return tonumber(a.id)<tonumber(b.id) end)
        A.PaintPartySpecs()
        A.Log("已加载服务端真实职业专精；不可用项不会召唤。")
    elseif kind == "PARTYBOT" then
        local bot=parseFields(parts)
        A.partyBotStatus=A.partyBotStatus or {}
        A.partyBotStatus[bot.guid or tostring(table.getn(A.partyBotStatus)+1)]=bot
        local name="机器人 "..(bot.guid or "?")
        for _,entry in ipairs(A.partySpecs) do if entry.id==bot.specId then name=A.PartySpecName(entry);break end end
        local status=bot.state=="loading" and "载入中" or bot.state=="ready" and "已加载" or bot.state=="removing" and "移除中" or "状态待核实"
        local detail
        if bot.state=="removing" then detail="等待服务端注销，仍计入实际剩余数量"
        elseif bot.state~="ready" then
            if bot.strategy=="tank_hit" then detail="计划命中优先修订，尚未核实"
            else detail=bot.strategy=="phase6" and "计划P6，尚未核实" or "等待配置核实" end
        elseif bot.strategy=="tank_hit" then
            if bot.loadout=="1" and bot.verified=="1" then detail="命中优先修订配装已核实（P6候选已调整）"
            elseif bot.loadout=="1" then detail="修订装备已核对，专精未完整核实"
            else detail="命中优先修订配装尚未核实" end
        elseif bot.p6=="1" and bot.verified=="1" then detail="P6装备及专精已核实"
        elseif bot.p6=="1" then detail="P6装备已核对，专精未完整核实"
        elseif bot.strategy=="adaptive" then detail=bot.verified=="1" and "适配装备，专精已核实" or "适配配置待核实"
        elseif bot.strategy=="phase6" then detail="P6实装未完整"
        else detail="原生配置，毕业状态未核实" end
        if bot.ratio and bot.state=="ready" then detail=detail.." · 参考比 "..bot.ratio end
        if bot.limited=="1" then detail=detail.." · 装备受限" end
        if bot.state=="ready" and bot.verified~="1" and bot.spells then detail=detail.." · 预设法术覆盖 "..bot.spells end
        A.Log(name.."："..status.." · "..detail)
        if bot.state=="ready" and bot.strategy=="tank_hit" and bot.specId=="15" and bot.loadout=="1" and bot.verified=="1" and not A.partyRevisionShown then
            A.Log("防骑装备主要条目取舍：命中+2%、防御-8、招架词条-1%、躲闪词条+1%；生命/护甲词条不变，净面板以实时属性为准。")
            A.partyRevisionShown=true
        end
        if A.LogPartyTankStats then A.LogPartyTankStats(bot.guid) end
        if A.LogPartyTankDefense then A.LogPartyTankDefense(bot.guid) end
    elseif kind == "PARTYSTATS" then
        local stats=parseFields(parts)
        A.partyStats=A.partyStats or {}
        if stats.guid then A.partyStats[stats.guid]=stats;if A.LogPartyTankStats then A.LogPartyTankStats(stats.guid) end end
    elseif kind == "PARTYDEFENSE" then
        local defense=parseFields(parts)
        A.partyDefense=A.partyDefense or {}
        if defense.guid then A.partyDefense[defense.guid]=defense;if A.LogPartyTankDefense then A.LogPartyTankDefense(defense.guid) end end
    elseif kind == "PARTYMETA" then
        A.partyMeta=parseFields(parts)
        local m=A.partyMeta
        A.Log("机器人 "..(m.owned or "?").."：已加载 "..(m.ready or "?").."，载入中 "..(m.pending or "?")..
            "，移除中 "..(m.removing or "?").."；已核实P6治疗 "..(m.p6Healers or "?").."，待载入计划 "..(m.pendingP6Healers or "?").."。")
    elseif kind == "DONE" and parts[3]=="partyStatus" then
        for guid,_ in pairs(A.partyStats or {}) do A.LogPartyTankStats(guid) end
        for guid,_ in pairs(A.partyDefense or {}) do A.LogPartyTankDefense(guid) end
        A.partyStatusFinished=true
    elseif kind == "ITEM" then
        if A.itemsFinished then A.items={};A.itemsFinished=false end
        A.items=A.items or {};table.insert(A.items,parseFields(parts))
    elseif kind == "ITEMMETA" then
        if A.itemsFinished then A.items={};A.itemsFinished=false end
        local meta=parseFields(parts);A.itemPage=tonumber(meta.page) or 1;A.itemTotal=tonumber(meta.total) or 0;A.itemMore=meta.more=="1"
    elseif kind == "DONE" and parts[3]=="items" then
        A.itemsLoaded=true;A.itemsLoading=false;A.itemsFinished=true;A.PaintItems()
    elseif kind == "GEAR" then
        table.insert(A.gear, parseFields(parts))
    elseif kind == "TELE" then
        table.insert(A.teles, parseFields(parts))
    elseif kind == "TELEMETA" then
        local meta = parseFields(parts)
        A.telePage = tonumber(meta.page) or A.telePage
        A.teleMore = meta.more == "1"
        if A.telePaging then A.telePaging:SetText("第 " .. A.telePage .. " 页 · 共 " .. (meta.total or "?") .. " 个地点") end
    elseif kind == "DONE" and parts[3] == "gear" then
        A.gearPage = 1; A.PaintGear(); A.Log("已加载当前职业的测试套装。")
    elseif kind == "DONE" and parts[3] == "tele" then
        A.PaintTele()
    elseif kind == "AUTO" then
        local meta = parseFields(parts)
        if A.autoText then
            local seconds = tonumber(meta.autoSeconds) or 0
            local text_ = seconds > 0 and ("自动补人：排队 " .. seconds .. " 秒后检查缺少真人的一侧。") or "自动补人未启用，可手动开始匹配。"
            if meta.queued == "1" then text_ = text_ .. " 已等待 " .. (meta.waiting or "0") .. " 秒。" end
            if meta.blocked == "active" then text_ = "本次机器人匹配已经启动。"
            elseif meta.blocked == "invited" then text_ = "已收到战场邀请，请在原生窗口进入。"
            elseif meta.blocked == "both_sides_real" then text_ = "两边都有真人，继续按正常战场规则匹配。"
            elseif meta.blocked == "manual_cancel" or meta.blocked == "cohort_cancelled" then text_ = "本次排队已停止自动补人；退出重排可重新尝试。"
            elseif meta.blocked == "cohort_changed" then text_ = "排队成员发生变化，本次自动匹配已取消；退出重排可重新尝试。"
            elseif meta.blocked == "other_request" then text_ = "当前等级段已有匹配请求，请等待或退出后重排。"
            elseif meta.blocked == "begin_failed" then text_ = "自动匹配未能建立，请查看结果，或退出队列后重试。" end
            A.autoText:SetText(text_)
        end
    elseif kind == "BGTEAM" then
        local meta = parseFields(parts)
        A.bgTeams = A.bgTeams or {}
        A.bgTeams[meta.team] = meta
        if A.teamText then
            local rows = {}
            for _, team in ipairs({"469", "67"}) do
                local row = A.bgTeams[team]
                if row then
                    table.insert(rows, (team == "469" and "联盟" or "部落") .. "：真人 " .. (row.humans or "0") .. " + 机器人 " .. (row.bots or "0") .. "/" .. (row.target or "?") .. "，治疗目标 " .. (row.healerTarget or "?") .. "（真人 " .. (row.humanHealers or "0") .. "，已载入治疗机器人 " .. (row.readyHealers or "0") .. "）")
                    if (tonumber(row.flagBots) or 0)+(tonumber(row.midBots) or 0)>0 then
                        table.insert(rows,"  夺旗组 "..row.flagBots.."（治疗 "..(row.flagHealers or "0").."） / 中场组 "..row.midBots.."（治疗 "..(row.midHealers or "0").."）")
                    end
                end
            end
            A.teamText:SetText(table.concat(rows, "\n"))
        end
    elseif kind == "MATCH" then
        local text_ = string.sub(text, 12)
        local fields = {}
        for key, value in string.gfind(text_, "(%w+)=([^%s]+)") do fields[key] = value end
        A.matching = fields.request ~= nil
        if not A.matching or A.bgRequest ~= fields.request then
            A.bgTeams = {}
            if A.teamText then A.teamText:SetText("战歌10对10／阿拉希15对15／奥山40对40；治疗占每方1/5，其余职业随机。") end
        end
        A.bgRequest = fields.request
        local description = messages[text_] or text_
        if A.matching then
            description = "机器人 " .. (fields.bots or "0") .. " 个，就绪 " .. (fields.ready or "0") ..
                " 个，装备受限 " .. (fields.limited or "0") .. " 个。\n玩家装备参考分 " .. (fields.snapshotWeightedItemLevel or "?") ..
                "，军装 " .. (fields.pvpPieces or "0") .. " 件；机器人强度范围 " .. (fields.range or "自动") .. "。"
        end
        if A.matchText then A.matchText:SetText("匹配状态：" .. description) end
    elseif kind == "OK" or kind == "ERROR" then
        if kind=="ERROR" and A.itemsLoading then A.itemsLoading=false;A.MarkItemsDirty() end
        local message = messages[parts[3]] or parts[3] or ""
        local _, _, pieces = string.find(message, "^Final military set pieces=(%d+)")
        if pieces then message = "最终穿戴军装 " .. pieces .. " 件，原装备已保留，等级未改变。" end
        local _,_,main,off,ranged=string.find(message,"^Weapons configured; main=(%d+) off=(%d+) ranged=(%d+)")
        if main then message="本职武器已配置：主手#"..main.."，副手"..(off=="0" and "无" or "#"..off).."，远程"..(ranged=="0" and "无" or "#"..ranged).."；原装备保留在背包，等级不变。" end
        local _,_,mailTarget,envelopes=string.find(message,"^Mail batch committed for (.+): (%d+) envelopes; claim at a mailbox$")
        if mailTarget then message="邮件已提交给角色「"..mailTarget.."」，共 "..envelopes.." 封；请收件角色到邮箱领取附件。" end
        local _,_,requested=string.find(message,"^Removal requested for (%d+) owned party companions; waiting for cleanup%.$")
        if requested then message="已请求移除你的 "..requested.." 个组队机器人，等待服务端清理；实际剩余数量请刷新核实。" end
        if string.sub(message, 1, 8) == "request=" then message = "匹配请求已创建，请查看战场状态。" end
        A.Log((kind == "ERROR" and "操作未完成：" or "") .. message)
    else A.Log(text) end
    return true
end

function A.ShowTab(index)
    A.tab = index
    for i, page in ipairs(A.pages) do if i == index then page:Show() else page:Hide() end end
    for i, b in ipairs(A.tabs) do b:SetText((i == index and "|cffffd060" or "|cffffffff") .. tabs[i] .. "|r") end
    if index == 2 then A.Send("skills status");A.SearchSkills() end
    if index == 3 then A.ShowTeleView(A.teleView or "common") end
    if index == 4 then A.Send("status");if not A.partySpecsLoaded then A.RequestPartySpecs() else A.PaintPartySpecs() end end
    if index == 5 then A.Send("bg status") end
    if index == 7 then A.ShowItemView(A.itemView or "browse") end
end

local partyClasses = { [1]="战士",[2]="圣骑士（联盟）",[3]="猎人",[4]="潜行者",[5]="牧师",[7]="萨满（部落）",[8]="法师",[9]="术士",[11]="德鲁伊" }
local partyTalents = {
    ["fury-dw-pve"]="狂怒（双持）",["protection-pve"]="防护",["retribution-pve"]="惩戒",["holy-pve"]="神圣",
    ["mm-sv-pve"]="射击 / 生存",["combat-swords-pve"]="战斗（剑）",["shadow-pve"]="暗影",
    ["elemental-pve"]="元素",["resto-pve"]="恢复",["enha-resto-pve"]="增强 / 恢复",
    ["arcane-power-frost-pve"]="奥术强化冰霜",["ds-ruin-pve"]="恶魔牺牲 / 毁灭",
    ["balance-pve"]="平衡",["resto-swiftmend-pve"]="恢复（迅捷治愈）",["feral-bear-pve"]="野性（熊）",
}
local partyReasons = { faction="当前阵营不能召唤该职业。",level60="此毕业配置入口要求角色达到60级；不会自动升级。",no_phase6="缺少对应的P6装备模板，暂不提供此专精。" }
function A.RequestPartyStatus()
    A.partyBotStatus={};A.partyStats={};A.partyStatsShown={};A.partyDefense={};A.partyDefenseShown={};A.partyMeta=nil;A.partyRevisionShown=false;A.partyStatusFinished=false
    A.Send("party status")
end
function A.LogPartyTankStats(guid)
    if not guid then return end
    local bot=A.partyBotStatus and A.partyBotStatus[guid]
    local stats=A.partyStats and A.partyStats[guid]
    A.partyStatsShown=A.partyStatsShown or {}
    if not bot or not stats or bot.state~="ready" or tonumber(bot.role)~=3 or A.partyStatsShown[guid] then return end
    local hit,need,miss=tonumber(stats.hitPct),tonumber(stats.hitNeed),tonumber(stats.yellowMiss)
    local verdict="命中参考未返回"
    if hit and need and miss then
        if miss>0.005 or hit+0.005<need then verdict="未达命中参考"
        else verdict="命中达参考" end
    end
    local forms={ ["0"]="人形",["1"]="猫",["5"]="熊",["8"]="巨熊",["17"]="战斗姿态",["18"]="防御姿态",["19"]="狂暴姿态" }
    local form=forms[stats.form or ""] or "当前形态"
    local text="坦克 "..guid.."（"..(stats.currentLevel or bot.level or "?").."级"..form.."） · "..(stats.targetLevel or "?").."级首领近战黄字参考：命中 "..(stats.hitPct or "?").."% / 需 "..(stats.hitNeed or "?").."% · "..verdict
    if stats.yellowMiss then text=text.."（余 "..stats.yellowMiss.."%）" end
    text=text.."；武器技能 "..(stats.weaponSkill or "?").."，防御 "..(stats.defense or "?").."，护甲 "..(stats.armor or "?").."，生命上限 "..(stats.health or "?")
    A.Log(text);A.partyStatsShown[guid]=true
end
function A.LogPartyTankDefense(guid)
    if not guid then return end
    local bot=A.partyBotStatus and A.partyBotStatus[guid]
    local defense=A.partyDefense and A.partyDefense[guid]
    A.partyDefenseShown=A.partyDefenseShown or {}
    if not bot or not defense or bot.state~="ready" or tonumber(bot.role)~=3 or A.partyDefenseShown[guid] then return end
    local block=tonumber(defense.blockPct)
    local blockText=block and block<=0 and "当前格挡不可用" or block and ("格挡值 "..(defense.blockValue or "?")) or "格挡状态未返回"
    A.Log("坦克 "..guid.." · "..(defense.targetLevel or "?").."级常规近战参考：余暴击 "..(defense.critRef or "?").."% / 护甲减伤 "..(defense.armorDr or "?")..
        "%（无额外破甲）；当前闪/招/格 "..(defense.dodgePct or "?").."/"..(defense.parryPct or "?").."/"..(defense.blockPct or "?").."%，"..blockText.."。")
    A.partyDefenseShown[guid]=true
end
function A.PartySpecName(entry)
    return (partyClasses[tonumber(entry.class)] or "未知职业").." · "..(partyTalents[entry.name] or entry.name or "未命名专精")
end
function A.PartySpecAvailable(entry)
    return A.partySpecsLoaded and entry and entry.supported=="1" and (tonumber(entry.gear) or 0)>0 and (tonumber(A.status.level) or 0)>=60
end
function A.PartyClassList()
    local list,seen={},{}
    for _,entry in ipairs(A.partySpecs) do local id=tonumber(entry.class);if id and not seen[id] then table.insert(list,id);seen[id]=true end end
    table.sort(list);return list
end
function A.PartyCurrentSpecs()
    local list={}
    for _,entry in ipairs(A.partySpecs) do if tonumber(entry.class)==A.partyClass then table.insert(list,entry) end end
    return list
end
function A.RequestPartySpecs(force)
    if A.partyLoading and not force then A.Log("正在等待服务端专精目录。");return end
    A.partySpecs={};A.partySpecsLoaded=false;A.partyLoading=true
    A.Send("party specs");A.PaintPartySpecs()
end
function A.PaintPartySpecs()
    if not A.partyClassButton then return end
    local classes=A.PartyClassList();local valid=false
    for _,id in ipairs(classes) do if id==A.partyClass then valid=true end end
    if not valid then
        A.partyClass=classes[1]
        for _,id in ipairs(classes) do if id==tonumber(A.status.class) then A.partyClass=id end end
    end
    local specs=A.PartyCurrentSpecs();local selected=nil
    for _,entry in ipairs(specs) do if entry.id==A.partySelectedSpec then selected=entry end end
    selected=selected or specs[1];A.partySelectedSpec=selected and selected.id or nil
    A.partyClassButton:SetText("职业："..(partyClasses[A.partyClass] or "待加载").." >")
    A.partyTalentButton:SetText(selected and ("天赋："..(partyTalents[selected.name] or selected.name)..(selected.supported=="1" and "" or "（不可用）").." >") or "天赋目录待加载")
    local detail=A.partyLoading and "正在读取服务端真实专精目录；未加载时不会使用随机装备机器人替代。" or "请刷新服务端专精目录。"
    if selected then
        detail=A.PartySpecName(selected).." · "..(roles[tonumber(selected.role)] or "未知职责").." · 专精编号 "..selected.id
        if (tonumber(A.status.level) or 0)<60 then detail=detail.."\n此入口仅限60级；请先明确调整角色等级，不会自动升级。"
        elseif not A.partySpecsLoaded then detail=detail.."\n目录状态已变化，请刷新后召唤。"
        elseif selected.supported~="1" then detail=detail.."\n"..(partyReasons[selected.reason] or "服务端尚未开放此专精。")
        elseif tonumber(selected.role)==3 then detail=detail.."\n坦克以对应P6配装为候选基础；命中优先策略可能修订物品，实际清单请刷新核实。"
        elseif tonumber(selected.role)==4 then detail=detail.."\n治疗使用对应的60级P6毕业装备。"
        else detail=detail.."\n输出围绕你的当前装备强度适配，以该职业真实P6配置为上限。" end
    end
    A.partyDetail:SetText(detail)
    if A.PartySpecAvailable(selected) then A.partySummon:Enable() else A.partySummon:Disable() end
    for index,kind in ipairs({"tank","healer","dps"}) do
        local enabled=false
        for _,entry in ipairs(A.partySpecs) do
            local role=tonumber(entry.role)
            if A.PartySpecAvailable(entry) and ((kind=="tank" and role==3) or (kind=="healer" and role==4) or (kind=="dps" and (role==1 or role==2))) then enabled=true end
        end
        local shortcut=getglobal("AzerothGMPartyAdd"..index)
        if shortcut then if enabled then shortcut:Enable() else shortcut:Disable() end end
    end
end
function A.PartySelectClass()
    local list=A.PartyClassList();if table.getn(list)==0 then A.RequestPartySpecs();return end
    local nextIndex=1
    for i,id in ipairs(list) do if id==A.partyClass then nextIndex=i+1 end end
    if nextIndex>table.getn(list) then nextIndex=1 end
    A.partyClass=list[nextIndex];A.partySelectedSpec=nil;A.PaintPartySpecs()
end
function A.PartySelectTalent()
    local list=A.PartyCurrentSpecs();if table.getn(list)==0 then A.RequestPartySpecs();return end
    local nextIndex=1
    for i,entry in ipairs(list) do if entry.id==A.partySelectedSpec then nextIndex=i+1 end end
    if nextIndex>table.getn(list) then nextIndex=1 end
    A.partySelectedSpec=list[nextIndex].id;A.PaintPartySpecs()
end
function A.SummonPartySpec(entry)
    if (tonumber(A.status.level) or 0)<60 then A.Log("此入口要求60级，不会自动提升你的等级。");return false end
    if not A.partySpecsLoaded then A.Log("请先刷新服务端专精目录；不会回退到随机装备召唤。");A.RequestPartySpecs();return false end
    if not A.PartySpecAvailable(entry) then A.Log((entry and partyReasons[entry.reason]) or "该专精没有可用P6装备，无法召唤。");return false end
    A.Log("请求召唤："..A.PartySpecName(entry))
    A.Send("party add "..entry.id);return true
end
function A.SummonSelectedPartySpec()
    for _,entry in ipairs(A.partySpecs) do if entry.id==A.partySelectedSpec then A.SummonPartySpec(entry);return end end
    A.Log("请选择服务端真实专精后再召唤。");if not A.partySpecsLoaded then A.RequestPartySpecs() end
end
function A.SummonPartyRole(role)
    if (tonumber(A.status.level) or 0)<60 then A.Log("此入口要求60级，不会自动提升你的等级。");return end
    if not A.partySpecsLoaded then A.RequestPartySpecs();A.Log("请等待专精目录加载后再召唤。");return end
    local chosen=nil
    for _,entry in ipairs(A.partySpecs) do
        local r=tonumber(entry.role);local matches=role=="dps" and (r==1 or r==2) or role=="tank" and r==3 or role=="healer" and r==4
        if matches and A.PartySpecAvailable(entry) then
            if not chosen or tonumber(entry.class)==A.partyClass then chosen=entry end
            if entry.id==A.partySelectedSpec then chosen=entry;break end
        end
    end
    if not chosen then A.Log((tonumber(A.status.level) or 0)<60 and "此入口要求60级，不会自动升级。" or "当前阵营没有可用的对应专精，请刷新目录。");return end
    A.partyClass=tonumber(chosen.class);A.partySelectedSpec=chosen.id;A.PaintPartySpecs();A.SummonPartySpec(chosen)
end

local destinationCategories = { city="主城", dungeon="副本", taxi="飞行点", inn="旅馆", other="野外地点", important="重要任务" }
local factionFilters = {{"all","全部"},{"alliance","联盟"},{"horde","部落"},{"neutral","中立"},{"contested","争夺区域"}}
local levelFilters = {{"all","全部副本"},{"10-29","10–29级"},{"30-49","30–49级"},{"50-60","50–60级"},{"raid","60级团队"}}
local levelRanges = { ["10-29"]={10,29}, ["30-49"]={30,49}, ["50-60"]={50,60} }
function A.DestinationName(entry)
    if GetLocale()=="zhCN" then return entry.name or entry.en or "" end
    return entry.en or entry.name or ""
end
function A.FilterDestinations()
    local category=A.destinationCategory or "city"
    local query=string.lower(trim(A.destinationSearch and A.destinationSearch:GetText() or ""))
    local matches={}
    for _,entry in ipairs(AzerothGMDestinations or {}) do
        local accepted=entry.category==category
        if accepted and category=="dungeon" then
            local band=A.destinationLevel or "all"
            if band=="raid" then accepted=entry.raid and true or false
            elseif band~="all" then
                local range=levelRanges[band]
                accepted=not entry.raid and range and (tonumber(entry.minLevel) or 0)>0 and (tonumber(entry.maxLevel) or 0)>=range[1] and (tonumber(entry.minLevel) or 0)<=range[2]
            end
        elseif accepted then
            local faction=A.destinationFaction or "all"
            accepted=faction=="all" or entry.faction==faction
        end
        if accepted and category~="dungeon" and category~="taxi" then local continent=A.destinationContinent or "all";accepted=continent=="all" or entry.continent==continent end
        local names=string.lower((entry.name or "").." "..(entry.en or ""))
        if accepted and (query=="" or string.find(names,query,1,true)) then table.insert(matches,entry) end
    end
    return matches
end
function A.PaintDestinations()
    if not A.destinationRows then return end
    local category=A.destinationCategory or "city"
    local filters=category=="dungeon" and levelFilters or factionFilters
    for i,b in ipairs(A.destinationFilters) do
        local filter=filters[i]
        if filter then
            b.filter=filter[1]
            local selected=category=="dungeon" and (A.destinationLevel or "all") or (A.destinationFaction or "all")
            b:SetText((selected==filter[1] and "|cffffd060" or "|cffffffff")..filter[2].."|r");b:Show()
        else b:Hide() end
    end
    for key,b in pairs(A.destinationCategoryButtons) do b:SetText((category==key and "|cffffd060" or "|cffffffff")..destinationCategories[key].."|r") end
    if A.destinationContinentButton then if category=="dungeon" or category=="taxi" then A.destinationContinentButton:Hide() else A.destinationContinentButton:Show() end end
    A.destinationMatches=A.FilterDestinations()
    local pages=math.max(1,math.ceil(table.getn(A.destinationMatches)/8))
    A.destinationPage=math.max(1,math.min(A.destinationPage or 1,pages))
    for i,b in ipairs(A.destinationRows) do
        local entry=A.destinationMatches[(A.destinationPage-1)*8+i];b.entry=entry
        if entry then
            local detail=""
            if category=="dungeon" then
                detail=entry.raid and "  · 团队" or "  · 副本"
                if (tonumber(entry.minLevel) or 0)>0 then detail=detail.." · 建议 "..entry.minLevel.."–"..(entry.maxLevel or entry.minLevel).."级" end
            elseif category=="other" or category=="important" then local n={alliance="联盟",horde="部落",neutral="中立",contested="争夺",unclassified="未分类"};detail="  · "..(n[entry.faction] or "未分类")
            else
                local names={alliance="联盟",horde="部落",neutral="中立"};detail="  · "..(names[entry.faction] or "")
            end
            b:SetText(A.DestinationName(entry)..detail);b:Show()
        else b:Hide() end
    end
    A.destinationPaging:SetText("共 "..table.getn(A.destinationMatches).." 个地点\n第 "..A.destinationPage.." / "..pages.." 页")
    A.destinationHint:SetText(category=="dungeon" and "等级为推荐区间，不是传送限制。\n普通副本与所选等级档有交集就显示，\n所以同一副本可能出现在相邻档。\n60级团队使用独立筛选。" or "常用地点按阵营分类。\n可用中文或英文名称搜索。\n所有传送仍由服务端校验。")
end
function A.SetDestinationCategory(category)
    A.destinationCategory=category;A.destinationPage=1;A.destinationLevel="all";A.destinationFaction="all"
    if A.destinationSearch then A.destinationSearch:SetText("") end
    A.PaintDestinations()
end
function A.ShowTeleView(view)
    A.teleView=view
    if A.bossTeleFrame then A.bossTeleFrame:Hide() end
    if view=="bosses" then A.teleCommon:Hide();A.teleAdvanced:Hide();A.ShowBossTele()
    elseif view=="advanced" then
        A.teleCommon:Hide();A.teleAdvanced:Show()
        if table.getn(A.teles)==0 then A.SearchTele() else A.PaintTele() end
    else A.teleAdvanced:Hide();A.teleCommon:Show();A.PaintDestinations() end
end

function A.SearchTele()
    if not A.teleSearch then return end
    local query = trim(A.teleSearch:GetText())
    local aliases = { ["暴风城"]="stormwind",["铁炉堡"]="ironforge",["奥格瑞玛"]="orgrimmar",["幽暗城"]="undercity",["雷霆崖"]="thunderbluff",["达纳苏斯"]="darnassus",["纳克萨玛斯"]="nax",["熔火之心"]="molten",["黑翼之巢"]="blackwing",["安其拉"]="ahn",["奥妮克希亚"]="onyxia",["祖尔格拉布"]="zulgurub",["死亡矿井"]="deadmines",["怒焰裂谷"]="ragefire",["影牙城堡"]="shadowfang",["哀嚎洞穴"]="wailing",["血色修道院"]="scarlet",["黑石深渊"]="blackrock",["斯坦索姆"]="stratholme",["通灵学院"]="scholomance",["厄运之槌"]="diremaul",["玛拉顿"]="maraudon" }
    query = aliases[query] or query
    if string.find(query,"[|\r\n]") then A.Log("请输入正常地点名称。");return end
    A.teles = {}
    A.Send("tele " .. (A.teleEntrances and "entrances " or "search ") .. (query ~= "" and query or "all") .. " " .. A.telePage)
end
function A.PaintTele()
    if not A.teleRows then return end
    for i,b in ipairs(A.teleRows) do
        local entry=A.teles[i];b.entry=entry
        if entry then b:SetText((entry.kind=="entrance" and "[副本内部] " or "") .. entry.name .. "  · 地图 " .. entry.map);b:Show() else b:Hide() end
    end
end
function A.Toggle()
    if not A.frame then A.Build() end
    if A.frame:IsShown() then A.frame:Hide() else A.frame:Show(); A.Send("status") end
end

function A.PaintGear()
    if not A.gearRows then return end
    local first = ((A.gearPage or 1) - 1) * 5 + 1
    for i, row in ipairs(A.gearRows) do
        local item = A.gear[first + i - 1]; row.entry = item
        if item then
            row.text:SetText("[" .. item.id .. "] " .. item.name .. "  · 等级 " .. item.level .. " · " .. (roles[tonumber(item.role)] or "通用"))
            row.give:Show(); row.equip:Show()
        else row.text:SetText(""); row.give:Hide(); row.equip:Hide() end
    end
    A.gearPaging:SetText("套装 " .. (A.gearPage or 1) .. " / " .. math.max(1, math.ceil(table.getn(A.gear) / 5)))
end
function A.PaintCatalog()
    if not A.catalogRows then return end
    local query = string.lower(trim(A.catalogFilter:GetText())); local matches = {}
    for _, row in ipairs(AzerothGMCatalog or {}) do
        if query == "" or string.find(string.lower(row.name .. " " .. row.category .. " " .. row.help), query, 1, true) then table.insert(matches, row) end
    end
    A.catalogMatches = matches
    local maxPage = math.max(1, math.ceil(table.getn(matches) / 8))
    if A.catalogPage > maxPage then A.catalogPage = maxPage end
    for i, b in ipairs(A.catalogRows) do
        local row = matches[(A.catalogPage - 1) * 8 + i]; b.entry = row
        if row then b:SetText(row.category .. "  ·  ." .. row.name); b:Show() else b:Hide() end
    end
    A.catalogPaging:SetText("命令 " .. table.getn(matches) .. " 条  · " .. A.catalogPage .. " / " .. maxPage)
end

local function readyUnits()
    local units = {}; local raid = GetNumRaidMembers()
    if raid > 0 then for i = 1, raid do table.insert(units, "raid" .. i) end
    else table.insert(units, "player"); for i = 1, GetNumPartyMembers() do table.insert(units, "party" .. i) end end
    return units
end
function A.ReadyCheck()
    local problems = {}; local hp = integer(A.readyHP, 1, 100); local mana = integer(A.readyMana, 0, 100)
    if not hp or not mana then return false, "请修正生命和法力阈值。" end
    for _, unit in ipairs(readyUnits()) do
        local name = UnitName(unit) or unit
        if not UnitExists(unit) or not UnitIsConnected(unit) then table.insert(problems, name .. "不在线")
        elseif UnitIsDeadOrGhost(unit) then table.insert(problems, name .. "已死亡")
        elseif UnitAffectingCombat(unit) then table.insert(problems, name .. "仍在战斗")
        elseif UnitHealthMax(unit) > 0 and UnitHealth(unit) * 100 / UnitHealthMax(unit) < hp then table.insert(problems, name .. "生命不足")
        elseif UnitPowerType(unit) == 0 and UnitManaMax(unit) > 0 and UnitMana(unit) * 100 / UnitManaMax(unit) < mana then table.insert(problems, name .. "法力不足")
        elseif not UnitIsUnit(unit, "player") and not CheckInteractDistance(unit, 4) then table.insert(problems, name .. "离队长太远") end
    end
    return table.getn(problems) == 0, table.concat(problems, "；")
end

local itemQualities={{4,"史诗（紫）"},{5,"传说（橙）"},{-1,"全部品质"},{0,"粗糙（灰）"},{1,"普通（白）"},{2,"优秀（绿）"},{3,"精良（蓝）"}}
local itemKinds={{"gear","装备"},{"neck","项链"},{"rings","戒指"},{"cloak","披风"},{"trinkets","饰品"},{"weapons","武器"},{"offhand","副手 / 盾"},{"wand","魔杖"},{"materials","材料"},{"bags","背包"},{"all","全部物品"},{"waist","腰带"},{"wrist","护腕"},{"feet","鞋"},{"head","头部"},{"shoulder","肩部"},{"chest","胸部"},{"hands","手套"},{"legs","腿部"}}
local itemClasses={{0,"全部职业"},{1,"战士"},{2,"圣骑士"},{3,"猎人"},{4,"潜行者"},{5,"牧师"},{7,"萨满"},{8,"法师"},{9,"术士"},{11,"德鲁伊"}}
local inventoryNames={[1]="头部",[2]="项链",[3]="肩部",[4]="衬衣",[5]="胸部",[6]="腰部",[7]="腿部",[8]="脚部",[9]="手腕",[10]="手部",[11]="戒指",[12]="饰品",[13]="单手",[14]="盾牌",[15]="远程",[16]="披风",[17]="双手",[18]="背包",[19]="战袍",[20]="长袍",[21]="主手",[22]="副手",[23]="法系副手",[24]="弹药",[25]="投掷",[26]="远程",[27]="箭袋",[28]="圣物"}
local itemColors={[0]="|cff9d9d9d",[1]="|cffffffff",[2]="|cff1eff00",[3]="|cff0070dd",[4]="|cffa335ee",[5]="|cffff8000"}
function A.MarkItemsDirty()
    A.itemsDirty=true;A.PaintItems()
end
function A.PaintItems()
    if not A.itemRows then return end
    A.itemQualityButton:SetText("品质："..itemQualities[A.itemQualityIndex or 1][2].." >")
    A.itemKindButton:SetText("类别："..itemKinds[A.itemKindIndex or 1][2].." >")
    A.itemClassButton:SetText("职业："..itemClasses[A.itemClassIndex or 1][2].." >")
    A.itemBasisButton:SetText(A.itemBasis=="ilvl" and "按物品等级 >" or "按需求等级 >")
    for i,row in ipairs(A.itemRows) do
        local entry=not A.itemsDirty and A.items and A.items[i] or nil
        row.text.entry=entry;row.give.entry=entry;row.mail.entry=entry
        if entry then
            local team=entry.team=="469" and "[联盟] " or entry.team=="67" and "[部落] " or "[通用] "
            local name=(itemColors[tonumber(entry.quality)] or itemColors[1]).."["..(entry.name or "未命名物品").."]|r"
            row.text:SetText(team..name.." · 需"..(entry.level or "?").." / 物等"..(entry.ilvl or "?").." · "..(inventoryNames[tonumber(entry.slot)] or "物品"))
            row.frame:Show()
        else row.frame:Hide() end
    end
    if A.itemsDirty then A.itemPaging:SetText("筛选已变化，请点击搜索。")
    elseif A.itemsLoading then A.itemPaging:SetText("正在查询当前版本物品…")
    else A.itemPaging:SetText("共 "..(A.itemTotal or 0).." 件 · 第 "..(A.itemPage or 1).." 页（每页8件）") end
end
function A.SearchItems()
    if not A.itemMinLevel then return end
    A.MarkItemsDirty()
    local lo=integer(A.itemMinLevel,0,100);local hi=integer(A.itemMaxLevel,0,100)
    if not lo or not hi then return end
    if lo>hi then A.Log("最低等级不能大于最高等级。");return end
    local query=trim(A.itemSearch:GetText())
    if string.find(query,"[|\r\n]") or string.len(query)>120 then A.Log("请缩短关键词并移除换行或竖线。");return end
    A.items={};A.itemsDirty=false;A.itemsLoading=true;A.itemsFinished=false;A.itemMore=false
    A.Send("items search "..lo.." "..hi.." "..itemQualities[A.itemQualityIndex][1].." "..itemKinds[A.itemKindIndex][1].." "..itemClasses[A.itemClassIndex][1].." "..(A.itemPage or 1).." "..(A.itemBasis or "req")..(query~="" and " "..query or ""))
    A.PaintItems()
end
function A.ItemTooltip(owner,entry)
    if not entry then return end
    GameTooltip:SetOwner(owner,"ANCHOR_RIGHT");GameTooltip:SetHyperlink("item:"..entry.id..":0:0:0");GameTooltip:Show()
end
local function recipient(box)
    local name=trim(box:GetText())
    if name=="" or string.find(name,"[%s|\r\n]") or string.len(name)>36 then A.Log("请输入有效的收件角色名（不是账号，可离线）。");return nil end
    return name
end
function A.GiveBrowseItem(entry)
    if not entry then return end
    local n=integer(A.itemQuantity,1,100000);if not n then return end
    confirm("给自己的背包添加 "..(entry.name or entry.id).." × "..n.."？不会自动升级或穿戴。",function() A.Send("item "..entry.id.." "..n) end)
end
function A.MailBrowseItem(entry)
    if not entry then return end
    local target=recipient(A.itemRecipient);local n=integer(A.itemQuantity,1,100000)
    if not target or not n then return end
    confirm("将 "..(entry.name or entry.id).." × "..n.." 邮寄给角色「"..target.."」？成功发送后仍需收件角色到邮箱领取。",function() A.Send("mail item "..target.." "..entry.id.." "..n);A.Log("邮寄指令已发送，等待服务端真实提交结果。") end)
end
function A.MailTier(tier,title,count)
    local target=recipient(A.tierRecipient);if not target then return end
    confirm("将 "..title.."（"..count.."件）寄给角色「"..target.."」？按收件角色职业匹配，低级可收但不会自动升级或穿戴；请到邮箱领取。",function() A.Send("mail set "..tier.." "..target);A.Log("套装邮寄指令已发送，等待服务端真实提交结果。") end)
end
function A.ShowItemView(view)
    A.itemView=view
    A.itemBrowseFrame:Hide();A.tierMailFrame:Hide();A.gearFrame:Hide();A.supplyFrame:Hide();A.raidConsumableFrame:Hide()
    if view=="gear" then
        A.gearFrame:Show();if table.getn(A.gear)==0 then A.Send("gear list") else A.PaintGear() end
    elseif view=="raidconsumables" then A.raidConsumableFrame:Show();A.PaintRaidConsumables()
    elseif view=="supplies" then A.supplyFrame:Show();A.PaintSupplies()
    elseif view=="mail" then
        A.tierMailFrame:Show()
        if trim(A.itemRecipient:GetText())~="" then A.tierRecipient:SetText(A.itemRecipient:GetText()) end
    else
        A.itemView="browse";A.itemBrowseFrame:Show()
        if A.tierRecipient and trim(A.tierRecipient:GetText())~="" then A.itemRecipient:SetText(A.tierRecipient:GetText()) end
        if A.tab==7 and not A.itemsLoaded then A.SearchItems() else A.PaintItems() end
    end
end

function A.Build()
    if A.frame then return end
    A.inputs = {}; A.tabs = {}; A.pages = {}; A.gearRows = {}; A.catalogRows = {}
    local f = CreateFrame("Frame", "AzerothGMPanel", UIParent); A.frame = f
    f:SetWidth(920); f:SetHeight(690); f:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
    f:SetFrameStrata("DIALOG"); f:SetMovable(true); f:EnableMouse(true); f:RegisterForDrag("LeftButton")
    f:SetScript("OnDragStart", function() this:StartMoving() end)
    f:SetScript("OnDragStop", function() this:StopMovingOrSizing() end)
    f:SetBackdrop({bgFile="Interface\\DialogFrame\\UI-DialogBox-Background", edgeFile="Interface\\DialogFrame\\UI-DialogBox-Border", tile=true, tileSize=32, edgeSize=32, insets={left=8,right=8,top=8,bottom=8}})
    label(f, "AzerothGMTitle", "艾泽拉斯 · GM 助手  "..((GetAddOnMetadata and GetAddOnMetadata("AzerothGM","Version")) or "0.6.10"), 25, -20, 760, "GameFontNormalLarge")
    A.summary = label(f, "AzerothGMSummary", "请进入游戏后刷新状态。", 25, -49, 840, "GameFontHighlightSmall")
    local close = CreateFrame("Button", "AzerothGMClose", f, "UIPanelCloseButton"); close:SetPoint("TOPRIGHT", f, "TOPRIGHT", -5, -5)
    close:SetScript("OnClick", function() A.frame:Hide() end)
    for i, name in ipairs(tabs) do
        local index = i
        A.tabs[i] = button(f, "AzerothGMTab" .. i, name, 20 + (i - 1) * 126, -77, 122, function() A.ShowTab(index) end)
        local p = CreateFrame("Frame", "AzerothGMPage" .. i, f); p:SetPoint("TOPLEFT", f, "TOPLEFT", 25, -116); p:SetWidth(870); p:SetHeight(385); A.pages[i] = p
    end
    local function edit(p, name, text, x, y, width)
        local e = input(p, name, text, x, y, width); table.insert(A.inputs, e); return e
    end
    local p = A.pages[1]
    label(p,nil,"角色等级可升可降；所有常用操作固定作用于你自己。",0,0)
    A.level = edit(p,"AzerothGMLevelInput","60",10,-42,75)
    button(p,"AzerothGMSetLevel","设置等级",110,-40,140,function()
        local n=integer(A.level,1,tonumber(A.status.maxLevel) or 60)
        if n then confirm("将自己的角色等级设置为 "..n.."？降级不会自动清除高级技能或所得装备；严格体验低级战场建议使用独立测试角色。",function() A.Send("level "..n); A.Send("status") end) end
    end)
    A.money = edit(p,"AzerothGMMoneyInput","100",350,-42,90)
    label(p,nil,"金币变化（可填负数）",350,-20,210,"GameFontHighlightSmall")
    button(p,"AzerothGMSetMoney","增减金币",465,-40,135,function() local n=integer(A.money,-1000,1000); if n then A.Send("money "..n); A.Send("status") end end)
    button(p,"AzerothGMGoldQuick","+1000 金币",465,-73,135,function() A.Send("money 1000"); A.Send("status") end)
    A.flags = label(p,"AzerothGMFlags","GM 状态待刷新",0,-111)
    for i, item in ipairs({{"gm","GM模式"},{"visible","对外可见"},{"god","无敌"},{"fly","飞行"}}) do
        local key=item[1]; local title=item[2]; local y=-145-(i-1)*37
        label(p,nil,title,10,y-4,180)
        button(p,"AzerothGMFlagOn"..i,"开启",190,y,100,function() A.Send("toggles "..key.." on"); A.Send("status") end)
        button(p,"AzerothGMFlagOff"..i,"关闭",305,y,100,function() A.Send("toggles "..key.." off"); A.Send("status") end)
    end
    label(p,nil,"当前军衔 R0–R14",10,-302,180)
    A.honorRank=edit(p,"AzerothGMHonorRank","6",190,-298,60)
    button(p,"AzerothGMHonorApply","设置军衔",270,-296,120,function()
        local rank=integer(A.honorRank,0,14)
        if rank then confirm("将当前军衔调整为 R"..rank.."？历史最高不会降低；周结算仍可能改变军衔。",function() A.Send("honor rank "..rank); A.Send("status") end) end
    end)
    button(p,"AzerothGMHonorHall","R6 大厅门槛",405,-296,160,function()
        confirm("将当前军衔设为 R6，以满足本阵营军衔大厅门槛？历史最高不降低。",function() A.Send("honor rank 6"); A.Send("status") end)
    end)
    button(p,"AzerothGMRefresh","刷新状态",660,-40,150,function() A.Send("status") end)

    A.BuildSkillPanel(A.pages[2])
    A.gearFrame=CreateFrame("Frame","AzerothGMGear",A.pages[7]);A.gearFrame:SetPoint("TOPLEFT",A.pages[7],"TOPLEFT",0,-35);A.gearFrame:SetWidth(870);A.gearFrame:SetHeight(345)
    p=A.gearFrame
    label(p,nil,"测试套装按职业提供；应用前检查等级和使用条件，旧装备保留。",0,0)
    for i=1,5 do
        local row={}; A.gearRows[i]=row; row.text=label(p,nil,"",0,-27-(i-1)*31,570,"GameFontHighlightSmall")
        row.give=button(p,"AzerothGMGearGive"..i,"领取",590,-22-(i-1)*31,85,function() if row.entry then A.Send("gear give "..row.entry.id) end end)
        row.equip=button(p,"AzerothGMGearEquip"..i,"应用",690,-22-(i-1)*31,85,function()
            if row.entry then local id=row.entry.id; confirm("应用这个测试套装？原装备将保留到背包（空间不足时操作会拒绝）。",function() A.Send("gear equip "..id); A.Send("status") end) end
        end)
    end
    A.gearPaging=label(p,nil,"套装待加载",0,-187,260,"GameFontHighlightSmall")
    button(p,"AzerothGMGearPrev","上一页",280,-180,105,function() A.gearPage=math.max(1,(A.gearPage or 1)-1); A.PaintGear() end)
    button(p,"AzerothGMGearNext","下一页",395,-180,105,function() A.gearPage=math.min(math.max(1,math.ceil(table.getn(A.gear)/5)),(A.gearPage or 1)+1); A.PaintGear() end)
    button(p,"AzerothGMGearReload","刷新套装",510,-180,105,function() A.gear={}; A.Send("gear list") end)
    label(p,nil,"军衔六件套数量",0,-226,150); A.pvp=edit(p,"AzerothGMPvpPieces","2",155,-222,50)
    A.pvpQuality="blue"; A.pvpButton=button(p,"AzerothGMPvpQuality","蓝色军装",230,-220,125,function()
        A.pvpQuality=A.pvpQuality=="blue" and "epic" or "blue"; A.pvpButton:SetText(A.pvpQuality=="blue" and "蓝色军装" or "紫色军装")
    end)
    button(p,"AzerothGMPvpEquip","配置军装",370,-220,125,function()
        local n=integer(A.pvp,0,6)
        if n then confirm("配置 "..n.." 件真实军衔套装？不改变等级；必要的测试军衔将按服务端规则处理，旧装备保留。",function() A.Send("gear pvp "..n.." "..A.pvpQuality); A.Send("status") end) end
    end)
    button(p,"AzerothGMWeaponsEquip","配置本职完整武器",510,-220,310,function()
        confirm("配置主手、副手及本职远程（布甲含法系副手与魔杖）？优先本阵营军衔装备，缺少该类别时用真实合法物品补位；历史军衔可能升至所选装备最低要求（最高R14）。不会升级或学习新武器技能，旧装备保留背包。",function()
            A.Send("gear weapons");A.Send("status")
        end)
    end)
    A.itemId=edit(p,"AzerothGMItemId","",10,-270,100); A.itemCount=edit(p,"AzerothGMItemCount","1",125,-270,45)
    button(p,"AzerothGMGiveItem","领取物品ID / 数量",190,-268,170,function() local id=integer(A.itemId,1,1000000);local n=integer(A.itemCount,1,100000);if id and n then A.Send("item "..id.." "..n) end end)

    p=A.pages[3]
    A.teleCommon=CreateFrame("Frame","AzerothGMTeleCommon",p);A.teleCommon:SetAllPoints(p)
    A.teleAdvanced=CreateFrame("Frame","AzerothGMTeleAdvancedFrame",p);A.teleAdvanced:SetAllPoints(p)
    A.BuildBossTelePanel(p)
    p=A.teleCommon
    A.destinationCategory="city";A.destinationFaction="all";A.destinationContinent="all";A.destinationLevel="all";A.destinationPage=1
    A.destinationCategoryButtons={}
    for i,item in ipairs({{"city","主城","City"},{"dungeon","副本","Dungeon"},{"taxi","飞行点","Taxi"},{"inn","旅馆","Inn"},{"other","野外地点","Other"},{"important","重要任务","Important"}}) do
        local key=item[1]
        A.destinationCategoryButtons[key]=button(p,"AzerothGMTeleCategory"..item[3],item[2],(i-1)*90,0,84,function() A.SetDestinationCategory(key) end)
    end
    button(p,"AzerothGMTeleAdvanced","高级：编号 / 坐标",690,0,150,function() A.ShowTeleView("advanced") end)
    A.destinationFilters={}
    for i=1,5 do
        A.destinationFilters[i]=button(p,"AzerothGMTeleFilter"..i,"",(i-1)*126,-35,120,function()
            if A.destinationCategory=="dungeon" then A.destinationLevel=this.filter else A.destinationFaction=this.filter end
            A.destinationPage=1;A.PaintDestinations()
        end)
    end
    local continents={{"all","全部大陆"},{"kalimdor","卡利姆多"},{"eastern","东部王国"}}
    A.destinationContinentButton=button(p,"AzerothGMTeleContinent","全部大陆 >",650,-35,190,function()
        local index=1;for i,e in ipairs(continents) do if e[1]==A.destinationContinent then index=i end end
        index=index+1;if index>table.getn(continents) then index=1 end;A.destinationContinent=continents[index][1];A.destinationContinentButton:SetText(continents[index][2].." >");A.destinationPage=1;A.PaintDestinations()
    end)
    A.destinationSearch=edit(p,"AzerothGMDestinationSearch","",10,-75,365)
    A.destinationSearch:SetScript("OnTextChanged",function() A.destinationPage=1;A.PaintDestinations() end)
    A.destinationSearch:SetScript("OnEnterPressed",function() this:ClearFocus();A.destinationPage=1;A.PaintDestinations() end)
    button(p,"AzerothGMDestinationFind","按名称搜索",395,-72,145,function() A.destinationPage=1;A.PaintDestinations() end)
    A.destinationRows={}
    for i=1,8 do
        local b=button(p,"AzerothGMDestinationRow"..i,"",0,-108-(i-1)*26,560,function()
            if this.entry then local entry=this.entry;confirm("传送到 "..A.DestinationName(entry).."？",function() A.Send(entry.command) end) end
        end);A.destinationRows[i]=b;b:Hide()
    end
    A.destinationPaging=label(p,"AzerothGMDestinationPaging","",580,-115,250,"GameFontHighlightSmall")
    button(p,"AzerothGMDestinationPrev","上一页",580,-162,110,function() A.destinationPage=math.max(1,A.destinationPage-1);A.PaintDestinations() end)
    button(p,"AzerothGMDestinationNext","下一页",700,-162,110,function() A.destinationPage=A.destinationPage+1;A.PaintDestinations() end)
    A.destinationHint=label(p,"AzerothGMDestinationHint","",580,-210,255,"GameFontHighlightSmall")
    A.PaintDestinations()
    p=A.teleAdvanced
    label(p,nil,"高级传送：完整原始目录、内部入口、地点编号及任意有效坐标",0,0,590,"GameFontHighlightSmall")
    button(p,"AzerothGMTeleBack","返回常用分类",680,0,155,function() A.ShowTeleView("common") end)
    A.teleSearch=edit(p,"AzerothGMTeleSearch","",10,-42,280)
    button(p,"AzerothGMTeleFind","搜索地点",305,-39,110,function() A.telePage=1; A.SearchTele() end)
    A.teleKind=button(p,"AzerothGMTeleKind","全部预设地点",430,-39,180,function()
        A.teleEntrances=not A.teleEntrances; A.teleKind:SetText(A.teleEntrances and "副本内部入口" or "全部预设地点"); A.telePage=1;A.SearchTele()
    end)
    A.teleRows={}
    for i=1,8 do
        local b=button(p,"AzerothGMTeleRow"..i,"",0,-75-(i-1)*24,560,function()
            if this.entry then local e=this.entry;confirm("传送到 "..e.name.."？",function() A.Send("tele "..(e.kind=="entrance" and "entrance " or "id ")..e.id) end) end
        end);A.teleRows[i]=b;b:Hide()
    end
    A.telePaging=label(p,nil,"地点目录待加载",580,-80,265,"GameFontHighlightSmall")
    button(p,"AzerothGMTelePrev","上一页",580,-111,110,function() if A.telePage>1 then A.telePage=A.telePage-1;A.SearchTele() end end)
    button(p,"AzerothGMTeleNext","下一页",700,-111,110,function() if A.teleMore then A.telePage=A.telePage+1;A.SearchTele() end end)
    label(p,nil,"支持中文常用名或英文名称搜索。\n副本内部直传仍受原生地图校验；\n战场必须走排队与邀请。",580,-157,260,"GameFontHighlightSmall")
    A.teleId=edit(p,"AzerothGMTeleId","275",590,-229,85)
    button(p,"AzerothGMTeleById","按地点编号传送",690,-227,145,function() local id=integer(A.teleId,1,1000000);if id then A.Send("tele id "..id) end end)
    label(p,nil,"坐标直传：X / Y / Z / 地图编号 / 朝向（可选）",0,-279,830,"GameFontHighlightSmall")
    A.x=edit(p,"AzerothGMTeleX","",10,-304,110);A.y=edit(p,"AzerothGMTeleY","",130,-304,110);A.z=edit(p,"AzerothGMTeleZ","",250,-304,100);A.map=edit(p,"AzerothGMTeleMap","0",365,-304,70);A.orientation=edit(p,"AzerothGMTeleOrientation","",450,-304,85)
    button(p,"AzerothGMTeleXYZ","按坐标传送",560,-301,180,function()
        local x,y,z=tonumber(trim(A.x:GetText())),tonumber(trim(A.y:GetText())),tonumber(trim(A.z:GetText()));local map=integer(A.map,0,10000)
        if not x or not y or not z or not map then A.Log("请填写有效的 X、Y、Z 和地图编号。");return end
        local cmd="tele xyz "..x.." "..y.." "..z.." "..map;local o=trim(A.orientation:GetText());if o~="" then if not tonumber(o) then A.Log("朝向必须是数字。");return end;cmd=cmd.." "..o end
        confirm("确认传送到指定地图和坐标？请使用已知有效位置。",function() A.Send(cmd) end)
    end)

    A.ShowTeleView("common")

    p=A.pages[4]
    label(p,nil,"60级副本队友：点击职业 / 天赋按钮切换；没有的天赋或装备不会随机冒充。",0,0,840,"GameFontHighlightSmall")
    A.partyClassButton=button(p,"AzerothGMPartyClass","职业目录待加载",0,-31,165,function() A.PartySelectClass() end)
    A.partyTalentButton=button(p,"AzerothGMPartyTalent","天赋目录待加载",180,-31,270,function() A.PartySelectTalent() end)
    A.partySummon=button(p,"AzerothGMPartySummon","召唤所选专精",465,-31,165,function() A.SummonSelectedPartySpec() end)
    button(p,"AzerothGMPartyRefresh","刷新专精",645,-31,155,function() A.RequestPartySpecs(true) end)
    A.partyDetail=label(p,"AzerothGMPartyDetail","",0,-70,840,"GameFontHighlightSmall")
    for i,item in ipairs({{"tank","快捷：坦克配装"},{"healer","快捷：P6治疗"},{"dps","快捷：适配输出"}}) do
        local role=item[1];button(p,"AzerothGMPartyAdd"..i,item[2],(i-1)*215,-113,205,function() A.SummonPartyRole(role) end)
    end
    button(p,"AzerothGMPartyCome","集合到我身边",0,-154,165,function() A.Send("partybot cometome",true) end)
    button(p,"AzerothGMPartyPause","暂停全队",175,-154,165,function() A.Send("partybot pause all",true) end)
    button(p,"AzerothGMPartyUnpause","恢复全队",350,-154,165,function() A.Send("partybot unpause all",true) end)
    button(p,"AzerothGMPartyAttackStop","停止攻击当前目标",525,-154,185,function() A.Send("partybot attackstop",true) end)
    label(p,nil,"开怪检查：最低生命 %",0,-205,210);A.readyHP=edit(p,"AzerothGMReadyHP","90",215,-201,55)
    label(p,nil,"最低法力 %",300,-205,120);A.readyMana=edit(p,"AzerothGMReadyMana","80",425,-201,55)
    button(p,"AzerothGMReady","检查队伍状态",510,-198,185,function() local ready,why=A.ReadyCheck();A.Log(ready and "全队达到血蓝和集合条件；仍需确认视线和站位。" or why) end)
    button(p,"AzerothGMReadyPull","就绪后拉当前目标",0,-242,235,function()
        if not UnitExists("target") or not UnitCanAttack("player","target") then A.Log("请先选中要拉的敌人。");return end
        local ready,why=A.ReadyCheck();if not ready then A.Log(why);return end
        confirm("血蓝和集合检查已通过。确认让坦克拉当前选中目标？",function()
            local stillReady,reason=A.ReadyCheck();if not stillReady then A.Log(reason);return end
            A.Send("partybot pull 10000",true)
        end)
    end)
    button(p,"AzerothGMPartyStatusRefresh","刷新机器人状态",510,-242,185,function() A.RequestPartyStatus() end)
    button(p,"AzerothGMPartyRemoveMine","移除我的机器人",250,-242,245,function()
        confirm("移除由你召唤的组队机器人（含等待载入者）？不会影响其他人的队友、战场机器人或真人。",function()
            A.Send("party remove all")
            A.Log("已发送移除请求；实际剩余数量以服务端状态为准，可再次手动刷新确认。")
            A.RequestPartyStatus()
        end)
    end)
    label(p,nil,"建议先召坦克和治疗；无P6毕业治疗时，服务端为最后空位保留治疗。\n集合回血回蓝后再检查；副本机制与危险站位仍需手动判断。\n生存参考按63级默认5%常规近战、无额外破甲，不代表首领实战结果。",0,-287,840,"GameFontHighlightSmall")
    A.PaintPartySpecs()

    p=A.pages[5]
    label(p,nil,"流程：选等级 → 配装/学技能 → 恢复正常战斗状态 → 排队 → 开启机器人匹配 → 接受邀请",0,0,840,"GameFontHighlightSmall")
    A.bgButton=button(p,"AzerothGMBgType",bgNames[A.bg],0,-38,180,function() A.bg=A.bg==3 and 1 or A.bg+1;A.bgButton:SetText(bgNames[A.bg]) end)
    label(p,nil,"等级",205,-43,45); A.bgLevel=edit(p,"AzerothGMBgLevel","60",255,-39,65)
    button(p,"AzerothGMBgApplyLevel","设置该等级",340,-37,125,function() local n=integer(A.bgLevel,10,60);if n then confirm("将自己设为 "..n.." 级？",function() A.Send("level "..n);A.Send("status") end) end end)
    button(p,"AzerothGMBgNormal","恢复正常战斗状态",485,-37,190,function()
        A.Send("toggles god off");A.Send("toggles fly off");A.Send("toggles visible on");A.Send("toggles gm off");A.Send("status")
    end)
    label(p,nil,"装备强度范围 %（装备等级的参考分，不等同精确战斗力）",0,-91,650,"GameFontHighlightSmall")
    A.scoreMin=edit(p,"AzerothGMScoreMin","85",10,-119,65);A.scoreMax=edit(p,"AzerothGMScoreMax","115",100,-119,65)
    A.autoPvp=CreateFrame("CheckButton","AzerothGMAutoPvp",p,"UICheckButtonTemplate");A.autoPvp:SetPoint("TOPLEFT",p,"TOPLEFT",210,-111);A.autoPvp:SetChecked(1)
    label(p,nil,"军装件数自动浮动",250,-119,190,"GameFontHighlightSmall")
    label(p,nil,"或指定最少 / 最多件数",455,-119,220,"GameFontHighlightSmall")
    A.pvpMin=edit(p,"AzerothGMPvpMin","1",670,-119,50);A.pvpMax=edit(p,"AzerothGMPvpMax","4",740,-119,50)
    button(p,"AzerothGMBgOpen","1. 打开战场排队窗口",0,-166,235,function() A.Send("bg open "..bgKeys[A.bg]) end)
    button(p,"AzerothGMBgMatch","2. 已排队，开始匹配",250,-166,235,function()
        local n=integer(A.bgLevel,10,60);local lo=integer(A.scoreMin,25,300);local hi=integer(A.scoreMax,25,300)
        if not n or not lo or not hi then return end
        if lo>hi then A.Log("最低装备强度不能大于最高值。");return end
        local cmd="bg match "..bgKeys[A.bg].." "..n.." "..(lo/100).." "..(hi/100)
        if not A.autoPvp:GetChecked() then local a=integer(A.pvpMin,0,6);local b=integer(A.pvpMax,0,6);if not a or not b or a>b then A.Log("请检查军装件数范围。");return end;cmd=cmd.." "..a.." "..b end
        A.Send(cmd);A.Send("bg status")
    end)
    button(p,"AzerothGMBgCancel","取消本次机器人请求",500,-166,235,function() A.Send("bg cancel");A.Send("bg status") end)
    A.matchText=label(p,"AzerothGMMatchStatus","匹配状态：尚未开始",0,-215,835,"GameFontHighlightSmall")
    A.teamText=label(p,"AzerothGMBgTeams","战歌10对10／阿拉希15对15／奥山40对40；治疗占每方1/5，其余职业随机。",0,-310,835,"GameFontHighlightSmall")
    A.autoText=label(p,"AzerothGMAutoStatus","自动补人状态待刷新。",0,-252,835,"GameFontHighlightSmall")
    label(p,nil,"战歌10级起，阿拉希20级起，奥山51级起；低等级使用真实可装备物品。",0,-278,835,"GameFontHighlightSmall")
    label(p,nil,"排队与邀请仍由原生战场窗口处理；等级调整不等于已经配好装备与技能。",0,-293,835,"GameFontHighlightSmall")

    p=A.pages[6]
    A.catalogFilter=edit(p,"AzerothGMCatalogFilter","",10,-6,360);A.catalogFilter:SetScript("OnTextChanged",function() A.catalogPage=1;A.PaintCatalog() end)
    label(p,nil,"按命令名、中文类别或帮助搜索",390,-10,420,"GameFontHighlightSmall")
    for i=1,8 do
        local b=button(p,"AzerothGMCatalogRow"..i,"",0,-40-(i-1)*26,430,function()
            if this.entry then A.command:SetText(this.entry.name);A.commandHelp:SetText(this.entry.help~="" and this.entry.help or "可点击服务端帮助，按说明填写参数。") end
        end);A.catalogRows[i]=b
    end
    A.catalogPaging=label(p,nil,"",455,-44,360,"GameFontHighlightSmall")
    button(p,"AzerothGMCatalogPrev","上一页",455,-73,110,function() A.catalogPage=math.max(1,A.catalogPage-1);A.PaintCatalog() end)
    button(p,"AzerothGMCatalogNext","下一页",575,-73,110,function() A.catalogPage=A.catalogPage+1;A.PaintCatalog() end)
    A.command=edit(p,"AzerothGMCommand","",465,-115,350)
    A.commandArgs=edit(p,"AzerothGMCommandArgs","",465,-155,350)
    A.commandHelp=label(p,nil,"上框是命令，下框是参数。原生命令按服务端的目标规则执行。",455,-190,365,"GameFontHighlightSmall")
    button(p,"AzerothGMCommandHelp","服务端帮助",455,-270,130,function() A.Send("help "..trim(A.command:GetText()),true) end)
    button(p,"AzerothGMCommandSend","执行原生命令",600,-270,170,function()
        local cmd=trim(A.command:GetText());local args=trim(A.commandArgs:GetText());if cmd=="" then return end
        confirm("执行 ."..cmd.." "..args.."？原生命令可能作用于当前选中目标。",function() A.Send(cmd..(args~="" and " "..args or ""),true) end)
    end)
    p=A.pages[7]
    for i,entry in ipairs({{"browse","物品浏览"},{"gear","配装 / 军装"},{"supplies","材料 / 食水"},{"raidconsumables","副本消耗品"},{"mail","套装邮件"}}) do
        local view,title=entry[1],entry[2];button(p,"AzerothGMItemView"..i,title,(i-1)*172,0,165,function() A.ShowItemView(view) end)
    end
    A.BuildSupplyPanel(p)
    A.BuildRaidConsumables(p)
    A.itemBrowseFrame=CreateFrame("Frame","AzerothGMItemBrowse",p);A.itemBrowseFrame:SetPoint("TOPLEFT",p,"TOPLEFT",0,-35);A.itemBrowseFrame:SetWidth(870);A.itemBrowseFrame:SetHeight(345)
    A.tierMailFrame=CreateFrame("Frame","AzerothGMTierMail",p);A.tierMailFrame:SetPoint("TOPLEFT",p,"TOPLEFT",0,-35);A.tierMailFrame:SetWidth(870);A.tierMailFrame:SetHeight(345)
    p=A.itemBrowseFrame
    A.itemQualityIndex=3;A.itemKindIndex=11;A.itemClassIndex=1;A.itemBasis="req";A.itemPage=1;A.items={}
    label(p,nil,"等级",0,-5,45);A.itemMinLevel=edit(p,"AzerothGMItemMin","0",50,-1,45)
    label(p,nil,"–",100,-5,15);A.itemMaxLevel=edit(p,"AzerothGMItemMax","60",125,-1,45)
    A.itemBasisButton=button(p,"AzerothGMItemBasis","",185,0,140,function() A.itemBasis=A.itemBasis=="req" and "ilvl" or "req";A.itemPage=1;A.MarkItemsDirty() end)
    A.itemQualityButton=button(p,"AzerothGMItemQuality","",340,0,140,function() A.itemQualityIndex=A.itemQualityIndex+1;if A.itemQualityIndex>table.getn(itemQualities) then A.itemQualityIndex=1 end;A.itemPage=1;A.MarkItemsDirty() end)
    A.itemKindButton=button(p,"AzerothGMItemKind","",495,0,175,function() A.itemKindIndex=A.itemKindIndex+1;if A.itemKindIndex>table.getn(itemKinds) then A.itemKindIndex=1 end;A.itemPage=1;A.MarkItemsDirty() end)
    A.itemClassButton=button(p,"AzerothGMItemClass","",685,0,160,function() A.itemClassIndex=A.itemClassIndex+1;if A.itemClassIndex>table.getn(itemClasses) then A.itemClassIndex=1 end;A.itemPage=1;A.MarkItemsDirty() end)
    A.itemSearch=edit(p,"AzerothGMItemSearch","",10,-40,325);A.itemSearch:SetMaxLetters(80)
    for _,box in ipairs({A.itemMinLevel,A.itemMaxLevel,A.itemSearch}) do box:SetScript("OnTextChanged",function() A.itemPage=1;A.MarkItemsDirty() end) end
    A.itemSearch:SetScript("OnEnterPressed",function() A.itemPage=1;A.SearchItems() end)
    button(p,"AzerothGMItemFind","搜索物品",350,-37,100,function() A.itemPage=1;A.SearchItems() end)
    label(p,nil,"收件角色",475,-43,85);A.itemRecipient=edit(p,"AzerothGMItemRecipient",UnitName("player") or "",570,-40,125)
    label(p,nil,"数量",715,-43,45);A.itemQuantity=edit(p,"AzerothGMItemQuantity","1",770,-40,60)
    A.itemQuantity:SetScript("OnEnter",function() GameTooltip:SetOwner(this,"ANCHOR_RIGHT");GameTooltip:SetText("领取／邮寄每次1–100000件；领取需背包能完整容纳；邮寄最多1000个堆叠，每堆一封邮件。唯一物品仍受限制。");GameTooltip:Show() end)
    A.itemQuantity:SetScript("OnLeave",function() GameTooltip:Hide() end)
    A.itemRows={}
    for i=1,8 do
        local row={};row.frame=CreateFrame("Frame","AzerothGMItemRow"..i,p);row.frame:SetWidth(850);row.frame:SetHeight(24);row.frame:SetPoint("TOPLEFT",p,"TOPLEFT",0,-80-(i-1)*26)
        row.text=button(row.frame,"AzerothGMItemRowText"..i,"",0,0,595,function() end);row.text:SetHeight(24)
        row.text:SetScript("OnEnter",function() A.ItemTooltip(this,this.entry) end);row.text:SetScript("OnLeave",function() GameTooltip:Hide() end)
        row.give=button(row.frame,"AzerothGMItemGive"..i,"给自己",610,0,95,function() A.GiveBrowseItem(this.entry) end);row.give:SetHeight(24)
        row.mail=button(row.frame,"AzerothGMItemMail"..i,"邮寄",720,0,95,function() A.MailBrowseItem(this.entry) end);row.mail:SetHeight(24)
        A.itemRows[i]=row;row.frame:Hide()
    end
    A.itemPaging=label(p,"AzerothGMItemPaging","",0,-313,325,"GameFontHighlightSmall")
    button(p,"AzerothGMItemPrev","上一页",330,-307,90,function() if (A.itemPage or 1)>1 then A.itemPage=A.itemPage-1;A.SearchItems() end end)
    button(p,"AzerothGMItemNext","下一页",435,-307,90,function() if A.itemMore then A.itemPage=A.itemPage+1;A.SearchItems() end end)
    button(p,"AzerothGMTierMailOpen","套装邮件 T1 / T2 / T2.5 / T3",585,-307,260,function() A.ShowItemView("mail") end)
    p=A.tierMailFrame
    label(p,nil,"职业套装邮件：按收件角色的职业匹配，不要求发送者同职业。",0,0,620,"GameFontHighlightSmall")
    button(p,"AzerothGMItemBrowseBack","返回物品浏览",650,0,190,function() A.ShowItemView("browse") end)
    label(p,nil,"收件角色名（可离线）",0,-58,200);A.tierRecipient=edit(p,"AzerothGMTierRecipient",UnitName("player") or "",215,-54,245)
    label(p,nil,"低级角色可以收到邮件；不会自动升级或穿戴，装备条件仍由游戏规则限制。",0,-99,840,"GameFontHighlightSmall")
    for i,tier in ipairs({{"t1","T1",8},{"t2","T2",8},{"t2.5","T2.5",5},{"t3","T3",9}}) do
        local key,title,n=tier[1],tier[2],tier[3]
        button(p,"AzerothGMMailTier"..i,"邮寄 "..title.."（"..n.."件）",(i-1)*210,-139,195,function() A.MailTier(key,title,n) end)
    end
    label(p,nil,"服务端提交成功只代表邮件已写入收件箱，尚未领取。\n请收件角色到邮箱取附件；非法目标、数量或阵营物品会被服务端拒绝。",0,-195,840,"GameFontHighlightSmall")
    A.ShowItemView("browse")

    A.PaintCatalog()
    label(f,nil,"操作结果",25,-510,820)
    A.logText=label(f,"AzerothGMLog","",25,-536,855,"GameFontHighlightSmall")
    f:SetScript("OnHide",function() clearFocus() end)
    local elapsed=0
    f:SetScript("OnUpdate",function()
        elapsed=elapsed+arg1
        if elapsed>4 then elapsed=0;if A.tab==5 then A.Send("bg status") end end
    end)
    A.ShowTab(1);f:Hide()
end

SLASH_AZEROTHGM1="/gmui";SLASH_AZEROTHGM2="/agm"
SlashCmdList["AZEROTHGM"]=function() A.Toggle() end
SLASH_AZEROTHGMLEVEL1="/level"
SlashCmdList["AZEROTHGMLEVEL"]=function(text)
    local n=tonumber(trim(text));if not n or n~=math.floor(n) or n<1 or n>60 then A.Log("用法：/level 1–60");return end
    A.Send("level "..n)
end
SLASH_AZEROTHGMGO1="/go"
SlashCmdList["AZEROTHGMGO"]=function(text)
    local key=string.lower(trim(text));local allowed={naxx=true,stormwind=true,ironforge=true,orgrimmar=true}
    if allowed[key] then A.Send("tele "..key) else A.Log("可用位置：naxx、stormwind、ironforge、orgrimmar") end
end

local events=CreateFrame("Frame","AzerothGMEvents",UIParent)
events:RegisterEvent("PLAYER_LOGIN");events:RegisterEvent("CHAT_MSG_SYSTEM")
events:SetScript("OnEvent",function()
    if event=="PLAYER_LOGIN" then
        A.Build()
        A.launch=button(UIParent,"AzerothGMLauncher","GM 面板",-155,-210,130,function() A.Toggle() end)
        A.launch:ClearAllPoints();A.launch:SetPoint("TOPRIGHT",UIParent,"TOPRIGHT",-20,-210)
        A.Log("GM 助手已加载，点击右侧按钮或输入 /gmui。")
    elseif event=="CHAT_MSG_SYSTEM" then A.HandleMessage(arg1) end
end)
-- Protocol replies belong in the panel rather than the ordinary chat window.
local stockChatEvent=ChatFrame_OnEvent
function ChatFrame_OnEvent(...)
    if event=="CHAT_MSG_SYSTEM" and type(arg1)=="string" and string.sub(arg1,1,5)=="GMUI|" then return end
    return stockChatEvent(unpack(arg))
end
