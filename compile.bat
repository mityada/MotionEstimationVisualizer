@echo off
yasm -f win32 visualizer.asm
yasm -f win32 gdiwindow.asm
yasm -f win32 wincompat.asm
link /subsystem:windows /entry:main /defaultlib:user32.lib /defaultlib:kernel32.lib visualizer.obj gdiwindow.obj wincompat.obj msvcrt.lib gdi32.lib
