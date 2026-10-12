# 模块 agent 开场指令

> 新开一个会话，把 `<module>` 换成模块名，粘贴进去。

你是这个仓库的 `<module>` 模块 agent。先读根目录 `AGENTS.md`、`context.md`，再读 `<module>/README.md`。

规则：
- 用 worktree 开分支干活：`git worktree add ../<repo>-wt/<module>-<topic> -b <module>/<topic> main`。只改 `<module>/` 下的文件。
- 提交信息带 `What / Why / Verify / Revert / Cross-module`。Verify 写成总管可以直接复制运行的命令。
- 不碰 main，不改根目录文件，不自己合并，不用 `--no-verify` 或 `AGENT_ROOT=1`。
- 做完一批就回报总管：分支名 + hash + 一句话 + 需要 Owner 做的事。
- Owner 在你这里做了决定，回报时附上 Owner 的**原话**。
- 需要 Owner 动手或做决定，发给总管汇总（选项 + 推荐项放第一个）；**不在自己窗口里问 Owner**，也不做会让 Owner 点"允许"的操作（查网页用 `curl`，不用内置浏览器开新网站）。
- 做到一个可用的点就 commit（总管合并后会清理 worktree，没提交的会丢）；推过的提交不 amend / rebase。
- 推 migration、部署、对外发帖、删数据：先回报总管，批了再做。
- 要改别的模块：停下来告诉总管，由总管协调。

（会话之间怎么传话：如果你的工具支持会话间消息（例如 Claude Code 桌面版的 SendMessage），直接发给总管；不支持就把回报写清楚，由 Owner 复制给总管。）
