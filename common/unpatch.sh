#!/usr/bin/env bash
# ============================================================================
# 反向回滚 PATCHDIR 里的 *.patch（patch -R）。配合 apply-overlay.sh -undo 使用。
# 用法: bash common/unpatch.sh <TREE> <PATCHDIR>
# ============================================================================
set -euo pipefail

TREE="${1:?用法: unpatch.sh <TREE> <PATCHDIR>}"
PATCHDIR="${2:?用法: unpatch.sh <TREE> <PATCHDIR>}"
cd "$TREE" || { echo "cd $TREE 失败" >&2; exit 1; }

shopt -s nullglob
PATCHES=("$PATCHDIR"/*.patch)
if [ ${#PATCHES[@]} -eq 0 ]; then
    echo "无补丁可回滚: $PATCHDIR"
    exit 0
fi

# 逆序回滚更稳妥（与打补丁顺序相反）
for ((i=${#PATCHES[@]}-1; i>=0; i--)); do
    p="${PATCHES[$i]}"
    echo ">> reverse $(basename "$p")"
    patch -p1 --reverse --forward --dry-run < "$p" >/dev/null 2>&1 \
        && patch -p1 --reverse --forward < "$p" \
        || echo "   跳过(可能未打): $(basename "$p")"
done
