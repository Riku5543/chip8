# import sdl2
# import sdl2/mixer

import raylib

type System* = object
  stack*: seq[uint16]
  delayTimer*: uint8
  soundTimer*: uint8
  ram*: array[0..4095, uint8]
  pc*: uint16
  i*: uint16 # Index
  varRegisters*: array[0..15, uint8]
  screen*: array[0..63, array[0..31, bool]]
  halted*: bool

# type SDLSystem* = object
#   window*: WindowPtr
  # glContext*: GlContextPtr
  # renderer*: RendererPtr
  # screenTexture*: TexturePtr
  # beep*: ptr Chunk
  # shouldQuit*: bool
  # targetFrameRate*: float
  # heldKeys*: seq[Scancode]
  # justReleasedKeys*: seq[Scancode]
  # allowedKeys*: array[0..15, Scancode]

type Frontend* = object
  heldKeys*: seq[KeyboardKey]
  justReleasedKeys*: seq[KeyboardKey]
  allowedKeys*: array[0..15, KeyboardKey]
  beep*: Music

type Config* = object
  quirkCosmicShifting*: bool
  quirkCosmicJumpWithOffset*: bool
  quirkCosmicFlagReset*: bool
  quirkCosmicMemoryIndex*: bool
  quirkCosmicDisplayWait*: bool
  frameRateDisplay*: bool
  offColor*: Color
  onColor*: Color
  instructionsPerFrame*: uint8

type Emulator* = object
  system*: System
  frontend*: Frontend
  config*: Config

# type PixelArrayPointer* = ptr array[0..8191, uint8] # Texture is 8192 bytes

proc newSystem*: System =
  result.pc = 0x200

# proc newSDLSystem*: SDLSystem =
#   result.targetFrameRate = 1000 / 60
#   # In order of keypad
  # result.allowedKeys = [SDL_SCANCODE_X,
  # SDL_SCANCODE_1, SDL_SCANCODE_2, SDL_SCANCODE_3,
  # SDL_SCANCODE_Q, SDL_SCANCODE_W, SDL_SCANCODE_E,
  # SDL_SCANCODE_A, SDL_SCANCODE_S, SDL_SCANCODE_D,
  # SDL_SCANCODE_Z, SDL_SCANCODE_C, SDL_SCANCODE_4,
  # SDL_SCANCODE_R, SDL_SCANCODE_F, SDL_SCANCODE_V]

# proc newFrontend*: Frontend =
  # raylib stuff here

proc newFrontend*: Frontend =
  result.allowedKeys = [X, One, Two, Three, Q, W, E, A, S, D, Z, C, Four, R, F, V]

proc newConfig*: Config =
  result.quirkCosmicShifting = true
  result.quirkCosmicJumpWithOffset = true
  result.quirkCosmicFlagReset = true
  result.quirkCosmicMemoryIndex = true
  result.quirkCosmicDisplayWait = true
  result.frameRateDisplay = false
  # ARGB
  result.offColor = Black
  result.onColor = White
  result.instructionsPerFrame = 11

proc newEmulator*: Emulator =
  result.system = newSystem()
  result.frontend = newFrontend()
  result.config = newConfig()

# Rectangle comes from raylib, so adding a convienience proc
proc newRectangle*(x, y, width, height: float32): Rectangle =
  result.x = x
  result.y = y
  result.width = width
  result.height = height

# From raylib
proc newColor*(r, g, b: uint8, a: uint8 = 0xFF): Color =
  result.r = r
  result.g = g
  result.b = b
  result.a = a
