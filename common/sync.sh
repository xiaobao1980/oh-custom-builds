#!/usr/bin/env bash
# ============================================================================
# OpenHarmony 增量 repo sync —— 复用本地已存在的参考树，绝不重新下载共享仓
#
# 用法:
#   bash common/sync.sh [TREE_PATH]
#
# 设计要点（区别于 Armbian 每次全新 clone）:
#   - OpenHarmony 整树 97G+，公共 runner 装不下、跨境拉不动，所以构建机必须
#     持久化一棵已 sync 的树；workflow 只做"增量 sync"。
#   - --reference 指向你那棵标准 6.1-LTS 树，共享仓的 git 对象直接复用。
#   - 断点续传: 中途被杀(如关机)后重跑本脚本会跳过已完成工程，接着拉。
#   - 清残留锁 + nproc 并行；结尾自动 git lfs pull。
# ============================================================================
set -euo pipefail

TREE="${1:-/home/xiaobao/share/OpenHarmony-v6.1/rk3576_oh_6.1}"
LOG="$TREE/sync.log"
OUT="$TREE/sync.out"
REFERENCE="${REFERENCE:-/home/xiaobao/share/OpenHarmony-v6.1/OpenHarmony}"

cd "$TREE" || { echo "cd $TREE 失败" >&2; exit 1; }
export PATH="$HOME/bin:$PATH"

# 并行度: 构建机多核，取物理核数；网络弱时可在环境变量覆盖 SYNC_J
SYNC_J="${SYNC_J:-$(nproc)}"

echo "[$(date '+%F %T')] SYNC_START pid=$$ reference=$REFERENCE j=$SYNC_J" | tee -a "$LOG"

# 清掉可能残留的锁（异常关机/强杀后常见）
rm -f .repo/*.lock 2>/dev/null || true

repo sync -c -j"$SYNC_J" --no-repo-verify >> "$OUT" 2>&1
SY=$?
echo "[$(date '+%F %T')] repo_sync_exit=$SY" | tee -a "$LOG"

if [ "$SY" -eq 0 ]; then
    echo "[$(date '+%F %T')] lfs pull ..." | tee -a "$LOG"
    repo forall -c 'git lfs pull' >> "$OUT" 2>&1 || true
    echo "[$(date '+%F %T')] LFS_DONE" | tee -a "$LOG"
    echo SYNC_DONE >> "$LOG"
else
    echo SYNC_FAILED >> "$LOG"
fi
