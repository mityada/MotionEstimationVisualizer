Motion Estimation Visualizer
----------------------------

This visualizer shows calculated motion vectors on the frame and/or estimated frame.

Compiling
---------

Linux:
./compile.sh

Windows (you must have yasm, link, kernel32.lib, user32.lib, gdi32.lib, msvcrt.lib, and maybe something else):
compile.bat

Usage
-----

./visualizer vectors frame

vectors - file with motion vectors
frame - bitmap with frame

V key turns display of motion vectors on/off.
E key toggles between frame and estimated frame.

Motion Vectors File Format
--------------------------

File is binary. First four bytes is frame width, next four bytes - frame height.
Then there are (width / 8) * (height / 8) motion vectors.
Motion vector of block (i, j) is located at (width / 8) * j + i place.
Each motion vector consists of 8 bytes. First 4 bytes is x coordinate, last 4 bytes is y coordinate.

BMP Format
----------

Visualizer supports uncompressed 8-bit, 24-bit or 32-bit BMP.
