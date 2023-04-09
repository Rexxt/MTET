@echo off
echo Building...
7z a -tzip game.love .
copy /b love.exe+game.love MTET.exe
echo OK!
@echo on