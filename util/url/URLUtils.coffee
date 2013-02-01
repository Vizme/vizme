# vmi.util.url.URLUtils.coffee
# Vizme, Inc. (C)2011-2012
# Scott Ernst

# require vmi.util.Types
# require vmi.util.color.ColorMixer

#___________________________________________________________________________________________________ URLUtils
class URLUtils
    ### Utilities class for URL related operations.###

#===================================================================================================
#                                                                                       C L A S S

    @VIZME_DOMAIN    = 'vizme.com'
    @_LOADING_IMAGE  = 'load/#T/#B/#F'

#===================================================================================================
#                                                                                     P U B L I C

#___________________________________________________________________________________________________ createUniqueIdentifier
# Creates a unique identifier string that is based on the time down to the millisecond with a
# randomized suffix to prevent collisions for multiple identifiers at the same time.
    @createUniqueIdentifier: () ->
        d    = new Date()
        uid  = '' + d.getHours() + d.getMinutes() + d.getSeconds() + d.getMilliseconds()
        return uid + Math.floor(Math.random() * 10000)

#___________________________________________________________________________________________________ createAbsoluteURL
# Modifies relative URLs to be absolute on the current domain. If the url argument is already
# absolute the URL is returned unchanged.
    @createAbsoluteURL: (url) ->
        root = URLUtils.getURL()

        # Don't modify if the URL is already absolute.
        if root.indexOf(url) == 0
            return url
        else if url.substr(0,1) == '/'
            return root + url.substr(1)

        return root + url

#___________________________________________________________________________________________________ getLoadingURL
# Gets a page that acts as nothing but a loader.
    @getLoadingURL: () ->
        return URLUtils.createAbsoluteURL('/load')

#___________________________________________________________________________________________________ getLoadingImageURL
# Gets the loading image URL.
    @getLoadingImageURL: (color, backColor, small) ->
        type = if small then 'sr' else 'mr'

        if Types.isString(color)
            front = new ColorMixer(front)
            back  = if Types.isString(backColor) then new ColorMixer(backColor) else null
        else if Types.isSet(color)
            target = $(color)
            front  = new ColorMixer(target.css('color'))

            # Recurse through parents to find the correct background color
            parent  = target
            while parent and parent.length > 0
                back = new ColorMixer(parent.css('background-color'))
                if back.alpha() == 0
                    if parent.is('html')
                        back = new ColorMixer('#FFF')
                        break

                    parent = parent.parent()
                else
                    break
        else
            front = null
            back  = null

        cls = URLUtils
        return cls.getImageURL(cls._LOADING_IMAGE.
                               replace('#B', if back then back.bareHex() else '~').
                               replace('#F', if front then front.bareHex() else '~').
                               replace('#T', type))

#___________________________________________________________________________________________________ isSecure
# Specifies whether or not the site is running under https security.
    @isSecure: () ->
        return location.protocol == 'https:'

#___________________________________________________________________________________________________ getURL
# Returns the root domain URL for the current location.
    @getURL: (scriptURI, secure) ->
        cls = URLUtils
        return cls._getProtocol(secure) + location.hostname + cls._getScriptURI(scriptURI)

#___________________________________________________________________________________________________ getImageURL
# Returns the data domain URL for JSONP data access.
    @getImageURL: (scriptURI) ->
        cls = URLUtils
        domain = VIZME.CONFIG.IMAGE_DOMAIN
        if not domain
            domain = VIZME.DOMAINS.IMAGE

        return cls._getProtocol() + domain + cls._getScriptURI(scriptURI)

#___________________________________________________________________________________________________ getDataURL
# Returns the data domain URL for JSONP data access.
    @getDataURL: (scriptURI) ->
        cls = URLUtils
        domain = VIZME.CONFIG.DATA_DOMAIN
        if not domain
            domain = VIZME.DOMAINS.DATA

        return cls._getProtocol(true) + domain + cls._getScriptURI(scriptURI)

#___________________________________________________________________________________________________ getJSURL
# Returns the root data domain URL for JSONP data access.
    @getJSURL: (scriptURI) ->
        cls = URLUtils
        domain = VIZME.CONFIG.JS_DOMAIN
        if not domain
            domain = VIZME.DOMAINS.JS

        return cls._getProtocol() + domain + cls._getScriptURI(scriptURI)

#___________________________________________________________________________________________________ getWebAppURL
# Returns the root data domain URL for JSONP data access.
    @getWebAppURL: (scriptURI) ->
        cls = URLUtils
        domain = VIZME.CONFIG.WEB_DOMAIN
        if not domain
            domain = VIZME.DOMAINS.WEB

        return cls._getProtocol() + domain + cls._getScriptURI(scriptURI)

#___________________________________________________________________________________________________ getCSSURL
# Returns the root data domain URL for JSONP data access.
    @getCSSURL: (scriptURI) ->
        cls = URLUtils
        domain = VIZME.CONFIG.CSS_DOMAIN
        if not domain
            domain = VIZME.DOMAINS.CSS

        return cls._getProtocol() + domain + cls._getScriptURI(scriptURI)

#___________________________________________________________________________________________________ getURLFromDomain
# Returns the root domain URL for the specified domain.
    @getURLFromDomain: (domain, scriptURI, secure) ->
        cls = URLUtils
        return cls._getProtocol(secure) + domain + cls._getScriptURI(scriptURI)

#___________________________________________________________________________________________________ createCacheString
# Creates a cache string, either random or versioned depending on the server deployment status,
# which can be used to manage caching on URL requests.
    @createCacheString: (forceRandom) ->
        if forceRandom
            return URLUtils.createUniqueIdentifier()

        v  = VIZME.CONFIG.VERSION
        r  = VIZME.CONFIG.REVISION
        cs = (if v then v else VIZME.VERSION) + '-' + (if r then r else VIZME.REVISION)
        if PAGE
            if PAGE.CLOUD_SIG
                return PAGE.CLOUD_SIG
            else if PAGE.DEV
                d = new Date()
                return cs + '-' + Math.floor(d.getTime() / 300.0)

        return cs

#___________________________________________________________________________________________________ createCacheSignature
# Creates a cache signature to append to a URL for cache control.
    @createCacheSignature: () ->
        return 'nocache=' + URLUtils.createCacheString(false)


#===================================================================================================
#                                                                               P R O T E C T E D

#___________________________________________________________________________________________________ _getProtocol
    @_getProtocol: (secure) ->
        if not Types.isSet(secure)
            p = location.protocol.replace(':', '')
            if p == 'file'
                p = 'http'
        else
            p = if secure then 'https' else 'http'
        return p + '://'

#___________________________________________________________________________________________________ _getScriptURI
    @_getScriptURI: (scriptURI) ->
        if not scriptURI
            scriptURI = '/'
        else if scriptURI.substr(0,1) != '/'
            scriptURI = '/' + scriptURI

        return scriptURI

