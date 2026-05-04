#!/bin/bash
# image-ocr.sh — 飞书图片 OCR（基于 tesseract）
# 用法: ./image-ocr.sh <message_id>

MESSAGE_ID="$1"
WORKDIR="/tmp/feishu-ocr-$$"
mkdir -p "$WORKDIR"
cd "$WORKDIR"

# 1. 获取图片 file_key
MSG_JSON=$(lark-cli api GET "/open-apis/im/v1/messages/${MESSAGE_ID}" --as bot 2>/dev/null)
FILE_KEY=$(echo "$MSG_JSON" | python3 -c "import sys,json; d=json.load(sys.stdin); c=json.loads(d['data']['items'][0]['body']['content']); print(c['image_key'])")

# 2. 下载图片
lark-cli api GET "/open-apis/im/v1/messages/${MESSAGE_ID}/resources/${FILE_KEY}" --params '{"type":"image"}' --as bot --output ./image.jpg 2>/dev/null >/dev/null

# 3. OCR 识别（中英文）
tesseract ./image.jpg ./ocr_output -l chi_sim+eng 2>/dev/null

# 4. 输出结果
if [ -f ./ocr_output.txt ]; then
  cat ./ocr_output.txt
else
  echo "[OCR: no text found]"
fi

# 5. 清理
rm -rf "$WORKDIR"
