-- Original 1.12 has no GetSpellLink/GetSpellInfo API. Resolve the exact localized
-- name AND rank against the installed client's DBC; never mistake a book index
-- or an action-bar slot for a spell ID. Same-name collisions remain explicit.
AzerothSpellID = {}
local A = AzerothSpellID
local function annotate(tooltip, ids, pet)
    if not ids or table.getn(ids) == 0 then return end
    local label = pet and "宠物技能 ID" or "技能 ID"
    local values = {}
    for i = 1, math.min(table.getn(ids), 8) do values[i] = tostring(ids[i]) end
    if table.getn(ids) > 1 then label = label .. "（同名同级候选）" end
    local text = table.concat(values, ", ")
    if table.getn(ids) > 8 then text = text .. " …共" .. table.getn(ids) .. "个" end
    tooltip:AddLine(label .. ": " .. text, 0.35, 0.85, 1)
    tooltip:Show()
end
function A.Resolve(name, rank)
    if not name or not AzerothSpellIDNames then return nil end
    return AzerothSpellIDNames[name .. "\001" .. (rank or "")]
end
local function fromTitle(tooltip, pet)
    local name = tooltip:GetName()
    if not name then return end
    local left = getglobal(name .. "TextLeft1")
    local right = getglobal(name .. "TextRight1")
    if not left then return end
    local rank = right and right:IsShown() and right:GetText() or ""
    annotate(tooltip, A.Resolve(left:GetText(), rank), pet)
end
local function hook(method, after)
    local original = GameTooltip[method]
    if type(original) ~= "function" then return end
    GameTooltip[method] = function(self, a, b, c)
        local result = original(self, a, b, c)
        after(self, a, b, c)
        return result
    end
end
hook("SetSpell", function(self, slot, book)
    local name, rank = GetSpellName(slot, book)
    annotate(self, A.Resolve(name, rank), book == "pet")
end)
hook("SetPetAction", function(self, slot)
    local name, rank, texture, token = GetPetActionInfo(slot)
    -- Attack/follow/stay are command tokens, not learned pet spells.
    if token then return end
    annotate(self, A.Resolve(name, rank), true)
end)
hook("SetAction", function(self, slot)
    -- Item and macro actions must not acquire a guessed spell ID.
    if GetActionText(slot) or GetActionCount(slot) > 0 or IsConsumableAction(slot) then return end
    fromTitle(self, false)
end)
