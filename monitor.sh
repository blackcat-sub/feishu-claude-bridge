#!/bin/bash
# monitor.sh — 飞书消息监听，断网自动重连
# 用法: ./monitor.sh

JQ_FILTER='if .message_type=="text" then "TEXT|\(.chat_id)|\(.content)" elif .message_type=="audio" then "AUDIO|\(.chat_id)|\(.message_id)" elif .message_type=="image" then "IMAGE|\(.chat_id)|\(.message_id)" elif .message_type=="file" then "FILE|\(.chat_id)|\(.message_id)" elif .message_type=="post" then "POST|\(.chat_id)|\(.content)" else "OTHER|\(.message_type)|\(.chat_id)|\(.message_id)" end'

RETRY=0
while true; do
  if [ $RETRY -gt 0 ]; then
    echo "[monitor] 第 ${RETRY} 次重连..." >&2
    sleep 3
  fi
  echo "[monitor] 启动监听..." >&2
  lark-cli event consume im.message.receive_v1 --as bot \
    --jq "$JQ_FILTER" \
    < <(tail -f /dev/null)
  RETRY=$((RETRY + 1))
  echo "[monitor] 监听退出，准备重连..." >&2
done
