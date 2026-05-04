# 用飞书在手机上遥控 Claude Code 干活，支持语音

你在外面吃饭、开会、躺床上，突然想让 Claude Code 帮你改个 bug、搜个文档、跑个脚本——掏出手机，给飞书 Bot 发条消息就行。文字也行，语音也行。

跟 GitHub 上同类项目比，这套方案最大的不同：**不需要服务器、不需要 Webhook、不需要数据库**。全程就跑在你自己的电脑上，lark-cli 负责飞书通信，Claude Code 负责干活，一个 shell 脚本搞定语音转文字。

## 实际效果

手机飞书 → Bot 收到消息 → Claude Code 在电脑上自动处理 → 飞书回复结果。

- 发文字：秒回
- 发语音：自动转文字后再处理（10 秒左右）
- 操控飞书：让 Claude Code 帮你读文档、搜通讯录、发消息

## 怎么做到的

### 文字消息：事件监听 + WebSocket

飞书开放平台提供了 `im.message.receive_v1` 事件，Bot 可以通过 WebSocket 长连接实时接收消息。lark-cli 封装了这个过程，一行命令就能起一个持久监听进程：

```bash
lark-cli event consume im.message.receive_v1 --as bot
```

当你的手机给 Bot 发消息，这个进程立刻就收到事件，Claude Code 读到后处理并回复。

### 语音消息：妙记 API 中转

飞书的语音转文字 API（`speech_to_text`）需要特殊审批，大部分应用拿不到。所以我们走了另一条路：飞书妙记。

妙记本来是做会议纪要的，但它的核心能力就是音视频转文字。流程是：

1. 收到语音消息，下载 OGG 音频文件
2. 上传到飞书云空间
3. 调用妙记 API 生成一个妙记
4. 等 AI 转写完成后，提取逐字稿
5. 删掉云空间的音频文件，不占存储

每一步都是正经的飞书公开 API，没有 hack。只是借了妙记的道，稍微绕了一点。

### 权限白名单

Claude Code 执行每个 shell 命令都要你点确认。飞书远程操控的时候你不在电脑前，点不了。所以提前把飞书相关的命令加入白名单：

```json
{
  "permissions": {
    "allow": [
      "Bash(lark-cli im *)",
      "Bash(lark-cli drive *)",
      "Bash(lark-cli minutes *)",
      "Bash(lark-cli vc *)",
      "Bash(lark-cli docs *)",
      ...
    ]
  }
}
```

这样 Claude Code 执行这些命令时不会弹框，流程全自动。

## 搭建步骤

### 你需要先有

- 一台 Mac（Windows 也能用，但 `open` 命令要换成对应的）
- [Claude Code](https://claude.ai/code) 已安装
- 一个飞书账号

### 1. 创建飞书应用

去 [飞书开发者后台](https://open.feishu.cn) 创建一个企业自建应用。记下 App ID 和 App Secret。

### 2. 开通权限

在应用的「权限管理」页面添加：

**Bot 权限（应用身份）：**
- `im:message` — 发送消息
- `im:message.p2p_msg:readonly` — 接收私聊消息

**用户权限（你的身份，用于妙记语音转文字）：**
- `drive:file:upload` — 上传文件
- `minutes:minutes.upload:write` — 生成妙记
- `minutes:minutes:readonly` — 读取妙记
- `minutes:minutes.artifacts:read` — 读取 AI 产物
- `minutes:minutes.transcript:export` — 导出逐字稿

**事件订阅：**
- 在「事件与回调」页面，启用 `im.message.receive_v1`（接收消息）

完成权限配置后，发布一个新版本让配置生效。

### 3. 安装 lark-cli 并登录

```bash
npm install -g @larksuite/cli
lark-cli config init --new    # 填入 App ID 和 App Secret
lark-cli auth login --scope "im:message.send_as_user im:chat:create_by_user drive:file:upload minutes:minutes.upload:write minutes:minutes:readonly minutes:minutes.artifacts:read minutes:minutes.transcript:export"
```

登录过程会弹出浏览器让你授权，确认即可。

### 4. 配置 Claude Code 权限

把 `settings.example.json` 里的白名单合并到你的 `~/.claude/settings.local.json` 中（记得把 STT 脚本路径改成你自己的）。

### 5. 放好语音转文字脚本

```bash
cp feishu-stt.sh ~/feishu-stt.sh
chmod +x ~/feishu-stt.sh
```

### 6. 设环境变量

```bash
export LARK_CLI_NO_PROXY=1
```

### 7. 启动消息监听

在 Claude Code 里说：「帮我监听飞书消息」，或者直接在终端跑：

```bash
lark-cli event consume im.message.receive_v1 --as bot \
  --jq 'if .message_type=="text" then "TEXT|\(.chat_id)|\(.content)" elif .message_type=="audio" then "AUDIO|\(.chat_id)|\(.message_id)" else empty end' \
  < <(tail -f /dev/null)
```

### 8. 在飞书里找到你的 Bot

在飞书 App 里搜索你的应用名称，给它发一条消息。如果一切正常，Claude Code 这边应该就收到了。

## 文件说明

- `feishu-stt.sh` — 语音转文字脚本。给它一个 message_id，它把语音变成文字吐出来
- `settings.example.json` — Claude Code 权限白名单模板，照着改路径就行

## 注意事项

- 电脑锁屏没问题，但**不能休眠**。休眠了所有进程挂起，消息收不到。Mac 用户可以设「系统设置 → 电池 → 防止自动休眠」
- 每次语音转写会产生一条妙记记录。飞书会弹通知，可以在飞书设置里关掉妙记通知
- 飞书 `speech_to_text` API 目前需要单独找飞书申请白名单，普通应用开不了。等项目规模大了可以考虑申请，到时就彻底不用妙记了
- lark-cli 会自动走你的系统代理（如果有的话）。如果代理干扰了飞书 API 通信，设 `LARK_CLI_NO_PROXY=1`

## 为什么不用服务器

同类项目大多需要一个公网服务器来接收飞书的 Webhook 回调。但这套方案用了 lark-cli 的 WebSocket 长连接模式——Bot 直接跟飞书服务器保持一条 TCP 连接，消息推下来就走这条通道。没有公网 IP、没有端口映射、没有 HTTPS 证书，全部免了。

这就是它最轻的地方：你不需要维护任何额外的基础设施，代码全在本地，想改就改，想停就停。

## License

MIT
