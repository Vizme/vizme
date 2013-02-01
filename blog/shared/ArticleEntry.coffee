# vmi.blog.shared.ArticleEntry
# Vizme, Inc. (C)2011-2012
# Scott Ernst

#___________________________________________________________________________________________________ ArticleEntry
class ArticleEntry

#===================================================================================================
#                                                                                       C L A S S

#___________________________________________________________________________________________________ initialize
    @initialize: () ->
        # Handles article side like resizing based on asynchronous loading.
        $('.articleSideLike').resize(@resizeArticles)

#___________________________________________________________________________________________________ resizeArticles
    @resizeArticles: (containerWidth, smallLayout) ->
        # Update sizes on each article item on the page.
        w = $(window).width()

        $('.article').each((index, element) ->
            me   = $(this)
            s    = me.find('.articleSummary')
            i    = me.find('.articleImage')
            img  = i.find('img')
            con  = me.find('.articleContainer')
            line = me.find('.articleLine')

            hAuto = {height:'auto'}
            me.css(hAuto)
            s.css(hAuto)
            i.css(hAuto)
            line.css(hAuto)

            if smallLayout
                s.css('margin', '0 0 0 0')
                s.css('float', 'none')
                s.css('width', 'auto')

                i.css('margin', '10px auto 0 auto')
                i.css('float', 'none')
                i.css('width', 'auto')
            else
                i.css('margin', '0 10px 0 0')
                i.css('float', 'right')
                i.width(img.width())

                s.css('margin-left', '10px 0 0 0')
                s.css('float', 'left')
                s.width(s.parent().width() - i.width() - 30)

                h = Math.max(s.height() + 20, img.height())
                s.height(h)
                i.height(h)


            like  = me.find('.articleLike')
            slike = me.find('.articleSideLike')
            if not smallLayout and (w - 130) > containerWidth
                if like.length > 0
                    like.hide()

                if slike.length > 0
                    slike.show()

                    dh = slike.height() - me.height()
                    if dh > 0
                        me.find('.articleLine').height(dh + 10)
            else
                if like.length > 0
                    like.show()

                if slike.length > 0
                    slike.hide()
                    slike.width(0)
        )

        return
