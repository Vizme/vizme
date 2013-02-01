# vmi.developers.docs.docs-lib.coffee
# Vizme, Inc. (C)2012
# Scott Ernst

# targets vmi.api.VizmeAPI

# require vmi.util.exec.PageManager
# require vmi.util.display.Help
# require vmi.util.display.Response
# require vmi.developers.Developers

#___________________________________________________________________________________________________ init
libraryInit = () ->
    pm = new PageManager('#container', 400, 910)
    pm.loadModule(Developers,    false)
    pm.loadModule(Help,          false)
    pm.loadModule(Response,      false)
    pm.initializeComplete()
    VIZME.resize()
