#!/usr/bin/env bash
# ============================================================================
# 把 boards/<board>/device-overlay 拷进 OpenHarmony 树，并打上该板的补丁。
#
# 用法:
#   bash common/apply-overlay.sh <board> <TREE_PATH>
#   bash common/apply-overlay.sh <board> <TREE_PATH> -undo   # 反向回滚
#
# 抗 repo sync 冲掉策略（你一贯要求的"防回归/可复现"落地处）:
#   - 板级目录放在自有命名空间 device/board/<vendor>/<board> 与 vendor/<vendor>/<product>，
#     这些是 fork 仓之外的"新目录"，repo sync 不会动，天然存活。
#   - 本脚本把 overlay 拷入时先备份被覆盖的树内文件到 .overlay-backup/<board>，
#     并打上 patches/ 里的补丁；-undo 时反向还原，可重放、可回滚。
#   - 更彻底的玩法见 common/local_manifest.xml.example（把 overlay 做成独立仓经
#     local_manifest 引入），本脚本是轻量版，够三块板用。
# ============================================================================
set -euo pipefail

BOARD="${1:?用法: apply-overlay.sh <board> <TREE> [-undo]}"
TREE="${2:?用法: apply-overlay.sh <board> <TREE> [-undo]}"
UNDO=0
[[ "${3:-}" == "-undo" ]] && UNDO=1

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
OVERLAY="$HERE/boards/$BOARD/device-overlay"
PATCHDIR="$HERE/boards/$BOARD/patches"

if [ ! -d "$OVERLAY" ]; then
    echo "overlay 不存在: $OVERLAY" >&2
    exit 1
fi
cd "$TREE" || { echo "cd $TREE 失败" >&2; exit 1; }

if [ "$UNDO" -eq 1 ]; then
    echo "[$(date '+%F %T')] UN-APPLY $BOARD (reverse patches + restore backup)"
    bash "$HERE/common/unpatch.sh" "$TREE" "$PATCHDIR"
    if [ -d "$TREE/.overlay-backup/$BOARD" ]; then
        rsync -a --delete "$TREE/.overlay-backup/$BOARD/" "$TREE/" 2>/dev/null \
            || cp -rf "$TREE/.overlay-backup/$BOARD/." "$TREE/"
        rm -rf "$TREE/.overlay-backup/$BOARD"
    fi
    echo "undo 完成"
    exit 0
fi

echo "[$(date '+%F %T')] APPLY $BOARD -> $TREE"
mkdir -p "$TREE/.overlay-backup/$BOARD"
# 仅备份 overlay 会触碰到的路径；优先 rsync --backup，无 rsync 时退化为新增不覆盖
if command -v rsync >/dev/null 2>&1; then
    rsync -a --backup --backup-dir="$TREE/.overlay-backup/$BOARD" "$OVERLAY/" "$TREE/"
else
    cp -rn "$OVERLAY/." "$TREE/"
fi
# 打补丁
bash "$HERE/common/patch.sh" "$TREE" "$PATCHDIR"
echo "apply 完成；回滚命令: bash common/apply-overlay.sh $BOARD $TREE -undo"
