# vmi.origin.editors.theme.ThemeEditor.coffee
# Vizme, Inc. (C)2012
# Scott Ernst

# import vmi.origin.editors.InteractiveEditor
# require vmi.api.enum.AttrEnum
# require vmi.util.color.ColorMixer
# require vmi.util.Types
# require vmi.util.dom.DOMUtils

class ThemeEditor extends InteractiveEditor

#===================================================================================================
#                                                                                       C L A S S

    @ID = 'themeEditor'

    @_OFF_BORDER_CLASS = 'v-S-sftbor-trans'
    @_ON_BORDER_CLASS  = 'v-S-sftbor-u1h'

#___________________________________________________________________________________________________ constructor
# Creates a new Login module instance.
    constructor: () ->
        super(ThemeEditor.ID, 'Theme')

#===================================================================================================
#                                                                                     P U B L I C

#___________________________________________________________________________________________________ initialize
# Intializes the module.
    initialize: () =>
        editors = $('.v-colorBundleEditor')
        editors.each((index, element) ->
            me = $(this)
            if me.attr('data-adv') == '1'
                me.find('.v-colbun-adv').show()
                me.find('.v-colbun-smpl').hide()
            else
                me.find('.v-colbun-smpl').show()
                me.find('.v-colbun-adv').hide()

            me.data('vdata', {refreshIndex:0, refreshTimer:null})
        )

        update = @_setSwatchColor
        cols   = $('.v-color')
        cols.each((index, element) ->
            me      = $(this)
            me.data('vdata', {})
            me.data('ldata', {refreshIndex:0})
            update(me, me.find('.v-colorSwatch').css('background-color'), me.attr('data-auto') == '1')
            me.find('.v-colorSwatchLoading').html(DOMUtils.getFillerElement(null, null, me))
        )

        cols.click(@_handleSwatchClick)
        $('.v-select-closeHeader').click(@_handleCloseClick)
        $('.v-select-paneOption').click(@_handlePaneOptionClick)
        $('.v-smplMode').click(@_handleSimpleMode)
        $('.v-advMode').click(@_handleAdvancedMode)
        $('.v-theme-colorEdit').click(@_handleToggleEditor)
        $('.p-edit-hex').bind('v-textchange', @_handleHexColorEdit)

        cslides = $('.p-edit-slider')
        cslides.bind('v-slidechange', @_handleColorChange)
        cslides.bind('v-slidestart', @_handleColorChangestart)
        cslides.bind('v-slidestop', @_handleColorSet)

        add = VIZME.addEventListener
        add('simpleQuery-yes', @_handleYesSimpleMode)
        add('simpleQuery-no', @_handleNoSimpleMode)

        return super()

#===================================================================================================
#                                                                               P R O T E C T E D

#___________________________________________________________________________________________________ _getEditorRoot
    _getEditorRoot: (target) =>
        if target.hasClass('v-colorBundleEditor')
            return target

        return target.parents('.v-colorBundleEditor')

#___________________________________________________________________________________________________ _unfocusSwatches
    _unfocusSwatches: (target, focusOnSwatch) =>
        editor = @_getEditorRoot(target)

        swatches = editor.find('.v-color')
        swatches.removeClass(ThemeEditor._ON_BORDER_CLASS)
        swatches.addClass(ThemeEditor._OFF_BORDER_CLASS)

        if focusOnSwatch and editor.attr('data-adv') == '1'
            focusOnSwatch.removeClass(ThemeEditor._OFF_BORDER_CLASS)
            focusOnSwatch.addClass(ThemeEditor._ON_BORDER_CLASS)

#___________________________________________________________________________________________________ _getSelectedSwatch
    _getSelectedSwatch: (target) =>
        editor = @_getEditorRoot(target)
        if editor.attr('data-adv') == '1'
            return editor.find('.v-color.' + ThemeEditor._ON_BORDER_CLASS)
        else
            return editor.find('.v-color:visible')

#___________________________________________________________________________________________________ _closeEditor
    _closeEditor: (target) =>
        editor = @_getEditorRoot(target)
        editor.find('.v-colorSelector').hide()
        editor.find('.v-theme-colorEdit').show()
        @_unfocusSwatches(editor)

#___________________________________________________________________________________________________ _openEditorPane
    _openEditorPane: (target) =>
        editor = @_getEditorRoot(target)
        editor.find('.v-theme-colorEdit').hide()

        if target.hasClass('v-select-paneOption')
            swatch  = @_getSelectedSwatch(editor)
            paneBtn = target
            isAuto  = paneBtn.attr('data-edt') == 'auto'
        else if target.hasClass('v-color')
            swatch  = target
            isAuto  = swatch.data('vdata').auto
            paneBtn = editor.find(".v-select-paneOption[data-edt='#{if isAuto then 'auto' else 'custom'}']")
        else
            return

        grp  = editor.find('.p-select-options')
        btns = grp.find('input')
        btns.attr('checked', '0')
        paneBtn.attr('checked', '1')
        grp.buttonset('refresh')

        vd = swatch.data('vdata')
        if isAuto
            changed = vd.auto != true
            vd.auto = true
            if changed
                @_setSwatchColor(swatch)
                @_setDataStateChanged(swatch.attr(AttrEnum.DATA_ID))
                rl = if swatch.hasClass('v-colbun-adv') then [swatch] else null
                @_activateRefresh(editor, rl)
        else
            changed = vd.auto == true
            vd.auto = false

            if changed
                @_setSwatchColor(swatch)
                @_setDataStateChanged(swatch.attr(AttrEnum.DATA_ID))

            # Stops pending refresh calls
            @_stepRefreshIndex([swatch])

            # Hide loading on the swatch
            @_showSwatchLoading(swatch, false)

            # If the base swatch was changed, update the rest of the bundle
            if changed and not swatch.hasClass('v-colbun-adv')
                @_activateRefresh(editor)

            @_updateColorEditor(swatch)

        panes = editor.find('.p-selectPane')
        panes.hide()
        panes.filter("[data-edt=#{paneBtn.attr('data-edt')}]").show()
        editor.find('.v-colorSelector').show()

        VIZME.resize()

#___________________________________________________________________________________________________ _updateColorEditor
    _updateColorEditor: (swatch, skipHex) =>
        editor = @_getEditorRoot(swatch)
        c      = new ColorMixer(swatch.data('vdata').color)
        hsv    = c.rawHsv()
        bends  = c.getBendShifts(true)
        editor.find('.p-currentColor').css({'background-color':c.hsl(), 'border-color':bends[1]})

        VIZME.trace('HSV color', hsv, swatch)
        d = VIZME.mod.ui_CON
        d.setValue(editor.find('.p-edit-hue'), hsv[0])
        d.setValue(editor.find('.p-edit-saturation'), hsv[1])
        d.setValue(editor.find('.p-edit-brightness'), hsv[2])

        if skipHex
            return

        d.setValue(editor.find('.p-edit-hex'), c.hex().replace('#',''))

#___________________________________________________________________________________________________ _setSwatchColor
    _setSwatchColor: (swatch, color, auto) =>
        vd = swatch.data('vdata')
        if Types.isSet(auto)
            vd.auto = if auto then true else false

        if not Types.isInstance(color, ColorMixer)
            c = new ColorMixer(if color then color else vd.color)
        else
            c = color

        vd.color = c.hex()
        vd.alpha = c.alpha()

        mods = c.getBendShifts('hsl')
        swatch.find('.v-colorSwatch').css({'background-color':c.hsl(), 'border-color':mods[1]})
        swatch.find('.v-colorStatus').html(if vd.auto then 'Automatic' else 'Custom')

#___________________________________________________________________________________________________ _showSwatchLoading
    _showSwatchLoading: (swatch, show) =>
        s = swatch.find('.v-colorSwatch')
        l = swatch.find('.v-colorSwatchLoading')
        if not Types.isSet(show) or show
            s.hide()
            l.show()
        else
            s.show()
            l.hide()

#___________________________________________________________________________________________________ _updateRefreshedItem
    _updateRefreshedItem: (item, value) =>
        if item.hasClass('v-color')
            @_setSwatchColor(item, value.color, value.auto)
            s = @_getSelectedSwatch(item)
            if s.length > 0 and s[0] == item[0]
                @_openEditorPane(s)

            @_showSwatchLoading(item, false)
        else
            super(item, value)

#___________________________________________________________________________________________________ _exitLoadDataState
    _exitLoadDataState: (loaded, stored) =>
        # After loading an undo/redo state refresh any dynamic swatch data for swatches that changed
        # value.
        for n,v of loaded
            target = $("[#{AttrEnum.DATA_ID}='#{n}']")
            if not target.hasClass('v-color')
                continue

            # Refresh necssary swatches
            editor = @_getEditorRoot(target)
            if target.hasClass('v-colbun-adv')
                if target.data('vdata').auto
                    @_activateRefresh(editor, [target])
            else
                @_activateRefresh(editor, null)

#___________________________________________________________________________________________________ _activateRefresh
    _activateRefresh: (editor, refreshList) =>
        evd = editor.data('vdata')
        evd.refreshIndex++

        # Kill pending refresh
        if evd.refreshTimer
            evd.refreshTimer.stop()

        # If the base color changes, refresh the auto colors in its bundle
        if Types.isEmpty(refreshList)
            refreshList = []
            show   = @_showSwatchLoading
            editor.find('.v-color').each((index, element) ->
                me = $(this)
                if me.data('vdata').auto
                    refreshList.push(me.attr(AttrEnum.DATA_ID))
                    show(me, true)
            )
        else
            res = []
            for item in refreshList
                if Types.isString(item)
                    refID  = item
                    swatch = $("[#{AttrEnum.DATA_ID}='#{refID}']")
                else
                    refID  = item.attr(AttrEnum.DATA_ID)
                    swatch = item

                @_showSwatchLoading(swatch, true)
                res.push(refID)
            refreshList = res

        if refreshList.length == 0
            return

        if not evd.refreshTimer
            evd.refreshTimer = new DataTimer(750, 1, null, @_handleRefreshTimer)
        evd.refreshTimer.data({editor:editor, refresh:refreshList})
        evd.refreshTimer.start()

#___________________________________________________________________________________________________ _cancelRefresh
    _cancelRefresh: (editor) =>
        evd = editor.data('vdata')
        if evd.refreshTimer
            evd.refreshTimer.stop()
            evd.refreshTimer.data(null)
            evd.refreshIndex++

#___________________________________________________________________________________________________ _setSimpleMode
    _setSimpleMode: (editor) =>
        editor.find('.v-colbun-smpl').show()
        editor.find('.v-colbun-adv').hide()
        editor.attr('data-adv', '0')
        @_closeEditor(editor)

        # Sets the advanced swatches back to auto mode.
        refreshList   = []
        update        = @_setSwatchColor
        show          = @_showSwatchLoading
        editor.find('.v-color').filter('.v-colbun-adv').each((index, element) ->
            me = $(this)

            # Skip items that are already set to auto
            if me.data('vdata').auto
                return

            update(me, null, true)
            refreshList.push(me.attr(AttrEnum.DATA_ID))
            show(me, true)
        )
        if refreshList.length > 0
            @_saveChanges(false, refreshList)

#===================================================================================================
#                                                                                 H A N D L E R S

#___________________________________________________________________________________________________ _handleRefreshTimer
    _handleRefreshTimer: (dt) =>
        d = dt.data()
        dt.data(null)

        # Tries to save changes but if it turns out nothing was changed the loading swatches are
        # returned to their non-loading display state. This is most commonly necessary when changing
        # the hue of a color without saturation, in which case the hue slider has no impact on the
        # color and so doesn't require a save changes action.
        if not @_saveChanges(false, d.refresh)
            @_showSwatchLoading(d.editor.find('.v-color'), false)

#___________________________________________________________________________________________________ _handlePaneOptionClick
    _handlePaneOptionClick: (event) =>
        target = $(event.currentTarget)
        editor = @_getEditorRoot(target)

        currentPane = editor.find('.v-select-paneOption').is(':checked')
        if currentPane[0] == target[0]
            return

        @_openEditorPane(target)

#___________________________________________________________________________________________________ _handleCloseClick
    _handleCloseClick: (event) =>
        @_closeEditor($(event.currentTarget))

#___________________________________________________________________________________________________ _handleSwatchClick
    _handleSwatchClick: (event) =>
        target = $(event.currentTarget)

        # Don't respond to clicks while the swatch is loading
        if target.find('.v-colorSwatchLoading').is(':visible')
            return

        editor = @_getEditorRoot(target)

        # Closes the editor if you click on the active swatch
        if editor.find('.v-colorSelector').is(':visible') and
        (editor.attr('data-adv') == '0' or target.hasClass(ThemeEditor._ON_BORDER_CLASS))
            @_closeEditor(target)
            return

        name = target.find('.v-colorName').html()
        editor.find('.v-select-colorname').html(name)

        @_unfocusSwatches(target, target)
        @_openEditorPane(target)

#___________________________________________________________________________________________________ _handleAdvancedMode
    _handleAdvancedMode: (event) =>
        target = $(event.currentTarget)
        editor = @_getEditorRoot(target)

        update = @_setSwatchColor
        editor.find('.v-color').each((index, element) ->
            me = $(this)
            update(me)
        )

        editor.find('.v-colbun-adv').show()
        editor.find('.v-colbun-smpl').hide()
        editor.attr('data-adv', '1')
        @_closeEditor(editor)

#___________________________________________________________________________________________________ _handleSimpleMode
    _handleSimpleMode: (event) =>
        editor = @_getEditorRoot($(event.currentTarget))

        # Check to see if there are custom advanced colors
        advSwatches = editor.find('.v-color').filter('.v-colbun-adv')
        advMode     = false
        advSwatches.each((index, element) ->
            if not $(this).data('vdata').auto
                advMode = true
        )

        if advMode
            editor.find('.p-colorInterface').hide()
            editor.find('.p-colorSimpleQuery').show()
        else
            @_setSimpleMode(editor)

#___________________________________________________________________________________________________ _handleToggleEditor
    _handleToggleEditor: (event) =>
        target = $(event.currentTarget)
        editor = @_getEditorRoot(target)
        if editor.find('.v-colorSelector').is(':visible')
            @_closeEditor(editor)
            return

        @_openEditorPane(editor.find('.v-color:visible'))

#___________________________________________________________________________________________________ _handleColorChange
    _handleColorChange: (event, value) =>
        ### Event triggered on slide changes. ###
        target = $(event.currentTarget)
        editor = @_getEditorRoot(target)
        swatch = @_getSelectedSwatch(editor)

        if swatch.length == 0 or not target.is(':visible')
            return

        d   = VIZME.mod.ui_CON
        hsv = [d.getValue(editor.find('.p-edit-hue')),
               d.getValue(editor.find('.p-edit-saturation')),
               d.getValue(editor.find('.p-edit-brightness'))]
        c   = new ColorMixer(hsv, 'hsv')
        d.setValue(editor.find('.p-edit-hex'), c.hex().replace('#',''))
        bends = c.getBendShifts('hsl')
        editor.find('.p-currentColor').css({'background-color':c.hsl(), 'border-color':bends[1]})

        @_setSwatchColor(swatch, c)

#___________________________________________________________________________________________________ _handleColorChangestart
    _handleColorChangestart: (event, value) =>
        @_pauseSaveTimer()
        editor = @_getEditorRoot($(event.currentTarget))
        @_cancelRefresh(editor)

#___________________________________________________________________________________________________ _handleColorSet
    _handleColorSet: (event, value) =>
        editor = @_getEditorRoot($(event.currentTarget))
        swatch = @_getSelectedSwatch(editor)
        if not swatch.hasClass('v-colbun-adv')
            @_activateRefresh(editor)

        @_restartAutoSaveTimer()
        @_setDataStateChanged(swatch.attr(AttrEnum.DATA_ID))

#___________________________________________________________________________________________________ _handleHexColorEdit
    _handleHexColorEdit: (event, value) =>
        target = $(event.currentTarget)
        editor = @_getEditorRoot(target)
        @_cancelRefresh(editor)
        @_restartAutoSaveTimer()

        v = value.replace('#','').replace('0x','').toUpperCase()

        # Only accept a fully specified hex color
        if v.length != 6
            return

        # Don't allow invalid characters
        p = /[^a-fA-F0-9]/g
        if p.test(v)
            return

        swatch = @_getSelectedSwatch(editor)
        @_setSwatchColor(swatch, v)
        @_updateColorEditor(swatch, true)
        @_activateRefresh(editor)

#___________________________________________________________________________________________________ _handleYesSimpleMode
    _handleYesSimpleMode: (event) =>
        editor = @_getEditorRoot($(event.currentTarget))
        editor.find('.p-colorSimpleQuery').hide()
        editor.find('.p-colorInterface').show()
        @_setSimpleMode(editor)

#___________________________________________________________________________________________________ _handleNoSimpleMode
    _handleNoSimpleMode: (event) =>
        editor = @_getEditorRoot($(event.currentTarget))
        editor.find('.p-colorSimpleQuery').hide()
        editor.find('.p-colorInterface').show()
