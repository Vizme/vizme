# vmi.api.render.gui.BackdropRenderer.coffee
# Vizme, Inc. (C)2011-2012
# Scott Ernst

# import vmi.api.render.ElementRenderer
# require vmi.util.Types

# renderer for page footers.
class FooterRenderer extends ElementRenderer

#===================================================================================================
#                                                                                       C L A S S

    @LIB_ID     = 'nav'
    @RENDER_ID  = 'FOOT'
    @ROOT_CLASS = '.v-FOOT'

#___________________________________________________________________________________________________ constructor
# Creates an APIManager module instance.
    constructor: () ->
        super(FooterRenderer.LIB_ID, FooterRenderer.RENDER_ID, FooterRenderer.ROOT_CLASS)
        @_autoResize = true

#===================================================================================================
#                                                                                   G E T / S E T

#===================================================================================================
#                                                                                     P U B L I C

#===================================================================================================
#                                                                               P R O T E C T E D

#___________________________________________________________________________________________________ _renderElementImpl
    _renderElementImpl: (self, payload) =>
        payload.settings.spacer = payload.me.parents('.v-FOOT-spacer')
        return super(self, payload)

#___________________________________________________________________________________________________ _resizeElement
    _resizeElement: (self, me, settings) =>
        cls   = FooterRenderer
        win   = $(window)
        outer = $('.v-scrollContainer')
        inner = $('.v-scrollContainerInner')
        if not outer.length
            outer     = win
            inner     = win
            scrollerH = 0
            viewH     = win.height()
        else
            scrollerH = inner.height()
            viewH     = outer.height()

        w     = outer.width()
        h     = 0

        footerIn = $('.v-FOOT-inner')
        footerIn.css('padding-bottom', '20px')

        footer = $(cls.ROOT_CLASS)
        spacer = settings.spacer
        fh     = footer.innerHeight()
        wh     = Math.max(inner.height(), win.height())
        spacer.height(footer.height() - 20)

        if (wh > spacer.position().top + fh) and (scrollerH <= viewH)
            footer.css({position:'fixed', top:(wh - fh + 20) + 'px', left:'0'})
        else
            footer.css('position', 'static')

        super(self, me, settings)

#===================================================================================================
#                                                                                 H A N D L E R S

