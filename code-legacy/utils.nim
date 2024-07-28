import strformat

import raylib

# import sdl2
# import sdl2/mixer

import objects

proc dumpRAM*(system: System) =
  var tmp: uint16 = 0
  for b in system.ram:
    echo(fmt"{tmp:#06X}: {b:#04X}")
    tmp += 1

proc ramSequentialWrite*(ram: var openArray[uint8], address: uint16, data: openArray[uint8]): uint16 =
  # Returns the next address
  result = address
  for b in data:
    ram[result] = b
    result += 1

# proc pixelSequentialWrite*(pixelData: var PixelArrayPointer, address: uint16, data: openArray[uint8]): uint16 =
#   # Returns the next address
#   result = address
#   for b in data:
#     pixelData[result] = b
#     result += 1

proc teardown*(emulator: var Emulator) =
  # sdlSystem.window.destroy()
  # sdlSystem.glContext.glDeleteContext()
  # sdlSystem.renderer.destroy()
  # sdlSystem.screenTexture.destroy()
  # sdlSystem.beep.freeChunk()
  # mixer.closeAudio()
  # sdl2.quit()
  closeWindow()
