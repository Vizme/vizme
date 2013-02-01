# vmi.blog.index.BlogHome
# Vizme, Inc. (C)2012
# Scott Ernst

# import vmi.util.module.DisplayModule

# require vmi.blog.shared.ArticleEntry
# require vmi.util.url.URLUtils

class BlogHome extends DisplayModule

#===================================================================================================
#                                                                                       C L A S S

#___________________________________________________________________________________________________ constructor
    constructor: () ->

#===================================================================================================
#                                                                                     P U B L I C

#___________________________________________________________________________________________________ initialize
    initialize: () =>
        if not super()
            return false

        # Handles article side like resizing based on asynchronous loading.
        ArticleEntry.initialize()

        return true

#___________________________________________________________________________________________________ _resize
    resize: () ->
        win         = $(window)
        w           = win.width()
        h           = win.height()
        ww          = Math.max(300, Math.min(910, w - 20)) # Focus width
        smallLayout = w < 760 or w < h or VIZME.exec.displayType > 1

        # Resizes the main page containers
        c = $('#v-container')
        c.width(ww)
        $('#content-header').width(ww)

        content  = $('#content')
        sidebar  = $('#sidebar')

        if smallLayout
            sidebar.hide()
            sidebar.width(0)
            conWidth = ww
        else
            sidebar.show()
            sidebar.width(200)
            conWidth = ww - 210

        content.width(conWidth)

        ArticleEntry.resizeArticles(conWidth, smallLayout)

