# oh-custom-builds

OpenHarmony 多板卡镜像**在线/自动化构建**骨架。结构平移自
[xiaobao1980/armbian-custom-builds](https://github.com/xiaobao1980/armbian-custom-builds)
的「`boards/` 隔离 + `common/` 共享 + workflow 下拉参数 + 矩阵 + Releases」模式，
但执行环境改为 **GitHub Actions self-hosted runner**，重活留在构建机那棵**持久化**的
OpenHarmony 源码树（公共 runner 装不下 97G+ 的树，也跨境拉不动 gitcode 的 rk-develop fork）。

## 当前进度

- LKD3576：`repo sync` 进行中（rk-develop fork，整条 Rockchip 6.1 适配）。
- LKD3568 / CM3588-NAS：仅参数占位，板级 overlay 待 sync 后落地。

## 目录结构

```
oh-custom-builds/
├── boards/
│   ├── lkd3576/          build.env + device-overlay/ + patches/
│   ├── lkd3568/          （占位）
│   └── cm3588-nas/       （占位，该机现跑 HAOS，建议最后做）
├── common/
│   ├── sync.sh           增量 repo sync（--reference 复用本地 97G 树，断点续传）
│   ├── apply-overlay.sh  把板级 overlay 拷进树 + 打补丁（-undo 可回滚）
│   ├── patch.sh          按序打 boards/<board>/patches/*.patch
│   ├── unpatch.sh        反向回滚
│   ├── build.sh          封装 ./build.sh --product-name <X> --ccache
│   └── local_manifest.xml.example  更抗造的 overlay 引入方式（可选）
└── .github/workflows/
    ├── build-image.yml   单板：下拉 board / kernel / tag
    └── build-all.yml     矩阵：多板并行
```

## 与 armbian-custom-builds 的关键差异

| 维度 | Armbian | OpenHarmony |
|---|---|---|
| 每次构建 | 全新 clone 框架 | **持久化一棵已 sync 的树**，workflow 只做增量 `repo sync` |
| 构建命令 | `compile.sh ...` | `./build.sh --product-name <X> --ccache` |
| 板级隔离 | `boards/<b>/` → `userpatches/` | `device/board/<vendor>/<board>` + `vendor/<vendor>/<product>/config.json` |
| 防 sync 冲掉 | 不适用 | 板级放自有命名空间 + 可重放脚本 / local_manifest |
| 镜像分发 | Releases | Releases 有 **2G/文件** 上限，超限先 xz 或走本地 HTTP 源 |

## 前置条件

1. **构建机**：已备 97G 标准树 + `openharmony_prebuilts` + 持久化的 rk3576_oh_6.1 树。
2. **磁盘**：多板 + ccache 建议 ≥700G 余量（当前 350G/已用 209G，偏紧，需扩容）。
3. **self-hosted runner**：在构建机装 GitHub Actions runner，打标签 `oh-builder`，
   URL/令牌从仓库 Settings → Actions → Runners 获取。runner 主动外连，内网可用。

## 手动跑（不走 GitHub）

```bash
TREE=/home/xiaobao/share/OpenHarmony-v6.1/rk3576_oh_6.1
bash common/sync.sh "$TREE"
bash common/apply-overlay.sh lkd3576 "$TREE"
bash common/build.sh lkd3576 "$TREE"
```

## 新增板卡 SOP

0. 判定档位：新板(SOC 已在 fork) 最轻；新 SOC 最重。
1. `ls device/soc/rockchip/` 确认 SOC 层齐；不齐先引 SOC 子配置 + 内核 DT。
2. `cp -r` 模板建 `boards/<newboard>/{build.env,device-overlay,patches}`。
3. 在 `device-overlay/` 里按树结构放 `device/board/<vendor>/<board>`、
   `vendor/<vendor>/<product>/config.json`、`device/soc/rockchip/<chip>`（如需）。
4. 从原厂 6.1 内核抠该板 `.dts` 移植；逐项 retarget Wi-Fi/音频/网卡/显示。
5. `loader/u-boot` 加该板 defconfig；确认 `loader/rkbin` 含对应 DDR/bl31 blob。
6. 备 `patches/`（仿社区 `0_add_local_ccache` / `1_arm64_close_selinux` / `2_fix_build`）。
7. `bash common/build.sh <newboard> "$TREE"`；多板各自 `out/<name>/`，勿全局 `rm -rf out`。
8. RKDevTool 烧录时 **U-Boot + MiniLoaderAll.bin 必须与该板同烧**。

## 必须记住的坑

- **`api_version=8` 是错的**：社区 rk3568 参考写的 8 是 OH3.x 旧字段，6.1 应约 20，三板都要改真值。
- **内核版本二选一**：fork 同时给 linux-6.1 / linux-6.6，每块板锁定 DT 基准，三板尽量一致。
- **外围必须 retarget**：社区参考板用博通 `bcmdhd_wifi6` + `BCM4362A2` BT，大概率对不上各板实际模组。
- **抗 sync 冲掉**：板级目录放 fork 仓之外 + 可重放脚本；或上 `local_manifest.xml.example`。
- **CM3588-NAS 现跑 HAOS**：最后做，烧录前备份 HAOS，loader 与 CM3588 同烧防砖。
