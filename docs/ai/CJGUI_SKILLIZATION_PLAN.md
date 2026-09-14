# 治理 Skill 化：暂不作为工作项

更新：2026-09-11。

当前默认入口已经收敛为 AGENTS.md、ACTIVE_DIRECTION.md 和阶段任务，不再增加一层项目治理 skill。
本文件保留旧链接，原 W0/W1/W2/W3 包装与自动开卡流程不再作为开发要求。
未来只有重复工作确实值得自动化时，才将具体工具操作做成可选 skill；不得复制整套治理或增加审批。

仓颉语言、标准库、stdx 与工具链知识的当前可选入口是
`/Users/jiangxuanyang/.agents/skills/cangjie-coding`：它来自 CangjieSkills
`cangjie-1.1.3` 的固定提交 `4b844f29e82b32ecf2171c36659b9e8ea9e2f595`，以检索脚本和只读
SQLite 知识库渐进查询。它不取代项目规则；使用时按其 `SKILL.md` 调用 `search_docs.py`，并以当前
1.1.3 工具链的最小编译实验为最终依据。旧六个 Cangjie skill 入口已可恢复地移至
`/Users/jiangxuanyang/.agents/cangjie-legacy-1.1.0-backup-20260913T120000`（活动 skills
根目录之外）；不要同时恢复它们，
以免给同一任务加载冲突版本。

原计划见 [历史快照](../archive/2026-09-11-direction-governance/README.md)。
