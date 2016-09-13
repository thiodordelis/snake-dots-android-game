--calculate the aspect ratio of the device:
local aspectRatio = display.pixelHeight / display.pixelWidth
display.setDefault( "background", 1, 1, 1,1)

application = {
   content = {
      width = aspectRatio > 1.5 and 320 or math.floor( 480 / aspectRatio ),
      height = aspectRatio < 1.5 and 480 or math.floor( 320 * aspectRatio ),
      scale = "letterBox",
      fps = 30,

      imageSuffix = {
         ["@2x"] = 1.5,
         ["@4x"] = 3.0,
      },
   },
}
