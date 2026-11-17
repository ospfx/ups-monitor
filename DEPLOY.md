# 部署指南

## 项目说明

这是一个现代化的 UPS 监控前端界面，用于替代 luci-app-nut 的传统界面。

**设计思路：前后端分离**
- **前端**：Vue 3 + TypeScript + Tailwind CSS（本项目）
- **后端**：复用 OpenWrt 路由器现有的 NUT 服务（upsd）

## 预构建包下载

从 [GitHub Releases](https://github.com/ospfx/ups-monitor/releases) 下载预构建的 IPK 包：

```bash
# 下载 IPK
wget https://github.com/ospfx/ups-monitor/releases/latest/download/ups-monitor_1.0.0-1_all.ipk

# 安装到 OpenWrt
opkg install ups-monitor_1.0.0-1_all.ipk

# 访问
# http://your-router-ip/ups/
```

## 构建流程

### 1. 在有 Node.js 的环境中构建

如果你的 Windows 没有安装 Node.js，需要：

#### 方案 A：安装 Node.js（推荐）

```bash
# 下载并安装 Node.js LTS 版本
# https://nodejs.org/

# 安装完成后，在普通 CMD 或 PowerShell 中执行：
cd D:\zcodeworkspace\ups-monitor
npm install
npm run build
```

#### 方案 B：使用 Docker 构建（无需安装 Node.js）

```bash
# 在项目目录创建临时构建容器
docker run --rm -v ${PWD}:/app -w /app node:20-alpine sh -c "npm install && npm run build"
```

### 2. 构建产物

构建成功后，`dist/` 目录包含：
```
dist/
├── index.html           # 入口页面
├── assets/
│   ├── index-xxx.js    # 主应用代码
│   ├── index-xxx.css   # 样式文件
│   └── ...             # 其他资源
```

## 部署到 OpenWrt 路由器

### 准备：确保 NUT 已安装

```bash
ssh root@your-router-ip

# 检查 NUT 是否安装
opkg list-installed | grep nut

# 如果未安装：
opkg update
opkg install nut nut-upsc nut-upsmon
```

### 方法 1：使用 IPK 包（推荐）

```bash
# 从 Releases 下载或自己构建
wget https://github.com/ospfx/ups-monitor/releases/latest/download/ups-monitor_1.0.0-1_all.ipk

# 安装
opkg install ups-monitor_1.0.0-1_all.ipk
```

### 方法 2：手动部署

将构建文件直接部署到 `/www/ups/` 目录：

```bash
# 打包构建产物
tar czf ups-monitor.tar.gz -C dist .

# 上传到路由器
scp ups-monitor.tar.gz root@your-router-ip:/tmp/

# SSH 到路由器解压
ssh root@your-router-ip
mkdir -p /www/ups
tar xzf /tmp/ups-monitor.tar.gz -C /www/ups/
```

访问地址：`http://your-router-ip/ups/`

### 方法 3：集成到 LuCI 菜单

如果想在 OpenWrt 的 LuCI 界面中添加菜单项：

1. 创建 LuCI 控制器文件：

```bash
ssh root@your-router-ip

cat > /usr/lib/lua/luci/controller/upsmonitor.lua << 'EOF'
module("luci.controller.upsmonitor", package.seeall)

function index()
    entry({"admin", "services", "upsmonitor"}, 
          call("action_upsmonitor"), 
          _("UPS Monitor"), 80)
end

function action_upsmonitor()
    luci.http.redirect("/ups/")
end
EOF
```

2. 刷新 LuCI 缓存：
```bash
rm /tmp/luci-indexcache
/etc/init.d/uhttpd restart
```

现在可以在 LuCI 的"服务"菜单中看到"UPS Monitor"。

## 后端接口配置

### 使用 IPK 安装（推荐）

IPK 包已包含 CGI 接口 `/www/cgi-bin/ups-api.sh`，安装后自动配置。

### 手动配置 CGI

如果手动部署，需创建 `/www/cgi-bin/ups-api.sh`（内容见 `openwrt/files/ups-api.sh`）：

```bash
# 复制 CGI 脚本
scp openwrt/files/ups-api.sh root@your-router-ip:/www/cgi-bin/

# 设置执行权限
ssh root@your-router-ip "chmod +x /www/cgi-bin/ups-api.sh"
```

然后修改前端 API 调用：编辑 `src/api/ups.ts`，将 API 端点改为：
```typescript
const response = await api.get(`/cgi-bin/ups-api.sh?${upsName}`)
```

### 选项 3：使用 NUT 自带的网络协议

NUT 提供原生网络协议（端口 3493），但需要在前端添加 WebSocket 网关或使用服务器端代理。

## 验证部署

1. 访问 `http://10.0.15.1/ups/`
2. 应该看到现代化的 UPS 监控界面
3. 如果数据显示为模拟数据，说明后端接口需要配置

## 开发模式

如果需要本地开发调试：

```bash
# 1. 确保 easytier 已连接到路由器网络
cd /d/zcodeworkspace/easytier
./start-easytier.sh noadmin

# 2. 在另一个终端启动开发服务器
cd /d/zcodeworkspace/ups-monitor
npm run dev

# 3. 访问 http://localhost:3000
# Vite 会自动代理 /api 请求到路由器
```

## 故障排查

### 1. 页面空白

检查浏览器控制台，可能是资源路径问题。修改 `vite.config.ts`：
```typescript
base: '/ups/'  // 确保与部署路径一致
```

### 2. 数据不更新

- 检查 NUT 服务是否运行：`/etc/init.d/nut-server status`
- 测试 upsc 命令：`upsc ups`
- 检查 CGI 脚本权限：`chmod +x /www/cgi-bin/ups-api.sh`

### 3. CORS 错误

在 CGI 脚本中添加 CORS 头（已包含在示例中）：
```bash
echo "Access-Control-Allow-Origin: *"
```

## 卸载

```bash
ssh root@10.0.15.1
rm -rf /www/ups
rm -f /www/cgi-bin/ups-api.sh
rm -f /usr/lib/lua/luci/controller/upsmonitor.lua
rm /tmp/luci-indexcache
```

## 技术支持

- 查看浏览器控制台获取错误信息
- 检查路由器系统日志：`logread | grep ups`
- NUT 文档：https://networkupstools.org/docs/user-manual.chunked/index.html
