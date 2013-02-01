# vmi.util.io.CallbackManager
# Vizme, Inc. (C)2011
# Eric David Wills

# require vmi.util.Types

class CallbackManager

#===================================================================================================
#                                                                                       C L A S S
    
#___________________________________________________________________________________________________ constructor
# Creates a new instance of CallbackManager.
    constructor: () ->
        @_callbacks = {}

#===================================================================================================
#                                                                                     P U B L I C

#___________________________________________________________________________________________________ addCallback
# Adds the specified callback function with the specified type to this Loadable.
# @param callback The function called upon loading complete (e.g., foo(l:Loadable):void).
# @param type The type of the callback.
    addCallback: (callback, type) =>
        if not Types.isNone(callback)
            callbacks = @_callbacks[type]
            if Types.isNone(callbacks)
                callbacks         = []
                @_callbacks[type] = callbacks;
            callbacks.push(callback)

#___________________________________________________________________________________________________ removeCallback
# Cancels and removes the specified callback function of the specified type.
# @param callback The function to be removed.
# @param type The type of the callback.
    removeCallback: (callback, type) =>
        callbacks = @_callbacks[type]
        if not Types.isNone(callbacks)
            callbacks.splice(callbacks.indexOf(callback), 1);


#___________________________________________________________________________________________________ clearCallbacks
# Cancels and removes all callback functions of the specified type.
# @param type The type of the callback.
    clearCallbacks: (type) =>
        callbacks = @_callbacks[type]
        if not Types.isNone(callbacks)
            callbacks         = []
            @_callbacks[type] = callbacks;

#___________________________________________________________________________________________________ notifyCallbacks
# Call and remove all callback functions with the specified type.
# @param type The type of the callback.
# @param getArgumentFunction The function with signature foo(type:String):Object which
# returns the argument for the callback functions
# @param optionalArg An optional second argument that can be added to the callback.
    notifyCallbacks: (type, getArgumentFunction, optionalArg =null) =>
        callbacks = @_callbacks[type];
        if not Types.isNone(callbacks)
            if Types.isNone(optionalArg)
                while callbacks.length > 0
                    callbacks.pop()(getArgumentFunction(type))
            else
                while callbacks.length > 0
                    callbacks.pop()(getArgumentFunction(type), optionalArg)
