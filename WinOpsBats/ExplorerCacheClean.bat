@echo off

set EXPLORER_ICON_CACHE=%LOCALAPPDATA%\Microsoft\Windows\Explorer\iconcache_*.db
set EXPLORER_THUMB_CACHE=%LOCALAPPDATA%\Microsoft\Windows\Explorer\thumbcache_*.db
set EXPLORER_ICON_CACHE_OLD=%LOCALAPPDATA%\IconCache.db

for /f "tokens=1-3 delims=/ " %%a in ("%date%") do (
    set day=%%a
    set month=%%b
    set year=%%c
)

for /f "tokens=1-3 delims=:." %%a in ("%time%") do (
    set hour=%%a
    set minute=%%b
    set second=%%c
)

echo %year%-%month%-%day% %hour%:%minute%:%second% INFO - Process explorer.exe is about to be closed
pause

taskkill /f /im explorer.exe

for /f "tokens=1-3 delims=/ " %%a in ("%date%") do (
    set day=%%a
    set month=%%b
    set year=%%c
)

for /f "tokens=1-3 delims=:." %%a in ("%time%") do (
    set hour=%%a
    set minute=%%b
    set second=%%c
)

echo %year%-%month%-%day% %hour%:%minute%:%second% INFO - The explorer icon cache file is being deleted

echo %year%-%month%-%day% %hour%:%minute%:%second% INFO - Process explorer.exe is being restarted

del /a /q %EXPLORER_ICON_CACHE%

del /a /q %EXPLORER_THUMB_CACHE%

del /a /q %EXPLORER_ICON_CACHE_OLD%

start explorer.exe

echo Complete!

pause
