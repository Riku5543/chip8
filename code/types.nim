import raylib

type
  ProgramState* = object
    windowState*: WindowState
    systemState*: SystemState
    frontendState*: FrontendState

  WindowState* = object
    closeRequested*: bool
    framebuffer*: RenderTexture2D
    scale*: float32
    intRes*: Resolution
  
  SystemState* = object
    stack*: seq[uint16]
    delayTimer*: uint8
    soundTimer*: uint8
    ram*: array[0..4095, uint8]
    pc*: uint16
    i*: uint16 # Index
    varRegisters*: array[0..15, uint8]
    screen*: array[0..63, array[0..31, bool]]
    halted*: bool
    config*: SystemConfig
  
  SystemConfig* = object
    quirkCosmicShifting*: bool
    quirkCosmicJumpWithOffset*: bool
    quirkCosmicFlagReset*: bool
    quirkCosmicMemoryIndex*: bool
    quirkCosmicDisplayWait*: bool
    offColor*: Color
    onColor*: Color
    instructionsPerFrame*: uint8

  FrontendState* = object
    heldKeys*: seq[KeyboardKey]
    releasedKeys*: seq[KeyboardKey]
    allowedKeys*: array[0..15, KeyboardKey]
    beep*: Music
    config*: FrontendConfig

  FrontendConfig* = object
    frameRateDisplay*: bool

  Resolution* = tuple[w,h:int32]
  Position* = tuple[x,y:int32]

proc newRectangle*(x, y, width, height: float32): Rectangle =
  result.x = x
  result.y = y
  result.width = width
  result.height = height

proc newVector2*(x, y: float32): Vector2 =
  result.x = x
  result.y = y
