# Installation
1. Copy files _"aseplatform.lua"_.
2. Paste these files to the path **"%AppData%/Aseprite/scripts/"**.
3. Start Aseprite or, if the program is running, click **File > Scripts > Rescan Scripts Folder**.
4. The scripts will appear in **File > Scripts**.

# Introduction
AsePlatform is a script for the [Aseprite](https://github.com/aseprite/aseprite) graphic program.

This script allows you to run a mockup of the game screen as a very simple platformer, extremely limited but interactive!

An example in sprite form is attached, however, here is what is needed in the sprite itself:
- A layer named "TMCollision" with the collision shape drawn with opaque pixels.
- A layer named "Player". Can be a group.
- A layer named "Dangers", which must be a group. Within the group, each "danger zone" is a separate layer.
- A layer named "Bonuses", must be a group. Within the group each bonus is a separate layer.
- The layer named "Finish", which must be a group. Each element is an object, when colliding with which the game ends with a "finish".
And now about the interface:
- Layer-group with the name "Interface"
- Inside the "Interface" group, there should be a group called "Health".  In such a group each layer is one point of player's health.
- Inside the "Interface" group there should be a layer called "ScorePoint", one pixel is enough - it will be a reference point where the points gained in the game will be written.

And here's a video demonstration(of a slightly older version):
[![Watch the video](https://img.youtube.com/vi/u7vUu686ojI/hqdefault.jpg)](https://www.youtube.com/watch?v=u7vUu686ojI)

# LICENSES
The scripts are distributed under the [MIT license](LICENSE).
Sprites are distributed under [CC-BY-NC4.0 license](https://creativecommons.org/licenses/by-nc/4.0/). ![CC-BY-NC image](https://i.creativecommons.org/l/by-nc/4.0/88x31.png)