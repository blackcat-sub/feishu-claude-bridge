#!/bin/bash
# cleanup-minutes.sh — 查看和清理妙记
# 用法: ./cleanup-minutes.sh [--open]

echo "正在搜索妙记..."
RESULT=$(lark-cli minutes +search --as user --page-size 50 2>/dev/null)
COUNT=$(echo "$RESULT" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d['data']['total_count'])" 2>/dev/null || echo "0")

echo "当前共有 $COUNT 条妙记"
echo ""

if [ "$COUNT" -gt 0 ]; then
  echo "最近的妙记："
  echo "$RESULT" | python3 -c "
import sys,json
d=json.load(sys.stdin)
for m in d['data']['minutes']:
    print(f\"  {m['title']}  |  {m['create_time']}  |  {m['url']}\")
" 2>/dev/null
fi

if [ "${1}" = "--open" ]; then
  echo ""
  echo "打开飞书妙记管理页面..."
  open "https://ghptvzzn9u.feishu.cn/minutes"
fi
