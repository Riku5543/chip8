import raylib
import os

import code/types
import code/init
from code/framebuffer import nil
from code/chip8 import nil

proc main(fileName: string) =
  var program: ProgramState
  init(program, fileName)
  let window: ptr WindowState = program.windowState.addr

  while (not window.closeRequested) and (not windowShouldClose()):
    framebuffer.tick(program)
    chip8.tick(program)

    beginTextureMode(window.framebuffer)
    clearBackground(Black)
    chip8.draw(program)
    endTextureMode()

    beginDrawing()
    clearBackground(Black)
    framebuffer.draw(program)
    # frontend
    endDrawing()

if commandLineParams().len > 0:
  main(commandLineParams()[0])
else:
  main("roms/1-chip8-logo.ch8")
