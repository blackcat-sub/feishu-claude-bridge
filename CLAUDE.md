# CLAUDE.md

## 飞书双向对话（自动启动）

当用户说到"飞书"、发飞书消息、通过飞书聊天等任何飞书 IM 交互时，立即自动执行：

1. 启动飞书消息监听：
   ```
   lark-cli event consume im.message.receive_v1 --as bot < <(tail -f /dev/null)
   ```
   用 Monitor 工具启动（persistent 模式），监听 incoming 消息。

2. 收到消息后根据内容处理并回复：
   ```
   lark-cli im +messages-send --chat-id <chat_id> --text "<回复内容>" --as bot
   ```

3. 语音消息：用 `feishu-stt.sh` 转写后处理；图片消息：用 `image-ocr.sh` OCR 后处理。

用户不需要提醒"监听"——提到飞书的那一刻，监听就已经开始了。
