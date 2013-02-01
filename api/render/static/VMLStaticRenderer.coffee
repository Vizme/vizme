# vmi.api.render.static.VMLStaticRenderer.coffee
# Vizme, Inc. (C)2012
# Scott Ernst

# require vmi.api.enum.AttrEnum
# require vmi.util.Types
# require vmi.util.dom.DOMUtils

class VMLStaticRenderer

#===================================================================================================
#                                                                                       C L A S S

#___________________________________________________________________________________________________ constructor
# Creates an Renderer instance.
    constructor: () ->
        @_timers = []

        @_resizers = [
            ['.v-gvml-row', @_handleResizeRow],
            ['.v-gvml-grid', @_handleResizeGrid],
            ['.v-gvml-image', @_handleImageResize],
            ['.v-gvml-hanger-sizer', @_handleHangerResize],
            ['.v-vmlAspect', @_handleAspectResize],
            ['.v-resizer', @_handleResizer]
        ]

        @_clicks = [
            ["[#{AttrEnum.JUMP_ID}]", @_handleAnchorClick],
            ["[#{AttrEnum.CLICKER}]", @_handleClicker]
        ]

#___________________________________________________________________________________________________ render
    render: (rootDom) =>
        self = this

        if Types.isNone(rootDom)
            rootDom = $('body')

        # Render Clicks
        for c in @_clicks
            DOMUtils.findAndFilter(rootDom, c[0]).each((i, e) ->
                me = $(e)
                VIZME.exec.data.renderStatusInit(me)
                stat = me.data('vrstatus')
                if stat.vmlclick
                    return

                me.click(c[1])
                stat.vmlclick = true
            )

        # Render Resizes
        for r in @_resizers
            DOMUtils.findAndFilter(rootDom, r[0]).each((i, e) ->
                me = $(e)
                VIZME.exec.data.renderStatusInit(me)
                stat = me.data('vrstatus')
                if stat.vmlresize
                    return

                me.resize(r[1])
                stat.vmlresize = true
            )

        rootDom.find('.v-gvml-image').resize()
        return

#___________________________________________________________________________________________________ resize
    resize: (rootDom, force) =>
        if not force
            return false

        for r in @_resizers
            DOMUtils.findAndFilter(rootDom, r[0]).each((i, e) ->
                $(e).resize()
            )

        return true

#===================================================================================================
#                                                                               P R O T E C T E D

#___________________________________________________________________________________________________ _resizeRowGroup
    _resizeRowGroup: (row, rowIn, cs, gapW, w, addGutter, cellWidth, perRowHeight) =>
        n = cs.length
        if n == 0
            return [0, []]

        mb    = if addGutter then gapW  + 'px' else 0
        props = {height:'auto', 'margin-top':0, 'margin-right':0, 'margin-bottom':mb, clear:'none'}
        cs.css(props)
        delete props['margin-bottom']
        delete props['clear']
        cs.children('.v-gvml-styleInner').css(props)
        $(cs[0]).css('clear', 'left')
        if n == 1
            cw = if cellWidth then cellWidth else w
            cs.width(cw - cs.outerWidth() + cs.width())
            csIn = cs.children('.v-gvml-styleInner')
            return [cs.innerHeight(), [if csIn.length then csIn else cs]]

        if cellWidth
            usedW = 0
            cs.each((i, e) ->
                me     = $(e)
                pad    = me.innerWidth() - me.width()
                border = me.outerWidth() - me.innerWidth()
                cw     = w - usedW
                meW    = if cw < cellWidth then cw else cellWidth
                meW    = Math.floor(meW - pad - border)
                me.width(meW)
                usedW += meW + gapW + pad + border
            )
        else
            totalReach = 0
            cs.each((i, e) ->
                totalReach += $(e).data('vsets').rowReach
            )
            nw    = n*Math.floor((w - (n - 1)*gapW) / n)

            usedW = 0
            cs.each((i, e) ->
                me    = $(e)
                reach = me.data('vsets').rowReach / totalReach
                if not reach
                    reach = totalReach/n

                pad    = me.innerWidth() - me.width()
                border = me.outerWidth() - me.innerWidth()

                # The -1 at the end of this line forces rounding down the remaining space to
                # handle sub-pixel truncation errors when the row container width is not an
                # integer value inside the browser.
                meW    = if i < n - 1 then Math.floor(reach*nw) else w - usedW - 1
                meW    = Math.floor(meW - pad - border)
                me.width(meW)
                usedW += meW + gapW + pad + border
            )

        cs.not($(cs[cs.length - 1])).css('margin-right', gapW + 'px')

        # Resize the heights to match
        h       = 0
        targets = []
        cs.each((i, e) ->
            e = $(e)
            e = e.add(e.children('.v-gvml-styleInner'))
            e.css({'height':'auto', 'margin-top':0})
            h = Math.max(h, $(e[0]).innerHeight())
            targets.push($(e[e.length - 1]))
        )

        if perRowHeight
            @_adjustGroupHeight(row.data('vsets').rowAlign, targets, h)
        return [h, targets]

#___________________________________________________________________________________________________ _adjustGroupHeight
    _adjustGroupHeight: (alignType, targets, tall) =>
        if alignType == 'top'
            return

        for t in targets
            switch alignType
                when 'fill'
                    pad    = t.innerHeight() - t.height()
                    border = t.outerHeight() - t.innerHeight()
                    t.height(tall - pad - border)
                when 'middle'
                    t.css('margin-top', Math.round(0.5*Math.max(0, tall - t.outerHeight())) + 'px')
                when 'bottom'
                    t.css('margin-top', Math.max(0, tall - t.outerHeight()) + 'px')

        return

#===================================================================================================
#                                                                                 H A N D L E R S

#___________________________________________________________________________________________________ _handleAnchorClick
    _handleAnchorClick: (event) =>
        src    = $(event.currentTarget)
        target = $("#" + src.attr(AttrEnum.JUMP_ID))
        if target.length == 0
            return
        else if target.length > 1
            target = $(target[0])

        c = $('.v-scrollContainer')
        d = {offset: {top:-50, left:0}}
        if c.length
            c.scrollTo(target, d)
        else
            $.scrollTo(target, d)

        return

#___________________________________________________________________________________________________ _handleClicker
    _handleClicker: (event) ->
        out = $(event.currentTarget).attr(AttrEnum.CLICKER).split('|')
        if out.length > 1
            window.open(out[1], out[0])
            return

        window.open(out[0], '_self')
        return

#___________________________________________________________________________________________________ _handleHangerResize
    _handleHangerResize: (event) =>
        sizer  = $(event.currentTarget)
        hanger = $('#' + sizer.attr(AttrEnum.TARGET))
        if hanger.length == 0 or not hanger.is(':visible')
            return

        VIZME.exec.data.parseSettings(hanger)
        reach  = hanger.data('vsets').hangerReach
        if not reach
            hanger.css('width', 'auto')
            return

        w      = Math.floor(sizer.width())
        hw     = Math.floor(reach*w)
        pad    = hanger.innerWidth() - hanger.width()
        border = hanger.outerWidth() - hanger.innerWidth()
        if w < reach*512
            hw = w
        he  = Math.max(Math.min(128, w), hw)
        hw -= pad + border
        hanger.width(hw)

#___________________________________________________________________________________________________ _handleImageResize
    _handleImageResize: (event) =>
        me    = $(event.currentTarget)
        vsets = VIZME.exec.data.parseSettings(me)

        if not vsets.fixed
            nominalWide   = me.attr('data-width')
            nominalHeight = me.attr('data-height')
            aspectRatio   = nominalWide/nominalHeight
            wide          = Math.floor(Math.min(me.width(), nominalWide))
            tall          = Math.round(wide/aspectRatio)

            # Handles the case where the resize event occurs while the image div container still
            # doesn't have a valid height or width value.
            if not wide or not tall
                self = this
                dt = new DataTimer(500, 1, me, (dt) ->
                    m = dt.data()
                    if not m.is(':hidden') and m.width() > 0 and m.height() > 0
                        dtIndex = self._timers.indexOf(dt)
                        if dtIndex != -1
                            self._timers.splice(dtIndex, dtIndex)
                        self._handleImageResize({currentTarget:m})
                        return

                    dt.restart()
                    return
                )
                @_timers.push(dt)
                dt.start()
                return

        img = me.find('img')
        if img.length == 0
            ph = me.find('.v-gvml-image-ph')
            if vsets.fixed or me.attr(AttrEnum.FORCE) or not me.is(':hidden')
                me.removeAttr(AttrEnum.FORCE)
                img = $("<img src='#{vsets.image}' width='100%' height='100%' />")
                ph.after(img)
                ph.remove()

                if me.hasClass('v-gvml-image-inline')
                    me.css('display', 'inline-block')
            else
                img = ph

        if not vsets.fixed
            if wide == 0
                img.width(nominalWide)
                img.height(nominalHeight)
            else
                img.width(wide)
                img.height(tall)

        return

#___________________________________________________________________________________________________ _handleResizeRow
    _handleResizeRow: (event) =>
        row = $(event.currentTarget)
        if not row.is(':visible')
            return

        # Handles the case where the row is wrapped for a change in style or accent
        if row.children().length == 1 and $(row.children()[0]).hasClass('v-gvml-styleInner')
            rowIn = $(row.children()[0])
        else
            rowIn = row

        w  = row.width()
        cs = rowIn.children('.v-gvml-rowChild:visible')
        if cs.length == 0
            cs = rowIn.children('.v-gvml-rowChildLeft, .v-gvml-rowChildRight')

        n = cs.length
        if n == 0
            return

        VIZME.exec.data.parseSettings(row)
        scale    = VIZME.exec.styles.globalScale()
        vs       = row.data('vsets')
        gapW     = scale*vs.gap
        rowsData = []
        wAdd     = 0
        rd       = {b:0, e:n, rs:[], tr:0}
        maxCols  = vs.maxCols
        if VIZME.exec.displayType > 1
            minCols = 1
        else
            minCols = Math.min(Math.max(1, maxCols), vs.minCols)
        cs.each((i, e) ->
            me = $(this)
            vsets = VIZME.exec.data.parseSettings(me)
            minW  = scale*vsets.rowMinW
            reach = vsets.rowReach
            nc    = i - rd.b
            if nc >= minCols and (wAdd + minW > w or (maxCols > 0 and nc >= maxCols))
                rd.e = i
                rowsData.push(rd)
                rd   = {b:i, e:n, rs:[reach], tr:reach}
                wAdd = minW + gapW
            else
                rd.rs.push(reach)
                rd.tr += reach
                wAdd  += minW + gapW
        )
        rowsData.push(rd)

        # Try to fix ragged columns by moving columns from the previous to last row to the last row
        nr = rowsData.length
        if nr > 1
            pr = ArrayUtils.get(rowsData, -2)
            lr = ArrayUtils.get(rowsData, -1)
            while pr.e - pr.b > 1
                r = ArrayUtils.get(pr.rs, -1)
                if Math.abs(pr.tr - lr.tr - 2*r) < Math.abs(pr.tr - lr.tr)
                    lr.tr += r
                    pr.tr -= r
                    lr.rs.push(pr.rs.pop())
                    lr.b -= 1
                    pr.e -= 1
                else
                    break

        i   = 0
        targets = []
        tall    = 0
        cs.css({height:'auto', 'margin-top':0, 'margin-right':0, clear:'none'})
        for r in rowsData
            if r.b < r.e
                res = @_resizeRowGroup(row, rowIn, cs.slice(r.b, r.e), gapW, w, i < nr - 1,
                                       false, not vs.hAll)
                tall    = Math.max(tall, res[0])
                targets = ArrayUtils.extend(targets, res[1])
            i++

        if vs.hAll
            @_adjustGroupHeight(vs.rowAlign, targets, tall)

        return

#___________________________________________________________________________________________________ _handleResizeGrid
    _handleResizeGrid: (event) =>
        grid = $(event.currentTarget)
        if not grid.is(':visible')
            return

        # Handles the case where the grid is wrapped for a change in style or accent
        if grid.children().length == 1 and $(grid.children()[0]).hasClass('v-gvml-styleInner')
            gridIn = $(grid.children()[0])
        else
            gridIn = grid

        w     = grid.width()
        cs    = gridIn.children('.v-gvml-gridChild:visible')

        VIZME.exec.data.parseSettings(grid)
        scale = VIZME.exec.styles.globalScale()
        vs    = grid.data('vsets')
        hAll  = if Types.isSet(vs.hAll) then vs.hAll else true
        gapW  = scale*(if Types.isSet(vs.gap) then vs.gap else 8)
        minW  = scale*(if Types.isSet(vs.size) then vs.size else 125)
        rag   = if Types.isSet(vs.rag) then vs.rag else false
        align = if Types.isSet(vs.rowAlign) then vs.rowAlign else 'fill'
        colW  = minW

        ncols = cs.length
        if Types.isSet(vs.maxCols) and vs.maxCols > 0
            ncols = Math.min(ncols, vs.maxCols)

        try
            nrows = Math.ceil(cs.length / ncols)
        catch err
            nrows = 1

        while ncols > 1
            cw = Math.floor((w - (ncols - 1)*gapW) / ncols)
            if cw < minW
                ncols--
            else
                colW = cw
                break
            nrows = Math.ceil(cs.length / ncols)

        if not rag and nrows > 1 and ncols > 2
            while ncols > 1
                r = Math.ceil(cs.length / (ncols - 1))
                if r != nrows
                    break
                ncols--
            colW = Math.floor((w - (ncols - 1)*gapW) / ncols)

        i       = 0
        targets = []
        tall    = 0
        cs.css({height:'auto', 'margin-top':0, 'margin-right':0, clear:'none'})
        while i < nrows
            start   = i*ncols
            end     = Math.min((i + 1)*ncols, cs.length)
            res     = @_resizeRowGroup(grid, gridIn, cs.slice(start, end), gapW, w, i < (nrows - 1),
                                       colW, not hAll)
            tall    = Math.max(tall, res[0])
            targets = ArrayUtils.extend(targets, res[1])
            i++

        if hAll
            @_adjustGroupHeight(align, targets, tall)

        return

#___________________________________________________________________________________________________ _handleAspectResize
    _handleAspectResize: (event) =>
        target = $(event.currentTarget)
        aspect = target.data('vsets').aspect
        if not Types.isSet(aspect)
            aspect = 1.778
        target.height(Math.floor(target.width() / aspect))

        return

#___________________________________________________________________________________________________ _handleResizer
    _handleResizer: (event) =>
        resizer = $(event.currentTarget)
        w       = Math.floor(resizer.width())

        vsets = VIZME.exec.data.parseSettings(resizer)
        if Types.isSet(vsets.maxw)
            w = Math.floor(Math.min(w, vsets.maxw))

        target = resizer.find('.v-resizer-target')
        target.width(w)

        # Handle facebook comment resizing
        fb = target.find('.fb-comments')
        if fb.length > 0
            fb.width(w)
            fb.attr('data-width', w)
            fbif = fb.find('iframe')
            if fbif.length > 0
                fbif.width(w)
