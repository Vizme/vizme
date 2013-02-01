# vmi.origin.contact.contact-lib.coffee
# Vizme, Inc. (C)2011
# Scott Ernst

# targets vmi.api.VizmeAPI

# require vmi.util.exec.PageManager
# require vmi.util.display.Help
# require vmi.util.display.Response
# require vmi.origin.contact.Contact

#___________________________________________________________________________________________________ init
libraryInit = () ->
    pm = new PageManager('#container', 400, 640)
    pm.loadModule(Contact,  false)
    pm.loadModule(Response, true)
    pm.loadModule(Help,     false)
    pm.initializeComplete()

    VIZME.mod.contact.show()
