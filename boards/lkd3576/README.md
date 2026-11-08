# LKD3576 (Neardi, RK3576)

第一块落地板，社区已有 `rk3576_openharmony_adaptation_guide` 可改造。

## 来源
社区指南提供三套目录：`device_board_rk_board_rk3576`、`device_soc_rockchip_rk3576`、
`vendor_rk_board_rk3576` + `rk3576_env.sh`（带 `-undo`）+ `rk3576_patch/`。
落地时把 vendor 由 `rk_board` 改为 `neardi`，板名 `rk3576` → `lkd3576`。

## 本目录内容
- `build.env`：构建参数（PRODUCT_NAME / CHIP / KERNEL / API_VERSION …）。
- `device-overlay/`：按 OpenHarmony 树结构放置板级三件套，由 `common/apply-overlay.sh` 拷入树。
  - `device/board/neardi/lkd3576/`      板构建脚本 + kernel defconfig + .dts + HDF
  - `device/soc/rockchip/rk3576/`       （若 fork 的 soc 仓未含 rk3576，需补）
  - `vendor/neardi/lkd3576/config.json` product 定义
- `patches/`：构建补丁（仿社区 `0_add_local_ccache` / `1_arm64_close_selinux` / `2_fix_build`）。

## 待办
- [ ] 确认 fork `device/soc/rockchip/` 是否含 rk3576（不含则拷入 device-overlay）
- [ ] 外围 retarget：Wi-Fi 模组 / 音频 codec / 双千兆 PHY / HDMI-MIPI
- [ ] 核 API_VERSION 真值（社区写的 8 是错的）
