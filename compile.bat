@echo off
yasm -f win32 visualizer.asm
yasm -f win32 gdiwindow.asm
yasm -f win32 wincompat.asm
yasm -f win32 bitmap.asm
link /subsystem:console /entry:main /defaultlib:kernel32.lib /defaultlib:user32.lib /defaultlib:shell32.lib visualizer.obj gdiwindow.obj wincompat.obj bitmap.obj msvcrt.lib gdi32.lib
