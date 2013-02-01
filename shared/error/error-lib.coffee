# vmi.shared.error.error-lib.coffee
# Vizme, Inc. (C)2012
# Scott Ernst

# targets vmi.api.VizmeAPI

# require vmi.shared.error.Error
# require vmi.util.exec.PageManager
# require vmi.util.display.Help
# require vmi.util.display.Response

#___________________________________________________________________________________________________ init
libraryInit = () ->
    pm = new PageManager('#container', 320, 3000, 0)
    pm.loadModule(Error,    false)
    pm.loadModule(Response, false)
    pm.loadModule(Help,     false)
    pm.initializeComplete()

    VIZME.mod.error.show()
    pm.initializeComplete()
    $('#container').show()
    VIZME.resize()
