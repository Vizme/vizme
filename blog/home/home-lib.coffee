# vmi.origin.home.home-lib.coffee
# Vizme, Inc. (C)2012
# Scott Ernst

# targets vmi.api.VizmeAPI

# require vmi.blog.home.BlogHome
# require vmi.util.exec.PageManager
# require vmi.util.display.Help
# require vmi.util.display.Response
# require vmi.util.dom.DOMUtils

#___________________________________________________________________________________________________ init
libraryInit = () ->
    pm  = new PageManager('#v-container', 400, 960, 0)
    pm.loadModule(Help,     false)
    pm.loadModule(Response, false)
    pm.loadModule(BlogHome, false)
    pm.initializeComplete()
    VIZME.resize()
