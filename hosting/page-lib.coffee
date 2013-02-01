# vmi.origin.previews.webpage.webpage-lib.coffee
# Vizme, Inc. (C)2012
# Scott Ernst

# targets vmi.api.VizmeAPI

# require vmi.shared.vml.webpage.Webpage
# require vmi.util.exec.PageManager
# require vmi.util.display.Help
# require vmi.util.display.Response

#___________________________________________________________________________________________________ init
libraryInit = () ->
    sp = if PAGE.GUTTER then 25 else 0
    pm = new PageManager('#v-container', 400, PAGE.MAX_WEBPAGE_WIDTH, sp)
    pm.loadModule(Help,   false)
    pm.loadModule(Webpage, false)
    pm.initializeComplete()

    VIZME.mod.webpage.show()
    VIZME.resize()
