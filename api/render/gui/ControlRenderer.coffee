# vmi.api.render.gui.ControlRenderer.coffee
# Vizme, Inc. (C)2012
# Scott Ernst

# import vmi.api.render.GuiRenderer
# require vmi.api.enum.AttrEnum
# require vmi.api.io.APIRequest
# require vmi.util.ArrayUtils
# require vmi.util.NumberUtils
# require vmi.util.TextUtils
# require vmi.util.Types
# require vmi.util.canvas.CanvasUtils
# require vmi.util.dom.DOMUtils
# require vmi.util.hash.HashUtils
# require vmi.util.time.DataTimer
# require vmi.util.url.URLUtils

# ignore VMLMode

# UI renderer for interface controls.
class ControlRenderer extends GuiRenderer

#===================================================================================================
#                                                                                       C L A S S

    @RENDER_ID  = 'CON'
    @ROOT_CLASS = '.v-CON'

    @_ERROR_CLASS = 'v-CONBOX-EmptyInputError'

    @CLICKABLE    = 'lnk'
    @C_BUTTON     = 'cui-button'
    @BUTTON       = 'jui-button'
    @CHECK        = 'jui-check'
    @SLIDER       = 'jui-slider'
    @RADIOSET     = 'jui-radioset'
    @RADIO        = 'jui-radio'
    @LIST         = 'ui-list'
    @COLOR_PICKER = 'colpick'
    @TEXT         = 'ui-text'
    @TEXTAREA     = 'ui-textarea'
    @PASSWORD     = 'ui-passwd'
    @EDITOR       = 'ui-editor'
    @CONTROL_BOX  = 'ui-cbox'
    @SEARCH       = 'ui-search'
    @BROWSE       = 'jui-browse'
    @RADIO_BTN    = 'ui-radio'
    @RADIO_ARRAY  = 'ui-radioArray'

    @_NAV_KEYS = [33, 34, 37, 38, 39, 40]

    @_changeCallbacks = []

#___________________________________________________________________________________________________ constructor
# Creates an APIManager module instance.
    constructor: () ->
        super(ControlRenderer.RENDER_ID)

#===================================================================================================
#                                                                                   G E T / S E T

#===================================================================================================
#                                                                                     P U B L I C

#___________________________________________________________________________________________________ addChangeListener
    addChangeListener: (callback, dataIDs) =>
        dids = null
        if Types.isString(dataIDs)
            dids = [dataIDs]
        else if Types.isArray(dataIDs)
            dids = dataIDs.concat()

        ControlRenderer._changeCallbacks.push({cb:callback, dids:dids})

#___________________________________________________________________________________________________ addKeyUpHandler
    addKeyUpHandler: (dom, callback) =>
        if not Types.isFunction(callback)
            return

        cls = ControlRenderer
        @getByType(dom, cls.TEXT).keyup(callback)
        @getByType(dom, cls.TEXTAREA).keyup(callback)
        @getByType(dom, cls.PASSWORD).keyup(callback)

#___________________________________________________________________________________________________ getByType
    getByType: (dom, type) =>
        dom = $(dom)
        return dom.find("[#{AttrEnum.UI_TYPE}='#{type}']")

#___________________________________________________________________________________________________ clearErrors
    clearErrors: (dom, errorClass) =>
        cls = ControlRenderer
        dom = $(dom)
        if dom.length == 0
            return

        ec = if Types.isString(errorClass) then errorClass else cls._ERROR_CLASS
        removeError = (index, element) ->
            me = $(this)
            me.removeClass(ec)

        @getByType(dom, cls.PASSWORD).each(removeError)
        @getByType(dom, cls.TEXT).each(removeError)
        @getByType(dom, cls.TEXTAREA).each(removeError)

#___________________________________________________________________________________________________ getEmptyFields
    getEmptyFields: (dom, useErrorClass) =>
        cls = ControlRenderer
        dom = $(dom)
        if dom.length == 0
            return []

        empties = []

        testForEmpty = (index, element) ->
            me = $(this)
            if not me.is(':visible')
                return

            if me.data('vsets').empty
                return

            if not me.val() or not me.val().length
                empties.push(me)

        @getByType(dom, cls.PASSWORD).each(testForEmpty)
        @getByType(dom, cls.TEXT).each(testForEmpty)
        @getByType(dom, cls.TEXTAREA).each(testForEmpty)

        if useErrorClass
            ec = if Types.isString(useErrorClass) then useErrorClass else cls._ERROR_CLASS
            for item in empties
                item.addClass(ec)

        return empties

#___________________________________________________________________________________________________ refresh
    refresh: (target) =>
        cls = ControlRenderer
        e   = target
        switch target.attr(AttrEnum.UI_TYPE)
            when cls.LIST then @_refreshList(e)
            when cls.CHECK then @_refreshCheck(e)

#___________________________________________________________________________________________________ getValueByDataID
    getValueByDataID: (dataID, clone) =>
        return @getValue($("[#{AttrEnum.DATA_ID}='#{dataID}']"), clone)

#___________________________________________________________________________________________________ getValue
    getValue: (target, clone) =>
        cls = ControlRenderer
        e   = target
        switch target.attr(AttrEnum.UI_TYPE)
            when cls.TEXT, cls.TEXTAREA
                return if e.hasClass('v-defaultedText') then '' else e.val()
            when cls.PASSWORD
                return if e.hasClass('v-defaultedText') then '' else
                HashUtils.sha256(e.val())
            when cls.SEARCH
                t = e.find('input')
                return if t.hasClass('v-defaultedText') then '' else t.val()

            when cls.CHECK     then return e.is(':checked')
            when cls.SLIDER    then return e.find('.v-CON-sliderWidget').slider('value')
            when cls.RADIO     then return null
            when cls.RADIO_BTN then return null
            when cls.RADIO_ARRAY
                item = $(".v-CON-radioBtn[#{AttrEnum.RADIO_ARRAY}='#{e.attr(AttrEnum.RADIO_ARRAY)}']").
                        filter('.v-CON-radioBtnOn')
                enm = item.attr(AttrEnum.DATA_ID)
                if not enm
                    enm = item.attr('id')
                return enm

            when cls.RADIOSET
                item = $(e.find(':checked'))
                enm  = item.attr(AttrEnum.DATA_ID)
                if not enm
                    enm = item.attr('id')
                return enm

            when cls.COLOR_PICKER
                return e.data('color')

            when cls.LIST
                return e.find('.v-CON-listItemSelected').attr(AttrEnum.DATA_ID)

            when cls.EDITOR
                editor = e.data('ldata').editor
                if editor
                    return editor.getSession().getValue()
                else
                    return null

            when cls.BROWSE
                return if clone then [] else e.find('input')[0].files

            else
                getData = e.data('getVData')
                v = if Types.isFunction(getData) then getData(e) else e.data('vdata')
                if not Types.isSet(v)
                    v = e.attr(AttrEnum.DATA)
                    return if Types.isSet(v) then v else null
                else if Types.isArray(v)
                    return if clone then v + [] else v
                else
                    return if clone then JSON.parse(JSON.stringify(v)) else v

#___________________________________________________________________________________________________ setValueByDataID
    setValueByDataID: (dataID, value, property) =>
        return @setValue($("[#{AttrEnum.DATA_ID}='#{dataID}']"), value, property)

#___________________________________________________________________________________________________ setValues
    setValues: (targets, value, property) =>
        setValue = @setValue
        targets.each((index, element) ->
            setValue($(this), value, property)
        )

#___________________________________________________________________________________________________ setValue
    setValue: (target, value, property) =>
        cls   = ControlRenderer
        e     = target
        vsets = e.data('vsets')
        ttype = target.attr(AttrEnum.UI_TYPE)
        switch ttype
            when cls.TEXT, cls.TEXTAREA, cls.PASSWORD
                if ttype == cls.TEXTAREA
                    t = if e.is('textarea') then e else e.find('textarea')
                else
                    t = if e.is('input') then e else e.find('input')

                if t.is(':focus') or Types.isEmpty(vsets.blank)
                    t.val(value)
                else
                    if Types.isEmpty(value)
                        t.val(vsets.blank)
                        t.removeClass('v-S-fcl')
                        t.addClass('v-S-sft v-italic v-defaultedText')
                    else
                        t.val(value)
                        t.removeClass('v-S-sft v-italic v-defaultedText')
                        t.addClass('v-S-fcl')

            when cls.CHECK
                e[0].checked = if value then true else false

            when cls.SLIDER
                e.find('.v-CON-sliderWidget').slider('value', value)

            when cls.RADIO_ARRAY
                if Types.isString(value)
                    items = $(".v-CON-radioBtn[#{AttrEnum.RADIO_ARRAY}='#{e.attr(AttrEnum.RADIO_ARRAY)}']")
                    value = items.filter("[#{AttrEnum.DATA_ID}='#{value}']")
                    if not value.length
                        value = items.filter("id='#{value}'")

                if value and value.length
                    value.click()

            when cls.RADIOSET
                items = item.find('.v-controlRadio')
                items.each((index, element) ->
                    this.checked = false
                    $(this).button('refresh')
                )

                btn = items.filter(value)
                if btn.length == 0
                    btn = items.filter("[#{AttrEnum.DATA_ID}='#{value}']")
                    return false
                btn[0].checked = true
                btn.button('refresh')

            when cls.COLOR_PICKER
                e.data('color', value)

            when cls.LIST
                items = e.find('.v-CON-listItem')
                s     = items.filter(value)
                if s.length == 0
                    s = items.filter("[#{AttrEnum.DATA_ID}='#{value}']")
                    if s.length == 0
                        return false
                @_setListSelection(e, s)

            when cls.EDITOR
                editor = e.data('ldata').editor
                if editor
                    editor.getSession().setValue(value)
                else
                    e.data('ldata').updatedValue = value
                return

            else
                if Types.isSet(property)
                    e.data('vdata')[property] = value
                else
                    e.data('vdata', value)

        # Refreshes the display after the value has been updated
        @refresh(e)

#___________________________________________________________________________________________________ getControlValues
    getControlValues: (dom, stringify) =>
        if not Types.isSet(dom)
            return {}

        dom      = $(dom)
        res      = {}
        getValue = @getValue

        dom.find("[#{AttrEnum.DATA_ID}]").each((index, element) ->
            e   = $(element)
            eid = e.attr(AttrEnum.DATA_ID)
            if not eid
                return

            v = getValue(e, true)
            if Types.isEmpty(v)
                return

            if stringify and Types.isObject(v) or Types.isArray(v)
                v = JSON.stringify(v)
            res[eid] = v
            return
        )

        return res

#===================================================================================================
#                                                                               P R O T E C T E D

#___________________________________________________________________________________________________ _renderElementImpl
    _renderElementImpl: (self, payload) =>
        me       = payload.me
        settings = payload.settings
        cls      = ControlRenderer

        type = me.attr(AttrEnum.UI_TYPE)
        evt  = @_parseJSONAttr(me, AttrEnum.EVENTS, null)
        ini  = @_parseJSONAttr(me, AttrEnum.INI, null)

        if not Types.isSet(me.data('vdata'))
            me.data('vdata', {})
        if not Types.isSet(me.data('ldata'))
            me.data('ldata', {})
        me.data('ldata').refreshIndex = 0

        switch type
            when cls.C_BUTTON     then @_processCUIButton(me, ini, settings)
            when cls.BUTTON       then me.button(ini)
            when cls.BROWSE       then me.button(ini)
            when cls.CHECK        then @_processCheckButton(me, ini, settings)
            when cls.SLIDER       then @_processSlider(me, ini, settings)
            when cls.RADIOSET     then @_processRadioGroup(me, ini, settings)
            when cls.RADIO_BTN    then @_processRadioArrayButton(me, ini, settings)
            when cls.COLOR_PICKER then @_processColorPicker(me, ini, settings)
            when cls.LIST         then @_processList(me, ini, settings)
            when cls.EDITOR       then @_processEditor(me, ini, settings)
            when cls.SEARCH       then @_processSearch(me, ini, settings)
            when cls.TEXT, cls.PASSWORD, cls.TEXTAREA then @_processText(me, ini, settings)

        # Buttons and clickables receive a default click global event if none is specified
        y = type == cls.BUTTON or type == cls.C_BUTTON
        y = y or (type == cls.CLICKABLE and (Types.isNone(evt) or not evt.click))
        if y
            if me.attr(AttrEnum.EVENT_ID)
                evtID = me.attr(AttrEnum.EVENT_ID)
            else if me.attr('id')
                evtID = me.attr('id')
            else if me.attr(AttrEnum.LINK)
                evtID = 'v-LINK-ONLY'
            else
                evtID = null

            if Types.isString(evtID)
                me.bind('click', evtID, VIZME.dispatchEvent)

        if not Types.isNone(evt)
            for n,v of evt
                me.bind(n, v, VIZME.dispatchEvent)

        return super(self, payload)

#___________________________________________________________________________________________________ _postRender
    _postRender: (dom) =>
        @_preResize(dom)

#___________________________________________________________________________________________________ _preResize
    _preResize: (items, dom) =>
        # Resize any control boxes in the DOM
        dom     = $(dom)
        cbClass = '.v-CONBOX'
        cbox    = dom.find(cbClass)
        if cbox.length == 0
            cbox = dom.filter(cbClass)
            if cbox.length == 0
                return

        cbox.each((index, element) ->
            me   = $(this)
            sets = me.data('vsets')

            # Don't resize if not yet rendered
            if Types.isNone(sets)
                return

            me.css('width', 'auto')
            if me.width() > sets.maxW
                me.width(sets.maxW)

            if not me.is(':visible')
                return

            cbls = me.find('.v-CONBOX-LabelColumn')
            if cbls.length == 0
                return
            cbls.css('width', '250px')

            w = 0
            me.find('.v-CONBOX-Label').each((li, le) ->
                w = Math.max($(this).width(), w)
            )

            me.find('.v-CONBOX-LabelColumn').css('width', Math.max(Math.min(w + 10, 250), 20) + 'px')
        )

#___________________________________________________________________________________________________ _resizeElement
    _resizeElement: (self, me, settings) =>
        cls =  ControlRenderer
        switch me.attr(AttrEnum.UI_TYPE)
            when cls.SLIDER
                me.find('.v-CON-sliderBoundValue').each((index, element) ->
                    bound = $(this)
                    bound.css('width', 'auto')
                    bound.width(bound.find('div').width())
                )
                me.find('.v-CON-sliderWidget').trigger('slidechange')

            when cls.LIST
                items = me.find('.v-CON-listItem')
                items.css('width', 'auto')

                maxW = 0
                items.each((index, element) ->
                    itemMe = $(this)
                    maxW   = Math.max(itemMe.width(), maxW)
                )
                # The +5 here adds a little padding to handle browsers (FF!) that don't float nicely
                # and chop of the edge.
                if items.length
                    items.width(Math.min(me.width(), maxW + 5))

            when cls.SEARCH
                t    = me.find('.v-CON-searchBox')
                b    = me.find('.v-CON-searchButton')
                icon = b.find('.v-CON-searchIcon')
                bh   = t.height()
                b.height(bh)
                icon.height(bh)
                b.width(Math.round(1.5*t.height()))
                t.width(me.width() - b.width() - 3) # Subtract 3 pixels for borders

        super(self, me, settings)

#___________________________________________________________________________________________________ _processRadioArrayButton
    _processRadioArrayButton: (e, eini, settings) =>
        rOn = 'v-CON-radioBtnOn'
        cPip = '.v-CON-radioBtnPip'

        e.click((event) ->
            b       = $(event.currentTarget)
            arrayID = b.attr(AttrEnum.RADIO_ARRAY)
            btns    = $(".v-CON-radioBtn[#{AttrEnum.RADIO_ARRAY}='#{arrayID}']")
            btns.removeClass(rOn)
            btns.find(cPip).
                removeClass('v-CON-radioBtnPipOn v-S-fbnback').
                addClass('v-CON-radioBtnPipOff')
            b.find(cPip).
                removeClass('v-CON-radioBtnPipOff').
                addClass('v-CON-radioBtnPipOn v-S-fbnback')
            b.addClass('v-CON-radioBtnOn')

            radioArray = $(".v-CON-radioBtnArray[#{AttrEnum.RADIO_ARRAY}='#{arrayID}']")
            if radioArray
                if radioArray.data('vsets').accent
                    btns.removeClass('v-STY-ACCENT')
                    b.addClass('v-STY-ACCENT')
                radioArray.trigger('change', b)
        )

        e.mouseover((event) ->
            b   = $(event.currentTarget)
            pip = b.find(cPip)
            if b.hasClass(rOn)
                pip.removeClass('v-S-fbnback').addClass('v-S-fbnback-m2')
            else
                pip.removeClass('v-S-fbnbor').addClass('v-S-fbnbor-m2')
        )

        e.mouseout((event) ->
            b   = $(event.currentTarget)
            pip = b.find(cPip)
            if b.hasClass(rOn)
                pip.removeClass('v-S-fbnback-m2').addClass('v-S-fbnback')
            else
                pip.removeClass('v-S-fbnbor-m2').addClass('v-S-fbnbor')
        )

#___________________________________________________________________________________________________ _processRadioGroup
    _processRadioGroup: (e, eini, settings) =>
        self = this
        e.buttonset(eini)
        e.click((event) ->
            self._dispatchChangeEvent($(event.currentTarget), $(event.target))
            return
        )
        return

#___________________________________________________________________________________________________ _executeSearch
    _executeSearch: (me, allowEmpty) =>
        ld         = me.data('ldata')
        vsets      = me.data('vsets')
        allowEmpty = allowEmpty or vsets.empty
        clear      = ld.clear and vsets.clears

        # Don't trigger empty searches
        t = me.find('input')
        isEmpty = t.hasClass('v-defaultedText') or t.val().length == 0
        if not allowEmpty and isEmpty
            return

        if clear or isEmpty
            ld.clear      = false
            ld.lastSearch = null
            t.val('').blur()
            me.trigger('clearSearch', [''], ld.idx)
        else
            ld.clear  = true # and search.data('vsets').filter
            ld.lastSearch = me.find('input').val()
            me.trigger('search', [ld.lastSearch], ld.idx)
            ld.idx += 1
        @_updateSearchButtonIcon(me)

#___________________________________________________________________________________________________ _updateSearchButtonIcon
    _updateSearchButtonIcon: (me) =>
        ld    = me.data('ldata')
        vsets = me.data('vsets')
        clear = ld.clear and vsets.clears

        if Types.isNone(ld)
            me = me.parents('.v-CON-search')
            if me.length == 0
                return

        iconClass = if clear then '.v-CON-clearSearchIcon' else '.v-CON-searchGoIcon'
        if ld.mouseDown
            iconClass += 'Active'

        icons = me.find('.v-CON-searchIcon')
        icons.hide()
        icons.filter(iconClass).show().resize()

#___________________________________________________________________________________________________ _processSearch
    _processSearch: (e, eini, settings) =>
        self          = this
        ld            = e.data('ldata')
        ld.clear      = false
        ld.mouseDown  = false
        ld.idx      = 0
        ld.lastSearch = null

        b = e.find('.v-CON-searchButton')

        # Search button mouseover
        b.mouseover((event) ->
            me    = $(event.currentTarget)
            me.addClass('ui-state-hover')

            search = me.parents('.v-CON-search')
            search.data('ldata').mouseDown = false
            self._updateSearchButtonIcon(search)
        )

        # Search button mousedown
        b.mousedown((event) ->
            me = $(event.currentTarget)
            me.addClass('ui-state-active')

            search = me.parents('.v-CON-search')
            search.data('ldata').mouseDown = true
            self._updateSearchButtonIcon(search)
        )

        # Search button mouseup
        b.mouseup((event) ->
            me = $(event.currentTarget)
            me.removeClass('ui-state-active')

            search = me.parents('.v-CON-search')
            search.data('ldata').mouseDown = false
            self._executeSearch(search)
        )

        # Search button mousleave
        b.mouseleave((event) ->
            me = $(event.currentTarget)
            me.removeClass('ui-state-hover ui-state-active')

            search = me.parents('.v-CON-search')
            search.data('ldata').mouseDown = false
            self._updateSearchButtonIcon(search)
        )

        t = e.find('input')
        t.data('vdata', e.data('vdata'))
        t.data('ldata', e.data('ldata'))

        @_processText(e, eini, settings, true)

        # Text field keyup
        t.keyup((event) ->
            me      = $(event.currentTarget)
            search  = me.parents('.v-CON-search')
            ld      = search.data('ldata')
            code    = event.keyCode
            vd      = me.data('vdata')
            changed = vd.text != me.val()

            if code == 13
                self._executeSearch(search)
            else if code == 27 or changed
                if code == 27
                    me.val('')
                    vd.text = ''
                else
                    vd.text = me.val()
                    me.trigger('v-textchange', [me.val()])
                    ld.changeTimer.restart()

                ld.clear = false
                self._updateSearchButtonIcon(search)
        )

        # Handles blured text field 'clear searches'
        t.blur((event) ->
            me     = $(event.currentTarget)
            search = me.parents('.v-CON-search')
            ld     = search.data('ldata')
            if (self.getValue(me).length == 0 or me.hasClass('v-defaultedText')) and ld.lastSearch
                self._executeSearch(search, true)
        )

#___________________________________________________________________________________________________ _processText
    _processText: (e, eini, settings, skipKeyUpEvent) =>
        cls                         = ControlRenderer
        self                        = this
        e.data('vdata').text        = e.val()
        e.data('ldata').changeTimer = new DataTimer(500, 1, e[0], @_handleTextChange)

        if not e.is('input,textarea')
            e = e.find('input,textarea')

        # Handle losing focus
        e.blur((event) ->
            me = $(event.currentTarget)

            # If the change timer is running, complete the action and dispatch events to prevent
            # collisions with whatever takes away focus from the text input.
            ld    = me.data('ldata')
            if ld.changeTimer.stop()
                ld.changeTimer.reset()
                me.trigger('v-textmodified')
                self._dispatchChangeEvent(me, me)

            vsets = me.data('vsets')
            if Types.isNone(vsets)
                vsets = me.parents('.v-CON').data('vsets')
                if Types.isNone(vsets)
                    return

            if not Types.isEmpty(vsets.blank) and Types.isEmpty(me.val())
                me.removeClass('v-S-fcl')
                me.addClass('v-S-sft v-italic v-defaultedText')
                me.val(vsets.blank)
        )

        # Handle receiving focus
        e.focus((event) ->
            me = $(event.currentTarget)
            if me.hasClass('v-defaultedText')
                me.removeClass('v-S-sft v-italic v-defaultedText')
                me.addClass('v-S-fcl')
                me.val('')

            if me.attr(AttrEnum.UI_TYPE) != cls.TEXTAREA
                me.select()
        )

        if skipKeyUpEvent
            return

        # Handle Key up (text change)
        e.keyup((event) ->
            me      = $(event.currentTarget)
            code    = event.keyCode
            vd      = me.data('vdata')
            changed = vd.text != me.val()

            if code == 13 or code == 27 or changed
                vd.text = me.val()
                me.trigger('v-textchange', [me.val()])

            if changed
                me.data('ldata').changeTimer.restart()
        )

#___________________________________________________________________________________________________ _processEditor
    _processEditor: (_e, _eini, _settings) =>
        initializeAceEditor = () ->
            e        = this.e
            eini     = this.eini
            settings = this.settings
            renderer = this.renderer

            e.data('ldata').initialize  = null
            e.data('ldata').changeTimer = new DataTimer(500, 1, e[0], renderer._handleTextChange)
            target  = e.children('pre')
            edt     = ace.edit(target.attr('id'))
            mode    = 'ace/mode/' + (if settings.mode then settings.mode else 'vmlhtml')
            s = edt.getSession()
            s.setUseWorker(false)
            s.setMode(mode)
            s.setUseWrapMode(true)
            edt.setShowPrintMargin(false)

            e.data('ldata').editor = edt

            e.resize((event) ->
                me = $(event.currentTarget)
                if not me.is(':visible')
                    return

                ed = me.children('pre')
                ed.width(100)
                ed.width(me.width())
                ed.height(me.height())

                editor = me.data('ldata').editor
                if editor
                    editor.resize()
            )

            e.keyup((event) ->
                if ArrayUtils.contains(ControlRenderer._NAV_KEYS, event.keyCode)
                    return

                $(event.currentTarget).data('ldata').changeTimer.restart()
            )

        _e.data('ldata').initialize = initializeAceEditor.bind({
            e:_e,
            eini:_eini,
            settings:_settings,
            renderer:this
        })

#___________________________________________________________________________________________________ _processSlider
    _processSlider: (e, eini, settings) =>
        slider = e.find('.v-CON-sliderWidget')
        slider.slider(eini)

        slideFunc = (event) ->
            me   = if event.data then $(event.data) else $(event.currentTarget)
            sldr = me.parents('.v-CON-slider')
            val  = sldr.find('.v-CON-sliderValue')
            unit = settings.unit
            v    = me.slider('value')
            min  = me.slider('option', 'min')
            max  = me.slider('option', 'max')
            vp   = Math.round(100*(v - min) / (max - min))
            val.html(NumberUtils.roundTo(v, 2) + (if unit then unit else ''))
            handle = me.find('.ui-slider-handle')
            #val.css('left', handle.css('left'))
            val.css('left', vp + '%')
            me.trigger('v-slidechange', [v])

        startFunc = (event) ->
            me = $(event.currentTarget)
            me.trigger('v-slidestart', [me.slider('value')])
            $(document).mousemove(event.currentTarget, slideFunc)

        dispatchChangeEvent = @_dispatchChangeEvent
        stopFunc = (event) ->
            me = $(event.currentTarget)
            $(document).unbind('mousemove', slideFunc)
            me.trigger('v-slidestop', [me.slider('value')])
            dispatchChangeEvent(me.parents('.v-CON-slider'), me)

        slider.bind('slidestart', startFunc)
        slider.bind('slidestop', stopFunc)
        slider.bind('slidechange', slideFunc)
        slider.slider('value', slider.slider('value'))
        slideFunc({data:slider})

#___________________________________________________________________________________________________ _processList
    _processList: (e, eini, settings) =>
        e.data('open', false)
        settings.refreshIndex = 0
        e.find('.v-CON-listRefresh').click(@_handleListRefresh)
        @_updateList(e, null)

#___________________________________________________________________________________________________ _updateList
    _updateList: (e, dom) =>
        con = e.find('.v-CON-listItems')
        con.find('.v-CON-loadingList').remove()
        con.css('height', 'auto')

        if not Types.isNone(dom)
            con.html(dom)

        items = con.find('.v-CON-listItem')
        items.find('.v-CON-listItemOPEN').css('visibility','hidden')
        items.addClass('v-S-bckbor-mbtrans')
        items.click(@_handleListSelection)

        if not Types.isNone(dom)
            @_openList(e, items.filter('.v-CON-listItemSelected'))
        else
            @_setListSelection(e, items.filter('.v-CON-listItemSelected'))

#___________________________________________________________________________________________________ _refreshList
    _refreshList: (e) =>
        con = e.find('.v-CON-listItems')
        con.height(Math.max(64, con.height()))
        con.find('.v-CON-listItem').hide()
        con.append(DOMUtils.getFillerElement(null, '.v-CON-loadingList', con))
        e.find('.v-CON-listFooter').hide()

        sets = e.data('vsets')
        sets.refreshIndex++
        args = {id:@getValue(e)}
        VIZME.api(sets.apiCat, sets.apiID, args, @_handleListRefreshData,
        {list:e, index:sets.refreshIndex})

#___________________________________________________________________________________________________ _processCheckButton
# Processes a color picker control box element
    _processCheckButton: (e, eini, settings) =>
        e.button(eini)
        toggles = JSON.parse(e.attr(AttrEnum.CHECK_DATA))
        e.data('checkOn', toggles['on'])
        e.data('checkOff', toggles['off'])

        dispatchChangeEvent = @_dispatchChangeEvent
        refreshCheck        = @_refreshCheck
        e.click((event) ->
            target = $(event.currentTarget)
            refreshCheck(target)
            dispatchChangeEvent(target, target)
        )

#___________________________________________________________________________________________________ _refreshCheck
    _refreshCheck: (target) =>
        if target.is(':checked')
            target.button('option', 'icons', target.data('checkOn'))
        else
            target.button('option', 'icons', target.data('checkOff'))
        target.button('refresh')

#___________________________________________________________________________________________________ _processColorPicker
# Processes a color picker control box element
    _processColorPicker: (e, eini, settings) =>
        e.data('color', eini.color)
        e.data('store', eini.color)

        e.ColorPicker($.extend({
            onShow: (cp) ->
                $(cp).fadeIn(500)
                return false
            ,

            onHide: (cp) ->
                $(cp).fadeOut(500)
                return false
            ,

            onChange: (hsb, hex, rgb) ->
                asHex = '#' + hex
                e.find('div').css('backgroundColor', asHex)
                e.data('store', asHex)
                e.data('color', asHex)
                ControlRenderer._dispatchChangeEvent(e, e)
        }, eini))

        trans = $(e.attr('id') + '-trans')
        if trans.length > 0
            e.data('trans', trans.attr('id'))
            trans.data('cp', e.attr('id'))
            trans.click((event) ->
                target = $(event.currentTarget)
                color  = $(target.data('cp'))
                if target.is(':checked')
                    color.hide()
                    color.data('color', null)
                else
                    color.show()
                    color.data('color', color.data('store'))
            )

#___________________________________________________________________________________________________ _setListSelection
    _setListSelection: (list, item) =>
        list.data('open', false)
        items = list.find('.v-CON-listItem')
        items.removeClass('v-CON-listItemSelected v-S-fcl-h')
        items.addClass('v-S-bckbor-mbtrans')

        item.removeClass('v-S-sft-h v-S-fclbor-h')
        item.addClass('v-CON-listItemSelected v-S-fcl-h')

        item.find('.v-CON-listItemOPEN').css('visibility', 'visible')
        items.hide()
        item.show()

        list.find('.v-CON-listFooter').hide()

#___________________________________________________________________________________________________ _openList
    _openList: (list, item) =>
        list.data('open', true)
        items = list.find('.v-CON-listItem')
        items.find('.v-CON-listItemOPEN').css('visibility', 'hidden')
        items.addClass('v-S-sft-h')

        item.removeClass('v-S-sft-h v-S-bckbor-mbtrans')
        item.addClass('v-S-fcl-h v-S-fclbor-h')
        items.show()

        list.find('.v-CON-listFooter').show()

#___________________________________________________________________________________________________ _dispatchChangeEvent
    _dispatchChangeEvent: (control, target) =>
        dataID = control.attr(AttrEnum.DATA_ID)
        if not dataID
            return

        for c in ControlRenderer._changeCallbacks
            if Types.isFunction(c.cb) and (Types.isNone(c.dids) or ArrayUtils.contains(c.dids, dataID))
                c.cb({currentTarget:control, target:target, data:dataID})

#___________________________________________________________________________________________________ _processCUIButton
    _processCUIButton: (e, eini, sets) =>
        if e.is(':visible') and e.width() and e.height()
            cu = CanvasUtils
            c = e.find('canvas')
            cu.setSize(c, e.width() - 1, e.height() - 1)
            cu.renderGradientBox(c, sets)

        e.resize(@_handleCanvasRedraw)
        e.mouseover(@_handleCanvasRedraw)
        e.mousedown(@_handleCanvasRedraw)
        e.mouseup(@_handleCanvasRedraw)
        e.mouseleave(@_handleCanvasRedraw)

#===================================================================================================
#                                                                                 H A N D L E R S

#___________________________________________________________________________________________________ _handleCanvasRedraw
    _handleCanvasRedraw: (event) =>
        me      = $(event.currentTarget)
        vs      = me.data('vsets')

        if event.type == 'mousedown'
            ds = 'down'
        else if event.type == 'mouseover' or event.type == 'mouseup'
            ds = 'over'
        else
            ds = null
        vs.displayMode = ds

        cu = CanvasUtils
        c = me.find('canvas')
        cu.setSize(c, me.width() - 1, me.height() - 1)
        cu.renderGradientBox(c, vs)

#___________________________________________________________________________________________________ _handleTextChange
    _handleTextChange: (dt) =>
        text = $(dt.data())
        text.trigger('v-textmodified')
        @_dispatchChangeEvent(text, text)

#___________________________________________________________________________________________________ _handleListSelection
    _handleListSelection: (event) =>
        target = $(event.currentTarget)
        list   = target.parents('.v-CON-list')

        if list.data('open')
            @_setListSelection(list, target)
            @_dispatchChangeEvent(list, target)
        else
            @_openList(list, target)

#___________________________________________________________________________________________________ _handleListRefresh
    _handleListRefresh: (event) =>
        @_refreshList($(event.currentTarget).parents('.v-CON-list'))

#___________________________________________________________________________________________________ _handleListRefreshData
    _handleListRefreshData: (request) =>
        ld   = request.localData
        list = ld.list
        list.find('.v-CON-listFooter').show()

        if not request.success
            return

        # Don't process old refreshes
        if list.data('vsets').refreshIndex > ld.idx
            return

        @_updateList(list, request.data.dom)

