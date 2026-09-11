# OneCloud ImmortalWrt 优化构建


基于 [ImmortalWrt](https://github.com/immortalwrt/immortalwrt) 源码，针对玩客云（Amlogic S805 / Cortex-A5 四核 / 1GB RAM / 8GB eMMC）的旁路由场景优化。

## 相比原版 OpenWrt 的优化点

### 内核与网络栈
| 优化项 | 原版 OpenWrt | ImmortalWrt 优化版 |
|--------|-------------|-------------------|
| TCP 拥塞控制 | cubic | **BBR**（代理国际链路吞吐提升明显） |
| 队列调度 | fq_codel | **fq**（配合 BBR 最佳） |
| 网络缓冲区 | 176KB | **16MB**（千兆高并发防丢包） |
| netdev backlog | 1000 | **5000** |
| netdev budget | 默认 | **600** |
| MTU 探测 | 关闭 | **开启**（代理场景防网站打不开） |
| TCP Fast Open | 1 | **3** |
| TCP 连接优化 | 默认 | **fin_timeout=15s / keepalive 优化 / syn_backlog=2048** |
| conntrack 超时 | 默认 | **established=1h / time_wait=60s / udp=30s** |
| Full Cone NAT | 无 | **内置**（P2P/游戏优化） |
| Shortcut-FE | 无 | **内置**（软件流加速） |
| 连接跟踪表 | 自动 | **131072** |
| RPS/XPS 多核 | 关闭 | **开启**（4核网络负载均衡，消除单核瓶颈） |
| BBR 模块加载 | 手动 | **自动**（开机 modules.d 自动加载 tcp_bbr + sch_fq） |

### 系统优化
| 优化项 | 说明 |
|--------|------|
| **irqbalance** | 自动分散网卡中断到多核，避免 CPU0 瓶颈 |
| **中断亲和性** | eth0 中断绑定 CPU1，CPU0 留给系统定时器 |
| **CPU 调频** | performance 模式（已默认） |
| **编译优化** | `-O2 -march=cortex-a5 -mtune=cortex-a5 -mfpu=neon-vfpv4` |
| **服务精简** | 禁用 wpad/odhcpd 等旁路由不需要的服务（samba4 已保留用于网络共享） |

### 旁路由预设
- 默认 IP：`192.168.2.2`
- 默认网关/DNS：`192.168.2.1`（主路由）
- DHCP：已关闭（由主路由分配）
- 默认密码：`turbo`
- 主机名：`OneCloud`
- 时区：Asia/Shanghai

### 预装软件
- **mihomo-meta** + **luci-app-nikki**（透明代理）
- **samba4-server** + **luci-app-samba4**（网络共享盘）
- **luci-app-turboacc**（shortcut-fe + fullconenat 开关）
- **luci-app-ttyd**（网页终端）
- **luci-app-diskman**（磁盘管理）
- **Argon 主题**
- htop / ethtool / iperf3 / curl 等工具

## 文件说明

```
OneCloud-ImmortalWrt/
├── .config          # 编译配置（minimal，make defconfig 自动补全）
├── op1.sh           # DIY 脚本1（feeds 更新前：添加 feed、注入 sysctl）
└── op2.sh           # DIY 脚本2（feeds 安装后：改 IP、密码、服务精简）

.github/workflows/
└── build-onecloud-immortalwrt.yml   # GitHub Actions 自动构建
```

## 使用方法

### 方式一：GitHub Actions 自动构建（推荐）

1. Fork 本仓库
2. 进入 Actions → 选择 "Build OneCloud ImmortalWrt" → Run workflow
3. 等待约 2-3 小时构建完成
4. 在 Releases 或 Artifacts 下载固件

### 方式二：本地编译

```bash
# 1. 克隆 ImmortalWrt 源码
git clone https://github.com/immortalwrt/immortalwrt -b openwrt-24.10 --depth 1
cd immortalwrt

# 2. 复制配置和脚本
cp /path/to/OneCloud-ImmortalWrt/.config .config
cp /path/to/OneCloud-ImmortalWrt/op1.sh .
cp /path/to/OneCloud-ImmortalWrt/op2.sh .

# 3. 执行 DIY
chmod +x op1.sh op2.sh
./op1.sh

# 4. 更新并安装 feeds
./scripts/feeds update -a
./scripts/feeds install -a

# 5. 执行 op2
./op2.sh

# 6. 编译
make defconfig
make -j$(nproc)
```

## 刷机

- 文件名含 `burn` 的为线刷固件，使用 Amlogic USB Burning Tool 烧录
- 红灯闪 = 启动中，蓝灯常亮 = 启动完成
- 首次启动约 2-5 分钟

## 注意事项

1. **网卡 Ring Buffer**：Amlogic stmmac 驱动不支持将 RX/TX 调到 1024（会导致网卡挂死），保持默认 512
2. **eMMC 频率**：设备树默认 HS200 200MHz，如遇 eMMC 不稳定可降为 100MHz
3. **分支**：使用 `openwrt-24.10` 分支（25.12 已移除 32位 meson8b/S805 支持）
4. **网络共享**：建议外接 USB 硬盘，eMMC 8GB 系统占后约 6GB 可用
