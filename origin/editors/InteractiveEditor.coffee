# vmi.origin.editors.Editor.coffee
# Vizme, Inc. (C)2012
# Scott Ernst

# import vmi.util.module.ContainerDisplayModule
# require vmi.util.Types
# require vmi.util.time.DataTimer


class InteractiveEditor extends ContainerDisplayModule

#===================================================================================================
#                                                                                       C L A S S

#___________________________________________________________________________________________________ constructor
# Creates a new InteractiveEditor instance.
    constructor: (id, apiCategory) ->
        super(id, '#editor-container')
        @_data            = null
        @_dataState       = null
        @_undos           = []
        @_redos           = []
        @_apiCategory     = apiCategory
        @_saver           = new DataTimer(10000, 0, null, @_handleSaveTime)
        @_editorContentID = PAGE.EDITOR_CONTENT_ID
        @_lastTimestamp   = ''
        @_refreshIndex    = 0
        @_statusTimer     = new DataTimer(3000, 1, null, @_handleClearStatus)

#===================================================================================================
#                                                                                     P U B L I C

#___________________________________________________________________________________________________ initialize
# Intializes the module.
    initialize: () =>
        if not super()
            return false

        @_refreshUndoButton()
        $('#userSaveBtn').button("option", "disabled", true)

        self = this
        VIZME.onRendered(@me(), () ->
            uiCON = VIZME.mod.ui_CON
            self._data      = uiCON.getControlValues(self.me())
            self._dataState = uiCON.getControlValues(self.me())
            self._saver.start()
            $('#userSaveBtn').button("option", "disabled", false)

            uiCON.addChangeListener(self._handleDataStateChanged)
        )

        @me().mousedown(@_handleStopSaveTimer)
        @me().mouseup(@_handleRestartSaveTimer)
        @me().keydown(@_handleStopSaveTimer)
        @me().keyup(@_handleRestartSaveTimer)

        add = VIZME.addEventListener
        add('userSaveBtn', @_handleUserSave)
        add('userUndoBtn', @_handleUndoRedo)
        add('userRedoBtn', @_handleUndoRedo)

        return true

#===================================================================================================
#                                                                               P R O T E C T E D

#___________________________________________________________________________________________________ _setDataStateChanged
    _setDataStateChanged: (dataIDs) =>
        @_pauseSaveTimer()

        snapshot = {}
        if not Types.isArray(dataIDs)
            dataIDs = [dataIDs]

        self = this
        for did in dataIDs
            if Types.isString(did)
                snapshot[did]    = @_dataState[did]
                @_dataState[did] = VIZME.mod.ui_CON.getValueByDataID(did, true)
            else
                did.each((index, element) ->
                    me = $(this)
                    dataID                  = me.attr(AttrEnum.DATA_ID)
                    snapshot[dataID]        = self._dataState[dataID]
                    self._dataState[dataID] = VIZME.mod.ui_CON.getValue(me, true)
                )

        @_undos.push(snapshot)
        while @_undos.length > 50
            @_undos.shift()

        @_refreshUndoButton()
        @_resumeSaveTimer()

#___________________________________________________________________________________________________ _refreshUndoButton
    _refreshUndoButton: () =>
        $('#userUndoBtn').button("option", "disabled", @_undos.length == 0)
        $('#userRedoBtn').button("option", "disabled", @_redos.length == 0)

#___________________________________________________________________________________________________ _reportStatus
    _reportStatus: (status) =>
        esr = $('#editorStatusReport')
        esr.html(status)
        esr.css('visibility', 'visible')
        @_statusTimer.restart()

#___________________________________________________________________________________________________ _stepRefreshIndex
    _stepRefreshIndex: (refreshTargets) =>
        @_refreshIndex++
        if Types.isArray(refreshTargets)
            @_populateRefreshIndex(refreshTargets, @_refreshIndex)

#___________________________________________________________________________________________________ _refresh
    _refresh: (refreshTargets) =>
        @_refreshIndex++
        refreshIDs = @_populateRefreshIndex(refreshTargets, @_refreshIndex)

        args = {
            'id':@_editorContentID,
            'items':refreshIDs,
            'timestamp':@_lastTimestamp}

        VIZME.api(@_apiCategory, 'refresh', args, @_handleDataRefresh, @_refreshIndex)

#___________________________________________________________________________________________________ _saveChanges
    _saveChanges: (userSave, refreshTargets) =>
        @_saver.reset()
        autoSave = not userSave

        d  = VIZME.mod.ui_CON.getControlValues(@me())
        if ObjectUtils.compare(d, @_data)
            @_saver.start()

            if userSave
                @_reportStatus('Changes saved')
            return false

        if userSave
            @_showLoading()

        # Only save changes
        diff  = {}
        for n,v of d
            if Types.isObject(v)
                if ObjectUtils.compare(@_data[n], v)
                    continue
                else
                    diff[n] = v
            else if Types.isArray(v)
                if ArrayUtils.compare(@_data[n], v)
                    continue
                else
                    diff[n] = v
            else if @_data[n] != v
                diff[n] = v

        @_data = d

        if Types.isSet(refreshTargets) and refreshTargets.length > 0
            @_refreshIndex++
            refreshIDs = @_populateRefreshIndex(refreshTargets, @_refreshIndex)

        args = @_createSaveChangesArgs({
            data:diff,
            id:@_editorContentID,
            auto:autoSave,
            refresh:refreshIDs,
            timestamp:@_lastTimestamp
        })

        VIZME.api(@_apiCategory, 'saveChanges', args, @_handleChangesSaved, {
                index:@_refreshIndex,
                status:"All Changes Saved",
                failedStatus:'Saving changes failed!'
            },
            null,
            {timeout:(if autoSave then 10000 else 6000)}
        )

        return true

#___________________________________________________________________________________________________ _createSaveChangesArgs
    _createSaveChangesArgs: (args) =>
        return args

#___________________________________________________________________________________________________ _changesSavedImpl
    _changesSavedImpl: (userSave) =>
        return

#___________________________________________________________________________________________________ _populateRefreshIndex
    _populateRefreshIndex: (refreshIDs, index) =>
        res = []
        for refID in refreshIDs
            if Types.isObject(refID)
                refID = refID.attr(AttrEnum.DATA_ID)
            res.push(refID)
            ld = $("[#{AttrEnum.DATA_ID}='#{refID}']").data('ldata')
            if index > ld.refreshIndex
                ld.refreshIndex = index

        return res

#___________________________________________________________________________________________________ _showLoading
    _showLoading: () =>
        $('.p-editorHeaderRightBox').css('visibility', 'hidden')
        $('.p-editorHeaderLeft').css('visibility', 'hidden')
        @_saver.reset()
        super()

#___________________________________________________________________________________________________ _hideLoading
    _hideLoading: () =>
        $('.p-editorHeaderRightBox').css('visibility', 'visible')
        $('.p-editorHeaderLeft').css('visibility', 'visible')
        super()

        if @_initialized
            @_saver.start()

#___________________________________________________________________________________________________ _updateRefreshedData
    _updateRefreshedData: (data, cbi, updateCurrentDataState) =>
        if Types.isEmpty(data)
            return false

        for n,v of data
            target = $("[#{AttrEnum.DATA_ID}='#{n}']")
            if target.length == 0
                continue

            ld = target.data('ldata')
            if cbi >= ld.refreshIndex
                ld.refreshIndex = cbi
                @_updateRefreshedItem(target, v, n)
                if updateCurrentDataState
                    @_dataState[n] = v

                # Update the name display property as well
                if n == 'NAME'
                    @_updateName()

        return true

#___________________________________________________________________________________________________ _updateRefreshedItem
    _updateRefreshedItem: (item, value, dataID) =>
        VIZME.mod.ui_CON.setValue(item, value)

#___________________________________________________________________________________________________ _restartAutoSaveTimer
    _restartAutoSaveTimer: () =>
        @_saver.restart()

#___________________________________________________________________________________________________ _pauseSaveTimer
    _pauseSaveTimer: () =>
        @_saver.stop()

#___________________________________________________________________________________________________ _resumeSaveTimer
    _resumeSaveTimer: () =>
        @_saver.start()

#___________________________________________________________________________________________________ _loadDataState
    _loadDataState: (undo) =>
        @_pauseSaveTimer()
        load   = if undo then @_undos.pop() else @_redos.pop()
        store  = {}

        for n,v of load
            store[n]       = @_dataState[n]
            @_dataState[n] = v

        if undo
            @_redos.push(store)
        else
            @_undos.push(store)

        @_enterLoadDataState(load, store)
        @_refreshIndex++
        @_updateRefreshedData(load, @_refreshIndex)
        @_refreshUndoButton()
        @_exitLoadDataState(load, store)
        @_restartAutoSaveTimer()

#___________________________________________________________________________________________________ _enterLoadDataState
    _enterLoadDataState: (loading, storing) =>
        return

#___________________________________________________________________________________________________ _exitLoadDataState
    _exitLoadDataState: (loaded, stored) =>
        return

#___________________________________________________________________________________________________ _updateName
    _updateName: () =>
        target = $("[#{AttrEnum.DATA_ID}=NAME]")
        if target.length == 0
            return ''

        name = VIZME.mod.ui_CON.getValue(target)
        if name
            uid = name.replace(/[^A-Za-z0-9_]/g, '')
            $('.p-editorHeaderName').html(name)
            $('.p-editorHeaderUID').html(uid)
            return name

        return ''

#===================================================================================================
#                                                                                 H A N D L E R S

#___________________________________________________________________________________________________ _handleSaveTime
    _handleSaveTime: (dt) =>
        @_saveChanges()
        return

#___________________________________________________________________________________________________ _handleStopSaveTimer
    _handleStopSaveTimer: (event) =>
        @_saver.stop()
        return

#___________________________________________________________________________________________________ _handleRestartSaveTimer
    _handleRestartSaveTimer: (event) =>
        target = $(event.target)
        if target.attr(AttrEnum.DATA_ID) == 'NAME'
            @_updateName()

        @_saver.restart()
        return

#___________________________________________________________________________________________________ _handleDataRefresh
    _handleDataRefresh: (request) =>
        if not request.success
            VIZME.trace('Refreshing changes failed!', request)
            return

        d = request.data
        @_lastTimestamp = d.timestamp

        # Refreshes any values that were requested to be refreshed
        @_updateRefreshedData(d.items, request.localData)

#___________________________________________________________________________________________________ _handleChangesSaved
    _handleChangesSaved: (request) =>
        userSave = @loading()

        @_hideLoading()

        if not request.success
            VIZME.trace(request.localData.failedStatus, request)
            if userSave
                @_showError(request.data)
            return

        @_reportStatus(request.localData.status)

        d = request.data
        @_lastTimestamp = d.timestamp

        # Refreshes any values that were requested to be refreshed
        @_updateRefreshedData(d.items, request.localData.index, true)

        @_changesSavedImpl(userSave)

#___________________________________________________________________________________________________ _handleUserSave
    _handleUserSave: (event) =>
        @_reportStatus('Saving changes...')
        @_saveChanges(true)
        return true

#___________________________________________________________________________________________________ _handleDataStateChanged
    _handleDataStateChanged: (event) =>
        @_setDataStateChanged(event.data)

#___________________________________________________________________________________________________ _handleUndoRedo
    _handleUndoRedo: (event) =>
        @_loadDataState($(event.currentTarget).attr('id') == 'userUndoBtn')

#___________________________________________________________________________________________________ _handleClearStatus
    _handleClearStatus: (dt) =>
        $('#editorStatusReport').css('visibility', 'hidden')
