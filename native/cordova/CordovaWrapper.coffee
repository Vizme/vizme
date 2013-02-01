# CordovaWrapper.coffee
# Vizme, Inc. (C)2012-2013
# Scott Ernst

# require vmi.util.Types

#___________________________________________________________________________________________________ CordovaWrapper
class CordovaWrapper

#===================================================================================================
#                                                                                       C L A S S

    @_PLUGIN_ID = 'Vizme'

    @_execIndex     = 0
    @_queue         = []
    @_queueInterval = null

#===================================================================================================
#                                                                                     P U B L I C

#___________________________________________________________________________________________________ freeze
    @freeze: (callback) ->
        return CordovaWrapper.exec(
            CordovaWrapper._PLUGIN_ID,
            'freeze',
            callback,
            null
        )

#___________________________________________________________________________________________________ unfreeze
    @unfreeze: (callback) ->
        return CordovaWrapper.exec(
            CordovaWrapper._PLUGIN_ID,
            'unfreeze',
            callback,
            null
        )

#___________________________________________________________________________________________________ initialize
    @initialize: (args, callback) ->
        me = CordovaWrapper
        d  = $(document)

        freeze = () ->
            me.freeze()
            VIZME.resizeEnable(false)
            return

        unfreeze = () ->
            me.unfreeze()
            VIZME.resizeEnable(true)
            return

        d.bind('pagebeforechange', freeze)
        d.bind('pagechange', unfreeze)
        d.bind('pagechangefailed', unfreeze)

        return me.exec(
            me._PLUGIN_ID,
            'initialize',
            callback,
            args
        )

#___________________________________________________________________________________________________ getData
    @getData: (key, callback) ->
        me = CordovaWrapper
        return me.exec(
            me._PLUGIN_ID,
            'getData',
            callback,
            {key:key},
            me._getDataSuccessCallback
        )

#___________________________________________________________________________________________________ getDataMany
    @getDataMany: (keys, callback) ->
        me = CordovaWrapper
        return me.exec(
            me._PLUGIN_ID,
            'getDataMany',
            callback,
            {keys:keys},
            me._getDataSuccessCallback
        )

#___________________________________________________________________________________________________ extractData
    @extractData: (key, callback) ->
        me = CordovaWrapper
        return me.exec(
            me._PLUGIN_ID,
            'extractData',
            callback,
            {key:key},
            me._getDataSuccessCallback
        )

#___________________________________________________________________________________________________ extractDataMany
    @extractDataMany: (keys, callback) ->
        me = CordovaWrapper
        return me.exec(
            me._PLUGIN_ID,
            'extractDataMany',
            callback,
            {keys:keys},
            me._getDataSuccessCallback
        )

#___________________________________________________________________________________________________ putData
    @putData: (key, value, callback) ->
        return CordovaWrapper.exec(
            CordovaWrapper._PLUGIN_ID,
            'putData',
            callback,
            {key:key, data:JSON.stringify({payload:value})}
        )

#___________________________________________________________________________________________________ putDataMany
    @putDataMany: (values, callback) ->
        return CordovaWrapper.exec(
            CordovaWrapper._PLUGIN_ID,
            'putDataMany',
            callback,
            {data:JSON.stringify({payload:values})}
        )

#___________________________________________________________________________________________________ removeData
    @removeData: (key, callback) ->
        return CordovaWrapper.exec(
            CordovaWrapper._PLUGIN_ID,
            'removeData',
            callback,
            {key:key}
        )

#___________________________________________________________________________________________________ removeDataMany
    @removeDataMany: (keys, callback) ->
        return CordovaWrapper.exec(
            CordovaWrapper._PLUGIN_ID,
            'removeDataMany',
            callback,
            {keys:keys}
        )

#___________________________________________________________________________________________________ clearAllData
    @clearAllData: (callback) ->
        return CordovaWrapper.exec(
            CordovaWrapper._PLUGIN_ID,
            'clearAllData',
            callback,
            null
        )

#___________________________________________________________________________________________________ sendResult
    @sendResult: (action, callback, args) ->
        return CordovaWrapper.exec(
            CordovaWrapper._PLUGIN_ID,
            'result',
            callback,
            [action, args]
        )

#___________________________________________________________________________________________________ exec
    @exec: (service, action, callback, args, successCB, errorCB) ->
        me = CordovaWrapper

        if not window.cordova
            me._queueExecution(service, action, callback, args)
            return

        index = me._execIndex++

        data = {
            index:index,
            service:service,
            action:action,
            callback:callback,
            args:args
        }

        success = if Types.isFunction(successCB) then successCB else me._successCallback
        success = success.bind(data)

        failure = if Types.isFunction(errorCB) then errorCB else me._errorCallback
        failure = failure.bind(data)

        try
            VIZME.trace('CORDOVA EXEC[' + index + ']: ' + service + '.' + action)
            window.cordova.exec(success, failure, service, action, [index, args])
        catch err
            VIZME.trace('CORDOVA EXEC ERROR[' + index + ']:' + service + '.' + action, err)
            me._errorCallback.bind(data)('ERROR: Cordova service not available.')
            return false

        return true

#===================================================================================================
#                                                                               P R O T E C T E D

#___________________________________________________________________________________________________ _queueExecution
    @_queueExecution: (service, action, callback, args) ->
        me = CordovaWrapper
        me._queue.push({service:service, action:action, callback:callback, args:args})
        if not me._queueInterval
            me._queueInterval = window.setInterval(me._handleQueueInterval, 250)
        return

#===================================================================================================
#                                                                                 H A N D L E R S

#___________________________________________________________________________________________________ _getDataSuccessCallback
    @_getDataSuccessCallback: (result) ->
        VIZME.trace('CordovaWrapper._getDataSuccessCallback')
        try
            result = JSON.parse(result).payload
        catch err
            VIZME.trace('ERROR[get/extract data parsing failure]: ' + result)
            result = null
        CordovaWrapper._successCallback.bind(this)(result)
        return

#___________________________________________________________________________________________________ _successCallback
    @_successCallback: (result) ->
        VIZME.trace('CordovaWrapper._successCallback')
        callback = this.callback
        if not Types.isFunction(callback)
            return

        delete this.callback
        this.success = true
        this.result  = result
        callback(this)
        return

#___________________________________________________________________________________________________ _errorCallback
    @_errorCallback: (error) ->
        callback = this.callback
        if not Types.isFunction(callback)
            return

        delete this.callback
        this.success = false
        this.error   = error
        callback(this)
        return

#___________________________________________________________________________________________________ _handleQueueInterval
    @_handleQueueInterval: () ->
        if not window.cordova
            return

        me = CordovaWrapper
        while me._queue.length > 0
            data = me._queue.shift()
            me.exec(data.service, data.action, data.callback, data.args)

        window.clearInterval(me._queueInterval)
        me._queueInterval = null
        return
