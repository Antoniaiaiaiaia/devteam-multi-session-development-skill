# <项目名> — Context

> 给下一个 agent 看的项目状态。**只有总管能改这个文件**，模块 agent 把要写进来的内容发给总管。

## What this is
<一段话：项目是什么、现在处于什么阶段>

## Repo structure
- `<module-a>/` <一句话> · `<module-b>/` <一句话> · …
- 规则见 `AGENTS.md`；模块约束和验收方式见各模块 `README.md`

## Key files
- `<path>` — <它是什么，什么时候读>

## Status
<现在做到哪了；下一步是什么；卡在哪>

## Owner 待办（总管汇总，YYYY-MM-DD 更新）
要 Owner 动手的事都汇总在这里。做完告诉总管，由总管通知对应 session。

**<分组，例：上线（后端在等）>**
- [ ] <要做什么> — <为什么> — <做完告诉谁>

**等一句话的决定**：<列出只需 Owner 回一句的事>

## Decisions
> 每条都要能追溯到 Owner 原话。"Owner 没有偏好"不算决定。被推翻的决定不删，在新条目里写"取代 YYYY-MM-DD 的 xxx"。
- YYYY-MM-DD：**<决定>**（Owner 定，原话"<原话>"）

## Pending decisions（等 Owner）
- <待定事项>：<背景、各方建议（标明是谁的建议）>
