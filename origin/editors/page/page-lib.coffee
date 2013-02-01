# vmi.origin.editors.style.style-lib.coffee
# Vizme, Inc. (C)2012
# Scott Ernst

# targets vmi.api.VizmeAPI

# require vmi.origin.editors.page.PageEditor
# require vmi.util.exec.PageManager
# require vmi.util.display.Help
# require vmi.util.display.Response

#___________________________________________________________________________________________________ init
libraryInit = () ->
    pm = new PageManager('#container', 400)
    pm.loadModule(Help,       false)
    pm.loadModule(Response,   true)
    pm.loadModule(PageEditor, true)
    pm.initializeComplete()

    VIZME.mod.pageEditor.show()
    VIZME.resize()
    VIZME.mod.pageEditor.refresh()
