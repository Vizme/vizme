# vmi.origin.editors.site.site-lib.coffee
# Vizme, Inc. (C)2012
# Scott Ernst

# targets vmi.api.VizmeAPI

# require vmi.origin.editors.site.SiteEditor
# require vmi.util.exec.PageManager
# require vmi.util.display.Help
# require vmi.util.display.Response

#___________________________________________________________________________________________________ init
libraryInit = () ->
    pm = new PageManager('#container', 400)
    pm.loadModule(Help,       false)
    pm.loadModule(Response,   true)
    pm.loadModule(SiteEditor, false)
    pm.initializeComplete()

    VIZME.mod.siteEditor.show()
    VIZME.resize()
