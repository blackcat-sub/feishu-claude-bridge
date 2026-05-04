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

把这段话发给 Claude Code，它会帮你全部搞定：

> 帮我搭建飞书 Claude Code 桥接，仓库在 https://github.com/blackcat-sub/feishu-claude-bridge

Claude Code 会做的事情：用 lark-cli 创建飞书应用、弹出浏览器让你授权用户权限、配置 Claude Code 白名单、下载语音转文字脚本、启动消息监听。中间如果需要去飞书后台开什么权限，它会告诉你具体加哪个，你搜一下加上就行。

它具体执行的步骤大概是这样：

1. `npm install -g @larksuite/cli` — 装 lark-cli
2. `lark-cli config init --new` — 自动在飞书后台创建应用
3. `lark-cli auth login --scope "im:message.send_as_user im:chat:create_by_user drive:file:upload minutes:minutes.upload:write minutes:minutes:readonly minutes:minutes.artifacts:read minutes:minutes.transcript:export"` — 弹浏览器授权用户权限，你点确认
4. 如果需要 bot 权限（`im:message`、`im:message.p2p_msg:readonly`），它会告诉你，你去 [飞书开发者后台](https://open.feishu.cn/app) 搜一下加上
5. 把 `settings.example.json` 合并到 `~/.claude/settings.local.json`
6. `export LARK_CLI_NO_PROXY=1`
7. 用 `monitor.sh` 启动监听（断网自动重连），Bot 开始接收消息

事件订阅（`im.message.receive_v1`）不用管，`event consume` 启动时自动注册。

## 语音怎么转文字

飞书 speech_to_text API 需要特殊审批。项目用飞书妙记 API 做中转：下载语音 → 生成妙记 → 取逐字稿 → 删音频文件。全程公开 API，不占云空间。

## 文件说明

- `monitor.sh` — 消息监听脚本，断网自动重连
- `feishu-stt.sh` — 语音转文字脚本，给 message_id 出文字
- `cleanup-minutes.sh` — 查看妙记列表，加 `--open` 打开管理页
- `settings.example.json` — Claude Code 权限白名单模板

## 注意

- 电脑锁屏可以，不能休眠
- 语音转写会产生妙记通知，可在飞书设置里关掉
- 监听进程断网后自动重连，不用手动重启

## License

MIT
