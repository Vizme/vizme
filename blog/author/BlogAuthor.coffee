# vmi.blog.article.Article
# Vizme, Inc. (C)2011-2012
# Scott Ernst

# import vmi.util.module.DisplayModule
# require vmi.blog.shared.ArticleEntry

class BlogAuthor extends DisplayModule

#===================================================================================================
#                                                                                       C L A S S

    @ID = 'blogAuthor'

#___________________________________________________________________________________________________ constructor
    constructor: () ->
        super(BlogAuthor.ID, '#author-container')

#===================================================================================================
#                                                                                     P U B L I C

#___________________________________________________________________________________________________ initialize
    initialize: () =>
        if not super()
            return false

        # Handles article side like resizing based on asynchronous loading.
        ArticleEntry.initialize()

        return true

#___________________________________________________________________________________________________ resize
    resize: () =>
        win         = $(window)
        w           = win.width() # Width of the window
        h           = win.height()
        smallLayout = w < 760 or w < h or VIZME.exec.displayType > 1

        focus    = $('#focus')
        content  = $('#content')
        sidebar  = $('#sidebar')
        likes    = $(".likeBox")

        fw    = focus.width()
        hAuto = {height:'auto'}
        sidebar.css(hAuto)
        content.css(hAuto)

        if smallLayout
            sidebar.css('float', 'none')
            sidebar.css('width', 'auto')

            content.css('float', 'none')
            content.css('width', 'auto')
        else
            sidebar.css('float', 'left')
            sidebar.width(200)

            content.css('float', 'right')
            content.width(fw - 210)

            h = Math.max(sidebar.height(), content.height()) + 10
            sidebar.height(h)
            content.height(h)

        ArticleEntry.resizeArticles(fw, smallLayout)
