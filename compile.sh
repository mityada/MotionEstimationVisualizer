#!/bin/bash

yasm -f elf32 -g dwarf2 bitmap.asm
yasm -f elf32 -g dwarf2 xwindow.asm
yasm -f elf32 -g dwarf2 visualizer.asm

ld -dynamic-linker /lib/ld-linux.so.2 -lc -lX11 -o visualizer visualizer.o xwindow.o bitmap.o
