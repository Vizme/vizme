# vmi.origin.author.author-lib.coffee
# Vizme, Inc. (C)2012
# Scott Ernst

# targets vmi.api.VizmeAPI

# require vmi.blog.author.BlogAuthor
# require vmi.util.exec.PageManager
# require vmi.util.display.Help
# require vmi.util.display.Response
# require vmi.util.dom.DOMUtils

#___________________________________________________________________________________________________ init
libraryInit = () ->
    pm  = new PageManager('#v-container', 400, 960)
    pm.loadModule(Help,     false)
    pm.loadModule(Response, false)
    pm.loadModule(BlogAuthor, false)
    pm.initializeComplete()
    VIZME.resize()
