# vmi.origin.editors.style.PageEditor.coffee
# Vizme, Inc. (C)2012
# Scott Ernst

# import vmi.origin.editors.InteractiveEditor
# require vmi.api.enum.AttrEnum
# require vmi.util.ArrayUtils
# require vmi.util.Types
# require vmi.util.dom.DOMUtils
# require vmi.util.string.StringUtils

class PageEditor extends InteractiveEditor

#===================================================================================================
#                                                                                       C L A S S

    @ID = 'pageEditor'

    @_BLOCKS  = ['#','raw','code']
    @_NAV_KEYS = [33, 34, 37, 38, 39, 40]

    @_BREADCRUMB_DOM = "<div class='p-editorBreadcrumb v-S-sft-h' data-pos='#I#:#R#:#C#'>[##T#]</div>"

#___________________________________________________________________________________________________ constructor
# Creates a new Login module instance.
    constructor: () ->
        super(PageEditor.ID, 'Webpage')

        @_pageEditor   = null
        @_styleEditor  = null
        @_scriptEditor = null
        @_serverEditor = null
        @_publishSave  = false

        @_insideTags   = []
        @_tagHelpIndex = 0
        @_tagInfo      = {}

#===================================================================================================
#                                                                                   G E T / S E T

#___________________________________________________________________________________________________ GS: currentEditor
    currentEditor: () =>
        if not $('#editorDisplay').is(':visible')
            return null

        return $('.p-editorBox:visible').data('ldata').editor

#===================================================================================================
#                                                                                     P U B L I C

#___________________________________________________________________________________________________ initialize
# Intializes the module.
    initialize: () =>
        if not super()
            return false

        # Create the editors by calling their init functions
        editors = [$('#bodyEditor'), $('#scriptEditor'), $('#styleEditor'), $('#serverEditor')]
        for editor in editors
            iniFunc = editor.data('ldata').initialize
            if Types.isFunction(iniFunc)
                iniFunc()

        self = this
        $('.p-editorTab').click((event) ->
            tabs = $('.p-editorTab')
            tabs.removeClass('v-S-fbnback-h v-S-bbnfront-h').addClass('v-S-fbn-h v-S-bbn-h')
            me = $(event.currentTarget)
            me.removeClass('v-S-fbn-h v-S-bbn-h').addClass('v-S-fbnback-h v-S-bbnfront-h')

            $('.p-editorBox').hide()
            e  = $('#' + me.attr('data-editor')).show()
            ce = self.currentEditor()
            self._toggleOptionsBox(false)
            if ce
                ce.resize()
            e.resize()
        )

        $('#editModeSettings').click((event) ->
            $('#settingsDisplay').show()
            $('#editorDisplay').hide()
            VIZME.resize()
        )

        $('#editModeEditor').click((event) ->
            $('#settingsDisplay').hide()
            $('#editorDisplay').show()
            VIZME.resize()
            e = self.currentEditor()
            if not e
                return

            e.resize()
            if e == self._pageEditor
                self._findCurrentTag()
        )

        e = $('#bodyEditor')
        e.keyup(@_handleEditorChange)
        e.click(@_handleEditorChange)
        @_pageEditor = e.data('ldata').editor
        session      = @_pageEditor.getSession()
        session.on('change', @_handleEditorChange)

        @_styleEditor = $('#styleEditor').data('ldata').editor
        @_scriptEditor = $('#scriptEditor').data('ldata').editor
        @_serverEditor = $('#serverEditor').data('ldata').editor

        editors = [@_pageEditor, @_styleEditor, @_scriptEditor, @_serverEditor]

        for e in editors
            e.commands.addCommand({
                name: 'saveCommand',
                bindKey: {win: 'Ctrl-S',  mac: 'Command-S'},
                exec: @_handleUserSave
            })

        add = VIZME.addEventListener
        add('publishBtn', @_handlePublishClick)

        $('#editorBreadcrumbs').click(@_handleBreadcrumbClick)
        $('#helpTagTitle').click(@_handleReturnToTagClick)

        l = $('#helpTagLoading')
        l.html(DOMUtils.getFillerElement(null, null, l))
        $('#helpTagMore').click(@_handleShowTagDetails)

        # The undo and redo is not available in the page editor because it is available on the
        # editors directly.
        $('.p-editorUndoRedoBox').hide()

        $('#pagesets-clientAdvanced').click(@_handleAdvancedEditor)
        @_handleAdvancedEditor()
        $('#pagesets-server').click(@_handleServerEditor)
        @_handleServerEditor()

        $('.p-editorOptionsBtn').click((e) ->
            self._toggleOptionsBox()
        )

        $('#editorColorScheme').bind('change', (event, element) ->
            theme = 'textmate'
            style = 'w'
            switch $(element).attr('id')
                when 'schemeTomorrow' then theme = 'tomorrow'
                when 'schemeNight'
                    theme = 'tomorrow_night'
                    style = '10'
                when 'schemeSolarized'
                    theme = 'solarized_light'
                    style = '11'
                when 'schemeTwilight'
                    theme = 'twilight'
                    style = '10'
            for editor in editors
                editor.setTheme('ace/theme/' + theme)
            VIZME.exec.styles.setTheme(style)
        )

        $('#stylePreprocesor').bind('change', (event, element) ->
            ppMode = 'css'
            switch $(element).attr('id')
                when 'preprocessor-scss' then ppMode = 'scss'
                when 'preprocessor-sass' then ppMode = 'scss'
                when 'preprocessor-less' then ppMode = 'less'
            self._styleEditor.getSession().setMode('ace/mode/' + ppMode)
        )

        $('#domPreprocessor').bind('change', (event, element) ->
            ppMode = 'vmlhtml'
            switch $(element).attr('id')
                when 'dom-jade'      then ppMode = 'jade'
                when 'dom-haml'      then ppMode = 'jade'
                when 'dom-coffeecup' then ppMode = 'coffee'
                when 'dom-markdown'  then ppMode = 'markdown'
            self._pageEditor.getSession().setMode('ace/mode/' + ppMode)
        )

        $('#scriptLanguage').bind('change', (event, element) ->
            sMode = 'javascript'
            switch $(element).attr('id')
                when 'script-cs'    then sMode = 'coffee'
                when 'script-dart'  then sMode = 'java'
            self._scriptEditor.getSession().setMode('ace/mode/' + sMode)
        )

        return true

#___________________________________________________________________________________________________ refresh
# Resizes the module.
    refresh: () =>
        if not Types.isNull(@currentEditor())
            @_findCurrentTag()

#___________________________________________________________________________________________________ resize
# Resizes the module.
    resize: () =>
        super()

        box = $('#editorDisplay')
        if not box.is(':visible')
            return

        # Using window.innerHeight instead of $(window).height() because FF misbehaves.
        h  = window.innerHeight
        h  = h - box.offset().top - 22
        bw = box.width()
        box.height(h + 2)
        h -= $('#editorToolPane').height() + $('.p-editorTopbar').outerHeight()
        helpBox = box.children('#helpContent')
        editBox = box.children('#editorContent')
        editBox.width(bw - 310)
        editors = editBox.children('.v-CON-editor')
        editors.width(bw - 310)
        editors.height(h)

#===================================================================================================
#                                                                               P R O T E C T E D

#___________________________________________________________________________________________________ _publishChanges
    _publishChanges: () =>
        @_showLoading()

        args = {
            id:@_editorContentID,
            timestamp:@_lastTimestamp
        }

        VIZME.api(@_apiCategory, 'publish', args, @_handleChangesSaved, {
                index:@_refreshIndex,
                status:"Published",
                failedStatus:'Publish attempt failed!'
            },
            null,
            {timeout:6000}
        )
        return

#___________________________________________________________________________________________________ _toggleOptionsBox
    _toggleOptionsBox: (value) =>
        box   = $('.p-editorOpts-box')
        btn   = $('.p-editorOptionsBtn')
        value = if Types.isSet(value) then value else not box.is(':visible')
        closed = 'v-S-fbn-h v-S-bbn-h'
        opened = 'v-S-bbnfront-h v-S-fbnback-h'

        $('.p-editorOpts').hide()
        if value
            e   = @currentEditor()
            cls = '#p-editorOpts-'
            switch e
                when @_pageEditor then cls += 'page'
                when @_styleEditor then cls += 'style'
                when @_scriptEditor then cls += 'script'
                when @_serverEditor then cls += 'server'
                else
                    cls = null
            if cls
                box.show()
                $(cls).show()
                btn.removeClass(closed).addClass(opened)
        else
            box.hide()
            btn.removeClass(opened).addClass(closed)

        @resize()

#___________________________________________________________________________________________________ _findCurrentTag
    _findCurrentTag: (insertedText) =>
        cls = PageEditor
        e   = @currentEditor()
        if Types.isNull(e)
            return

        session = e.getSession()
        if session.getValue().length == 0
            @_lastOpenTagName = null
            $('#helpTagBox').hide()
            return

        r       = e.getSelectionRange()
        r.end   = r.start
        r.start = {column:0, row:0}
        src     = e.getSession().doc.getTextRange(r)
        text    = src.replace(/\n/g, ' ')

        #-------------------------------------------------------------------------------------------
        # Redact all blocks
        blocks  = []
        for b in cls._BLOCKS
            oi    = 0
            open  = new RegExp("\\[##{b}[^\\]]*\\]", 'gim')
            close = "[/##{b}]"

            # Find all matches
            while match = open.exec(text)
                oi = match.index
                oi = oi + match[0].length
                ci = text.indexOf(close, oi)
                if ci == -1
                    # Handles the case of closing a redacted block
                    if insertedText == ']'
                        ci = (text + ']').indexOf(close, oi)
                        if ci == -1
                            ci = text.length
                    else
                        ci = text.length

                blocks.push([oi, ci])
                text = text.substring(0, oi) + StringUtils.repeat('_', ci - oi + 1) +
                       text.substring(ci)

        #-------------------------------------------------------------------------------------------
        # Find all tags
        tags = []

        re = /\[#([A-Za-z0-9_#]+)([^\]\[]*)\]/gim
        while match = re.exec(text)
            if ArrayUtils.contains(PAGE.SINGLE_TAGS, match[1].toLowerCase())
                end = match.index + match[0].length
            else
                end = null

            tags.push(@_createTagData(match[1].toLowerCase(), match.index, end))

        re = /\[\/#([A-Za-z0-9_#]+)\]/gim
        while match = re.exec(text)
            index = tags.length
            while index > 0
                index--
                t = tags[index]

                if Types.isNull(t.end) and t.name == match[1].toLowerCase() and match.index > t.start
                    t.end = match.index
                    break

        #-------------------------------------------------------------------------------------------
        # Record all open tags
        open = []
        for t in tags
            if Types.isNull(t.end)
                t.end = text.length
                open.push(t)

        #-------------------------------------------------------------------------------------------
        # Gets the next batch of characters in the editor (after cursor position) and returns the
        # portion up to a space or closing character.
        getNext = () ->
            next = e.getSession().getValue().substr(text.length, 50)

            # If closing a tag return an empty string to let the tag be considered complete
            closers = [']', ' ', '\t', '\n']
            if ArrayUtils.contains(closers, next.charAt(0)) or ArrayUtils.contains(closers, insertedText)
                return {res:'', full:next}

            # Don't return a valid result if the tag name is only partially specified meaning
            # the tag name isn't followed by either whitespace or a ]
            nextItems = if next and next.length > 0 then next.split(/[\s\]]/gim) else []
            if nextItems.length < 2
                return null

            # Handles the case when a character is being inserted, which is inserted as the first
            # character in the next string. Or if next[0] is empty it means that there aren't any
            # closing characters following the cursor and the tag isn't yet closed.
            if nextItems[0].length == 0 or (nextItems[0] == insertedText and nextItems[1].length == 0)
                return null

            return {res:nextItems[0], full:next}

        #-------------------------------------------------------------------------------------------
        # Get any partially open tag at cursor position
        if text.charAt(text.length - 1) == '['
            next = getNext()
            if not Types.isNull(next) and next.res.charAt(0) == '#'
                next = next.res.substr(1).toLowerCase()
                t    = @_createTagData(next, text.length - 1, text.length - 1)
                tags.push(t)
                open.push(t)
        else
            re    = /\[#([A-Za-z0-9_#]*)([^\]\[]*)$/gi
            match = re.exec(text)
            if match
                tagName = match[1].toLowerCase()
                if match[2].length > 0
                    if not (insertedText == ']' and ArrayUtils.contains(PAGE.SINGLE_TAGS, tagName))
                        t = @_createTagData(tagName, match.index, text.length - 1)
                        tags.push(t)
                        open.push(t)
                else
                    next = getNext()
                    if not Types.isNull(next)
                        tagName = (match[1] + next.res).toLowerCase()
                        if next.full.charAt(0) != ']' or not ArrayUtils.contains(PAGE.SINGLE_TAGS, tagName)
                            t = @_createTagData(tagName, match.index, text.length - 1)
                            tags.push(t)
                            open.push(t)

        cursorIndex = text.length - 1
        inside = []
        for t in tags
            if t.start < cursorIndex and (Types.isNull(t.end) or t.end >= cursorIndex)
                @_setTagPosition(t, src)
                inside.push(t)
        @_insideTags = inside

        #-------------------------------------------------------------------------------------------
        # Update help display
        lastInside = if inside.length > 0 then ArrayUtils.get(inside, -1) else null
        if lastInside != null and lastInside.name != @_lastOpenTagName
            @_lastOpenTagName = lastInside.name
            box      = $('#helpTagBox')
            tagLabel = "[##{lastInside.name}]"

            box.find('#helpTagLabel').empty().hide()
            box.find('#helpTagInfo').empty().hide()
            more = box.find('#helpTagMore')
            more.hide()

            box.find('#helpTagTitle').html(tagLabel)
            box.show()

            if @_tagInfo[tagLabel]
                @_setTagHelpInfo(@_tagInfo[tagLabel])
            else
                @_tagHelpIndex++
                box.find('#helpTagLoading').show()
                key = tagLabel
                more.attr('data-hlpid', key)
                VIZME.api('Help', 'context', {key:key, type:'vmltag'}, @_handleTagInfoResult,
                          {key:key, index:@_tagHelpIndex}, 'vmltag-' + key)
        else if Types.isNull(lastInside) and @_lastOpenTagName != null
            @_lastOpenTagName = null
            $('#helpTagBox').hide()

        bcs = $('#editorBreadcrumbs')
        bcs.empty()
        if inside.length > 0
            for t in inside
                bcs.append(cls._BREADCRUMB_DOM.replace('#T#', t.name).
                                               replace('#I#', t.start).
                                               replace('#R#', t.row).
                                               replace('#C#', t.column))
        else
            bcs.html('No open tag at cursor position')

        return open

#___________________________________________________________________________________________________ _createTagData
    _createTagData: (name, start, end) =>
        return {name:name, start:start, end:end}

#___________________________________________________________________________________________________ _setTagPosition
    _setTagPosition: (tag, src) =>
        index = 0
        line  = 0
        while index < tag.start
            i = src.indexOf('\n', index)
            if i == -1 or tag.start < i
                break

            index = i + 1
            line++

        tag.row    = line
        tag.column = Math.max(0, tag.start - index)

        return tag

#___________________________________________________________________________________________________ _setTagHelpInfo
    _setTagHelpInfo: (data) =>
        $('#helpTagLoading').hide()
        label = if data.url then "<a href='#{data.url}' class='v-S-lnk v-hoverLink' target='v_editHelp'>#{data.label}</a>" else data.label
        $('#helpTagLabel').html(label).show()
        $('#helpTagInfo').html(data.info).show()
        $('#helpTagMore').show()

#___________________________________________________________________________________________________ _changesSavedImpl
    _changesSavedImpl: (userSave) =>
        if not userSave
            return

        e   = @currentEditor()
        if not e
            return

        pos = e.getCursorPosition()
        e.moveCursorToPosition(pos)
        e.centerSelection()
        e.resize()

#___________________________________________________________________________________________________ _createSaveChangesArgs
    _createSaveChangesArgs: (args) =>
        if @_publishSave
            args.publish = true
        @_publishSave = false
        return args

#===================================================================================================
#                                                                                 H A N D L E R S

#___________________________________________________________________________________________________ _handleEditorChange
    _handleEditorChange: (event) =>
        # Skip keyUp events when a change will be triggered instead
        if not Types.isSet(event)
            @_findCurrentTag()

        if event.type == 'keyup' and not ArrayUtils.contains(PageEditor._NAV_KEYS, event.keyCode)
                return

        if event.type == 'change' and event.data.action == 'insertText'
            @_findCurrentTag(event.data.text)
        else
            @_findCurrentTag()

        @resize()

#___________________________________________________________________________________________________ _handleBreadcrumbClick
    _handleBreadcrumbClick: (event) =>
        target = $(event.target)
        if not target.hasClass('p-editorBreadcrumb') or Types.isNull(@currentEditor())
            return

        dPos = target.attr('data-pos').split(':')
        row  = parseInt(dPos[1])
        col  = parseInt(dPos[2])
        @currentEditor().navigateTo(row, col)

#___________________________________________________________________________________________________ _handleReturnToTagClick
    _handleReturnToTagClick: (event) =>
        if @_insideTags.length == 0 or Types.isNull(@currentEditor())
            return

        tag = ArrayUtils.get(@_insideTags, -1)
        @currentEditor().navigateTo(tag.row, tag.column)

#___________________________________________________________________________________________________ _handleTagInfoResult
    _handleTagInfoResult: (request) =>
        if not request.success
            return

        if request.localData.index != @_tagHelpIndex
            return

        d = @_tagInfo[request.localData.key]
        if d
            @_setTagHelpInfo(d)
            return

        rd = request.data.data
        d = {label:request.data.label, info:request.data.message, url:(if rd then rd.url else null)}
        @_tagInfo[request.localData.key] = d
        @_setTagHelpInfo(d)

#___________________________________________________________________________________________________ _handleShowTagDetails
    _handleShowTagDetails: (event) =>
        key = $('#helpTagTitle').html()
        if Types.isNone(key)
            return

        VIZME.mod.help.showContextDetails(key, 'vmltag')

#___________________________________________________________________________________________________ _handleAdvancedEditor
    _handleAdvancedEditor: (event) =>
        tabs = $('.p-editorTab-advanced')
        if VIZME.mod.ui_CON.getValue($('#pagesets-clientAdvanced'))
            tabs.show()
            # Save changes immediately to refresh script and stylesheet editor content
            @_saveChanges(true, ['STYLE_CONTENT', 'SCRIPT_CONTENT'])
        else
            tabs.hide()
            $('.p-editorTab-simple').click()

#___________________________________________________________________________________________________ _handleServerEditor
    _handleServerEditor: (event) =>
        tabs = $('.p-editorTab-server')
        if VIZME.mod.ui_CON.getValue($('#pagesets-server'))
            tabs.show()
            # Save changes immediately to refresh server editor content
            @_saveChanges(true, ['SERVER_CONTENT'])
        else
            tabs.hide()
            $('.p-editorTab-simple').click()

#___________________________________________________________________________________________________ _handlePublishClick
    _handlePublishClick: (event) =>
        @_publishSave = true
        if @_saveChanges(true)
            return

        @_publishChanges()
        @_publishSave = false
        return
