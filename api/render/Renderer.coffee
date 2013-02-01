# vmi.api.render.Renderer.coffee
# Vizme, Inc. (C)2011-2012
# Scott Ernst

# import vmi.util.module.Module
# require vmi.api.enum.AttrEnum
# require vmi.util.Types
# require vmi.util.canvas.CanvasUtils
# require vmi.util.string.StringUtils

# Absrtact base module for DOM rendered elements (e.g. entities or ui).
class Renderer extends Module

#===================================================================================================
#                                                                                       C L A S S

    @RENDERED = 'done'

    @_RENDER_ON = ['1', 'on', 't', 'true', 'yes']

    @_LOAD_DOM = "<div class='v-rendererLoading'><table><tr><td><canvas></canvas></td></tr></table></div>"

    @_loadingTimer = null
    @_queue        = []

#___________________________________________________________________________________________________ constructor
# Creates an Renderer instance.
    constructor: (libID, renderID, rootClass) ->
        @_libID           = libID
        @_renderID        = if renderID then renderID else libID
        @_rootClass       = rootClass
        @_renderInvisible = true
        if not StringUtils.startsWith(@_rootClass, '.')
            @_rootClass = '.' + @_rootClass

        super(@_libID + '_' + @_renderID)

#===================================================================================================
#                                                                                   G E T / S E T

#___________________________________________________________________________________________________ GS: renderID
    renderID: () =>
        return @_renderID

#___________________________________________________________________________________________________ GS: libID
    libID: () =>
        return @_libID

#===================================================================================================
#                                                                                     P U B L I C

#___________________________________________________________________________________________________ getAll
    getAll: (rootDOM) =>
        rootDOM = if rootDOM then $(rootDOM) else $('body')
        sor     = "[#{AttrEnum.RENDER_ID}^='#{@id()}']"
        return rootDOM.find(sor).add(rootDOM.filter(sor))

#___________________________________________________________________________________________________ render
    render: (rootDOM) =>
        self = this
        dom  = @getAll(rootDOM)
        @_preRender(dom)

        dom.each((i, e) ->
            me = $(e)
            if self.renderReady(me)
                uid = me.attr('data-v-uid')
                if Types.isString(uid)
                    $("[data-v-targetuid=#{uid}]").remove()
                else
                    Renderer.addUID(me)

                if not self._renderInvisible and not me.is(':visible')
                    self._addToRenderLoopQueue(self, me)
                else
                    payload = {me:me, settings:self._getVSettings(me)}
                    self._renderElement(self, payload)
        )
        VIZME.exec.styles.registerBorderClassesInDOM(dom)

        @_postRender(dom)

#___________________________________________________________________________________________________ resize
    resize: (rootDOM) =>
        self    = this
        rootDOM = if Types.isNone(rootDOM) then $('body') else rootDOM
        dom     = @getAll(rootDOM)
        @_preResize(dom, rootDOM)

        dom.each((i, e) ->
            me = $(e)
            if Renderer.isRendered(me)
                settings = me.data('vsets')
                self._resizeElement(self, me, settings)
        )

        @_postResize(dom, rootDOM)

#___________________________________________________________________________________________________ renderReady
    renderReady: (dom) =>
        d   = $(dom)
        res = Types.isEmpty(d.attr(AttrEnum.RENDER))
        return res or ArrayUtils.contains(Renderer._RENDER_ON, d.attr(AttrEnum.RENDER))

#___________________________________________________________________________________________________ isRendered
    @isRendered: (dom) ->
        return $(dom).attr(AttrEnum.RENDER) == Renderer.RENDERED

#___________________________________________________________________________________________________ getActiveComponents
    @getActiveComponents: (rootDOM, unloadedOnly, componentType) ->
        comps   = {libs:[], renders:[], eles:{}, rids:[], loads:[], uids:[]}
        rootDOM = if rootDOM then $(rootDOM) else $('body')

        sor = "[#{AttrEnum.RENDER_ID}]"
        rootDOM.find(sor).add(rootDOM.filter(sor)).each((index, element) ->
            me  = $(this)
            rid = me.attr(AttrEnum.RENDER_ID)
            if ArrayUtils.contains(comps.rids, rid)
                return

            uid = Renderer.addUID(me)
            cs  = rid.split('_')
            r   = if cs.length > 1 then cs[1].split(':') else [cs[0]]
            a   = false

            if not ArrayUtils.contains(comps.libs, cs[0])
                comps.libs.push(cs[0])
            if not ArrayUtils.contains(comps.renders, r[0])
                comps.renders.push(r[0])

            if not VIZME.exec.hasLibrary(cs[0], false) and not ArrayUtils.contains(comps.loads, cs[0])
                comps.loads.push(cs[0])

            if r.length > 1 and not comps.eles[r[1]]
                v       = {}
                v.ini   = me.attr(AttrEnum.INI)
                v.rid   = me.attr(AttrEnum.RENDER_ID)
                v.id    = me.attr('id')
                v.class = me.attr('class')
                comps.eles[r[1]] = v

            comps.rids.push(rid)
            comps.uids.push(uid)
        )
        comps.libs    = comps.libs.sort()
        comps.loads   = comps.loads.sort()
        comps.renders = comps.renders.sort()
        comps.rids    = comps.rids.sort()
        comps.uids    = comps.uids.sort()

        if Types.isString(componentType)
            return comps[compontentType]
        else
            return comps

#___________________________________________________________________________________________________ showElementLoading
    @showElementLoading: (target) ->
        if Types.isString(target)
            uid    = target
            target = $("[#{AttrEnum.UID}='#{target}']")
        else
            uid    = target.attr(AttrEnum.UID)

        targetAttr = 'data-v-targetuid'
        if Types.isString(uid)
            # Skip elements that already have a loader
            if $("[#{targetAttr}='#{uid}']").length > 0
                return
        else
            uid = Renderer.addUID(target)

        size   = Math.max(24, Math.min(32, Math.min(target.height(), target.width())))
        sizePX = size + 'px'
        bars   = Math.floor(size/4)
        data   = {'s':size, 'spx':sizePX, 'target':target, 'i':0, 'bars':bars}

        d      = $(Renderer._LOADING_DOM)
        d.appendTo($('body'))
        d.css('background-color', target.css('background-color'))

        c      = d.find('canvas')
        c.attr({'height':sizePX, 'width':sizePX, 'data-v-targetuid':uid})
        d.data('vsets', data)

        if Types.isNone(Renderer._loadingTimer)
            Renderer._loadingTimer = setInterval(Renderer._drawLoading, 240)

#___________________________________________________________________________________________________ addUID
    @addUID: (element) ->
        uid = element.attr(AttrEnum.UID)
        if uid
            return uid

        uid = StringUtils.getRandom(16)
        element.attr(AttrEnum.UID, uid)
        return uid

#___________________________________________________________________________________________________ renderQueuedItems
    @renderQueuedItems: () ->
        removes = []
        for r in Renderer._queue
            if r.t.is(':visible')
                removes.push(r)
                r.t.attr(AttrEnum.RENDER, null)
                r.r.render(r.t)

        for r in removes
            ArrayUtils.remove(Renderer._queue, r)

#===================================================================================================
#                                                                               P R O T E C T E D

#___________________________________________________________________________________________________ _addToRenderLoopQueue
    _addToRenderLoopQueue: (renderer, target) =>
        if target.attr(AttrEnum.RENDER) == 'queued'
            return

        target.attr(AttrEnum.RENDER, 'queued')
        Renderer._queue.push({'r':renderer, 't':target})

#___________________________________________________________________________________________________ _parseJSONAttr
    _parseJSONAttr: (target, attr, defaultValue) =>
        a = target.attr(attr)
        if Types.isString(a)
            try
                return JSON.parse(a)
            catch err
                return defaultValue

        return defaultValue

#___________________________________________________________________________________________________ _getVSettings
    _getVSettings: (target) =>
        return @_parseJSONAttr(target, AttrEnum.SETTINGS, {})

#___________________________________________________________________________________________________ _resizeOn
    _resizeOn: (target) =>
        $(target).resize(@_handleResize)

#___________________________________________________________________________________________________ _preRender
    _preRender: (dom) =>

#___________________________________________________________________________________________________ _postRender
    _postRender: (dom) =>

#___________________________________________________________________________________________________ _renderElement
    _renderElement: (self, payload) =>
        payload = @_renderElementImpl(self, payload)
        payload.me.attr(AttrEnum.RENDER, Renderer.RENDERED)
        payload.me.data('vsets', payload.settings)
        VIZME.exec.icons.render(payload.me)
        @_resizeElement(self, payload.me, payload.settings)

        root = payload.me.parents('.v-gvml-resize').last()
        if root.length
            VIZME.resize(root, true)

        return true

#___________________________________________________________________________________________________ _renderElementImpl
    _renderElementImpl: (self, payload) =>
        return payload

#___________________________________________________________________________________________________ _preResize
    _preResize: (dom) =>

#___________________________________________________________________________________________________ _postResize
    _postResize: (dom) =>

#___________________________________________________________________________________________________ _resizeElement
    _resizeElement: (self, me, settings) =>

#___________________________________________________________________________________________________ _resizeLoading
    @_resizeLoading: () ->
        $('.v-rendererLoading').each((index, element) ->
            me   = $(this)
            data = me.data('vsets')
            t    = data.target
            o    = t.offset()
            me.css({'width':t.width(), 'height':t.height(), 'top':o.top, 'left':o.left})
        )

#___________________________________________________________________________________________________ _drawLoading
    @_drawLoading: () ->
        $('.v-rendererLoading').each((index, element) ->
            me     = $(this)
            ctx    = CanvasUtils.getContext(me.find('canvas'))
            data   = me.data('vsets')
            center = Math.round(data.s / 2)
            radius = Math.round(center/2)

            if data.i == 0
                ctx.clearRect(0, 0, data.s, data.s)

            ctx.save()
            ctx.strokeStyle = data.target.css('color')
            ctx.lineWidth   = radius

            ctx.beginPath()
            s = Math.floor(2*Math.PI*data.i / data.bars)
            e = (s + Math.floor(2*Math.PI*(data.i + 1) / data.bars)) / 2

            ctx.arc(center, center, radius, s, e, false)
            ctx.stroke()
            ctx.restore()

            data.i = if data.i < data.bars - 1 then data.i + 1 else 0
        )


#===================================================================================================
#                                                                                 H A N D L E R S

#___________________________________________________________________________________________________ _handleResize
    _handleResize: (event) =>
        rootDOM = $(event.currentTarget).parents(@_rootClass)
        if rootDOM.attr(AttrEnum.RENDER) == Renderer.RENDERED
            @_resizeElement(this, rootDOM, rootDOM.data('vsets'))

