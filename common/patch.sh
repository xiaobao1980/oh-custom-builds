#!/usr/bin/env bash
# ============================================================================
# 按文件名顺序给 PATCHDIR 里的 *.patch 打上（默认 -p1，从 TREE 根打）。
#
# 约定（重要）:
#   - 补丁路径相对 TREE 根书写（与社区 rk3576_patch/ 一致，如 a/build/... ）。
#   - 跨 repo 工程的补丁（如只改 kernel 仓内部）请在该补丁内用相对路径，
#     或在 boards/<board>/patches/ 里用 "<repo>__<name>.patch" 命名并在本脚本
#     按前缀 cd 进对应工程再打（当前骨架用统一 -p1，足够三板起步）。
#   - 已打过的补丁会被跳过（git apply --check 失败则退化为 patch --forward）。
# ============================================================================
set -euo pipefail

TREE="${1:?用法: patch.sh <TREE> <PATCHDIR>}"
PATCHDIR="${2:?用法: patch.sh <TREE> <PATCHDIR>}"
cd "$TREE" || { echo "cd $TREE 失败" >&2; exit 1; }

shopt -s nullglob
PATCHES=("$PATCHDIR"/*.patch)
if [ ${#PATCHES[@]} -eq 0 ]; then
    echo "无补丁: $PATCHDIR"
    exit 0
fi

for p in "${PATCHES[@]}"; do
    echo ">> apply $(basename "$p")"
    if git apply --check "$p" >/dev/null 2>&1; then
        git apply "$p"
    else
        patch -p1 --forward --dry-run < "$p" >/dev/null 2>&1 \
            && patch -p1 --forward < "$p" \
            || echo "   跳过(可能已打或与当前树不符): $(basename "$p")"
    fi
done
