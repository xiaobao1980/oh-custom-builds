# CM3588-NAS (FriendlyElec, RK3588)

第三块板，**建议最后做**：该机当前跑 HAOS 18.3，先验证 OH 能在 LKD3576/LKD3568 上起来再动它。

## 本目录内容
- `build.env`：参数占位（`KERNEL=linux-6.1` 取自 FriendlyElec 6.1 内核基准）。
- `device-overlay/`：待 sync 后核 fork 是否带 rk3588 参考板；不带则完全自建。
- `patches/`：待定。

## 待办
- [ ] 确认 fork `device_board_rockchip` 是否带 rk3588 参考板
- [ ] DT 取 FriendlyElec 6.1 内核；U-Boot / rkbin DDR + bl31 blob 对应
- [ ] NAS 特性：M.2 NVMe / SATA / 多网口 retarget
- [ ] 烧录前备份 HAOS；U-Boot + MiniLoaderAll.bin 与 CM3588 同烧防砖
