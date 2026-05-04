# Feishu ↔ Claude Code Bridge

用飞书 Bot 双向操控 Claude Code，支持文字和语音。

## 能做什么

- 手机飞书发文字/语音 → Claude Code 电脑端自动接收处理 → 飞书回复
- 语音自动转文字（通过飞书妙记 API）
- 文档读写、通讯录搜索等飞书操作

## 前置条件

1. [飞书开发者后台](https://open.feishu.cn) 创建企业自建应用
2. [lark-cli](https://github.com/larksuite/cli) 安装并配置
3. [Claude Code](https://claude.ai/code) 已安装
4. macOS（`open` 命令）

## 快速开始

### 1. 配置飞书应用

在飞书开发者后台为应用添加以下 Bot 权限：
- `im:message` （发送消息）
- `im:message.p2p_msg:readonly` （接收私聊消息）

为用户添加以下权限（用于妙记语音转文字）：
- `drive:file:upload`
- `minutes:minutes.upload:write`
- `minutes:minutes:readonly`
- `minutes:minutes.artifacts:read`
- `minutes:minutes.transcript:export`

事件订阅：启用 `im.message.receive_v1`

### 2. 配置 lark-cli

```bash
npm install -g @larksuite/cli
lark-cli config init --new
lark-cli auth login --scope "im:message.send_as_user im:chat:create_by_user drive:file:upload minutes:minutes.upload:write minutes:minutes:readonly minutes:minutes.artifacts:read minutes:minutes.transcript:export"
```

### 3. 配置 Claude Code 权限

将 `settings.example.json` 中的权限合并到 `~/.claude/settings.local.json` 的 `permissions.allow` 中。

### 4. 设置环境变量

```bash
export LARK_CLI_NO_PROXY=1
```

### 5. 启动消息监听

```bash
lark-cli event consume im.message.receive_v1 --as bot \
  --jq 'if .message_type=="text" then "TEXT|\(.chat_id)|\(.content)" elif .message_type=="audio" then "AUDIO|\(.chat_id)|\(.message_id)" else empty end' \
  < <(tail -f /dev/null)
```

### 6. 语音转文字

```bash
./feishu-stt.sh <message_id>
```

## 文件说明

- `feishu-stt.sh` — 语音转文字脚本，通过妙记 API 将语音消息转为文本
- `settings.example.json` — Claude Code 权限白名单模板

## 注意事项

- 电脑锁屏可以，但不能休眠，否则监听进程挂起
- 飞书 speech_to_text API 需要单独审批，当前用妙记做中转
- 语音转写会产生妙记记录，可在飞书设置中关闭妙记通知

## License

MIT
