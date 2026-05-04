# 用飞书在手机上遥控 Claude Code 干活，支持语音

手机飞书发文字或语音 → Claude Code 电脑端自动处理 → 飞书回复结果。

**跟同类项目最大的区别：不需要服务器、不需要 Webhook、不需要数据库。** 全程跑在你自己的电脑上，零额外基础设施。

## 能做什么

- 手机上给飞书 Bot 发文字，Claude Code 收到后自动处理并回复
- 发语音也一样，自动转文字再处理
- 让 Claude Code 帮你读飞书文档、搜通讯录、发消息

## 为什么不用服务器

同类项目大多需要公网服务器接收飞书 Webhook。这套方案用 lark-cli 的 WebSocket 长连接，Bot 直连飞书服务器，消息走这条通道推下来。没有公网 IP、没有端口映射、没有 HTTPS 证书，全免了。

## 快速开始

### 1. 飞书开发者后台

创建企业自建应用，开通以下权限：

Bot 权限：`im:message`、`im:message.p2p_msg:readonly`

用户权限：`drive:file:upload`、`minutes:minutes.upload:write`、`minutes:minutes:readonly`、`minutes:minutes.artifacts:read`、`minutes:minutes.transcript:export`

事件订阅：启用 `im.message.receive_v1`

### 2. 安装 lark-cli 并授权

```bash
npm install -g @larksuite/cli
lark-cli config init --new
lark-cli auth login --scope "im:message.send_as_user im:chat:create_by_user drive:file:upload minutes:minutes.upload:write minutes:minutes:readonly minutes:minutes.artifacts:read minutes:minutes.transcript:export"
```

### 3. 下载本项目文件

```bash
git clone https://github.com/blackcat-sub/feishu-claude-bridge.git
cp feishu-stt.sh ~/feishu-stt.sh && chmod +x ~/feishu-stt.sh
```

### 4. 配置 Claude Code 权限

把 `settings.example.json` 里的内容合并到 `~/.claude/settings.local.json`，记得把 STT 脚本路径改成你自己的。

### 5. 设环境变量

```bash
export LARK_CLI_NO_PROXY=1
```

### 6. 启动监听

```bash
lark-cli event consume im.message.receive_v1 --as bot \
  --jq 'if .message_type=="text" then "TEXT|\(.chat_id)|\(.content)" elif .message_type=="audio" then "AUDIO|\(.chat_id)|\(.message_id)" else empty end' \
  < <(tail -f /dev/null)
```

### 7. 在飞书里搜你的 Bot 应用，发消息

搞定了。

## 语音怎么转文字

飞书 speech_to_text API 需要特殊审批。项目用飞书妙记 API 做中转：下载语音 → 生成妙记 → 取逐字稿 → 删音频文件。全程公开 API，不占云空间。

## 注意

- 电脑锁屏可以，不能休眠
- 语音转写会产生妙记通知，可在飞书设置里关掉
- 如果代理干扰飞书 API，设 `LARK_CLI_NO_PROXY=1`

## License

MIT
