# vmi.shared.markup.MarkupImages
# Vizme, Inc. (C)2011-2012
# Scott Ernst

class MarkupImages

#===================================================================================================
#                                                                                       C L A S S

#___________________________________________________________________________________________________ resizeImages
    @resizeImages: (containerWidth, smallLayout) ->
        # Update sizes on each markupImage on the page.
        $('.markupImage').each(
            (index) ->
                me = $(this)
                nominalWide   = me.attr('data-width')
                nominalHeight = me.attr('data-height')
                normalClass   = me.attr('data-class')
                aspectRatio   = nominalWide/nominalHeight

                wide = Math.min(containerWidth, nominalWide)
                tall = Math.round(wide/aspectRatio)
                me.width(wide)
                me.height(tall)

                if smallLayout
                    me.removeClass(normalClass)
                    me.addClass('smallMarkupImages')
                else
                    me.addClass(normalClass)
                    me.removeClass('smallMarkupImages')
        )