# LKD3568 (Neardi, RK3568)

第二块板。SOC 层 fork 已带（`device/soc/rockchip/rk3568`），板级需按
`dayu200`（RK3568 官方参考板）/ `lkd3576` 模式新建。

## 本目录内容
- `build.env`：参数占位。
- `device-overlay/`：待 sync 后从 dayu200 + lkd3576 模板派生。
- `patches/`：待定。

## 待办
- [ ] 派生 device/board/neardi/lkd3568 + vendor/neardi/lkd3568/config.json
- [ ] LKD3568 底板 DT 按实际模组 retarget
- [ ] 核 API_VERSION 真值
