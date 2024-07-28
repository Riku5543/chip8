import strformat
import raylib

import code/objects
import code/utils
import code/init
import code/chip8

proc main =
  # https://tobiasvl.github.io/blog/write-a-chip-8-emulator/
  var emulator = newEmulator()
  emulator.init()
  playMusicStream(emulator.frontend.beep)

  # emulator.config.offColor = newColor(0x00, 0x00, 0x80) # Dark blue
  # emulator.config.onColor = newColor(0xB0, 0xE0, 0xE6) # Light blue
  # emulator.config.frameRateDisplay = true

  while not windowShouldClose():
    updateMusicStream(emulator.frontend.beep)

    if isKeyPressed(F3):
      emulator.config.frameRateDisplay = not emulator.config.frameRateDisplay

    emulator.frontend.justReleasedKeys = @[]
    var currentKey = getKeyPressed()
    while currentKey != Null:
      if not (currentKey in emulator.frontend.heldKeys):
        if currentKey in emulator.frontend.allowedKeys:
          emulator.frontend.heldKeys.add(currentKey)
      currentKey = getKeyPressed()

    var newHeldKeys = emulator.frontend.heldKeys
    for k in newHeldKeys:
      if isKeyUp(k):
        emulator.frontend.heldKeys.delete(emulator.frontend.heldKeys.find(k))
        emulator.frontend.justReleasedKeys.add(k)

    # Run cpu
    if not emulator.system.halted:
      emulator.runChip8()
    else:
      # TODO: Show a "message box" on screen when the machine gets halted.
      # echo("[I] Machine is halted.")
      discard
    
    # Now that cpu logic is done for the frame, decrement the counters.
    if emulator.system.delayTimer > 0:
      emulator.system.delayTimer -= 1
    if emulator.system.soundTimer > 0:
      # if not paused(emulator.frontend.beep): # if sound is not playing
      resumeMusicStream(emulator.frontend.beep)
      emulator.system.soundTimer -= 1
    else:
      pauseMusicStream(emulator.frontend.beep)

    # TODO: skip rendering if nothing changed
    # Convert 2d bool array to 1d pixel data
    var screenPixels: seq[Color] = @[]
    for yCoord in 0..31:
      for xCoord in emulator.system.screen:
        if xCoord[yCoord] == true:
          screenPixels.add(emulator.config.onColor)
        else:
          screenPixels.add(emulator.config.offColor)

    beginDrawing()
    clearBackground(Black)
    # Take pixels and fit them to the screen size
    drawTexture(loadTextureFromData(screenPixels, 64, 32), newRectangle(0, 0, 64, 32), newRectangle(0, 0, getScreenWidth().float32, getScreenHeight().float32), Vector2(x:0,y:0), 0, White)
    if emulator.config.frameRateDisplay:
      let fpsString = fmt"{getFPS()} FPS ({getFrameTime() * 1000:.5}ms)"
      drawText(fpsString.cstring, 20, 20, 24, Red)
    endDrawing()

  closeAudioDevice()
  emulator.teardown()

main()
