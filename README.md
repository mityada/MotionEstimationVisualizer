Motion Estimation Visualizer
----------------------------

This visualizer shows calculated motion vectors (currently just on white background) and created estimated frame from previous frame and motion vectors.

Compiling
---------

./compile.sh

Usage
-----

./visualizer motion_vectors prev_frame.bmp est_frame.bmp

Motion Vectors File Format
--------------------------

File is binary. First four bytes is frame width, next four bytes - frame height.
Then there are (width / 8) * (height / 8) motion vectors.
Motion vector of block (i, j) is located at (width / 8) * j + i place.
Each motion vector consists of 8 bytes. First 4 bytes is x coordinate, last 4 bytes is y coordinate.
