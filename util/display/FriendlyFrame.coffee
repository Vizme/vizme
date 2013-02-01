# vmi.util.display.FriendlyFrame.coffee
# Vizme, Inc. (C)2010-2012
# Scott Ernst

# import vmi.util.module.ContainerDisplayModule
# require vmi.util.dom.DOMUtils
# require vmi.util.url.URLUtils

# FriendlyFrame module.
class FriendlyFrame extends ContainerDisplayModule

#===================================================================================================
#                                                                                       C L A S S

    @IFRAME_TYPE = 1
    @AJAX_TYPE   = 2
    @HTML_TYPE   = 3

    @IFRAME_RESIZE_INTERVAL = 150

    @IFRAME_DOM  = '<iframe id="friendlyiframe" allowtransparency=true frameborder=0' +
                   ' ##SANDBOX## scrolling=no style="width:##W##px;height:1px;visibility:hidden;"' +
                   ' src="##SRC##"></iframe>'

    @FULL_SANBOX_ATTR = 'sandbox="allow-same-origin allow-forms allow-scripts"'

    # Module identifier
    @ID = 'frame'

#___________________________________________________________________________________________________ constructor
    constructor: () ->
        super(FriendlyFrame.ID, "#friendly-container")
        @invisibleOnHide = true

        @_frameData     = null

        @_frameType     = null

        @_isLoading     = false

        @_barData       = null

        @_iframeIntervalID = null

        @_iframeHeight = -1

        @_requestIndex = 0

        @_activeRequest = null

        @_apiCallback   = null

#===================================================================================================
#                                                                                     P U B L I C

#___________________________________________________________________________________________________ initialize
# Initializes the FriendlyFrame module
    initialize: () =>
        if not super()
            return false

        fc = $("#friendly-loading")
        fc.append(DOMUtils.getFillerElement(URLUtils.getLoadingImageURL(), 'friendly-loader', fc))
        fc.hide()

        return true

#___________________________________________________________________________________________________ resize
    resize: () =>
        th = if $("#top-bar").length > 0 then $("#top-bar").height() else 0
        h  = Math.min(Math.max(320, $(window).height() - th - 50), 600)
        $("#friendly-loading").css('height', h + 'px')
        super()

#___________________________________________________________________________________________________ openHTML
    openHTML: (contents, barData, allowSnapshots) =>
        VIZME.trace('Opening FriendlyFrame (HTML)', contents, barData)

        @_prepareToOpen(FriendlyFrame.HTML_TYPE, contents, allowSnapshots)
        @_updateFriendlyBar(barData)
        $('#friendly-content').append(content)
        @_updateDisplay()
        @_openComplete()

#___________________________________________________________________________________________________ openAPI
    openAPI: (category, identifier, args, barData, callback, allowSnapshots) =>
        VIZME.trace("Opening FriendlyFrame (API: #{category}.#{identifier})", args, barData)

        @_prepareToOpen(FriendlyFrame.API_TYPE, [category, identifier, args], callback,
                        allowSnapshots)
        @_updateFriendlyBar(barData)
        @_showLoading()

        VIZME.api(category, identifier, args, @_handleAPIResults)

#___________________________________________________________________________________________________ openAJAX
    openAJAX: (url, data, barData, allowSnapshots) =>
        VIZME.trace('Opening FriendlyFrame (AJAX)', data, barData)

        @_prepareToOpen(FriendlyFrame.AJAX_TYPE, [url, data], null, allowSnapshots)
        @_updateFriendlyBar(barData)
        @_showLoading()

        req = new AJAXRequest('frame' + @_requestIndex, url, AJAXRequest.HTML)
        req.request(data, @_handleAjaxResults, @_handlePrepareAJAXRequest)

#___________________________________________________________________________________________________ openFrame
    openFrame: (url, barData, allowSnapshots) =>
        VIZME.trace('Opening FriendlyFrame (IFRAME)', url, barData)

        @_prepareToOpen(FriendlyFrame.IFRAME_TYPE, url, null, allowSnapshots)
        @_updateFriendlyBar(barData)
        @_showLoading()

        dom = FriendlyFrame.IFRAME_DOM.replace('##SRC##', url).
                  replace('##SANDBOX##', $.browser.webkit ? '' : FriendlyFrame.FULL_SANBOX_ATTR).
                  replace('##W##', $("#friendly-content").width())

        $("#friendly-content").append(dom)
        f = $("#friendlyiframe")
        f.css('overflow', if $.browser.msie then 'visible' else 'hidden')

        if not Types.isNull(@_iframeIntervalID)
            clearInterval(@_iframeIntervalID)

        # Dynamically adjust the height of the iframe to match its contents.
        @_iframeHeight = -1
        $("#friendlyiframe").load(=>
            @_iframeIntervalID = setInterval(@_handleIFrameUpdateInterval,
                                            FriendlyFrame.IFRAME_RESIZE_INTERVAL)
        )

#___________________________________________________________________________________________________ close
    close: (reloading) =>
        if not @_frameType
            return

        if not Types.isNull(@_iframeIntervalID)
            clearInterval(@_iframeIntervalID)

        @_frameType = null
        @_frameData = null
        @_barData   = null
        $("#friendly-content").empty()

        if reloading
            return

        @hide()

#___________________________________________________________________________________________________ dumpSnapshot
# Creates a cache snapshot for storage in the history module.
    dumpSnapshot: () =>
        snap = super()
        if snap.vis
            snap.data = @_frameData
            snap.type = @_frameType
            snap.bar  = @_barData
            snap.cb   = @_apiCallback

        return snap

#___________________________________________________________________________________________________ loadSnapshot
# Loads a previously created cache snapshot for the module, updating the state to comply with the
# values specified in the snapshot data.
# @param {Object} snapshotData     - Data object representing the cache snapshot to load.
    loadSnapshot: (snapshotData) =>
        super(snapshotData)
        sd = snapshotData

        @close(true)

        if not sd.vis or not sd.type
            return

        switch sd.type
            when FriendlyFrame.AJAX_TYPE
                @openAJAX(sd.data[0], sd.data[1], sd.bar, false)
            when FriendlyFrame.HTML_TYPE
                @openHTML(sd.data, sd.bar, false)
            when FriendlyFrame.IFRAME_TYPE
                @openFrame(sd.data, sd.bar, false)
            when FriendlyFrame.API_TYPE
                @openAPI(sd.data[0], sd.data[1], sd.data[2], sd.bar, false)

#===================================================================================================
#                                                                               P R O T E C T E D

#___________________________________________________________________________________________________ _hideMeImpl
    _hideMeImpl: () =>
        @close(true)

#___________________________________________________________________________________________________ _showLoading
    _showLoading: () =>
        if @_isLoading
            return

        @_isLoading = true

        $("#friendly-loading").show()
        @resize()

        $("#friendly-bar").hide()

        @_updateDisplay()

#___________________________________________________________________________________________________ _hideLoading
    _hideLoading: () =>
        if not @_isLoading
            return

        @_isLoading = false

        $("#friendly-loading").hide()

        if @_barData
            $("#friendly-bar").show()

        @_updateDisplay()

#___________________________________________________________________________________________________ _prepareToOpen
    _prepareToOpen: (type, data, callback, allowSnapshots) =>
        # Navigate to the top of the page for content display.
        $.scrollTo(0)

        @_apiCallback = callback

        if allowSnapshots
            allowSnapshot()

        @_requestIndex++

        @_frameType     = type
        @_frameData     = data

        fc = $("#friendly-content")
        fc.empty()
        fc.css("height","auto")

        $("#friendly-bar").css('width', 'auto')

        @show()

#___________________________________________________________________________________________________ _updateFriendlyBar
    _updateFriendlyBar: (barData) =>
        b = $("#friendly-bar")
        b.empty()

        if Types.isEmpty(barData) or not Types.isSet(VIZME.mod.gui)
            @_barData = null
            b.hide()
            return

        @_barData = if barData.length then barData else [barData]

        index = 0
        for btn in @_barData
            bid = if btn['id'] then btn['id'] else 'ffbutton' + index
            t   = if btn['type'] then btn['type'] else 'red'
            l   = if btn['label'] then btn['label'] else 'OK'
            cb  = if btn['cb'] then btn['cb'] else @_handleButtonReturn
            b.append(VIZME.mod.gui.createButton(bid, t, l, cb))
            index++

        b.show()

#___________________________________________________________________________________________________ _updateDisplay
    _updateDisplay: () =>
        VIZME.exec.updateSize()

#___________________________________________________________________________________________________ _openComplete
    _openComplete: () =>
        @_createSnapshot()

#===================================================================================================
#                                                                                 H A N D L E R S

#___________________________________________________________________________________________________ _handleIFrameUpdateInterval
    _handleIFrameUpdateInterval: () =>
        try
            c = $($("#friendlyiframe").contents().find('#container'))
            h = 50 + Math.max(150, Math.max(c.height(), c.get(0).scrollHeight))
            w = c.width()
        catch err
            VIZME.trace('friendly resize failed', err, c)
            return

        $("#friendly-bar").width(w)

        if @_iframeHeight == h
            return

        if @_iframeHeight < 0
            @_hideLoading()
            $("#friendlyiframe").css('visibility','visible')
            @_openComplete()

        $("#friendlyiframe").height(h)
        @_iframeHeight = h

#___________________________________________________________________________________________________ _handlePrepareAJAXRequest
    _handlePrepareAJAXRequest: (req, request, settings) =>
        @_requestIndex++
        request.ffuid = @_requestIndex

#___________________________________________________________________________________________________ _handleAjaxResults
    _handleAjaxResults: (request) =>
        if not request.success
            @_hideLoading()
            $("#friendly-content").html('<h1>Error: Page Failed To load. Please try again.</h1>')
            return

        if request.ffuid < @_requestIndex
            return

        dom = $(request.data)
        $("#friendly-content").html(dom)
        dom.show()

        @_hideLoading()
        @_openComplete()

#___________________________________________________________________________________________________ _handleButtonReturn
    _handleButtonReturn: () =>
        if VIZME.mod.history
            VIZME.mod.history.back()

#___________________________________________________________________________________________________ _handleAPIResults
    _handleAPIResults: (request) =>
        dom = $(request.data.dom)
        $('#friendly-content').html(dom)
        dom.show()

        @_hideLoading()
        @_openComplete()

        if Types.isFunction(@_apiCallback)
            @_apiCallback(request)
            @_apiCallback = null