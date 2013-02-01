# vmi.api.render.gui.NavBarRenderer.coffee
# Vizme, Inc. (C)2012
# Scott Ernst

# import vmi.api.render.ElementRenderer
# require vmi.api.enum.AttrEnum
# require vmi.util.Types


# Element renderer for Navigation bars.
class NavBarRenderer extends ElementRenderer

#===================================================================================================
#                                                                                       C L A S S

    @LIB_ID     = 'nav'
    @RENDER_ID  = 'NVB'
    @ROOT_CLASS = '.v-NVB'

#___________________________________________________________________________________________________ constructor
# Creates a NavBarRenderer instance.
    constructor: () ->
        super(NavBarRenderer.LIB_ID, NavBarRenderer.RENDER_ID,
              NavBarRenderer.ROOT_CLASS)
        @_autoResize = true

#===================================================================================================
#                                                                                   G E T / S E T

#===================================================================================================
#                                                                                     P U B L I C

#===================================================================================================
#                                                                               P R O T E C T E D

#___________________________________________________________________________________________________ _renderElementImpl
    _renderElementImpl: (self, payload) =>
        if payload.settings.fixed
            me.addClass('v-NVB-fixed')
            spacer = $('<div class="v-NVB-spacer"></div>')
            payload.me.after(spacer)
            payload.settings.spacer = spacer

        return super(self, payload)

#___________________________________________________________________________________________________ _resizeElement
    _resizeElement: (self, me, settings) =>
        if settings.spacer
            spacer.height(me.height() + 10)

#===================================================================================================
#                                                                                 H A N D L E R S

