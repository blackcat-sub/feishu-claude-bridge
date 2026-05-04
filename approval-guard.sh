#!/bin/bash
# approval-guard.sh — 远程审批，高危操作需飞书确认
# Claude Code PreToolUse hook

TOOL_NAME="$1"
TOOL_INPUT="${2:-}"
CHAT_ID="${FEISHU_CHAT_ID:-oc_b65550890e9f389e708b33bb1e1ef29b}"

# 读操作直接放行
case "$TOOL_NAME" in
  Read|TodoWrite|Task|WebSearch|WebFetch|Skill|AskUserQuestion|EnterPlanMode|ExitPlanMode|Monitor|TaskList|TaskGet|TaskUpdate|TaskCreate|TaskOutput|TaskStop)
    exit 0 ;;
esac

# Bash: 安全命令免审批
if [ "$TOOL_NAME" = "Bash" ]; then
  CMD=$(echo "$TOOL_INPUT" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('command',''))" 2>/dev/null || echo "$TOOL_INPUT")
  if echo "$CMD" | grep -qE "^(lark-cli|open|echo|ls|cat|cd|which|pwd|date|whoami|git status|git log|git diff|find|grep|file|wc|unset|export|env|mkdir)"; then
    exit 0
  fi
fi

# 需要审批
APPROVAL_ID="apr-$(date +%s)"
SUMMARY=$(echo "$TOOL_INPUT" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('command',str(d)[:100]))" 2>/dev/null || echo "$TOOL_INPUT" | cut -c1-100)

lark-cli im +messages-send --chat-id "$CHAT_ID" --text "批准请求 [$APPROVAL_ID] 操作: $TOOL_NAME 内容: $SUMMARY 回复 yes 批准，no 拒绝" --as bot 2>/dev/null >/dev/null

for i in $(seq 1 30); do
  LATEST=$(lark-cli im +chat-messages-list --chat-id "$CHAT_ID" --as bot --page-size 3 2>/dev/null | python3 -c "
import sys,json
try:
    d=json.load(sys.stdin)
    for m in d.get('data',{}).get('messages',[]):
        c=m.get('content','').strip().lower()
        if c in ('yes','no'):
            print(c)
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

lark-cli im +messages-send --chat-id "$CHAT_ID" --text "超时自动拒绝 $APPROVAL_ID" --as bot 2>/dev/null >/dev/null
exit 1
