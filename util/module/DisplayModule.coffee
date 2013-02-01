# vmi.util.module.DisplayModule.coffee
# Vizme, Inc. (C)2011-2012
# Scott Ernst

# import vmi.util.module.Module
# require vmi.util.Types
# require vmi.util.dom.DOMUtils

# General Display module
class DisplayModule extends Module

#===================================================================================================
#                                                                                       C L A S S

    @LOGOUT_CHANGE = 'logout_chg'
    @LOGIN_CHANGE  = 'loging_chg'

#___________________________________________________________________________________________________ constructor
# Creates a new Login module instance.
    constructor: (id, container) ->
        super(id)

        # DOM id target on which the display actions will act.
        if not StringUtils.startsWith(container, '#') and not StringUtils.startsWith(container, '.')
            container = '#' + container
        @_target         = container

        # Current visibility state.
        @_isVisible      = false

        # Allows cache snapshots
        @_allowSnapshots = true

        # Requests by other modules to keep the target module invisible.
        @_hideRequests   = []

        # Module IDs for the modules to hide when this target module is shown.
        @_modulesToHide  = 'ALL_FOCAL'

        # ModuleIDs for modules that should be allowed when this module is shown. Only used if the
        # @_modulesToHide is a global value, either ALL or ALL_FOCAL.
        @_modulesToShow  = null

        # When true, hiding this module just shrinks it to 1x1 pixels instead of making it invisible
        # as is necessary for hiding certain types of content, e.g. Flash movies which in Firefox are
        # rebooted when made invisible.
        @_shrinkToHide   = false

        # When true, the module will be made invisible once it is hidden, meaning it won't become
        # visible again until explicitly shown. When false, the target module will return to its
        # visible state as soon as hide requests have been removed.
        @_invisibleOnHide = false

        # If true, the ExecutionManager will automatically resize on a regular interval in addition
        # to explicit resize calls.
        @_autoResize = false

#===================================================================================================
#                                                                                   G E T / S E T

#___________________________________________________________________________________________________ GS: autoResize
# Container DOM ID/Class
    autoResize: () =>
        return @_autoResize

#___________________________________________________________________________________________________ GS: container
# Container DOM ID/Class
    container: () =>
        return @_target

#___________________________________________________________________________________________________ GS: me
    me: () =>
        return $(@_target)

#___________________________________________________________________________________________________ GS: children
    children: () =>
        return $(@_target + ' .v-containerContent').children()

#___________________________________________________________________________________________________ GS: shrinkToHide
    shrinkToHide: (value) =>
        if not Types.isEmpty(value)
            @_shrinkToHide = value

        return @_shrinkToHide

#___________________________________________________________________________________________________ GS: invisibleOnHide
    invisibleOnHide: (value) =>
        if not Types.isEmpty(value)
            @_invisibleOnHide = value

        return @_invisibleOnHide

#___________________________________________________________________________________________________ GS: loading
    loading: () =>
        t = $(@_target)
        if not t.length
            return true

        t = t.find('.v-visContainer')
        if not t.length
            return true

        return not t.is(':visible')

#___________________________________________________________________________________________________ GS: visible
    visible: (value) =>
        # If no value specified return current visible state
        if not Types.isSet(value)
            return @_isVisible && @_hideRequests.length == 0

        @_isVisible = value
        if @_isVisible && @_hideRequests.length == 0
            if @showMe()
                @_updateAll()
            return true

        if @hideMe()
            @_updateAll()
        return false

#___________________________________________________________________________________________________ modulesToHide
    modulesToHide: (value) =>
        if not Types.isSet(value)
            return @_modulesToHide

        if Types.isEmpty(value)
            @_modulesToHide = []
        else
            @_modulesToHide = value

        return @_modulesToHide

#___________________________________________________________________________________________________ modulesToShow
    modulesToShow: (value) =>
        if not Types.isSet(value)
            return @_modulesToShow

        if Types.isEmpty(value)
            @_modulesToShow = []
        else
            @_modulesToShow = value

        return @_modulesToShow

#===================================================================================================
#                                                                                     P U B L I C

#___________________________________________________________________________________________________ initialize
# Intializes the module.
    initialize: () =>
        if not super()
            return false

        @_isVisible = if @_shrinkToHide then $(@_target).hasClass('hideaway') else $(@_target).is(":visible")

        @me().find('.v-APIResponseBox').click(@_handleHideError)

        return true

#___________________________________________________________________________________________________ addHideRequest
    addHideRequest: (moduleID, skipUpdate) =>
        # Prevent duplicate hide requests
        for mid in @_hideRequests
            if mid == moduleID
                return false

        len = @_hideRequests.length
        @_hideRequests.push(moduleID)

        if not skipUpdate and len == 0 and @_isVisible
            @hide()
            @_updateAll()

        return true

#___________________________________________________________________________________________________ removeHideRequest
    removeHideRequest: (moduleID, skipUpdate) =>
        len = @_hideRequests.length

        # Find the request and remove it
        for i in [0..len]
            if @_hideRequests[i] == moduleID
                @_hideRequests.splice(i, 1)
                break

        if not skipUpdate and len > 0 and @_hideRequests.length == 0 and @_isVisible
            @show()
            @_updateAll()

#___________________________________________________________________________________________________ clearHideRequests
    clearHideRequests: () =>
        len = @_hideRequests.length
        @_hideRequests = []

        if @_isVisible and len > 0
            @show()
            @_updateAll()

#___________________________________________________________________________________________________ update
    update: (ignoreOthers) =>
        if @_hideRequests.length == 0 and @_isVisible
            return @_showMe(ignoreOthers)

        return @_hideMe(ignoreOthers)

#___________________________________________________________________________________________________ show
    show: (allowSnapshots) =>
        if Types.isSet(allowSnapshots)
            @_allowSnapshots = allowSnapshots

        @_isVisible      = true
        @_hideRequests   = []

        if @_showMe()
            @_updateAll()
            VIZME.exec.updateSize()

#___________________________________________________________________________________________________ hide
    hide: () =>
        @_isVisible = false

        if @_hideMe()
            @_updateAll()
            VIZME.exec.updateSize()

#___________________________________________________________________________________________________ resize
# Resizes the module.
    resize: () =>

#___________________________________________________________________________________________________ dumpSnapshot
# Creates a cache snapshot of the module for storage in the history module to support browser
# back and forward actions.
    dumpSnapshot: () =>
        snap       = super()
        snap.vis   = @_isVisible
        snap.hides = @_hideRequests.slice(0)
        return snap

#___________________________________________________________________________________________________ loadSnapshot
# Loads a previously created cache snapshot for the module, updating the state to comply with the
# values specified in the snapshot data.
# @param {Object} snapshotData     - Data object representing the cache snapshot to load.
    loadSnapshot: (snapshotData) =>
        super(snapshotData)
        @_allowSnapshots = false
        @_isVisible      = snapshotData.vis
        @_hideRequests   = snapshotData.hides.slice(0)
        @update(true)
        @_hideLoading()

#___________________________________________________________________________________________________ cleanseSnapshot
# Cleanses a snapshot data object, which is invoked after a significant state change, e.g. logout.
    cleanseSnapshot: (snapshotData, changeID) =>
        return snapshotData


#===================================================================================================
#                                                                               P R O T E C T E D

#___________________________________________________________________________________________________ _showImpl
    _showMeImpl: () =>

#___________________________________________________________________________________________________ _hideImpl
    _hideMeImpl: () =>

#___________________________________________________________________________________________________ _allowSnapshot
    _allowSnapshot: () =>
        @_allowSnapshots = true

#___________________________________________________________________________________________________ _createSnapshot
# Creates a snapshot if the module currently allows it.
    _createSnapshot: (force) =>
        if not VIZME.mod.history
            return

        if @_allowSnapshots or force
            @_allowSnapshots = false
            VIZME.mod.history.createSnapshot()

#___________________________________________________________________________________________________ _showNoShow
# Shows the loading state for the module while it processes a request.
    _showNoShow: () =>
        @_hideLoading()
        c = $(@_target)
        c.find('.v-visContainer').hide()
        c.find('.v-noShowBox').show()

#___________________________________________________________________________________________________ _hideNoShow
# Shows the loading state for the module while it processes a request.
    _hideNoShow: () =>
        c = $(@_target)
        c.find('.v-noShowBox').hide()

        if c.find('.module-loading').length == 0
            c.find('.v-visContainer').show()

#___________________________________________________________________________________________________ _showLoading
# Shows the loading state for the module while it processes a request.
    _showLoading: () =>
        @_clearError()
        @_hideNoShow()

        c = $(@_target)
        h = Math.max(c.height(), 100)

        c.find('.v-visContainer').hide()
        c.find('.v-noShowBox').hide()
        c.append(DOMUtils.getFillerElement(null, '.module-loading', c))
        c.find('.module-loading').height(h)

#___________________________________________________________________________________________________ _hideLoading
# Shows the loading state for the module while it processes a request.
    _hideLoading: () =>
        c = $(@_target)
        c.find('.v-visContainer').show()
        c.find('.module-loading').remove()

#___________________________________________________________________________________________________ _showError
# Displays the specified error and focuses on the target.
# @param errorData   - Error object as returned by request.data.
# @param showMessage - Display as a message result instead of an error.
    _showError: (errorData, showMessage) =>
        @_hideLoading()
        @_clearError()

        t      = $(@_target)
        root   = if showMessage then '.v-APIMessage' else '.v-APIError'
        box    = t.find(root)
        header = box.find('.v-APIAlertHeader')
        info   = box.find('.v-APIAlertInfo')

        if errorData
            header.html(errorData.label)
            info.html(errorData.message)
        else
            header.html('Connection Lost')
            info.html('Unable to establish a remote connection. Check internet connectivity.')
        t.find('.v-APIResponseBox').show()
        box.show()
        VIZME.render(box)

#___________________________________________________________________________________________________ _clearError
# Clears the display of any errors.
    _clearError: () =>
        @_hideLoading()
        c         = $(@_target)
        parentBox = c.find('.v-APIResponseBox')
        parentBox.find('.v-APIAlertHeader').html('')
        parentBox.find('.v-APIAlertInfo').html('')
        parentBox.children().hide()
        parentBox.hide()
        VIZME.resize()

#___________________________________________________________________________________________________ _hideMe
    _hideMe: (ignoreOthers) =>
        if @_shrinkToHide
            if $(@_target).hasClass('hideaway')
                return false
            else
                $(@_target).addClass('hideaway')
        else
            if not $(@_target).is(":visible")
                return false
            else
                $(@_target).hide()

        if @_invisibleOnHide
            @_isVisible = false

        @_hideLoading()
        @_hideNoShow()
        @_hideMeImpl()

        if not ignoreOthers
            @_removeActiveRequests()

        return true

#___________________________________________________________________________________________________ _showMe
    _showMe: (ignoreOthers) =>

        if @_shrinkToHide
            if not $(@_target).hasClass('hideaway')
                return false
            else
                $(@_target).removeClass('hideaway')
        else
            if $(@_target).is(":visible")
                return false
            else
                $(@_target).show()

        @_hideLoading()
        @_hideNoShow()
        @_showMeImpl()

        if not ignoreOthers
            @_addActiveRequests()

        return true

#___________________________________________________________________________________________________ _addActiveRequests
    _addActiveRequests: () =>
        mods = []

        if @_modulesToHide == 'ALL'
            for mid,mod of VIZME.mod
                if @_indexOfItemInArray(mid, @_modulesToShow)
                    continue

                if mid != @_moduleID and Types.isFunction(mod.visible)
                    mods.push(mid)

        else if @_modulesToHide == 'ALL_FOCAL'
            for mid,mod of VIZME.mod
                if mid == @_moduleID or not mod or not Types.isFunction(mod.visible)
                    continue

                skip = @_indexOfItemInArray(mid, @_modulesToShow) != -1 or
                       @_indexOfItemInArray(mid, if VIZME.mod.page then VIZME.mod.page.focalModuleIDs() else null) != -1

                if not skip
                    mods.push(mid)

        else if Types.isString(@_modulesToHide)
            mods = [@_modulesToHide]
        else
            mods = @_modulesToHide

        for mid in mods
            if not mid
                continue

            try
                if VIZME.mod[mid] and Types.isFunction(VIZME.mod[mid].addHideRequest)
                    VIZME.mod[mid].addHideRequest(@_moduleID, true)
            catch err

#___________________________________________________________________________________________________ _indexOfItemInArray
    _indexOfItemInArray: (item, array) =>
        if Types.isEmpty(array)
            return -1

        for i in [0..array.length]
            if item == array[i]
                return i

        return -1

#___________________________________________________________________________________________________ _removeActiveRequests
    _removeActiveRequests: () =>
        # Remove my hide requests from other modules.
        for mid, mod of VIZME.mod
            if not mod or not Types.isFunction(mod.removeHideRequest)
                continue

            try
                mod.removeHideRequest(@_moduleID, true)
            catch err

#___________________________________________________________________________________________________ _updateAll
    _updateAll: () =>
        for mid,mod of VIZME.mod
            if mid != @_moduleID and mod and Types.isFunction(mod.update)
                mod.update(false)

        # Resize the page after element display changes
        if VIZME.mod.page
            VIZME.mod.page.resizePage()

#===================================================================================================
#                                                                                 H A N D L E R S

#___________________________________________________________________________________________________ _handleHideError
    _handleHideError: (event) =>
        @_clearError()