# Devteam Multi-session Development Skill

[English](README.md) | **简体中文**

**给每个项目配一个「总管 agent」，其余 session 各管一个模块。** 一个人同时开好几个 AI 编码会话（前端、后端、设计、合约……）时，用它管住协作：谁能改哪里、谁来验收合并、决定记在哪、要你做的事汇总到哪。session 之间自动发消息派活和回报，你只需要跟总管说话。

做成了一个 Claude Code skill：`/devteam`。

## 安装

```bash
git clone https://github.com/Antoniaiaiaiaia/devteam-multi-session-development-skill.git
cp -R devteam-multi-session-development-skill/skills/devteam ~/.claude/skills/
```

## 用法

```text
/devteam init design frontend backend   # 在仓库根目录装框架（AGENTS.md、context.md、change-log.md、git 钩子、各模块 README）
/devteam root                           # 把这个 session 设成总管
/devteam frontend                       # 在另一个 session：设成 frontend 模块
/devteam backend api-v2                 # 设成 backend 模块，并直接开 backend/api-v2 分支的 worktree
```

总管还能用：

| 命令 | 做什么 |
|---|---|
| `/devteam status` | 更新进度看板（等你验收 / 正在做 / 等你决定 / 已上线），再简短汇报 |
| `/devteam dispatch <模块> <需求>` | 按模板派活（附你的原话和验收标准），并自动等分支出现提交 |
| `/devteam review <分支>` | 验收：改动范围、冲突、密钥，在合并后的代码上跑 Verify |
| `/devteam merge <分支>` | 合并、记 change-log / context，需要时上线并在线上核对 |
| `/devteam ask` | 把攒下的待定项合并成一次提问问你 |

模块 session 用 `/devteam report` 按模板回报总管。

内置模块预设（管什么、约束、Verify 怎么写、端口段）：`frontend`、`backend`、`design`、`mobile`、`qa`、`admin`、`contracts`、`support`（客服）、`data`（导入 / 采集）。其他名字也能用，按通用模块手册走。

## 文件

```
skills/devteam/
  SKILL.md                  # 入口：参数怎么解析、每个命令做什么
  roles/root.md             # 总管手册：派活循环、验收、合并、问 Owner、进度看板
  roles/module.md           # 模块 agent 手册
  roles/messages.md         # 上线 / 派活 / 回报 / 退回 / 合并通知 / 更正 / 暂停 模板
  roles/presets/*.md        # 常见模块预设
  assets/AGENTS.md          # 仓库规则模板（init 时复制到仓库根）
  assets/templates/         # context.md、change-log.md、module-README.md
  assets/githooks/          # 钩子：越界、密钥、偷偷移动 main 都会被拦
  scripts/init.sh           # 装框架（已存在的文件不覆盖）
```

## 解决什么问题

同时开 5 个 agent 窗口，很快会出现：
- A 窗口改了 B 窗口的文件，互相覆盖
- 某个 agent 替你拍了板，你根本没同意过
- 同一个问题，三个窗口各问你一遍
- 你要挨个点开窗口，才知道谁在等你装软件、给 key
- 决定散落在各个对话里，过两天谁也说不清为什么这么定

这个框架的做法：
- **一个总管 agent**：唯一能合并到 `main` 的角色。负责验收、决定合并顺序、维护项目状态、汇总你的待办。
- **若干模块 agent**：各管一个目录，在自己的分支上干活，做完交总管验收。
- **所有决定都由你（Owner）做**：写进 `context.md` 的每条决定，总管都要找到你的原话才记。
- **全自动协作**：总管派活 → 模块会话在自己的分支上做 → 回报 → 总管在合并后的代码上跑验证、合并、上线、线上核对。只有总管会来问你问题。
- **git 钩子强制边界**：模块分支越界改别的目录、提交密钥、偷偷移动 `main`，都会被拦下。

## 它怎么运转

```
模块 agent ──(分支 + 提交)──▶ 总管验收 ──▶ main
     │                         │
     │  Owner 的原话 / 要 Owner 做的事
     └────────────────────────▶ 总管核对、写进 context.md、汇总给 Owner
```

- **验收只查明显问题**：越界、冲突、和已有决定矛盾、数字算错、密钥、Verify 跑不过。没问题就合，不卡在待定项上。
- **合并顺序有规则**：底层程度 → 干净程度 → 影响范围 → 安全性。
- **后合并的分支用 `git merge main` 同步**，不 rebase。钩子允许模块分支合并 main，但合并结果仍然只能改本模块目录。

## 踩过的坑（照抄就能绕开）

这些都是真实用下来遇到的：

1. **fast-forward 能绕过所有 commit / merge 钩子。** 模块 agent 一句 `git merge --ff-only` 就把 main 移走了。所以要加 `reference-transaction` 钩子拦住所有移动 main 的操作，并设 `merge.ff false`。
2. **无冲突合并时，`pre-merge-commit` 阶段还没有 `MERGE_HEAD`。** 想判断"正在合并的是不是 main"，要从 `GIT_REFLOG_ACTION` 里解析。见 `.githooks/_lib.sh`。
3. **分支推过备份仓库后，不要 rebase。** 改写过的历史推不上去，备份就一直失败。同步一律 `git merge main`。
4. **"Owner 没有偏好"不等于"已决定"。** 总管一度把"你没偏好"当成自己可以拍板，结果 Owner 后来改了主意。现在规则是：没有原话的只能记成候选。
5. **总管不要就同一件事再问 Owner 一遍。** 负责那个话题的会话已经在问了，两边同时问会打架，还会让 Owner 以为两件事。
6. **别的会话"转述"的决定要回原对话核对。** 至少碰到过一次：把 agent 自己提问时说的话，当成了 Owner 的回答。
7. **决定会被推翻，旧决定不要删。** 在新条目里写"取代 YYYY-MM-DD 的 xxx"，附上新旧两句原话，以后才说得清为什么改。
8. **非总管会话也可能直接提交 main。** git 分不清是哪个窗口在提交，钩子只防失误。发现了就保留正确内容、修正错误、提醒那个会话，并把规则写得更明确。
9. **要 Owner 做的事必须集中。** 否则 Owner 要逐个点开窗口，才知道谁在等自己装软件、给 key。
10. **zsh 会把 `$VAR:f` 当成变量修饰符。** 脚本里写 `git show "$B:path"` 会出错，要写成 `"${B}:path"`。
11. **总管自己动手做模块活，会让其他会话闲着、绕开分工。** 现在规则是总管只验收 / 合并 / 部署 / 记录，再小的活也派出去。
12. **只在分支上跑 Verify 不够。** 主线在你验收期间可能已经合了别的分支，两者单独都过、合在一起才炸。在 `merge-tree` + `commit-tree` 合出来的临时树上跑。
13. **跨会话消息会排队。** 对方在跑长任务时收不到"暂停"，Owner 急的时候总管要直接停进程，再补一句说明。
14. **消息交叉。** 你刚发的更正，对方可能已经按旧要求做完并回报了。看回报时先对 hash / 时间，别把旧回报当成对新要求的回应。
15. **Owner 点名换人做时，先让原来的人停手。** 否则两个会话同时发帖、同时改同一批数据。
16. **对外发出的东西（频道帖、邮件）先对照 Owner 给的样例逐字核对，再批量发。** 一次模板错了，几十条都要回头改；改之前先渲染一条、读回一条确认。
17. **首次导入 / 回填不要触发"新内容自动推送"。** 新来源第一次扫描只入库，否则频道会被一次刷几百条。
18. **合规问题总管拍板，按保守的来。** robots.txt 禁止的接口、要伪造请求头或借用网页会话才能调的内部接口，一律不用。
19. **模块会话问 Owner、开浏览器弹"允许"，Owner 会被打断很多次。** 统一由总管问，查网页用 curl。
20. **Owner 说"记一下"的规则，同时写进 AGENTS.md 和总管的长期记忆**，否则下一个会话还会犯。

## 适用范围

- 为 Claude Code 这类能读写仓库、跑命令的 coding agent 设计。会话之间能互相发消息时最顺手（例如 Claude Code 桌面版的 SendMessage）。不能的话，由 Owner 把模块的回报复制给总管，流程一样。
- 钩子是 bash + git，支持 macOS / Linux。
- 只是约定和护栏，不替代代码评审和测试。

## License

MIT，见 [LICENSE](LICENSE)。
