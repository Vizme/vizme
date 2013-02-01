# vmi.origin.info.tour.tour-lib.coffee
# Vizme, Inc. (C)2012
# Scott Ernst

# targets vmi.api.VizmeAPI

# require vmi.util.exec.PageManager
# require vmi.util.display.Help
# require vmi.util.display.Response

#___________________________________________________________________________________________________ init
libraryInit = () ->
    pm  = new PageManager('#v-container', 400, 5000, 0)

    pm.loadModule(Help,          false)
    pm.loadModule(Response,      true)
    pm.initializeComplete()
    VIZME.resize()
