#!/usr/bin/env bash
# 推送代码到 GitHub 的脚本
# 在有网络连接的环境中运行

set -euo pipefail

cd "$(dirname "$0")"

echo "正在推送代码到 GitHub..."
echo ""

# 检查是否已提交
if ! git log -1 >/dev/null 2>&1; then
    echo "[错误] 未找到提交，请先运行:"
    echo "  git add -A"
    echo "  git commit -m 'Initial commit'"
    exit 1
fi

# 推送到 GitHub
if git push -u origin master; then
    echo ""
    echo "✓ 代码推送成功！"
    echo ""
    echo "GitHub Actions 将自动构建："
    echo "  - ups-monitor_x86_64.ipk"
    echo "  - ups-monitor_x86_64.apk"
    echo ""
    echo "查看构建状态："
    echo "  https://github.com/ospfx/ups-monitor/actions"
else
    echo ""
    echo "[错误] 推送失败，请检查："
    echo "  1. 网络连接"
    echo "  2. GitHub 认证（已配置 token）"
    echo "  3. 仓库权限"
    exit 1
fi
