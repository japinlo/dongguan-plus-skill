@echo off
chcp 65001 >nul
setlocal

set WORK_DIR=%USERPROFILE%\DongguanPlus
set LD_DIR=C:\LDPlayer\LDPlayer9
set LD_CONSOLE=%LD_DIR%\ldconsole.exe
set LD_ADB=%LD_DIR%\adb.exe
set LOG=%WORK_DIR%\task_log.txt

echo === 自动任务开始: %date% %time% === >> "%LOG%"

:: 1. 启动模拟器
echo 启动模拟器... >> "%LOG%"
"%LD_CONSOLE%" launch --index 0 >> "%LOG%" 2>&1

:: 2. 等待模拟器就绪（最多等 120 秒）
set READY=0
set COUNT=0
:wait_loop
timeout /t 5 /nobreak >nul
set /a COUNT+=1
"%LD_ADB%" get-state 2>nul | findstr "device" >nul
if not errorlevel 1 (
    set READY=1
    echo 模拟器已就绪！（第 %COUNT% 次检测） >> "%LOG%"
    goto wait_done
)
echo 等待中... (%COUNT%/24) >> "%LOG%"
if %COUNT% lss 24 goto wait_loop

:wait_done
if "%READY%"=="0" (
    echo 模拟器启动超时，任务终止。 >> "%LOG%"
    goto sleep_now
)

:: 3. 额外等待 10 秒让系统稳定
timeout /t 10 /nobreak >nul

:: 4. 运行 Airtest 脚本
echo 开始运行 Airtest 脚本... >> "%LOG%"
python "%WORK_DIR%\dongguan_plus.py" >> "%LOG%" 2>&1

:: 5. 关闭模拟器
echo 关闭模拟器... >> "%LOG%"
"%LD_CONSOLE%" quit --index 0 >> "%LOG%" 2>&1
echo 模拟器已关闭 >> "%LOG%"

:sleep_now
echo === 任务结束: %date% %time% === >> "%LOG%"
echo. >> "%LOG%"

:: 6. 休眠
shutdown /h /f
