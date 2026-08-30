#!/usr/bin/env bash
# ============================================================
#  ImmortalWrt-mt798x-rebase · RAX3000M(NAND) 一键编译脚本
#
#  用法（在 WSL / Linux 下，源码根目录执行）：
#      bash build-rax3000m.sh
#
#  产物：
#      bin/targets/mediatek/filogic/*.bin      固件（刷机用）
#      bin/targets/mediatek/filogic/packages/  全部 .ipk 插件包
# ============================================================
set -e
cd "$(dirname "$0")"

echo "==> [1/6] 写入 RAX3000M 定制配置"
cp -f defconfig/mt7981-rax3000m-nand.config .config

echo "==> [2/6] 更新并安装 feeds"
./scripts/feeds update -a
./scripts/feeds install -a

echo "==> [3/6] 规范化配置（自动补全依赖）"
make defconfig

echo "==> [4/6] 校验必需插件是否全部选中"
REQUIRED_PKGS="luci-app-homeproxy luci-app-accesscontrol luci-app-samba4 hd-idle luci-app-oaf luci-app-control-speedlimit kmod-usb-storage luci-app-diskman"
MISSING=""
for p in $REQUIRED_PKGS; do
  if ! grep -q "^CONFIG_PACKAGE_${p}=y" .config; then
    MISSING="$MISSING $p"
  fi
done
if [ -n "$MISSING" ]; then
  echo "!!! 以下插件在 make defconfig 后未被选中：$MISSING"
  echo "!!! 可能原因：包名不存在 / 依赖缺失 / 内核模块与 6.12 不兼容"
  echo "!!! 请运行 make menuconfig 手工确认后继续，或按提示排查。"
  exit 1
fi
echo "所有必需插件均已启用 ✓"

echo "==> [5/6] 预下载源码包（网络差可反复重跑本命令）"
make -j$(nproc) download V=s || { echo "下载失败，请重试 make download"; exit 1; }

echo "==> [6/6] 正式编译（首次约 1~4 小时，日志写入 build.log）"
make -j$(nproc) V=s 2>&1 | tee build.log

echo ""
echo "======== 编译完成 ========"
echo "固件目录：bin/targets/mediatek/filogic/"
ls -lh bin/targets/mediatek/filogic/ 2>/dev/null || true
echo "RAX3000M(NAND) 刷机文件："
ls -lh bin/targets/mediatek/filogic/*cmcc_rax3000m* 2>/dev/null || true
