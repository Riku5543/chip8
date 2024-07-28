Hi there. This is a chip-8 emulator written in Nim using raylib. It's a bit of a mess since I haven't gotten around to refactoring anything, and it even includes older code in "code-legacy" from back when I was using more sdl2 code. There's a lot I'd change about this project if I were to rewrite it, but I'm working on something else at the moment. Enjoy!

Note: Roboto Regular is included in this project. I think the license permits this, but if not I can remove it.

Also, this was developed on Linux, other platforms are probably okay though.
You can compile it by running `nim c ./c8.nim` and then running the resulting executable.
It runs a rom called `roms/1-chip8-logo.ch8` by default, but you can supply a path as the first argument on the command line and have it run that instead.

It seems during my refactoring from using sdl2 to only using raylib, I didn't end up implementing the input and sound commands, so that won't work for now.
You can run any rom that only displays graphics though. If you're extra determined you can try compiling the legacy code where it's all fully implemented.
