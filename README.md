# UPS Monitor

现代化的 UPS (不间断电源) 监控界面，基于 Vue 3 + TypeScript 构建，为 OpenWrt 路由器提供美观的 NUT (Network UPS Tools) 管理前端。

## ✨ 特性

- 🎨 **现代化 UI** - 基于 Tailwind CSS，深色主题设计
- 📊 **实时监控** - ECharts 图表展示电池、负载、电压历史数据
- 🔄 **自动刷新** - 可配置的自动数据更新
- 📱 **响应式设计** - 完美适配桌面和移动设备
- ⚡ **轻量快速** - Vite 构建，静态部署

## 🖼️ 界面预览

主要功能模块：
- **状态概览** - UPS 在线状态、设备信息
- **电池监控** - 电量、剩余时间、电压、温度
- **电源信息** - 负载百分比、输入输出电压、频率、功率
- **历史图表** - 实时数据趋势可视化

## 🚀 快速开始

### 开发环境

```bash
# 安装依赖
npm install

# 启动开发服务器
npm run dev

# 访问 http://localhost:3000
```

开发模式下会使用模拟数据，方便调试 UI。

### 生产构建

```bash
# 构建静态文件
npm run build

# 预览构建结果
npm run preview
```

构建产物位于 `dist/` 目录。

## 📦 部署到 OpenWrt

### 方式一：直接部署静态文件

1. 构建项目：
```bash
npm run build
```

2. 将 `dist/` 目录内容上传到路由器：
```bash
scp -r dist/* root@10.0.15.1:/www/ups/
```

3. 访问：`http://your-router-ip/ups/`

### 方式二：配置 LuCI 集成

创建 LuCI 菜单配置 `/usr/lib/lua/luci/controller/ups.lua`：

```lua
module("luci.controller.ups", package.seeall)

function index()
    entry({"admin", "services", "ups"}, alias("admin", "services", "ups", "monitor"), _("UPS Monitor"), 60)
    entry({"admin", "services", "ups", "monitor"}, template("ups/index"), _("Dashboard"), 1)
end
```

将构建文件复制到：
- HTML/JS/CSS → `/www/luci-static/ups/`
- 模板文件 → `/usr/lib/lua/luci/view/ups/`

## 🔧 配置后端接口

编辑 `src/api/ups.ts` 中的 API 调用，适配你的 NUT 服务器：

### 选项 1: 使用 NUT CGI（默认）

OpenWrt 的 luci-app-nut 已包含 CGI 接口，无需额外配置。

### 选项 2: 创建自定义 API

在路由器上创建简单的 Shell CGI：

```bash
#!/bin/sh
echo "Content-Type: application/json"
echo ""

upsc ups | awk '
BEGIN { print "{" }
/battery.charge:/ { printf "\"battery.charge\": %s,", $2 }
/battery.runtime:/ { printf "\"battery.runtime\": %s,", $2 }
/input.voltage:/ { printf "\"input.voltage\": %s,", $2 }
/ups.load:/ { printf "\"ups.load\": %s", $2 }
END { print "}" }
'
```

保存为 `/www/cgi-bin/ups-status.sh`，设置执行权限。

### 选项 3: 使用 uhttpd-mod-lua

创建 Lua API 提供 JSON 接口，参考 luci-app-nut 的实现。

## 🛠️ 技术栈

- **Vue 3** - 渐进式 JavaScript 框架
- **TypeScript** - 类型安全
- **Vite** - 下一代前端构建工具
- **Pinia** - Vue 状态管理
- **Tailwind CSS** - 实用优先的 CSS 框架
- **ECharts** - 数据可视化图表库
- **Axios** - HTTP 客户端

## 📝 开发说明

### 目录结构

```
src/
├── api/          # API 接口封装
├── components/   # Vue 组件
├── router/       # 路由配置
├── stores/       # Pinia 状态管理
├── types/        # TypeScript 类型定义
├── views/        # 页面视图
├── App.vue       # 根组件
├── main.ts       # 入口文件
└── style.css     # 全局样式
```

### 添加新功能

1. **新增数据字段** - 修改 `src/types/ups.ts`
2. **API 调用** - 更新 `src/api/ups.ts`
3. **状态管理** - 扩展 `src/stores/ups.ts`
4. **UI 组件** - 在 `src/components/` 创建新组件

### 对接真实 NUT 服务器

修改 `vite.config.ts` 中的代理配置：

```typescript
proxy: {
  '/api': {
    target: 'http://10.0.15.1',  // 你的路由器 IP
    changeOrigin: true,
    rewrite: (path) => path.replace(/^\/api/, '')
  }
}
```

## 🔍 与 luci-app-nut 对比

| 特性 | luci-app-nut | UPS Monitor |
|------|--------------|-------------|
| UI 框架 | LuCI (Lua) | Vue 3 + TypeScript |
| 设计风格 | 传统表单 | 现代卡片式 |
| 数据可视化 | 无 | ECharts 图表 |
| 响应式 | 基础 | 完全响应式 |
| 实时更新 | 手动刷新 | 自动轮询 |
| 扩展性 | 受限于 LuCI | 完全可定制 |

## 📄 许可证

MIT License

## 🤝 贡献

欢迎提交 Issue 和 Pull Request！

## 🔗 相关链接

- [Network UPS Tools](https://networkupstools.org/)
- [OpenWrt](https://openwrt.org/)
- [luci-app-nut](https://github.com/openwrt/luci/tree/master/applications/luci-app-nut)
