#!/bin/bash
#
# https://github.com/P3TERX/Actions-OpenWrt
# File name: diy-part1.sh
# Description: OpenWrt DIY script part 1 (Before Update feeds)
#
# Copyright (c) 2019-2024 P3TERX <https://p3terx.com>
#
# This is free software, licensed under the MIT License.
# See /LICENSE for more information.
#

# Uncomment a feed source
#sed -i 's/^#\(.*helloworld\)/\1/' feeds.conf.default

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
	option username '123456789'
	option password '123456789'
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
