# vmi.api.render.gui.io.Profile
# Vizme, Inc. (C)2011-2012
# Scott Ernst and Eric David Wills

# import vmi.util.module.ContainerDisplayModule
# require vmi.api.exec.APIManager
# require vmi.api.io.APIRequest
# require vmi.util.Types
# require vmi.util.dom.DOMUtils
# require vmi.util.string.StringUtils
# require vmi.util.time.DataTimer

# Vizme Profile display and operations module.
class Profile extends ContainerDisplayModule

#===================================================================================================
#                                                                                       C L A S S

    # Module identifier
    @ID = 'profile'

#___________________________________________________________________________________________________ constructor
# Creates a new Login module instance.
    constructor: () ->
        super(Profile.ID, "#profile-container")
        @_doms         = null
        @_wins         = {}
        @_activeButton = null
        @_timestamp    = ''
        @_loadIndex    = 0
        @_refreshTimer = new DataTimer(15000, 1, null, @_handleRefreshTimer)

#===================================================================================================
#                                                                                   G E T / S E T

#___________________________________________________________________________________________________ GS: profile
# Profile data.
    profile: () =>
        return APIManager.profile

#___________________________________________________________________________________________________ GS: loggedIn
    loggedIn: () =>
        return not (Types.isNull(APIManager.profile) or Types.isNull(APIRequest.loginID))

#___________________________________________________________________________________________________ GS: possessiveName
    possessiveName: () =>
        if StringUtils.endsWith(@profile().name, 's')
            return @profile().name + "'"

        return @profile().name + "'s"

#___________________________________________________________________________________________________ GS: activeButton
    activeButton: () =>
        return @me().find('.profileButtonSelected')

#===================================================================================================
#                                                                                     P U B L I C

#___________________________________________________________________________________________________ initialize
# Intializes the Login module for use.
    initialize: () =>
        if not super()
            return false

        add = VIZME.addEventListener
        add('LOGIN:loggedIn', @_handleLogin)
        add('profsets-save', @_handleSaveProfileSettings)
        add('profsets-passwd', @_handleChangePassword)
        add('profsets-deactivate', @_handleDeactivateProfile)
        add('profile-openeditor', @_handleCreateContent)
        add('profile-toggleSort', @_handleToggleSort)
        add('profile-sort', @_handleUpdateProfilePage)
        add('profs-edit', @_handleEditItem)
        add('profs-preview', @_handlePreviewItem)
        add('profs-use', @_handleUseItem)
        add('profs-delete', @_handleConfirmAction)
        add('profs-noDelete', @_handleConfirmAction)
        add('profs-yesDelete', @_handleDoAction)
        add('profs-untrash', @_handleConfirmAction)
        add('profs-emptyTrash', @_handlePurgeTrashConfirm)
        add('profs-globalconfirm-no', @_handleCancelGlobalConfirmation)
        add('profs-globalconfirm-yes', @_handleAcceptGlobalConfirmation)
        add('profs-asset-upload', @_handleOpenAssetUploader)
        add('profs-asset-link', @_handleOpenAssetLinker)

        $('#profile-center-container').resize(@resize)

        @activate()
        return true

#___________________________________________________________________________________________________ activate
# Activates the module for use with a specific profile.
    activate: () =>
        if Types.isEmpty(@profile())
            return

        b = $('.profileButton')
        b.click(@_handleProfileDisplayAction)

        for name, module of VIZME.mod
            if module == this
                continue

            if Types.isFunction(module.onLogin)
                module.onLogin(@profile())

#___________________________________________________________________________________________________ openHome
    openHome: () =>
        # Redirects to the secure website if you try to load the profile home page insecurely.
        if not URLUtils.isSecure()
            window.location.href = 'https' + window.location.href.substr(4)
            return

        @_loadIndex++
        @show()
        @_showLoading()
        VIZME.api('Profile', 'home', {}, @_handleProfileActionResult, @_loadIndex)

#___________________________________________________________________________________________________ logout
# Activates the module for use with a specific profile.
    logout: () =>
        if Types.isNull(@profile())
            return

        for name, module of VIZME.mod
            if Types.isFunction(module.onLogout)
                module.onLogout()

        APIManager.profile   = null
        APIRequest.loginID   = null
        APIRequest.loginCode = null

#___________________________________________________________________________________________________ resize
    resize: () =>
        c  = $(@_target)
        c.width(Math.max(400, Math.min(1280, $(window).width() - 20)))

        lc = $('#profile-left-container')
        cc = $('#profile-center-container')
        cc.width(Math.max(240, c.width() - lc.width() - 10))

        lc.css('height', 'auto')
        cc.css('height', 'auto')
        h = Math.max(lc.height(), cc.height())
        lc.height(h)

#___________________________________________________________________________________________________ dumpSnapshot
# Creates a cache snapshot of the module for storage in the history module to support browser
# back and forward actions.
    dumpSnapshot: () =>
        snap = super()
        if snap.vis
            snap.button = $('.profileButtonSelected').attr('id')
        return snap

#___________________________________________________________________________________________________ loadSnapshot
# Loads a previously created cache snapshot for the module, updating the state to comply with the
# values specified in the snapshot data.
# @param {Object} snapshotData     - Data object representing the cache snapshot to load.
    loadSnapshot: (snapshotData) =>
        super(snapshotData)
        @_clearDoms()

        if not snapshotData.vis
            return

        if not snapshotData.button
            @_showNoShow()
            return

        b = $('#' + snapshotData.button)
        if b.length > 0
            @_loadProfilePage(b)

#___________________________________________________________________________________________________ cleanseSnapshot
# Cleanses a snapshot data object, which is invoked after a significant state change, e.g. logout.
    cleanseSnapshot: (snapshotData, changeID) =>
        sd = super(snapshotData, changeID)
        if not sd.vis
            return sd

        sd.button = null
        return sd

#===================================================================================================
#                                                                               P R O T E C T E D

#___________________________________________________________________________________________________ _setActiveButton
    _setActiveButton: (apiTarget) =>
        $('.profileButton').removeClass('profileButtonSelected v-S-hgh-h v-S-hghbor-h')
        b = $(".profileButton[data-api='#{apiTarget}']")
        b.addClass('profileButtonSelected v-S-hgh-h v-S-hghbor-h')
        @_activeButton = b

        if Types.isSet(b.attr('data-refresh'))
            @_startRefreshTimer(b)

#___________________________________________________________________________________________________ _startRefreshTimer
    _startRefreshTimer: (target) =>
        r = @_refreshTimer
        r.reset()

        if Types.isSet(target)
            r.data(target)
        r.start()

#___________________________________________________________________________________________________ _stopRefreshTimer
    _stopRefreshTimer: () =>
        @_refreshTimer.reset()

#___________________________________________________________________________________________________ _loadDoms
    _loadDoms: (doms) =>
        @_clearDoms()
        @_doms = doms

        if Types.isEmpty(doms)
            return

        if doms.center
            p = $('#profile-center-box')
            p.html(doms.center)
            VIZME.render(p)

        p = $('#profile-center-controls')
        if doms.controls
            p.show()
            p.html(doms.controls)
            VIZME.render(p)

            search = $('#profile-search')
            if search.length > 0
                search.bind('search', @_handleUpdateProfilePage)
                search.bind('clearSearch', @_handleUpdateProfilePage)
                search.focus(@_stopRefreshTimer)
                search.blur(@_startRefreshTimer)
        else
            p.hide()

        VIZME.resize()

#___________________________________________________________________________________________________ _clearDoms
    _clearDoms: () =>
        $('#profile-center-box').html('')
        $('#profile-center-controls').html('')
        VIZME.resize()

#___________________________________________________________________________________________________ _loadProfilePage
    _loadProfilePage: (target, refresh, force) =>
        @_loadIndex++

        api = target.attr('data-api')
        VIZME.trace('Profile page loading: ' + api)

        if api.indexOf('.') == -1
            cat = 'Profile'
            id  = api
        else
            api = StringUtils.rSplit(api, '.', 1)
            cat = api[0]
            id  = api[1]

        # Adjust behaviors depending on whether or not the page is refreshing or being
        # reloaded for the first time.
        if refresh
            id      += 'Refresh'
            callback = @_handleProfileRefresh
        else
            callback = @_handleProfileActionResult

        if target.attr('data-secure') == 'yes'
            if refresh
                return

            VIZME.apiSecure(cat, id, {}, callback, @_loadIndex)
        else
            d = {}
            if refresh
                d.timestamp = @_timestamp
                d.sort      = VIZME.mod.ui_CON.getValue($('#profile-sort'))
                d.search    = VIZME.mod.ui_CON.getValue($('#profile-search'))
                d.force     = force == true
            else
                @_showLoading()

            VIZME.api(cat, id, d, callback, @_loadIndex)

#___________________________________________________________________________________________________ _getItemRoot
    _getItemRoot: (target) =>
        if target.hasClass('.profs-item')
            return target

        return target.parents('.profs-item')

#___________________________________________________________________________________________________ _updateProfilePage
    _updateProfilePage: () =>
        # Populate the center box with a loading icon while the sorting changes
        box = $('#profile-center-box')
        h   = box.height()
        box.html(DOMUtils.getFillerElement(null, '.profileRefreshLoading', box))
        box.find('.profileRefreshLoading').height(Math.min(Math.max(200, h), 400))
        VIZME.resize()

        @_loadProfilePage(@activeButton(), true, true)

#___________________________________________________________________________________________________ _showGlobalConfirmation
    _showGlobalConfirmation: (labelClass, action) =>
        $('.profs-itemsBox').hide()
        box = $('.profs-globalConfirmBox')
        box.find(labelClass).show()
        box.show()
        box.data('action', action)

#___________________________________________________________________________________________________ _purgeTrash
    _purgeTrash: () =>
        @_showLoading()
        VIZME.api('Profile', 'emptyTrash', {}, @_handleTrashPurged)

#===================================================================================================
#                                                                                 H A N D L E R S

#___________________________________________________________________________________________________ _handleProfileRefresh
    _handleProfileRefresh: (request) =>
        if request.localData != @_loadIndex
            return

        if not request.success
            @_startRefreshTimer()
            return

        @_timestamp = request.data.timestamp

        if request.data.doms
            dom = request.data.doms.refresh
            if dom
                dom = $(dom)
                pcb = $('#profile-center-box')

                if pcb.find('.profileRefreshLoading').length > 0
                    pcb.html(dom)
                else if dom.find('.profs-empty').length > 0
                    pcb.html(dom)
                else
                    # Replace the old message box
                    msgBoxSel = '.profs-items-msgBox'
                    pcb.find(msgBoxSel).remove()
                    pcb.prepend(dom.find(msgBoxSel))

                    # Replace the refreshed items
                    pi       = pcb.find('.profs-items')
                    itemsSel = '.profs-item'
                    oldItems = pi.find(itemsSel)
                    prevItem = null
                    dom.find(itemsSel).each((i, e) ->
                        me = $(e)
                        oldItems.filter("[data-itemid=\"#{me.attr('data-itemid')}\"]").remove()
                        if prevItem
                            prevItem.after(me)
                        else
                            pi.prepend(me)
                        prevItem = me
                        VIZME.render(me)
                    )
                VIZME.render(pcb)

        VIZME.resize()
        @_startRefreshTimer()

#___________________________________________________________________________________________________ _handleProfileActionResult
    _handleProfileActionResult: (request) =>
        old  = request.localData != @_loadIndex
        fail = not request.success

        if old or fail
            if fail
                @_showError(request.data)
            @_hideLoading()
            @show()
            return

        @_timestamp = request.data.timestamp
        @_setActiveButton(request.requestMethodID())
        @_loadDoms(request.data.doms)
        @_hideLoading()
        @show()

#___________________________________________________________________________________________________ _handleProfileDisplayAction
    _handleProfileDisplayAction: (event) =>
        @_stopRefreshTimer()
        @_clearError()
        @_loadProfilePage($(event.currentTarget))

#___________________________________________________________________________________________________ _handleLogin
    _handleLogin: (event) =>
        @activate()
        @openHome()

#___________________________________________________________________________________________________ _handleSaveProfileSettings
    _handleSaveProfileSettings: (event) =>
        @_showLoading()
        a = VIZME.mod.ui_CON.getControlValues($('#profsets-box'))
        VIZME.apiSecure('Profile', 'changeSettings', a, @_handleSettingsChanged)

#___________________________________________________________________________________________________ _handleSettingsChanged
    _handleSettingsChanged: (request) =>
        @show()

        if not request.success
            @_showError(request.data)
            return

        @_showError(request.data, true)
        @_clearDoms()

#___________________________________________________________________________________________________ _handleChangePassword
    _handleChangePassword: (event) =>
        @_showLoading()
        @_wins['newPassword'] = window.open(URLUtils.getLoadingURL(), 'vizme-newPassword')
        VIZME.api('Login', 'newPasswordURL', {}, @_handleChangePasswordResult)

#___________________________________________________________________________________________________ _handleChangePasswordResult
    _handleChangePasswordResult: (request) =>
        w                     = @_wins['newPassword']
        @_wins['newPassword'] = null

        if not request.success
            @_showError(request.data)
            w.close()
            return

        @_hideLoading()
        w.location.href = request.data.url

#___________________________________________________________________________________________________ _handleDeactivateProfile
    _handleDeactivateProfile: (event) =>
        @_showLoading()
        VIZME.api('Login', 'deactivateURL', {}, @_handleDeactivateProfileResult)

#___________________________________________________________________________________________________ _handleDeactivateProfileResult
    _handleDeactivateProfileResult: (request) =>
        if not request.success
            @_showError(request.data)
            return

        @_hideLoading()
        window.location.href = request.data.url

#___________________________________________________________________________________________________ _handleRefreshTimer
    _handleRefreshTimer: (dt) =>
        # If the module isn't visible ignore this refresh and buffer the next one
        if not @visible()
            @_startRefreshTimer(dt.data)
            return

        # Ignore the update if the module is in a loading state or the active button and the
        # timer button do not match
        if @loading() or Types.isNone(dt.data()) or @_activeButton.attr('id') != dt.data().attr('id')
            return

        @_loadProfilePage(dt.data(), true)

#___________________________________________________________________________________________________ _handleCreateContent
    _handleCreateContent: (event) =>
        @_showLoading()
        target = $(event.currentTarget)

        d              = {}
        d.target       = target
        d.remoteWindow = window.open(URLUtils.getLoadingURL())
        vsets          = d.target.data('vsets')
        VIZME.api(vsets.apiCategory, vsets.apiID, {}, @_handleContentCreated, d)

#___________________________________________________________________________________________________ _handleContentCreated
    _handleContentCreated: (request) =>
        if not request.success
            @_showError(request.data)
            request.remoteWindow().close()
            return

        @_hideLoading()
        request.remoteWindow().location.href = request.data.url

#___________________________________________________________________________________________________ _handleToggleSort
    _handleToggleSort: (event) =>
        target = $(event.currentTarget)
        sb     = $('.profilesSortBox')
        if target.is(':checked')
            sb.show()
        else
            sb.hide()

#___________________________________________________________________________________________________ _handleUpdateProfilePage
    _handleUpdateProfilePage: (event) =>
        @_updateProfilePage()

#___________________________________________________________________________________________________ _handleEditItem
    _handleEditItem: (event) =>
        target = $(event.currentTarget)
        item   = @_getItemRoot(target)
        window.open('/editor/' + item.attr('data-curl'), '_blank')

#___________________________________________________________________________________________________ _handlePreviewItem
    _handlePreviewItem: (event) =>
        target = $(event.currentTarget)
        item   = @_getItemRoot(target)
        window.open('/preview/' + item.attr('data-curl'), '_blank')

#___________________________________________________________________________________________________ _handleUseItem
    _handleUseItem: (event) =>
        target = $(event.currentTarget)
        item   = @_getItemRoot(target)
        uses   = item.find('.profs-uses')

        if uses.is(':visible')
            uses.hide()
            rep = '&#9660;'
        else
            uses.show()
            rep = '&#9650;'

        v = target.html()
        target.html(v.substr(0,v.length - 1) + rep)

#___________________________________________________________________________________________________ _handleConfirmAction
    _handleConfirmAction: (event) =>
        target = $(event.currentTarget)
        item   = @_getItemRoot(target)

        box      = item.find('.profs-itemConfirm')
        category = item.attr('data-apicat')
        remove   = true
        if target.hasClass('profs-untrashControl')
            id = 'untrash'
        else if target.hasClass('profs-deleteControl')
            id = 'delete'
        else
            id = 'trash'

        box.data('action', {id:id, category:category, remove:remove})
        if box.is(':visible')
            box.hide()
        else
            box.find('.profs-confirmLabel').hide()
            box.find('.profs-confirm-' + id).show()
            box.show()

#___________________________________________________________________________________________________ _handleDoAction
    _handleDoAction: (event) =>
        target = $(event.currentTarget)
        item   = @_getItemRoot(target)
        action = item.find('.profs-itemConfirm').data('action')

        VIZME.api(action.category, action.id, {id:item.attr('data-itemid')}, @_handleActionComplete,
                  {action:action, target:item})

        if action.remove
            item.hide()
            if $('.profs-item').length == 0
                $('.profs-noItems').show()
                $('.profs-items').hide()

#___________________________________________________________________________________________________ _handleActionComplete
    _handleActionComplete: (request) =>
        action = request.localData.action
        item   = request.localData.target

        if not request.success
            @_showError(request.data)
            item.show()
            if $('.profs-item').length > 0
                $('.profs-noItems').hide()
                $('.profs-items').show()
            return

        if action.remove
            item.remove()
            if $('.profs-item').length == 0
                $('.profs-noItems').show()
                $('.profs-items').hide()

#___________________________________________________________________________________________________ _handleAcceptGlobalConfirmation
    _handleAcceptGlobalConfirmation: (event) =>
        $('.profs-itemsBox').show()
        $('.profs-globalConfirmBox').hide()
        $('.profs-globalConfirmBox').data('action')()

#___________________________________________________________________________________________________ _handleCancelGlobalConfirmation
    _handleCancelGlobalConfirmation: (event) =>
        $('.profs-itemsBox').show()
        $('.profs-globalConfirmBox').hide()

#___________________________________________________________________________________________________ _handlePurgeTrashConfirm
    _handlePurgeTrashConfirm: (event) =>
        @_showGlobalConfirmation('.profs-gcon-purgeTrash', @_purgeTrash)

#___________________________________________________________________________________________________ _handleTrashPurged
    _handleTrashPurged: (request) =>
        @_hideLoading()
        if not request.success
            @_showError(request.data)
            return

        @_showError(request.data, true)
        @_updateProfilePage()

#___________________________________________________________________________________________________ _handleOpenAssetLinker
    _handleOpenAssetLinker: (event) =>
        return

#___________________________________________________________________________________________________ _handleOpenAssetUploader
    _handleOpenAssetUploader: (event) =>
        window.open('/upload/asset', '_blank')
