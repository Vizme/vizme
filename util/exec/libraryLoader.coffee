# libraryLoader.coffee
# Vizme, Inc. (C)2012
# Scott Ernst

##MODULES##
VIZME.exec.libraryReady('##LIBNAME##')
if typeof(libraryInit) == 'function'
    VIZME.addEventListener('API:complete', libraryInit)
