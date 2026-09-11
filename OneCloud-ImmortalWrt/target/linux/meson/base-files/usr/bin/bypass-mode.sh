#!/bin/sh
# OneCloud bypass router mode setup script
# Usage: bypass-mode.sh <static_ip> <gateway_ip> [netmask]
# Example: bypass-mode.sh 192.168.1.2 192.168.1.1

set -e

IP="${1:-192.168.2.2}"
GATEWAY="${2:-192.168.2.1}"
NETMASK="${3:-255.255.255.0}"
PREFIX=$(echo "$NETMASK" | awk -F. '{
  n=0;
  for(i=1;i<=4;i++){
    x=$i;
    while(x>0){ n++; x=int(x/2) }
  }
  print n
}')

echo "=== OneCloud Bypass Router Mode ==="
echo "IP:      $IP/$PREFIX"
echo "Gateway: $GATEWAY"
echo ""

# 1. Configure network - static IP on LAN (CIDR format, keep IPv6)
echo "[1/5] Configuring network interface..."
uci set network.lan.proto='static'
uci delete network.lan.ipaddr 2>/dev/null || true
uci add_list network.lan.ipaddr="${IP}/${PREFIX}"
uci set network.lan.gateway="$GATEWAY"
uci delete network.lan.dns 2>/dev/null || true
uci add_list network.lan.dns="$GATEWAY"
uci set network.lan.ip6assign='60'
uci set network.lan.multipath='off'
uci commit network

# 2. Disable DHCP server on LAN (bypass router mode)
# ignore=1 disables DHCPv4; dhcpv6/ra disabled to avoid conflict with main router
echo "[2/5] Disabling DHCP server..."
uci set dhcp.lan.ignore='1'
uci set dhcp.lan.dhcpv6='disabled'
uci set dhcp.lan.ra='disabled'
uci commit dhcp

# 3. Configure firewall - bypass mode (single arm)
echo "[3/5] Configuring firewall (bypass mode)..."
uci set firewall.@defaults[0].forward='ACCEPT'
uci set firewall.@defaults[0].syn_flood='1'
uci set firewall.@defaults[0].flow_offloading='1'
uci set firewall.@defaults[0].flow_offloading_hw='0'
uci set firewall.@defaults[0].fullcone='1'
uci set firewall.@defaults[0].fullcone6='0'
uci delete firewall.wan 2>/dev/null || true
uci delete firewall.@forwarding[0] 2>/dev/null || true
uci commit firewall

# 4. Ensure sysctl optimizations are applied (use existing 99-bypass.conf if available)
echo "[4/5] Applying sysctl optimizations..."
if [ ! -f /etc/sysctl.d/99-bypass.conf ]; then
    # Create basic sysctl config if not exists (full version comes from firmware)
    cat > /etc/sysctl.d/99-bypass.conf << 'SYSCTL'
# OneCloud bypass router sysctl optimizations
net.ipv4.ip_forward=1
net.ipv4.conf.all.forwarding=1
net.ipv4.conf.default.forwarding=1
net.ipv6.conf.all.forwarding=1
net.ipv4.conf.all.arp_ignore=1
net.ipv4.conf.all.arp_announce=2
net.core.default_qdisc=fq
net.ipv4.tcp_congestion_control=bbr
net.core.rmem_max=33554432
net.core.wmem_max=33554432
net.ipv4.tcp_rmem=4096 131072 33554432
net.ipv4.tcp_wmem=4096 65536 33554432
net.ipv4.tcp_fastopen=3
net.netfilter.nf_conntrack_max=262144
vm.swappiness=10
vm.dirty_ratio=10
kernel.panic=3
kernel.panic_on_oops=1
SYSCTL
fi
sysctl -p /etc/sysctl.d/99-bypass.conf 2>/dev/null || true

# 5. Restart services
echo "[5/5] Restarting services..."
/etc/init.d/dnsmasq restart 2>/dev/null || true
/etc/init.d/odhcpd restart 2>/dev/null || true
/etc/init.d/firewall restart 2>/dev/null || true

echo ""
echo "=== Bypass router mode configured ==="
echo "Device IP:  $IP/$PREFIX"
echo "Gateway:    $GATEWAY"
echo ""
echo "Next steps:"
echo "  1. Set your client devices' gateway to $IP"
echo "  2. Set DNS to $IP (or your preferred DNS)"
echo "  3. Reboot device: reboot"
echo ""
echo "To restore router mode: firstboot && reboot"
