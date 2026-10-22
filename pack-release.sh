#!/bin/bash

# WorkBuddy 扩展发布打包脚本

set -e

DIST_DIR="workbuddy-extension-dist"

echo "🧹 清理旧的构建..."
rm -rf "$DIST_DIR"

echo "📁 创建发布目录..."
mkdir -p "$DIST_DIR/panel"
mkdir -p "$DIST_DIR/service"

echo "📋 复制必要文件..."
# 清理的 package.json（不包含 devDependencies）
cat package.json | sed '/devDependencies/,/}/d' > "$DIST_DIR/package.json"

# 复制核心文件
cp icon.svg "$DIST_DIR/"
cp panel/index.html "$DIST_DIR/panel/"
cp panel/main.js "$DIST_DIR/panel/"
cp service/index.js "$DIST_DIR/service/"
cp README.md "$DIST_DIR/" 2>/dev/null || true

echo "✅ 验证文件完整性..."
required_files=(
    "$DIST_DIR/package.json"
    "$DIST_DIR/icon.svg"
    "$DIST_DIR/panel/index.html"
    "$DIST_DIR/panel/main.js"
    "$DIST_DIR/service/index.js"
)

for file in "${required_files[@]}"; do
    if [ ! -f "$file" ]; then
        echo "❌ 缺少文件: $file"
        exit 1
    fi
done

echo "📊 文件大小统计:"
du -sh "$DIST_DIR"

echo "✨ 打包完成！"
echo ""
echo "📂 发布目录: $DIST_DIR"
echo "📍 绝对路径: $(pwd)/$DIST_DIR"
echo ""
echo "安装方式："
echo "1. 在 OpenChamber 中打开「设置 → 扩展」"
echo "2. 粘贴路径: $(pwd)/$DIST_DIR"
echo "3. 点击「添加」并授予权限"
