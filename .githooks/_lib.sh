# 被其他钩子 source 的公共函数。

# 读 .githooks/modules，输出模块名（去掉注释和空行）
agent_modules() {
  grep -vE '^\s*(#|$)' "$(dirname "${BASH_SOURCE[0]}")/modules" | tr -d ' \t\r'
}

# 当前分支是不是模块分支；是的话输出模块名
agent_branch_module() {
  local branch="$1" m
  for m in $(agent_modules); do
    case "$branch" in "$m"/*) echo "$m"; return 0 ;; esac
  done
  return 1
}

# 输出正在合并进来的提交（每行一个），不在合并中则无输出。
# 有冲突的合并：读 MERGE_HEAD。
# 无冲突的合并：pre-merge-commit 阶段还没有 MERGE_HEAD，只能从 GIT_REFLOG_ACTION（"merge <ref>..."）解析。
agent_merge_heads() {
  local f
  f=$(git rev-parse --git-path MERGE_HEAD)
  if [ -f "$f" ]; then cat "$f"; return; fi
  case "${GIT_REFLOG_ACTION:-}" in
    "merge "*)
      for r in ${GIT_REFLOG_ACTION#merge }; do
        case "$r" in -*) ;; *) git rev-parse -q --verify "$r^{commit}" ;; esac
      done ;;
  esac
}

# 正在把 main（或 main 上的某个提交）合进来：恰好一个合并来源，且它在 main 上
agent_merging_main() {
  local heads
  heads=$(agent_merge_heads)
  [ -n "$heads" ] && [ "$(printf '%s\n' "$heads" | wc -l | tr -d ' ')" = 1 ] \
    && git merge-base --is-ancestor "$heads" main
}
