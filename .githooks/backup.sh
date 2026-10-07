#!/usr/bin/env bash
# （可选）自动备份：本地领先 origin（private 备份仓库）达到阈值时推送。没有 origin 时什么都不做。
#
# 推送条件（满足任一）：
#   1. main 领先 origin/main（main 只在总管验收合并时移动，每次验收都备份）
#   2. 所有本地分支未推送的提交合计 >= BACKUP_MIN_COMMITS（默认 5）
#   3. 最老的未推送提交超过 BACKUP_MAX_AGE_HOURS 小时（默认 6）
# 推送范围：main + .githooks/modules 里每个模块的 <module>/* 分支；本地删掉的模块分支在远端同步删除。
# 绝不 force push。失败重试 3 次；仍失败且设置了 BACKUP_ALERT_CMD 时，执行它告警（失败原因作为 $1）。
#
# 用法：backup.sh（按阈值） / backup.sh --now（立即推） / backup.sh --status（只看领先情况）
# 想要"每小时兜底检查"（负责第 3 条），用系统定时任务每小时跑一次本脚本（macOS 用 LaunchAgent，Linux 用 cron / systemd timer）。
set -uo pipefail

MIN_COMMITS=${BACKUP_MIN_COMMITS:-5}
MAX_AGE_HOURS=${BACKUP_MAX_AGE_HOURS:-6}
export GIT_TERMINAL_PROMPT=0

mode=${1:-}
cd "$(dirname "$0")/.." || exit 1
. .githooks/_lib.sh
git remote get-url origin >/dev/null 2>&1 || exit 0
common=$(git rev-parse --path-format=absolute --git-common-dir) || exit 1
log="$common/agent-backup.log"; lock="$common/agent-backup.lock"
say() { printf '%s %s\n' "$(date '+%F %T')" "$*" >> "$log"; }

if git rev-parse -q --verify refs/remotes/origin/main >/dev/null; then
  main_ahead=$(git rev-list --count origin/main..main)
else
  main_ahead=$(git rev-list --count main)
fi
unpushed=$(git rev-list --count --branches --not --remotes=origin)
oldest=$(git log --branches --not --remotes=origin --format=%ct | sort -n | head -n1)
age_h=0; [ -n "$oldest" ] && age_h=$(( ($(date +%s) - oldest) / 3600 ))

if [ "$mode" = --status ]; then
  echo "main 领先 origin/main: $main_ahead"
  echo "未推送提交合计: $unpushed（阈值 $MIN_COMMITS）"
  echo "最老未推送提交: ${age_h}h 前（阈值 ${MAX_AGE_HOURS}h）"
  exit 0
fi

reason=""
if [ "$mode" = --now ]; then reason="manual"
elif [ "$main_ahead" -gt 0 ]; then reason="main ahead $main_ahead"
elif [ "$unpushed" -ge "$MIN_COMMITS" ]; then reason="$unpushed unpushed commits"
elif [ -n "$oldest" ] && [ "$age_h" -ge "$MAX_AGE_HOURS" ]; then reason="oldest unpushed ${age_h}h"
fi
[ -z "$reason" ] && exit 0

if ! mkdir "$lock" 2>/dev/null; then
  [ $(( $(date +%s) - $(stat -f %m "$lock" 2>/dev/null || stat -c %Y "$lock") )) -gt 600 ] && rmdir "$lock" && mkdir "$lock" || exit 0
fi
trap 'rmdir "$lock" 2>/dev/null' EXIT

refspecs=(main)
for m in $(agent_modules); do refspecs+=("refs/heads/$m/*:refs/heads/$m/*"); done

say "PUSH ($reason)"
for delay in 2 4 8 0; do
  if out=$(git push --prune --porcelain origin "${refspecs[@]}" 2>&1); then
    say "OK $(printf '%s' "$out" | grep $'\t' | tr '\n' ' ')"; exit 0
  fi
  say "FAIL $(printf '%s' "$out" | tail -n3 | tr '\n' ' ')"
  [ "$delay" -gt 0 ] && sleep "$delay"
done
[ -n "${BACKUP_ALERT_CMD:-}" ] && $BACKUP_ALERT_CMD "backup failed ($reason): $(printf '%s' "$out" | tail -n2 | tr '\n' ' ')"
exit 1
