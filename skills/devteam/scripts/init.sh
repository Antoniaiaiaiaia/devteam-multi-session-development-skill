#!/usr/bin/env bash
# /devteam init：把框架装进当前 git 仓库。已存在的文件一律不覆盖（列出跳过了哪些）。
# 用法：bash init.sh <模块…>     例：bash init.sh design frontend backend
set -euo pipefail

SKILL="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ROOT="$(git rev-parse --show-toplevel 2>/dev/null)" || { echo "✗ 不在 git 仓库里，先 git init" >&2; exit 1; }
cd "$ROOT"

MODULES=("$@")
[ ${#MODULES[@]} -eq 0 ] && MODULES=(design frontend backend)

skipped=()
copy() { # copy <src> <dst>
  if [ -e "$2" ]; then skipped+=("$2"); else mkdir -p "$(dirname "$2")"; cp "$1" "$2"; echo "  + $2"; fi
}

echo "安装到 $ROOT"
copy "$SKILL/assets/AGENTS.md" AGENTS.md
copy "$SKILL/assets/templates/context.md" context.md
copy "$SKILL/assets/templates/change-log.md" change-log.md

mkdir -p .githooks
for f in "$SKILL"/assets/githooks/*; do
  name="$(basename "$f")"
  [ "$name" = modules ] && continue
  copy "$f" ".githooks/$name"
done
if [ -e .githooks/modules ]; then
  skipped+=(".githooks/modules")
else
  { echo "# 模块列表：一行一个目录名。模块分支名必须是 <module>/<topic>，且只能改 <module>/ 下的文件。"; printf '%s\n' "${MODULES[@]}"; } > .githooks/modules
  echo "  + .githooks/modules（${MODULES[*]}）"
fi

for m in "${MODULES[@]}"; do
  if [ -e "$m/README.md" ]; then skipped+=("$m/README.md"); continue; fi
  mkdir -p "$m"
  sed "s/<module>/$m/g" "$SKILL/assets/templates/module-README.md" > "$m/README.md"
  echo "  + $m/README.md"
done

bash .githooks/setup.sh

if [ ${#skipped[@]} -gt 0 ]; then
  echo "已存在、没有覆盖：${skipped[*]}"
fi
echo "下一步：填 AGENTS.md 里的 <占位符>，以总管身份提交（AGENT_ROOT=1 git commit），然后这个 session /devteam root，其他 session /devteam <模块>。"
