# 技能 ID 提示（原版 1.12）

启用插件后，将鼠标移到法术书、动作条或宠物技能图标，提示框底部增加技能 ID。
不需要 GM 权限，不学习或删除技能，不操作服务器或数据库。

原版没有 GetSpellLink/GetSpellInfo。此插件使用安装数据中的技能名称与等级进行精确匹配；
同名同级有多个 ID 时明确显示“同名同级候选”，不保证能唯一识别这些记录。
宠物栏的攻击、跟随、停留指令不显示技能 ID。宏与物品动作不显示推测的技能 ID。
技能超出本地数据库或使用其他语言时不显示；当前发行包包含中文和英文数据。

开发时从本机客户端的 Spell.dbc 生成 SpellNames.lua：

    python3 tools/build_spell_id_names.py AddOns/AzerothSpellID/SpellNames.lua zhCN-Spell.dbc enUS-Spell.dbc

生成的数据不提交 Git。安装包需要包含该文件。验证脚本 tests/verify_spell_id_addon.py
在实际中文客户端 Lua 环境检查加载、已注入元数据的玩家/宠物悬停适配，
以及宠物指令和空动作不显示ID；它不等同于登录角色后的鼠标实测。
