# EzDismount施法目标保护

面向WoW1.12的EzDismount2.03，作为独立插件加载，第三方源码保持不变。0.2.0不再仅以“目标能攻击或能协助”放行；只允许当前动作栏法术通过本机生成的明确目标类型、目标生物类别、原生动作射程、可用资源及冷却检查后，响应本次骑乘错误下马。

无目标、死亡目标、敌友类型不符、受限生物类别不符、射程不明或超距时保留骑乘。记录只保留0.75秒，目标改变或没有本次动作记录时拒绝；不自动重试施法，不增加施法次数。显式自身目标、宏、物品、直接CastSpell入口、歧义或复杂法术目标类型均保守地要求手动下马。即使这些检查通过，也不保证服务端视线、特定任务/阶段条件或每个技能的全部资格。

`/ezguard`显示版本及最近一次保护原因。正常施法入口仍调用原始函数，无法检查时也保留原始施法尝试；仅阻止自动取消骑乘。NPC交互、手动下马等原EzDismount独立入口仍保留。

本地数据用`python3 tools/build_dismount_targets.py Spell.dbc CreatureType.dbc /安装目录/SpellTargets.lua`生成；必须来自当前客户端的同一补丁链。源码仅有空占位，缺数据时不自动下马。生成数据不得公开提交或收入源码包。

验证：`lua tests/verify_dismount_guard.lua`、`python3 tests/test_dismount_targets.py`；旧Lua语义使用`python3 tests/run_talent_vm.py --fixture tests/verify_dismount_guard.lua --source AddOns/AzerothDismountGuard/AzerothDismountGuard.lua`。这些是实际Lua模块在受控API桩下的验证，不代替游戏内验收。关联ISSUE-0064。
