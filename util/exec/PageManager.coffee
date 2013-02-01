# vmi.util.exec.PageManager.coffee
# Vizme, Inc. (C)2011-2012
# Scott Ernst

# require vmi.util.Types
# require vmi.util.url.URLUtils
# require vmi.util.exec.HistoryManager

# ExecutionManager module that manages other modules.
class PageManager

#===================================================================================================
#                                                                                       C L A S S

    @ID = 'page'

    @_COMPARES = ['VERSION', 'REVISION']

#___________________________________________________________________________________________________ constructor
# Initializes the ExecutionManager module.
    constructor: (container =null, minSize =380, maxSize =null, sidePadding =25) ->

        @_container   = container
        @_minSize     = minSize
        @_maxSize     = maxSize
        @_sidePadding = sidePadding

        VIZME.addEventListener('API:ready', @_checkVersion)

        @_focalModuleIDs = [] # List of focal module Identifiers

        VIZME.mod[PageManager.ID] = this

        @history = new HistoryManager()
        VIZME.mod[HistoryManager.ID] = @history
        @history.initialize()

        if PAGE.insideFacebook
            @updateSize()
            resizeInterval = setInterval(@updateSize, 250)

#===================================================================================================
#                                                                                   G E T / S E T

#___________________________________________________________________________________________________ focalModuleIDs
    focalModuleIDs: (moduleIDs) =>
        if moduleIDs
            @_focalModuleIDs = moduleIDs

        return @_focalModuleIDs;

#===================================================================================================
#                                                                                     P U B L I C

#___________________________________________________________________________________________________ resize
    resize: () =>
        win = $(window)
        if not Types.isEmpty(@_container)
            c  = $(@_container)
            ww = win.width()

            c.css('width', 'auto')

            if @_maxSize and not @_sidePadding and @_maxSize > ww
                return

            size    = ww - 2*@_sidePadding
            maxSize = if @_maxSize then @_maxSize else win.width()
            c.width(Math.max(@_minSize, Math.min(maxSize, size)))

#___________________________________________________________________________________________________ loadModule
    loadModule: (module, trackHistory) =>
        m = VIZME.mod.api.loadModule(module)
        if Types.isNone(m)
            return

        if trackHistory
            @history.addModule(m)

#___________________________________________________________________________________________________ updateSize
    updateSize: () =>
        try
            if window.FB and PAGE.insideFacebook
                FB.Canvas.setSize({
                    width: PAGE.containerWidth,
                    height: (100 + $("#container").eq(0).height())
                })
        catch err

#___________________________________________________________________________________________________ checkVizMeWarning
# Checks the warning message written as a config variable by PHP when the page is loaded. If a
# message exists on the server, see data/config/Config.php, then this message will be passed as
# a JS config variable. This function checks that variable for a message and if found will
# display it to users.
    checkVizMeWarning: () =>
        if not PAGE.WARNING
            return

        $("#vizmewarningheader").html(PAGE.WARNING.HEADER)
        $("#vizmewarninginfo").html(PAGE.WARNING.INFO)

        img = $(".vizmewarningimage")
        img.html(DOMUtils.getFillerElement(PAGE.WARNING.IMAGE, null, img))

        warn = $("#vizme-warning")
        warn.click(@_handleWarningClick)
        warn.show()

#___________________________________________________________________________________________________ resizePage
    resizePage: () =>
        try
            $(window).resize()
        catch e
            setTimeout(() ->
                try
                    $(window).resize()
                catch err
            , 500)
        return

#___________________________________________________________________________________________________ initializeComplete
    initializeComplete: () =>
        @resize()
        return true

#===================================================================================================
#                                                                               P R O T E C T E D

#___________________________________________________________________________________________________ _checkVersion
    _checkVersion: () =>
        # Reloads the page if the version and revision properties don't match between PAGE and
        # CONFIG, which signifies that the cached PAGE is out of date and should be reloaded from
        # the server.
        try
            if VIZME.CONFIG and PAGE
                for comp in PageManager._COMPARES
                    if not VIZME.CONFIG[comp] or not PAGE[comp]
                        continue
                    if PAGE[comp] == VIZME.CONFIG[comp]
                        continue

                    window.location.reload(true)
        catch err


#===================================================================================================
#                                                                                 H A N D L E R S

#___________________________________________________________________________________________________ _handleWarningClick
    _handleWarningClick: (event) =>
        $(event.currentTarget).hide()
        @resizePage()
