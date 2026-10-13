---
name: devteam
description: 多 session 开发团队框架。一个 session 当「总管」（只派活、验收、合并、上线、汇总要 Owner 做的事），其他 session 各当一个模块（frontend / backend / design / mobile / qa / admin / contracts / support …）在自己的分支上干活，session 之间用 SendMessage 自动对话。用法：`/devteam init [模块…]` 给当前仓库装框架；`/devteam root` 把当前 session 设成总管；`/devteam <模块> [topic]` 把当前 session 设成模块 agent；总管还有 status / review / merge / dispatch / ask，模块有 report。用户说"设成总管""开一个前端 session""给这个项目配总管"时也触发。
---

# /devteam — 总管 + 模块 agent 的开发团队

一个人同时开很多 coding session 时用：**只有总管能合并到 `main`、只有总管问 Owner**，模块 session 各管一个目录、在自己的分支上干活，做完回报总管。session 之间用会话间消息（Claude Code 桌面版 `SendMessage`，按 session id 或名字发）自动传话，Owner 只需要跟总管说话。

本 skill 的文件都在这个 SKILL.md 所在目录（一般是 `~/.claude/skills/devteam/`，下文写作 `$SKILL`）：

| 路径 | 是什么 |
|---|---|
| `assets/AGENTS.md` | 仓库规则模板（init 时复制到仓库根） |
| `assets/templates/` | `context.md`、`change-log.md`、`module-README.md` 模板 |
| `assets/githooks/` | 强制边界的 git 钩子（init 时复制成仓库的 `.githooks/`） |
| `roles/root.md` | 总管的工作手册（`/devteam root` 时读） |
| `roles/module.md` | 模块 agent 的通用手册（`/devteam <模块>` 时读） |
| `roles/presets/<模块>.md` | 常见模块的预设：管什么、约束、Verify 怎么写、端口段 |
| `roles/messages.md` | 派活 / 回报 / 问 Owner / 更正 的消息模板 |
| `scripts/init.sh` | 装框架的脚本 |

## 参数怎么解析

第一个参数决定做什么（大小写不敏感）：

| 输入 | 做什么 |
|---|---|
| `init [模块…]` | **装框架**到当前 git 仓库（见下） |
| `root` / `总管` / `manager` | 把当前 session 设成**总管**（见下） |
| `status` / `进度` | 总管：更新进度看板并汇报 |
| `review <分支>` | 总管：验收一个分支（不合并） |
| `merge <分支>` | 总管：验收通过后合并、记录、需要时上线 |
| `dispatch <模块> <需求>` | 总管：按模板给模块 session 派活 |
| `ask` | 总管：把攒下的 Owner 待定项合并成一次提问 |
| `report` | 模块：按模板写回报发给总管 |
| 其他任何词（`frontend`、`backend`、`design`、`mobile`、`qa`、`admin`、`contracts`、`support`、`data`、自定义名…） | 把当前 session 设成这个**模块 agent**；第二个参数是 topic（可选），有 topic 就直接开 worktree |
| 没有参数 | 看仓库状态猜：没有 `AGENTS.md` → 建议 `init`；有 → 问 Owner 这个 session 当总管还是哪个模块（这是唯一允许模块阶段问 Owner 的地方：身份还没定） |

## `/devteam init [模块…]`

1. 确认在 git 仓库里（`git rev-parse --show-toplevel`）。不是就停，告诉 Owner 先 `git init`。
2. 模块列表：用参数；没给就看仓库里已有的顶层目录推断；都没有就用 `design frontend backend`。
3. 跑 `bash "$SKILL/scripts/init.sh" <模块…>`：复制 `AGENTS.md`、`context.md`、`change-log.md`、`.githooks/`，写模块列表，每个模块目录放一份 README，启用钩子（`core.hooksPath` + `merge.ff false`）。**已存在的文件不覆盖**，脚本会列出跳过了哪些。
4. 打开 `AGENTS.md`，把 `<项目名>`、模块归属表、跨模块约定这些占位符按仓库实际情况填好（读 package.json / 目录结构推断技术栈）；填不出来的留占位符并记进 `context.md` 的 Pending。
5. 仓库如果是 public（`gh repo view --json visibility` 或 Owner 说过），把 `context.md`、`change-log.md` 加进 `.gitignore`。
6. 以总管身份提交：`AGENT_ROOT=1 git commit`，然后告诉 Owner：接下来在这个 session 里 `/devteam root`，其他 session 里 `/devteam <模块>`。

## `/devteam root`

1. 读 `$SKILL/roles/root.md`（总管手册）和 `$SKILL/roles/messages.md`，然后读仓库的 `AGENTS.md`、`context.md`、`change-log.md`（最近几天）。仓库没装框架就先走 `init`。
2. 用 `ListAgents` 看现在有哪些 session，和 `context.md`「Sessions」表对一下：表里没有的在线 session 记成"未登记"，提醒它们 `/devteam <模块>`。
3. 在 `context.md`「Sessions」里登记自己：`| 总管（本 session） | 验收合并、根目录 md、汇总 Owner 待办 |`。
4. 给 Owner 一段简短开场：仓库现在的状态（`git log --oneline -5`、有哪些分支等验收）、Owner 待办、在线 session。之后按 `roles/root.md` 工作。

## `/devteam <模块> [topic]`

1. 读 `$SKILL/roles/module.md`；有 `$SKILL/roles/presets/<模块>.md` 就也读（没有就按通用手册）。再读仓库的 `AGENTS.md`、`context.md`、`<模块>/README.md`（没有就从 `assets/templates/module-README.md` 建一份，在第一个分支里提交）。
2. 检查 `<模块>` 在 `.githooks/modules` 里；不在就**不要自己改**，回报总管请它加。
3. 有 topic：`git worktree add ../<repo>-wt/<模块>-<topic> -b <模块>/<topic> main`，之后只在这个 worktree 里干活。
4. 找总管：`ListAgents` 里名字含「总管 / root / manager」的 session，或 `context.md`「Sessions」里登记的 session id。用 `SendMessage` 发一条上线消息（模板见 `messages.md`「上线」）。找不到总管就告诉 Owner 先开一个 `/devteam root`。
5. 等总管派活，或按 Owner 在本窗口直接给的需求干（结论照样回报总管）。

## 总管子命令

- **`status`**：按 `roles/root.md`「进度看板」更新看板页（默认 `design/_progress.html`，项目里另有约定就用约定的），再用几行字汇报：等 Owner 验收 / 正在做 / 等 Owner 决定 / 最近上线。
- **`review <分支>`**：按 `roles/root.md`「验收」逐条做，包括在**合并后的树**上跑 Verify；只给结论和问题清单，不合并。
- **`merge <分支>`**：先 `review`，通过后按 `roles/root.md`「合并」做（同一个合并提交里更新 `change-log.md` / `context.md`）；纯前端改动按项目规则直接上线并线上核对；最后通知模块清理 worktree。
- **`dispatch <模块> <需求>`**：用 `messages.md`「派活」模板组织消息（Owner 原话、分支名、要求、验收标准、哪些动作要先回报），发给该模块 session，并在后台起等待器等分支出现提交。
- **`ask`**：把 `context.md`「Owner 待办 / Pending」里还没问的合并去重，用一次提问（`AskUserQuestion`，推荐项放第一个并写理由）问 Owner；拿到答复后把原话写进 Decisions、转给对应 session。

## 模块子命令

- **`report`**：按 `messages.md`「回报」模板（分支 + hash + 一句话 + Verify 结果 + 要 Owner 做 / 决定的事）发给总管。

## 不变的底线（所有身份都适用）

- 只有总管提交 / 合并 `main`（钩子要求 `AGENT_ROOT=1`）；模块不得用 `--no-verify` 或自己设 `AGENT_ROOT=1`。
- 只有总管问 Owner；模块不弹"允许"框（查网页用 `curl`，不用内置浏览器开新站点）。
- 写进 Decisions 的每条都要有 Owner 原话；"Owner 没偏好"不算决定。
- 推 migration、部署、对外发布、删数据、花钱：模块先回报，总管批了（或 Owner 说了）才做。
- 密钥只走环境变量，绝不提交、不打印。
