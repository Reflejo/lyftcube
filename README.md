# <img src="https://cloud.githubusercontent.com/assets/232113/12376017/b8c6733a-bc93-11e5-9b6d-d169c321d867.png" width="60%">

This repository contains the guides, the code and the PCB layouts to create an 8x8x8 LED Cube driven by a Raspberry Pi Zero. The cube also exposes an API to enable remote control.

### Preview

[![Cube video](http://img.youtube.com/vi/IA_xOcMGhlw/0.jpg)](http://www.youtube.com/watch?v=IA_xOcMGhlw)

### Modules

This repository contains 3 different parts:

1. [CubeDesigner-iOS](https://github.com/Reflejo/lyftcube/tree/master/CubeDesigner-iOS): An iOS application used to design, preview animations and control the cube remotely.
2. [cube](https://github.com/Reflejo/lyftcube/tree/master/cube): All the logic that runs on the Raspberry Pi Zero, including:
  * [lyftcube](https://github.com/Reflejo/lyftcube/tree/master/cube/lyftcube): This program controls the cube, including the Bit Angle Modulation, Multiplexing and animation parsing.
  * [server](https://github.com/Reflejo/lyftcube/tree/master/cube/server): Binds an HTTP server containing the API that comunicates with the cube
3. [hardware](https://github.com/Reflejo/lyftcube/tree/master/hardware): Contains schematics and PCB designs
