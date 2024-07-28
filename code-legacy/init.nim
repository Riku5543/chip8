import random

import strutils

import raylib

# import sdl2
# import sdl2/mixer
# import sdl2/audio

import objects
import utils

proc init*(emulator: var Emulator) =
  #+-----+
  #| SDL |
  #+-----+
  # if sdl2.init(INIT_EVERYTHING) != SdlSuccess:
  #   echo("[X] Failed to initialize sdl2.")
  #   sdl2.quit()
  #   quit(1)

  # if setHint("SDL_RENDER_SCALE_QUALITY", "0") != true:
  #   echo("[W] Unable to set render quality to preferred value.")

  # let windowFlags = SDL_WINDOW_SHOWN or SDL_WINDOW_RESIZABLE
  # sdlSystem.window = createWindow("Chip-8 Emulator", SDL_WINDOWPOS_CENTERED, SDL_WINDOWPOS_CENTERED, 512, 256, windowFlags)
  # if sdlSystem.window.isNil:
  #   echo("[X] Failed to create the window.")
  #   sdlSystem.window.destroy()
  #   sdl2.quit()
  #   quit(1)

  # sdlSystem.renderer = sdlSystem.window.createRenderer(-1, Renderer_Accelerated or Renderer_PresentVsync)
  # if sdlSystem.renderer.isNil:
  #   echo("[X] Failed to create the renderer.")
  #   sdlSystem.window.destroy()
  #   sdlSystem.renderer.destroy()
  #   sdl2.quit()
  #   quit(1)
  # sdlSystem.renderer.setDrawBlendMode(BlendMode_Blend)
  # sdlSystem.renderer.setDrawColor(0, 0, 0, 0xFF)
  # sdlSystem.renderer.clear()
  # sdlSystem.renderer.present()

  # sdlSystem.screenTexture = sdlSystem.renderer.createTexture(SDL_PIXELFORMAT_BGRA8888, SDL_TEXTUREACCESS_STREAMING, 64, 32)

  # if openAudio(44100, AUDIO_F32, 2, 2048) != 0:
  #   echo("[X] Failed to enable audio.")
  #   sdlSystem.window.destroy()
  #   sdlSystem.renderer.destroy()
  #   sdl2.quit()
  #   quit(1)

  # discard allocateChannels(1)
  # sdlSystem.beep = loadWAV("beep.wav")

  #+--------+
  #| Raylib |
  #+--------+
  setTraceLogLevel(Warning)
  initWindow(512, 256, "Chip-8 Emulator")
  setExitKey(Null)
  setTargetFPS(60)
  initAudioDevice()
  emulator.frontend.beep = loadMusicStream("beep.wav")

  #+--------+
  #| Chip-8 |
  #+--------+
  # Font needs to be stored within 0000-01FF, but usually stored at 0000-004F
  var fontAddress: uint16 = 0x0
  fontAddress = emulator.system.ram.ramSequentialWrite(fontAddress, [0xF0'u8, 0x90, 0x90, 0x90, 0xF0]) # 0
  fontAddress = emulator.system.ram.ramSequentialWrite(fontAddress, [0x20'u8, 0x60, 0x20, 0x20, 0x70]) # 1
  fontAddress = emulator.system.ram.ramSequentialWrite(fontAddress, [0xF0'u8, 0x10, 0xF0, 0x80, 0xF0]) # 2
  fontAddress = emulator.system.ram.ramSequentialWrite(fontAddress, [0xF0'u8, 0x10, 0xF0, 0x10, 0xF0]) # 3
  fontAddress = emulator.system.ram.ramSequentialWrite(fontAddress, [0x90'u8, 0x90, 0xF0, 0x10, 0x10]) # 4
  fontAddress = emulator.system.ram.ramSequentialWrite(fontAddress, [0xF0'u8, 0x80, 0xF0, 0x10, 0xF0]) # 5
  fontAddress = emulator.system.ram.ramSequentialWrite(fontAddress, [0xF0'u8, 0x80, 0xF0, 0x90, 0xF0]) # 6
  fontAddress = emulator.system.ram.ramSequentialWrite(fontAddress, [0xF0'u8, 0x10, 0x20, 0x40, 0x40]) # 7
  fontAddress = emulator.system.ram.ramSequentialWrite(fontAddress, [0xF0'u8, 0x90, 0xF0, 0x90, 0xF0]) # 8
  fontAddress = emulator.system.ram.ramSequentialWrite(fontAddress, [0xF0'u8, 0x90, 0xF0, 0x10, 0xF0]) # 9
  fontAddress = emulator.system.ram.ramSequentialWrite(fontAddress, [0xF0'u8, 0x90, 0xF0, 0x90, 0x90]) # A
  fontAddress = emulator.system.ram.ramSequentialWrite(fontAddress, [0xE0'u8, 0x90, 0xE0, 0x90, 0xE0]) # B
  fontAddress = emulator.system.ram.ramSequentialWrite(fontAddress, [0xF0'u8, 0x80, 0x80, 0x80, 0xF0]) # C
  fontAddress = emulator.system.ram.ramSequentialWrite(fontAddress, [0xE0'u8, 0x90, 0x90, 0x90, 0xE0]) # D
  fontAddress = emulator.system.ram.ramSequentialWrite(fontAddress, [0xF0'u8, 0x80, 0xF0, 0x80, 0xF0]) # E
  discard emulator.system.ram.ramSequentialWrite(fontAddress, [0xF0'u8, 0x80, 0xF0, 0x80, 0x80]) # F
  # let romFile = open("IBM Logo.ch8")
  let romToLoad = readFile("romname").strip() # temporary until I can get imgui working
  let romFile = open(romToLoad)
  # TODO: Overflow check
  # try:
  discard romFile.readBytes(emulator.system.ram, 0x200, romFile.getFileSize())
  # except IndexDefect:
  #   echo("Rom cannot be loaded, it's too big to fit into ram.")
  #   quit(1)
  romFile.close()

  #+-----+
  #| Nim |
  #+-----+
  randomize()
