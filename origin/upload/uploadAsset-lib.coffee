# vmi.origin.upload.uploadAsset-lib.coffee
# Vizme, Inc. (C)2012
# Scott Ernst

# targets vmi.api.VizmeAPI

# require vmi.util.exec.PageManager
# require vmi.util.display.Help
# require vmi.util.display.Response
# require vmi.origin.upload.UploadAsset

#___________________________________________________________________________________________________ init
libraryInit = () ->
    pm  = new PageManager('#p-container', 400, 640)
    pm.loadModule(Help,          false)
    pm.loadModule(UploadAsset,   false)
    pm.loadModule(Response,      true)

    # Check for the various File API support.
    if window.File and window.FileReader and window.FileList and window.Blob
        VIZME.mod.uploadAsset.show()
    else
        $('.p-incompatible-browser').show()

    pm.initializeComplete()
