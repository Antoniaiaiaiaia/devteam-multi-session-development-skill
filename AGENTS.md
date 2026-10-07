# <项目名> — Agent Rules

> 这是「总管 agent + 模块 agent」协作框架的规则文件。放在仓库根目录。
> 所有在这个仓库里干活的 agent，**动手前先读这里，再读 `context.md`**。
> 把 `<尖括号>` 里的内容换成你自己的。

## 一句话

一个**总管 agent** 只管结构、验收、合并和汇总；若干**模块 agent** 各管一个目录、在自己的分支上干活；**所有决定由项目主人（下文称 Owner）做**。agent 之间不互相拍板，也不替 Owner 拍板。

## 目录结构

```
<repo>/
├── AGENTS.md        # 本文件：协作规则（很少改）
├── context.md       # 项目当前状态、决定、待定、Owner 待办（经常改，只有总管改）
├── change-log.md    # 功能改动日志：What / Why / How to revert（只有总管改）
├── <module-a>/      # 例：design/
├── <module-b>/      # 例：frontend/
├── <module-c>/      # 例：backend/
└── <module-d>/      # 例：infra/ 或 contracts/
```

根目录只放这三个 md + 仓库配置（`.gitignore`、`.githooks/` 等）。其他东西都进某个模块目录。

## 模块归属

| 目录 | 管什么 | 不管什么 |
|---|---|---|
| `<module-a>/` | <例：品牌、UI 稿、调研文档> | <例：任何可运行代码> |
| `<module-b>/` | <例：App 前端> | <例：拼交易、调 LLM、存数据> |
| `<module-c>/` | <例：API、数据库> | <例：UI> |

每个模块目录有自己的 `README.md`，写本模块的**约束**、验收方式（Verify 怎么写）、技术栈、当前状态。模块 agent 可以更新自己的 README，但改「约束」一节要经总管记录、由 Owner 确认。

## 跨模块约定

<在这里写跨模块必须一致的东西，例如：>
- **接口和共享类型**：定义在哪个模块、谁 import、改了要同时改哪几边
- **数据约定**：主键、金额格式、命名规则
- **密钥**：API key 全走环境变量，绝不提交

## 角色

### 总管 agent（Root agent）
- **唯一能提交到 `main` 的角色。** 负责：验收合并、分支冲突时决定合并顺序、维护根目录三个 md、跨模块的**技术**一致性（目录、接口、共享类型、数据结构）。
- **不做产品决策，不替 Owner 拍板。** 产品、业务、花钱的事，由负责该话题的模块 session 直接和 Owner 商量。总管不就同一件事再去问 Owner 一遍。
- **写进 Decisions 的每一条，都要能追溯到 Owner 的原话**（看来源 session 的对话记录核对）。"Owner 没有偏好"≠ 已决定，只能记成候选。
- **验收范围只查明显问题**：文本冲突、和已有 Decisions 矛盾、数字算错、越界改别的目录、提交了密钥、Verify 跑不过。没问题就合并。**没定的事一律留给 Owner**，包括模块草案里写着"待总管定"的技术项：总管不拍板，记进 `context.md` 的 Pending。不因为还有待定项而卡住合并。
- **汇总 Owner 的待办。** 所有模块 session 要 Owner 动手或做决定的事，都发给总管；总管维护 `context.md`「Owner 待办」，每次汇报都把新增和未完成的事列给 Owner。Owner 做完告诉总管，由总管通知对应 session。**Owner 不需要挨个打开 session 看谁在等自己。**
- 来源 session 还在和 Owner 讨论的内容，不催促改，等它交最终版。

### 模块 agent
- 在 `<module>/<topic>` 分支上干活，**只改自己的目录**，完成后交总管验收。
- 不碰 `main`，不改根目录文件，不自己合并。
- 需要 Owner 做的事（开账号、给 key、装软件、点网页、做决定）→ 发给总管汇总，可以在自己窗口里提一句，但不能只在自己窗口里说。
- Owner 在自己窗口里做的决定 → 连同**原话**一起回报总管，由总管核对后写进 Decisions。

## 提交与验收流程

### 一次性设置（clone 后跑一次）
```bash
bash .githooks/setup.sh
```
启用钩子，并设置 `merge.ff false`（否则 fast-forward 合并会绕过钩子）。模块列表在 `.githooks/modules`，一行一个。

### 钩子强制的规则
| 钩子 | 规则 |
|---|---|
| `pre-commit` | 分支名必须是 `<module>/<topic>` 或 `main`；模块分支只能改自己的目录；模块分支只能合并 `main`（同步用），合并结果相对 main 也只能改自己的目录；`main` 只有设了 `AGENT_ROOT=1` 才能提交；任何分支都不能提交 `.env` / keypair / `.pem` 等密钥文件 |
| `commit-msg` | 模块分支的提交信息第一行必须是 `[module] 标题`，正文必须有 `What:` / `Why:` / `Verify:` / `Revert:`（同步 main 的合并提交除外） |
| `pre-merge-commit` | 无冲突的合并也走 `pre-commit` 同一套检查 |
| `reference-transaction` | 任何方式移动 `main`（fast-forward、`reset`、`branch -f`）都必须设 `AGENT_ROOT=1` |
| `post-commit` / `post-merge` | （可选）后台检查备份阈值，达到就推远端备份 |

### 模块 agent 怎么干活
1. 读本文件、`context.md`、目标模块的 `README.md`。
2. 用 worktree 开分支，几个 agent 并行互不干扰：
   ```bash
   git worktree add ../<repo>-wt/<module>-<topic> -b <module>/<topic> main
   ```
3. 在 worktree 里干活、提交。提交信息格式：
   ```
   [<module>] 一句话标题

   What: 改了什么
   Why: 为什么（Owner 定的就附原话）
   Verify: 总管怎么验证（命令 + 预期结果）
   Revert: 怎么回滚
   Cross-module: 无 / 影响哪些模块
   ```
4. 完成后回报总管：分支名 + hash + 一句话说明 + 需要 Owner 做的事。

### 总管怎么验收
```bash
git log main..<branch> --format='%h %s%n%b'   # 看提交信息
git diff main...<branch> --stat                # 看改动范围
git diff main...<branch>                       # 逐行看
# 到分支的 worktree 里，自己跑一遍 Verify 字段的命令
```
检查清单：
- [ ] 改动只在该模块目录内，符合模块 README 的约束
- [ ] Verify **总管自己跑过**并通过，不只看描述
- [ ] 没破坏跨模块约定
- [ ] 写进 Decisions 的内容能追溯到 Owner 原话
- [ ] 没有密钥、没有不该提交的大文件

通过后合并，并在**同一个合并提交**里更新根目录 md：
```bash
AGENT_ROOT=1 git merge --no-ff --no-commit <branch>
# 编辑 change-log.md（用提交里的 What/Why/Revert）和 context.md（状态 / 决定 / 待定 / 待办）
git add change-log.md context.md
AGENT_ROOT=1 git commit -m "merge <branch>: 一句话"
```
不通过：不合并，把具体问题（文件 + 行号 + 要改成什么）发回给模块 agent，它在同一分支上追加提交。

### 合并顺序与冲突（总管负责）
两个以上分支同时等验收、且互相冲突时，**由总管决定谁先合**，模块 agent 不自行协商。

**冲突有两种，都要查：**
- **文本冲突**：只会出现在同一模块的两个分支之间（钩子保证不同模块不改同一文件）。检测：
  ```bash
  git merge-tree --write-tree <分支A> <分支B> >/dev/null || echo 有冲突
  ```
- **语义冲突**：文件不冲突，但功能互相依赖或打架（例：后端改了接口，前端分支还按旧的写）。看两边的 `Cross-module` 字段和 diff。

**决定先后的优先级**（从上往下比，前一条分出高下就不看后面的）：
1. **底层程度**：越底层越先合（接口 / 数据结构 → 后端逻辑 → 前端 → 文档）
2. **干净程度**：一次通过、不用返工的先合
3. **影响范围**：影响范围大的先合，小的去适配它
4. **安全性**：更安全的先合

前提：只在**都能通过验收**的分支之间比较。有问题的直接退回，不参与排序。

**定了顺序之后：** 总管合并先合的 → 通知后合的模块 agent（先合了谁、依据哪条、要适配什么）→ 后合的分支 `git merge main` 同步（**不要 rebase**：分支推过远端备份后再 rebase，备份会推送失败），只在本模块内解决冲突，重跑 Verify 再交 → 总管在 change-log 里写一行「合并顺序：A 先于 B（依据：底层程度）」。

### 局限
- 钩子只防失误，不防故意绕过（`--no-verify`、手动设 `AGENT_ROOT=1`）。**模块 agent 禁止使用这些手段**，发现即视为验收不通过。git 分不清是哪个窗口在提交，所以这一条只能靠规则约束。
- 主目录（`main` 所在的工作区）是总管的工作区，模块 agent 只在 `../<repo>-wt/` 下的 worktree 里干活。

## 备份（可选）
`.githooks/backup.sh` 在本地领先远端到一定程度时自动推送私有备份仓库（`origin`）：`main` 领先就推；未推送提交 ≥ 5 个就推；最老的未推送提交超过 6 小时就推。绝不 force push。详见脚本开头的注释。**备份仓库必须是 private**（`context.md` 里有决策过程和内部信息）。

## 其他规则
1. 看到不是自己这轮做的改动（未提交的 diff、新文件），默认是 Owner 或另一个 agent 在并行干活，保留，不要"顺手整理"。
2. 一次性产出（对比页、草稿）文件名加 `_` 前缀。
3. 不把 dev server 丢在后台常驻；验证编译用 build / typecheck，必须起 dev server 时前台跑、用完就关。
4. **不是这个项目的任务，先问 Owner 是不是发错窗口了。** 判断依据：文件路径、截图里的项目名、提到的产品对不上。确认前不动手。
5. **涉及浏览器 / 第三方账号的操作，先确认当前登录的是这个项目该用的账号**（例：个人项目不能在公司账号的浏览器里操作）。不确定就停下来问。
6. <在这里加你自己的规则。每条最好写明"谁定的、哪天定的"，以后改规则时知道它为什么存在。>
