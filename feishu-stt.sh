#!/bin/bash
# feishu-stt.sh — 飞书语音转文字，一次调用搞定
# 用法: ./feishu-stt.sh <message_id>
MESSAGE_ID="$1"
WORKDIR="/tmp/feishu-stt-$$"
mkdir -p "$WORKDIR"
cd "$WORKDIR"

# 1. 获取消息，提取 file_key
MSG_JSON=$(lark-cli api GET "/open-apis/im/v1/messages/${MESSAGE_ID}" --as bot 2>/dev/null)
FILE_KEY=$(echo "$MSG_JSON" | python3 -c "import sys,json; d=json.load(sys.stdin); c=json.loads(d['data']['items'][0]['body']['content']); print(c['file_key'])")

# 2. 下载音频
lark-cli api GET "/open-apis/im/v1/messages/${MESSAGE_ID}/resources/${FILE_KEY}" --params '{"type":"file"}' --as bot --output ./audio.ogg 2>/dev/null >/dev/null

# 3. 上传云空间
UPLOAD_JSON=$(lark-cli drive +upload --file ./audio.ogg --as user 2>/dev/null)
FILE_TOKEN=$(echo "$UPLOAD_JSON" | python3 -c "import sys,json; print(json.load(sys.stdin)['data']['file_token'])") || exit 1

# 4. 生成妙记
MINUTE_JSON=$(lark-cli minutes +upload --file-token "$FILE_TOKEN" --as user 2>/dev/null)
MINUTE_TOKEN=$(echo "$MINUTE_JSON" | python3 -c "import sys,json; u=json.load(sys.stdin)['data']['minute_url']; print(u.split('/')[-1])") || exit 1
MINUTE_TOKEN=$(echo "$MINUTE_JSON" | python3 -c "import sys,json; u=json.load(sys.stdin)['data']['minute_url']; print(u.split('/')[-1])")

# 5. 等妙记转写完成（轮询最多30秒）
NOTES_JSON=""
for i in $(seq 1 15); do
  NOTES_JSON=$(lark-cli vc +notes --minute-tokens "$MINUTE_TOKEN" --as user 2>/dev/null) || true
  if echo "$NOTES_JSON" | grep -q "transcript_file"; then break; fi
  sleep 2
done

# 6. 提取逐字稿文本（跳过日期行、关键词行、空行、说话人时间戳行）
TRANSCRIPT_REL=$(echo "$NOTES_JSON" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d['data']['notes'][0]['artifacts']['transcript_file'])")
python3 -c "
import re
with open('${WORKDIR}/${TRANSCRIPT_REL}') as f:
    for line in f:
        line = line.strip()
        if not line: continue
        if re.match(r'^\d{4}-\d{2}-\d{2}|^关键词|^说话人', line): continue
        print(line)
"

# 7. 删除云空间音频文件（避免占用存储）
lark-cli drive +delete --file-token "$FILE_TOKEN" --type file --yes --as user 2>/dev/null >/dev/null || true

rm -rf "$WORKDIR"
