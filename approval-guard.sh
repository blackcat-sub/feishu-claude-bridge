#!/bin/bash
# approval-guard.sh — 远程审批，通过飞书确认 Claude Code 高危操作
# Claude Code PreToolUse hook 调用
# 用法: ./approval-guard.sh <tool_name> <tool_input>
# 环境变量: FEISHU_CHAT_ID（飞书对话ID）

TOOL_NAME="$1"
TOOL_INPUT="${2:-}"
CHAT_ID="${FEISHU_CHAT_ID:-oc_b65550890e9f389e708b33bb1e1ef29b}"

# 不需要审批的安全操作
SAFE_TOOLS="Read|TodoWrite|Task|WebSearch|WebFetch|Skill|Bash(lark-cli *)|Bash(open *)|Bash(echo *)|Bash(ls *)|Bash(cat *)|Bash(cd *)|Bash(which *)"

# 检查是否在白名单中
if echo "$TOOL_NAME" | grep -qE "$SAFE_TOOLS"; then
  exit 0
fi

# 需要审批 — 发飞书消息
APPROVAL_ID="apr-$(date +%s)"
SUMMARY=$(echo "$TOOL_INPUT" | cut -c1-100)

lark-cli im +messages-send \
  --chat-id "$CHAT_ID" \
  --text "批准请求 [$APPROVAL_ID]
操作: $TOOL_NAME
内容: $SUMMARY
回复 yes 批准，no 拒绝（60秒超时自动拒）" \
  --as bot 2>/dev/null >/dev/null

# 轮询用户回复
for i in $(seq 1 30); do
  LATEST=$(lark-cli im +chat-messages-list \
    --chat-id "$CHAT_ID" \
    --as bot \
    --page-size 3 2>/dev/null | python3 -c "
import sys,json
try:
    d=json.load(sys.stdin)
    msgs=d.get('data',{}).get('messages',[])
    for m in msgs:
        c=m.get('content','')
        if c.strip().lower() in ('yes','no'):
            print(c.strip().lower())
            break
except: pass
")

  if [ "$LATEST" = "yes" ]; then
    lark-cli im +messages-send --chat-id "$CHAT_ID" --text "已批准 $APPROVAL_ID" --as bot 2>/dev/null >/dev/null
    exit 0
  elif [ "$LATEST" = "no" ]; then
    lark-cli im +messages-send --chat-id "$CHAT_ID" --text "已拒绝 $APPROVAL_ID" --as bot 2>/dev/null >/dev/null
    exit 1
  fi
  sleep 2
done

# 超时自动拒绝
lark-cli im +messages-send --chat-id "$CHAT_ID" --text "超时自动拒绝 $APPROVAL_ID" --as bot 2>/dev/null >/dev/null
exit 1
