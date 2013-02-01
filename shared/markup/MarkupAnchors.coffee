# vmi.shared.markup.MarkupAnchors
# Vizme, Inc. (C)2012
# Scott Ernst

# require vmi.util.Types

class MarkupAnchors

#===================================================================================================
#                                                                                       C L A S S

#___________________________________________________________________________________________________ addAnchorEvents
    @addAnchorEvents: (callback) ->
        callback = if Types.isFunction(callback) then callback else MarkupAnchors._handleAnchorClick
        $('.v-gvml-header-link').click(callback)

#___________________________________________________________________________________________________ _handleAnchorClick
    @_handleAnchorClick: (event) ->
        src    = $(event.currentTarget)
        target = $('#' + src.attr('data-id'))
        $.scrollTo(target, {offset: {top:-50, left:0}})