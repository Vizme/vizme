# loadLibrary-exec.coffee
# Vizme, Inc. (C)2011
# Scott Ernst

#import vmi.util.exec.ExecutionManager
#import vmi.util.io.AJAXRequest

$ ->
    exec = new ExecutionManager()
    exec.initializeComplete()

    req = new AJAXRequest('test', 'share.php', AJAXRequest.JSON)
    
    handleLibraryLoaded = (e) ->
        alert('Library loaded!')

    $('#container').html('Loading library...')
    exec.loadLibrary('vmi.sandbox.loadLibrary.test-lib', handleLibraryLoaded)