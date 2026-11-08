# SETUP —— 远程仓库与 Self-hosted Runner 安装清单

> 本仓库是 OpenHarmony Rockchip（RK3568 / RK3576 / RK3588）多板镜像的在线构建骨架，
> 模式平移自 `armbian-custom-builds`，但执行环境改为 **GitHub Actions self-hosted runner**
> （因为 OpenHarmony 整树 97G+，公共 runner 装不下、跨境也拉不动）。
>
> 构建机：`192.168.60.192`（xiaobao / 123456，Ubuntu 22.04 KVM），已备 97G 参考树 +
> `openharmony_prebuilts` + 持久化 rk3576 树。

---

## A. 远程仓库（已完成 ✅）

| 项 | 值 |
|---|---|
| 仓库地址 | https://github.com/xiaobao1980/oh-custom-builds |
| 可见性 | public（与 `armbian-custom-builds` 一致；含公开板级配置，无密钥） |
| 已推送分支 | `main`（初始骨架 commit） |

- 改 private：`gh repo edit xiaobao1980/oh-custom-builds --private`
- 本地已加 `origin` 远程，后续 `git push` 即可。

---

## B. 构建机 Self-hosted Runner 安装（Ubuntu 22.04）

Runner 主动外连 GitHub 取任务，**内网 / NAT 后也能用，无需开入站端口**。

### B.0 前置确认
- [ ] `~/bin/repo` 与 `~/bin/python → python3` 软链已就位（编译 OH 依赖）
- [ ] 持久化 OH 树存在：`/home/xiaobao/share/OpenHarmony-v6.1/rk3576_oh_6.1`
- [ ] 磁盘余量充足（建议 ≥500G；见 README 容量测算）

### B.1 装 runner 依赖
```bash
sudo apt-get update
sudo apt-get install -y curl tar git libicu70 libssl3 libkrb5-3 zlib1g
```

### B.2 下载 runner 包（⚠️ 限速处理）
直连 GitHub 实测 **被限到 ~28KB/s**（217MB 要 2 小时），**必须用国内镜像**：

```bash
mkdir -p ~/actions-runner && cd ~/actions-runner
# 直连（仅作对照，勿用）：
#   https://github.com/actions/runner/releases/download/v2.338.2/actions-runner-linux-x64-2.338.2.tar.gz
# 国内镜像：在直连 URL 前加 https://ghproxy.net/ 前缀
curl -L -o ar.tar.gz \
  https://ghproxy.net/https://github.com/actions/runner/releases/download/v2.338.2/actions-runner-linux-x64-2.338.2.tar.gz
tar xzf ar.tar.gz
./bin/installdependencies.sh   # 若有缺失依赖，脚本会提示
```
> `ghproxy.com` 已失效；`ghproxy.net` 实测 ~213KB/s（约 17 分钟）。

### B.3 生成注册 token（**每次安装前现生成**，有效期 1 小时）
在 GitHub 网页：`仓库 → Settings → Actions → Runners → New self-hosted runner → 复制命令中的 token`；
或用 `gh`（本机已登录 xiaobao1980 账号）：
```bash
gh api -X POST repos/xiaobao1980/oh-custom-builds/actions/runners/registration-token --jq .token
```

### B.4 注册 runner
```bash
cd ~/actions-runner
./config.sh --url https://github.com/xiaobao1980/oh-custom-builds \
            --token <上一步的TOKEN> \
            --labels oh-builder \
            --name oh-builder-1 \
            --runnergroup "" \
            --unattended
```
注册成功后，runner 出现在 `仓库 → Settings → Actions → Runners` 列表（此时状态为 **offline**，正常）。

### B.5 装成 systemd 服务（重启自动上线，以 xiaobao 身份跑，保留 ~/bin 环境）
```bash
sudo tee /etc/systemd/system/github-runner-oh.service >/dev/null <<'EOF'
[Unit]
Description=GitHub Actions Runner (oh-custom-builds)
After=network.target

[Service]
User=xiaobao
WorkingDirectory=/home/xiaobao/actions-runner
ExecStart=/home/xiaobao/actions-runner/run.sh
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl daemon-reload
sudo systemctl enable github-runner-oh.service   # 开机自启（务必，因为要扩容重启）
# 暂不 start —— 见下方 ⚠️ 冲突警告
```

### B.6 启动并验证
```bash
sudo systemctl start github-runner-oh.service
systemctl status github-runner-oh.service
# 在 GitHub 网页或本机确认 online：
gh api repos/xiaobao1980/oh-custom-builds/actions/runners --jq '.runners[]|{name,status}'
```

---

## ⚠️ 关键：避免双 `repo sync` 撞树

构建机上**另有一路手动 `repo sync`（PID 2416）正在跑**（拉 rk3576 整条 fork）。
runner 一旦 online，若此时从 GitHub 触发 `build-image.yml`，workflow 第一步就是
`common/sync.sh` → 又会起一个 `repo sync` 操作**同一棵树**，可能损坏 `.repo` 状态。

**规则**：
- 在手动 sync 出 `SYNC_DONE` 之前（或扩容重启之前），**不要**从 GitHub 触发构建。
- sync 完成后（或扩容重启后 runner 自启），再触发构建即可，脚本会自动增量 sync（已完成项跳过）。

---

## C. 触发构建

- **单板**：`Actions → Build OH Image (single board) → Run workflow`，下拉选
  `board`（`lkd3576` / `lkd3568` / `cm3588-nas`）、`kernel`、`tag`（空=只出 Artifact）。
- **全板矩阵**：`Actions → Build All Boards`（`build-all.yml`，`fail-fast: false`）。
- **产物**：Artifacts（保留 90 天）；`tag` 非空时额外发 Releases。
  > GitHub Releases 单文件硬上限 **2G**，镜像超限请先 `xz` 压缩，或走本地 HTTP 源
  >（构建机 `python3 -m http.server 8000`）。

## D. 新增板卡
见 `README.md` 的 SOP 与 `boards/<board>/README.md`。核心是复用 LKD3576 配方骨架，
板级放 `device/board/<vendor>/` + `vendor/<vendor>/<product>/config.json` 自有命名空间，
补丁做成可重放脚本（`apply-overlay.sh` / `patch.sh`），`repo sync` 后不丢。

---

## E. 故障排查
| 现象 | 处理 |
|---|---|
| runner 一直 offline | `systemctl status github-runner-oh`；看 `~/actions-runner/_diag` 日志；确认出网到 GitHub |
| 构建报 `python: command not found` | 确认 `~/bin/python` 软链存在；`common/*.sh` 已 `export PATH=$HOME/bin:$PATH` |
| 构建报 `repo: command not found` | 同 PATH 问题；或重新 `ln -sf $(which repo) ~/bin/repo` |
| 下载 runner 极慢 | 直连被限，换 `ghproxy.net` 前缀（见 B.2） |
| 触发构建后卡在 sync | 检查是否和手动 sync 冲突（见上方 ⚠️） |
