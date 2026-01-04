@echo off
rem 切换当前目录到脚本所在的目录
pushd "%~dp0"

rem 列出所有与 Hyper-V 相关的 .mum 文件，并将输出保存到 hyper-v.txt
dir /b %SystemRoot%\servicing\Packages\*Hyper-V*.mum > hyper-v.txt

rem 遍历 hyper-v.txt 中的每一行
for /f %%i in ('findstr /i . hyper-v.txt 2^>nul') do (
    rem 使用 DISM 添加相应的软件包
    dism /online /norestart /add-package:"%SystemRoot%\servicing\Packages\%%i"
)

rem 删除临时文件 hyper-v.txt
del hyper-v.txt

rem 启用所有 Hyper-V 功能
Dism /online /enable-feature /featurename:Microsoft-Hyper-V-All /LimitAccess /ALL
