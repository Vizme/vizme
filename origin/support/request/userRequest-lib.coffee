# vmi.origin.support.request.userRequest-lib.coffee
# Vizme, Inc. (C)2012
# Scott Ernst

# targets vmi.api.VizmeAPI

# require vmi.util.exec.PageManager
# require vmi.util.display.Help
# require vmi.util.display.Response
# require vmi.origin.support.request.UserRequest

#___________________________________________________________________________________________________ init
libraryInit = () ->
    pm = new PageManager('#container', 400, 640)
    pm.loadModule(UserRequest, false)
    pm.loadModule(Response,    true)
    pm.loadModule(Help,        false)
    pm.initializeComplete()

    VIZME.mod.userRequest.show()
