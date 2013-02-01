# vizmeDefinition.coffee
# Vizme, Inc. (C)2012
# Scott Ernst

#---------------------------------------------------------------------------------------------------
# FUNCTION.BIND DEFINITION
#       This creates a bind method on functions if one does not exist, which is needed to bind
#       callback functions to a closure (scope) during the beach head loading process. This bind
#       definition was influenced heavily by the one available on the Mozilla developer network
#       function.bind documentation site.
if not Function.prototype.bind
    Function.prototype.bind = (oThis) ->
        aArgs   = Array.prototype.slice.call(arguments, 1)
        fToBind = this
        fNOP    = () ->
        fBound  = () ->
            return fToBind.apply(
                if (this instanceof fNOP && oThis) then this else oThis,
                aArgs.concat(Array.prototype.slice.call(arguments))
            )

        fNOP.prototype = this.prototype
        fBound.prototype = new fNOP()
        return fBound

#---------------------------------------------------------------------------------------------------
# VIZME BEACH HEAD
#       Creates temporary global VIZME access point, which can be used until the actual VizmeAPI has
#       has been created. For details on the various fields see vmi.api.VizmeAPI.
vm = {
    mod:{},
    r:[],
    _queue:[],
    SCRIPTS:false,
    CONFIG:{},
    TRC:[],
}
window.VIZME = vm

#___________________________________________________________________________________________________ VIZME.trace
vm.trace = (args...) ->
    window.VIZME.TRC.push(args)
    return

#___________________________________________________________________________________________________ VIZME.dispatchEvent
vm.dispatchEvent = (id, data, oneShot) ->
    ### A temporary dispatchEvent method that queues any events fired before the VizmeAPI has
        created the real VIZME object. Any queued events are then fired in the order they were
        received by the VIZME object during its initialization.
    ###
    window.VIZME._queue.push({t:'de', id:id, d:data, os:oneShot})
    return

#___________________________________________________________________________________________________ VIZME.addEventListener
vm.addEventListener = (id, callback) ->
    ### A temporary event listener registration method that queues the registration of event
        handlers until the VIZME object has been created.
    ###
    window.VIZME._queue.push({t:'el', id:id, cb:callback})
    return
