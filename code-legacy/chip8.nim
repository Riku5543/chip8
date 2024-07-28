import strformat
import math
import random
import algorithm

import objects

proc haltChip(system: var System, msg: string) =
  echo(fmt"[X] {msg} Machine will now halt.")
  system.halted = true

proc runChip8*(emulator: var Emulator) =
  for _ in 1'u8..emulator.config.instructionsPerFrame:
    if (emulator.system.pc > 4095) or (emulator.system.pc + 1) > 4095:
      emulator.system.haltChip("Tried to execute instructions outside of ram.")
      break
    var currentInstruction: uint16 = emulator.system.ram[emulator.system.pc]
    currentInstruction = (currentInstruction shl 8) or emulator.system.ram[emulator.system.pc + 1]
    emulator.system.pc += 2

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
          for xCoord in emulator.system.screen.mitems:
            xCoord[yCoord] = false
      of 0x0EE:
        # 00EE, subroutine return
        # TODO: Underflow check
        emulator.system.pc = emulator.system.stack.pop()
      else:
        # 0NNN, machine language
        echo("[W] Encountered machine language instruction, skipping it.")
        # discard
    of 0x1:
      # 1NNN, jump
      emulator.system.pc = nnn
    of 0x2:
      # 2NNN, subroutine
      emulator.system.stack.add(emulator.system.pc)
      emulator.system.pc = nnn
    of 0x3:
      # 3XNN, skip instruction if vx == nn
      if emulator.system.varRegisters[x] == nn:
        emulator.system.pc += 2
    of 0x4:
      # 4XNN, skip instruction if vx != nn
      if emulator.system.varRegisters[x] != nn:
        emulator.system.pc += 2
    of 0x5:
      # 5XY0, skip instruction if vx == vy
      if emulator.system.varRegisters[x] == emulator.system.varRegisters[y]:
        emulator.system.pc += 2
    of 0x6:
      # 6XNN, set
      emulator.system.varRegisters[x] = nn.uint8
    of 0x7:
      # 7XNN, add
      # carry flag not affected
      emulator.system.varRegisters[x] += nn.uint8
    of 0x8:
      case n
      of 0x0:
        # 8XY0, set
        emulator.system.varRegisters[x] = emulator.system.varRegisters[y]
      of 0x1:
        # 8XY1, binary or
        emulator.system.varRegisters[x] = emulator.system.varRegisters[x] or emulator.system.varRegisters[y]
        if emulator.config.quirkCosmicFlagReset:
          emulator.system.varRegisters[0xF] = 0
      of 0x2:
        # 8XY2, binary and
        emulator.system.varRegisters[x] = emulator.system.varRegisters[x] and emulator.system.varRegisters[y]
        if emulator.config.quirkCosmicFlagReset:
          emulator.system.varRegisters[0xF] = 0
      of 0x3:
        # 8XY3, logical xor
        emulator.system.varRegisters[x] = emulator.system.varRegisters[x] xor emulator.system.varRegisters[y]
        if emulator.config.quirkCosmicFlagReset:
          emulator.system.varRegisters[0xF] = 0
      of 0x4:
        # 8XY4, add
        let value = emulator.system.varRegisters[x] + emulator.system.varRegisters[y]
        var flag: uint8
        if value < emulator.system.varRegisters[x]:
          # overflow
          flag = 1
        else:
          flag = 0
        emulator.system.varRegisters[x] = value
        emulator.system.varRegisters[0xF] = flag
      of 0x5:
        # 8XY5, subtract
        var flag: uint8
        if emulator.system.varRegisters[x] >= emulator.system.varRegisters[y]:
          flag = 1
        else:
          flag = 0
        emulator.system.varRegisters[x] -= emulator.system.varRegisters[y]
        emulator.system.varRegisters[0xF] = flag
      of 0x6:
        # 8XY6, shift right
        if emulator.config.quirkCosmicShifting:
          emulator.system.varRegisters[x] = emulator.system.varRegisters[y]
        let flag = emulator.system.varRegisters[x] and 0x1
        emulator.system.varRegisters[x] = emulator.system.varRegisters[x] shr 1
        emulator.system.varRegisters[0xF] = flag
      of 0x7:
        # 8XY7, subtract
        var flag: uint8
        if emulator.system.varRegisters[y] >= emulator.system.varRegisters[x]:
          flag = 1
        else:
          flag = 0
        emulator.system.varRegisters[x] = emulator.system.varRegisters[y] - emulator.system.varRegisters[x]
        emulator.system.varRegisters[0xF] = flag
      of 0xE:
        # 8XYE, shift left
        if emulator.config.quirkCosmicShifting:
          emulator.system.varRegisters[x] = emulator.system.varRegisters[y]
        let flag = (emulator.system.varRegisters[x] and 0b10000000) shr 7 # Bit that's about to get shifted out
        emulator.system.varRegisters[x] = emulator.system.varRegisters[x] shl 1
        emulator.system.varRegisters[0xF] = flag
      else:
        emulator.system.haltChip(fmt"Unknown instruction: {currentInstruction:#06X}.")
        break
    of 0x9:
      # 9XY0, skip instruction if vx != vy
      if emulator.system.varRegisters[x] != emulator.system.varRegisters[y]:
        emulator.system.pc += 2
    of 0xA:
      # ANNN, set index
      emulator.system.i = nnn
    of 0xB:
      # BNNN, jump with offset
      if emulator.config.quirkCosmicJumpWithOffset:
        emulator.system.pc = nnn + emulator.system.varRegisters[0]
      else:
        # BXNN
        emulator.system.pc = nnn + emulator.system.varRegisters[x]
    of 0xC:
      # CXNN, random
      emulator.system.varRegisters[x] = uint8(rand(255)) and nn.uint8
    of 0xD:
      # DXYN, display
      let destX = emulator.system.varRegisters[x] mod 64
      let destY = emulator.system.varRegisters[y] mod 32
      var tmpX: uint8
      var tmpY: uint8
      emulator.system.varRegisters[0xF] = 0
      for r in 1'u16..n:
        if (emulator.system.i + (r - 1)) > 4095:
          # echo("[W] Display tried to write outside of ram.")
          continue
        let currentRow = fmt"{emulator.system.ram[emulator.system.i + (r - 1)]:08b}"
        for b in currentRow:
          if not (((destX + tmpX) > 63) or ((destY + tmpY) > 31)):
            if (b == '1') and (emulator.system.screen[destX + tmpX][destY + tmpY] == true):
              # Collision
              emulator.system.screen[destX + tmpX][destY + tmpY] = false
              emulator.system.varRegisters[0xF] = 1
            elif (b == '1') and (emulator.system.screen[destX + tmpX][destY + tmpY] == false):
              # No collision
              emulator.system.screen[destX + tmpX][destY + tmpY] = true
            # else bit was 0, so nothing to do
          # else:
          #   echo("[W] Tried drawing out of bounds.")
          tmpX += 1
        tmpX = 0
        tmpY += 1
      if emulator.config.quirkCosmicDisplayWait:
        break
    of 0xE:
      # These should check the lower nibble.
      # TODO: Overflow protection
      case nn
      of 0x9E:
        # EX9E, skip if key is pressed
        let key = emulator.system.varRegisters[x] and 0xF # Lower nibble
        if emulator.frontend.allowedKeys[key] in emulator.frontend.heldKeys:
          emulator.system.pc += 2
      of 0xA1:
        # EXA1, skip if key is not pressed
        let key = emulator.system.varRegisters[x] and 0xF # Lower nibble
        if not (emulator.frontend.allowedKeys[key] in emulator.frontend.heldKeys):
          emulator.system.pc += 2
      else:
        # E???
        emulator.system.haltChip(fmt"Unknown instruction: {currentInstruction:#06X}.")
        break
    of 0xF:
      case nn
      of 0x07:
        # FX07, set vx to delay timer
        emulator.system.varRegisters[x] = emulator.system.delayTimer
      of 0x15:
        # FX15, set delay timer to vx
        emulator.system.delayTimer = emulator.system.varRegisters[x]
      of 0x18:
        # FX18, set sound timer to vx
        emulator.system.soundTimer = emulator.system.varRegisters[x]
      of 0x1E:
        # FX1E, add to index
        # TODO: Overflow check quirk
        emulator.system.i += emulator.system.varRegisters[x]
      of 0x0A:
        # FX0A, get key
        # TODO: Cosmic quirk
        if emulator.frontend.justReleasedKeys.len == 0:
          emulator.system.pc -= 2
        else: 
          # Only first key in the array is put here, this may
          # cause trouble.
          emulator.system.varRegisters[x] = emulator.frontend.allowedKeys.find(emulator.frontend.justReleasedKeys[0]).uint8
      of 0x29:
        # FX29, font character
        if (emulator.system.varRegisters[x] and 0xF) <= 0xF:
          emulator.system.i = (emulator.system.varRegisters[x] and 0xF) * 5
        else:
          echo("[E] Tried drawing unknown font character.")
          # system.i = 0x50 # Whatever is after font storage, may not be correct behavior.
      of 0x33:
        # FX33, binary coded decimal conversion
        # TODO: overflow check (to not crash, not VF)
        if emulator.system.varRegisters[x] == 0:
          emulator.system.ram[emulator.system.i] = 0
        else:
          var bcd: seq[uint8]
          var tmp = emulator.system.varRegisters[x]
          while tmp > 0:
            bcd.add(tmp mod 10)
            tmp = floor(tmp.float / 10.0).uint8
          bcd.reverse()
          tmp = 0
          for d in bcd:
            try:
              emulator.system.ram[emulator.system.i + tmp] = d
            except IndexDefect:
              echo("[E] BCD tried writing outside of ram.")
            tmp += 1
      of 0x55:
        # FX55, varRegisters -> memory
        var index: uint16
        for v in 0'u16..x:
          if emulator.config.quirkCosmicMemoryIndex:
            index = emulator.system.i
          else:
            index = emulator.system.i + v
          try:
            emulator.system.ram[index] = emulator.system.varRegisters[v]
          except IndexDefect:
            echo("[E] Register -> memory instruction tried writing outside of ram.")
          if emulator.config.quirkCosmicMemoryIndex:
            emulator.system.i += 1
      of 0x65:
        # FX65, memory -> varRegisters
        var index: uint16
        for v in 0'u16..x:
          if emulator.config.quirkCosmicMemoryIndex:
            index = emulator.system.i
          else:
            index = emulator.system.i + v
          try:
            emulator.system.varRegisters[v] = emulator.system.ram[index]
          except IndexDefect:
            emulator.system.varRegisters[v] = 0x0 # Write a 0 instead, unsure if correct behavior.
            echo("[E] Memory -> register instruction tried reading outside of ram.")
          if emulator.config.quirkCosmicMemoryIndex:
            emulator.system.i += 1
      else:
        # F???
        emulator.system.haltChip(fmt"Unknown instruction: {currentInstruction:#06X}.")
        break
    else:
      emulator.system.haltChip(fmt"Unknown instruction: {currentInstruction:#06X}.")
      break
