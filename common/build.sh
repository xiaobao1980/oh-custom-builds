#!/usr/bin/env bash
# ============================================================================
# 封装 OpenHarmony 单板构建（fork 的 ./build.sh --product-name <X> --ccache）。
#
# 用法:
#   bash common/build.sh <board> [TREE_PATH]
#
# 要点:
#   - 从 boards/<board>/build.env 读取 PRODUCT_NAME 等参数。
#   - 多板共存时【不要】全局 rm -rf out，否则前面板的镜像白编；本脚本默认不清，
#     只在 build.env 设 FORCE_CLEAN_OUT=1 时才清本板 out 目录。
#   - 编完打印 out/<product>/images 产物清单。
# ============================================================================
set -euo pipefail

BOARD="${1:?用法: build.sh <board> [TREE]}"
TREE="${2:-/home/xiaobao/share/OpenHarmony-v6.1/rk3576_oh_6.1}"
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck disable=SC1090
source "$HERE/boards/$BOARD/build.env"

cd "$TREE" || { echo "cd $TREE 失败" >&2; exit 1; }
export PATH="$HOME/bin:$PATH"

PRODUCT="${PRODUCT_NAME:?build.env 缺 PRODUCT_NAME}"
IMG_DIR="$TREE/out/$PRODUCT/images"

if [ "${FORCE_CLEAN_OUT:-0}" = "1" ]; then
    echo "[$(date '+%F %T')] FORCE_CLEAN_OUT: rm -rf out/$PRODUCT"
    rm -rf "$TREE/out/$PRODUCT"
fi

echo "[$(date '+%F %T')] BUILD $PRODUCT (ccache, kernel=${KERNEL:-default})"
./build.sh --product-name "$PRODUCT" --ccache

echo "[$(date '+%F %T')] images:"
ls -lh "$IMG_DIR" 2>/dev/null || { echo "未找到 $IMG_DIR"; exit 1; }

# Rockchip 整包（fork 的 build-rk.sh 通常产出 update.img）
UPDATE_IMG="$TREE/out/$PRODUCT/packages/phone/images/update.img"
[ -f "$UPDATE_IMG" ] && echo "update.img ready: $UPDATE_IMG" || true
