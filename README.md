# 用飞书在手机上遥控 Claude Code 干活，支持语音和图片

手机飞书发文字、语音或图片 → Claude Code 电脑端自动处理 → 飞书回复结果。

**跟同类项目最大的区别：不需要服务器、不需要 Webhook、不需要数据库。** 全程跑在你自己的电脑上，零额外基础设施。

**另一个关键优势：无需多模态模型，也能处理语音和图片。** 语音走飞书妙记 API（已包含在你的飞书账号里），图片走 tesseract OCR（免费开源，本地跑）。你用的 DeepSeek 是纯文本模型，一样能用——不用为多模态掏额外 API 费用。

## 能做什么

- 手机上给飞书 Bot 发文字，Claude Code 收到后自动处理并回复
- 发语音，自动转文字再处理（通过飞书妙记 API）
- 发图片，自动 OCR 提取图中文字再处理（基于 tesseract，免费本地跑）
- 让 Claude Code 帮你读飞书文档、搜通讯录、发消息
- 断网后监听自动重连，不用手动重启
- 妙记列表查看和一键打开管理页清理

## 为什么不用服务器

同类项目大多需要公网服务器接收飞书 Webhook。这套方案用 lark-cli 的 WebSocket 长连接，Bot 直连飞书服务器，消息走这条通道推下来。没有公网 IP、没有端口映射、没有 HTTPS 证书，全免了。

## 怎么搭

把这段话发给 Claude Code，它会帮你全部搞定：

> 帮我搭建飞书 Claude Code 桥接，仓库在 https://github.com/blackcat-sub/feishu-claude-bridge

Claude Code 会做的事情：用 lark-cli 创建飞书应用、弹出浏览器让你授权用户权限、配置 Claude Code 白名单、下载所有脚本、启动消息监听。中间如果需要去飞书后台开什么权限，它会告诉你具体加哪个，你搜一下加上就行。

它具体执行的步骤：

1. `npm install -g @larksuite/cli` — 装 lark-cli
2. `lark-cli config init --new` — 自动在飞书后台创建应用
3. `lark-cli auth login --scope "..."` — 弹浏览器授权用户权限，你点确认
4. 如果需要 bot 权限（`im:message`、`im:message.p2p_msg:readonly`），它会告诉你，你去飞书后台搜一下加上
5. 把 `settings.example.json` 合并到 `~/.claude/settings.local.json`
6. `export LARK_CLI_NO_PROXY=1`
7. 用 `monitor.sh` 启动监听（断网自动重连），Bot 开始接收消息

事件订阅（`im.message.receive_v1`）不用管，`event consume` 启动时自动注册。

语音转文字和图片 OCR 的前置依赖：

```bash
brew install tesseract tesseract-lang    # 图片 OCR 引擎
```

妙记相关权限已包含在上面的 auth login scope 中，无需额外操作。

## 文件说明

| 文件 | 用途 |
|------|------|
| `monitor.sh` | 消息监听脚本，断网自动重连，全消息类型支持 |
| `feishu-stt.sh` | 语音转文字，传入 message_id 返回文本 |
| `image-ocr.sh` | 图片 OCR，传入 message_id 返回图中文字 |
| `cleanup-minutes.sh` | 妙记管理，`--open` 打开管理页清理 |
| `settings.example.json` | Claude Code 权限白名单模板 |

## 语音和图片怎么处理（无需多模态模型）

纯文本模型（如 DeepSeek）本身不能听语音、不能看图。项目用两个免费路径绕开这个限制：

**语音 → 飞书妙记**（飞书自带，不用额外付费）。下载语音 → 生成妙记 → 取逐字稿 → 删音频文件。妙记是飞书内置的会议纪要服务，转写能力由飞书提供，不需要你接入任何第三方 ASR API。

**图片 → tesseract OCR**（开源免费，本地离线运行）。下载图片 → OCR 提取文字 → 删本地文件。整个识别过程在你的电脑上完成，不调任何云 API，不花钱。

两条路都不需要多模态模型，不需要额外 API Key，纯文本模型就能用。

## 注意

- 电脑锁屏可以，不能休眠
- 语音转写会产生妙记通知，可在飞书设置里关掉
- 图片 OCR 需要提前 `brew install tesseract tesseract-lang`
- 项目远程已配置 SSH（`git@github.com`），HTTPS 被墙时不受影响

## License

MIT
