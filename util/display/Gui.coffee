# vmi.util.Gui.coffee
# Vizme, Inc. (C)2010-2011
# Scott Ernst

# import vmi.util.module.Module
# require vmi.util.Types

# The TopBar module represents the statically placed command bar for the main site and includes
# navigation, status, and other control user-interface elements.
class Gui extends Module

#===================================================================================================
#                                                                                       C L A S S

    @BUTTON_DOM = '<div ##ID## class="##BC##" data-cb="##CBID##"><div class="##BHC##">' +
                  '<p class="noselect">##L##</p></div></div>'

    # Module identifier
    @ID = 'gui'

#___________________________________________________________________________________________________ constructor
    constructor: () ->
        super(Gui.ID)
        @_callbackIndex = 0
        @_callbacks     = {}
        @_data          = {}

#===================================================================================================
#                                                                                     P U B L I C

#___________________________________________________________________________________________________ initialize
# Initializes the Gui module.
    initialize: () =>
        return super()

#___________________________________________________________________________________________________ resize
    resize: () =>
        ws = $('[data-v-wide]')
        ws.css('width', 'auto')
        ws.each((index, element) ->
            me   = $(this)

            if not me.is(':visible')
                return

            wa   = me.attr('data-v-wide').split(',')
            minW = parseInt(wa[0])
            maxW = if wa.length > 1 then parseInt(wa[1]) else minW
            if me.width() > maxW
                me.width(maxW)
            else if me.width() < minW
                me.width(minW)
        )

        #-------------------------------------------------------------------------------------------
        # Resize any control boxes in the DOM
        $('.v-CONBOX-LabelColumn').css('width', 'auto')
        $('.v-CONBOX').each((index, element) ->
            me     = $(this)

            if not me.is(':visible')
                return

            w      = 0
            lboxes = $('.v-CONBOX-Label', me)
            labels = $('.v-CONBOX-Label', me)

            for l in lboxes
                w = Math.max($(l).width(), w)

            $('.v-CONBOX-LabelColumn', me).css('width', Math.max(Math.min(w + 10, 250), 20) + 'px')
        )

        #-------------------------------------------------------------------------------------------
        # Resize control box sliders
        $('.v-CON-slider').each((index, element) ->
            me = $(this)
            me.find('.v-CON-sliderBoundValue').each((index, element) ->
                bound = $(this)
                bound.css('width', 'auto')
                bound.width(bound.find('div').width())
            )
            me.find('.v-CON-sliderWidget').trigger('slidechange')
        )

        #-------------------------------------------------------------------------------------------
        # Resize lists
        $('.v-CON-list').each((index, element) ->
            me    = $(this)
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
        )

#___________________________________________________________________________________________________ createButton
    createButton: (buttonID, type, label, callback, data) =>
        switch type
            when 'gray'
                bc  = 'graybutton'
                bhc = 'graybuttonhighlight'

            else
                bc  = 'redbutton'
                bhc = 'redbuttonhighlight'

        @_callbackIndex++
        cbid = 'b' + @_callbackIndex
        @_callbacks[cbid] = callback
        @_data[cbid]      = data

        bid = if buttonID then 'id=' + buttonID else ''
        lbl = if label then label else 'OK'
        dom = Gui.BUTTON_DOM.replace('##ID##', bid).
                             replace('##CBID##', cbid).
                             replace('##BC##', bc).
                             replace('##BHC##', bhc).
                             replace('##L##', lbl)

        d = $(dom)
        d.click(@_handleClickCallback)
        return d

#===================================================================================================
#                                                                                 H A N D L E R S

#___________________________________________________________________________________________________ _handleClickCallback
    _handleClickCallback: (event) =>
        cbid = $(event.currentTarget).attr('data-cb')
        if Types.isFunction(@_callbacks[cbid])
            @_callbacks[cbid](@_data[cbid])