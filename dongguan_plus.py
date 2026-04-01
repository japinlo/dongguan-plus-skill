# -*- encoding=utf8 -*-
__author__ = "japinlo"

from airtest.core.api import *
import requests
import subprocess
import os

# ========== 配置区（由 setup.bat 自动写入，无需手动修改）==========
FEISHU_APP_ID = ""
FEISHU_APP_SECRET = ""
FEISHU_USER_ID = ""       # 接收通知的用户 open_id
APP_PACKAGE = "com.cmstop.timedg"
TARGET_COUNT = 20
RETRY_COUNT = 5
LD_ADB = r"C:\LDPlayer\LDPlayer9\adb.exe"
# ===================================================================


# ========== 飞书通知（通过 App 凭证发私信）==========
def get_feishu_token():
    resp = requests.post(
        "https://open.feishu.cn/open-apis/auth/v3/tenant_access_token/internal",
        json={"app_id": FEISHU_APP_ID, "app_secret": FEISHU_APP_SECRET},
        timeout=10
    )
    return resp.json().get("tenant_access_token", "")

def send_feishu(text):
    try:
        token = get_feishu_token()
        requests.post(
            "https://open.feishu.cn/open-apis/im/v1/messages?receive_id_type=open_id",
            headers={"Authorization": f"Bearer {token}"},
            json={
                "receive_id": FEISHU_USER_ID,
                "msg_type": "text",
                "content": f'{{"text": "{text}"}}'
            },
            timeout=10
        )
        print(f"[飞书通知已发送] {text}")
    except Exception as e:
        print(f"[飞书通知失败] {e}")


# ========== 自动检测雷电模拟器 adb 端口 ==========
def get_emulator_serial():
    result = subprocess.run(
        [LD_ADB, "devices"],
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE
    )
    for line in result.stdout.decode("utf-8").split("\n"):
        if "emulator" in line and "device" in line:
            return line.split("\t")[0].strip()
    return None


# ========== 核心任务：刷一篇文章 ==========
def do_one_article():
    touch((500, 800))
    sleep(4)

    unliked_icon = Template(r"tpl1772442140691.png", record_pos=(0.304, 0.838), resolution=(1080, 1920))

    if exists(unliked_icon):
        print("发现新文章，开始点赞分享！")
        touch(unliked_icon)
        sleep(1.5)

        touch(Template(r"tpl1772442157578.png", record_pos=(0.438, 0.836), resolution=(1080, 1920)))
        sleep(2)

        copy_link_icon = Template(r"tpl1772452786215.png", record_pos=(-0.374, 0.829), resolution=(1080, 2400))
        if exists(copy_link_icon):
            touch(copy_link_icon)
            sleep(1.5)
            return True
        else:
            print("⚠️ 复制链接面板未弹出，跳过本次")
            return False
    else:
        print("这篇文章已经点过赞了，跳过。")
        return False


# ========== 滑到下一篇 ==========
def scroll_to_next(continuous_skip):
    keyevent("BACK")
    sleep(2)
    swipe((500, 1600), (500, 300), duration=1.2)
    sleep(2)
    if continuous_skip >= 3:
        print("连续跳过3次，执行额外深度滑动！")
        swipe((500, 1600), (500, 300), duration=1)
        sleep(1)
        swipe((500, 1600), (500, 300), duration=1)
        sleep(2)
        return 0
    return continuous_skip


# ========== 执行 N 篇任务 ==========
def run_tasks(n):
    success_count = 0
    continuous_skip = 0
    while success_count < n:
        print(f"正在寻找第 {success_count + 1} 篇未点赞文章...")
        result = do_one_article()
        if result:
            success_count += 1
            continuous_skip = 0
            print(f"--- 成功！目前已完成 {success_count}/{n} 篇 ---")
        else:
            continuous_skip += 1
        continuous_skip = scroll_to_next(continuous_skip)
    print(f"本轮 {n} 篇任务完成。")


# ========== 检查进度条是否已满 ==========
def check_progress_full():
    touch((975, 2266))
    sleep(3)
    touch((910, 470))
    sleep(3)

    full_bar = Template(r"tpl1774797491250.png", record_pos=(0.0, 0.055), resolution=(1080, 2400))
    result = exists(full_bar)

    keyevent("BACK")
    sleep(2)
    touch((111, 2266))
    sleep(2)

    if result:
        print("✅ 进度条已满！")
        return True
    else:
        print("❌ 进度条未满。")
        return False


# ========== 主流程 ==========
print("\n========== 开始执行东莞+自动打卡任务 ==========")

try:
    # 自动检测模拟器端口
    serial = get_emulator_serial()
    if not serial:
        raise RuntimeError("找不到在线的模拟器")

    print(f"检测到模拟器：{serial}")
    EMULATOR = f"Android://127.0.0.1:5037/{serial}"
    auto_setup(__file__, logdir=True, devices=[EMULATOR])
    sleep(3)  # 等待 adb 连接稳定，防止 Broken pipe

    start_app(APP_PACKAGE)
    sleep(8)

    run_tasks(TARGET_COUNT)

    fail_count = 0
    for attempt in range(2):
        if check_progress_full():
            send_feishu("✅ 东莞+ 今日积分任务已全部完成，进度条已满！")
            break
        else:
            fail_count += 1
            if fail_count < 2:
                print(f"第 {attempt + 1} 次检查未满，补做 {RETRY_COUNT} 篇...")
                run_tasks(RETRY_COUNT)
            else:
                send_feishu("⚠️ 东莞+ 今日积分任务异常！连续两次检测进度条均未满，请手动检查！")

except Exception as e:
    print(f"执行过程中出现异常: {e}")
    send_feishu(f"🚨 东莞+ 脚本执行异常，错误信息：{e}")

finally:
    print("任务执行完毕！准备关闭 App...")
    stop_app(APP_PACKAGE)
    print("========== 今日任务结束 ==========\n")
