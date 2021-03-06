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

./visualizer vectors frames

vectors - file with motion vectors

frames - file with description of frames

V key turns display of motion vectors on/off.

1 - show first frame in pair. 2 - show second frame in pair. 3 - show estimated second frame.

Displayed frame pair can be selected with keys K and L.

Motion Vectors File Format
--------------------------

File is binary. First four bytes is the frame count. Next eight bytes is frame width and height, four bytes for each.
Then there are (frame count - 1) blocks of motion vectors.
Each block consists of (width / 8) * (height / 8) motion vectors.
Motion vector of block (i, j) is located at (width / 8) * j + i place.
Each motion vector consists of 8 bytes. First 4 bytes is x coordinate, last 4 bytes is y coordinate.

Frames file format
------------------

File is text. On the first line there is the frame count.
The next (frame count) lines contain paths to corresponding frame bitmaps.

BMP Format
----------

Visualizer supports uncompressed 8-bit, 24-bit or 32-bit BMP.
