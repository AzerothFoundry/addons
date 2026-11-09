# AzerothFoundry addons

面向标准 WoW 1.12.1 的插件套件源码。部署入口为同组织 `realm`，此仓库独立维护插件和第三方来源清单。

| 插件 | 功能 |
| --- | --- |
| AzerothGM | 自定义服务器 GM 面板 |
| AzerothConvenience | 背包整理、自动卖灰装和修理 |
| AzerothSpellID | 法术提示 ID |
| AzerothTalentPreview | 天赋预览 |

## 当前发布边界

这是初次源码导入，尚非完整稳定体验包。兼容性目标是服务端不支持扩展时安全降级；**现有 GM 扩展尚未完成所有普通服务端上的降级验收**，不能把目标当成已通过验证。

仓库不包含 MPQ、DBC 或从游戏提取的大型名称、天赋描述表。`SpellNames.lua` 与 `TalentData.lua` 是空占位文件；未生成数据时法术 ID 查询无结果、天赋预览无图数据。`tools/build_spell_id_names.py` 可从使用者自己的 Spell.dbc 生成名字表；`tools/build_talent_preview.py` 接受 Talent.dbc、TalentTab.dbc、使用者导出的法术 JSON 和输出路径。生成结果仅在本地使用，不提交。

GM 的目的地和命令清单包含服务端命令、ID、名称和坐标，不包含游戏模型、音频或完整法术描述。目的地 ID 对应我们的服务端版本，其他核心可能不一致，不应盲目执行。

## 第三方插件

`third-party.lock.json` 记录本机安装文件的 SHA256 作为后续溯源依据，**不是已经解析完成的可重复下载锁文件**。AutoQuest 修改版将独立维护 fork；pfQuest、ShaguDPS、ItemRack、BetterCharacterStats、Bagnon 等不复制进本仓库。精确上游提交、部分来源和再分发许可未核实的项不会自动下载或纳入发布包。AutoQuest 已知基础提交为 fd349f1642c2fa2f452d8aadeaafbbbb4aa56b62，本地包含额外修改；当前未发现其上游明确许可证，禁止打包再分发，等待授权确认。

## 构建与安装

运行 `python3 tools/package.py` 生成自研源码预览包与 SHA256。该包带空数据占位，不是完整插件体验包。将 ZIP 中 AddOns 下目录复制到标准客户端 Interface/AddOns，benilla 使用 benilla-config/AddOns。保留原有 SavedVariables，先备份再覆盖。

测试需要使用者编译 benilla 的 addon_harness，并设置 ADDON_HARNESS 和 WOW_DATA。例如 `python3 tests/verify_convenience.py`；这些是含模拟 API 的 Lua 规则测试，不代替真实客户端视觉或服务端验收。

## 授权与贡献

现有自研目录未发现明确授权文件，本次导入不擅自添加许可证。正式对外分发前需由权利人明确授权。第三方插件保持原作者、原许可证和独立来源；安装清单不转移其授权。通用修复拆成小 PR，自定义服务器接口不要求修改客户端程序。
