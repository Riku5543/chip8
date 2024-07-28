import raylib

proc newRectangle(x, y, width, height: float32): Rectangle =
  result.x = x
  result.y = y
  result.width = width
  result.height = height

proc main =
  initWindow(512, 256, "Raylib test")

  var owo = [Blue, Blue, Blue, Blue,
              Blue, White, Black, Blue,
              Blue, Black, White, Blue,
              Blue, Blue, Blue, Blue]
  var finalized = loadTextureFromData(owo, 4, 4)

  var roboto = loadFont("Roboto-Regular.ttf", 64, [])

  setTargetFPS(60)
  while not windowShouldClose():
    beginDrawing()
    clearBackground(RayWhite)
    drawTexture(finalized, newRectangle(0, 0, 4, 4), newRectangle(0, 0, 64, 64), Vector2(x:0,y:0), 0, White)
    drawText("Congrats etc.", 190, 200, 16, Black)
    drawText(roboto, "Roboto test", Vector2(x:40,y:30), Vector2(x:0,y:0), 0, 16, 0.5, Black)
    endDrawing()
  closeWindow()

main()
