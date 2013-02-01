# vmi.util.display.Response.coffee
# Vizme, Inc. (C)2010-2011
# Scott Ernst

# import vmi.util.module.DisplayModule
# require vmi.api.io.APIRequest

# Global response display module.
class Response extends DisplayModule

#===================================================================================================
#                                                                                       C L A S S

    # Module identifier
    @ID = 'response'

    @ERROR_MODE   = 'err'
    @MESSAGE_MODE = 'msg'

#___________________________________________________________________________________________________ constructor
    constructor: () ->
        super(Response.ID, "#response-container")
        @_displayData  = null
        @_displayMode  = null
        @_globalAlerts = []

#===================================================================================================
#                                                                                     P U B L I C

#___________________________________________________________________________________________________ initialize
# Initializes the FriendlyFrame module
    initialize: () =>
        if not super()
            return false

        msg = $('#v-globalAlertBox')
        if msg.length > 0
            msg.find('#v-globalAlertClose').click((event) ->
                $('#v-globalAlertBox').hide()
            )

        APIRequest.globalErrorHandler = @_handleGlobalError
        APIRequest.registerGlobalAlertHandler(@_handleGlobalAlert)

        return true

#___________________________________________________________________________________________________ show
    show: () =>
        super(true)

#___________________________________________________________________________________________________ resize
    resize: () =>
        c = $(@_target)
        c.css('width', 'auto')
        if c.width() > 800
            c.width(800)

        super()

#___________________________________________________________________________________________________ dumpSnapshot
# Creates a cache snapshot for storage in the history module.
    dumpSnapshot: () =>
        snap = super()
        if snap.vis
            snap.displayData = $.extend({}, @_displayData)
            snap.displayMode = @_displayMode

        return snap

#___________________________________________________________________________________________________ loadSnapshot
# Loads a previously created cache snapshot for the module, updating the state to comply with the
# values specified in the snapshot data.
# @param {Object} snapshotData     - Data object representing the cache snapshot to load.
    loadSnapshot: (snapshotData) =>
        super(snapshotData)
        if not snapshotData.vis
            return

        @_displayData = snapshotData.displayData
        @_displayMode = snapshotData.mode
        @_loadDisplayData()

#===================================================================================================
#                                                                               P R O T E C T E D

#___________________________________________________________________________________________________ _loadDisplayData
    _loadDisplayData: () =>
        if not @_displayData
            return false

        $(@_target + ' .v-responseLabel').html(@_displayData.label)
        $(@_target + ' .v-responseMessage').html(@_displayData.message)

        switch @_displayMode
            when Response.ERROR_MODE
                $(@_target + ' .v-errorCode').html(@_displayData.code)
                $(@_target + ' .v-errorResponse').show()

        return true

#===================================================================================================
#                                                                                 H A N D L E R S

#___________________________________________________________________________________________________ _handleGlobalError
    _handleGlobalError: (request) =>
        @_displayData = $.extend({}, request.data)
        if Types.isSet(request.data.error)
            @_displayMode = Response.ERROR_MODE

        @_loadDisplayData()
        @show()
        @_createSnapshot()

        # Closes any remotely opened windows owned by the request.
        win = request.remoteWindow()
        if win
            win.close()

        return false

#___________________________________________________________________________________________________ _handleGlobalAlert
    _handleGlobalAlert: (alert, request) =>
        # Prevents the same alert from being displayed multiple times.
        if ArrayUtils.contains(@_globalAlerts, alert.id)
            return
        @_globalAlerts.push(alert.id)

        box = $('#v-globalAlertBox')
        if box.length == 0
            return

        box.find('#v-globalAlertLabel').html(alert.label)
        box.find('#v-globalAlertMessage').html(alert.message)
        box.show()
