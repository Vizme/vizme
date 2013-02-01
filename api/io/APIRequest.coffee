# vmi.api.io.APIRequest
# Vizme, Inc. (C)2011-2012
# Scott Ernst

# import vmi.util.io.AJAXRequest

# require vmi.api.exec.APIManager
# require vmi.util.Types
# require vmi.util.hash.HashUtils
# require vmi.util.string.StringUtils
# require vmi.util.time.DataTimer
# require vmi.util.url.URLUtils

# AJAX Request class tailored specifically for handling API requests.
class APIRequest extends AJAXRequest

#===================================================================================================
#                                                                                       C L A S S

    # SCRIPT URI that overrides the default domain and directs the requests to the local domain.
    @scriptURI          = null
    @sessionID          = null
    @sessionCode        = null
    @loginID            = null
    @loginCode          = null
    @globalErrorHandler = null
    @requestIndex       = 1

    @_globalAlertHandler = null
    @_queuedGlobalAlert  = null

#___________________________________________________________________________________________________ constructor
    constructor: (category, id, extraParams, opts) ->
        @_apiCallback    = null
        @_extraParams    = extraParams
        @category        = category
        @identifier      = id
        @verified        = Types.isObject(extraParams) and extraParams['valid']
        @_args           = null
        @_retries        = 0

        # Create the URL for the request
        isSecure = not Types.isNull(APIRequest.scriptURI)
        url  = (if isSecure then URLUtils.getURL(APIRequest.scriptURI, true) else URLUtils.getDataURL())
        url += '/' + category + '/' + id

        # Use JSONP by default, but return JSON if running on an https site with a local API connection.
        mode = AJAXRequest.JSONP
        if not Types.isNull(@scriptURI) and URLUtils.isSecure()
            mode = AJAXRequest.JSON

        super('api-' + category + '-' + id, url, mode, false)

        @_timeout      = if opts and opts.timeout then opts.timeout else null
        @_timeoutTimer = null
        @_timedOut     = false

#===================================================================================================
#                                                                                   G E T / S E T

#___________________________________________________________________________________________________ GS: remoteWindow
    remoteWindow: () =>
        return if Types.isObject(@localData) then @localData.remoteWindow else null

#___________________________________________________________________________________________________ GS: requestMethodID
    requestMethodID: () =>
        return @category + '.' + @identifier

#___________________________________________________________________________________________________ GS: errorDOM
    errorDOM: () =>
        if Types.isNull(@data) or @success
            return ''

        return "<div class='v-apiError'><div class='v-apiErrorHeader'>#{@data.label}</div>" +
               "<div class='v-apiErrorMessage'>#{@data.message}</div></div>"

#===================================================================================================
#                                                                                     P U B L I C

#___________________________________________________________________________________________________ registerGlobalAlertHandler
    @registerGlobalAlertHandler: (callback) ->
        cls = APIRequest
        cls._globalAlertHandler = callback

        # Activates the queued alert if it exists. This is necessary for delayed assignment of the
        # callback where API calls, e.g. Session.create, can be made prior to the callback being
        # registered.
        request = cls._queuedGlobalAlert
        if Types.isFunction(callback) and request
            cls._queuedGlobalAlert = null
            callback(request.data.globalAlert, request)

#___________________________________________________________________________________________________ request
    request: (args, callback, prepareCallback) =>
        useSession = not Types.isEmpty(APIRequest.sessionID)
        useLogin   = not Types.isEmpty(APIRequest.loginID)
        params     = {}

        @_args = args
        if Types.isNone(args)
            args = {}

        if Types.isObject(@_extraParams)
            for name,value of @_extraParams
                params[name] = value

        params.i     = APIRequest.requestIndex++ + ''
        params.proto = window.location.protocol
        params.args  = JSON.stringify(args)
        params.csrf  = @_getCookie('vizmecsrf')
        params.tzOff = new Date().getTimezoneOffset()

        # Add signature
        text = @id + ';' + params.i + ';' + params.proto + ';' + params.args
        key  = ''
        if useSession
            params.s = APIRequest.sessionID
            key += APIRequest.sessionCode
        if useLogin
            params.l = APIRequest.loginID
            key += APIRequest.loginCode

        params.sg = HashUtils.sha256hmac(key, StringUtils.encode64(text))

        if @dataType == AJAXRequest.JSONP
            VIZME.trace("API: #{@category}.#{@identifier}", params)
        super(params, callback)
        @_startTimeout()

#___________________________________________________________________________________________________ getProtectedPasswordHash
# Returns the 'protected' hash for the src string, which is the hashed src
    @getProtectedPasswordHash: (src) ->
        text = HashUtils.sha256(src) + APIRequest.requestIndex
        return HashUtils.sha256hmac(APIRequest.getHmacKey(), StringUtils.encode64(text))

#___________________________________________________________________________________________________ getHmacKey
    @getHmacKey: () ->
        key = ''
        if not Types.isEmpty(APIRequest.sessionID)
            key += APIRequest.sessionCode
        if not Types.isEmpty(APIRequest.loginID)
            key += APIRequest.loginCode
        return key

#===================================================================================================
#                                                                               P R O T E C T E D

#___________________________________________________________________________________________________ _stopTimeout
    _stopTimeout: () =>
        if not @_timeoutTimer
            return false

        @_timeoutTimer.stop()
        @_timeoutTimer = null

        return true

#___________________________________________________________________________________________________ _startTimeout
    _startTimeout: () =>
        if not @_timeout or @_timeoutTimer
            return false

        @_timeoutTimer = new DataTimer(@_timeout + 500, 1, null, @_handleTimeout)
        @_timeoutTimer.start()
        return true

#___________________________________________________________________________________________________ _processResult
    _processResult: (data) =>
        cls       = APIRequest
        @success  = not Types.isSet(data.error)
        @data     = data

        # Populate config values with result
        if data.CONFIG
            for n,v of data.CONFIG
                VIZME.CONFIG[n] = v

        propagate = true
        if not @success and data and data.retry and @_retries < 3
            @_retries++
            @request(@_args, @_callback)
            return

        if not @success and Types.isSet(data.global)
            if Types.isFunction(cls.globalErrorHandler)
                propagate = cls.globalErrorHandler(this)
            else
                propagate = cls._defaultGlobalErrorHandler(this)

        if Types.isSet(data.globalAlert)
            if Types.isFunction(cls._globalAlertHandler)
                cls._globalAlertHandler(data.globalAlert, this)
            else
                cls._queuedGlobalAlert = this

        if Types.isSet(data.empty)
            propagate = data.prop

        if propagate
            @_executeCallback()

        # Resize after any response that included a DOM
        VIZME.resize()

#___________________________________________________________________________________________________ _defaultGlobalErrorHandler
    @_defaultGlobalErrorHandler: (request) ->
        return true

#===================================================================================================
#                                                                                 H A N D L E R S

#___________________________________________________________________________________________________ _handleSuccess
    _handleSuccess: (data, status, response) =>
        @_stopTimeout()
        if @_timedOut
            return

        @response = response
        @_processResult(data)

#___________________________________________________________________________________________________ _handleJSONPSuccess
    _handleJSONPSuccess: (data) =>
        @_stopTimeout()
        if @_timedOut
            return

        @response = null
        @_processResult(data)

#___________________________________________________________________________________________________ _handleTimeout
    _handleTimeout: (dt) =>
        @_jqXHR.abort()

        @_timedOut     = true
        @success       = false
        @_timeoutTimer = null

        @_executeCallback()
