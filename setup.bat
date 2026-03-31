@echo off
chcp 65001 >nul
setlocal enabledelayedexpansion

echo.
echo ========================================
echo   东莞+ 自动积分任务 - 一键安装配置
echo ========================================
echo.

:: ========== 路径配置 ==========
set WORK_DIR=%USERPROFILE%\DongguanPlus
set LD_DIR=C:\LDPlayer\LDPlayer9
set LD_CONSOLE=%LD_DIR%\ldconsole.exe
set LD_ADB=%LD_DIR%\adb.exe
set APK_PATH=%~dp0dongguanplus.apk
set SCRIPT_DIR=%~dp0

:: ========== Step 1：检测雷电模拟器 ==========
echo [1/6] 检测雷电模拟器...
if exist "%LD_CONSOLE%" (
    echo      ✓ 雷电模拟器已安装
) else (
    echo      未检测到雷电模拟器，开始下载安装...
    echo      请稍候，安装包约 500MB...
    powershell -Command "Invoke-WebRequest -Uri 'https://ldplayer-res.ldmnq.com/ldplayer9/LDPlayer9Setup.exe' -OutFile '%TEMP%\LDPlayerSetup.exe'"
    echo      正在静默安装雷电模拟器...
    "%TEMP%\LDPlayerSetup.exe" /S
    timeout /t 30 /nobreak >nul
    echo      ✓ 雷电模拟器安装完成
)

:: ========== Step 2：创建模拟器实例 ==========
echo.
echo [2/6] 配置模拟器实例...

:: 检查是否已有实例 0
"%LD_CONSOLE%" list2 | findstr "0," >nul 2>&1
if errorlevel 1 (
    echo      创建新实例...
    "%LD_CONSOLE%" add --name "DongguanPlus"
    timeout /t 5 /nobreak >nul
)

:: 设置分辨率 1080x2400，DPI 420
"%LD_CONSOLE%" modify --index 0 --resolution 1080,2400,420
echo      ✓ 模拟器分辨率已设置为 1080x2400

:: ========== Step 3：安装东莞+ APK ==========
echo.
echo [3/6] 安装东莞+ App...

:: 先启动模拟器
"%LD_CONSOLE%" launch --index 0
echo      等待模拟器启动...
timeout /t 20 /nobreak >nul

:: 等待 adb 连接就绪
:wait_adb
"%LD_ADB%" get-state 2>nul | findstr "device" >nul
if errorlevel 1 (
    timeout /t 5 /nobreak >nul
    goto wait_adb
)

:: 安装 APK
"%LD_CONSOLE%" installapp --index 0 --filename "%APK_PATH%"
echo      ✓ 东莞+ 安装完成

:: ========== Step 4：安装 Python 依赖 ==========
echo.
echo [4/6] 安装 Airtest 和依赖...
pip install airtest requests --quiet
if errorlevel 1 (
    echo      pip 未找到，尝试用 Python 模块方式安装...
    python -m pip install airtest requests --quiet
)
echo      ✓ 依赖安装完成

:: ========== Step 5：部署脚本文件 ==========
echo.
echo [5/6] 部署脚本文件...
if not exist "%WORK_DIR%" mkdir "%WORK_DIR%"

:: 复制所有文件到工作目录
xcopy /Y /Q "%SCRIPT_DIR%dongguan_plus.py" "%WORK_DIR%\"
xcopy /Y /Q "%SCRIPT_DIR%run_task.bat" "%WORK_DIR%\"
xcopy /Y /Q "%SCRIPT_DIR%*.png" "%WORK_DIR%\"

echo      ✓ 文件已部署到 %WORK_DIR%

:: ========== Step 6：配置定时任务 ==========
echo.
echo [6/6] 配置 Windows 定时任务...

:: 删除旧任务（如果存在）
schtasks /delete /tn "DongguanPlusTask" /f >nul 2>&1

:: 创建新任务：每天 00:38 运行，允许唤醒电脑
schtasks /create ^
    /tn "DongguanPlusTask" ^
    /tr "\"%WORK_DIR%\run_task.bat\"" ^
    /sc daily ^
    /st 00:38 ^
    /ru "%USERNAME%" ^
    /f >nul

:: 开启唤醒电脑权限（需要管理员权限）
powercfg /waketimers enable >nul 2>&1

:: 用 XML 方式更新任务以启用唤醒
schtasks /query /tn "DongguanPlusTask" /xml > "%TEMP%\task_temp.xml"
powershell -Command "(Get-Content '%TEMP%\task_temp.xml') -replace '<DisallowStartIfOnBatteries>true</DisallowStartIfOnBatteries>', '<DisallowStartIfOnBatteries>false</DisallowStartIfOnBatteries>' | Set-Content '%TEMP%\task_temp.xml'"
powershell -Command "(Get-Content '%TEMP%\task_temp.xml') -replace '<WakeToRun>false</WakeToRun>', '<WakeToRun>true</WakeToRun>' | Set-Content '%TEMP%\task_temp.xml'"
schtasks /delete /tn "DongguanPlusTask" /f >nul 2>&1
schtasks /create /tn "DongguanPlusTask" /xml "%TEMP%\task_temp.xml" /f >nul

echo      ✓ 定时任务已创建（每天 00:38 自动运行）

echo.
echo ========================================
echo   安装配置完成！
echo.
echo   接下来请手动操作：
echo   1. 模拟器已启动，请打开东莞+ App
echo   2. 登录您的个人账号
echo   3. 登录完成后，告知 OpenClaw 继续
echo ========================================
echo.
pause
