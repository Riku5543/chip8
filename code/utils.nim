import raylib

import types

proc getCenter*(imageRes, objectRes: Resolution): Position =
  result.x = (imageRes.w div 2) - (objectRes.w div 2)
  result.y = (imageRes.h div 2) - (objectRes.h div 2)

proc drawCenteredText*(text: cstring, size: int32, color: Color, imageRes: Resolution) =
  var textSize: Resolution
  textSize.h = measureText(getFontDefault(), text, size.float32, 0).y.int32
  textSize.w = measureText(text, size)
  let textPos = getCenter(imageRes, textSize)
  drawText(text, textPos.x, textPos.y, size, color)

proc ramSequentialWrite*(ram: var openArray[uint8], address: uint16, data: openArray[uint8]): uint16 =
  # Returns the next address
  result = address
  for b in data:
    ram[result] = b
    result += 1
