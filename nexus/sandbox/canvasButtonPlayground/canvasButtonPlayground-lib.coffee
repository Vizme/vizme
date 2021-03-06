# canvasButtonPlayground.coffee
# Vizme, Inc. (C)2012
# Scott Ernst

# targets vmi.api.VizmeAPI

# require vmi.util.exec.PageManager
# require vmi.util.display.Response
# require vmi.util.canvas.CanvasUtils

#___________________________________________________________________________________________________ init
libraryInit = () ->
    pm  = new PageManager('#container', 400, 640)
    pm.loadModule(Response, false)
    pm.initializeComplete()

    VIZME.resize()