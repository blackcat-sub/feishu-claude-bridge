# 用飞书在手机上遥控 Claude Code 干活，支持语音

手机飞书发文字或语音 → Claude Code 电脑端自动处理 → 飞书回复结果。

**跟同类项目最大的区别：不需要服务器、不需要 Webhook、不需要数据库。** 全程跑在你自己的电脑上，零额外基础设施。

## 能做什么

- 手机上给飞书 Bot 发文字，Claude Code 收到后自动处理并回复
- 发语音也一样，自动转文字再处理
- 让 Claude Code 帮你读飞书文档、搜通讯录、发消息

## 为什么不用服务器

同类项目大多需要公网服务器接收飞书 Webhook。这套方案用 lark-cli 的 WebSocket 长连接，Bot 直连飞书服务器，消息走这条通道推下来。没有公网 IP、没有端口映射、没有 HTTPS 证书，全免了。

## 怎么搭

基本全程 AI 帮你搞定，你只需要做一件事。

**把这段发给 Claude Code：**

> 帮我搭建飞书 Claude Code 桥接，仓库在 https://github.com/blackcat-sub/feishu-claude-bridge。先装 lark-cli 并建应用，把用户权限都授权好，bot 权限告诉我需要加什么我自己去后台加，然后配置好 Claude Code 白名单，最后把监听跑起来。

然后你会经历：

1. Claude Code 跑 `lark-cli config init --new` 建应用，弹浏览器，你点确认
2. Claude Code 跑 `lark-cli auth login` 授权用户权限，弹浏览器，你再点确认
3. Claude Code 告诉你两个 bot 权限名，你去飞书后台搜一下加上、发布。这是你唯一需要动手的一步
4. 其余（下载脚本、配置白名单、设环境变量、启动监听）Claude Code 全包

搞定了。去飞书搜你的 Bot 应用，发条消息试试。

## 手动步骤清单（如果你不用 AI 搭）

### 1. 安装 lark-cli 并创建应用

```bash
npm install -g @larksuite/cli
lark-cli config init --new
lark-cli auth login --scope "im:message.send_as_user im:chat:create_by_user drive:file:upload minutes:minutes.upload:write minutes:minutes:readonly minutes:minutes.artifacts:read minutes:minutes.transcript:export"
```

### 2. 去飞书后台加 Bot 权限

打开 [飞书开发者后台](https://open.feishu.cn/app)，在「权限管理」里给 Bot 加上：

- `im:message`
- `im:message.p2p_msg:readonly`

发布新版本。事件订阅不用管，`event consume` 启动时自动注册。

### 3. 下载脚本

```bash
git clone https://github.com/blackcat-sub/feishu-claude-bridge.git
cp feishu-claude-bridge/feishu-stt.sh ~/feishu-stt.sh && chmod +x ~/feishu-stt.sh
```

### 4. 配置 Claude Code 白名单

把 `settings.example.json` 内容合并到 `~/.claude/settings.local.json`。

### 5. 启动监听

```bash
export LARK_CLI_NO_PROXY=1
lark-cli event consume im.message.receive_v1 --as bot \
  --jq 'if .message_type=="text" then "TEXT|\(.chat_id)|\(.content)" elif .message_type=="audio" then "AUDIO|\(.chat_id)|\(.message_id)" else empty end' \
  < <(tail -f /dev/null)
```

## 语音怎么转文字

飞书 speech_to_text API 需要特殊审批。项目用飞书妙记 API 做中转：下载语音 → 生成妙记 → 取逐字稿 → 删音频文件。全程公开 API，不占云空间。

## 注意

- 电脑锁屏可以，不能休眠
- 语音转写会产生妙记通知，可在飞书设置里关掉

## License

MIT
