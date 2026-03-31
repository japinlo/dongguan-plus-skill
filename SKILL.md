# 东莞+自动积分 Skill

## 功能说明
自动完成东莞+ App 每日积分任务，任务完成后通过飞书发送结果通知。

## 运行环境
- Windows 10/11
- 雷电模拟器 9
- Airtest（自动安装）

## 使用前提
- 已安装并配置好 OpenClaw
- 飞书已登录

---

## 第一次使用：执行安装配置

按顺序完成以下步骤：

### Step 1：读取飞书凭证
读取 OpenClaw 本地配置文件，获取飞书 App ID 和 App Secret。

配置文件通常在以下位置之一：
- `%APPDATA%\OpenClaw\config.json`
- `%USERPROFILE%\.openclaw\config.json`
- OpenClaw 安装目录下的 `config.json`

找到后提取以下字段：
```
feishu_app_id
feishu_app_secret
feishu_user_id（用于接收消息的用户 open_id）
```

### Step 2：运行安装脚本
执行 `setup.bat`，该脚本会自动完成：
1. 检测雷电模拟器是否已安装，未安装则下载安装
2. 创建指定分辨率（1080x2400）的模拟器实例
3. 安装东莞+ APK
4. 安装 Python 依赖（airtest、requests）
5. 将飞书凭证写入 `dongguan_plus.py` 配置区
6. 将所有文件复制到工作目录
7. 创建 Windows 任务计划程序定时任务

### Step 3：用户手动操作（唯一需要手动的步骤）
启动雷电模拟器，打开东莞+ App，登录个人账号。
登录完成后告知 OpenClaw，OpenClaw 将关闭模拟器并完成最终配置。

### Step 4：验证
OpenClaw 手动触发一次任务，确认脚本正常运行并能收到飞书通知。

---

## 日常运行逻辑
每日定时自动执行，无需人工干预：

```
任务计划程序唤醒电脑
→ run_task.bat 启动雷电模拟器
→ 等待模拟器就绪
→ 运行 dongguan_plus.py
→ 完成 20 篇点赞任务
→ 检测积分进度条
→ 飞书发送结果通知
→ 关闭模拟器
→ 电脑休眠
```

---

## 飞书通知说明
通知通过飞书机器人以私信形式发送给用户本人，无需建群。
使用 OpenClaw 已有的飞书应用凭证，不需要额外配置。

通知内容：
- ✅ 成功：「东莞+ 今日积分任务已全部完成，进度条已满！」
- ⚠️ 异常：「东莞+ 今日积分任务异常！连续两次检测进度条均未满，请手动检查！」
- 🚨 报错：「东莞+ 脚本执行异常，错误信息：[具体错误]」

---

## 文件说明

| 文件 | 说明 |
|---|---|
| `SKILL.md` | 本文件，OpenClaw 操作指引 |
| `setup.bat` | 一键安装配置脚本 |
| `run_task.bat` | 每日定时运行脚本 |
| `dongguan_plus.py` | Airtest 主脚本 |
| `*.png` | Airtest 图像识别模板图 |
| `dongguanplus.apk` | 东莞+ 安装包 |
