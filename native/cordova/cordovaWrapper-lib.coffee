# cordovaWrapper-lib.coffee
# Vizme, Inc. (C)2012
# Scott Ernst

# targets vmi.api.VizmeAPI

# require vmi.native.cordova.CordovaWrapper

onLoaded = () ->
    VIZME.cordova = CordovaWrapper
    VIZME.dispatchEvent('NATIVE:cordova', null, true)
    return

VIZME.addEventListener('API:loaded', onLoaded)
