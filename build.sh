#!/usr/bin/env bash
# WorkBuddy 扩展构建 + 同步到 workbuddy-extension-dist/
set -euo pipefail

cd "$(dirname "$0")"

DIST="workbuddy-extension-dist"
SOURCES=(package.json icon.svg README.md panel/index.html panel/main.js service/index.js)

echo "▶ 1/4 编译 panel/main.js（IIFE）"
CACHED_ESBUILD=$(find "$HOME/.npm/_npx" -path "*/node_modules/.bin/esbuild" 2>/dev/null | head -n 1 || true)
if command -v bun >/dev/null 2>&1; then
  bunx openchamber-guest-bundle panel/main.ts panel/main.js
elif command -v esbuild >/dev/null 2>&1; then
  esbuild panel/main.ts --bundle --format=iife --platform=browser --outfile=panel/main.js
elif [ -n "$CACHED_ESBUILD" ] && [ -x "$CACHED_ESBUILD" ]; then
  "$CACHED_ESBUILD" panel/main.ts --bundle --format=iife --platform=browser --outfile=panel/main.js
elif [ -f node_modules/.bin/esbuild ]; then
  ./node_modules/.bin/esbuild panel/main.ts --bundle --format=iife --platform=browser --outfile=panel/main.js
else
  npx --yes esbuild panel/main.ts \
    --bundle --format=iife --platform=browser \
    --outfile=panel/main.js
fi

echo "▶ 2/4 校验 panel/main.js 为经典 IIFE（非 ESM）"
if grep -qE '^\s*(import|export)[[:space:]]' panel/main.js; then
  echo "✗ panel/main.js 含 ESM 语法，沙箱 iframe 无法加载"
  exit 1
fi
echo "  ✓ IIFE 校验通过"

echo "▶ 3/4 同步到 ${DIST}/"
rm -rf "$DIST"
mkdir -p "$DIST/panel" "$DIST/service"
for f in "${SOURCES[@]}"; do
  if [ ! -f "$f" ]; then
    echo "✗ 缺少源文件: $f"
    exit 1
  fi
  cp "$f" "$DIST/$f"
done

echo "▶ 4/4 校验清单与产物一致性"
SRC_MANIFEST=$(node -e "process.stdout.write(require('./$DIST/package.json').openchamber.contributes.panel.id)")
echo "  • panel.id = ${SRC_MANIFEST}"

node --input-type=module -e "
import fs from 'node:fs';
const { parseManifest } = await import(process.argv[1]);
const doc = JSON.parse(fs.readFileSync('./$DIST/package.json','utf8'));
const r = parseManifest(doc);
if (!r.ok) { console.error('✗ 清单校验失败:', r.code, r.message); process.exit(1); }
console.log('  ✓ 清单校验通过 (apiVersion ' + r.manifest.apiVersion + ', v' + r.version + ')');
" "$(pwd)/node_modules/@openchamber/sdk/dist/parse.js"

for f in "${SOURCES[@]}"; do
  if [ ! -f "$DIST/$f" ]; then
    echo "✗ 同步缺失: $f"
    exit 1
  fi
  if ! cmp -s "$f" "$DIST/$f"; then
    echo "✗ 内容不一致: $f"
    exit 1
  fi
done
echo "  ✓ ${#SOURCES[@]} 个文件与源目录 100% 一致"

echo "▶ 5/5 打包为 zip 发布包"
rm -f workbuddy-extension.zip workbuddy-extension-windows.zip
(cd "$DIST" && zip -r ../workbuddy-extension.zip ./* -x "*.DS_Store")
cp workbuddy-extension.zip workbuddy-extension-windows.zip
echo "  ✓ 生成 workbuddy-extension.zip / workbuddy-extension-windows.zip"

echo
echo "✅ 构建完成"
echo "   文件夹安装路径: $(pwd)/${DIST}"
echo "   压缩包路径: $(pwd)/workbuddy-extension-windows.zip"