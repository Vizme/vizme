# vmi.api.display.IconManager.coffee
# Vizme, Inc. (C)2012
# Scott Ernst

# require vmi.api.enum.AttrEnum
# require vmi.util.ArrayUtils
# require vmi.util.ObjectUtils
# require vmi.util.Types

# A class for creating and managing Vizme SVG based icons.
class IconManager

#===================================================================================================
#                                                                                       C L A S S

    @_WRAP_DOM = '<div class="v-svgIcon" style="width:#S#;height:#S#">#SVG#</div>'

    @_SVG_DOM = '<svg version="1.1" x="0px" y="0px" width="#S#" height="#S#" viewBox="#X# #X# #BW# #BW#" ' +
                'enable-background="new #X# #X# #BW# #BW#">#D#</svg>'

    @_NORMAL_CLASSES = 'v-S-fbn v-hoverLink'
    @_INVERT_CLASSES = 'v-S-bbnfront v-hoverLink'

    @_requestedLibraries = []
    @_icons              = {}
    @_requests           = []

#___________________________________________________________________________________________________ constructor
# Creates a new StyleManager instance.
    constructor: () ->
        @cls = IconManager

#===================================================================================================
#                                                                                   G E T / S E T

#===================================================================================================
#                                                                                     P U B L I C

#___________________________________________________________________________________________________ render
    render: (rootDOM) =>
        ###Renders all the icons defined within the rootDOM.

        @@@param rootDOM:object
            The root DOM element in which to render the icons.
        ###

        if Types.isNone(rootDOM)
            rootDOM = $('body')

        replace = @replace
        cls     = IconManager
        rootDOM.find("[#{AttrEnum.ICON}]").not('.v-svgIcon').each((index, element) ->
            me      = $(this)
            data    = me.attr(AttrEnum.ICON)
            try
                data = JSON.parse(data)
            catch err

            lib     = if data.lib then data.lib else 'BASIC'
            icon    = if data.icon then data.icon else 'x'
            fill    = if data.fill then data.fill else 0.8
            size    = if data.size then data.size else null
            classes = if data.classes then data.classes else ''
            color   = if data.color then data.color else ''
            resize  = if data.resize then data.resize else false
            if data.mode == 'NORMAL'
                classes = cls._NORMAL_CLASSES
            else if data.mode == 'INVERT'
                classes = cls._INVERT_CLASSES
            replace(me, lib, icon, classes, color, size, fill, resize)
        )

#___________________________________________________________________________________________________ load
    load: (libIDs) =>
        ###Determines whether or not the specified style (name/uid/id) is already loaded and
        available for use.

        @@@param style:string
            The style name/uid/id to check.

        @@@return boolean
            Whether or not the style already exists.
        ###

        if Types.isEmpty(libIDs)
            return

        # Only load libraries that haven't already been requested or loaded
        libIDs = if Types.isString(libIDs) then [libIDs] else libIDs
        libs   = []
        for l in libIDs
            l = l.toUpperCase()
            if ArrayUtils.contains(@cls._requestedLibraries, l)
                continue
            @cls._requestedLibraries.push(l)
            libs.push(l)

        if libs.length == 0
            return

        url = "iconLib/#{URLUtils.createCacheString()}/#{encodeURI(libs.join('+'))}"
        s   = "<script type='text/javascript' src='#{URLUtils.getJSURL() + url}'></script>"
        $('head').append(s)

#___________________________________________________________________________________________________ addTo
    addTo: (target, libID, iconID, classes, color, size, fill, resize) =>
        @_createRequest(target, libID, iconID, classes, color, size, fill, resize, 'APPEND')

#___________________________________________________________________________________________________ replace
    replace: (target, libID, iconID, classes, color, size, fill, resize) =>
        @_createRequest(target, libID, iconID, classes, color, size, fill, resize, 'REPLACE')

#___________________________________________________________________________________________________ populateLibrary
    populateLibrary: (libID, data) =>
        ###Sets the specified library as loaded and ready for use.###

        @cls._icons[libID.toUpperCase()] = data
        @_processRequests()

#===================================================================================================
#                                                                               P R O T E C T E D

#___________________________________________________________________________________________________ _createRequest
    _createRequest: (target, libID, iconID, classes, color, size, fill, resize, insertMode) =>
        if fill
            fill = parseFloat(fill)
            fill = if fill > 1 then fill / 100 else fill
        else
            fill = 0.8

        libID   = libID.toUpperCase()
        iconID  = iconID.toLowerCase()
        request = {
            target:target,
            lib:libID,
            icon:iconID,
            css:classes,
            color:color,
            size:size,
            fill:fill,
            insertMode:insertMode,
            resize:resize
        }

        if @cls._icons[libID]
            @_createIcon(request)
            return

        @cls._requests.push(request)
        @load(libID)

#___________________________________________________________________________________________________ _processRequests
    _processRequests: () =>
        removes = []
        for r in @cls._requests
            if r.done or Types.isNone(@cls._icons[r.lib])
                continue

            # Set the request as complete
            r.done = true
            removes.push(r)

            @_createIcon(r)

        for r in removes
            ArrayUtils.remove(@cls._requests, r)

#___________________________________________________________________________________________________ _createIcon
    _createIcon: (data) =>
        fill   = if data.fill then Math.max(0.1, Math.min(data.fill, 1)) else 1
        pad    = Math.round(512*(1 - parseFloat(fill)))
        target = $(data.target)
        size   = if data.size then data.size else target.innerHeight() + 'px'

        color = if data.color then "fill=\"#{data.color}\"" else ''
        css   = if data.css then "class=\"#{data.css}\"" else ''

        v = @cls._icons[data.lib][data.icon]
        if not v
            return

        v = v.replace(/#C#/g, css).replace(/#F#/g, color)
        v = @cls._WRAP_DOM.replace('#SVG#', @cls._SVG_DOM.replace('#D#', v)).
                           replace(/#X#/g, '-' + pad).
                           replace(/#BW#/g, 512 + 2*pad).
                           replace(/#S#/g, size)

        if data.insertMode == 'REPLACE'
            target.html($(v))
        else
            target.append(v)

        if data.resize
            target.resize(@_handleIconResize)

#===================================================================================================
#                                                                                 H A N D L E R S

#___________________________________________________________________________________________________ _handleIconResize
    _handleIconResize: (event) =>
        target = $(event.currentTarget)
        icon   = target.find('.v-svgIcon')
        svg    = icon.find('svg')
        size   = target.innerHeight()
        icon.width(size).height(size)
        svg.attr('width', size + 'px')
        svg.attr('height', size + 'px')
