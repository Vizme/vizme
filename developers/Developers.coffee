# vmi.developers.Developers.coffee
# Vizme, Inc. (C)2012
# Scott Ernst

# import vmi.util.module.DisplayModule

class Developers extends DisplayModule

#===================================================================================================
#                                                                                       C L A S S

    @ID = 'developers'

#___________________________________________________________________________________________________ constructor
    constructor: () ->
        super(Developers.ID, '#vdev-focal-box')

        $('#vdev-search').bind('search', @_handleDocSearch)

        res = $('.vdev-searchResult')

        res.mouseover((event) ->
            me = $(event.currentTarget)
            me.addClass('v-S-bck-m1')
            me.find('.vdev-searchResult-title').addClass('vdev-searchResult-title-over')
        )

        res.mouseleave((event) ->
            me = $(event.currentTarget)
            me.removeClass('v-S-bck-m1')
            me.find('.vdev-searchResult-title').removeClass('vdev-searchResult-title-over')
        )

        res.click((event) ->
            me = $(event.currentTarget)
            window.open(me.attr('data-link'), '_self')
        )

#===================================================================================================
#                                                                                     P U B L I C

#___________________________________________________________________________________________________ resize
    resize: () =>
        cw         = $('#container').width()
        centerWide = cw - 210

        left   = $('#vdev-left-panel')
        center = $('#vdev-center-panel')
        center.width(centerWide)

        left.css('height', 'auto')
        center.css('height', 'auto')

        h = Math.max(left.height(), center.height()) + 10
        left.height(h)
        center.height(h)
        $('#vdev-focal-box').height(h + 10)

#===================================================================================================
#                                                                                 H A N D L E R S

#___________________________________________________________________________________________________ _handleDocSearch
    _handleDocSearch: (event) =>
        query = VIZME.mod.ui_CON.getValue($('#vdev-search'))
        if not query or query.length == 0
            return

        window.open('/search/doc?q=' + encodeURIComponent(query), '_self')