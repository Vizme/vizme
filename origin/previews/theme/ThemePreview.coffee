# vmi.origin.editors.style.ThemePreview.coffee
# Vizme, Inc. (C)2012
# Scott Ernst

# import vmi.util.module.DisplayModule

class ThemePreview extends DisplayModule

#===================================================================================================
#                                                                                       C L A S S

    @ID = 'themePreview'

#___________________________________________________________________________________________________ constructor
# Creates a new Login module instance.
    constructor: () ->
        super(ThemePreview.ID, '#theme-container')

#===================================================================================================
#                                                                                     P U B L I C

#___________________________________________________________________________________________________ initialize
# Intializes the module.
    initialize: () =>
        return super()

#___________________________________________________________________________________________________ resize
# Resizes the module
    resize: () =>
        super()
        w    = @me().width()
        cw   = Math.floor(w/2) - 5

        cons = $('.p-styleContainer')
        if cw < 420
            cons.css('float', 'none')
            cons.width(Math.min(640, w))
        else
            cons.width(cw)
            $('#normal-container').css('float', 'left')
            $('#accent-container').css('float', 'right')

        return

#===================================================================================================
#                                                                               P R O T E C T E D
