# vmi.util.io.AJAXRequest
# Vizme, Inc. (C)2011-2012
# Scott Ernst

#import vmi.util.Types
#import vmi.util.url.URLUtils
#import vmi.util.string.StringUtils

# AJAX request class. Includes support for Cross Site Request Forgery protection using cookie
# matching.
#
# For Django apps using csrf AJAXRequest.djangoInit() must be called before making any AJAX requests
# to setup csrf for Django's protocol.
#
# For details see: https://docs.djangoproject.com/en/dev/ref/contrib/csrf/
class AJAXRequest

#===================================================================================================
#                                                                                       C L A S S

    @JSON  = 'json'
    @JSONP = 'jsonp'
    @XML   = 'xml'
    @HTML  = 'html'
    @TEXT  = 'text'

    @POST_METHOD = 'POST'
    @GET_METHOD  = 'GET'

    @_CSRF_TOKENS = [
        ['X-CSRFVizmeToken', 'vizmecsrf'],
        ['X-CSRFToken', 'csrftoken']
    ]

#___________________________________________________________________________________________________ constructor
# Creates a new instance of AJAXRequest.
# @param id         Identifier for the request (or null for no identifiers)
# @param scriptURI  Relative or full path to the AJAX request target. Relative paths are specified
#                   relative to the root domain URL, e.g. http://www.vizme.com/[relative_path...]
#                   and all requests must be made on the same domain (except for JSONP requests).
# @param dataType   Data type to be returned by the request
# @param callback   Function executed as callback with signature callback(AJAXRequest).
    constructor: (id, scriptURI, dataType, csrfProtect) ->
        @dataType = if dataType then dataType else AJAXRequest.TEXT
        @id       = id

        rURL = URLUtils.getURL()
        if StringUtils.startsWith(scriptURI, rURL)
            @url = scriptURI
        else if StringUtils.startsWith(scriptURI, 'http')
            @url = scriptURI
            if @dataType == AJAXRequest.JSON and not @_sameOrigin(@url)
                @dataType = AJAXRequest.JSONP
        else
            @url = rURL + scriptURI

        @data        = null
        @localData   = null
        @cache       = false
        @success     = false
        @requestUID  = URLUtils.createUniqueIdentifier()
        @response    = null
        @method      = AJAXRequest.POST_METHOD
        @csrfProtect = Types.isSet(csrfProtect) and csrfProtect

        @_cacheID         = null
        @_callback        = null
        @_prepareCallback = null
        @_jqXHR           = null

#===================================================================================================
#                                                                                   G E T / S E T

#___________________________________________________________________________________________________ GS: cacheID
    cacheID: (value) =>
        if Types.isSet(value)
            @_cacheID = value
            @cache    = not Types.isEmpty(value)

        return @_cacheID

#___________________________________________________________________________________________________ GS: timeout
    timeout: (value) =>
        if Types.isSet(value)
            @_timeout = value

        return @_timeout

#===================================================================================================
#                                                                                     P U B L I C

#___________________________________________________________________________________________________ request
# Executes the specified request with the given parameters.
# @param params - Object containing data parameters and values to be POSTed with the request.
# @param prepareCallback - Callback executed prior to sending the request, which can be used to
#                          modify the request before it is sent. Callback signature is:
#                          prepareCallback(this, [HTTPRequest Object], settings). The prepare
#                          callback is not valid in JSONP requests since JSONP does not conform to
#                          AJAX communication protocols.
    request: (params, callback, prepareCallback) =>
        @_callback = callback

        if @dataType == AJAXRequest.JSONP
            @_requestJSONP(params)
        else
            @_request(params, prepareCallback)

        return @requestUID

#===================================================================================================
#                                                                               P R O T E C T E D

#___________________________________________________________________________________________________ _request
    _request: (params, prepareCallback) =>
        if Types.isEmpty(params)
            params = {}

        params.ajaxid = @id

        if Types.isFunction(prepareCallback)
            @_prepareCallback = prepareCallback

        cmd = {
            type: @method,
            dataType: @dataType,
            url: @_getURL(),
            data: params,
            processData: true,
            cache: @cache,
            beforeSend: @_prepareRequest,
            success: @_handleSuccess,
            error: @_handleFailure
        }

        @_jqXHR = $.ajax(cmd)

#___________________________________________________________________________________________________ _requestJSONP
    _requestJSONP: (params) =>
        # Converts complex parameters into JSON notation for delivery through GET.
        if Types.isObject(params)
            data = {}
            for name,value of params
                if Types.isArray(value) or Types.isObject(value)
                    data[name] = JSON.stringify(value)
                else
                    data[name] = value
        else if Types.isEmpty(params)
            params = {}
        else
            data = params

        @_jqXHR = $.ajax({
            dataType: AJAXRequest.JSONP,
            url: @_getURL(),
            data: data,
            cache: @cache,
            success: @_handleJSONPSuccess,
            error: @_handleFailure,
        })

#___________________________________________________________________________________________________ _getURL
    _getURL: () =>
        url = @url
        if @cache and @_cacheID
            url += if url.indexOf('?') == -1 then '?' else '&'
            url += 'vmcacheid=' + encodeURIComponent(@_cacheID)

        return url

#___________________________________________________________________________________________________ _executeCallback
    _executeCallback: =>
        if Types.isFunction(@_callback)
            @_callback(this)

#___________________________________________________________________________________________________ _prepareRequest
    _prepareRequest: (request, settings) =>
        request.arcid = @requestUID

        if Types.isFunction(@_prepareCallback)
            @_prepareCallback(this, request, settings)

        # Adds CSRF tokens when appropriate
        if @csrfProtect and (not @_safeMethod(settings.type) or @_sameOrigin(settings.url))
            for csrf in AJAXRequest._CSRF_TOKENS
                request.setRequestHeader(csrf[0], @_getCookie(csrf[1]))

        return request

#___________________________________________________________________________________________________ _getCookie
    _getCookie: (name) =>
        cookieValue = null
        if document.cookie and document.cookie != ''
            cookies = document.cookie.split(';')
            for i in [0..cookies.length]
                cookie = $.trim(cookies[i])
                # Does this cookie string begin with the name we want?
                if cookie.substring(0, name.length + 1) == (name + '=')
                    cookieValue = decodeURIComponent(cookie.substring(name.length + 1))
                    break
        return cookieValue

#___________________________________________________________________________________________________ _sameOrigin
    _sameOrigin: (url) =>
        # url could be relative or scheme relative or absolute
        host       = document.location.host
        protocol   = document.location.protocol
        sr_origin  = '//' + host
        origin     = protocol + sr_origin

        # Allow absolute or scheme relative URLs to same origin
        # or any other URL that isn't scheme relative or absolute i.e relative.
        return (url == origin or url.slice(0, origin.length + 1) == origin + '/') or
               (url == sr_origin or url.slice(0, sr_origin.length + 1) == sr_origin + '/') or
               not (/^(\/\/|http:|https:).*/.test(url))

#___________________________________________________________________________________________________ _safeMethod
    _safeMethod: (method) =>
        return /^(GET|HEAD|OPTIONS|TRACE)$/.test(method)

#===================================================================================================
#                                                                                 H A N D L E R S

#___________________________________________________________________________________________________ _handleSuccess
    _handleSuccess: (data, status, response) =>
        @success  = true
        @data     = data
        @response = response
        @_executeCallback()

#___________________________________________________________________________________________________ _handleJSONPSuccess
    _handleJSONPSuccess: (data) =>
        @success  = true
        @data     = data
        @response = null
        @_executeCallback()

#___________________________________________________________________________________________________ _handleFailure
    _handleFailure: (request, status, response) =>
        @success  = false
        @response = response
        @_executeCallback()