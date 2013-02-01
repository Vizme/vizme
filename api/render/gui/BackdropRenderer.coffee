# vmi.api.render.gui.BackdropRenderer.coffee
# Vizme, Inc. (C)2011-2012
# Scott Ernst

# import vmi.api.render.GuiRenderer
# require vmi.api.enum.AttrEnum
# require vmi.util.Types
# require vmi.util.url.URLUtils

# UI renderer for gradient based backdrops.
class BackdropRenderer extends GuiRenderer

#===================================================================================================
#                                                                                       C L A S S

    @RENDER_ID  = 'GB'
    @ROOT_CLASS = '.v-GB'

    @_BACK_IMAGE   = 'url("#IMG#grad/#TN#/#S#/#C1#/#C2#")'

    @_BACKDROP_DOM = '<div class="v-GB-Box">' +
        '<div class="v-GB-Back"><div class="v-GB-Row v-GB-T ' +
        'v-GB-H"><div class="v-GB-TL v-GB-WH"></div><div class="v-GB-TR  ' +
        'v-GB-WH"></div></div><div class="v-GB-Row"><div class="v-GB-L v-GB-W">' +
        '</div><div class="v-GB-R  v-GB-W"></div></div><div class="v-GB-Row v-GB-B ' +
        'v-GB-H"><div class="v-GB-BL v-GB-WH"></div><div class="v-GB-BR  v-GB-WH">' +
        '</div></div></div></div>'

    @_SIZES = {xxs:8, xs:16, s:32, m:64, l:128, xl:256, xxl:512}

#___________________________________________________________________________________________________ constructor
# Creates an APIManager module instance.
    constructor: () ->
        super(BackdropRenderer.RENDER_ID)

#===================================================================================================
#                                                                                   G E T / S E T

#===================================================================================================
#                                                                                     P U B L I C

#===================================================================================================
#                                                                               P R O T E C T E D

#___________________________________________________________________________________________________ _renderElementImpl
    _renderElementImpl: (self, payload) =>
        me       = payload.me
        settings = payload.settings
        cls      = BackdropRenderer
        target   = me.clone()
        me.removeAttr('id')
        me.removeClass().addClass('v-GB-Focus')
        me.removeAttr(AttrEnum.RENDER_ID)
        me.removeAttr(AttrEnum.DATA_ID)

        target.empty()
        target.insertBefore(me)
        target.addClass('v-GB')
        target.append(cls._BACKDROP_DOM)

        focus = me
        me    = target
        focus.appendTo(me.find('.v-GB-Box'))
        me.css({padding:'0'})
        focus.css({width:'auto', margin:'0', border:'none', 'box-shadow':'none'})
        @_resizeOn(focus)

        if not Types.isNumber(settings.s)
            if not StringUtils.isNumeric(settings.s)
                s = settings.s.toLowerCase()
                for n,v of cls._SIZES
                    if StringUtils.startsWith(s, n)
                        settings.s = v
                        break
            else
                settings.s = parseInt(settings.s, 10)
        if not Types.isNumber(settings.s)
            settings.s = 16

        gs = Math.round(settings.s/2)
        me.find('.v-GB-Back').css('background-color', settings.c)

        iw = Math.max(settings.s, me.width() - settings.s)
        ih = Math.max(settings.s, me.height() - settings.s)
        s_cb = 'background-image'
        s_bp = 'background-position'
        ip   = '-' + gs + 'px'

        cnrs = me.find('.v-GB-WH').width(gs).height(gs)
        bars = me.find('.v-GB-H').height(gs)
        plls = me.find('.v-GB-W').width(gs).height(ih)
        switch settings.t
            when 'bottom'
                me.find('.v-GB-B').css(s_cb, self._getBackImage(settings, 'v'))
            when 'top'
                me.find('.v-GB-T').css(s_cb, self._getBackImage(settings, 'v'))
            else
                cnrs.css(s_cb, self._getBackImage(settings, 'b'))
                bars.css(s_cb, self._getBackImage(settings, 'v'))
                plls.css(s_cb, self._getBackImage(settings, 'h'))

        me.find('.v-GB-B').css(s_bp,  '0 ' + ip)
        me.find('.v-GB-BL').css(s_bp, '0 ' + ip)
        me.find('.v-GB-R').css(s_bp,  ip + ' 0')
        me.find('.v-GB-TR').css(s_bp, ip + ' 0')
        me.find('.v-GB-BR').css(s_bp, ip + ' ' + ip)

        payload.me       = me
        payload.settings = settings
        return super(self, payload)

#___________________________________________________________________________________________________ _resizeElement
    _resizeElement: (self, me, settings) =>
        me.css('height', 'auto')
        box   = me.find('.v-GB-Box')
        focus = box.find('.v-GB-Focus')
        focus.css('margin-top', '0')
        focus.width(box.width())

        gs = Math.round(settings.s/2)
        h  = Math.max(2*settings.s, focus.innerHeight())
        me.height(h)
        box.height(h)
        me.find('.v-GB-W').height(Math.max(settings.s, h - settings.s))

        if settings.va == 'm'
            hOff = Math.max(0, Math.floor(0.5*(h - focus.height())))
            focus.css('margin-top', hOff)
        super(self, me, settings)

#___________________________________________________________________________________________________ _getBackImage
    _getBackImage: (sets, backType) =>
        c = (if sets.c.length < 6 then sets.c + sets.c else sets.c).replace(/#/g,'')
        if sets.d
            d = (if sets.d.length < 6 then sets.d + sets.d else sets.d).replace(/#/g,'')
        else
            d = '~'

        return BackdropRenderer._BACK_IMAGE.replace('#TN#', backType).
                                            replace('#S#', sets.s + '').
                                            replace('#C1#', c).
                                            replace('#C2#', d).
                                            replace('#IMG#', URLUtils.getImageURL())

#===================================================================================================
#                                                                                 H A N D L E R S

