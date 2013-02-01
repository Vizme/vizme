# vmi.api.render.ElementRenderer.coffee
# Vizme, Inc. (C)2011-2012
# Scott Ernst

# import vmi.api.render.Renderer
# require vmi.api.enum.AttrEnum

# Absrtact base module for DOM rendered elements (e.g. entities or ui).
class ElementRenderer extends Renderer

#===================================================================================================
#                                                                                       C L A S S

    @_elementData = {}

#___________________________________________________________________________________________________ constructor
# Creates an APIManager module instance.
    constructor: (libID, renderID) ->
        super(libID, renderID)

#===================================================================================================
#                                                                                   G E T / S E T

#===================================================================================================
#                                                                                     P U B L I C

#___________________________________________________________________________________________________ addElementData
    @addElementData: (data) ->
        if Types.isNone(data)
            return

        for n,v of data
            ElementRenderer._elementData[n] = v

#===================================================================================================
#                                                                               P R O T E C T E D

#___________________________________________________________________________________________________ _renderElement
    _renderElement: (self, payload) =>
        s  = payload.settings
        me = payload.me

        # Replaces the placeholder DOM with the fully rendered DOM returned by the server
        if me.attr(AttrEnum.RENDER_ID).indexOf(':') != -1
            me.removeAttr('id')
            newMe = $(s.dom)
            me.before(newMe)
            me.remove()
            payload.me = newMe
            payload.settings = if s.sets then s.sets else {}

        @_updateAttributes(me, s)
        return super(self, payload)

#___________________________________________________________________________________________________ _getVSettings
    _getVSettings: (target) =>
        eleID = @_getElementID(target)
        if eleID
            return ElementRenderer._elementData[eleID]
        else
            return super(target)

#___________________________________________________________________________________________________ _getElementID
    _getElementID: (target) =>
        rid = target.attr(AttrEnum.RENDER_ID)
        if Types.isNone(rid) or rid.indexOf(':') == -1
            return ''

        return rid.split(':')[1]

#___________________________________________________________________________________________________ _updateAttributes
    _updateAttributes: (me, settings) =>
        me.addClass(@_rootClass.substr(1))

        if Types.isSet(settings.classes)
            for v in settings.classes
                me.addClass(v)

        if Types.isSet(settings.styles)
            for n,v of settings.styles
                me.css(n, v)

#===================================================================================================
#                                                                                 H A N D L E R S
