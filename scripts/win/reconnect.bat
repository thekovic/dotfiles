@echo off

REM Restart my Wi-Fi because it sucks.

echo Disconnecting from %WIFI_SSID%...
netsh wlan disconnect

timeout /t 3 /nobreak >nul

echo Reconnecting to %WIFI_SSID%...
netsh wlan connect name=%WIFI_SSID%

echo Done!

timeout /t 1 /nobreak >nul