# UPS Monitor

现代、响应式的 UPS（不间断电源）监控面板，为 OpenWrt / ImmortalWrt 路由器提供 NUT（Network UPS Tools）实时状态展示。

数据来自路由器本机的 NUT 服务（`upsc`），前端使用 Vue 3 + TypeScript + ECharts 构建，安装后可从 LuCI 的「服务 → UPS Monitor」进入，也可以直接访问 `http://<路由器IP>/ups/`。

## 功能

- UPS 在线状态、电池电量、剩余时间、电池电压与温度
- 输入/输出电压、频率、负载百分比与功率
- 最近 60 个采样点的趋势图（电量、负载、输入电压）
- 每 5 秒自动刷新，可手动开关
- 适配桌面和手机浏览器
- 支持多台 UPS（`/ups/?ups=<名称>`）

## 安装

### 前置条件

路由器上需要有一个可用的 NUT 服务端，并且 `upsc <名称>` 能读到数据：

```sh
apk add nut-server nut-upsc nut-driver-usbhid-ups   # 24.10 及更早用 opkg install
upsc ups
```

`upsc` 没有输出时，先按 [NUT 文档](https://networkupstools.org/docs/user-manual.chunked/index.html) 或 `luci-app-nut` 的界面配置 `/etc/config/nut_server`、`/etc/nut/ups.conf`。

### 从 Release 安装

在 [Releases](https://github.com/ospfx/ups-monitor/releases) 下载与系统匹配的包：

| 系统 | 包格式 | 安装命令 |
|------|--------|----------|
| ImmortalWrt / OpenWrt SNAPSHOT（apk） | `.apk` | `apk add --allow-untrusted ./luci-app-ups-monitor-*.apk` |
| OpenWrt / ImmortalWrt 24.10 及更早（opkg） | `.ipk` | `opkg install ./luci-app-ups-monitor_*.ipk` |

包管理器会从软件源自动补齐依赖：

- `luci-base`：LuCI 本体（提供菜单和页面框架）
- `nut-upsc`：提供 `upsc` 命令（同时会带上 `nut`、`nut-common`）

离线安装时需要先手动安装这两个依赖。

### 访问

- LuCI 网页 →「服务」→「UPS Monitor」
- 或直接打开 `http://<路由器IP>/ups/`
- 多台 UPS：`http://<路由器IP>/ups/?ups=ups2`

## 配置

本包不写任何配置文件，只读取 NUT 的实时变量。常用变量：

| 变量 | 用途 | 缺失时显示 |
|------|------|-----------|
| `battery.charge` | 电池电量 | 0% |
| `battery.runtime` | 剩余时间（秒） | 0 分钟 |
| `ups.load` | 负载百分比 | 0% |
| `input.voltage` / `output.voltage` | 输入/输出电压 | 0 V |
| `ups.status` | `OL` / `OB` / `OFF` | 未知 |
| `ups.realpower` | 实际功率（W） | 由额定功率 × 负载估算 |

不同品牌 UPS 暴露的变量不同，缺失的项显示 0 属于正常现象。

## 卸载

```sh
apk del luci-app-ups-monitor     # apk 系统
opkg remove luci-app-ups-monitor # opkg 系统
```

## 常见问题

**页面能打开，但数值全是 0 或「未知」**

说明 CGI 正常工作但 NUT 没有数据。SSH 登录路由器执行 `upsc ups`，确认输出里有 `battery.charge`、`ups.status` 等变量；没有就先修好 NUT 服务。

**页面提示「无法连接 UPS 服务」**

检查 CGI 是否可访问：

```sh
curl 'http://127.0.0.1/cgi-bin/ups-api.sh?ups=ups'
```

应返回一段 JSON。404 时确认 uhttpd 的 `cgi_prefix` 为 `/cgi-bin`（默认值）。使用 nginx 等其它 Web 服务器时，需要自行配置 CGI。

**趋势图一直为空**

趋势数据只保存在浏览器内存中，页面打开后每 5 秒采一个点，刷新页面会清空。

**安装时提示依赖缺失**

先 `apk update` / `opkg update`，或手动安装 `luci-base` 和 `nut-upsc`。

## 安全说明

面板和 CGI 默认只靠路由器防火墙限制在局域网内，未做登录校验，请勿把 `/ups/` 或 `/cgi-bin/ups-api.sh` 暴露到公网。

## 开发

见 [DEVELOPMENT.md](DEVELOPMENT.md)。

## 许可证

[MIT](LICENSE)
