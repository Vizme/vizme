# vmi.shared.error.Error.coffee
# Vizme, Inc. (C)2012
# Scott Ernst

# import vmi.util.module.DisplayModule
# require vmi.util.url.URLUtils

# Full page Error display module.
class Error extends DisplayModule

#===================================================================================================
#                                                                                   P R I V A T E

    # Module ID
    @ID = 'error'

#___________________________________________________________________________________________________ constructor
    constructor: () ->
        super(Error.ID, "#p-response-container")
        @_isOpen    = false
        @_activated = false

#===================================================================================================
#                                                                                     P U B L I C

#___________________________________________________________________________________________________ initialize
# Initializes the Introduction module.
    initialize: () =>
        if not super()
            return false

        VIZME.addEventListener('continue-button', @_handleContinue)

        return true

#___________________________________________________________________________________________________ resize
    resize: () =>
        win = $(window)
        ww  = win.width()
        wh  = win.height()

        c = $('#container')
        c.width(ww)
        c.height(wh)

        con = $('#p-response-container')
        con.width(ww)
        con.height(wh)

        box = $('.p-responseBox')
        box.css({width:'auto', top:0, left:0})

        bmw = Math.min(640, ww - 60)
        bw  = if box.is(':visible') then Math.max(box.width(), 320) else bmw
        bw  = Math.min(bw, bmw)
        box.width(bw)

        bh  = if box.is(':visible') then box.height() else Math.round(wh/2)

        bleft = Math.max(0, Math.round((ww - bw) / 2))
        btop  = Math.min(Math.max(0, Math.round((wh - bh) / 2)), 200)
        box.css({top:btop + 'px', left:bleft + 'px'})

        focus = $('.p-backSpacer')
        focus.height(wh)
        VIZME.render(focus.parents('.v-GB'))

#===================================================================================================
#                                                                               P R O T E C T E D



#===================================================================================================
#                                                                                 H A N D L E R S

#___________________________________________________________________________________________________ _handleContinue
    _handleContinue: (event) =>
        try
            window.close()
        catch err

        # If the window doesn't close load the home page instead.
        window.location.href = URLUtils.getURL()