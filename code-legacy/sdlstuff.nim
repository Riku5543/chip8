import sequtils

import sdl2

import objects

proc handleEvents*(sdlSystem: var SDLSystem) =
  sdlSystem.justReleasedKeys = @[]
  var event = defaultEvent
  while pollEvent(event):
    case event.kind
    of QuitEvent:
      sdlSystem.shouldQuit = true
    of KeyDown:
      if not (event.key.keysym.scancode in sdlSystem.heldKeys):
        if event.key.keysym.scancode in sdlSystem.allowedKeys:
          sdlSystem.heldKeys.add(event.key.keysym.scancode)
    of KeyUp:
      if event.key.keysym.scancode in sdlSystem.heldKeys:
        # Removes any key that matches current scancode
        sdlSystem.heldKeys.keepIf(proc(k: Scancode):bool = k != event.key.keysym.scancode)
        sdlSystem.justReleasedKeys.add(event.key.keysym.scancode)
    else:
      discard
