import raylib
import random

import types
import utils
import strformat
from framebuffer import nil

proc init*(program: var ProgramState, fileName: string) =
  let window: ptr WindowState = program.windowState.addr
  let system: ptr SystemState = program.systemState.addr
  # +-----+
  # | Nim |
  # +-----+
  randomize()

  # +--------+
  # | Raylib |
  # +--------+
  window.intRes.w = 64
  window.intRes.h = 32
  window.scale = 1

  setTraceLogLevel(Warning)
  initWindow(window.intRes.w * 16, window.intRes.h * 16, "Chip-8 Emulator")
  setWindowState(flags(WindowResizable))
  setWindowMinSize(window.intRes.w * 16, window.intRes.h * 16)
  window.framebuffer = loadRenderTexture(window.intRes.w, window.intRes.h)
  setExitKey(Null)
  initAudioDevice()
  setTargetFPS(60)

  framebuffer.calculateScale(window[]) # Needed since window is bigger than intRes when starting

  # +--------+
  # | Chip-8 |
  # +--------+
  # Font needs to be stored within 0000-01FF, but usually stored at 0000-004F
  var fontAddress: uint16 = 0x0
  fontAddress = system.ram.ramSequentialWrite(fontAddress, [0xF0'u8, 0x90, 0x90, 0x90, 0xF0]) # 0
  fontAddress = system.ram.ramSequentialWrite(fontAddress, [0x20'u8, 0x60, 0x20, 0x20, 0x70]) # 1
  fontAddress = system.ram.ramSequentialWrite(fontAddress, [0xF0'u8, 0x10, 0xF0, 0x80, 0xF0]) # 2
  fontAddress = system.ram.ramSequentialWrite(fontAddress, [0xF0'u8, 0x10, 0xF0, 0x10, 0xF0]) # 3
  fontAddress = system.ram.ramSequentialWrite(fontAddress, [0x90'u8, 0x90, 0xF0, 0x10, 0x10]) # 4
  fontAddress = system.ram.ramSequentialWrite(fontAddress, [0xF0'u8, 0x80, 0xF0, 0x10, 0xF0]) # 5
  fontAddress = system.ram.ramSequentialWrite(fontAddress, [0xF0'u8, 0x80, 0xF0, 0x90, 0xF0]) # 6
  fontAddress = system.ram.ramSequentialWrite(fontAddress, [0xF0'u8, 0x10, 0x20, 0x40, 0x40]) # 7
  fontAddress = system.ram.ramSequentialWrite(fontAddress, [0xF0'u8, 0x90, 0xF0, 0x90, 0xF0]) # 8
  fontAddress = system.ram.ramSequentialWrite(fontAddress, [0xF0'u8, 0x90, 0xF0, 0x10, 0xF0]) # 9
  fontAddress = system.ram.ramSequentialWrite(fontAddress, [0xF0'u8, 0x90, 0xF0, 0x90, 0x90]) # A
  fontAddress = system.ram.ramSequentialWrite(fontAddress, [0xE0'u8, 0x90, 0xE0, 0x90, 0xE0]) # B
  fontAddress = system.ram.ramSequentialWrite(fontAddress, [0xF0'u8, 0x80, 0x80, 0x80, 0xF0]) # C
  fontAddress = system.ram.ramSequentialWrite(fontAddress, [0xE0'u8, 0x90, 0x90, 0x90, 0xE0]) # D
  fontAddress = system.ram.ramSequentialWrite(fontAddress, [0xF0'u8, 0x80, 0xF0, 0x80, 0xF0]) # E
  discard system.ram.ramSequentialWrite(fontAddress, [0xF0'u8, 0x80, 0xF0, 0x80, 0x80]) # F
  
  # Load rom
  var romAddress: uint16 = 0x200
  let loadedRomFile = readFile(fileName)
  for b in loadedRomFile:
    romAddress = system.ram.ramSequentialWrite(romAddress, [b.uint8])
    # echo(fmt"{b.uint8:#04X}")
  system.pc = 0x200

  # +--------+
  # | Config |
  # +--------+
  system.config.quirkCosmicShifting = true
  system.config.quirkCosmicJumpWithOffset = true
  system.config.quirkCosmicFlagReset = true
  system.config.quirkCosmicMemoryIndex = true
  system.config.quirkCosmicDisplayWait = true
  system.config.offColor = Black
  system.config.onColor = White
  system.config.instructionsPerFrame = 11
