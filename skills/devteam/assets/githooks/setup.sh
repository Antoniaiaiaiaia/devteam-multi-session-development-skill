#!/usr/bin/env bash
# clone 后跑一次：启用仓库钩子，禁止 fast-forward 合并（否则合并 main 不经过钩子）。
set -euo pipefail
cd "$(git rev-parse --show-toplevel)"
chmod +x .githooks/*
git config core.hooksPath .githooks
git config merge.ff false
echo "✓ hooks enabled. modules: $(grep -vE '^\s*(#|$)' .githooks/modules | tr '\n' ' ')"
git remote get-url origin >/dev/null 2>&1 \
  && echo "  backup remote: $(git remote get-url origin)" \
  || echo "  （可选）加一个 private 备份仓库：git remote add origin <url>"
