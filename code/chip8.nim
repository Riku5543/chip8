import strformat
import random
import math
import algorithm
import raylib

import types

proc haltChip(system: var SystemState, msg: string) =
  echo(fmt"[X] {msg} Machine will now halt.")
  system.halted = true

proc tick*(program: var ProgramState) =
  let system: ptr SystemState = program.systemState.addr
  if system.halted: return
  for _ in 1'u8..system.config.instructionsPerFrame:
    if (system.pc > 4095) or ((system.pc + 1) > 4095):
      system[].haltChip("Tried to execute instructions outside of ram.")
      return
    
    var currentInstruction: uint16 = system.ram[system.pc]
    currentInstruction = (currentInstruction shl 8) or system.ram[system.pc + 1]
    system.pc += 2

    let h = (currentInstruction and 0xF000) shr 12 # "high nibble", instruction
    let x = (currentInstruction and 0x0F00) shr 8 # looks up register
    let y = (currentInstruction and 0x00F0) shr 4 # looks up register
    let n = currentInstruction and 0x000F # 4-bit number
    let nn = currentInstruction and 0x00FF # 8-bit immediate number
    let nnn = currentInstruction and 0x0FFF # 12-bit imm. memory address
    case h
    of 0x0:
      case nnn
      of 0x0E0:
        # 00E0, clear screen
        for yCoord in 0..31:
          for xCoord in system.screen.mitems:
            xCoord[yCoord] = false
        continue
      of 0x0EE:
        # 00EE, subroutine return
        # TODO: underflow check
        system.pc = system.stack.pop()
        continue
      else:
        # 0NNN, machine language
        # echo(fmt"[W] Unknown machine language instruction. {currentInstruction:#06X}.")
        continue
    of 0x1:
      # 1NNN, jump
      system.pc = nnn
      continue
    of 0x2:
      # 2NNN, subroutine
      system.stack.add(system.pc)
      system.pc = nnn
      continue
    of 0x3:
      # 3XNN, skip instruction if vx == nn
      if system.varRegisters[x] == nn: system.pc += 2
      continue
    of 0x4:
      # 4XNN, skip instruction if vx != nn
      if system.varRegisters[x] != nn: system.pc += 2
      continue
    of 0x5:
      # 5XY0, skip instruction if vx == vy
      if system.varRegisters[x] == system.varRegisters[y]: system.pc += 2
      continue
    of 0x6:
      # 6XNN, set
      system.varRegisters[x] = nn.uint8
      continue
    of 0x7:
      # 7XNN, add
      # carry flag not affected
      system.varRegisters[x] += nn.uint8
      continue
    of 0x8:
      case n
      of 0x0:
        # 8XY0, set
        system.varRegisters[x] = system.varRegisters[y]
        continue
      of 0x1:
        # 8XY1, binary or
        system.varRegisters[x] = system.varRegisters[x] or system.varRegisters[y]
        if system.config.quirkCosmicFlagReset: system.varRegisters[0xF] = 0
        continue
      of 0x2:
        # 8XY2, binary and
        system.varRegisters[x] = system.varRegisters[x] and system.varRegisters[y]
        if system.config.quirkCosmicFlagReset: system.varRegisters[0xF] = 0
        continue
      of 0x3:
        # 8XY3, logical xor
        system.varRegisters[x] = system.varRegisters[x] xor system.varRegisters[y]
        if system.config.quirkCosmicFlagReset: system.varRegisters[0xF] = 0
        continue
      of 0x4:
        # 8XY4, add
        let value = system.varRegisters[x] + system.varRegisters[y]
        var flag: uint8
        if value < system.varRegisters[x]: flag = 1 else: flag = 0
        system.varRegisters[x] = value
        system.varRegisters[0xF] = flag
        continue
      of 0x5:
        # 8XY5, subtract
        var flag: uint8
        if system.varRegisters[x] >= system.varRegisters[y]: flag = 1 else: flag = 0
        system.varRegisters[x] -= system.varRegisters[y]
        system.varRegisters[0xF] = flag
        continue
      of 0x6:
        # 8XY6, shift right
        if system.config.quirkCosmicShifting: system.varRegisters[x] = system.varRegisters[y]
        let flag = system.varRegisters[x] and 0x1
        system.varRegisters[x] = system.varRegisters[x] shr 1
        system.varRegisters[0xF] = flag
        continue
      of 0x7:
        # 8XY7, subtract
        var flag: uint8
        if system.varRegisters[y] >= system.varRegisters[x]: flag = 1 else: flag = 0
        system.varRegisters[x] = system.varRegisters[y] - system.varRegisters[x]
        system.varRegisters[0xF] = flag
        continue
      of 0xE:
        # 8XYE, shift left
        if system.config.quirkCosmicShifting: system.varRegisters[x] = system.varRegisters[y]
        let flag = (system.varRegisters[x] and 0b10000000) shr 7
        system.varRegisters[x] = system.varRegisters[x] shl 1
        system.varRegisters[0xF] = flag
        continue
      else:
        system[].haltChip(fmt"Unknown instruction: {currentInstruction:#06X}.")
        return
    of 0x9:
      # 9XY0, skip instruction if vx != vy
      if system.varRegisters[x] != system.varRegisters[y]: system.pc += 2
      continue
    of 0xA:
      # ANNN, set index
      system.i = nnn
      continue
    of 0xB:
      # BNNN, jump with offset
      if system.config.quirkCosmicJumpWithOffset:
        system.pc = nnn + system.varRegisters[0]
      else:
        system.pc = nnn + system.varRegisters[x]
      continue
    of 0xC:
      # CXNN, random
      system.varRegisters[x] = rand(255).uint8 and nn.uint8
      continue
    of 0xD:
      # DXYN, display
      # TODO: Don't loop over a string lmao
      let destX = system.varRegisters[x] mod 64
      let destY = system.varRegisters[y] mod 32
      var tmpX: uint8
      var tmpY: uint8
      system.varRegisters[0xF] = 0
      for r in 1'u16..n:
        if (system.i + (r - 1)) > 4095: continue # Write outside of ram
        let currentRow = fmt"{system.ram[system.i + (r - 1)]:08b}"
        for b in currentRow:
          if not (((destX + tmpX) > 63) or ((destY + tmpY) > 31)):
            if (b == '1') and (system.screen[destX + tmpX][destY + tmpY] == true):
              # Collision
              system.screen[destX + tmpX][destY + tmpY] = false
              system.varRegisters[0xF] = 1
            elif (b == '1') and (system.screen[destX + tmpX][destY + tmpY] == false):
              # No collision
              system.screen[destX + tmpX][destY + tmpY] = true
          tmpX += 1
        tmpX = 0
        tmpY += 1
      if system.config.quirkCosmicDisplayWait: break else: continue
    of 0xE:
      # These should check the lower nibble.
      # TODO: Overflow protection
      case nn
      of 0x9E:
        # EX9E, skip if key is pressed
        # STUB
        continue
      of 0xA1:
        # EXA1, skip if key is not pressed
        # STUB
        continue
      else:
        # E???
        system[].haltChip(fmt"Unknown instruction: {currentInstruction:#06X}.")
        return
    of 0xF:
      case nn
      of 0x07:
        # FX07, set vx to delay timer
        system.varRegisters[x] = system.delayTimer
        continue
      of 0x15:
        # FX15, set delay timer to vx
        system.delayTimer = system.varRegisters[x]
        continue
      of 0x18:
        # FX18, set sound timer to vx
        system.soundTimer = system.varRegisters[x]
        continue
      of 0x1E:
        # FX1E, add to index
        # TODO: Overflow check quirk
        system.i += system.varRegisters[x]
        continue
      of 0x0A:
        # FX0A, get key
        # TODO: Cosmis quirk
        # STUB
        continue
      of 0x29:
        # FX29, font character
        if (system.varRegisters[x] and 0xF) <= 0xF:
          system.i = (system.varRegisters[x] and 0xF) * 5
        else:
          echo("[E] Tried drawing unknown font character.")
        continue
      of 0x33:
        # FX33, binary coded decimal conversion
        # TODO: overflow check (to not crash, not VF)
        if system.varRegisters[x] == 0:
          system.ram[system.i] = 0
        else:
          var bcd: seq[uint8]
          var tmp = system.varRegisters[x]
          while tmp > 0:
            bcd.add(tmp mod 10)
            tmp = floor(tmp.float / 10.0).uint8
          bcd.reverse()
          tmp = 0
          for d in bcd:
            try:
              system.ram[system.i + tmp] = d
            except IndexDefect:
              echo("[E] BCD tried writing outside of ram.")
            tmp += 1
        continue
      of 0x55:
        # FX55, varregisters -> memory
        var index: uint16
        for v in 0'u16..x:
          if system.config.quirkCosmicMemoryIndex: index = system.i else: index = system.i + v
          try:
            system.ram[index] = system.varRegisters[v]
          except IndexDefect:
            echo("[E] Register -> memory instruction tried writing outside of ram.")
          if system.config.quirkCosmicMemoryIndex: system.i += 1
        continue
      of 0x65:
        # FX65, memory -> varregisters
        var index: uint16
        for v in 0'u16..x:
          if system.config.quirkCosmicMemoryIndex: index = system.i else: index = system.i + v
          try:
            system.varRegisters[v] = system.ram[index]
          except IndexDefect:
            system.varRegisters[v] = 0x0 # Write a 0 instead, unsure if correct behavior.
            echo("[E] Memory -> register instruction tried reading outside of ram.")
          if system.config.quirkCosmicMemoryIndex: system.i += 1
        continue
      else:
        # F???
        system[].haltChip(fmt"Unknown instruction: {currentInstruction:#06X}.")
        return
    else:
      system[].haltChip(fmt"Unknown instruction: {currentInstruction:#06X}.")
      return
  
  # Done executing instructions, decrement the counters.

  if system.delayTimer > 0:
    system.delayTimer -= 1
  if system.soundTimer > 0:
    # resumeMusicStream(emulator.frontend.beep)
    system.soundTimer -= 1
  else:
    discard
    # pauseMusicStream(emulator.frontend.beep)

proc draw*(program: var ProgramState) =
  let system: ptr SystemState = program.systemState.addr
  # Use bool array to draw pixels
  for yCoord in 0..31:
    for xCoord in 0..63:
      if system.screen[xCoord][yCoord] == true:
        drawPixel(xCoord.int32, yCoord.int32, system.config.onColor)
      else:
        drawPixel(xCoord.int32, yCoord.int32, system.config.offColor)
