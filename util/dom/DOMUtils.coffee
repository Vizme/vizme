# vmi.util.dom.DOMUtils.coffee
# Vizme, Inc. (C)2011-2012
# Scott Ernst

# require vmi.util.Types
# require vmi.util.color.ColorMixer
# require vmi.util.string.StringUtils
# require vmi.util.url.URLUtils

class DOMUtils

#===================================================================================================
#                                                                                     P U B L I C

    @_screenData

#___________________________________________________________________________________________________ findAndFilter
    @findAndFilter: (selector, arg) ->
        return selector.find(arg).add(selector.filter(arg))

#___________________________________________________________________________________________________ getClasses
# Returns a list of CSS classes for the element of the given ID.
    @getClasses: (id) ->
        return document.getElementById(id).className.split(/\s+/)

#___________________________________________________________________________________________________ htmlEntities
# Functions like PHP's htmlEntities function by escaping DOM characters in the specified string.
    @htmlEntities: (str) ->
        return String(str).replace(/&/g, '&amp;')
                          .replace(/</g, '&lt;')
                          .replace(/>/g, '&gt;')
                          .replace(/"/g, '&quot;')

#___________________________________________________________________________________________________ getScreenData
# Gets the screen DPI by attaching a dpi dom element.
    @getScreenData: () ->
        if @_screenData
            return @_screenData
        $('body').append("<div id='DOMUtilsDPITest' style='width:1in;height:1in;z-index:-1000;
        position:fixed;'></div>")

        target = $('#DOMUtilsDPITest')
        win    = $(window)
        d      = {}
        d.wide = screen.width/target.width()
        d.tall = screen.height/target.height()
        d.dpi  = screen.width/d.wide
        target.remove()

        @_screenData = d
        return d

#___________________________________________________________________________________________________ getFillerElement
    @getFillerElement: (imageURL, identifier, target) ->
        id  = ''
        cls = ''

        if Types.isEmpty(identifier)
            id = ''
        else if StringUtils.startsWith(identifier, '#')
            id = "id='#{identifier.substr(1)}'"
        else if StringUtils.startsWith(identifier, '.')
            cls = "#{identifier.substr(1)}"
        else if identifier
            id = "id='#{identifier}'"

        img = if Types.isEmpty(imageURL) then URLUtils.getLoadingImageURL(target) else imageURL

        return "<div #{id}
        class=\"placholderdisplay #{cls}\"><table style=\"width:100%;height:100%\"><tr>
        <td style=\"text-align:center;vertical-align:middle\"><img src=\"#{img}\" />
        </td></tr></table></div>"
