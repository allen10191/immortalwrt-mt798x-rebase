# RAX3000M(NAND) 定制编译说明

> 目标设备：CMCC RAX3000M（**NAND 版**，MT7981B + 512MB RAM + 128MB SPI-NAND）
> 源码：`immortalwrt-mt798x-rebase`（25.12 分支，ImmortalWrt 25.12 + MTK 闭源驱动）

## 本次定制内容

### 新增插件（已写入 `defconfig/mt7981-rax3000m-nand.config`）

| 功能 | 包名 | 说明 |
|---|---|---|
| HomeProxy | `luci-app-homeproxy` | sing-box 内核，全功能代理 |
| Internet Access Control | `luci-app-accesscontrol` | 按 MAC/IP 定时上网控制 |
| 网络共享 | `luci-app-samba4` + `samba4-server` | Samba 文件共享 |
| 硬盘休眠 | `hd-idle` | 空闲自动停转外接硬盘 |
| 应用过滤 | `luci-app-oaf` + `appfilter` + `kmod-oaf` | OpenAppFilter DPI 行为管理 |
| 网速控制 | `luci-app-control-speedlimit` | 按 IP/MAC 限速（tc/ifb） |
| （配套）USB 存储 | `kmod-usb-storage`/`uas` + `kmod-fs-exfat/ntfs3/ext4` | 挂载 U 盘/移动硬盘 |
| （配套）磁盘管理 | `luci-app-diskman` | 图形化挂载/格式化 |

> 说明：源码自带 MTK 的 `luci-app-eqos-mtk`（端口级限速）与 `luci-app-turboacc-mtk`（硬件加速）也会保留。

### 外部插件源码（已放入 `package/`）
- `package/OpenAppFilter` —— 应用过滤（OAF），包含 `luci-app-oaf` / `appfilter` / `kmod-oaf`
- `package/luci-app-control-speedlimit` —— 网速控制

### 配置文件
- `defconfig/mt7981-rax3000m-nand.config` —— **仅构建 RAX3000M(NAND) 单机型** + 以上插件

---

## 编译方式（二选一）

### 方式 A：GitHub Actions 云编译（推荐，无需本机 Linux）
1. 把本仓库推到你的 GitHub 仓库（GitHub Desktop 即可）；
2. 打开仓库 **Actions** 页 → 左侧 **「编译 RAX3000M NAND 固件」** → 右侧 **Run workflow**；
3. 编译完成后，在该运行记录底部 **Artifacts** 下载 `rax3000m-nand-firmware`。

### 方式 B：WSL / Linux 本地编译
```bash
cd /path/to/immortalwrt-mt798x-rebase
bash build-rax3000m.sh
```
脚本会自动：写配置 → 更新 feeds → `make defconfig` → **校验插件是否齐全** → 预下载 → 编译。

### 手动版（想自己点菜单）
```bash
cp -f defconfig/mt7981-rax3000m-nand.config .config
./scripts/feeds update -a && ./scripts/feeds install -a
make menuconfig     # 可在 LuCI → Applications 里增减插件
make -j$(nproc) V=s
```

---

## 刷机

产物在 `bin/targets/mediatek/filogic/`：
- `openwrt-mediatek-filogic-cmcc_rax3000m-*-squashfs-sysupgrade.bin` —— 已刷 ImmortalWrt 后在「系统 → 备份/升级」或 U-Boot Web 上传
- 若你用的是 hanwckf U-Boot，直接进 U-Boot 网页上传 **initramfs** 版再升级到 sysupgrade 版

---

## 注意事项（避坑）

1. **应用过滤（OAF）与硬件加速冲突**：OAF 做 DPI 识别，使用前需在「网络 → 防火墙 / Turbo ACC」里**关闭流量分载（flow offload / HW NAT）**，否则应用识别失效。
2. **内核 6.12 与 kmod-oaf**：本仓库内核为 6.12，若编译时 `kmod-oaf` 报错（内核头不兼容），到 [OpenAppFilter issues](https://github.com/destan19/OpenAppFilter/issues) 找 6.12 适配补丁，或改用 6.6 内核版本的分支。
3. **网速控制与 SQM 二选一注意**：`luci-app-control-speedlimit` 与自带 `luci-app-eqos-mtk` 都做限速，同时开可能互相干扰，建议只用其一。
4. **首次编译慢**：建议网络好时先单独跑 `make -j$(nproc) download V=s` 预取源码。
5. **插件校验失败**：脚本会打印未选中的包名并退出，请据此排查（一般是包名随版本变化，或依赖缺失）。

---

## 改动文件清单

| 路径 | 说明 |
|---|---|
| `package/OpenAppFilter/` | 新增，应用过滤插件源码 |
| `package/luci-app-control-speedlimit/` | 新增，网速控制插件源码 |
| `defconfig/mt7981-rax3000m-nand.config` | 新增，RAX3000M(NAND) 单机型 + 插件配置 |
| `build-rax3000m.sh` | 新增，一键编译脚本 |
| `.github/workflows/build-rax3000m.yml` | 新增，GitHub Actions 云编译 |
| `BUILD-RAX3000M.md` | 本说明 |
