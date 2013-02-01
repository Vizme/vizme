# vmi.blog.article.Article
# Vizme, Inc. (C)2011-2012
# Scott Ernst

# import vmi.util.module.DisplayModule

class BlogArticle extends DisplayModule

#===================================================================================================
#                                                                                       C L A S S

    @ID = 'blogArticle'

#___________________________________________________________________________________________________ constructor
    constructor: () ->
        super(BlogArticle.ID, '#article-container')

#===================================================================================================
#                                                                                     P U B L I C

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
        thumb    = $('#header-image')

        fw    = focus.width()
        hAuto = {height:'auto'}
        sidebar.css(hAuto)
        content.css(hAuto)

        if smallLayout
            d = {float:'none', width:'auto'}
            sidebar.css(d)
            content.css(d)
            thumb.css(d)

            $('#share-box').css('width', 'auto')
            likes.css('display', 'inline-block')
        else
            sidebar.css('float', 'left')
            sidebar.width(200)

            content.css('float', 'right')
            content.width(fw - 210)

            thumb.css('float', 'right')
            thumb.width(thumb.find('img').width())

            $('#share-box').width(66)
            likes.css('display', 'block')

            h = Math.max(sidebar.height(), content.height()) + 10
            sidebar.height(h)
            content.height(h)



