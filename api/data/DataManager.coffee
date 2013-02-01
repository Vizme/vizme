# vmi.api.data.DataManager.coffee
# Vizme, Inc. (C)2012
# Scott Ernst

# require vmi.api.enum.AttrEnum
# require vmi.util.ArrayUtils
# require vmi.util.ObjectUtils
# require vmi.util.Types

# A class for creating and managing Vizme SVG based icons.
class DataManager

#===================================================================================================
#                                                                                       C L A S S

#___________________________________________________________________________________________________ constructor
# Creates a new StyleManager instance.
    constructor: () ->
        @cls = DataManager

#===================================================================================================
#                                                                                   G E T / S E T

#===================================================================================================
#                                                                                     P U B L I C

#___________________________________________________________________________________________________ render
    render: (rootDOM) =>
        ###Renders all the data items defined within the rootDOM.

        @@@param rootDOM:object
            The root DOM element in which to render the icons.
        ###

        self = this

        if Types.isNone(rootDOM)
            rootDOM = $('body')

        rootDOM.find("[#{AttrEnum.DATA_ID}]").each((index, element) ->
            me   = $(this)
            if not Types.isSet(me.data('vdata'))
                if Types.isSet(me.attr(AttrEnum.DATA))
                    me.data('vdata', JSON.parse(me.attr(AttrEnum.DATA)))
                else
                    me.data('vdata', {})

            if not Types.isSet(me.data('ldata'))
                me.data('ldata', {})
        )

        # Parses vsets on all non-render, non-ui items
        ae = AttrEnum
        rootDOM.find("[#{ae.SETTINGS}]").not("[#{ae.UI_TYPE}] [#{ae.RENDER_ID}]").each((i, e) ->
            self.parseSettings($(e))
        )

#___________________________________________________________________________________________________ renderStatusInit
    renderStatusInit: (item) =>
        if item.data('vrstatus')
            return

        item.data('vrstatus', {})
        return

#___________________________________________________________________________________________________ parseSettings
    parseSettings: (item) =>
        vs = item.data('vsets')
        if vs
            return vs

        vs = item.attr(AttrEnum.SETTINGS)
        if vs
            try
                vs = JSON.parse(vs)
            catch err
                vs = {}
        else
            vs = {}

        item.data('vsets', vs)
        return vs

#===================================================================================================
#                                                                               P R O T E C T E D

#===================================================================================================
#                                                                                 H A N D L E R S
