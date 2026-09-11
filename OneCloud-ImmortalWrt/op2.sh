#!/bin/bash
# ============================================================
# OneCloud ImmortalWrt DIY 脚本 Part 2 (Install feeds 之后)
# 作用：修改默认 IP、密码、服务精简、主题、ttyd、rpcd 等
# ============================================================

# ---------- ttyd 自动登录 root（网页终端免输密码） ----------
sed -i 's|/bin/login|/bin/login -f root|g' feeds/packages/utils/ttyd/files/ttyd.config 2>/dev/null

# ---------- rpcd 超时延长（30s→60s，防止 LuCI 操作超时） ----------
sed -i 's/option timeout 30/option timeout 60/g' package/system/rpcd/files/rpcd.config 2>/dev/null

# ---------- 默认 IP 改为旁路由模式 ----------
# 旁路由：192.168.2.2，网关指向主路由 192.168.2.1
sed -i 's/192.168.1.1/192.168.2.2/g' package/base-files/files/bin/config_generate

# ---------- 默认密码 ----------
# 无密码登录
sed -i 's/root:::0:99999:7:::/root::0:0:99999:7:::/g' package/base-files/files/etc/shadow

# ---------- 主机名 ----------
sed -i 's/hostname='\''ImmortalWrt'\''/hostname='\''OneCloud'\''/g' package/base-files/files/bin/config_generate

# ---------- 时区 ----------
sed -i "s/timezone='UTC'/timezone='CST-8'/g" package/base-files/files/bin/config_generate
sed -i "/timezone='CST-8'/a set system.@system[-1].zonename='Asia/Shanghai'" package/base-files/files/bin/config_generate 2>/dev/null

# ---------- 禁用旁路由不需要的服务 ----------
mkdir -p files/etc/uci-defaults
cat > files/etc/uci-defaults/99-onecloud-optimize << 'UCIEOF'
#!/bin/sh
# 旁路由服务精简：只保留网络转发、代理、管理必需的服务
for svc in \
  wpad hostapd odhcpd \
  radius hd-idle gpio_switch \
  openlist2 momo \
  upnpd \
  ddns; do
  /etc/init.d/$svc disable 2>/dev/null
  /etc/init.d/$svc stop 2>/dev/null
done
# 启用 irqbalance（中断分散）
/etc/init.d/irqbalance enable 2>/dev/null
/etc/init.d/irqbalance start 2>/dev/null
# 关闭 DNS 转发（旁路由不做 DNS 服务器，由主路由或 mihomo 处理）
uci set dhcp.@dnsmasq[0].port='0' 2>/dev/null
# DHCP 关闭（旁路由由主路由分配 IP）
uci set dhcp.lan.ignore='1'
uci commit dhcp
# 网关和 DNS 指向主路由
uci set network.lan.gateway='192.168.2.1'
uci set network.lan.dns='192.168.2.1'
uci commit network
# 防火墙：关闭 syn_flood（旁路由在 NAT 后，不需要）
uci set firewall.@defaults[0].syn_flood='0' 2>/dev/null
uci commit firewall
exit 0
UCIEOF
chmod +x files/etc/uci-defaults/99-onecloud-optimize

mkdir -p files/etc
cat > files/etc/banner << 'BANNER'
  _______                     ________        __
 |       |.-----.-----.-----.|  |  |  |.----.|  |_
 |   -   ||  _  |  -__|     ||  |  |  ||   _||   _|
 |_______||   __|_____|__|__||________||__|  |____|
          |__|
 -----------------------------------------------------
   OneCloud ImmortalWrt
 -----------------------------------------------------

BANNER

# ---------- 网卡 Ring Buffer / 中断亲和性 / RPS-XPS 优化 ----------
# 注意：Amlogic stmmac 驱动不支持调到 1024，保持默认 512
cat > files/etc/uci-defaults/98-network-optimize << 'NETEOF'
#!/bin/sh
# === IRQ 亲和性：动态查找 eth0 中断并绑定到 CPU1 ===
# CPU0: 系统定时器等  CPU1: 网卡  CPU2/3: 应用/代理
eth0_irq=$(grep eth0 /proc/interrupts | head -1 | awk -F: '{print $1}' | tr -d ' ')
if [ -n "$eth0_irq" ]; then
  echo 2 > /proc/irq/$eth0_irq/smp_affinity 2>/dev/null
fi

# === RPS/XPS：4核网络负载均衡 ===
for iface in eth0 br-lan; do
  for q in /sys/class/net/$iface/queues/rx-*; do
    [ -w "$q/rps_cpus" ] && echo f > "$q/rps_cpus" 2>/dev/null
    [ -w "$q/rps_flow_cnt" ] && echo 4096 > "$q/rps_flow_cnt" 2>/dev/null
  done
  for q in /sys/class/net/$iface/queues/tx-*; do
    [ -w "$q/xps_cpus" ] && echo f > "$q/xps_cpus" 2>/dev/null
  done
done
exit 0
NETEOF
chmod +x files/etc/uci-defaults/98-network-optimize

echo "op2.sh 执行完成"
