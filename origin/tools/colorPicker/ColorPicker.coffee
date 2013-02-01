# ColorPicker.coffee
# Vizme, Inc. (C)2012
# Scott Ernst

# import vmi.util.module.ContainerDisplayModule
# require vmi.util.Types

class ColorPicker extends ContainerDisplayModule

#===================================================================================================
#                                                                                       C L A S S

    # Module identifier
    @ID = 'colorPicker'

    @_FOCAL_FILTER_CSS = 'v-S-fcl p-filterSelect v-S-bckm1'

#___________________________________________________________________________________________________ constructor
# Creates a new Login module instance.
    constructor: () ->
        super(ColorPicker.ID, "#color-container")

#===================================================================================================
#                                                                                     P U B L I C

#___________________________________________________________________________________________________ initialize
# Intializes the Login module for use.
    initialize: () =>
        cls = ColorPicker

        if not super()
            return false

        fs = $('.p-filter')
        fs.addClass('v-hoverLink v-S-borh v-S-sft')
        fs.click((event) ->
            target = $(event.currentTarget)
            $('.p-filter').removeClass(cls._FOCAL_FILTER_CSS).addClass('v-S-sft')
            target.removeClass('v-S-sft').addClass(cls._FOCAL_FILTER_CSS)
            $('.p-color').hide()
            if target.hasClass('p-filterTag')
                $(".p-ctag-#{target.html().substr(0,3).toLowerCase()}").show()
            else
                $(".p-abc-#{target.html().toLowerCase()}").show()

            #VIZME.resize()
            $('.p-colorList').resize()
        )

        box = $('.p-colorList')
        dom = PAGE.COLOR_DOM
        i   = 0
        for col in PAGE.COLORS
            color = new ColorMixer(col[0])
            css   = ['p-abc-' + col[1].substr(0,1).toLowerCase()]
            if col[2].length > 0
                n = Math.floor(col[2].length / 3)
                for j in [0...n]
                    css.push('p-ctag-' + col[2].substr(3*j, 3))

            c = $(dom.replace('#ID#', 'col' + i).
                           replace('#C#', col[0]).
                           replace('#V#', col[0]).
                           replace('#BC#', color.getBendShifts('hex', 1)[0]).
                           replace('#N#', col[1])
            ).addClass(css.join(' '))
            box.append(c)
            i++

        $('.p-color').hide()

        box.addClass('v-gvml-grid')
        VIZME.render()

        $($('.p-filter')[0]).click()

        return true

#___________________________________________________________________________________________________ resize
# Resizes the module.
    resize: () =>

#===================================================================================================
#                                                                               P R O T E C T E D


#===================================================================================================
#                                                                                 H A N D L E R S

