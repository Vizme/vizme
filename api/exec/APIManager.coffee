# vmi.api.exec.APIManager.coffee
# Vizme, Inc. (C)2011-2012
# Scott Ernst

# import vmi.util.exec.ExecutionManager
# require vmi.api.data.DataManager
# require vmi.api.display.IconManager
# require vmi.api.display.StyleManager
# require vmi.api.enum.AttrEnum
# require vmi.api.io.APIRequest
# require vmi.api.render.Renderer
# require vmi.api.render.ElementRenderer
# require vmi.api.render.static.VMLStaticRenderer
# require vmi.util.ArrayUtils
# require vmi.util.ObjectUtils
# require vmi.util.Types
# require vmi.util.color.ColorMixer
# require vmi.util.debug.Logger
# require vmi.util.io.AJAXRequest
# require vmi.util.string.StringUtils
# require vmi.util.time.DataTimer
# require vmi.util.url.URLUtils

#___________________________________________________________________________________________________ APIManager
class APIManager extends ExecutionManager
    ### The APIManager class is the main executive class for managing the VIZME API. The actual
        VIZME API Class, VizmeAPI, is really just a lightwight public wrapper around the APIManager
        class. The API Manager class is responsible for initializing the API and handling all of the
        library and render functions within the page.
    ###

#===================================================================================================
#                                                                                       C L A S S

    @ID      = 'api'

    @appID   = ''
    @profile = null

#___________________________________________________________________________________________________ constructor
    constructor: () ->
        ### Creates an APIManager module instance. ###

        super(APIManager.ID)

        @_renderLoopTimer = new DataTimer(200, 1, false, @_handleRenderLoop)
        @_mouseState      = null

        @styles      = new StyleManager()
        @icons       = new IconManager()
        @data        = new DataManager()
        @vmlRender   = new VMLStaticRenderer()
        @displayType = -1

        @_modules           = {}
        @_renderers         = {}
        @_autoResizers      = []
        @_libraryCallbacks  = []
        @_loadedLibraries   = []
        @_loadingLibraries  = if PAGE then PAGE.RLIBS else []
        @_renderCallbacks   = {}
        @_queuedAPIRequests = []
        @_oneShotEvents     = []
        @_pageLoading       = true
        @_resizeEnable      = true

        @_scroller = $('.v-scrollContainer')

        # Enable smart resizing of modules.
        win = $(window)
        win.resize(@_handleResize)

        cb = @_handleMouseEvent
        doc = $(document)
        doc.mousedown(cb)
        doc.mouseup(cb)
        doc.mouseleave(cb)
        doc.mouseout(cb)

        @requestCode          = null
        @args                 = {}
        @_sessionCallback     = null
        @_eventCallbacks      = {}
        @_mousePos            = {x:0, y:0}

        $('body').mousemove(@_handleUpdateMousePosition)


#===================================================================================================
#                                                                                   G E T / S E T

#___________________________________________________________________________________________________ mouse
    mouse: () =>
        ### The APIManager stores the mouse position globally for the lifetime of the application
            as a centeral access point for the lastest position information for popup placement.
        ###

        return @_mousePos

#___________________________________________________________________________________________________ resizeEnable
    resizeEnable: (value) =>
        if Types.isSet(value)
            pre            = @_resizeEnable
            @_resizeEnable = if value then true else false
            if not pre and value
                @resize()

        return @_resizeEnable

#===================================================================================================
#                                                                                     P U B L I C

#___________________________________________________________________________________________________ init
    init: (requestCode, args, destinationScriptURI) =>
        @initialize()

        @requestCode = requestCode

        if args
            @args        = args
            @displayType = ObjectUtils.get(args, 'displayType', -1)

        if not Types.isEmpty(destinationScriptURI)
            APIRequest.scriptURI = destinationScriptURI

        return true

#___________________________________________________________________________________________________ executeAPIRequest
    executeAPIRequest: (category, identifier, args, callback, localData, force, cacheID, opts) =>
        if VIZME.LOADED or force
            req           = new APIRequest(category, identifier, null, opts)
            req.localData = localData
            if cacheID
                req.cacheID(cacheID)
            req.request(args, callback)
        else
            @_queuedAPIRequests.push([category, identifier, args, callback, localData])

#___________________________________________________________________________________________________ hasLibrary
    hasLibrary: (libID, loadedOnly) =>
        ###Determines whether or not the API has loaded or is loading the specified library or
        libraries.

        @@@param libID:string,array
            A single library ID, or an array of library IDs to check. If a list is supplied the
            result will only be true if every library in the list is available.

        @@@param loadedOnly:boolean -default=true
            Whether or not to only count libraries that have already finished loading. Otherwise,
            libraries that are currently in the loading process will be considered 'have' as well.

        @@@return boolean
            Whether or not the library ID or IDs are present in the API.
        ###

        if Types.isEmpty(libID)
            return false

        if Types.isString(libID)
            libID = [libID]

        for l in libID
            if ArrayUtils.contains(@_loadedLibraries, l)
                continue

            if Types.isNone(loadedOnly) or loadedOnly
                return false

            if not ArrayUtils.contains(@_loadingLibraries, libID)
                return false

        return true

#___________________________________________________________________________________________________ hasRenderer
    hasRenderer: (renderID, loadedOnly) =>
        ###Determines whether or not the API has loaded or is loading the specified renderer(s).

        @@@param renderID:string,array
            A single render ID, or an array of render IDs to check. If a list is supplied the
            result will only be true if every renderer in the list is available.

        @@@param loadedOnly:boolean -default=true
            Whether or not to only count rendereres that have already finished loading. Otherwise,
            rendererers that are currently in the loading process will be considered 'have' as well.

        @@@return boolean
            Whether or not the render ID or IDs are present in the API.
        ###

        if Types.isEmpty(renderID)
            return

        if Types.isString(renderID)
            renderID = [renderID]

        for r in renderID
            if ArrayUtils.contains(@_renderers, renderID)
                continue

            if Types.isNone(loadedOnly) or loadedOnly
                return false

            if not ArrayUtils.contains(@_loadingLibraries, renderID.split('_')[0])
                return false

        return true

#___________________________________________________________________________________________________ createSession
    createSession: (callback) =>
        ###The method that kicks everything off, createSession initializes the API by communicating
        with the server using the specified arguments and then uses the results to enable further
        session-based communication as well as the login and configuration states.

        @@@param callback:function -default=null
            A function to execute when the session creation process is complete and the VIZME API is
            in the READY state. The signature is callback().
        ###

        @_sessionCallback = callback

        p          = window.PAGE
        sData      = if p and p.SESSION_DATA then p.SESSION_DATA.data else null

        # If a default theme was specified load it as the default theme
        if sData
            defTheme = sData.theme.id
        else
            defTheme = @styles.cleanIdentifiers(ObjectUtils.get(@args, 'defaultTheme', null))
        @styles.setThemeLoading(defTheme)

        # Find themes in the page and add them to the list of themes to load
        if sData
            tids = []
            for theme in sData.themes
                tids.push(theme.id)
        else
            tids = @styles.cleanIdentifiers(ObjectUtils.get(@args, 'themes', []))
            tids = @styles.getThemeIDs().concat(tids)
        @styles.setThemeLoading(tids)

        if sData
            @_handleSessionCreateResult(p.SESSION_DATA)
            return

        @executeAPIRequest(
            'Session',
            'create',
            {code:@requestCode, theme:defTheme, themes:tids},
            @_handleSessionCreateResult,
            null,
            true
        )

#___________________________________________________________________________________________________ render
    render: (rootDOM, callback) =>
        # Find any renderers and entities that are not loaded and load them

        @icons.render(rootDOM)
        @data.render(rootDOM)
        @vmlRender.render(rootDOM)

        comps = Renderer.getActiveComponents(rootDOM, true)
        cbid  = URLUtils.createUniqueIdentifier()
        eles  = comps.eles
        loads = comps.loads

        themes = @styles.getThemeIDs(rootDOM, true)
        @styles.setThemeLoading(themes)

        @_renderCallbacks[cbid] = {id:cbid, comps:comps, dom:rootDOM, cb:callback, tids:themes}

        loadEles = not Types.isEmpty(eles)
        loadLibs = not Types.isEmpty(loads)

        # If loading is necessary show loading icons
        if loadEles or loadLibs
            for uid in comps.uids
                Renderer.showElementLoading(uid)

        if loadEles
            args = {eles:eles, tids:themes}
            VIZME.api('Element', 'get', args, @_handleRenderEntitiesLoaded, cbid)
            loading = true
        else if themes.length > 0
            @styles.loadThemes(themes, @_handleThemesLoaded, {cbid:cbid})
            loading = true

        if loadLibs
            loading = @loadLibraries(loads, @_handleRenderLibrariesLoaded)

        if loadEles or loadLibs
            return

        # If nothing needs to be loaded skip to rendering
        @_renderLoadedComponents()

#___________________________________________________________________________________________________ loadLibraries
    loadLibraries: (ids, callback) =>
        if Types.isNone(ids)
            ids = Renderer.getActiveComponents().libs
        else if Types.isString(ids)
            ids = [ids]

        # Don't load libraries that have already been loaded
        toLoad         = []
        alreadyLoading = []
        for id in ids
            if ArrayUtils.contains(@_loadedLibraries, id)
                continue
            else if ArrayUtils.contains(@_loadingLibraries, id)
                alreadyLoading.push(id)
            else
                toLoad.push(id)
                @_loadingLibraries.push(id)

        if Types.isEmpty(toLoad) and Types.isEmpty(alreadyLoading)
            if Types.isFunction(callback)
                callback()
            return false

        # Rebuilding the array is necessary because JS is dumb and unrolls arrays
        cbids = ArrayUtils.combine(toLoad, alreadyLoading)
        if Types.isString(cbids)
            cbids = [cbids]

        libCB = {cb:callback, ids:cbids}
        @_libraryCallbacks.push(libCB)

        if Types.isEmpty(toLoad)
            @_processLibraryCallbacks(libCB)
            return true

        # Create the script and stylesheet tags to load the library(s)
        libID = encodeURI(toLoad.join('+'))
        url   = "lib/#{URLUtils.createCacheString()}/#{libID}/apilib."

        h = $('head')
        l = "<link rel='stylesheet' type='text/css' href='#{URLUtils.getCSSURL() +
            'css' + url}css'  #{AttrEnum.SCRIPT_ID}='#{libID}' />"
        h.append(l)

        s = "<script type='text/javascript' src='#{URLUtils.getJSURL() +
            'js' + url}js' #{AttrEnum.SCRIPT_ID}='#{libID}'></script>"

        # Temporarily overrides the JQuery AJAX command to force caching so that appending a script
        # tag will not receive a no-cache query parameter.
        x = $.ajax;
        $.ajax= (s) ->
            s.cache = true
            x(s)
        h.append(s)
        $.ajax = x

        VIZME.trace('Loading API library: ' + url + '\n\tScript: ' + s + '\n\tCSS: ' + l)

        return true

#___________________________________________________________________________________________________ libraryReady
    libraryReady: (libraryID) =>
        ### Mark the library as loaded. ###
        @_loadedLibraries.push(libraryID)
        ArrayUtils.remove(@_loadingLibraries, libraryID)
        @_processLibraryCallbacks()
        @dispatchEvent('API:library:' + libraryID, null, true)
        return libraryID

#___________________________________________________________________________________________________ resize
    resize: (rootDOM, force) =>
        ### Resizes all Vizme elements currently displayed on the page. This happens automatically
            when the window object is resized, but for changes to the page that do not cause a
            resize event this can be triggered manually at any time.
        ###

        if not @_resizeEnable
            return

        @styles.refreshFontSizes()

        # Shrinks the imposed scrolling viewport to the size of the window.
        if @_scroller.length
            win = $(window)
            @_scroller.height(win.height())

        # Resizes fluid boxes that have a maximum allowed width
        dom = if rootDOM then rootDOM else $('body')

        @vmlRender.resize(dom, force)

        # If a rootDOM is specified only resize rendering within that DOM
        if not Types.isNone(rootDOM)
            @_resizeAutoMaxBoxes(dom)
            for n,v of @_renderers
                v.resize(rootDOM)
                return

        @_resizeAutoMaxBoxes(dom, true)

        if VIZME.mod.page
            VIZME.mod.page.resize()

        for name, module of @_modules
            if Types.isFunction(module.resize)
                module.resize()

        @_resizeAutoMaxBoxes(dom)

        for module in @_autoResizers
            module.resize()

#___________________________________________________________________________________________________ loadModule
    loadModule: (module) =>
        m   = new module()
        mfn = module.ID

        if not m.initialize()
            return null

        if Types.isFunction(m.autoResize) and m.autoResize()
            @_autoResizers.push(m)

        @_modules[m.id()] ?= m
        VIZME.mod[m.id()] ?= m

        # If the module has a render component add it to the list of renderers
        if Types.isFunction(m.render)
            @_renderers[m.id()] ?= m

        @dispatchEvent('API:module:' + m.id(), null, true)

        return m

#___________________________________________________________________________________________________ addEventListener
    addEventListener: (id, callback, data) =>
        ### Adds an event listener of the specified ID, which will execute the specified callback.

            @@@param id:string
                The event identifier on which to register the event callback.

            @@@param callback:function
                The callback function executed whenever the event is fired.

            @@@param data:mixed
                Any data to be passed to the callback function when called by the event.
        ###

        if ArrayUtils.contains(@_oneShotEvents, id)
            callback(id, data)
            return

        e      = @_eventCallbacks
        e[id] ?= []

        # Do not add callbacks more than once
        for cb in e[id]
            if cb == callback
                return

        e[id].push({cb:callback, data:data})
        return

#___________________________________________________________________________________________________ removeEventListener
    removeEventListener: (id, callback) =>
        ### Removes an event listener of the specified ID.

            @@@param id:string
                The event identifier associated with the listener.

            @@@param callback:function
                The function to remove for the given id.
        ###

        e = @_eventCallbacks

        if not e[id]
            return

        index = 0
        for cb in e[id]
            if cb.cb == callback
                e[id].splice(index, 1)
                return
            index++

        return

#___________________________________________________________________________________________________ dispatchEvent
    dispatchEvent: (event, data, oneShot) =>

        #-------------------------------------------------------------------------------------------
        # EVENT ID
        #       Determine the event ID, which can either be the event itself if dispatching by
        #       string through dispatching events by wrapped event objects.
        if Types.isString(event)
            id = event
        else
            if event.type == 'click'
                t   = $(event.currentTarget)
                url = t.attr(AttrEnum.LINK)
                if url
                    win = if url.substr(0, 1) == 'b' then '_blank' else '_self'
                    window.open(url.substr(3), win)

            id   = event.data
            if not id
                return false
            else if id == 'v-LINK-ONLY'
                return true

        if oneShot and not ArrayUtils.contains(@_oneShotEvents, id)
            @_oneShotEvents.push(id)

        e = @_eventCallbacks
        if not e[id]
            return false

        for cb in e[id]
            if Types.isFunction(cb.cb)
                cb.cb(event, cb.data)

        return true

#___________________________________________________________________________________________________ updateSize
    updateSize: () =>
        if VIZME.mod.page
            VIZME.mod.page.updateSize()

#===================================================================================================
#                                                                               P R O T E C T E D

#___________________________________________________________________________________________________ _resizeAutoMaxBoxes
    _resizeAutoMaxBoxes: (dom, unlockOnly) =>
        styles = @styles
        dom.find("[#{AttrEnum.MAX_WIDE}]").each((index, element) ->
            me = $(this)
            v  = me.attr(AttrEnum.MAX_WIDE)
            if v.substr(0, 1) == '~'
                v = Math.round(10*parseInt(v.substr(1))*styles.globalScale()) + 'px'
            else
                try
                    v = Math.round(parseInt(v)) + 'px'
                catch err

            me.css('max-width', v)
        )

#___________________________________________________________________________________________________ _renderLoadedComponents
    _renderLoadedComponents: () =>
        if not VIZME.LOADED
            return false

        removes = []
        for rid, r of @_renderCallbacks
            # Skip:
            # 1. finished renders
            # 2. Any renders that have entities not yet finished loading.
            # 3. Any renders that themes that have not yet finished loading.
            skip = r.done or (not Types.isEmpty(r.comps.eles) and not r.eles) or
                   (not Types.isEmpty(r.comps.sids) and not r.sidsReady)

            if skip
                continue

            # Don't execute render until all libraries requested are loaded.
            if ArrayUtils.missing(r.comps.libs, @_loadedLibraries).length > 0
                continue

            r.done = true
            VIZME.trace('Processing Render callback: ', @_loadedLibraries, r)

            ElementRenderer.addElementData(r.eles)

            for id, module of @_renderers
                if ArrayUtils.contains(r.comps.libs, module.libID())
                    module.render(r.dom)

            if Types.isFunction(r.cb)
                r.cb()
                r.cb = null
            removes.push(rid)

        # Remove any render callbacks that were processed during this method execution.
        for rid in removes
            delete @_renderCallbacks[rid]

        return true

#___________________________________________________________________________________________________ _hidePageLoading
    _hidePageLoading: () =>
        @_pageLoading = false
        $('.v-API-pageLoader').remove()
        $('#v-API-pHider').show()

#___________________________________________________________________________________________________ _processLibraryCallbacks
    _processLibraryCallbacks: (callback) =>
        if Types.isEmpty(callback)
            cbs = @_libraryCallbacks
        else
            cbs = if Types.isArray(callback) then callback else [callback]

        removes = []
        for item in cbs
            if item.done
                continue

            skip = false

            # Skip callbacks with libraries that haven't been loaded yet
            for id in item.ids
                if not ArrayUtils.contains(@_loadedLibraries, id)
                    skip = true
                    break

            if skip
                continue

            removes.push(item)
            item.done = true

            VIZME.trace('Executing library callback request: ' + item.ids.join(', '))
            if Types.isFunction(item.cb)
                item.cb()

        # Cleanup completed items
        for item in removes
            ArrayUtils.remove(@_libraryCallbacks, item)

        return true

#===================================================================================================
#                                                                                 H A N D L E R S

#___________________________________________________________________________________________________ _handleUpdateMousePosition
    _handleUpdateMousePosition: (event) =>
        @_mousePos.x = event.clientX
        @_mousePos.y = event.clientY

#___________________________________________________________________________________________________ _handleSessionCreateResult
    _handleSessionCreateResult: (request) =>
        if not request.success
            if request.data.error == 'SCR'
                window.location = window.location.href.replace('http:', 'https:')
                return

            window.location.reload()
            return

        d = request.data
        if @displayType == -1
            @displayType = d.displayType

        # Create the themes and set font properties
        @styles.createDefaultTheme(d.theme, @args.styleBody)
        if Types.isSet(@args.globalScale)
            @styles.setGlobalFontScale(@args.globalScale)
        else
            @styles.setGlobalFontScale(d.scale)

        if d.themes
            for t in d.themes
                @styles.createTheme(t)

        # Set the session id and code for later use
        APIRequest.sessionID   = d.sessionID
        APIRequest.sessionCode = d.sessionCode
        APIManager.appID       = d.appID
        APIManager.profile     = d.profile
        if not Types.isEmpty(d.loginID)
            APIRequest.loginID = d.loginID
        if not Types.isEmpty(d.loginCode)
            APIRequest.loginCode = d.loginCode

        VIZME.LOADED = true
        queuedReqs   = @_queuedAPIRequests
        while queuedReqs.length > 0
            r = queuedReqs.shift()
            VIZME.api(r[0], r[1], r[2], r[3], r[4])
        @dispatchEvent('API:loaded', null, true)

        self = this
        @loadLibraries(null, () ->
            self.addEventListener('SCRIPT:complete', self._handleVizmeReady)
        )

#___________________________________________________________________________________________________ _handleVizmeReady
    _handleVizmeReady: () =>
        @_hidePageLoading()
        VIZME.render()

        @_renderLoopTimer.data(true)
        @_renderLoopTimer.start()

        VIZME.READY = true
        @dispatchEvent('API:ready', null, true)

        if Types.isFunction(@_sessionCallback)
            @_sessionCallback()
            @_sessionCallback = null

        @dispatchEvent('API:complete', null, true)

#___________________________________________________________________________________________________ _handleResize
    _handleResize: (event) =>
        # Refresh the global font scale based on window aspect ratio
        @styles.setGlobalFontScale(null, false)

        @resize()

#___________________________________________________________________________________________________ _handleAutoResize
    _handleAutoResize: (event) =>
        if @_mouseState == 'down'
            return

        for module in @_autoResizers
            module.resize()

#___________________________________________________________________________________________________ _handleThemesLoaded
    _handleThemesLoaded: (data, request) =>
        @_renderCallbacks[data.cbid].sidsReady = true
        @_renderLoadedComponents()

#___________________________________________________________________________________________________ _handleRenderLibrariesLoaded
    _handleRenderLibrariesLoaded: () =>
        VIZME.trace('Render library loaded...', @_loadedLibraries)
        @_renderLoadedComponents()

#___________________________________________________________________________________________________ _handleRenderEntitiesLoaded
    _handleRenderEntitiesLoaded: (request) =>
        if not request.success
            VIZME.trace('Element.get render failure:', request)
            return

        VIZME.trace('Render element data loaded...', request)

        @_renderCallbacks[request.localData].eles = request.data.eles
        @_renderLoadedComponents()

#___________________________________________________________________________________________________ _handleRenderLoop
    _handleRenderLoop: (dt) =>
        if @_mouseState != 'down'
            Renderer.renderQueuedItems()

            for module in @_autoResizers
                module.resize()

        dt.restart()

#___________________________________________________________________________________________________ _handleMouseEvent
    _handleMouseEvent: (event) =>
        if event.type == 'mousedown'
            @_renderLoopTimer.stop()
            @_mouseState = 'down'
            return

        if @_renderLoopTimer.data()
            @_renderLoopTimer.restart()

        @_mouseState = null
