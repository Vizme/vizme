# vmi.origin.feedback.feedback-lib.coffee
# Vizme, Inc. (C)2011
# Scott Ernst

# targets vmi.api.VizmeAPI

# require vmi.util.exec.PageManager
# require vmi.util.display.Help
# require vmi.util.display.Response
# require vmi.origin.feedback.Feedback

#___________________________________________________________________________________________________ init
libraryInit = () ->
    pm = new PageManager('#container', 400, 640)
    pm.loadModule(Feedback, false)
    pm.loadModule(Response, false)
    pm.loadModule(Help,     false)
    pm.initializeComplete()

    VIZME.mod.feedback.show()
