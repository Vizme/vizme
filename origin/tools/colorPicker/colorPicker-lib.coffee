# colorPicker-lib.coffee
# Vizme, Inc. (C)2012
# Scott Ernst

# targets vmi.api.VizmeAPI

# require vmi.origin.tools.colorPicker.ColorPicker
# require vmi.util.exec.PageManager
# require vmi.util.display.Help
# require vmi.util.display.Response

#___________________________________________________________________________________________________ init
libraryInit = () ->
    pm  = new PageManager('#container', 400, 1280)

    pm.loadModule(Help,          false)
    pm.loadModule(Response,      false)
    pm.loadModule(ColorPicker,   false)

    pm.initializeComplete()
    VIZME.mod.colorPicker.show()
