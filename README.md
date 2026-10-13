# Devteam Multi-session Development Skill

**English** | [简体中文](README.zh-CN.md)

**Give every project one "root agent" and let every other session own a single module.** When you run several AI coding sessions at once (frontend, backend, design, contracts…), this keeps the collaboration under control: who may change what, who reviews and merges, where decisions are recorded, and where the things *you* need to do get collected. Sessions message each other to dispatch work and report back — you only talk to the root agent.

It ships as a Claude Code skill: `/devteam`.

> **Language note:** the skill's prompts and the files it installs (`AGENTS.md`, `context.md`, templates, hook messages) are written in Chinese. Claude follows them fine and will still talk to you in English, but the generated files will be in Chinese.

## Install

```bash
git clone https://github.com/Antoniaiaiaiaia/devteam-multi-session-development-skill.git
cp -R devteam-multi-session-development-skill/skills/devteam ~/.claude/skills/
```

## Usage

```text
/devteam init design frontend backend   # install the framework at the repo root (AGENTS.md, context.md, change-log.md, git hooks, per-module READMEs)
/devteam root                           # make this session the root agent
/devteam frontend                       # in another session: make it the frontend module
/devteam backend api-v2                 # make it the backend module and open a worktree on branch backend/api-v2
```

Root agent commands:

| Command | What it does |
|---|---|
| `/devteam status` | Update the progress board (awaiting your review / in progress / awaiting your decision / shipped), then give a short report |
| `/devteam dispatch <module> <request>` | Dispatch work from a template (with your exact words and acceptance criteria), then wait for commits to appear on the branch |
| `/devteam review <branch>` | Review: scope of changes, conflicts, secrets, and run Verify on the merged code |
| `/devteam merge <branch>` | Merge, record in change-log / context, and deploy + check production when needed |
| `/devteam ask` | Batch all pending questions into a single question to you |

Module sessions report back to the root agent with `/devteam report`.

Built-in module presets (ownership, constraints, how to write Verify, port range): `frontend`, `backend`, `design`, `mobile`, `qa`, `admin`, `contracts`, `support`, `data` (import / scraping). Any other name works too and follows the generic module handbook.

## Files

```
skills/devteam/
  SKILL.md                  # entry point: argument parsing and what each command does
  roles/root.md             # root agent handbook: dispatch loop, review, merge, asking the Owner, progress board
  roles/module.md           # module agent handbook
  roles/messages.md         # templates: launch / dispatch / report / reject / merge notice / correction / pause
  roles/presets/*.md        # common module presets
  assets/AGENTS.md          # repo rules template (copied to the repo root by init)
  assets/templates/         # context.md, change-log.md, module-README.md
  assets/githooks/          # hooks that block out-of-scope edits, secrets, and sneaky moves of main
  scripts/init.sh           # installs the framework (never overwrites existing files)
```

## The problem it solves

Open five agent windows at once and you quickly get:
- Window A edits window B's files and they overwrite each other
- An agent makes a decision on your behalf that you never agreed to
- Three windows ask you the same question
- You have to click through every window to find out who is waiting for you to install something or provide a key
- Decisions are scattered across conversations, and two days later nobody can say why something was decided

How this framework handles it:
- **One root agent**: the only role allowed to merge into `main`. It reviews, decides merge order, maintains project state, and collects your to-dos.
- **Several module agents**: each owns one directory, works on its own branch, and hands finished work to the root agent for review.
- **You (the Owner) make every decision**: the root agent only records a decision in `context.md` after finding your exact words.
- **Fully automatic collaboration**: root dispatches → module works on its branch → reports back → root runs verification on the merged code, merges, deploys, and checks production. Only the root agent ever asks you questions.
- **Git hooks enforce the boundaries**: a module branch editing another module's directory, committing secrets, or quietly moving `main` gets blocked.

## How it works

```
module agent ──(branch + commits)──▶ root reviews ──▶ main
     │                                   │
     │  Owner's words / things the Owner must do
     └──────────────────────────────────▶ root verifies, writes to context.md, summarizes for the Owner
```

- **Review only checks for obvious problems**: out-of-scope edits, conflicts, contradictions with existing decisions, wrong numbers, secrets, failing Verify. If it's clean, merge — don't block on open questions.
- **Merge order follows rules**: most foundational → cleanest → smallest blast radius → safest.
- **Branches merged later sync with `git merge main`**, never rebase. Hooks let module branches merge main, but the result may still only touch that module's directory.

## Pitfalls we hit (copy the fixes)

All of these came up in real use:

1. **Fast-forward bypasses every commit / merge hook.** A module agent ran `git merge --ff-only` and moved main. So a `reference-transaction` hook blocks every operation that moves main, and `merge.ff` is set to `false`.
2. **On a conflict-free merge, `MERGE_HEAD` doesn't exist yet during `pre-merge-commit`.** To tell whether the branch being merged is main, parse `GIT_REFLOG_ACTION`. See `.githooks/_lib.sh` (`skills/devteam/assets/githooks/_lib.sh` in this repo).
3. **Don't rebase a branch after it's been pushed to the backup remote.** Rewritten history can't be pushed and backups keep failing. Always sync with `git merge main`.
4. **"The Owner has no preference" is not "decided".** The root agent once treated "no preference" as permission to decide, and the Owner later changed their mind. Rule now: anything without the Owner's words is only recorded as a candidate.
5. **The root agent shouldn't re-ask the Owner about the same thing.** If the session that owns that topic is already asking, two parallel questions conflict and make the Owner think there are two issues.
6. **Verify "relayed" decisions against the original conversation.** At least once, something an agent said while asking a question was mistaken for the Owner's answer.
7. **Decisions get overturned — don't delete the old ones.** Write "supersedes the YYYY-MM-DD xxx" in the new entry, quoting both the old and new words, so it's clear later why it changed.
8. **Non-root sessions may still commit to main directly.** Git can't tell which window is committing; hooks only prevent mistakes. When it happens, keep the correct content, fix what's wrong, remind that session, and make the rule more explicit.
9. **Things the Owner must do have to be centralized.** Otherwise the Owner clicks through every window to find who's waiting on them to install something or provide a key.
10. **zsh treats `$VAR:f` as a variable modifier.** `git show "$B:path"` in a script breaks; write `"${B}:path"`.
11. **When the root agent does module work itself, other sessions sit idle and the division of labor breaks down.** Rule now: root only reviews / merges / deploys / records — every task, however small, gets dispatched.
12. **Running Verify only on the branch isn't enough.** Main may have merged another branch while you were reviewing; each passes alone but they break together. Run it on a temporary tree built with `merge-tree` + `commit-tree`.
13. **Cross-session messages queue.** A session running a long task won't see "pause". When the Owner is in a hurry, the root agent should stop the process directly and then send an explanation.
14. **Messages cross.** A correction you just sent may arrive after the other session has finished the old request and reported. Check the hash / timestamp before treating a report as a response to the new request.
15. **When the Owner reassigns work, stop the original session first.** Otherwise two sessions post at the same time and edit the same data.
16. **Check anything outbound (channel posts, emails) word-for-word against the Owner's sample before sending in bulk.** One template mistake means dozens of fixes; render one, read it back, then send.
17. **The first import / backfill must not trigger "auto-push new content".** A new source's first scan should only store data, or the channel gets flooded with hundreds of posts.
18. **The root agent decides compliance questions, conservatively.** Endpoints disallowed by robots.txt, or internal APIs that need forged headers or a borrowed browser session, are never used.
19. **When module sessions ask the Owner questions or pop browser "Allow" prompts, the Owner gets interrupted constantly.** Route all questions through the root agent, and use curl to check web pages.
20. **When the Owner says "remember this", write the rule into both AGENTS.md and the root agent's long-term memory**, or the next session will make the same mistake.

## Scope

- Designed for coding agents like Claude Code that can read and write the repo and run commands. Works best when sessions can message each other (e.g. `SendMessage` in the Claude Code desktop app). If they can't, the Owner copies module reports to the root agent by hand — the flow is the same.
- Hooks are bash + git and support macOS / Linux.
- These are conventions and guardrails; they don't replace code review or tests.

## License

MIT — see [LICENSE](LICENSE).
