# 用飞书在手机上遥控 Claude Code 干活，支持语音和图片

**适合谁：用 DeepSeek 等纯文本模型、不想为多模态额外付费、想在手机上指挥电脑干活的飞书用户。**

手机飞书发文字、语音或图片 → Claude Code 电脑端自动处理 → 飞书回复结果。

核心优势：
1. **零服务器** — 不需要服务器、Webhook、数据库，全在你电脑上跑
2. **无需多模态模型** — 纯文本模型（DeepSeek 等）也能处理语音和图片，不额外花钱
3. **全本土生态** — 飞书 + DeepSeek 都在国内，普通网络稳定运行，不依赖境外服务
4. **数据不出境** — 语音走飞书妙记（飞书自带），图片走本地 OCR，不引入第三方 API

## 怎么搭

把下面这句话发给 Claude Code，它会全部帮你搞定：

> 帮我搭建飞书 Claude Code 桥接，仓库在 https://github.com/blackcat-sub/feishu-claude-bridge

Claude Code 会按顺序做这些事：

1. 克隆仓库，跑 `setup.sh` 装 tesseract + lark-cli
2. `lark-cli config init --new` 创建飞书应用
3. `lark-cli auth login` 弹浏览器授权权限
4. 告诉你需要加哪些 bot 权限，你去飞书后台搜一下加上
5. 把 `settings.example.json` 合并到你的 Claude Code 白名单
6. 用 `monitor.sh` 启动消息监听
7. 搞定，去飞书搜你的 Bot 发消息试试

事件订阅自动注册，不用管。tesseract 语言包约 650MB，只识别中英文的话装完问 Claude Code 怎么精简。

## 能做什么

- 发文字 → Claude Code 自动处理回复
- 发语音 → 飞书妙记自动转文字再处理
- 发图片 → tesseract 本地 OCR 提取文字再处理（支持 100+ 种语言）
- 断网后监听自动重连，不用管
- 读飞书文档、搜通讯录、发消息

## 为什么不用服务器

同类项目大多需要公网服务器接收飞书 Webhook。这套方案用 lark-cli 的 WebSocket 长连接，Bot 直连飞书服务器，没有公网 IP、没有端口映射、没有 HTTPS 证书。

## 使用场景与局限

项目最适合处理文字类图片：聊天截图、文档拍照、表格等等。飞书里的图片大多是为了传上面的文字，OCR 完全够用。

如果你需要理解复杂视觉内容（照片里有什么、图表趋势分析、设计稿评价），需要真正的多模态模型。项目架构支持升级——把 `image-ocr.sh` 换成调 Claude Vision / GPT-4V API 的脚本即可。

语音同理：飞书妙记只负责转写，不分析语气情绪。要这些就换多模态模型。

## 文件说明

| 文件 | 用途 |
|------|------|
| `setup.sh` | 一键装依赖（tesseract + lark-cli），已装的跳过 |
| `monitor.sh` | 消息监听，断网自动重连 |
| `feishu-stt.sh` | 语音转文字 |
| `image-ocr.sh` | 图片 OCR 提取文字 |
| `cleanup-minutes.sh` | 妙记管理 |
| `settings.example.json` | Claude Code 白名单模板 |

## 语音和图片怎么处理

**语音** → 下载 → 飞书妙记生成逐字稿 → 提取文字 → 删文件（全程飞书 API，不花钱）

**图片** → 下载 → tesseract 本地 OCR → 输出文字 → 删文件（离线运行，不花钱）

处理完自动清理本地文件，不占空间。

## 注意

- 电脑锁屏可以，不能休眠
- 妙记转写会弹飞书通知，可在飞书设置里关掉

## License

MIT
