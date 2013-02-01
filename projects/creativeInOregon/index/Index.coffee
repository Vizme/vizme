# vmi.projects.creativeInOregon.index.Index
# Vizme, Inc. (C)2011
# Scott Ernst

class Index

#===================================================================================================
#                                                                                       C L A S S



#===================================================================================================
#                                                                                     P U B L I C

#___________________________________________________________________________________________________ initialize
    initialize: () =>
        $('#twitter-button').click((event) ->
            window.open('http://twitter.com/#!/CreativeOregon', '_blank')
        )

        $('#facebook-button').click((event) ->
            window.open('http://www.facebook.com/CreativeOregon', '_blank')
        )

        $('#google-button').click((event) ->
            window.open('https://plus.google.com/113814424155129471270', '_blank')
        )

        $('.scaleImage').each(
            (index) ->
                me = $(this)
                me.attr('data-width', me.width())
                me.attr('data-height', me.height())
        )

        $(window).resize(@_handleResize)
        @_handleResize()

#===================================================================================================
#                                                                               P R O T E C T E D

#___________________________________________________________________________________________________ _resizeImages
    _resizeImages: (containerWidth, smallLayout) =>
        # Update sizes on each scalable image on the page.
        $('.scaleImage').each(
            (index) ->
                me = $(this)
                nominalWide   = me.attr('data-width')
                nominalHeight = me.attr('data-height')
                aspectRatio   = nominalWide/nominalHeight

                wide = Math.min(containerWidth - 40, nominalWide)
                tall = Math.round(wide/aspectRatio)
                me.width(wide)
                me.height(tall)
        )

#===================================================================================================
#                                                                                 H A N D L E R S


#___________________________________________________________________________________________________ _handleResize
    _handleResize: () =>
        w           = $(window).width() # Width of the window
        h           = $(window).height() # Height of the window
        ww          = Math.max(300, Math.min(910, w - 20)) # Focus width
        smallLayout = w < 760 # Use "mobile" layout or not

        # Adjusts the follow button layout
        fbs = $('.followButton')
        if smallLayout
            css = {display:'block', margin:'5px auto'}
        else
            css = {display:'inline-block', margin:'5px'}
        fbs.css(css)

        # Resizes the main page containers
        c           = $('#container')
        c.width(ww)

        # Adjust background image position
        hh       = h + 50
        backdrop = $('#backdrop')
        backdrop.height(hh)

        pos = 'bottom'
        if hh > 1080
            pos = 'bottom'
        else if h < 800
            pos = 'center'
        else
            pos = 'top'
        backdrop.css('backgroud-position', pos)

        @_resizeImages(c.width(), smallLayout)
