# vmi.origin.editors.style.style-lib.coffee
# Vizme, Inc. (C)2012
# Scott Ernst

# targets vmi.api.VizmeAPI

# require vmi.origin.previews.theme.ThemePreview
# require vmi.util.exec.PageManager
# require vmi.util.display.Help
# require vmi.util.display.Response

#___________________________________________________________________________________________________ init
libraryInit = () ->
    pm = new PageManager('#v-container', 400, 1290)
    pm.loadModule(Help,        false)
    pm.loadModule(ThemePreview, true)
    pm.initializeComplete()

    VIZME.mod.themePreview.show()
    VIZME.resize()
