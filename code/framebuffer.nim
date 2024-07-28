import raylib
import math

import types

proc calculateScale*(window: var WindowState) =
  window.scale = min(getScreenWidth() / window.intRes.w, getScreenHeight() / window.intRes.h).round(2)

proc tick*(program: var ProgramState) =
  if isWindowResized():
    program.windowState.calculateScale()

proc draw*(program: var ProgramState) =
  let window: ptr WindowState = program.windowState.addr
  
  let startX = (getScreenWidth() div 2).float - ((window.intRes.w.float * window.scale) / 2)
  let startY = (getScreenHeight() div 2).float - ((window.intRes.h.float * window.scale) / 2)
  drawTexture(window.framebuffer.texture,
              newRectangle(0, 0, window.intRes.w.float, -window.intRes.h.float),
              newRectangle(startX, startY, window.intRes.w.float * window.scale, window.intRes.h.float * window.scale),
              newVector2(0, 0), 0, White)
