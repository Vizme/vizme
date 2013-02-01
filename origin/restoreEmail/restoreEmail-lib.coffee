# vmi.origin.restoreEmail.restoreEmail-lib.coffee
# Vizme, Inc. (C)2011
# Scott Ernst

# targets vmi.api.VizmeAPI

# require vmi.util.exec.PageManager
# require vmi.util.display.Help
# require vmi.util.display.Response
# require vmi.origin.restoreEmail.RestoreEmail

#___________________________________________________________________________________________________ init
libraryInit = () ->
    pm = new PageManager('#container', 400, 640)
    pm.loadModule(RestoreEmail, false)
    pm.loadModule(Response,     true)
    pm.loadModule(Help,         false)
    pm.initializeComplete()

    VIZME.mod.restoreEmail.show()
