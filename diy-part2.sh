#!/bin/bash
# DIY脚本
# https://github.com/P3TERX/Actions-OpenWrt
# 文件名: diy-part2.sh
# 功能说明: OpenWrt DIY脚本第2部分（更新feeds之后）
# 版权: (c) 2019-2024 P3TERX
# 基于 MIT 开源协议，详见 /LICENSE

# 修改默认IP地址
#sed -i 's/192.168.1.1/192.168.100.1/g' package/base-files/files/bin/config_generate


# 修改默认主题为 argon（路径不存在时跳过，不中断编译）
sed -i 's/luci-theme-bootstrap/luci-theme-argon/g' feeds/luci/collections/luci/Makefile 2>/dev/null || true

# 启用 IPv4 策略路由（直接写入内核 platform config，绕过 make defconfig 的依赖检查）
# CONFIG_KERNEL_IP_ADVANCED_ROUTER 在 OpenWrt Config.in 中无对应 wrapper，必须用此方式
#for cfg in target/linux/msm89xx/config-*; do
#  grep -q 'CONFIG_IP_ADVANCED_ROUTER' "$cfg" || echo 'CONFIG_IP_ADVANCED_ROUTER=y' >> "$cfg"
#  grep -q 'CONFIG_IP_MULTIPLE_TABLES' "$cfg" || echo 'CONFIG_IP_MULTIPLE_TABLES=y' >> "$cfg"
#done


# 临时添加的插件
# git clone https://github.com/lkiuyu/luci-app-cpu-perf package/luci-app-cpu-perf
# git clone https://github.com/lkiuyu/luci-app-cpu-status package/luci-app-cpu-status
# git clone https://github.com/gSpotx2f/luci-app-cpu-status-mini package/luci-app-cpu-status-mini
# git clone https://github.com/lkiuyu/luci-app-temp-status package/luci-app-temp-status
# git clone https://github.com/lkiuyu/DbusSmsForwardCPlus package/DbusSmsForwardCPlus

# 修复 GCC 15.2.0 + musl 1.2.5 的 __REDIR implicit-int 错误
# 该错误会导致 toolchain/gcc/final 阶段编译 libgcc 失败
echo 'CONFIG_EXTRA_CFLAGS="-Wno-error=implicit-int"' >> .config
echo 'CONFIG_EXTRA_HOST_CFLAGS="-Wno-error=implicit-int"' >> .config
# Extend to toolchain build
echo 'EXTRA_CFLAGS+=-Wno-error=implicit-int -Wno-error=declaration-missing-parameter-type' >> .config
echo 'EXTRA_HOST_CFLAGS+=-Wno-error=implicit-int -Wno-error=declaration-missing-parameter-type' >> .config


# 修复 Qt5 recursive dependency (qt5base-gui <-> OPENGLES2 choice)
# 在 feeds 更新后立即卸载 video feed 中的 Qt5 包，避免 defconfig 时触发递归
if [ -d feeds/video/frameworks/qt5 ]; then
  echo '>>> 移除 feeds/video 中全部 Qt5 包，避免 recursive dependency'
  rm -rf feeds/video/frameworks/qt5 || true
fi
# Fix self-dependency in package Makefiles
find feeds/ -name "Makefile" -type f | while read makefile; do
    if grep -q "DEPENDS:=+\$(PKG_NAME)" "$makefile" || grep -q "DEPENDS:=+${PKG_NAME}" "$makefile"; then
        echo ">>> Fixing self-dependency in $makefile"
        sed -i '/DEPENDS:=+\$(PKG_NAME)/d' "$makefile"
        sed -i '/DEPENDS:=+${PKG_NAME}/d' "$makefile"
    fi
done
# 同时清理 .config 中可能残留的 Qt5 选项
if [ -f .config ]; then
  sed -i '/PACKAGE_qt5/d' .config 2>/dev/null || true
  sed -i '/PACKAGE_qt5quick/d' .config 2>/dev/null || true
  sed -i '/PACKAGE_qt5script/d' .config 2>/dev/null || true
  sed -i '/PACKAGE_qt5virtualkeyboard/d' .config 2>/dev/null || true
  sed -i '/PACKAGE_qt5graphicaleffects/d' .config 2>/dev/null || true
  sed -i '/PACKAGE_qt5tools/d' .config 2>/dev/null || true
  sed -i '/PACKAGE_qt5translations/d' .config 2>/dev/null || true
fi

# Fix recursive dependency in luci-app-clashoo and luci-app-fchomo
for pkg in luci-app-clashoo luci-app-fchomo; do
    pkg_dir="package/feeds/smpackage/$pkg"
    if [ -d "$pkg_dir" ]; then
        echo ">>> Removing $pkg to avoid recursive dependency"
        rm -rf "$pkg_dir"
    fi
done
# Remove smpackage feed entirely to avoid recursive dependency issues
if [ -d package/feeds/smpackage ]; then
  echo ">>> Removing smpackage feed entirely"
  rm -rf package/feeds/smpackage
fi
# Resolve package conflicts for x86/64 builds
if [[ "${PROFILE}" == "hyperv" ]]; then
    sed -i '/CONFIG_PACKAGE_kmod-nf-ipt/d' .config
    sed -i '/CONFIG_PACKAGE_kmod-nf-ipt6/d' .config
    sed -i '/CONFIG_PACKAGE_kmod-ipt-core/d' .config
    sed -i '/CONFIG_PACKAGE_kmod-nft-compat/d' .config
    sed -i '/CONFIG_PACKAGE_luci-app-mosdns/d' .config
    sed -i '/CONFIG_PACKAGE_luci-i18n-mosdns-zh-cn/d' .config
    sed -i '/CONFIG_PACKAGE_luci-app-tailscale/d' .config
    sed -i '/CONFIG_PACKAGE_luci-i18n-tailscale-zh-cn/d' .config
    sed -i '/CONFIG_PACKAGE_luci-i18n-tailscale-zh-tw/d' .config
fi
