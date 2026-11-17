# 开发与构建

## 技术栈

Vue 3 + TypeScript + Vite + Pinia + Tailwind CSS + ECharts。

## 本地开发

```bash
npm install
npm run dev        # http://localhost:3000/ups/
```

开发服务器把 `/cgi-bin` 代理到 `vite.config.ts` 里的 `target`（默认 `192.168.1.1`），改成你的路由器地址即可联调真实数据。真实数据接口要求 LuCI 登录会话，开发时可直接用模拟数据（`npm run dev` 下自动回退），生产构建不会。

## 前端构建

```bash
npm run build      # vue-tsc + vite build
```

产物在 `dist/`，资源路径以 `/ups/` 为基准（`vite.config.ts` 的 `base`）。

## 目录

```
openwrt/                 OpenWrt 打包文件
  Makefile               包定义（luci-app-ups-monitor）
  files/controller/ups_monitor.uc  LuCI 接口，调用 upsc 输出 JSON（需登录）
  files/view/dashboard.js          LuCI 页面，内嵌 /ups/ 面板
  files/luci-app-ups-monitor.json  LuCI 菜单/路由定义
src/                     前端源码
public/                  静态资源
```

## 本地打包

需要 OpenWrt/ImmortalWrt SDK：

```bash
npm run build
SDK=immortalwrt-sdk-x86-64_gcc-14.4.0_musl.Linux-x86_64
tar --zstd -xf "$SDK.tar.zst"
mkdir -p "${SDK#immortalwrt-sdk-}"/package/luci-app-ups-monitor   # 目录名任意
cp -r openwrt/. "${SDK#immortalwrt-sdk-}"/package/luci-app-ups-monitor/
cp -r dist "${SDK#immortalwrt-sdk-}"/package/luci-app-ups-monitor/
cd "${SDK#immortalwrt-sdk-}"
make defconfig
make package/luci-app-ups-monitor/compile V=s -j$(nproc)
```

产物在 `bin/packages/*/base/`（apk）或 `bin/packages/*/base/`（ipk）。

## CI 与发布

`.github/workflows/build.yml` 在每次 push 到 `master` 时构建前端、打包 apk 与 ipk，并更新 `latest` Release；推送 `v*` 标签时生成正式版本 Release。

- apk 使用 ImmortalWrt SNAPSHOT SDK（主路由为 SNAPSHOT + apk）
- ipk 使用 ImmortalWrt 24.10 SDK
- 包是纯脚本/静态资源（`PKGARCH:=all`），与目标 CPU 架构无关

## 版本号

改 `openwrt/Makefile` 里的 `PKG_VERSION` / `PKG_RELEASE`，然后打同名 tag（如 `v1.0.1`）。
