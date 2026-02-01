#!/bin/bash
#
# https://github.com/P3TERX/Actions-OpenWrt
# File name: diy-part2.sh
# Description: OpenWrt DIY script part 2 (After Update feeds)
#
# Copyright (c) 2019-2024 P3TERX <https://p3terx.com>
#
# This is free software, licensed under the MIT License.
# See /LICENSE for more information.


# 设置默认ip
# sed -i 's/192.168.1.1/192.168.81.1/g' package/base-files/files/bin/config_generate

# 移除要替换的包
rm -rf feeds/luci/themes/luci-theme-argon

# 设置默认主题
sed -i 's/luci-theme-bootstrap/luci-theme-argon/g' feeds/luci/collections/luci-light/Makefile

# x86 型号只显示 CPU 型号
sed -i 's/${g}.*/${a}${b}${c}${d}${e}${f}${hydrid}/g' package/lean/autocore/files/x86/autocore

# 修改版本为编译日期
date_version=$(date +"%y.%m.%d")
orig_version=$(cat "package/lean/default-settings/files/zzz-default-settings" | grep DISTRIB_REVISION= | awk -F "'" '{print $2}')
sed -i "s/${orig_version}/R${date_version} by LERAN/g" package/lean/default-settings/files/zzz-default-settings

# Git稀疏克隆，只克隆指定目录到本地
function git_sparse_clone() {
  branch="$1" repourl="$2" && shift 2
  git clone --depth=1 -b $branch --single-branch --filter=blob:none --sparse $repourl
  repodir=$(echo $repourl | awk -F '/' '{print $(NF)}')
  cd $repodir && git sparse-checkout set $@
  mv -f $@ ../package
  cd .. && rm -rf $repodir
}

# 添加插件
git clone https://github.com/nhhqgirl/luci-app-onliner.git package/lean/luci-app-onliner
git clone --depth=1 -b master https://github.com/jerrykuku/luci-theme-argon package/luci-theme-argon
git clone --depth=1 -b master https://github.com/vernesong/OpenClash package/luci-app-openclash


# 设置nlbwmon独立菜单
sed -i 's/services\/nlbw/nlbw/g; /path/s/admin\///g' feeds/luci/applications/luci-app-nlbwmon/root/usr/share/luci/menu.d/luci-app-nlbwmon.json
sed -i 's/services\///g' feeds/luci/applications/luci-app-nlbwmon/htdocs/luci-static/resources/view/nlbw/config.js


# DIY script part2 - 编译中配置：下载OpenClash核心/规则文件（编译阶段自动部署）

# 1. 创建OpenClash核心目录（不存在则创建，确保目录结构完整）
[ -d files/etc/openclash/core ] || mkdir -p files/etc/openclash/core

# 2. 定义各类文件下载地址（保留你原地址，适配x86_64架构）
CLASH_META_URL="https://raw.githubusercontent.com/vernesong/OpenClash/core/dev/meta/clash-linux-amd64-v1.tar.gz"
COUNTRY_URL="https://raw.githubusercontent.com/alecthw/mmdb_china_ip_list/release/lite/Country.mmdb"
GEOIP_URL="https://raw.githubusercontent.com/Loyalsoldier/v2ray-rules-dat/release/geoip.dat"
GEOSITE_URL="https://raw.githubusercontent.com/Loyalsoldier/v2ray-rules-dat/release/geosite.dat"

# 3. 下载并部署文件（静默下载，适配编译脚本无交互执行）
echo -e "\033[32m开始下载OpenClash Meta核心及规则文件...\033[0m"
wget -qO- $CLASH_META_URL | tar xOz > files/etc/openclash/core/clash_meta
wget -qO- $COUNTRY_URL > files/etc/openclash/Country.mmdb
wget -qO- $GEOIP_URL > files/etc/openclash/GeoIP.dat
wget -qO- $GEOSITE_URL > files/etc/openclash/GeoSite.dat

# 4. 赋予核心文件执行权限（确保OpenClash能正常启动核心）
chmod +x files/etc/openclash/core/clash*

# 5. 下载完成提示（方便编译时查看执行状态）
echo -e "\033[32m✅ OpenClash核心、Country.mmdb、GeoIP.dat、GeoSite.dat 下载部署完成！\033[0m"

#!/bin/bash
# DIY script part1 - 编译前配置：覆盖为自定义网络配置（eth3=WAN/eth0-2=LAN+PPPoE+VPN接口）
# 适用OpenWrt x86_64通用平台，与原有.config编译配置无冲突

# 定义OpenWrt网络配置模板的标准路径（官方/主流第三方源码通用）
NETWORK_CONF="package/base-files/files/etc/config/network"

# 覆盖写入你提供的完整network配置（保留所有原格式和参数）
cat > $NETWORK_CONF << 'EOF'
config interface 'loopback'
	option device 'lo'
	option proto 'static'
	option ipaddr '127.0.0.1'
	option netmask '255.0.0.0'

config globals 'globals'
	option packet_steering '1'

config device
	option name 'br-lan'
	option type 'bridge'
	list ports 'eth0'
	list ports 'eth1'
	list ports 'eth2'

config interface 'lan'
	option device 'br-lan'
	option proto 'static'
	option ipaddr '192.168.81.1'
	option netmask '255.255.255.0'
	option ip6assign '60'

config interface 'wan'
	option device 'eth3'
	option proto 'pppoe'
	option username '12345678@163.gd'
	option password '12345678'
	option ipv6 'auto'

config interface 'wan6'
	option proto 'dhcpv6'
	option device 'eth3'
	option reqaddress 'try'
	option reqprefix 'auto'

config interface 'VPN'
	option device 'ipsec0'
	option proto 'static'
	option ipaddr '192.168.0.1'
	option netmask '255.255.255.0'
EOF

# 赋予配置文件OpenWrt标准权限（避免权限异常导致网络服务启动失败）
chmod 644 $NETWORK_CONF

# 输出配置完成提示（方便编译时查看执行状态）
echo -e "\033[32m✅ 自定义网络配置已成功覆盖！\033[0m"
echo -e "  WAN口：eth3（PPPoE拨号） | LAN口：eth0/eth1/eth2（桥接）"
echo -e "  LAN地址：192.168.81.1 | 已添加VPN静态接口（ipsec0）"
echo -e "  配置文件路径：$NETWORK_CONF"
