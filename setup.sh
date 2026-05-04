#!/bin/bash
# setup.sh — 一键安装依赖
# 用法: ./setup.sh

set -e

echo "=== 检查并安装依赖 ==="

# tesseract OCR（图片识别）
if ! command -v tesseract &>/dev/null; then
  echo "安装 tesseract OCR..."
  brew install tesseract tesseract-lang
else
  echo "tesseract 已安装 ✓"
fi

# lark-cli
if ! command -v lark-cli &>/dev/null; then
  echo "安装 lark-cli..."
  npm install -g @larksuite/cli
else
  echo "lark-cli 已安装 ✓"
fi

echo ""
echo "=== 依赖安装完成 ==="
echo "下一步：lark-cli config init --new   # 创建飞书应用"
echo "        lark-cli auth login --scope \"...\"  # 授权用户权限"
