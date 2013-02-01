# vmi.api.render.gui.GraphRenderer.coffee
# Vizme, Inc. (C)2012
# Scott Ernst

# import vmi.api.render.ElementRenderer
# require vmi.api.enum.AttrEnum
# require vmi.util.ArrayUtils
# require vmi.util.NumberUtils
# require vmi.util.TextUtils
# require vmi.util.Types
# require vmi.util.dom.DOMUtils
# require vmi.util.time.DataTimer
# require vmi.util.url.URLUtils

class GraphRenderer extends ElementRenderer

#===================================================================================================
#                                                                                       C L A S S

    @LIB_ID     = 'graph'
    @RENDER_ID  = 'GRAPH'
    @ROOT_CLASS = '.v-GRAPH'

#___________________________________________________________________________________________________ constructor
# Creates an APIManager module instance.
    constructor: () ->
        super(GraphRenderer.LIB_ID, GraphRenderer.RENDER_ID)
        @_renderInvisible = false

#===================================================================================================
#                                                                                   G E T / S E T

#===================================================================================================
#                                                                                     P U B L I C

#===================================================================================================
#                                                                               P R O T E C T E D

#___________________________________________________________________________________________________ _renderElementImpl
    _renderElementImpl: (self, payload) =>
        cls  = GraphRenderer
        me   = payload.me
        sets = payload.settings
        data = sets.data
        opts = sets.opts

        me.height(Math.max(240, Math.round(me.width() / sets.aspect)))
        target = me.find('.v-GRAPH-inner')
        target.width(me.width())
        target.height(me.height())
        sets.plot = $.plot(target, data, opts)

        me.resize((event) ->
            e     = $(event.currentTarget)
            if not e.is(':visible')
                return

            vsets = e.data('vsets')
            e.height(Math.max(240, Math.round(e.width() / vsets.aspect)))
            plot  = e.find('.v-GRAPH-inner')
            plot.width(e.width())
            plot.height(e.height())
        )

        return super(self, payload)

#___________________________________________________________________________________________________ _resizeElement
    _resizeElement: (self, me, settings) =>
        me.height(Math.round(me.width() / settings.aspect))
        target = me.find('.v-GRAPH-inner')
        target.width(me.width())
        target.height(me.height())
        p = settings.plot
        p.resize()
        p.setupGrid()
        p.draw()

#===================================================================================================
#                                                                                 H A N D L E R S
